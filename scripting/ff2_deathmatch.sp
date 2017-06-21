#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <freak_fortress_2>
#include <POTRY>

#define CPGameData "cp_pct"

bool RoundRunning;
bool IsFakeLastManStanding=false;
bool IsLastMan[MAXPLAYERS+1];
bool AlreadyLastmanSpawned[MAXPLAYERS+1];
bool IsSnowStorm[MAXPLAYERS+1];

int top[MAXPLAYERS+1];
bool loserTop[MAXPLAYERS+1];
bool IsAFK[MAXPLAYERS+1];
int lastDamage;

int BGMCount;
int SpecialBGMCount;

float timeleft;
int noticed;

Handle MusicKV;
Handle DrawGameTimer; // Same FF2's DrawGameTimer.

Handle OnTimerFor;

Handle SDKGetCPPct;
bool useCPvalue;
int capTeam;
int controlpointIndex;
bool isCapping;

float NoTimerHudTime;
float NoEnemyTime[MAXPLAYERS+1];
float WeaponCannotUseTime[MAXPLAYERS+1];
float TeleportTime[MAXPLAYERS+1];

int suddendeathDamege;

/*
enum GameMode
{
    Game_None = 0,
    Game_SuddenDeath,
    Game_LastManStanding,
    Game_AttackAndDefense
};
*/

GameMode CurrentGame;

static const char OTVoice[][] = {
    "vo/announcer_overtime.mp3",
    "vo/announcer_overtime2.mp3",
    "vo/announcer_overtime3.mp3",
    "vo/announcer_overtime4.mp3"
};


public Plugin:myinfo=
{
    name="Freak Fortress 2 : Deathmatch Mod",
    author="Nopied",
    description="....",
    version="1.3",
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	CreateNative("FF2_EnablePlayerLastmanStanding", Native_EnablePlayerLastmanStanding);
    CreateNative("FF2_GetGameState", Native_GetGameState);
    CreateNative("FF2_SetGameState", Native_SetGameState);
    CreateNative("FF2_GetTimeLeft", Native_GetTimeLeft);
    CreateNative("FF2_SetTimeLeft", Native_SetTimeLeft);
    CreateNative("FF2_IsLastMan", Native_IsLastMan);

    OnTimerFor = CreateGlobalForward("FF2_OnDeathMatchTimer", ET_Hook, Param_FloatByRef);

	return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
    HookEvent("teamplay_round_start", OnRoundStart_Pre);
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
    // TODO: pass 커맨드 구현.

    LoadTranslations("freak_fortress_2.phrases");

    RegConsoleCmd("pass", PassCmd);
    RegAdminCmd("checklastman", CheckLastMan, ADMFLAG_CHEATS);

    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");

    HookEvent("teamplay_point_startcapture", OnStartCapture);
    new Handle:hCFG=LoadGameConfigFile(CPGameData);
    if(hCFG == INVALID_HANDLE)
    {
        LogError("Missing gamedata file %s.txt! Will not use CP capture percentage values!", CPGameData);
        CloseHandle(hCFG);
        useCPvalue=false;
        HookEvent("teamplay_capture_broken", OnBreakCapture);
        return;
    }
    StartPrepSDKCall(SDKCall_Entity);
    PrepSDKCall_SetFromConf(hCFG, SDKConf_Signature, "CTeamControlPoint::GetTeamCapPercentage");
    PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
    PrepSDKCall_SetReturnInfo(SDKType_Float, SDKPass_Plain);
    if((SDKGetCPPct = EndPrepSDKCall()) == INVALID_HANDLE)
    {
        LogError("Failed to create SDKCall for CTeamControlPoint::GetTeamCapPercentage signature! Will not use CP capture percentage values!");
        CloseHandle(hCFG);
        useCPvalue=false;
        HookEvent("teamplay_capture_broken", OnBreakCapture);
        return;
    }
    useCPvalue=true;
    CloseHandle(hCFG);
}

public Action OnStartCapture(Handle:event, const char[] eventName, bool dontBroadcast)
{
    capTeam=GetEventInt(event, "capteam");
    /*
    if(useCPvalue)
    {
        capTeam=GetEventInt(event, "capteam");
        return;
    }
    */

    if(!isCapping && GetEventInt(event, "capteam")>1)
    {
        isCapping=true;

        if(GetGameState() == Game_ControlPointOverTime)
        {
            char OTAlerting[PLATFORM_MAX_PATH];
            strcopy(OTAlerting, sizeof(OTAlerting), OTVoice[GetRandomInt(0, sizeof(OTVoice)-1)]);
            EmitSoundToAll(OTAlerting);
        }
    }
}

public Action OnBreakCapture(Handle event, const char[] eventName, bool dontBroadcast)
{
    if(!GetEventFloat(event, "time_remaining") && isCapping)
    {
        capTeam=0;
        isCapping=false;
    }
}

public Action OnRoundStart_Pre(Handle event, const char[] name, bool dont)
{
    if(!RoundRunning)
    {
        CreateTimer(10.4, OnRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
        RoundRunning = true;
    }
}

public void OnMapStart()
{
  if(MusicKV != INVALID_HANDLE)
  {
    CloseHandle(MusicKV);
    MusicKV = INVALID_HANDLE;
  } //

  RoundRunning = false;
  NoTimerHudTime = 0.0;

  for (new i = 0; i < sizeof(OTVoice); i++)
  {
      PrecacheSound(OTVoice[i], true);
  }

  if(DrawGameTimer != INVALID_HANDLE)
  {
      timeleft = 0.0;
      KillTimer(DrawGameTimer);
      DrawGameTimer = INVALID_HANDLE;
  }
  PrecacheMusic();
}

public Action CheckLastMan(int client, int args)
{
    if(args != 1)
	{
		CReplyToCommand(client, "{olive}[FF2]{default} Usage: !checklastman <target>");
		return Plugin_Handled;
	}

	char pattern[PLATFORM_MAX_PATH];
	GetCmdArg(1, pattern, sizeof(pattern));

	char targetName[MAX_TARGET_LENGTH];
	int targets[MAXPLAYERS], matches;
	bool targetNounIsMultiLanguage;

	if((matches=ProcessTargetString(pattern, client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
	{
		ReplyToTargetError(client, matches);
		return Plugin_Handled;
	}

	for(int target; target<matches; target++)
	{
		if(!IsClientSourceTV(targets[target]) && !IsClientReplay(targets[target]))
		{
            CPrintToChatAll("%N: IsLastMan[%N] = %s\n AlreadyLastmanSpawned[%N] = %s",
            targets[target], targets[target], IsLastMan[targets[target]] ? "true" : "false"
            , targets[target], AlreadyLastmanSpawned[targets[target]] ? "true" : "false");
        }
	}

    return Plugin_Handled;
}

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	char strChat[100];
	char temp[3][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 3, 64, true);

	if(StrEqual(temp[0], "넘기기", true))
	{
		if(temp[1][0] != '\0')
		{
			return Plugin_Continue;
		}
		PassLastMan(client);
		return Plugin_Handled;
	}

    return Plugin_Continue;
}

public Action PassCmd(int client, int args)
{
    if(!IsValidClient(client))  return Plugin_Continue;

    PassLastMan(client);

    return Plugin_Continue;
}

void PassLastMan(int client)
{
    if(FF2_GetRoundState() != 1 && GetGameState() != Game_LastManStanding || IsFakeLastManStanding)
    {
        CPrintToChat(client, "{olive}[FF2]{default} 이 명령어는 {orange}최후의 결전{default}에서만 사용하실 수 있습니다.");
        return;
    }
    if(loserTop[client] || !IsLastMan[client] || !IsPlayerAlive(client) || IsBossTeam(client))
    {
        CPrintToChat(client, "{olive}[FF2]{default} 이미 넘기셨거나 라스트맨이 아닙니다.");
        return;
    }
    if(NoEnemyTime[client] <= GetGameTime())
    {
        CPrintToChat(client, "{olive}[FF2]{default} 무적시간 끝나서 넘겨드릴 수 없습니다. 싸우세요!");
        return;
    }

    bool IsBossHurt = false;
    int boss;
    for(int target = 1; target <= MaxClients; target++)
    {
        if(IsClientInGame(target) && IsBoss(target) && IsPlayerAlive(target))
        {
            boss = FF2_GetBossIndex(target);
            if(FF2_GetBossMaxHealth(boss) - 3 > FF2_GetBossHealth(boss))
                IsBossHurt = true;
        }
    }

    if(IsBossHurt)
    {
        CPrintToChat(client, "{olive}[FF2]{default} 이미 보스를 때리신 것 같은데.. 어쩔 수 없네요. 싸우세요!");
        return;
    }

    loserTop[client] = true;
    timeleft = 120.0;
    int somebodyBeLastman = 0;
    TFTeam team = TF2_GetClientTeam(client);

    for(int count = 0; count <= MaxClients; count++)
    {
        if(!loserTop[top[count]] && IsValidClient(top[count]) && !IsPlayerAlive(top[count]))
        {
            TF2_ChangeClientTeam(client, team);
            EnableLastManStanding(top[count], true);
            somebodyBeLastman = top[count];

            break;
        }
    }

    TF2_ChangeClientTeam(client, TFTeam_Spectator);
    TF2_ChangeClientTeam(client, team);
    if(IsPlayerAlive(client))
        ForcePlayerSuicide(client);
    // FIXME: 팀포 버그

    if(IsValidClient(somebodyBeLastman))
    {
        CPrintToChatAll("{olive}[FF2]{default} %N님이 라스트맨을 다른 사람에게 넘겼습니다. 이제 %N님이 대신 싸웁니다!", client, somebodyBeLastman);
    }
    else
    {
        CPrintToChatAll("{olive}[FF2]{default} %N님이 라스트맨을 넘기려고 하였으나.. 대체할 사람이 없군요!", client);
    }
}

public Action OnRoundStart(Handle timer)
{
    if(FF2_GetRoundState() != 1) return Plugin_Continue;

    NoTimerHudTime = GetGameTime() + 10.0;
    for(int target = 1; target <= MaxClients; target++)
    {
        NoEnemyTime[target] = 0.0;
        TeleportTime[target] = 0.0;
        WeaponCannotUseTime[target] = -1.0;
        loserTop[target] = false;
        IsLastMan[target] = false;

        if(IsClientInGame(target))
        {
            FF2_SetClientGlow(target, 0.0, 0.0);

            SDKUnhook(target, SDKHook_OnTakeDamage, OnTakeDamage);
            SDKHook(target, SDKHook_OnTakeDamage, OnTakeDamage);

            SDKUnhook(target, SDKHook_PreThinkPost, StatusTimer);
            SDKHook(target, SDKHook_PreThinkPost, StatusTimer);
        }
    }

    if(CheckAlivePlayers() < 2){ // TODO: 커스터마이즈
        CPrintToChatAll("{olive}[FF2]{default} {green}최소 %d명{default}이 있어야 타이머가 작동됩니다.", 2);
        return Plugin_Continue;
    }

    // SetGameState(Game_AttackAndDefense);

    timeleft = float(CheckAlivePlayers()*22)+45.0;
    DrawGameTimer = CreateTimer(0.1, OnTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Continue;
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(FF2_GetRoundState() != 1)    return Plugin_Continue;

    if((GetGameState() == Game_LastManStanding || IsFakeLastManStanding)
    && IsLastMan[client]
    && !AlreadyLastmanSpawned[client])
    {
        AlreadyLastmanSpawned[client] = true;

        Handle LastManData;
        CreateDataTimer(0.1, BeLastMan, LastManData);

        WritePackCell(LastManData, 0);
        WritePackCell(LastManData, client);
        ResetPack(LastManData);

    }
    else if(GetGameState() == Game_SuddenDeath
    && !IsBossTeam(client))
    {
        suddendeathDamege = CheckAlivePlayers();
    }

    return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    RoundRunning = false;
    NoTimerHudTime = 0.0;

    for(int client = 1; client <= MaxClients; client++)
    {
        if(IsClientInGame(client))
        {
            SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
            SDKUnhook(client, SDKHook_PreThinkPost, StatusTimer);
        }

        IsLastMan[client] = false;
        AlreadyLastmanSpawned[client] = false;
        WeaponCannotUseTime[client] = -1.0;
        NoEnemyTime[client] = 0.0;
        TeleportTime[client] = 0.0;
        loserTop[client] = false;
        IsAFK[client] = false;
    }

    SetGameState(Game_None);

    IsFakeLastManStanding = false;
    suddendeathDamege = 0;

    timeleft=0.0;
    if(DrawGameTimer != INVALID_HANDLE) // What?
    {
        KillTimer(DrawGameTimer);
        DrawGameTimer = INVALID_HANDLE;
    }
    return Plugin_Continue;
}

public Action:OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
    if(FF2_GetRoundState() != 1)
    {
        SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
        return Plugin_Continue;
    }

    if(!IsValidClient(attacker) || !IsValidClient(victim))
        return Plugin_Continue;

    char classname[60];

    if(IsBossTeam(attacker) && GetGameState() == Game_AttackAndDefense)
    {
        if(GetEntityClassname(attacker, classname, sizeof(classname)) && !strcmp(classname, "trigger_hurt", false))
            return Plugin_Continue;

        float realDamage = damage;
        if(damagetype & DMG_CRIT)
            realDamage *= 3.0;

        if(GetEntProp(victim, Prop_Send, "m_iHealth") - (RoundFloat(realDamage) + 2) < 0)
        {
            TF2_RegeneratePlayer(victim);

            TF2_AddCondition(victim, TFCond_Ubercharged, 20.0);
            TF2_AddCondition(victim, TFCond_Stealthed, 20.0);
            TF2_AddCondition(victim, TFCond_SpeedBuffAlly, 20.0);

            WeaponCannotUseTime[victim] = GetGameTime() + 20.0;
            SetEntProp(victim, Prop_Send, "m_CollisionGroup", 1);

            PrintCenterText(victim, "죽을 정도의 치명적인 피해를 받아 20초 동안 행동불능 상태가 됩니다.\n 보스에게서 떨어지세요!");

            return Plugin_Handled;
        }
    }

    bool changed = false;

    if(!IsBossTeam(attacker) && (GetGameState() == Game_LastManStanding || IsFakeLastManStanding) && IsLastMan[attacker] && IsValidEntity(weapon))
    {
        // int boss = FF2_GetBossIndex(victim);
        float bossPosition[3];

        GetEntPropVector(victim, Prop_Send, "m_vecOrigin", bossPosition);
        GetEntityClassname(weapon, classname, sizeof(classname));

        if(!StrContains(classname, "tf_weapon_shotgun", false) && TF2_GetPlayerClass(attacker) == TFClass_Soldier)
        {
          if(!TF2_IsPlayerInCondition(victim, TFCond_MegaHeal) && !(GetEntityFlags(victim) & FL_ONGROUND))
          {
                float velocity[3];
                GetEntPropVector(victim, Prop_Data, "m_vecVelocity", velocity);
                velocity[2] += 650.0;
                TeleportEntity(victim, NULL_VECTOR, NULL_VECTOR, velocity);
          }

          int explosion = CreateEntityByName("env_explosion");

          DispatchKeyValueFloat(explosion, "DamageForce", 0.0);
          SetEntProp(explosion, Prop_Data, "m_iMagnitude", 0, 4);
          SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 400, 4);
          SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", attacker);
          DispatchSpawn(explosion);

          TeleportEntity(explosion, bossPosition, NULL_VECTOR, NULL_VECTOR);
          AcceptEntityInput(explosion, "Explode");
          AcceptEntityInput(explosion, "kill");
        }
        if(!StrContains(classname, "tf_weapon_shotgun", false) && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
        {
            TF2_IgnitePlayer(victim, attacker);
        }

        if(damagetype & DMG_BULLET && (TF2_GetPlayerClass(attacker) == TFClass_Sniper || TF2_GetPlayerClass(attacker) == TFClass_Engineer))
        {
          changed=true;
          damagetype|=DMG_PREVENT_PHYSICS_FORCE;
      }

    }

    return changed ? Plugin_Changed : Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

    if(!IsValidClient(client))
        return Plugin_Continue;

    if(FF2_GetRoundState() != 1 || IsBossTeam(client) || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        return Plugin_Continue;

    IsLastMan[client] = false;
    AlreadyLastmanSpawned[client] = false;

    if((GetGameState() == Game_SuddenDeath || GetGameState() == Game_None)
    && !IsBossTeam(client))
    {
        if(!(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
        {
            // timeleft += 15.0 + (float(FF2_GetClientDamage(client)) / 100.0);
            suddendeathDamege = CheckAlivePlayers();
        }
    }

    if((GetGameState() != Game_AttackAndDefense && GetGameState() != Game_LastManStanding && GetGameState() != Game_SpecialLastManStanding && GetGameState() != Game_ControlPoint && GetGameState() != Game_ControlPointOverTime)
    && CheckAlivePlayers() <= 1 && GetClientCount(true) > 2) // 라스트 맨 스탠딩
    {
        SetGameState(Game_LastManStanding);
        IsFakeLastManStanding = false;

        int bosses[MAXPLAYERS+1];
        int topDamage[3];
        int totalDamage;
        int bossCount;

        for(int count=0; count<=MaxClients; count++)
        {
            top[count] = 0;
        }

        for(int target = 1; target <= MaxClients; target++)
        {
          if(!IsValidClient(target)) // for bossCount.
      			continue;
          else if(IsBoss(target) && IsPlayerAlive(target)){
            ExtinguishEntity(target);
            bosses[bossCount++] = target;
            continue;
          }
          else if(IsBossTeam(target)) // FF2_GetClientDamage(client)<=0 ||
            continue;
        }

        int clientDamage;
        int targetDamage;
        int tempTop[MAXPLAYERS+1];

        for(int target=1; target<=MaxClients; target++)
        {
            if(!IsClientInGame(target) || FF2_GetClientDamage(target) <= 0 || IsBossTeam(target))
                continue;

            clientDamage = FF2_GetClientDamage(target);
            targetDamage = FF2_GetClientDamage(top[0]);

            if(targetDamage > 0)
            {
                for(int count=0; count < MaxClients; count++)
                {
                    tempTop[count] = top[count];
                }

                if(clientDamage > targetDamage)
                {
                    for(int count=0; count < MaxClients; count++)
                    {
                        if(MaxClients < count + 1) break;

                        top[count+1] = tempTop[count];
                    }

                    top[0] = target;
                }
                else // 이때는 본인의 포지션의 맞는 곳으로 가야함.
                {   // 위쪽부터 순차적으로 검색 후 정렬.
                    int position=0;
                    for(int count=1; count < MaxClients; count++)
                    {
                        if(MaxClients < count + 1) break;
                        targetDamage = FF2_GetClientDamage(top[count]);

                        if(clientDamage >= targetDamage)
                        {
                            top[count+1] = tempTop[count];
                            if(position == 0)
                                position = count;
                        }
                    }
                    top[position] = target;
                }
            }
            else
            {
                top[0] = target;
            }
        }

        if(!IsValidClient(top[0]))
            return Plugin_Continue;

        SetRandomSeed(GetTime());

        for(int i; i<3; i++)
        {
            topDamage[i] = FF2_GetClientDamage(top[i]);
            totalDamage += topDamage[i];
        }

        int random = GetRandomInt(0, totalDamage);

        while(lastDamage == random)
        {
          random = GetRandomInt(0, totalDamage);
        }
        lastDamage = random;
        int winner;

        for(int i; i < 3; i++) // OH this stupid code..
        {
            int tempDamage;
            for (int x = i; x >= 0; x--)
            {
                tempDamage+=topDamage[x];
            }

            if(random > tempDamage)
                continue;
            winner = top[i];
            break;
        }

        CPrintToChatAll("{olive}[FF2]{default} 확률: %N - %.2f%% | %N - %.2f%% | %N - %.2f%%",
        top[0], float(topDamage[0])/float(totalDamage)*100.0,
        top[1], float(topDamage[1])/float(totalDamage)*100.0,
        top[2], float(topDamage[2])/float(totalDamage)*100.0
        );
        CPrintToChatAll("%N님이 {red}강력한 무기{default}를 흭득하셨습니다!",
        winner);


        /*
        int particle = AttachParticle(winner, "env_snow_stormfront_001");

        if(IsValidEntity(particle))
        {
            SDKHook(particle, SDKHook_SetTransmit, SnowStormTransmit);
        }

        particle = AttachParticle(winner, "env_snow_stormfront_mist");

        if(IsValidEntity(particle))
        {
            SDKHook(particle, SDKHook_SetTransmit, SnowStormTransmit);
        }
        */

        if(timeleft<=0.0)
            DrawGameTimer=CreateTimer(0.1, OnTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);

        timeleft = 120.0;
        SetGameState(Game_LastManStanding);

        for(int i; i<bossCount; i++)
        {
            int boss = FF2_GetBossIndex(bosses[i]);
            int newhealth = 7500/bossCount;

            FF2_SetBossCharge(boss, 0, 0.0);
            FF2_SetBossLives(boss, 1);
            FF2_SetBossMaxLives(boss, 1);

            FF2_SetBossMaxHealth(boss, FF2_GetBossHealth(boss));

            if(FF2_GetBossHealth(boss) < newhealth){
                FF2_SetBossMaxHealth(boss, newhealth);
                FF2_SetBossHealth(boss, newhealth);
            }

            if(FF2_HasAbility(boss, "ff2_support", "ff2_special_lastmanstanding"))
            {
                SetGameState(Game_SpecialLastManStanding);
            }
        }

        if(GetGameState() == Game_SpecialLastManStanding)
        {
            for(int i; i<bossCount; i++)
            {
                int boss = FF2_GetBossIndex(bosses[i]);

                FF2_SetBossMaxRageCharge(boss, 1000.0);
                FF2_SetBossCharge(boss, 0, 400.0);
            }

            PrintCenterTextAll("%N님이 보스가 됩니다!", winner);
        }
        else
        {
            PrintCenterTextAll("%N님이 보스와 최후의 결전을 치루게 됩니다!", winner);
        }

        FF2_SetServerFlags(FF2SERVERFLAG_ISLASTMAN|FF2SERVERFLAG_UNCHANGE_BOSSBGM_USER|FF2SERVERFLAG_UNCHANGE_BOSSBGM_SERVER|FF2SERVERFLAG_UNCOLLECTABLE_DAMAGE);

        if(GetEventInt(event, "userid") == GetClientUserId(winner))
        {
            int forWinner = FindAnotherPerson(winner);

            if(!forWinner)
            {
                CPrintToChatAll("{olive}[FF2]{default} 보스가 그 누구도 라스트맨이 되는 것을 허락하지 않았습니다..");
                return Plugin_Continue;
            }

            Handle LastManData; // In this? data = NeedData | winner | forWinner | team | IsAlive
            CreateDataTimer(0.4, BeLastMan, LastManData);

            WritePackCell(LastManData, 1);
            WritePackCell(LastManData, winner);
            WritePackCell(LastManData, forWinner);
            WritePackCell(LastManData, GetClientTeam(forWinner));

            if(IsPlayerAlive(forWinner))
            {
                WritePackCell(LastManData, 1);

                TF2_AddCondition(forWinner, TFCond_Bonked, 0.4);
            }
            else // Yeah. then it said. Not Alive.
            {
                WritePackCell(LastManData, 0);

                TF2_ChangeClientTeam(forWinner, TF2_GetClientTeam(winner));
                TF2_RespawnPlayer(forWinner);
            }
            ResetPack(LastManData);

            FF2_StartMusic(); // Call FF2_OnMusic
            FF2_LoadMusicData(MusicKV);
            return Plugin_Continue;
        }

        EnableLastManStanding(winner, true);
        // Debug("OnPlayerDeath => EnableLastManStanding");

        FF2_StartMusic(); // Call FF2_OnMusic
        FF2_LoadMusicData(MusicKV);
        return Plugin_Continue;
    }


    return Plugin_Continue;
}

public Action SnowStormTransmit(int entity, int client)
{
    // SetEdictFlags(entity, FL_EDICT_FREE);
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    if(IsClientInGame(owner))
    {
        float position[3];
        GetEntPropVector(owner, Prop_Send, "m_vecOrigin", position);
	    TeleportEntity(entity, position, NULL_VECTOR, NULL_VECTOR);
    }

    if(!IsSnowStorm[client])
        return Plugin_Handled;

    return Plugin_Continue;
}

void EnableLastManStanding(int client, bool spawnPlayer = false)
{
    if(FF2_GetRoundState() != 1)
    {
        IsLastMan[client] = false;
        NoEnemyTime[client] = 0.0;
        // Debug("%N is lastman. but not now.", client);
        return;
    }

    IsLastMan[client] = true;
    NoEnemyTime[client] = GetGameTime() + 12.0;
    IsAFK[client] = true;

    if(!AlreadyLastmanSpawned[client] && spawnPlayer)
    {
        AlreadyLastmanSpawned[client] = true;
        TF2_RespawnPlayer(client);
    }

    if(GetGameState() == Game_SpecialLastManStanding)
    {
        // Debug("Game_SpecialLastManStanding");
        Handle BossKV;
        ArrayList nameArray = new ArrayList();
        int nameArrayCount = 0;
        char name[120];
        char bossName[120];
        int bossCount=0;

        int totalBossHP=0;

        int bosses[MAXPLAYERS+1];
        for(int target = 1; target <= MaxClients; target++)
        {
            if(!IsValidClient(target)) // for bossCount.
                continue;

            else if(IsBoss(target) && IsPlayerAlive(target))
            {
                bosses[bossCount++] = target;
                int boss = FF2_GetBossIndex(target);
                totalBossHP += FF2_GetBossHealth(boss);

                continue;
            }
        }

        bool equalName = false;

        for (int i=1; (BossKV=FF2_GetSpecialKV(i,true)); i++)
    	{
            KvRewind(BossKV);
            if(KvGetNum(BossKV, "ban_vs_bosses") > 0)
                continue;

            for(int bossC; bossC<bossCount; bossC++)
            {
                int boss = FF2_GetBossIndex(bosses[bossC]);
                if(boss == i)
                {
                    equalName = true;
                    break;
                }

            }

            if(equalName)
            {
                continue;
            }

            // Debug("name = %s, equalName = %s", name, equalName ? "true" : "false");

            if(!equalName)
            {
                nameArrayCount++;
                nameArray.Push(i);
            }
    	}

        if(nameArrayCount > 0)
        {
            SetRandomSeed(GetTime());

            int random = GetRandomInt(1, nameArrayCount-1);
            random = nameArray.Get(random);
            Debug("Game_SpecialLastManStanding: %N %i", client, random);
            FF2_MakeClientToBoss(client, random);

            int boss = FF2_GetBossIndex(client);
            FF2_SetBossMaxHealth(boss, totalBossHP/2);
            FF2_SetBossHealth(boss, totalBossHP/2);
            FF2_SetBossLives(boss, 1);
            FF2_SetBossCharge(boss, 0, 400.0);
            FF2_SetBossMaxRageCharge(boss, 1000.0);
        }
        else
        {
            TF2_AddCondition(client, TFCond_Ubercharged, 10.0);
            TF2_AddCondition(client, TFCond_Stealthed, 10.0);
            TF2_AddCondition(client, TFCond_SpeedBuffAlly, 10.0);
            GiveLastManWeapon(client);

            RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
            RemovePlayerTarge(client);
        }

        nameArray.Close();
    }
    else
    {
        TF2_AddCondition(client, TFCond_Ubercharged, 10.0);
        TF2_AddCondition(client, TFCond_Stealthed, 10.0);
        TF2_AddCondition(client, TFCond_SpeedBuffAlly, 10.0);
        GiveLastManWeapon(client);

        RemovePlayerBack(client, {57, 133, 405, 444, 608, 642}, 7);
        RemovePlayerTarge(client);
    }

    FF2_SetFF2Userflags(client, FF2_GetFF2Userflags(client) | FF2USERFLAG_ALLOW_FACESTAB | FF2USERFLAG_ALLOW_GROUNDMARKET | FF2USERFLAG_ALLOW_MINIBOMB | ~FF2USERFLAG_NOTALLOW_MINIBOMB);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
  if(!IsLastMan[client]
  || !IsPlayerAlive(client) ) return Plugin_Continue;

  if(GetGameState() == Game_LastManStanding)
  {
      if(NoEnemyTime[client] > GetGameTime())
      {
          if(IsAFK[client] && buttons > 0)
          {
              IsAFK[client] = false;
          }
      }
  }

  if(GetGameState() != Game_LastManStanding && !IsFakeLastManStanding)
        return Plugin_Continue;

  if(buttons & IN_ATTACK2 && IsWeaponSlotActive(client, 1)) // && GetPlayerWeaponSlot(client, 2) == GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"))
  {
    if(TF2_GetPlayerClass(client) != TFClass_Engineer)
      return Plugin_Continue;

    if(TeleportTime[client] > GetGameTime())
    {
      CPrintToChat(client, "{olive}[FF2]{default} 휴대용 텔레포터의 대기시간이 남아있습니다. (남은 시간: %.1f)", TeleportTime[client]-GetGameTime());
      return Plugin_Continue;
    }

    int metal = GetEntProp(client, Prop_Send, "m_iAmmo", _, 3);
    if(metal < 200) // TODO: 커스터마이즈
    {
      CPrintToChat(client, "{olive}[FF2]{default} 최소 {red}%d{default}의 금속이 필요합니다.", 200);
      return Plugin_Continue;
    }

    float clientPos[3];
    GetClientEyePosition(client, clientPos);

    if(TryTeleport(client))
    {
      CreateTimer(2.0, RemoveEntity, AttachParticle(client, "teleported_red"), TIMER_FLAG_NO_MAPCHANGE);
      CreateTimer(2.0, RemoveEntity, AttachParticle(client, "teleported_red", false), TIMER_FLAG_NO_MAPCHANGE);

      if(!IsPlayerStuck(client))
      {
         CPrintToChatAll("{olive}[FF2]{default} {red}%N{default}님의 휴대용 텔레포터!", client);
         SetEntProp(client, Prop_Send, "m_iAmmo", metal-200, _, 3);
         TeleportTime[client] = GetGameTime()+15.0;
      }
      else
      {
          PrintCenterText(client, "지정한 위치가 끼는 자리에 있어 작동되지 않았습니다.");
          TeleportEntity(client, clientPos, NULL_VECTOR, NULL_VECTOR);
      }
    }
  }

  return Plugin_Continue;
}

public bool TraceAnything(int entity, int contentsMask)
{
    return false;
}

public Action RemoveEntity(Handle timer, int entity)
{
	if(IsValidEntity(entity) && entity>MaxClients)
	{
		AcceptEntityInput(entity, "Kill");
        RemoveEdict(entity);
	}
}


public Action OnTimer(Handle timer)
{
    if(FF2_GetRoundState() != 1 || timeleft < 0.0)
    {
        return Plugin_Stop;
    }

    Handle timeleftHUD=CreateHudSynchronizer();

    char timeDisplay[60];

    if(GetGameState() == Game_ControlPointOverTime)
    {
        float captureValue;
        if(useCPvalue)
        {
            captureValue=SDKCall(SDKGetCPPct, controlpointIndex, capTeam);
            SetHudTextParams(-1.0, 0.17, 0.11, capTeam==2 ? 191 : capTeam==3 ? 90 : 0, capTeam==2 ? 57 : capTeam==3 ? 140 : 0, capTeam==2 ? 28 : capTeam==3 ? 173 : 0, 255, 0);
            Format(timeDisplay, sizeof(timeDisplay), "OVERTIME (Capture: %d%%)", RoundFloat(captureValue*100));

            if(captureValue<=0.0)
            {
                ForceTeamWin(0);
                capTeam=0;
                CloseHandle(timeleftHUD);
                return Plugin_Stop;
            }
        }
        else
        {
            SetHudTextParams(-1.0, 0.17, 0.11, 255, 255, 255, 255);
            Format(timeDisplay, sizeof(timeDisplay), "OVERTIME");

            // capTeam

            if(!isCapping)
            {
                ForceTeamWin(0);
                capTeam=0;
                CloseHandle(timeleftHUD);
                return Plugin_Stop;
            }

        }

        for(new client = 1; client <= MaxClients; client++)
      	{
      		if(IsValidClient(client))
      		{
      			FF2_ShowSyncHudText(client, timeleftHUD, timeDisplay);
      		}
      	}

        CloseHandle(timeleftHUD);
        return Plugin_Continue;
    }

  	if(RoundFloat(timeleft)/60>9)
  	{
  		IntToString(RoundFloat(timeleft)/60, timeDisplay, sizeof(timeDisplay));
  	}
  	else
  	{
  		Format(timeDisplay, sizeof(timeDisplay), "0%i", RoundFloat(timeleft)/60);
  	}

  	if(RoundFloat(timeleft)%60>9)
  	{
  		Format(timeDisplay, sizeof(timeDisplay), "%s:%i", timeDisplay, RoundFloat(timeleft)%60);
  	}
  	else
  	{
  		Format(timeDisplay, sizeof(timeDisplay), "%s:0%i", timeDisplay, RoundFloat(timeleft)%60);
  	}

    if(timeleft<60.0)
    {
      Format(timeDisplay, sizeof(timeDisplay), "%.1f", timeleft);
    }


/*
    if(GetGameState() == Game_None && CheckAlivePlayers() <= 2)
    {
        Format(timeDisplay, sizeof(timeDisplay), "%s | 2명 이하는 타이머가 작동되지 않음!", timeDisplay);
    }
    else
    {
        timeleft-=0.1;
    }
*/
    float tempTimeleft = timeleft;
    Action action;

    Call_StartForward(OnTimerFor);
    Call_PushFloatRef(tempTimeleft);
    Call_Finish(action);

    if(action == Plugin_Continue)
    {
        if(GetGameState() == Game_None || GetGameState() == Game_SuddenDeath)
            timeleft -= 0.1 * float(OnlyParisLeft()+1);
        else
            timeleft -= 0.1;
    }
    else if(action == Plugin_Changed)
    {
        timeleft = tempTimeleft;
    }

    if(NoTimerHudTime <= GetGameTime())
    {
        SetHudTextParams(-1.0, 0.17, 0.11, 255, 255, 255, 255);
      	for(new client = 1; client <= MaxClients; client++)
      	{
      		if(IsValidClient(client))
      		{
      			FF2_ShowSyncHudText(client, timeleftHUD, timeDisplay);
      		}
      	}
    }

    if(GetGameState() == Game_SuddenDeath)
    {
        int boss;
        int bossCount = 0;
        int bossList[MAXPLAYERS + 1];

        for(new client = 1; client <= MaxClients; client++)
        {
            if(IsClientInGame(client) && IsBoss(client) && IsPlayerAlive(client))
            {
                bossList[bossCount++] = client;
            }
        }

        for(int loop = 0; loop < bossCount; loop++)
        {
            boss = FF2_GetBossIndex(bossList[loop]);
            if(boss != -1)
                FF2_SetBossHealth(boss, FF2_GetBossHealth(boss) - (suddendeathDamege / bossCount));
        }
    }

    CloseHandle(timeleftHUD);

    switch(RoundFloat(timeleft))
  	{
  		case 300:
  		{
            if(noticed != RoundFloat(timeleft))
      			   EmitSoundToAll("vo/announcer_ends_5min.mp3");
            noticed=RoundFloat(timeleft);
  		}
  		case 120:
  		{
            if(noticed != RoundFloat(timeleft))
      			   EmitSoundToAll("vo/announcer_ends_2min.mp3");
            noticed=RoundFloat(timeleft);
  		}
  		case 60:
  		{
            if(noticed != RoundFloat(timeleft))
      			   EmitSoundToAll("vo/announcer_ends_60sec.mp3");
            noticed=RoundFloat(timeleft);
  		}
  		case 30:
  		{
            if(noticed != RoundFloat(timeleft))
      			   EmitSoundToAll("vo/announcer_ends_30sec.mp3");
            noticed=RoundFloat(timeleft);
      	}
  		case 10:
  		{
            if(noticed != RoundFloat(timeleft))
              EmitSoundToAll("vo/announcer_ends_10sec.mp3");
            noticed=RoundFloat(timeleft);
  		}
  		case 1, 2, 3, 4, 5:
  		{
            if(noticed != RoundFloat(timeleft))
            {
        			decl String:sound[PLATFORM_MAX_PATH];
        			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", RoundFloat(timeleft));
        			EmitSoundToAll(sound);
            }
            noticed=RoundFloat(timeleft);
  		}
  		case 0:
  		{
            DrawGameTimer=INVALID_HANDLE;

            if(GetGameState() == Game_LastManStanding)
            {
                CPrintToChatAll("{olive}[FF2]{default} 제한시간이 끝나 보스가 승리합니다.");
                ForceTeamWin(FF2_GetBossTeam());
                return Plugin_Stop;
            }
            else if(GetGameState() == Game_SpecialLastManStanding)
            {
                CPrintToChatAll("{olive}[FF2]{default} 제한시간이 끝나 무승부로 처리됩니다.");
                ForceTeamWin(0);
                return Plugin_Stop;
            }
            else if(GetGameState() == Game_ControlPoint)
            {
                if(!isCapping)
                {
                    CPrintToChatAll("{olive}[FF2]{default} 제한시간이 끝나 무승부로 처리됩니다.");
                    ForceTeamWin(0);

                    return Plugin_Stop;
                }
                else
                {
                    SetGameState(Game_ControlPointOverTime);
                    timeleft = 60.0; // 이 시간으로 고정;

                    char OTAlerting[PLATFORM_MAX_PATH];
                    strcopy(OTAlerting, sizeof(OTAlerting), OTVoice[GetRandomInt(0, sizeof(OTVoice)-1)]);
                    EmitSoundToAll(OTAlerting);
                }
            }

            if(GetGameState() == Game_None)
            {
                controlpointIndex = FindEntityByClassname(controlpointIndex, "team_control_point");

                if(IsValidEntity(controlpointIndex))
                {
                    SetGameState(Game_ControlPoint);
                    timeleft = 90.0;
                    CPrintToChatAll("{olive}[FF2]{default} 서든데스가 시작되었습니다! 점령지점을 장악하면 승리!");
                    PrintHintTextToAll("서든데스가 시작되었습니다! \n점령지점을 장악하면 승리!");

                    // SetArenaCapEnableTime(0.0);
            		SetControlPoint(true);
                }
                else
                    SetGameState(Game_SuddenDeath);
            }


            if(GetGameState() == Game_SuddenDeath)
            {
                /*
                int loser=GetLowestDamagePlayer();
                int damage = (FF2_GetClientDamage(loser) / 20) / 10;
                suddendeathDamege += damage > 2 ? damage : 2;

                timeleft += 30.0 + (damage*3); // 게임이 중단되는것을 막는 용.
                ForcePlayerSuicide(loser);
                */
                static bool alreadyNotice = false;
                int loser=GetLowestDamagePlayer();
                FF2_SetClientGlow(loser, 99999.9);
                timeleft += 30.0;
                suddendeathDamege = CheckAlivePlayers();

                CPrintToChatAll("{olive}[FF2]{default} {red}%N{default}님이 {olive}데미지가 가장 낮아{default} 발각됩니다.\n({orange}데미지: %i{default})", loser, suddendeathDamege);

                if(!alreadyNotice)
                {
                    alreadyNotice = true;

                    CPrintToChatAll("{olive}[FF2]{default} {red}서든데스{default}가 시작되었습니다! \n보스는 생존한 플레이어의 수에 비례해 데미지를 입습니다!");
                    PrintHintTextToAll("서든데스가 시작되었습니다! \n보스는 생존한 플레이어의 수에 비례해 데미지를 입습니다!");
                }
                return Plugin_Continue;
            }

            if(GetGameState() == Game_AttackAndDefense)
            {
                CPrintToChatAll("{olive}[FF2]{default} 보스가 살아남아 승리합니다.");
                ForceTeamWin(FF2_GetBossTeam());
                return Plugin_Stop;
            }
      		return Plugin_Continue;
  		}

    }

    return Plugin_Continue;
}

public void StatusTimer(int client)
{
    if(!IsPlayerAlive(client)) return;

    if(NoEnemyTime[client] > GetGameTime())
    {
        for(int target = 1; target <= MaxClients; target++)
        {
            if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(client) != GetClientTeam(target))
            {
                float pos[3];
                float enemyPos[3];

                GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
                GetEntPropVector(target, Prop_Send, "m_vecOrigin", enemyPos);

                if(GetVectorDistance(pos, enemyPos) <= 250.0)
                {
                    PushClientsApart(target, client);

                    if(TF2_IsPlayerInCondition(client, TFCond_Taunting))
                        TF2_RemoveCondition(client, TFCond_Taunting);

                    PrintCenterText(target, "라스트맨에게 잠시만 시간을 주세요!");
                }
            }
        }
    }
    else if(GetGameState() == Game_LastManStanding && NoEnemyTime[client] <= GetGameTime())
    {
        if(IsAFK[client])
        {
            NoEnemyTime[client] = GetGameTime() + 0.1;
            PassLastMan(client);
            IsAFK[client] = false;
        }
    }

    if(WeaponCannotUseTime[client] > GetGameTime())
    {
        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

        if(IsValidEntity(weapon))
        {
            SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime() + 0.03);
            SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime() + 0.03);
            SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime() + 0.03);
        }
    }
    else if(WeaponCannotUseTime[client] != -1.0)
    {
        WeaponCannotUseTime[client] = -1.0;
        SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);

        if(IsPlayerStuck(client))
        {
            TF2_RespawnPlayer(client);
            PrintCenterText(client, "이런! 끼는 자리에 있어서 부활시켰습니다!");
        }
    }

    return;
}

public Action BeLastMan(Handle timer, Handle LastManData)
{
    if(!LastManData || !IsPackReadable(LastManData, 0))
    {
      Debug("LastManData is invalid! what!?!?");
      return Plugin_Continue;
    }

    int needData = ReadPackCell(LastManData);
    int winner = ReadPackCell(LastManData);

    TF2_RespawnPlayer(winner);
    // Debug("BeLastMan => EnableLastManStanding");
    EnableLastManStanding(winner, false);

    if(needData > 0)
    {
        int client = ReadPackCell(LastManData);
        TFTeam team = view_as<TFTeam>(ReadPackCell(LastManData));
        bool alive = ReadPackCell(LastManData);

        if(alive)
        {
            TF2_ChangeClientTeam(client, team);
        }
        else
        {
            TF2_ChangeClientTeam(client, TFTeam_Spectator);
            TF2_ChangeClientTeam(client, view_as<TFTeam>(team));
            if(IsPlayerAlive(client))
            {
                ForcePlayerSuicide(client);
            }

        }
    }
    return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
    if(FF2_GetRoundState() == 1)
    {
        IsLastMan[client] = false;
        AlreadyLastmanSpawned[client] = false;

        WeaponCannotUseTime[client] = -1.0;
        NoEnemyTime[client] = 0.0;

        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHook(client, SDKHook_PreThinkPost, StatusTimer);
    }
}

public void OnClientDisconnect(int client)
{
    if(GetGameState() == Game_LastManStanding && IsLastMan[client])
    {
        PassLastMan(client);
    }
    if(IsLastMan[client] || IsBoss(client))
    {
        IsLastMan[client] = false;
        AlreadyLastmanSpawned[client] = false;

        WeaponCannotUseTime[client] = -1.0;
        NoEnemyTime[client] = 0.0;

        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKUnhook(client, SDKHook_PreThinkPost, StatusTimer);
    }
}


public Action FF2_OnMusic(char path[PLATFORM_MAX_PATH], float &time, float &volume, char artist[80], char name[100], bool &notice, int client, int selected)
{
    IsSnowStorm[client] = false;
    bool Changed = false;

    if(GetGameState() == Game_LastManStanding && BGMCount)
    {
        int random=GetRandomInt(1, BGMCount);
        char tempItem[35];
        char tempPath[PLATFORM_MAX_PATH];
        char tempArtist[80];
        char tempName[100];

        if(MusicKV && !selected)
        {
            Changed = true;

            KvRewind(MusicKV);
            if(KvJumpToKey(MusicKV, "sound_bgm"))
            {
              Format(tempItem, sizeof(tempItem), "time%i", random);
              time = KvGetFloat(MusicKV, tempItem);

              Format(tempPath, sizeof(tempPath), "path%i", random);
              KvGetString(MusicKV, tempPath, tempPath, sizeof(tempPath));
              Format(path, sizeof(path), "%s", tempPath);

              Format(tempArtist, sizeof(tempArtist), "artist%i", random);
              KvGetString(MusicKV, tempArtist, tempArtist, sizeof(tempArtist));
              Format(artist, sizeof(artist), "%s", tempArtist);

              Format(tempName, sizeof(tempName), "name%i", random);
              KvGetString(MusicKV, tempName, tempName, sizeof(tempName));
              Format(name, sizeof(name), "%s", tempName);

              Format(tempItem, sizeof(tempItem), "volume%i", random);
              volume=KvGetFloat(MusicKV, tempItem, 1.0);
            }
        }

        if(StrEqual(name, "snow storm -euphoria-"))
            IsSnowStorm[client] = true;
     }
     else if(GetGameState() == Game_SpecialLastManStanding && SpecialBGMCount)
     {
         int random=GetRandomInt(1, BGMCount);
         char tempItem[35];
         char tempPath[PLATFORM_MAX_PATH];
         char tempArtist[80];
         char tempName[100];

         KvRewind(MusicKV);
         if(MusicKV && !selected)
         {
             Changed = true;

             KvRewind(MusicKV);
             if(KvJumpToKey(MusicKV, "sound_special_bgm"))
             {
               Format(tempItem, sizeof(tempItem), "time%i", random);
               time = KvGetFloat(MusicKV, tempItem);

               Format(tempPath, sizeof(tempPath), "path%i", random);
               KvGetString(MusicKV, tempPath, tempPath, sizeof(tempPath));
               Format(path, sizeof(path), "%s", tempPath);

               Format(tempArtist, sizeof(tempArtist), "artist%i", random);
               KvGetString(MusicKV, tempArtist, tempArtist, sizeof(tempArtist));
               Format(artist, sizeof(artist), "%s", tempArtist);

               Format(tempName, sizeof(tempName), "name%i", random);
               KvGetString(MusicKV, tempName, tempName, sizeof(tempName));
               Format(name, sizeof(name), "%s", tempName);

               Format(tempItem, sizeof(tempItem), "volume%i", random);
               volume=KvGetFloat(MusicKV, tempItem, 1.0);
             }
         }
     }
     return Changed ? Plugin_Changed : Plugin_Continue;
}

stock int FindAnotherPerson(int Gclient)
{
    int count;
    int validTarget[MAXPLAYERS+1];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && client != Gclient && !IsBossTeam(client) && !IsPlayerAlive(client))
        {
            validTarget[count++]=client;
        }
    }

    if(!count)
    {
        return 0;
    }
    return validTarget[GetRandomInt(0, count-1)];
}

stock void GiveLastManWeapon(int client)
{
  TF2_RemoveAllWeapons(client);

  switch(TF2_GetPlayerClass(client))
  {
    case TFClass_Scout:
    {
      SpawnWeapon(client, "tf_weapon_scattergun", 200, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.6 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_pistol", 209, 0, 2, "2 ; 1.5 ; 97 ; 0.5 ; 6 ; 0.5");
      SpawnWeapon(client, "tf_weapon_bat", 30667, 0, 2, "2 ; 4.0 ; 112 ; 1.0 ; 26 ; 150");
      // 2: 피해량 향상
      // 97: 재장전 향상
      // 6: 발사 속도 향상
    }
    case TFClass_Sniper:
    {
      SpawnWeapon(client, "tf_weapon_sniperrifle", 201, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.5 ; 390 ; 3.0");
      SpawnWeapon(client, "tf_weapon_smg", 203, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 2.5 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_club", 264, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 4.0 ; 112 ; 1.0 ; 26 ; 150");
      // 390: 헤드샷 보너스 데미지
    }
    case TFClass_Soldier:
    {
      SpawnWeapon(client, "tf_weapon_rocketlauncher", 205, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 2.5 ; 6 ; 0.4 ; 97 ; 0.4 ; 103 ; 1.2 ; 135 ; 1.3 ; 488 ; 1.0 ; 521 ; 2.0");
      SpawnWeapon(client, "tf_weapon_shotgun_soldier", 15016, 0, 2, "2 ; 2.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_shovel", 416, 0, 2, "2 ; 4.0 ; 112 ; 1.0 ; 26 ; 150");
      // 103: 투사체 비행속도 향상
      // 135: 로켓점프 피해량 감소
      // 488: 로켓 특화
      // 521: 연기
    }
    case TFClass_DemoMan:
    {
      SpawnWeapon(client, "tf_weapon_grenadelauncher", 206, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.6 ; 671 ; 1.0 ; 103 ; 1.3 ; 135 ; 1.3 ; 6 ; 0.4 ; 97 ; 0.7");
      SpawnWeapon(client, "tf_weapon_pipebomblauncher", 207, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.6 ; 6 ; 0.4 ; 97 ; 0.7");
      SpawnWeapon(client, "tf_weapon_sword", 132, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 2.2 ; 540 ; 1.0 ; 97 ; 0.4 ; 6 ; 0.4 ; 112 ; 1.0 ; 26 ; 150");
      // 540:아이랜더 효과로 추정됨..
      //changeMelee=false;
    }
    case TFClass_Medic: //
    {
      SpawnWeapon(client, "tf_weapon_crossbow", 305, 0, 2, "2 ; 1.6 ; 17 ; 0.25 ; 4 ; 8.0 ; 6 ; 0.4 ; 97 ; 0.4");
      SpawnWeapon(client, "tf_weapon_medigun", 211, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 482 ; 4.0 ; 493 ; 8.0");
      SpawnWeapon(client, "tf_weapon_bonesaw", 1071, 0, 2, "2 ; 4.0 ; 17 ; 0.40 ; 112 ; 1.0 ; 26 ; 150 ; 107 ; 1.10");
      // 17: 적중 시 우버차지
      // 482: 오버힐 마스터리
      // 493: 힐 마스터리
      // 107: 이동속도
    }
    case TFClass_Heavy:
    {
      SpawnWeapon(client, "tf_weapon_minigun", 202, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.8 ; 87 ; 0.3 ; 6 ; 1.1");
      SpawnWeapon(client, "tf_weapon_shotgun_hwg", 15016, 0, 2, "2 ; 2.3 ; 87 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_fists", 1071, 0, 2, "2 ; 4.0 ; 112 ; 1.0 ; 26 ; 150");
      // 87: 미니건 돌리는 속도 증가
      //
    }
    case TFClass_Pyro:
    {
      SpawnWeapon(client, "tf_weapon_flamethrower", 208, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0");
      SpawnWeapon(client, "tf_weapon_shotgun_pyro", 15016, 0, 2, "2 ; 2.2 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_fireaxe", 38, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.6 ; 178 ; 0.2 ; 112 ; 1.0 ; 26 ; 150");
      //changeMelee=false;
      // 178: 무기 바꾸는 속도 향상
    }
    case TFClass_Spy:
    {
      SpawnWeapon(client, "tf_weapon_revolver", 61, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.5 ; 51 ; 1.0 ; 390 ; 5.0");
      SpawnWeapon(client, "tf_weapon_knife", 194, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 112 ; 1.0 ; 26 ; 150 ; 107 ; 1.10");
      int sapper = SpawnWeapon(client, "tf_weapon_sapper", 735, 0, 2, _);

      SetEntProp(sapper, Prop_Send, "m_iObjectType", 3);
      SetEntProp(sapper, Prop_Data, "m_iSubType", 3);
      SetEntProp(sapper, Prop_Send, "m_aBuildableObjectTypes", 0, _, 0);
      SetEntProp(sapper, Prop_Send, "m_aBuildableObjectTypes", 0, _, 1);
      SetEntProp(sapper, Prop_Send, "m_aBuildableObjectTypes", 0, _, 2);
      SetEntProp(sapper, Prop_Send, "m_aBuildableObjectTypes", 1, _, 3);

      SpawnWeapon(client, "tf_weapon_invis", 30, 0, 2, "35 ; 1.8");
      // 51: 헤드샷 판정 가능
    }
    case TFClass_Engineer:
    {
      SpawnWeapon(client, "tf_weapon_sentry_revenge", 141, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.6 ; 97 ; 0.4 ; 6 ; 0.4 ; 136 ; 1.0");
      SpawnWeapon(client, "tf_weapon_wrench", 197, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 124 ; 1.0 ; 343 ; 0.2 ; 344 ; 1.3 ; 464 ; 3.0 ; 112 ; 100.0 ; 286 ; 5.0 ; 287 ; 1.5 ; 80 ; 8.0 ; 26 ; 150");
      SpawnWeapon(client, "tf_weapon_laser_pointer", 140, 0, 2, _);
      SpawnWeapon(client, "tf_weapon_pda_engineer_build", 25, 0, 2, "351 ; 100.0 ; 344 ; 100.0 ; 345 ; 6.0");
      int pda = SpawnWeapon(client, "tf_weapon_builder", 28, 0, 2, _);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
      SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 0, 2, _);
      //changeMelee=false;
      // 113: 금속 리젠
      // 80: 최대 금속량
      // 124: 미니 센트리 설정
      // 136: 센트리 복수
      // 286: 건물 체력
      // 287: 센트리 공격력
      // 343: 센트리 발사 속도
      // 344: 센트리 사정 거리
      // 464: 센트리 짓는 속도
    }
  }
/*  if(changeMelee)
    SpawnWeapon(client, "tf_weapon_bottle", 1071, 0, 1, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 4.0");
*/

}

void PrecacheMusic()
{
  char config[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, config, sizeof(config), "configs/ff2_lastman.cfg");

  if(!FileExists(config))
  {
    return;
  }
  if(MusicKV == INVALID_HANDLE)
  {
    BGMCount = 0;
    MusicKV = CreateKeyValues("lastmanstanding");
    FileToKeyValues(MusicKV, config);
    KvRewind(MusicKV);

    if(!KvJumpToKey(MusicKV, "sound_bgm"))
    {
      LogMessage("No BGM found!");
      return;
    }

    char path[PLATFORM_MAX_PATH];
    char item[20];

    for(int i=1; ; i++)
    {
      Format(item, sizeof(item), "path%i", i);
      KvGetString(MusicKV, item, path, sizeof(path), "");

      if(!path[0]) break;

      char temp[PLATFORM_MAX_PATH];
      Format(temp, sizeof(temp), "sound/%s", path);

      if(!FileExists(temp, true))
      {
        LogMessage("파일이 감지되지 않아 path%i에서 검색을 멈췄습니다.", BGMCount);
        break;
      }
      AddFileToDownloadsTable(temp);
      PrecacheSound(path, true);

      BGMCount++;
    }

    KvRewind(MusicKV);

    if(!KvJumpToKey(MusicKV, "sound_special_bgm"))
    {
      LogMessage("No sound_special_bgm found!");
      return;
    }

    for(int i=1; ; i++)
    {
      Format(item, sizeof(item), "path%i", i);
      KvGetString(MusicKV, item, path, sizeof(path), "");

      if(!path[0]) break;

      char temp[PLATFORM_MAX_PATH];
      Format(temp, sizeof(temp), "sound/%s", path);

      if(!FileExists(temp, true))
      {
        LogMessage("파일이 감지되지 않아 path%i에서 검색을 멈췄습니다.", BGMCount);
        break;
      }
      AddFileToDownloadsTable(temp);
      PrecacheSound(path, true);

      SpecialBGMCount++;
    }
  }
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute="")
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	int entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

stock int CheckAlivePlayers() // Without bosses. LOL
{
    int alive=0;

    for(int i=1; i<=MaxClients; i++)
    {
        if(IsValidClient(i) && IsPlayerAlive(i) && FF2_GetBossTeam() != GetClientTeam(i))
            alive++;
    }

    return alive;
}

stock int GetIndexOfWeaponSlot(int client, int slot)
{
	int weapon=GetPlayerWeaponSlot(client, slot);
	return (weapon>MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex") : -1);
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

stock PushClientsApart(int iClient1, int iClient2) // Copied from Chdata's Fixed Friendly Fire
{
    // SetEntProp(iClient1, Prop_Send, "m_CollisionGroup", 2);     // No collision with players and certain projectiles
    // SetEntProp(iClient2, Prop_Send, "m_CollisionGroup", 2);

    float vVel[3];

    float vOrigin1[3];
    float vOrigin2[3];

    GetEntPropVector(iClient1, Prop_Send, "m_vecOrigin", vOrigin1);
    GetEntPropVector(iClient2, Prop_Send, "m_vecOrigin", vOrigin2);

    MakeVectorFromPoints(vOrigin1, vOrigin2, vVel);
    NormalizeVector(vVel, vVel);
    ScaleVector(vVel, -300.0);               // Set to 15.0 for a black hole effect

    vVel[1] += 0.1;                         // This is just a safeguard for sm_tele
    vVel[2] = 0.0;                          // Negate upwards push. += 280.0; for extra upwards push (can have sort of a fan/vent effect)

    new iBaseVelocityOffset = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");
    SetEntDataVector(iClient1, iBaseVelocityOffset, vVel, true);
}

// Copied from FF2

stock void ForceTeamWin(int team)
{
	new entity=FindEntityByClassname2(-1, "team_control_point_master");
	if(!IsValidEntity(entity))
	{
		entity=CreateEntityByName("team_control_point_master");
		DispatchSpawn(entity);
		AcceptEntityInput(entity, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(entity, "SetWinner");
}

stock int FindEntityByClassname2(startEnt, const char[] classname)
{
	while(startEnt>-1 && !IsValidEntity(startEnt))
	{
		startEnt--;
	}
	return FindEntityByClassname(startEnt, classname);
}

stock int GetLowestDamagePlayer() //
{
  int targetCount=0;
  int targetList[MAXPLAYERS+1];
  int lowestTarget;
  bool enableTargetList=false;

  for (int z = 1; z <= GetMaxClients(); z++)
  {
    if (IsClientInGame(z) && IsPlayerAlive(z) && GetClientTeam(z) != FF2_GetBossTeam() && FF2_GetClientDamage(z) <= (lowestTarget==0 ? 50000 : FF2_GetClientDamage(lowestTarget)))
    {
      if(lowestTarget && FF2_GetClientDamage(z) == FF2_GetClientDamage(lowestTarget)){
        enableTargetList=true;
        targetList[targetCount++]=z;
        continue;
      }

      lowestTarget=z;
    }
  }

  return enableTargetList ? targetList[GetRandomInt(0, targetCount-1)] : lowestTarget;
}

public void GetEyeEndPos(int client, float max_distance, float endPos[3])
{
	if(IsClientInGame(client))
	{
		if(max_distance<0.0)
			max_distance=0.0;
		float PlayerEyePos[3];
		float PlayerAimAngles[3];
		GetClientEyePosition(client,PlayerEyePos);
		GetClientEyeAngles(client,PlayerAimAngles);
		float PlayerAimVector[3];
		GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
		if(max_distance>0.0){
			ScaleVector(PlayerAimVector,max_distance);
		}
		else{
			ScaleVector(PlayerAimVector,3000.0);
		}
        AddVectors(PlayerEyePos,PlayerAimVector,endPos);
	}
}

int AttachParticle(int entity, char[] particleType, bool attach=true)
{
	int particle=CreateEntityByName("info_particle_system");

	char targetName[128];
    float position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	TeleportEntity(particle, position, NULL_VECTOR, NULL_VECTOR);

	Format(targetName, sizeof(targetName), "target%i", entity);
	DispatchKeyValue(entity, "targetname", targetName);

	DispatchKeyValue(particle, "targetname", "tf2particle");
	DispatchKeyValue(particle, "parentname", targetName);
	DispatchKeyValue(particle, "effect_name", particleType);
	DispatchSpawn(particle);
	SetVariantString(targetName);
	if(attach)
	{
		AcceptEntityInput(particle, "SetParent", particle, particle, 0);
		SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", entity);
	}
    else
    {
        SetEntPropEnt(particle, Prop_Send, "m_hOwnerEntity", 0);
    }
	ActivateEntity(particle);
	AcceptEntityInput(particle, "start");
	return particle;
} //

bool IsWeaponSlotActive(int iClient, int iSlot)
{
    int hActive = GetEntPropEnt(iClient, Prop_Send, "m_hActiveWeapon");
    int hWeapon = GetPlayerWeaponSlot(iClient, iSlot);
    return (hWeapon == hActive);
}

bool ResizeTraceFailed;

public bool TryTeleport(clientIdx) // Copied from sarysa's code.
{
	new Float:sizeMultiplier = GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale");
	static Float:startPos[3];
	static Float:endPos[3];
	static Float:testPos[3];
	static Float:eyeAngles[3];
	GetClientEyePosition(clientIdx, startPos);
	GetClientEyeAngles(clientIdx, eyeAngles);
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceAnything);
	TR_GetEndPosition(endPos);

	// don't even try if the distance is less than 82
	new Float:distance = GetVectorDistance(startPos, endPos);
	if (distance < 82.0)
	{
		return false;
	}

	if (distance > 1500.0)
		constrainDistance(startPos, endPos, distance, 1500.0);
	else // shave just a tiny bit off the end position so our point isn't directly on top of a wall
		constrainDistance(startPos, endPos, distance, distance - 1.0);

	// now for the tests. I go 1 extra on the standard mins/maxs on purpose.
	new bool:found = false;
	for (new x = 0; x < 3; x++)
	{
		if (found)
			break;

		new Float:xOffset;
		if (x == 0)
			xOffset = 0.0;
		else if (x == 1)
			xOffset = 12.5 * sizeMultiplier;
		else
			xOffset = 25.0 * sizeMultiplier;

		if (endPos[0] < startPos[0])
			testPos[0] = endPos[0] + xOffset;
		else if (endPos[0] > startPos[0])
			testPos[0] = endPos[0] - xOffset;
		else if (xOffset != 0.0)
			break; // super rare but not impossible, no sense wasting on unnecessary tests

		for (new y = 0; y < 3; y++)
		{
			if (found)
				break;

			new Float:yOffset;
			if (y == 0)
				yOffset = 0.0;
			else if (y == 1)
				yOffset = 12.5 * sizeMultiplier;
			else
				yOffset = 25.0 * sizeMultiplier;

			if (endPos[1] < startPos[1])
				testPos[1] = endPos[1] + yOffset;
			else if (endPos[1] > startPos[1])
				testPos[1] = endPos[1] - yOffset;
			else if (yOffset != 0.0)
				break; // super rare but not impossible, no sense wasting on unnecessary tests

			for (new z = 0; z < 3; z++)
			{
				if (found)
					break;

				new Float:zOffset;
				if (z == 0)
					zOffset = 0.0;
				else if (z == 1)
					zOffset = 41.5 * sizeMultiplier;
				else
					zOffset = 83.0 * sizeMultiplier;

				if (endPos[2] < startPos[2])
					testPos[2] = endPos[2] + zOffset;
				else if (endPos[2] > startPos[2])
					testPos[2] = endPos[2] - zOffset;
				else if (zOffset != 0.0)
					break; // super rare but not impossible, no sense wasting on unnecessary tests

				// before we test this position, ensure it has line of sight from the point our player looked from
				// this ensures the player can't teleport through walls
				static Float:tmpPos[3];
				TR_TraceRayFilter(endPos, testPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceAnything);
				TR_GetEndPosition(tmpPos);
				if (testPos[0] != tmpPos[0] || testPos[1] != tmpPos[1] || testPos[2] != tmpPos[2])
					continue;

				// now we do our very expensive test. thankfully there's only 27 of these calls, worst case scenario.
				found = IsSpotSafe(clientIdx, testPos, sizeMultiplier);
			}
		}
	}

	if (!found)
	{
		return false;
	}
	TeleportEntity(clientIdx, testPos, NULL_VECTOR, NULL_VECTOR);

	return true;
}

stock void constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

public bool IsSpotSafe(clientIdx, float playerPos[3], float sizeMultiplier)
{
	ResizeTraceFailed = false;
	static Float:mins[3];
	static Float:maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;

	return true;
}

bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset)
{
	static Float:tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static Float:targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;

	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	return true;
}

bool Resize_TestSquare(const float bossOrigin[3], float xmin, float xmax, float ymin, float ymax, float zOffset)
{
	static Float:pointA[3];
	static Float:pointB[3];
	for (new phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (new shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}

	return true;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3])
{
	static Float:result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceAnything);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}

	return true;
}

//Copied from Chdata's Fixed Friendly Fire
stock bool IsPlayerStuck(int ent)
{
    float vecMin[3];
	float vecMax[3];
	float vecOrigin[3];

    GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, ent);
    return (TR_DidHit());
}

stock void RemovePlayerTarge(int client)
{
	int entity = MaxClients+1;
	while((entity = FindEntityByClassname2(entity, "tf_wearable_demoshield")) != -1)
	{
		int index = GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
		if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") == client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			if(index==131 || index==406 || index==1099 || index==1144)  //Chargin' Targe, Splendid Screen, Tide Turner, Festive Chargin' Targe
			{
				TF2_RemoveWearable(client, entity);
			}
		}
	}
}

stock void RemovePlayerBack(int client, int[] indices, int length)
{
	if(length<=0)
	{
		return;
	}

	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable"))
		{
			int index=GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex");
			if(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
			{
				for(int i; i<length; i++)
				{
					if(index==indices[i])
					{
						TF2_RemoveWearable(client, entity);
					}
				}
			}
		}
	}
}

stock int FindPlayerBack(int client, int index)
{
	int entity=MaxClients+1;
	while((entity=FindEntityByClassname2(entity, "tf_wearable"))!=-1)
	{
		char netclass[32];
		if(GetEntityNetClass(entity, netclass, sizeof(netclass)) && StrEqual(netclass, "CTFWearable") && GetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex")==index && GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")==client && !GetEntProp(entity, Prop_Send, "m_bDisguiseWearable"))
		{
			return entity;
		}
	}
	return -1;
}

stock int OnlyParisLeft()
{
	int scouts;
	int BossTeam = FF2_GetBossTeam();

	for(int client=0; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsPlayerAlive(client) && GetClientTeam(client) != BossTeam)
		{
			if(TF2_GetPlayerClass(client) == TFClass_Scout
			|| (TF2_GetPlayerClass(client) == TFClass_Soldier && GetIndexOfWeaponSlot(client, TFWeaponSlot_Primary) == 237)
			|| (TF2_GetPlayerClass(client) == TFClass_Spy && (TF2_IsPlayerInCondition(client, TFCond_Cloaked) || TF2_IsPlayerInCondition(client, TFCond_Stealthed)))
			)
			{
				scouts++;
			}
			else
			{
				return 0;
			}
		}
	}
	return scouts;
}

GameMode GetGameState()
{
    return CurrentGame;
}

void SetGameState(GameMode gamemode)
{
    CurrentGame = gamemode;

    if(gamemode == Game_AttackAndDefense)
    {
        if(timeleft <= 0.0)
        {
            DrawGameTimer = CreateTimer(0.1, OnTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
        }
        timeleft = float(CheckAlivePlayers() * 21) + 45.0;
    }
}

public bool TraceRayPlayerOnly(int iEntity, int iMask, any iData)
{
    return (IsValidClient(iEntity) && IsValidClient(iData) && iEntity != iData);
}

public Native_EnablePlayerLastmanStanding(Handle plugin, numParams)
{
    int client =  GetNativeCell(1);

    if(GetGameState() != Game_LastManStanding)
        IsFakeLastManStanding = true;

    // Debug("Native_EnablePlayerLastmanStanding => EnableLastManStanding");
    EnableLastManStanding(client, !IsPlayerAlive(client));
}

public Native_GetGameState(Handle plugin, numParams)
{
    return _:GetGameState();
}

public Native_SetGameState(Handle plugin, numParams)
{
    SetGameState(view_as<GameMode>(GetNativeCell(1)));
}

public Native_GetTimeLeft(Handle plugin, numParams)
{
    if(DrawGameTimer != INVALID_HANDLE)
        return _:timeleft;

    return _:0.0;
}

public Native_SetTimeLeft(Handle plugin, numParams)
{
    timeleft = GetNativeCell(1);
    if(DrawGameTimer == INVALID_HANDLE)
    {
        DrawGameTimer = CreateTimer(0.1, OnTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
    }
}

stock SetControlPoint(bool:enable)
{
    new controlPoint=MaxClients+1;
    while((controlPoint=FindEntityByClassname2(controlPoint, "team_control_point"))!=-1)
    {
        if(controlPoint>MaxClients && IsValidEdict(controlPoint))
        {
            AcceptEntityInput(controlPoint, (enable ? "ShowModel" : "HideModel"));
            SetVariantInt(enable ? 0 : 1);
            AcceptEntityInput(controlPoint, "SetLocked");
        }
    }
}


public Native_IsLastMan(Handle plugin, numParams)
{
    return IsLastMan[GetNativeCell(1)];
} //

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <tf2attributes>
#include <morecolors>
#include <freak_fortress_2>
#tryinclude <POTRY>

bool IsLastManStanding=false;
bool IsLastMan[MAXPLAYERS+1];

int top[3];
// int lastmanClientIndex;
int BGMCount;

Handle MusicKV;
Handle LastManData;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Deathmatch Mod",
    author="Nopied",
    description="....",
    version="0.1",
};

public void OnPluginStart()
{
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
    HookEvent("arena_round_start", OnRoundStart);
    HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Pre);
    //HookEvent("teamplay_win_panel", OnRoundEnd, EventHookMode_Pre);
    // TODO: pass 커맨드 구현.

    LoadTranslations("freak_fortress_2");
}

public void OnMapStart()
{
  if(MusicKV != INVALID_HANDLE)
  {
    CloseHandle(MusicKV);
    MusicKV=INVALID_HANDLE;
  }
  PrecacheMusic();
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    int client=GetClientOfUserId(GetEventInt(event, "userid"));

    if(FF2_GetRoundState() == 1 && IsLastManStanding && IsClientInGame(lastmanClientIndex) && !IsLastMan[client])
    {
        // Debug("Spawn %N", client);
        CreateTimer(0.1, BeLastMan);
    }
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    IsLastManStanding=false;
    // FF2_SetServerFlags(FF2_GetServerFlags()|~FF2SERVERFLAG_ISLASTMAN|~FF2SERVERFLAG_UNCHANGE_BGM_USER|~FF2SERVERFLAG_UNCHANGE_BGM_SERVER);
}


public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
    for(int client=1; client<=MaxClients; client++)
    {
        if(IsLastMan[client] || IsBoss(client)) // Lastmax and bosses.
        {
            IsLastMan[client]=false;

            SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        }
    }

    return Plugin_Continue;
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
    if(!IsLastManStanding || FF2_GetRoundState() != 1)
    {
        SDKUnhook(victim, SDKHook_OnTakeDamage, OnTakeDamage);
        return Plugin_Continue;
    }
    if(IsBoss(attacker) || !IsBoss(victim)) return Plugin_Continue;

    if(IsValidEntity(weapon))
    {
        int boss=FF2_GetBossIndex(victim);
        char classname[60];
        GetEntityClassname(weapon, classname, sizeof(classname));

        if(!StrContains(classname, "tf_weapon_knife") && !(damagetype & TF_CUSTOM_BACKSTAB))
        {
            damagetype|=DMG_CRIT;
            damage=((float(FF2_GetBossMaxHealth(boss))*float(FF2_GetBossMaxLives(boss)))*0.06)/3.0;

            EmitSoundToClient(client, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
            EmitSoundToClient(attacker, "player/spy_shield_break.wav", _, _, _, _, 0.7, _, _, position, _, false);
            EmitSoundToClient(client, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
            EmitSoundToClient(attacker, "player/crit_received3.wav", _, _, _, _, 0.7, _, _, _, _, false);
            SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+2.0);
            SetEntPropFloat(attacker, Prop_Send, "m_flNextAttack", GetGameTime()+2.0);
            SetEntPropFloat(attacker, Prop_Send, "m_flStealthNextChangeTime", GetGameTime()+2.0);

            int viewmodel=GetEntPropEnt(attacker, Prop_Send, "m_hViewModel");
            if(viewmodel>MaxClients && IsValidEntity(viewmodel) && TF2_GetPlayerClass(attacker)==TFClass_Spy)
            {
                int melee=GetIndexOfWeaponSlot(attacker, TFWeaponSlot_Melee);
                int animation=41;
                switch(melee)
                {
                    case 225, 356, 423, 461, 574, 649, 1071:  //Your Eternal Reward, Conniver's Kunai, Saxxy, Wanga Prick, Big Earner, Spy-cicle, Golden Frying Pan
                    {
                        animation=15;
                    }
                    case 638:  //Sharp Dresser
                    {
                        animation=31;
                    }
                }
                SetEntProp(viewmodel, Prop_Send, "m_nSequence", animation);
            }

            char playerName[64];
            char bossName[64];
            GetClientName(attacker, playerName, sizeof(playerName));
            KvRewind(BossKV[Special[boss]]);
            KvGetString(BossKV[Special[boss]], "name", bossName, sizeof(bossName), "ERROR NAME");

            CPrintToChatAll("{olive}[FF2]{default} %t", "Someone_do", playerName, "페이스스탭", bossName, RoundFloat(damage*(255.0/85.0)));
            return Plugin_Changed;
        }
        else if(!StrContains(classname, "tf_weapon_shotgun") && TF2_GetPlayerClass(attacker) == TFClass_Soldier)
        {
            float bossPosition[3];
            GetEntPropVector(victim, Prop_Send, "m_vecOrigin", bossPosition);
            int explosion=CreateEntityByName("env_explosion");

            DispatchKeyValueFloat(explosion, "DamageForce", 180.0);

			SetEntProp(explosion, Prop_Data, "m_iMagnitude", 280, 4);
			SetEntProp(explosion, Prop_Data, "m_iRadiusOverride", 200, 4);
			SetEntPropEnt(explosion, Prop_Data, "m_hOwnerEntity", client);

			DispatchSpawn(explosion);

/*			if(!(GetEntityFlags(victim) & FL_ONGROUND))
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(-150, 150);
			}
			else
			{
				explosionPosition[2]=bossPosition[2]+GetRandomInt(0,100);
			}/*/ // TODO: if it need....
			TeleportEntity(explosion, bossPosition, NULL_VECTOR, NULL_VECTOR);
			AcceptEntityInput(explosion, "Explode");
			AcceptEntityInput(explosion, "kill");
        }
        else if(!StrContains(classname, "tf_weapon_shotgun") && TF2_GetPlayerClass(attacker) == TFClass_Pyro)
        {
            TF2_IgnitePlayer(victim, attacker);
        }
    }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    if(FF2_GetRoundState() != 1 || IsBossTeam(GetClientOfUserId(GetEventInt(event, "userid"))) || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        return Plugin_Continue;

    if(!IsLastManStanding && CheckAlivePlayers() <= 1) // 라스트 맨 스탠딩
    {
        IsLastManStanding=true;
        StartMusic(); // Call FF2_OnMusic
        // FF2_SetServerFlags(FF2_GetServerFlags()|FF2SERVERFLAG_ISLASTMAN|FF2SERVERFLAG_UNCHANGE_BGM);
        enabled=true;
        int bosses[MAXPLAYERS+1];
        int topDamage[3];
        int totalDamage;
        int bossCount;
        // bool valid[3];

        for(int client=1; client<=MaxClients; client++)
        {
          if(!IsValidClient(client)) // for bossCount.
      			continue;
          else if(IsBoss(client) && IsPlayerAlive(client)){
            bosses[bossCount++]=client;
            continue;
          }
          else if(IsBossTeam(client)) // FF2_GetClientDamage(client)<=0 ||
            continue;

          if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[0]))
      		{
      			top[2]=top[1];
      			top[1]=top[0];
      			top[0]=client;
      		}
      		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[1]))
      		{
      			top[2]=top[1];
      			top[1]=client;
      		}
      		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[2]))
      		{
      			top[2]=client;
      		}
        }

        char temp[3][60];

        for(int i; i<3; i++)
        {
            topDamage[i]=FF2_GetClientDamage(top[i]);
            // valid[i]=IsValidClient(top[i]) && topDamage[i]>0;

            /*
            for(int x=i-1; x>=0; x--)
            {
              if(top[i] == top[x]){
                valid[i]=false;
                break;
              }
            }
            */

            totalDamage+=topDamage[i];
        }

        int random=GetRandomInt(0, totalDamage);
        int winner;

        for(int i; i<3; i++) // OH this stupid code..
        {
            int tempDamage;
            for (int x=i; x>=0; x--)
            {
                tempDamage+=FF2_GetClientDamage(top[x]);
            }

            Format(temp[i], sizeof(temp[]), "%N - %.2f%%", top[i], float(FF2_GetClientDamage(top[i]))/float(totalDamage)*100.0);

            if(random > tempDamage)
                continue;
            winner=top[i];
            break;
        }

        CPrintToChatAll("{olive}[FF2]{default} 확률: %s | %s | %s",
        temp[0],
        temp[1],
        temp[2]);
        CPrintToChatAll("%N님이 {red}강력한 무기{default}를 흭득하셨습니다!",
        winner);

        for(int i; i<bossCount; i++)
        {
            int boss=FF2_GetBossIndex(bosses[i]);
            int newhealth=10000/bossCount;

            if(FF2_GetBossHealth(boss) < newhealth){
                FF2_SetBossMaxHealth(boss, newhealth);
                FF2_SetBossHealth(boss, newhealth);
            }
            FF2_SetBossCharge(boss, 0, 0.0);
            FF2_SetBossLives(boss, 1);
            SDKHook(bosses[i], SDKHook_OnTakeDamage, OnTakeDamage);
        }

        // lastmanClientIndex=winner;
        IsLastMan[winner]=true;
        SDKHook(winner, SDKHook_OnTakeDamage, OnTakeDamage);

        if(GetEventInt(event, "userid") == GetClientUserId(winner))
        {
            int forWinner=FindAnotherPerson(winner);

            LastManData=CreateDataPack(); // In this? data = winner | forWinner | team | IsAlive | abserverTarget

            WritePackCell(LastManData, winner);
            WritePackCell(LastManData, forWinner);
            WritePackCell(LastManData, GetClientTeam(forWinner));

            if(IsPlayerAlive(forWinner))
            {
                WritePackCell(LastManData, 1);
                WritePackCell(LastManData, 0);
                CreateTimer(0.4, BeLastMan);
                TF2_AddCondition(forWinner, TFCond_Bonked, 0.4);
            }
            else // Yeah. then it said. Not Alive.
            {
                WritePackCell(LastManData, 0);
                WritePackCell(LastManData, GetEntPropEnt(forWinner, Prop_Send, "m_hObserverTarget"));
                // Debug("Spawning %n...", forWinner);
                TF2_ChangeClientTeam(forWinner, TF2_GetClientTeam(winner));
                TF2_RespawnPlayer(forWinner);
            }
            ResetPack(LastManData);
            return Plugin_Continue;
        }

        TF2_RespawnPlayer(winner);
        TF2_AddCondition(winner, TFCond_Ubercharged, 10.0);
        TF2_AddCondition(winner, TFCond_Stealthed, 10.0);
        GiveLastManWeapon(winner);
        return Plugin_Continue;
    }
    return Plugin_Continue;
}

public Action BeLastMan(Handle timer)
{
    ResetPack(LastManData);

    FF2_SetServerFlags(FF2_GetServerFlags()|FF2SERVERFLAG_ISLASTMAN|FF2SERVERFLAG_UNCHANGE_BGM_SERVER|FF2SERVERFLAG_UNCHANGE_BGM_USER);
    int winner=ReadPackCell(LastManData);
    int client=ReadPackCell(LastManData);
    TFTeam team=view_as<TFTeam>(ReadPackCell(LastManData));
    bool alive=ReadPackCell(LastManData);
    int observer=ReadPackCell(LastManData);

    TF2_RespawnPlayer(winner);
    TF2_AddCondition(winner, TFCond_Ubercharged, 10.0);
    TF2_AddCondition(winner, TFCond_Stealthed, 10.0);
    GiveLastManWeapon(winner);

    if(alive)
    {
        TF2_ChangeClientTeam(client, team);
    }
    else
    {
        Debug("winner: %N, client: %N, team: %d, alive: %s, real Dead? : %s",
        winner,
        client,
        view_as<int>(team),
        alive ? "true" : "false",
        !IsPlayerAlive(client) ? "true" : "false");

        TF2_ChangeClientTeam(client, TFTeam_Spectator);
        SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", observer);
        TF2_ChangeClientTeam(client, view_as<TFTeam>(team));

    }
    CloseLastmanData();
    return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{
    if(IsLastMan[client] || IsBoss(client))
    {
        IsLastMan[client]=false;
        SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    }
}


public Action FF2_OnMusic(char path[PLATFORM_MAX_PATH], float &time, char artist[80], char name[100], bool &notice, int client)
{
  if(IsLastManStanding && BGMCount)
  {
    int random=GetRandomInt(1, BGMCount);
    char tempItem[35];
    char tempPath[PLATFORM_MAX_PATH];
    char tempArtist[80];
    char tempName[100];

    if(MusicKV==INVALID_HANDLE)
    {
      LogError("MusicKV is invalid!");
      return Plugin_Continue;
    }

    Format(tempItem, sizeof(tempItem), "time%i", random);
    time=KvGetFloat(MusicKV, tempItem);

    Format(tempPath, sizeof(tempPath), "path%i", random);
    KvGetString(MusicKV, tempPath, tempPath, sizeof(tempPath));
    Format(path, sizeof(path), "%s", tempPath);

    Format(tempArtist, sizeof(tempArtist), "artist%i", random);
    KvGetString(MusicKV, tempArtist, tempArtist, sizeof(tempArtist));
    Format(artist, sizeof(artist), "%s", tempArtist);

    Format(tempName, sizeof(tempName), "name%i", random);
    KvGetString(MusicKV, tempName, tempName, sizeof(tempName));
    Format(name, sizeof(name), "%s", tempName);

    return Plugin_Changed;
  }
  return Plugin_Continue;
}

stock void SpawnPlayer(int client, int team)
{
    Handle event=CreateEvent("player_spawn", true);
    SetEventInt(event, "userid", GetClientUserId(client));
    SetEventInt(event, "team", team);
    SetEventInt(event, "class", GetRandomInt(1, 10));
    FireEvent(event);
}

stock void StartMusic(int client=0)
{
    FF2_StartMusic(client);
}

stock int FindAnotherPerson(int Gclient)
{
    int count;
    int validTarget[MAXPLAYERS+1];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsValidClient(client) && client != Gclient && !IsBoss(client))
        {
            validTarget[count++]=client;
        }
    }

    if(!count)
    {
        return CreateFakeClient("sorry. I can't find target.");
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
      SpawnWeapon(client, "tf_weapon_scattergun", 200, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_pistol", 209, 0, 2, "2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_bat", 30667, 0, 1, "2 ; 4.0 ; 112 ; 100.0");
      // 2: 피해량 향상
      // 97: 재장전 향상
      // 6: 발사 속도 향상
    }
    case TFClass_Sniper:
    {
      SpawnWeapon(client, "tf_weapon_sniperrifle", 201, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 5.0 ; 390 ; 3.0");
      SpawnWeapon(client, "tf_weapon_smg", 203, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 2.5 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_club", 264, 0, 1, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 4.0 ; 112 ; 100.0");
      // 390: 헤드샷 보너스 데미지
    }
    case TFClass_Soldier:
    {
      SpawnWeapon(client, "tf_weapon_rocketlauncher", 205, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 6 ; 0.4 ; 97 ; 0.4 ; 103 ; 1.2 ; 135 ; 1.3 ; 488 ; 1.0 ; 521 ; 2.0");
      SpawnWeapon(client, "tf_weapon_shotgun_soldier", 15016, 0, 2, "2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_shovel", 1071, 0, 1, "2 ; 4.0 ; 112 ; 100.0");
      // 103: 투사체 비행속도 향상
      // 135: 로켓점프 피해량 감소
      // 488: 로켓 특화
      // 521: 연기
    }
    case TFClass_DemoMan:
    {
      SpawnWeapon(client, "tf_weapon_grenadelauncher", 206, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 671 ; 1.0 ; 103 ; 1.3 ; 135 ; 1.3 ; 6 ; 0.4 ; 97 ; 1.3");
      SpawnWeapon(client, "tf_weapon_pipebomblauncher", 207, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 6 ; 0.4 ; 97 ; 1.3");
      SpawnWeapon(client, "tf_weapon_sword", 132, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 540 ; 1.0 ; 97 ; 0.4 ; 6 ; 0.4 ; 112 ; 100.0");
      // 540:아이랜더 효과로 추정됨..
      //changeMelee=false;
    }
    case TFClass_Medic:
    {
      SpawnWeapon(client, "tf_weapon_syringegun_medic", 36, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 17 ; 0.08 ; 97 ; 1.3");
      SpawnWeapon(client, "tf_weapon_medigun", 211, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 482 ; 2.0 ; 493 ; 3.0");
      SpawnWeapon(client, "tf_weapon_bonesaw", 1071, 0, 1, "2 ; 4.0 ; 17 ; 0.40 ; 112 ; 100.0");
      // 17: 적중 시 우버차지
      // 482: 오버힐 마스터리
      // 493: 힐 마스터리
    }
    case TFClass_Heavy:
    {
      SpawnWeapon(client, "tf_weapon_minigun", 202, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 1.3 ; 87 ; 0.6 ; 6 ; 1.1");
      SpawnWeapon(client, "tf_weapon_shotgun_hwg", 15016, 0, 2, "2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_fists", 1071, 0, 1, "2 ; 4.0 ; 112 ; 100.0");
      // 87: 미니건 돌리는 속도 증가
      //
    }
    case TFClass_Pyro:
    {
      SpawnWeapon(client, "tf_weapon_flamethrower", 208, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0");
      SpawnWeapon(client, "tf_weapon_shotgun_pyro", 15016, 0, 2, "2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4");
      SpawnWeapon(client, "tf_weapon_fireaxe", 38, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 178 ; 0.2 ; 112 ; 100.0");
      //changeMelee=false;
      // 178: 무기 바꾸는 속도 향상
    }
    case TFClass_Spy:
    {
      SpawnWeapon(client, "tf_weapon_revolver", 61, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.5 ; 51 ; 1.0 ; 390 ; 5.0");
      SpawnWeapon(client, "tf_weapon_knife", 194, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 112 ; 100.0");
      SpawnWeapon(client, "tf_weapon_builder", 735, 0, 2, _);
      SpawnWeapon(client, "tf_weapon_invis", 30, 0, 2, _);
      // 51: 헤드샷 판정 가능
    }
    case TFClass_Engineer:
    {
      SpawnWeapon(client, "tf_weapon_sentry_revenge", 141, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 97 ; 0.4 ; 6 ; 0.4 ; 136 ; 1.0");
      SpawnWeapon(client, "tf_weapon_wrench", 197, 0, 2, "2027 ; 1 ; 2022 ; 1 ; 542 ; 1 ; 2 ; 3.0 ; 124 ; 1.0 ; 343 ; 0.2 ; 344 ; 1.3 ; 464 ; 0.4 ; 112 ; 100.0");
      SpawnWeapon(client, "tf_weapon_laser_pointer", 140, 0, 2, _);
      SpawnWeapon(client, "tf_weapon_pda_engineer_build", 25, 0, 2, "351 ; 2.0");
      int pda = SpawnWeapon(client, "tf_weapon_builder", 28, 0, 2, _);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
      SetEntProp(pda, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
      SpawnWeapon(client, "tf_weapon_pda_engineer_destroy", 26, 0, 2, _);
      //changeMelee=false;
      // 124: 미니 센트리 설정
      // 136: 센트리 복수
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
  new String:config[PLATFORM_MAX_PATH];
  BuildPath(Path_SM, config, sizeof(config), "configs/ff2_lastman.cfg");

  if(!FileExists(config))
  {
    return;
  }
  if(MusicKV==INVALID_HANDLE)
  {
    BGMCount=0;
    MusicKV=CreateKeyValues("lastmanstanding");
    FileToKeyValues(MusicKV, config);
    KvRewind(MusicKV);

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

stock void CloseLastmanData()
{
    CloseHandle(LastManData);
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

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

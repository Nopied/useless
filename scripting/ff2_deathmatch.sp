#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>

// 아나운서의 음성은 FF2에서 이미 다운로드 테이블에 올리고, 캐시해둠.

Handle TimerHUD;

bool g_bEnable=false; //FF2나 기타 플러그인을 확인하는 용도

int g_iTimeleft;
int g_iTimeleftMax;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Deathmatch Mod",
    author="Nopied",
    description="....",
    version="0.1",
};

public void OnPluginStart()
{
    TimerHUD=CreateHudSynchronizer();

    HookEvent("teamplay_round_start", OnRoundStart);
    HookEvent("teamplay_round_win", OnRoundEnd);
}

public Action OnRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    if(!FF2_IsFF2Enabled())
    {
        LogMessage("FF2 NOT ENABLED!!!!");
        return Plugin_Continue;
    }
    CreateTimer(10.4, Timer_SetupRound);
    return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    if(g_bEnable)   g_bEnable=false;
    return Plugin_Continue;
}

public Action Timer_SetupRound(Handle timer)
{
    if(CheckAlivePlayers() < 6)
    {
        CPrintToChatAll("{olive}[FF2]{default} {red}최소 6명{default}이 있어야 타이머가 작동됩니다."); //TODO: FF2의 텍스트를 이용.
        return Plugin_Continue;
    }
    g_bEnable=true;

    g_iTimeleftMax=60+(CheckAlivePlayers()*15); // TODO: 커스터마이즈 가능하게.
    g_iTimeleft=g_iTimeleftMax;
    CreateTimer(1.0, RoundTimer, TIMER_REPEAT);

    return Plugin_Continue;
}

public Action RoundTimer(Handle timer)
{
    if(!g_bEnable)
    {
        g_iTimeleft=0;
        return Plugin_Stop;
    }
    g_iTimeleft--;
    char timer[20];
    const int color=RoundFloat(float(g_iTimeleft)*(float(g_iTimeleftMax)/510.0));

    Format(timer, sizeof(timer), "%d:%d", g_iTimeleft/60, g_iTimeleft%60);
    SetHudTextParams(-1.0, 0.17, 1.1,
        color<=255 ? color : 0,
        color>255 ? color-255 : 0,
         0, 255);

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsValidClient(client))
        {
            FF2_ShowSyncHudText(client, TimerHUD, timer);
        }
    }

    switch(g_iTimeleft)
    {
        case 300:
  		{
  			EmitSoundToAll("vo/announcer_ends_5min.mp3");
  		}
  		case 120:
  		{
  			EmitSoundToAll("vo/announcer_ends_2min.mp3");
  		}
  		case 60:
  		{
  			EmitSoundToAll("vo/announcer_ends_60sec.mp3");
  		}
  		case 30:
  		{
  			EmitSoundToAll("vo/announcer_ends_30sec.mp3");
  		}
  		case 10:
  		{
  			EmitSoundToAll("vo/announcer_ends_10sec.mp3");
  		}
  		case 1, 2, 3, 4, 5:
  		{
  			decl String:sound[PLATFORM_MAX_PATH];
  			Format(sound, PLATFORM_MAX_PATH, "vo/announcer_ends_%isec.mp3", time);
  			EmitSoundToAll(sound);
  		}
        case 0:
        {
            CPrintToChatAll("{olive}[FF2]{default} 어? 이 텍스트를 보셨나요? 그렇다면 넌 멀록이야!");
            return Plugin_Stop;
        }
    }

    return Plugin_Continue;
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
        if(IsValidClient(i) && (FF2_GetBossIndex(i) != -1) && IsPlayerAlive(i))
            alive++;
    }

    return alive;
}

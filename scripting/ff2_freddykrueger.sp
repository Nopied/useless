#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

float abilityDuration[MAXPLAYER+1];
bool g_bUseAbility=false;
int g_iFogIndex=-1;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Freddy Krueger's Ability",
    author="Nopied",
    description="FF2: Abilities used by some bosses",
    version="1.0",
};

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if(!strcmp(ability_name, "ff2_freddykrueger"))
    {
        Ability_FreddyKrueger(boss, ability_name);
    }
}

/*
Arg 1: 안개 시작
Arg 2: 안개 끝
Arg 3: 안개 색
*/

void Ability_FreddyKrueger(int boss, const char[] ability_name)
{
    new client=GetClientOfUserId(FF2_GetBossUserId(boss));
    char color[25];

    SetEntProp(client, Prop_Send, "m_CollisionGroup", 1);

    if(!g_bUseAbility)
    {
        FF2_GetAbilityArgumentString(boss, this_plugin_name, ability_name, 3, color, sizeof(color));

        AddNormalSoundHook(SoundHook);
        AddAmbientSoundHook(SoundAmbientHook);
        SpawnFog(
        FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 300.0)
        , FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 500.0)
        , "0 0 0");
        FF2_StopMusic();
    }

    g_bUseAbility=true;
    Handle bossKV=FF2_GetSpecialKV(boss, 0); // 이게 될까!?
    abilityDuration[client]=bossKV.GetFloat("ability_duration", 10.0);
    CreateTimer(0.1, Timer_AbilityDuration, TIMER_REPEAT);
    CloseHandle(bossKV);
}

public Action Timer_AbilityDuration(Handle timer, any client)
{
    if(!IsValidClient(client) || abilityDuration<=0.0)
    {
        SetEntProp(client, Prop_Send, "m_CollisionGroup", 5);
        g_bUseAbility=false;
        RemoveNormalSoundHook(SoundHook);
        RemoveAmbientSoundHook(SoundAmbientHook);
        ability_duration[client]=0.0;
        KillFog();
        FF2_StartMusic();
        return Plugin_Stop;
    }
    ability_duration[client]-=0.1;
    return Plugin_Continue;
}

public Action SoundHook(int clients[64], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    volume=0.0;
    StopSound(client, channel, sample);
    return Plugin_Changed;
}

public Action SoundAmbientHook(char sample[PLATFORM_MAX_PATH], int &entity, float &volume, int &level, int &pitch, float pos[3], int &flags, float &delay)
{
    volume=0.0;
    StopSound(entity, 0, sample);
    return Plugin_Changed;
}

stock void SpawnFog(float fogStart, float fogEnd, const char color[25])
{
    g_iFogIndex=CreateEntityByName("env_fog_controller");
    DispatchSpawn(g_iFogIndex);
    if(IsValidEntity(g_iFogIndex))
    {
        SetVariantFloat(fogStart);
        AcceptEntityInput(g_iFogIndex, "SetStartDist");
        SetVariantFloat(fogEnd);
        AcceptEntityInput(g_iFogIndex, "SetEndDist");
        SetVariantString(color);
        AcceptEntityInput(g_iFogIndex, "SetColor");
        SetVariantString("!activator");
        AcceptEntityInput(g_iFogIndex, "SetFogController");
        AcceptEntityInput(g_iFogIndex, "TurnOn");

        if(!IsValidEntity(g_iFogIndex))
        {
            g_iFogIndex=-1;
            PrintToChatAll("이 안개는 정상이 아님!");
        }
    }
    else g_iFogIndex=-1;
}

stock void KillFog()
{
    if(IsValidEntity(g_iFogIndex))
    {
        AcceptEntityInput(g_iFogIndex, "Kill");
    }
}

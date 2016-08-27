#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo=
{
    name="Freak Fortress 2 : CSGO",
    author="Nopied",
    description="FF2",
    version="1.0",
};

bool IsCSGO=false;

public void OnPluginStart2()
{
    HookEvent("arena_round_start", OnRoundStart);
    HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    CheckAbility();
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(FF2_GetRoundState() != 1 || !IsCSGO)
        return Plugin_Continue;

    SDKHook(GetClientOfUserId(GetEventInt(event, "userid")), SDKHook_FireBulletsPost, OnWeaponFire);
}

public void OnWeaponFire(int client, int shots, const char[] weaponname)
{
    float punchAng[3];
    GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);

    punchAng[1]+=GetRandomFloat(-3.0*shots, 3.0*shots);
    punchAng[2]+=GetRandomFloat(0.1*shots, 5.0*shots);

    SetEntPropFloat(client, Prop_Send, "m_vecPunchAngle", punchAng);
}

void CheckAbility()
{
    IsCSGO=false;
    int client, boss;
    for(client=1; client<=MaxClients; client++)
    {
        if((boss = FF2_GetBossIndex(client)) != -1 && FF2_HasAbility(boss, this_plugin_name, "ff2_csgo"))
        {
            IsCSGO=true;
        }
    }

    for(client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            SDKHook(client, SDKHook_FireBulletsPost, OnWeaponFire);
        }
    }
}

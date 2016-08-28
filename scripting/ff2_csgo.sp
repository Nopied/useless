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
bool PlayerRecoiled[MAXPLAYERS+1];

public void OnPluginStart2()
{
    HookEvent("arena_round_start", OnRoundStart);
    // HookEvent("player_spawn", OnPlayerSpawn);
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{

}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    CheckAbility();
}

/*
public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    if(FF2_GetRoundState() != 1 || !IsCSGO)
        return Plugin_Continue;

    SDKHook(GetClientOfUserId(GetEventInt(event, "userid")), SDKHook_FireBulletsPost, OnWeaponFire);
		return Plugin_Continue;
}
*/


public void OnGameFrame()
{
    if(IsCSGO && FF2_GetRoundState() == 1)
    {
        for(int client=1; client<=MaxClients; client++)
        {
            if(IsClientInGame(client) && IsPlayerAlive(client))
            {
                if(PlayerRecoiled[client] &&
                    GetEntPropFloat(client, Prop_Send, "m_flNextAttack") <= GetGameTime())
                {
                    PlayerRecoiled[client]=false;
                }

                else if(!PlayerRecoiled[client] &&
                    GetEntPropFloat(client, Prop_Send, "m_flNextAttack") > GetGameTime())
                {
                    PlayerRecoiled[client]=true;

                    float punchAng[3];
                    GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);

                    punchAng[1]+=GetRandomFloat(-3.0, 3.0);
                    punchAng[2]+=GetRandomFloat(0.1, 5.0);

                    SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);
                }
            }
            else
            {
                PlayerRecoiled[client]=false;
            }
        }
    }
}

/*
public void OnWeaponFire(int client, int shots, const char[] weaponname)
{
    float punchAng[3];
    GetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);

    punchAng[1]+=GetRandomFloat(-3.0, 3.0);
    punchAng[2]+=GetRandomFloat(0.1, 5.0);

    SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", punchAng);
}
*/

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

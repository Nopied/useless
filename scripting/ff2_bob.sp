#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>

bool Bob_Enabled[MAXPLAYERS+1];

public Plugin myinfo=
{
    name="Freak Fortress 2 : Bob's Abilities",
    author="Nopied",
    description="....",
    version="2016_10_17",
};

public void OnPluginStart2()
{
    HookEvent("arena_round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
  CheckAbility();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawn);
}

public void OnProjectileSpawn(int entity)
{
    char classname[60];
    GetEntityClassname(entity, classname, sizeof(classname));

    if(StrEqual(classname, "tf_projectile_pipe", true))
    {
        int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
        if(IsValidClient(client) && Bob_Enabled[client])
        {

        }
    }
}

/*

    stock UpdatePlayerHitbox(const client, const Float:fScale)
    {
        static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

        decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

        vecScaledPlayerMin = vecTF2PlayerMin;
        vecScaledPlayerMax = vecTF2PlayerMax;

        ScaleVector(vecScaledPlayerMin, fScale);
        ScaleVector(vecScaledPlayerMax, fScale);

        SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
        SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
    }

*/

void CheckAbility()
{
    int client, boss;
    for(client=1; client<=MaxClients; client++)
    {
        Bob_Enabled[client] = false;

  	    if((boss=FF2_GetBossIndex(client)) != -1)
  	    {
  	      	if(FF2_HasAbility(boss, this_plugin_name, "ff2_bob"))
                Bob_Enabled[client] = true;
  		}
    }
}

stock bool IsValidClient(int client)
{
    return (0 < client && client < MaxClients && IsClientInGame(client));
}

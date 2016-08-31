#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>


/*
    1: 지속시간
    2: 시전시간
*/
public Plugin myinfo=
{
	name="Freak Fortress 2: Shulk's Abilities",
	author="Nopied",
	description="",
	version="wat.",
};

int g_nEntityMovetype[MAXENTITIES+1];
float g_flTimeStop;

public void OnPluginStart2()
{

}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if(!strcmp(ability_name, "rage_timestop"))
     {
         Rage_TimeStop(boss);
     }
}

void Rage_TimeStop(int boss)
{
    float abilityDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 1, 15.0);
    float ability


    for(int entity=1; entity<=MAXENTITIES; entity++)
    {
        if(IsValidClient(entity) && IsPlayerAlive(entity))
        {
            TF2_AddCondition(entity, TFCond_HalloweenKartNoTurn, FF2_GetAbilityDurationMax(boss));

        }

        if(IsValidEntity(entity))
        {
            g_nEntityMovetype[entity] = view_as<int>(GetEntityMoveType(entity));
        }
    }
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

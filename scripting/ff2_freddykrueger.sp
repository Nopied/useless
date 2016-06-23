#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Freddy Krueger's Ability",
    author="Nopied",
    description="FF2",
    version="1.0",
};

public void OnPluginStart2()
{
  HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
  HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
  int client=GetClientOfUserId(GetEventInt(event, "userid"));

  if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, "ff2_freddykrueger"))
  {
    SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 54.0);
    SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", 124.0);
  }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
  int client=GetClientOfUserId(GetEventInt(event, "userid"));

  if(FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, "ff2_freddykrueger"))
  {
    SetEntPropFloat(client, Prop_Send, "m_fadeMinDist", 0.0);
    SetEntPropFloat(client, Prop_Send, "m_fadeMaxDist", 0.0);
  }
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{

}

stock bool IsValidClient(int client)
{
    return (0<client && client <= MaxClients && IsClientInGame(client));
}

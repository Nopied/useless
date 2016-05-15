#include <sourcemod>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>

bool g_bAirBlocked[MAXPLAYERS+1]=false;

Handle cvarTime;

public Plugin:myinfo = {
	name = "Pyro's airblast blocker",
	description = "No ConVar. EZ Life.",
	author = "Nopied◎",
	version = "씨팔.",
};

public void OnPluginStart()
{
  cvarTime=CreateConVar("airblast_block_time", "3.0", "", _, true, 0.0);
}

public void OnGameFrame()
{
  for(int target=1; target<=MaxClients; target++)
  {
    if(IsValidClient(target) && IsPlayerAlive(target) && TF2_GetPlayerClass(target)==TFClass_Pyro) // 7 = 파이로
    {
      int weapon=GetEntPropEnt(target, Prop_Send, "m_hActiveWeapon");
      char weaponName[80];
      GetEntityClassname(weapon, weaponName, sizeof(weaponName));

      if(StrContains(weaponName, "tf_weapon_flamethrower")) return;

      if(g_bAirBlocked[target])
      {
        SetEntPropFloat(weapon, Prop_Send, "m_flNextSecondaryAttack", GetGameTime()+0.2);
        SetEntPropFloat(target, Prop_Send, "m_flNextAttack", GetGameTime()+0.2);
      }
    }
  }
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
  if(IsValidClient(client) && IsPlayerAlive(client) && TF2_GetPlayerClass(client)==TFClass_Pyro) // 7 = 파이로
  {
		int Weapon;
    if(!g_bAirBlocked[client] && buttons & IN_ATTACK2)
    {
			Weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			char weaponName[80];
      GetEntityClassname(Weapon, weaponName, sizeof(weaponName));

			if(StrContains(weaponName, "tf_weapon_flamethrower") || !HasAirblast(Weapon)) return Plugin_Continue;

      CreateTimer(0.05, StartBlocking, client);
      CreateTimer(GetConVarFloat(cvarTime), EndBlocking, client);
    }
  }
	return Plugin_Continue;
}

public Action StartBlocking(Handle timer, int client)
{
  g_bAirBlocked[client]=true;
}
public Action EndBlocking(Handle timer, int client)
{
  g_bAirBlocked[client]=false;
}

stock bool HasAirblast(int weapon)
{
	if(!IsValidEntity(weapon))	return false;
	int iAttribIndices[16];
	float flAttribValues[16];

	for(int i=0; i<=TF2Attrib_GetStaticAttribs(GetIndexOfWeapon(weapon), iAttribIndices, flAttribValues); i++)
	{
		if(iAttribIndices[i] == 356 && flAttribValues[i] > 0.0) return false;
	}
	return true;
}

stock int GetIndexOfWeapon(int weapon)
{
	return (weapon > MaxClients && IsValidEntity(weapon) ? GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"):-1);
}

stock bool IsValidClient(int client)
{
  return (0<client && client<=MaxClients && IsClientInGame(client));
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin myinfo=
{
	name="Freak Fortress 2: Sam's Abilities",
	author="Nopied",
	description="",
	version="wat.",
};

public void OnPluginStart2()
{

}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
  if(!strcmp(ability_name, "rage_sam"))
	{
		Rage_Sam(boss);
	}
}

void Rage_Sam(int boss)
{
	int bossClient=GetClientOfUserId(FF2_GetBossUserId(boss));
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsBossTeam(client) && IsPlayerAlive(client))
		{
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, 10.0);
			TF2_StunPlayer(client, 10.0, 1.0, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_THIRDPERSON, bossClient); // TODO: 시간 커스터마이즈
			// 들고있던 무기 떨구기 || 107: 이속 증가
		}

	}
}

public Action OnEntityTransmit(int prop, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && propIndex[client] == prop && lostWeapon[client])
		return Plugin_Continue;

	return Plugin_Handled;
}

stock int SpawnWeaponProp(int client, int weapon)
{
	int ent=CreateEntityByName("prop_physics_override");

	if(!IsValidEntity(ent)) return -1;

	float clientPos[3];
	GetClientEyePosition(client, clientPos);

	SetEntProp(ent, Prop_Data, "m_takedamage", 2);
	SetEntProp(ent, Prop_Send, "m_nModelIndex", GetEntProp(weapon, Prop_Send, "m_nModelIndex"));

	DispatchSpawn(ent);
	TeleportEntity(ent, clientPos, NULL_VECTOR, NULL_VECTOR);
	SetEntityMoveType(ent, MOVETYPE_VPHYSICS);

	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 0);

	return ent;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

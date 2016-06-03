#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo=
{
	name="Freak Fortress 2: Sam's Abilities",
	author="Nopied",
	description="",
	version=PLUGIN_VERSION,
};

public void OnPluginStart2()
{

}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
    if(!strcmp(ability_name, "rage_sam"))
	{
		Rage_Sam(boss, ability_name);
	}
}

void Rage_Sam(int boss, const char[] ability_name)
{
	int bossClient=GetClientOfUserId(FF2_GetBossUserId(boss));
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && !IsBossTeam(client) && IsPlayerAlive(client))
		{
			TF2_StunPlayer(client, 10.0, 1.0, TF_STUNFLAG_NOSOUNDOREFFECT|TF_STUNFLAG_THIRDPERSON, bossClient); // TODO: 시간 커스터마이즈

			// 들고있던 무기 떨구기

			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			for(int i=0; i<=5; i++)
			{
				if(GetPlayerWeaponSlot(client, i) == weapon)
				{
					// 프롭소한 필요
					SpawnWeaponProp(client, weapon);
					TF2_RemoveWeaponSlot(client, i);
					break;
				}
			}
		}
	}
}

stock void SpawnWeaponProp(int client, int weapon)
{
	int ent=CreateEntityByName("prop_physics_override");

	if(!IsValidEntity(ent)) return;

	
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

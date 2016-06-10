#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

int lostWeapon[MAXPLAYERS+1];
int propIndex[MAXPLAYERS+1];

bool Raging=false;

public Plugin:myinfo=
{
	name="Freak Fortress 2: Sam's Abilities",
	author="Nopied",
	description="",
	version="wat.",
};

public void OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
  if(!strcmp(ability_name, "rage_sam"))
	{
		Raging=true;
		Rage_Sam(boss);
	}
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client))
		{
			TF2Attrib_SetByDefIndex(client, 107, 0.0);
		}
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

			int weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			// TF2Attrib_SetByDefIndex(client, 107, 9999.0);

			if(lostWeapon[client] && lostWeapon[client] != weapon)
			{
				SetEntityRenderColor(lostWeapon[client], _, _, _, 255);
				// SDKUnhook(lostWeapon[client], SDKHook_WeaponCanUse, OnWeaponUse);
				AcceptEntityInput(propIndex[client], "Kill");
			}
			for(int i=0; i<=5; i++)
			{
				if(GetPlayerWeaponSlot(client, i) == weapon)
				{
					// 프롭소한 필요
					int prop=SpawnWeaponProp(client, weapon);
					SetEntityRenderColor(weapon, _, _, _, 70);

					SDKHook(prop, SDKHook_StartTouch, OnPlayerTouch);
					SDKHook(prop, SDKHook_SetTransmit, OnEntityTransmit);
					// SDKHook(client, SDKHook_WeaponCanUse, OnWeaponUse);

					propIndex[client]=prop;
					lostWeapon[client]=weapon;
					break;
				}
			}
			PrintCenterText(client, "들고 있던 무기를 놓쳐버렸습니다! 제정신이 돌아오면 가서 주우세요!");
		}
	}
}

public Action FF2_OnBossAbilityTime(int boss, char[] abilityName, float &abilityDuration, float &abilityCooldown)
{
	if(FF2_HasAbility(boss, this_plugin_name, "rage_sam") && Raging && !abilityDuration)
	{
		Raging=false;
/*		for(int client=1; client<=MaxClients; client++)
		{
			if(IsClientInGame(client))
			{
				TF2Attrib_SetByDefIndex(client, 107, 0.0);//
			}
		}*/
	}
	return Plugin_Continue;
}

/* public Action OnWeaponUse(int client, int weapon) // TODO: 쓸모 없음.
{
	if(lostWeapon[client] == weapon)
	{
		PrintCenterText(client, "이 무기는 지금 사용할 수 없습니다.. 가서 다시 주우세요!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
*/

public Action OnEntityTransmit(int prop, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && propIndex[client] == prop && lostWeapon[client])
		return Plugin_Continue;

	return Plugin_Handled;
}

public Action OnPlayerTouch(int prop, int client)
{
	if(!Raging && IsValidClient(client) && IsPlayerAlive(client) && propIndex[client] == prop && lostWeapon[client])
	{
		SetEntityRenderColor(lostWeapon[client], _, _, _, 255);
		// SDKUnhook(lostWeapon[client], SDKHook_WeaponCanUse, OnWeaponUse);

		AcceptEntityInput(prop, "Kill");

		propIndex[client]=-1;
		lostWeapon[client]=-1;

		PrintCenterText(client, "무기를 다시 사용할 수 있습니다!");
	}
	return Plugin_Continue;
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

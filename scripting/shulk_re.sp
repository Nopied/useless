#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <custompart>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define MAXENTITIES 2048

/*
    1: 지속시간
    2: 시전시간
		3: 사운드 경로 (시전)
		4: 사운드 경로 (발동)
*/
public Plugin myinfo=
{
	name="Freak Fortress 2: Shulk's Abilities",
	author="Nopied",
	description="",
	version="wat.",
};

int g_nEntityMovetype[MAXENTITIES+1];

float g_flTimeStop = -1.0;
float g_flTimeStopCooling = -1.0;

float g_flTimeStopDamage[MAXPLAYERS + 1];

public void OnPluginStart2()
{
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(FF2_GetRoundState() != 1)    return Plugin_Continue;

	if( g_flTimeStop > GetGameTime() || (g_flTimeStop != -1.0 && g_flTimeStop > GetGameTime()))
	{
		g_nEntityMovetype[client] = view_as<int>(GetEntityMoveType(client));
		SetEntityMoveType(client, MOVETYPE_NONE);

		TF2_AddCondition(client, TFCond_HalloweenKartNoTurn, -1.0);

		SetEntProp(client, Prop_Send, "m_bIsPlayerSimulated", 0);
		SetEntProp(client, Prop_Send, "m_bSimulatedEveryTick", 0);
		SetEntProp(client, Prop_Send, "m_bAnimatedEveryTick", 0);
		SetEntProp(client, Prop_Send, "m_bClientSideAnimation", 0);
		SetEntProp(client, Prop_Send, "m_bClientSideFrameReset", 1);

		SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+10000.0);

		int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 0);
		SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 0);
		SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 0);
		SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 0);
		SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 1);

		SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action CP_OnActivedPartTime(int client, int partIndex, float &duration)
{
	if(FF2_GetRoundState() == 1)
	{
		if(g_flTimeStop > GetGameTime() || g_flTimeStop != -1.0)
		{
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action FF2_OnDeathMatchTimer(float &time)
{
	if(FF2_GetRoundState() == 1)
	{
		if(g_flTimeStop > GetGameTime() || g_flTimeStop != -1.0)
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_flTimeStop != -1.0 && g_flTimeStop > GetGameTime())
	{
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnOnTimeStop);
	}
}

public Action OnEntitySpawnOnTimeStop(int entity)
{
	if(IsValidEntity(entity))
	{
		g_nEntityMovetype[entity] = view_as<int>(GetEntityMoveType(entity));
		SetEntityMoveType(entity, MOVETYPE_NONE);
	}
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if(g_flTimeStop != -1.0 && condition == TFCond_Taunting)
	{
		TF2_RemoveCondition(client, condition);
	}
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
    // float abilityDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 1, 10.0);
		if(g_flTimeStopCooling <= 0.0)
		{
			for(int client = 1; client <= MaxClients; client++)
			{
				g_flTimeStopDamage[client] = 0.0;

				if(IsClientInGame(client) && IsPlayerAlive(client))
				{
					SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
					SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
				}
			}
		}
		g_flTimeStopCooling = GetGameTime() + FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 2, 5.0);

		SDKHook(GetClientOfUserId(FF2_GetBossUserId(boss)), SDKHook_PreThinkPost, RageTimer);

		char sound[PLATFORM_MAX_PATH];
		FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_timestop", 3, sound, sizeof(sound));

		if(sound[0] != '\0')
		{
			EmitSoundToAll(sound);
		}
}

public void RageTimer(int client)
{
	if(FF2_GetRoundState() != 1)
	{
		if(g_flTimeStopCooling != -1.0)
		{
			g_flTimeStopCooling = -1.0;
		}
		else if(g_flTimeStop != -1.0)
		{
			g_flTimeStop = -1.0;
			DisableTimeStop(FF2_GetBossIndex(client));
		}

		SDKUnhook(client, SDKHook_PreThinkPost, RageTimer);
	}

	if(g_flTimeStopCooling <= GetGameTime() && g_flTimeStopCooling != -1.0)
	{
		EnableTimeStop(FF2_GetBossIndex(client));
		g_flTimeStopCooling = -1.0;
		g_flTimeStop = GetGameTime()+FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, "rage_timestop", 1, 10.0);
	}
	else if(g_flTimeStop <= GetGameTime() && g_flTimeStop != -1.0)
	{
		g_flTimeStop = -1.0;
		DisableTimeStop(FF2_GetBossIndex(client));
		SDKUnhook(client, SDKHook_PreThinkPost, RageTimer);
	}
}

public Action OnTakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(IsValidClient(client) && IsValidClient(attacker))
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Ubercharged))
			return Plugin_Continue;

		if(g_flTimeStopCooling != -1.0 && IsBoss(client) && client != attacker)
		{
				TF2_AddCondition(attacker, TFCond_MarkedForDeath, -1.0);
				// Debug("%N Marked", client)
		}

		else if(g_flTimeStop != -1.0 && client != attacker)
		{
			g_flTimeStopDamage[client] += damage*0.2;
			// Debug("%N, g_flTimeStopDamage = %.1f", client, g_flTimeStopDamage[client]);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

/*
	m_bIsPlayerSimulated
	m_bSimulatedEveryTick
	m_bAnimatedEveryTick
	m_bClientSideAnimation
	m_bClientSideFrameReset
*/
void EnableTimeStop(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	// float abilityDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 1, 10.0);
	char classname[60];

	for(int entity=1; entity <= MAXENTITIES; entity++)
	{
			if(entity == client)
				continue;

			if(IsValidClient(entity))
			{
					SetClientOverlay(entity, "debug/yuv");
					if(IsPlayerAlive(entity))
					{
							TF2_AddCondition(entity, TFCond_HalloweenKartNoTurn, -1.0);

							SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 0);
							SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 0);
							SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 0);
							SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 0);
							SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 1);

							SetEntPropFloat(entity, Prop_Send, "m_flNextAttack", GetGameTime()+10000.0);

							int weapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
							SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 0);
							SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 0);
							SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 0);
							SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 0);
							SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 1);
					}
			}

			if(IsValidEntity(entity))
			{
					g_nEntityMovetype[entity] = view_as<int>(GetEntityMoveType(entity));
					SetEntityMoveType(entity, MOVETYPE_NONE);
					GetEntityClassname(entity, classname, sizeof(classname));

					if(!StrContains(classname, "obj_"))
					{
						if(TF2_GetObjectType(entity) == TFObject_Dispenser
						|| TF2_GetObjectType(entity) == TFObject_Teleporter
						|| TF2_GetObjectType(entity) == TFObject_Sentry)
						{
							SetEntProp(entity, Prop_Send, "m_bDisabled", 1);

							SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 0);
							SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 0);
							SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 0);
							SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 0);
							SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 1);
						}
					}
			}
	}

	char sound[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_timestop", 4, sound, sizeof(sound));

	if(sound[0] != '\0')
	{
		EmitSoundToAll(sound);
	}
}

void DisableTimeStop(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	char classname[60];

	for(int entity=1; entity<=MAXENTITIES; entity++)
	{
			if(entity == client)
				continue;

			if(IsValidClient(entity))
			{
				if(TF2_IsPlayerInCondition(entity, TFCond_HalloweenKartNoTurn))
				{
					TF2_RemoveCondition(entity, TFCond_HalloweenKartNoTurn);
				}

				SetClientOverlay(entity, "");
				SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 1);
				SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 1);
				SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
				SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
				SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 0);

				SetEntPropFloat(entity, Prop_Send, "m_flNextAttack", GetGameTime());
				SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);

				if(IsPlayerAlive(entity))
				{
					int weapon = GetEntPropEnt(entity, Prop_Send, "m_hActiveWeapon");
					SetEntProp(weapon, Prop_Send, "m_bIsPlayerSimulated", 1);
					SetEntProp(weapon, Prop_Send, "m_bAnimatedEveryTick", 1);
					SetEntProp(weapon, Prop_Send, "m_bSimulatedEveryTick", 1);
					SetEntProp(weapon, Prop_Send, "m_bClientSideAnimation", 1);
					SetEntProp(weapon, Prop_Send, "m_bClientSideFrameReset", 0);

					SDKHooks_TakeDamage(entity, client, client, g_flTimeStopDamage[entity], DMG_GENERIC, -1);
					TF2_RemoveCondition(entity, TFCond_MarkedForDeath);
				}

				g_flTimeStopDamage[entity] = 0.0;
			}

			if(IsValidEntity(entity))
			{
					GetEntityClassname(entity, classname, sizeof(classname));
					SetEntityMoveType(entity, view_as<MoveType>(g_nEntityMovetype[entity]));

					if(!StrContains(classname, "obj_"))
					{
						if(TF2_GetObjectType(entity) == TFObject_Dispenser
						|| TF2_GetObjectType(entity) == TFObject_Teleporter
						|| TF2_GetObjectType(entity) == TFObject_Sentry)
						{
							SetEntProp(entity, Prop_Send, "m_bDisabled", 0);

							SetEntProp(entity, Prop_Send, "m_bIsPlayerSimulated", 1);
							SetEntProp(entity, Prop_Send, "m_bAnimatedEveryTick", 1);
							SetEntProp(entity, Prop_Send, "m_bSimulatedEveryTick", 1);
							SetEntProp(entity, Prop_Send, "m_bClientSideAnimation", 1);
							SetEntProp(entity, Prop_Send, "m_bClientSideFrameReset", 0);
						}
					}
					else if(!StrContains(classname, "tf_projectile_", false) || IsValidClient(entity))
					{
						continue;
					}
					else
					{
						float tempVelo[3];
						tempVelo[2] = 0.1;
						NormalizeVector(tempVelo, tempVelo);
						TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, tempVelo);
					}
			}

			/*
			TFObject_Dispenser
			TFObject_Teleporter
			TFObject_Sentry
			*/
	}
}

stock bool IsBoss(int client)
{
	return FF2_GetBossIndex(client) != client;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

void SetClientOverlay(int client, char[] strOverlay)
{
	new iFlags = GetCommandFlags("r_screenoverlay") & (~FCVAR_CHEAT);
	SetCommandFlags("r_screenoverlay", iFlags);

	ClientCommand(client, "r_screenoverlay \"%s\"", strOverlay);
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
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
// bool RageCooling[MAXPLAYERS+1];

float g_flTimeStop = -1.0;
float g_flTimeStopCooling = -1.0;

public void OnPluginStart2()
{

}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(g_flTimeStop != -1.0)
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawnOnTimeStop);
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
    g_flTimeStopCooling = GetGameTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 2, 5.0);
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

void EnableTimeStop(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	float abilityDuration = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "rage_timestop", 1, 10.0);
	for(int entity=1; entity<=MAXENTITIES; entity++)
	{
			if(entity == client)
				continue;

			if(IsValidClient(entity) && IsPlayerAlive(entity))
			{
					TF2_AddCondition(entity, TFCond_HalloweenKartNoTurn, abilityDuration);
					SetClientOverlay(entity, "debug/yuv");
			}

			if(IsValidEntity(entity))
			{
					g_nEntityMovetype[entity] = view_as<int>(GetEntityMoveType(entity));
					SetEntityMoveType(entity, MOVETYPE_NONE);
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
	for(int entity=1; entity<=MAXENTITIES; entity++)
	{
			if(entity == client)
				continue;

			if(IsValidClient(entity))
			{
					SetClientOverlay(entity, "");
			}

			if(IsValidEntity(entity))
			{
					SetEntityMoveType(entity, view_as<MoveType>(g_nEntityMovetype[entity]));
			}
	}
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

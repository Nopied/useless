#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define SOUND_SHIELD "weapons/medi_shield_deploy.wav"

//int PlayerShield[MAXPLAYERS+1];

public Plugin:myinfo=
{
	name="Freak Fortress 2: Wolf's Abilities",
	author="Nopied◎",
	description="",
	version="EE",
};

public void OnPluginStart2()
{
  if(!IsSoundPrecached(SOUND_SHIELD))
    PrecacheSound(SOUND_SHIELD);
  HookEvent("medigun_shield_blocked_damage", OnBlocked, EventHookMode_Post);
}

public Action OnBlocked(Handle event, const char[] name, bool dont)
{
  int boss=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "userid")));
  if(FF2_HasAbility(boss, this_plugin_name, "wolf_deflecter"))
  {
		int client=GetClientOfUserId(GetEventInt(event, "userid"));
		float abilityTime=FF2_GetAbilityDuration(boss);
		/*
		FF2_SetBossCharge(boss, 0, FF2_GetBossCharge(boss, 0)+(GetEventFloat(event, "damage")*100.0/float(FF2_GetBossRageDamage(boss))));
		if(FF2_GetBossCharge(boss, 0) > 100.0)
			FF2_SetBossCharge(boss, 0, 100.0);


		*/
		if(abilityTime<=0.0)
		{
			if(GetEntPropFloat(client, Prop_Send, "m_flRageMeter") > 15.0)
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 15.0);
			return Plugin_Continue;
		}

		FF2_SetAbilityDuration(boss, abilityTime+3.0 > 70.0 ? 70.0 : abilityTime+3.0);

		SetEntPropFloat(client, Prop_Send, "m_flRageMeter",
			GetEntPropFloat(client, Prop_Send, "m_flRageMeter") > abilityTime*11.5 ?
			11.5*70.0 : abilityTime*11.5);
  }
	return Plugin_Continue;
}

public Action FF2_OnRageEnd(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 22.5);
}

public Action FF2_OnAbility2(int boss, const char[] pluginName, const char[] abilityName, int status)
{
  if(!strcmp(abilityName, "wolf_deflecter"))
  {
		int client=GetClientOfUserId(FF2_GetBossUserId(boss));
    // PlayerShield[client]=SpawnShield(client);
		SpawnShield(client);
  }
}

stock int SpawnShield(int client)
{
  int shield = CreateEntityByName("entity_medigun_shield");
  if(IsValidEntity(shield))
  {
    SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));
    if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
    else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
    SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 99999999.9);
    SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
    DispatchSpawn(shield);
    EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
    SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
	SDKHook(shield, SDKHook_StartTouch, OnStartTouch);
	return shield;
  }
	return -1;
}

public Action OnStartTouch(int entity, int other)
{
	if (other >= 0 || other <= MaxClients)
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action OnTouch(int entity, int other)
{
	char classname[60];
	GetEntityClassname(other, classname, sizeof(classname));

	if(GetEntPropEnt(other, Prop_Send, "m_hOwnerEntity") != GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity")
	&& StrContains(classname, "tf_projectile_"))
	{
		float RocketPos[3];
  		float RocketAng[3];
  		float RocketVec[3];
  		float TargetPos[3];
  		float TargetVec[3];
  		float MiddleVec[3];

  		GetPlayerEye(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"), TargetPos);

  		GetEntPropVector( other, Prop_Data, "m_vecAbsOrigin", RocketPos );
  		GetEntPropVector( other, Prop_Data, "m_angRotation", RocketAng );
  		GetEntPropVector( other, Prop_Data, "m_vecAbsVelocity", RocketVec );

  		float RocketSpeed = GetVectorLength( RocketVec );
  		SubtractVectors( TargetPos, RocketPos, TargetVec );

  		NormalizeVector( TargetVec, RocketVec );

  		AddVectors( RocketVec, TargetVec, MiddleVec );
/*
  		for( int j=0; j < iAccuracy-2; j++ )
		{
  			AddVectors( RocketVec, MiddleVec, MiddleVec );
  			AddVectors( RocketVec, MiddleVec, RocketVec );
  		}
*/
  		NormalizeVector( RocketVec, RocketVec );

  		GetVectorAngles( RocketVec, RocketAng );
  		SetEntPropVector( other, Prop_Data, "m_angRotation", RocketAng );

  		ScaleVector( RocketVec, RocketSpeed );
  		SetEntPropVector( other, Prop_Data, "m_vecAbsVelocity", RocketVec );

		SetEntPropEnt(other, Prop_Send, "m_hOwnerEntity", GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
	    SetEntProp(other, Prop_Send, "m_iTeamNum", GetEntProp(entity, Prop_Send, "m_iTeamNum"));

		int boss = FF2_GetBossIndex(GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity"));
		FF2_SetAbilityDuration(boss, FF2_GetAbilityDuration(boss) - 3.0);
	}

}

public bool GetPlayerEye(int client, float pos[3])
{
	float vAngles[3], float vOrigin[3];
	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceEntityFilterPlayer, client);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(pos, trace);
		CloseHandle(trace);
		return true;
	}
	CloseHandle(trace);
	return false;
}

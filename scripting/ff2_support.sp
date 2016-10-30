#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <entity>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <POTRY>

#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

public Plugin myinfo=
{
	name="Freak Fortress 2: Support",
	author="Nopied",
	description="",
	version="NEEDED!",
};

bool Sub_SaxtonReflect[MAXPLAYERS+1];
bool CBS_Abilities[MAXPLAYERS+1];

bool IsEntityCanReflect[MAX_EDICTS];
bool AllLastmanStanding;
int g_nEntityBounce[MAX_EDICTS];

public void OnPluginStart2()
{
	HookEvent("arena_round_start", OnRoundStart);
	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
	if(AllLastmanStanding)
		CreateTimer(0.3, CheckTimer, _, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action CheckTimer(Handle timer, int client)
{
	if(IsValidClient(client) && IsPlayerAlive(client) && !IsBossTeam(client))
	{
		FF2_EnablePlayerLastmanStanding(client);
	}
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "tf_projectile_"))
		return;
 	// SDKHook_SpawnPost

	SDKHook(entity, SDKHook_SpawnPost, OnSpawn);
	SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
}

public Action OnStartTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;

	// Only allow a rocket to bounce x times.
	if (g_nEntityBounce[entity] >= 50)
		return Plugin_Continue;

	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public void OnSpawn(int entity)
{
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	if(CBS_Abilities[ owner > MaxClients || owner <= 0 ? 0 : owner ])
	{
		int observer;
		float opPos[3];
		float opAng[3];

		IsEntityCanReflect[entity]=true;
		g_nEntityBounce[entity]=0;
		GetEntPropVector(entity,Prop_Data,"m_vecOrigin",opPos);
		GetEntPropVector(entity,Prop_Data, "m_angAbsRotation", opAng);

		observer = CreateEntityByName("info_observer_point");
		DispatchKeyValue(observer, "Angles", "90 0 0");
		DispatchKeyValue(observer, "TeamNum", "0");
		DispatchKeyValue(observer, "StartDisabled", "0");
		DispatchSpawn(observer);
		AcceptEntityInput(observer, "Enable");
		SetVariantString("!activator");
		AcceptEntityInput(observer, "SetParent", entity);
	}
	else IsEntityCanReflect[entity]=false;
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
  // HookEvent("arena_round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
  CheckAbilities();
}

void CheckAbilities()
{
  int client, boss;
  AllLastmanStanding = false;
  for(client=1; client<=MaxClients; client++)
  {
	    Sub_SaxtonReflect[client]=false;
		CBS_Abilities[client]=false;

	    if((boss=FF2_GetBossIndex(client)) != -1)
	    {
	      	if(FF2_HasAbility(boss, this_plugin_name, "ff2_saxtonreflect"))
	        	Sub_SaxtonReflect[client] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_CBS_abilities"))
		    	CBS_Abilities[client] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_lastmanstanding"))
				AllLastmanStanding = true;
		}
  }


	if(AllLastmanStanding)
	{
		for(client=1; client<=MaxClients; client++)
	    {
	  	 if(IsClientInGame(client) && IsPlayerAlive(client) && !IsBossTeam(client))
	    	{
	    		FF2_EnablePlayerLastmanStanding(client);
	    	}
	    }
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
  if(0 < client && client <= MaxClients && IsClientInGame(client))
  {
    if(buttons & IN_ATTACK && Sub_SaxtonReflect[client])
    {
			if(GetEntPropFloat(client, Prop_Send, "m_flNextAttack") > GetGameTime()
			|| GetEntPropFloat(GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_flNextPrimaryAttack") > GetGameTime())
				return Plugin_Continue;

			int ent;
			float clientPos[3];
			float clientEyeAngles[3];
			float end_pos[3];
			float targetPos[3];
			// float targetEndPos[3];
			float vecrt[3];
			float angVector[3];
			char classname[60];

			GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
			GetClientEyeAngles(client, clientEyeAngles);
			GetEyeEndPos(client, 100.0, end_pos);

			while((ent = FindEntityByClassname(ent, "tf_projectile_*")) != -1)
			{
/*				if(!HasEntProp(ent, Prop_Send, "m_hOwnerEntity")
				 || GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
*/
				if(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
				 continue;

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);
				// GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

				if(GetVectorDistance(end_pos, targetPos) <= 100.0)
				{
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);

/*					if(HasEntProp(ent, Prop_Send, "m_iTeamNum"))
					{
						SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));
					}
					if(HasEntProp(ent, Prop_Send, "m_bCritical"))
					{
						SetEntProp(ent, Prop_Send, "m_bCritical", 1);
					} // m_iDeflected
					if(HasEntProp(ent, Prop_Send, "m_iDeflected"))
					{
						SetEntProp(ent, Prop_Send, "m_iDeflected", 1);
					} */
					GetEntityClassname(ent, classname, sizeof(classname)); //
					if(StrEqual(classname, "tf_projectile_pipe", true))
					{
						SetEntPropEnt(ent, Prop_Send, "m_hThrower", client); // m_hDeflectOwner
						SetEntPropEnt(ent, Prop_Send, "m_hDeflectOwner", client);
					}

					SetEntProp(ent, Prop_Send, "m_iTeamNum", GetClientTeam(client));

					if(!StrEqual(classname, "tf_projectile_syringe", true))
					{
						SetEntProp(ent, Prop_Send, "m_bCritical", 1);
						SetEntProp(ent, Prop_Send, "m_iDeflected", 1);
					}

					GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
					NormalizeVector(angVector, angVector);

					angVector[0]*=1500.0;
					angVector[1]*=1500.0;
					angVector[2]*=1500.0;

					TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, angVector);
					EmitSoundToAll("player/flame_out.wav", ent, _, _, _, _, _, ent, targetPos);
				}
			}
		}
	}

  return Plugin_Continue;
}

public void GetEyeEndPos(int client, float max_distance, float endPos[3])
{
	if(IsClientInGame(client))
	{
		if(max_distance<0.0)
			max_distance=0.0;
		float PlayerEyePos[3];
		float PlayerAimAngles[3];
		GetClientEyePosition(client,PlayerEyePos);
		GetClientEyeAngles(client,PlayerAimAngles);
		float PlayerAimVector[3];
		GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
		if(max_distance>0.0){
			ScaleVector(PlayerAimVector,max_distance);
		}
		else{
			ScaleVector(PlayerAimVector,3000.0);
		}
      AddVectors(PlayerEyePos,PlayerAimVector,endPos);
	}
}

public Action OnTouch(int entity, int other)
{
	if(!IsEntityCanReflect[entity]) return Plugin_Continue;

	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);

	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);

	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);

	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);

	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}

	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);

	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);

	CloseHandle(trace);

	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);

	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);

	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);

	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);

	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));

	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	g_nEntityBounce[entity]++;

	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, any data)
{
	return (entity != data);
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

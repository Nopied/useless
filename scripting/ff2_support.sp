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
bool CBS_UpgradeRage[MAXPLAYERS+1];
bool IsTank[MAXPLAYERS+1];

bool CanWallWalking[MAXPLAYERS+1];
bool DoingWallWalking[MAXPLAYERS+1];
bool CoolingWallWalking[MAXPLAYERS+1];

float RocketCooldown[MAXPLAYERS+1];

float WalkingSoundCooldown[MAXPLAYERS+1];

bool IsEntityCanReflect[MAX_EDICTS];
bool AllLastmanStanding;
bool AttackAndDef;
int g_nEntityBounce[MAX_EDICTS];

public void OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundStart_Pre);

	HookEvent("player_spawn", OnPlayerSpawn);
}

public Action OnRoundStart_Pre(Handle event, const char[] name, bool dont)
{
    CreateTimer(10.4, OnRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{

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
	IsEntityCanReflect[entity] = false;
	int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

	if(!IsValidClient(owner)) return;

	if(CBS_Abilities[owner])
	{
		int observer;
		char angleString[80];
		float opAng[3];

		IsEntityCanReflect[entity]=true;
		g_nEntityBounce[entity]=0;
		// GetEntPropVector(entity,Prop_Data,"m_vecOrigin",opPos);
		GetEntPropVector(entity,Prop_Data, "m_angAbsRotation", opAng);
		Format(angleString, sizeof(angleString), "%.1f %.1f %.1f",
		opAng[0],
		opAng[1],
		opAng[2]);

		observer = CreateEntityByName("info_observer_point");
		DispatchKeyValue(observer, "Angles", angleString);
		DispatchKeyValue(observer, "TeamNum", "0");
		DispatchKeyValue(observer, "StartDisabled", "0");
		DispatchSpawn(observer);
		AcceptEntityInput(observer, "Enable");
		SetVariantString("!activator");
		AcceptEntityInput(observer, "SetParent", entity);
	}

	if(CBS_UpgradeRage[owner])
	{
		float opAng[3];
		float opPos[3];
		float tempAng[3];
		float tempVelocity[3];
		float opVelocity[3];

		int boss = FF2_GetBossIndex(owner);
		int arrowCount = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_CBS_upgrade_rage", 1, 5);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", opPos);
		GetEntPropVector(entity, Prop_Data, "m_angAbsRotation", opAng);
		GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", opVelocity);

		float arrowSpeed = GetVectorLength(opVelocity);

		for(int count=0; count < arrowCount; count++)
		{
			tempAng[0] = opAng[0] + GetRandomFloat(-5.0, 5.0);
			tempAng[1] = opAng[1] + GetRandomFloat(-5.0, 5.0);
			tempAng[2] = opAng[2] + GetRandomFloat(-5.0, 5.0);

			GetVectorAngles(tempAng, tempVelocity);

			tempVelocity[0] *= arrowSpeed;
			tempVelocity[1] *= arrowSpeed;
			tempVelocity[2] *= arrowSpeed;

			int arrow = CreateEntityByName("tf_projectile_arrow");
			if(!IsValidEntity(arrow)) break;

			SetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity", owner);
			SetEntProp(arrow,    Prop_Send, "m_bCritical",  0);
			SetEntProp(arrow,    Prop_Send, "m_iTeamNum", GetClientTeam(owner));
			// SetEntData(arrow, FindSendPropInfo("CTFProjectile_Arrow" , "m_nSkin"), (iTeam-2), 1, true);

			SetEntDataFloat(arrow,
				FindSendPropInfo("CTFProjectile_Arrow" , "m_iDeflected") + 4,
				100.0,
				true); // set damage

			TeleportEntity(arrow, opAng, tempAng, tempVelocity);

			DispatchSpawn(arrow);

			SetVariantInt(GetClientTeam(owner));
			AcceptEntityInput(arrow, "TeamNum", -1, -1, 0);

			SetVariantInt(GetClientTeam(owner));
			AcceptEntityInput(arrow, "SetTeam", -1, -1, 0);
		}
	}
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));

  	if(StrEqual(ability_name, "ff2_tank"))
	{
		RocketCooldown[client] = GetGameTime() + FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 1, 1.5);

		float clientEyePos[3];
		float clientEyeAngles[3];
		float vecrt[3];
		float angVector[3];

		GetClientEyePosition(client, clientEyePos);
		GetClientEyeAngles(client, clientEyeAngles);

		GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
		NormalizeVector(angVector, angVector);

		float speed = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 5, 1200.0);

		angVector[0] *= speed;
		angVector[1] *= speed;
		angVector[2] *= speed;

		int rocket = SpawnRocket(client, clientEyePos, clientEyeAngles, angVector, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 6, 90.5), true);
		if(IsValidEntity(rocket))
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			TF2Attrib_SetByDefIndex(weapon, 521, 1.0);
			TF2Attrib_SetByDefIndex(weapon, 642, 0.0); // 99
			TF2Attrib_SetByDefIndex(weapon, 99, 2.5);

			char path[PLATFORM_MAX_PATH];
			FF2_GetAbilityArgumentString(boss, this_plugin_name, "ff2_tank", 7, path, sizeof(path));

			if(path[0] != '\0')
			{
				EmitSoundToAll(path, client, _, _, _, _, _, client, clientEyePos);
			}
		}
	}

	if(StrEqual(ability_name, "ff2_CBS_upgrade_rage"))
	{
		CBS_UpgradeRage[client] = true;
	}
}

public Action FF2_OnAbilityTimeEnd(int boss, int slot, char[] abilityName)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));

	if(StrEqual(abilityName, "ff2_CBS_upgrade_rage"))
	{
		CBS_UpgradeRage[client] = false;
	}
}

public Action OnRoundStart(Handle timer)
{
  	CheckAbilities();

  	if(AttackAndDef)
		FF2_SetGameState(Game_AttackAndDefense);
}

void CheckAbilities()
{
  int client, boss;
  AllLastmanStanding = false;
  AttackAndDef = false;

  for(client=1; client<=MaxClients; client++)
  {
		if(IsClientInGame(client))
		{
			if(IsTank[client])
			{
				SetOverlay(client, "");

				SDKUnhook(client, SDKHook_StartTouch, OnTankTouch);
				SDKUnhook(client, SDKHook_Touch, OnTankTouch);
			}
			if(IsTank[client]) // TODO: 개별화
			{
				float StartAngle[3];
				float tempAngle[3];
				char Input[100];

				GetClientEyeAngles(client, StartAngle);

				tempAngle[0] = 0.0;
				tempAngle[1] = StartAngle[1];
				tempAngle[2] = StartAngle[2];

				Format(Input, sizeof(Input), "%.1f %.1f %.1f", tempAngle[0], tempAngle[1], tempAngle[2]);

				SetVariantBool(true);
				AcceptEntityInput(client, "SetCustomModelRotates", client);

				SetVariantString(Input);
				AcceptEntityInput(client, "SetCustomModelRotation", client);

				RequestFrame(ClassAniTimer, client);

				SetVariantBool(false);
				AcceptEntityInput(client, "SetCustomModelRotates", client);
			}
		}

		Sub_SaxtonReflect[client] = false;
		CBS_Abilities[client] = false;
		CBS_UpgradeRage[client] = false;

		CanWallWalking[client] = false;
		DoingWallWalking[client] = false;
		CoolingWallWalking[client] = false;

		IsTank[client] = false;

		RocketCooldown[client] = 0.0;
		WalkingSoundCooldown[client] = 0.0;

	    if((boss=FF2_GetBossIndex(client)) != -1)
	    {
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_wallwalking"))
			{
				CanWallWalking[client] = true;
			}
	      	if(FF2_HasAbility(boss, this_plugin_name, "ff2_saxtonreflect"))
	        	Sub_SaxtonReflect[client] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_CBS_abilities"))
		    	CBS_Abilities[client] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_lastmanstanding"))
				AllLastmanStanding = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_attackanddef"))
				AttackAndDef = true;


			if(FF2_HasAbility(boss, this_plugin_name, "ff2_tank"))
			{
				IsTank[client] = true;
				SetOverlay(client, "Effects/combine_binocoverlay");

				char model[PLATFORM_MAX_PATH];
				float StartAngle[3];
				float tempAngle[3];
				GetClientEyeAngles(client, StartAngle);

				GetClientModel(client, model, sizeof(model));
				SetVariantString(model);
				AcceptEntityInput(client, "SetCustomModel", client);

				char Input[100];

				tempAngle[0] = 0.0;
				tempAngle[1] = StartAngle[1];
				tempAngle[2] = StartAngle[2];

				Format(Input, sizeof(Input), "%.1f %.1f %.1f", tempAngle[0], tempAngle[1], tempAngle[2]);

				SetVariantBool(true);
				AcceptEntityInput(client, "SetCustomModelRotates", client);

				SetVariantString(Input);
				AcceptEntityInput(client, "SetCustomModelRotation", client);

				RequestFrame(ClassAniTimer, client);

				SDKHook(client, SDKHook_StartTouch, OnTankTouch);
				SDKHook(client, SDKHook_Touch, OnTankTouch);
			}
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

public Action OnTankTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients)
	{
		if(IsTank[entity])
		{
			SDKHooks_TakeDamage(other, entity, entity, 30.0, DMG_SLASH, -1);
		}
	}

}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(FF2_GetRoundState() != 1)
	{
		return Plugin_Continue;
	}

  if(0 < client && client <= MaxClients && IsClientInGame(client))
  {
	 	int boss = FF2_GetBossIndex(client);

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

			GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientPos);
			GetClientEyeAngles(client, clientEyeAngles);
			GetEyeEndPos(client, 100.0, end_pos);

			while((ent = FindEntityByClassname(ent, "tf_projectile_*")) != -1)
			{
				if(GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client)
				 continue;

				GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);

				if(GetVectorDistance(end_pos, targetPos) <= 100.0)
				{
					SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);

					if(HasEntProp(ent, Prop_Send, "m_iTeamNum"))
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
					}
					if(HasEntProp(ent, Prop_Send, "m_hThrower"))
					{
						SetEntPropEnt(ent, Prop_Send, "m_hThrower", client);
					}
					if(HasEntProp(ent, Prop_Send, "m_hDeflectOwner"))
					{
						SetEntPropEnt(ent, Prop_Send, "m_hDeflectOwner", client);
					}

					GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
					NormalizeVector(angVector, angVector);

					angVector[0] *= 1500.0;
					angVector[1] *= 1500.0;
					angVector[2] *= 1500.0;

					TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, angVector);
					EmitSoundToAll("player/flame_out.wav", ent, _, _, _, _, _, ent, targetPos);
				}
			}
		}

		if(IsTank[client])
		{
			SetOverlay(client, "Effects/combine_binocoverlay");

			int ent = -1;
			float range = 75.0;
			float clientPos[3];
			float targetPos[3];
			GetClientEyePosition(client, clientPos);

			while((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1) // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
		    {
		      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);

		      if(GetVectorDistance(clientPos, targetPos) <= range)
		      {
		        SDKHooks_TakeDamage(ent, client, client, 30.0, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1);
		      }
		    }

		    while((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)  // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
		    {
		      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);

		      if(GetVectorDistance(clientPos, targetPos) <= range)
		      {
		        SDKHooks_TakeDamage(ent, client, client, 30.0, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1);
		      }
		    }


		    while((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1) // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
		    {
		      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);

		      if(GetVectorDistance(clientPos, targetPos) <= range)
		      {
		        SDKHooks_TakeDamage(ent, client, client, 30.0, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1);
		      }
		    }
		}

		if(buttons & IN_ATTACK2 && IsTank[client] && GetGameTime() > RocketCooldown[client])
		{
			RocketCooldown[client] = GetGameTime() + FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 1, 1.5);

			float clientEyePos[3];
			float clientEyeAngles[3];
			float vecrt[3];
			float angVector[3];

			GetClientEyePosition(client, clientEyePos);
			GetClientEyeAngles(client, clientEyeAngles);

			GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
			NormalizeVector(angVector, angVector);

			float speed = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 2, 1200.0);

			clientEyePos[2] -= 12.0;

			angVector[0] *= speed;
			angVector[1] *= speed;
			angVector[2] *= speed;

			int rocket = SpawnRocket(client, clientEyePos, clientEyeAngles, angVector, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_tank", 3, 14.5), true);
			if(IsValidEntity(rocket))
			{
				int weapon2 = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");

				TF2Attrib_SetByDefIndex(weapon2, 521, 0.0); //642
				TF2Attrib_SetByDefIndex(weapon2, 642, 3.0);
				TF2Attrib_SetByDefIndex(weapon2, 99, 1.0);

				char path[PLATFORM_MAX_PATH];
				FF2_GetAbilityArgumentString(boss, this_plugin_name, "ff2_tank", 4, path, sizeof(path));

				if(path[0] != '\0')
				{
					EmitSoundToAll(path, client, _, _, _, _, _, client, clientEyePos);
				}

			}
		}

		if((buttons & IN_FORWARD || buttons & IN_LEFT || buttons & IN_RIGHT)
		&& IsTank[client])
		{
		 	bool NearWall = false;
			float StartOrigin[3];
			float StartAngle[3];
			float tempAngle[3];
			float EndOrigin[3];
			float vecrt[3];
			float Velocity[3];

			float Distance;
			Handle TraceRay;

			GetClientEyePosition(client, StartOrigin);
			GetClientEyeAngles(client, StartAngle);

			GetAngleVectors(StartAngle, Velocity, vecrt, NULL_VECTOR);
			NormalizeVector(Velocity, Velocity);

			tempAngle[0] = 50.0;
			tempAngle[1] = StartAngle[1];
			tempAngle[2] = StartAngle[2];

			for(int y = 50; y >= -50; y--)
			{
				tempAngle[0] -= 1.0;

				// TraceRay = TR_TraceRayEx(StartOrigin, tempAngle, MASK_SOLID, RayType_Infinite);
				TraceRay = TR_TraceRayFilterEx(StartOrigin, tempAngle, MASK_SOLID, RayType_Infinite, TraceRayNoPlayer, client);

				if(TR_DidHit(TraceRay))
				{
					TR_GetEndPosition(EndOrigin, TraceRay);
					Distance = (GetVectorDistance(StartOrigin, EndOrigin));

					if(Distance < 60.0 && !TR_PointOutsideWorld(EndOrigin)) NearWall = true;
				}

				CloseHandle(TraceRay);
/*
				PrintCenterText(client, "Distance: %.1f\n%.1f %.1f %.1f %s", Distance, Velocity[0], Velocity[1], Velocity[2],
				NearWall ? "true" : "false"
				);
*/

				if(NearWall)
				{
					float Speed = 300.0;

					if(buttons & IN_JUMP)
						Speed *= 2.0;

					Velocity[1] *= 180.0;
					Velocity[2] *= Speed;
					Velocity[0] *= 180.0;

					TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, Velocity);

					DoingWallWalking[client] = NearWall;

					break;
				}
			}
		}

		if(IsTank[client])
		{
			float StartAngle[3];
			float tempAngle[3];
			GetClientEyeAngles(client, StartAngle);

			if(DoingWallWalking[client])
			{
				CoolingWallWalking[client] = false;
				tempAngle[0] = StartAngle[0] > 0.0 ? 0.0 : StartAngle[0];
			}
			else if(GetEntityFlags(client) & FL_ONGROUND)
			{
				tempAngle[0] = 0.0;
			}

			tempAngle[1] = StartAngle[1];
			tempAngle[2] = StartAngle[2];

			if(!CoolingWallWalking[client])
			{
				char Input[100];

				char modelPath[PLATFORM_MAX_PATH];
				GetClientModel(client, modelPath, sizeof(modelPath));

				SetVariantString(modelPath);
				AcceptEntityInput(client, "SetCustomModel", client);

				Format(Input, sizeof(Input), "%.1f %.1f %.1f", tempAngle[0], tempAngle[1], tempAngle[2]);

				SetVariantBool(true);
				AcceptEntityInput(client, "SetCustomModelRotates", client);

				SetVariantString(Input);
				AcceptEntityInput(client, "SetCustomModelRotation", client);

				RequestFrame(ClassAniTimer, client);

				if(GetEntityFlags(client) & FL_ONGROUND)
				{
					CoolingWallWalking[client] = true;
				}
			}
		}
	}

  	return Plugin_Continue;
}

public void ClassAniTimer(int client)
{
	if(IsClientInGame(client))
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

public bool TraceRayNoPlayer(int iEntity, int iMask, any iData)
{
    return (!IsValidClient(iEntity));
}

public Action FF2_OnTakePercentDamage(int victim, int &attacker, PercentDamageType:damageType, float &damage)
{
	if(IsTank[victim])
	{
		damage *= 0.6;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

void SetOverlay(int client, const char[] overlay)						// changes a client's screen overlay (requires clientcommand, they could disable so, enforce with smac or something if you care.)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}

stock int SpawnRocket(int client, float origin[3], float angles[3], float velocity[3], float damage, bool allowcrit)
{
	int ent=CreateEntityByName("tf_projectile_rocket");
	if(!IsValidEntity(ent)){
		 return -1;
		}
	int clientTeam = GetClientTeam(client);
	int damageOffset = FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4;

	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(ent, Prop_Send, "m_bCritical", allowcrit ? 1 : 0);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", clientTeam);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 4);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);
	// SetEntPropEnt(ent, Prop_Send, "m_nForceBone", -1);
	SetEntPropVector(ent, Prop_Send, "m_vecMins", Float:{0.0,0.0,0.0});
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", Float:{0.0,0.0,0.0});
	SetEntDataFloat(ent, damageOffset, damage); // set damage
	SetVariantInt(clientTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	SetVariantInt(clientTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0);
	DispatchSpawn(ent);
	SetEntPropEnt(ent, Prop_Send, "m_hOriginalLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	SetEntPropEnt(ent, Prop_Send, "m_hLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));

	TeleportEntity(ent, origin, angles, velocity);

	return ent;
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

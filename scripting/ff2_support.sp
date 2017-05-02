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

#define SOLID_NONE 0 // no solid model
#define SOLID_BSP 1 // a BSP tree
#define SOLID_BBOX 2 // an AABB
#define SOLID_OBB 3 // an OBB (not implemented yet)
#define SOLID_OBB_YAW 4 // an OBB, constrained so that it can only yaw
#define SOLID_CUSTOM 5 // Always call into the entity for tests
#define SOLID_VPHYSICS 6 // solid vphysics object, get vcollide from the model and collide with that

#define FSOLID_CUSTOMRAYTEST 0x0001 // Ignore solid type + always call into the entity for ray tests
#define FSOLID_CUSTOMBOXTEST 0x0002 // Ignore solid type + always call into the entity for swept box tests
#define FSOLID_NOT_SOLID 0x0004 // Are we currently not solid?
#define FSOLID_TRIGGER 0x0008 // This is something may be collideable but fires touch functions
#define FSOLID_NOT_STANDABLE 0x0010 // You can't stand on this
#define FSOLID_VOLUME_CONTENTS 0x0020 // Contains volumetric contents (like water)
#define FSOLID_FORCE_WORLD_ALIGNED 0x0040 // Forces the collision rep to be world-aligned even if it's SOLID_BSP or SOLID_VPHYSICS
#define FSOLID_USE_TRIGGER_BOUNDS 0x0080 // Uses a special trigger bounds separate from the normal OBB
#define FSOLID_ROOT_PARENT_ALIGNED 0x0100 // Collisions are defined in root parent's local coordinate space
#define FSOLID_TRIGGER_TOUCH_DEBRIS 0x0200 // This trigger will touch debris objects

#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

#define SPRITE 	"materials/sprites/dot.vmt"

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

bool IsTravis[MAXPLAYERS];
float TravisBeamCharge[MAXPLAYERS+1];
// float TravisBeamCoolTick[MAXPLAYERS+1];

int entSpriteRef[MAXPLAYERS+1] = {-1, ...};

bool IsEntityCanReflect[MAX_EDICTS];
bool AllLastmanStanding;
bool AttackAndDef;
bool enableVagineer = false;
int g_nEntityBounce[MAX_EDICTS];

public void OnPluginStart2()
{
	HookEvent("teamplay_round_start", OnRoundStart_Pre);

	HookEvent("player_spawn", OnPlayerSpawn);

	HookEvent("player_death", OnPlayerDeath);

	PrecacheGeneric(SPRITE, true);
}

public Action OnRoundStart_Pre(Handle event, const char[] name, bool dont)
{
    CreateTimer(10.4, OnRoundStart, _, TIMER_FLAG_NO_MAPCHANGE);

/*
	for(int client = 1; client<=MaxClients; client++)
	{
		int viewentity = EntRefToEntIndex(entSpriteRef[client]);
		if(IsValidEntity(viewentity))
		{
			if(IsClientInGame(client))
				SetClientViewEntity(client, client);

			AcceptEntityInput(viewentity, "kill");
		}
	}
*/

}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(FF2_GetRoundState() != 1 || !IsValidClient(client))	return Plugin_Continue;


	if(enableVagineer && entSpriteRef[client] == -1)
	{
		float clientPos[3];
		GetClientEyePosition(client, clientPos);

		int ent = CreateViewEntity(client, clientPos);
		if(IsValidEntity(ent))
		{
			entSpriteRef[client] = EntIndexToEntRef(ent);
		}
	}


}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!IsValidClient(client))	return Plugin_Continue;

	int viewentity = EntRefToEntIndex(entSpriteRef[client]);
	if(IsValidEntity(viewentity))
	{
		SetClientViewEntity(client, client);
		AcceptEntityInput(viewentity, "kill");
		entSpriteRef[client] = -1;
	}

/*
	if(IsBoss(attacker))
	{
		int boss = FF2_GetBossIndex(attacker);

		if(TravisBeamCharge[attacker] >= 70.0)
		{
			float neededTimeStop = (100.0 - TravisBeamCharge[attacker]) / 5.0;

			if(TIMESTOP_IsTimeStopping())
			{
				TIMESTOP_DisableTimeStop();
			}

			TIMESTOP_EnableTimeStop(attacker, 0.1, neededTimeStop);
		}
	}
	*/

	return Plugin_Continue;
}

public void OnClientDisconnect(int client)
{

	if(entSpriteRef[client] != -1)
	{
		int viewentity = EntRefToEntIndex(entSpriteRef[client]);
		if(IsValidEntity(viewentity))
		{
			AcceptEntityInput(viewentity, "kill");
			entSpriteRef[client] = -1;
		}
	}

}

stock bool IsBoss(int client)
{
	return FF2_GetBossIndex(client) != -1;
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
/*
	if(CBS_UpgradeRage[owner])
	{
		float opAng[3];
		float opPos[3];
		float tempPos[3];
		float tempAng[3];
		float tempVelocity[3];
		float opVelocity[3];

		int boss = FF2_GetBossIndex(owner);
		int arrowCount = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_CBS_upgrade_rage", 1, 5);

		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", opPos);
		GetEntPropVector(entity, Prop_Send, "m_angRotation", opAng);
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", opVelocity);

		float arrowSpeed = GetVectorLength(opVelocity);

		float Random = 10.0;
		float Random2 = Random*-1;
		int counter = 0;

		for(int count=0; count < arrowCount; count++)
		{
			tempAng[0] = opAng[0] + GetRandomFloat(Random2,Random);
			tempAng[1] = opAng[1] + GetRandomFloat(Random2,Random);
			// avoid unwanted collision
			int i2 = count%4;
			switch(i2)
			{
				case 0:
				{
					counter++;
					tempPos[0] = opPos[0] + counter;
				}
				case 1:
				{
					tempPos[1] = opPos[1] + counter;
				}
				case 2:
				{
					tempPos[0] = opPos[0] - counter;
				}
				case 3:
				{
					tempPos[1] = opPos[1] - counter;
				}
			}

			GetVectorAngles(tempAng, tempVelocity);

			tempVelocity[0] *= arrowSpeed;
			tempVelocity[1] *= arrowSpeed;
			tempVelocity[2] *= arrowSpeed;

			int arrow = CreateEntityByName("tf_projectile_arrow");
			if(!IsValidEntity(arrow)) break;

			Debug("arrow = %i", arrow);

			IsEntityCanReflect[arrow] = true;

			SetEntPropEnt(arrow, Prop_Send, "m_hOwnerEntity", owner);
			SetEntProp(arrow,    Prop_Send, "m_bCritical",  0);
			SetEntProp(arrow,    Prop_Send, "m_iTeamNum", GetClientTeam(owner));

			SetEntDataFloat(arrow,
				FindSendPropInfo("CTFProjectile_Arrow" , "m_iDeflected") + 4,
				100.0,
				true); // set damage
			// SetEntData(arrow, FindSendPropInfo("CTFProjectile_Arrow" , "m_nSkin"), (iTeam-2), 1, true);

			SetVariantInt(GetClientTeam(owner));
			AcceptEntityInput(arrow, "TeamNum", -1, -1, 0);

			SetVariantInt(GetClientTeam(owner));
			AcceptEntityInput(arrow, "SetTeam", -1, -1, 0);

			DispatchSpawn(arrow);

			TeleportEntity(arrow, tempPos, tempAng, tempVelocity);
		}
	}
	*/
}
public Action:FF2_OnPlayBoss(int client, int bossIndex)
{
	CheckAbilities(client, true);
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

	if(StrEqual(ability_name, "ff2_rage_stone"))
	{
		CreateStone(boss);
	}
/*
	if(StrEqual(ability_name, "ff2_CBS_upgrade_rage"))
	{
		Debug("CBS_UpgradeRage[client] = true");
		CBS_UpgradeRage[client] = true;
	}
*/
}

void CreateStone(int boss)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));
	int stoneCount = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_rage_stone", 1, 10);
	float PropVelocity = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "ff2_rage_stone", 2, 10000.0);
	int stoneHealth = FF2_GetAbilityArgument(boss, this_plugin_name, "ff2_rage_stone", 3, 400);
	char strModelPath[PLATFORM_MAX_PATH];
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "ff2_rage_stone", 4, strModelPath, sizeof(strModelPath));

	for(int count=0; count<stoneCount; count++)
	{
		int prop = CreateEntityByName("prop_physics_override");
		if(IsValidEntity(prop))
		{
			Debug("%i", prop);
			SetEntityModel(prop, strModelPath);
			SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", 5);
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", FSOLID_TRIGGER_TOUCH_DEBRIS); // not solid
			SetEntProp(prop, Prop_Send, "m_nSolidType", SOLID_VPHYSICS); // not solid
			SetEntProp(prop, Prop_Data, "m_takedamage", 2);
			SetEntProp(prop, Prop_Data, "m_iMaxHealth", stoneHealth);
			SetEntProp(prop, Prop_Data, "m_iHealth", stoneHealth);
			DispatchSpawn(prop);

			float position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

			float velocity[3];

			velocity[0] = GetRandomFloat(PropVelocity*0.5, PropVelocity*1.5);
			velocity[1] = GetRandomFloat(PropVelocity*0.5, PropVelocity*1.5);
			velocity[2] = GetRandomFloat(PropVelocity*0.5, PropVelocity*1.5);
			NormalizeVector(velocity, velocity);


			TeleportEntity(prop, position, NULL_VECTOR, velocity);
			// TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);

			SDKHook(prop, SDKHook_Touch, OnStoneTouch);
			SDKHook(prop, SDKHook_StartTouch, OnStoneTouch);
		}
		else
			break;
	}
}


public Action OnStoneTouch(int entity, int other)
{
	float modelScale = GetEntPropFloat(entity, Prop_Send, "m_flModelScale");

	if (other > 0 && other <= MaxClients)
	{
		if(!IsBossTeam(other))
		{
			SDKHooks_TakeDamage(other, entity, entity, 15.0, DMG_SLASH, -1);
		}
		else
		{
			KickEntity(other, entity);
		}

		if(modelScale-0.008 < 0.1)
		{
			AcceptEntityInput(entity, "kill");
			return Plugin_Continue;
		}
		SetEntPropFloat(entity, Prop_Send, "m_flModelScale", modelScale-0.008);
	}
	else if(other > 0)
	{
		float position[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);

		float otherPosition[3];
		GetEntPropVector(other, Prop_Send, "m_vecOrigin", otherPosition);

		float goalVector[3], goalOtherVector[3];
		MakeVectorFromPoints(position, otherPosition, goalVector);
		MakeVectorFromPoints(otherPosition, position, goalOtherVector);

		NormalizeVector(goalVector, goalVector);
		ScaleVector(goalVector, -2500.0);

		NormalizeVector(goalOtherVector, goalOtherVector);
		ScaleVector(goalOtherVector, -2500.0);

		TeleportEntity(entity, position, NULL_VECTOR, goalVector);
		TeleportEntity(other, position, NULL_VECTOR, goalOtherVector);
	}
	else
	{
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
	}

	return Plugin_Continue;
}

void KickEntity(int client, int entity)
{
	float clientEyeAngles[3];
	float vecrt[3];
	float angVector[3];

	GetClientEyeAngles(client, clientEyeAngles);
	GetAngleVectors(clientEyeAngles, angVector, vecrt, NULL_VECTOR);
	NormalizeVector(angVector, angVector);

	angVector[0] *= 1500.0;
	angVector[1] *= 1500.0;
	angVector[2] *= 1500.0;

	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, angVector);
	// SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);

}


 public Action FF2_OnBossAbilityTime(int boss, char[] abilityName, int slot, float &abilityDuration, float &abilityCooldown)
 {
	 int client = GetClientOfUserId(FF2_GetBossUserId(boss));

	 if(IsTravis[client] && abilityDuration > 0.0)
	 {
		 TravisBeamCharge[client] = 100.0;
	 }

 }
public Action FF2_OnAbilityTimeEnd(int boss, int slot)
{
	int client = GetClientOfUserId(FF2_GetBossUserId(boss));

	/*
	if(StrEqual(abilityName, "ff2_CBS_upgrade_rage"))
	{
		CBS_UpgradeRage[client] = false;
	}
	*/
}

public Action OnRoundStart(Handle timer)
{
  	CheckAbilities();

  	if(AttackAndDef)
		FF2_SetGameState(Game_AttackAndDefense);
}

void CheckAbilities(int client=0, bool onlyforclient=false)
{
  int boss;
  AllLastmanStanding = false;
  AttackAndDef = false;
  enableVagineer = false;

  for(int target=1; target <= MaxClients; target++)
  {
	  	if(onlyforclient && target != client)
		{
			continue;
		}

		if(entSpriteRef[target] != -1)
		{
			int viewentity = EntRefToEntIndex(entSpriteRef[target]);
			if(IsValidEntity(viewentity))
			{
				if(IsClientInGame(target))
					SetClientViewEntity(target, target);
				AcceptEntityInput(viewentity, "kill");

				entSpriteRef[target] = -1;
			}
		}
		entSpriteRef[target] = -1;


		if(IsClientInGame(target))
		{
			if(IsTank[target])
			{
				SetOverlay(target, "");

				SDKUnhook(target, SDKHook_StartTouch, OnTankTouch);
				SDKUnhook(target, SDKHook_Touch, OnTankTouch);
			}
			if(IsTank[target]) // TODO: 개별화
			{
				float StartAngle[3];
				float tempAngle[3];
				char Input[100];

				GetClientEyeAngles(target, StartAngle);

				tempAngle[0] = 0.0;
				tempAngle[1] = StartAngle[1];
				tempAngle[2] = StartAngle[2];

				Format(Input, sizeof(Input), "%.1f %.1f %.1f", tempAngle[0], tempAngle[1], tempAngle[2]);

				SetVariantBool(true);
				AcceptEntityInput(target, "SetCustomModelRotates", target);

				SetVariantString(Input);
				AcceptEntityInput(target, "SetCustomModelRotation", target);

				RequestFrame(ClassAniTimer, target);

				SetVariantBool(false);
				AcceptEntityInput(target, "SetCustomModelRotates", target);
			}
		}

		Sub_SaxtonReflect[target] = false;
		CBS_Abilities[target] = false;
		CBS_UpgradeRage[target] = false;

		CanWallWalking[target] = false;
		DoingWallWalking[target] = false;
		CoolingWallWalking[target] = false;

		IsTank[target] = false;

		RocketCooldown[target] = 0.0;
		WalkingSoundCooldown[target] = 0.0;

		IsTravis[target] = false;
		TravisBeamCharge[target] = 0.0;

	    if((boss=FF2_GetBossIndex(target)) != -1)
	    {
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_wallwalking"))
			{
				CanWallWalking[target] = true;
			}
	      	if(FF2_HasAbility(boss, this_plugin_name, "ff2_saxtonreflect"))
	        	Sub_SaxtonReflect[target] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_CBS_abilities"))
		    	CBS_Abilities[target] = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_lastmanstanding"))
				AllLastmanStanding = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_attackanddef"))
				AttackAndDef = true;
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_travis"))
				IsTravis[target] = true;

			if(FF2_HasAbility(boss, this_plugin_name, "ff2_tank"))
			{
				IsTank[target] = true;
				SetOverlay(target, "Effects/combine_binocoverlay");

				char model[PLATFORM_MAX_PATH];
				float StartAngle[3];
				float tempAngle[3];
				GetClientEyeAngles(target, StartAngle);

				GetClientModel(target, model, sizeof(model));
				SetVariantString(model);
				AcceptEntityInput(target, "SetCustomModel", target);

				char Input[100];

				tempAngle[0] = 0.0;
				tempAngle[1] = StartAngle[1];
				tempAngle[2] = StartAngle[2];

				Format(Input, sizeof(Input), "%.1f %.1f %.1f", tempAngle[0], tempAngle[1], tempAngle[2]);

				SetVariantBool(true);
				AcceptEntityInput(target, "SetCustomModelRotates", target);

				SetVariantString(Input);
				AcceptEntityInput(target, "SetCustomModelRotation", target);

				RequestFrame(ClassAniTimer, target);

				SDKHook(target, SDKHook_StartTouch, OnTankTouch);
				SDKHook(target, SDKHook_Touch, OnTankTouch);
			}

			if(FF2_HasAbility(boss, this_plugin_name, "ff2_vagineer_passive"))
			{
				enableVagineer = true;
				for(int spTarget=1; spTarget <= MaxClients; spTarget++)
				{
					if(!IsValidClient(spTarget) || !IsPlayerAlive(spTarget))
					{
						entSpriteRef[spTarget] = -1;
						continue;
					}

					float clientPos[3];
					GetClientEyePosition(spTarget, clientPos);

					int ent = CreateViewEntity(spTarget, clientPos);
					if(IsValidEntity(ent))
					{
						entSpriteRef[spTarget] = EntIndexToEntRef(ent);
					}
				}
			}

/*
			if(FF2_HasAbility(boss, this_plugin_name, "ff2_test_map_rota"))
			{
				float StartAngle[3];

				StartAngle[0] = 60.0;

				SetEntPropVector(0, Prop_Data, "m_angRotation", StartAngle);
			}
*/
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

	bool changed = false;

  if(IsValidClient(client) && IsPlayerAlive(client))
  {
	 	int boss = FF2_GetBossIndex(client);

		if(enableVagineer && entSpriteRef[client] != -1)
		{
			int viewentity = EntRefToEntIndex(entSpriteRef[client]);

			float clientAngles[3];
			GetClientEyeAngles(client, clientAngles);

			clientAngles[1] = -179.0;

			TeleportEntity(viewentity, NULL_VECTOR, clientAngles, NULL_VECTOR);

			/*
			// 버튼 반대

			if(buttons & IN_FORWARD|IN_BACK)
			{

			}
			*/
		}

	    if(buttons & IN_ATTACK)
	    {
			if(Sub_SaxtonReflect[client])
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
			/*
			if(IsTravis[client])
			{
				TravisBeamCharge[client] += FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(boss), this_plugin_name, "ff2_travis", 1, 2.0);

				Debug("%.1f%%", TravisBeamCharge[client]);

				if(TravisBeamCharge[client] > 100.0)
					TravisBeamCharge[client] = 100.0;
			}
			*/
		}

		if(IsTravis[client])
		{
			TravisBeamCharge[client] -= FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(boss), this_plugin_name, "ff2_travis", 2, 0.01);

			if(TravisBeamCharge[client] < 0.0)
				TravisBeamCharge[client] = 0.0;

			PrintCenterText(client, "빔 카타나 충전율: %.1f%%\n무기를 휘둘러 충전", TravisBeamCharge[client]);
		}

		if(IsTank[client])
		{
			SetOverlay(client, "Effects/combine_binocoverlay");

			int ent = -1;
			float range = 75.0;
			float clientPos[3];
			float targetPos[3];
			GetClientAbsOrigin(client, clientPos);

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

int CreateViewEntity(int client, float pos[3])
{
	int entity;
	if((entity = CreateEntityByName("env_sprite")) != -1)
	{
		DispatchKeyValue(entity, "model", SPRITE);
		DispatchKeyValue(entity, "renderamt", "0");
		DispatchKeyValue(entity, "rendercolor", "0 0 0");
		DispatchSpawn(entity);

		float angle[3];
		GetClientEyeAngles(client, angle);

		TeleportEntity(entity, pos, angle, NULL_VECTOR);
		TeleportEntity(client, NULL_VECTOR, angle, NULL_VECTOR);

		SetVariantString("!activator");
		AcceptEntityInput(entity, "SetParent", client, entity, 0);
		SetClientViewEntity(client, entity);
		return entity;
	}
	return -1;
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

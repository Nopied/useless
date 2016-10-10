#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

public Plugin myinfo=
{
	name="DROP THE PROP!!",
	author="Nopied",
	description="",
	version="1.0",
};

//

bool enabled = false;
TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarModelPath;
Handle cvarSpellModelPath;
Handle cvarPropGainMaxHp;
Handle cvarPropBuffCount;
Handle cvarPropBuffTime;
Handle cvarPropMiniCritTime;
Handle cvarPropUberTime;
Handle cvarPropCloakTime;
Handle cvarPropSize;

char g_strModelPath[PLATFORM_MAX_PATH];
char g_strSpellModelPath[PLATFORM_MAX_PATH];

int g_iEatCount[MAXPLAYERS+1];
//

public void OnPluginStart()
{
  // TODO: NEED CVAR!
  cvarPropCount = CreateConVar("dp_prop_count", "1", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
  cvarPropVelocity = CreateConVar("dp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
  cvarPropGainMaxHp = CreateConVar("dp_heal_hp", "70", "프롭을 얻을 시, 얼마나 HP를 회복시킬 것 인가?", _, true, 0.0);
  cvarPropBuffCount = CreateConVar("dp_gain_buff_count", "5", "버프를 얻기 위한 얻어야 될 프롭 갯수", _, true, 0.0);
  cvarPropBuffTime =  CreateConVar("dp_gain_buff_time", "5.0", "스피드 버프(징계조치 효과)의 지속 시간", _, true, 0.1);
  cvarPropForNoBossTeam = CreateConVar("dp_prop_for_team", "2", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
  cvarModelPath = CreateConVar("dp_prop_model_path", "", "이걸 꼭 기재하셔야 프롭을 소환할 수 있습니다.");
  cvarPropMiniCritTime = CreateConVar("dp_gain_minicrit_time", "6.0", "미니크리의 지속 시간", _, true, 0.1);
  cvarPropUberTime = CreateConVar("dp_gain_uber_time", "10.0", "우버의 지속 시간", _, true, 0.1);
  cvarPropCloakTime = CreateConVar("dp_gain_cloak_time", "8.0", "은폐 지속시간", _, true, 0.1);
  cvarSpellModelPath = CreateConVar("dp_spellprop_model_path", "", "특별한 프롭의 모델, 기입하지 않을 경우 일반 프롭과 동일");
  cvarPropSize = CreateConVar("dp_prop_size", "50.0", "캡슐 섭취 범위", _, true, 0.1);

  HookEvent("player_spawn", OnPlayerSpawn);
  HookEvent("player_death", OnPlayerDeath);

  // PrecacheThings();
  CreateTimer(0.2, PrecacheTimer);
}

public void OnMapStart()
{
	CreateTimer(0.2, PrecacheTimer);
}

public Action PrecacheTimer(Handle timer)
{
	PrecacheThings();
}

void PrecacheThings()
{
	PropForTeam = view_as<TFTeam>(GetConVarInt(cvarPropForNoBossTeam));
 	GetConVarString(cvarModelPath, g_strModelPath, sizeof(g_strModelPath));
	GetConVarString(cvarSpellModelPath, g_strSpellModelPath, sizeof(g_strSpellModelPath));

	if(g_strModelPath[0] != '\0')
	{
		if(FileExists(g_strModelPath, true))
		{
			PrecacheModel(g_strModelPath);
			enabled = true;
		}
		else
		{
			enabled = false;
			LogError("모델 파일이 존재하지 않습니다!");
		}
	}
	else
	{
		LogError("모델 경로를 기입하여 주시길 바랍니다!");
		enabled = false;
	}

	if(g_strSpellModelPath[0] != '\0' && FileExists(g_strSpellModelPath, true))
	{
		PrecacheModel(g_strSpellModelPath);
	}
	else
	{
		LogError("특별한 캡슐의 모델이 존재하지 않습니다!");
		enabled = false;
	}
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
	if(!enabled)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_iEatCount[client] = 0;
	return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

  	if(!enabled || !IsCorrectTeam(client) || CheckRoundState() != 1)
  	{
    	return Plugin_Continue;
  	}

	bool IsFake = false;
	if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
		IsFake = true;

  	for(int count = 0; count < GetConVarInt(cvarPropCount); count++)
  	{
    	int prop = CreateEntityByName("prop_physics_override");
    	if(IsValidEntity(prop))
    	{
      		SetEntityModel(prop, g_strModelPath);
      		SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
      		SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);
      		// SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16); // 0x0004
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
      		DispatchSpawn(prop);
			TF2_CreateGlow(prop);

      		float position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

      		float velocity[3];
      		velocity[0] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      		velocity[1] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      		velocity[2] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      		NormalizeVector(velocity, velocity);

      		TeleportEntity(prop, position, NULL_VECTOR, velocity);
	  		// TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);

			if(IsFake)
			{
				/*
				SDKHook(prop, SDKHook_Touch, FakePickup);
	      		SDKHook(prop, SDKHook_StartTouch, FakePickup);
				*/
				CreateTimer(2.0, FakePickup, EntIndexToEntRef(prop));
				SDKHook(prop, SDKHook_SetTransmit, FakePropTransmit);

			}
			else
			{
				/*
				SDKHook(prop, SDKHook_Touch, OnPickup);
	      		SDKHook(prop, SDKHook_StartTouch, OnPickup);
				*/
				CreateTimer(0.05, OnPickup, EntIndexToEntRef(prop));
			}
    	}
  	}

	// 스파이 스나이퍼 전용
	if(TF2_GetPlayerClass(client) == TFClass_Spy || TF2_GetPlayerClass(client) == TFClass_Sniper)
	{
		int prop = CreateEntityByName("prop_physics_override");
		if(IsValidEntity(prop))
		{
			SetEntityModel(prop, g_strSpellModelPath);
			SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);
			// SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16); // 0x0004
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
			DispatchSpawn(prop);
			TF2_CreateGlow(prop);

			float position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

			float velocity[3];
			velocity[0] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
			velocity[1] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
			velocity[2] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
			NormalizeVector(velocity, velocity);

			TeleportEntity(prop, position, NULL_VECTOR, velocity);
			// TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);

			if(IsFake)
			{
				/*
				SDKHook(prop, SDKHook_Touch, FakePickup);
				SDKHook(prop, SDKHook_StartTouch, FakePickup);
				*/
				CreateTimer(2.0, FakePickup, EntIndexToEntRef(prop));
				SDKHook(prop, SDKHook_SetTransmit, FakePropTransmit);
			}
			else
			{
				/*
				SDKHook(prop, SDKHook_Touch, OnSpellPickup);
				SDKHook(prop, SDKHook_StartTouch, OnSpellPickup);
				*/
				CreateTimer(0.05, OnSpellPickup, EntIndexToEntRef(prop));
			}
		}
	}

  	g_iEatCount[client] = 0;
  	return Plugin_Continue;
}

public Action FakePropTransmit(int entity, int client)
{
	if(IsCorrectTeam(client))
		return Plugin_Handled;

	return Plugin_Continue;
}

/*
public Action OnStuckTest(Handle timer, int entity)
{
	if(!IsValidEntity(entity))
		return Plugin_Continue;

	if(!IsEntityStuck(entity))
	{
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 5);
		return Plugin_Stop;
		// SDKUnhook(entity, SDKHook_PreThinkPost, OnStuckTest);
	}
	else
	{
		SetEntityMoveType(entity, MOVETYPE_VPHYSICS);
	}

	CreateTimer(0.02, OnStuckTest, entity);
	return Plugin_Continue;
}
*/

public Action OnPickup(Handle timer, int entRef) // Copied from FF2
{
	int entity = EntRefToEntIndex(entRef);
	if(!IsValidEntity(entity))
		return Plugin_Handled;

	int client = IsEntityStuck(entity);
	if(IsValidClient(client))
	{
		if(IsCorrectTeam(client))
		{
			char centerMessage[100];
			g_iEatCount[client]++;

			// 버프
			SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + GetConVarInt(cvarPropGainMaxHp));
			TF2_AddCondition(client, TFCond_SpeedBuffAlly, GetConVarFloat(cvarPropBuffTime));
			TF2_AddCondition(client, TFCond_Buffed, GetConVarFloat(cvarPropMiniCritTime));

			// 메세지
			Format(centerMessage, sizeof(centerMessage), "%i개를 얻었습니다!", g_iEatCount[client]);
		    // PrintCenterText(client, "%i개 주웠습니다!");
			int remaining=0;

			for(int count = 1; remaining < g_iEatCount[client]; count++)
			{
				remaining = GetConVarInt(cvarPropBuffCount) * count;
			}

			if(remaining - g_iEatCount[client] == 0) // 일정 갯수를 얻었을 경우
			{
			  	Format(centerMessage, sizeof(centerMessage), "%s\n잠시동안 버프를 받게됩니다!", centerMessage);
				TF2_AddCondition(client, TFCond_Ubercharged, GetConVarFloat(cvarPropUberTime));
				SetEntProp(client, Prop_Data, "m_takedamage", 0);
				CreateTimer(GetConVarFloat(cvarPropUberTime), EnableTakeDamage, client, TIMER_FLAG_NO_MAPCHANGE);
			}
			else
			{
		    	Format(centerMessage, sizeof(centerMessage), "%s [ 버프까지 남은 갯수: %i / %i ]", centerMessage, remaining - g_iEatCount[client], GetConVarInt(cvarPropBuffCount));
			}

			PrintCenterText(client, centerMessage);

			AcceptEntityInput(entity, "kill");
			return Plugin_Handled;
		}
		else if(!IsCorrectTeam(client))
		{
		  KickEntity(client, entity);
		}
	}

	CreateTimer(0.05, OnPickup, EntIndexToEntRef(entity));
	return Plugin_Continue;
}

public Action EnableTakeDamage(Handle timer, int client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2);
	}
}


public Action OnSpellPickup(Handle timer, int entRef) // Copied from FF2
{
	int entity = EntRefToEntIndex(entRef);
	if(!IsValidEntity(entity))
		return Plugin_Handled;

	int client = IsEntityStuck(entity);
	if(IsValidClient(client))
	{
		if(IsCorrectTeam(client))
		{
			char centerMessage[100];
			// 버프
			TF2_AddCondition(client, TFCond_Stealthed, GetConVarFloat(cvarPropCloakTime));
			TF2_AddCondition(client, TFCond_StealthedUserBuffFade, GetConVarFloat(cvarPropCloakTime));

			// 메세지
			Format(centerMessage, sizeof(centerMessage), "특별한 캡슐을 얻었습니다!");
			PrintCenterText(client, centerMessage);

			AcceptEntityInput(entity, "kill");
			return Plugin_Handled;
		}
		else if(!IsCorrectTeam(client))
		{
		  KickEntity(client, entity);
		}
	}
	CreateTimer(0.05, OnSpellPickup, EntIndexToEntRef(entity));
	return Plugin_Continue;
}

public Action FakePickup(Handle timer, int entRef)
{
	int entity = EntRefToEntIndex(entRef);
	if(!IsValidEntity(entity))
		return Plugin_Handled;

	int client = IsEntityStuck(entity);
	if(IsValidClient(client))
	{
		if(!IsCorrectTeam(client))
		{
			KickEntity(client, entity);
		}
		else
		{
			AcceptEntityInput(entity, "kill");
			return Plugin_Handled;
		}
	}

	CreateTimer(0.05, FakePickup, EntIndexToEntRef(entity));
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

	angVector[0] *= 1200.0;
	angVector[1] *= 1200.0;
	angVector[2] *= 1200.0;

	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, angVector);
	SetEntProp(entity, Prop_Send, "m_CollisionGroup", 2);
	// SDKHook(entity, SDKHook_PreThinkPost, OnStuckTest);
	// CreateTimer(0.02, OnStuckTest, entity);
}

stock bool IsCorrectTeam(int client)
{
	if(PropForTeam != TFTeam_Red && PropForTeam != TFTeam_Blue)
		return true;

	return PropForTeam == TF2_GetClientTeam(client);
}

stock int IsEntityStuck(int entity) // Copied from Chdata's FFF
{/*
 	float vecMin[3], vecMax[3], vecOrigin[3];

    GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, entity);
    if(TR_DidHit())
	{
		return TR_GetEntityIndex();
	}
	return -1;
	*/
	float vecOrigin[3], playerOrigin[3];
	float propsize = GetConVarFloat(cvarPropSize);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vecOrigin);

	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client))
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", playerOrigin);

			if(CheckCollision(vecOrigin, playerOrigin, propsize))
				return client;
		}
	}

	return -1;
}

public bool TraceRayPlayerOnly(int ent, int mask, int data)
{
    return (IsValidEntity(ent) && IsValidClient(ent) && ent != data);
}

stock bool IsValidClient(int client)
{
    return (0 < client && client<=MaxClients && IsClientInGame(client));
}

int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
}

stock int TF2_CreateGlow(int iEnt)
{
	char strName[126], strClass[64];
	GetEntityClassname(iEnt, strClass, sizeof(strClass));
	Format(strName, sizeof(strName), "%s%i", strClass, iEnt);
	DispatchKeyValue(iEnt, "targetname", strName);

	char strGlowColor[18];
	Format(strGlowColor, sizeof(strGlowColor), "%i %i %i %i", GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(180, 255));

	int ent = CreateEntityByName("tf_glow");
	DispatchKeyValue(ent, "targetname", "RainbowGlow");
	DispatchKeyValue(ent, "target", strName);
	DispatchKeyValue(ent, "Mode", "0");
	DispatchKeyValue(ent, "GlowColor", strGlowColor);
	DispatchSpawn(ent);

	AcceptEntityInput(ent, "Enable");

	return ent;
}

stock bool CheckCollision(float cylinderOrigin[3], float colliderOrigin[3], float maxDistance)// (float cylinderOrigin[3], float colliderOrigin[3], float maxDistance, float zMin, float zMax)
{
/*
	if (colliderOrigin[2] < zMin || colliderOrigin[2] > zMax)
		return false;
*/
	return GetVectorDistance(cylinderOrigin, colliderOrigin) <= maxDistance;
}

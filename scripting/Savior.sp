#include <sourcemod>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <morecolors>
#include <tf2attributes>

bool IsSavior[MAXPLAYERS+1];
bool SaviorBlocked[MAXPLAYERS+1];
bool ShieldStatus[MAXPLAYERS+1];
bool SaviorRocketStatus[MAXPLAYERS+1]=true;
bool ButtonPress[MAXPLAYERS+1]=false;
// true: if shield is not downed.
// flase: if shield is downed. LOL.
float g_flSaviorShield[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "Savior",
	description = "Test for Savior.",
	author = "Nopied◎",
	version = "TEST",
};

public void OnPluginStart()
{
	RegConsoleCmd("savior", CmdTurnToBeSavior);

	HookEvent("arena_round_start", OnRoundStart, EventHookMode_Post);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
	for(int client=1; client<=MaxClients; client++)
	{
		if(IsValidClient(client) && IsSavior[client])	DisableSavior(client);
	}
	return Plugin_Continue;
}

public Action CmdTurnToBeSavior(int client, int args)
{
	if(!IsSavior[client]) EnableSavior(client);
	else DisableSavior(client);

	return Plugin_Continue;
}

public Action RocketCooldown(Handle timer, int client)
{
	SaviorRocketStatus[client]=true;
	return Plugin_Continue;
}

public void Savior_Tick(int client)
{
	if(!IsSavior[client] || !IsValidClient(client) || !IsPlayerAlive(client)){
		DisableSavior(client);
		return; //
	}

	if(ShieldStatus[client])
	{
		// TF2_AddCondition(client, TFCond_DisguisedAsDispenser, TFCondDuration_Infinite, 0);

		int ent=-1;
		while((ent=FindEntityByClassname(ent, "tf_projectile_*")) != -1)
		{
			if(IsValidEntity(ent))
			{
				float velocity[3]; float clientPos[3]; float proOri[3];
				GetClientEyePosition(client, clientPos);
				GetEntPropVector(ent, Prop_Data, "m_vecOrigin", proOri);
				GetEntPropVector(ent, Prop_Data, "m_vecVelocity", velocity);
				if(GetVectorDistance(clientPos, proOri) <= 300.0)
				{
					velocity[0]=GetRandomFloat(-velocity[0], velocity[0]);
					velocity[1]=GetRandomFloat(-velocity[1], velocity[1]);
					velocity[2]=GetRandomFloat(-velocity[2], velocity[2]);

					float angles[3];
					GetVectorAngles(velocity, angles);
					TeleportEntity(ent, NULL_VECTOR, angles, velocity);
				}
			}
		}
	}

	int buttons = GetClientButtons(client);
/*	if(IsPlayerStuck(client)){ // 쓸모없어..
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[0]=(velocity[0]*-1.0); //+(velocity[0] ? 10 : -10)
		velocity[1]=(velocity[1]*-1.0);
		velocity[2]=(velocity[2]*-1.0);

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

		SDKHooks_TakeDamage(client, client, client, 3.0, DMG_BLAST, -1);
	}
*/

	if(SaviorRocketStatus[client] && buttons & IN_ATTACK2){
		// PrintToChatAll("우클릭 감지");
		int ent=SpawnRocket(client, true);
		if(!IsValidEntity(ent)){
			return;
		}
		// 	PrintToChatAll("감지된 로켓: %d", ent);
		SaviorRocketStatus[client]=false;

		//float rocketVelocity[3];
		float clientPos[3]; float angles[3]; float angVector[3]; float vecrt[3];
		GetClientEyeAngles(client, angles);
		GetClientEyePosition(client, clientPos);

		GetAngleVectors(angles, angVector, vecrt, NULL_VECTOR);
		NormalizeVector(angVector, angVector);

		//GetAngleVectors(angles, rocketVelocity, vcfl, NULL_VECTOR);

		// ScaleVector();
		angVector[0]*=1500.0;	// Test this,
		angVector[1]*=1500.0;
		angVector[2]*=1500.0;

		TeleportEntity(ent, clientPos, angles, angVector);
		TF2Attrib_SetByDefIndex(ent, 488, 1.0);
		CreateTimer(0.25, RocketCooldown, client);
	}

	if(SaviorBlocked[client])
	{
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[2]=10.0;// velocity[2]*-1.0;

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}

	if(!ButtonPress[client] && SaviorBlocked[client] && buttons & IN_RELOAD)
	{
		ButtonPress[client]=true;
		SaviorBlocked[client]=false;
		PrintCenterText(client, "고도의 고정이 헤체되었습니다.");
		CreateTimer(0.5, ButtonTimer, client);
	}
	else if(!ButtonPress[client] && !SaviorBlocked[client] && buttons & IN_RELOAD)
	{
		ButtonPress[client]=true;
		SaviorBlocked[client]=true;
		PrintCenterText(client, "고도가 고정되었습니다.");
		CreateTimer(0.5, ButtonTimer, client);
	}
	else if(buttons & IN_JUMP)
	{
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[2]+=30.0;

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);
	}

	if(g_flSaviorShield[client] <= 100.0) g_flSaviorShield[client]+=0.01; //TODO: 커스터마이즈.
	if(!ShieldStatus[client] && g_flSaviorShield[client]>=50.0){
		RestoreShield(client);
	}
}

public Action ButtonTimer(Handle timer, int client)
{
	ButtonPress[client]=false;
}

public void Savior_TakeDamage(int victim, int attacker, int inflictor, float damage, int damagetype)
{
	if(ShieldStatus[victim]){
		g_flSaviorShield[victim]-=damage/1000.0; // TODO: 커스터마이즈.
		PrintToServer("남은 쉴드 %.1f", g_flSaviorShield[victim]);
		if(!g_flSaviorShield[victim]){
			BlockShield(victim);
		}
		return;
	}
	return;
}

void EnableSavior(int client)
{
	if(!IsPlayerAlive(client) || IsSavior[client]) return;
	IsSavior[client]=true;
	SaviorRocketStatus[client]=true;
	/* TODO:
		- 플레이어 스크린 오버레이 변경
		- 무기 부여
		- 무기 조작법 추가. (우클릭 로켓발사)
		- 쉴드 시스템 추가
		- 사운드 추가
		- 모델은..?
	*/
	RestoreShield(client, _, false);
	SDKHook(client, SDKHook_PreThinkPost, Savior_Tick);
	SDKHook(client, SDKHook_OnTakeDamagePost, Savior_TakeDamage);
	SetOverlay(client, "Effects/combine_binocoverlay");
	CPrintToChat(client, "Savior 모드가 활성화되었습니다.");
}

void DisableSavior(int client)
{
	IsSavior[client]=false;
	// SetEntityMoveType(client, MOVETYPE_WALK);
	SDKUnhook(client, SDKHook_PreThinkPost, Savior_Tick);
	SDKUnhook(client, SDKHook_OnTakeDamagePost, Savior_TakeDamage);
	SetOverlay(client, "");
	CPrintToChat(client, "Savior 모드가 비활성화되었습니다.");
}

void RestoreShield(int client, float giveshield=0.0, bool notice=true)
{
	if(!IsSavior[client]) return;

	ShieldStatus[client]=true;
	if(giveshield) g_flSaviorShield[client]=giveshield;
	else g_flSaviorShield[client]=100.0;

	if(notice)	PrintCenterText(client, "쉴드가 회복되었습니다!");
}

void BlockShield(int client)
{
	//TODO: 사운드 추가
	if(!IsSavior[client] || !ShieldStatus[client]) return;

	TF2_RemoveCondition(client, TFCond_DisguisedAsDispenser);
	ShieldStatus[client]=false;
	g_flSaviorShield[client]=0.0;
	PrintCenterText(client, "쉴드가 깨졌습니다!");
}

void SetOverlay(client, const char[] overlay)
{
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") & ~FCVAR_CHEAT);
	ClientCommand(client, "r_screenoverlay \"%s\"", overlay);
	SetCommandFlags("r_screenoverlay", GetCommandFlags("r_screenoverlay") | FCVAR_CHEAT);
}

stock int SpawnRocket(int client, bool allowcrit)
{
	int ent=CreateEntityByName("tf_projectile_rocket");
	if(!IsValidEntity(ent)){
		 return -1;
		}
	int clientTeam=_:TF2_GetClientTeam(client);
	new damageOffset = FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4;

	SetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity", client);
	SetEntProp(ent, Prop_Send, "m_bCritical", allowcrit ? 1 : 0);
	SetEntProp(ent, Prop_Send, "m_iTeamNum", clientTeam);
	SetEntProp(ent, Prop_Send, "m_CollisionGroup", 4);
	SetEntProp(ent, Prop_Data, "m_takedamage", 0);
	// SetEntPropEnt(ent, Prop_Send, "m_nForceBone", -1);
	SetEntPropVector(ent, Prop_Send, "m_vecMins", Float:{0.0,0.0,0.0});
	SetEntPropVector(ent, Prop_Send, "m_vecMaxs", Float:{0.0,0.0,0.0});
	SetEntDataFloat(ent, damageOffset, 5.0); // set damage
	SetVariantInt(clientTeam);
	AcceptEntityInput(ent, "TeamNum", -1, -1, 0);
	SetVariantInt(clientTeam);
	AcceptEntityInput(ent, "SetTeam", -1, -1, 0);
	DispatchSpawn(ent);
	SetEntPropEnt(ent, Prop_Send, "m_hOriginalLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	SetEntPropEnt(ent, Prop_Send, "m_hLauncher", GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	return ent;
}

//Copied from Chdata's Fixed Friendly Fire
stock bool IsPlayerStuck(ent)
{
  float vecMin[3];
	float vecMax[3];
	float vecOrigin[3];

    GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, ent);
    return (TR_DidHit());
}

//Copied from Chdata's Fixed Friendly Fire
public bool:TraceRayPlayerOnly(iEntity, iMask, any:iData)
{
    return (IsValidClient(iEntity) && IsValidClient(iData) && iEntity != iData);
}

stock bool IsValidClient(int client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}

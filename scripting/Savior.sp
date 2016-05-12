#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

bool IsSavior[MAXPLAYERS+1];
bool ShieldStatus[MAXPLAYERS+1];
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
	HookEvent("projectile_direct_hit", OnDirectHit);
}

public Action OnDirectHit(Handle event, const char[] name, bool dont)
{
	// CPrintToChatAll("");
	// int client=GetEventInt(event, "victim");
	BlockShield(GetEventInt(event, "victim"));
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

public void Savior_Tick(int client)
{
	if(!IsSavior[client] || !IsValidClient(client) || !IsPlayerAlive(client)){
		DisableSavior(client);
		return; //
	}
	else if(IsPlayerStuck(client)){
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[0]=(velocity[0]*-1.0)+(velocity[0] ? 10 : -10);
		velocity[1]=(velocity[1]*-1.0)+(velocity[1] ? 10 : -10);
		velocity[2]=(velocity[2]*-1.0)+(velocity[2] ? 10 : -10);

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

		SDKHooks_TakeDamage(client, client, client, 3.0, DMG_BLAST, -1);
	}

	if(g_flSaviorShield[client] <= 100.0)g_flSaviorShield[client]+=0.01; //TODO: 커스터마이즈.
	if(!ShieldStatus[client] && g_flSaviorShield[client]>=50.0){
		RestoreShield(client);
	}
}

public Action Savior_TakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(ShieldStatus[victim]){
		g_flSaviorShield[victim]-=damage/1000.0; // TODO: 커스터마이즈.
		if(!g_flSaviorShield[victim]){
			BlockShield(victim);
		}
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void EnableSavior(int client)
{
	if(!IsPlayerAlive(client) || IsSavior[client]) return;
	IsSavior[client]=true;
	/* TODO:
		- 플레이어 스크린 오버레이 변경
		- 무기 부여
		- 무기 조작법 추가. (우클릭 로켓발사)
		- 쉴드 시스템 추가
		- 사운드 추가
		- 모델은..?
	*/
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	RestoreShield(client);
	SDKHook(client, SDKHook_PreThinkPost, Savior_Tick);
	SDKHook(client, SDKHook_OnTakeDamage, Savior_TakeDamage);
	CPrintToChat(client, "Savior 모드가 활성화되었습니다.");
}

void DisableSavior(int client)
{
	IsSavior[client]=false;
	SetEntityMoveType(client, MOVETYPE_WALK);
	SDKUnhook(client, SDKHook_PreThinkPost, Savior_Tick);
	SDKUnhook(client, SDKHook_OnTakeDamage, Savior_TakeDamage);
	CPrintToChat(client, "Savior 모드가 비활성화되었습니다.");
}

void RestoreShield(int client, float giveshield=0.0)
{
	if(!IsSavior[client]) return;

	ShieldStatus[client]=true;
	if(giveshield) g_flSaviorShield[client]=giveshield;
	else g_flSaviorShield[client]=100.0;
}

void BlockShield(int client)
{
	//TODO: 사운드 추가
	if(!IsSavior[client]) return;

	ShieldStatus[client]=false;
	g_flSaviorShield[client]=0.0;
	PrintCenterText(client, "쉴드가 깨졌습니다!");
}

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

stock bool IsValidClient(int client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}

#include <sourcemod>
#include <sdkhooks>
#include <morecolors>

bool IsSavior[MAXPLAYERS+1];

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
		if(IsValidClient(client))	DisableSavior(client);
	}
	return Plugin_Continue;
}

public Action CmdTurnToBeSavior(int client, int args)
{
	TurnToBeSavior(client);
	return Plugin_Continue;
}

public void Savior_Tick(int client)
{
	if(!IsSavior[client] || !IsValidClient(client) || !IsPlayerAlive(client))
		DisableSavior(client);
	else if(IsPlayerStuck(client))
	{
		float velocity[3];
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

		velocity[0]=(velocity[0]*-1.0)+(velocity[0] ? 200 : -200);
		velocity[1]=(velocity[1]*-1.0)+(velocity[1] ? 200 : -200);
		velocity[2]=(velocity[2]*-1.0)+(velocity[2] ? 200 : -200);

		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, velocity);

		SDKHooks_TakeDamage(client, client, client, 3.0, DMG_BLAST, -1);
	}

}

void EnableSavior(int client)
{
	IsSavior[client]=true;
	/* TODO:
		- 플레이어 스크린 오버레이 변경
		- 무기 부여
		- 무기 조작법 추가. (우클릭 로켓발사)
		- 쉴드 시스템 추가
		- 사운드 추가
	*/
	SetEntityMoveType(client, MOVETYPE_NOCLIP);
	SDKHook(client, SDKHook_PreThinkPost, Savior_Tick);
	CPrintToChat(client, "Savior 모드가 활성화되었습니다.");
}

void DisableSavior(int client)
{
	IsSavior[client]=false;
	SetEntityMoveType(client, MOVETYPE_WALK);
	SDKUnhook(client, SDKHook_PreThinkPost, Savior_Tick);
	CPrintToChat(client, "Savior 모드가 비활성화되었습니다.");
}

stock bool IsPlayerStuck(ent)
{
    float vecMin[3], float vecMax[3], float vecOrigin[3];

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

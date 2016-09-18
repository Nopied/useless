#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <clientprefs>

/*

참고사항: BossQueue가 -1 이하일 경우, 보스 안함이 설정된 상태.
테스트가 필요함.

*/

#define PLUGIN_VERSION "2.1"
#define MAX_NAME 126
// #define INFINITE_BLASTER_NAME "INFINITE BLASTER"

int g_iChatCommand;

char Incoming[MAXPLAYERS+1][64];
char BlasterIncoming[MAXPLAYERS+1][64];
char g_strChatCommand[42][50]; // 이 말은 즉슨.. 42개 이상의 커맨드를 등록하면 이 플러그인은 터진다.

Handle g_hBossCookie;
Handle g_hBossQueue;
Handle g_hCvarChatCommand;

Handle g_hInfiniteBlasterCookie;
// Handle g_hInfiniteBlasterDataPack;
// Handle g_hCvarLanguage;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection EX",
	description = "Allows players select their bosses by /ff2boss (Need 1.10.6+)",
	author = "Nopied◎",
	version = PLUGIN_VERSION,
};

public void OnPluginStart()
{
	int version[3];
	FF2_GetFF2Version(version);
	if(version[0]==1 && (version[1]<10 || (version[1]==10 && version[2]<6)))
	{
		SetFailState("This version of FF2 Boss Selection requires at least FF2 v1.10.6!");
	}

	g_hCvarChatCommand = CreateConVar("ff2_bossselection_chatcommand", "ff2boss,boss,보스,보스선택");
	// g_hCvarLanguage = CreateConVar("ff2_bossselection_default", "en");

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("boss", Command_SetMyBoss, "Set my boss");

	g_hBossCookie  = RegClientCookie("BossCookie", "Bosses name", CookieAccess_Protected);
	g_hBossQueue = RegClientCookie("QueuePoint", "", CookieAccess_Protected);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2_boss_selection");

	HookEvent("teamplay_round_win", OnRoundEnd);

	ChangeChatCommand();
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
	for(int client = 1; client<=MaxClients; client++)
	{
		if(IsClientInGame(client) && IsBoss(client) && IsPlayerChargingBlaster(client))
		{
			SetBarrierDamaged(client, BlasterIncoming[client], GetBarrierDamaged(client, BlasterIncoming[client]) + RoundFloat(GetGameTime()));
			if(GetBarrierDamaged(client, BlasterIncoming[client]) >= GetBarrierMaxHealth(BlasterIncoming[client]))
			{
				SetClientBossBlast(client, BlasterIncoming[client], true);
				CPrintToChat(client, "{lightblue}[INF-B]{default} 축하드립니다! {orange}%s{default}를 다음부터 즐기실 수 있습니다!", BlasterIncoming[client]);
				AbleInfiniteBlaster(client, false);
			}
			else
			{
				CPrintToChat(client, "{lightblue}[INF-B]{default} {orange}%s{default}의 남은 베리어 HP: %i / %i",
				BlasterIncoming[client],
				GetBarrierMaxHealth(BlasterIncoming[client]) - GetBarrierDamaged(client, BlasterIncoming[client])
				, GetBarrierMaxHealth(BlasterIncoming[client]));
			}
		}
	}
}

public void Cvar_ChatCommand_Changed(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	ChangeChatCommand();
}

public void OnMapStart()
{
	ChangeChatCommand();
}

void ChangeChatCommand()
{
	g_iChatCommand = 0;

	char cvarV[MAX_NAME];
	GetConVarString(g_hCvarChatCommand, cvarV, sizeof(cvarV));

	for (int i=0; i<ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[FF2boss] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
	}
}

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	char strChat[100];
	char temp[2][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 2, 64, true);

	for (int i=0; i<=g_iChatCommand; i++)
	{
		if(StrEqual(temp[0], g_strChatCommand[i], true))
		{
			/*
			if(temp[1][0] != '\0')
			{
				CheckBossName(client, temp[1]);
				return Plugin_Continue;
			}
			*/
			Command_SetMyBoss(client, 0);
			return Plugin_Continue;
		}
	}

	return Plugin_Continue;
}

public Action FF2_OnAddQueuePoints(add_points[MAXPLAYERS+1])
{
		int queuepoints;

		for (int client=1; client<=MaxClients; client++)
		{
			if(IsValidClient(client) && !IsBoss(client))
			{
				queuepoints=GetClientQueueCookie(client);
				if(queuepoints >= 0)
				{
					if(FF2_GetQueuePoints(client))
					{
						SetClientQueueCookie(client, queuepoints+FF2_GetQueuePoints(client));
					}

					add_points[client]=0;
					FF2_SetQueuePoints(client, -1);
				}
				else
				{
					LogMessage("%N의 대기열 포인트: %d, 저장된 대기열포인트: %d", client, FF2_GetQueuePoints(client), GetClientQueueCookie(client));
				}
			}
		}
		return Plugin_Changed;
}


public void OnClientPutInServer(client)
{
	char CookieV[MAX_NAME];

	if(AreClientCookiesCached(client))
	{
		GetClientCookie(client, g_hBossQueue, CookieV, sizeof(CookieV));
		if(CookieV[0] == '\0')
		{
			SetClientCookie(client, g_hBossCookie, "");
			Format(CookieV, sizeof(CookieV), "%d", -1); // 만약에 대비해..
			SetClientCookie(client, g_hBossQueue, CookieV);
		}
		else
		{
			GetClientCookie(client, g_hBossCookie, CookieV, sizeof(CookieV));
			strcopy(Incoming[client], sizeof(Incoming[]), CookieV);
			GetBlasterIncomingString(client, CookieV, sizeof(CookieV));
			strcopy(BlasterIncoming[client], sizeof(BlasterIncoming[]), CookieV);
		}
	}
}

public Action Command_SetMyBoss(int client, int args)
{
	if (client == 0)
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_ingame_only");
		return Plugin_Handled;
	}

	if (!CheckCommandAccess(client, "ff2_boss", 0, true))
	{
		ReplyToCommand(client, "[SM] %t", "ff2boss_noaccess");
		return Plugin_Handled;
	}

	char spclName[MAX_NAME];
	Handle BossKV;
	char CookieV[MAX_NAME];
	int queuepoints;
/*
	if(args)
	{
		char bossName[64];
		GetCmdArgString(bossName, sizeof(bossName));
		PrintToChatAll("%s", bossName);

		CheckBossName(client, bossName);
		return Plugin_Handled;
	}
*/

	GetClientCookie(client, g_hBossCookie, CookieV, sizeof(CookieV));
	char s[MAX_NAME];

	Handle dMenu = CreateMenu(Command_SetMyBossH);

	if(IsPlayerChargingBlaster(client))
	{
		SetMenuTitle(dMenu, "INFINITE BLASTER IS CHARGING...\n(다른 보스를 선택할 경우 비활성화 됩니다.)");
	}
	else if(StrEqual(CookieV, ""))
	{
		Format(s, sizeof(s), "%t", "ff2boss_random_option");
		SetMenuTitle(dMenu, "%t", "ff2boss_title", s);
	}
	else
	{
		GetClientCookie(client, g_hBossQueue, CookieV, sizeof(CookieV));
		queuepoints=StringToInt(CookieV);
		Format(s, sizeof(s), queuepoints>=0 ? "%t" : "%s", queuepoints>=0 ? "ff2boss_none_1":Incoming[client]);
		SetMenuTitle(dMenu, "%t", "ff2boss_title", s);
	}

	Format(s, sizeof(s), "%t", "ff2boss_random_option");
	AddMenuItem(dMenu, "Random Boss", s);
	Format(s, sizeof(s), "%t", "ff2boss_none_1");
	AddMenuItem(dMenu, "None", s);

	for (int i=0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		if (KvGetNum(BossKV, "blocked",0)) continue;
		if (KvGetNum(BossKV, "hidden",0)) continue;
		KvGetString(BossKV, "name", spclName, 64);
		AddMenuItem(dMenu,spclName,spclName);
	}
	SetMenuExitButton(dMenu, true);
	DisplayMenu(dMenu, client, 90);
	return Plugin_Handled;
}


public Command_SetMyBossH(Handle menu, MenuAction action, int param1, int param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}

		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
				{
					Incoming[param1] = "";

					SetClientCookie(param1, g_hBossCookie, Incoming[param1]);
					AbleInfiniteBlaster(param1, false);
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_randomboss");
					SetClientQueueNoneCookie(param1, false);
				}
				case 1:
				{
					SetClientQueueNoneCookie(param1, true);
					AbleInfiniteBlaster(param1, false);
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_none");
				}
				default:
				{
					char bossName[80];
					GetMenuItem(menu, param2, bossName, sizeof(bossName));

					if(IsBossBlasted(param1, bossName))
					{
						AbleInfiniteBlaster(param1, false);
						GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
						SetClientCookie(param1, g_hBossCookie, Incoming[param1]);
						CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
						SetClientQueueNoneCookie(param1, false);
					}
					else
					{
						Handle Nmenu = CreateMenu(BlasterMenu);
						int barrierMaxhp = GetBarrierMaxHealth(bossName);
						strcopy(BlasterIncoming[param1], sizeof(BlasterIncoming[]), bossName);

						SetMenuTitle(Nmenu, "INFINITE BLASTER\n-------------------\n선택하신 그 보스(%s)는 선택하기 위해서는\n다른 보스로 활약하여 배리어 HP를 0으로 만들어야 합니다!\n\n도전할 경우 무작위 보스, 무작위 난이도로 싸우게됩니다!\n---------------\n현재 배리어 HP: %i / %i",
						bossName,
						barrierMaxhp - GetBarrierDamaged(param1, bossName),
						barrierMaxhp);

						AddMenuItem(Nmenu, "예", "네, 도전하겠습니다!");
						AddMenuItem(Nmenu, "아니요", "아니요..");

						DisplayMenu(Nmenu, param1, 90);
					}
				}
			}
		}
	}
}

public BlasterMenu(Handle menu, MenuAction action, int client, int item)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}

		case MenuAction_Select:
		{
			switch(item)
			{
				case 0:
				{
					SetClientQueueNoneCookie(client, false);
					SetClientCookie(client, g_hBossCookie, "");
					CPrintToChat(client, "{lightblue}[INF-B]{default} 당신의 다음 보스 라운드에 활성화됩니다. 준비하세요!");
					AbleInfiniteBlaster(client, true);
				}

				case 1:
				{
					CloseHandle(menu);
				}
			}
		}
	}
}

public void GetBlasterIncomingString(client, char[] bossName, int buffer)
{
	g_hInfiniteBlasterCookie = RegClientCookie("INF-B", ".", CookieAccess_Protected);
	GetClientCookie(client, g_hInfiniteBlasterCookie, bossName, buffer);
}

void AbleInfiniteBlaster(int client, bool enable)
{
	g_hInfiniteBlasterCookie = RegClientCookie("INF-B", ".", CookieAccess_Protected);

	// char CookieV[100];

	if(enable)
	{
		SetClientCookie(client, g_hInfiniteBlasterCookie, BlasterIncoming[client]);
	}
	else
	{
		SetClientCookie(client, g_hInfiniteBlasterCookie, "");
	}
}

bool IsPlayerChargingBlaster(int client)
{
	g_hInfiniteBlasterCookie = RegClientCookie("INF-B", ".", CookieAccess_Protected);

	char temp[30];
	GetClientCookie(client, g_hInfiniteBlasterCookie, temp, sizeof(temp));

	return temp[0] != '\0';
}

void SetClientBossBlast(int client, const char[] bossName, bool enable)
{
	char temp[100];
	Format(temp, sizeof(temp), "blaster_%s", bossName);
	g_hInfiniteBlasterCookie = RegClientCookie(temp, "sdvx?", CookieAccess_Protected);

	if(enable)
	{
		SetClientCookie(client, g_hInfiniteBlasterCookie, "1");
	}
	else
	{
		SetClientCookie(client, g_hInfiniteBlasterCookie, "0");
		SetBarrierDamaged(client, bossName, 0);
	}
}

int GetBarrierDamaged(int client, const char[] bossName)
{
	Handle BossKV = GetBossNameHandle(bossName);
	if(BossKV != INVALID_HANDLE)
	{
		char temp[100];
		Format(temp, sizeof(temp), "blaster_damaged_%s", bossName);

		g_hInfiniteBlasterCookie = RegClientCookie(temp, ".", CookieAccess_Protected);
		GetClientCookie(client, g_hInfiniteBlasterCookie, temp, sizeof(temp));

		return StringToInt(temp);
	}

	return -1;
}

void SetBarrierDamaged(int client, const char[] bossName, int damage)
{
	Handle BossKV = GetBossNameHandle(bossName);
	if(BossKV != INVALID_HANDLE)
	{
		char temp[100];
		Format(temp, sizeof(temp), "blaster_damaged_%s", bossName);

		g_hInfiniteBlasterCookie = RegClientCookie(temp, ".", CookieAccess_Protected);

		Format(temp, sizeof(temp), "%i", damage);
		SetClientCookie(client, g_hInfiniteBlasterCookie, temp);
	}
}

int GetBarrierMaxHealth(const char[] bossName)
{
	Handle BossKV = GetBossNameHandle(bossName);
	if(BossKV != INVALID_HANDLE)
	{
		return KvGetNum(BossKV, "barrier_hp", 0);
	}

	return -1;
}

Handle GetBossNameHandle(const char[] bossName)
{
	Handle BossKV;
	char spclName[MAX_NAME];

	for (int i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		KvGetString(BossKV, "name", spclName, sizeof(spclName));
		if(StrEqual(bossName, spclName, true))
		{
			KvRewind(BossKV);
			return BossKV;
		}
	}

	return INVALID_HANDLE;
}

/*
stock void CheckBossName(int client, const char[] bossName)
{
	Handle BossKV;
	char spclName[MAX_NAME];

	for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		if (KvGetNum(BossKV, "blocked",0)) continue;
		if (KvGetNum(BossKV, "hidden",0)) continue;
		KvGetString(BossKV, "name", spclName, sizeof(spclName));

		if(StrContains(bossName, spclName, false)!=-1)
		{
			strcopy(Incoming[client], sizeof(Incoming[]), spclName);
			SetClientCookie(client, g_hBossCookie, Incoming[client]);

			CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
			return;
		}

		KvGetString(BossKV, "filename", spclName, sizeof(spclName));
		if(StrContains(bossName, spclName, false)!=-1)
		{
			KvGetString(BossKV, "name", spclName, sizeof(spclName));
			strcopy(Incoming[client], sizeof(Incoming[]), spclName);
			SetClientCookie(client, g_hBossCookie, Incoming[client]);

			CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
			return;
		}
	}
	CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossnotfound");
}
*/
stock bool IsBossBlasted(int client, const char[] bossName)
{
	char temp[100];
	Format(temp, sizeof(temp), "blaster_%s", bossName);

	g_hInfiniteBlasterCookie = RegClientCookie(temp, "sdvx?", CookieAccess_Protected);
	GetClientCookie(client, g_hInfiniteBlasterCookie, temp, sizeof(temp));
	return StringToInt(temp) == 1;
}


public Action FF2_OnSpecialSelected(boss, &SpecialNum, char[] SpecialName, bool preset)
{
	if(preset) return Plugin_Continue;

	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (!boss && !StrEqual(Incoming[client], ""))
	{
		strcopy(SpecialName, sizeof(Incoming[]), Incoming[client]);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

stock bool IsValidClient(client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}

stock bool IsBoss(int client)
{
	return (FF2_GetBossIndex(client) != -1);
}

stock int GetClientQueueCookie(int client)
{
	char CookieV[MAX_NAME];

	GetClientCookie(client, g_hBossQueue, CookieV, sizeof(CookieV));
	return	StringToInt(CookieV);
}

stock void SetClientQueueCookie(int client, int points)
{
	char CookieV[50];

	GetClientCookie(client, g_hBossQueue, CookieV, sizeof(CookieV));
	int queuepoints=StringToInt(CookieV);
	if(queuepoints==-1) return;

	Format(CookieV, sizeof(CookieV), "%i", FF2_GetQueuePoints(client)+queuepoints);
	SetClientCookie(client, g_hBossQueue, CookieV);
}

// true = 보스 안함 설정, 대기포인트 저장
// false = 보스 안함 미설정.
stock void SetClientQueueNoneCookie(int client, bool setNone)
{
	char CookieV[50];

	if(setNone)
	{
		Format(CookieV, sizeof(CookieV), "%i", FF2_GetQueuePoints(client));
		SetClientCookie(client, g_hBossQueue, CookieV);
		FF2_SetQueuePoints(client, -1);
	}
	else
	{
		GetClientCookie(client, g_hBossQueue, CookieV, sizeof(CookieV));
		int queuepoints=StringToInt(CookieV);
		if(queuepoints==-1) return;

		FF2_SetQueuePoints(client, queuepoints);
		IntToString(-1, CookieV, sizeof(CookieV));
		SetClientCookie(client, g_hBossQueue, CookieV);
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2_queue_restored");
	}
}

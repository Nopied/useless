#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <clientprefs>

/*

참고사항: StringToInt(CookieV) == 1는 보스 안함을 뜻함.

수정 필수:

- 코드 최적화(BossName 삭제를 위함.)
- 채팅트리거 도입.

*/

new String:Incoming[MAXPLAYERS+1][64];

new Handle:BossCookie;
new Handle:BossQueue;

public Plugin:myinfo = {
	name = "Freak Fortress 2: Boss Selection EX",
	description = "Allows players select their bosses by /ff2boss",
	author = "Tean Potry: Nopied◎",
};

public OnPluginStart()
{
	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
	
	HookEvent("teamplay_round_start", event_round);
	
	RegConsoleCmd("ff2_boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("ff2boss", Command_SetMyBoss, "Set my boss");
	RegConsoleCmd("boss", Command_SetMyBoss, "Set my boss");
	
	BossCookie  = RegClientCookie("BossCookie", " ", CookieAccess_Protected);
	BossQueue = RegClientCookie("QueuePoint", " ", CookieAccess_Protected);

	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
	LoadTranslations("ff2_boss_selection");
}

public Action:Listener_Say(client, const String:command[], argc)
{
	if(!client || client > MaxClients || !IsClientInGame(client)) return Plugin_Continue;
	
	decl String:strChat[100];
	GetCmdArgString(strChat, sizeof(strChat));
	new iStart;
	
	if(strChat[iStart] == '"') iStart++;
	if(strChat[iStart] == '!') iStart++;
	
	if(StrContains(strChat[iStart], "ff2boss") != -1)
	{
		Command_SetMyBoss(client, 0);
	}
	if(StrContains(strChat[iStart], "boss", false) != -1)
	{
		Command_SetMyBoss(client, 0);
		// return Plugin_Stop;
	}
	
	if(StrContains(strChat[iStart], "보스") != -1)
	{
		Command_SetMyBoss(client, 0);
	}	
	return Plugin_Continue;
}

public Action:event_round(Handle:event, const String:name[], bool:dontBroadcast)
{
	new queuepoints;
	for(new client=1; client<=MaxClients; client++)
	{
		new String:CookieV[50];
		GetClientCookie(client, BossQueue, CookieV, 50);
		queuepoints = StringToInt(CookieV);
		if(queuepoints >= 0) FF2_SetQueuePoints(client, -1);
	}
	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	new String:CookieV[50];
	
	if(!AreClientCookiesCached(client)) 
	{
		strcopy(Incoming[client], sizeof(Incoming[]), "");
		
		CookieV = "";
		
		SetClientCookie(client, BossCookie, CookieV);
		IntToString(-1, CookieV, 50);
		SetClientCookie(client, BossQueue, CookieV);
	}
	
	else 
	{
	GetClientCookie(client, BossCookie, CookieV, 50);
		
	strcopy(Incoming[client], sizeof(Incoming[]), CookieV);
		
	}
	// 중요. 표시를 위한 것.
	// strcopy(Incoming[client], sizeof(Incoming[]), "");
}

public Action:Command_SetMyBoss(client, args)
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
	
	decl String:spclName[64];
	decl Handle:BossKV;
	new String:CookieV[126];
	
	if(args)
	{
		new String:bossName[64];
		GetCmdArgString(bossName, sizeof(bossName));
		for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
		{
			if (KvGetNum(BossKV, "blocked",0)) continue;
			KvGetString(BossKV, "name", spclName, sizeof(spclName));

			if(StrContains(bossName, spclName, false)!=-1)
			{
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}
			
			KvGetString(BossKV, "filename", spclName, sizeof(spclName));
			if(StrContains(bossName, spclName, false)!=-1)
			{
				KvGetString(BossKV, "name", spclName, sizeof(spclName));
				strcopy(Incoming[client], sizeof(Incoming[]), spclName);
				
				CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossselected", spclName);
				return Plugin_Handled;
			}	
		}
		CReplyToCommand(client, "{olive}[FF2]{default} %t", "ff2boss_bossnotfound");
		return Plugin_Handled;
	}	
	
	GetClientCookie (client, BossCookie, CookieV, 126);
	new String:s[256];
	
	new Handle:dMenu = CreateMenu(Command_SetMyBossH);
	
	if(StrEqual(CookieV, "")) 
	{
	Format(s, sizeof(s), "%t", "ff2boss_random_option");
	SetMenuTitle(dMenu, "%t", "ff2boss_title", s);
	}
	else if (StringToInt(CookieV) == 1) 
	{
	Format(s, sizeof(s), "%t", "ff2boss_none");
	SetMenuTitle(dMenu, "%t", "ff2boss_title", s);
	}
	else SetMenuTitle(dMenu, "%t", "ff2boss_title", Incoming[client]);

	Format(s, sizeof(s), "%t", "ff2boss_random_option");
	AddMenuItem(dMenu, "Random Boss", s);
	Format(s, sizeof(s), "%t", "ff2boss_none_1");
	AddMenuItem(dMenu, "None", s);
	
	
	for (new i = 0; (BossKV=FF2_GetSpecialKV(i,true)); i++)
	{
		if (KvGetNum(BossKV, "blocked",0)) continue;
		KvGetString(BossKV, "name", spclName, 64);
		AddMenuItem(dMenu,spclName,spclName);
		
	}
	SetMenuExitButton(dMenu, true);
	DisplayMenu(dMenu, client, 90);
	return Plugin_Handled;
}


public Command_SetMyBossH(Handle:menu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
		
		case MenuAction_Select:
		{
			new String:CookieV[126];
			switch(param2)
			{
				case 0:
				{
					Incoming[param1] = "";
					
					CookieV = "";
					
					SetClientCookie(param1, BossCookie, CookieV);
						
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_randomboss");
                    
					GetClientCookie(param1, BossQueue, CookieV, 126);
					
					new queuepoints;
					queuepoints = StringToInt(CookieV);
					if(queuepoints >= 0)
					{
						FF2_SetQueuePoints(param1, queuepoints);
						CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2_queue_restored");
						IntToString(-1, CookieV, 50);
						SetClientCookie(param1, BossQueue, CookieV);
					}
				}
				case 1:
				{
					IntToString(1, CookieV, 126);
					
					SetClientCookie(param1, BossCookie, CookieV);
				
					new queuepoints;
					queuepoints = FF2_GetQueuePoints(param1);
					IntToString(queuepoints, CookieV, 126);
					SetClientCookie(param1, BossQueue, CookieV);
					FF2_SetQueuePoints(param1, -1);
					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_none");
				
				}
				default:
				{
					GetMenuItem(menu, param2, Incoming[param1], sizeof(Incoming[]));
					
					strcopy(CookieV, sizeof(CookieV),Incoming[param1]);
					SetClientCookie(param1, BossCookie, CookieV);

					CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2boss_bossselected", Incoming[param1]);
					
					GetClientCookie(param1, BossQueue, CookieV, 126);
					
					new queuepoints;
					queuepoints = StringToInt(CookieV);
					if(queuepoints >= 0)
					{
						FF2_SetQueuePoints(param1, queuepoints);
						CReplyToCommand(param1, "{olive}[FF2]{default} %t", "ff2_queue_restored");
						IntToString(-1, CookieV, 50);
						SetClientCookie(param1, BossQueue, CookieV);
					}
				}
			}
		}
	}
}

public Action:FF2_OnSpecialSelected(boss, &SpecialNum, String:SpecialName[])
{
	new client=GetClientOfUserId(FF2_GetBossUserId(boss));
	if (!boss && !StrEqual(Incoming[client], ""))
	{
		strcopy(SpecialName, sizeof(Incoming[]), Incoming[client]);
		// Incoming[client] = "";
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

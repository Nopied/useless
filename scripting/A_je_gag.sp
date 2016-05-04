#include <sourcemod>
#include <morecolors>
#include <clientprefs>

Handle g_hGagCookie;

Handle cvarTimer;

public Plugin:myinfo = {
	name = "A_je_gag",
	description = "A-je... Are you stand that thing?",
	author = "Nopied◎",
	version = "18",
};

public void OnPluginStart()
{
	cvarTimer=CreateConVar("A_je_gag_Timer", "90.0", "A-je...", FCVAR_PLUGIN, true, 0.0);

  g_hGagCookie=RegClientCookie("A_je_gag.cookie", "LOL", CookieAccess_Protected);

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

  RegConsoleCmd("ajegag", Command_Ajegag);
}

public void OnMapStart()
{
	CreateTimer(GetConVarFloat(cvarTimer), Timer_Gag, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Gag(Handle timer)
{
  char cookieClient[MAXPLAYERS+1][100];
  char CookieV[100];
  int clientQueue[MAXPLAYERS+1]; // 이것도 0은 취급 안함.
  int count=0; // for문의 client는 1부터 시작.

  for(int client=1; client<=MaxClients; client++) // 0은 World.
  {
    if(IsValidClient(client))
    {
      GetClientCookie(client, g_hGagCookie, CookieV, sizeof(CookieV));
      if(CookieV[0] != '\0')
      {
        Format(cookieClient[count], 100, "%s", CookieV);
        clientQueue[count]=client;
				count++;
      }
    }
  }
  int random=GetRandomInt(0, count-1);
	if(count)
  CPrintToChatAll("{green}[개그]{default} %s{default} - {green}%N",
	cookieClient[random],
	clientQueue[random]);
  return Plugin_Continue;
}

public Action:Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	char gag[1][100];
	// int start=0;
	bool start=false;
	GetCmdArgString(chat, sizeof(chat));

	// if(chat[start]=='"') start++;
	if(strlen(chat)>=2 && (chat[1]=='!' || chat[1]=='/')) start=true; // start++;
	chat[strlen(chat)-1]='\0';

	if(!start) return Plugin_Continue;

	ExplodeString(chat[2], " ", gag, 1, 100);
	if(StrEqual("개그", gag[0], true))
	{
		CheckGag(client, chat[strlen(gag[0])+3]); // 띄어쓰기 때문에 1 추가 그리고 "랑 !를 포함
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Command_Ajegag(int client, int args)
{
  if(!IsValidClient(client)) return Plugin_Continue;

  char gag[150];
  GetCmdArgString(gag, sizeof(gag));

	CheckGag(client, gag);
  return Plugin_Continue;
}

void CheckGag(int client, const char[] gag)
{
	if(gag[0] != '\0')
  {
    SetClientCookie(client, g_hGagCookie, gag);
    CPrintToChat(client, "{green}[개그]{default} ''%s{default}''로 설정하셨습니다.", gag);
  }
  else
  {
		char CookieV[150];
		GetClientCookie(client, g_hGagCookie, CookieV, sizeof(CookieV));

		if(CookieV[0] == '\0')
	  {
			CPrintToChat(client, "{green}[개그]{default} 등록할 개그를 적어주세요!");
		}
    else
		{
			SetClientCookie(client, g_hGagCookie, "");
			CPrintToChat(client, "{green}[개그]{default} 개그를 초기화했습니다.");
		}
  }
 }

stock bool IsValidClient(int client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}

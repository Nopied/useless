#include <sourcemod>
#include <morecolors>
#include <freak_fortress_2>
#include <tf2>
#include <tf2_stocks>

bool g_bCheckedAlive=false;

int g_iCheckPeople=10;
int g_iPeopleCheck=5; //  TODO:ConVar
int g_iDeathDamage=500;// TODO:ConVar
int g_iDeathTimer=20; // TODO: ConVar

int staticTimer; // STATIC WHY!?!?!?

bool actieved=false;

Handle cvarPeople;
Handle cvarDeathDamage;
Handle cvarDeathTimer;
Handle cvarCheckPeople;

public Plugin:myinfo = {
	name = "duck-duck",
	description = "No ConVar. EZ Life.",
	author = "Nopied◎",
	version = "18",
};

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);
	HookEvent("teamplay_round_win", OnRoundEnd);

	cvarPeople=CreateConVar("ff2_loser_people", "5", ".");
	cvarCheckPeople=CreateConVar("ff2_loser_check_people", "10", ".");
	cvarDeathDamage=CreateConVar("ff2_loser_deathdamage", "500", ".");
	cvarDeathTimer=CreateConVar("ff2_loser_deathtimer", "20", ".");
  // Wat.
}

public void OnMapStart()
{
	g_iCheckPeople=GetConVarInt(cvarCheckPeople);
	g_iPeopleCheck=GetConVarInt(cvarPeople);
	g_iDeathDamage=GetConVarInt(cvarDeathDamage);
	g_iDeathTimer=GetConVarInt(cvarDeathTimer);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
  LogMessage("라운드 시작.");
	CreateTimer(10.4, OnRoundStart_Timer);
}

public Action OnRoundStart_Timer(Handle timer)
{
	if(CheckAlivePeople() < g_iCheckPeople && CheckAlivePeople()) // 이건 보스가 아닌 팀의 인원만 확인함.
  {
    CPrintToChatAll("{olive}[FF2]{default} 잉여자 처리는 %d명부터 작동됩니다.", g_iCheckPeople);
    return Plugin_Continue;
  }
  else g_bCheckedAlive=true;
  return Plugin_Continue;
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
	actieved=false;
	g_bCheckedAlive=false;
	return Plugin_Continue;
}

public Action FF2_OnAlivePlayersChanged(int players, int bosses)
{
  if(g_bCheckedAlive && !actieved && players <= g_iPeopleCheck)
  {
		CPrintToChatAll("{olive}[FF2]{default} %d명 이하이므로 잉여자 처리가 시작됩니다!\n약 %d초 안에 데미지 %d을 넘겨야 살아남을 수 있습니다!", g_iPeopleCheck, g_iDeathTimer, g_iDeathDamage);
		actieved=true;
		staticTimer=g_iDeathTimer;
		CreateTimer(1.0, TimeToDeath, _, TIMER_REPEAT);
  }
}

public Action TimeToDeath(Handle timer)
{
	if (!actieved) return Plugin_Stop;

  bool end=false;
  for(int client=1; client<=MaxClients; client++)
  {
    if(IsValidClient(client) && IsPlayerAlive(client) && FF2_GetClientDamage(client) < g_iDeathDamage)
    {
      if(staticTimer<=0)
      {
        ForcePlayerSuicide(client);
        CPrintToChat(client, "{olive}[FF2]{default} 잉여자로 선정되어 사망합니다..");
        end=true;
      }
      else
        PrintCenterText(client, "%d초 안에 데미지를 %d까지 쌓으세요!", staticTimer, g_iDeathDamage);
    }
		else end=true;
  }

  staticTimer--;
  return end ? Plugin_Stop : Plugin_Continue;
}

stock int CheckAlivePeople()
{
  int people=0;
  int bossteam=FF2_GetBossTeam();
  for(int client=1; client<=MaxClients; client++)
  {
    if(IsValidClient(client) && IsPlayerAlive(client) && _:TF2_GetClientTeam(client) != bossteam)
      people++;
  }
  return people;
}

stock bool IsValidClient(int client)
{
  return (0<client && client<=MaxClients && IsClientInGame(client));
}

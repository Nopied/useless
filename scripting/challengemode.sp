#include <sourcemod>
#include <freak_fortress_2>
#include <POTRY>
#include <adt_array>
#include <clientprefs>
#include <morecolors>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2items>

#define PLUGIN_NAME "Challenge Mode"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "."
#define PLUGIN_VERSION ""

#define	MAX_EDICT_BITS	12
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle ChallengeKV;

Handle cvarChatCommand;

int g_iChatCommand=0;
char g_strChatCommand[42][50];

public void OnPluginStart()
{
    cvarChatCommand = CreateConVar("challenge_chatcommand", "챌린지,challenge");

    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");

    CreateTimer(15.0, ClientTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Continue;

	char strChat[100];
	char temp[3][64];
	GetCmdArgString(strChat, sizeof(strChat));

	int start;

	if(strChat[start] == '"') start++;
	if(strChat[start] == '!' || strChat[start] == '/') start++;
	strChat[strlen(strChat)-1] = '\0';
	ExplodeString(strChat[start], " ", temp, 3, 64, true);

	for (int i=0; i<=g_iChatCommand; i++)
	{
		if(StrEqual(temp[0], g_strChatCommand[i], true))
		{
			if(temp[1][0] != '\0')
			{
				return Plugin_Continue;
			}

			ViewChallengeMenu(client);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

void ViewChallengeMenu(int client, bool passCheckCharge = false)
{
    int charge = GetClientChallengeCharge(client);

    int totalCount = GetValidUnlockCount();
    int[] unlockArray = new int[totalCount];

    GetValidUnlockArray(unlockArray, totalCount);

    Menu menu = new Menu(ChallengeMenuCallback);
    char item[300];

    Format(item, sizeof(item), "설정할 타켓을 선택해주십시요.");

    if(GetClientChallengeTarget(client) > 0)
    {
        char name[200];
        GetUnlockString(GetClientChallengeTarget(client), "name", name, sizeof(name));
        Format(item, sizeof(item), "%s\n설정된 타켓: %s", item, name);
    }
    else
    {
        Format(item, sizeof(item), "%s\n설정된 타켓이 없습니다.", item);
    }


    if(charge >= 100.0)
    {
        Format(item, sizeof(item), "%s\n블래스터 차징이 끝났습니다.\n유효한 상황에 챌린지 모드가 실행됩니다!", item);
    }
    else
    {
        Format(item, sizeof(item), "%s\n블래스터 차징: %.1f%% / 100.0%%\n타켓이 설정되어도 챌린지 모드가 실행되지 않습니다.", item, charge);
    }


    menu.SetTitle(item);
    menu.ExitButton = true;

    menu.AddItem("help", "이건 무슨 모드죠? (도움말)");
    menu.AddItem("target delete", "설정된 타켓 제거");

    for(int count=0; count < totalCount; count++)
    {
        GetUnlockString(unlockArray[count], "name", item, sizeof(item));

        menu.AddItem("targets", item);
    }

    menu.Display(client, MENU_TIME_FOREVER);


    // 챌린지 메뉴 코드
    // 챌런지 메뉴에서 다른 해금이 필요한건 비활성화 시켜둘것.
}

public int ChallengeMenuCallback(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
          case MenuAction_End:
          {
              menu.Close();
          }

          case MenuAction_Select:
          {
              switch(item)
              {
                  case 0:
                  {
                      ViewHelpMessage(client);
                  }

                  case 1:
                  {
                      SetClientChallengeTarget(0);
                      CPrintToChat(client, "{yellow}[CHALLENGE]{default} 설정된 타켓을 제거하였습니다.");
                  }

                  default:
                  {
                      int totalCount = GetValidUnlockCount();
                      int[] unlockArray = new int[totalCount];

                      GetValidUnlockArray(unlockArray, totalCount);

                      ViewUnlockInfo(unlockArray[item - 2]);
                  }
              }
          }
    }
}

void ViewHelpMessage(int client)
{
    Menu menu = new Menu(OnSelected);

    menu.SetTitle("챌린지 모드는 서버의 잠겨있는 컨텐츠를 해금하기 위해 거쳐야하는 노-력 컨텐츠입니다.\n블래스터 차징이 100%%일 경우, 선택한 타켓의 유효한 상황에 챌린지 모드가 활성화됩니다.\n그 선택한 타켓의 베리어 HP가 0이 될 경우, 타켓의 내용물을 사용할 수 있습니다.");
    menu.ExitButton = true;

    menu.Display(client, MENU_TIME_FOREVER);
}

void ViewUnlockInfo(int client)
{

}


public int OnSelected(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
    }
}


public void GetValidUnlockArray(int[] unlocks, int size)
{
    int count;
    int unlock;

    Handle clonedHandle = CloneHandle(ChallengeKV);
    KvRewind(clonedHandle);
    char key[20];

    if(KvGotoFirstSubKey(clonedHandle))
    {
        do
        {
            KvGetSectionName(clonedHandle, key, sizeof(key));
            if(!StrContains(key, "unlock"))
            {
                ReplaceString(key, sizeof(key), "unlock", "");
                if(IsValidUnlock((unlock = StringToInt(key))) && KvGetNum(clonedHandle, "not_able") <= 0)
                {
                    if(unlock <= 0) continue;

                    unlocks[count++] = unlock;
                }
            }
        }
        while(KvGotoNextKey(clonedHandle) && count < size);
    }
}

int GetValidUnlockCount()
{
    int count;
    int unlock;

    Handle clonedHandle = CloneHandle(ChallengeKV);
    KvRewind(clonedHandle);
    char key[20];

    if(KvGotoFirstSubKey(clonedHandle))
    {
        do
        {
            KvGetSectionName(clonedHandle, key, sizeof(key));
            if(!StrContains(key, "unlock"))
            {
                ReplaceString(key, sizeof(key), "unlock", "");
                if(IsValidUnlock((unlock = StringToInt(key))) && KvGetNum(clonedHandle, "not_able") <= 0)
                {
                    if(part <= 0) continue;

                    count++;
                }
            }
        }
        while(KvGotoNextKey(clonedHandle));
    }

    return count;
}

public Action ClientTimer(Handle timer)
{
    for(int client=1; client<=MaxClients; client++)
    {
        if(!IsClientInGame(client) || IsFakeClient(client)) continue;

        SetClientChallengeCharge(client, GetClientChallengeCharge(client) + 0.1);
    }
}

public void OnMapStart()
{
	ChangeChatCommand();
    PrecacheChallenge();
}

void ChangeChatCommand()
{
	g_iChatCommand = 0;

	char cvarV[100];
	GetConVarString(cvarChatCommand, cvarV, sizeof(cvarV));

	for (int i=0; i<ExplodeString(cvarV, ",", g_strChatCommand, sizeof(g_strChatCommand), sizeof(g_strChatCommand[])); i++)
	{
		LogMessage("[CHALLENGE] Added chat command: %s", g_strChatCommand[i]);
		g_iChatCommand++;
    }
}

Handle FindClientCookieEx(char[] cookieName, CookieAccess cookieProtectFlags = CookieAccess_Protected)
{
    Handle cookieHandle = FindClientCookie(cookieName);
    if(cookieHandle == INVALID_HANDLE)
    {
        cookieHandle = RegClientCookie(cookieName, "", cookieProtectFlags);
    }

    return cookieHandle;
}

float GetClientChallengeCharge(int client)
{
    Handle cookieHandle = FindClientCookieEx("challenge_charge");

    char cookieValues[10];
    GetClientCookie(client, cookieHandle, cookieValues, sizeof(cookieValues));

    return StringToFloat(cookieValues);
}

void SetClientChallengeCharge(int client, float charge)
{
    Handle cookieHandle = FindClientCookieEx("challenge_charge");

    char cookieValues[10];
    Format(cookieValues, sizeof(cookieValues), "%.1f", charge);

    SetClientCookie(client, cookieHandle, cookieValues);
}

int GetClientChallengeTarget(int client)
{
    Handle cookieHandle = FindClientCookieEx("challenge_target");

    char cookieValues[10];
    GetClientCookie(client, cookieHandle, cookieValues, sizeof(cookieValues));

    return StringToInt(cookieValues);
}

void SetClientChallengeTarget(int client, int unlockTarget)
{
    Handle cookieHandle = FindClientCookieEx("challenge_target");

    char cookieValues[10];
    Format(cookieValues, sizeof(cookieValues), "%i", unlockTarget);

    SetClientCookie(client, cookieHandle, cookieValues);
}

int GetClientBarrierDamage(int client, int unlockTarget)
{
    char cookieValues[40];
    Format(cookieValues, sizeof(cookieValues), "challenge_damage_%i", unlockTarget);

    Handle cookieHandle = FindClientCookieEx(cookieValues);

    GetClientCookie(client, cookieHandle, cookieValues, sizeof(cookieValues));

    return StringToInt(cookieValues);
}

void SetClientBarrierDamage(int client, int unlockTarget, int damage)
{
    char cookieValues[40];
    Format(cookieValues, sizeof(cookieValues), "challenge_damage_%i", unlockTarget);

    Handle cookieHandle = FindClientCookieEx(cookieValues);

    Format(cookieValues, sizeof(cookieValues), "%i", damage);

    SetClientCookie(client, cookieHandle, cookieValues);
}

int GetUnlockBarrierHealth(int index)
{
    if(!IsValidUnlock(index))   return 0;

    return KvGetNum(ChallengeKV, "barrier_hp", 0);
}

float GetUnlockBarrierRank(int index)
{
    if(!IsValidUnlock(index))   return 0.0;

    return KvGetFloat(ChallengeKV, "barrier_rank", 0.0);
}

bool GetUnlockNeedBlaster(int index)
{
    if(!IsValidUnlock(index))   return false;

    return KvGetNum(ChallengeKV, "is_blaster", 0) > 0;
}

public void GetUnlockString(int index, const char[] item, char[] resultstr, int buffer)
{
    if(IsValidUnlock(index))
    {
        KvGetString(ChallengeKV, item, resultstr, buffer, "ERROR");
    }
    else
    {
        Format(resultstr, buffer, "");
    }
}

stock bool IsValidUnlock(int index)
{
    if(ChallengeKV != INVALID_HANDLE)
    {
        KvRewind(ChallengeKV);
        char item[10];
        Format(item, sizeof(item), "unlock%i", index);

        if(KvJumpToKey(ChallengeKV, item))
            return true;
    }
    return false;
}


void PrecacheChallenge()
{
    if(ChallengeKV != INVALID_HANDLE)
    {
      CloseHandle(ChallengeKV);
      ChallengeKV = INVALID_HANDLE;
    }

    char config[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, config, sizeof(config), "configs/challengeunlock.cfg");

    if(!FileExists(config))
    {
        SetFailState("[CHALLENGE] NO CFG FILE! (configs/challengeunlock.cfg)");
        return;
    }

    ChallengeKV = CreateKeyValues("challengeunlock");

    if(!FileToKeyValues(ChallengeKV, config))
    {
        SetFailState("[CHALLENGE] configs/challengeunlock.cfg is broken?!");
        return;
    }

    KvRewind(ChallengeKV);
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

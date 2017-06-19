#include <sourcemod>
#include <morecolors>
#include <POTRY>
#include <clientprefs>

#define PLUGIN_NAME "POTRY VIP System"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "0x"

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	CreateNative("POTRY_IsClientVIP", Native_IsClientVIP);
    CreateNative("POTRY_IsClientEnableVIPEffect", Native_IsClientEnableVIPEffect);
    CreateNative("POTRY_EnableClientVIPEffect", Native_EnableClientVIPEffect);

	return APLRes_Success;
}

public void OnPluginStart()
{
	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");
}

public Action:Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	char chat[150];
	char chatcharge[1][100];
	bool start=false;
	GetCmdArgString(chat, sizeof(chat));

	if(strlen(chat)<3)	return Plugin_Continue;

	if(chat[1]=='!' || chat[1]=='/') start=true; // start++;
	chat[strlen(chat)-1]='\0';

	if(!start) return Plugin_Continue;

	ExplodeString(chat[2], " ", chatcharge, 1, 100);
	if(StrEqual("후원", chatcharge[0], true))
	{
		// CheckGag(client, chat[strlen(chatcharge[0])+3]); // 띄어쓰기 때문에 1 추가 그리고 "랑 !를 포함
        if(IsClientVIP(client))
        {
            ViewVIPMenu(client);
        }
        else
        {
            CPrintToChatAll("{lightblue}[POTRY]{default} {yellow}서버 후원자{default}가 되어야 사용가능합니다.")
        }
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void ViewVIPMenu(int client)
{
    Menu menu = new Menu(OnSelectedItem);

    menu.SetTitle("");

    char temp[200];
    Format(temp, sizeof(temp), "보스 스탠다드 플레이: %s", IsClientEnableVIPEffect(client, VIPEffect_BossStandard) ? "ON" : "OFF");
    menu.AddItem("", temp);
    menu.AddItem("", "네임태그 자유 설정 가능: ON", ITEMDRAW_DISABLED);

    menu.ExitButton = true;

    menu.Display(client, 40);
}

public int OnSelectedItem(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
      case MenuAction_End:
      {
          menu.Close();
      }
      case MenuAction_Select:
      {
          EnableClientVIPEffect(client, view_as<VIPEffect>(item+1), IsClientEnableVIPEffect(client, view_as<VIPEffect>(item+1)) ? false : true);
          CPrintToChat(client, "{lightblue}[POTRY]{default} 선택한 효과: {yellow}%s{default}", IsClientEnableVIPEffect(client, view_as<VIPEffect>(item+1)) ? "ON" : "OFF");

          ViewVIPMenu(client);
      }
    }
}
bool IsClientEnableVIPEffect(int client, VIPEffect effect)
{
    int integerEffect = view_as<int>(effect);
    char cookieName[80];
    Format(cookieName, sizeof(cookieName), "potry_vip_effect_%i", integerEffect);

    Handle CookieV = FindClientCookie(cookieName);
    if(CookieV == INVALID_HANDLE)
    {
        CookieV = RegClientCookie(cookieName, "", CookieAccess_Protected);
    }

    GetClientCookie(client, CookieV, cookieName, sizeof(cookieName));

    return StringToInt(cookieName) == 1;
}

void EnableClientVIPEffect(int client, VIPEffect effect, bool setbool)
{
    int integerEffect = view_as<int>(effect);
    char cookieName[80];
    Format(cookieName, sizeof(cookieName), "potry_vip_effect_%i", integerEffect);

    Handle CookieV = FindClientCookie(cookieName);
    if(CookieV == INVALID_HANDLE)
    {
        CookieV = RegClientCookie(cookieName, "", CookieAccess_Protected);
    }

    SetClientCookie(client, CookieV, setbool ? "1" : "0");
}

public Native_IsClientVIP(Handle plugin, numParams)
{
    return IsClientVIP(GetNativeCell(1));
}

public Native_IsClientEnableVIPEffect(Handle plugin, numParams)
{
    return IsClientEnableVIPEffect(GetNativeCell(1), GetNativeCell(2));
}

public Native_EnableClientVIPEffect(Handle plugin, numParams)
{
    EnableClientVIPEffect(GetNativeCell(1), GetNativeCell(2), GetNativeCell(3));
}

stock bool IsClientVIP(int client)
{
    AdminId adminid = GetUserAdmin(client);

    if(adminid == INVALID_ADMIN_ID)
         return false;

    int flags = GetAdminFlags(adminid, Access_Real);
    if((flags &  ADMFLAG_CUSTOM1)
    || (flags & ADMFLAG_ROOT))
        return true;

    return false;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

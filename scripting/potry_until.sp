#include <sourcemod>
#include <clientprefs>
#include <ccc>
#include <steamtools>
#include <morecolors>

#define PLUGIN_NAME "POTRY 유틸리티"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "0x0000"

#define PORTY_GROUP_ID 7824949

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

bool IsPlayerInGroup[MAXPLAYERS+1];
bool IsPlayerVIP[MAXPLAYERS+1];

bool IsPlayerAdmin[MAXPLAYERS+1];
bool IsPlayerModer[MAXPLAYERS+1];

public void OnClientPutInServer(client)
{
    Steam_RequestGroupStatus(client, PORTY_GROUP_ID);

    for(int target = 1; target <= MaxClients; target++)
    {
        if(IsPlayerInGroup[client])
            SetListenOverride(target, client, Listen_Yes);

        else
            SetListenOverride(target, client, Listen_No);
    }

    IsPlayerAdmin[client] = false;
    IsPlayerModer[client] = false;

    AdminId adminid = GetUserAdmin(client);
    if(adminid != INVALID_ADMIN_ID)
    {
        // Admin_Config
        if(GetAdminFlag(adminid, Admin_Config, Access_Real))
        {
            IsPlayerModer[client] = true;
            CCC_SetColor(client, CCC_ChatColor, );
        }

        else
        {
            IsPlayerAdmin[client] = true;
            CCC_SetColor(client, CCC_ChatColor, );
        }
    }
}

public int Steam_GroupStatusResult(int client, int groupAccountID, bool groupMember, bool groupOfficer)
{
	if(groupAccountID == PORTY_GROUP_ID)
	{
		if(groupMember)
		{
			IsPlayerInGroup[client] = true;
		}
		else
		{
			IsPlayerInGroup[client] = false;
		}
	}
}

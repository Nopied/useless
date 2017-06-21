#include <sourcemod>
#include <clientprefs>
#include <steamtools>
#include <morecolors>
#include <sdktools_voice>

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
/*
    for(int target = 1; target <= MaxClients; target++)
    {
        if(!IsClientInGame(target)) continue;

        if(IsPlayerInGroup[client])
            SetListenOverride(target, client, Listen_Yes);

        else
            SetListenOverride(target, client, Listen_No);


        if(IsPlayerInGroup[target])
            SetListenOverride(client, target, Listen_Yes);

        else
            SetListenOverride(client, target, Listen_No);

    }
*/
    if(!IsPlayerInGroup[client])
        SetClientListeningFlags(client, GetClientListeningFlags(client) | VOICE_MUTED);

    IsPlayerAdmin[client] = false;
    IsPlayerModer[client] = false;

    // AdminId adminid = GetUserAdmin(client);
    if(CheckCommandAccess(client, "POTRYUTILL", ADMFLAG_GENERIC))// adminid != INVALID_ADMIN_ID
    {
        // Admin_Config
        if(CheckCommandAccess(client, "POTRYUTILL", ADMFLAG_RCON))
        {
            IsPlayerAdmin[client] = true;
            // CCC_SetColor(client, CCC_ChatColor, 0xADD8E6, true);
        }
        else
        {
            IsPlayerModer[client] = true;
            // CCC_SetColor(client, CCC_ChatColor, 0xFFFFE0, true);
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(IsClientInGame(client))
    {
        if(buttons & IN_ALT1)
        {
            PrintToChatAll("ALT");
        }
    }
}

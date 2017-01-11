#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <tf2items>
#define MB 3
#define ME 2048
public Plugin:myinfo = {
	name = "Freak Fortress 2: Damage Tracker",
	author = "MasterOfTheXP",
	version = "1.0",
};
/*
This plugin for a plugin (bwooong) allows clients to type "!ff2dmg <number 1 to 8>" to enable the damage tracker.
If a client enables it, the top X damagers will always be printed to the top left of their screen.
*/

new damageTracker[MAXPLAYERS + 1];
new Handle:damageHUD;

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	return APLRes_Success;
}

public OnPluginStart2()
{
	RegConsoleCmd("ff2dmg", Command_damagetracker, "ff2dmg - Enable/disable the damage tracker.");
	RegConsoleCmd("haledmg", Command_damagetracker, "haledmg - Enable/disable the damage tracker.");

	AddCommandListener(Listener_Say, "say");
	AddCommandListener(Listener_Say, "say_team");

	CreateTimer(0.2, Timer_Millisecond);
	damageHUD = CreateHudSynchronizer();
}

public Action:Listener_Say(int client, const char[] commands, int argc)
{
	if(!IsClientInGame(client))	return Plugin_Continue;

	char chat[150];
	char command[1][100];
	bool start=false;
	GetCmdArgString(chat, sizeof(chat));

	if(strlen(chat)>=2 && (chat[1]=='!' || chat[1]=='/')) start=true;
	chat[strlen(chat)-1]='\0';

	if(!start) return Plugin_Continue;

	ExplodeString(chat[2], " ", command, 1, 100);
	if(StrEqual("데미지", command[0], true) ||
	StrEqual("데미지표시", command[0], true))
	{
		DoDamageTracker(client, chat[strlen(command[0])+3]); // 띄어쓰기 때문에 1 추가 그리고 "랑 !를 포함
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action:Timer_Millisecond(Handle:timer)
{
	CreateTimer(0.2, Timer_Millisecond);
	if (FF2_GetRoundState() != 1) return Plugin_Handled;

	new highestDamage = 0;
	new highestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > highestDamage)
		{
			highestDamage = FF2_GetClientDamage(z);
			highestDamageClient = z;
		}
	}
	new secondHighestDamage = 0;
	new secondHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > secondHighestDamage && z != highestDamageClient)
		{
			secondHighestDamage = FF2_GetClientDamage(z);
			secondHighestDamageClient = z;
		}
	}
	new thirdHighestDamage = 0;
	new thirdHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > thirdHighestDamage && z != highestDamageClient && z != secondHighestDamageClient)
		{
			thirdHighestDamage = FF2_GetClientDamage(z);
			thirdHighestDamageClient = z;
		}
	}
	new fourthHighestDamage = 0;
	new fourthHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > fourthHighestDamage && z != highestDamageClient && z != secondHighestDamageClient && z != thirdHighestDamageClient)
		{
			fourthHighestDamage = FF2_GetClientDamage(z);
			fourthHighestDamageClient = z;
		}
	}
	new fifthHighestDamage = 0;
	new fifthHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > fifthHighestDamage && z != highestDamageClient && z != secondHighestDamageClient && z != thirdHighestDamageClient && z != fourthHighestDamageClient)
		{
			fifthHighestDamage = FF2_GetClientDamage(z);
			fifthHighestDamageClient = z;
		}
	}
	new sixthHighestDamage = 0;
	new sixthHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > sixthHighestDamage && z != highestDamageClient && z != secondHighestDamageClient && z != thirdHighestDamageClient && z != fourthHighestDamageClient && z != fifthHighestDamageClient)
		{
			sixthHighestDamage = FF2_GetClientDamage(z);
			sixthHighestDamageClient = z;
		}
	}
	new seventhHighestDamage = 0;
	new seventhHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > seventhHighestDamage && z != highestDamageClient && z != secondHighestDamageClient && z != thirdHighestDamageClient && z != fourthHighestDamageClient && z != fifthHighestDamageClient && z != sixthHighestDamageClient)
		{
			seventhHighestDamage = FF2_GetClientDamage(z);
			seventhHighestDamageClient = z;
		}
	}
	new eigthHighestDamage = 0;
	new eigthHighestDamageClient = -1;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && FF2_GetClientDamage(z) > eigthHighestDamage && z != highestDamageClient && z != secondHighestDamageClient && z != thirdHighestDamageClient && z != fourthHighestDamageClient && z != fifthHighestDamageClient && z != sixthHighestDamageClient && z != seventhHighestDamageClient)
		{
			eigthHighestDamage = FF2_GetClientDamage(z);
			eigthHighestDamageClient = z;
		}
	}

	int tempDamageTrack;
	for (new z = 1; z <= GetMaxClients(); z++)
	{
		if (IsClientInGame(z) && !IsFakeClient(z))
		{
			new a_index = FF2_GetBossIndex(z);
			if (a_index == -1) // client is not Hale
			{
				tempDamageTrack = damageTracker[z];
				if(!IsPlayerAlive(z) && damageTracker[z] < 3)
				{
					tempDamageTrack = 3;
				}
				else if(tempDamageTrack <= 0)
				{
					continue;
				}

				new userIsWinner = false;
				if (z == highestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 1 && z == secondHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 2 && z == thirdHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 3 && z == fourthHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 4 && z == fifthHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 5 && z == sixthHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 6 && z == seventhHighestDamageClient) userIsWinner = true;
				if (tempDamageTrack > 7 && z == eigthHighestDamageClient) userIsWinner = true;
				SetHudTextParams(0.0, 0.0, 0.2, 255, 255, 255, 255);
				SetGlobalTransTarget(z);
				new String:first[64];
				new String:second[64];
				new String:third[64];
				new String:fourth[64];
				new String:fifth[64];
				new String:sixth[64];
				new String:seventh[64];
				new String:eigth[64];
				new String:user[64];
				if (highestDamageClient != -1) Format(first, 64, "[1] %N : %i\n", highestDamageClient, highestDamage);
				if (highestDamageClient == -1) Format(first, 64, "[1]\n", highestDamageClient, highestDamage);
				if (tempDamageTrack > 1 && secondHighestDamageClient != -1) Format(second, 64, "[2] %N : %i\n", secondHighestDamageClient, secondHighestDamage);
				if (tempDamageTrack > 1 && secondHighestDamageClient == -1) Format(second, 64, "[2]\n", secondHighestDamageClient, secondHighestDamage);
				if (tempDamageTrack > 2 && thirdHighestDamageClient != -1) Format(third, 64, "[3] %N : %i\n", thirdHighestDamageClient, thirdHighestDamage);
				if (tempDamageTrack > 2 && thirdHighestDamageClient == -1) Format(third, 64, "[3]\n", thirdHighestDamageClient, thirdHighestDamage);
				if (tempDamageTrack > 3 && fourthHighestDamageClient != -1) Format(fourth, 64, "[4] %N : %i\n", fourthHighestDamageClient, fourthHighestDamage);
				if (tempDamageTrack > 3 && fourthHighestDamageClient == -1) Format(fourth, 64, "[4]\n", fourthHighestDamageClient, fourthHighestDamage);
				if (tempDamageTrack > 4 && fifthHighestDamageClient != -1) Format(fifth, 64, "[5] %N : %i\n", fifthHighestDamageClient, fifthHighestDamage);
				if (tempDamageTrack > 4 && fifthHighestDamageClient == -1) Format(fifth, 64, "[5]\n", fifthHighestDamageClient, fifthHighestDamage);
				if (tempDamageTrack > 5 && sixthHighestDamageClient != -1) Format(sixth, 64, "[6] %N : %i\n", sixthHighestDamageClient, sixthHighestDamage);
				if (tempDamageTrack > 5 && sixthHighestDamageClient == -1) Format(sixth, 64, "[6]\n", sixthHighestDamageClient, sixthHighestDamage);
				if (tempDamageTrack > 6 && seventhHighestDamageClient != -1) Format(seventh, 64, "[7] %N : %i\n", seventhHighestDamageClient, seventhHighestDamage);
				if (tempDamageTrack > 6 && seventhHighestDamageClient == -1) Format(seventh, 64, "[7]\n", seventhHighestDamageClient, seventhHighestDamage);
				if (tempDamageTrack > 7 && eigthHighestDamageClient != -1) Format(eigth, 64, "[8] %N : %i\n", eigthHighestDamageClient, eigthHighestDamage);
				if (tempDamageTrack > 7 && eigthHighestDamageClient == -1) Format(eigth, 64, "[8]\n", eigthHighestDamageClient, eigthHighestDamage);
				if (userIsWinner) Format(user, 64, " ");
				if (!userIsWinner) Format(user, 64, "---------\n[  ] %N : %i", z, FF2_GetClientDamage(z));
				if (z == secondHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[2] %N : %i", z, FF2_GetClientDamage(z));
				if (z == thirdHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[3] %N : %i", z, FF2_GetClientDamage(z));
				if (z == fourthHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[4] %N : %i", z, FF2_GetClientDamage(z));
				if (z == fifthHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[5] %N : %i", z, FF2_GetClientDamage(z));
				if (z == sixthHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[6] %N : %i", z, FF2_GetClientDamage(z));
				if (z == seventhHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[7] %N : %i", z, FF2_GetClientDamage(z));
				if (z == eigthHighestDamageClient && !userIsWinner) Format(user, 64, "---------\n[8] %N : %i", z, FF2_GetClientDamage(z));
				ShowSyncHudText(z, damageHUD, "%s%s%s%s%s%s%s%s%s", first, second, third, fourth, fifth, sixth, seventh, eigth, user);
			}
		}
	}
	return Plugin_Handled;
}

public Action:Command_damagetracker(client, args)
{
	if (client == 0)
	{
		PrintToServer("[FF2] The damage tracker cannot be enabled by Console.");
		return Plugin_Handled;
	}
/*
	if (args == 0)
	{
		new String:playersetting[3];
		if (damageTracker[client] == 0) playersetting = "OFF";
		if (damageTracker[client] > 0) playersetting = "ON";
		CPrintToChat(client, "{olive}[FF2]{default} 데미지 표시: {olive}%s{default}.\n{olive}[FF2]{default}{olive}\"!ff2dmg on\"{default} 혹은 {olive}\"!ff2dmg off\"{default}로 수정하실 수 있습니다.", playersetting);
		CPrintToChat(client, "혹은 {olive}\"/ff2dmg (슬릇))\"{default}으로 원하는 슬릇을 추가할 수 있습니다.");
		return Plugin_Handled;
	}
*/
	new String:arg1[64];
	GetCmdArgString(arg1, sizeof(arg1));
	DoDamageTracker(client, arg1);

	return Plugin_Handled;
}

void DoDamageTracker(int client, const char[] command)
{
	if(!strlen(command))
	{
		new String:playersetting[3];
		if (damageTracker[client] == 0) playersetting = "OFF";
		if (damageTracker[client] > 0) playersetting = "ON";
		CPrintToChat(client, "{olive}[FF2]{default} 현재 데미지 표시: {olive}%s{default}.\n{olive}[FF2]{default}{olive}\"!ff2dmg on\"{default} 혹은 {olive}\"!ff2dmg off\"{default}로 수정하실 수 있습니다.", playersetting);
		CPrintToChat(client, "혹은 {olive}\"!데미지 (슬릇))\"{default}으로 원하는 슬릇을 추가할 수 있습니다.");
		return;
	}
	new newval = 3;

	if (StrEqual(command,"off",false)) damageTracker[client] = 0;
	else if(StrEqual(command,"끄기",false)) damageTracker[client] = 0;

	if (StrEqual(command,"on",false)) damageTracker[client] = 3;
	else if(StrEqual(command,"켜기",false)) damageTracker[client] = 3;

	if (StrEqual(command,"0",false)) damageTracker[client] = 0;
	if (StrEqual(command,"of",false)) damageTracker[client] = 0;
	if (!StrEqual(command,"off",false) && !StrEqual(command,"on",false) && !StrEqual(command,"0",false) && !StrEqual(command,"of",false))
	{
		newval = StringToInt(command);
		new String:newsetting[3];
		if (newval > 8) newval = 8;
		if (newval != 0) damageTracker[client] = newval;
		// if (newval != 0 && damageTracker[client] == 0) newsetting = "OFF";
		// if (newval != 0 && damageTracker[client] > 0) newsetting = "ON";
		CPrintToChat(client, "{olive}[FF2]{default} 데미지 표시: {lightgreen}%s{default}", damageTracker[client] ? "ON" : "OFF");
	}
}

public OnClientPutInServer(client)
{
	damageTracker[client] = 0;
}

public Action:FF2_OnAbility2(index, const String:plugin_name[], const String:ability_name[], action)
{
	return Plugin_Continue;
}

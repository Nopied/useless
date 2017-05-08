#include <sourcemod>
#include <discord>
#include <morecolors>

#define PLUGIN_NAME "POTRY DiscordBot"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "00"

#define BOT_TOKEN "MzEwMzQ3MDk5MDAwNjY4MTYw.C_HVNg.ucjrWlpzyMNzlI53OLxPuohL968"
#define SERVER_CHAT_ID "309330201421283328"

DiscordBot gBot;
DiscordChannel gServerChat;
// DiscordChannel gServerReport;

// ArrayList chatArray;

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

// int chatEngineTime;

public void OnAllPluginsLoaded()
{
    gBot = new DiscordBot(BOT_TOKEN);
    if(gBot != INVALID_HANDLE && gServerChat == INVALID_HANDLE)
    {
        //
        // PrintToChatAll("Create a Bot"); //

        // gBot.MessageCheckInterval = 3.05;

    	// gBot.GetGuilds(GuildList);
        // gBot.StartListeningToChannel(gServerChat, OnMessage);
    }
    // chatArray = new ArrayList();

    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");
}

public void OnMapStart()
{
    if(gBot != INVALID_HANDLE)
    {
        char map[50];
        char message[100];
        GetCurrentMap(map, sizeof(map));
        Format(message, sizeof(message), "현재 맵: %s", map);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, message);
    }
}

/*
public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
    gBot.GetGuildChannels(id, ChannelList);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data)
{

		char name[32];
		char id[32];
		Channel.GetID(id, sizeof(id));
		Channel.GetName(name, sizeof(name));
		// PrintToConsole(client, "Channel for Guild(%s) - [%s] [%s]", guild, id, name);

		if(Channel.IsText)
        {
            if(StrEqual(id, SERVER_CHAT_ID))
            {
                gServerChat = view_as<DiscordChannel>(CloneHandle(Channel));
                //Send a message with all ways
    			// gBot.SendMessage(Channel, "Sending message with DiscordBot.SendMessage");
                // PrintToServer("Find Channel %s", name);
    			//gBot.SendMessageToChannelID(id, "Sending message with DiscordBot.SendMessageToChannelID");
    			//Channel.SendMessage(gBot, "Sending message with DiscordChannel.SendMessage");

    			// gBot.StartListeningToChannel(Channel, OnMessage);
            }
		}
}
*/
public Action Listener_Say(int client, const char[] command, int argc)
{
	if(!IsValidClient(client))	return Plugin_Continue;

	new String:chat[150];
	new bool:handleChat=false;

	GetCmdArgString(chat, sizeof(chat));

    if(strlen(chat) > 1)
        chat[strlen(chat)-1] = '\0';
    else
        return Plugin_Continue;
	// char specialtext[2][100];
	// ExplodeString(chat[2], " ", specialtext, sizeof(specialtext), sizeof(specialtext[]));

	if(StrEqual("신고", chat[2], true) ||
	StrEqual("report", chat[2], true))
	{
        handleChat = true;
        // TODO: 유저 신고 기능

        return Plugin_Handled;
	}

    // if(gBot != INVALID_HANDLE && chatEngineTime < GetTime())
    if(gBot != INVALID_HANDLE)
    {
        char steamAccount[60];
        char message[300];

        GetClientAuthId(client, AuthId_Steam2, steamAccount, sizeof(steamAccount));
        Format(message, sizeof(message), "%N [%s]: %s", client, steamAccount, chat[1]);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, message);

        // chatEngineTime = GetTime()+1;
    }


	return handleChat ? Plugin_Handled : Plugin_Continue;
}

/*
public void OnMessage(DiscordBot bot, DiscordChannel channel, const char[] message, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator)
{

    CPrintToChatAll("{yellow}%s: %s{default}", userName, message); // TODO: 이 채팅을 보고 싶은 사람만.
    // 채팅 색으로 인한 크래쉬인가?
}
*/

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

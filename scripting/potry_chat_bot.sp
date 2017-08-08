#include <sourcemod> //////////
#include <discord>
#include <morecolors>
#include <sourcebans>
#include <sdktools>
#include <sdkhooks>
#include <SteamWorks>
#include <smjansson>

#define PLUGIN_NAME "POTRY DiscordBot"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "00"

char SERVER_CHAT_ID[40];
char SERVER_REPORT_ID[40];
char SERVER_SUGGESTION_ID[40];
char BOT_CONSOLE_ID[40];
char STEAM_API_KEY[60];
char SERVER_NAME[100];

char g_strSteamUserAvatar[MAXPLAYERS+1][200];

DiscordBot gBot;
DiscordChannel gServerChat;

Handle TokenKv = INVALID_HANDLE;
char BOT_TOKEN[120];

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

public void OnPluginStart()
{
    CheckConfigFile();
}

void CheckConfigFile()
{
    if(TokenKv != INVALID_HANDLE)
    {
      CloseHandle(TokenKv);
      TokenKv = INVALID_HANDLE;
    }

    char config[PLATFORM_MAX_PATH];
    char temp[PLATFORM_MAX_PATH];
    char item[20];
    char keyName[60];
    // int count;
    BuildPath(Path_SM, config, sizeof(config), "configs/discordbot_token.cfg");

    if(!FileExists(config))
    {
        SetFailState("[CP] NO CFG FILE! (configs/discordbot_token.cfg)");
        return;
    }

    TokenKv = CreateKeyValues("discord");

    if(!FileToKeyValues(TokenKv, config))
    {
      SetFailState("[CP] configs/discordbot_token.cfg is broken?!");
    }
    KvRewind(TokenKv);

    KvGetString(TokenKv, "bot_token", BOT_TOKEN, sizeof(BOT_TOKEN));
    KvGetString(TokenKv, "server_chat_id", SERVER_CHAT_ID, sizeof(SERVER_CHAT_ID));
    KvGetString(TokenKv, "server_report_id", SERVER_REPORT_ID, sizeof(SERVER_REPORT_ID));
    KvGetString(TokenKv, "server_suggestion_id", SERVER_SUGGESTION_ID, sizeof(SERVER_SUGGESTION_ID)); // STEAM_API_KEY
    KvGetString(TokenKv, "steam_api_key", STEAM_API_KEY, sizeof(STEAM_API_KEY));
    KvGetString(TokenKv, "server_name", SERVER_NAME, sizeof(SERVER_NAME));
    KvGetString(TokenKv, "bot_console_id", BOT_CONSOLE_ID, sizeof(BOT_CONSOLE_ID));
}

public void OnAllPluginsLoaded()
{
    if(gBot == INVALID_HANDLE)
    {
        gBot = new DiscordBot(BOT_TOKEN);
    }

    AddCommandListener(Listener_Say, "say");
    AddCommandListener(Listener_Say, "say_team");
}

public void OnMapStart()
{
    if(gBot != INVALID_HANDLE)
    {
        char map[50];
        char discordMessage[100];
        GetCurrentMap(map, sizeof(map));
        Format(discordMessage, sizeof(discordMessage), "현재 맵: %s", map);

        gBot.GetGuilds(GuildList);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, discordMessage);
    }
}
/*
public void OnMapEnd()
{
    if(gBot != INVALID_HANDLE)
    {
        gBot.StopListening();
    }
}
*/
public void OnClientPostAdminCheck(int client)
{
    if(gBot != INVALID_HANDLE && !IsFakeClient(client))
    {
        g_strSteamUserAvatar[client] = "";

        char steamAccount[60];
        char steamAvatarUrl[200];

        GetClientAuthId(client, AuthId_SteamID64, steamAccount, sizeof(steamAccount));
        Format(steamAvatarUrl, sizeof(steamAvatarUrl), "http://api.steampowered.com/ISteamUser/GetPlayerSummaries/v0002/?key=%s&steamids=%s", STEAM_API_KEY, steamAccount);
        PrepareRequest(steamAvatarUrl);

        char discordMessage[100];
        Format(discordMessage, sizeof(discordMessage), "%N님이 서버에 입장하셨습니다.", client);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, discordMessage);
    }
}

public void OnClientDisconnect(int client)
{
    if(gBot != INVALID_HANDLE && !IsFakeClient(client))
    {
        g_strSteamUserAvatar[client] = "";

        char discordMessage[100];
        Format(discordMessage, sizeof(discordMessage), "%N님이 서버에서 퇴장하셨습니다.", client);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, discordMessage);
    }
}

public SourceBans_OnBanPlayer(int client, int target, int time, char[] reason)
{
    if(gBot != INVALID_HANDLE && !IsFakeClient(target))
    {
        char discordMessage[100];
        char timeString[20];
        if(time > 0)
            Format(timeString, sizeof(timeString), "%d분 동안", time);
        else
            Format(timeString, sizeof(timeString), "영구적으로");

        Format(discordMessage, sizeof(discordMessage), "%N님이 %N님을 %s 서버에서 차단됩니다. (사유: %s)", client, target, timeString, reason);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, discordMessage);
    }
}

public void GuildList(DiscordBot bot, char[] id, char[] name, char[] icon, bool owner, int permissions, any data)
{
	gBot.GetGuildChannels(id, ChannelList, INVALID_FUNCTION, data);
}

public void ChannelList(DiscordBot bot, char[] guild, DiscordChannel Channel, any data) {

		char name[32];
		char id[32];
		Channel.GetID(id, sizeof(id));
		Channel.GetName(name, sizeof(name));

		if(StrEqual(id, SERVER_CHAT_ID))
        {
			//Send a message with all ways
			// gBot.SendMessage(Channel, "Sending message with DiscordBot.SendMessage");
			//gBot.SendMessageToChannelID(id, "Sending message with DiscordBot.SendMessageToChannelID");
			//Channel.SendMessage(gBot, "Sending message with DiscordChannel.SendMessage");

            gServerChat = view_as<DiscordChannel>(CloneHandle(Channel));
            if(!gBot.IsListeningToChannel(Channel))
			         gBot.StartListeningToChannel(Channel, OnMessage);
		}
        else if(StrEqual(id, BOT_CONSOLE_ID))
        {
            if(!gBot.IsListeningToChannel(Channel))
                gBot.StartListeningToChannel(Channel, OnMessage);
        }
}

public void GuildListAll(DiscordBot bot, ArrayList Alid, ArrayList Alname, ArrayList Alicon, ArrayList Alowner, ArrayList Alpermissions, any data) {

		char id[32];
		char name[64];
		char icon[128];
		bool owner;
		int permissions;

		// PrintToConsole(client, "Dumping Guilds from arraylist");

		for(int i = 0; i < Alid.Length; i++) {
			GetArrayString(Alid, i, id, sizeof(id));
			GetArrayString(Alname, i, name, sizeof(name));
			GetArrayString(Alicon, i, icon, sizeof(icon));
			owner = GetArrayCell(Alowner, i);
			permissions = GetArrayCell(Alpermissions, i);
			// PrintToConsole(client, "Guild: [%s] [%s] [%s] [%i] [%i]", id, name, icon, owner, permissions);
		}
}

public void OnMessage(DiscordBot Bot, DiscordChannel Channel, DiscordMessage message) {

    char messageString[120];
    char userName[60];
    char id[80];
    message.GetContent(messageString, sizeof(messageString));
    Channel.GetID(id, sizeof(id));

    DiscordUser user = message.GetAuthor();
    user.GetUsername(userName, sizeof(userName));
	// PrintToServer("Message from discord: %s", messageString);

    if(user.IsBot())
        return;

    if(StrEqual(id, BOT_CONSOLE_ID))
    {
        ServerCommand(messageString);
        char warn[200];
        Format(warn, sizeof(warn), "%s님이 \"%s\" 명령어를 사용하셨습니다.", userName, messageString);
        gBot.SendMessage(Channel, warn);
        return;
    }

	if(StrEqual(messageString, "Ping")) {
		gBot.SendMessage(Channel, "Pong!");
	}
    else
    {
        CPrintToChatAll("{discord}%s{default}: %s", userName, messageString);
    }
}

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

	char specialtext[3][150];
    ExplodeString(chat[2], " ", specialtext, sizeof(specialtext), sizeof(specialtext[]));

    if(chat[1] == '/')
        handleChat = true;

    if(gBot == INVALID_HANDLE)
        return Plugin_Continue;

	if(StrEqual("신고", specialtext[0]) ||
	StrEqual("report", specialtext[0]))
	{
        if(specialtext[1][0] == '\0' || specialtext[2][0] == '\0')
        {
            CPrintToChat(client, "{discord}[신고]{default} 올바른 사용: !신고 (대상) (사유)");
            return Plugin_Handled;
        }

        int target;
        if(IsCharNumeric(specialtext[1][0]) || IsCharAlpha(specialtext[1][0]) || specialtext[1][0] == '@') // 멀티 유저 설정
        {
            char targetName[MAX_TARGET_LENGTH];
        	int targets[MAXPLAYERS], matches;
        	bool targetNounIsMultiLanguage;

        	if((matches=ProcessTargetString(specialtext[1], client, targets, sizeof(targets), 0, targetName, sizeof(targetName), targetNounIsMultiLanguage))<=0)
        	{
        		CPrintToChat(client, "{discord}[신고]{default} 정해진 대상이 없습니다. 확실하게 대상을 지정해주십시요.");
        		return Plugin_Handled;
        	}

            if(matches>1)
            {
                for(target=0; target<matches; target++)
                {
                    if(!IsFakeClient(targets[target]))
                    {
                        ReportToDiscord(client, targets[target], specialtext[2]);
                        CPrintToChat(client, "{discord}[신고]{default} %N님의 신고가 접수되었습니다.", targets[target]);
                    }
                }
            }
            else
            {
                if(!IsFakeClient(targets[target]))
                {
                    ReportToDiscord(client, targets[0], specialtext[2]);
                    CPrintToChat(client, "{discord}[신고]{default} %N님의 신고가 접수되었습니다.", targets[0]);
                }
            }
        }
        else
        {
            CPrintToChat(client, "{discord}[신고]{default} 한글이나 특수문자 닉네임으로 지정한 신고는 현재 문제로 인해 대상을 알아낼 수 없습니다.\n해당 플레이어를 관전 후 {yellow}@aim{default}으로 지목해주십시요.");
        }


        return Plugin_Handled;
	}
    else if(StrEqual("건의", specialtext[0]) ||
    StrEqual("suggestion", specialtext[0]))
    {
        if(specialtext[1][0] == '\0')
        {
            CPrintToChat(client, "{discord}[건의]{default} 올바른 사용: !건의 (건의 내용)");
            return Plugin_Handled;
        }
        char mapName[80];
        char steamAccount[60];
        char discordMessage[300];
        GetCurrentMap(mapName, sizeof(mapName));
        GetClientAuthId(client, AuthId_Steam2, steamAccount, sizeof(steamAccount));
        Format(discordMessage, sizeof(discordMessage), "현재 맵: %s\n- %N [%s]: %s", mapName, client, steamAccount, chat[strlen(specialtext[0])+3]);

        gBot.SendMessageToChannelID(SERVER_SUGGESTION_ID, discordMessage);

        CPrintToChat(client, "{discord}[신고]{default} 해당 건의 {yellow}''%s''{default}가 접수되었습니다. 고맙습니다!", chat[strlen(specialtext[0])+3]);
        return Plugin_Handled;
    }

    if(!handleChat)
    {
        char discordMessage[400];
        char serverName[100];
        char steamUrl[200];
        char debugUrl[350];
        char discordName[100];
        char steamAccount[60];
        char playerName[60];
        GetClientName(client, playerName, sizeof(playerName));

        GetClientAuthId(client, AuthId_SteamID64, steamAccount, sizeof(steamAccount));
        Format(steamUrl, sizeof(steamUrl), "http://steamcommunity.com/profiles/%s", client, steamAccount);


        Format(discordName, sizeof(discordName), "%N (%s)", client, steamAccount);
        Format(discordMessage, sizeof(discordMessage), " - %N (%s):\n  %s", client, steamAccount, chat[1]);

        gBot.SendMessageToChannelID(SERVER_CHAT_ID, discordMessage);
        // Format(debugUrl, sizeof(debugUrl), "%s\n%s", steamUrl, g_strSteamUserAvatar[client]);

        /*
    	MessageEmbed Embed = new MessageEmbed();

    	Embed.SetColor("3978097");
        // Embed.SetAuthorData(discordName, g_strSteamUserAvatar[client]);
        Embed.Author = json_string(playerName);
    	Embed.SetTitle("");
        Embed.SetURL(steamUrl);
        Embed.SetDescription("서버 채팅이 저장됩니다.");
        Embed.SetData("type", "rich")
        Embed.AddField(SERVER_NAME, chat[1], true);

        gBot.SendMessageEmbed(gServerChat, Embed);
        */

        //gBot.SendMessageToChannelID(SERVER_CHAT_ID, debugUrl);

        //
    }


	return handleChat ? Plugin_Handled : Plugin_Continue;
}
void ReportToDiscord(int client, int target, char[] reason)
{
    if(gBot == INVALID_HANDLE) return;

    char discordMessage[1800];
    char steamAccount[60];
    char targetSteamAccount[60];
    char mapName[80];
    char timeString[60];
    float targetPos[3];
    GetClientAbsOrigin(target, targetPos);

    bool IsPlayerStuckOnPlayer = IsPlayerStuck(target);
    bool IsPlayerStuckOnWall = IsSpotSafe(target, targetPos, GetEntPropFloat(target, Prop_Send, "m_flModelScale"));

    FormatTime(timeString, sizeof(timeString), "%Y%m%d-%H%M%S", GetTime());
    GetCurrentMap(mapName, sizeof(mapName));
    GetClientAuthId(client, AuthId_Steam2, steamAccount, sizeof(steamAccount));
    GetClientAuthId(client, AuthId_Steam2, targetSteamAccount, sizeof(targetSteamAccount));

    Format(discordMessage, sizeof(discordMessage), " - 신고자: %N(%s)\n - 신고 대상: %N(%s)\n\n - 신고 사유: %s\n\n - 발생 시각: %s\n - 발생 맵 이름: %s\n - 신고 대상의 좌표: %.3f, %.3f, %.3f\n - 맵에 낌 유무: %s\n - 사람과 낌 유무: %s\n - 생존 유무: %s",
    client, steamAccount,
    target, steamAccount,
    reason,
    timeString,
    mapName,
    targetPos[0], targetPos[1], targetPos[2],
    IsPlayerStuckOnWall ? "네" : "아니요",
    IsPlayerStuckOnPlayer ? "네" : "아니요",
    IsPlayerAlive(target) ? "네" : "아니요"
    );

    gBot.SendMessageToChannelID(SERVER_REPORT_ID, discordMessage);
}

stock Handle PrepareRequest(char[] url, EHTTPMethod method=k_EHTTPMethodGET, Handle hJson=null)
{
	static char stringJson[16384];
	stringJson[0] = '\0';
	if(hJson != null) {
		json_dump(hJson, stringJson, sizeof(stringJson), 0, true);
	}

	Handle request = SteamWorks_CreateHTTPRequest(method, url);
	if(request == null) {
		return null;
	}

	SteamWorks_SetHTTPRequestRawPostBody(request, "application/json; charset=UTF-8", stringJson, strlen(stringJson));

	SteamWorks_SetHTTPRequestNetworkActivityTimeout(request, 30);


	SteamWorks_SetHTTPCallbacks(request, _, _, HTTPDataReceive);
	if(hJson != null) delete hJson;
    SteamWorks_SendHTTPRequest(request);


	return request;
}
/*
public int HTTPCompleted(Handle request, bool failure, bool requestSuccessful, EHTTPStatusCode statuscode, any data, any data2) {
}
*/

public int HTTPDataReceive(Handle request, bool failure, int offset, int statuscode, any dp)
{ // TODO: 최적화
    if(!failure)
    {
        char playerName[80];
        char IsplayerName[80];

        JsonObjectGetString(dp, "personaname", playerName, sizeof(playerName));

        for(int client=1; client<=MaxClients; client++)
        {
            if(IsClientInGame(client) && !IsFakeClient(client))
            {
                GetClientName(client, IsplayerName, sizeof(IsplayerName));

                if(StrEqual(playerName, IsplayerName))
                {
                    JsonObjectGetString(dp, "avatarfull", g_strSteamUserAvatar[client], sizeof(g_strSteamUserAvatar[]));
                }
            }
        }
    }

    delete view_as<Handle>(dp);
	delete request;
}
/*
public int HeadersReceived(Handle request, bool failure, any data, any datapack) {
	DataPack dp = view_as<DataPack>(datapack);
	if(failure) {
		delete dp;
		return;
	}

	char xRateLimit[16];
	char xRateLeft[16];
	char xRateReset[32];

	bool exists = false;

	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Limit", xRateLimit, sizeof(xRateLimit));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Remaining", xRateLeft, sizeof(xRateLeft));
	exists = SteamWorks_GetHTTPResponseHeaderValue(request, "X-RateLimit-Reset", xRateReset, sizeof(xRateReset));

	//Get url
	char route[128];
	ResetPack(dp);
	ReadPackString(dp, route, sizeof(route));
	delete dp;

	int reset = StringToInt(xRateReset);
	if(reset > GetTime() + 3) {
		reset = GetTime() + 3;
	}

	if(exists) {
		SetTrieValue(hRateReset, route, reset);
		SetTrieValue(hRateLeft, route, StringToInt(xRateLeft));
		SetTrieValue(hRateLimit, route, StringToInt(xRateLimit));
	}else {
		SetTrieValue(hRateReset, route, -1);
		SetTrieValue(hRateLeft, route, -1);
		SetTrieValue(hRateLimit, route, -1);
	}
}
*/
bool ResizeTraceFailed;

stock void constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

public bool IsSpotSafe(clientIdx, float playerPos[3], float sizeMultiplier)
{
	ResizeTraceFailed = false;
	static Float:mins[3];
	static Float:maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;

	return true;
}

bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset)
{
	static Float:tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static Float:targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;

	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	return true;
}

bool Resize_TestSquare(const float bossOrigin[3], float xmin, float xmax, float ymin, float ymax, float zOffset)
{
	static Float:pointA[3];
	static Float:pointB[3];
	for (new phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (new shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}

	return true;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3])
{
	static Float:result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceAnything);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}

	return true;
}

//Copied from Chdata's Fixed Friendly Fire
stock bool IsPlayerStuck(int ent)
{
    float vecMin[3];
	float vecMax[3];
	float vecOrigin[3];

    GetEntPropVector(ent, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(ent, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(ent, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, ent);
    return (TR_DidHit());
}

public bool TraceRayPlayerOnly(int iEntity, int iMask, any iData)
{
    return (IsValidClient(iEntity) && IsValidClient(iData) && iEntity != iData);
}

public bool TraceRayNoneOnly(int iEntity, int iMask, any iData)
{
    return !(IsValidClient(iEntity) && IsValidClient(iData) && iEntity != iData);
}

public bool TraceAnything(int entity, int contentsMask)
{
    return false;
}

/*
void ViewReportOptions(int client)
{
    Menu menu = new Menu(OnSelectedReportOption);
    menu.SetTitle("신고 유형을 선택해주십시요.");
    menu.AddItem("건의", "(신고는 아니지만) 건의");
    menu.AddItem("악용", "맵 버그 악용");
    menu.AddItem("채팅 악용", "채팅 악용");
    menu.AddItem("기타", "기타 사유 (채팅에 적어야 함.)");

    menu.ExitButton = true;

    menu.Display(client, 40);
}

public int OnSelectedReportOption(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
          case MenuAction_End:
          {
              menu.Close();
          }
          case MenuAction_Select:
          {
              PrepareReport[client] = view_as<ReportType>(item+1);
              switch(view_as<ReportType>(item))
              {
                case Report_Suggestion:
                {
                    readyReport[client] = true;
                }
                case Report_UseMapExploit:
                {
                    ViewTargetList(client);
                }
                case Report_ChatAttack:
                {
                    ViewTargetList(client);
                }
                case Report_Another:
                {
                    readyReport[client] = true;
                    CPrintToChat(client, "{green}신고 사유에 따라 전송되는 정보가 다르니 꼭 올바른 사유를 선택해주시길 바랍니다.{default}");
                    CPrintToChat(client, "{green}대상을 지정 후 신고 사유를 채팅창에 적어주세요.{default} (채팅에 뜨지 않음.)");
                    ViewTargetList(client);
                }
              }
          }
    }
}

void ViewTargetList(int client)
{
    Menu menu = new Menu(OnSelectedTarget);

    menu.SetTitle("신고 할 대상을 선택해주십시요.");
    char playerName[80];

    for(int target=1; target<=MaxClients; target++)
    {
        if(IsClientInGame(target) && client == target)
        {
            Format(playerName, sizeof(playerName), "%N", playerName);
            menu.AddItem("target", playerName);
        }
    }

    menu.ExitButton = true;

    menu.Display(client, 40);
}

public int OnSelectedReportOption(Menu menu, MenuAction action, int client, int item)
{
    switch(action)
    {
          case MenuAction_End:
          {
              menu.Close();
          }
          case MenuAction_Select:
          {
              ㄴ
          }
    }
}
*/
/*
public void OnMessage(DiscordBot bot, DiscordChannel channel, const char[] discordMessage, const char[] messageID, const char[] userID, const char[] userName, const char[] discriminator)
{

    CPrintToChatAll("{yellow}%s: %s{default}", userName, discordMessage); // TODO: 이 채팅을 보고 싶은 사람만.
    // 채팅 색으로 인한 크래쉬인가?
}
*/

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

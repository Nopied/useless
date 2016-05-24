#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

bool g_bTra[MAXPLAYERS+1];
bool g_bTraLoop[MAXPLAYERS+1];

int g_iPlayerFrame[MAXPLAYERS+1];

public Plugin:myinfo = {
	name = "I want play Overwatch...",
	description = "Tang - Tang - Tang!",
	author = "Nopied◎",
	version = "Overwatch",
};

public void OnPluginStart()
{
	RegConsoleCmd("tra", CmdOver);
}

public Action CmdOver(int client, int args)
{
	if(!g_bTra[client]){
		 g_bTra[client]=true;
		 g_iPlayerFrame[client]=0;
	}
	else g_bTra[client]=false;
	PrintToChat(client, "%s", g_bTra[client] ? "활성화" : "비활성화");
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if(!IsValidClient(client) || !IsPlayerAlive(client) || !g_bTra[client] || g_bTraLoop[client]) return Plugin_Continue;

	if(buttons & IN_RELOAD)
	{
		g_bTraLoop=true;
		PrintCenterText(client, "......!");
	}
	return Plugin_Continue;
}

public void OnGameFrame()
{
	static float flPlayerVelocity[MAXPLAYERS+1][1000][3];
	float velocity[3];

	for(int client=1; client<=MaxClients; client++)
	{
		if(!IsValidClient(client) || !g_bTra[client]) continue;

		if(!g_bTraLoop[client])
		{
/*			for(int frame=g_iPlayerFrame[client]; 0<frame;)
			{
				frame--;
				flPlayerVelocity[client][frame][0]=flPlayerVelocity[client][frame+1][0];
				flPlayerVelocity[client][frame][1]=flPlayerVelocity[client][frame+1][1];
				flPlayerVelocity[client][frame][2]=flPlayerVelocity[client][frame+1][2];
			}
*/

			GetEntPropVector(client, Prop_Data, "m_vecVelocity", velocity);

			velocity[0]*=-1.0;
			velocity[1]*=-1.0;
			velocity[2]*=-1.0;

			flPlayerVelocity[client][g_iPlayerFrame[client]][0]=velocity[0];
			flPlayerVelocity[client][g_iPlayerFrame[client]][1]=velocity[1];
			flPlayerVelocity[client][g_iPlayerFrame[client]][2]=velocity[2];

			if(g_iPlayerFrame[client] < 1000) g_iPlayerFrame[client]++;
		}
		else
		{
			for(int frame=g_iPlayerFrame[client]; frame>0; frame--)
			{
				TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, flPlayerVelocity[client][frame]);
			}
			g_bTraLoop[client]=false;
		}
	}
}
//

stock bool IsValidClient(int client)
{
	return (0 < client && client < MaxClients && IsClientInGame(client));
}

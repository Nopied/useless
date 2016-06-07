#include <sourcemod>
#include <morecolors>

new Handle:cvarResetTimer;

new h_time;
new WastedTime;

public Plugin:myinfo=
{
	name="Wait for players (For tf2)",
	author="Nopied◎",
	description="EZ(Because this plugin used Cvar(mp_waitingforplayers_restart)",
};

public OnPluginStart()
{
	cvarResetTimer=CreateConVar("sm_reset_timersec", "90", "Nope.", FCVAR_PLUGIN, true, 1.0);

	LoadTranslations("reset_timer.phrases");

}

public OnMapStart()
{
	WastedTime = 0;
	h_time = GetConVarInt(cvarResetTimer);

	CreateTimer(1.0, Timer_reset, _, TIMER_REPEAT);
}

public Action:Timer_reset(Handle:timer)
{
	if (h_time <= 0)
	{
		CPrintToChatAll("{green}[SM]{default} %t", "NowBegin");
		return Plugin_Stop;
	}

	h_time--;
	WastedTime++;

	ServerCommand("mp_waitingforplayers_restart 1");

	if (WastedTime >= 20)
	{
		CPrintToChatAll("{green}[SM]{default} %t", "waitfortimer")
		WastedTime = 0;
	}

	return Plugin_Continue;
}

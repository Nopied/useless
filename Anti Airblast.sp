#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

new Handle:cvarCooltime;

new Float:Cooltime;

public Plugin:myinfo=
{
	name="Anti Infinity Airblast",
	author="Team Potry : Nopied◎",
	description="",
};

public OnPluginStart()
{
	AddCommandListener(Command_blast, "+attack2");
	
	cvarCooltime = CreateConVar("sm_blast_cooltime", "5.0", "Yeah.", _, true, 0.0);
	
}

public Action:Command_blast(client, const String:command[], arg)
{
	if(TF2_GetPlayerClass(client) == TFClass_Pyro)
	{
		if(GetClientButtons(client) & IN_WEAPON1)
		{
			new weapon=GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			new viewmodel=GetEntPropEnt(client, Prop_Send, "m_hViewModel");
			Cooltime = GetConVarFloat(cvarCooltime);
		
			SetEntPropFloat(weapon, Prop_Send, "m_flNextPrimaryAttack", GetGameTime()+Cooltime);
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", GetGameTime()+Cooltime);
			SetEntPropFloat(client, Prop_Send, "m_nNextThinkTick'", GetGameTime()+Cooltime);
			SetEntProp(viewmodel, Prop_Send, "m_nSequence", 10);
		
			CPrintToChat(client, "{green}[SM]{defalut} 에어블라스트 쿨타임 %d초!", Cooltime);
			
			return Plugin_Stop;
		}
	}
	
	return Plugin_Continue;
}

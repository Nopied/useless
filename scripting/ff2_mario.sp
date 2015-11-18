// 나중으로 미룸.

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>  


#define PLUGIN_VERSION "1.0"

public Plugin:myinfo=
{
    name="Freak Fortress 2: Mario abilities",
    author="Nopied◎",
    description="Wat?",
    version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	// 이거 쓰긴 할거니?
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{

	// new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0); 
	// If you want...
	
	if(!strcmp(ability_name, "charge_cape"))
	{
		Charge_Cape(boss, ability_name);
	}
}

Charge_Cape(boss, ability_name)
{
	new distance = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 1, 30.0); 
	new m_bossrage = FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2, 10.0);
	new bosspos[3]; GetEntDataVector(boss, Prop_Send, "m_vecOrigin", bosspos);
	new clientpos[3]; new clientangle[3];
	
	for(new client=0; client<=MaxClients; client++)
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", clientpos);
		if(GetVectorDistance(bosspos, clientpos) <= distance) // 보스의 시야에 보일 경우에만 해당되도록 수정해야됨.
		{
			GetEntPropVector(client, Prop_Send, "m_vecAbsOrigin", clientangle);
			
			clientangle[0] -= 90.0; if(clientangle[0] < 0.0) clientangle[0] *= -1.0;
			clientangle[1] -= 90.0; if(clientangle[1] <  -180.0) clientangle[1] *= -1.0;
			clientangle[2] -= 90.0; if(clientangle[2] < -180.0)	clientangle[2] *= -1.0;
			
			SetEntDataVector(client, Prop_Send, "m_vecAbsOrigin", clientangle);
			
			PrintCenterText(client, "Caped!");
			// FF2_RandomSound | (test later..)
			
			
		}
	}
	
	FF2_SetBossCharge(boss, 0, (FF2_GetBossCharge(boss) - m_bossrage));
	
}


/*

For Notepad++:

	FF2 inc:
		FF2_GetBossIndex
		FF2_SetBossRageDamage
		FF2_GetBossCharge
		FF2_SetBossCharge
		FF2_GetAbilityArgument
		FF2_GetAbilityArgumentFloat
		FF2_GetAbilityArgumentString
		FF2_RandomSound
		FF2_OnMusic
		
	SM: 
		CreateTimer
		GetClientButtons
		GetEntData
		GetEntDataEnt
		GetEntDataVector
		SetEntData
		SetEntDataEnt
		SetEntDataVector
		GetVectorDistance
		DispatchSpawn
		DispatchKeyValue



*/

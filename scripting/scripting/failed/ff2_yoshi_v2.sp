// failed. 모델이 불량품이네요 D:

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>  

#define PLUGIN_VERSION "1.0"

new eggs[MAXPLAYERS+1]=0;
new egginfo[MAXPLAYERS+1]=0;

new Float:eggpos[][3];
new bool:enableeggpos[MAXPLAYERS+1] = false;

new deadcount=0;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Yoshi abilities",
    author="Nopied",
    description="Yoshi!!",
    version=PLUGIN_VERSION,
};

public OnPluginStart2()
{
	// LoadTranslations("ff2_yoshi");
	
	HookEvent("player_death", PlayerDead);
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	// new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0); 
	// If you want...
	
	if(!strcmp(ability_name, "charge_egg_ability"))
	{
	
	}
}

public Action:PlayerDead(Handle:event, const String:name[], bool:dontBroadcast)
{

	// Copied from ff2_1st_set_abilities

	new client=GetClientOfUserId(GetEventInt(event, "userid"));
	new boss;
	
	if(!FF2_HasAbility(boss, this_plugin_name, "charge_egg_ability"))
	{
		return Plugin_Continue;
	}
	
	for(new i=0; i<=MaxClients; i++)
	{
		if(FF2_GetBossIndex(i) != -1) 
		{
			boss = i;
			break;
		}
	}
	
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", eggpos[deadcount]);

	new String:m[PLATFORM_MAX_PATH];
	
	// Copied from ff2_1st_set_abilities
	
	FF2_GetAbilityArgumentString(boss, this_plugin_name, "charge_egg_ability", 1, m, sizeof(m));
	
	if(m[0]!='\0')
	{
		if(!IsModelPrecached(m))
		{
			if(!FileExists(m, true))
			{
				PrintToServer("[FF2 Yoshi] ERROR!! I think you don't have model file.");
				return Plugin_Continue;
			}
			PrintToServer("[FF2 Yoshi] WARMING! Please write \"mod_precache\".");
			PrecacheModel(m);
		}
		
		CreateTimer(0.01, Timer_RemoveRagdoll, GetEventInt(event, "userid"));
		
		new prop=CreateEntityByName("prop_physics_override");
		if(IsValidEntity(prop))
		{
			SetEntityModel(prop, m);
			SetEntityMoveType(prop, MOVETYPE_NONE);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
			DispatchSpawn(prop);
			
			eggpos[deadcount][2]+=20;
			
			TeleportEntity(prop, eggpos[deadcount], NULL_VECTOR, NULL_VECTOR);
		}
	}
	else 
	{
		PrintToServer("[FF2 Yoshi] WARMING! No egg model. (arg5 is blank!?)");
		return Plugin_Continue;
	}
	
	enableeggpos[deadcount] = true;
	deadcount++;
	
	return Plugin_Continue;
}

public Action:Timer_RemoveRagdoll(Handle:timer, any:userid)
{
	new client=GetClientOfUserId(userid);
	new ragdoll;
	if(client>0 && (ragdoll=GetEntPropEnt(client, Prop_Send, "m_hRagdoll"))>MaxClients)
	{
		AcceptEntityInput(ragdoll, "Kill");
	}
}

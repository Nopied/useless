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

new realboss;

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
	LoadTranslations("ff2_yoshi");
	
	HookEvent("player_death", PlayerDead);
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	// new slot=FF2_GetAbilityArgument(boss, this_plugin_name, ability_name, 0); 
	// If you want...
	
	realboss = boss;
	
	if(!strcmp(ability_name, "charge_egg_ability"))
	{
	
	}
}

public Action:PlayerDead(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client=GetEventInt(event, "userid");
	
	if(!FF2_HasAbility(realboss, this_plugin_name, "charge_egg_ability"))
	{
		return Plugin_Continue;
	}
	
	GetClientEyePosition(client, eggpos[deadcount]);	
	
	if(!CreateEgg(eggpos[deadcount], client)) PrintToServer("WTF!?");
	
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

stock bool:CreateEgg(Float:pos[3], client)
{
	decl String:model[PLATFORM_MAX_PATH];
	
	// Copied from ff2_1st_set_abilities
	
	FF2_GetAbilityArgumentString(realboss, this_plugin_name, "charge_egg_ability", 5, model, sizeof(model));
	
	if(model[0] != '\0') 
	{
		if(!IsModelPrecached(model))
		{
			if(!FileExists(model, true))
			{
				PrintToServer("[FF2 Yoshi] ERROR!! I think you don't have model file.");
				return false;
			}
			PrintToServer("[FF2 Yoshi] WARMING! Please write \"mod_precache\".");
			return false;
		}
		
		CreateTimer(0.01, Timer_RemoveRagdoll, client);
		
		new prop=CreateEntityByName("prop_physics_override");
		if(IsValidEntity(prop))
		{
			SetEntityModel(prop, model);
			SetEntityMoveType(prop, MOVETYPE_NONE);
			SetEntProp(prop, Prop_Send, "m_CollisionGroup", 1);
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16);
			DispatchSpawn(prop);

			new Float:position[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);
			position[2]+=20;
			TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);
		}
		
		return true;
	}
	else PrintToServer("[FF2 Yoshi] WARMING! No egg model. (arg5 is blank!?)");
	
	return false;
	
}

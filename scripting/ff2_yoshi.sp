/* 

해당 작업은 본인의 시험이 끝난 뒤 만들 예정.

요시:

패시브: 사람을 죽여서 알로 바꿀 수 있음. (기본적으로 최대 한도는 3개.)
(알이 된 상태에서 주워야함 (화살표나 빛으로 위치 표시))

엑티브: 알이 하나라도 있어야함. + 짧은 스턴

- 알을 던져서 터침. (재장전 키로 조준하고 때면 발사.)
(데미지는 알이 되었던 상대의 최대 체력)

- 알을 먹어서 체력 회복. (줍기 전 상태에서 알이 있는 위치에 앉기)

(회복량은 알이 되었던 상대의 딜의 2분의 1(최대 1000까지))

*/



#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stock>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

new Eggs[MAXPLAYERS+1]=0;
new EggPos[MAXPLAYERS+1][3];
new ClientInfo[MAXPLAYERS+1][2]; // 0은 데미지, 1은 최대체력

new Handle:OnHaleRage = INVALID_HANDLE;

public Plugin:myinfo={
	name="Freak Fortress 2 : Yoshi",
	author="Team Potry : Nopied",
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    OnHaleRage=CreateGlobalForward("VSH_OnDoRage", ET_Hook, Param_FloatByRef);  

    return APLRes_Success;
}

public Action:FF2_OnAbility2(boss, const String:plugin_name[], const String:ability_name[], status)
{
	new slot=FF2_GetAbliltyArgument(client, this_plugin_name, ability_name);
	if(!slot)
	{
		if(!boss)
		{
			new Float:distance=FF2_GetRageDist(boss, this_plugin_name, ability_name);
			new Float:Distance=distance;
			new Action:action=Plugin_Continue;
			
			Call_StartForward(OnHaleRage);
			Call_PushFloatRef(Distance);
			Call_Finish(action);
			
			if(action != Plugin_Continue && action != Plugin_Changed) return Plugin_Continue;
			
			else if(action == Plugin_Changed) distance = Distance;
			
		}
	}
	
	if(!strcmp(ability_name, "charge_egg_ability"))
	{
		HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
		for 
		Charge_egg_ability(boss)
	}
}

Charge_egg_ability(boss)
{
	
}

public Action:PlayerDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new boss;
	
	if(FF2_GetBossIndex(client) != -1)
	{
		return Plugin_Continue;
	}
	
	GetClientEyePosition(client, EggPos[client]); //
	
	
	new entity = CreateEntityByName("light_dynamic");
	// 고맙습니다 엘리스님.
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		DispatchKeyValue(entity, "_light", "0 255 0");		
		SetEntProp(entity, Prop_Send, "m_Exponent", 7);	
		SetEntPropFloat(entity, Prop_Send, "m_Radius", 280.0);	

		TeleportEntity(entity, EggPos[client], NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(entity, "SetParent", client);		
	}
	boss = GetBossIndex();
	
	if( FF2_HasAbility(boss, ff2_1st_set_abilities, special_dropprop) )
	{
		CreateTimer(0.1, Timer_StopEgg);
	}	
}

public Action:Timer_StopEgg(Handle:timer)
{
	new eggprop = FindEntityByClassname("prop_physics_override");
	if (IsValidEntity(eggprop)) SetEntityMoveType(prop, MOVETYPE_NONE);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:pos[3], Float:Angle[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new boss = GetBossIndex();
	
	if(IsPlayerAlive(client))
	{
		ClientInfo[0] = FF2_GetClientDamage(client);
		ClientInfo[1] = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	}
	
	for(new i=0; i<=MaxClient; i++)
	{
		if(GetVectorDistance(pos, EggPos[i]) <= FF2_GetAbilityArgumentFloat(boss, , ff2_yoshi, charge_egg_ability, 1, 10.0))
		{
			if(boss == client) 
			{
				if(Eggs[client] >= FF2_GetAbliltyArgument(boss, ff2_yoshi, charge_egg_ability, 0, 3))
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "cant_get_egg");
				}
				else
				{
					Eggs[client]++;
					removeegg(EggPos[i]);
				}
			}
			else
			{
				if(Eggs[client] >= FF2_GetAbilityArgument(boss, ff2_yoshi, charge_egg_ability, 2, 1))
				{
					CPrintToChat(client, "{olive}[FF2][default} %t", "cant_get_egg");
				}
				else
				{
					Eggs[client]++;
					removeegg(EggPos[i]);
				}
			}
		}
	}
	
	if(Eggs[client] > 0)
	{
		if (boss = client) PrintCenterText(client, "%t", "print_egg", Eggs[client], FF2_GetAbliltyArgument(boss, ff2_yoshi, charge_egg_ability, 0, 3));
		else PrintCenterText(client, "t", "print_egg", Eggs[client], FF2_GetAbilityArgument(boss, ff2_yoshi, charge_egg_ability, 2, 1));
	}
	
	else return Plugin_Continue;
	
	if
	
	
	
	
	
}

stock GetBossIndex()
{
	for(new client = 0;  client<=MaxClient; client++)
	{
		if(FF2_GetBossIndex(client) != -1)
		{
			return FF2_GetBossIndex(client); // 
		}
	}
	return -1;
}

stock removeegg(Float:Pos[3])
{
	
}

}

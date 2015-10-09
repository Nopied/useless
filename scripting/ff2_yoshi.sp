/* 

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
new EggInfo[][2];
new EggPos[][3];
new whategg[MAXPLAYERS+1][];

new DeadCount=0;

// 0은 데미지, 1은 최대체력

new Handle:OnHaleRage = INVALID_HANDLE;

public Plugin:myinfo={
	name="Freak Fortress 2 : Yoshi",
	author="Team Potry : Nopied",
};

public OnPluginStart2()
{
	HookEvent("player_death", PlayerDeath, EventHookMode_Pre);
}

public Action:PlayerDeath(Handle:event, const String:eventName[], bool:dontBroadcast)
{
	new client=GetClientOfUserId(GetEventInt(event, "userid")), attacker=GetClientOfUserId(GetEventInt(event, "attacker"));
	new boss;
	
	if(FF2_GetBossIndex(client) != -1)
	{
		return Plugin_Continue;
	}
	
	GetClientEyePosition(client, EggPos[DeadCount]); //
	
	EggInfo[DeadCount][0] = FF2_GetClientDamage(client)/3;
	
	EggInfo[DeadCount][1] = GetEntProp(client, Prop_Data, "m_iMaxHealth");
	
	new entity = CreateEntityByName("light_dynamic");
	// 고맙습니다 엘리스님.
	if( IsValidEntity(entity) )
	{
		DispatchSpawn(entity);
		DispatchKeyValue(entity, "_light", "0 255 0");		
		SetEntProp(entity, Prop_Send, "m_Exponent", 7);	
		SetEntPropFloat(entity, Prop_Send, "m_Radius", 280.0);	

		TeleportEntity(entity, EggPos[DeadCount], NULL_VECTOR, NULL_VECTOR);

		AcceptEntityInput(entity, "SetParent", client);		
	}
	boss = GetBossIndex();
	
	if( FF2_HasAbility(boss, ff2_1st_set_abilities, special_dropprop) )
	{
		CreateTimer(0.03, Timer_StopEgg);
	}

	DeadCount++;
}

public Action:Timer_StopEgg(Handle:timer)
{
	new eggprop = FindEntityByClassname("prop_physics_override");
	if (IsValidEntity(eggprop)) SetEntityMoveType(prop, MOVETYPE_NONE);
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:pos[3], Float:Angle[3], &weapon, &subtype, &cmdnum, &tickcount, &seed, mouse[2])
{
	new boss = GetBossIndex();
	
	for(new i=0; i<=DeadCount; i++)
	{
		if(GetVectorDistance(pos, EggPos[i]) <= FF2_GetAbilityArgumentFloat(boss, , this_plugin_name, charge_egg_ability, 1, 10.0))
		{
			if(buttons & IN_DUCK)
			{
				if(EggInfo[i][0] > FF2_GetAbilityArgument(boss, this_plugin_name, "charge_egg_ability", 3, 1000)) 
					EggInfo[i][0] = FF2_GetAbilityArgument(boss, this_plugin_name, "charge_egg_ability", 3, 1000);
				
				if(client == boss) FF2_SetBossHealth(boss, (FF2_GetBossHealth(boss) + EggInfo[i][0]));
				else
				{
				SetEntProp(client, Prop_Data, "m_iHealth", EggInfo[i][0]); 
				SetEntProp(client, Prop_Send, "m_iHealth", EggInfo[i][0]);
				}
				if(!removeegg(EggPos[i])) PrintToServer("WTF?!");
				EggPos[i] = NULL; //
				
			}
			if(boss == client) 
			{
				
				if(Eggs[client] >= FF2_GetAbliltyArgument(boss, this_plugin_name, "charge_egg_ability", 0, 3))
				{
					CPrintToChat(client, "{olive}[FF2]{default} %t", "cant_get_egg");
				}
				else
				{
					Eggs[client]++; 
					whategg[client][Eggs[client]] = EggInfo[DeadCount][1];
					if(!removeegg(EggPos[i])) PrintToServer("WTF?!");
					EggPos[i] = NULL; // 
				}
			}
			else
			{
				if(Eggs[client] >= FF2_GetAbilityArgument(boss, this_plugin_name, "charge_egg_ability", 2, 1))
				{
					CPrintToChat(client, "{olive}[FF2][default} %t", "cant_get_egg");
				}
				else
				{
					Eggs[client]++;
					whategg[client][Eggs[client]] = EggInfo[DeadCount][1];
					if(!removeegg(EggPos[i])) PrintToServer("WTF?!");
					EggPos[i] = NULL; //
				}
			}
		}
	}
	
	if(Eggs[client] > 0)
	{
		if (boss = client) PrintCenterText(client, "%t", "print_egg", Eggs[client], FF2_GetAbliltyArgument(boss, ff2_yoshi, charge_egg_ability, 0, 3), whategg[client][Eggs[client]]);
		else PrintCenterText(client, "t", "print_egg", Eggs[client], FF2_GetAbilityArgument(boss, ff2_yoshi, charge_egg_ability, 2, 1), whategg[client][Eggs[client]]);
	}
	
	else return Plugin_Continue;

	
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

stock bool:removeegg(Float:Pos[3])
{ 
	new Float:proppos[3];
	
	new eggprop = FindEntityByClassname("prop_physics_override");
	if(IsValidEntity(eggprop))
	{
		GetEntPropVector(eggprop, Prop_Data, "m_vecOrigin", proppos);
		if(GetVectorDistance(Pos, proppos) <= 3)
		{
			AcceptEntityInput(eggprop, "Kill");
			return true;
		}
	}	
	else return false;
}

}




















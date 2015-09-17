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

new Eggs=0;

new Handle:OnHaleRage = INVALID_HANDLE;

pubilc Plugin:myinfo={
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
	new slot=FF2GetAbliltyArgument(client, this_plugin_name, ability_name);
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
		
	}
}

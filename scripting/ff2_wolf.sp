#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#define SOUND_SHIELD "weapons/medi_shield_deploy.wav"

//int PlayerShield[MAXPLAYERS+1];

public Plugin:myinfo=
{
	name="Freak Fortress 2: Wolf's Abilities",
	author="Nopied◎",
	description="",
	version="EE",
};

public void OnPluginStart2()
{
  if(!IsSoundPrecached(SOUND_SHIELD))
    PrecacheSound(SOUND_SHIELD);
  HookEvent("medigun_shield_blocked_damage", OnBlocked, EventHookMode_Post);
}

public Action OnBlocked(Handle event, const char[] name, bool dont)
{
  int boss=FF2_GetBossIndex(GetClientOfUserId(GetEventInt(event, "userid")));
  if(FF2_HasAbility(boss, this_plugin_name, "wolf_deflecter"))
  {
		int client=GetClientOfUserId(GetEventInt(event, "userid"));
		float abilityTime=FF2_GetAbilityDuration(boss);
		/*
		FF2_SetBossCharge(boss, 0, FF2_GetBossCharge(boss, 0)+(GetEventFloat(event, "damage")*100.0/float(FF2_GetBossRageDamage(boss))));
		if(FF2_GetBossCharge(boss, 0) > 100.0)
			FF2_SetBossCharge(boss, 0, 100.0);


		*/
		if(abilityTime<=0.0)
		{
			if(GetEntPropFloat(client, Prop_Send, "m_flRageMeter") > 15.0)
				SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 15.0);
			return Plugin_Continue;
		}

		FF2_SetAbilityDuration(boss, abilityTime+3.0 > 70.0 ? 70.0 : abilityTime+3.0);

		SetEntPropFloat(client, Prop_Send, "m_flRageMeter",
			GetEntPropFloat(client, Prop_Send, "m_flRageMeter") > abilityTime*11.5 ?
			11.5*70.0 : abilityTime*11.5);
  }
	return Plugin_Continue;
}

public Action FF2_OnRageEnd(int boss)
{
	int client=GetClientOfUserId(FF2_GetBossUserId(boss));
	SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 15.0);
}

public Action FF2_OnAbility2(int boss, const char[] pluginName, const char[] abilityName, int status)
{
  if(!strcmp(abilityName, "wolf_deflecter"))
  {
		int client=GetClientOfUserId(FF2_GetBossUserId(boss));
    // PlayerShield[client]=SpawnShield(client);
		SpawnShield(client);
  }
}

stock int SpawnShield(int client)
{
  int shield = CreateEntityByName("entity_medigun_shield");
  if(IsValidEntity(shield))
  {
    SetEntPropEnt(shield, Prop_Send, "m_hOwnerEntity", client);
    SetEntProp(shield, Prop_Send, "m_iTeamNum", GetClientTeam(client));
    SetEntProp(shield, Prop_Data, "m_iInitialTeamNum", GetClientTeam(client));
    if (GetClientTeam(client) == _:TFTeam_Red) DispatchKeyValue(shield, "skin", "0");
    else if (GetClientTeam(client) == _:TFTeam_Blue) DispatchKeyValue(shield, "skin", "1");
    SetEntPropFloat(client, Prop_Send, "m_flRageMeter", 12.5*FF2_GetAbilityArgumentFloat(FF2_GetBossIndex(client), this_plugin_name, "wolf_deflecter", 1, 15.0));
    SetEntProp(client, Prop_Send, "m_bRageDraining", 1);
    DispatchSpawn(shield);
    EmitSoundToClient(client, "weapons/medi_shield_deploy.wav", shield);
    SetEntityModel(shield, "models/props_mvm/mvm_player_shield2.mdl");
		return shield;
  }
	return -1;
}

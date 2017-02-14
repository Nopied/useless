#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

/*
passive_painis
Arg 1=회복 최대량
Arg 2=사운드 경로 (먹는 사운드)

Rage_Painis
Arg 1=사운드 경로


*/

char RageSoundPath[PLATFORM_MAX_PATH];

public Plugin myinfo=
{
	name="Freak Fortress 2: Painis Cupcake's Abilities",
	author="Nopied",
	description="",
	version="wat.",
};

bool playingSound;

public void OnPluginStart2()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_Post);
}

public Action OnRoundEnd(Handle event, const char[] name, bool dont)
{
	for(int target=1; target<=MaxClients; target++)
	{
		if(IsValidClient(target))
			StopSound(target, SNDCHAN_AUTO, RageSoundPath);
	}
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
  int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
  int victim = GetClientOfUserId(GetEventInt(event, "userid"));

  if(!IsBossTeam(victim) && FF2_HasAbility(FF2_GetBossIndex(attacker), this_plugin_name, "passive_painis") && !(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER))
  {
    int boss = FF2_GetBossIndex(attacker);
    int healHp = FF2_GetClientDamage(victim)/2;
    char bossName[64];
    char sound[PLATFORM_MAX_PATH];
    Handle BossKV=FF2_GetSpecialKV(boss);

    KvRewind(BossKV);
    KvGetString(BossKV, "name", bossName, sizeof(bossName), "ERROR NAME");
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "passive_painis", 2, sound, sizeof(sound));

    if(healHp > FF2_GetAbilityArgument(boss, this_plugin_name, "passive_painis", 1, 500))
      healHp=FF2_GetAbilityArgument(boss, this_plugin_name, "passive_painis", 1, 500);

    FF2_SetBossHealth(boss, FF2_GetBossHealth(boss)+healHp);
    if(FF2_GetBossHealth(boss) > FF2_GetBossMaxHealth(boss))
      FF2_SetBossHealth(boss, FF2_GetBossMaxHealth(boss));

    TF2_StunPlayer(attacker, 2.2, 0.0, TF_STUNFLAG_BONKSTUCK|TF_STUNFLAG_NOSOUNDOREFFECT); // TODO: 커스터마이즈

    EmitSoundToAll(sound);
    CPrintToChatAll("{olive}[FF2]{default} {blue}%s{default}(이)가 {green}%N{default}님을 먹었습니다. (+%dHP)", bossName, victim, healHp);
    if(FF2_GetAbilityDuration(boss) > 0.0)
	{
      	PainisRage(boss);
	}
  }
  return Plugin_Continue;
}

public Action FF2_OnAbilityTimeEnd(int boss, int slot, String:abilityName[])
{
  if(playingSound && slot == 0 && StrEqual(abilityName, "rage_painis", true))
  {
    FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_painis", 1, RageSoundPath, sizeof(RageSoundPath));

    for(int target=1; target<=MaxClients; target++)
    {
      if(IsValidClient(target))
        StopSound(target, SNDCHAN_AUTO, RageSoundPath);
    }
    playingSound=false;
  }
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{
  if(!strcmp(ability_name, "rage_painis"))
  {
    // Debug("Userid: %d, client: %d", FF2_GetBossUserId(boss), GetClientOfUserId(FF2_GetBossUserId(boss)));
    PainisRage(boss);
  }
  return Plugin_Continue;
}

// EmitSoundToAll
void PainisRage(int boss)
{
  int client=GetClientOfUserId(FF2_GetBossUserId(boss));
  float abilityDuration=KvGetFloat(FF2_GetSpecialKV(boss), "ability_duration", 10.0);

  FF2_GetAbilityArgumentString(boss, this_plugin_name, "rage_painis", 1, RageSoundPath, sizeof(RageSoundPath));

  for(int target=1; target<=MaxClients; target++)
  {
    if(IsValidClient(target))
      StopSound(target, SNDCHAN_AUTO, RageSoundPath);
  }

  EmitSoundToAll(RageSoundPath); // KvGetFloat
  TF2_AddCondition(client, TFCond_Ubercharged, abilityDuration);

  FF2_SetAbilityDuration(boss, abilityDuration);
  playingSound=true;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

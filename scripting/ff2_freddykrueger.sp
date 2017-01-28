#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <record_client>
#include <morecolors>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Freddy Krueger's Ability",
    author="Nopied",
    description="FF2",
    version="1.0",
};

bool CanRecordMinion;
int OwnerIndex;
char MinionModelPath[PLATFORM_MAX_PATH];

int RecordMinionOwner[MAXPLAYERS+1];

public void OnPluginStart2()
{
    HookEvent("arena_round_start", OnRoundStart);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Pre);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
  	CheckAbilities();
}

void CheckAbilities()
{
  int client, boss;

  CanRecordMinion = false;
  OwnerIndex = -1;
  strcopy(MinionModelPath, sizeof(MinionModelPath), "");

  for(client=1; client<=MaxClients; client++)
  {
      RecordMinionOwner[client] = -1;

      if((boss=FF2_GetBossIndex(client)) != -1)
      {
          if(FF2_HasAbility(boss, this_plugin_name, "ff2_record_minion"))
          {
              CanRecordMinion = true;
              OwnerIndex = client;
              GetClientModel(client, MinionModelPath, sizeof(MinionModelPath));

              CreateTimer(1.0, RecordTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
          }
      }
  }
}

public Action RecordTimer(Handle timer)
{
    if(FF2_GetRoundState() != 1 || !IsValidClient(OwnerIndex))
    {
        OwnerIndex = -1;
        return Plugin_Stop;
    }

    int BossTeam = FF2_GetBossTeam();
    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && RecordMinionOwner[client] < 0 && GetClientTeam(client) != BossTeam && !IsPlayerAlive(client))
        {
            RecordMinionOwner[client] = OwnerIndex;

            ChangeClientTeam(client, BossTeam);
            TF2_SetPlayerClass(client, TF2_GetPlayerClass(OwnerIndex));
            TF2_RespawnPlayer(client);

        }
    }
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{

}


stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsValidClient(int client)
{
    return (0<client && client <= MaxClients && IsClientInGame(client));
}

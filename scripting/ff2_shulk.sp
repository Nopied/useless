#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>

enum MonadoArt
{
    Monado_Overloaded=-1,
    Monado_None=0,
    Monado_Jump,
    Monado_Speed,
    Monado_Shield,
    Monado_Buster,
    Monado_Smash
};

bool ButtonPressed[MAXPLAYERS+1];
bool EnableMonado[MAXPLAYERS+1];
int ClientMonado[MAXPLAYERS+1];
float MonadoOverloadTimer[MAXPLAYERS+1];

public Plugin myinfo=
{
    name="Freak Fortress 2 : Shulk's Abilities",
    author="Nopied",
    description="....",
    version="2016_07_21",
};

public void OnPluginStart2()
{
    HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_Post);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    CreateTimer(10.4, RoundStarted, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action RoundStarted(Handle timer)
{
    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && FF2_HasAbility(FF2_GetBossIndex(client), this_plugin_name, "shulk_monadoart"))
        {
            EnableMonado[client]=true;
            ClientMonado[client]=0;
            MonadoOverloadTimer[client]=0.0;
            CreateTimer(0.2, MonadoTimer, client, TIMER_REPEAT, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
}

public Action MonadoTimer(Handle timer, int client)
{
    if(!EnableMonado[client] || !IsPlayerAlive(client))
    {
        EnableMonado[client]=false;
        ClientMonado[client]=0;
        MonadoOverloadTimer[client]=0.0;
        return Plugin_Stop;
    }

    Handle Hud=CreateHudSynchronizer();
    char message[120];
    char abilityString[40];
    int rgba[4];
    GetColorOfMonado(GetClientMonadoStat(client), rgba);
    GetAbilityStringOfMonado(GetClientMonadoStat(client), abilityString, sizeof(abilityString));
    SetHudTextParams(-1.0, 0.65, 0.35, rgba[0], rgba[1], rgba[2], rgba[3], 0, 0.35, 0.0, 0.2);

    ShowSyncHudText(client, Hud, message);

    CloseHandle(Hud);
    return Plugin_Continue;
}

public Action FF2_OnAbility2(int boss, const char[] plugin_name, const char[] ability_name, int status)
{

}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
    if(!EnableMonado[client] || !IsPlayerAlive(client)) return Plugin_Continue;

    
}

MonadoArt GetClientMonadoStat(int client)
{
    return view_as<MonadoArt>(ClientMonado[client]);
}

public void GetAbilityStringOfMonado(MonadoArt monado, char[] abilityString, int buffer)
{
    switch(monado)
    {
      case Monado_Overloaded:
      {
          Format(abilityString, buffer, "과부하");
      }
      case Monado_None:
      {
          Format(abilityString, buffer, "능력 없음");
      }
      case Monado_Jump:
      {
          Format(abilityString, buffer, "점프");
      }
      case Monado_Speed:
      {
          Format(abilityString, buffer, "스피드");
      }
      case Monado_Shield:
      {
          Format(abilityString, buffer, "쉴드");
      }
      case Monado_Buster:
      {
          Format(abilityString, buffer, "버스터");
      }
      case Monado_Smash:
      {
          Format(abilityString, buffer, "스매쉬");
      }
    }
}

public void GetColorOfMonado(MonadoArt monado, int rgba[4])
{
    switch(monado)
    {
      case Monado_Overloaded:
      {
          rgba[0]=140;
          rgba[1]=140;
          rgba[2]=140;
          rgba[3]=255;
      }
      case Monado_None:
      {
          rgba[0]=255;
          rgba[1]=255;
          rgba[2]=255;
          rgba[3]=255;
      }
      case Monado_Jump:
      {
          rgba[0]=171;
          rgba[1]=242;
          rgba[2]=0;
          rgba[3]=255;
      }
      case Monado_Speed:
      {
          rgba[0]=0;
          rgba[1]=216;
          rgba[2]=255;
          rgba[3]=255;
      }
      case Monado_Shield:
      {
          rgba[0]=255;
          rgba[1]=228;
          rgba[2]=0;
          rgba[3]=255;
      }
      case Monado_Buster:
      {
          rgba[0]=255;
          rgba[1]=0;
          rgba[2]=221;
          rgba[3]=255;
      }
      case Monado_Smash:
      {
          rgba[0]=255;
          rgba[1]=0;
          rgba[2]=0;
          rgba[3]=255;
      }
    }
}

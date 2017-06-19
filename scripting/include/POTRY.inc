enum GameMode
{
    Game_None = 0,
    Game_SuddenDeath,
    Game_LastManStanding,
    Game_SpecialLastManStanding,
    Game_AttackAndDefense,
    Game_ControlPoint,
    Game_ControlPointOverTime
};
///
enum VIPEffect
{
    VIPEffect_None = 0,
    VIPEffect_BossStandard,
    VIPEffect_FreeNametag
};

#define VIPEFFECT_MAX_COUNT 3
///
public bool IsServerPotry()
{
  return true;
}

// native bool FF2Boss_IsPlayerBlasterReady(int client);

native void FF2_EnablePlayerLastmanStanding(int client);

native GameMode FF2_GetGameState();

native void FF2_SetGameState(GameMode gamemode);
// native void FF2_SetGameState(GameMode gamemode, int needSetting);

native float FF2_GetTimeLeft();

native void FF2_SetTimeLeft(float time);

native bool FF2_IsLastMan(int client);

native void ROLLER_CreateRollerMine(int client, int count=1);

forward Action FF2_OnDeathMatchTimer(float &time);

native bool TIMESTOP_IsTimeStopping();

native bool POTRY_IsClientVIP(int client);

native bool POTRY_IsClientEnableVIPEffect(int client, VIPEffect effect); //EnableClientVIPEffect

native bool POTRY_EnableClientVIPEffect(int client, VIPEffect effect, bool setbool);

// 효과음은 알아서.
native void TIMESTOP_EnableTimeStop(int parent, float warntime=0.0, float stoptime);

native void TIMESTOP_DisableTimeStop();
/*
* 이 inc는 존재만 확인하는 용도임.
*/

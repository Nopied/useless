enum GameMode
{
    Game_None = 0,
    Game_SuddenDeath,
    Game_LastManStanding,
    Game_AttackAndDefense
};

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

/*
* 이 inc는 존재만 확인하는 용도임.
*/

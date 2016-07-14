/*
"laser_attack"
arg0은 무조건 0
arg1: 레이저 지속시간
arg2: 레이저에 불 효과?
arg4: 레이저의 공격력 (0.1초 간격)
arg5: 지진효과.
arg6: 사운드 경로
arg7: 사운드 볼륨 (0 - 120)

arg10:Red (레이저 색상)(0 - 255)
arg11:Green (레이저 색상)(0 - 255)
arg12:Blue (레이저 색상)(0 - 255)
arg13: 레이저 투명도
*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>
// 이유없이 선언한게 현재 있긴 하지만, 추후엔 분명히 쓰일 것임.

int BeamSprite, HaloSprite;

float clientRageBeamTime[MAXPLAYERS+1];
float clientRageBeamWarmTime[MAXPLAYERS+1];
Handle clientRageTimer[MAXPLAYERS+1]=INVALID_HANDLE;

public Plugin myinfo=
{
    name="Freak Fortress 2 : For touhou users.",
    author="Nopied",
    description="....",
    version="9.9",
};

public void OnPluginStart2()
{
  BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
  HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
}

public Action FF2_OnAbility2(int boss, const char[] pluginName, const char[] abilityName, int status)
{
  if(!strcmp(abilityName, "laser_attack"))
  {
    if(!BeamSprite || !HaloSprite){
      BeamSprite=PrecacheModel("materials/sprites/lgtning.vmt");
      HaloSprite=PrecacheModel("materials/sprites/halo01.vmt");
    }
    Rage_Beam(boss);
  }
}

Rage_Beam(int boss)
{
  int client=GetClientOfUserId(FF2_GetBossUserId(boss));
  char path[PLATFORM_MAX_PATH];
  FF2_GetAbilityArgumentString(boss, this_plugin_name, "laser_attack", 6, path, sizeof(path));
  EmitSoundToAll(path, _, _, _, _, FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 7, 120.0));

  clientRageBeamTime[client]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 1, 10.0);
  clientRageBeamWarmTime[client]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 2, 1.5);

  SetEntityMoveType(client, MOVETYPE_NONE);
  TF2_AddCondition(client, TFCond_Ubercharged, clientRageBeamTime[client]+clientRageBeamWarmTime[client]);

  if(clientRageTimer[client]==INVALID_HANDLE)
    clientRageTimer[client]=CreateTimer(0.1, OnBeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnBeam(Handle timer, int client)
{
  if(!IsClientInGame(client) || !IsPlayerAlive(client) || clientRageBeamTime[client]<=0.0)
  {
      char path[PLATFORM_MAX_PATH];
      FF2_GetAbilityArgumentString(boss, this_plugin_name, "laser_attack", 6, path, sizeof(path));
      for(int target=1; target<=MaxClients; target++)
      {
          if(IsClientInGame(target))
            StopSound(target, SNDCHAN_AUTO, path);
      }

      clientRageBeamTime[client]=0.0;
      clientRageBeamWarmTime[client]=0.0;
      SetEntityMoveType(client, MOVETYPE_WALK);
      clientRageTimer[client]=INVALID_HANDLE;
    return Plugin_Stop;
  }

  int boss=FF2_GetBossIndex(client);

  if(FF2_GetAbilityArgument(boss, this_plugin_name, "laser_attack", 5, 1))
    EarthQuakeEffect(client);

  if(clientRageBeamWarmTime[client]>0.0){
    clientRageBeamWarmTime[client]-=0.1;
    return Plugin_Continue;
  }
  else
    clientRageBeamTime[client]-=0.1;


  float clientPos[3];
  float end_pos[3];
  float damage=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 4, 12.0);
  int rgba[4];

  rgba[0]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 10, 0);
  rgba[1]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 11, 255);
  rgba[2]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 12, 0);
  rgba[3]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 13, 255);

  GetClientEyePosition(client, clientPos);
  GetEyeEndPos(client, 0.0, end_pos);

  clientPos[0]-=2.3;
  clientPos[2]-=5.0;

  TE_SetupBeamPoints(clientPos, end_pos, BeamSprite, HaloSprite, 0, 50, 0.1, 6.0, 25.0, 0, 64.0, rgba, 40);
  TE_SendToAll();
  //TODO: 빔 색 커스터마이즈

  for(int target=1; target<=MaxClients; target++)
  {
    if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != FF2_GetBossTeam())
    {
      float targetPos[3];
      float targetEndPos[3];

      GetClientEyePosition(target, targetPos);
      GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

      if(GetVectorDistance(targetPos, targetEndPos) <= 50.0 && !TF2_IsPlayerInCondition(target, TFCond_Ubercharged))
      {
        SDKHooks_TakeDamage(target, client, client, damage, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1, _, targetEndPos);

        if(FF2_GetAbilityArgument(boss, this_plugin_name, "laser_attack", 2, 1))
            TF2_IgnitePlayer(target, client);
      }
    }
  }
  return Plugin_Continue;
}

public void GetEyeEndPos(int client, float max_distance, float endPos[3])
{
	if(IsClientInGame(client))
	{
		if(max_distance<0.0)
			max_distance=0.0;
		float PlayerEyePos[3];
		float PlayerAimAngles[3];
		GetClientEyePosition(client,PlayerEyePos);
		GetClientEyeAngles(client,PlayerAimAngles);
		float PlayerAimVector[3];
		GetAngleVectors(PlayerAimAngles,PlayerAimVector,NULL_VECTOR,NULL_VECTOR);
		if(max_distance>0.0){
			ScaleVector(PlayerAimVector,max_distance);
		}
		else{
			ScaleVector(PlayerAimVector,3000.0);
		}
        AddVectors(PlayerEyePos,PlayerAimVector,endPos);
	}
}

void EarthQuakeEffect(int client)
{
    int flags = GetCommandFlags("shake") & (~FCVAR_CHEAT);
    SetCommandFlags("shake", flags);

    FakeClientCommand(client, "shake");

    flags = GetCommandFlags("shake") | (FCVAR_CHEAT);
    SetCommandFlags("shake", flags);
}

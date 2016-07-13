/*


*/
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>
// 이유없이 선언한게 현재 있긴 하지만, 추후엔 분명히 쓰일 것임.

// int clientRageBeam[MAXPLAYERS+1];
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

  clientRageBeamTime[client]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 1, 10.0);
  clientRageBeamWarmTime[client]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 2, 1.5);

  SetEntityMoveType(client, MOVETYPE_NONE);
  TF2_AddCondition(client, TFCond_Ubercharged, clientRageBeamTime[client]+clientRageBeamWarmTime[client]);

  clientRageTimer[client]=CreateTimer(0.1, OnBeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnBeam(Handle timer, int client)
{
  if(!IsClientInGame(client) || !IsPlayerAlive(client) || clientRageBeamTime[client]<=0.0)
  {
    clientRageBeamTime[client]=0.0;
    clientRageBeamWarmTime[client]=0.0;
    SetEntityMoveType(client, MOVETYPE_WALK);
    clientRageTimer[client]=INVALID_HANDLE;
    return Plugin_Stop;
  }

  if(clientRageBeamWarmTime[client]>0.0)
  {
    clientRageBeamWarmTime[client]-=0.1;
    return Plugin_Continue;
  }
  else
    clientRageBeamTime[client]-=0.1;

  float clientPos[3];
  float end_pos[3];

  GetClientEyePosition(client, clientPos);
  GetEyeEndPos(client, 0.0, end_pos);

  clientPos[0]-=2.3;
  clientPos[2]-=5.0;

  TE_SetupBeamPoints(clientPos, end_pos, BeamSprite, HaloSprite, 0, 50, 0.1, 6.0, 25.0, 0, 64.0, {255, 0, 0, 255}, 40);
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

      if(GetVectorDistance(targetPos, targetEndPos) <= 40.0 && !TF2_IsPlayerInCondition(target, TFCond_Ubercharged))
      {
        SDKHooks_TakeDamage(target, client, client, 12.0, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1, _, targetEndPos);
        //TODO: 불 설정 커스터마이즈
      }
    }
  }
  return Plugin_Continue;
}

/*
public bool TraceWallsOnly(entity, contentsMask)
{
	return false;
}
*/


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


// stock int CreateBeam(int client, )

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
Handle clientRageTimer[MAXPLAYERS+1];

float endPos[3];

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
    Rage_Beam(boss);
  }
}

Rage_Beam(int boss)
{
  int client=GetClientOfUserId(FF2_GetBossUserId(boss));

  clientRageBeamTime[client]=FF2_GetAbilityArgumentFloat(boss, this_plugin_name, "laser_attack", 1, 10.0);
  Debug("분노 사용함. laser_attack");

  clientRageTimer[client]=CreateTimer(0.1, OnBeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnBeam(Handle timer, int client)
{
  if(!IsClientInGame(client) || !IsPlayerAlive(client) || clientRageBeamTime[client]<=0.0)
  {
    clientRageBeamTime[client]=0.0;
    clientRageTimer[client]=INVALID_HANDLE;
    return Plugin_Stop;
  }

  // CreateBeam(client);

  clientRageBeamTime[client]-=0.1;
  float clientPos[3];
  float clientEyeAngles[3];
  float spawnPoint[3];

  GetClientEyePosition(client, clientPos);
  GetClientEyeAngles(client, clientEyeAngles);
  // Debug("남은 시간: %.1f", clientRageBeamTime[client]);

  Handle trace;
  trace = TR_TraceRayFilterEx(clientPos, clientEyeAngles, _, RayType_Infinite, TraceWallsOnly);
  // trace = TR_TraceRayFilterEx(eyePosition, eyeAngles, MASK_ALL, RayType_Infinite, TraceWallsOnly);
  // bool playerHit = TR_GetHitGroup(trace) > 0; // group 0 is "generic" which I hope includes nothing. 1=head 2=chest 3=stomach 4=leftarm 5=rightarm 6=leftleg 7=rightleg (shareddefs.h)
  TR_GetEndPosition(spawnPoint, trace);
  CloseHandle(trace);
  clientPos[0]-=2.3;
  clientPos[2]-=5.0;
  // Debug("pos[1]: %.1f, pos[2]: %.1f, pos[3]: %.1f", spawnPoint[0], spawnPoint[1], spawnPoint[2]);

  TE_SetupBeamPoints(clientPos, spawnPoint, BeamSprite, HaloSprite, 0, 50, 0.1, 6.0, 25.0, 0, 64.0, {255, 0, 0, 255}, 40);
  TE_SendToAll();

  for(int target=1; target<=MaxClients; target++)
  {
    if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != FF2_GetBossTeam())
    {
      continue;
    }
  }
  return Plugin_Continue;
}

public bool TraceWallsOnly(entity, contentsMask)
{
	return false;
}

/*
public void GetEyeEndPos(int client, float max_distance)
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
			ScaleVector(PlayerAimVector,56756.0);
			AddVectors(PlayerEyePos,PlayerAimVector,endPos);
		}
	}
}
*/

// stock int CreateBeam(int client, )

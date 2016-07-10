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
  BeamSprite=PrecacheModel("materials/sprites/glowenergy.vmt");
	HaloSprite=PrecacheModel("materials/sprites/pulsered.vmt");
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

  if(!clientRageTimer)
    clientRageTimer[client]=CreateTimer(0.1, OnBeam, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action OnBeam(Handle timer, int client)
{
  if(!IsClientInGame(client) || IsPlayerAlive(client) || !clientRageBeamTime[client])
  {
    clientRageBeamTime[client]=0.0;
    clientRageTimer[client]=INVALID_HANDLE;
    return Plugin_Stop;
  }

  // CreateBeam(client);

  clientRageBeamTime[client]-=0.1;
  float clientPos[3];
  float end_pos[3];
  GetClientEyePosition(client, clientPos);
  GetEyeEndPos(client, 0.0);

  TE_SetupBeamPoints(clientPos, end_pos, BeamSprite, HaloSprite, 0, 50, 0.1, 6.0, 25.0, 0, 120.0, {255, 0, 0, 255}, 40);
  return Plugin_Continue;
}

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

// stock int CreateBeam(int client, )

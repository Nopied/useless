#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

public Plugin myinfo=
{
	name="DROP THE PROP!!",
	author="Nopied",
	description="",
	version="1.0",
};

//

bool enabled = false;
TFTeam PropForTeam;

Handle cvarPropCount;
Handle cvarPropVelocity;
Handle cvarPropForNoBossTeam;
Handle cvarModelPath;
Handle cvarPropGainMaxHp;
Handle cvarPropBuffCount;
Handle cvarPropBuffTime;

char g_strModelPath[PLATFORM_MAX_PATH];

int g_iEatCount[MAXPLAYERS+1];


//

public void OnPluginStart()
{
  // TODO: NEED CVAR!
  cvarPropCount = CreateConVar("dp_prop_count", "1", "생성되는 프롭 갯수, 0은 생성을 안함", _, true, 0.0);
  cvarPropVelocity = CreateConVar("dp_prop_velocity", "250.0", "프롭 생성시 흩어지는 최대 속도, 설정한 범위 내로 랜덤으로 속도가 정해집니다.", _, true, 0.0);
  cvarPropGainMaxHp = CreateConVar("dp_heal_hp", "60", "프롭을 얻을 시, 얼마나 HP를 회복시킬 것 인가?", _, true, 0.0);
  cvarPropBuffCount = CreateConVar("dp_gain_buff_count", "5", "스피드 버프(징계조치 효과)를 얻기 위한 얻어야 될 프롭 갯수", _, true, 0.0);
  cvarPropBuffTime =  CreateConVar("dp_gain_buff_time", "6.0", "스피드 버프(징계조치 효과)의 지속 시간", _, true, 0.1);
  cvarPropForNoBossTeam = CreateConVar("dp_prop_for_team", "0", "0 혹은 1은 제한 없음, 2는 레드팀에게만, 3은 블루팀에게만. (생성도 포함됨.)", _, true, 0.0, true, 2.0);
  cvarModelPath = CreateConVar("dp_prop_model_path", "", "이걸 꼭 기재하셔야 프롭을 소환할 수 있습니다.");

  HookEvent("player_spawn", OnPlayerSpawn);
  HookEvent("player_death", OnPlayerDeath);

	PrecacheThings();
}

public void OnMapStart()
{
  PrecacheThings();
}

void PrecacheThings()
{
	PropForTeam = view_as<TFTeam>(GetConVarInt(cvarPropForNoBossTeam));
  GetConVarString(cvarModelPath, g_strModelPath, sizeof(g_strModelPath));

  if(g_strModelPath[0] != '\0')
  {
    if(FileExists(g_strModelPath, true))
    {
      PrecacheModel(g_strModelPath);
      enabled = true;
    }
    else
    {
      enabled = false;
      LogError("모델 파일이 존재하지 않습니다!");
    }
  }
  else
  {
    LogError("모델 경로를 기입하여 주시길 바랍니다!");
    enabled = false;
  }
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
  if(!enabled)
  {
    return Plugin_Continue;
  }

	int client = GetClientOfUserId(GetEventInt(event, "userid"));

  g_iEatCount[client] = 0;
  return Plugin_Continue;
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

  if(!enabled || GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER || !IsCorrectTeam(client))
  {
    return Plugin_Continue;
  }

  for(int count = 0; count < GetConVarInt(cvarPropCount); count++)
  {
    int prop = CreateEntityByName("prop_physics_override");
    if(IsValidEntity(prop))
    {
      SetEntityModel(prop, g_strModelPath);
      SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
      SetEntProp(prop, Prop_Send, "m_CollisionGroup", 5);
      // SetEntProp(prop, Prop_Send, "m_usSolidFlags", 16); // 0x0004
			SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);
      DispatchSpawn(prop);

      float position[3];
    	GetEntPropVector(client, Prop_Send, "m_vecOrigin", position);

      float velocity[3];
      velocity[0] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      velocity[1] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      velocity[2] = GetRandomFloat(GetConVarFloat(cvarPropVelocity)*-0.5, GetConVarFloat(cvarPropVelocity)*0.5);
      NormalizeVector(velocity, velocity);


      TeleportEntity(prop, position, NULL_VECTOR, velocity);
			// TeleportEntity(prop, position, NULL_VECTOR, NULL_VECTOR);

      SDKHook(prop, SDKHook_StartTouch, OnPickup);
    	SDKHook(prop, SDKHook_Touch, OnPickup);
    }
  }

	g_iEatCount[client] = 0;
  return Plugin_Continue;
}

public Action OnPickup(int entity, int client) // Copied from FF2
{
	if(client <= 0 || client > MaxClients)
		return Plugin_Handled;

  if(!IsCorrectTeam(client))
  {
    return Plugin_Handled;
  }
	char centerMessage[100];

  g_iEatCount[client]++;

  SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + GetConVarInt(cvarPropGainMaxHp));

	Format(centerMessage, sizeof(centerMessage), "%i개를 얻었습니다!", g_iEatCount[client]);
    //   PrintCenterText(client, "%i개 주웠습니다!");
	int remaining=0;

  for(int count = 1; remaining < g_iEatCount[client]; count++)
  {
    remaining = GetConVarInt(cvarPropBuffCount) * count;
  }

  if(remaining - g_iEatCount[client] == 0) // 일정 갯수를 얻었을 경우
  {
    Format(centerMessage, sizeof(centerMessage), "%s\n잠시동안 스피드 버프를 받게됩니다!", centerMessage);
    TF2_AddCondition(client, TFCond_SpeedBuffAlly, GetConVarFloat(cvarPropBuffTime));
  }
  else
  {
    Format(centerMessage, sizeof(centerMessage), "%s [ 버프까지 남은 갯수: %i / %i ]", centerMessage, remaining - g_iEatCount[client], GetConVarInt(cvarPropBuffCount));
  }

	PrintCenterText(client, centerMessage);

	AcceptEntityInput(entity, "kill");

  return Plugin_Continue;
}

stock bool IsCorrectTeam(int client)
{
	if(PropForTeam != TFTeam_Red && PropForTeam != TFTeam_Blue)
		return true;

  return PropForTeam == TF2_GetClientTeam(client);
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <entity>

public Plugin:myinfo=
{
    name="Change Health/Ammo Packs!",
    author="Nopied",
    description="....",
    version="wat",
};

public void OnEntityCreated(entity, const String:classname[])
{
  if (StrEqual(classname, "item_ammopack_full", true) ||
  StrEqual(classname, "item_ammopack_small", true)
  )
  {
	   SDKHook(entity, SDKHook_SpawnPost, OnAmmoSpawn);
  }

  if(StrEqual(classname, "item_healthkit_full", true) ||
    StrEqual(classname, "item_healthkit_small", true)
    )
    {
      SDKHook(entity, SDKHook_SpawnPost, OnHealthkitSpawn);
    }
}

public void OnAmmoSpawn(int entity)
{
  float pos[3];
  GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
  AcceptEntityInput(entity, "Disable");


  int anotherEnt=CreateEntityByName("item_ammopack_medium");
  if(IsValidEntity(anotherEnt))
  {
    // DispatchKeyValue(anotherEnt, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(anotherEnt);
		SetEntProp(anotherEnt, Prop_Send, "m_iTeamNum", 0, 4);
    TeleportEntity(anotherEnt, pos, NULL_VECTOR, NULL_VECTOR);

    PrintToChatAll("entity: %d, anotherEnt: %d", entity, anotherEnt);
  }
}

public void OnHealthkitSpawn(int entity)
{
  float pos[3];
  GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
  AcceptEntityInput(entity, "Disable");

  int anotherEnt=CreateEntityByName("item_healthkit_medium");
  if(IsValidEntity(anotherEnt))
  {
    DispatchKeyValue(anotherEnt, "OnPlayerTouch", "!self,Kill,,0,-1");
		DispatchSpawn(anotherEnt);
		SetEntProp(anotherEnt, Prop_Send, "m_iTeamNum", 0, 4);
    TeleportEntity(anotherEnt, pos, NULL_VECTOR, NULL_VECTOR);

    PrintToChatAll("entity: %d, anotherEnt: %d", entity, anotherEnt);
  }
}

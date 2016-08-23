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

int g_iPackCount;

public void OnMapStart()
{
    g_iPackCount=0;
    int ent=-1;

    while((ent = FindEntityByClassname(ent, "item_ammopack_full")) != -1)  // FIXME: 컴파일러님..?
    {
      g_iPackCount++;
    }

    while((ent = FindEntityByClassname(ent, "item_ammopack_small")) != -1) // FIXME: 컴파일러님..?
    {
      g_iPackCount++;
    }

    while((ent = FindEntityByClassname(ent, "item_healthkit_full")) != -1) // FIXME: 컴파일러님..?
    {
      g_iPackCount++;
    }

    while((ent = FindEntityByClassname(ent, "item_healthkit_small")) != -1) // FIXME: 컴파일러님..?
    {
      g_iPackCount++;
    }
}

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
      DispatchKeyValue(anotherEnt, "OnPlayerTouch", "!self,Kill,,0,-1");
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

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

bool IsMapRunning = false;

public void OnMapStart()
{
    IsMapRunning = true;
}

public void OnMapEnd()
{
    IsMapRunning = false;
}

public void OnPluginStart()
{
    HookEvent("teamplay_round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    if(!IsMapRunning)   return;
    
    int ent = -1;

    while((ent = FindEntityByClassname(ent, "item_healthkit_*")) != -1)
    {
        OnHealthkitSpawn(ent);
    }

    while((ent = FindEntityByClassname(ent, "item_ammopack_*")) != -1)
    {
        OnAmmoSpawn(ent);
    }
}
/*
public void OnEntityCreated(entity, const String:classname[])
{
    if(!IsMapRunning)   return;

//  if (StrEqual(classname, "item_ammopack_full", true) ||
//  StrEqual(classname, "item_ammopack_small", true)
//  )

  if(!StrContains(classname, "item_ammopack_"))
  {
	   SDKHook(entity, SDKHook_SpawnPost, OnAmmoSpawn);
  }

//  if(StrEqual(classname, "item_healthkit_full", true) ||
//    StrEqual(classname, "item_healthkit_small", true)
//    )

    if(!StrContains(classname, "item_healthkit_"))
    {
      SDKHook(entity, SDKHook_SpawnPost, OnHealthkitSpawn);
    }
}
*/
public void OnAmmoSpawn(int entity)
{
      float pos[3];
      GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

      char classname[60];
      char sizeString[15];
      GetEntityClassname(entity, classname, sizeof(classname));
      int size = GetKitSize(classname);
      switch(size)
      {
        case 0:
        {
            Format(sizeString, sizeof(sizeString), "small");
        }
        case 1:
        {
            Format(sizeString, sizeof(sizeString), "medium");
        }
        case 2:
        {
            Format(sizeString, sizeof(sizeString), "full");
        }
      }
      Format(classname, sizeof(classname), "item_healthkit_%s", sizeString);


      int anotherEnt = CreateEntityByName(classname);
      if(IsValidEntity(anotherEnt))
      {
        // DispatchKeyValue(anotherEnt, "OnPlayerTouch", "!self,Kill,,0,-1");
    		DispatchSpawn(anotherEnt);
    		SetEntProp(anotherEnt, Prop_Send, "m_iTeamNum", 0, 4);
            TeleportEntity(anotherEnt, pos, NULL_VECTOR, NULL_VECTOR);
            AcceptEntityInput(anotherEnt, "Enable");

            // PrintToChatAll("entity: %d, anotherEnt: %d", entity, anotherEnt);
      }
}

public void OnHealthkitSpawn(int entity)
{
      float pos[3];
      GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);

      char classname[60];
      char sizeString[15];
      GetEntityClassname(entity, classname, sizeof(classname));
      int size = GetKitSize(classname);
      switch(size)
      {
        case 0:
        {
            Format(sizeString, sizeof(sizeString), "small");
        }
        case 1:
        {
            Format(sizeString, sizeof(sizeString), "medium");
        }
        case 2:
        {
            Format(sizeString, sizeof(sizeString), "full");
        }
      }
      Format(classname, sizeof(classname), "item_ammopack_%s", sizeString);

      int anotherEnt = CreateEntityByName(classname);
      if(IsValidEntity(anotherEnt))
      {
        // DispatchKeyValue(anotherEnt, "OnPlayerTouch", "!self,Kill,,0,-1");
    		DispatchSpawn(anotherEnt);
    		SetEntProp(anotherEnt, Prop_Send, "m_iTeamNum", 0, 4);
            TeleportEntity(anotherEnt, pos, NULL_VECTOR, NULL_VECTOR);
            AcceptEntityInput(anotherEnt, "Enable");

            // PrintToChatAll("entity: %d, anotherEnt: %d", entity, anotherEnt);
      }
}

int GetKitSize(char[] classname)
{
    int size = 0;

    if(!StrContains(classname, "full"))
    {
        size = 2;
    }
    else if(!StrContains(classname, "medium"))
    {
        size = 1;
    }

    return size;
}

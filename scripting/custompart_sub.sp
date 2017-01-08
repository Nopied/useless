#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <tf2items>
#include <freak_fortress_2>
#include <custompart>
#include <POTRY>

#define PLUGIN_NAME "CustomPart Subplugin"
#define PLUGIN_AUTHOR "Nopied◎"
#define PLUGIN_DESCRIPTION "Yup. Yup."
#define PLUGIN_VERSION "Dev"

public Plugin myinfo = {
  name=PLUGIN_NAME,
  author=PLUGIN_AUTHOR,
  description=PLUGIN_DESCRIPTION,
  version=PLUGIN_VERSION,
};

Handle CustomPartSubKv;

int slotWeaponEntityRef[MAXPLAYERS+1][5];
bool slotWeaponEntityRefChanged[MAXPLAYERS+1][5];

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath);
    // HookEvent("teamplay_round_start", OnRoundStart);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
}

public void OnMapStart()
{
    CheckPartConfigFile();
}

public int TF2Items_OnGiveNamedItem_Post(int client, char[] classname, int itemDefinitionIndex, int itemLevel, int itemQuality, int entityIndex)
{
    int slot = GetWeaponSlot(client, entityIndex);

    if(slot != -1)
    {
        slotWeaponEntityRef[client][slot] = EntIndexToEntRef(entityIndex);
    }
}

public Action OnPlayerSpawn(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));

    if(!IsValidClient(client) || IsFakeClient(client)) return Plugin_Continue;

    int weapon;

    for(int slot=0; slot<5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
        {
            slotWeaponEntityRef[client][slot] = EntIndexToEntRef(weapon);
        }
    }


    return Plugin_Continue;

}

public void OnClientPostAdminCheck(int client)
{
    if(CP_IsEnabled())
    {
        SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
        SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
        SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
        SDKHook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
    }
}

public void OnClientDisconnect(int client)
{
    SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    SDKUnhook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
    SDKUnhook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
    SDKUnhook(client, SDKHook_OnTakeDamageAlivePost, OnTakeDamageAlivePost);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{

}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{

}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{

}

public void OnTakeDamageAlivePost(int victim, int attacker, int inflictor, float damage, int damagetype)
{
    if(IsValidClient(victim))
    {
        if(CP_ReplacePartSlot(victim, 18, 1))
        {
            CP_NoticePart(victim, 18);

            int target = FindAnotherPerson(victim, true);
            if(IsValidClient(target))
            {
                float targetPos[3];
                GetClientEyePosition(target, targetPos);

                TeleportEntity(victim, targetPos, NULL_VECTOR, NULL_VECTOR);
            }
            else
            {
                CPrintToChatAll("{yellow}[CP]{default} 그런데 효과를 발동할 아군이 없어요!");
            }
        }
    }
    if(IsValidClient(attacker))
    {
        return; // What?
    }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    bool IsFake;
    if(GetEventInt(event, "death_flags") & TF_DEATHFLAG_DEADRINGER)
        IsFake = true;

    if(!IsClientInGame(client)) return Plugin_Continue;

    if(!IsFake && CP_IsPartActived(client, 15))
    {
        CP_NoticePart(client, 15);

        int target = FindAnotherPerson(client);
        if(IsValidClient(target))
        {
            TF2_RespawnPlayer(target);
        }
        else
        {
            CPrintToChatAll("{yellow}[CP]{default} 그런데 부활시킬 아군이 없어요!");
        }
    }

    return Plugin_Continue;
}

public void OnEntityCreated(int entity)
{
    SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(int entity)
{
    int owner;
    if(HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
        owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");

    if(!IsValidClient(owner)) return;

    char classname[60];
    GetEntityClassname(entity, classname, sizeof(classname));

    if(!StrContains(classname, "tf_projectile_", false))
    {
        if(CP_IsPartActived(owner, 19))
        {
            float pos[3];
            float ang[3];
            float velocity[3];

            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
            GetEntPropVector(entity, Prop_Send, "m_angRotation", ang);

            velocity[0]=ang[0]*800.0;
            velocity[1]=ang[1]*800.0;
            velocity[2]=ang[2]*800.0;
            NormalizeVector(velocity, velocity);

            AcceptEntityInput(entity, "kill");

            int prop = CreateEntityByName("prop_physics_override");

            if(IsValidEntity(prop))
            {
                SetEntityMoveType(prop, MOVETYPE_VPHYSICS);
                SetEntProp(prop, Prop_Send, "m_CollisionGroup", 2);

                SetEntProp(prop, Prop_Send, "m_usSolidFlags", 0x0004);

                CP_PropToPartProp(prop, 0, CP_RandomPartRank(true), true, true, false);

                FF2_SetClientDamage(owner, FF2_GetClientDamage(owner) + 20);
                TeleportEntity(prop, pos, ang, velocity);
            }
        }
    }
}

public void CP_OnActivedPartEnd(int client, int partIndex)
{
    if(IsPlayerAlive(client))
    {
        if(partIndex == 12)
        {
            RemoveToAllWeapon(client, 2, -0.3);
            RemoveToSomeWeapon(client, 412, 0.5);

            TF2_StunPlayer(client, 6.0, 0.5, TF_STUNFLAGS_SMALLBONK);
        }
    }
}

public Action CP_OnTouchedPartProp(int client, int prop)
{
    if(CP_IsPartActived(client, 11))
        return Plugin_Handled;

    return Plugin_Continue;
}

public void CP_OnGetPart_Post(int client, int partIndex)
{
    float clientPos[3];
    GetClientEyePosition(client, clientPos);

    if(partIndex == 10) // "파츠 멀티 슬릇"
    {
        CP_SetClientMaxSlot(client, CP_GetClientMaxSlot(client) + 2);
    }

    else if(partIndex == 2) // "체력 강화제"
    {
        AddToSomeWeapon(client, 26, 50.0);
        AddToSomeWeapon(client, 109, -0.1);
    }

    else if(partIndex == 3) // "근육 강화제"
    {
        AddToAllWeapon(client, 6, -0.2);
        AddToAllWeapon(client, 97, -0.2);
        AddToSomeWeapon(client, 69, -0.5);
    }

    else if(partIndex == 4) // "나노 제트팩"
    {
        AddToSomeWeapon(client, 610, 0.5);
        AddToSomeWeapon(client, 207, 1.2);
    }

    else if(partIndex == 6) // "무쇠 탄환"
    {
        AddToAllWeapon(client, 389, 50.0); // 무기?
        AddToAllWeapon(client, 397, 5.0);
        AddToAllWeapon(client, 266, 1.0);

        AddToAllWeapon(client, 2, 0.3);
        AddToSomeWeapon(client, 54, -0.15);
    }

    else if(partIndex == 7) // "롤러마인"
    {
        ROLLER_CreateRollerMine(client, 8);
    }

    else if(partIndex == 13)
    {
        SetEntProp(client, Prop_Send, "m_iHealth", GetEntProp(client, Prop_Send, "m_iHealth") + 300);
        TF2_StunPlayer(client, 1.5, 0.5, TF_STUNFLAGS_SMALLBONK);

        char path[PLATFORM_MAX_PATH];
        RandomSound("Hal_ly", path, sizeof(path));

        // EmitSoundToAll(path, client, _, _, _, _, _, client, clientPos);
        // EmitSoundToAll(path, client, _, _, _, _, _, client, clientPos);
        EmitSoundToAll(path);
        EmitSoundToAll(path);

        CP_NoticePart(client, partIndex);
    }

    else if(partIndex == 14)
    {
        TF2_AddCondition(client, TFCond_Stealthed, 20.0); //TFCond_Stealthed
        CP_NoticePart(client, partIndex);
    }

    else if(partIndex == 16)
    {
        AddToSomeWeapon(client, 80, 1.0);
        AddToSomeWeapon(client, 54, -0.1);
    }

    else if(partIndex == 17)
    {
        AddToSlotWeapon(client, 0, 32, 1.0);
        AddToSlotWeapon(client, 0, 356, 1.0);

        AddToSomeWeapon(client, 54, -0.3);
    }
    else if(partIndex == 21)
    {
        TF2_AddCondition(client, TFCond_MarkedForDeath, TFCondDuration_Infinite);
    }
    else if(partIndex == 22)
    {
        int boss = FF2_GetBossIndex(client);
        if(boss != -1)
        {
            FF2_SetBossCharge(boss, 0, 100.0);
        }
        else
        {
            Debug("보스가 아닌데 이 파츠를 흭득함.");
        }
    }
}

public void CP_OnActivedPart(int client, int partIndex)
{
    if(partIndex == 12)
    {
        AddToAllWeapon(client, 2, 0.3);
        AddToSomeWeapon(client, 412, -0.5);
        CP_NoticePart(client, partIndex);
    }
}

public Action CP_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    int weapon;

    if(IsClientInGame(client))
    {
        Debug("CP_OnSlotClear: client = %i, partIndex = %i", client, partIndex);

        for(int slot=0; slot<5; slot++)
        {
            weapon = GetPlayerWeaponSlot(client, slot);
            if(IsValidEntity(weapon))
            {
                if(slotWeaponEntityRef[client][slot] != EntIndexToEntRef(weapon))
                {
                    slotWeaponEntityRefChanged[client][slot] = true;
                    slotWeaponEntityRef[client][slot] = EntIndexToEntRef(weapon);
                }
                else
                {
                    slotWeaponEntityRefChanged[client][slot] = false;
                }
            }
            else
            {
                slotWeaponEntityRefChanged[client][slot] = false;
                slotWeaponEntityRef[client][slot] = -1;
            }
        }

        if(partIndex == 10)
        {
            CP_SetClientMaxSlot(client, CP_GetClientMaxSlot(client) - 2);
        }

        else if(partIndex == 2) // "체력 강화제"
        {
/////////////////////////////////// 복사 북여넣기 하기 좋은거!!
            RemoveToSomeWeapon(client, 26, -50.0);
//////////////////////////////////
            RemoveToSomeWeapon(client, 109, 0.1);
        }

        else if(partIndex == 3) // "근육 강화제"
        {
            RemoveToAllWeapon(client, 6, 0.2);
            RemoveToAllWeapon(client, 97, 0.2);
            RemoveToSomeWeapon(client, 69, 0.5);
        }

        else if(partIndex == 4) // "나노 제트팩"
        {
            RemoveToSomeWeapon(client, 610, -0.5);
            RemoveToSomeWeapon(client, 207, -1.2);
        }

        else if(partIndex == 6) // "무쇠 탄환"
        {
            RemoveToAllWeapon(client, 389, -1.0);
            RemoveToAllWeapon(client, 397, -5.0);
            RemoveToAllWeapon(client, 266, -1.0);

            RemoveToAllWeapon(client, 2, -0.3);
            RemoveToSomeWeapon(client, 54, 0.15);
        }

        else if(partIndex == 16)
        {
            RemoveToSomeWeapon(client, 80, -1.0);
            RemoveToSomeWeapon(client, 54, 0.1);
        }

        else if(partIndex == 17)
        {
            RemoveToSlotWeapon(client, 0, 32, -1.0);
            RemoveToSlotWeapon(client, 0, 356, -1.0);

            RemoveToSomeWeapon(client, 54, 0.3);
        }
    }
    else
    {
        // 클라이언트가 접속이 안되어있을 경우, 아이템 값을 설정하진 않아도 됨.
    }
    return Plugin_Continue;
}

public Action FF2_OnTakePercentDamage(int victim, int &attacker, PercentDamageType damageType, float &damage)
{
    bool changed;
    bool blocked;

    if((damageType == Percent_Marketed || damageType == Percent_GroundMarketed))
    {
        if(CP_IsPartActived(attacker, 9))
        {
            changed = true;
            damage *= 1.5;
        }
    }

    if(damageType == Percent_Backstab)
    {
        if(CP_IsPartActived(attacker, 20))
        {
            blocked = true;
            TF2_StunPlayer(victim, 3.5, 0.5, TF_STUNFLAGS_SMALLBONK, attacker);
            CP_NoticePart(attacker, 20);
        }
    }

    // Debug("FF2_OnTakePercentDamage: attacker = %i, damageType = %i", attacker, damageType);

    if(blocked)         return Plugin_Handled;
    else if(changed)    return Plugin_Changed;

    return Plugin_Continue;
}

public void FF2_OnTakePercentDamage_Post(int victim, int attacker, PercentDamageType damageType, float damage)
{
    if(damageType == Percent_Goomba && CP_IsPartActived(attacker, 8))
    {
        float distance = 600.0; // TODO: 메인 플러그인 상의 거리 설정 (파츠 컨픽에서 설정 가능하게.)
        float clientPos[3];
        float targetPos[3];

        GetClientEyePosition(attacker, clientPos);
        for(int client=1; client<=MaxClients; client++)
        {
            if(IsClientInGame(client) && GetClientTeam(attacker) != GetClientTeam(client))
            {
                GetClientEyePosition(client, targetPos);

                if(GetVectorDistance(clientPos, targetPos) <= distance)
                {
                    TF2_StunPlayer(client, 5.0, 0.5, TF_STUNFLAGS_SMALLBONK, attacker); // TODO: 메인 플러그인 상의 시간 설정 (파츠 컨픽에서 설정 가능하게.)
                }
            }
        }
        CP_NoticePart(attacker, 8);
    }

    if((damageType == Percent_Marketed || damageType == Percent_GroundMarketed) && CP_IsPartActived(attacker, 9))
    {
        TF2_StunPlayer(victim, 5.0, 0.5, TF_STUNFLAGS_SMALLBONK, attacker);
        CP_NoticePart(attacker, 9);
    }
}

public void TF2_OnConditionAdded(int client, TFCond condition)
{

}

public void TF2_OnConditionRemoved(int client, TFCond condition)
{
    if(condition == TFCond_MarkedForDeath)
    {
        if(CP_IsPartActived(client, 21))
        {
            TF2_AddCondition(client, TFCond_MarkedForDeath, TFCondDuration_Infinite);
        }
    }
}

int CreateDispenserTrigger(int client)
{
    int trigger = CreateEntityByName("dispenser_touch_trigger");
    if(IsValidEntity(trigger))
    {
        float pos[3];
        GetClientEyePosition(client, pos);

        DispatchSpawn(trigger);
        SetEntPropEnt(trigger, Prop_Send, "m_hOwnerEntity", client);

        SetVariantString("!activator");
        AcceptEntityInput(trigger, "SetParent", client);

        AcceptEntityInput(trigger, "Enable");

        TeleportEntity(trigger, pos, NULL_VECTOR, NULL_VECTOR);

        return EntIndexToEntRef(trigger);

    }
    return -1;
}

void RemoveToSlotWeapon(int client, int slot, int defIndex, float value)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    if(IsValidEntity(weapon) && !slotWeaponEntityRefChanged[client][slot])
    {
        AddAttributeDefIndex(weapon, defIndex, value);
    }
}

void RemoveToAllWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot < 5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon) && !slotWeaponEntityRefChanged[client][slot])
            AddAttributeDefIndex(weapon, defIndex, value);
    }
}

void RemoveToSomeWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot < 5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
        {
            if(!slotWeaponEntityRefChanged[client][slot] || slotWeaponEntityRef[client][slot] != -1)
            {
                AddAttributeDefIndex(weapon, defIndex, value);
                return;
            }
        }
        else
        {
            if(slotWeaponEntityRefChanged[client][slot] || slotWeaponEntityRef[client][slot] == -1)
                continue;
        }

        return;
    }
}


void AddToSlotWeapon(int client, int slot, int defIndex, float value)
{
    int weapon = GetPlayerWeaponSlot(client, slot);
    if(IsValidEntity(weapon))
    {
        AddAttributeDefIndex(weapon, defIndex, value);
    }
}

void AddToAllWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot < 5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
            AddAttributeDefIndex(weapon, defIndex, value);
    }
}

void AddToSomeWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot < 5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
        {
            AddAttributeDefIndex(weapon, defIndex, value);
            return;
        }
    }
}

void AddAttributeDefIndex(int entity, int defIndex, float value)
{
    Address itemAddress;
    float beforeValue;

    itemAddress = TF2Attrib_GetByDefIndex(entity, defIndex);
    if(itemAddress != Address_Null)
    {
        beforeValue = TF2Attrib_GetValue(itemAddress) + value;
        TF2Attrib_SetValue(itemAddress, beforeValue);
    }
    else
    {
        if(TF2Attrib_IsIntegerValue(defIndex))
            TF2Attrib_SetByDefIndex(entity, defIndex, value);
        else
            TF2Attrib_SetByDefIndex(entity, defIndex, value + 1.0);
    }
}

void CheckPartConfigFile()
{
  if(CustomPartSubKv != INVALID_HANDLE)
  {
    CloseHandle(CustomPartSubKv);
    CustomPartSubKv = INVALID_HANDLE;
  }

  char config[PLATFORM_MAX_PATH];
  char temp[PLATFORM_MAX_PATH];
  char item[20];
  int count;
  BuildPath(Path_SM, config, sizeof(config), "configs/custompart_sub.cfg");

  if(!FileExists(config))
  {
      SetFailState("[CP] NO CFG FILE! (configs/custompart_sub.cfg)");
      return;
  }

  CustomPartSubKv = CreateKeyValues("custompart_sub");

  if(!FileToKeyValues(CustomPartSubKv, config))
  {
    SetFailState("[CP] configs/custompart_sub.cfg is broken?!");
  }

  KvRewind(CustomPartSubKv);
  if(KvGotoFirstSubKey(CustomPartSubKv))
  {
      do
      {
          count = 0;
          for( ; ; )
          {
            Format(item, sizeof(item), "%i", ++count);
            KvGetString(CustomPartSubKv, item, config, sizeof(config), "");

            if(config[0] == '\0') break;

            Format(temp, sizeof(temp), "sound/%s", config);
            if(FileExists(temp, true))
            {
                PrecacheSound(config);
                AddFileToDownloadsTable(temp);
            }
          }
      }
      while(KvGotoNextKey(CustomPartSubKv));
  }
}

public void RandomSound(const char[] key, char[] path, int buffer)
{
    if(CustomPartSubKv == INVALID_HANDLE)   return;

    char config[PLATFORM_MAX_PATH];
    char item[20];
    int count;

    KvRewind(CustomPartSubKv);
    if(KvJumpToKey(CustomPartSubKv, key))
    {
        count = 0;
        for( ; ; )
        {
          Format(item, sizeof(item), "%i", ++count);
          KvGetString(CustomPartSubKv, item, config, sizeof(config), "");

          if(config[0] == '\0') break;
        }
    }

    Format(item, sizeof(item), "%i", GetRandomInt(1, count-1));
    KvGetString(CustomPartSubKv, item, path, buffer, "");
}

stock int FindAnotherPerson(int Gclient, bool checkAlive=false)
{
    int count;
    int validTarget[MAXPLAYERS+1];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client)
        && client != Gclient
        && GetClientTeam(client) == GetClientTeam(Gclient)
        && ((checkAlive && IsPlayerAlive(client))
        || (!checkAlive && !IsPlayerAlive(client))))
        {
            validTarget[count++]=client;
        }
    }

    if(!count)
    {
        // return CreateFakeClient("No Target.");
        return 0;
    }
    return validTarget[GetRandomInt(0, count-1)];
}

stock int GetWeaponSlot(int client, int entityIndex)
{
    int weapon;

    for(int slot=0; slot<5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon) && weapon == entityIndex)
        {
            return slot;
        }
    }

    return -1;
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

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

ArrayList MaterialsModelNum;

int slotWeaponEntityRef[MAXPLAYERS+1][5];
bool slotWeaponEntityRefChanged[MAXPLAYERS+1][5];

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath);
    // HookEvent("teamplay_round_start", OnRoundStart);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);

    MaterialsModelNum = new ArrayList(100);
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
                targetPos[2] -= 15.0;
                SetEntProp(victim, Prop_Send, "m_bDucked", true);

                TeleportEntity(victim, targetPos, NULL_VECTOR, NULL_VECTOR);

                if(!IsSpotSafe(victim, targetPos, 1.0))
                {
                    CP_SetClientCPFlags(victim, CP_GetClientCPFlags(victim) | CPFLAG_DONOTCLEARSLOT);
                    TF2_RespawnPlayer(victim);
                    CP_SetClientCPFlags(victim, CP_GetClientCPFlags(victim) | ~CPFLAG_DONOTCLEARSLOT);
                }
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

            velocity[0] = ang[0] * 800.0;
            velocity[1] = ang[1] * 800.0;
            velocity[2] = ang[2] * 800.0;
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

public Action CP_OnActivedPartTime(int client, int partIndex, float &duration)
{
    if(IsPlayerAlive(client))
    {
        char path[PLATFORM_MAX_PATH];
        float clientPos[3];
        GetClientEyePosition(client, clientPos);

        if(partIndex == 24)
        {
            CreateLaser(client);
            RandomSound("Laser_Hit", path, sizeof(path));

            EmitSoundToAll(path, client, _, _, _, _, _, client, clientPos);
        }
    }

    return Plugin_Continue;
}

void CreateLaser(int client)
{
    float clientPos[3];
    float clientEyeAngles[3];
    float end_pos[3];
    float damage = 14.0;
    float range = 65.0;

    GetClientEyePosition(client, clientPos);
    GetClientEyeAngles(client, clientEyeAngles);
    GetEyeEndPos(client, 0.0, end_pos);

    clientPos[2] -= 28.0;
    clientPos[1] -= 14.0;
    clientPos[0] -= 17.0;

    TE_SetupBeamPoints(clientPos, end_pos, GetPrecacheMaterialsNum(1), GetPrecacheMaterialsNum(2), 10, 50, 0.1
    , 6.0
    , 25.0, 0, 64.0, {0, 255, 0, 255}, 40);
    TE_SendToAll();

    float targetPos[3];
    float targetEndPos[3];
    char path[PLATFORM_MAX_PATH];
    RandomSound("Laser_Hit", path, sizeof(path));

    for(int target=1; target<=MaxClients; target++)
    {
      if(IsClientInGame(target) && IsPlayerAlive(target) && GetClientTeam(target) != GetClientTeam(client))
      {
        GetClientEyePosition(target, targetPos);
        GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

        if(GetVectorDistance(targetPos, targetEndPos) <= range && !TF2_IsPlayerInCondition(target, TFCond_Ubercharged))
        {
          SDKHooks_TakeDamage(target, client, client, damage, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM, -1, _, targetEndPos);

          if(path[0] != '\0'){
              EmitSoundToAll(path, target, _, _, _, _, _, target, targetPos);
              EmitSoundToAll(path, target, _, _, _, _, _, target, targetPos);
          }

          TF2_IgnitePlayer(target, client);
        }
      }
    }

    int ent = -1;

    while((ent = FindEntityByClassname(ent, "obj_sentrygun")) != -1) // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
    {
      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);
      GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

      if(GetVectorDistance(targetPos, targetEndPos) <= range)
      {
        SDKHooks_TakeDamage(ent, client, client, damage*1.5, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1, _, targetEndPos);
      }
    }

    while((ent = FindEntityByClassname(ent, "obj_dispenser")) != -1)  // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
    {
      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);
      GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

      if(GetVectorDistance(targetPos, targetEndPos) <= range)
      {
        SDKHooks_TakeDamage(ent, client, client, damage*1.5, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1, _, targetEndPos);
      }
    }


    while((ent = FindEntityByClassname(ent, "obj_teleporter")) != -1) // FIXME: 한 문장 안에 다 넣으면 스크립트 처리에 문제가 생김.
    {
      GetEntPropVector(ent, Prop_Send, "m_vecOrigin", targetPos);
      GetEyeEndPos(client, GetVectorDistance(clientPos, targetPos), targetEndPos);

      if(GetVectorDistance(targetPos, targetEndPos) <= range)
      {
        SDKHooks_TakeDamage(ent, client, client, damage*1.5, DMG_SLASH|DMG_SHOCK|DMG_ENERGYBEAM|DMG_BURN, -1, _, targetEndPos);
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

            TF2_StunPlayer(client, 1.0, 0.5, TF_STUNFLAGS_SMALLBONK);
            TF2_AddCondition(client, TFCond_MarkedForDeath, 5.0);
        }
    }
}

public Action CP_OnTouchedPartProp(int client, int &prop)
{
    if(CP_IsPartActived(client, 11))
        return Plugin_Handled;

    return Plugin_Continue;
}

public Action CP_OnGetPart(int client, int &prop, int &partIndex)
{
    int part;

    if(CP_IsPartActived(client, 23))
    {
        part = CP_GetClientPart(client, 0);
        partIndex = part;
        return Plugin_Changed;
    }

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

        EmitSoundToAll(path, client, _, _, _, _, _, client, clientPos);

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
    float clientPos[3];

    GetClientEyePosition(client, clientPos);
    CP_NoticePart(client, partIndex);

    if(partIndex == 12)
    {
        AddToAllWeapon(client, 2, 0.3);
        AddToSomeWeapon(client, 412, -0.5);

        char path[PLATFORM_MAX_PATH];
        RandomSound("NanoBbong", path, sizeof(path));

        EmitSoundToAll(path, client, _, _, _, _, _, client, clientPos);
    }


}

public Action CP_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    int weapon;

    if(IsClientInGame(client))
    {
        // Debug("CP_OnSlotClear: client = %i, partIndex = %i", client, partIndex);

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
    float clientPos[3];
    float targetPos[3];

    GetClientEyePosition(attacker, clientPos);

    if(damageType == Percent_Goomba && CP_IsPartActived(attacker, 8))
    {
        float distance = 600.0; // TODO: 메인 플러그인 상의 거리 설정 (파츠 컨픽에서 설정 가능하게.)

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

        char path[PLATFORM_MAX_PATH];
        RandomSound("Bat", path, sizeof(path));

        EmitSoundToAll(path, victim, _, _, _, _, _, victim, clientPos);
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

/*
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
*/

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
        {
            TF2Attrib_SetByDefIndex(entity, defIndex, value);
        }
        else
        {
            TF2Attrib_SetByDefIndex(entity, defIndex, value + 1.0);
        }

        SwitchWeaponForTick(entity);
    }
}

void SwitchWeaponForTick(int entity)
{
    int owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
    int weapon;
    Address itemAddress;

    int slotWeapon[5];
    int count;
    bool hasThis = false;

    if(IsValidClient(owner) && IsValidEntity(entity))
    {
        for(int slot=0; slot < 5; slot++)
        {
            weapon = GetPlayerWeaponSlot(owner, slot);
            itemAddress = TF2Attrib_GetByDefIndex(entity, 226);

            if(IsValidEntity(weapon))
            {
                if(itemAddress != Address_Null && TF2Attrib_GetValue(itemAddress) >= 1.0) // 226
                {
                    continue;
                }
                else if(weapon == entity)
                {
                    hasThis = true;
                    continue;
                }

                slotWeapon[count++] = weapon;
            }
        }

        if(hasThis)
        {
            int random = GetRandomInt(0, count-1);

            SetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon", slotWeapon[random]);
            SetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon", entity);

            if(GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon") != entity)
            {
                SetEntPropFloat(GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_flNextPrimaryAttack", GetGameTime()); // FIXME: 이걸 삭제.
                SetEntPropFloat(GetEntPropEnt(owner, Prop_Send, "m_hActiveWeapon"), Prop_Send, "m_flNextSecondaryAttack", GetGameTime());
                SetEntPropFloat(owner, Prop_Send, "m_flNextAttack", GetGameTime());
                
                Debug("무기 변경 ERROR! %N, slotWeapon[random] = %i, random = %i, entity = %i", owner, slotWeapon[random], random, entity);
            }
        }
    }


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

/*
public bool TryTeleport(clientIdx) // Copied from sarysa's code.
{
	new Float:sizeMultiplier = GetEntPropFloat(clientIdx, Prop_Send, "m_flModelScale");
	static Float:startPos[3];
	static Float:endPos[3];
	static Float:testPos[3];
	static Float:eyeAngles[3];
	GetClientEyePosition(clientIdx, startPos);
	GetClientEyeAngles(clientIdx, eyeAngles);
	TR_TraceRayFilter(startPos, eyeAngles, MASK_PLAYERSOLID, RayType_Infinite, TraceAnything);
	TR_GetEndPosition(endPos);

	// don't even try if the distance is less than 82
	new Float:distance = GetVectorDistance(startPos, endPos);
	if (distance < 82.0)
	{
		return false;
	}

	if (distance > 1500.0)
		constrainDistance(startPos, endPos, distance, 1500.0);
	else // shave just a tiny bit off the end position so our point isn't directly on top of a wall
		constrainDistance(startPos, endPos, distance, distance - 1.0);

	// now for the tests. I go 1 extra on the standard mins/maxs on purpose.
	new bool:found = false;
	for (new x = 0; x < 3; x++)
	{
		if (found)
			break;

		new Float:xOffset;
		if (x == 0)
			xOffset = 0.0;
		else if (x == 1)
			xOffset = 12.5 * sizeMultiplier;
		else
			xOffset = 25.0 * sizeMultiplier;

		if (endPos[0] < startPos[0])
			testPos[0] = endPos[0] + xOffset;
		else if (endPos[0] > startPos[0])
			testPos[0] = endPos[0] - xOffset;
		else if (xOffset != 0.0)
			break; // super rare but not impossible, no sense wasting on unnecessary tests

		for (new y = 0; y < 3; y++)
		{
			if (found)
				break;

			new Float:yOffset;
			if (y == 0)
				yOffset = 0.0;
			else if (y == 1)
				yOffset = 12.5 * sizeMultiplier;
			else
				yOffset = 25.0 * sizeMultiplier;

			if (endPos[1] < startPos[1])
				testPos[1] = endPos[1] + yOffset;
			else if (endPos[1] > startPos[1])
				testPos[1] = endPos[1] - yOffset;
			else if (yOffset != 0.0)
				break; // super rare but not impossible, no sense wasting on unnecessary tests

			for (new z = 0; z < 3; z++)
			{
				if (found)
					break;

				new Float:zOffset;
				if (z == 0)
					zOffset = 0.0;
				else if (z == 1)
					zOffset = 41.5 * sizeMultiplier;
				else
					zOffset = 83.0 * sizeMultiplier;

				if (endPos[2] < startPos[2])
					testPos[2] = endPos[2] + zOffset;
				else if (endPos[2] > startPos[2])
					testPos[2] = endPos[2] - zOffset;
				else if (zOffset != 0.0)
					break; // super rare but not impossible, no sense wasting on unnecessary tests

				// before we test this position, ensure it has line of sight from the point our player looked from
				// this ensures the player can't teleport through walls
				static Float:tmpPos[3];
				TR_TraceRayFilter(endPos, testPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceAnything);
				TR_GetEndPosition(tmpPos);
				if (testPos[0] != tmpPos[0] || testPos[1] != tmpPos[1] || testPos[2] != tmpPos[2])
					continue;

				// now we do our very expensive test. thankfully there's only 27 of these calls, worst case scenario.
				found = IsSpotSafe(clientIdx, testPos, sizeMultiplier);
			}
		}
	}

	if (!found)
	{
		return false;
	}
	TeleportEntity(clientIdx, testPos, NULL_VECTOR, NULL_VECTOR);

	return true;
}
*/

bool ResizeTraceFailed;

stock void constrainDistance(const float[] startPoint, float[] endPoint, float distance, float maxDistance)
{
	float constrainFactor = maxDistance / distance;
	endPoint[0] = ((endPoint[0] - startPoint[0]) * constrainFactor) + startPoint[0];
	endPoint[1] = ((endPoint[1] - startPoint[1]) * constrainFactor) + startPoint[1];
	endPoint[2] = ((endPoint[2] - startPoint[2]) * constrainFactor) + startPoint[2];
}

public bool IsSpotSafe(clientIdx, float playerPos[3], float sizeMultiplier)
{
	ResizeTraceFailed = false;
	static Float:mins[3];
	static Float:maxs[3];
	mins[0] = -24.0 * sizeMultiplier;
	mins[1] = -24.0 * sizeMultiplier;
	mins[2] = 0.0;
	maxs[0] = 24.0 * sizeMultiplier;
	maxs[1] = 24.0 * sizeMultiplier;
	maxs[2] = 82.0 * sizeMultiplier;

	// the eight 45 degree angles and center, which only checks the z offset
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, 0.0, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], 0.0, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1], maxs[2])) return false;

	// 22.5 angles as well, for paranoia sake
	if (!Resize_TestResizeOffset(playerPos, mins[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], mins[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0], maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, mins[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, mins[0] * 0.5, maxs[1], maxs[2])) return false;
	if (!Resize_TestResizeOffset(playerPos, maxs[0] * 0.5, maxs[1], maxs[2])) return false;

	// four square tests
	if (!Resize_TestSquare(playerPos, mins[0], maxs[0], mins[1], maxs[1], maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.75, maxs[0] * 0.75, mins[1] * 0.75, maxs[1] * 0.75, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.5, maxs[0] * 0.5, mins[1] * 0.5, maxs[1] * 0.5, maxs[2])) return false;
	if (!Resize_TestSquare(playerPos, mins[0] * 0.25, maxs[0] * 0.25, mins[1] * 0.25, maxs[1] * 0.25, maxs[2])) return false;

	return true;
}

bool Resize_TestResizeOffset(const float bossOrigin[3], float xOffset, float yOffset, float zOffset)
{
	static Float:tmpOrigin[3];
	tmpOrigin[0] = bossOrigin[0];
	tmpOrigin[1] = bossOrigin[1];
	tmpOrigin[2] = bossOrigin[2];
	static Float:targetOrigin[3];
	targetOrigin[0] = bossOrigin[0] + xOffset;
	targetOrigin[1] = bossOrigin[1] + yOffset;
	targetOrigin[2] = bossOrigin[2];

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	tmpOrigin[0] = targetOrigin[0];
	tmpOrigin[1] = targetOrigin[1];
	tmpOrigin[2] = targetOrigin[2] + zOffset;

	if (!Resize_OneTrace(targetOrigin, tmpOrigin))
		return false;

	targetOrigin[0] = bossOrigin[0];
	targetOrigin[1] = bossOrigin[1];
	targetOrigin[2] = bossOrigin[2] + zOffset;

	if (!(xOffset == 0.0 && yOffset == 0.0))
		if (!Resize_OneTrace(tmpOrigin, targetOrigin))
			return false;

	return true;
}

bool Resize_TestSquare(const float bossOrigin[3], float xmin, float xmax, float ymin, float ymax, float zOffset)
{
	static Float:pointA[3];
	static Float:pointB[3];
	for (new phase = 0; phase <= 7; phase++)
	{
		// going counterclockwise
		if (phase == 0)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 1)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 2)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmax;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 3)
		{
			pointA[0] = bossOrigin[0] + xmax;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 4)
		{
			pointA[0] = bossOrigin[0] + 0.0;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymin;
		}
		else if (phase == 5)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymin;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + 0.0;
		}
		else if (phase == 6)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + 0.0;
			pointB[0] = bossOrigin[0] + xmin;
			pointB[1] = bossOrigin[1] + ymax;
		}
		else if (phase == 7)
		{
			pointA[0] = bossOrigin[0] + xmin;
			pointA[1] = bossOrigin[1] + ymax;
			pointB[0] = bossOrigin[0] + 0.0;
			pointB[1] = bossOrigin[1] + ymax;
		}

		for (new shouldZ = 0; shouldZ <= 1; shouldZ++)
		{
			pointA[2] = pointB[2] = shouldZ == 0 ? bossOrigin[2] : (bossOrigin[2] + zOffset);
			if (!Resize_OneTrace(pointA, pointB))
				return false;
		}
	}

	return true;
}

public bool TraceAnything(int entity, int contentsMask)
{
    return false;
}

bool Resize_OneTrace(const float startPos[3], const float endPos[3])
{
	static Float:result[3];
	TR_TraceRayFilter(startPos, endPos, MASK_PLAYERSOLID, RayType_EndPoint, TraceAnything);
	if (ResizeTraceFailed)
	{
		return false;
	}
	TR_GetEndPosition(result);
	if (endPos[0] != result[0] || endPos[1] != result[1] || endPos[2] != result[2])
	{
		return false;
	}

	return true;
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
  char keyName[60];
  int count;
  BuildPath(Path_SM, config, sizeof(config), "configs/custompart_sub.cfg");

  if(!FileExists(config))
  {
      SetFailState("[CP] NO CFG FILE! (configs/custompart_sub.cfg)");
      return;
  }

  CustomPartSubKv = CreateKeyValues("custompart_sub");
  MaterialsModelNum.Clear();
  MaterialsModelNum.Resize(100);

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
              KvGetSectionName(CustomPartSubKv, keyName, sizeof(keyName));
              Format(item, sizeof(item), "%i", ++count);
              KvGetString(CustomPartSubKv, item, config, sizeof(config), "");

              if(config[0] == '\0') break;

              Format(temp, sizeof(temp), "sound/%s", config);

              if(StrEqual(keyName, "models"))
              {
                  if(FileExists(config, true))
                  {
                      PrecacheModel(config);
                  }
              }
              else if(StrEqual(keyName, "materials"))
              {
                  if(FileExists(config, true))
                  {
                      int precached = PrecacheModel(config);
                      MaterialsModelNum.Set(count, precached);
                  }
              }
              else if(FileExists(temp, true))
              {
                  PrecacheSound(config);
                  AddFileToDownloadsTable(temp);
              }
          }
      }
      while(KvGotoNextKey(CustomPartSubKv));
  }
}

public int GetPrecacheMaterialsNum(int index)
{
    if(index >= MaterialsModelNum.Length || 0 > index)
        return 0;

    return MaterialsModelNum.Get(index);
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

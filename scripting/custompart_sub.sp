#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
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

/*

- 1: 파괴됨!
- 9: 건 소울
- 11: 파츠 거부 반응

*/

float NanoBoongDuration[MAXPLAYERS+1];

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
}

public void OnGameFrame() // TODO: 본 작업을 메인플러그인에서 할 수 있게.
{
    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            float currentTime = GetGameTime();
            if(currentTime > NanoBoongDuration[client])
            {
                AddToAllWeapon(client, 2, -0.3);
                AddToSomeWeapon(client, 412, 0.5);
            }
        }
        else
        {
            NanoBoongDuration[client] = 0.0;
        }
    }
}

public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    int client = GetEventInt(event, "userid");
    if(!IsClientInGame(client)) return Plugin_Continue;

    return Plugin_Continue;
}

public Action CP_OnTouchedPartProp(int client, int prop)
{
    if(CP_IsPartActived(client, 11))
        return Plugin_Handled;

    return Plugin_Continue;
}

public void CP_OnGetPart_Post(int client, int partIndex)
{
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
        CP_NoticePart(client, partIndex);
    }
}

public void CP_OnActivedPart(int client, int partIndex)
{
    if(partIndex == 12)
    {
        NanoBoongDuration[client] = GetGameTime() + 8.0;

        AddToAllWeapon(client, 2, 0.3);
        AddToSomeWeapon(client, 412, -0.5);
        CP_NoticePart(client, partIndex);
    }
}

public Action CP_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    if(IsClientInGame(client))
    {
        if(FF2_GetRoundState() != 1)
            return Plugin_Continue;

        Debug("CP_OnSlotClear: client = %i, partIndex = %i", client, partIndex);

        if(CP_IsPartActived(client, 8))
            return Plugin_Handled;

        if(partIndex == 10)
        {
            CP_SetClientMaxSlot(client, CP_GetClientMaxSlot(client) - 2);
        }

        else if(partIndex == 2) // "체력 강화제"
        {
/////////////////////////////////// 복사 북여넣기 하기 좋은거!!
            AddToSomeWeapon(client, 26, -50.0);
//////////////////////////////////
            AddToSomeWeapon(client, 109, 0.1);
        }

        else if(partIndex == 3) // "근육 강화제"
        {
            AddToAllWeapon(client, 6, -0.2);
            AddToAllWeapon(client, 97, 0.2);
            AddToSomeWeapon(client, 69, 0.5);
        }

        else if(partIndex == 4) // "나노 제트팩"
        {
            AddToSomeWeapon(client, 610, -0.5);
            AddToSomeWeapon(client, 207, -1.2);
        }

        else if(partIndex == 6) // "무쇠 탄환"
        {
            AddToAllWeapon(client, 389, -1.0);
            AddToAllWeapon(client, 397, -5.0);
            AddToAllWeapon(client, 266, -1.0);

            AddToAllWeapon(client, 2, -0.3);
            AddToSomeWeapon(client, 54, 0.15);
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

    if((damageType == Percent_Marketed || damageType == Percent_GroundMarketed) && CP_IsPartActived(attacker, 9))
    {
        changed = true;
        damage *= 1.5;
    }

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

void AddToAllWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot <= 5; slot++)
    {
        weapon = GetPlayerWeaponSlot(client, slot);
        if(IsValidEntity(weapon))
            AddAttributeDefIndex(weapon, defIndex, value);
    }
}

void AddToSomeWeapon(int client, int defIndex, float value)
{
    int weapon;
    for(int slot = 0; slot <= 5; slot++)
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
        TF2Attrib_SetByDefIndex(entity, defIndex, value+1.0);
    }
}

stock int FindAnotherPerson(int Gclient)
{
    int count;
    int validTarget[MAXPLAYERS+1];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && client != Gclient && !IsBossTeam(client) && !IsPlayerAlive(client))
        {
            validTarget[count++]=client;
        }
    }

    if(!count)
    {
        return CreateFakeClient("No Target.");
    }
    return validTarget[GetRandomInt(0, count-1)];
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

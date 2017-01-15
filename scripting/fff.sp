/*
Fixed Friendly Fire
By: Chdata & Kit O' Rifty

TODO:
Fix Flying Guillotine cleavers.
Investigate bodies falling through the ground when you die after toggling the plugin on/off

*/

#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>
#include <morecolors>

#define PLUGIN_VERSION "0x02"

static const String:g_sPvPProjectileClasses[][] =
{
    "tf_projectile_rocket",
    "tf_projectile_sentryrocket",
    "tf_projectile_arrow",
    "tf_projectile_stun_ball",
    //"tf_projectile_cleaver",
    "tf_projectile_ball_ornament",
    "tf_projectile_energy_ball",
    "tf_projectile_energy_ring",
    "tf_projectile_flare",
    "tf_projectile_healing_bolt",
    "tf_projectile_jar",
    "tf_projectile_jar_milk",
    "tf_projectile_pipe",
    //"tf_projectile_pipe_remote",
    "tf_projectile_syringe"
}; //

static bool:bFriendlyFire = false;

static Handle:g_hPvPFlameEntities;

enum
{
    PvPFlameEntData_EntRef = 0,
    PvPFlameEntData_LastHitEntRef,
    PvPFlameEntData_MaxStats
};

public Plugin:myinfo = {
    name = "Fixed Friendly Fire",
    author = "Kit O'Rifty & Chdata",
    description = "Hexy.",
    version = PLUGIN_VERSION,
    url = "http://steamcommunity.com/groups/tf2data",
};

public OnPluginStart()
{
    g_hPvPFlameEntities = CreateArray(PvPFlameEntData_MaxStats);

    HookConVarChange(FindConVar("mp_friendlyfire"), CvarChange);

    RegAdminCmd("sm_friendlyfire", cmdFriendlyFireToggle, ADMFLAG_CHEATS, "sm_friendlyfire <on/off> - Toggles mp_friendlyfire status.");

    for (new lClient = 1; lClient <= MaxClients; lClient++)
    {
        if (IsClientInGame(lClient))
        {
            if (GetConVarBool(FindConVar("mp_friendlyfire")))
            {
                //SDKHook(lClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
                SDKHook(lClient, SDKHook_PreThinkPost, FriendlyPushApart);
            }
            // else
            // {
            //     SDKUnhook(lClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
            //     SDKUnhook(lClient, SDKHook_PreThinkPost, FriendlyPushApart);
            // }
        }
    }

    // AutoExecConfig(true, "plugin.friendlyfire");
}

public OnClientPostAdminCheck(iClient)
{
    if (bFriendlyFire)
    {
        //SDKHook(iClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
        SDKHook(iClient, SDKHook_PreThinkPost, FriendlyPushApart);
    }
}

public OnClientDisconnect(iClient)
{
    //SDKUnhook(iClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
    //SDKUnhook(iClient, SDKHook_PreThinkPost, FriendlyPushApart);
}

public OnMapStart()
{
    ClearArray(g_hPvPFlameEntities);
}

public OnConfigsExecuted()
{
    bFriendlyFire = GetConVarBool(FindConVar("mp_friendlyfire"));
}

public CvarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
    // CPrintToChdata("ff status changed");

    new Handle:svtags = FindConVar("sv_tags");
    new sflags = GetConVarFlags(svtags);
    sflags &= ~FCVAR_NOTIFY;
    SetConVarFlags(svtags, sflags);

    new flags = GetConVarFlags(convar);
    flags &= ~FCVAR_NOTIFY;
    SetConVarFlags(convar, flags);

    bFriendlyFire = GetConVarBool(convar);

    SetConVarBool(FindConVar("tf_avoidteammates"), !bFriendlyFire, true);

    // if (bFriendlyFire)
    // {
    //     SetConVarInt(FindConVar("tf_avoidteammates"), 0);           // Friendly players are solid
    //     //SetConVarInt(FindConVar("tf_avoidteammates_pushaway"), 0);
    // }
    // else
    // {
    //     SetConVarInt(FindConVar("tf_avoidteammates"), 1);           // Friendly players are not solid
    // }

    for (new lClient = 1; lClient <= MaxClients; lClient++)
    {
        if (IsClientInGame(lClient)) // && IsPlayerAlive(lClient)
        {
            if (bFriendlyFire)
            {
                //SDKHook(lClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
                SDKHook(lClient, SDKHook_PreThinkPost, FriendlyPushApart);
            }
            else
            {
                //SDKUnhook(lClient, SDKHook_ShouldCollide, Hook_ClientPvPShouldCollide);
                SDKUnhook(lClient, SDKHook_PreThinkPost, FriendlyPushApart);
            }

        }
    }

  //  CPrintToChatAll("{green}[{lightgreen}FF{green}]{default} Friendly Fire has been %sabled.", bFriendlyFire ? "en" : "dis");
}

/*
Runs every frame for clients

*/
public FriendlyPushApart(iClient)
{
    // if (!bFriendlyFire)
    // {
    //     // Technically this code should never be reached because we unhook it during CvarChange
    //     SDKUnhook(iClient, SDKHook_PreThinkPost, FriendlyPushApart);
    //     return;
    // }

    if (IsPlayerAlive(iClient) && IsPlayerStuck(iClient))       // If a player is stuck in a player, push them apart
    {
        PushClientsApart(iClient, TR_GetEntityIndex());         // Temporarily remove collision while we push apart
    }
    else
    {
        SetEntProp(iClient, Prop_Send, "m_CollisionGroup", 5);  // Same collision as normal
    }
}

stock bool:IsPlayerStuck(iEntity)
{
    decl Float:vecMin[3], Float:vecMax[3], Float:vecOrigin[3];

    GetEntPropVector(iEntity, Prop_Send, "m_vecMins", vecMin);
    GetEntPropVector(iEntity, Prop_Send, "m_vecMaxs", vecMax);
    GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", vecOrigin);

    TR_TraceHullFilter(vecOrigin, vecOrigin, vecMin, vecMax, MASK_SOLID, TraceRayPlayerOnly, iEntity);
    return (TR_DidHit());
}

public bool:TraceRayPlayerOnly(iEntity, iMask, any:iData)
{
    return (IsValidClient(iEntity) && IsValidClient(iData) && iEntity != iData);
}

stock PushClientsApart(iClient1, iClient2)
{
    SetEntProp(iClient1, Prop_Send, "m_CollisionGroup", 2);     // No collision with players and certain projectiles
    SetEntProp(iClient2, Prop_Send, "m_CollisionGroup", 2);

    decl Float:vVel[3];

    decl Float:vOrigin1[3];
    decl Float:vOrigin2[3];

    GetEntPropVector(iClient1, Prop_Send, "m_vecOrigin", vOrigin1);
    GetEntPropVector(iClient2, Prop_Send, "m_vecOrigin", vOrigin2);

    MakeVectorFromPoints(vOrigin1, vOrigin2, vVel);
    NormalizeVector(vVel, vVel);
    ScaleVector(vVel, -15.0);               // Set to 15.0 for a black hole effect

    vVel[1] += 0.1;                         // This is just a safeguard for sm_tele
    vVel[2] = 0.0;                          // Negate upwards push. += 280.0; for extra upwards push (can have sort of a fan/vent effect)

    // new iBaseVelocityOffset = FindSendPropOffs("CBasePlayer","m_vecBaseVelocity");  // FindSendPropInfo
    new iBaseVelocityOffset = FindSendPropInfo("CBasePlayer","m_vecBaseVelocity");
    SetEntDataVector(iClient1, iBaseVelocityOffset, vVel, true);
}

public Action:cmdFriendlyFireToggle(iClient, iArgc)
{
    if (iArgc < 1)
    {
        SetFriendlyFire(!bFriendlyFire);
    }
    else
    {
        decl String:arg[32];
        GetCmdArgString(arg, sizeof(arg));

        if (StrEqual(arg, "on") || arg[0] == '1')
        {
            SetFriendlyFire(true);
        }
        else if (StrEqual(arg, "off") || arg[0] == '0')
        {
            SetFriendlyFire(false);
        }
        else
        {
            SetFriendlyFire(!bFriendlyFire);
        }
    }

    return Plugin_Handled;
}

stock SetFriendlyFire(bool:bStatus)
{
    SetConVarBool(FindConVar("mp_friendlyfire"), bStatus, true);
}

// Start of Kit O' Rifty's material

public OnGameFrame()
{
    if (bFriendlyFire)
    {
        // Process through PvP projectiles.
        for (new i = 0; i < sizeof(g_sPvPProjectileClasses); i++)
        {
            new ent = -1;
            while ((ent = FindEntityByClassname(ent, g_sPvPProjectileClasses[i])) != -1)
            {
                // new iThrowerOffset = FindDataMapOffs(ent, "m_hThrower"); // FindDataMapInfo
                new iThrowerOffset = FindDataMapInfo(ent, "m_hThrower");
                new bool:bChangeProjectileTeam = false;

                new iOwnerEntity = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
                if (IsValidClient(iOwnerEntity))
                {
                    bChangeProjectileTeam = true;
                }
                else if (iThrowerOffset != -1)
                {
                    iOwnerEntity = GetEntDataEnt2(ent, iThrowerOffset);
                    if (IsValidClient(iOwnerEntity))
                    {
                        bChangeProjectileTeam = true;
                    }
                }

                if (bChangeProjectileTeam)
                {
                    SetEntProp(ent, Prop_Data, "m_iInitialTeamNum", 0);
                    SetEntProp(ent, Prop_Send, "m_iTeamNum", 0);
                }
            }
        }

        // Process through PvP flame entities.
        static Float:flMins[3] = { -6.0, ... };
        static Float:flMaxs[3] = { 6.0, ... };

        decl Float:flOrigin[3];

        new Handle:hTrace = INVALID_HANDLE;
        new ent = -1;
        new iOwnerEntity = INVALID_ENT_REFERENCE;
        new iHitEntity = INVALID_ENT_REFERENCE;

        while ((ent = FindEntityByClassname(ent, "tf_flame")) != -1)
        {
            iOwnerEntity = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");

            if (IsValidEdict(iOwnerEntity))
            {
                // tf_flame's initial owner SHOULD be the flamethrower that it originates from.
                // If not, then something's completely bogus.

                iOwnerEntity = GetEntPropEnt(iOwnerEntity, Prop_Data, "m_hOwnerEntity");
            }

            if (IsValidClient(iOwnerEntity))
            {
                GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", flOrigin);

                hTrace = TR_TraceHullFilterEx(flOrigin, flOrigin, flMins, flMaxs, MASK_PLAYERSOLID, TraceRayDontHitSelf, iOwnerEntity);
                iHitEntity = TR_GetEntityIndex(hTrace);
                CloseHandle(hTrace);

                if (IsValidEntity(iHitEntity))
                {
                    new entref = EntIndexToEntRef(ent);

                    new iIndex = FindValueInArray(g_hPvPFlameEntities, entref);
                    if (iIndex != -1)
                    {
                        new iLastHitEnt = EntRefToEntIndex(GetArrayCell(g_hPvPFlameEntities, iIndex, PvPFlameEntData_LastHitEntRef));

                        if (iHitEntity != iLastHitEnt)
                        {
                            SetArrayCell(g_hPvPFlameEntities, iIndex, EntIndexToEntRef(iHitEntity), PvPFlameEntData_LastHitEntRef);
                            PvP_OnFlameEntityStartTouchPost(ent, iHitEntity);
                        }
                    }
                }
            }
        }
    }
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
    return (entity != data);
}

static PvP_OnFlameEntityStartTouchPost(flame, other)
{
    if (IsValidClient(other))
    {
        new iFlamethrower = GetEntPropEnt(flame, Prop_Data, "m_hOwnerEntity");
        if (IsValidEdict(iFlamethrower))
        {
            new iOwnerEntity = GetEntPropEnt(iFlamethrower, Prop_Data, "m_hOwnerEntity");
            if (iOwnerEntity != other && IsValidClient(iOwnerEntity))
            {
                if (GetClientTeam(other) == GetClientTeam(iOwnerEntity))
                {
                    TF2_IgnitePlayer(other, iOwnerEntity);
                    SDKHooks_TakeDamage(other, iOwnerEntity, iOwnerEntity, 7.0, IsClientCritBoosted(iOwnerEntity) ? (DMG_BURN | DMG_PREVENT_PHYSICS_FORCE | DMG_ACID) : DMG_BURN | DMG_PREVENT_PHYSICS_FORCE);
                }
            }
        }
    }
}

public OnEntityCreated(ent, const String:sClassname[])
{
    if (StrEqual(sClassname, "tf_flame", false))
    {
        new iIndex = PushArrayCell(g_hPvPFlameEntities, EntIndexToEntRef(ent));
        if (iIndex != -1)
        {
            SetArrayCell(g_hPvPFlameEntities, iIndex, INVALID_ENT_REFERENCE, PvPFlameEntData_LastHitEntRef);
        }
    }
    else
    {
        if (bFriendlyFire)
        {
            for (new i = 0; i < sizeof(g_sPvPProjectileClasses); i++)
            {
                if (StrEqual(sClassname, g_sPvPProjectileClasses[i], false))
                {
                    SDKHook(ent, SDKHook_Spawn, Hook_PvPProjectileSpawn);
                    SDKHook(ent, SDKHook_SpawnPost, Hook_PvPProjectileSpawnPost);
                    break;
                }
            }

            /*if (StrEqual(sClassname, "tf_projectile_cleaver", false))
            {
                SDKHook(ent, SDKHook_StartTouch, Hook_PVPCleaverHit);
            }*/
        }
    }
}

/*public Action:Hook_PVPCleaverHit(entity, other)
{
    if (IsValidClient(other))
    {
        new iOwnerEntity = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");
        if (IsValidClient(iOwnerEntity) && iOwnerEntity != other)
        {
            if (GetClientTeam(other) == GetClientTeam(iOwnerEntity))
            {
                TF2_MakeBleed(other, iOwnerEntity, 5.0);
                SDKHooks_TakeDamage(other, iOwnerEntity, iOwnerEntity, 50.0, IsClientCritBoosted(iOwnerEntity) ? (DMG_SLASH | DMG_ACID) : DMG_SLASH);
            }
        }
    }
}*/

public OnEntityDestroyed(ent)
{
    if (!IsValidEntity(ent) || ent <= 0) return;

    decl String:sClassname[64];
    GetEntityClassname(ent, sClassname, sizeof(sClassname));

    if (StrEqual(sClassname, "tf_flame", false))
    {
        new entref = EntIndexToEntRef(ent);
        new iIndex = FindValueInArray(g_hPvPFlameEntities, entref);
        if (iIndex != -1)
        {
            RemoveFromArray(g_hPvPFlameEntities, iIndex);
        }
    }
}

public Action:Hook_PvPProjectileSpawn(ent)
{
    ChangeProjectileTeam(ent);

    return Plugin_Continue;
}

public Hook_PvPProjectileSpawnPost(ent)
{
    ChangeProjectileTeam(ent);
}

stock ChangeProjectileTeam(ent)
{
    if (bFriendlyFire)
    {
        decl String:sClass[64];
        GetEntityClassname(ent, sClass, sizeof(sClass));

        // new iThrowerOffset = FindDataMapOffs(ent, "m_hThrower");
        new iThrowerOffset = FindDataMapInfo(ent, "m_hThrower");
        new iOwnerEntity = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");

        if (iOwnerEntity == -1 && iThrowerOffset != -1)
        {
            iOwnerEntity = GetEntDataEnt2(ent, iThrowerOffset);
        }

        if (IsValidClient(iOwnerEntity))
        {
            SetEntProp(ent, Prop_Data, "m_iInitialTeamNum", 0);
            SetEntProp(ent, Prop_Send, "m_iTeamNum", 0);
        }
    }
}

public bool:Hook_ClientPvPShouldCollide(ent, collisiongroup, contentsmask, bool:originalResult)
{
    if (bFriendlyFire) return true;
    return originalResult;
}

stock bool:IsClientCritBoosted(client)
{
    if (TF2_IsPlayerInCondition(client, TFCond_Kritzkrieged) ||
        TF2_IsPlayerInCondition(client, TFCond_HalloweenCritCandy) ||
        TF2_IsPlayerInCondition(client, TFCond_CritCanteen) ||
        TF2_IsPlayerInCondition(client, TFCond_CritOnFirstBlood) ||
        TF2_IsPlayerInCondition(client, TFCond_CritOnWin) ||
        TF2_IsPlayerInCondition(client, TFCond_CritOnFlagCapture) ||
        TF2_IsPlayerInCondition(client, TFCond_CritOnKill) ||
        TF2_IsPlayerInCondition(client, TFCond_CritOnDamage) ||
        TF2_IsPlayerInCondition(client, TFCond_CritMmmph))
    {
        return true;
    }

    new iActiveWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
    if (IsValidEdict(iActiveWeapon))
    {
        decl String:sNetClass[64];
        GetEntityNetClass(iActiveWeapon, sNetClass, sizeof(sNetClass));

        if (StrEqual(sNetClass, "CTFFlameThrower"))
        {
            if (GetEntProp(iActiveWeapon, Prop_Send, "m_bCritFire")) return true;

            new iItemDef = GetEntProp(iActiveWeapon, Prop_Send, "m_iItemDefinitionIndex");
            if (iItemDef == 594 && TF2_IsPlayerInCondition(client, TFCond_CritMmmph)) return true;
        }
        else if (StrEqual(sNetClass, "CTFMinigun"))
        {
            if (GetEntProp(iActiveWeapon, Prop_Send, "m_bCritShot")) return true;
        }
    }

    return false;
}

stock bool:IsValidClient(iClient)
{
    return bool:(0 < iClient && iClient <= MaxClients && IsClientInGame(iClient));
}

/*static PvP_RemovePlayerProjectiles(client)
{
    for (new i = 0; i < sizeof(g_sPvPProjectileClasses); i++)
    {
        new ent = -1;
        while ((ent = FindEntityByClassname(ent, g_sPvPProjectileClasses[i])) != -1)
        {
            new iThrowerOffset = FindDataMapOffs(ent, "m_hThrower");
            new bool:bMine = false;

            new iOwnerEntity = GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
            if (iOwnerEntity == client)
            {
                bMine = true;
            }
            else if (iThrowerOffset != -1)
            {
                iOwnerEntity = GetEntDataEnt2(ent, iThrowerOffset);
                if (iOwnerEntity == client)
                {
                    bMine = true;
                }
            }

            if (bMine) AcceptEntityInput(ent, "Kill");
        }
    }
}*/

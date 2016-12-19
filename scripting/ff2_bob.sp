#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>
#include <sdkhooks>

bool Bob_Enabled[MAXPLAYERS+1];

public Plugin myinfo=
{
    name="Freak Fortress 2 : Bob's Abilities",
    author="Nopied",
    description="....",
    version="2016_10_17",
};

public void OnPluginStart2()
{
    HookEvent("arena_round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
  CheckAbility();
}

public void OnEntityCreated(int entity, const char[] classname)
{
    SDKHook(entity, SDKHook_SpawnPost, OnProjectileSpawn);
}

public void OnProjectileSpawn(int entity)
{
    char classname[60];
    GetEntityClassname(entity, classname, sizeof(classname));

    if(StrEqual(classname, "tf_projectile_pipe", true))
    {
        int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
        if(IsValidClient(client) && Bob_Enabled[client])
        {
            float origin[3];
            float angles[3];
            float angVector[3];
            // float velocity[3];
            // float vecrt[3];

            GetClientEyePosition(client, origin);
            GetClientEyeAngles(client, angles);

            // GetEntPropVector(entity, Prop_Data, "m_vecVelocity", velocity);
            AcceptEntityInput(entity, "Kill");

            GetAngleVectors(angles, angVector, NULL_VECTOR, NULL_VECTOR);
            NormalizeVector(angVector, angVector);

            origin[2] += 25.0;

            angVector[0]*=1500.0;	// Test this,
    		angVector[1]*=1500.0;
    		// angVector[2]*=800.0;
            angVector[2]*=1500.0;

            int sentry = TF2_BuildSentry(client, origin, angles, 3, _, _, _, 8);
            SetEntityMoveType(sentry, MOVETYPE_FLYGRAVITY);
            // SetEntityMoveType(sentry, MOVETYPE_FLY);
            // SetEntityGravity(sentry, 0.0);
            // SetEntityFlags(sentry, GetEntityFlags(sentry) | FL_BASEVELOCITY | FL_DONTTOUCH | ~FL_WORLDBRUSH);
            // SetEntityFlags(sentry, GetEntityFlags(sentry) | FL_BASEVELOCITY | ~FL_WORLDBRUSH);
            UpdateEntityHitbox(sentry, 4.0);// TODO: 커스터마이즈

            TeleportEntity(sentry, origin, angles, angVector);
        }
    }
}

public Action FF2_OnAbility2(int boss, const char[] pluginName, const char[] abilityName, int status)
{

}

stock void UpdateEntityHitbox(const int client, const float fScale)
{
    static const Float:vecTF2PlayerMin[3] = { -24.5, -24.5, 0.0 }, Float:vecTF2PlayerMax[3] = { 24.5,  24.5, 83.0 };

    decl Float:vecScaledPlayerMin[3], Float:vecScaledPlayerMax[3];

    vecScaledPlayerMin = vecTF2PlayerMin;
    vecScaledPlayerMax = vecTF2PlayerMax;

    ScaleVector(vecScaledPlayerMin, fScale);
    ScaleVector(vecScaledPlayerMax, fScale);

    SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMins", vecScaledPlayerMin);
    SetEntPropVector(client, Prop_Send, "m_vecSpecifiedSurroundingMaxs", vecScaledPlayerMax);
}

void CheckAbility()
{
    int client, boss;
    for(client=1; client<=MaxClients; client++)
    {
        Bob_Enabled[client] = false;

  	    if((boss=FF2_GetBossIndex(client)) != -1)
  	    {
  	      	if(FF2_HasAbility(boss, this_plugin_name, "ff2_bob_ability"))
                Bob_Enabled[client] = true;
  		}
    }
}

stock bool IsValidClient(int client)
{
    return (0 < client && client < MaxClients && IsClientInGame(client));
}

stock int TF2_BuildSentry(int builder, float fOrigin[3], float fAngle[3], int level, bool mini=false, bool disposable=false, bool carried=false, int flags=4)
{
	static const float m_vecMinsMini[3] = {-15.0, -15.0, 0.0};
	float m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	static const float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0};
	float m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};

	int sentry = CreateEntityByName("obj_sentrygun");

	if(IsValidEntity(sentry))
	{
		AcceptEntityInput(sentry, "SetBuilder", builder);

		DispatchKeyValueVector(sentry, "origin", fOrigin);
		DispatchKeyValueVector(sentry, "angles", fAngle);

		if(mini)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			// SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);

			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");

			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
		}
		else if(disposable)
		{
			SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			// SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
			SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? GetClientTeam(builder) : GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);

			SetVariantInt(100);
			AcceptEntityInput(sentry, "SetHealth");

			SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
			SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
			SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
		}
		else
		{
			SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
			SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
			SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
			// SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
            SetEntProp(sentry, Prop_Send, "m_bBuilding", 0);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
		}

        // SetEntProp(sentry, Prop_Send, "m_bPlayerControlled", 1);
        SetEntProp(sentry, Prop_Send, "m_iTeamNum", builder > 0 ? GetClientTeam(builder) : FF2_GetBossTeam());

        return sentry;
	}

    return -1;
}

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

bool MapIsRunning = false;

#define MODEL_TRIGGER	"models/buildables/teleporter.mdl"

public Plugin myinfo=
{
	name="팩 위에.. 건물 짓지마..",
	author="Nopied◎",
	description="",
	version="111111111111111111111111111.0",
};

public OnEntityCreated(entity, const String:classname[])
{
	if(!StrContains(classname, "item_healthkit", false) || !StrContains(classname, "item_ammopack", false))
	{
		SDKHook(entity, SDKHook_Spawn, OnItemSpawned);
	}
}

public void OnMapStart()
{
    MapIsRunning = true;

    PrecacheModel(MODEL_TRIGGER, true);
}

public void OnMapEnd()
{
    MapIsRunning = false;
}

public OnItemSpawned(entity)
{
    if(MapIsRunning && CheckRoundState() != 1)
    {
        int nobulid = CreateEntityByName("func_nobuild");
        if(IsValidEntity(nobulid))
        {
            float vecMin[3];
            float vecMax[3];
            float origin[3];

            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);

            DispatchSpawn(nobulid);

            GetEntPropVector(entity, Prop_Send, "m_vecMins", vecMin);
            GetEntPropVector(entity, Prop_Send, "m_vecMaxs", vecMax);

            vecMin[0] *= 2.0;
            vecMin[1] *= 2.0;
            vecMin[2] *= 2.0;

            vecMax[0] *= 2.0;
            vecMax[1] *= 2.0;
            vecMax[2] *= 2.0;

            SetEntPropVector(nobulid, Prop_Send, "m_vecMins", vecMin);
            SetEntPropVector(nobulid, Prop_Send, "m_vecMaxs", vecMax);

            TeleportEntity(nobulid, origin, NULL_VECTOR, NULL_VECTOR);

            SetEntityModel(nobulid, MODEL_TRIGGER);
            SetEntProp(nobulid, Prop_Send, "m_nSolidType", 2);

            AcceptEntityInput(nobulid, "Enable");
            ActivateEntity(nobulid);
        }
    }
}

int CheckRoundState()
{
	switch(GameRules_GetRoundState())
	{
		case RoundState_Init, RoundState_Pregame:
		{
			return -1;
		}
		case RoundState_StartGame, RoundState_Preround:
		{
			return 0;
		}
		case RoundState_RoundRunning, RoundState_Stalemate:  //Oh Valve.
		{
			return 1;
		}
		default:
		{
			return 2;
		}
	}
	return -1;  //Compiler bug-doesn't recognize 'default' as a valid catch-all
}

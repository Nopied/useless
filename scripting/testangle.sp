#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <morecolors>

public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart);
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    CPrintToChatAll("{green}변형된 신체로 잘 숨어보세요!");
}

public void OnGameFrame()
{
    float StartAngle[3];
    char Input[100];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            char modelPath[PLATFORM_MAX_PATH];
            GetClientModel(client, modelPath, sizeof(modelPath));

            SetVariantString(modelPath);
            AcceptEntityInput(client, "SetCustomModel", client);

            GetClientEyeAngles(client, StartAngle);

            Format(Input, sizeof(Input), "%.1f %.1f %.1f", StartAngle[0], StartAngle[1], StartAngle[2]);

            SetVariantBool(true);
            AcceptEntityInput(client, "SetCustomModelRotates");

            SetVariantString(Input);
            AcceptEntityInput(client, "SetCustomModelRotation", client);

            RequestFrame(ClassAniTimer, client);
        }
    }
}

public void ClassAniTimer(int client)
{
	if(IsClientInGame(client))
		SetEntProp(client, Prop_Send, "m_bUseClassAnimations", 1);
}

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnGameFrame()
{
    float StartAngle[3];
    char Input[100];
    char model[PLATFORM_MAX_PATH];

    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            ActivateEntity(client);
            
            GetClientModel(client, model, sizeof(model));
            GetClientEyeAngles(client, StartAngle);

            Format(Input, sizeof(Input), "%.1f %.1f %.1f", StartAngle[0], StartAngle[1], StartAngle[2]);

            SetVariantString(model);
            AcceptEntityInput(client, "SetCustomModel");

            SetVariantBool(true);
            AcceptEntityInput(client, "SetCustomModelRotates");

            SetVariantString(Input);
            AcceptEntityInput(client, "SetCustomModelRotation", client);
        }
    }
}

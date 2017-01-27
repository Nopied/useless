#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public void OnEntityCreated(int entity, const char[] classname)
{
    // LogMessage("%i, %s", entity, classname);
    // PrintToChatAll("%i, %s", entity, classname);
}

public void OnGameFrame()
{
    float StartAngle[3];
    char Input[100];

    /*
    for(int client=1; client<=MaxClients; client++)
    {
        if(IsClientInGame(client) && IsPlayerAlive(client))
        {
            GetClientEyeAngles(client, StartAngle);

            ActivateEntity(client);

            Format(Input, sizeof(Input), "%.1f %.1f %.1f", StartAngle[0], StartAngle[1], StartAngle[2]);

            SetVariantBool(true);
            AcceptEntityInput(client, "SetCustomModelRotates");

            SetVariantString(Input);
            AcceptEntityInput(client, "SetCustomModelRotation", client);
            
            SetEntPropVector(client, Prop_Send, "m_angRotation", StartAngle);
        }
    }
    */
}

#include <sourcemod>

public void OnPluginStart()
{
    RegConsoleCmd("testcoll", Command_TestColl, "");
    AddNormalSoundHook(SoundHook);
}

public Action Command_TestColl(int client, int args)
{
    int clientColl = GetEntProp(client, Prop_Send, "m_CollisionGroup");
    char clientName[50];
    GetClientName(client, clientName, sizeof(clientName));

    PrintToChatAll("%s의 Coll을 %d에서 2로 바꿈.", clientName, clientColl);
    SetEntProp(client, Prop_Send, "m_CollisionGroup", 2);
}

public Action SoundHook(int clients[64], int &numClients, char sample[], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags)
{
    PrintToChatAll("SoundHook: \n sample: %s\n entity: %d\n channel: %d\n volume: %.1f", sample, entity, channel, volume);
}

#include <sourcemod>
#include <morecolors>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <freak_fortress_2>
#include <custompart>

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

bool IsRealSpy[MAXPLAYERS+1];
int PetDispenserIndex[MAXPLAYERS+1];

public void OnPluginStart()
{

}


public void CP_OnGetPart_Post(int client, int partIndex)
{
    if(partIndex == 10) // "파츠 멀티 슬릇"
    {
        CP_SetClientMaxSlot(client, CP_GetClientMaxSlot(client) + 2);
    }

    else if(partIndex == 2) // "체력 강화제"
    {
        TF2Attrib_SetByDefIndex(client, 26, 50);
        TF2Attrib_SetByDefIndex(client, 109, 0.9);
    }

    else if(partIndex == 3) // "근육 강화제"
    {
        TF2Attrib_SetByDefIndex(client, 6, 1.2);
        TF2Attrib_SetByDefIndex(client, 97, 0.8);
        TF2Attrib_SetByDefIndex(client, 69, 0.5);
    }

    else if(partIndex == 4) // "나노 제트팩"
    {
        TF2Attrib_SetByDefIndex(client, 610, 1.5);
        TF2Attrib_SetByDefIndex(client, 207, 0.2);
    }

    else if(partIndex == 5) // "나는 총알도 씹어먹는다!"
    {
        TF2Attrib_SetByDefIndex(client, 258, 1.0); //
        TF2Attrib_SetByDefIndex(client, 412, 0.5);
    }

    else if(partIndex == 6) // "무쇠 탄환"
    {
        TF2Attrib_SetByDefIndex(client, 389, 1.0);
        TF2Attrib_SetByDefIndex(client, 397, 5.0);

        TF2Attrib_SetByDefIndex(client, 2, 0.3);
        TF2Attrib_SetByDefIndex(client, 54, 0.85);
    }

    else if(partIndex == 7) // "히트박스를 제대로 활용하기"
    {
        TF2Attrib_SetByDefIndex(client, 51, 1.0);
    }

    else if(partIndex == 8) // "'진짜' 스파이"
    {


    }

    else if(partIndex == 9) // "휴대용 디스펜서"
    {

    }
}

public Action CP_OnSlotClear(int client, int partIndex, bool gotoNextRound)
{
    if(partIndex == 10)
    {
        CP_SetClientMaxSlot(client, CP_GetClientMaxSlot(client) - 2);
    }

    else if(partIndex == 9)
    {

    }
}

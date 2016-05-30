#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2items>
#include <morecolors>
#include <freak_fortress_2>

// 아나운서의 음성은 FF2에서 이미 다운로드 테이블에 올리고, 캐시해둠.

bool IsLastManStanding=false;

public Plugin:myinfo=
{
    name="Freak Fortress 2 : Deathmatch Mod",
    author="Nopied",
    description="....",
    version="0.1",
};

public void OnPluginStart()
{
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
    HookEvent("arena_round_start", OnRoundStart);
    //
}

public Action OnRoundStart(Handle event, const char[] name, bool dont)
{
    IsLastManStanding=false;
}
public Action OnPlayerDeath(Handle event, const char[] name, bool dont)
{
    if(!IsLastManStanding && CheckAlivePlayers() <= 1) // 라스트 맨 스탠딩
    {
        IsLastManStanding=true;
        int bosses[MAXPLAYERS+1];
        int top[3];
        int totalDamage;
        int bossCount;

        for(int client=1; client<=MaxClients; client++)
        {
            if(!IsValidClient(client)) // for bossCount.
    			continue;
            else if(IsBoss(client)){
                bosses[bossCount++]=client;
                continue;
            }
            else if(FF2_GetClientDamage(client)<=0 || IsBossTeam(client))
                continue;

    		if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[0]))
    		{
    			top[2]=top[1];
    			top[1]=top[0];
    			top[0]=client;
    		}
    		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[1]))
    		{
    			top[2]=top[1];
    			top[1]=client;
    		}
    		else if(FF2_GetClientDamage(client)>=FF2_GetClientDamage(top[2]))
    		{
    			top[2]=client;
    		}
        }

        for(int i; i<3; i++)
        {
            totalDamage+=FF2_GetClientDamage(top[i]);

/*            top[0]=FF2_GetClientDamage(top[0]);
            top[1]=top[0]+FF2_GetClientDamage(top[1]);
            top[2]=top[0]+top[1]+FF2_GetClientDamage(top[2]);
*/
        }

        int random=GetRandomInt(0, totalDamage);
        int winner;

        for(int i; i<3; i++) // OH this stupid code..
        {
            if(random > FF2_GetClientDamage(top[i]))
                continue;
            winner=top[i];
            break;
        }

        CPrintToChatAll("{olive}[FF2]{default} 확률: %N - %.1f | %N - %.1f | %N - %.1f\n %N님이 {red}강력한 무기{default}를 흭득하셨습니다!",
        top[0], float(FF2_GetClientDamage(top[0])%totalDamage),
        top[1], float(FF2_GetClientDamage(top[1])%totalDamage),
        top[2], float(FF2_GetClientDamage(top[2])%totalDamage),
        winner);

        for(int i; i<=bossCount; i++)
        {
            int boss=FF2_GetBossIndex(bosses[i]);
            int newhealth=10000/bossCount;

            if(FF2_GetBossHealth(boss) < newhealth)
                FF2_SetBossHealth(boss, newhealth);
        }

        TF2_RespawnPlayer(winner);
        FF2_SetFF2flags(client, FF2_GetFF2flags(client)|FF2FLAG_CLASSTIMERDISABLED);
    }
    return Plugin_Continue;
}

stock int SpawnWeapon(int client, char[] name, int index, int level, int quality, char[] attribute)
{
	Handle weapon=TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(weapon, name);
	TF2Items_SetItemIndex(weapon, index);
	TF2Items_SetLevel(weapon, level);
	TF2Items_SetQuality(weapon, quality);
	char attributes[32][32];
	int count = ExplodeString(attribute, ";", attributes, 32, 32);
	if(count%2!=0)
	{
		count--;
	}

	if(count>0)
	{
		TF2Items_SetNumAttributes(weapon, count/2);
		int i2=0;
		for(int i=0; i<count; i+=2)
		{
			int attrib=StringToInt(attributes[i]);
			if(attrib==0)
			{
				LogError("Bad weapon attribute passed: %s ; %s", attributes[i], attributes[i+1]);
				return -1;
			}
			TF2Items_SetAttribute(weapon, i2, attrib, StringToFloat(attributes[i+1]));
			i2++;
		}
	}
	else
	{
		TF2Items_SetNumAttributes(weapon, 0);
	}

	if(weapon==INVALID_HANDLE)
	{
		return -1;
	}
	int entity=TF2Items_GiveNamedItem(client, weapon);
	CloseHandle(weapon);
	EquipPlayerWeapon(client, entity);
	return entity;
}

stock bool IsValidClient(int client)
{
    return (0<client && client<=MaxClients && IsClientInGame(client));
}

stock int CheckAlivePlayers() // Without bosses. LOL
{
    int alive=0;

    for(int i=1; i<=MaxClients; i++)
    {
        if(IsValidClient(i) && IsPlayerAlive(i) && FF2_GetBossTeam() != GetClientTeam(client))
            alive++;
    }

    return alive;
}

stock bool IsBoss(int client)
{
    return FF2_GetBossIndex(client) != -1;
}

stock bool IsBossTeam(int client)
{
    return FF2_GetBossTeam() == GetClientTeam(client);
}

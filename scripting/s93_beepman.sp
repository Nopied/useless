/*
	Beepman's Abilities:

	Coded by SHADoW NiNE TR3S.

	Some code snippets from sarysa & pelipoika

	rage_scramble:
		arg0 - ability slot
		arg1 - distance
		arg2 - duration

	special_hijacksg
		arg1 - Button mode (1 - Reload, 2 - Special)
		arg2 - RAGE cost
		arg3 - Hijack range (default is 'ragedist' value)
		arg4 - Cooldown between uses (default 10 secs)
		arg5 - Grace period (before sentries are completely hijacked)
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2items>
#include <freak_fortress_2>
#include <freak_fortress_2_subplugin>

#pragma newdecls required

public Plugin myinfo = {
	name = "Freak Fortress 2: Beepman's Abilities",
	author = "SHADoW NiNE TR3S",
	description="THE HAAAAAAAAAAAAAX!",
	version="1.1",
};

#define SCRAMBLE "rage_scramble"
#define HIJACK "special_hijacksg"
#define INACTIVE 100000000.0
int currentBossIdx;
int enemies;
bool HasHijackAbility[MAXPLAYERS+1]=false;
bool scrambleKeys[MAXPLAYERS+1]=false;
bool IsOnCoolDown[MAXPLAYERS+1]=false;
float ragecost;
float LoopHudNotificationAt[MAXPLAYERS+1]=INACTIVE;
float UnscrambleAt[MAXPLAYERS+1]=INACTIVE;
float CooldownEndsIn[MAXPLAYERS+1]=INACTIVE;

public void OnPluginStart2() // No bugs pls
{
	HookEvent("teamplay_round_start", Event_RoundStart);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for(int clientIdx=1; clientIdx<=MaxClients; clientIdx++)
	{
		if(IsValidClient(clientIdx))
		{
			LoopHudNotificationAt[clientIdx]=INACTIVE;
			CooldownEndsIn[clientIdx]=INACTIVE;
			UnscrambleAt[clientIdx]=INACTIVE;
			HasHijackAbility[clientIdx]=false;
			scrambleKeys[clientIdx]=false;
			IsOnCoolDown[clientIdx]=false;
		}

		if(IsValidLivingPlayer(clientIdx))
		{
			int bossIdx=FF2_GetBossIndex(clientIdx); // Well this seems to be the solution to make it multi-boss friendly
			{
				if(bossIdx>=0 && FF2_HasAbility(bossIdx, this_plugin_name, HIJACK))
				{
					ragecost=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, HIJACK, 2);
					LoopHudNotificationAt[clientIdx]=GetEngineTime()+1.0;
					HasHijackAbility[clientIdx]=true;
					int entity = SpawnWeapon(clientIdx, "tf_weapon_builder", 28, 101, 5, "391 ; 2"); // Builder
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 0);
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 1);
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 1, _, 2);
					SetEntProp(entity, Prop_Send, "m_aBuildableObjectTypes", 0, _, 3);
				}
			}
		}
	}
}

public void FF2_OnAbility2(int boss,const char[] plugin_name,const char[] ability_name,int action)
{
	if(!FF2_IsFF2Enabled() || FF2_GetRoundState()!=1)
		return;
	int bossIdx=GetClientOfUserId(FF2_GetBossUserId(boss));
	if(!strcmp(ability_name, SCRAMBLE)) // Keyboard scramble
	{
		float pos[3], pos2[3], dist;
		float dist2=FF2_GetAbilityArgumentFloat(boss, this_plugin_name,ability_name, 1, FF2_GetRageDist(boss, this_plugin_name, ability_name));
		GetEntPropVector(bossIdx, Prop_Send, "m_vecOrigin", pos);

		enemies=0;
		for(int targetIdx=1;targetIdx<=MaxClients;targetIdx++)
		{
			if(IsValidLivingPlayer(targetIdx))
			{
				GetEntPropVector(targetIdx, Prop_Send, "m_vecOrigin", pos2);
				dist=GetVectorDistance(pos,pos2);
				if(dist<dist2 && GetClientTeam(targetIdx)!=FF2_GetBossTeam())
				{
					scrambleKeys[targetIdx]=true;
					UnscrambleAt[targetIdx]=GetEngineTime()+FF2_GetAbilityArgumentFloat(boss, this_plugin_name, ability_name, 2);
					enemies++;
				}
			}
		}
	}
}

public void OnGameFrame()
{
	TickTock(GetEngineTime());
}

public void TickTock(float currentTime)
{

	for(int clientIdx=1;clientIdx<=MaxClients;clientIdx++)
	{
		if(!IsValidClient(clientIdx)|| FF2_GetRoundState()!=1 || !FF2_IsFF2Enabled())
			continue;

		if(currentTime>=CooldownEndsIn[clientIdx])
		{
			if(IsBoss(clientIdx) && HasHijackAbility[clientIdx])
			{
				SetHudTextParams(-1.0, 1.0, 1.0, 0, 255, 0, 255);
				ShowHudText(clientIdx, -1, "Sentry hijack has now cooled down!");
				IsOnCoolDown[clientIdx]=false;
				CooldownEndsIn[clientIdx]=INACTIVE;
			}
		}

		if(currentTime>=LoopHudNotificationAt[clientIdx])
		{
			if(IsBoss(clientIdx) && FF2_GetBossCharge(FF2_GetBossIndex(clientIdx),0)>=ragecost && !IsOnCoolDown[clientIdx] && HasHijackAbility[clientIdx])
			{
					SetHudTextParams(-1.0, 1.0, 1.0, 0, 255, 0, 255);
					ShowHudText(clientIdx, -1, "재장전 키로 센트리를 납치할 수 있습니다! (분노 %i 소모)", RoundFloat(ragecost));
			}
			LoopHudNotificationAt[clientIdx]=GetEngineTime()+1.0;
		}

		if(currentTime>=UnscrambleAt[clientIdx])
		{
			if(enemies==1)
			{
				enemies=0;
			}
			scrambleKeys[clientIdx]=false;
			UnscrambleAt[clientIdx]=INACTIVE;
		}
	}
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	/*
	 * TO-DO: i really gotta start organizing this crap.
	 */

	// Sentry Hijack
	int bossIdx=FF2_GetBossIndex(client);
	if(bossIdx>=0 && FF2_HasAbility(bossIdx, this_plugin_name, HIJACK))
	{
		int buttonmode=FF2_GetAbilityArgument(bossIdx, this_plugin_name, HIJACK, 1); // Use RELOAD, or SPECIAL to activate ability
		if(buttonmode==2 &&(buttons & IN_ATTACK3) || buttonmode==1 && (buttons & IN_RELOAD))
		{
			if(IsOnCoolDown[client]) // Prevent ability from firing if ability is on cooldown
			{
				switch(buttonmode)
				{
					case 1: buttons &= ~IN_RELOAD;
					case 2: buttons &= ~IN_ATTACK3;
				}
				SetHudTextParams(-1.0, 0.96, 3.0, 255, 0, 0, 255);
				ShowHudText(client, -1, "능력 쿨타임으로 인해 사용할 수 없습니다!");
				return Plugin_Changed;
			}

			if(FF2_GetBossCharge(bossIdx, 0)<ragecost) // Not enough RAGE, prevent ability
			{
				switch(buttonmode)
				{
					case 1: buttons &= ~IN_RELOAD;
					case 2: buttons &= ~IN_ATTACK3;
				}
				SetHudTextParams(-1.0, 0.96, 3.0, 255, 0, 0, 255);
				ShowHudText(client, -1, "분노 %i 이상이어야 센트리 납치를 할 수 있습니다!", RoundFloat(ragecost));
				return Plugin_Changed;
			}

			// Else, we start the sentry hijack process

			float bossPosition[3], buildingPosition[3];
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", bossPosition);
			float duration=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, HIJACK, 1, 4.0); // Grace period between disabling and fully hijacking sentry

			int building, sentry;
			while((building=FindEntityByClassname(building, "obj_sentrygun"))!=-1) // Let's look for sentries to hijack
			{
				GetEntPropVector(building, Prop_Send, "m_vecOrigin", buildingPosition);
				if(GetVectorDistance(bossPosition, buildingPosition)<=FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, HIJACK, 3) && GetEntProp(building, Prop_Send, "m_iTeamNum")!=FF2_GetBossTeam())
				{
					SetEntProp(building, Prop_Data, "m_takedamage", 0);
					SetEntProp(building, Prop_Send, "m_bDisabled", 1);
					CreateTimer(duration, Timer_Hijack, EntIndexToEntRef(building));

					sentry++;
				}
			}

			if(sentry) // Let's not drain RAGE if no sentries are within range.
			{
				FF2_SetBossCharge(bossIdx, 0, FF2_GetBossCharge(bossIdx,0)-ragecost);
				currentBossIdx=client;
				IsOnCoolDown[client]=true;
				CooldownEndsIn[client]=GetEngineTime()+FF2_GetAbilityArgumentFloat(bossIdx, this_plugin_name, HIJACK, 4, 10.0);
				switch(buttonmode)
				{
					case 1: buttons &= ~IN_RELOAD;
					case 2: buttons &= ~IN_ATTACK3;
				}
				return Plugin_Changed;
			}

			return Plugin_Continue;
		}
		return Plugin_Continue;
	}

	// Keyboard scramble
	if(IsValidLivingPlayer(client) && scrambleKeys[client]) // Only affect raged players...
	{
		switch(GetRandomInt(1,27)) // Fake lag
		{
			case 1: GetRandomInt(1,2)==1 ? (buttons &= IN_ATTACK) : (buttons &= ~IN_ATTACK);
			case 2: GetRandomInt(1,2)==1 ? (buttons &= IN_ATTACK2) : (buttons &= ~IN_ATTACK2);
			case 3: GetRandomInt(1,2)==1 ? (buttons &= IN_ATTACK3) : (buttons &= ~IN_ATTACK3);
			case 4: GetRandomInt(1,2)==1 ? (buttons &= IN_JUMP) : (buttons &= ~IN_JUMP);
			case 5: GetRandomInt(1,2)==1 ? (buttons &= IN_DUCK) : (buttons &= ~IN_DUCK);
			case 6: GetRandomInt(1,2)==1 ? (buttons &= IN_FORWARD) : (buttons &= ~IN_FORWARD);
			case 7: GetRandomInt(1,2)==1 ? (buttons &= IN_BACK) : (buttons &= ~IN_BACK);
			case 8: GetRandomInt(1,2)==1 ? (buttons &= IN_USE) : (buttons &= ~IN_USE);
			case 9: GetRandomInt(1,2)==1 ? (buttons &= IN_CANCEL) : (buttons &= ~IN_CANCEL);
			case 10: GetRandomInt(1,2)==1 ? (buttons &= IN_LEFT) : (buttons &= ~IN_LEFT);
			case 11: GetRandomInt(1,2)==1 ? (buttons &= IN_RIGHT) : (buttons &= ~IN_RIGHT);
			case 12: GetRandomInt(1,2)==1 ? (buttons &= IN_MOVELEFT) : (buttons &= ~IN_MOVELEFT);
			case 13: GetRandomInt(1,2)==1 ? (buttons &= IN_MOVERIGHT) : (buttons &= ~IN_MOVERIGHT);
			case 14: GetRandomInt(1,2)==1 ? (buttons &= IN_RUN) : (buttons &= ~IN_RUN);
			case 15: GetRandomInt(1,2)==1 ? (buttons &= IN_RELOAD) : (buttons &= ~IN_RELOAD);
			case 16: GetRandomInt(1,2)==1 ? (buttons &= IN_ALT1) : (buttons &= ~IN_ALT1);
			case 17: GetRandomInt(1,2)==1 ? (buttons &= IN_ALT2) : (buttons &= ~IN_ALT2);
			case 18: GetRandomInt(1,2)==1 ? (buttons &= IN_SCORE) : (buttons &= ~IN_SCORE);
			case 19: GetRandomInt(1,2)==1 ? (buttons &= IN_WALK) : (buttons &= ~IN_WALK);
			case 20: GetRandomInt(1,2)==1 ? (buttons &= IN_ZOOM) : (buttons &= ~IN_ZOOM);
			case 21: GetRandomInt(1,2)==1 ? (buttons &= IN_WEAPON1) : (buttons &= ~IN_WEAPON1);
			case 22: GetRandomInt(1,2)==1 ? (buttons &= IN_WEAPON2) : (buttons &= ~IN_WEAPON2);
			case 23: GetRandomInt(1,2)==1 ? (buttons &= IN_BULLRUSH) : (buttons &= ~IN_BULLRUSH);
			case 24: GetRandomInt(1,2)==1 ? (buttons &= IN_GRENADE1) : (buttons &= ~IN_GRENADE1);
			case 25: GetRandomInt(1,2)==1 ? (buttons &= IN_GRENADE2) : (buttons &= ~IN_GRENADE2);
			case 26: return Plugin_Handled;
			case 27: return Plugin_Continue;
		}
		switch(GetRandomInt(1,4)) // More fake lag rage
		{
			case 1: return Plugin_Handled;
			case 2: return Plugin_Continue;
			case 3: return Plugin_Handled;
			case 4: return Plugin_Continue;
		}
	}
	return Plugin_Continue;
}

public Action Timer_Hijack(Handle timer, any buildingIdx) // Grace period ends here
{
	int owner;
	int building=EntRefToEntIndex(buildingIdx);
	if(FF2_GetRoundState()==1 && building>MaxClients)
	{
		if ((owner = GetEntDataEnt2(building, FindSendPropInfo("CObjectSentrygun", "m_hBuilder"))) != -1)
		{
			SetEntProp(building, Prop_Data, "m_takedamage", 2);
			SetEntProp(building, Prop_Send, "m_bDisabled", 0);
			owner=currentBossIdx;
			float location[3], angle[3];
			GetEntDataVector(building, FindSendPropInfo("CObjectSentrygun","m_vecOrigin"), location);
			GetEntDataVector(building, FindSendPropInfo("CObjectSentrygun","m_angRotation"), angle);
			TF2_BuildSentry(owner, location, angle, GetEntProp(building, Prop_Send, "m_iUpgradeLevel"), GetEntProp(building, Prop_Send, "m_bMiniBuilding") ? true : false, GetEntProp(building, Prop_Send, "m_bMiniBuilding") ? true : false);
			AcceptEntityInput(building, "kill");
		}
	}
	return Plugin_Continue;
}

//Stock from Pelipoika (code from sentryfun)
stock void TF2_BuildSentry(int builder, float fOrigin[3], float fAngle[3], int level, bool mini=false, bool disposable=false, bool carried=false, int flags=4)
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
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
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
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
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
			SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
			SetEntProp(sentry, Prop_Send, "m_nSkin", GetClientTeam(builder) - 2);
			DispatchSpawn(sentry);
		}
	}
}

// We need to spawn tf_weapon_builder, hence this.
stock int SpawnWeapon(int client, char[] name, int index, int level, int qual, char[] att)
{
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL|FORCE_GENERATION);
	TF2Items_SetClassname(hWeapon, name);
	TF2Items_SetItemIndex(hWeapon, index);
	TF2Items_SetLevel(hWeapon, level);
	TF2Items_SetQuality(hWeapon, qual);
	char atts[32][32];
	int count = ExplodeString(att, " ; ", atts, 32, 32);
	if (count > 0)
	{
		TF2Items_SetNumAttributes(hWeapon, count/2);
		int i2 = 0;
		for (int i = 0; i < count; i+=2)
		{
			TF2Items_SetAttribute(hWeapon, i2, StringToInt(atts[i]), StringToFloat(atts[i+1]));
			i2++;
		}
	}
	else
		TF2Items_SetNumAttributes(hWeapon, 0);
	if (hWeapon==null)
		return -1;
	int entity = TF2Items_GiveNamedItem(client, hWeapon);
	delete hWeapon;
	EquipPlayerWeapon(client, entity);
	return entity;
}

// Check for valid boss
stock bool IsBoss(int client)
{
	if(FF2_GetBossIndex(client)==-1) return false;
	if(GetClientTeam(client)!=FF2_GetBossTeam()) return false;
	return true;
}


// Stocks below by sarysa
stock bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return IsClientInGame(client);
}

stock bool IsValidLivingPlayer(int client)
{
	if (client <= 0 || client > MaxClients)
		return false;

	return IsClientInGame(client) && IsPlayerAlive(client);
}

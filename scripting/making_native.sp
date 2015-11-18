
// Navive 선언

CreateNative("FF2_SetDamage", Native_SetDamage);
CreateNative("FF2_GetCharaterName", Native_GetCharacterName);
CreateNative("FF2_SetCharaterName", Native_SetCharacterName);

// Native 역할

public Native_SetDamage(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new damage = GetNativeCell(2);
	
	Damage[client] = damage;	
}

public Native_GetCharacterName(Handle:plugin, numParams)
{
	new Special = GetNativeCell(1);
	new String:bossName[64];
	
	KvRewind(BossKV[Special]);
	KvGetString(BossKV[Special], "name", bossName, sizeof(bossName), "=Failed name=");
	
	
	
	
}

public Native_SetCharacterName(Handle:plugin, numParams)
{
	
}

// inc 파일에 작성할 것


// Navive 선언

CreateNative("FF2_SetClientDamage", Native_SetDamage);
CreateNative("FF2_GetCharaterName", Native_GetCharacterName);

// 케릭터 네임쪽은 나중에.

// Native 역할

public Native_SetClientDamage(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	Damage[client] = GetNativeCell(2);
}

public Native_GetCharacterName(Handle:plugin, numParams)
{
	new Special = GetNativeCell(1);
	new String:bossName[64];
	
	KvRewind(BossKV[Special]);
	KvGetString(BossKV[Special], "name", bossName, sizeof(bossName), "=Failed name=");
	
	
	
	
}

// inc 파일에 작성할 것

Native FF2_SetClientDamage(client, damage);

MarkNativeAsOptional("FF2_SetClientDamage");

// 아.. 컴파일 좀 하고싶어요 ㅠㅠ

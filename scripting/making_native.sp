
// Navive 선언

CreateNative("FF2_SetClientDamage", Native_SetDamage);

// 케릭터 네임쪽은 나중에.

// Native 역할

public Native_SetDamage(Handle:plugin, numParams)
{
	Damage[GetNativeCell(1)] = GetNativeCell(2);
}


// inc 파일에 작성할 것

/**
 * Sets damage dealt by this client
 *
 * @param client 	Client's index
 * @param damage	New damage dealt
 * @noreturn
 */
native FF2_SetClientDamage(client, damage);

MarkNativeAsOptional("FF2_SetClientDamage");



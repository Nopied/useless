#if defined _beskeleton_included_
  #endinput
#endif
#define _beskeleton_included_

/**
 * Makes a client The Skeleton King.
 *
 * @param client			Index of the client to set.
 * @noreturn
 */
native BeSkeletonKing_MakeSkeleton(client);

/**
 * Returns whether or not the client is a Skeleton King.
 *
 * @param client			Index of the client to set.
 * @return true if client is skeleton, false otherwise.
 */
native BeSkeletonKing_IsSkeleton(client);

public SharedPlugin:__pl_beskeleton = 
{
	name = "beskeleton",
	file = "beskeleton.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public __pl_beskeleton_SetNTVOptional()
{
	MarkNativeAsOptional("BeSkeletonKing_MakeSkeleton");
	MarkNativeAsOptional("BeSkeletonKing_IsSkeleton");
}
#endif
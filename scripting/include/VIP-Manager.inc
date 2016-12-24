#if defined _vipmanager_included
  #endinput
#endif
#define _vipmanager_included

public SharedPlugin __pl_vipmanager = {
  name = "VIP-Manager",
  file = "VIP-Manager.smx",
#if defined REQUIRE_PLUGIN
  required = 1
#else
  required = 0
#endif
};

/**
  * Called everytime a VIP is added.
  *
  * @param admin          Index of admin, who has added the VIP.
  * @param name           Name of the VIP.
  * @param steamId        SteamId of the VIP.
  * @param minutes        Time the player is VIP.
  *
  */
forward void OnVIPAdded(int admin, char[] name, char[] steamId, int minutes);

/**
  * Called everytime a VIP is removed.
  *
  * @param admin          Index of admin, who has removed the VIP.
  * @param name           Name of the removed VIP.
  * @param steamId        SteamId of the removed VIP.
  * @param reason         Reason for removing VIP.
  *
  */
forward void OnVIPRemoved(int admin, char[] name, char[] steamId, char[] reason);

/**
  * Called everytime the duration for a VIP has changed.
  *
  * @param admin          Index of admin, who has changed the duration for a VIP.
  * @param name           Name of the VIP.
  * @param steamId        SteamId of the VIP.
  * @param mode           The mode used for the change. Can be 'set', 'add' or 'sub'.
  * @param oldDuration    Old value of the duration.
  * @param duration       New value of the duration.
  *
  */
forward void OnVIPDurationChanged(int admin, char[] name, char[] steamId, char[] mode, int oldDuration, int duration);

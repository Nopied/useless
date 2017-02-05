#if defined _InspectControl_included
 #endinput
#endif
#define _InspectControl_included

/**
 * Called whenever the player inspects a weapon.
 *
 * @param weapon				Weapon being inspected index.
 * @param stage					Weapon inspect stage.
 * @param originalactivity		The activity the game wants to use.
 * @param newactivity			Your new activity to use.
 *
 * @return 						Return Plugin_Continue to use the game result. Return anything else to use the value set in result.
 */
forward Action IC_OnGetInspectActivity(int weapon, int stage, int originalactivity, int &newactivity);

/**
 * Do not edit below this line!
 */
public Extension __ext_InspectControl = 
{
	name = "InspectControl",
	file = "InspectControl.ext",
#if defined AUTOLOAD_EXTENSIONS
	autoload = 1,
#else
	autoload = 0,
#endif
#if defined REQUIRE_EXTENSIONS
	required = 1,
#else
	required = 0,
#endif
};
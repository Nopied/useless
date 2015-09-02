#include <sourcemod>
#include <files>

new String:Map[128];

public Plugin:myinfo = {
	name = "Plugin works custom maps!",
	description = "For Ch.ZBK",
	author = "Tean Potry: Nopied◎",
};

public OnPluginStart()
{
	GetCurrentMap(Map, sizeof(Map));
	
}

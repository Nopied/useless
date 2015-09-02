#include <sourcemod>
#include <files>

new Handle:CheckMaps;

public Plugin:myinfo = {
	name = "Plugin works custom maps!",
	description = "For Ch.ZBK",
	author = "Tean Potry: Nopied◎",
};

public OnPluginStart()
{
	BuildPath(Path_SM, );
	CheckMaps = OpenDirectory(d)
}

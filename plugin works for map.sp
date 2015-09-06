#include <sourcemod>

public Plugin:myinfo = {
	name = "Plugin works for maps!",
	description = "",
	author = "Tean Potry: Nopied◎",
};

public OnPluginStart()
{
	PrintToServer("[PWCM] HELLO!");
}

public OnMapStart()
{
	new String:config[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, config, sizeof(config), "configs/mappluginslist.cfg");
	
	if(!FileExists(config)) PrintToServer("[PWCM]ERROR! mappluginslist.cfg not found!");
	else
	{
		new Handle:KV = CreateKeyValues("mappluginslist");
		FileToKeyValues(KV, config);
		KvRewind(KV);
		if(KvGotoFirstSubKey(KV))
		{
			new String:Map[PLATFORM_MAX_PATH];
			new String:foldername[PLATFORM_MAX_PATH];
			new String:item[8];
			
			do
			{
				KvGetSectionName(KV, foldername, sizeof(foldername));
				
				for(new i=1; ; i++)
				{
					Format(item, sizeof(item), "%d", i);
					KvGetString(KV, item, Map, sizeof(Map), "");
					
					if(Map[0] == '\0') break;
					else
					{
						result(foldername, Map);
					}
				}
			}
			while(KvGotoNextKey(KV))
		}
		else PrintToServer("[PWCM] ERROR! NO SUBKEY FOUND!");
		
		CloseHandle(KV);
	}
}

public result(const String:foldername[], const String:Map[])
{
	new String:plugin[PLATFORM_MAX_PATH];
	new String:filename[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, plugin, sizeof(plugin), "plugins/%s", foldername);
	
	if(!DirExists(plugin)) 
	{
		PrintToServer("[PWCM] ERROR! %s folder not found.", foldername);
	}
	else 
	{
		new String:currentmap[50];
		GetCurrentMap(currentmap, sizeof(currentmap));
		Format(currentmap, sizeof(currentmap), "%s.bsp", currentmap);
		
		
		new Handle:dir = OpenDirectory(plugin);
		decl FileType:filetype;
		while(ReadDirEntry(dir, filename, PLATFORM_MAX_PATH, filetype))
		{
			if(filetype==FileType_File && StrContains(filename, ".smx"))
			{
				if(StrEqual(Map, currentmap))
				{
					InsertServerCommand("sm plugins load %s/%s", foldername, filename);
				}
				else 
				{
					InsertServerCommand("sm plugins unload %s/%s", foldername, filename);
				}
			}	
		}
	}	
}


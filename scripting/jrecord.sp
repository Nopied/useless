#include <sourcemod>
#include <sdktools>
#include <record_client>

int clientRecording;
int maxByte;

Handle outputFile;

char recordingFilePath[PLATFORM_MAX_PATH];
char outputFilePath[PLATFORM_MAX_PATH];

public Plugin:myinfo = {
	name = "JRecord",
	author = "talkingmelon",
	description = "Records to csv",
	version = ".1",
	url = "http://www.tf2rj.com"
};


public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, err_max)
{
	CreateNative("Record_StartRecord", Native_StartRecord);
    CreateNative("Record_StopRecord", Native_StopRecord);
	CreateNative("Record_GetStringData", Native_GetStringData);

	return APLRes_Success;
}

public Native_StartRecord(Handle plugin, numParams)
{
	char path[PLATFORM_MAX_PATH];
	GetNativeString(3, path, sizeof(path));

	return StartRecord(GetNativeCell(1), GetNativeCell(2), path);
}

public Native_StopRecord(Handle plugin, numParams)
{
	StopRecord();
}

public Native_GetStringData(Handle plugin, numParams)
{
	char data[120];
	GetNativeString(1, data, sizeof(data));

	return _:GetStringData(data);
}


bool StartRecord(int client, int byte, char[] pathAndFilename)
{
	if(MaxClients < client || 0 > client || !IsClientInGame(client) || IsClientInGame(clientRecording))
		return false;

	clientRecording = client;
	maxByte = byte;

	decl String:path[PLATFORM_MAX_PATH];

	BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "data/%s", pathAndFilename);
	strcopy(outputFilePath, sizeof(outputFilePath), path);

	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"recording/%s", pathAndFilename);
	strcopy(recordingFilePath, sizeof(recordingFilePath), path);

	LogMessage("녹화 중... (%s)", path);

	outputFile = OpenFile(path, "w+");

	if(outputFile == INVALID_HANDLE){
		LogError("An error occured while creating the file");
		clientRecording = 0;
		return false;
	}else{
		WriteFileString(outputFile, "xloc,yloc,zloc,xvel,yvel,zvel,pitch,yaw,roll,buttons\n", false);
	}

	return true;
}

void StopRecord()
{
	clientRecording = 0;
	if(outputFile !=  INVALID_HANDLE){
		CloseHandle(outputFile);
		strcopy(outputFilePath, sizeof(outputFilePath), "");
		LogMessage("녹화가 멈췄습니다.");
	}


}

public OnPluginStart(){

	// RegConsoleCmd("sm_rec", Command_Record, "Records");
	// RegConsoleCmd("sm_st", Command_StopRecord, "Stops");
	// RegConsoleCmd("sm_tog", Command_ToggleRecord, "Stops");

}

public Action:Command_Record(client, args){
	clientRecording = client;

	decl String:path[PLATFORM_MAX_PATH];
	decl String:dateTime[1024];
	new time = GetTime();
	FormatTime(dateTime, sizeof(dateTime), "%y%m%d_%H%M%S", time);
	BuildPath(Path_SM,path,PLATFORM_MAX_PATH,"REC %s.csv", dateTime);
	PrintToChat(client,path);
	outputFile = OpenFile(path, "w+");

	if(outputFile == INVALID_HANDLE){
		LogError("An error occured while creating the file");
		clientRecording = 0;
	}else{
		WriteFileString(outputFile, "xloc,yloc,zloc,xvel,yvel,zvel,pitch,yaw,roll,buttons\n", false);
	}
}


public Action:Command_StopRecord(client, args){
	clientRecording = 0;
	if(outputFile !=  INVALID_HANDLE){
		CloseHandle(outputFile);
	}
	PrintToChat(client, "Stopped Recording");
}

public Action:Command_ToggleRecord(client, args){
	if(clientRecording){
		Command_StopRecord(client, 0);
	}else{
		Command_Record(client, 0);
	}
}


public OnGameFrame(){
	if(0 < clientRecording && clientRecording <= MaxClients && IsClientInGame(clientRecording) && IsPlayerAlive(clientRecording)
	&& FileSize(recordingFilePath) < maxByte){ //
		decl Float:angles[3];
		decl Float:velocity[3];
		decl Float:position[3];

		int buttons;
		// new bool:at, bool:j, bool:d;

		GetEntPropVector(clientRecording, Prop_Data, "m_vecOrigin", position);
		GetClientEyeAngles(clientRecording, angles);
		GetEntPropVector(clientRecording, Prop_Data, "m_vecVelocity", velocity);

		buttons = GetClientButtons(clientRecording);
		/*
		if(b & IN_ATTACK){
			at=true;
		}
		if(b & IN_JUMP){
			j=true;
		}
		if(b & IN_DUCK){
			d=true;
		}

		new String:buttonBuffer[16];
		if(at){
			Format(buttonBuffer, sizeof(buttonBuffer), "1,", buttonBuffer);
		}else{
			Format(buttonBuffer, sizeof(buttonBuffer), "0,", buttonBuffer);
		}
		if(j){
			Format(buttonBuffer, sizeof(buttonBuffer), "%s1,", buttonBuffer);
		}else{
			Format(buttonBuffer, sizeof(buttonBuffer), "%s0,", buttonBuffer);
		}
		if(d){
			Format(buttonBuffer, sizeof(buttonBuffer), "%s1", buttonBuffer);
		}else{
			Format(buttonBuffer, sizeof(buttonBuffer), "%s0", buttonBuffer);
		}
		*/


		new String:buffer[512];
		Format(buffer, sizeof(buffer), "%f,%f,%f,%f,%f,%f,%f,%f,%f,%i\n",
		position[0],
		position[1],
		position[2],
		velocity[0],
		velocity[1],
		velocity[2],
		angles[0],
		angles[1],
		angles[2],
		buttons);

		WriteFileString(outputFile, buffer, false);
	}
	else
	{
		StopRecord();
	}
}

Handle GetStringData(char[] data)
{
	char dataString[10][20];
	ExplodeString(data, ",", dataString, sizeof(dataString), sizeof(dataString[]), false);

	Handle datapack = CreateDataPack();

	WritePackCell(datapack, StringToFloat(dataString[0]));
	WritePackCell(datapack, StringToFloat(dataString[1]));
	WritePackCell(datapack, StringToFloat(dataString[2]));
	WritePackCell(datapack, StringToFloat(dataString[3]));
	WritePackCell(datapack, StringToFloat(dataString[4]));
	WritePackCell(datapack, StringToFloat(dataString[5]));
	WritePackCell(datapack, StringToFloat(dataString[6]));
	WritePackCell(datapack, StringToFloat(dataString[7]));
	WritePackCell(datapack, StringToFloat(dataString[8]));
	WritePackCell(datapack, StringToInt(dataString[9]));

	ResetPack(datapack);

	return datapack;
}

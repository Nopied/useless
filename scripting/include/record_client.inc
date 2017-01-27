

// false = 이미 녹화가 진행 중인 경우, 클라이언트가 정상이 아님
native bool Record_StartRecord(int client, int megaByte, char[] pathAndFilename);

native void Record_StopRecord();


/*
* 0 - position[0]
* 1 - position[1]
* 2 - position[2]
* 3 - velocity[0]
* 4 - velocity[1]
* 5 - velocity[2]
* 6 - angles[0]
* 7 - angles[1]
* 8 - angles[2]
* 9 - buttons (int)
*
*
*
*/
native Handle Record_GetStringData(char[] data);

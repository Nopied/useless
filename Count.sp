#include <sourcemod>

new bool:IsCounddown=false;

pubilc Plugin:myinfo = {
name= "Countdown",
description="",
author="Team Potry : Nopied◎",
}

pubilc OnPluginStart()
{
 RegAdminCmd("5", Command_Count, ADMFLAG_CHEATS, "");
}

pubilc Action:Command_Count(client, arg)
{
 if(IsCountdown){
 PrintToChat(client, "[SM] 타이머가 진행 중입니다.");
 }
 else{
 IsCountdown = true;
 CreateTimer(1.0, Timer_Count, 5, TIMER_REPEAT);
 }
}

pubilc Action:Timer_Count(Handle:timer, any:timeleft)
{
 if(timeleft <= 0)
 {
 PrintToChatAll("[SM] 타이머 끝!");
 return Plugin_Stop;
 }
 else
 {
 PrintToChatAll("[SM] 남은 시간: %d", timeleft);
 timeleft--;
 return Plugin_Continue;
 }
}

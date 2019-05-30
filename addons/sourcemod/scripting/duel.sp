#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "DiogoOnAir" 
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <smlib>

#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")

#pragma newdecls required
#pragma tabsize 0

int vote1 = 0;
int vote2 = 0;
int vote3 = 0;
int vote4 = 0;
int vote5 = 0;

bool InNoscope = false;
bool g_DuelMusic = false;

float teleloc[3];

char g_PluginPrefix[64];

ConVar g_KnifeDuelPlayerSpeed;
ConVar g_KnifeDuelGravity;
ConVar g_hPluginPrefix;

public Plugin myinfo = 
{
	name = "1V1 Duel",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/diogo218dv"
};

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_death", Event_PlayerDeath);
	
	g_KnifeDuelPlayerSpeed = CreateConVar("duel_knifespeed", "1.8", "Define players speed when they are in a speed knife duel");
	g_KnifeDuelGravity = CreateConVar("duel_knifegravity", "0.3", "Define the players gravity when they are in a low gravity knife duel");
	g_hPluginPrefix = CreateConVar("duel_chatprefix", "{lime}Duel {default}|", "Determines the prefix used for chat messages", FCVAR_NOTIFY);
	
	LoadTranslations("duel_phrases.txt");
	AutoExecConfig(true, "Duel");
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnConfigsExecuted()
{
	GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
}

//Hooks

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/duel/sound1.mp3");
	PrecacheSound("duel/sound1.mp3");
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_PreThink, PreThink);
}

public Action PreThink(int client)
{
	if(IsPlayerAlive(client))
	{
		int  weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if(!IsValidEdict(weapon))
			return Plugin_Continue;

		char item[64];
		GetEdictClassname(weapon, item, sizeof(item)); 
		if(InNoscope && StrEqual(item, "weapon_awp"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9); 
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    vote1 = 0;
    vote2 = 0;
    vote3 = 0;
    vote4 = 0;
    vote5 = 0;
    InNoscope = false;
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    if(g_DuelMusic)
    {
       for (int i = 0; i <= MaxClients; i++)
       {
       	g_DuelMusic = false;
    	StopSound(i, SNDCHAN_AUTO, "duel/sound1.mp3");
       }
    }
    ServerCommand("sv_infinite_ammo 0");
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(AliveTPlayers() == 1 && AliveCTPlayers() == 1)
	{
	  for (int i = 0; i <= MaxClients; i++)
	  {
	  	ShowDuelMenu(i);
	  }
    }
}

//Duel

public void ShowDuelMenu(int client)
{
     if(IsValidClient(client) && IsPlayerAlive(client))
     {
        Menu menu = new Menu(DuelMenu);

		menu.SetTitle("Duel Menu");
		menu.AddItem("AN", "AWP NoScope");
		menu.AddItem("KLG", "Low Gravity + Knife");
		menu.AddItem("SK", "Speed + Knife");
		menu.AddItem("D1HP", "Decoy + 1 HP");
		menu.AddItem("ND", "No Duel");
		menu.ExitButton = false;
		menu.Display(client, MENU_TIME_FOREVER);
	 }
}

public int DuelMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

		    if (StrEqual(info, "AN"))
			{
				VoteD1();
			}
			else if (StrEqual(info, "KLG"))
			{
				VoteD2();
			}
			else if (StrEqual(info, "D1HP"))
			{
				VoteD3();
			}
			else if (StrEqual(info, "SK"))
			{
				VoteD4();
			}
			else if (StrEqual(info, "ND"))
			{
				VoteD5();
			}
		}

		case MenuAction_End:{delete menu;}
	}

	return 0;
}

public void VoteD1()
{
	vote1 += 1;
	checkvotes();
}

public void VoteD2()
{
	vote2 += 1;
	checkvotes();
}

public void VoteD3()
{
	vote3 += 1;
	checkvotes();
}

public void VoteD4()
{
	vote4 += 1;
	checkvotes();
}

public void VoteD5()
{
	vote5 += 1;
	checkvotes();
}

public void checkvotes()
{
  	if(vote1 == 2)
	{
		   AWNoscope();
    }
    else if(vote1 == 1)
    {
    	int number = GetRandomInt(1, 2);
    	if (vote2 == 1)
    	{
    		if(number == 1)
    		{
    			AWNoscope();
    	    }
    	    else
    	    {
    	    	KnifeLowGravity();
    	    }
        }
        else if (vote3 == 1)
        {
        	if(number == 1)
    		{
    			AWNoscope();
    	    }
    	    else
    	    {
    	    	Decoy1HP();
    	    }
        }
        else if (vote4 == 1)
        {
        	if(number == 1)
    		{
    			AWNoscope();
    	    }
    	    else
    	    {
    	    	SpeedKnife();
    	    }
        }
        else if (vote5 == 1)
        {
        	NoDuel();
        }
    }
    
    else if(vote2 == 2)
	{
		   KnifeLowGravity();
    }
    else if(vote2 == 1)
    {
    	int number = GetRandomInt(1, 2);
    	if (vote2 == 1)
    	{
    		if(number == 1)
    		{
    			KnifeLowGravity();
    	    }
    	    else
    	    {
    	    	AWNoscope();
    	    }
        }
        else if (vote3 == 1)
        {
        	if(number == 1)
    		{
    			KnifeLowGravity();
    	    }
    	    else
    	    {
    	    	Decoy1HP();
    	    }
        }
        else if (vote4 == 1)
        {
        	if(number == 1)
    		{
    			KnifeLowGravity();
    	    }
    	    else
    	    {
    	    	SpeedKnife();
    	    }
        }
        else if (vote5 == 1)
        {
        	NoDuel();
        }
    }
    else if(vote3 == 2)
	{
		   Decoy1HP();
    }
    else if(vote3 == 1)
    {
    	int number = GetRandomInt(1, 2);
    	if (vote1 == 1)
    	{
    		if(number == 1)
    		{
    			Decoy1HP();
    	    }
    	    else
    	    {
    	    	AWNoscope();
    	    }
        }
        else if (vote2 == 1)
        {
        	if(number == 1)
    		{
    			Decoy1HP();
    	    }
    	    else
    	    {
    	    	KnifeLowGravity();
    	    }
        }
        else if (vote4 == 1)
        {
        	if(number == 1)
    		{
    			Decoy1HP();
    	    }
    	    else
    	    {
    	    	SpeedKnife();
    	    }
        }
        else if (vote5 == 1)
        {
        	NoDuel();
        }
    }
    else if(vote4 == 2)
	{
		   Decoy1HP();
    }
    else if(vote4 == 1)
    {
    	int number = GetRandomInt(1, 2);
    	if (vote1 == 1)
    	{
    		if(number == 1)
    		{
    			SpeedKnife();
    	    }
    	    else
    	    {
    	    	AWNoscope();
    	    }
        }
        else if (vote2 == 1)
        {
        	if(number == 1)
    		{
    			SpeedKnife();
    	    }
    	    else
    	    {
    	    	KnifeLowGravity();
    	    }
        }
        else if (vote3 == 1)
        {
        	if(number == 1)
    		{
    			SpeedKnife();
    	    }
    	    else
    	    {
    	    	Decoy1HP();
    	    }
        }
        else if (vote5 == 1)
        {
        	NoDuel();
        }
    }
    else if (vote5 == 2)
    {
        	NoDuel();
    }
}

//Some Stocks and Actions

public Action TeleportPlayers()
{ 
   for (int i = 0; i <= MaxClients; i++)
	if(IsValidClient(i) && IsPlayerAlive(i))
	{
		float ctvec[3];
		float tvec[3];
		float distance[1];
		if(GetClientTeam(i) == 2)
		{
			GetClientAbsOrigin(i, tvec);
	    }
	    else if(GetClientTeam(i) == 3)
		{
			GetClientAbsOrigin(i, ctvec);
	    }
		distance[0] = GetVectorDistance(ctvec, tvec, true);
		if (distance[0] >= 600000.0)
		{
			teleloc = ctvec;
			CreateTimer(1.0, DoTp);
		}
	}
}

public Action DoTp(Handle timer)
{
  for (int i = 0; i <= MaxClients; i++)
  {
	if(GetClientTeam(i) == 2 && IsValidClient(i) && IsPlayerAlive(i))
	{
		TeleportEntity(i, teleloc, NULL_VECTOR, NULL_VECTOR);
	}
  }
}

public Action AWNoscope()
{ 
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    TeleportPlayers();
	InNoscope = true;
    Client_RemoveAllWeapons(i);
    char weapon = GivePlayerItem(i, "weapon_awp");
    SetEntProp(weapon, Prop_Data, "m_iClip1", 1000);
  }
  EmitSoundToAll("duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
  g_DuelMusic = true;
  CPrintToChatAll("%t", "AwNoscope", g_PluginPrefix);
}

public Action KnifeLowGravity()
{ 
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    TeleportPlayers();
    Client_RemoveAllWeapons(i);
    GivePlayerItem(i, "weapon_knife");
    SetGravity(i, g_KnifeDuelGravity.FloatValue); 
  }
  EmitSoundToAll("duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
  g_DuelMusic = true;
  CPrintToChatAll("%t", "KnifeLowGravity", g_PluginPrefix);
}

public Action SpeedKnife()
{ 
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    TeleportPlayers();
    Client_RemoveAllWeapons(i);
    GivePlayerItem(i, "weapon_knife");
    SetSpeed(i, g_KnifeDuelPlayerSpeed.FloatValue);
  }
  EmitSoundToAll("duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
  g_DuelMusic = true;
  CPrintToChatAll("%t", "SpeedKnife", g_PluginPrefix);
}

public Action Decoy1HP()
{ 
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    TeleportPlayers();
    Client_RemoveAllWeapons(i);
    ServerCommand("sv_infinite_ammo 1");
    SetEntityHealth(i, 1);
    GivePlayerItem(i, "weapon_decoy");
    SetGravity(i, g_KnifeDuelGravity.FloatValue); 
  }
  EmitSoundToAll("duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
  g_DuelMusic = true;
  CPrintToChatAll("%t", "Decoy1HP", g_PluginPrefix);
}

public Action NoDuel()
{ 
    CPrintToChatAll("%t", "DuelCancelled", g_PluginPrefix);
}

stock bool IsValidClient(int client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}

public int AliveTPlayers()
{
	int g_Terrorists = 0;
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 2)
		{
			g_Terrorists++;
		}
	}
	return g_Terrorists;
}

public int AliveCTPlayers()
{
	int g_CTerrorists = 0;
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i) && IsPlayerAlive(i) && GetClientTeam(i) == 3)
		{
			g_CTerrorists++;
		}
	}
	return g_CTerrorists;
}

public void SetSpeed(int client, float speed)
{
    SetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue", speed);
}

public void SetGravity(int client, float amount)
{
    SetEntityGravity(client, amount / GetEntPropFloat(client, Prop_Data, "m_flLaggedMovementValue"));
}
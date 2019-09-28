#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "DiogoOnAir" 
#define PLUGIN_VERSION "1.8"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <clientprefs>
#include <multicolors>
#include <cstrike>
#include <smlib>

#define g_WeaponParent FindSendPropInfo("CBaseCombatWeapon", "m_hOwnerEntity");
#define m_flNextSecondaryAttack FindSendPropInfo("CBaseCombatWeapon", "m_flNextSecondaryAttack")

#pragma tabsize 0

int voteyes = 0;
int voteno = 0;

bool InNoscope = false;
bool g_DuelMusic = false;
bool g_Deagle1TapDuel = false;
bool g_Decoyduel = false;
bool g_zeusduel = false;
int g_EnableMusicDuel[MAXPLAYERS + 1];
int g_VotePref[MAXPLAYERS + 1];

char g_PluginPrefix[64];
char g_soundmode[64];

ConVar g_KnifeDuelPlayerSpeed;
ConVar g_KnifeDuelGravity;
ConVar g_hPluginPrefix;
ConVar g_MinPlayers; 
ConVar g_MaxDuelTime; 

Handle DuelTimer;
Handle DuelCookie;
Handle PrefVote;

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
	HookEvent("weapon_fire", Event_WeaponFire, EventHookMode_Post);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
	
	g_KnifeDuelPlayerSpeed = CreateConVar("duel_knifespeed", "1.8", "Define players speed when they are in a speed knife duel");
	g_KnifeDuelGravity = CreateConVar("duel_knifegravity", "0.3", "Define the players gravity when they are in a low gravity knife duel");
	g_MinPlayers = CreateConVar("duel_minplayers", "3", "Define the minimium players to enable the duel");
	g_hPluginPrefix = CreateConVar("duel_chatprefix", "{lime}Duel {default}|", "Determines the prefix used for chat messages", FCVAR_NOTIFY);
	g_MaxDuelTime = CreateConVar("duel_maxdueltime", "60.0", "Max time for a duel in seconds", FCVAR_NOTIFY);
	DuelCookie = RegClientCookie("Duel Music Preference", "Duel Music", CookieAccess_Private);
	PrefVote = RegClientCookie("Duel Vote Preference", "Duel Vote", CookieAccess_Private);
	SetCookieMenuItem(DuelPrefSelected, 0, "Duel Music Preference");
	
	LoadTranslations("duel_phrases.txt");
	AutoExecConfig(true, "Duel");
	
	RegConsoleCmd("sm_duelsettings", Cmd_DuelSettings);
	
	for (int i = 0; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}

//Hooks
public OnClientCookiesCached(int client)
{
    char sValue[8];
    GetClientCookie(client, DuelCookie, sValue, sizeof(sValue));
    
    g_EnableMusicDuel[client] = (sValue[0] != '\0' && StringToInt(sValue));
   
    char sValue2[8];
    GetClientCookie(client, PrefVote, sValue2, sizeof(sValue2));
    
    g_VotePref[client] = (sValue2[0] != '\0' && StringToInt(sValue2));
} 

public DuelPrefSelected(int client,CookieMenuAction action,any info,char[] buffer,maxlen)
{
	if(action == CookieMenuAction_SelectOption)
	{
		DuelMusic(client);
	}
}

public Action Cmd_DuelSettings(int client, int args)
{
	Menu menu = new Menu(SettingsMenu);

	menu.SetTitle("Duel Menu");
	if(g_VotePref[client] == 1)
	{
		menu.AddItem("1", "Always Accept: Yes");
		menu.AddItem("2", "Always Refuse: No");
    }
    else if(g_VotePref[client] == 2)
	{
		menu.AddItem("1", "Always Accept: No");
		menu.AddItem("2", "Always Refuse: Yes");
    }
    else if(g_VotePref[client] == 0)
	{
		menu.AddItem("1", "Always Accept: No");
		menu.AddItem("2", "Always Refuse: No");
    }
    
	if(g_EnableMusicDuel[client] == 1)
	{
		menu.AddItem("3", "Enable Music: Yes");
    }
    else
    {
    	menu.AddItem("3", "Enable Music: No");
    }
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);  
}

public int SettingsMenu(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));
			
			if (StrEqual(info, "1"))
			{
               GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
	            if(g_VotePref[client] == 1)
	            {
		        	CPrintToChat(client, "%t", "DuelVotePref", g_PluginPrefix);
					g_VotePref[client] = 0;
    			}
    			else
   				{
    				CPrintToChat(client, "%t", "DuelVotePref", g_PluginPrefix);
    				g_VotePref[client] = 1;
    			}
    			char buffer[5];
		        IntToString(g_VotePref[client], buffer, 5);
		        SetClientCookie(client, PrefVote, buffer);
			}
			else if (StrEqual(info, "2"))
			{
               GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
	            if(g_VotePref[client] == 2)
	            {
		        	CPrintToChat(client, "%t", "DuelVotePref", g_PluginPrefix);
					g_VotePref[client] = 0;
    			}
    			else
   				{
    				CPrintToChat(client, "%t", "DuelVotePref", g_PluginPrefix);
    				g_VotePref[client] = 2;
    			}
    			char buffer[5];
		        IntToString(g_VotePref[client], buffer, 5);
		        SetClientCookie(client, PrefVote, buffer);
			}
			else if (StrEqual(info, "3"))
			{
               GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
	            if(g_EnableMusicDuel[client] == 1)
	            {
		        	CPrintToChat(client, "%t", "DisableDuelMusic", g_PluginPrefix);
					g_EnableMusicDuel[client] = 0;
    			}
    			else
   				{
    				CPrintToChat(client, "%t", "EnableDuelMusic", g_PluginPrefix);
    				g_EnableMusicDuel[client] = 1;
    			}
    			char buffer[5];
		        IntToString(g_EnableMusicDuel[client], buffer, 5);
		        SetClientCookie(client, DuelCookie, buffer);
			}
		}

		case MenuAction_End:{delete menu;}
	}

	return 0;
}

public Action DuelMusic(int client)
{
	char option[200];
	if(g_EnableMusicDuel[client] == 1)
	{
		g_soundmode = "On";
    }
    else
    {
    	g_soundmode = "Off";
    }
    
    FormatEx(option, 200, "Duel Music: %s", g_soundmode);
    
	Menu menu = new Menu(DuelMenuSound);

	menu.SetTitle("Duel Menu");
	menu.AddItem("ss", option);
	menu.ExitButton = false;
	menu.Display(client, MENU_TIME_FOREVER);  
}

public int DuelMenuSound(Menu menu, MenuAction action, int client, int param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			char info[32];
			menu.GetItem(param2, info, sizeof(info));

			if (StrEqual(info, "ss"))
			{
               GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
	            if(g_EnableMusicDuel[client] == 1)
	            {
		        	CPrintToChat(client, "%t", "DisableDuelMusic", g_PluginPrefix);
					g_EnableMusicDuel[client] = 0;
    			}
    			else
   				{
    				CPrintToChat(client, "%t", "EnableDuelMusic", g_PluginPrefix);
    				g_EnableMusicDuel[client] = 1;
    			}
    			char buffer[5];
		        IntToString(g_EnableMusicDuel[client], buffer, 5);
		        SetClientCookie(client, DuelCookie, buffer);
			}
		}

		case MenuAction_End:{delete menu;}
	}

	return 0;
}

public Action Event_WeaponFire(Event event,const char[] name,bool dontBroadcast)
{
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		char weapon[32];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
		if (StrEqual(weapon, "weapon_decoy") && g_Decoyduel)
		{
			CreateTimer(1.0, GiveDecoy, client);
		}
		else 
		   if (StrEqual(weapon, "weapon_deagle") && g_Deagle1TapDuel)
		   {
		   		CreateTimer(0.05, RemoveDeagle, client);
				CreateTimer(1.0, GiveDeagle, client);
		   }
		   else if (StrEqual(weapon, "weapon_taser") && g_zeusduel)
		   {
				CreateTimer(3.0, GiveZeus, client);
		   }
		   
}

public Action RemoveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) {
		Client_RemoveAllWeapons(client);
	}
}

public Action GiveDeagle(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) {
		GivePlayerItem(client, "weapon_deagle");
	}
}

public Action GiveZeus(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) {
		GivePlayerItem(client, "weapon_taser");
	}
}

public Action GiveDecoy(Handle timer, any client)
{
	if (IsValidClient(client) && (IsPlayerAlive(client))) {
		GivePlayerItem(client, "weapon_decoy");
	}
}

public Action Event_PlayerHurt(Handle event, const char[] name,bool dontBroadcast)
{
  if (g_Deagle1TapDuel)
  {
    int victim = GetClientOfUserId(GetEventInt(event, "userid"));
    int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
    bool headshot = GetEventBool(event, "headshot");
    int damage = GetEventInt(event, "dmg_health");

    if (!headshot && attacker != victim && victim != 0 && attacker != 0)
    {
      if (damage > 0)
      {
      	SetEntityHealth(victim, 100);
      }
    }
  }
  return Plugin_Continue;
}

public void OnMapStart()
{
	AddFileToDownloadsTable("sound/duel/sound1.mp3");
	AddFileToDownloadsTable("sound/duel/sound2.mp3");
	AddFileToDownloadsTable("sound/duel/sound3.mp3");
	AddFileToDownloadsTable("sound/duel/sound4.mp3");
	AddFileToDownloadsTable("sound/duel/sound5.mp3");
	PrecacheSound("duel/sound1.mp3");
	PrecacheSound("duel/sound2.mp3");
	PrecacheSound("duel/sound3.mp3");
	PrecacheSound("duel/sound4.mp3");
	PrecacheSound("duel/sound5.mp3");
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
		if(InNoscope && StrEqual(item, "weapon_awp") || StrEqual(item, "weapon_ssg08"))
		{
			SetEntDataFloat(weapon, m_flNextSecondaryAttack, GetGameTime() + 9999.9); 
		}
	}
	return Plugin_Continue;
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    voteyes = 0;
	voteno = 0;
    InNoscope = false;
    g_Deagle1TapDuel = false;
    g_Decoyduel = false;
    g_zeusduel = false;
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
    KillTimer(DuelTimer, true);
    DuelTimer = INVALID_HANDLE;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if(AliveTPlayers() == 1 && AliveCTPlayers() == 1)
	{
	  for (int i = 0; i <= MaxClients; i++)
	  {
	  	if(GetRealClientCount() >= g_MinPlayers.IntValue)
	  	ShowDuelMenu(i);
	  }
    }
}

//Duel

public void ShowDuelMenu(int client)
{
     if(IsValidClient(client) && IsPlayerAlive(client))
     {
     	if(g_VotePref[client] == 0)
     	{
     		Menu menu = new Menu(DuelMenu);

			menu.SetTitle("Duel Menu");
			menu.AddItem("YES", "Yes");
			menu.AddItem("NO", "No");
			menu.ExitButton = false;
			menu.Display(client, MENU_TIME_FOREVER);
        }
        else if(g_VotePref[client] == 1)
        {
        	voteyes += 1;
        	checkvotes();
        }
        else if(g_VotePref[client] == 2)
        {
        	voteno += 1;
        	checkvotes();
        }
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

		    if (StrEqual(info, "YES"))
			{
				voteyes += 1;
				checkvotes();
			}
			else if (StrEqual(info, "NO"))
			{
				voteno += 1;
				checkvotes();
			}
		}

		case MenuAction_End:{delete menu;}
	}

	return 0;
}


public void checkvotes()
{
  	if(voteyes + voteno == 2 && voteno >= 1)
  	{
  		NoDuel();
    }
    else if(voteyes == 2)
    {
    	int randomnumber = GetRandomInt(1, 8);
    	if(randomnumber == 1)
    	{
    		AWNoscope();
        }
        else if(randomnumber == 2)
    	{
    		KnifeLowGravity();
        }
        else if(randomnumber == 3)
    	{
    		SpeedKnife();
        }
        else if(randomnumber == 4)
    	{
    		Decoy1HP();
        }
        else if(randomnumber == 5)
    	{
    		DEAGLE1TAP();
        }
        else if(randomnumber == 6)
    	{
    		ZEUSDUEL();
        }
        else if(randomnumber == 7)
    	{
    		SCOUTDUEL();
		}
    }
}

//Some Stocks and Actions

public Action AWNoscope()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
	InNoscope = true;
    Client_RemoveAllWeapons(i);
    char weapon = GivePlayerItem(i, "weapon_awp");
    SetEntProp(weapon, Prop_Data, "m_iClip1", 1000);
  }  
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "AwNoscope", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
}

public Action SCOUTDUEL()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
	InNoscope = true;
    Client_RemoveAllWeapons(i);
    char weapon = GivePlayerItem(i, "weapon_ssg08");
    SetEntProp(weapon, Prop_Data, "m_iClip1", 1000);
  }  
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "ScoutNoscope", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
}

public Action KnifeLowGravity()
{ 
	RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    Client_RemoveAllWeapons(i);
    GivePlayerItem(i, "weapon_knife");
    SetGravity(i, g_KnifeDuelGravity.FloatValue); 
  }
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "KnifeLowGravity", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
}

public Action SpeedKnife()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    Client_RemoveAllWeapons(i);
    GivePlayerItem(i, "weapon_knife");
    SetSpeed(i, g_KnifeDuelPlayerSpeed.FloatValue);
  }
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "SpeedKnife", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
}

public Action Decoy1HP()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    Client_RemoveAllWeapons(i);
    SetEntityHealth(i, 1);
    GivePlayerItem(i, "weapon_decoy");
    SetGravity(i, g_KnifeDuelGravity.FloatValue); 
  }
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "Decoy1HP", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
  g_Decoyduel = true;
}

public Action DEAGLE1TAP()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    Client_RemoveAllWeapons(i);
    SetEntityHealth(i, 100);
    GivePlayerItem(i, "weapon_deagle");
  }
  DuelPlayMusic();
  g_DuelMusic = true;
  g_Deagle1TapDuel = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "Deagle1tap", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
}

public Action ZEUSDUEL()
{ 
  RemoveWeapons();
 for (int i = 0; i <= MaxClients; i++)
  if(IsValidClient(i) && IsPlayerAlive(i))
  {
    Client_RemoveAllWeapons(i);
    SetEntityHealth(i, 1);
    GivePlayerItem(i, "weapon_taser");
  }
  DuelPlayMusic();
  g_DuelMusic = true;
  GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
  CPrintToChatAll("%t", "ZEUSDUEL", g_PluginPrefix);
  float waittime = g_MaxDuelTime.FloatValue;
  DuelTimer = CreateTimer(waittime, DuelTimerFunc); 
  g_zeusduel = true;
}

public Action NoDuel()
{ 
	GetConVarString(g_hPluginPrefix, g_PluginPrefix, sizeof(g_PluginPrefix));
    CPrintToChatAll("%t", "DuelCancelled", g_PluginPrefix);
}

public Action RemoveWeapons()
{ 
	char weapon[64];
	int maxent = GetMaxEntities();
	for (int i=GetMaxClients();i< maxent;i++)
	{
		if ( IsValidEdict(i) && IsValidEntity(i) )
		{
			GetEdictClassname(i, weapon, sizeof(weapon));
			if (( StrContains(weapon, "weapon_") != -1 || StrContains(weapon, "item_") != -1 ))
					RemoveEdict(i);
		}
	}	
	return Plugin_Continue;
}

public Action DuelTimerFunc(Handle timer) 
{ 
    if(AliveTPlayers() == 1 && AliveCTPlayers() == 1)
	{
		CS_TerminateRound(7.0, CSRoundEnd_Draw);
	}
}  

public Action DuelPlayMusic()
{
	for (int  i = 1; i <= MaxClients; i++)
	{
		if(g_EnableMusicDuel[i] == 1)
		{
			int number = GetRandomInt(1, 5);
			if(number == 1)
			{
				EmitSoundToClient(i, "duel/sound1.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
		    }
			else if(number == 2)
			{
				EmitSoundToClient(i, "duel/sound2.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
		    }
		    else if(number == 3)
			{
				EmitSoundToClient(i, "duel/sound3.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
		    }
		    else if(number == 4)
			{
				EmitSoundToClient(i, "duel/sound4.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
		    }
		    else if(number == 5)
			{
				EmitSoundToClient(i, "duel/sound5.mp3", _, SNDCHAN_AUTO, _, _, 1.0, _, _, _, _, _, _);  
		    }
	    }
	}
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

stock int GetRealClientCount()
{
    int iClients = 0;

    for (int i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && !IsFakeClient(i)) {
            iClients++;
        }
    }

    return iClients;
}  
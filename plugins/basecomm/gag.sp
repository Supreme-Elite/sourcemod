/**
 * vim: set ts=4 :
 * =============================================================================
 * SourceMod Basecomm
 * Part of Basecomm plugin, menu and other functionality.
 *
 * SourceMod (C)2004-2008 AlliedModders LLC.  All rights reserved.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */

enum CommType
{
	CommType_Mute,
	CommType_UnMute,
	CommType_Gag,
	CommType_UnGag,
	CommType_Silence,
	CommType_UnSilence
};

void DisplayGagTypesMenu(int client)
{
	Menu menu = new Menu(MenuHandler_GagTypes);
	int target = playerstate[client].gagTarget;
	
	char title[100];
	Format(title, sizeof(title), "%T: %N", "Choose Type", client, target);
	menu.SetTitle(title);
	menu.ExitBackButton = true;

	if (!playerstate[target].isMuted)
	{
		AddTranslatedMenuItem(menu, "0", "Mute Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "1", "UnMute Player", client);
	}
	
	if (!playerstate[target].isGagged)
	{
		AddTranslatedMenuItem(menu, "2", "Gag Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "3", "UnGag Player", client);
	}
	
	if (!playerstate[target].isMuted || !playerstate[target].isGagged)
	{
		AddTranslatedMenuItem(menu, "4", "Silence Player", client);
	}
	else
	{
		AddTranslatedMenuItem(menu, "5", "UnSilence Player", client);
	}
		
	menu.Display(client, MENU_TIME_FOREVER);
}

void AddTranslatedMenuItem(Menu menu, const char[] opt, const char[] phrase, int client)
{
	char buffer[128];
	Format(buffer, sizeof(buffer), "%T", phrase, client);
	menu.AddItem(opt, buffer);
}

void DisplayGagPlayerMenu(int client)
{
	Menu menu = new Menu(MenuHandler_GagPlayer);
	
	char title[100];
	Format(title, sizeof(title), "%T:", "Gag/Mute player", client);
	menu.SetTitle(title);
	menu.ExitBackButton = true;
	
	AddTargetsToMenu(menu, client, true, false);
	
	menu.Display(client, MENU_TIME_FOREVER);
}

public void AdminMenu_Gag(TopMenu topmenu, 
					  TopMenuAction action,
					  TopMenuObject object_id,
					  int param,
					  char[] buffer,
					  int maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "%T", "Gag/Mute player", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayGagPlayerMenu(param);
	}
}

public int MenuHandler_GagPlayer(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		int userid, target;
		
		menu.GetItem(param2, info, sizeof(info));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			playerstate[param1].gagTarget = GetClientOfUserId(userid);
			DisplayGagTypesMenu(param1);
		}
	}
}

public int MenuHandler_GagTypes(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_End)
	{
		delete menu;
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu)
		{
			hTopMenu.Display(param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		char info[32];
		CommType type;
		
		menu.GetItem(param2, info, sizeof(info));
		type = view_as<CommType>(StringToInt(info));
		
		int target = playerstate[param1].gagTarget;
		
		char name[MAX_NAME_LENGTH];
		GetClientName(target, name, sizeof(name));

		switch (type)
		{
			case CommType_Mute:
			{
				PerformMute(target);
				LogAction(param1, target, "\"%L\" muted \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Muted target", "_s", name);
			}
			case CommType_UnMute:
			{
				PerformUnMute(target);
				LogAction(param1, target, "\"%L\" unmuted \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Unmuted target", "_s", name);
			}
			case CommType_Gag:
			{
				PerformGag(target);
				LogAction(param1, target, "\"%L\" gagged \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Gagged target", "_s", name);
			}
			case CommType_UnGag:
			{
				PerformUnGag(target);
				LogAction(param1, target, "\"%L\" ungagged \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Ungagged target", "_s", name);
			}
			case CommType_Silence:
			{
				PerformSilence(target);
				LogAction(param1, target, "\"%L\" silenced \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Silenced target", "_s", name);
			}
			case CommType_UnSilence:
			{
				PerformUnSilence(target);
				LogAction(param1, target, "\"%L\" unsilenced \"%L\"", param1, target);
				ShowActivity2(param1, "[SM] ", "%t", "Unsilenced target", "_s", name);
			}
		}
	}
}

void PerformMute(int target)
{
	playerstate[target].isMuted = true;
	SetClientListeningFlags(target, VOICE_MUTED);

	FireOnClientMute(target, true);
}

void PerformUnMute(int target)
{
	playerstate[target].isMuted = false;
	if (g_Cvar_Deadtalk.IntValue == 1 && !IsPlayerAlive(target))
	{
		SetClientListeningFlags(target, VOICE_LISTENALL);
	}
	else if (g_Cvar_Deadtalk.IntValue == 2 && !IsPlayerAlive(target))
	{
		SetClientListeningFlags(target, VOICE_TEAM);
	}
	else
	{
		SetClientListeningFlags(target, VOICE_NORMAL);
	}
	
	FireOnClientMute(target, false);
}

void PerformGag(int target)
{
	playerstate[target].isGagged = true;
	FireOnClientGag(target, true);
}

void PerformUnGag(int target)
{
	playerstate[target].isGagged = false;
	FireOnClientGag(target, false);
}

void PerformSilence(int target)
{
	if (!playerstate[target].isGagged)
	{
		playerstate[target].isGagged = true;
		FireOnClientGag(target, true);
	}
	
	if (!playerstate[target].isMuted)
	{
		playerstate[target].isMuted = true;
		SetClientListeningFlags(target, VOICE_MUTED);
		FireOnClientMute(target, true);
	}
}

void PerformUnSilence(int target)
{
	if (playerstate[target].isGagged)
	{
		playerstate[target].isGagged = false;
		FireOnClientGag(target, false);
	}
	
	if (playerstate[target].isMuted)
	{
		playerstate[target].isMuted = false;
		
		if (g_Cvar_Deadtalk.IntValue == 1 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_LISTENALL);
		}
		else if (g_Cvar_Deadtalk.IntValue == 2 && !IsPlayerAlive(target))
		{
			SetClientListeningFlags(target, VOICE_TEAM);
		}
		else
		{
			SetClientListeningFlags(target, VOICE_NORMAL);
		}
		FireOnClientMute(target, false);
	}
}

public Action Command_Mute(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_mute <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		PerformMute(target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Muted target", target_name);
		LogAction(client, -1, "\"%L\" muted \"%s\"", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Muted target", "_s", target_name);
		LogAction(client, target_list[0], "\"%L\" muted \"%L\"", client, target_list[0]);
	}
	
	return Plugin_Handled;	
}

public Action Command_Gag(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_gag <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		PerformGag(target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Gagged target", target_name);
		LogAction(client, -1, "\"%L\" gagged \"%s\"", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Gagged target", "_s", target_name);
		LogAction(client, target_list[0], "\"%L\" gagged \"%L\"", client, target_list[0]);
	}
	
	return Plugin_Handled;	
}

public Action Command_Silence(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_silence <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		PerformSilence(target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Silenced target", target_name);
		LogAction(client, -1, "\"%L\" silenced \"%s\"", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Silenced target", "_s", target_name);
		LogAction(client, target_list[0], "\"%L\" silenced \"%L\"", client, target_list[0]);
	}
	
	return Plugin_Handled;	
}

public Action Command_Unmute(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unmute <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		if (!playerstate[target].isMuted)
		{
			continue;
		}
		
		PerformUnMute(target);
	}
	
	LogAction(client, -1, "\"%L\" unmuted \"%s\"", client, target_name);
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Unmuted target", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Unmuted target", "_s", target_name);
	}
	
	return Plugin_Handled;	
}

public Action Command_Ungag(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_ungag <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		PerformUnGag(target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Ungagged target", target_name);
		LogAction(client, -1, "\"%L\" ungagged \"%s\"", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Ungagged target", "_s", target_name);
		LogAction(client, target_list[0], "\"%L\" ungagged \"%L\"", client, target_list[0]);
	}
	
	return Plugin_Handled;	
}

public Action Command_Unsilence(int client, int args)
{	
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_unsilence <player>");
		return Plugin_Handled;
	}
	
	char arg[64];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			0,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (int i = 0; i < target_count; i++)
	{
		int target = target_list[i];
		
		PerformUnSilence(target);
	}
	
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "%t", "Unsilenced target", target_name);
		LogAction(client, -1, "\"%L\" unsilenced \"%s\"", client, target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "%t", "Unsilenced target", "_s", target_name);
		LogAction(client, target_list[0], "\"%L\" unsilenced \"%L\"", client, target_list[0]);
	}
	
	return Plugin_Handled;	
}

 /* Biohazard mod
*   
*  by Cheap_Suit
*
*  This program is free software; you can redistribute it and/or modify it
*  under the terms of the GNU General Public License as published by the
*  Free Software Foundation; either version 2 of the License, or (at
*  your option) any later version.
*
*  This program is distributed in the hope that it will be useful, but
*  WITHOUT ANY WARRANTY; without even the implied warranty of
*  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
*  General Public License for more details.
*
*  You should have received a copy of the GNU General Public License
*  along with this program; if not, write to the Free Software Foundation,
*  Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*
*  In addition, as a special exception, the author gives permission to
*  link the code of this program with the Half-Life Game Engine ("HL
*  Engine") and Modified Game Libraries ("MODs") developed by Valve,
*  L.L.C ("Valve"). You must obey the GNU General Public License in all
*  respects for all of the code used other than the HL Engine and MODs
*  from Valve. If you modify this file, you may extend this exception
*  to your version of the file, but you are not obligated to do so. If
*  you do not wish to do so, delete this exception statement from your
*  version.
*/

#define VERSION	"2.00 Beta 3"

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <hamsandwich>
#include <xs>

#tryinclude "biohazard.cfg"

#if !defined _biohazardcfg_included
	#assert Biohazard configuration file required!
#elseif AMXX_VERSION_NUM < 180
	#assert AMX Mod X v1.8.0 or greater required!
#endif

#define OFFSET_DEATH 444
#define OFFSET_TEAM 114
#define OFFSET_ARMOR 112
#define OFFSET_NVG 129
#define OFFSET_CSMONEY 115
#define OFFSET_PRIMARYWEAPON 116
#define OFFSET_WEAPONTYPE 43
#define OFFSET_CLIPAMMO	51
#define EXTRAOFFSET_WEAPONS 4

#define OFFSET_AMMO_338MAGNUM 377
#define OFFSET_AMMO_762NATO 378
#define OFFSET_AMMO_556NATOBOX 379
#define OFFSET_AMMO_556NATO 380
#define OFFSET_AMMO_BUCKSHOT 381
#define OFFSET_AMMO_45ACP 382
#define OFFSET_AMMO_57MM 383
#define OFFSET_AMMO_50AE 384
#define OFFSET_AMMO_357SIG 385
#define OFFSET_AMMO_9MM 386

#define OFFSET_LASTPRIM 368
#define OFFSET_LASTSEC 369
#define OFFSET_LASTKNI 370

#define TASKID_STRIPNGIVE 698
#define TASKID_NEWROUND	641
#define TASKID_INITROUND 222
#define TASKID_STARTROUND 153
#define TASKID_BALANCETEAM 375
#define TASKID_UPDATESCR 264
#define TASKID_SPAWNDELAY 786
#define TASKID_WEAPONSMENU 564
#define TASKID_CHECKSPAWN 423
#define TASKID_RESPAWN 99

#define EQUIP_PRI (1<<0)
#define EQUIP_SEC (1<<1)
#define EQUIP_GREN (1<<2)
#define EQUIP_ALL (1<<0 | 1<<1 | 1<<2)

#define HAS_NVG (1<<0)
#define ATTRIB_BOMB (1<<1)
#define DMG_HEGRENADE (1<<24)

#define MODEL_CLASSNAME "player_model"
#define IMPULSE_FLASHLIGHT 100

#define MAX_SPAWNS 128

#define fm_get_user_team(%1) get_ent_data(%1, "CBasePlayer", "m_iTeam")
#define fm_get_user_deaths(%1) get_ent_data(%1, "CBasePlayer", "m_iDeaths")
#define fm_get_user_money(%1) get_ent_data(%1, "CBasePlayer", "m_iAccount")
#define fm_get_user_armortype(%1) get_ent_data(%1, "CBasePlayer", "m_iKevlar")
#define fm_set_user_armortype(%1,%2) set_ent_data(%1, "CBasePlayer", "m_iKevlar", %2)
#define fm_get_weapon_id(%1) get_ent_data(%1, "CBasePlayerItem", "m_iId")
#define fm_reset_user_primary(%1) set_ent_data(%1, "CBasePlayer", "m_bHasPrimary", 0)
#define fm_lastprimary(%1) get_ent_data_entity(%1, "CBasePlayer", "m_rgpPlayerItems", 1)
#define fm_lastsecondry(%1) get_ent_data_entity(%1, "CBasePlayer", "m_rgpPlayerItems", 2)
#define fm_lastknife(%1) get_ent_data_entity(%1, "CBasePlayer", "m_rgpPlayerItems", 3)

#define _random(%1) random_num(0, %1 - 1)
#define AMMOWP_NULL (1<<0 | 1<<CSW_KNIFE | 1<<CSW_FLASHBANG | 1<<CSW_HEGRENADE | 1<<CSW_SMOKEGRENADE | 1<<CSW_C4)

#define	ZCLASS_NAME 0
#define	ZCLASS_DESC 1
#define	ZCLASS_CLASS 2
#define	ZCLASS_MODEL 3
#define	ZCLASS_KNIFE 4
#define	ZCLASS_HEALTH 5
#define	ZCLASS_SPEED 6
#define	ZCLASS_GRAVITY 7
#define	ZCLASS_KNOCKBACK 8
#define	ZCLASS_LAST 9

enum
{
	MAX_CLIP = 0,
	MAX_AMMO
}

enum
{
	MENU_PRIMARY = 1,
	MENU_SECONDARY
}

enum
{
	TEAM_UNASSIGNED = 0,
	TEAM_T,
	TEAM_CT,
	TEAM_SPECTATOR
}

enum
{
	ARMOR_NONE = 0,
	ARMOR_KEVLAR,
	ARMOR_VESTHELM
}

enum
{
	KBPOWER_357SIG = 0,
	KBPOWER_762NATO,
	KBPOWER_BUCKSHOT,
	KBPOWER_45ACP,
	KBPOWER_556NATO,
	KBPOWER_9MM,
	KBPOWER_57MM,
	KBPOWER_338MAGNUM,
	KBPOWER_556NATOBOX,
	KBPOWER_50AE
}

new const g_ammo_name[][] =
{
	"",
	"338magnum",
	"762nato",
	"556natobox",
	"556nato",
	"buckshot",
	"45acp",
	"57mm",
	"50ae",
	"357sig",
	"9mm",
	"Flashbang",
	"HEGrenade",
	"SmokeGrenade",
	"C4"
};

new const g_weapon_ammotype[] = 
{
	0,
	9, //p228
	0,
	2, //scout
	12, //hegrenade
	5, //xm1014
	14, //c4
	6, //mac10
	4, //aug
	13, //smoke
	10, //elite
	7, //fiveseven
	6, //ump45
	4, //sg550
	4, //galil
	4, //famas
	6, //usp
	10, //glock
	1, //awp
	10, //mp5
	3, //m249
	5, //m3
	4, //m4a1
	10, //tmp
	2, //g3sg1
	11, //flash
	8, //deagle
	4, //sg552
	2, //ak47
	0,
	7 //p90
}

new const g_weapon_knockback[] =
{
	-1, 
	KBPOWER_357SIG, 
	-1, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_BUCKSHOT, 
	-1, 
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	-1, 
	KBPOWER_9MM, 
	KBPOWER_57MM,
	KBPOWER_45ACP, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_556NATO, 
	KBPOWER_45ACP,
	KBPOWER_9MM, 
	KBPOWER_338MAGNUM,
	KBPOWER_9MM, 
	KBPOWER_556NATOBOX,
	KBPOWER_BUCKSHOT, 
	KBPOWER_556NATO, 
	KBPOWER_9MM, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_50AE, 
	KBPOWER_556NATO, 
	KBPOWER_762NATO, 
	-1, 
	KBPOWER_57MM
}

new const g_remove_entities[][] = 
{ 
	"func_bomb_target",    
	"info_bomb_target", 
	"hostage_entity",      
	"monster_scientist", 
	"func_hostage_rescue", 
	"info_hostage_rescue",
	"info_vip_start",      
	"func_vip_safetyzone", 
	"func_escapezone",     
	"func_buyzone"
}

new g_buyzone, g_sync_hpdisplay, 
    g_sync_msgdisplay, g_fwd_spawn, g_fwd_result, g_fwd_infect, g_fwd_gamestart, 
    g_msg_flashlight, g_msg_scoreattrib, g_msg_scoreinfo, g_msg_deathmsg , 
	g_msg_screenfade, g_msg_damage;
	
new	Float:g_buytime, bool:g_gamestarted, bool:g_roundstarted, bool:g_roundended;
    
new cvar_skyname, cvar_autoteambalance[4], cvar_starttime, cvar_autonvg, 
    cvar_winsounds, cvar_weaponsmenu, cvar_lights, cvar_killbonus, cvar_enabled, 
    cvar_gamedescription, cvar_maxzombies, cvar_flashbang, cvar_buytime,
    cvar_punishsuicide, cvar_infectmoney, cvar_showtruehealth, cvar_obeyarmor,
	cvar_impactexplode, cvar_caphealthdisplay, cvar_knockback, cvar_knockback_dist, 
	cvar_knockback_duck, cvar_shootobjects, cvar_pushpwr_weapon, 
	cvar_pushpwr_zombie;
    
new bool:g_zombie[MAX_PLAYERS+1], bool:g_falling[MAX_PLAYERS+1], bool:g_disconnected[MAX_PLAYERS+1], 
    bool:g_showmenu[MAX_PLAYERS+1], bool:g_suicide[MAX_PLAYERS+1], g_mutate[MAX_PLAYERS+1],
	g_player_zclass[MAX_PLAYERS+1];

new Array:g_zclass[ZCLASS_LAST];
new g_zclass_count;

public plugin_precache()
{
	register_plugin("Biohazard", VERSION, "cheap_suit")
	register_cvar("bh_version", VERSION, FCVAR_SPONLY|FCVAR_SERVER)
	set_cvar_string("bh_version", VERSION)
	
	cvar_enabled = register_cvar("bh_enabled", "1")

	if (!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_gamedescription = register_cvar("bh_gamedescription", "Biohazard")
	cvar_skyname = register_cvar("bh_skyname", "drkg")
	cvar_lights = register_cvar("bh_lights", "d")
	cvar_starttime = register_cvar("bh_starttime", "15.0")
	cvar_buytime = register_cvar("bh_buytime", "0")
	cvar_punishsuicide = register_cvar("bh_punishsuicide", "1")
	cvar_winsounds = register_cvar("bh_winsounds", "1")
	cvar_autonvg = register_cvar("bh_autonvg", "1")
	cvar_knockback = register_cvar("bh_knockback", "1")
	cvar_knockback_duck = register_cvar("bh_knockback_duck", "1")
	cvar_knockback_dist = register_cvar("bh_knockback_dist", "280.0")
	cvar_obeyarmor = register_cvar("bh_obeyarmor", "0")
	cvar_infectmoney = register_cvar("bh_infectionmoney", "0")
	cvar_caphealthdisplay = register_cvar("bh_caphealthdisplay", "1")
	cvar_weaponsmenu = register_cvar("bh_weaponsmenu", "1")
	cvar_maxzombies = register_cvar("bh_maxzombies", "31")
	cvar_flashbang = register_cvar("bh_flashbang", "1")
	cvar_impactexplode = register_cvar("bh_impactexplode", "1")
	cvar_showtruehealth = register_cvar("bh_showtruehealth", "1")
	cvar_killbonus = register_cvar("bh_kill_bonus", "1")
	cvar_shootobjects = register_cvar("bh_shootobjects", "1")
	cvar_pushpwr_weapon = register_cvar("bh_pushpwr_weapon", "2.0")
	cvar_pushpwr_zombie = register_cvar("bh_pushpwr_zombie", "5.0")

	g_zclass[ZCLASS_NAME] = ArrayCreate(32);
	g_zclass[ZCLASS_DESC] = ArrayCreate(64);
	g_zclass[ZCLASS_CLASS] = ArrayCreate(32);
	g_zclass[ZCLASS_MODEL] = ArrayCreate(32);
	g_zclass[ZCLASS_KNIFE] = ArrayCreate(128);
	g_zclass[ZCLASS_HEALTH] = ArrayCreate(1);
	g_zclass[ZCLASS_SPEED] = ArrayCreate(1);
	g_zclass[ZCLASS_GRAVITY] = ArrayCreate(1);
	g_zclass[ZCLASS_KNOCKBACK] = ArrayCreate(1);
	
	new file[64]
	get_configsdir(file, 63)
	format(file, 63, "%s/bh_cvars.cfg", file)
	
	if (file_exists(file)) 
		server_cmd("exec %s", file)
	
	register_dictionary("biohazard.txt")
	
	precache_model(DEFAULT_PMODEL);
	precache_model(DEFAULT_WMODEL);
	
	new i;
	for(i = 0; i < sizeof g_zombie_miss_sounds; i++)
		precache_sound(g_zombie_miss_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_hit_sounds; i++) 
		precache_sound(g_zombie_hit_sounds[i])
	
	for(i = 0; i < sizeof g_scream_sounds; i++) 
		precache_sound(g_scream_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_die_sounds; i++)
		precache_sound(g_zombie_die_sounds[i])
	
	for(i = 0; i < sizeof g_zombie_win_sounds; i++) 
		precache_sound(g_zombie_win_sounds[i])
	
	g_fwd_spawn = register_forward(FM_Spawn, "fwd_spawn")
	
	g_buyzone = create_entity("func_buyzone");
	if (g_buyzone) 
	{
		DispatchSpawn(g_buyzone);
		set_pev(g_buyzone, pev_solid, SOLID_NOT)
	}
	
	new ent = create_entity("info_bomb_target");
	if (ent) 
	{
		DispatchSpawn(ent);
		set_pev(ent, pev_solid, SOLID_NOT)
	}

	#if FOG_ENABLE
	ent = create_entity("env_fog");
	if (ent)
	{
		new colorcode[16], color[3];
		color[0] = random_num(50, 76);
		color[1] = random_num(50, 76);
		color[2] = random_num(50, 76);

		formatex(colorcode, charsmax(colorcode), "%d %d %d", color[0], color[1], color[2]);

		DispatchKeyValue(ent, "density", FOG_DENSITY);
		DispatchKeyValue(ent, "rendercolor", colorcode);
		//DispatchKeyValue(ent, "rendercolor", FOG_COLORS[random(sizeof FOG_COLORS)]);
	}
	#endif
}

public plugin_init()
{
	if (!get_pcvar_num(cvar_enabled)) 
		return
	
	cvar_autoteambalance[0] = get_cvar_pointer("mp_autoteambalance")
	cvar_autoteambalance[1] = get_pcvar_num(cvar_autoteambalance[0])
	set_pcvar_num(cvar_autoteambalance[0], 0)

	register_clcmd("jointeam", "cmd_jointeam")
	register_clcmd("chooseteam", "cmd_jointeam")
	register_clcmd("say /class", "cmd_classmenu")
	register_clcmd("say /guns", "cmd_enablemenu")
	register_clcmd("say /help", "cmd_helpmotd")
	register_clcmd("amx_infect", "cmd_infectuser", ADMIN_BAN, "<name or #userid>")
	
	unregister_forward(FM_Spawn, g_fwd_spawn)
	register_forward(FM_CmdStart, "fwd_cmdstart")
	register_forward(FM_EmitSound, "fwd_emitsound")
	register_forward(FM_GetGameDescription, "fwd_gamedescription")
	register_forward(FM_CreateNamedEntity, "fwd_createnamedentity")
	register_forward(FM_ClientKill, "fwd_clientkill")
	register_forward(FM_PlayerPreThink, "fwd_player_prethink")
	register_forward(FM_PlayerPostThink, "fwd_player_postthink")

	RegisterHam(Ham_TakeDamage, "player", "bacon_takedamage_player")
	RegisterHam(Ham_Killed, "player", "bacon_killed_player")
	RegisterHam(Ham_Spawn, "player", "bacon_spawn_player")
	RegisterHam(Ham_Spawn, "player", "bacon_spawn_player_post", 1)
	RegisterHam(Ham_TraceAttack, "player", "bacon_traceattack_player")
	RegisterHam(Ham_TraceAttack, "func_pushable", "bacon_traceattack_pushable")
	RegisterHam(Ham_CS_Player_ResetMaxSpeed, "player", "bacon_resetmaxspeed_post", 1);
	RegisterHam(Ham_Use, "func_tank", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankmortar", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tankrocket", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_tanklaser", "bacon_use_tank")
	RegisterHam(Ham_Use, "func_pushable", "bacon_use_pushable")
	RegisterHam(Ham_Touch, "func_pushable", "bacon_touch_pushable")
	RegisterHam(Ham_Touch, "weaponbox", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "armoury_entity", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "weapon_shield", "bacon_touch_weapon")
	RegisterHam(Ham_Touch, "grenade", "bacon_touch_grenade")
	RegisterHam(Ham_Item_Deploy, "weapon_knife", "bacon_knife_deploy_post", 1)
	
	register_message(get_user_msgid("Health"), "msg_health")
	register_message(get_user_msgid("TextMsg"), "msg_textmsg")
	register_message(get_user_msgid("SendAudio"), "msg_sendaudio")
	register_message(get_user_msgid("StatusIcon"), "msg_statusicon")
	register_message(get_user_msgid("ScoreAttrib"), "msg_scoreattrib")
	register_message(get_user_msgid("DeathMsg"), "msg_deathmsg")
	register_message(get_user_msgid("ScreenFade"), "msg_screenfade")
	register_message(get_user_msgid("TeamInfo"), "msg_teaminfo")
	register_message(get_user_msgid("ClCorpse"), "msg_clcorpse")
	register_message(get_user_msgid("WeapPickup"), "msg_weaponpickup")
	register_message(get_user_msgid("AmmoPickup"), "msg_ammopickup")
	
	register_event("TextMsg", "event_textmsg", "a", "2=#Game_will_restart_in")
	register_event("HLTV", "event_newround", "a", "1=0", "2=0")
	register_event("ArmorType", "event_armortype", "be")
	
	register_logevent("logevent_round_start", 2, "1=Round_Start")
	register_logevent("logevent_round_end", 2, "1=Round_End")
	
	g_msg_flashlight = get_user_msgid("Flashlight")
	g_msg_scoreattrib = get_user_msgid("ScoreAttrib")
	g_msg_scoreinfo = get_user_msgid("ScoreInfo")
	g_msg_deathmsg = get_user_msgid("DeathMsg")
	g_msg_screenfade = get_user_msgid("ScreenFade")
	g_msg_damage = get_user_msgid("Damage");
	
	g_fwd_infect = CreateMultiForward("event_infect", ET_IGNORE, FP_CELL, FP_CELL)
	g_fwd_gamestart = CreateMultiForward("event_gamestart", ET_IGNORE)

	g_sync_hpdisplay = CreateHudSyncObj()
	g_sync_msgdisplay = CreateHudSyncObj()
	
	new skyname[32]
	get_pcvar_string(cvar_skyname, skyname, 31)
		
	if (strlen(skyname) > 0)
		set_cvar_string("sv_skyname", skyname)
	
	new lights[2]
	get_pcvar_string(cvar_lights, lights, 1)
	
	if (strlen(lights) > 0)
	{
		set_task(3.0, "task_lights", _, _, _, "b")
		
		set_cvar_num("sv_skycolor_r", 0)
		set_cvar_num("sv_skycolor_g", 0)
		set_cvar_num("sv_skycolor_b", 0)
	}
	
	if (get_pcvar_num(cvar_showtruehealth))
		set_task(0.1, "task_showtruehealth", _, _, _, "b")

	if (g_zclass_count < 1)
	{
		new index = register_zclass(DEFAULT_NAME, DEFAULT_DESC, DEFAULT_CLASS);
		register_zclass_attr(index, DEFAULT_HEALTH, DEFAULT_SPEED, DEFAULT_GRAVITY, DEFAULT_KNOCKBACK);

		ArraySetString(g_zclass[ZCLASS_MODEL], index, DEFAULT_PMODEL);
		ArraySetString(g_zclass[ZCLASS_KNIFE], index, DEFAULT_WMODEL);
	}
}

public plugin_end()
{
	if (get_pcvar_num(cvar_enabled))
		set_pcvar_num(cvar_autoteambalance[0], cvar_autoteambalance[1])
}

public plugin_natives()
{
	register_library("biohazardf");

	register_native("bio_infect_user", "native_infect_user");
	register_native("bio_cure_user", "native_cure_user");
	register_native("bio_register_zclass", "native_register_zclass");
	register_native("bio_register_zclass_model", "native_register_zclass_model");
	register_native("bio_register_zclass_attr", "native_register_zclass_attr");
	register_native("bio_get_zclass_id", "native_get_zclass_id")
	register_native("bio_get_zclass_str", "native_get_zclass_str");
	register_native("bio_get_zclass_float", "native_get_zclass_float");
	register_native("bio_get_zclass_int", "native_get_zclass_int");
	register_native("bio_is_game_started", "native_is_game_started");
	register_native("bio_is_zombie", "native_is_zombie");
	register_native("bio_get_user_zclass", "native_get_user_zclass");
}

public client_putinserver(id)
{
	g_showmenu[id] = false
	g_zombie[id] = false
	g_disconnected[id] = false
	g_falling[id] = false
	g_mutate[id] = -1
	g_player_zclass[id] = 0
}

public client_disconnected(id)
{
	remove_task(TASKID_STRIPNGIVE + id);
	remove_task(TASKID_UPDATESCR + id);
	remove_task(TASKID_SPAWNDELAY + id);
	remove_task(TASKID_WEAPONSMENU + id);
	remove_task(TASKID_CHECKSPAWN + id);
	remove_task(TASKID_RESPAWN + id);

	g_showmenu[id] = false
	g_zombie[id] = false
	g_disconnected[id] = false
	g_falling[id] = false
	g_mutate[id] = -1
	g_player_zclass[id] = 0

	g_disconnected[id] = true;
}

public cmd_jointeam(id)
{
	if (is_user_alive(id) && g_zombie[id])
	{
		client_print(id, print_center, "%L", id, "CMD_TEAMCHANGE");
		cmd_classmenu(id);
		return PLUGIN_HANDLED;
	} else if(is_user_alive(id) && !g_zombie[id]) {
		client_print(0, print_chat, "ha");
		cmd_enablemenu(id);
		return PLUGIN_HANDLED;
	}

	return PLUGIN_CONTINUE;
}

public cmd_classmenu(id)
{
	if (g_zclass_count > 1)
		display_zclassmenu(id);
}

public cmd_enablemenu(id)
{	
	if (get_pcvar_num(cvar_weaponsmenu))
	{
		client_print(id, print_chat, "%L", id, g_showmenu[id] == false ? "MENU_REENABLED" : "MENU_ALENABLED");
		g_showmenu[id] = true;
	}
}

public cmd_helpmotd(id)
{
	static motd[2048];
	formatex(motd, 2047, "%L", id, "HELP_MOTD");
	replace(motd, 2047, "#Version#", VERSION);
	
	show_motd(id, motd, "Biohazard Help");
}	

public cmd_infectuser(id, level, cid)
{
	if (!cmd_access(id, level, cid, 2))
		return PLUGIN_HANDLED_MAIN;
	
	static arg1[32];
	read_argv(1, arg1, 31);
	
	static target;
	target = cmd_target(id, arg1, (CMDTARGET_OBEY_IMMUNITY|CMDTARGET_ALLOW_SELF|CMDTARGET_ONLY_ALIVE));
	
	if (!is_user_connected(target) || g_zombie[target])
		return PLUGIN_HANDLED_MAIN;
	
	if (!allow_infection())
	{
		console_print(id, "%L", id, "CMD_MAXZOMBIES")
		return PLUGIN_HANDLED_MAIN;
	}
	
	if (!g_gamestarted)
	{
		console_print(id, "%L", id, "CMD_GAMENOTSTARTED")
		return PLUGIN_HANDLED_MAIN;
	}
			
	static name[32];
	get_user_name(target, name, 31);
	
	console_print(id, "%L", id, "CMD_INFECTED", name)
	infect_user(target, 0)
	
	return PLUGIN_HANDLED_MAIN
}

public msg_teaminfo(msgid, dest, id)
{
	if (!g_gamestarted)
		return PLUGIN_CONTINUE

	static team[2]
	get_msg_arg_string(2, team, 1)
	
	if (team[0] != 'U')
		return PLUGIN_CONTINUE

	id = get_msg_arg_int(1)
	if (is_user_alive(id) || !g_disconnected[id])
		return PLUGIN_CONTINUE

	g_disconnected[id] = false
	id = randomly_pick_zombie()
	if (id)
	{
		cs_set_user_team(id, g_zombie[id] ? TEAM_CT : TEAM_T, CS_NORESET, false);
		set_pev(id, pev_deadflag, DEAD_RESPAWNABLE)
	}
	return PLUGIN_CONTINUE
}

public msg_screenfade(msgid, dest, id)
{
	if (!get_pcvar_num(cvar_flashbang))
		return PLUGIN_CONTINUE
	
	if (!g_zombie[id] || !is_user_alive(id))
	{
		static data[4]
		data[0] = get_msg_arg_int(4)
		data[1] = get_msg_arg_int(5)
		data[2] = get_msg_arg_int(6)
		data[3] = get_msg_arg_int(7)
		
		if (data[0] == 255 && data[1] == 255 && data[2] == 255 && data[3] > 199)
			return PLUGIN_HANDLED
	}
	return PLUGIN_CONTINUE
}

public msg_scoreattrib(msgid, dest, id)
{
	static attrib 
	attrib = get_msg_arg_int(2)
	
	if (attrib == ATTRIB_BOMB)
		set_msg_arg_int(2, ARG_BYTE, 0)
}

public msg_statusicon(msgid, dest, id)
{
	static icon[3]
	get_msg_arg_string(2, icon, 2)
	
	return (icon[0] == 'c' && icon[1] == '4') ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public msg_weaponpickup(msgid, dest, id)
{
	return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public msg_ammopickup(msgid, dest, id)
{
	return g_zombie[id] ? PLUGIN_HANDLED : PLUGIN_CONTINUE;
}

public msg_deathmsg(msgid, dest, id) 
{
	static killer
	killer = get_msg_arg_int(1)

	if (is_user_connected(killer) && g_zombie[killer])
		set_msg_arg_string(4, g_zombie_weapname)
}

public msg_sendaudio(msgid, dest, id)
{
	if (!get_pcvar_num(cvar_winsounds))
		return PLUGIN_CONTINUE
	
	static audiocode [22]
	get_msg_arg_string(2, audiocode, 21)
	
	if (equal(audiocode[7], "terwin"))
		set_msg_arg_string(2, g_zombie_win_sounds[_random(sizeof g_zombie_win_sounds)])
	else if (equal(audiocode[7], "ctwin"))
		set_msg_arg_string(2, g_survivor_win_sounds[_random(sizeof g_survivor_win_sounds)])
	
	return PLUGIN_CONTINUE
}

public msg_health(msgid, dest, id)
{
	if (!get_pcvar_num(cvar_caphealthdisplay))
		return PLUGIN_CONTINUE
	
	static health
	health = get_msg_arg_int(1)
		
	if (health > 255) 
		set_msg_arg_int(1, ARG_BYTE, 255)
	
	return PLUGIN_CONTINUE
}

public msg_textmsg(msgid, dest, id)
{
	if (get_msg_arg_int(1) != 4)
		return PLUGIN_CONTINUE
	
	static txtmsg[25], winmsg[32]
	get_msg_arg_string(2, txtmsg, 24)
	
	if (equal(txtmsg[1], "Game_bomb_drop"))
		return PLUGIN_HANDLED

	else if (equal(txtmsg[1], "Terrorists_Win"))
	{
		formatex(winmsg, 31, "%L", LANG_SERVER, "WIN_TXT_ZOMBIES")
		set_msg_arg_string(2, winmsg)
	}
	else if (equal(txtmsg[1], "Target_Saved") || equal(txtmsg[1], "CTs_Win"))
	{
		formatex(winmsg, 31, "%L", LANG_SERVER, "WIN_TXT_SURVIVORS")
		set_msg_arg_string(2, winmsg)
	}
	return PLUGIN_CONTINUE
}

public msg_clcorpse(msgid, dest, id)
{
	id = get_msg_arg_int(12)
	if (!g_zombie[id])
		return PLUGIN_CONTINUE
	
	static ent
	ent = find_ent_by_owner(-1, MODEL_CLASSNAME, id)
	
	if (ent)
	{
		static model[64]
		pev(ent, pev_model, model, 63)
		
		set_msg_arg_string(1, model)
	}
	return PLUGIN_CONTINUE
}

public logevent_round_start()
{
	g_roundended = false
	g_roundstarted = true
}

public logevent_round_end()
{
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true
	
	remove_task(TASKID_BALANCETEAM) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	RequestFrame("task_balanceteam");
}

public event_textmsg()
{
	g_gamestarted = false 
	g_roundstarted = false 
	g_roundended = true
	
	static seconds[5] 
	read_data(3, seconds, 4)
	
	static Float:tasktime 
	tasktime = float(str_to_num(seconds)) - 0.5
	
	remove_task(TASKID_BALANCETEAM)
	
	set_task(tasktime, "task_balanceteam", TASKID_BALANCETEAM)
}

public event_newround()
{
	g_gamestarted = false
	
	new buytime = get_pcvar_num(cvar_buytime)
	
	if (buytime) 
		g_buytime = buytime + get_gametime()
	
	for(new id = 0; id <= MaxClients; id++)
	{
		if (is_user_connected(id))
		{
			g_zombie[id] = false;
		}
	}
	
	remove_task(TASKID_NEWROUND) 
	remove_task(TASKID_INITROUND)
	remove_task(TASKID_STARTROUND)
	
	set_task(get_pcvar_float(cvar_starttime), "task_initround", TASKID_INITROUND)
}

public event_armortype(id)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return PLUGIN_CONTINUE
	
	if (fm_get_user_armortype(id) != ARMOR_NONE)
		fm_set_user_armortype(id, ARMOR_NONE)
	
	return PLUGIN_CONTINUE
}

public fwd_player_prethink(id)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	
	static flags
	flags = pev(id, pev_flags)
	
	if (~flags & FL_ONGROUND)
	{
		static Float:fallvelocity
		pev(id, pev_flFallVelocity, fallvelocity)
		
		g_falling[id] = fallvelocity >= 350.0 ? true : false
	}
	return FMRES_IGNORED
}

public fwd_player_postthink(id)
{ 
	if (!is_user_alive(id))
		return FMRES_IGNORED
	
	if (g_zombie[id] && g_falling[id] && (pev(id, pev_flags) & FL_ONGROUND))
	{	
		set_pev(id, pev_watertype, CONTENTS_WATER)
		g_falling[id] = false
	}
	
	if (get_pcvar_num(cvar_buytime))
	{
		if (pev_valid(g_buyzone) && g_buytime > get_gametime())
			dllfunc(DLLFunc_Touch, g_buyzone, id)
	}
	return FMRES_IGNORED
}

public fwd_emitsound(id, channel, sample[], Float:volume, Float:attn, flag, pitch)
{	
	if (channel == CHAN_ITEM && sample[6] == 'n' && sample[7] == 'v' && sample[8] == 'g')
		return FMRES_SUPERCEDE	
	
	if (!is_user_connected(id) || !g_zombie[id])
		return FMRES_IGNORED	

	if (sample[8] == 'k' && sample[9] == 'n' && sample[10] == 'i')
	{
		if (sample[14] == 's' && sample[15] == 'l' && sample[16] == 'a')
		{
			emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
			return FMRES_SUPERCEDE
		}
		else if (sample[14] == 'h' && sample[15] == 'i' && sample[16] == 't' || sample[14] == 's' && sample[15] == 't' && sample[16] == 'a')
		{
			if (sample[17] == 'w' && sample[18] == 'a' && sample[19] == 'l')
				emit_sound(id, channel, g_zombie_miss_sounds[_random(sizeof g_zombie_miss_sounds)], volume, attn, flag, pitch)
			else
				emit_sound(id, channel, g_zombie_hit_sounds[_random(sizeof g_zombie_hit_sounds)], volume, attn, flag, pitch)
			
			return FMRES_SUPERCEDE
		}
	}			
	else if (sample[7] == 'd' && (sample[8] == 'i' && sample[9] == 'e' || sample[12] == '6'))
	{
		emit_sound(id, channel, g_zombie_die_sounds[_random(sizeof g_zombie_die_sounds)], volume, attn, flag, pitch)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_cmdstart(id, handle, seed)
{
	if (!is_user_alive(id) || !g_zombie[id])
		return FMRES_IGNORED
	
	static impulse
	impulse = get_uc(handle, UC_Impulse)
	
	if (impulse == IMPULSE_FLASHLIGHT)
	{
		set_uc(handle, UC_Impulse, 0)
		return FMRES_SUPERCEDE
	}
	return FMRES_IGNORED
}

public fwd_spawn(ent)
{
	if (!pev_valid(ent)) 
		return FMRES_IGNORED
	
	static classname[32]
	pev(ent, pev_classname, classname, 31)

	static i
	for(i = 0; i < sizeof g_remove_entities; ++i)
	{
		if (equal(classname, g_remove_entities[i]))
		{
			remove_entity(ent)
			return FMRES_SUPERCEDE
		}
	}
	return FMRES_IGNORED
}

public fwd_gamedescription() 
{ 
	static gamename[32]
	get_pcvar_string(cvar_gamedescription, gamename, 31)
	
	forward_return(FMV_STRING, gamename)
	
	return FMRES_SUPERCEDE
}  

public fwd_createnamedentity(entclassname)
{
	static classname[10]
	engfunc(EngFunc_SzFromIndex, entclassname, classname, 9)
	
	return (classname[7] == 'c' && classname[8] == '4') ? FMRES_SUPERCEDE : FMRES_IGNORED
}

public fwd_clientkill(id)
{
	if (get_pcvar_num(cvar_punishsuicide) && is_user_alive(id))
		g_suicide[id] = true
}

public bacon_touch_weapon(ent, id)
{
	return (is_user_alive(id) && g_zombie[id]) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public bacon_use_tank(ent, caller, activator, use_type, Float:value)
{
	return (is_user_alive(caller) && g_zombie[caller]) ? HAM_SUPERCEDE : HAM_IGNORED;
}

public bacon_use_pushable(ent, caller, activator, use_type, Float:value)
{
	return HAM_SUPERCEDE
}

public bacon_traceattack_player(victim, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
	if (!g_gamestarted) 
		return HAM_SUPERCEDE
	
	if (!get_pcvar_num(cvar_knockback) || !(damagetype & DMG_BULLET))
		return HAM_IGNORED
	
	if (!is_user_connected(attacker) || !g_zombie[victim])
		return HAM_IGNORED
	
	static kbpower
	kbpower = g_weapon_knockback[get_user_weapon(attacker)]
	
	if (kbpower != -1) 
	{
		static flags
		flags = pev(victim, pev_flags)
		
		if (get_pcvar_num(cvar_knockback_duck) && ((flags & FL_DUCKING) && (flags & FL_ONGROUND)))
			return HAM_IGNORED
		
		static Float:origins[2][3]
		pev(victim, pev_origin, origins[0])
		pev(attacker, pev_origin, origins[1])
		
		if (get_distance_f(origins[0], origins[1]) <= get_pcvar_float(cvar_knockback_dist))
		{
			new Float:velocity[3];
			pev(victim, pev_velocity, velocity);
			
			new Float:tempvec = velocity[2];
			
			xs_vec_mul_scalar(direction, damage, direction)
			xs_vec_mul_scalar(direction, Float:ArrayGetCell(g_zclass[ZCLASS_KNOCKBACK], g_player_zclass[victim]), direction)
			xs_vec_mul_scalar(direction, g_knockbackpower[kbpower], direction)
			
			xs_vec_add(direction, velocity, velocity)
			velocity[2] = tempvec
			
			set_pev(victim, pev_velocity, velocity)
			
			return HAM_HANDLED
		}
	}
	return HAM_IGNORED
}

public bacon_touch_grenade(ent, world)
{
	if (!get_pcvar_num(cvar_impactexplode))
		return HAM_IGNORED
	
	static model[12]
	pev(ent, pev_model, model, 11)
	
	if (model[9] == 'h' && model[10] == 'e')
	{
		set_pev(ent, pev_dmgtime, 0.0)
		
		return HAM_HANDLED
	}
	return HAM_IGNORED
}

public bacon_takedamage_player(victim, inflictor, attacker, Float:damage, damagetype)
{
	if (damagetype & DMG_GENERIC || victim == attacker || !is_user_alive(victim) || !is_user_connected(attacker))
		return HAM_IGNORED;

	if (g_zombie[victim] == g_zombie[attacker])
		return HAM_IGNORED;

	if (!g_gamestarted)
		return HAM_SUPERCEDE;
	
	if (g_zombie[attacker])
	{
		if (inflictor != attacker || get_user_weapon(attacker) != CSW_KNIFE)
			return HAM_IGNORED;

		new Float:armor;
		pev(victim, pev_armorvalue, armor);
		
		if (get_pcvar_num(cvar_obeyarmor) && armor > 0.0)
		{
			armor -= damage;
			
			if (armor < 0.0) 
				armor = 0.0;
			
			set_pev(victim, pev_armorvalue, armor);
			SetHamParamFloat(4, 0.0);
		}
		else
		{
			if (allow_infection())
			{
				new Float:origin[3];
				pev(attacker, pev_origin, origin);

				send_damage_msg(victim, 0, floatround(damage), (DMG_BULLET|DMG_NEVERGIB), origin); // send dmg msg

				// slowdown effect
				set_ent_data_float(victim, "CBasePlayer", "m_flVelocityModifier", 0.0);
				
				infect_user(victim, attacker, true, true);
				return HAM_SUPERCEDE;
			}

			SetHamParamFloat(4, damage);
		}
	}

	return HAM_HANDLED;
}

public bacon_killed_player(victim, killer, shouldgib)
{
	remove_task(victim + TASKID_RESPAWN);
	set_task(5.0, "task_respawnplayer", victim + TASKID_RESPAWN);

	if (is_user_alive(killer) && !g_zombie[killer] && g_zombie[victim])
	{
		static killbonus
		killbonus = get_pcvar_num(cvar_killbonus)
		
		if (killbonus)
			set_pev(killer, pev_frags, pev(killer, pev_frags) + float(killbonus))
	}
}

public bacon_spawn_player(id)
{
	// 玩家出生時平衡隊伍
	if (pev_valid(id) && (TEAM_T <= fm_get_user_team(id) <= TEAM_CT))
	{
		if (!g_gamestarted)
		{
			set_ent_data(id, "CBasePlayer", "m_iTeam", TEAM_UNASSIGNED);

			new num_t = count_team_players(TEAM_T);
			new num_ct = count_team_players(TEAM_CT);

			new team;
			if (num_t < num_ct)
				team = TEAM_T;
			else if (num_ct < num_t)
				team = TEAM_CT;
			else
				team = random_num(TEAM_T, TEAM_CT);

			set_ent_data(id, "CBasePlayer", "m_iTeam", team);
		}
		else
		{
			set_ent_data(id, "CBasePlayer", "m_iTeam", g_zombie[id] ? TEAM_T : TEAM_CT);
		}
	}
}

public bacon_spawn_player_post(id)
{	
	if (!is_user_alive(id))
		return HAM_IGNORED
	
	static team
	team = fm_get_user_team(id)
	
	if (team != TEAM_T && team != TEAM_CT)
		return HAM_IGNORED
	
	if (g_zombie[id])
	{
		infect_user(id, 0)
	}
	else
	{
		cure_user(id);
	}
	
	set_task(0.3, "task_spawned", TASKID_SPAWNDELAY + id)
	
	return HAM_IGNORED
}

public bacon_touch_pushable(ent, id)
{
	static movetype
	pev(id, pev_movetype)
	
	if (movetype == MOVETYPE_NOCLIP || movetype == MOVETYPE_NONE)
		return HAM_IGNORED	
	
	if (is_user_alive(id))
	{
		set_pev(id, pev_movetype, MOVETYPE_WALK)
		
		if (!(pev(id, pev_flags) & FL_ONGROUND))
			return HAM_SUPERCEDE
	}
	
	if (!get_pcvar_num(cvar_shootobjects))
		return HAM_IGNORED
	
	static Float:velocity[2][3]
	pev(ent, pev_velocity, velocity[0])
	
	if (vector_length(velocity[0]) > 0.0)
	{
		pev(id, pev_velocity, velocity[1])
		velocity[1][0] += velocity[0][0]
		velocity[1][1] += velocity[0][1]
		
		set_pev(id, pev_velocity, velocity[1])
	}
	return HAM_SUPERCEDE
}

public bacon_traceattack_pushable(ent, attacker, Float:damage, Float:direction[3], tracehandle, damagetype)
{
	if (!get_pcvar_num(cvar_shootobjects) || !is_user_alive(attacker))
		return HAM_IGNORED
	
	static Float:velocity[3]
	pev(ent, pev_velocity, velocity)
			
	static Float:tempvec
	tempvec = velocity[2]	
			
	xs_vec_mul_scalar(direction, damage, direction)
	xs_vec_mul_scalar(direction, g_zombie[attacker] ? 
	get_pcvar_float(cvar_pushpwr_zombie) : get_pcvar_float(cvar_pushpwr_weapon), direction)
	xs_vec_add(direction, velocity, velocity)
	velocity[2] = tempvec
	
	set_pev(ent, pev_velocity, velocity)
	
	return HAM_HANDLED
}

public bacon_knife_deploy_post(ent)
{
	new id = get_ent_data_entity(ent, "CBasePlayerItem", "m_pPlayer");
	if (is_user_connected(id))
	{
		// viewmodel2
		if (g_zombie[id])
		{
			static model[128];
			ArrayGetString(Array:g_zclass[ZCLASS_KNIFE], g_player_zclass[id], model, charsmax(model));

			set_pev(id, pev_weaponmodel2, "");
			set_pev(id, pev_viewmodel2, model);
		}
	}
}

public bacon_resetmaxspeed_post(id)
{
	if (is_user_alive(id) && g_zombie[id])
	{
		set_user_maxspeed(id, Float:ArrayGetCell(g_zclass[ZCLASS_SPEED], g_player_zclass[id]));
	}
}

public task_respawnplayer(taskid)
{
	new id = taskid - TASKID_RESPAWN;

	if (g_roundended || !g_gamestarted)
		return;
	
	if (!(1 <= fm_get_user_team(id) <= 2))
		return;
	
	if (is_user_alive(id))
		return;
	
	ExecuteHam(Ham_CS_RoundRespawn, id);
}

public task_spawned(taskid)
{
	static id
	id = taskid - TASKID_SPAWNDELAY
	
	if (is_user_alive(id))
	{
		if (g_suicide[id])
		{
			g_suicide[id] = false
			
			user_silentkill(id)
			remove_task(TASKID_CHECKSPAWN + id)

			client_print(id, print_chat, "%L", id, "SUICIDEPUNISH_TXT")
			
			return
		}
		
		if (get_pcvar_num(cvar_weaponsmenu) && g_roundstarted && g_showmenu[id])
			display_equipmenu(id);
	}
}
	
public task_showtruehealth()
{
	set_hudmessage(_, _, _, 0.03, 0.93, _, 0.2, 0.2)
	
	new Float:health;
	static name[32];

	for(new id = 1; id <= MaxClients; id++)
	{
		if (is_user_alive(id) && !is_user_bot(id) && g_zombie[id])
		{
			pev(id, pev_health, health);
			ArrayGetString(g_zclass[ZCLASS_NAME], g_player_zclass[id], name, charsmax(name));

			ShowSyncHudMsg(id, g_sync_hpdisplay, "Health: %0.f  Class: %s", health, name);
		}
	}
}

public task_lights()
{
	static light[2]
	get_pcvar_string(cvar_lights, light, 1)
	
	set_lights(light);
}

public task_stripngive(id)
{
	if (is_user_alive(id))
	{
		strip_user_weapons(id)
		fm_reset_user_primary(id)
		give_item(id, "weapon_knife")
	}
}

public task_initround()
{
	new players[32], num;

	// Get all valid players and push it to the array list
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (!(TEAM_T <= fm_get_user_team(i) <= TEAM_CT))
			continue;

		if (!is_user_alive(i))
			ExecuteHam(Ham_CS_RoundRespawn, i);
		
		players[num++] = i;
	}

	new player;
	new numZombies = 0
	new maxZombies = floatround(num * 0.25, floatround_ceil);

	// clone
	new players2[32], num2;
	players2 = players;
	num2 = num;

	// Pick random zombie(s)
	while (numZombies < maxZombies && num2)
	{
		player = pick_random_player(players2, num2, true);
		if (!player)
			continue;
		
		infect_user(player, 0);
		numZombies++;
	}

	// 剩下的玩家全部轉為 CT 隊伍
	for (new i = 0; i < num2; i++)
	{
		player = players2[i];
		cs_set_user_team(player, CS_TEAM_CT, CS_NORESET, true);
	}

	g_gamestarted = true
	ExecuteForward(g_fwd_gamestart, g_fwd_result)
}

public task_balanceteam()
{
	static players[3][32], count[3]
	get_players(players[TEAM_UNASSIGNED], count[TEAM_UNASSIGNED])
	
	count[TEAM_T] = 0
	count[TEAM_CT] = 0
	
	static i, id, team
	for(i = 0; i < count[TEAM_UNASSIGNED]; i++)
	{
		id = players[TEAM_UNASSIGNED][i] 
		team = fm_get_user_team(id)
		
		if (team == TEAM_T || team == TEAM_CT)
			players[team][count[team]++] = id
	}

	if (abs(count[TEAM_T] - count[TEAM_CT]) <= 1) 
		return

	static maxplayers
	maxplayers = (count[TEAM_T] + count[TEAM_CT]) / 2
	
	if (count[TEAM_T] > maxplayers)
	{
		for(i = 0; i < (count[TEAM_T] - maxplayers); i++)
			cs_set_user_team(players[TEAM_T][i], CS_TEAM_CT, CS_NORESET, false);
	}
	else
	{
		for(i = 0; i < (count[TEAM_CT] - maxplayers); i++)
			cs_set_user_team(players[TEAM_CT][i], CS_TEAM_T, CS_NORESET, false);
	}
}

infect_user(victim, attacker, deathmsg=false, score=false, slient=false)
{
	if (!is_user_alive(victim))
		return
	
	if (is_user_connected(attacker))
	{
		if (deathmsg)
		{
			send_deathmsg(attacker, victim, false, g_infection_name);
			send_scoreattrib(victim, false);
		}

		if (score)
		{
			new frags = get_user_frags(attacker);
			new deaths = cs_get_user_deaths(victim);

			set_user_frags(attacker,frags + 1);
			cs_set_user_deaths(victim, deaths + 1);

			update_score(attacker);
			update_score(victim);

			cs_set_user_money(attacker, cs_get_user_money(attacker) + get_pcvar_num(cvar_infectmoney));
		}
	}

	message_begin(MSG_ONE, g_msg_screenfade, _, victim)
	write_short(1<<10)
	write_short(1<<10)
	write_short(0)
	write_byte((g_mutate[victim] != -1) ? 255 : 100)
	write_byte(100)
	write_byte(100)
	write_byte(250)
	message_end()
	
	if (g_mutate[victim] != -1)
	{
		g_player_zclass[victim] = g_mutate[victim]
		g_mutate[victim] = -1
		
		set_hudmessage(_, _, _, _, _, 1)
		ShowSyncHudMsg(victim, g_sync_msgdisplay, "%L", victim, "MUTATION_HUD", ArrayGetStringHandle(g_zclass[ZCLASS_NAME], g_player_zclass[victim]));
	}
	else
	{
		g_player_zclass[victim] = random(g_zclass_count);
	}
	
	cs_set_user_team(victim, CS_TEAM_T, CS_NORESET, true);
	set_zombie_attibutes(victim)
	
	if (!slient)
	{
		emit_sound(victim, CHAN_STATIC, g_scream_sounds[_random(sizeof g_scream_sounds)], VOL_NORM, ATTN_NONE, 0, PITCH_NORM)
		ExecuteForward(g_fwd_infect, g_fwd_result, victim, attacker)
	}
}

public cure_user(id)
{
	if (!is_user_alive(id)) 
		return

	g_zombie[id] = false
	g_falling[id] = false

	cs_reset_user_model(id)
	cs_set_user_nvg(id, 0)
	set_pev(id, pev_gravity, 1.0)

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, id);
	
	if (get_user_weapon(id) == CSW_KNIFE)
	{
		new weapon = fm_lastknife(id);
		if (pev_valid(weapon))
			ExecuteHam(Ham_Item_Deploy, weapon);
	}
}

public display_equipmenu(id)
{
	new menu = menu_create("Choose Your Weapon:", "action_equip");

	for (new i = 0; i < sizeof g_secondaryweapons; i++)
	{
		menu_additem(menu, g_secondaryweapons[i][0]);
	}

	menu_setprop(menu, MPROP_NUMBER_COLOR, "\y");
	menu_display(id, menu);
}

public action_equip(id, menu, item)
{
	menu_destroy(menu);

	if (item == MENU_EXIT)
		return;

	if (!is_user_alive(id) || g_zombie[id])
		return;
	
	drop_weapons(id, 2);
	
	give_item(id, g_secondaryweapons[item][1]);
	
	new weapon = get_weaponid(g_secondaryweapons[item][1])
	give_weapon_full_ammo(id, weapon);
}

public display_zclassmenu(id)
{
	static string[96];
	new menu = menu_create("Choose Your Zombie class", "action_zclassmenu");

	for (new i = 0; i < g_zclass_count; i++)
	{
		formatex(string, charsmax(string), "%a \y%a", 
			ArrayGetStringHandle(g_zclass[ZCLASS_NAME], i), 
			ArrayGetStringHandle(g_zclass[ZCLASS_DESC], i));

		menu_additem(menu, string);
	}

	menu_display(id, menu);
}

public action_zclassmenu(id, menu, item)
{
	menu_destroy(menu);

	if (item == MENU_EXIT)
		return;

	g_mutate[id] = item;
	client_print(id, print_chat, "%L", id, "MENU_CHANGECLASS", ArrayGetStringHandle(g_zclass[ZCLASS_NAME], item));
}

stock register_zclass(const name[], const desc[], const classname[])
{
	ArrayPushString(g_zclass[ZCLASS_NAME], name);
	ArrayPushString(g_zclass[ZCLASS_DESC], desc);
	ArrayPushString(g_zclass[ZCLASS_CLASS], classname);

	ArrayPushString(g_zclass[ZCLASS_MODEL], DEFAULT_PMODEL);
	ArrayPushString(g_zclass[ZCLASS_KNIFE], DEFAULT_WMODEL);

	ArrayPushCell(g_zclass[ZCLASS_HEALTH], DEFAULT_HEALTH);
	ArrayPushCell(g_zclass[ZCLASS_SPEED], DEFAULT_SPEED);
	ArrayPushCell(g_zclass[ZCLASS_GRAVITY], DEFAULT_GRAVITY);
	ArrayPushCell(g_zclass[ZCLASS_KNOCKBACK], DEFAULT_KNOCKBACK);

	g_zclass_count++;

	return (g_zclass_count - 1);
}

stock register_zclass_attr(class, Float:health, Float:speed, Float:gravity, Float:knockback)
{
	if (class >= g_zclass_count)
		return 0;
	
	ArraySetCell(g_zclass[ZCLASS_HEALTH], class, health);
	ArraySetCell(g_zclass[ZCLASS_SPEED], class, speed);
	ArraySetCell(g_zclass[ZCLASS_GRAVITY], class, gravity);
	ArraySetCell(g_zclass[ZCLASS_KNOCKBACK], class, knockback);

	return 1;
}

stock register_zclass_model(class, const model[], const knife[])
{
	if (class >= g_zclass_count)
		return 0;
	
	ArraySetString(g_zclass[ZCLASS_MODEL], class, model);
	ArraySetString(g_zclass[ZCLASS_KNIFE], class, knife);

	precache_player_model(model);
	precache_model(knife);

	return 1;
}

public native_register_zclass()
{
	new name[32], desc[64], classname[32];
	get_string(1, name, charsmax(name));
	get_string(2, desc, charsmax(desc));
	get_string(3, classname, charsmax(classname));

	return register_zclass(name, desc, classname);
}

public native_register_zclass_model()
{
	new classid = get_param(1);

	new model[32], knife[128];
	get_string(2, model, charsmax(model));
	get_string(3, knife, charsmax(knife));

	return register_zclass_model(classid, model, knife);
}

public native_register_zclass_attr()
{
	new classid = get_param(1);

	new Float:health = get_param_f(2);
	new Float:speed = get_param_f(3);
	new Float:gravity = get_param_f(4);
	new Float:knockback = get_param_f(5);

	return register_zclass_attr(classid, health, speed, gravity, knockback);
}

public native_is_zombie()
{
	new id = get_param(1);

	return g_zombie[id];
}

public native_get_user_zclass()
{
	new id = get_param(1);
	return g_player_zclass[id];
}

public native_is_game_started()
{
	return g_gamestarted;
}

public native_infect_user()
{
	new id = get_param(1);
	new attacker = get_param(2);

	if (allow_infection() && g_gamestarted)
		infect_user(id, attacker);
}

public native_cure_user()
{
	new id = get_param(1);
	cure_user(id)
}

public native_get_zclass_id()
{
	new classname[32], str[32];
	get_string(1, classname, charsmax(classname));

	for(new i = 0; i < g_zclass_count; i++)
	{
		ArrayGetString(g_zclass[ZCLASS_CLASS], i, str, charsmax(str));
		if (equali(classname, str))
			return i;
	}

	return -1;
}

public native_get_zclass_str()
{
	new index = get_param(1);
	new type = get_param(2);

	new string[128];
	ArrayGetString(g_zclass[type], index, string, charsmax(string));
	
	new len = get_param(4);
	set_string(3, string, len);
}

public Float:native_get_zclass_float()
{
	new index = get_param(1);
	new type = get_param(2);

	return Float:ArrayGetCell(g_zclass[type], index);
}

public native_get_zclass_int()
{
	new index = get_param(1);
	new type = get_param(2);

	return ArrayGetCell(g_zclass[type], index);
}

stock bool:fm_is_hull_vacant(const Float:origin[3], hull)
{
	static tr
	tr = 0
	
	engfunc(EngFunc_TraceHull, origin, origin, 0, hull, 0, tr)
	return (!get_tr2(tr, TR_StartSolid) && !get_tr2(tr, TR_AllSolid) && get_tr2(tr, TR_InOpen)) ? true : false
}

stock str_count(str[], searchchar)
{
	static maxlen
	maxlen = strlen(str)
	
	static i, count
	count = 0
	
	for(i = 0; i <= maxlen; i++) if (str[i] == searchchar)
		count++

	return count
}

stock set_zombie_attibutes(index)
{
	if (!is_user_alive(index)) 
		return

	g_zombie[index] = true

	strip_user_weapons(index);
	fm_reset_user_primary(index);
	give_item(index, "weapon_knife");

	new class = g_player_zclass[index];
	
	set_pev(index, pev_health, Float:ArrayGetCell(g_zclass[ZCLASS_HEALTH], class));
	set_pev(index, pev_gravity, Float:ArrayGetCell(g_zclass[ZCLASS_GRAVITY], class));
	set_pev(index, pev_body, 0);
	set_pev(index, pev_armorvalue, 0.0);
	
	fm_set_user_armortype(index, ARMOR_NONE);
	cs_set_user_nvg(index);
	
	if (get_pcvar_num(cvar_autonvg)) 
		engclient_cmd(index, "nightvision");
	
	static playermodel[32];
	ArrayGetString(g_zclass[ZCLASS_MODEL], g_player_zclass[index], playermodel, charsmax(playermodel));
	cs_set_user_model(index, playermodel);

	new effects = pev(index, pev_effects);
	if (effects & EF_DIMLIGHT)
	{
		message_begin(MSG_ONE, g_msg_flashlight, _, index);
		write_byte(0);
		write_byte(100);
		message_end();
		
		set_pev(index, pev_effects, effects & ~EF_DIMLIGHT);
	}

	ExecuteHamB(Ham_CS_Player_ResetMaxSpeed, index);
}

stock bool:allow_infection()
{
	static count[2]
	count[0] = 0
	count[1] = 0
	
	static index, maxzombies
	for(index = 1; index <= MaxClients; index++)
	{
		if (is_user_connected(index) && g_zombie[index]) 
			count[0]++
		else if (is_user_alive(index)) 
			count[1]++
	}
	
	maxzombies = clamp(get_pcvar_num(cvar_maxzombies), 1, 31)
	return (count[0] < maxzombies && count[1] > 1) ? true : false;
}

stock randomly_pick_zombie()
{
	static data[4]
	data[0] = 0 
	data[1] = 0 
	data[2] = 0 
	data[3] = 0
	
	static index, players[2][32]
	for(index = 1; index <= MaxClients; index++)
	{
		if (!is_user_alive(index)) 
			continue
		
		if (g_zombie[index])
		{
			data[0]++
			players[0][data[2]++] = index
		}
		else 
		{
			data[1]++
			players[1][data[3]++] = index
		}
	}

	if (data[0] > 0 &&  data[1] < 1) 
		return players[0][_random(data[2])]
	
	return (data[0] < 1 && data[1] > 0) ?  players[1][_random(data[3])] : 0;
}

stock bacon_strip_weapon(index, weapon[])
{
	if (!equal(weapon, "weapon_", 7)) 
		return 0

	static weaponid 
	weaponid = get_weaponid(weapon)

	if (!weaponid) 
		return 0

	static weaponent
	weaponent = find_ent_by_owner(-1, weapon, index)

	if (!weaponent) 
		return 0

	if (get_user_weapon(index) == weaponid) 
		ExecuteHamB(Ham_Weapon_RetireWeapon, weaponent)

	if (!ExecuteHamB(Ham_RemovePlayerItem, index, weaponent)) 
		return 0

	ExecuteHamB(Ham_Item_Kill, weaponent)
	set_pev(index, pev_weapons, pev(index, pev_weapons) & ~(1<<weaponid))
	
	return 1;
}

stock precache_player_model(const model[])
{
	new buffer[128];
	formatex(buffer, charsmax(buffer), "models/player/%s/%s.mdl", model, model);
	precache_model(buffer);
	
	formatex(buffer, charsmax(buffer), "models/player/%s/%sT.mdl", model, model);
	if (file_exists(buffer))
		precache_model(buffer);
}

stock update_score(id)
{
	new frags = get_user_frags(id)
	new deaths = cs_get_user_deaths(id)
	new team = fm_get_user_team(id)
	
	message_begin(MSG_BROADCAST, g_msg_scoreinfo);
	write_byte(id);
	write_short(frags);
	write_short(deaths);
	write_short(0);
	write_short(team);
	message_end();
}

stock send_deathmsg(attacker, victim, bool:headshot, const weapon[])
{
	message_begin(MSG_ALL, g_msg_deathmsg);
	write_byte(attacker);
	write_byte(victim);
	write_byte(headshot);
	write_string(weapon);
	message_end();
}

stock send_scoreattrib(id, bool:val)
{
	message_begin(MSG_ALL, g_msg_scoreattrib);
	write_byte(id);
	write_byte(val);
	message_end();
}

stock send_damage_msg(id, save, take, type, Float:origin[3])
{
	message_begin(MSG_ONE, g_msg_damage, _, id);
	write_byte(save);
	write_byte(take);
	write_long(type);
	write_coord_f(origin[0]);
	write_coord_f(origin[1]);
	write_coord_f(origin[2]);
	message_end();
}

stock pick_random_player(players[32], &num, bool:remove=true)
{
	if (num < 1)
		return 0;
	
	new rand = random(num);
	new playerindex = players[rand];

	if (remove && num > 0)
		players[rand] = players[--num];
	
	return playerindex;
}

stock drop_weapons(id, slot=0)
{
	new classname[32];

	for (new i = 1; i <= 5; i++)
	{
		if (slot && slot != i)
			continue;

		new weapon = get_ent_data_entity(id, "CBasePlayer", "m_rgpPlayerItems", i);

		while (pev_valid(weapon))
		{
			if (ExecuteHamB(Ham_CS_Item_CanDrop, weapon))
			{
				pev(weapon, pev_classname, classname, charsmax(classname));
				engclient_cmd(id, "drop", classname);
			}

			weapon = get_ent_data_entity(weapon, "CBasePlayerItem", "m_pNext");
		}
	}
}

stock count_team_players(team)
{
	new count = 0;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (!is_user_connected(i))
			continue;
		
		if (fm_get_user_team(i) == team)
			count++;
	}

	return count;
}

stock give_full_ammo(player, type)
{
	give_ammo(player, type, g_ammo_data[type][AMMO_MAX], g_ammo_data[type][AMMO_MAX]);
}

stock give_ammo(player, type, amount=0, max=0)
{
	if (!amount)
		amount = g_ammo_data[type][AMMO_AMT];

	if (!max)
		max = g_ammo_data[type][AMMO_MAX];

	new ammo = get_ent_data(player, "CBasePlayer", "m_rgAmmo", type);
	ExecuteHamB(Ham_GiveAmmo, player, amount, g_ammo_name[type], max);

	if (ammo >= max)
		return 0;

	return 1;
}

stock give_weapon_ammo(player, weapon, amount=0, max=0)
{
	new type = g_weapon_ammotype[weapon];
	return give_ammo(player, type, amount, max);
}

stock give_weapon_full_ammo(player, weapon)
{
	new type = g_weapon_ammotype[weapon];
	give_full_ammo(player, type);
}
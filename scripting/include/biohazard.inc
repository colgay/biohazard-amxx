/* Biohazard functions
*
*  by Cheap_Suit
* 
*  This file is provided as is (no warranties).
*/

#if defined _biohazard_included
	#endinput
#endif
#define _biohazard_included

#pragma reqlib "biohazardf"

/* Returns the mods status */
stock is_biomod_active()
{
	if(!cvar_exists("bh_enabled"))
	{
		log_amx("Cvar: ^"bh_enabled^" does not exist.")
		return 0
	}
	return get_cvar_num("bh_enabled")
}

/* Called when a survivor is infected */
forward event_infect(victim, attacker);

/* Called when the game starts */
forward event_gamestart();

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

native bio_infect_user(victim, attacker);

native bio_cure_user(id);

native bio_register_zclass(const name[], const desc[], const classname[]);

native bio_register_zclass_model(index, const model[], const knifemdl[]);

native bio_register_zclass_attr(index, Float:health, Float:speed, Float:gravity, Float:knockback);

native bio_get_zclass_id(const classname[]);

native bio_get_zclass_str(index, type, string[], len);

native Float:bio_get_zclass_float(index, type);

native bio_get_zclass_int(index, type);

native bool:bio_is_game_started();

native bool:bio_is_zombie(id);

native bio_get_user_zclass(id);
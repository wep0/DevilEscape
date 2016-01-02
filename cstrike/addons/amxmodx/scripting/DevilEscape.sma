/*=============================================================
	
	DevilEscape mode
		For Counter-Strike 1.6
		
	Coding by watepy	in 15/12/7
	
log:
	15/12/7 : start coding
	
=============================================================*/

#include <amxmodx>
#include <amxmisc>
#include <fun>
#include <cstrike>
#include <fakemeta>
#include <hamsandwich>
#include <xs>
#include <dhudmessage>
#include <keyvalues>
#include <bitset>
#include <engine>

#define PLUGIN_NAME "DevilEscape"
#define PLUGIN_VERSION "0.0"
#define PLUGIN_AUTHOR "w&a"

/* ==================
	
				 常量

================== */

#define bit_id (id-1)
#define g_NeedXp[%1] (g_Level[%1]*g_Level[%1]*100)
#define is_user_valid_connected(%1) (1 <= %1 <= g_MaxPlayer && get_bit(g_isConnect, %1-1))

#define Game_Description "魔王 Alpha"

#define SHOTGUN_AIMING 32

//弹药类型武器
new const AMMOWEAPON[] = { 0, CSW_AWP, CSW_SCOUT, CSW_M249, 
			CSW_AUG, CSW_XM1014, CSW_MAC10, CSW_FIVESEVEN, CSW_DEAGLE, 
			CSW_P228, CSW_ELITE, CSW_FLASHBANG, CSW_HEGRENADE, 
			CSW_SMOKEGRENADE, CSW_C4 }

//弹药名
new const AMMOTYPE[][] = { "", "357sig", "", "762nato", "", "buckshot", "", "45acp", "556nato", "", "9mm", "57mm", "45acp",
		"556nato", "556nato", "556nato", "45acp", "9mm", "338magnum", "9mm", "556natobox", "buckshot",
			"556nato", "9mm", "762nato", "", "50ae", "556nato", "762nato", "", "57mm" }
			
//最大后背弹药
new const MAXBPAMMO[] = { -1, 52, -1, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90, 100, 120,
				30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, -1, 100 }

enum
{
	FM_CS_TEAM_UNASSIGNED = 0,
	FM_CS_TEAM_T,
	FM_CS_TEAM_CT,
	FM_CS_TEAM_SPECTATOR
}

enum(+=40)
{
	TASK_BOTHAM = 100, TASK_USERLOGIN, TASK_PWCHANGE,
	TASK_ROUNDSTART, TASK_BALANCE, TASK_SHOWHUD, TASK_PLRSPAWN, 
	TASK_GODMODE_LIGHT, TASK_GODMODE_OFF1,TASK_CRITICAL, TASK_SCARE_OFF
}

enum{
	Round_Start=0,			
	Round_Running,
	Round_End
}

new const g_RemoveEnt[][] = {
	"func_hostage_rescue", "info_hostage_rescue", "func_bomb_target", "info_bomb_target",
	"hostage_entity", "info_vip_start", "func_vip_safetyzone", "func_escapezone"
}

//资源
new const mdl_player_devil1[] = "models/player/devil1/devil1.mdl"

new const mdl_v_devil1[] = "models/v_devil_hand1.mdl"

new const snd_human_win[] = "DevilEscape/Human_Win.wav"
new const snd_devil_win[] = "DevilEscape/Devil_Win.wav"

new const snd_boss_scare[] = "DevilEscape/Boss_Scare.wav"
new const snd_boss_tele[] = "DevilEscape/Boss_Teleport.wav"
new const snd_boss_god[] = "DevilEscape/Boss_God.wav"

new const snd_crit_shoot[] = "DevilEscape/Crit_Shoot.wav"
new const snd_crit_hit[] = "DevilEscape/Crit_Hit.wav"
new const snd_crit_received[] = "DevilEscape/Crit_Received.wav"
new const snd_minicrit_hit[] = "DevilEscape/MiniCrit_Hit.wav"

new const spr_ring[] = "sprites/shockwave.spr"

new const spr_crit[] = "sprites/DevilEscape/Crit.spr"
new const spr_minicrit[] = "sprites/DevilEscape/MiniCrit.spr"

new const spr_scare[] = "sprites/DevilEscape/Boss_Scare.spr"

//offset
const m_CsTeam = 114 				//队伍
const m_MapZone = 235				//所在区域
const m_ModelIndex = 491 				//模型索引

const KEYSMENU = (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<5)|(1<<6)|(1<<7)|(1<<8)|(1<<9)

new const InvalidChars[]= { "/", "\", "*", ":", "?", "^"", "<", ">", "|", " " }
new const g_fog_color[] = "128 128 128";
new const g_fog_denisty[] = "0.002";


/* ================== 

				Vars
				
================== */

//Cvar
new cvar_DmgReward, cvar_LoginTime, cvar_DevilHea, cvar_DevilSlashDmgMulti, cvar_DevilScareTime, cvar_DevilScareRange, 
cvar_DevilGodTime, cvar_RewardCoin, cvar_RewardXp, cvar_SpPreLv, cvar_HumanCritMulti, cvar_HumanCritPercent, 
cvar_HumanMiniCritMulti, cvar_AbilityHeaCost, cvar_AbilityAgiCost, cvar_AbilityStrCost, cvar_AbilityGraCost, cvar_AbilityHeaMax, 
cvar_AbilityAgiMax, cvar_AbilityStrMax, cvar_AbilityGraMax

//Spr
new g_spr_ring;
new g_spr_crit;
new g_spr_minicrit;
new g_spr_scare;

//Game
new g_plrTeam;
new g_isRegister;
new g_isLogin;
new g_isConnect;
new g_isChangingPW;
new g_isModeled;
new g_isNoDamage
new g_isCrit;
new g_isMiniCrit;
// new g_isSemiclip;
// new g_isSolid;
new g_whoBoss;
new g_MaxPlayer;
new g_Online;
new bool:g_hasBot;
new g_RoundStatus;

new g_Level[33];
new g_Coin[33];
new g_Gash[33];
new g_Xp[33];
new g_Sp[33];
new g_Abi_Hea[33]
new g_Abi_Str[33];
new g_Abi_Agi[33];
new g_Abi_Gra[33];

new Float:g_Dmg[33];
new Float:g_DmgDealt[33]
new Float:g_AttackCooldown[33];
new g_LoginTime[33];
new g_users_ammo[33];
new g_users_weapon[33]

new g_savesDir[128];
new g_PlayerModel[33][32]

// new Float:g_PlrOrg[33][3]
new Float:g_TSpawn[32][3]
new Float:g_CTSpawn[32][3]

//Hud
new g_Hud_Center, g_Hud_Status, g_Hud_Reward

//Msg
new g_Msg_VGUI, g_Msg_ShowMenu;

//Forward Handle
new g_fwSpawn;


public plugin_precache()
{
	//载入
	gm_create_fog();
	gm_init_spawnpoint();
	engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_rain"));
	//Get saves' dir
	get_localinfo("amxx_configsdir", g_savesDir, charsmax(g_savesDir));
	formatex(g_savesDir, charsmax(g_savesDir), "%s/saves", g_savesDir)
	
	g_fwSpawn = register_forward(FM_Spawn, "fw_Spawn");
	
	engfunc(EngFunc_PrecacheModel, mdl_player_devil1)
	
	engfunc(EngFunc_PrecacheModel, mdl_v_devil1)
	
	g_spr_ring = engfunc(EngFunc_PrecacheModel, spr_ring)
	g_spr_crit = engfunc(EngFunc_PrecacheModel, spr_crit)
	g_spr_minicrit = engfunc(EngFunc_PrecacheModel, spr_minicrit)
	g_spr_scare = engfunc(EngFunc_PrecacheModel, spr_scare)
	
	engfunc(EngFunc_PrecacheSound, snd_human_win)
	engfunc(EngFunc_PrecacheSound, snd_devil_win)
	engfunc(EngFunc_PrecacheSound, snd_boss_scare)
	engfunc(EngFunc_PrecacheSound, snd_boss_tele)
	engfunc(EngFunc_PrecacheSound, snd_boss_god)
	engfunc(EngFunc_PrecacheSound, snd_crit_hit)
	engfunc(EngFunc_PrecacheSound, snd_crit_received)
	engfunc(EngFunc_PrecacheSound, snd_crit_shoot)
	engfunc(EngFunc_PrecacheSound, snd_minicrit_hit)
	
	//Cvar
	cvar_LoginTime = register_cvar("de_logintime","120")
	
	cvar_DmgReward = register_cvar("de_human_dmg_reward", "1500")
	cvar_RewardCoin = register_cvar("de_reward_coin", "1")
	cvar_RewardXp = register_cvar("de_reward_xp", "200")
	cvar_SpPreLv = register_cvar("de_sp_per_lv", "2")
	
	cvar_DevilHea = register_cvar("de_devil_basehea","2046")
	cvar_DevilSlashDmgMulti = register_cvar("de_devil_slashdmg_multi", "1.5")
	cvar_DevilScareRange = register_cvar("de_devil_scarerange", "512.0")
	cvar_DevilScareTime = register_cvar("de_devil_scaretime", "4.5")
	cvar_DevilGodTime = register_cvar("de_devil_godtime", "7.5")
	
	cvar_HumanCritPercent = register_cvar("de_crit_percent","3")
	cvar_HumanCritMulti = register_cvar("de_crit_multi","3.0")
	cvar_HumanMiniCritMulti = register_cvar("de_minicrit_multi","1.5")
	
	cvar_AbilityHeaCost = register_cvar("de_ability_hea_cost","1")
	cvar_AbilityAgiCost = register_cvar("de_ability_agi_cost","2")
	cvar_AbilityStrCost = register_cvar("de_ability_str_cost","4")
	cvar_AbilityGraCost = register_cvar("de_ability_gra_cost","8")
	
	cvar_AbilityHeaMax = register_cvar("de_ability_hea_max","100")
	cvar_AbilityAgiMax = register_cvar("de_ability_agi_max","20")
	cvar_AbilityStrMax = register_cvar("de_ability_str_max","50")
	cvar_AbilityGraMax = register_cvar("de_ability_gra_max","4")
}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	register_dictionary("devilescape.txt");
	
	//Menu
	register_menu("Main Menu", KEYSMENU, "menu_main")
	register_menu("Ability Menu", KEYSMENU, "menu_ability")
	register_menu("Skill Menu", KEYSMENU, "menu_skill")
	register_menu("Bossskill Menu", KEYSMENU, "menu_bossskill")
	//register_menu("Wpn Menu", KEYSMENU, "menu_wpn")
	// register_menu("Weapon1 Menu", KEYSMENU, "menu_weapon1")
	
	register_menucmd(register_menuid("#Team_Select_Spect"), 51, "menu_team_select") 
	
	//Event
	register_event("HLTV", "event_round_start", "a", "1=0", "2=0");
	register_event("AmmoX", "event_ammo_x", "be");
	register_logevent("event_round_end", 2, "1=Round_End");
	register_event("CurWeapon","event_shoot","be","1=1");
	
	//Forward
	register_forward(FM_CmdStart,"fw_CmdStart")
	register_forward(FM_PlayerPreThink, "fw_PlayerPreThink");
	register_forward(FM_PlayerPostThink, "fw_PlayerPostThink");
	register_forward(FM_ClientCommand, "fw_ClientCommand") ;
	register_forward(FM_ClientDisconnect, "fw_ClientDisconnect");
	register_forward(FM_SetClientKeyValue, "fw_SetClientKeyValue");
	register_forward(FM_ClientUserInfoChanged,"fw_ClientUserInfoChanged")
	register_forward(FM_GetGameDescription, "fw_GetGameDescription")
	register_forward(FM_AddToFullPack, "fw_AddToFullPack_Post", 1 );
	
	//Ham
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "fw_TakeDamage_Post",1);
	RegisterHam(Ham_Spawn, "player", "fw_PlayerSpawn_Post", 1);
	RegisterHam(Ham_Touch, "weapon_hegrenade", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "weaponbox", "fw_TouchWeapon")
	RegisterHam(Ham_Touch, "armoury_entity", "fw_TouchWeapon")
	
	//Msg
	g_Msg_VGUI = get_user_msgid("VGUIMenu")
	g_Msg_ShowMenu = get_user_msgid("ShowMenu")
	register_message(g_Msg_ShowMenu, "msg_show_menu")
	register_message(g_Msg_VGUI, "msg_vgui_menu")
	register_message(get_user_msgid( "StatusIcon" ), "msg_statusicon");
	register_message(get_user_msgid("Health"), "msg_health")
	register_message(get_user_msgid("TextMsg"), "msg_textmsg")
	register_message(get_user_msgid("SendAudio"), "msg_sendaudio")
	
	//Hud
	g_Hud_Center = CreateHudSyncObj();
	g_Hud_Status = CreateHudSyncObj();
	g_Hud_Reward = CreateHudSyncObj();
	
	//Unregister
	unregister_forward(FM_Spawn, g_fwSpawn)
	
	//Vars
	g_MaxPlayer = get_maxplayers()
	
	server_cmd("mp_autoteambalance 0")
}


/* =====================

			  Event
			 
===================== */

//Round_Start
public event_round_start()
{
	g_RoundStatus = Round_Start;
	
	//Light
	engfunc(EngFunc_LightStyle, 0, 'f')
	
	gm_reset_vars()
	remove_task(TASK_BALANCE)
	set_task(0.2, "task_balance", TASK_BALANCE)
	
	set_dhudmessage( 255, 255, 255, -1.0, 0.25, 1, 6.0, 3.0, 0.1, 1.5 );
	show_dhudmessage( 0, " %L", LANG_PLAYER, "DHUD_ROUND_START" );
	
	remove_task(TASK_ROUNDSTART)
	set_task(10.0, "task_round_start", TASK_ROUNDSTART)
}

//Round_End
public event_round_end()
{
	g_RoundStatus = Round_End;
	
	remove_task(TASK_BALANCE)
	set_task(0.2, "task_balance", TASK_BALANCE)
}

public event_ammo_x(id)
{
	//Human only
	if(id == g_whoBoss)
		return;
	
	static type
	type = read_data(1)
	
	// Unknown ammo type
	if (type >= sizeof AMMOWEAPON)
		return;
	
	// Get weapon's id
	static weapon
	weapon = AMMOWEAPON[type]
	
	// Primary and secondary only
	if (MAXBPAMMO[weapon] <= 2)
		return;
	
	// Get ammo amount
	static amount
	amount = read_data(2)
	
	if (amount < MAXBPAMMO[weapon])
	{
	// The BP Ammo refill code causes the engine to send a message, but we
	// can't have that in this forward or we risk getting some recursion bugs.
	// For more info see: https://bugs.alliedmods.net/show_bug.cgi?id=3664
		static args[1]
		args[0] = weapon
		set_task(0.1, "task_refill_bpammo", id, args, sizeof args)
	}
}

public event_shoot(id)
{
	new ammo = read_data(3), weapon = read_data(2);
	if(g_users_ammo[id] > ammo && ammo >= 0 && g_users_weapon[id] == weapon)
	{
		new vec1[3], vec2[3];
		get_user_origin(id, vec1, 1);
		get_user_origin(id, vec2, 4);
		if(weapon==CSW_M3 || weapon==CSW_XM1014)
		{
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));

			vec2[0]+=SHOTGUN_AIMING;
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
			vec2[1]+=SHOTGUN_AIMING;
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
			vec2[2]+=SHOTGUN_AIMING;
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
			vec2[0]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			vec2[0]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
			vec2[1]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			vec2[1]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
			vec2[2]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			vec2[2]-=SHOTGUN_AIMING; // Repeated substraction is faster then multiplication !
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
		}
		else
			msg_trace(vec1,vec2,get_bit(g_isCrit, bit_id));
		g_users_ammo[id]=ammo;
		if(get_bit(g_isCrit, bit_id))
			engfunc(EngFunc_EmitSound,id, CHAN_STATIC, snd_crit_shoot, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
    }
	else
	{
        g_users_weapon[id]=weapon;
        g_users_ammo[id]=ammo;
    }
	return PLUGIN_HANDLED;
}

/* =====================

			 Forward
			 
===================== */

//Entity Spawn
public fw_Spawn(entity)
{
	// Invalid entity
	if (!pev_valid(entity)) return FMRES_IGNORED;
	new classname[32]
	// Get classname
	pev(entity, pev_classname, classname, charsmax(classname))
	for(new i = 0; i < sizeof g_RemoveEnt; i ++)
	{
		if(equal(classname, g_RemoveEnt[i]))
		{
			//Remove Ent
			engfunc(EngFunc_RemoveEntity, entity)
			return FMRES_SUPERCEDE;
		}
	}
	return FMRES_IGNORED;
}

//Player Spawn Post
public fw_PlayerSpawn_Post(id)
{
	static team
	team = fm_cs_get_user_team(id)
	switch(team)
	{
		case FM_CS_TEAM_CT:
			set_bit(g_plrTeam, bit_id)
		case FM_CS_TEAM_T:
			delete_bit(g_plrTeam, bit_id)
	}
	
	new Float:test[3]
	pev(id, pev_origin, test)
	set_task(0.2, "task_plrspawn", id+TASK_PLRSPAWN)
	set_task(1.0, "task_showhud", id+TASK_SHOWHUD, _ ,_ ,"b")
	
}


//PreThink
public fw_PlayerPreThink(id)
{
	if(g_AttackCooldown[id] > get_gametime())
	{
		if(!is_user_alive(id)) return FMRES_IGNORED;
		set_pev(id, pev_button, pev(id,pev_button) & ~IN_ATTACK );
		set_pev(id, pev_button, pev(id,pev_button) & ~IN_ATTACK2 );
	}else set_view(id,CAMERA_NONE)
		
	
	// fw_SetPlayerSoild(id)
	if(g_Xp[id] >= g_NeedXp[id])
	{
		while(g_Xp[id] >= g_NeedXp[id])
		{
			g_Xp[id] -= g_NeedXp[id]
			g_Level[id] ++
			g_Sp[id] += get_pcvar_num(cvar_SpPreLv)
		}
		set_hudmessage(192, 0, 0, -1.0, -1.0, 1, 6.0, 1.5, 0.3, 0.3, 0)
		ShowSyncHudMsg(id, g_Hud_Center, "%L" , LANG_PLAYER, "HUD_LEVEL_UP", g_Level[id])
	}
	return FMRES_HANDLED;
}

//Post Think
// public fw_PlayerPostThink(id)
// {
	// static plr
	// for(plr = 1; plr<= g_MaxPlayer; plr++)
	// {
		// if(get_bit(g_isSemiclip, plr-1))
		// {
			// set_pev(plr, pev_solid, SOLID_SLIDEBOX)
			// delete_bit(g_isSemiclip, plr-1)
		// }
	// }
// }

//Damage
public fw_TakeDamage(victim, inflictor, attacker, Float:damage, damage_type)
{
	static Vic_team, Att_Team
	Vic_team = fm_cs_get_user_team(victim)
	Att_Team = fm_cs_get_user_team(attacker)
		
	if(Vic_team == Att_Team)
		return HAM_IGNORED
		
	//无敌
	if(get_bit(g_isNoDamage, victim))
		return HAM_SUPERCEDE;
	
	new Float:TrueDamage = damage;
	
	if(g_whoBoss == attacker)
	{
		TrueDamage *= get_pcvar_float(cvar_DevilSlashDmgMulti)
		SetHamParamFloat(4, TrueDamage)
		return HAM_HANDLED;
	}
	
	if(get_bit(g_isCrit, attacker-1))
	{
		TrueDamage *= get_pcvar_float(cvar_HumanCritMulti)
		msg_create_crit(attacker,victim,1)
	}
	else if(get_bit(g_isMiniCrit, attacker-1))
	{
		TrueDamage *= get_pcvar_float(cvar_HumanMiniCritMulti)
		msg_create_crit(attacker,victim,2)
	}
	
	SetHamParamFloat(4, TrueDamage)
		
	return HAM_HANDLED;
}

public fw_TakeDamage_Post(victim, inflictor, attacker, Float:damage, damage_type)
{
	static Vic_team, Att_Team
	Vic_team = fm_cs_get_user_team(victim)
	Att_Team = fm_cs_get_user_team(attacker)
		
	if(Vic_team == Att_Team)
		return HAM_IGNORED
	
	g_Dmg[attacker] += damage;
	g_DmgDealt[attacker] += damage;
	
	if(g_DmgDealt[attacker] > get_pcvar_num(cvar_DmgReward))
	{
		new i = 0;
		while(g_DmgDealt[attacker] > get_pcvar_num(cvar_DmgReward))
		{
			i ++;
			g_DmgDealt[attacker] -= get_pcvar_num(cvar_DmgReward);
			g_Coin[attacker] += get_pcvar_num(cvar_RewardCoin);
			g_Xp[attacker] += get_pcvar_num(cvar_RewardXp);
		}
		set_hudmessage(192, 0, 0, -1.0, 0.75, 1, 6.0, 1.5, 0.3, 0.3, 0)
		ShowSyncHudMsg(attacker, g_Hud_Reward, "+%d xp ^n +%d coin ^n" , i * get_pcvar_num(cvar_RewardXp), i * get_pcvar_num(cvar_RewardCoin))
	}
	
	//这里应该是HUD提示
	
	return HAM_IGNORED
}

public fw_TouchWeapon(weapon, id)
{
	if(!is_user_valid_connected(id))
		return HAM_IGNORED;
	
	if(id == g_whoBoss)
		return HAM_SUPERCEDE;
	
	return HAM_IGNORED;
}

//Disconnect
public fw_ClientDisconnect(id)
{
	delete_bit(g_isConnect, bit_id)
}

//Command
public fw_CmdStart(id,uc_handle,seed)
{
	new button = get_uc(uc_handle, UC_Buttons);
	// new old_button = pev(id,pev_oldbuttons);
	
	if(button&IN_USE)
	{
		if(id != g_whoBoss)
			return FMRES_IGNORED
		show_menu_bossskill(id)
		return FMRES_SUPERCEDE
	}
	
	return FMRES_IGNORED
}

//客户端命令
public fw_ClientCommand(id)
{
	new szCommand[24], szText[32];
	read_argv(0, szCommand, charsmax(szCommand));
	read_argv(1, szText, charsmax(szText));
	
	//未登录时
	if(!get_bit(g_isLogin, bit_id))
	{
		if(!strcmp(szCommand, "say"))
		{
			//注册与登录
			if(!get_bit(g_isRegister, bit_id))
				gm_user_register(id, szText);
			else
				gm_user_login(id, szText);
		}
		return FMRES_SUPERCEDE;
	}
	
	if(!strcmp(szCommand, "say"))
	{
		if(equal(szText, "/pwchange"))
		{
			set_task(1.0, "task_pw_change", id+TASK_PWCHANGE, _, _, "b")
			set_bit(g_isChangingPW, bit_id)
			return FMRES_SUPERCEDE;
		}
		if(get_bit(g_isChangingPW, bit_id))
		{
			gm_user_register(id, szText)
			return FMRES_SUPERCEDE;
		}
	}
	
	//Chooseteam
	if(!strcmp(szCommand, "chooseteam") || !strcmp(szCommand, "jointeam")) 
	{ 
		new team
		team = fm_cs_get_user_team(id)
	
		// 当此人为观察者可以换队
		if (team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED)
			return FMRES_IGNORED;
		
		if(get_bit(g_isLogin,bit_id))
			show_menu_main(id)
		
		return FMRES_SUPERCEDE;
	} 
	
	return FMRES_IGNORED;
}

public fw_ClientUserInfoChanged(id)
{
	//玩家是否使用自定义模型
	if(!get_bit(g_isModeled, bit_id))
		return FMRES_IGNORED;
	
	static RightModel[32]
	fm_get_user_model(id, RightModel, sizeof RightModel - 1)
	
	if(!equal(g_PlayerModel[id], RightModel))
		fm_set_user_model(id,g_PlayerModel[id])
	
	return FMRES_IGNORED;
}

public fw_SetClientKeyValue(id, const infobuffer[], const key[])
{
	// 阻止CS换模型
	if (get_bit(g_isModeled, bit_id) && equal(key, "model"))
		return FMRES_SUPERCEDE;
	
	return FMRES_IGNORED;
}

public fw_GetGameDescription()
{
	forward_return(FMV_STRING, Game_Description)
	return FMRES_SUPERCEDE;
}

/* =====================

			 Client
			 
===================== */

//进入服务器
public client_putinserver(id)
{
	set_bit(g_isConnect, bit_id)
	
	if(is_user_bot(id) && !g_hasBot)
	{
		set_task(0.1, "task_bots_ham", id+TASK_BOTHAM)
		return
	}
	g_LoginTime[id] = get_pcvar_num(cvar_LoginTime)
	delete_bit(g_isRegister, bit_id)
	delete_bit(g_isLogin, bit_id)
	gm_user_load(id)
	set_task(1.0, "task_user_login", id+TASK_USERLOGIN, _, _, "b")
}

public client_weapon_shoot(id)//MOUSE1
{
	
}

/* =====================

			 Tasks
			 
===================== */
public task_round_start()
{
	new id = gm_choose_boss()
	g_whoBoss = id
	for(new i = 1; i <= g_MaxPlayer; i++)
	{
		if(!is_user_valid_connected(i))
			continue;
		new team = fm_cs_get_user_team(i)
		if(team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED  || i == g_whoBoss)
			continue
		g_Online ++;
	}
	//get_pcvar_num(cvar_DevilHea) + (((760.8 + g_Online) * (g_Online - 1))
	new addhealth = floatround(floatpower(((760.8 + g_Online)*(g_Online - 1)), 1.0341) + get_pcvar_float(cvar_DevilHea))
	fm_set_user_health(id, addhealth)
	fm_cs_set_user_team(id, FM_CS_TEAM_T)
	
	fm_strip_user_weapons(id)
	give_item( id, "weapon_knife")

	set_pev(id, pev_viewmodel2, "models/v_devil_hand1.mdl")
	set_pev(id, pev_weaponmodel2, "")
	
	fm_set_user_model(id, "devil1")
	
	g_RoundStatus = Round_Running;
}

public task_balance()
{
	new team
	for(new id = 1; id <= g_MaxPlayer; id++)
	{
		if(!get_bit(g_isConnect, bit_id))
			continue
		
		team = fm_cs_get_user_team(id)
		if(team == FM_CS_TEAM_SPECTATOR || team == FM_CS_TEAM_UNASSIGNED)
			continue
		fm_cs_set_user_team(id, FM_CS_TEAM_CT)
		
	}
}

public task_showhud(id)
{
	id -= TASK_SHOWHUD
	
	set_hudmessage(25, 255, 25, 0.60, 0.80, 1, 1.0, 1.0, 0.0, 0.0, 0)
	ShowSyncHudMsg(id, g_Hud_Status, "HP:%d  |  Level:%d  |  Sp:%d  |  Coin:%d  |  Gash:%d^n累计伤害:%d  |  XP:%d/%d^nBossHP:%d",
	pev(id, pev_health), g_Level[id], g_Sp[id], g_Coin[id], g_Gash[id], floatround(g_Dmg[id]), g_Xp[id], g_NeedXp[id],get_user_health(g_whoBoss),g_Online)
}

public task_plrspawn(id)
{
	id -= TASK_PLRSPAWN
	fm_reset_user_model(id)
	fm_strip_user_weapons(id)
	fm_give_item(id, "weapon_knife")
	remove_task(id+TASK_PLRSPAWN);
}

public task_user_login(id)
{
	id-=TASK_USERLOGIN
	g_LoginTime[id] --
	msg_screen_fade(id, 0, 0, 0, 255)
	
	if(get_bit(g_isLogin, bit_id))
	{
		msg_screen_fade(id, 255, 255, 255, 0)
		remove_task(id+TASK_USERLOGIN)
	}
	
	if(!get_bit(g_isRegister, bit_id))
	{
		set_hudmessage(25, 255, 25, -1.0, -1.0, 1, 1.0, 1.0, 1.0, 1.0, 0)
		ShowSyncHudMsg(id, g_Hud_Center, "%L", LANG_PLAYER, "HUD_NO_REGISTER", g_LoginTime[id])
	}
	else
	{
		set_hudmessage(25, 255, 25, -1.0, -1.0, 1, 1.0, 1.0, 1.0, 1.0, 0)
		ShowSyncHudMsg(id, g_Hud_Center, "%L", LANG_PLAYER, "HUD_NO_LOGIN", g_LoginTime[id])
	}
	
	if(g_LoginTime[id] <= 0)
	{
		new Name[32]
		get_user_name(id, Name, charsmax(Name))
		server_cmd("kick %s", Name)
		remove_task(id+TASK_USERLOGIN)
	}
	
}

public task_pw_change(id)
{
	id-=TASK_PWCHANGE
	msg_screen_fade(id, 0, 0, 0, 255)
	set_hudmessage(25, 255, 25, -1.0, -1.0, 1, 1.0, 1.0, 1.0, 1.0, 0)
	ShowSyncHudMsg(id, g_Hud_Center, "%L", LANG_PLAYER, "HUD_CHANGING_PW")
	if(!get_bit(g_isChangingPW, bit_id))
	{
		msg_screen_fade(id, 255, 255, 255, 0)
		remove_task(id+TASK_PWCHANGE)
	}
		
}

public task_bots_ham(id)
{
	id-=TASK_BOTHAM
	if (!get_bit(g_isConnect, bit_id))
		return;
	
	RegisterHamFromEntity(Ham_Spawn, id, "fw_PlayerSpawn_Post", 1)
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage")
	RegisterHamFromEntity(Ham_TakeDamage, id, "fw_TakeDamage_Post", 1)
}

public task_refill_bpammo(const args[], id)
{
	if (!is_user_alive(id) || id == g_whoBoss)
		return;
	
	set_msg_block(get_user_msgid("AmmoPickup"), BLOCK_ONCE)
	ExecuteHamB(Ham_GiveAmmo, id, MAXBPAMMO[args[0]], AMMOTYPE[args[0]], MAXBPAMMO[args[0]])
}

public task_godmode_light(id)
{
	id -= TASK_GODMODE_LIGHT
	static origin[3]
	get_user_origin(id, origin)
	
	// Colored Aura
	message_begin(MSG_PVS, SVC_TEMPENTITY, origin)
	write_byte(TE_DLIGHT) // TE id
	write_coord(origin[0]) // x
	write_coord(origin[1]) // y
	write_coord(origin[2]) // z
	write_byte(20) // radius
	write_byte(255) // r
	write_byte(5) // g
	write_byte(5) // b
	write_byte(2) // life
	write_byte(0) // decay rate
	message_end()
}

public task_godmode_off(id)
{
	id -= TASK_GODMODE_OFF1
	
	set_pev(id, pev_takedamage, 2.0)
	delete_bit(g_isNoDamage, bit_id)
	fm_set_rendering(id,kRenderFxNone, 0,0,0, kRenderNormal, 0)
	remove_task( id+TASK_GODMODE_LIGHT )
}

public task_scare_off(id)
{
	id -= TASK_SCARE_OFF
	fm_set_rendering(id,kRenderFxNone, 0,0,0, kRenderNormal, 0)
	remove_task( id+TASK_SCARE_OFF )
}

public func_critical(taskid)
{
	static id
	if(taskid > g_MaxPlayer)
		id = taskid-TASK_CRITICAL
	else
		id = taskid
	
	if(g_whoBoss == id)
	{
		remove_task(taskid)
		delete_bit(g_isCrit, bit_id)
		return;
	}
	
	if(get_bit(g_isCrit, bit_id))
	{
		delete_bit(g_isCrit, bit_id)
		func_critical(id)
		return;
	}
	
	new percent = random_num(1,100)
	
	if(percent <= get_pcvar_num(cvar_HumanCritPercent))
	{
		set_bit(g_isCrit, bit_id)
		set_task(1.0,"func_critical",id+TASK_CRITICAL)
		return;
	}
	
	set_task(2.0,"func_critical",id+TASK_CRITICAL)
}

/* =====================

			 Menu
			 
===================== */
public show_menu_main(id)
{
	new Menu[256],Len;
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, Game_Description)
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "^n^n")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r1. \w%L^n", id, "MENU_WEAPON")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r2. \w%L^n", id, "MENU_SKILL")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r3. \w%L^n", id, "MENU_PACK")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r4. \w%L^n", id, "MENU_EQUIP")
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "^n^n\r0.\w %L", id, "MENU_EXIT")
	
	show_menu(id, KEYSMENU, Menu, -1, "Main Menu")
	return PLUGIN_HANDLED
}

public menu_main(id, key)
{
	switch(key)
	{
		case 0: show_menu_weapon1(id)
		case 1: show_menu_ability(id)
		case 2: show_menu_pack(id)
		case 3: show_menu_equip(id)
	}
	
	return PLUGIN_HANDLED;
}

public show_menu_weapon1(id)
{
	
}

public menu_weapon1(id, key)
{
	return PLUGIN_HANDLED;
}

public show_menu_pack(id)
{
	
}

public show_menu_equip(id)
{
	
}

public show_menu_skill(id)
{
	new Menu[250],Len;
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\w%L^n^n",id,"MENU_HUMANSKILL")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r1. \w%L^n",id,"HUMANSKILL_FASTRUN")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r2. \w%L^n",id,"HUMANSKILL_ONLYHEADSHOT")
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "^n^n\r0.\w %L", id, "MENU_EXIT")
	show_menu(id,KEYSMENU,Menu,-1,"Skill Menu")
	return PLUGIN_HANDLED
}

public menu_skill(id,key)
{
	switch(key)
	{
		case 0:
		{
			client_print(0, print_chat, "skillmenu 0")
		}
	}
	return PLUGIN_HANDLED;
}

public show_menu_ability(id)
{
	new Menu[256],Len;
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\w%L^n^n",id,"MENU_ABILITY")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r1. \w%L \d%d Sp  %d/%d^n", id,"ABILITY_HEALTH", get_pcvar_num(cvar_AbilityHeaCost), g_Abi_Hea[id], get_pcvar_num(cvar_AbilityHeaMax))
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r2. \w%L \d%d Sp  %d/%d^n", id,"ABILITY_AGILITY", get_pcvar_num(cvar_AbilityAgiCost), g_Abi_Agi[id], get_pcvar_num(cvar_AbilityHeaMax))
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r3. \w%L \d%d Sp  %d/%d^n", id,"ABILITY_STRENGTH", get_pcvar_num(cvar_AbilityStrCost), g_Abi_Str[id], get_pcvar_num(cvar_AbilityStrMax))
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r4. \w%L \d%d Sp  %d/%d^n", id,"ABILITY_GRAVITY", get_pcvar_num(cvar_AbilityGraCost), g_Abi_Gra[id], get_pcvar_num(cvar_AbilityGraMax))
	
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "^n^n\r0.\w %L", id, "MENU_EXIT")
	show_menu(id, KEYSMENU, Menu,-1,"Ability Menu")
	return PLUGIN_HANDLED
}

public menu_ability(id, key)
{
	if( key > 3 ) return PLUGIN_HANDLED
	
	new Sp_Cost[4]
	Sp_Cost[0] = get_pcvar_num(cvar_AbilityHeaCost); Sp_Cost[1] = get_pcvar_num(cvar_AbilityAgiCost)
	Sp_Cost[2] = get_pcvar_num(cvar_AbilityStrCost);  Sp_Cost[3] = get_pcvar_num(cvar_AbilityGraCost)
	// Abi_Max[0] = get_pcvar_num(cvar_AbilityHeaMax); Abi_Max[1] = get_pcvar_num(cvar_AbilityAgiMax)
	// Abi_Max[2] = get_pcvar_num(cvar_AbilityStrMax); Abi_Max[3] = get_pcvar_num(cvar_AbilityGraMax)
	
	
	if(g_Sp[id] < Sp_Cost[key])
	{
		client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "NO_SP");
		show_menu_ability(id)
		return PLUGIN_HANDLED
	}
			
	switch(key)
	{
		case 0: {
			if(g_Abi_Hea[id] >= get_pcvar_num(cvar_AbilityHeaMax)) 
			{
				client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "SKILL_LEARN_FULL");
				show_menu_ability(id)
				return PLUGIN_HANDLED
			}
			else g_Abi_Hea[id] ++;
		}
		case 1: {
			if(g_Abi_Agi[id] >= get_pcvar_num(cvar_AbilityAgiMax)) 
			{
				client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "SKILL_LEARN_FULL");
				show_menu_ability(id)
				return PLUGIN_HANDLED
			}
			else g_Abi_Agi[id] ++;
		}
		case 2: {
			if(g_Abi_Str[id] >= get_pcvar_num(cvar_AbilityStrMax)) 
			{
				client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "SKILL_LEARN_FULL");
				show_menu_ability(id)
				return PLUGIN_HANDLED
			}
			else g_Abi_Str[id] ++;
		}
		case 3: {
			if(g_Abi_Gra[id] >= get_pcvar_num(cvar_AbilityGraMax)) 
			{
				client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "SKILL_LEARN_FULL");
				show_menu_ability(id)
				return PLUGIN_HANDLED
			}
			else g_Abi_Gra[id] ++;
		}
	}
	
	g_Sp[id] -= Sp_Cost[key]		
	
	client_color_print(id, "^x04[DevilEscape]^x01%L", LANG_PLAYER, "SKILL_LEARN_SUCCESS");
	show_menu_ability(id)
	
	return PLUGIN_HANDLED
}

public show_menu_bossskill(id)
{
	new Menu[250],Len;
	
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\w%L^n^n",id,"MENU_BOSSSKILL")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r1. \w%L^n",id,"BOSSSKILL_SCARE")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r2. \w%L^n",id,"BOSSSKILL_BLIND")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r3. \w%L^n",id,"BOSSSKILL_TELEPORT")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "\r4. \w%L^n",id,"BOSSSKILL_GODMODE")
	Len += formatex(Menu[Len], sizeof Menu - Len - 1, "^n^n\r0.\w %L", id, "MENU_EXIT")
		
	show_menu(id,KEYSMENU,Menu,-1,"Bossskill Menu")
	return PLUGIN_HANDLED
}

public menu_bossskill(id,key)
{
	if(!is_user_valid_connected(id) || !is_user_alive(id) || g_RoundStatus == Round_End) return PLUGIN_HANDLED;
	new name[32], skillname[10]
	get_user_name(id, name, charsmax(name))
	switch(key)
	{
		case 0:
		{
			if(bossskill_scare(g_whoBoss,Float:{4000.0,400.0,1200.0},get_pcvar_float(cvar_DevilScareTime),get_pcvar_float(cvar_DevilScareRange)))
			{
				formatex(skillname, charsmax(skillname),"%L", LANG_PLAYER, "BOSSSKILL_SCARE")
				engfunc(EngFunc_EmitSound,g_whoBoss, CHAN_STATIC, snd_boss_scare, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				//扣魔力
				set_dhudmessage( 255, 255, 0, -1.0, 0.25, 1, 6.0, 3.0, 0.1, 1.5 );
				show_dhudmessage( 0, " %L", LANG_PLAYER, "DHUD_BOSS_USESKILL", name, skillname);
			}
		}
		case 2:
		{
			if(bossskill_teleport(g_whoBoss))
			{
				formatex(skillname, charsmax(skillname),"%L", LANG_PLAYER, "BOSSSKILL_TELEPORT")
				engfunc(EngFunc_EmitSound,g_whoBoss, CHAN_STATIC, snd_boss_tele, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				//扣魔力
				set_dhudmessage( 255, 255, 0, -1.0, 0.25, 1, 6.0, 3.0, 0.1, 1.5 );
				show_dhudmessage( 0, " %L", LANG_PLAYER, "DHUD_BOSS_USESKILL",name,skillname);
			}
		}
		
		case 3:
		{
			if(bossskill_godmode(g_whoBoss))
			{
				formatex(skillname, charsmax(skillname),"%L", LANG_PLAYER, "BOSSSKILL_GODMODE")
				engfunc(EngFunc_EmitSound,g_whoBoss, CHAN_STATIC, snd_boss_god, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
				set_dhudmessage( 255, 255, 0, -1.0, 0.25, 1, 6.0, 3.0, 0.1, 1.5 );
				show_dhudmessage( 0, " %L", LANG_PLAYER, "DHUD_BOSS_USESKILL",name,skillname);
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

/* =====================

			 Game Function
			 
===================== */

//选BOSS
gm_choose_boss()
{
	new id
	while(!is_user_alive(id) || !get_bit(g_isConnect, bit_id))
		id = random_num(1, g_MaxPlayer)
	
	return id
}

//重设变量
gm_reset_vars()
{
	g_whoBoss = -1;
	g_Online = 0;
	g_isNoDamage = 0;
	g_isCrit = 0;
	g_isMiniCrit = 0;
	for(new i = 1 ; i <= g_MaxPlayer; i++)
	{
		g_Dmg[i] = 0.0;
		g_AttackCooldown[i] = 0.0;
		remove_task(i+TASK_CRITICAL)
		func_critical(i);
	}
	
}

gm_user_register(id, const password[])
{
	msg_change_team_info(id, "SPECTATOR")
	new iteam[10]
	get_user_team(id, iteam, 9)
	
	new pw_len = strlen(password)
	if( pw_len > 12 || pw_len < 6)
	{
		client_color_print(id, "^x04[DevilEscape]^x03%L", LANG_PLAYER, "REGISTER_OUTOFLEN");
		return;
	}
	
	for(new i = 0; i < pw_len; i ++)
	{
		for(new j = 0; i < charsmax(InvalidChars); i++)
		{
			if( password[i] == InvalidChars[j])
			{
				client_color_print(id, "^x04[DevilEscape]^x03%L", LANG_PLAYER, "REGISTER_INVAILDCHAR");
				return;
			}
		}
	}
	
	//重要的事情说三遍
	client_color_print(id, "^x04[DevilEscape]%L^x03%s",  LANG_PLAYER, "REGISTER_SUCCESS", password)
	client_color_print(id, "^x04[DevilEscape]%L^x03%s",  LANG_PLAYER, "REGISTER_SUCCESS", password)
	client_color_print(id, "^x04[DevilEscape]%L^x03%s",  LANG_PLAYER, "REGISTER_SUCCESS", password)
	msg_change_team_info(id, iteam)
	
	set_bit(g_isRegister, bit_id)
	delete_bit(g_isChangingPW, bit_id)
	
	//储存密码
	new szFileDir[128], szUserName[32];
	get_user_name(id, szUserName, charsmax(szUserName))
	formatex(szFileDir, charsmax(szFileDir), "%s/%s.ini", g_savesDir, szUserName)
	
	new kv = kv_create(szUserName)
	kv_set_string(kv, "password", password);
	
	kv_save_to_file(kv, szFileDir);
	kv_delete(kv);
	
}

gm_user_login(id, const password[])
{
	new szUserName[32], szFileDir[128]
	get_user_name(id, szUserName, charsmax(szUserName))
	formatex(szFileDir, charsmax(szFileDir), "%s/%s.ini", g_savesDir, szUserName)
	new kv = kv_create();
	kv_load_from_file(kv, szFileDir)
	
	new save_pw[12]
	kv_find_key(kv, szUserName)
	kv_get_string(kv, "password", save_pw, charsmax(save_pw))
	static iteam[10]
	get_user_team(id, iteam, 9)
	msg_change_team_info(id, "SPECTATOR")
	
	if(equal(save_pw, password))
	{
		client_color_print(id, "^x04[DevilEscape]^x03%L",  LANG_PLAYER, "LOGIN_SUCCESS")
		client_color_print(id, "^x04[DevilEscape]^x03%L",  LANG_PLAYER, "LOGIN_SUCCESS")
		client_color_print(id, "^x04[DevilEscape]^x03%L",  LANG_PLAYER, "LOGIN_SUCCESS")
		set_bit(g_isLogin, bit_id)
		client_cmd(id, "chooseteam")
	}
	else
		client_color_print(id, "^x04[DevilEscape]^x03%L",  LANG_PLAYER, "LOGIN_FAILED")
	
	msg_change_team_info(id, iteam)
}

gm_user_load(id)
{
	new szUserName[32], szFileDir[128]
	get_user_name(id, szUserName, charsmax(szUserName))
	formatex(szFileDir, charsmax(szFileDir), "%s/%s.ini", g_savesDir, szUserName)
	new kv = kv_create();
	kv_load_from_file(kv, szFileDir)
	kv_find_key(kv, szUserName)
	
	//检测是否注册
	if(!kv_is_empty(kv))
		set_bit(g_isRegister, bit_id)
}

gm_create_fog()
{
	static ent 
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "env_fog"))
	if (pev_valid(ent))
	{
		fm_set_kvd(ent, "density", g_fog_denisty, "env_fog")
		fm_set_kvd(ent, "rendercolor", g_fog_color, "env_fog")
	}
}


gm_init_spawnpoint()
{
	new SpawnCount, ent
	while ((engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_start")) != 0)
	{
		pev(ent, pev_origin, g_CTSpawn[SpawnCount]);
		SpawnCount ++
		if(SpawnCount > sizeof g_CTSpawn) break;
	}
	while ((engfunc(EngFunc_FindEntityByString, ent, "classname", "info_player_deathmatch")) != 0)
	{
		pev(ent, pev_origin, g_TSpawn[SpawnCount]);
		SpawnCount ++
		if(SpawnCount > sizeof g_TSpawn) break;
	}
}

/* =====================

			 Message
			 
===================== */
public msg_health(msg_id, msg_dest, msg_entity)
{
	// Get player's health
	static health
	health = get_msg_arg_int(1)
	
	// Don't bother
	if (health < 256) return;
	
	// Check if we need to fix it
	if (health % 256 == 0)
		fm_set_user_health(msg_entity, pev(msg_entity, pev_health) + 1)
	
	// HUD can only show as much as 255 hp
	set_msg_arg_int(1, get_msg_argtype(1), 255)
}

// 阻止一些textmsg
public msg_textmsg()
{
	static textmsg[32]
	get_msg_arg_string(2, textmsg, sizeof textmsg - 1)
	
	if (equal(textmsg, "#Hostages_Not_Rescued") || equal(textmsg, "#Round_Draw") || equal(textmsg, "#Terrorists_Win") || equal(textmsg, "#CTs_Win") || 
	equal(textmsg, "#C4_Arming_Cancelled") || equal(textmsg, "#C4_Plant_At_Bomb_Spot") || equal(textmsg, "#Killed_Hostage") || equal(textmsg, "#Game_will_restart_in") )
		return PLUGIN_HANDLED
		
	return PLUGIN_CONTINUE;
}

//阻止cs胜利/失败音效
public msg_sendaudio()
{
	static audio[17]
	get_msg_arg_string(2, audio, charsmax(audio))
	
	if(equal(audio[7], "terwin") || equal(audio[7], "ctwin") || equal(audio[7], "rounddraw"))
		return PLUGIN_HANDLED;
	
	return PLUGIN_CONTINUE;
}

public msg_statusicon(msgid, dest, id)
{
	static szMsg[8]
	static const BuyMsg[] = "buyzone"
	get_msg_arg_string(2, szMsg, 7)
	
	if(equal(szMsg, BuyMsg))
	{
		set_pdata_int(id, m_MapZone, get_pdata_int(id, m_MapZone)& ~( 1<<0 ));
		return PLUGIN_HANDLED
	}
	
	return PLUGIN_CONTINUE
}


public msg_show_menu(msgid, dest, id)
{
	static team_select[] = "#Team_Select_Spect"
	static menu_text_code[sizeof team_select]
	get_msg_arg_string(4, menu_text_code, sizeof menu_text_code - 1)
	
	client_print(id, print_center, "%s", menu_text_code)
	
	if (!equal(menu_text_code, team_select))
		return PLUGIN_CONTINUE
	
	return PLUGIN_HANDLED
}

public msg_vgui_menu(msgid, dest, id)
{
	if (get_msg_arg_int(1) != 2)
		return PLUGIN_CONTINUE
	
	show_menu(id, 51, "#Team_Select_Spect", -1)
	return PLUGIN_HANDLED
}

public menu_team_select(id, key)
{
	if(!get_bit(g_isLogin, bit_id))
	return PLUGIN_HANDLED;
	switch(key)
	{
		case 0:	//T
		{
			team_join(id,"2")
			return PLUGIN_HANDLED;
		}
		case 4:	//Auto
		{
			team_join(id,"2")
			return PLUGIN_HANDLED;
		}
	}
	return PLUGIN_CONTINUE;
}

/* =====================

			 Skill
			 
===================== */
public bossskill_scare(id,Float:force[3],Float:dealytime,Float:radius)
{
	new Float:idorg[3]
	pev(id,pev_origin,idorg)
	msg_create_lightring(idorg, radius, {128, 28, 28})

	new target
	while(0<(target=engfunc(EngFunc_FindEntityInSphere,target,idorg,radius))<=g_MaxPlayer)
	{
		if(target==id) continue;
		
		fm_set_rendering(target,kRenderFxGlowShell,128, 128, 128, kRenderNormal, 32);
		g_AttackCooldown[target] = get_gametime() + dealytime
		msg_show_scare(target)
		set_task(dealytime, "task_scare_off", target+TASK_SCARE_OFF);
		if(!is_user_bot(target)) set_view(target,CAMERA_3RDPERSON);
	}
	return 1;
}

public bossskill_teleport(id)
{
	new target
	while(!is_user_alive(target) || g_whoBoss == target)
		target = random_num(1, g_MaxPlayer)
	
	new idorg[3]
	
	get_user_origin(target,idorg)
	idorg[2] = idorg[2] + 10
	set_user_origin(id,idorg)
	
	g_AttackCooldown[id] = get_gametime() + 1.5
	
	return 1;
}

public bossskill_godmode(id)
{
	set_pev(id, pev_takedamage, 0.0)
	set_bit(g_isNoDamage, bit_id)
	fm_set_rendering(id,kRenderFxGlowShell,250,0,0, kRenderNormal, 32);
	set_task(0.1, "task_godmode_light", id+TASK_GODMODE_LIGHT, _, _, "b")
	set_task(get_pcvar_float(cvar_DevilGodTime), "task_godmode_off", TASK_GODMODE_OFF1 + id)
	
	return 1;
}

/* ==========================

					[Stocks]
			 
==========================*/


/* =====================

			 Getter
			 
===================== */
stock fm_cs_get_user_team(id)
{
	return get_pdata_int(id, m_CsTeam);
}

stock fm_get_user_model(id, model[], len)
{
	return engfunc(EngFunc_InfoKeyValue, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model, len)
}

/* =====================

			 Setter
			 
===================== */
stock fm_cs_set_user_team(id, team)
{
	set_pdata_int(id, m_CsTeam, team)
	fm_cs_set_user_team_msg(id)
	switch(team)
	{
		case FM_CS_TEAM_CT:
			set_bit(g_plrTeam, bit_id)
		case FM_CS_TEAM_T:
			delete_bit(g_plrTeam, bit_id)
	}
}

stock fm_cs_set_user_team_msg(id)
{
	new const team_names[][] = { "UNASSIGNED", "TERRORIST", "CT", "SPECTATOR" }
	message_begin(MSG_ALL, get_user_msgid("TeamInfo"))
	write_byte(id) // player
	write_string(team_names[fm_cs_get_user_team(id)]) // team
	message_end()
}

stock fm_set_user_health(id, health)
{
	if(get_bit(g_isConnect, bit_id))
		(health > 0 ) ? set_pev(id, pev_health, float(health)) : dllfunc(DLLFunc_ClientKill, id);
	else return;
}

//设定模型
stock fm_cs_set_user_model(id, const model[])
{
	set_user_info(id, "model", model)
}

//设定模型2
stock fm_set_user_model(id, const model[])
{
	set_bit(g_isModeled, bit_id)
	engfunc(EngFunc_SetClientKeyValue, id, engfunc(EngFunc_GetInfoKeyBuffer, id), "model", model)
	copy(g_PlayerModel[id], sizeof g_PlayerModel[] - 1, model)
	
	// static ModelPath[64]
	// formatex(ModelPath, charsmax(ModelPath), "models/player/%s", model)
	// set_pdata_int(id, m_ModelIndex, engfunc(EngFunc_ModelIndex, ModelPath))
}

//重置模型
stock fm_reset_user_model(id)
{
	if (!get_bit(g_isConnect, bit_id))
		return

	delete_bit(g_isModeled, bit_id)
	dllfunc(DLLFunc_ClientUserInfoChanged, id, engfunc(EngFunc_GetInfoKeyBuffer, id))
}

//设置渲染
stock fm_set_rendering(entity, fx = kRenderFxNone, r = 255, g = 255, b = 255, render = kRenderNormal, amount = 16)
{
	static Float:color[3]
	color[0] = float(r)
	color[1] = float(g)
	color[2] = float(b)
	
	set_pev(entity, pev_renderfx, fx)
	set_pev(entity, pev_rendercolor, color)
	set_pev(entity, pev_rendermode, render)
	set_pev(entity, pev_renderamt, float(amount))
}

/* =====================

			 Entity
			 
===================== */

stock fm_set_kvd(entity, const key[], const value[], const classname[])
{
	set_kvd(0, KV_ClassName, classname)
	set_kvd(0, KV_KeyName, key)
	set_kvd(0, KV_Value, value)
	set_kvd(0, KV_fHandled, 0)

	dllfunc(DLLFunc_KeyValue, entity, 0)
}

stock fm_give_item(id, const item[])
{
	static ent
	ent = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, item))
	if (!pev_valid(ent)) return;
	
	static Float:originF[3]
	pev(id, pev_origin, originF)
	set_pev(ent, pev_origin, originF)
	set_pev(ent, pev_spawnflags, pev(ent, pev_spawnflags) | SF_NORESPAWN)
	dllfunc(DLLFunc_Spawn, ent)
	
	static save
	save = pev(ent, pev_solid)
	dllfunc(DLLFunc_Touch, ent, id)
	if (pev(ent, pev_solid) != save)
		return;
	
	engfunc(EngFunc_RemoveEntity, ent)
}


stock fm_strip_user_weapons( index )
{
   new iEnt = engfunc( EngFunc_CreateNamedEntity, engfunc( EngFunc_AllocString, "player_weaponstrip" ) );
   if( !pev_valid( iEnt ) )
      return 0;

   dllfunc( DLLFunc_Spawn, iEnt );
   dllfunc( DLLFunc_Use, iEnt, index );
   engfunc( EngFunc_RemoveEntity, iEnt );

   return 1;
}

stock fm_get_entity_index(owner,entclassname[])
{
	new ent = 0
	while ((ent = engfunc(EngFunc_FindEntityByString, ent, "classname", entclassname))!=0 )
	{
		if(pev(ent,pev_owner)==owner)
		{
			return ent
		}
	}
	return 0
}

stock fm_get_speed_vector(origin1[3],origin2[3],Float:force, new_velocity[3]){
    new_velocity[0] = origin2[0] - origin1[0]
    new_velocity[1] = origin2[1] - origin1[1]
    new_velocity[2] = origin2[2] - origin1[2]
    new Float:num = floatsqroot(force*force / (new_velocity[0]*new_velocity[0] + new_velocity[1]*new_velocity[1] + new_velocity[2]*new_velocity[2]))
    new_velocity[0] *= floatround(num)
    new_velocity[1] *= floatround(num)
    new_velocity[2] *= floatround(num)

    return 1;
}

/* =====================

			 Msg
			 
===================== */
stock msg_screen_fade(id, red, green, blue, alpha)
{
	message_begin(MSG_ONE, get_user_msgid("ScreenFade"), _, id)
	write_short(0)// Duration
	write_short(0)// Hold time
	write_short(( 1<<0 ) | ( 1<<2 ) )// Fade type
	write_byte (red)// Red
	write_byte (green)// Green
	write_byte (blue)// Blue
	write_byte (alpha)// Alpha
	message_end()
}

stock msg_change_team_info(id, team[])
{
	message_begin (MSG_ONE, get_user_msgid ("TeamInfo"), _, id)	// Tells to to modify teamInfo (Which is responsable for which time player is)
	write_byte (id)				// Write byte needed
	write_string (team)				// Changes player's team
	message_end()					// Also Needed
}

stock msg_trace(idorigin[3],targetorigin[3],crit){
	if(crit){
		new velfloat[3]
		fm_get_speed_vector(idorigin, targetorigin, 4000.0, velfloat)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_USERTRACER)
		write_coord(idorigin[0])
		write_coord(idorigin[1])
		write_coord(idorigin[2])
		write_coord(velfloat[0])
		write_coord(velfloat[1])
		write_coord(velfloat[2])
		write_byte(12)
		write_byte(3)
		write_byte(25)
		message_end()
	}else{
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(6);
		write_coord(idorigin[0]);
		write_coord(idorigin[1]);
		write_coord(idorigin[2]);
		write_coord(targetorigin[0]);
		write_coord(targetorigin[1]);
		write_coord(targetorigin[2]);
		message_end();
	}
}

stock msg_create_lightring(const Float:originF[3], const Float:radius = 100.0, rgb[3] = {100, 100, 100})
{
	// Smallest ring
	engfunc(EngFunc_MessageBegin, MSG_PVS, SVC_TEMPENTITY, originF, 0)
	write_byte(TE_BEAMCYLINDER) // TE id
	engfunc(EngFunc_WriteCoord, originF[0]) // x
	engfunc(EngFunc_WriteCoord, originF[1]) // y
	engfunc(EngFunc_WriteCoord, originF[2]) // z
	engfunc(EngFunc_WriteCoord, originF[0]) // x axis
	engfunc(EngFunc_WriteCoord, originF[1]) // y axis
	engfunc(EngFunc_WriteCoord, originF[2]+ radius) // z axis
	write_short(g_spr_ring) // sprite
	write_byte(0) // startframe
	write_byte(0) // framerate
	write_byte(4) // life
	write_byte(15) // width
	write_byte(0) // noise
	write_byte(rgb[0]) // red
	write_byte(rgb[1]) // green
	write_byte(rgb[2]) // blue
	write_byte(200) // brightness
	write_byte(0) // speed
	message_end()

}

stock msg_create_crit(id, target,type){
	if(!is_user_alive(id) || !is_user_alive(target) || id == target) return;
	if(type == 1)	//大暴击
	{
		engfunc(EngFunc_EmitSound,id, CHAN_STATIC,snd_crit_hit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_EmitSound,target, CHAN_STATIC,snd_crit_received, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		new iorigin[3], Float:forigin[3]
		pev(target, pev_origin, forigin)
		FVecIVec(forigin, iorigin)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BUBBLES)
		write_coord(iorigin[0])//位置
		write_coord(iorigin[1])
		write_coord(iorigin[2] + 16)
		write_coord(iorigin[0])//位置
		write_coord(iorigin[1])
		write_coord(iorigin[2] + 32)
		write_coord(192)
		write_short(g_spr_crit)
		write_byte(1)
		write_coord(30)
		message_end()
	}
	else	//小暴击
	{
		engfunc(EngFunc_EmitSound,id, CHAN_STATIC,snd_minicrit_hit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		engfunc(EngFunc_EmitSound,target, CHAN_STATIC,snd_minicrit_hit, VOL_NORM, ATTN_NORM, 0, PITCH_NORM)
		new iorigin[3], Float:forigin[3]
		pev(target, pev_origin, forigin)
		FVecIVec(forigin, iorigin)
		message_begin(MSG_BROADCAST, SVC_TEMPENTITY)
		write_byte(TE_BUBBLES)
		write_coord(iorigin[0])//位置
		write_coord(iorigin[1])
		write_coord(iorigin[2] + 16)
		write_coord(iorigin[0])//位置
		write_coord(iorigin[1])
		write_coord(iorigin[2] + 32)
		write_coord(192)
		write_short(g_spr_minicrit)
		write_byte(1)
		write_coord(30)
		message_end()
	}
}

stock msg_show_scare(id)
{
	message_begin( MSG_ALL, SVC_TEMPENTITY );
	write_byte(TE_PLAYERATTACHMENT);
	write_byte(id);
	write_coord(45);
	write_short(g_spr_scare); 
	write_short(50);
	message_end();
}

/* =====================

			 Other
			 
===================== */

stock client_color_print(target,  const message[], any:...)
{
	static buffer[512], i, argscount
	argscount = numargs()
	// 发送给所有人
	if (!target)
	{
		static player
		for (player = 1; player <= g_MaxPlayer; player++)
		{
			// 断线
			if (!get_bit(g_isConnect, player-1))
				continue;
			
			// 记住变化的变量
			static changed[5], changedcount // [5] = max LANG_PLAYER occurencies
			changedcount = 0
			
			// 将player id 取代LANG_PLAYER
			for (i = 2; i < argscount; i++)
			{
				if (getarg(i) == LANG_PLAYER)
				{
					setarg(i, 0, player)
					changed[changedcount] = i
					changedcount++
				}
			}
			
			// Format信息给玩家
			vformat(buffer, charsmax(buffer), message, 3)
			
			// 发送信息
			message_begin(MSG_ONE_UNRELIABLE, get_user_msgid("SayText"), _, player)
			write_byte(player)
			write_string(buffer)
			message_end()
			
			// 将back player id 取代LANG_PLAYER
			for (i = 0; i < changedcount; i++)
				setarg(changed[i], 0, LANG_PLAYER)
		}
	}
	// 发送给指定目标
	else
	{
		vformat(buffer, charsmax(buffer), message, 3)
		message_begin(MSG_ONE, get_user_msgid("SayText"), _, target)
		write_byte(target)
		write_string(buffer)
		message_end()
	}
}

team_join(id, team[] = "5")
{
	new msg_block = get_msg_block(g_Msg_ShowMenu)
	set_msg_block(g_Msg_ShowMenu, BLOCK_SET)
	engclient_cmd(id, "jointeam", team)
	set_msg_block(g_Msg_ShowMenu, msg_block)
}


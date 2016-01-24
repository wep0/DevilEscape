#include <amxmodx>
#include <amxmisc>
#include <fakemeta>
#include <hamsandwich>
#include <devilescape>

#define PLUGIN_NAME "道具列表(For De)"
#define PLUGIN_VERSION "0.0"
#define PLUGIN_AUTHOR "DevilEscape"

//ItemID
enum{
	ITEM_NONE, ITEM_G_HERB, ITEM_R_HERB, ITEM_GOLD_HERB, ITEM_LATIAO, ITEM_DIOKELA, ITEM_XUMING
}
new g_Itemid[32];
new cvar_g_herb_reco, cvar_r_herb_reco, cvar_gold_herb_reco, cvar_latiao_reco, cvar_diokela_reco, cvar_xuming_reco

new const ITEM_NAME[][] = {"无", "绿色药草", "红色药草", "金疮药", "辣条", "屌克拉", "续命"}
new const ITEM_INFO[][] = {"", "绿色的药草,恢复到100HP", "红色的药草,恢复到150HP", "江湖必备金疮药,恢复到200HP", 
									   "来包辣条冷静一下,恢复到250HP", "掺了屌克拉,一袋能顶两袋撒,恢复到350HP",
									   "来自长者的续命秘法,恢复到500HP"}

public plugin_init()
{
	register_plugin(PLUGIN_NAME, PLUGIN_VERSION, PLUGIN_AUTHOR);
	
	for(new i = 0; i < sizeof ITEM_NAME; i++)
		g_Itemid[i] = de_register_item(ITEM_NAME[i], ITEM_INFO[i])
	
	
	cvar_g_herb_reco = register_cvar("de_item_gherb_reco","100.0")
	cvar_r_herb_reco = register_cvar("de_item_rherb_reco","150.0")
	cvar_gold_herb_reco = register_cvar("de_item_goldherb_reco","200.0")
	cvar_latiao_reco = register_cvar("de_item_latiao_reco","250.0")
	cvar_diokela_reco = register_cvar("de_item_diokela_reco","350.0")
	cvar_xuming_reco = register_cvar("de_item_xuming_reco","500.0")
	
}

public de_item_select(id, itemid)
{
	if(itemid == g_Itemid[ITEM_G_HERB])			 set_pev(id, pev_health, get_pcvar_float(cvar_g_herb_reco))
	else if(itemid == g_Itemid[ITEM_R_HERB])		 set_pev(id, pev_health, get_pcvar_float(cvar_r_herb_reco))
	else if(itemid == g_Itemid[ITEM_GOLD_HERB]) set_pev(id, pev_health, get_pcvar_float(cvar_gold_herb_reco))
	else if(itemid == g_Itemid[ITEM_LATIAO])		 set_pev(id, pev_health, get_pcvar_float(cvar_latiao_reco))
	else if(itemid == g_Itemid[ITEM_DIOKELA])	 set_pev(id, pev_health, get_pcvar_float(cvar_diokela_reco))
	else if(itemid == g_Itemid[ITEM_XUMING])	 set_pev(id, pev_health, get_pcvar_float(cvar_xuming_reco))
		
	return 998
}





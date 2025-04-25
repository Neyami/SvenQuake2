namespace q2
{

bool g_bMapsRerelease = true;

int g_iTotalGoals; //level.total_goals
int g_iFoundGoals; //level.found_goals

int g_iTotalSecrets; //level.total_secrets
int g_iFoundSecrets; //level.found_secrets

int g_iTotalMonsters; //level.total_monsters
int g_iKilledMonsters; //level.killed_monsters

float g_flUpdateHelpComputer;

int g_iGameHelpChanged; //game.helpchanged
string g_sGameHelpMessage1; //game.helpmessage1
string g_sGameHelpMessage2; //game.helpmessage2


const int CHANNEL_HELP						= 4;
const string KVN_HELP_CHANGED			= "$i_q2helpchanged"; //client->pers.helpchanged
const string KVN_GAME_HELPCHANGED	= "$i_q2ghc"; //client->pers.game_helpchanged
const string KVN_HELP_SHOW				= "$i_q2helpopen"; //client->showhelp
const string KVN_HELP_SOUND				= "$f_q2helpsound"; //client->pers.help_time
const string KVN_HELP_ICON					= "$f_q2helpicon";
const string SPRITE_HELPCOMP				= "quake2/pics/help.spr";
const string SPRITE_HELPCOMP2				= "quake2/pics/help2.spr"; //Primary and Secondary
const string SPRITE_HELPCOMP3				= "quake2/pics/help3.spr"; //Primary only
const string SPRITE_HELPCOMP4				= "quake2/pics/help4.spr"; //Secondary only

dictionary g_dicLevelNames =
{
	{ "q2jorgarena", "Quake 2 Test Map" }, //temp
	{ "q2jorgarena2", "Quake 2 Test Map" }, //temp
    { "q2_base1", "Outer Base" },
    { "q2_base2", "Installation" },
    { "q2_base3", "Comm Center" },
    { "q2_train", "Lost Station" },
	{ "q2_train2", "Lost Station" }, //temp
    { "q2_bunk1", "Ammo Depot" },
    { "q2_ware1", "Supply Station" },
    { "q2_ware2", "Warehouse" },
    { "q2_jail1", "Main Gate" },
    { "q2_jail2", "Detention Center" },
    { "q2_jail3", "Security Complex" },
    { "q2_jail4", "Torture Chambers" },
    { "q2_jail5", "Guard House" },
    { "q2_security", "Grid Control" },
    { "q2_mintro", "Mine Entrance" },
    { "q2_mine1", "Upper Mines" },
    { "q2_mine2", "Borehole" },
    { "q2_mine3", "Drilling Area" },
    { "q2_mine4", "Lower Mines" },
    { "q2_fact1", "Receiving Center" },
    { "q2_fact2", "Processing Plant" },
    { "q2_fact3", "Sudden Death" },
    { "q2_power1", "Power Plant" },
    { "q2_power2", "The Reactor" },
    { "q2_cool1", "Cooling Facility" },
    { "q2_waste1", "Toxic Waste Dump" },
    { "q2_waste2", "Pumping Station 1" },
    { "q2_waste3", "Pumping Station 2" },
    { "q2_biggun", "Big Gun" },
    { "q2_hangar1", "Outer Hangar" },
    { "q2_space", "Comm Satellite" },
    { "q2_lab", "Research Lab" },
    { "q2_hangar2", "Inner Hangar" },
    { "q2_command", "Launch Command" },
    { "q2_strike", "Outlands" },
    { "q2_city1", "Outer Courts" },
    { "q2_city2", "Lower Palace" },
    { "q2_city3", "Upper Palace" },
    { "q2_boss1", "Inner Chamber" },
    { "q2_boss2", "Final Showdown" }
};

void InitializeMaps()
{
	g_iGameHelpChanged = 0;

	g_Game.PrecacheModel( "sprites/" + SPRITE_HELPCOMP );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HELPCOMP2 );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HELPCOMP3 );
	g_Game.PrecacheModel( "sprites/" + SPRITE_HELPCOMP4 );

	g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @MapsPlayerPreThink );
}

HookReturnCode MapsPlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 or q2::PVP )
		return HOOK_CONTINUE;

	if( g_Engine.time > g_flUpdateHelpComputer )
	{
		if( pPlayer.IsAlive() )
			UpdateHelpComputer( pPlayer );

		g_flUpdateHelpComputer = g_Engine.time + 0.1;
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if( GetInteger(pPlayer, KVN_HELP_SHOW) > 0 )
		ShowHelpComputerInfo( pPlayer );

	if( (pPlayer.m_afButtonPressed & IN_SCORE) != 0 )
	{
		if( pCustom.GetKeyvalue(KVN_HELP_SHOW).GetInteger() > 0 and pCustom.GetKeyvalue(KVN_GAME_HELPCHANGED).GetInteger() == g_iGameHelpChanged )
		{
			pCustom.SetKeyvalue( KVN_HELP_SHOW, 0 );
			g_PlayerFuncs.HudToggleElement( pPlayer, CHANNEL_HELP, false );
			//globals.server_flags &= ~SERVER_FLAG_SLOW_TIME;
			return HOOK_CONTINUE;
		}

		pCustom.SetKeyvalue( KVN_HELP_SHOW, 1 );
		pCustom.SetKeyvalue( KVN_HELP_CHANGED, 0 );
		//globals.server_flags |= SERVER_FLAG_SLOW_TIME;
		HelpComputer( pPlayer );
	}

	return HOOK_CONTINUE;
}

void UpdateHelpComputer( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if( GetInteger(pPlayer, KVN_GAME_HELPCHANGED) != g_iGameHelpChanged )
	{
		pCustom.SetKeyvalue( KVN_GAME_HELPCHANGED, g_iGameHelpChanged );
		pCustom.SetKeyvalue( KVN_HELP_CHANGED, 1 );
	}

	int iHelpChanged = GetInteger( pPlayer, KVN_HELP_CHANGED );
	// help beep (no more than three times)
	if( iHelpChanged > 0 and iHelpChanged <= 3 and pCustom.GetKeyvalue(KVN_HELP_SOUND).GetFloat() < g_Engine.time ) // !(level.framenum&63) )
	{
		if( !g_bMapsRerelease or (g_bMapsRerelease and iHelpChanged == 1) ) //once only, in rerelease
		{
			NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_STUFFTEXT, pPlayer.edict() );
				m1.WriteString( "speak quake2/misc/pc_up.wav\n" );
			m1.End();

			//gi.sound (ent, CHAN_VOICE, gi.soundindex ("misc/pc_up.wav"), 1, ATTN_STATIC, 0);
		}

		iHelpChanged++;
		pCustom.SetKeyvalue( KVN_HELP_CHANGED, iHelpChanged );
		pCustom.SetKeyvalue( KVN_HELP_SOUND, g_Engine.time + 5.0 );
	}

	//blink help icon 10 times, 1 second on, 1 second off ??
	/*int iHelpChanged = GetInteger( pPlayer, KVN_HELP_CHANGED2 );
	if( iHelpChanged >= 1 and iHelpChanged <= 2 and ((g_Engine.time * 1000) % 1000) < 500 )
		g_Game.AlertMessage( at_notice, "DISPLAY HELP ICON\n" );*/

/*
	if (ent->client->pers.helpchanged && (level.framenum&8) )
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex ("i_help");
	else if ( (ent->client->pers.hand == CENTER_HANDED || ent->client->ps.fov > 91)
		&& ent->client->pers.weapon)
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex (ent->client->pers.weapon->icon);
	else
		ent->client->ps.stats[STAT_HELPICON] = 0;
*/
	/*if (ent->client->pers.helpchanged >= 1 && ent->client->pers.helpchanged <= 2 && (level.time.milliseconds() % 1000) < 500) // haleyjd: time
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex ("i_help");
	else if ( (ent->client->pers.hand == CENTER_HANDED || ent->client->ps.fov > 91)
		&& ent->client->pers.weapon)
		ent->client->ps.stats[STAT_HELPICON] = gi.imageindex (ent->client->pers.weapon->icon);
	else
		ent->client->ps.stats[STAT_HELPICON] = 0;*/
}

void HelpComputer( CBasePlayer@ pPlayer )
{
	HUDSpriteParams hudParamsHelpComputer;

	hudParamsHelpComputer.channel = CHANNEL_HELP;
	hudParamsHelpComputer.flags = HUD_ELEM_ABSOLUTE_Y | HUD_ELEM_SCR_CENTER_Y | HUD_ELEM_SCR_CENTER_X | HUD_SPR_MASKED; //HUD_ELEM_DEFAULT_ALPHA

	if( g_sGameHelpMessage1.IsEmpty() and g_sGameHelpMessage2.IsEmpty() )
		hudParamsHelpComputer.spritename = SPRITE_HELPCOMP;
	else if( !g_sGameHelpMessage1.IsEmpty() and !g_sGameHelpMessage2.IsEmpty() )
		hudParamsHelpComputer.spritename = SPRITE_HELPCOMP2;
	else if( !g_sGameHelpMessage1.IsEmpty() and g_sGameHelpMessage2.IsEmpty() )
		hudParamsHelpComputer.spritename = SPRITE_HELPCOMP3;
	else if( g_sGameHelpMessage1.IsEmpty() and !g_sGameHelpMessage2.IsEmpty() )
		hudParamsHelpComputer.spritename = SPRITE_HELPCOMP4;

	hudParamsHelpComputer.x = 0;
	hudParamsHelpComputer.y = 0;
	hudParamsHelpComputer.color1 = RGBA_WHITE;

	g_PlayerFuncs.HudCustomSprite( pPlayer, hudParamsHelpComputer );

	ShowHelpComputerInfo( pPlayer );
}

void ShowHelpComputerInfo( CBasePlayer@ pPlayer )
{
	string sDifficultyName;
	if( q2npc::g_iDifficulty == q2npc::DIFF_EASY )
		sDifficultyName = "Easy";
	else if( q2npc::g_iDifficulty == q2npc::DIFF_NORMAL )
		sDifficultyName = "Medium";
	else if( q2npc::g_iDifficulty == q2npc::DIFF_HARD )
		sDifficultyName = "Hard";
	else
		sDifficultyName = "Nightmare";

	string sLevelName;
	g_dicLevelNames.get( g_Engine.mapname, sLevelName );

	HUDTextParams textParamsLevelName, textParamsPrimaryObjective, textParamsSecondaryObjective, textParamsDiffGoalsKillsSecrets;

	textParamsPrimaryObjective.r1 = textParamsSecondaryObjective.r1 = 255;
	textParamsPrimaryObjective.g1 = textParamsSecondaryObjective.g1 = 255;
	textParamsPrimaryObjective.b1 = textParamsSecondaryObjective.b1 = 255;
	textParamsLevelName.r1 = textParamsDiffGoalsKillsSecrets.r1 = 89;
	textParamsLevelName.g1 = textParamsDiffGoalsKillsSecrets.g1 = 184;
	textParamsLevelName.b1 = textParamsDiffGoalsKillsSecrets.b1 = 30;

	float flPositionY = 0.4;
	textParamsPrimaryObjective.x = -1.0; //0.45 //pPlayer.pev.dmgtime;
	textParamsPrimaryObjective.y = flPositionY; //pPlayer.pev.frags;

	if( !g_sGameHelpMessage1.IsEmpty() )
		flPositionY += 0.15;

	textParamsSecondaryObjective.x = -1.0;
	textParamsSecondaryObjective.y = flPositionY;

	textParamsLevelName.x = -1.0; //0.445
	textParamsLevelName.y = 0.31;
	textParamsDiffGoalsKillsSecrets.x = 0.36;
	textParamsDiffGoalsKillsSecrets.y = 0.63;

	textParamsLevelName.effect = textParamsPrimaryObjective.effect = textParamsSecondaryObjective.effect = textParamsDiffGoalsKillsSecrets.effect = 0;
	textParamsLevelName.holdTime = textParamsPrimaryObjective.holdTime = textParamsSecondaryObjective.holdTime = textParamsDiffGoalsKillsSecrets.holdTime = 0.02;
	textParamsLevelName.fadeinTime = textParamsPrimaryObjective.fadeinTime = textParamsSecondaryObjective.fadeinTime = textParamsDiffGoalsKillsSecrets.fadeinTime = 0.0;
	textParamsLevelName.fadeoutTime = textParamsPrimaryObjective.fadeoutTime = textParamsSecondaryObjective.fadeoutTime = textParamsDiffGoalsKillsSecrets.fadeoutTime = 0.0;

	textParamsLevelName.channel				= CHANNEL_HELP+1;
	textParamsPrimaryObjective.channel		= CHANNEL_HELP+2;
	textParamsSecondaryObjective.channel	= CHANNEL_HELP+3;
	textParamsDiffGoalsKillsSecrets.channel	= CHANNEL_HELP+4;

	g_PlayerFuncs.HudMessage( pPlayer, textParamsLevelName, sLevelName );

	if( !g_sGameHelpMessage1.IsEmpty() )
		g_PlayerFuncs.HudMessage( pPlayer, textParamsPrimaryObjective, g_sGameHelpMessage1 );

	if( !g_sGameHelpMessage2.IsEmpty() )
		g_PlayerFuncs.HudMessage( pPlayer, textParamsSecondaryObjective, g_sGameHelpMessage2 );

	g_PlayerFuncs.HudMessage( pPlayer, textParamsDiffGoalsKillsSecrets, sDifficultyName + "                                      " + "Goals: " + g_iFoundGoals + "/" + g_iTotalGoals + "\n" +
																										"Kills: " + g_iKilledMonsters + "/" + g_iTotalMonsters + "                                     " + "Secrets: " + g_iFoundSecrets + "/" + g_iTotalSecrets );
}

int GetInteger( CBasePlayer@ pPlayer, string sKVN )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	return pCustom.GetKeyvalue(sKVN).GetInteger();
}

} //end of namespace q2
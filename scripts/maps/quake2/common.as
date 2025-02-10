#include "q2funcs"
#include "items"
#include "npcs"
#include "weapons"

namespace q2
{

bool PVP 											= false;
const bool USE_QUAKE2_ITEMS			= true;
const bool USE_QUAKE2_NPCS			= true;
const bool USE_QUAKE2_WEAPONS		= true;
const bool USE_QUAKE2_EXTRAS		= true; //fall damage, pain sounds, jumping sounds
const bool USE_QUAKE2_VIEWOFS		= true; //sets view_ofs.z to 10 on Quake 2 maps
const float QUAKE2_VIEWOFS				= 10.0;

const uint8 Q2_FALLDAMAGE = 1;
float g_flItemThink; //??

const array<string> pStepSounds = 
{
	"quake2/player/step1.wav",
	"quake2/player/step2.wav",
	"quake2/player/step3.wav",
	"quake2/player/step4.wav"
};

array<string> arrsModelsFemale;
array<string> arrsModelsCyborg;
array<string> arrsModelsCrakhor;
array<string> arrsQuake2Maps;

void InitializeCommon()
{
	if( USE_QUAKE2_ITEMS )
	{
		q2items::g_bRerelease = true;
		q2items::InitializeItems();

		g_flItemThink = g_Engine.time + 0.1;
		g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );
	}

	if( USE_QUAKE2_NPCS )
		q2npc::InitializeNPCS();

	if( USE_QUAKE2_WEAPONS )
		q2weapons::Register();

	if( USE_QUAKE2_EXTRAS )
	{
		ReadQuake2Maps();
		PrecachePlayerSounds();
	}

	if( USE_QUAKE2_WEAPONS or USE_QUAKE2_EXTRAS )
		g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );

	if( USE_QUAKE2_EXTRAS or USE_QUAKE2_ITEMS )
	{
		if( USE_QUAKE2_EXTRAS )
		{
			g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
			g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
		}

		g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );
	}
}

HookReturnCode PlayerSpawn( CBasePlayer@ pPlayer )
{
	if( USE_QUAKE2_WEAPONS )
		SetAmmoCaps( pPlayer );

	if( USE_QUAKE2_EXTRAS )
	{
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( "$f_lastPain", 0.0 );

		if( USE_QUAKE2_VIEWOFS and arrsQuake2Maps.find(g_Engine.mapname) >= 0 )
			pPlayer.pev.view_ofs.z = QUAKE2_VIEWOFS;
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
	if( pPlayer is null or (pDamageInfo.pAttacker.IsPlayer() and !PVP) ) return HOOK_CONTINUE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flLastPain = pCustom.GetKeyvalue("$f_lastPain").GetFloat();

	if( pPlayer.pev.health <= 0 ) return HOOK_CONTINUE;

	float flDmg = pDamageInfo.flDamage;

	int iDmgType = pDamageInfo.bitsDamageType;
	string sName;

	//if( (iDmgType & (DMG_BURN | DMG_ACID)) != 0 ) 
	//if( pPlayer.pev.watertype == CONTENTS_LAVA )
	if( iDmgType == DMG_BURN and pDamageInfo.pInflictor.pev.classname == "trigger_hurt" )
	{
		if( q2items::IsItemActive(pPlayer, q2items::IT_ITEM_ENVIROSUIT) )
			pDamageInfo.flDamage = 1.0 * pPlayer.pev.waterlevel;
		else
			pDamageInfo.flDamage = 3.0 * pPlayer.pev.waterlevel;

		sName = "quake2/player/burn" + string( Math.RandomLong(1, 2) ) + ".wav";
		//pDamageInfo.flDamage *= pPlayer.pev.waterlevel;

		g_Scheduler.SetTimeout( "DelayTriggerHurt", 0.1, EHandle(pDamageInfo.pInflictor), "lava" );
	}
	else if( iDmgType == DMG_ACID and pDamageInfo.pInflictor.pev.classname == "trigger_hurt" )
	{
		pDamageInfo.flDamage = Math.max( 1, pDamageInfo.flDamage * pPlayer.pev.waterlevel );
		sName = GetPainSound( pPlayer );

		if( q2items::IsItemActive(pPlayer, q2items::IT_ITEM_ENVIROSUIT) )
		{
			pDamageInfo.flDamage = 0.0;
			pDamageInfo.bitsDamageType = 0;
			return HOOK_CONTINUE;
		}

		g_Scheduler.SetTimeout( "DelayTriggerHurt", 0.1, EHandle(pDamageInfo.pInflictor), "acid" );
	}
	else if( (iDmgType & DMG_FALL) != 0 )
	{
		if( flDmg >= 55.0 )
			sName = GetPlayerSoundFolder( pPlayer, "fall1.wav" );
		else
			sName = GetPlayerSoundFolder( pPlayer, "fall2.wav" );
	}
	else
		sName = GetPainSound( pPlayer );

	if( flLastPain < g_Engine.time )
	{
		g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, VOL_NORM, ATTN_NORM );
		pCustom.SetKeyvalue( "$f_lastPain", g_Engine.time + 0.7 );
	}

	return HOOK_CONTINUE;
}

string GetPainSound( CBasePlayer@ pPlayer )
{
	int iAmount;
	int iRand = Math.RandomLong(1, 2);

	if( pPlayer.pev.health < 25 )
		iAmount = 25;
	else if( pPlayer.pev.health < 50 )
		iAmount = 50;
	else if( pPlayer.pev.health < 75 )
		iAmount = 75;
	else
		iAmount = 100;

	return GetPlayerSoundFolder(pPlayer, "pain") + string(iAmount) + "_" + string(iRand) + ".wav";
}

void DelayTriggerHurt( EHandle &in eTriggerHurt, string sType )
{
	CBaseEntity@ pTriggerHurt = eTriggerHurt.GetEntity();

	if( pTriggerHurt !is null )
	{
		if( sType == "lava" )
			pTriggerHurt.pev.dmgtime = g_Engine.time + 1.0;
		else
			pTriggerHurt.pev.dmgtime = g_Engine.time + 0.1;
	}
}

HookReturnCode PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( USE_QUAKE2_EXTRAS )
	{
		if( pPlayer.pev.health > -30 )
		{
			if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, GetPlayerSoundFolder(pPlayer, "drown1.wav"), 1, ATTN_NORM );
			else
			{
				int iNum = Math.RandomLong( 1, 4 );
				string sName = GetPlayerSoundFolder(pPlayer, "death") + string(iNum) + ".wav";
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
			}	
		}
	}

	if( USE_QUAKE2_ITEMS )
	{
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pCustom.SetKeyvalue( q2items::QUAD_KVN, 0 );
		pCustom.SetKeyvalue( q2items::QUAD_KVN_TIME, 0.0 );
		pCustom.SetKeyvalue( q2items::INVUL_KVN, 0 );
		pCustom.SetKeyvalue( q2items::INVUL_KVN_TIME, 0.0 );
		pCustom.SetKeyvalue( q2items::BREATHER_KVN, 0 );
		pCustom.SetKeyvalue( q2items::BREATHER_KVN_SOUND, 0 );
		pCustom.SetKeyvalue( q2items::BREATHER_KVN_TIME, 0.0 );
		pCustom.SetKeyvalue( q2items::ENVIRO_KVN, 0 );
		pCustom.SetKeyvalue( q2items::ENVIRO_KVN_TIME, 0.0 );
		pCustom.SetKeyvalue( q2items::PARMOR_KVN, 0 );
		pCustom.SetKeyvalue( q2items::PARMOR_KVN_EFFECT, 0.0 );
		pCustom.SetKeyvalue( q2items::SILENCER_KVN, 0 );
		pCustom.SetKeyvalue( q2items::MAX_HEALTH_KVN, 0 ); //??

		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::PARMOR_HUD_CHANNEL, false );
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::INVUL_HUD_CHANNEL, false );
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::QUAD_HUD_CHANNEL, false );
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::SILENCER_HUD_CHANNEL, false );
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::BREATHER_HUD_CHANNEL, false );
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::ENVIRO_HUD_CHANNEL, false );
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( g_flItemThink < g_Engine.time )
	{
		RunTimedItems( pPlayer );
		g_flItemThink = g_Engine.time + 0.1;
	}

	q2items::FadeQuadDamage( pPlayer );
	q2items::FadeInvulnerability( pPlayer );
	q2items::FadeRebreather( pPlayer );
	q2items::FadeEnvirosuit( pPlayer );

	DoPowerArmorEffects( pPlayer );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPostThink( CBasePlayer@ pPlayer )
{
	if( USE_QUAKE2_EXTRAS )
	{
		q2_doFallDamage( EHandle(pPlayer) );
		q2_PlayPlayerJumpSounds( EHandle(pPlayer) );

		if( USE_QUAKE2_VIEWOFS and arrsQuake2Maps.find(g_Engine.mapname) >= 0 )
			pPlayer.pev.view_ofs.z = QUAKE2_VIEWOFS;
	}

	return HOOK_CONTINUE;
}

void RunTimedItems( CBasePlayer@ pPlayer )
{
	if( pPlayer is null or !pPlayer.IsAlive() ) return;

	q2items::RunRebreather( pPlayer );
	q2items::RunEnvirosuit( pPlayer );
}

void DoPowerArmorEffects( CBasePlayer@ pPlayer )
{
	if( pPlayer !is null and q2items::g_bRerelease )
	{
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
		
		if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() >= 1 )
		{
			if( pCustom.GetKeyvalue(q2items::PARMOR_KVN_EFFECT).GetFloat() > g_Engine.time )
			{
				pPlayer.pev.renderfx = kRenderFxGlowShell;
				pPlayer.pev.renderamt = 16;
				pPlayer.pev.rendercolor = Vector( 0, 255, 0 );
			}
			else if( pCustom.GetKeyvalue(q2items::PARMOR_KVN_EFFECT).GetFloat() > 0.0 )
				ResetPowerArmorEffect( pPlayer );
		}
		else if( pCustom.GetKeyvalue(q2items::PARMOR_KVN_EFFECT).GetFloat() > 0.0 )
			ResetPowerArmorEffect( pPlayer );
	}
}

void ResetPowerArmorEffect( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( q2items::PARMOR_KVN_EFFECT, 0.0 );

	if( q2items::IsItemActive(pPlayer, q2items::IT_ITEM_QUAD) )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor = Vector( 0, 0, 255 );
		pPlayer.pev.renderamt = 1;
	}
	else if( q2items::IsItemActive(pPlayer, q2items::IT_ITEM_QUAD) )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor = Vector( 255, 0, 0 );
		pPlayer.pev.renderamt = 1;
	}
	else
	{
		pPlayer.pev.renderfx = kRenderFxNone;
		pPlayer.pev.renderamt = 255;
		pPlayer.pev.rendercolor = Vector( 0, 0, 0 );
	}
}

void q2_doFallDamage( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
	if( pPlayer is null ) return;

	if( pPlayer.pev.FlagBitSet(FL_ONGROUND) and pPlayer.pev.health > 0 and pPlayer.m_flFallVelocity >= 350.0 )
	{
		//g_Game.AlertMessage( at_notice, "falling %1\n", pPlayer.m_flFallVelocity );

		if( g_EngineFuncs.PointContents(pPlayer.pev.origin) == CONTENTS_WATER )
		{
			//g_Game.AlertMessage( at_notice, "in water!\n"  );
			// Did he hit the world or a non-moving entity?
			// BUG - this happens all the time in water, especially when 
			// BUG - water has current force
			// if ( !pev.groundentity or VARS(pev.groundentity).velocity.z == 0 )
				// EMIT_SOUND(ENT(pev), CHAN_BODY, "player/pl_wade1.wav", 1, ATTN_NORM);
		}
		else if( pPlayer.m_flFallVelocity > 580 )
		{
			
			float flFallDamage;
			
			switch( Q2_FALLDAMAGE )
			{
				case 0: flFallDamage = 10; break;
				case 1:
					pPlayer.m_flFallVelocity -= 580;
					flFallDamage = pPlayer.m_flFallVelocity * 0.25;
				break;
			}			

			if( flFallDamage > pPlayer.pev.health )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, "quake2/gib.wav", 1, ATTN_NORM );
			}

			if( flFallDamage > 0 )
			{
				pPlayer.TakeDamage( g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, flFallDamage, flFallDamage > pPlayer.pev.health ? (DMG_FALL|DMG_ALWAYSGIB) : DMG_FALL );
				pPlayer.pev.punchangle.x = 0;
			}
		}
    }

	if( pPlayer.pev.FlagBitSet(FL_ONGROUND) )
	{
		if( pPlayer.m_flFallVelocity > 64 )
		{
			//CSoundEnt::InsertSound ( bits_SOUND_PLAYER, pev.origin, pPlayer.m_flFallVelocity, 0.2 );
			if( pPlayer.m_flFallVelocity < 347 )
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, pStepSounds[Math.RandomLong(0,3)], 1, ATTN_NORM );

			//g_Game.AlertMessage( at_notice, "landed %1\n", pPlayer.m_flFallVelocity );
		}

		if( pPlayer.m_flFallVelocity > 347 )
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, "quake2/player/land1.wav", 1, ATTN_NORM );

		pPlayer.m_flFallVelocity = 0;
	}
}

void q2_PlayPlayerJumpSounds( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	if( pPlayer is null or !pPlayer.IsAlive() ) return;

	if( (pPlayer.m_afButtonPressed & IN_JUMP) != 0 and (pPlayer.pev.waterlevel < WATERLEVEL_WAIST) )
	{
		TraceResult tr;
		g_Utility.TraceHull( pPlayer.pev.origin, pPlayer.pev.origin + Vector(0, 0, -5), dont_ignore_monsters, human_hull, pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, GetPlayerSoundFolder(pPlayer, "jump1.wav"), 1, ATTN_NORM );
	}
}

void PrecachePlayerSounds()
{
	ReadPlayerSoundFiles();

	const array<string> arrsPlayerFolders = 
	{
		"quake2/player/male/",
		"quake2/player/female/",
		"quake2/player/cyborg/",
		"quake2/player/crakhor/"
	};

	const array<string> arrsPlayerSounds = 
	{
		"pain100_1.wav",
		"pain100_2.wav",
		"pain75_1.wav",
		"pain75_2.wav",
		"pain50_1.wav",
		"pain50_2.wav",
		"pain25_1.wav",
		"pain25_2.wav",
		"bump1.wav",
		"death1.wav",
		"death2.wav",
		"death3.wav",
		"death4.wav",
		"drown1.wav",
		"fall1.wav",
		"fall2.wav",
		"gurp1.wav",
		"gurp2.wav",
		"jump1.wav"
	};

	for( uint i = 0; i < arrsPlayerFolders.length(); i++ )
	{
		for( uint j = 0; j < arrsPlayerSounds.length(); j++ )
			g_SoundSystem.PrecacheSound( arrsPlayerFolders[i] + arrsPlayerSounds[j] );
	}

	g_SoundSystem.PrecacheSound( "quake2/player/burn1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/burn2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/land1.wav" );

	for( uint i = 0; i < pStepSounds.length(); i++ )
		g_SoundSystem.PrecacheSound( pStepSounds[i] );

	g_SoundSystem.PrecacheSound( "quake2/null.wav" );
	g_SoundSystem.PrecacheSound( "quake2/gib.wav" );
	g_SoundSystem.PrecacheSound( "quake2/misc/talk.wav" );
}

void SetAmmoCaps( CBasePlayer@ pPlayer )
{
	if( pPlayer is null ) return;

	pPlayer.SetMaxAmmo( "q2shells", q2weapons::AMMO_SHELLS_MAX );
	pPlayer.SetMaxAmmo( "q2bullets", q2weapons::AMMO_BULLETS_MAX );
	pPlayer.SetMaxAmmo( "q2grenades", q2weapons::AMMO_GRENADES_MAX );
	pPlayer.SetMaxAmmo( "q2rockets", q2weapons::AMMO_ROCKETS_MAX );
	pPlayer.SetMaxAmmo( "q2cells", q2weapons::AMMO_CELLS_MAX );
	pPlayer.SetMaxAmmo( "q2slugs", q2weapons::AMMO_SLUGS_MAX );
}

void ReadQuake2Maps()
{
	arrsQuake2Maps.resize( 0 );

	File@ file = g_FileSystem.OpenFile( "scripts/maps/quake2/data/q2maps.txt", OpenFile::READ );

	if( file !is null and file.IsOpen() )
	{
		while( !file.EOFReached() )
		{
			string sLine;
			file.ReadLine(sLine);
			//fix for linux
			string sFix = sLine.SubString( sLine.Length() - 1, 1 );
			if( sFix == " " or sFix == "\n" or sFix == "\r" or sFix == "\t" )
				sLine = sLine.SubString( 0, sLine.Length() - 1 );

			//comment
			if( sLine.SubString(0,1) == "#" or sLine.IsEmpty() )
				continue;

			arrsQuake2Maps.insertLast( sLine );
			g_Game.AlertMessage( at_notice, "Added %1 to arrsQuake2Maps\n", sLine );
		}

		file.Close();
	}
}

void ReadPlayerSoundFiles()
{
	arrsModelsFemale.resize( 0 );
	arrsModelsCyborg.resize( 0 );
	arrsModelsCrakhor.resize( 0 );

	const array<string> arrsFileNames = 
	{
		"scripts/maps/quake2/data/female.txt",
		"scripts/maps/quake2/data/cyborg.txt",
		"scripts/maps/quake2/data/crakhor.txt"
	};

	for( uint i = 0; i < arrsFileNames.length(); i++ )
	{
		File@ file = g_FileSystem.OpenFile( arrsFileNames[i], OpenFile::READ );

		if( file !is null and file.IsOpen() )
		{
			while( !file.EOFReached() )
			{
				string sLine;
				file.ReadLine(sLine);
				//fix for linux
				string sFix = sLine.SubString( sLine.Length() - 1, 1 );
				if( sFix == " " or sFix == "\n" or sFix == "\r" or sFix == "\t" )
					sLine = sLine.SubString( 0, sLine.Length() - 1 );

				//comment
				if( sLine.SubString(0,1) == "#" or sLine.IsEmpty() )
					continue;

				if( i == 0 )
					arrsModelsFemale.insertLast( sLine );
				else if( i == 1 )
					arrsModelsCyborg.insertLast( sLine );
				else if( i == 2 )
					arrsModelsCrakhor.insertLast( sLine );
			}

			file.Close();
		}
	}
}

string GetPlayerSoundFolder( CBasePlayer@ pPlayer, const string &in sSoundFile )
{
	KeyValueBuffer@ pInfo = g_EngineFuncs.GetInfoKeyBuffer( pPlayer.edict() );

	string sSoundFolder = "quake2/player/male/";
	string sModelName = pInfo.GetValue( "model" );

	if( arrsModelsFemale.find(sModelName) >= 0 )
		sSoundFolder = "quake2/player/female/";
	else if( arrsModelsCyborg.find(sModelName) >= 0 )
		sSoundFolder = "quake2/player/cyborg/";
	else if( arrsModelsCrakhor.find(sModelName) >= 0 )
		sSoundFolder = "quake2/player/crakhor/";

	return sSoundFolder + sSoundFile;
}

} //end of namespace q2

/* FIXME
*/

/* TODO
	Consolidate the bRerelease variables ??

	Move all settings to one place ??
*/
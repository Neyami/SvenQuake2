#include "q2funcs"
#include "items"
#include "npcs"
#include "weapons"
#include "entities"
#include "maps"

namespace q2
{

bool PVP 											= false;
const bool USE_QUAKE2_ITEMS			= true;
const bool USE_QUAKE2_NPCS			= true;
const bool USE_QUAKE2_ENTITIES		= true; //map entities such as exploding barrels, dead marines, trigger_key, targetspeaker etc
//const bool USE_QUAKE2_AI				= true; //only for flying mobs atm
const bool USE_QUAKE2_WEAPONS		= true;
const bool USE_QUAKE2_EXTRAS		= true; //fall damage, pain sounds, jumping sounds, footsteps
const bool USE_QUAKE2_FOOTSTEPS	= true;
const bool USE_QUAKE2_SCALES		= true; //sets the player's view_ofs.z to 10 and scale to 0.6667 on Quake 2 maps to match the size of the maps and monsters
const bool USE_QUAKE2_DEATHMSGS	= true;

const float QUAKE2_VIEWOFS				= 10.0;
const float QUAKE2_SCALE					= 0.6667;

const int SF_NOT_IN_EASY					= 256;
const int SF_NOT_IN_NORMAL			= 512;
const int SF_NOT_IN_HARD				= 1024;
const int SF_NOT_IN_DEATHMATCH		= 65536; //2048 is reserved
const int SF_NOT_IN_SINGLEPLAYER	= SF_NOT_IN_EASY + SF_NOT_IN_NORMAL + SF_NOT_IN_HARD;

const uint8 Q2_FALLDAMAGE				= 1; //0: 10 damage flat, 1: normal damage (based on height)

const string KVN_ITEM_THINK			= "$f_q2itemshink";
const string KVN_MOD						= "$i_q2meansofdeath";

const float FRAMETIME						= 0.1;

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

//CCVar@ cvar_Difficulty;
//CCVar@ cvar_ChaosMode;
CCVar@ cvar_InfiniteAmmo; //CVAR_LATCH = no change until map restart/change ??
CCVar@ cvar_CoopHealthScaling; //CVAR_LATCH = no change until map restart/change ??

CClientCommand q2skill( "q2skill", "Difficulty level? 0-3 (default: 3)", @Quake2Settings );
CClientCommand q2chaos( "q2chaos", "Chaos mode? 0-2 (default: 0)", @Quake2Settings );
CClientCommand q2_infinite_ammo( "q2_infinite_ammo", "Infinite ammo for Quake 2 weapons? (default: 0)", @Quake2Settings );
CClientCommand q2_coop_health_scaling( "q2_coop_health_scaling", "Adds health to monsters based on playercount, 0.0 - 1.0 (default: 0)", @Quake2Settings );
CClientCommand q2deathmatch( "q2deathmatch", "Deathmatch off or on 0/1? (default: 0)", @Quake2Settings );
CClientCommand q2giveall( "q2giveall", "Give all Quake 2 weapons and items.", @Quake2GiveAll );

void InitializeCommon()
{
	//TEMP
	g_SoundSystem.PrecacheSound( "quake2/world/ric1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/world/ric2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/world/ric3.wav" );
	g_SoundSystem.PrecacheSound( "quake2/world/spark5.wav" );
	g_SoundSystem.PrecacheSound( "quake2/world/spark6.wav" );
	g_SoundSystem.PrecacheSound( "quake2/world/spark7.wav" );
	//g_Game.PrecacheModel( "sprites/wep_smoke_01.spr" );
	//g_Game.PrecacheModel( "sprites/particles/water_big.spr" );
	g_Game.PrecacheModel( "sprites/quake2/water_big.spr" );

	if( USE_QUAKE2_ITEMS )
	{
		q2items::g_bRerelease = true;
		q2items::InitializeItems();

		g_Hooks.RegisterHook( Hooks::Player::ClientDisconnect, @ClientDisconnect );
	}

	if( USE_QUAKE2_NPCS )
	{
		q2npc::g_bRerelease = true;
		q2npc::g_iChaosMode = q2::CHAOS_NONE;
		q2npc::g_iDifficulty = q2::DIFF_NIGHTMARE;

		q2npc::InitializeNPCS();

		//@cvar_Difficulty = CCVar( "q2-skill", 3, "Difficulty level? 0-3 (default: 3)", ConCommandFlag::AdminOnly );
		//@cvar_ChaosMode = CCVar( "q2-chaos", 0, "Chaos mode? 0-2 (default: 0)", ConCommandFlag::AdminOnly );
		@cvar_CoopHealthScaling = CCVar( "q2-health-scaling", 0, "Adds health to monsters based on playercount, 0.0 - 1.0 (default: 0)", ConCommandFlag::AdminOnly ); //level.coop_health_scaling

		g_Hooks.RegisterHook( Hooks::Player::ClientPutInServer, @ClientPutInServer );
	}

	if( USE_QUAKE2_ENTITIES )
	{
		g_iTotalGoals = 0;
		g_iFoundGoals = 0;

		g_iTotalSecrets = 0;
		g_iFoundSecrets = 0;

		g_iTotalMonsters = 0;
		g_iKilledMonsters = 0;

		InitializeMaps();

		q2entities::Register();
	}

	if( USE_QUAKE2_WEAPONS )
	{
		q2weapons::Register();

		@cvar_InfiniteAmmo = CCVar( "q2-infinite-ammo", 0, "Infinite ammo for Quake 2 weapons? (default: 0)", ConCommandFlag::AdminOnly );
	}

	if( USE_QUAKE2_EXTRAS )
	{
		ReadQuake2Maps();
		PrecachePlayerSounds();
	}

	if( USE_QUAKE2_WEAPONS or USE_QUAKE2_ITEMS or USE_QUAKE2_EXTRAS or USE_QUAKE2_SCALES )
		g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @PlayerSpawn );

	if( USE_QUAKE2_EXTRAS or USE_QUAKE2_ITEMS or USE_QUAKE2_FOOTSTEPS )
	{
		if( USE_QUAKE2_EXTRAS )
		{
			g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @PlayerPostThink );
			g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @PlayerTakeDamage );
		}

		g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @PlayerKilled );

		if( USE_QUAKE2_ITEMS or USE_QUAKE2_FOOTSTEPS /*or USE_QUAKE2_AI*/ )
		{
			g_Hooks.RegisterHook( Hooks::Player::PlayerPreThink, @PlayerPreThink );

			if( USE_QUAKE2_FOOTSTEPS )
				ReadQuake2Textures();
		}
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
	}

	if( USE_QUAKE2_ITEMS )
	{
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		if( !pCustom.GetKeyvalue(KVN_ITEM_THINK).Exists() )
			pCustom.InitializeKeyvalueWithDefault( KVN_ITEM_THINK );
	}

	if( USE_QUAKE2_SCALES )
	{
		if( arrsQuake2Maps.find(g_Engine.mapname) >= 0 )
		{
			if( pPlayer.pev.view_ofs.z != QUAKE2_VIEWOFS )
				pPlayer.pev.view_ofs.z = QUAKE2_VIEWOFS;

			if( pPlayer.pev.scale != QUAKE2_SCALE )
				pPlayer.pev.scale = QUAKE2_SCALE;
		}
	}

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( q2::KVN_MOD, q2::MOD_UNKNOWN );

	return HOOK_CONTINUE;
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	if( pDamageInfo.flDamage <= 0 or pDamageInfo.pInflictor is null ) return HOOK_CONTINUE;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pDamageInfo.pVictim );
	if( pPlayer is null ) return HOOK_CONTINUE;

	if( pPlayer.pev.deadflag != DEAD_NO ) return HOOK_CONTINUE;
	if( pPlayer.pev.FlagBitSet(FL_GODMODE) ) return HOOK_CONTINUE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	//prevent friendly fire from causing pain sounds if PVP is off
	//if( (pDamageInfo.pAttacker !is null and pDamageInfo.pAttacker.IsPlayer()) and !PVP ) return HOOK_CONTINUE;

	//if( !pDamageInfo.pInflictor.pev.FlagBitSet(FL_CLIENT) )
	if( !IsAlly(pPlayer, pDamageInfo.pInflictor) )
	{
		float flLastPain = pCustom.GetKeyvalue("$f_lastPain").GetFloat();

		float flDmg = pDamageInfo.flDamage;

		int iDmgType = pDamageInfo.bitsDamageType;
		string sName;

		//if( (iDmgType & (DMG_BURN | DMG_ACID)) != 0 ) 
		if( iDmgType == DMG_BURN and (pDamageInfo.pInflictor.pev.classname == "trigger_hurt" or pPlayer.pev.watertype == CONTENTS_LAVA) )
		{
			if( q2items::IsItemActive(pPlayer, q2::IT_ITEM_ENVIROSUIT) )
				pDamageInfo.flDamage = 1.0 * pPlayer.pev.waterlevel;
			else
				pDamageInfo.flDamage = 3.0 * pPlayer.pev.waterlevel;

			SetMeansOfDeath( pPlayer, q2::MOD_LAVA );
			sName = "quake2/player/burn" + string( Math.RandomLong(1, 2) ) + ".wav";
			//pDamageInfo.flDamage *= pPlayer.pev.waterlevel;

			g_Scheduler.SetTimeout( "DelayTriggerHurt", 0.1, EHandle(pDamageInfo.pInflictor), "lava" );
		}
		else if( iDmgType == DMG_ACID and (pDamageInfo.pInflictor.pev.classname == "trigger_hurt" or pPlayer.pev.watertype == CONTENTS_SLIME) )
		{
			pDamageInfo.flDamage = Math.max( 1, pDamageInfo.flDamage * pPlayer.pev.waterlevel );
			sName = GetPainSound( pPlayer );

			if( q2items::IsItemActive(pPlayer, q2::IT_ITEM_ENVIROSUIT) )
			{
				pDamageInfo.flDamage = 0.0;
				pDamageInfo.bitsDamageType = 0;
				return HOOK_CONTINUE;
			}

			SetMeansOfDeath( pPlayer, q2::MOD_SLIME );

			g_Scheduler.SetTimeout( "DelayTriggerHurt", 0.1, EHandle(pDamageInfo.pInflictor), "acid" );
		}
		else if( (iDmgType & DMG_FALL) != 0 )
		{
			if( flDmg >= 55.0 )
				sName = GetPlayerSoundFolder( pPlayer, "fall1.wav" );
			else
				sName = GetPlayerSoundFolder( pPlayer, "fall2.wav" );

			SetMeansOfDeath( pPlayer, q2::MOD_FALLING );
		}
		else if( (iDmgType & DMG_DROWN) != 0 )
		{
			SetMeansOfDeath( pPlayer, q2::MOD_WATER );
			sName = GetPlayerSoundFolder( pPlayer, "gurp" + string(Math.RandomLong(1, 2)) + ".wav" );
		}
		else
			sName = GetPainSound( pPlayer );

		if( flLastPain < g_Engine.time )
		{
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, VOL_NORM, ATTN_NORM );
			pCustom.SetKeyvalue( "$f_lastPain", g_Engine.time + 0.7 );
		}
	}

	if( USE_QUAKE2_DEATHMSGS )
		ClientObituary( pPlayer, pDamageInfo.pInflictor, pDamageInfo.pAttacker, pDamageInfo.flDamage, pDamageInfo.bitsDamageType, pCustom.GetKeyvalue(q2::KVN_MOD).GetInteger() );

	return HOOK_CONTINUE;
}

void SetMeansOfDeath( CBaseEntity@ pEntity, int iMeansOfDeath )
{
	CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
	pCustom.SetKeyvalue( q2::KVN_MOD, iMeansOfDeath );
}

void ClientObituary( CBasePlayer@ pPlayer, CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, float flDamage, int bitsDamageType, int iMeansOfDeath )
{
	//g_Game.AlertMessage( at_notice, "ClientObituary %1 %2 %3 %4 %5 %6\n", pPlayer.pev.netname, pInflictor.GetClassname(), pAttacker.GetClassname(), flDamage, bitsDamageType, iMeansOfDeath );
	//if( bitsDamageType & (DMG_BURN | DMG_ACID) != 0 and pInflictor.pev.classname == "trigger_hurt" )
		//return;

	if( pPlayer.IsAlive() and flDamage >= pPlayer.pev.health )
	{
		string base;

		switch( iMeansOfDeath )
		{
			case q2::MOD_SUICIDE:
				base = " suicides.\n";
				break;
			case q2::MOD_FALLING:
				base = " cratered.\n";
				break;
			case q2::MOD_CRUSH:
				base = " was squished.\n";
				break;
			case q2::MOD_WATER:
				base = " sank like a rock.\n";
				break;
			case q2::MOD_SLIME:
				base = " melted.\n";
				break;
			case q2::MOD_LAVA:
				base = " does a back flip into the lava.\n";
				break;
			case q2::MOD_EXPLOSIVE:
			case q2::MOD_BARREL:
				base = " blew up.\n";
				break;
			case q2::MOD_EXIT:
				base = " found a way out.\n";
				break;
			case q2::MOD_TARGET_LASER:
				base = " saw the light.\n";
				break;
			case q2::MOD_TARGET_BLASTER:
				base = " got blasted.\n";
				break;
			case q2::MOD_BOMB:
			case q2::MOD_SPLASH:
			case q2::MOD_TRIGGER_HURT:
				base = " was in the wrong place.\n";
				break;
			case q2::MOD_GEKK:
			case q2::MOD_BRAINTENTACLE:
				base = "... that's gotta hurt!\n";
				break;
			default:
				base = "";
				break;
		}

		if( pAttacker !is null and pAttacker is pPlayer )
		{
			switch( iMeansOfDeath )
			{
				case q2::MOD_HELD_GRENADE:
					base = " tried to put the pin back in.\n";
					break;
				case q2::MOD_HG_SPLASH:
				case q2::MOD_G_SPLASH:
					base = " tripped on their own grenade.\n";
					break;
				case q2::MOD_R_SPLASH:
					base = " blew themselves up.\n";
					break;
				case q2::MOD_BFG_BLAST:
					base = " should have used a smaller gun.\n";
					break;
				case q2::MOD_TRAP:
					base = " was sucked into their own trap.\n";
					break;
				case q2::MOD_DOPPLE_EXPLODE:
					base = " was fooled by their own doppelganger.\n";
					break;
				default:
				{
					if( base.IsEmpty() )
						base = " killed themselves.\n";

					break;
				}
			}
		}

		// send generic/self
		if( !base.IsEmpty() )
		{
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string(pPlayer.pev.netname) + base );
			bool bGib = (pPlayer.pev.health - flDamage) < -40;
			KillPlayer( pPlayer, pAttacker, bitsDamageType, bGib );

			return;
		}

		//projectiles (because pAttacker can be null)
		if( q2npc::g_arrsQ2Projectiles.find(pInflictor.GetClassname()) >= 0 /*and pAttacker !is pPlayer*/ )
		{
			bool bGib = (pPlayer.pev.health - flDamage) < -40;
			KillPlayer( pPlayer, pAttacker, bitsDamageType, bGib );

			//if( pInflictor.pev.weapons != 0 )
				//iMeansOfDeath = pInflictor.pev.weapons;

			string sDeathMsg = GetDeathMessage( pPlayer.pev.netname, pInflictor.pev.netname, iMeansOfDeath );;
			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
			//g_Game.AlertMessage( at_notice, "KILLED BY %1, LAUNCHED BY %2, iMeansOfDeath: %3\n", pInflictor.GetClassname(), pAttacker.pev.netname, iMeansOfDeath );

			return;
		}

		//monsters and players
		if( pAttacker !is null )
		{
			if( q2npc::g_arrsQ2Monsters.find(pAttacker.GetClassname()) >= 0 )
			{
				string sDeathMsg;

				bool bGib = (pPlayer.pev.health - flDamage) < -40;
				KillPlayer( pPlayer, pAttacker, bitsDamageType, bGib );

				/*if( bitsDamageType & (DMG_ALWAYSGIB + DMG_CRUSH) == (DMG_ALWAYSGIB + DMG_CRUSH) )
					iMeansOfDeath = q2::MOD_TELEFRAG;
				else if( HasFlags(bitsDamageType, DMG_ENERGYBEAM) )
					iMeansOfDeath = q2::MOD_RAILGUN;
				else */if( HasFlags(bitsDamageType, DMG_BULLET) )
				{
					if( pAttacker.pev.weapons == q2::MOD_SHOTGUN )
						iMeansOfDeath = q2::MOD_SHOTGUN;
					else if( pAttacker.GetClassname() == "npc_q2tank" or pAttacker.GetClassname() == "npc_q2supertank" or pAttacker.GetClassname() == "npc_q2jorg" )
						iMeansOfDeath = q2::MOD_CHAINGUN;
					else
						iMeansOfDeath = q2::MOD_MACHINEGUN;
				}
				else if( iMeansOfDeath == q2::MOD_HIT )
				{
					if( pAttacker.GetClassname() == "npc_q2flyer" )
						sDeathMsg = string(pPlayer.pev.netname) + " was cut up by a Flyer's sharp wings\n";
					else if( pAttacker.GetClassname() == "npc_q2enforcer" )
						sDeathMsg = string(pPlayer.pev.netname) + " was bludgeoned by an Enforcer\n";
					else if( pAttacker.GetClassname() == "npc_q2parasite" )
						sDeathMsg = string(pPlayer.pev.netname) + " was exsanguinated by a Parasite\n";
					else if( pAttacker.GetClassname() == "npc_q2ironmaiden" )
						sDeathMsg = string(pPlayer.pev.netname) + " was bitch-slapped by an Iron Maiden\n";
					else if( pAttacker.GetClassname() == "npc_q2berserker" )
						sDeathMsg = string(pPlayer.pev.netname) + " was smashed by a Berserker\n";
					else if( pAttacker.GetClassname() == "npc_q2brains" )
						sDeathMsg = string(pPlayer.pev.netname) + " was sliced to pieces by a Brains\n"; //a Brains ??
					else if( pAttacker.GetClassname() == "npc_q2gladiator" )
						sDeathMsg = string(pPlayer.pev.netname) + " was mangled by a Gladiator's claw\n";

					g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
					return;
				}

				string sMonsterName;
				q2npc::g_dicMonsterNames.get( pAttacker.GetClassname(), sMonsterName );
				sDeathMsg = GetDeathMessage( pPlayer.pev.netname, sMonsterName, iMeansOfDeath );

				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
			}
			else if( pAttacker.pev.FlagBitSet(FL_CLIENT) )
			{
				bool bGib = (pPlayer.pev.health - flDamage) < -40;
				KillPlayer( pPlayer, pAttacker, bitsDamageType, bGib );

				string sDeathMsg = GetDeathMessage( pPlayer.pev.netname, pAttacker.pev.netname, iMeansOfDeath );
				g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
			}

			return;
		}

		g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, string(pPlayer.pev.netname) + " died.\n" );
	}
}

void KillPlayer( CBasePlayer@ pPlayer, CBaseEntity@ pKiller, int bitsDamageType, bool bGib = false )
{
	if( (!HasFlags(bitsDamageType, DMG_NEVERGIB) and bGib) or HasFlags(bitsDamageType, DMG_ALWAYSGIB) )
	{
		pPlayer.GibMonster();
		pPlayer.pev.effects |= EF_NODRAW;
	}

	pPlayer.Killed( null, GIB_NOPENALTY );
	pPlayer.m_iDeaths++;

	if( pKiller !is null )
		pKiller.pev.frags++;
}

string GetDeathMessage( string sVictim, string sKiller, int iMeansOfDeath )
{
	//g_Game.AlertMessage( at_notice, "GetDeathMessage: %1 %2 %3\n", sVictim, sKiller, iMeansOfDeath );
	switch( iMeansOfDeath )
	{
		case q2::MOD_TARGET_BLASTER:
			return sVictim + " got blasted.\n";
		case q2::MOD_BLASTER:
			return sVictim + " was blasted by " + sKiller + ".\n";
		case q2::MOD_SHOTGUN:
			return sVictim + " was gunned down by " + sKiller + ".\n";
		case q2::MOD_SSHOTGUN:
			return sVictim + " was blown away by " + sKiller + "'s Super Shotgun.\n";
		case q2::MOD_MACHINEGUN:
			return sVictim + " was machinegunned by " + sKiller + ".\n";
		case q2::MOD_CHAINGUN:
			return sVictim + " was cut in half by " + sKiller + "'s Chaingun.\n";
		case q2::MOD_GRENADE:
			return sVictim + " was popped by " + sKiller + "'s grenade.\n";
		case q2::MOD_G_SPLASH:
			return sVictim + " was shredded by " + sKiller + "'s shrapnel.\n";
		case q2::MOD_ROCKET:
			return sVictim + " ate " + sKiller + "'s rocket.\n";
		case q2::MOD_R_SPLASH:
			return sVictim + " almost dodged " + sKiller + "'s rocket.\n";
		case q2::MOD_HYPERBLASTER:
			return sVictim + " was melted by " + sKiller + "'s HyperBlaster.\n";
		case q2::MOD_RAILGUN:
			return sVictim + " was railed by " + sKiller + ".\n";
		case q2::MOD_BFG_LASER:
			return sVictim + " saw the pretty lights from " + sKiller + "'s BFG.\n";
		case q2::MOD_BFG_BLAST:
			return sVictim + " was disintegrated by " + sKiller + "'s BFG blast.\n";
		case q2::MOD_BFG_EFFECT:
			return sVictim + " couldn't hide from " + sKiller + "'s BFG.\n";
		case q2::MOD_HANDGRENADE:
			return sVictim + " caught " + sKiller + "'s handgrenade.\n";
		case q2::MOD_HG_SPLASH:
			return sVictim + " didn't see " + sKiller + "'s handgrenade.\n";
		case q2::MOD_HELD_GRENADE:
			return sVictim + " feels " + sKiller + "'s pain.\n";
		case q2::MOD_TELEFRAG:
		case q2::MOD_TELEFRAG_SPAWN:
			return sVictim + " tried to invade " + sKiller + "'s personal space.\n";
		case q2::MOD_RIPPER:
			return sVictim + " ripped to shreds by " + sKiller + "'s ripper gun.\n";
		case q2::MOD_PHALANX:
			return sVictim + " was evaporated by " + sKiller + ".\n";
		case q2::MOD_TRAP:
			return sVictim + " was caught in " + sKiller + "'s trap.\n";
		case q2::MOD_CHAINFIST:
			return sVictim + " was shredded by " + sKiller + "'s ripsaw.\n";
		case q2::MOD_DISINTEGRATOR:
			return sVictim + " lost his grip courtesy of " + sKiller + "'s Disintegrator.\n";
		case q2::MOD_ETF_RIFLE:
			return sVictim + " was perforated by " + sKiller + ".\n";
		case q2::MOD_HEATBEAM:
			return sVictim + " was scorched by " + sKiller + "'s Plasma Beam.\n";
		case q2::MOD_TESLA:
			return sVictim + " was enlightened by " + sKiller + "'s tesla mine.\n";
		case q2::MOD_PROX:
			return sVictim + " got too close to " + sKiller + "'s proximity mine.\n";
		case q2::MOD_NUKE:
			return sVictim + " was nuked by " + sKiller + "'s antimatter bomb.\n";
		case q2::MOD_VENGEANCE_SPHERE:
			return sVictim + " was purged by " + sKiller + "'s Vengeance Sphere.\n";
		case q2::MOD_DEFENDER_SPHERE:
			return sVictim + " had a blast with " + sKiller + "'s Defender Sphere.\n";
		case q2::MOD_HUNTER_SPHERE:
			return sVictim + " was hunted down by " + sKiller + "'s Hunter Sphere.\n";
		case q2::MOD_TRACKER:
			return sVictim + " was annihilated by " + sKiller + "'s Disruptor.\n";
		case q2::MOD_DOPPLE_EXPLODE:
			return sVictim + " was tricked by " + sKiller + "'s Doppelganger.\n";
		case q2::MOD_DOPPLE_VENGEANCE:
			return sVictim + " was purged by " + sKiller + "'s Doppelganger.\n";
		case q2::MOD_DOPPLE_HUNTER:
			return sVictim + " was hunted down by " + sKiller + "'s Doppelganger.\n";
		case q2::MOD_GRAPPLE:
			return sVictim + " was caught by " + sKiller + "'s grapple.\n";
		default:
			return sVictim + " was killed by " + sKiller + ".\n";
	}
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

		if( q2items::IsItemActive(pPlayer, q2::IT_ITEM_INVISIBILITY) )
			q2items::InvisResetPlayer( pPlayer );

		pCustom.SetKeyvalue( q2items::INVIS_KVN, 0 );
		pCustom.SetKeyvalue( q2items::INVIS_KVN_TIME, 0.0 );
		pCustom.SetKeyvalue( q2items::INVIS_KVN_FADETIME, 0.0 );
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
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::INVIS_HUD_CHANNEL, false );

		CItemInventory@ pKey = q2items::HasNamedPlayerItem( pPlayer, "key_red_key" );
		if( pKey !is null )
			pKey.SUB_Remove();
	}

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPreThink( CBasePlayer@ pPlayer, uint& out uiFlags )
{
	if( USE_QUAKE2_ITEMS )
	{
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
		float flPlayerThink = pCustom.GetKeyvalue( KVN_ITEM_THINK ).GetFloat();

		if( flPlayerThink < g_Engine.time )
		{
			RunTimedItems( pPlayer );
			pCustom.SetKeyvalue( KVN_ITEM_THINK, g_Engine.time + 0.1 );
		}

		q2items::FadeQuadDamage( pPlayer );
		q2items::FadeInvulnerability( pPlayer );
		q2items::FadeInvisibility( pPlayer );
		q2items::FadeRebreather( pPlayer );
		q2items::FadeEnvirosuit( pPlayer );

		DoPowerArmorEffects( pPlayer );
	}

	if( USE_QUAKE2_EXTRAS and USE_QUAKE2_FOOTSTEPS )
		q2::PM_UpdateStepSound( pPlayer );

	/*if( USE_QUAKE2_AI )
	{
		if( q2::original::g_flRunFrame < g_Engine.time )
		{
			q2::original::AI_SetSightClient();
			q2::original::g_flRunFrame = g_Engine.time + 0.1;
		}
	}*/

	return HOOK_CONTINUE;
}

HookReturnCode PlayerPostThink( CBasePlayer@ pPlayer )
{
	if( USE_QUAKE2_EXTRAS )
	{
		q2_doFallDamage( EHandle(pPlayer) );
		q2_PlayPlayerJumpSounds( EHandle(pPlayer) );
	}

	if( USE_QUAKE2_SCALES and arrsQuake2Maps.find(g_Engine.mapname) >= 0 )
	{
		if( pPlayer.pev.view_ofs.z != QUAKE2_VIEWOFS )
			pPlayer.pev.view_ofs.z = QUAKE2_VIEWOFS;

		if( pPlayer.pev.scale != QUAKE2_SCALE )
			pPlayer.pev.scale = QUAKE2_SCALE;
	}

	return HOOK_CONTINUE;
}

HookReturnCode ClientPutInServer( CBasePlayer@ pPlayer )
{
	q2npc::G_Monster_CheckCoopHealthScaling();

	return HOOK_CONTINUE;
}

HookReturnCode ClientDisconnect( CBasePlayer@ pPlayer )
{
	g_Scheduler.SetTimeout( "RemoveKeys", 0.1 );

	return HOOK_CONTINUE;
}

void RemoveKeys()
{
	CBaseEntity@ pKey = null;
	while( (@pKey = g_EntityFuncs.FindEntityByClassname(pKey, "item_inventory")) !is null )
	{
		if( pKey.pev.netname != "key_red_key" )
			continue;

		if( pKey.pev.owner !is null )
			continue;

		pKey.SUB_Remove();
	}
}

void RunTimedItems( CBasePlayer@ pPlayer )
{
	if( pPlayer is null or !pPlayer.IsAlive() or !pPlayer.IsConnected() ) return;

	q2items::RunRebreather( pPlayer );
	q2items::RunEnvirosuit( pPlayer );
	q2items::RunInvisibility( pPlayer );
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

	if( q2items::IsItemActive(pPlayer, q2::IT_ITEM_QUAD) )
	{
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor = Vector( 0, 0, 255 );
		pPlayer.pev.renderamt = 1;
	}
	else if( q2items::IsItemActive(pPlayer, q2::IT_ITEM_QUAD) )
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

	if( USE_QUAKE2_FOOTSTEPS )
	{
		g_SoundSystem.PrecacheSound( "quake2/player/steps/boot1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/boot2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/boot3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/boot4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/carpet1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/carpet2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/carpet3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/carpet4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/clank1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/clank2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/clank3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/clank4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/energy1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/energy2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/energy3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/energy4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/flesh1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/flesh2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/flesh3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/flesh4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/glass1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/glass2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/glass3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/glass4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/glass5.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/grass1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/grass2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/grass3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/grass4.wav" );
		//g_SoundSystem.PrecacheSound( "quake2/player/steps/junk1.wav" );
		//g_SoundSystem.PrecacheSound( "quake2/player/steps/junk2.wav" );
		//g_SoundSystem.PrecacheSound( "quake2/player/steps/junk3.wav" );
		//g_SoundSystem.PrecacheSound( "quake2/player/steps/junk4.wav" );
		//g_SoundSystem.PrecacheSound( "quake2/player/steps/junk5.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/ladder1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/ladder2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/ladder3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/ladder4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/ladder5.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/meat1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/meat2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/meat3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/meat4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/meat5.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/mech1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/mech2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/mech3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/mech4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/snow1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/snow2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/snow3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/snow4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/splash1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/splash2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/splash3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/splash4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/step1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/step2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/step3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/step4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/tile1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/tile2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/tile3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/tile4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/wood1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/wood2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/wood3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/wood4.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/steps/wood5.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/wade1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/wade2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/wade3.wav" );
	}
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
			if( sLine.SubString(0,1) == "#" or sLine.SubString(0,1) == ";" or sLine.SubString(0,2) == "//" or sLine.IsEmpty() ) 
				continue;

			arrsQuake2Maps.insertLast( sLine );
		}

		file.Close();
	}
}

void ReadQuake2Textures()
{
	q2::pQ2Textures.deleteAll();

	File@ file = g_FileSystem.OpenFile( "scripts/maps/quake2/data/q2materials.txt", OpenFile::READ );

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
			if( sLine.SubString(0,1) == "#" or sLine.SubString(0,1) == ";" or sLine.SubString(0,2) == "//" or sLine.IsEmpty() ) 
				continue;

			array<string> parsed = sLine.Split(" ");
			if( parsed.length() < 2 )
				continue;

			//only register Quake 2 texture materials
			if( parsed[0] != "E" and parsed[0] != "A" )
				continue;

			pQ2Textures[ parsed[1].ToLowercase() ] = parsed[0];

			//g_Game.AlertMessage( at_notice, "Texture: %1, Char: %2\n", parsed[1].ToLowercase(), parsed[0] );
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

bool IsCoop()
{
	return g_PlayerFuncs.GetNumPlayers() > 1;
}

bool IsAlly( CBaseEntity@ pEntity, CBaseEntity@ pTarget )
{
	return pEntity.IRelationship( pTarget ) <= R_NO;
}

bool HasFlags( int iFlagVariable, int iFlags )
{
	return (iFlagVariable & iFlags) != 0;
}

bool ShouldEntitySpawn( CBaseEntity@ pEntity )
{
	if( HasFlags(pEntity.pev.spawnflags, SF_NOT_IN_DEATHMATCH) and PVP )
	{
		//g_Game.AlertMessage( at_notice, "SP-only item tried to spawn in deathmatch: %1\n", pEntity.GetClassname() );
		return false;
	}

	if( (pEntity.pev.spawnflags & SF_NOT_IN_SINGLEPLAYER) == SF_NOT_IN_SINGLEPLAYER and !PVP )
	{
		//g_Game.AlertMessage( at_notice, "DM-only item tried to spawn in singleplayer: %1\n", pEntity.GetClassname() );
		return false;
	}

	if( HasFlags(pEntity.pev.spawnflags, SF_NOT_IN_HARD) and q2npc::g_iDifficulty >= q2::DIFF_HARD )
	{
		//g_Game.AlertMessage( at_notice, "SF_NOT_IN_HARD item tried to spawn in >= DIFF_HARD: %1\n", pEntity.GetClassname() );
		return false;
	}

	if( HasFlags(pEntity.pev.spawnflags, SF_NOT_IN_NORMAL) and q2npc::g_iDifficulty == q2::DIFF_NORMAL )
	{
		//g_Game.AlertMessage( at_notice, "SF_NOT_IN_NORMAL item tried to spawn in >= DIFF_NORMAL: %1\n", pEntity.GetClassname() );
		return false;
	}

	if( HasFlags(pEntity.pev.spawnflags, SF_NOT_IN_EASY) and q2npc::g_iDifficulty == q2::DIFF_EASY )
	{
		//g_Game.AlertMessage( at_notice, "SF_NOT_IN_EASY item tried to spawn in >= DIFF_EASY: %1\n", pEntity.GetClassname() );
		return false;
	}

	return true;
}

void Quake2Settings( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if( args.Arg(0) == "q2_infinite_ammo" and !q2::USE_QUAKE2_WEAPONS )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Quake 2 Weapons are disabled\n" );
		return;
	}

	if( (args.Arg(0) == "q2skill" or args.Arg(0) == "q2chaos") and !q2::USE_QUAKE2_NPCS )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Quake 2 NPCs are disabled\n" );
		return;
	}

	if( args.ArgC() < 2 ) //If no args are supplied
	{
		if( args.Arg(0) == "q2skill" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2skill\" is \"" + q2npc::g_iDifficulty + "\"\n" );
		else if( args.Arg(0) == "q2chaos" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2chaos\" is \"" + q2npc::g_iChaosMode + "\"\n" );
		else if( args.Arg(0) == "q2_infinite_ammo" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_infinite_ammo\" is \"" + cvar_InfiniteAmmo.GetInt() + "\"\n" );
		else if( args.Arg(0) == "q2_coop_health_scaling" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_coop_health_scaling\" is \"" + cvar_CoopHealthScaling.GetInt() + "\"\n" );
		else if( args.Arg(0) == "q2deathmatch" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2deathmatch\" is \"" + q2::PVP + "\"\n" );
	}
	else if( args.ArgC() == 2 ) //If one arg is supplied (value to set)
	{
		if( args.Arg(0) == "q2skill" and Math.clamp(0, q2::DIFF_LAST-1, atoi(args.Arg(1))) != q2npc::g_iDifficulty )
		{
			q2npc::g_iDifficulty = Math.clamp( 0, q2::DIFF_LAST-1, atoi(args.Arg(1)) );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2skill\" changed to \"" + q2npc::g_iDifficulty + "\"\n" );
		}
		else if( args.Arg(0) == "q2chaos" and Math.clamp(0, q2::CHAOS_LAST-1, atoi(args.Arg(1))) != q2npc::g_iChaosMode )
		{
			q2npc::g_iChaosMode = Math.clamp( 0, q2::CHAOS_LAST-1, atoi(args.Arg(1)) );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2chaos\" changed to \"" + q2npc::g_iChaosMode + "\"\n" );
		}
		else if( args.Arg(0) == "q2_infinite_ammo" and Math.clamp(0, 1, atoi(args.Arg(1))) != cvar_InfiniteAmmo.GetInt() )
		{
			cvar_InfiniteAmmo.SetInt( Math.clamp(0, 1, atoi(args.Arg(1))) );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_infinite_ammo\" changed to \"" + cvar_InfiniteAmmo.GetInt() + "\"\n" );
		}
		else if( args.Arg(0) == "q2_coop_health_scaling" and Math.clamp(0.0, 1.0, atof(args.Arg(1))) != cvar_CoopHealthScaling.GetFloat() )
		{
			cvar_CoopHealthScaling.SetFloat( Math.clamp(0.0, 1.0, atof(args.Arg(1))) );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_coop_health_scaling\" changed to \"" + cvar_CoopHealthScaling.GetInt() + "\"\n" );
		}
		else if( args.Arg(0) == "q2deathmatch" )
		{
			bool bNewValue =  ( atoi(args.Arg(1)) > 0 );
			if( bNewValue != q2::PVP )
			{
				q2::PVP = bNewValue;
				g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2deathmatch\" changed to \"" + q2::PVP + "\"\n" );
			}
		}
	}
}

void Quake2GiveAll( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if( q2::USE_QUAKE2_WEAPONS )
	{
		for( uint i = 0; i < q2weapons::g_arrsQ2Weapons.length(); i++ )
		{
			if( pPlayer.HasNamedPlayerItem(q2weapons::g_arrsQ2Weapons[i]) is null )
				pPlayer.GiveNamedItem( q2weapons::g_arrsQ2Weapons[i] );
		}
	}
}

} //end of namespace q2

/* FIXME
	Players take double damage from each other
	The knockback from weapons is too high in DM
	Death messages in DM don't work as they should (eg: machinegun and chaingun, splash damage from rockets and grenades)
*/

/* TODO
	Consolidate the bRerelease variables ??

	Move all settings to one place ??

	Add q2 prefix to all items ??

	IsSlime and IsLava
*/
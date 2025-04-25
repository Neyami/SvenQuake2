#include "entities/projectiles"
#include "weapons/CBaseQ2Weapon"

//Original
#include "weapons/weapon_q2blaster"
#include "weapons/weapon_q2shotgun"
#include "weapons/weapon_q2supershotgun"
#include "weapons/weapon_q2machinegun"
#include "weapons/weapon_q2chaingun"
#include "weapons/weapon_q2grenades"
#include "weapons/weapon_q2grenadelauncher"
#include "weapons/weapon_q2rocketlauncher"
#include "weapons/weapon_q2hyperblaster"
#include "weapons/weapon_q2railgun"
#include "weapons/weapon_q2bfg"

//Ground Zero
#include "weapons/weapon_q2chainfist"
#include "weapons/weapon_q2plasmabeam"

namespace q2weapons
{

const Vector DEFAULT_BULLET_SPREAD = VECTOR_CONE_3DEGREES;
const Vector DEFAULT_SHOTGUN_SPREAD = VECTOR_CONE_5DEGREES;

const int BLASTER_SLOT					= 1;
const int BLASTER_POSITION			= 11;
const int BLASTER_WEIGHT			= 5;

const int CHAINFIST_SLOT				= 1;
const int CHAINFIST_POSITION		= 12;
const int CHAINFIST_WEIGHT			= 10;

const int SHOTGUN_SLOT				= 2;
const int SHOTGUN_POSITION		= 11;
const int SHOTGUN_WEIGHT			= 15;

const int SUPERSG_SLOT				= 3;
const int SUPERSG_POSITION			= 11;
const int SUPERSG_WEIGHT			= 20;

const int MGUN_SLOT						= 4;
const int MGUN_POSITION				= 11;
const int MGUN_WEIGHT				= 25;

const int CHAINGUN_SLOT				= 5;
const int CHAINGUN_POSITION		= 11;
const int CHAINGUN_WEIGHT			= 30;

const int GLAUNCHER_SLOT			= 6;
const int GLAUNCHER_POSITION		= 11;
const int GLAUNCHER_WEIGHT		= 0;

const int GRENADES_SLOT				= 6;
const int GRENADES_POSITION		= 12;
const int GRENADES_WEIGHT			= 0;

const int RLAUNCHER_SLOT			= 7;
const int RLAUNCHER_POSITION		= 11;
const int RLAUNCHER_WEIGHT		= 0;

const int HPB_SLOT						= 8;
const int HPB_POSITION					= 11;
const int HPB_WEIGHT					= 35;

const int PLASMABEAM_SLOT			= 8;
const int PLASMABEAM_POSITION	= 13;
const int PLASMABEAM_WEIGHT		= 40;

const int RAILGUN_SLOT				= 9;
const int RAILGUN_POSITION			= 11;
const int RAILGUN_WEIGHT			= 45;

const int BFG_SLOT						= 10;
const int BFG_POSITION					= 11;
const int BFG_WEIGHT					= 0;

const int AMMO_SHELLS_MAX			= 100; //Bandolier: 150, Ammo Pack: 200
const int AMMO_BULLETS_MAX		= 200; //Bandolier: 250, Ammo Pack: 300
const int AMMO_GRENADES_MAX	= 50; //Ammo Pack: 100
const int AMMO_ROCKETS_MAX		= 50; //Ammo Pack: 100
const int AMMO_CELLS_MAX			= 200; //Bandolier: 250, Ammo Pack: 300
const int AMMO_SLUGS_MAX			= 50; //Bandolier: 75, Ammo Pack: 100

const int AMMO_SHELLS_GIVE		= 10;
const int AMMO_BULLETS_GIVE		= 50;
const int AMMO_GRENADES_GIVE	= 5;
const int AMMO_ROCKETS_GIVE		= 5;
const int AMMO_CELLS_GIVE			= 50;
const int AMMO_SLUGS_GIVE			= 10;

CCVar@ cvar_InfiniteAmmo; //CVAR_LATCH = no change until map restart/change ??
CClientCommand q2_infinite_ammo( "q2_infinite_ammo", "Infinite ammo for Quake 2 weapons? (default: 0)", @Quake2Settings );

void Register()
{
	@cvar_InfiniteAmmo = CCVar( "q2-infinite-ammo", 0, "Infinite ammo for Quake 2 weapons? (default: 0)", ConCommandFlag::AdminOnly );

	//Original
	q2blaster::Register();
	q2shotgun::Register();
	q2supershotgun::Register();
	q2machinegun::Register();
	q2chaingun::Register();
	q2grenades::Register();
	q2grenadelauncher::Register();
	q2rocketlauncher::Register();
	q2hyperblaster::Register();
	q2railgun::Register();
	q2bfg::Register();

	//Ground Zero
	q2chainfist::Register();
	q2plasmabeam::Register();
}

void Quake2Settings( const CCommand@ args )
{
	CBasePlayer@ pPlayer = g_ConCommandSystem.GetCurrentPlayer();

	if( !q2::USE_QUAKE2_WEAPONS )
	{
		g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "Quake 2 Weapons are disabled\n" );
		return;
	}

	if( args.ArgC() < 2 ) //If no args are supplied
	{
		if( args.Arg(0) == ".q2_infinite_ammo" )
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_infinite_ammo\" is \"" + cvar_InfiniteAmmo.GetInt() + "\"\n" );
	}
	else if( args.ArgC() == 2 ) //If one arg is supplied (value to set)
	{
		if( args.Arg(0) == ".q2_infinite_ammo" and Math.clamp(0, 1, atoi(args.Arg(1))) != cvar_InfiniteAmmo.GetInt() )
		{
			cvar_InfiniteAmmo.SetInt( Math.clamp(0, 1, atoi(args.Arg(1))) );
			g_PlayerFuncs.ClientPrint( pPlayer, HUD_PRINTCONSOLE, "\"q2_infinite_ammo\" changed to \"" + cvar_InfiniteAmmo.GetInt() + "\"\n" );
		}
	}
}

} //end of namespace q2weapons

/* FIXME
*/

/* TODO
	Idle animations should play less often

	BLASTER
		Somehow fix the idle animation (the third part of it glitches)


	HAND GRENADES
		Set throwing speed based on length held
		Tweak the timer ??


	CHAIN GUN
		Make it drain fewer shots from the silencer in non-rerelease ??

	GRENADE LAUNCHER
		Set the grenade angles to the velocity


	HYPER BLASTER
		Fix the idle animation (the thumb glitches)


	PLASMA BEAM
		The beam needs rings
*/



/*
		IT_WEAPON_DISRUPTOR,
		IT_WEAPON_RAILGUN,
		IT_WEAPON_PLASMABEAM,
		IT_WEAPON_IONRIPPER,
		IT_WEAPON_HYPERBLASTER,
		IT_WEAPON_ETF_RIFLE,
		IT_WEAPON_CHAINGUN,
		IT_WEAPON_MACHINEGUN,
		IT_WEAPON_SSHOTGUN,
		IT_WEAPON_SHOTGUN,
		IT_WEAPON_PHALANX,
		IT_WEAPON_RLAUNCHER,
		IT_WEAPON_GLAUNCHER,
		IT_WEAPON_PROXLAUNCHER,
		IT_WEAPON_CHAINFIST,
		IT_WEAPON_BLASTER
*/
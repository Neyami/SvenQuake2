#include "entities/projectiles"
#include "weapons/CBaseQ2Weapon"
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

namespace q2weapons
{

const Vector DEFAULT_BULLET_SPREAD = VECTOR_CONE_3DEGREES;
const Vector DEFAULT_SHOTGUN_SPREAD = VECTOR_CONE_5DEGREES;

const int BLASTER_SLOT					= 1;
const int BLASTER_POSITION			= 11;
const int BLASTER_WEIGHT			= 5;

const int SHOTGUN_SLOT				= 2;
const int SHOTGUN_POSITION		= 11;
const int SHOTGUN_WEIGHT			= 10;

const int SUPERSG_SLOT				= 3;
const int SUPERSG_POSITION			= 11;
const int SUPERSG_WEIGHT			= 15;

const int MGUN_SLOT						= 4;
const int MGUN_POSITION				= 11;
const int MGUN_WEIGHT				= 20;

const int CHAINGUN_SLOT				= 5;
const int CHAINGUN_POSITION		= 11;
const int CHAINGUN_WEIGHT			= 25;

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
const int HPB_WEIGHT					= 30;

const int RAILGUN_SLOT				= 9;
const int RAILGUN_POSITION			= 11;
const int RAILGUN_WEIGHT			= 35;

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

void Register()
{
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
*/
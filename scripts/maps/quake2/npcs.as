#include "npcs/q2npccommon"
#include "npcs/q2npcentities"
#include "npcs/q2/fire_funcs"
#include "npcs/q2npcflying"

#include "npcs/npc_q2soldier" //20-40 HP
#include "npcs/npc_q2flyer" //50 HP
#include "npcs/npc_q2enforcer" //100 HP
#include "npcs/npc_q2parasite" //175 HP
#include "npcs/npc_q2gunner" //175 HP
#include "npcs/npc_q2ironmaiden" //175 HP
#include "npcs/npc_q2berserker" //240 HP
#include "npcs/npc_q2gladiator" //400 HP
#include "npcs/npc_q2tank" //750-1000 HP
#include "npcs/npc_q2supertank" //1500 HP
#include "npcs/npc_q2jorg" //3000 HP
#include "npcs/npc_q2makron" //3000 HP

//for stadium4q2
#include "../stadium4/env_te"
#include "../stadium4/game_monstercounter"
#include "../stadium4/trigger_random_position"

namespace q2npc
{

bool g_bRerelease;
int g_iDifficulty;
int g_iChaosMode;

const Vector DEFAULT_BULLET_SPREAD = VECTOR_CONE_3DEGREES;
const Vector DEFAULT_SHOTGUN_SPREAD = VECTOR_CONE_5DEGREES;

enum sflag_e
{
	SPAWNFLAG_MONSTER_AMBUSH = 1,
	SPAWNFLAG_MONSTER_TRIGGER_SPAWN = 2/*,
	SPAWNFLAG_MONSTER_DEAD = 65536,
	SPAWNFLAG_MONSTER_SUPER_STEP = 131072,
	SPAWNFLAG_MONSTER_NO_DROP = 262144,
	SPAWNFLAG_MONSTER_SCENIC = 524288*/
};

const string KVN_MASS = "$i_q2mass";

const array<string> g_arrsQ2Monsters =
{
	"npc_q2soldier_light",
	"npc_q2soldier",
	"npc_q2soldier_ss",
	"npc_q2flyer",
	"npc_q2enforcer",
	"npc_q2parasite",
	"npc_q2gunner",
	"npc_q2ironmaiden",
	"npc_q2berserker",
	"npc_q2gladiator",
	"npc_q2tank",
	"npc_q2tankc",
	"npc_q2supertank",
	"npc_q2jorg",
	"npc_q2makron"
};

dictionary g_dicMonsterNames = 
{
	{ "npc_q2soldier_light", "a Light Soldier" },
	{ "npc_q2soldier", "a Shotgun Soldier" },
	{ "npc_q2soldier_ss", "a Machinegun Soldier" },
	{ "npc_q2flyer", "a Flyer" },
	{ "npc_q2enforcer", "an Enforcer" },
	{ "npc_q2parasite", "a Parasite" },
	{ "npc_q2gunner", "a Gunner" },
	{ "npc_q2ironmaiden", "an Iron Maiden" },
	{ "npc_q2berserker", "a Berserker" },
	{ "npc_q2gladiator", "a Gladiator" },
	{ "npc_q2tank", "a Tank" },
	{ "npc_q2tankc", "a Tank Commander" },
	{ "npc_q2supertank", "a Super Tank" },
	{ "npc_q2jorg", "Jorg" },
	{ "npc_q2makron", "Makron" }
};

const array<string> g_arrsQ2Projectiles =
{
	"q2laser",
	"q2rocket",
	"q2grenade",
	"q2bfg"
};

enum animev_e
{
	AE_IDLESOUND = 3,
	AE_WALKMOVE,
	AE_FOOTSTEP,
	AE_FLINCHRESET //HACK
};

/*
	No pain animations in nightmare
	Not much else at the moment
*/
enum diff_e
{
	DIFF_EASY = 0,
	DIFF_NORMAL,
	DIFF_HARD,
	DIFF_NIGHTMARE
};

/*
	0 = npc weapons are normal
	1 = npc weapons are randomly decided at spawn
	2 = npc weapons are random on every shot
*/
enum chaos_e
{
	CHAOS_NONE = 0,
	CHAOS_LEVEL1,
	CHAOS_LEVEL2
};

enum weapons_e
{
	WEAPON_BULLET = 0,
	WEAPON_SHOTGUN,
	WEAPON_BLASTER,
	WEAPON_GRENADE,
	WEAPON_ROCKET,
	WEAPON_HEATSEEKING,
	WEAPON_RAILGUN,
	WEAPON_BFG
};

enum parmor_e
{
	POWER_ARMOR_NONE = 0,
	POWER_ARMOR_SCREEN,
	POWER_ARMOR_SHIELD
};

void InitializeNPCS()
{
	//for gibs
	g_SoundSystem.PrecacheSound( "debris/flesh1.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh2.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh3.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh5.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh6.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh7.wav" );

	npc_q2soldier::Register();
	npc_q2flyer::Register();
	npc_q2enforcer::Register();
	npc_q2parasite::Register();
	npc_q2gunner::Register();
	npc_q2ironmaiden::Register();
	npc_q2berserker::Register();
	npc_q2gladiator::Register();
	npc_q2tank::Register();
	npc_q2supertank::Register();
	npc_q2jorg::Register();
	npc_q2makron::Register();

	//for stadium4q2
	g_CustomEntityFuncs.RegisterCustomEntity( "env_te_teleport", "env_te_teleport" );
	g_CustomEntityFuncs.RegisterCustomEntity( "game_monstercounter", "game_monstercounter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_random_position", "trigger_random_position" );

	//g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2npc::PlayerTakeDamage );
}

/*HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	if( pDamageInfo.bitsDamageType & (DMG_BURN | DMG_ACID) != 0 and pDamageInfo.pInflictor.pev.classname == "trigger_hurt" )
		return HOOK_CONTINUE;

	//TODO TIDY THIS UP
	if( pDamageInfo.pAttacker !is pDamageInfo.pVictim and g_arrsQ2Projectiles.find(pDamageInfo.pInflictor.GetClassname()) >= 0 )
	{
		CBasePlayer@ pVictim = cast<CBasePlayer@>( pDamageInfo.pVictim );
		CBaseEntity@ pProjectile = pDamageInfo.pInflictor;

		if( pVictim.IsAlive() and pDamageInfo.flDamage >= pVictim.pev.health )
		{
			KillPlayer( pVictim, pDamageInfo.bitsDamageType );

			string sDeathMsg, sModeOfDeath, sMonsterName;
			g_dicMonsterNames.get( pProjectile.pev.netname, sMonsterName );

			CustomKeyvalues@ pCustom = pVictim.GetCustomKeyvalues();

			switch( pCustom.GetKeyvalue(q2::KVN_MOD).GetInteger() )
			{
				case q2::MOD_ROCKET:
				{
					sDeathMsg = string(pVictim.pev.netname) + " ate " + sMonsterName + "'s rocket.\n";
					break;
				}

				case q2::MOD_R_SPLASH:
				{
					sDeathMsg = string(pVictim.pev.netname) + " almost dodged " + sMonsterName + "'s rocket.\n";
					break;
				}

				default:
				{
					sDeathMsg = string(pVictim.pev.netname) + "died.\n";
					break;
				}
			}
/*
			if( pProjectile.GetClassname() == "q2laser" )
			{
				if( pProjectile.pev.netname == "target_blaster" )
					sDeathMsg = string(pVictim.pev.netname) + " got blasted\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by " + sMonsterName + "\n";
			}
			else if( pProjectile.GetClassname() == "q2rocket" )
			{
				if( Math.RandomLong(1, 10) <= 5 )
					sDeathMsg = string(pVictim.pev.netname) + " almost dodged " + sMonsterName + "'s rocket\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " ate " + sMonsterName + "'s rocket\n";
			}
			else if( pProjectile.GetClassname() == "q2grenade" )
				sDeathMsg = string(pVictim.pev.netname) + " was popped by " + sMonsterName + "'s grenade\n";
			else if( pProjectile.GetClassname() == "q2bfg" )
				sDeathMsg = string(pVictim.pev.netname) + " was disintegrated by " + sMonsterName + "'s BFG\n";
			else
				return HOOK_CONTINUE;

			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );

			return HOOK_CONTINUE;
		}
	}

	if( pDamageInfo.pAttacker is null )
		return HOOK_CONTINUE;

	if( g_arrsQ2Monsters.find(pDamageInfo.pAttacker.GetClassname()) >= 0 )
	{
		CBasePlayer@ pVictim = cast<CBasePlayer@>( pDamageInfo.pVictim );

		if( pVictim.IsAlive() and pDamageInfo.flDamage >= pVictim.pev.health )
		{
			KillPlayer( pVictim, pDamageInfo.bitsDamageType );

			string sDeathMsg, sMonsterName;
			g_dicMonsterNames.get( pDamageInfo.pAttacker.GetClassname(), sMonsterName );

			if( pDamageInfo.bitsDamageType & (DMG_ALWAYSGIB + DMG_CRUSH) == (DMG_ALWAYSGIB + DMG_CRUSH) )
				sDeathMsg = string(pVictim.pev.netname) + " tried to invade " + sMonsterName + "'s personal space.\n";
			else if( HasFlags(pDamageInfo.bitsDamageType, DMG_ENERGYBEAM) )
				sDeathMsg = string(pVictim.pev.netname) + " was railed by " + sMonsterName + "\n";
			else if( HasFlags(pDamageInfo.bitsDamageType, DMG_BULLET) )
			{
				if( pDamageInfo.pAttacker.GetClassname() == "npc_q2soldier" )
					sDeathMsg = string(pVictim.pev.netname) + " was gunned down by a Shotgun Soldier\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2soldier_ss" )
					sDeathMsg = string(pVictim.pev.netname) + " was machinegunned by a Machinegun Soldier\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2gunner" )
					sDeathMsg = string(pVictim.pev.netname) + " was machinegunned by a Gunner\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by " + sMonsterName + "\n";
			}
			else
			{
				if( pDamageInfo.pAttacker.GetClassname() == "npc_q2flyer" )
					sDeathMsg = string(pVictim.pev.netname) + " was cut up by a Flyer's sharp wings\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2enforcer" )
					sDeathMsg = string(pVictim.pev.netname) + " was bludgeoned by an Enforcer\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2parasite" )
					sDeathMsg = string(pVictim.pev.netname) + " was exsanguinated by a Parasite\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2ironmaiden" )
					sDeathMsg = string(pVictim.pev.netname) + " was bitch-slapped by an Iron Maiden\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2berserker" )
					sDeathMsg = string(pVictim.pev.netname) + " was smashed by a Berserker\n";
				else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2gladiator" )
					sDeathMsg = string(pVictim.pev.netname) + " was mangled by a Gladiator's claw\n";
			}

			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
		}
	}

	return HOOK_CONTINUE;
}*/

//from quake 2 rerelease
Vector slerp( const Vector &in vecFrom, const Vector &in vecTo, float t )
{
	float flDot = DotProduct( vecFrom, vecTo );
    float aFactor;
    float bFactor;

    if( flDot > 0.9995 ) //fabsf(flDot)
    {
        aFactor = 1.0 - t;
        bFactor = t;
    }
    else
    {
        float ang = acos( flDot );
        float sinOmega = sin( ang );
        float sinAOmega = sin( (1.0 - t) * ang );
        float sinBOmega = sin( t * ang );
        aFactor = sinAOmega / sinOmega;
        bFactor = sinBOmega / sinOmega;
    }

    return vecFrom * aFactor + vecTo * bFactor;
}

int GetMass( CBaseEntity@ pEntity )
{
	CustomKeyvalues@ pCustom = pEntity.GetCustomKeyvalues();
	if( !pCustom.GetKeyvalue(q2npc::KVN_MASS).Exists() )
		return 0;

	return pCustom.GetKeyvalue( q2npc::KVN_MASS ).GetInteger();
}

bool HasFlags( int iFlagVariable, int iFlags )
{
	return (iFlagVariable & iFlags) != 0;
}

} //end of namespace q2npc

/* FIXME
	Try to fix flinching, the last frame loops for a few frames (also triggering animation events)
*/

/* TODO
	Change idle sounds so they can make use of SPAWNFLAG_MONSTER_AMBUSH

	Add Trigger Spawn

	Add blindfire ??

	Add ducking/dodging/blocking ??

	Make use of m_flGibHealth ??

	Properly figure out how to make monsters not run away when at low health

	Update the size of the monsters to make sure they've been scaled properly ??

	Separate the Strogg Guards into separate entities ??

	Consolidate the CBaseQ2NPC and CBaseQ1Flying classes ??

	Move the weapon and monster fire functions to one place ??
*/
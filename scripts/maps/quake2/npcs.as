#include "npcs/q2npccommon"
#include "npcs/q2npcentities"

#include "npcs/npc_q2soldier" //20-40 HP
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

const int SPAWNFLAG_TANK_COMMANDER_GUARDIAN = 8;
const int SPAWNFLAG_TANK_COMMANDER_HEAT_SEEKING = 16;

const array<string> g_arrsQ2Monsters =
{
	"npc_q2soldier",
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

enum diff_e
{
	DIFF_EASY = 0,
	DIFF_MEDIUM,
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
	g_bRerelease = true;
	g_iChaosMode = CHAOS_NONE;
	g_iDifficulty = DIFF_NIGHTMARE;

	//for gibs
	g_SoundSystem.PrecacheSound( "debris/flesh1.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh2.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh3.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh4.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh5.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh6.wav" );
	g_SoundSystem.PrecacheSound( "debris/flesh7.wav" );

	npc_q2soldier::Register();
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

	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2npc::PlayerTakeDamage );
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
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
			if( ((pDamageInfo.bitsDamageType & DMG_NEVERGIB) == 0 and pVictim.pev.health < -30) or (pDamageInfo.bitsDamageType & DMG_ALWAYSGIB) != 0 ) 
			{
				pVictim.GibMonster();
				pVictim.pev.effects |= EF_NODRAW;
			}

			pVictim.Killed( null, GIB_NOPENALTY );
			pVictim.m_iDeaths++;

			string sDeathMsg;

			if( pProjectile.GetClassname() == "q2laser" )
			{
				if( pProjectile.pev.targetname == "npc_q2soldier" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by a Light Guard\n";
				else if( pProjectile.pev.targetname == "npc_q2tank" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by a Tank\n";
				else if( pProjectile.pev.targetname == "npc_q2tankc" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by a Tank Commander\n";
				else if( pProjectile.pev.targetname == "npc_q2makron" )
					sDeathMsg = string(pVictim.pev.netname) + " was blasted by Makron\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pProjectile.GetClassname() == "q2rocket" )
			{
				if( pProjectile.pev.targetname == "npc_q2ironmaiden" )
				{
					if( Math.RandomLong(1, 10) <= 5 )
						sDeathMsg = string(pVictim.pev.netname) + "  almost dodged an Iron Maiden's rocket\n";
					else
						sDeathMsg = string(pVictim.pev.netname) + " ate an Iron Maiden's rocket\n";
				}
				else if( pProjectile.pev.targetname == "npc_q2tank" )
				{
					if( Math.RandomLong(1, 10) <= 5 )
						sDeathMsg = string(pVictim.pev.netname) + " almost dodged a Tank's rocket\n";
					else
						sDeathMsg = string(pVictim.pev.netname) + " ate a Tank's rocket\n";
				}
				else if( pProjectile.pev.targetname == "npc_q2tankc" )
				{
					if( Math.RandomLong(1, 10) <= 5 )
						sDeathMsg = string(pVictim.pev.netname) + " almost dodged a Tank Commander's rocket\n";
					else
						sDeathMsg = string(pVictim.pev.netname) + " ate a Tank Commander's rocket\n";
				}
				else if( pProjectile.pev.targetname == "npc_q2supertank" )
				{
					if( Math.RandomLong(1, 10) <= 5 )
						sDeathMsg = string(pVictim.pev.netname) + " almost dodged a Super Tank's rocket\n";
					else
						sDeathMsg = string(pVictim.pev.netname) + " ate a Super Tank's rocket\n";
				}
				else
					return HOOK_CONTINUE;
			}
			else if( pProjectile.GetClassname() == "q2grenade" )
			{
				if( pProjectile.pev.targetname == "npc_q2supertank" )
					sDeathMsg = string(pVictim.pev.netname) + " was popped by a Super Tank's grenade\n";
				else if( pProjectile.pev.targetname == "npc_q2gunner" )
					sDeathMsg = string(pVictim.pev.netname) + " was popped by a Gunner's grenade\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pProjectile.GetClassname() == "q2bfg" )
			{
				if( pProjectile.pev.targetname == "npc_q2jorg" )
					sDeathMsg = string(pVictim.pev.netname) + " was disintegrated by Jorg's BFG\n";
				else if( pProjectile.pev.targetname == "npc_q2makron" )
					sDeathMsg = string(pVictim.pev.netname) + " was disintegrated by Makron's BFG\n";
				else
					return HOOK_CONTINUE;
			}
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
			if( ((pDamageInfo.bitsDamageType & DMG_NEVERGIB) == 0 and pVictim.pev.health < -30) or (pDamageInfo.bitsDamageType & DMG_ALWAYSGIB) != 0 ) 
			{
				pVictim.GibMonster();
				pVictim.pev.effects |= EF_NODRAW;
			}

			pVictim.Killed( null, GIB_NOPENALTY );
			pVictim.m_iDeaths++;

			string sDeathMsg;

			if( pDamageInfo.pAttacker.GetClassname() == "npc_q2soldier" )
			{
				if( pDamageInfo.pAttacker.pev.weapons == 1 )
					sDeathMsg = string(pVictim.pev.netname) + " was gunned down by a Shotgun Guard\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was machine-gunned by a Machinegun Guard\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2enforcer" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by an Enforcer\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was bludgeoned by an Enforcer\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2parasite" )
				sDeathMsg = string(pVictim.pev.netname) + " was exsanguinated by a Parasite\n";
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2gunner" )
				sDeathMsg = string(pVictim.pev.netname) + " was machinegunned by a Gunner\n";
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2ironmaiden" )
				sDeathMsg = string(pVictim.pev.netname) + " was bitch-slapped by an Iron Maiden\n";
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2berserker" )
				sDeathMsg = string(pVictim.pev.netname) + " was smashed by a Berserker\n";
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2gladiator" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_ENERGYBEAM) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was railed by a Gladiator\n";
				else
					sDeathMsg = string(pVictim.pev.netname) + " was mangled by a Gladiator's claw\n";
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2tank" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by a Tank\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2tankc" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by a Tank Commander\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2supertank" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by a Super Tank\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2jorg" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_BULLET) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was pumped full of lead by Jorg\n";
				else
					return HOOK_CONTINUE;
			}
			else if( pDamageInfo.pAttacker.GetClassname() == "npc_q2makron" )
			{
				if( (pDamageInfo.bitsDamageType & DMG_ENERGYBEAM) != 0 )
					sDeathMsg = string(pVictim.pev.netname) + " was railed by Makron\n";
				else
					return HOOK_CONTINUE;
			}

			g_PlayerFuncs.ClientPrintAll( HUD_PRINTNOTIFY, sDeathMsg );
		}
	}

	return HOOK_CONTINUE;
}

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

} //end of namespace q2npc

/* FIXME
*/

/* TODO
	Try to fix flinching, the last frame loops for a few frames (also triggering animation events)

	Add blindfire ??

	Add ducking/dodging/blocking ??

	Make use of m_flGibHealth ??

	Properly figure out how to make monsters not run away when at low health

	Update the size of the monsters to make sure they've been scaled properly ??

	Separate the Strogg Guards into separate entities ??
*/
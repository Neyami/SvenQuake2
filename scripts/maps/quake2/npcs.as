#include "npcs/q2npccommon"
#include "npcs/q2npcentities"
#include "npcs/q2/fire_funcs"
#include "npcs/q2npcflying"
#include "entities/bossexploder"
#include "entities/spawngro"

#include "npcs/npc_q2soldier" //20-40 HP
#include "npcs/npc_q2flyer" //50 HP
#include "npcs/npc_q2enforcer" //100 HP
#include "npcs/npc_q2parasite" //175 HP
#include "npcs/npc_q2gunner" //175 HP
#include "npcs/npc_q2ironmaiden" //175 HP
#include "npcs/npc_q2berserker" //240 HP
#include "npcs/npc_q2brains" //300 HP
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

const string KVN_MASS = "$i_q2mass";
const string KVN_RESURRECTING = "$i_q2resurrecting";

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
	"npc_q2brains",
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
	{ "npc_q2brains", "a Brains" },
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
	npc_q2brains::Register();
	npc_q2gladiator::Register();
	npc_q2tank::Register();
	npc_q2supertank::Register();
	npc_q2jorg::Register();
	npc_q2makron::Register();

	q2bossexploder::Register();
	q2spawngro::Register();

	//for stadium4q2
	g_CustomEntityFuncs.RegisterCustomEntity( "env_te_teleport", "env_te_teleport" );
	g_CustomEntityFuncs.RegisterCustomEntity( "game_monstercounter", "game_monstercounter" );
	g_CustomEntityFuncs.RegisterCustomEntity( "trigger_random_position", "trigger_random_position" );

	//g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2npc::PlayerTakeDamage );
}

CBaseQ2NPC@ GetQ2Pointer( CBaseEntity@ pEntity )
{
	return cast<CBaseQ2NPC@>( CastToScriptClass(pEntity) );
}

int64 GetMonsterFlags( CBaseEntity@ pEntity )
{
	CBaseQ2NPC@ pMonster = cast<CBaseQ2NPC@>( CastToScriptClass(pEntity) );
	if( pMonster !is null )
		return pMonster.m_iMonsterFlags;

	return q2::FL_NONE;
}

//from quake 2 rerelease
//adjust the monster's health from how many active players we have
void G_Monster_ScaleCoopHealth( CBaseEntity@ pEntity )
{
	CBaseQ2NPC@ pMonster = q2npc::GetQ2Pointer(pEntity);
	if( pMonster is null )
		return;

	// already scaled
	if( pMonster.monsterinfo.health_scaling >= g_PlayerFuncs.GetNumPlayers() ) //level.coop_scale_players
		return;

	// this is just to fix monsters that change health after spawning...
	// looking at you, soldiers
	if( pMonster.monsterinfo.base_health <= 0 )
		pMonster.monsterinfo.base_health = pMonster.pev.max_health;

	int iDelta = g_PlayerFuncs.GetNumPlayers() - pMonster.monsterinfo.health_scaling;
	float flAdditionalHealth = iDelta * ( pMonster.monsterinfo.base_health * q2::cvar_CoopHealthScaling.GetFloat() ); //level.coop_health_scaling

	pMonster.pev.health = Math.max( 1, pMonster.pev.health + flAdditionalHealth );
	pMonster.pev.max_health += flAdditionalHealth;

	pMonster.monsterinfo.health_scaling = g_PlayerFuncs.GetNumPlayers();
}

//from quake 2 rerelease
// check all active monsters' scaling
void G_Monster_CheckCoopHealthScaling()
{
	//for (auto monster : entity_iterable_t<monster_filter_t>())
	//return self->inuse && (self->flags & FL_COOP_HEALTH_SCALE) && self->health > 0; 

	edict_t@ edict = null;
	CBaseEntity@ pEntity = null;

	for( int i = 0; i < g_Engine.maxEntities; ++i )
	{
		@edict = @g_EntityFuncs.IndexEnt( i );

		@pEntity = g_EntityFuncs.Instance( edict );

		if( pEntity !is null and g_arrsQ2Monsters.find(pEntity.GetClassname()) >= 0 and pEntity.pev.deadflag == DEAD_NO )
		{
			//g_Game.AlertMessage( at_notice, "Running G_Monster_ScaleCoopHealth on %1\n", pEntity.GetClassname() );
			G_Monster_ScaleCoopHealth( pEntity );
		}
	}
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
	Change idle sounds so they can make use of q2::SPAWNFLAG_MONSTER_AMBUSH

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
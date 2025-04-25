#include "entities/func_explosive"
#include "entities/func_timer"
#include "entities/misc_deadsoldier"
#include "entities/misc_explobox"
#include "entities/light_mine2"
#include "entities/path_corner_q2"
//#include "entities/point_combat"
#include "entities/target_blaster"
#include "entities/target_goal"
#include "entities/target_help"
#include "entities/target_secret"
#include "entities/target_speaker"
#include "entities/target_splash"
#include "entities/trigger_always"
#include "entities/trigger_counter_q2"
#include "entities/trigger_key"

namespace q2entities
{

const Vector VEC_UP = Vector( 0, -1, 0 );
const Vector MOVEDIR_UP = Vector( 0, 0, 1 );
const Vector VEC_DOWN = Vector( 0, -2, 0 );
const Vector MOVEDIR_DOWN = Vector( 0, 0, -1 ); 

mixin class CBaseQ2Entity
{
	void BecomeExplosion1()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/rocklx1a.wav", VOL_NORM, ATTN_NORM );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );
			m1.WriteByte( int(30 * pev.scale) ); //scale
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_EntityFuncs.Remove( self );
	}

	void BecomeExplosion2()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/grenlx1a.wav", VOL_NORM, ATTN_NORM );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );
			m1.WriteByte( int(30 * pev.scale) ); //scale
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_EntityFuncs.Remove( self );
	}

	void fire_blaster( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHyper = false )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, false, self.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );
		pLaser.pev.netname = self.GetClassname(); //for death messages
		pLaser.pev.weapons = q2::MOD_TARGET_BLASTER; //TODO fix this (SPAWNFLAG_BLASTER_NOTRAIL)
	}

	void G_UseTargets( CBaseEntity@ pActivator, USE_TYPE useType, float flValue )
	{
		self.SUB_UseTargets( pActivator, useType, flValue );

		if( !string(pev.message).IsEmpty() and !pActivator.pev.FlagBitSet(FL_MONSTER) )
		{
			CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
			g_EngineFuncs.ClientPrintf( pPlayer, print_center, string(pev.message) );
		}
	}

	void G_SetMovedir( Vector &in angles, Vector &out movedir )
	{
		if( angles == VEC_UP )
			movedir = MOVEDIR_UP;
		else if( angles == VEC_DOWN )
			movedir = MOVEDIR_DOWN;
		else
			g_EngineFuncs.AngleVectors( angles, movedir, void, void );

		angles = g_vecZero; //??
	}

	bool HasFlags( int iFlagVariable, int iFlags )
	{
		return (iFlagVariable & iFlags) != 0;
	}
}

void Register()
{
	q2func_explosive::Register();
	q2func_timer::Register();
	q2misc_deadsoldier::Register();
	q2misc_explobox::Register();
	q2light_mine2::Register();
	q2path_corner_q2::Register();
	//q2point_combat::Register();
	q2target_blaster::Register();
	q2target_goal::Register();
	q2target_help::Register();
	q2target_secret::Register();
	q2target_speaker::Register();
	q2target_splash::Register();
	q2trigger_always::Register();
	q2trigger_counter_q2::Register();
	q2trigger_key::Register();
}

} //end of namespace q2entities

/* FIXME
*/

/* TODO
*/
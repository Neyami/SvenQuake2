/*QUAKED func_explosive (0 .5 .8) ? Trigger_Spawn ANIMATED ANIMATED_FAST
Any brush that you want to explode or break apart.  If you want an
ex0plosion, set dmg and it will do a radius explosion of that amount
at the center of the bursh.

If targeted it will not be shootable.

health defaults to 100.

mass defaults to 75.  This determines how much debris is emitted when
it explodes.  You get one large chunk per 100 of mass (up to 8) and
one small chunk per 25 of mass (up to 16).  So 800 gives the most.
*/

namespace q2func_explosive
{

enum feflags_e
{
	SPAWNFLAGS_EXPLOSIVE_TRIGGER_SPAWN = 1,
	SPAWNFLAGS_EXPLOSIVE_ANIMATED = 2,
	SPAWNFLAGS_EXPLOSIVE_ANIMATED_FAST = 4,
	SPAWNFLAGS_EXPLOSIVE_INACTIVE = 8,
	SPAWNFLAGS_EXPLOSIVE_ALWAYS_SHOOTABLE = 16
};

class func_explosive : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private int m_iMass;
	private int m_iSounds;
	private bool m_bFuncExplosiveUse;
	private bool m_bFuncExplosiveExplode;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "mass" )
		{
			m_iMass = atoi( szValue );
			return true;
		}
		else if( szKey == "sounds" )
		{
			m_iSounds = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( q2::PVP )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		pev.movetype = MOVETYPE_PUSH; // MOVETYPE_PUSHSTEP ??

		Precache();

		g_EntityFuncs.SetModel( self, pev.model );

		if( HasFlags(pev.spawnflags, SPAWNFLAGS_EXPLOSIVE_TRIGGER_SPAWN) )
		{
			//self->svflags |= SVF_NOCLIENT;
			pev.takedamage = DAMAGE_NO;
			pev.effects |= EF_NODRAW;
			pev.solid = SOLID_NOT;
			SetUse( UseFunction(this.func_explosive_spawn) );
		}
		else
		{
			pev.solid = SOLID_BSP;

			if( !string(pev.targetname).IsEmpty() )
			{
				SetUse( UseFunction(this.func_explosive_use) );
				m_bFuncExplosiveUse = true;
			}
		}

		/*if( HasFlags(pev.spawnflags, SPAWNFLAGS_EXPLOSIVE_ANIMATED) )
			self->s.effects |= EF_ANIM_ALL;

		if( HasFlags(pev.spawnflags, SPAWNFLAGS_EXPLOSIVE_ANIMATED_FAST) )
			self->s.effects |= EF_ANIM_ALLFAST;*/

		if( !m_bFuncExplosiveUse )
		{
			if( pev.health == 0 )
				pev.health = 100;

			m_bFuncExplosiveExplode = true;
			pev.takedamage = DAMAGE_YES;
		}

		if( m_iSounds != 0 )
		{
			if( m_iSounds == 1 )
				pev.noise = "quake2/world/brkglas.wav";
			else
				g_Game.AlertMessage( at_error, "%1: invalid \"sounds\" %2\n", self.GetClassname(), m_iSounds );
		}

		if( pev.scale == 0 )
			pev.scale = 1;

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/objects/debris1.mdl" );
		g_Game.PrecacheModel( "models/quake2/objects/debris2.mdl" );

		for( uint i = 0; i < q2projectiles::pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( q2projectiles::pExplosionSprites[i] );

		g_SoundSystem.PrecacheSound( "quake2/world/brkglas.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rocklx1a.wav" );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( m_bFuncExplosiveExplode )
			func_explosive_explode( self, g_EntityFuncs.Instance(pevAttacker) );
		else
			BaseClass.Killed( pevAttacker, iGib );
	}

	void func_explosive_spawn( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( !m_bFuncExplosiveUse )
			pev.takedamage = DAMAGE_YES;

		pev.effects &= ~EF_NODRAW;
		pev.solid = SOLID_BSP;
		SetUse( null );
		q2::KillBox( self );
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void func_explosive_use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		func_explosive_explode( self, pActivator );
	}

	void func_explosive_explode( CBaseEntity@ pInflictor, CBaseEntity@ pAttacker )
	{
		int iCount;
		int iMass;

		pev.takedamage = DAMAGE_NO;

		if( pev.dmg != 0 )
			q2::T_RadiusDamage( self, pAttacker, pev.dmg, null, pev.dmg + 40, 0, q2::MOD_EXPLOSIVE ); //DAMAGE_NONE

		pev.velocity = pInflictor.pev.origin - pev.origin;
		pev.velocity = pev.velocity.Normalize();
		pev.velocity = pev.velocity * 150;

		iMass = m_iMass;
		if( iMass <= 0 )
			iMass = 75;

		// big chunks
		if( iMass >= 100 )
		{
			iCount = iMass / 100;
			if( iCount > 8 )
				iCount = 8;

			q2::ThrowGib( self, iCount, "models/quake2/objects/debris1.mdl", 1, -1, q2::GIB_METALLIC | q2::GIB_DEBRIS );
		}

		// small chunks
		iCount = iMass / 25;
		if( iCount > 16 )
			iCount = 16;

		q2::ThrowGib( self, iCount, "models/quake2/objects/debris2.mdl", 2, -1, q2::GIB_METALLIC | q2::GIB_DEBRIS );

		G_UseTargets( pAttacker, USE_TOGGLE, 0.0 );

		// bmodel origins are (0 0 0), we need to adjust that here
		pev.origin = (pev.absmin + pev.absmax) * 0.5;

		if( !string(pev.noise).IsEmpty() )
			g_SoundSystem.PlaySound( self.edict(), CHAN_AUTO, string(pev.noise), VOL_NORM, ATTN_NORM, 0, PITCH_NORM, 0, true, pev.origin );
			//g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, string(pev.noise), VOL_NORM, ATTN_NORM );

		if( pev.dmg != 0 )
			BecomeExplosion1();
		else
			g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2func_explosive::func_explosive", "func_explosive" );
}

} //end of namespace q2func_explosive
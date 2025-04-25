namespace q2target_blaster
{

const int SPAWNFLAG_BLASTER_NOTRAIL = 1;
const int SPAWNFLAG_BLASTER_NOEFFECTS = 2;

class target_blaster : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Precache();

		g_EntityFuncs.SetOrigin( self, pev.origin );

		SetUse( UseFunction(this.use_target_blaster) );

		G_SetMovedir( pev.angles, pev.movedir );

		if( pev.dmg == 0 )
			pev.dmg = 15.0;

		if( pev.speed == 0 )
			pev.speed = 1000.0;
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake2/weapons/laser2.wav" );
	}

	void use_target_blaster( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		bool bHyper;

		/*if( HasFlags(pev.spawnflags, SPAWNFLAG_BLASTER_NOEFFECTS) )
			effect = EF_NONE;
		else */if( HasFlags(pev.spawnflags, SPAWNFLAG_BLASTER_NOTRAIL) )
			bHyper = true;
		else
			bHyper = false;

		fire_blaster( pev.origin, pev.movedir, pev.dmg, pev.speed, bHyper );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser2.wav", VOL_NORM, ATTN_NORM );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_blaster::target_blaster", "target_blaster" );
	g_Game.PrecacheOther( "target_blaster" );
}

} //end of namespace q2target_blaster

/*
		case MOD_TARGET_BLASTER:
			message = "got blasted";
*/
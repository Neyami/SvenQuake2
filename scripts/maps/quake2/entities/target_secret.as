namespace q2target_secret
{

class target_secret : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
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

		SetThink( ThinkFunction(this.G_VerifyTargetted) );
		pev.nextthink = g_Engine.time + 0.01; //10_ms

		SetUse( UseFunction(this.use_target_secret) );

		if( string(pev.noise).IsEmpty() )
			pev.noise = "quake2/misc/secret.wav";

		Precache();

		q2::g_iTotalSecrets++;
		//g_Game.AlertMessage( at_notice, "g_iTotalSecrets is now %1\n", q2::g_iTotalSecrets );

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( string(pev.noise) );
	}

	void G_VerifyTargetted()
	{
		if( string(pev.targetname).IsEmpty() )
			g_Game.AlertMessage( at_error, "WARNING: missing targetname on %1\n", self.GetClassname() );
		else if( g_EntityFuncs.FindEntityByString(null, "target", pev.targetname) is null )
			g_Game.AlertMessage( at_error, "WARNING: doesn't appear to be anything targeting %1\n", self.GetClassname() );
	}

	void use_target_secret( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, string(pev.noise), VOL_NORM, ATTN_NORM );

		q2::g_iFoundSecrets++;
		//g_Game.AlertMessage( at_notice, "g_iFoundSecrets is now %1\n", q2::g_iFoundSecrets );

		G_UseTargets( pActivator, useType, flValue );

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_secret::target_secret", "target_secret" );
	g_Game.PrecacheOther( "target_secret" );
}

} //end of namespace q2target_secret
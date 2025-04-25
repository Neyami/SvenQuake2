namespace q2target_goal
{

const int SPAWNFLAG_GOAL_KEEP_MUSIC = 1;

class target_goal : ScriptBaseEntity, q2entities::CBaseQ2Entity
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

		SetUse( UseFunction(this.use_target_goal) );

		if( string(pev.noise).IsEmpty() )
			pev.noise = "quake2/misc/secret.wav";
		else
			pev.noise = "quake2/" + pev.noise;

		Precache();

		q2::g_iTotalGoals++;
		//g_Game.AlertMessage( at_notice, "g_iTotalGoals is now %1\n", q2::g_iTotalGoals );

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake2/misc/secret.wav" );
		g_SoundSystem.PrecacheSound( string(pev.noise) );
	}

	void use_target_goal( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, string(pev.noise), VOL_NORM, ATTN_NORM );

		q2::g_iFoundGoals++;
		//g_Game.AlertMessage( at_notice, "g_iFoundGoals is now %1\n", q2::g_iFoundGoals );

		/*if( q2::g_iFoundGoals == q2::g_iTotalGoals and !HasFlags(pev.spawnflags, SPAWNFLAG_GOAL_KEEP_MUSIC) )
		{
			if( ent->sounds )
				gi.configstring (CS_CDTRACK, G_Fmt("{}", ent->sounds).data() );
			else
				gi.configstring(CS_CDTRACK, "0");
		}*/

		G_UseTargets( pActivator, useType, flValue );
		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_goal::target_goal", "target_goal" );
	g_Game.PrecacheOther( "target_goal" );
}

} //end of namespace q2target_goal
/*QUAKED target_help (1 0 1) (-16 -16 -24) (16 16 24) help1
When fired, the "message" key becomes the current personal computer string, and the message light will be set on all clients status bars.
*/

namespace q2target_help
{

const int SPAWNFLAG_HELP_HELP1 = 1;

class target_help : ScriptBaseEntity, q2entities::CBaseQ2Entity
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

		if( string(pev.message).IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "%1: no message\n", self.GetClassname() );
			g_EntityFuncs.Remove( self );
			return;
		}

		SetUse( UseFunction(this.Use_Target_Help) );

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake2/misc/secret.wav" );
		g_SoundSystem.PrecacheSound( string(pev.noise) );
	}

	void Use_Target_Help( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( HasFlags(pev.spawnflags, SPAWNFLAG_HELP_HELP1) )
			q2::g_sGameHelpMessage1 = string( pev.message );
		else
			q2::g_sGameHelpMessage2 = string( pev.message );

		q2::g_iGameHelpChanged++;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_help::target_help", "target_help" );
	g_Game.PrecacheOther( "target_help" );
}

} //end of namespace q2target_help
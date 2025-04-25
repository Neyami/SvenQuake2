namespace q2target_speaker
{

class target_speaker : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private int m_iAttenuation;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "volume" )
		{
			pev.health = 10.0 * atof( szValue ); //max volume in Q2 is 1.0, 10 in SC

			return true;
		}
		else if( szKey == "attenuation" )
		{
			m_iAttenuation = atoi( szValue );

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

		if( string(pev.noise).IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "target_speaker with no noise set at %1\n", pev.origin.ToString() );
			return;
		}

		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		Precache();

		CreateAmbientGeneric();

		g_EntityFuncs.Remove( self );
	}

	void Precache()
	{
		string szSoundFile = string( pev.noise );

		if( !szSoundFile.StartsWith("quake2/") )
			pev.noise = "quake2/" + szSoundFile;

		g_SoundSystem.PrecacheSound( pev.noise );
	}

	void CreateAmbientGeneric()
	{
		dictionary keys;
		int iSpawnflags = 0;

		if( pev.health <= 0.0 ) pev.health = 10.0;

		keys[ "origin" ] = pev.origin.ToString();
		keys[ "message" ] = string( pev.noise ); //Sound File
		keys[ "health" ] = string( pev.health ); //Volume (10 = loudest)

		// Handle attenuation settings
		switch( m_iAttenuation )
		{
			case -1: iSpawnflags |= 1; break; // Play everywhere

			case  0: //Tiny Radius
			{
				keys[ "linearmin" ] = "0"; //from 0 units
				keys[ "linearmax" ] = "1"; //to 256 units
				break;
			}

			default:
			{
				keys[ "m_flAttenuation" ] = string( m_iAttenuation );
				break;
			}
		}

		bool bLoopedOnOrOff = HasFlags( pev.spawnflags, 1 | 2 );
		bool bLoopedOff = HasFlags( pev.spawnflags, 2 );

		if( bLoopedOnOrOff )
			keys[ "playmode" ] = (m_iAttenuation == 0) ? "6" : "2"; //Linear / Loop : Loop
		else
			keys[ "playmode" ] = (m_iAttenuation == 0) ? "5" : "1"; //Linear / Play Once : Play Once (whenever triggered)

		if( !string(pev.targetname).IsEmpty() )
			keys[ "targetname" ] = string( pev.targetname );

		if( bLoopedOff )
			iSpawnflags |= 16; //Start Silent

		if( iSpawnflags != 0 )
			keys[ "spawnflags" ] = string(iSpawnflags);

		g_EntityFuncs.CreateEntity( "ambient_generic", keys, true );
	}

	bool HasFlags( int iFlagVariable, int iFlags )
	{
		return (iFlagVariable & iFlags) != 0;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_speaker::target_speaker", "target_speaker" );
	g_Game.PrecacheOther( "target_speaker" );
}

} //end of namespace q2target_speaker
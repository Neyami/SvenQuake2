namespace q2path_corner_q2
{

const int SPAWNFLAG_PATH_CORNER_TELEPORT = 1;

class path_corner_q2 : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private string m_sPathTarget;
	private float m_flWait;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "pathtarget" )
		{
			m_sPathTarget = szValue;
			return true;
		}
		else if( szKey == "wait" )
		{
			m_flWait = atof( szValue );
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

		if( string(pev.targetname).IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "path_corner_q2 with no targetname at %1\n", pev.origin.ToString() );
			g_EntityFuncs.Remove( self );
			return;
		}

		g_EntityFuncs.SetOrigin( self, pev.origin );

		CreatePathCorner();

		g_EntityFuncs.Remove( self );
	}

	void CreatePathCorner()
	{
		dictionary keys;
		int iSpawnFlags = 0;

		keys[ "origin" ] = pev.origin.ToString();
		keys[ "targetname" ] = string( pev.targetname );

		if( !string(pev.target).IsEmpty() )
			keys[ "target" ] = string( pev.target );

		//Fire On Arrive
		if( !m_sPathTarget.IsEmpty() )
			keys[ "message" ] = m_sPathTarget;
		else if( !string(pev.message).IsEmpty() )
			keys[ "message" ] = string( pev.message );

		if( m_flWait == -1 )
			iSpawnFlags |= 1; //Wait for retrigger
		else
			keys[ "wait" ] = string( m_flWait );

		if( HasFlags(pev.spawnflags, SPAWNFLAG_PATH_CORNER_TELEPORT) )
			iSpawnFlags |= 2;

		keys[ "spawnflags" ] = string( iSpawnFlags );

		g_EntityFuncs.CreateEntity( "path_corner", keys, true );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2path_corner_q2::path_corner_q2", "path_corner_q2" );
}

} //end of namespace q2path_corner_q2
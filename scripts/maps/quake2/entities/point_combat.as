namespace q2point_combat
{

class point_combat : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( string(pev.target).IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "point_combat with no target set at %1\n", pev.origin.ToString() );
			return;
		}

		g_EntityFuncs.SetOrigin( self, pev.origin );

		//CreateScriptedSequence();

		g_EntityFuncs.Remove( self );
	}

	void CreateScriptedSequence()
	{
		dictionary keys;
		int iSpawnflags = 1; //Remove On fire

		keys[ "origin" ] = pev.origin.ToString();
		keys[ "target" ] = string( pev.target );
		keys[ "triggerstate" ] = "2"; //Toggle

		if( !string(pev.targetname).IsEmpty() )
			keys[ "targetname" ] = string( pev.targetname );

		if( iSpawnflags != 0 )
			keys[ "spawnflags" ] = string(iSpawnflags);

		g_EntityFuncs.CreateEntity( "trigger_auto", keys, true );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2point_combat::point_combat", "point_combat" );
}

} //end of namespace q2point_combat
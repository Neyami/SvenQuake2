namespace q2trigger_always
{

class trigger_always : ScriptBaseEntity, q2entities::CBaseQ2Entity
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
			g_Game.AlertMessage( at_error, "trigger_always with no target set at %1\n", pev.origin.ToString() );
			return;
		}

		g_EntityFuncs.SetOrigin( self, pev.origin );

		CreateTriggerAuto();

		g_EntityFuncs.Remove( self );
	}

	void CreateTriggerAuto()
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
	g_CustomEntityFuncs.RegisterCustomEntity( "q2trigger_always::trigger_always", "trigger_always" );
}

} //end of namespace q2trigger_always
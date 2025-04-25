namespace q2light_mine2
{

class light_mine2 : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		Precache();

		pev.movetype		= MOVETYPE_NONE;
		pev.solid				= SOLID_NOT;

		g_EntityFuncs.SetModel( self, "models/quake2/objects/minelite/light2.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-2, -2, -12), Vector(2, 2, 12) );
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/objects/minelite/light2.mdl" );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2light_mine2::light_mine2", "light_mine2" );
	g_Game.PrecacheOther( "light_mine2" );
}

} //end of namespace q2light_mine2
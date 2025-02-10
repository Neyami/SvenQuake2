namespace q2npc
{

class q2pscreen : ScriptBaseAnimating
{
	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/items/armor/effect/pscreen.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_NONE;
		pev.solid = SOLID_NOT;

		SetThink( ThinkFunction(this.RemoveThink) );
		pev.nextthink = g_Engine.time;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/items/armor/effect/pscreen.mdl" );

		g_SoundSystem.PrecacheSound( "quake2/misc/mon_power2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/lashit.wav" );
	}

	void RemoveThink()
	{
		if( pev.renderamt > 7 )
		{
			pev.renderamt -= 7;
			pev.nextthink = g_Engine.time + 0.05;
		}
		else 
		{
			pev.renderamt = 0;
			pev.nextthink = g_Engine.time;
			SetThink( ThinkFunction(this.SUB_Remove) );
		}
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

void RegisterNPCPScreen()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2npc::q2pscreen", "q2pscreen" );
	g_Game.PrecacheOther( "q2pscreen" );
}

} //namespace q2npc END
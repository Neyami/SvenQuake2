namespace q2misc_deadsoldier
{

class misc_deadsoldier : ScriptBaseEntity, q2entities::CBaseQ2Entity
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

		Precache();

		pev.movetype		= MOVETYPE_NONE;
		pev.solid				= SOLID_BBOX;
		g_EntityFuncs.SetModel( self, "models/quake2/deadbods/dude.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-4, -4, 0), Vector(4, 4, 4) );
		pev.deadflag			= DEAD_DEAD;
		pev.takedamage	= DAMAGE_YES;

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/deadbods/dude.mdl" );
		g_Game.PrecacheModel( "models/quake2/objects/gibs/sm_meat.mdl" );
		g_Game.PrecacheModel( "models/quake2/objects/gibs/head2.mdl" );

		g_SoundSystem.PrecacheSound( "quake2/misc/udeath.wav" );
	}

	int BloodColor() { return BLOOD_COLOR_RED; }

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		pev.dmg = flDamage;
		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( pev.health > -30 )
			return;

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/misc/udeath.wav", VOL_NORM, ATTN_NORM );
		q2::ThrowGib( self, 4, "models/quake2/objects/gibs/sm_meat.mdl", pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, "models/quake2/objects/gibs/head2.mdl", pev.dmg, 4, BREAK_FLESH );

		g_EntityFuncs.Remove( self );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2misc_deadsoldier::misc_deadsoldier", "misc_deadsoldier" );
	g_Game.PrecacheOther( "misc_deadsoldier" );
}

} //end of namespace q2misc_deadsoldier
namespace q2misc_explobox
{

const string MODEL_GIB1	= "models/quake2/objects/debris1.mdl";
const string MODEL_GIB2	= "models/quake2/objects/debris2.mdl";
const string MODEL_GIB3	= "models/quake2/objects/debris3.mdl";

class misc_explobox : ScriptBaseMonsterEntity, q2entities::CBaseQ2Entity //ScriptBaseEntity
{
	private EHandle m_hActivator;
	private float m_flDamage; //pev.dmg doesn't work for some reason :aRage:
	private int m_iMass;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "damage" )
		{
			m_flDamage = atof( szValue );

			return true;
		}
		else if( szKey == "mass" )
		{
			m_iMass = atoi( szValue );

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

		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/objects/barrels.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-16, -16, 0), Vector(16, 16, 40) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid				= SOLID_BBOX;
		pev.movetype		= MOVETYPE_PUSHSTEP; //MOVETYPE_STEP
		pev.takedamage	= DAMAGE_YES;
		self.m_bloodColor	= DONT_BLEED;

		if( pev.scale == 0 )
			pev.scale = 1.0;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName = "Large Exploding Box";

		if( m_iMass == 0 )
			m_iMass = 400;

		if( pev.health == 0 )
			pev.health = 10;

		if( m_flDamage == 0 )
			m_flDamage = 150;

		SetTouch( TouchFunction(this.barrel_touch) );
		SetThink( ThinkFunction(this.M_droptofloor) );
		pev.nextthink = g_Engine.time + 2.0 * q2::FRAMETIME;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/objects/barrels.mdl" );
		g_Game.PrecacheModel( MODEL_GIB1 );
		g_Game.PrecacheModel( MODEL_GIB2 );
		g_Game.PrecacheModel( MODEL_GIB3 );

		for( uint i = 0; i < q2projectiles::pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( q2projectiles::pExplosionSprites[i] );

		g_SoundSystem.PrecacheSound( "quake2/weapons/rocklx1a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenlx1a.wav" );
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		pev.takedamage = DAMAGE_NO;
		pev.nextthink = g_Engine.time + 2 * q2::FRAMETIME;
		SetThink( ThinkFunction(this.barrel_explode) );
		m_hActivator = EHandle( g_EntityFuncs.Instance(pevAttacker) );
	}

	void barrel_touch( CBaseEntity@ pOther )
	{
		float ratio;
		Vector v;

		if( !pOther.pev.FlagBitSet(FL_ONGROUND) or pOther.pev.groundentity is self.edict() )
			return;

		int iOtherMass = q2npc::GetMass( pOther );
		if( iOtherMass != 0 )
			ratio = float(iOtherMass) / float(m_iMass);
		else
			ratio = pOther.pev.size.Length() / pev.size.Length(); //Is this an adequate replacement ??

		v = pev.origin - pOther.pev.origin;
		WalkMove( Math.VecToYaw(v), 20 * ratio * q2::FRAMETIME );
	}

	void barrel_explode()
	{
		q2::T_RadiusDamage( self, m_hActivator.GetEntity(), m_flDamage, null, m_flDamage + 40.0, DMG_GENERIC, q2::MOD_BARREL );

		q2::ThrowGib( self, 2, MODEL_GIB1, (1.5 * m_flDamage / 200.0), -1, BREAK_METAL );
		q2::ThrowGib( self, 4, MODEL_GIB3, (1.5 * m_flDamage / 200.0), -1, BREAK_METAL );
		q2::ThrowGib( self, 8, MODEL_GIB2, (1.5 * m_flDamage / 200.0), -1, BREAK_METAL );

		if( pev.FlagBitSet(FL_ONGROUND) )
			BecomeExplosion2();
		else
			BecomeExplosion1();
	}

	void M_droptofloor()
	{
		g_EngineFuncs.DropToFloor( self.edict() );
/*
	Vector end;
	TraceResult trace;

	pev.origin.z += 1.0;
	end = pev.origin;
	end.z -= 256;
	
	//trace = gi.trace (ent->s.origin, ent->mins, ent->maxs, end, ent, MASK_MONSTERSOLID);
	g_Utility.TraceMonsterHull( self.edict(), pev.origin, end, dont_ignore_monsters, self.edict(), trace ); 

	if( trace.flFraction == 1 or trace.fAllSolid != 0 )
		return;

	pev.origin = trace.vecEndPos;
	g_EntityFuncs.SetOrigin( self, pev.origin );

	//M_CheckGround (ent);
	//M_CatagorizePosition (ent);
*/
	}

	bool WalkMove( float flYaw, float flDist )
	{
		return g_EngineFuncs.WalkMove( self.edict(), flYaw, flDist, WALKMOVE_NORMAL ) != 0;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2misc_explobox::misc_explobox", "misc_explobox" );
	g_Game.PrecacheOther( "misc_explobox" );
}

} //end of namespace q2misc_explobox
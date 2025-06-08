namespace q2spawngro
{

const float SPAWNGROW_LIFESPAN = 1.0; //1000_ms;

class spawngro : ScriptBaseEntity
{
	private float m_flWait;
	private float m_flTimestamp;
	private float m_flTeleportTime;
	float m_flDecel;
	float m_flAccel;

	void Spawn()
	{
		Precache();

		pev.angles.x = Math.RandomFloat( 0.0, 360.0 );
		pev.angles.y = Math.RandomFloat( 0.0, 360.0 );
		pev.angles.z = Math.RandomFloat( 0.0, 360.0 );

		pev.avelocity.x = Math.RandomFloat( 280.0, 360.0 ) * 2.0;
		pev.avelocity.y = Math.RandomFloat( 280.0, 360.0 ) * 2.0;
		pev.avelocity.z = Math.RandomFloat( 280.0, 360.0 ) * 2.0;

		pev.movetype	= MOVETYPE_NONE;
		pev.solid			= SOLID_NOT;
		//pev.renderfx	|= RF_IR_VISIBLE;
		pev.rendermode	= kRenderTransColor;
		pev.skin			= 1;

		m_flTeleportTime = g_Engine.time;
		m_flWait = SPAWNGROW_LIFESPAN; //.seconds()
		m_flTimestamp = g_Engine.time + SPAWNGROW_LIFESPAN;

		//TEMP
		//m_flAccel = 36;
		//m_flDecel = 72;

		SetThink( ThinkFunction(this.spawngrow_think) );
		pev.nextthink = g_Engine.time + 0.025; //FRAME_TIME_MS

		g_EntityFuncs.SetModel( self, "models/quake2/items/spawngro3.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/items/spawngro3.mdl" );
	}

	void spawngrow_think()
	{
		if( g_Engine.time >= m_flTimestamp )
		{
			//g_EntityFuncs.Remove( self->target_ent );
			g_EntityFuncs.Remove( self );
			return;
		}

		pev.angles = pev.angles + pev.avelocity * 0.1; //gi.frame_time_s

		float t = 1.0 - ( (g_Engine.time - m_flTeleportTime) / m_flWait ); //(level.time - self->teleport_time).seconds()
		//g_Game.AlertMessage( at_notice, "spawngrow_think t: %1\n", t );

		pev.scale = Math.clamp( 0.001, 16.0, lerp(m_flDecel, m_flAccel, t) / 16.0 );
		pev.renderamt = (t * t) * 255; //self->s.alpha = t * t;

		//g_Game.AlertMessage( at_notice, "spawngrow_think pev.scale: %1\n", pev.scale );
		//g_Game.AlertMessage( at_notice, "spawngrow_think pev.renderamt: %1\n", pev.renderamt );

		//pev.nextthink += 0.025; //FRAME_TIME_MS
		pev.nextthink = g_Engine.time + 0.001; //FRAME_TIME_MS
	}
/*
	Vector SpawnGro_laser_pos( CBaseEntity@ ent )
	{
		// pick random direction
		float theta = Math.RandomFloat( 0.0, 2 * Math.PI ); //frandom(2 * PIf);
		float phi = acos( q2::crandom() );

		Vector d(
			sin(phi) * cos(theta),
			sin(phi) * sin(theta),
			cos(phi)
		);

		return ent.pev.origin + ( d * ent.pev.owner.vars.scale * 9.0 );
	}
*/
	float lerp( float from, float to, float t )
	{
		return (to * t) + (from * (1.0 - t));
	}
}

void SpawnGrow_Spawn( const Vector &in startpos, float start_size, float end_size )
{
	CBaseEntity@ cbeEntity = g_EntityFuncs.Create( "spawngro", startpos, g_vecZero, false, null ); 
	spawngro@ pEntity = cast<spawngro@>(CastToScriptClass(cbeEntity));

	pEntity.m_flAccel = start_size;
	pEntity.m_flDecel = end_size;

	pEntity.pev.scale = Math.clamp( start_size / 16.0, 0.001, 8.0 );

	g_EntityFuncs.DispatchSpawn( pEntity.self.edict() );
/*
	// [Paril-KEX]
	edict_t *beam = ent->target_ent = G_Spawn();
	beam->s.modelindex = MODELINDEX_WORLD;
	beam->s.renderfx = RF_BEAM_LIGHTNING | RF_NO_ORIGIN_LERP;
	beam->s.frame = 1;
	beam->s.skinnum = 0x30303030;
	beam->classname = "spawngro_beam";
	beam->angle = end_size;
	beam->owner = ent;
	beam->s.origin = ent->s.origin;
	beam->think = SpawnGro_laser_think;
	beam->nextthink = level.time + 1_ms;
	beam->s.old_origin = SpawnGro_laser_pos(beam);
	gi.linkentity(beam);*/
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2spawngro::spawngro", "spawngro" );
	g_Game.PrecacheOther( "spawngro" );
}

} //end of namespace q2spawngro


/*
THINK(SpawnGro_laser_think) (edict_t *self) -> void
{
	self->s.old_origin = SpawnGro_laser_pos(self);
	gi.linkentity(self);
	self->nextthink = level.time + 1_ms;
}
*/
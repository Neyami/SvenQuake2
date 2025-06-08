namespace q2bossexploder
{

class bossexploder : ScriptBaseEntity
{
	EHandle m_hOwner;
	Vector m_vecSize;
	Vector m_vecMins;
	protected int m_iViewHeight = 0; //I know the name makes no sense, I'm just keeping it similar to the original :eheh:

	void Spawn()
	{
		Precache();

		pev.movetype		= MOVETYPE_NONE;
		pev.solid				= SOLID_NOT;

		SetThink( ThinkFunction(this.BossExplode_think) );
		pev.nextthink = g_Engine.time + Math.RandomFloat( 0.075, 0.25 );

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void Precache()
	{
		for( uint i = 0; i < q2projectiles::pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( q2projectiles::pExplosionSprites[i] );		

		g_SoundSystem.PrecacheSound( "quake2/weapons/rocklx1a.wav" );
	}

	void BossExplode_think()
	{
		// owner gone or changed
		//if (!self->owner->inuse || self->owner->s.modelindex != self->style || self->count != self->owner->spawn_count)
		if( !m_hOwner.IsValid() )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		//g_Game.AlertMessage( at_notice, "EXPLODING!\n" );
		Vector vecOrigin = pev.origin + m_vecMins;
		
		vecOrigin.x += Math.RandomFloat(0.0, 1.0) * m_vecSize.x;
		vecOrigin.y += Math.RandomFloat(0.0, 1.0) * m_vecSize.y;
		vecOrigin.z += Math.RandomFloat(0.0, 1.0) * m_vecSize.z;

		bool bNoLight = (m_iViewHeight % 3) == 1;
		Explosion( vecOrigin, 15,  bNoLight );
		/*gi.WriteByte(svc_temp_entity);
		gi.WriteByte( !(self->viewheight % 3) ? TE_EXPLOSION1 : TE_EXPLOSION1_NL );
		gi.WritePosition(vecOrigin);
		gi.multicast(vecOrigin, MULTICAST_PVS, false);*/

		m_iViewHeight++;

		pev.nextthink = g_Engine.time + Math.RandomFloat( 0.05, 0.2 );
	}
/*
TE_EXPLOSION1:
		MSG_ReadPos (&net_message, pos);

		ex = CL_AllocExplosion ();
		VectorCopy (pos, ex->ent.origin);
		ex->type = ex_poly;
		ex->ent.flags = RF_FULLBRIGHT;
		ex->start = cl.frame.servertime - 100;
		ex->light = 350;
		ex->lightcolor[0] = 1.0;
		ex->lightcolor[1] = 0.5;
		ex->lightcolor[2] = 0.5;
		ex->ent.angles[1] = rand() % 360;
		if (type != TE_EXPLOSION1_BIG)				// PMM
			ex->ent.model = cl_mod_explo4;			// PMM
		else
			ex->ent.model = cl_mod_explo4_big;
		if (frand() < 0.5)
			ex->baseframe = 15;
		ex->frames = 15;
		if ((type != TE_EXPLOSION1_BIG) && (type != TE_EXPLOSION1_NP))		// PMM
			CL_ExplosionParticles (pos);									// PMM
		if (type == TE_ROCKET_EXPLOSION_WATER)
			S_StartSound (pos, 0, 0, cl_sfx_watrexp, 1, ATTN_NORM, 0);
		else
			S_StartSound (pos, 0, 0, cl_sfx_rockexp, 1, ATTN_NORM, 0);
		break;
*/
 	void Explosion( Vector vecOrigin, int iScale, bool bNoLight )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );
			m1.WriteByte( iScale );//scale
			m1.WriteByte( 30 );//framerate

			int iFlags = TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES;
			if( bNoLight ) iFlags |= TE_EXPLFLAG_NODLIGHTS;

			m1.WriteByte( iFlags );
		m1.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/rocklx1a.wav", VOL_NORM, ATTN_NORM );
	}
}

void BossExploderSpawn( CBaseQ2NPC@ pMonster )
{
	// no blowy on deady
	if( pMonster is null or (pMonster.m_iSpawnFlags & q2::SPAWNFLAG_MONSTER_DEAD) != 0 )
		return;

	CBaseEntity@ cbeExploder = g_EntityFuncs.Create( "bossexploder", pMonster.pev.origin, g_vecZero, true, null );
	q2bossexploder::bossexploder@ pExploder = cast<q2bossexploder::bossexploder@>(CastToScriptClass(cbeExploder));
	pExploder.m_hOwner = EHandle( pMonster.self );
	pExploder.m_vecSize = pMonster.pev.size;
	pExploder.m_vecMins = pMonster.pev.mins;

	/*edict_t *exploder = G_Spawn();
	exploder->owner = self;
	exploder->count = self->spawn_count;
	exploder->style = self->s.modelindex;
	exploder->viewheight = 0;*/

	g_EntityFuncs.DispatchSpawn( pExploder.self.edict() );
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2bossexploder::bossexploder", "bossexploder" );
	g_Game.PrecacheOther( "bossexploder" );
}

} //end of namespace q2bossexploder
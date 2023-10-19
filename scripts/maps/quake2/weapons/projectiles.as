enum q2_ExplosionType
{
	EXPLOSIONTYPE_ROCKET = 0,
	EXPLOSIONTYPE_GRENADE,
	EXPLOSIONTYPE_BFG
};

const array<string> pExplosionSprites = 
{
	"sprites/exp_a.spr",
	"sprites/bexplo.spr",
	"sprites/dexplo.spr",
	"sprites/eexplo.spr"
};

mixin class projectile_q2laserbase
{
	private CSprite@ glow;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/quake2/laser.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(0, 0, 0), Vector(0, 0, 0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		self.pev.nextthink = g_Engine.time + 0.05f;
		self.pev.movetype = MOVETYPE_FLYMISSILE;
		self.pev.solid = SOLID_BBOX;
		self.pev.effects |= EF_DIMLIGHT;
		self.pev.scale = 0.9f;
		self.pev.nextthink = g_Engine.time + 0.1f;
		SetThink( ThinkFunction(Ignite) );
		Glow();
	}

	void Ignite()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav", 0.05f, ATTN_NORM );
		SetThink( ThinkFunction(Fly) );
		self.pev.nextthink = g_Engine.time + 0;
	}

	void Glow() {}

	void Fly() {}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav" );

		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(Remove) );
			self.pev.nextthink = g_Engine.time + 0.1f;
			return;
		}

		if( pOther is g_EntityFuncs.Instance(self.pev.owner) || pOther.pev.ClassNameIs("projectile_q2laser") || pOther.pev.ClassNameIs("projectile_q2hlaser") || pOther.pev.ClassNameIs("projectile_q2grenade1") || pOther.pev.ClassNameIs("projectile_q2rocket") || pOther.pev.ClassNameIs("projectile_q2bfg") )
			return;

		if( pOther !is null )
		{
			if( !pOther.IsBSPModel() )
			{
				if( pOther.pev.takedamage != 0 )
				{
					g_WeaponFuncs.SpawnBlood( self.pev.origin, pOther.BloodColor(), self.pev.dmg );
					pOther.TakeDamage( self.pev, self.pev.owner.vars, self.pev.dmg, DMG_ENERGYBEAM );
				}
			}
			else
			{
				Explode();
				TraceResult tr;
				tr = g_Utility.GetGlobalTrace();
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, "quake2/weapons/laser_hit.wav", 0.8f, ATTN_NORM );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				if( pOther.pev.takedamage != 0 )
					pOther.TakeDamage( self.pev, self.pev.owner.vars, self.pev.dmg, DMG_ENERGYBEAM );
			}
		}

		SetThink( ThinkFunction(Remove) );
		self.pev.nextthink = g_Engine.time + 0.01f;
	}

	void Explode()
	{
		g_Utility.Sparks( self.pev.origin );

		int r = 255, g = 200, b = 50;

		NetworkMessage dl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dl.WriteByte( TE_DLIGHT );
			dl.WriteCoord( self.pev.origin.x );
			dl.WriteCoord( self.pev.origin.y );
			dl.WriteCoord( self.pev.origin.z );
			dl.WriteByte( 8 );//radius
			dl.WriteByte( int(r) );
			dl.WriteByte( int(g) );
			dl.WriteByte( int(b) );
			dl.WriteByte( 4 );//life
			dl.WriteByte( 128 );//decay
		dl.End();
	}
	// The only way to ensure that the sound stops playing...
	void Remove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/laser_fly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( glow );
	}
}

class projectile_q2laser : ScriptBaseEntity, projectile_q2laserbase
{
	void Glow()
	{
		@glow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", self.pev.origin, false ); 
		glow.SetTransparency( 3, 50, 20, 0, 255, 14 );
		glow.SetScale( 0.5 );
		glow.SetAttachment( self.edict(), 0 );
	}

	void Fly()
	{
		int r = 255, g = 200, b = 100;
		
		NetworkMessage glowdl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			glowdl.WriteByte( TE_DLIGHT );
			glowdl.WriteCoord( self.pev.origin.x );
			glowdl.WriteCoord( self.pev.origin.y );
			glowdl.WriteCoord( self.pev.origin.z );
			glowdl.WriteByte( 8 );//radius
			glowdl.WriteByte( int(r) );
			glowdl.WriteByte( int(g) );
			glowdl.WriteByte( int(b) );
			glowdl.WriteByte( 4 );//life
			glowdl.WriteByte( 128 );//decay
		glowdl.End();

		NetworkMessage trail( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			trail.WriteByte( TE_IMPLOSION );
			trail.WriteCoord( self.pev.origin.x );
			trail.WriteCoord( self.pev.origin.y );
			trail.WriteCoord( self.pev.origin.z );
			trail.WriteByte( 1 );//radius
			trail.WriteByte( 4 );//count
			trail.WriteByte( 2 );//life
		trail.End();

		self.pev.nextthink = g_Engine.time + 0;
	}
}

class projectile_q2hlaser : ScriptBaseEntity, projectile_q2laserbase
{
	void Glow()
	{
		@glow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", self.pev.origin, false ); 
		glow.SetTransparency( 3, 50, 20, 0, 255, 14 );
		glow.SetScale( 0.125 );
		glow.SetAttachment( self.edict(), 0 );
	}

	void Fly()
	{
		int r = 255, g = 200, b = 100;
		
		NetworkMessage glowdl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			glowdl.WriteByte( TE_DLIGHT );
			glowdl.WriteCoord( self.pev.origin.x );
			glowdl.WriteCoord( self.pev.origin.y );
			glowdl.WriteCoord( self.pev.origin.z );
			glowdl.WriteByte( 8 );//radius
			glowdl.WriteByte( int(r) );
			glowdl.WriteByte( int(g) );
			glowdl.WriteByte( int(b) );
			glowdl.WriteByte( 4 );//life
			glowdl.WriteByte( 128 );//decay
		glowdl.End();

		self.pev.nextthink = g_Engine.time + 0;
	}
}

class projectile_q2grenade1 : ScriptBaseEntity
{
	float m_fExplodeTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/quake2/w_grenade1.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-0.5f, -0.5f, -0.5f), Vector(0.5f, 0.5f, 0.5f) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		m_fExplodeTime = 2.5f;
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;
		self.pev.nextthink = g_Engine.time + m_fExplodeTime;
		self.pev.avelocity = Vector( 300, 300, 300 );
		SetThink( ThinkFunction(Explode) );
	}

	void Explode()
	{
		q2_Explode( self, self.pev.dmg, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES, EXPLOSIONTYPE_GRENADE, g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER ? "sprites/WXplo1.spr" : pExplosionSprites[Math.RandomLong(0,pExplosionSprites.length() - 1)] );
		g_EntityFuncs.Remove( self );
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is null || pOther.IsBSPModel() || pOther.edict() is self.pev.owner )
		{
			if( self.pev.velocity.Length() > 15.0f )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, Math.RandomLong(1,2) == 1 ? "quake2/weapons/grenade_bounce1.wav" : "quake2/weapons/grenade_bounce2.wav", 1, ATTN_NORM );
			}
			else
			{
				self.pev.angles.x = 0;
				self.pev.avelocity = Vector( 0, 0, 0 );
			}
			self.pev.velocity = self.pev.velocity * 0.5f;
			return;
		}
		Explode();
	}
}

class projectile_q2grenade2 : ScriptBaseEntity
{
	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/quake2/w_grenade2.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(-0.5f, -0.5f, -0.5f), Vector(0.5f, 0.5f, 0.5f) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		self.pev.movetype = MOVETYPE_BOUNCE;
		self.pev.solid = SOLID_BBOX;
		SetTouch( TouchFunction(BounceTouch) );
		SetThink( ThinkFunction(TumbleThink) );
		self.pev.nextthink = g_Engine.time + 0.1f;

		if( self.pev.dmgtime < 0.1f )
		{
			self.pev.nextthink = g_Engine.time;
			self.pev.velocity = Vector( 0, 0, 0 );
		}

		self.pev.avelocity = Vector( 300, 300, 300 );
	}

	void TumbleThink()
	{
		if( !self.IsInWorld() )
		{
			g_EntityFuncs.Remove( self );

			return;
		}

		self.pev.nextthink = g_Engine.time + 0.1f;

		if( self.pev.dmgtime <= g_Engine.time )
		{
			SetThink( ThinkFunction(this.Explode) );
			self.pev.nextthink = g_Engine.time + self.pev.dmgtime;
		}
			
		if( self.pev.waterlevel != WATERLEVEL_DRY )
		{
			self.pev.velocity = pev.velocity * 0.5;
			self.pev.framerate = 0.2;
		}
	}

	void Explode()
	{
		q2_Explode( self, self.pev.dmg, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES, EXPLOSIONTYPE_GRENADE, g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER ? "sprites/WXplo1.spr" : pExplosionSprites[Math.RandomLong(0,pExplosionSprites.length() - 1)] );
		g_EntityFuncs.Remove( self );
	}

	void BounceTouch( CBaseEntity@ pOther )
	{
		if( pOther is null || pOther.IsBSPModel() || pOther.edict() is self.pev.owner )
		{
			if( self.pev.velocity.Length() > 15.0f )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, Math.RandomLong(1,2) == 1 ? "quake2/weapons/grenade_bounce1.wav" : "quake2/weapons/grenade_bounce2.wav", 1, ATTN_NORM );
			}
			else
			{
				self.pev.angles.x = 0;
				self.pev.avelocity = Vector( 0, 0, 0 );
			}

			self.pev.velocity = self.pev.velocity * 0.5f;

			return;
		}

		Explode();
	}
}

class projectile_q2rocket : ScriptBaseEntity
{
	private CSprite@ glow;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/quake2/rockethd.mdl" );
		g_EntityFuncs.SetSize( self.pev, Vector(0, 0, 0), Vector(0, 0, 0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		self.pev.nextthink = g_Engine.time + 0.05f;
		self.pev.movetype = MOVETYPE_FLYMISSILE;
		self.pev.solid = SOLID_BBOX;
		self.pev.effects |= EF_DIMLIGHT;
		SetThink( ThinkFunction(Ignite) );
		Glow();
	}

	void Glow()
	{
		@glow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", self.pev.origin, false ); 
		glow.SetTransparency( 3, 100, 50, 0, 255, 14 );
		glow.SetScale( 0.300f );
		glow.SetAttachment( self.edict(), 1 );
	}
	
	void Ignite()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav", 1, ATTN_NORM );
		SetThink( ThinkFunction(Fly) );
		self.pev.nextthink = g_Engine.time + 0;
	}

	void Fly()
	{
		int r = 100, g = 50, b = 0;
		
		NetworkMessage glowdl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			glowdl.WriteByte( TE_DLIGHT );
			glowdl.WriteCoord( self.pev.origin.x );
			glowdl.WriteCoord( self.pev.origin.y );
			glowdl.WriteCoord( self.pev.origin.z );
			glowdl.WriteByte( 16 );//radius
			glowdl.WriteByte( int(r) );
			glowdl.WriteByte( int(g) );
			glowdl.WriteByte( int(b) );
			glowdl.WriteByte( 4 );//life
			glowdl.WriteByte( 128 );//decay
		glowdl.End();

		self.pev.nextthink = g_Engine.time + 0;
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav" );

		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(Remove) );
			self.pev.nextthink = g_Engine.time + 0.1f;
			return;
		}

		if( pOther is g_EntityFuncs.Instance(self.pev.owner) || pOther.pev.ClassNameIs("projectile_q2laser") || pOther.pev.ClassNameIs("projectile_q2hlaser") || pOther.pev.ClassNameIs("projectile_q2grenade1") || pOther.pev.ClassNameIs("projectile_q2rocket") || pOther.pev.ClassNameIs("projectile_q2bfg") )
			return;

		if( pOther !is null )
		{
			q2_Explode( self, self.pev.dmg, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES, EXPLOSIONTYPE_ROCKET, g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_WATER ? "sprites/WXplo1.spr" : pExplosionSprites[Math.RandomLong(0,pExplosionSprites.length() - 1)] );
		}

		SetThink( ThinkFunction(Remove) );
		self.pev.nextthink = g_Engine.time + 0.01f;
	}

	// The only way to ensure that the sound stops playing...
	void Remove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rocket_fly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( glow );
	}
}

class projectile_q2bfg : ScriptBaseEntity
{
	private CSprite@ bfg;
	private bool m_bDeployDelay;
	private float m_fLaserDamageDelay;
	CBaseEntity@ ents = null;
	float m_fGibTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, "models/quake2/laser.mdl" );
		self.pev.rendermode = 1;
		g_EntityFuncs.SetSize( self.pev, Vector(0, 0, 0), Vector(0, 0, 0) );
		g_EntityFuncs.SetOrigin( self, self.pev.origin );
		self.pev.nextthink = g_Engine.time + 0.05f;
		self.pev.movetype = MOVETYPE_FLYMISSILE;
		self.pev.solid = SOLID_BBOX;
		self.pev.effects |= EF_DIMLIGHT;
		self.pev.effects |= EF_BRIGHTFIELD;
		SetThink( ThinkFunction(Fly) );

		if( self.pev.dmg <= 0 )
			self.pev.dmg = 200;

		@bfg = g_EntityFuncs.CreateSprite( "sprites/quake2/bfg_sprite.spr", self.pev.origin, false ); 
		bfg.SetTransparency( 3, 0, 50, 20, 255, 14 );
		bfg.SetScale( 2 );
		bfg.SetAttachment( self.edict(), 0 );

		m_bDeployDelay = true;
	}
	
	void Ignite()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg_fly.wav", 1, ATTN_NORM );
		SetThink( ThinkFunction(Fly) );
		self.pev.nextthink = g_Engine.time + 0;
		m_fLaserDamageDelay = g_Engine.time + Q2_PROJECTILE_LASER_TICK;
	}

	void Fly()
	{
		if( m_bDeployDelay )
		{
			m_bDeployDelay = false;
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg_fly.wav", 1, ATTN_NORM );
			
		}

		if( g_Engine.time > m_fLaserDamageDelay )
		{
			m_fLaserDamageDelay = g_Engine.time + Q2_PROJECTILE_LASER_TICK;

			while( ( @ents = g_EntityFuncs.FindEntityInSphere( ents, self.GetOrigin(), Q2_PROJECTILE_LASER_RANGE, "*", "classname" ) ) !is null )
			{
				if( g_EntityFuncs.IsValidEntity(ents.edict()) /*&& ents.IsMonster()*/ && ents !is g_EntityFuncs.Instance(self.pev.owner) ) 
				{
					if( ents.IsPlayer() || ents.pev.takedamage == DAMAGE_NO ) continue;

					int lr = 50, lg = 255, lb = 50;//80?

					NetworkMessage bfgl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
						bfgl.WriteByte( TE_BEAMENTPOINT );
						bfgl.WriteShort( g_EngineFuncs.IndexOfEdict(self.edict()) );//start entity
						bfgl.WriteCoord( ents.Center().x );//end position X
						bfgl.WriteCoord( ents.Center().y );//end position Y
						bfgl.WriteCoord( ents.Center().z );//end position Z
						bfgl.WriteShort( g_EngineFuncs.ModelIndex("sprites/quake2/bfg_beam.spr") );//sprite index
						bfgl.WriteByte( 0 );//starting frame
						bfgl.WriteByte( 1 );//framerate
						bfgl.WriteByte( 1 );//life
						bfgl.WriteByte( 32 );//line width
						bfgl.WriteByte( 0 );//noise amplitude
						bfgl.WriteByte( int(lr) );
						bfgl.WriteByte( int(lg) );
						bfgl.WriteByte( int(lb) );
						bfgl.WriteByte( 80 );//brightness
						bfgl.WriteByte( 1 );//scroll speed
					bfgl.End();

					ents.TakeDamage( self.pev, self.pev.owner.vars, Q2_BFG_DAMAGE_LASER, DMG_ENERGYBEAM | DMG_ALWAYSGIB );
/*
					CBaseEntity@ owner = g_EntityFuncs.Instance( self.pev.owner.vars );  
					Vector vecAngles = (ents.GetOrigin() - self.GetOrigin()).Normalize();

					if( self.pev.fuser1 > 0 && g_Engine.time > self.pev.fuser1 )
					{
						self.pev.fuser1 = 0;
						//auto @pBFG = q2_ShootCustomProjectile( "projectile_q2bfg", "sprites/quake2/bfg_sprite.spr", self.GetOrigin(), vecAngles*Q2_BFG_PROJECTILE_SPEED, vecAngles, owner );
						auto @pBFG = q2_ShootCustomProjectile( "projectile_q2rocket", "models/quake2/rockethd.mdl", self.GetOrigin(), vecAngles*Q2_BFG_PROJECTILE_SPEED, vecAngles, owner );
						pBFG.pev.dmg = 200;
					}
					self.pev.fuser1 = g_Engine.time + 0.2f;
*/
				}
			}
		}

		int r = 155, g = 255, b = 150;
		
		NetworkMessage bfgdl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			bfgdl.WriteByte( TE_DLIGHT );
			bfgdl.WriteCoord( self.pev.origin.x );
			bfgdl.WriteCoord( self.pev.origin.y );
			bfgdl.WriteCoord( self.pev.origin.z );
			bfgdl.WriteByte( 16 );//radius
			bfgdl.WriteByte( int(r) );
			bfgdl.WriteByte( int(g) );
			bfgdl.WriteByte( int(b) );
			bfgdl.WriteByte( 4 );//life
			bfgdl.WriteByte( 255 );//decay
		bfgdl.End();

		self.pev.nextthink = g_Engine.time + 0;
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg_fly.wav" );

		if( g_EngineFuncs.PointContents( self.pev.origin ) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(Remove) );
			self.pev.nextthink = g_Engine.time + 0.1f;
			return;
		}

		if( pOther is g_EntityFuncs.Instance(self.pev.owner) || pOther.pev.ClassNameIs("projectile_q2laser") || pOther.pev.ClassNameIs("projectile_q2hlaser") || pOther.pev.ClassNameIs("projectile_q2grenade1") || pOther.pev.ClassNameIs("projectile_q2rocket") || pOther.pev.ClassNameIs("projectile_q2bfg") )
			return;

		if( pOther !is null )
			q2_Explode( self, self.pev.dmg, TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES, EXPLOSIONTYPE_BFG, "sprites/quake2/bfg_explosion.spr" );

		SetThink( ThinkFunction(Remove) );
		self.pev.nextthink = g_Engine.time + 0.01f;
	}

	// The only way to ensure that the sound stops playing...
	void Remove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg_fly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( bfg );
	}
}

void q2_RadiusDamage( Vector vecCenter, CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, float flDamage, float flRadius, int bitsDamage )
{
	g_WeaponFuncs.RadiusDamage( vecCenter, pInflictor.pev, pAttacker.pev, flDamage, flRadius, CLASS_NONE, bitsDamage ); //doesn't properly do aoe dmg (try spawning several mobs on the same spot)
	//This doesn't deal damage to brushes though
	/*CBaseEntity@ pEnt = null;

	while( (@pEnt = g_EntityFuncs.FindEntityInSphere(pEnt, vecCenter, flRadius, "*", "classname")) !is null )
	{
		if( pEnt.pev.takedamage != 0 && pEnt !is pInflictor )
		{
			Vector vecOrg = pEnt.pev.origin + (pEnt.pev.mins + pEnt.pev.maxs) * 0.5f;
			TraceResult tr;
			g_Utility.TraceLine( vecCenter, vecOrg, ignore_monsters, dont_ignore_glass, pInflictor.edict(), tr );
			if( tr.flFraction <= 0.999f ) continue;
			float flPoints = (vecOrg - vecCenter).Length() * 0.5f;
			if( flPoints < 0 ) flPoints = 0;
			flPoints = flDamage - flPoints;
			if( pEnt is pAttacker ) flPoints *= 0.5f;
			if( flPoints > 0 )
				pEnt.TakeDamage( pInflictor.pev, pAttacker.pev, flPoints, bitsDamage );
		}
	}*/
}

void q2_Explode( CBaseEntity@ proj, float dmg, int flags, int explosionType, string sprite = "sprites/exp_a.spr" )
{
	NetworkMessage exp1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
		exp1.WriteByte( TE_EXPLOSION );
		exp1.WriteCoord( proj.pev.origin.x );
		exp1.WriteCoord( proj.pev.origin.y );
		exp1.WriteCoord( proj.pev.origin.z );
		exp1.WriteShort( g_EngineFuncs.ModelIndex(sprite) );
		exp1.WriteByte( explosionType != EXPLOSIONTYPE_BFG ? 30 : 10 );//scale
		exp1.WriteByte( explosionType != EXPLOSIONTYPE_BFG ? 30 : 10 );//framerate
		exp1.WriteByte( flags );
	exp1.End();

	TraceResult tr;
	Vector vecSpot, vecEnd;

	switch( explosionType )
	{
		case EXPLOSIONTYPE_GRENADE:
			g_SoundSystem.EmitSound( proj.edict(), CHAN_AUTO, "quake2/weapons/grenade_explode.wav", 1, ATTN_NORM );
			g_Utility.TraceLine( proj.pev.origin, proj.pev.origin + Vector( 0, 0, -32 ),  ignore_monsters, proj.edict(), tr );
			g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
			q2_RadiusDamage( proj.pev.origin, proj, g_EntityFuncs.Instance(proj.pev.owner), dmg, 140.0f, DMG_BLAST );
		break;
		case EXPLOSIONTYPE_ROCKET:
			g_SoundSystem.EmitSound( proj.edict(), CHAN_AUTO, "quake2/weapons/rocket_explode.wav", 1, ATTN_NORM );
			vecSpot = proj.pev.origin - proj.pev.velocity.Normalize() * 32;
			vecEnd = proj.pev.origin + proj.pev.velocity.Normalize() * 64;
			g_Utility.TraceLine( vecSpot, vecEnd, ignore_monsters, proj.edict(), tr );
			g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );
			q2_RadiusDamage( proj.pev.origin, proj, g_EntityFuncs.Instance(proj.pev.owner), dmg, 100.0f, DMG_BLAST );
		break;
		case EXPLOSIONTYPE_BFG:
			g_SoundSystem.EmitSound( proj.edict(), CHAN_AUTO, "quake2/weapons/bfg_explode.wav", 1, ATTN_NORM );
			q2_RadiusDamage( proj.pev.origin, proj, g_EntityFuncs.Instance(proj.pev.owner), dmg, Q2_BFG_DAMAGE_RADIUS, DMG_BLAST | DMG_ALWAYSGIB );
		break;
	}
}

CBaseEntity@ q2_ShootCustomProjectile( string classname, string mdl, Vector origin, Vector velocity, Vector angles, CBaseEntity@ owner, float time = 0 )
{
	if( classname.Length() == 0 )
		return null;
	
	dictionary keys;
	Vector projAngles = angles * Vector( -1, 1, 1 );
	keys[ "origin" ] = origin.ToString();
	keys[ "angles" ] = projAngles.ToString();
	keys[ "velocity" ] = velocity.ToString();
	
	string model = mdl.Length() > 0 ? mdl : "models/error.mdl";
	keys[ "model" ] = model;

	if( mdl.Length() == 0 )
		keys[ "rendermode" ] = "1"; // don't render the model
	
	CBaseEntity@ shootEnt = g_EntityFuncs.CreateEntity( classname, keys, false );
	@shootEnt.pev.owner = owner.edict();

	if( time > 0 ) shootEnt.pev.dmgtime = time;

	g_EntityFuncs.DispatchSpawn( shootEnt.edict() );

	return shootEnt;
}

void q2_RegisterProjectiles()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2laser", "projectile_q2laser" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2hlaser", "projectile_q2hlaser" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2grenade1", "projectile_q2grenade1" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2grenade2", "projectile_q2grenade2" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2rocket", "projectile_q2rocket" );
	g_CustomEntityFuncs.RegisterCustomEntity( "projectile_q2bfg", "projectile_q2bfg" );
}
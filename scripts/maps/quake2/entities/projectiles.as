namespace q2projectiles
{

const string MODEL_GRENADE			= "models/quake2/objects/grenade4.mdl"; //glauncher
const string MODEL_GRENADE_NPC		= "models/quake2/objects/grenade.mdl";
const string MODEL_GRENADE2			= "models/quake2/objects/grenade3.mdl"; //handgrenade

const string BFG_SPRITE					= "sprites/quake2/s_bfg1.spr";
const string BFG_EXPLOSION1			= "sprites/quake2/s_bfg3.spr"; //when exploding on touch
const string BFG_EXPLOSION2			= "sprites/quake2/s_bfg2.spr"; //when hitting enemies with the larger aoe
const string BFG_BEAM						= "sprites/quake2/bfg_beam.spr";
const float BFG_DAMAGE1					= 200.0; //when exploding on touch, deals direct damage to target hit, and radius damage
const float BFG_RADIUS1					= 100.0; //when exploding on touch

const array<string> pExplosionSprites = 
{
	"sprites/exp_a.spr",
	"sprites/bexplo.spr",
	"sprites/dexplo.spr",
	"sprites/eexplo.spr"
};

class q2laser : ScriptBaseEntity
{
	protected EHandle m_hGlow;
	protected CSprite@ m_pGlow
	{
		get const { return cast<CSprite@>(m_hGlow.GetEntity()); }
		set { m_hGlow = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/objects/laser.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.solid = SOLID_BBOX;
		pev.effects |= EF_DIMLIGHT;
		pev.scale = 0.9;

		Ignite();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/objects/laser.mdl" );
		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/misc/lasfly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/lashit.wav" );
	}

	void Ignite()
	{
		@m_pGlow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", pev.origin, false ); 
		m_pGlow.SetTransparency( 3, 50, 20, 0, 255, 14 );
		m_pGlow.SetScale( (pev.weapons == q2::MOD_HYPERBLASTER) ? 0.125 : 0.5 );
		m_pGlow.SetAttachment( self.edict(), 0 );

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, "quake2/misc/lasfly.wav", 0.05, ATTN_NORM, SND_FORCE_LOOP );
		SetThink( ThinkFunction(this.FlyThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void FlyThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity );

		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteByte( 16 );//radius
			m1.WriteByte( 255 );
			m1.WriteByte( 200 );
			m1.WriteByte( 100 );
			m1.WriteByte( 4 );//life
			m1.WriteByte( 128 );//decay
		m1.End();

		if( pev.weapons != q2::MOD_HYPERBLASTER )
		{
			NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
				m2.WriteByte( TE_IMPLOSION );
				m2.WriteCoord( pev.origin.x );
				m2.WriteCoord( pev.origin.y );
				m2.WriteCoord( pev.origin.z );
				m2.WriteByte( 1 );//radius
				m2.WriteByte( 4 );//count
				m2.WriteByte( 2 );//life
			m2.End();
		}

		pev.nextthink = g_Engine.time;
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/misc/lasfly.wav" );

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time + 0.1;
			return;
		}

		if( pOther is g_EntityFuncs.Instance(pev.owner) )
			return;

		if( pOther !is null )
		{
			if( !pOther.IsBSPModel() )
			{
				if( pOther.pev.takedamage != 0 )
				{
					g_WeaponFuncs.SpawnBlood( pev.origin, pOther.BloodColor(), pev.dmg );
					pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_ENERGYBEAM );

					if( pev.weapons != q2::MOD_UNKNOWN )
					{
						CustomKeyvalues@ pCustom = pOther.GetCustomKeyvalues();
						pCustom.SetKeyvalue( q2::KVN_MOD, pev.weapons );
					}
				}
			}
			else
			{
				Explode();
				TraceResult tr;
				tr = g_Utility.GetGlobalTrace();
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/lashit.wav", 0.8, ATTN_NORM );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				if( pOther.pev.takedamage != 0 )
					pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_ENERGYBEAM );
			}
		}

		RemoveThink();
	}

	void Explode()
	{
		g_Utility.Sparks( pev.origin );

		NetworkMessage dl( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			dl.WriteByte( TE_DLIGHT );
			dl.WriteCoord( pev.origin.x );
			dl.WriteCoord( pev.origin.y );
			dl.WriteCoord( pev.origin.z );
			dl.WriteByte( 16 );//radius
			dl.WriteByte( 255 );
			dl.WriteByte( 200 );
			dl.WriteByte( 50 );
			dl.WriteByte( 4 );//life
			dl.WriteByte( 128 );//decay
		dl.End();
	}

	// The only way to ensure that the sound stops playing...
	void RemoveThink()
	{
		SetThink( null );
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/misc/lasfly.wav" );
		g_EntityFuncs.Remove( self );
		g_EntityFuncs.Remove( m_pGlow );
	}

	void UpdateOnRemove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/misc/lasfly.wav" );
		BaseClass.UpdateOnRemove();
	}
}

class q2grenade : ScriptBaseEntity
{
	protected EHandle m_hEnemy;
	protected CBaseEntity@ m_pEnemy
	{
		get const { return m_hEnemy.GetEntity(); }
		set { m_hEnemy = EHandle(@value); }
	}

	private float m_flTimeToBlow, m_fTimerSound;
	float m_flDamageRadius;

	void Spawn()
	{
		Precache();

		//hand grenade
		if( pev.weapons == 1 )
			g_EntityFuncs.SetModel( self, MODEL_GRENADE2 );
		else if( pev.weapons == 2 )
			g_EntityFuncs.SetModel( self, MODEL_GRENADE_NPC );
		else
			g_EntityFuncs.SetModel( self, MODEL_GRENADE );

		g_EntityFuncs.SetSize( self.pev, Vector(-0.5, -0.5, -0.5), Vector(0.5, 0.5, 0.5) );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.movetype = MOVETYPE_BOUNCE;
		pev.solid = SOLID_BBOX;
		pev.avelocity = Vector( 300, 300, 300 );

		//hand grenade
		if( pev.weapons == 1 )
		{
			SetThink( ThinkFunction(TimerThink) );
			pev.nextthink = g_Engine.time;
			m_flTimeToBlow = g_Engine.time + pev.dmgtime;
		}
		else
		{
			SetThink( ThinkFunction(Explode) );
			pev.nextthink = g_Engine.time + pev.dmgtime;
		}
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_GRENADE );
		g_Game.PrecacheModel( MODEL_GRENADE_NPC );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenlx1a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenlb1b.wav" );

		g_Game.PrecacheModel( MODEL_GRENADE2 );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hgrenb1a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hgrenb2a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hgrenc1b.wav" );

		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

		for( uint i = 0; i < pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( pExplosionSprites[i] );
	}

	void TimerThink()
	{
		if( g_Engine.time > m_flTimeToBlow )
		{
			Explode();
			return;
		}

		if( g_Engine.time > m_fTimerSound )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/hgrenc1b.wav", VOL_NORM, ATTN_NORM );
			m_fTimerSound = g_Engine.time + 1.0;
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther.edict() is pev.owner )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( pOther.pev.takedamage == DAMAGE_NO )
		{
			if( pev.velocity.Length() > 15.0 )
			{
					if( pev.weapons == 1 )
					{
						if( Math.RandomFloat(0.0, 1.0) > 0.5 )
							g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/hgrenb1a.wav", VOL_NORM, ATTN_NORM );
						else
							g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/hgrenb2a.wav", VOL_NORM, ATTN_NORM );
					}
					else
						g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/grenlb1b.wav", VOL_NORM, ATTN_NORM );
			}
			else
			{
				pev.angles.x = 0;
				pev.avelocity = g_vecZero;
			}

			pev.velocity = pev.velocity * 0.5;

			return;
		}

		@m_pEnemy = pOther;
		Explode();
	}

	void Explode()
	{
		Vector vecOrigin;
		int mod;

		//if (ent->owner->client)
			//PlayerNoise(ent->owner, ent->s.origin, PNOISE_IMPACT);
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, NORMAL_EXPLOSION_VOLUME, 3.0, g_EntityFuncs.Instance(pev.owner) );

		//FIXME: if we are onground then raise our Z just a bit since we are a point? ??
		if( m_pEnemy !is null )
		{
			float flPoints;
			Vector vecWhat;
			Vector vecDir;

			vecWhat = m_pEnemy.pev.mins + m_pEnemy.pev.maxs; //VectorAdd (ent->enemy->mins, ent->enemy->maxs, vecWhat);
			vecWhat = m_pEnemy.pev.origin + vecWhat * 0.5; //VectorMA (ent->enemy->s.origin, 0.5, vecWhat, vecWhat);
			vecWhat = pev.origin - vecWhat; //VectorSubtract (ent->s.origin, vecWhat, vecWhat);
			flPoints = pev.dmg - 0.5 * vecWhat.Length(); //flPoints = ent->dmg - 0.5 * VectorLength (vecWhat);
			vecDir = m_pEnemy.pev.origin - pev.origin; //VectorSubtract (ent->enemy->s.origin, ent->s.origin, vecDir);

			mod = (pev.weapons == 1) ? q2::MOD_HANDGRENADE : q2::MOD_GRENADE;

			q2::T_Damage( m_hEnemy.GetEntity(), self, g_EntityFuncs.Instance(pev.owner), vecDir, pev.origin, g_vecZero, flPoints, flPoints, 0, mod ); //DAMAGE_RADIUS
		}

		if( pev.weapons == 1 and pev.dmgtime == 0 )
			mod = q2::MOD_HELD_GRENADE;
		else if( pev.weapons == 1 )
			mod = q2::MOD_HG_SPLASH;
		else
			mod = q2::MOD_G_SPLASH;

		q2::T_RadiusDamage( self, g_EntityFuncs.Instance(pev.owner), pev.dmg, m_hEnemy.GetEntity(), m_flDamageRadius, DMG_BLAST | DMG_LAUNCH, mod ); //DMG_BLAST needed ??

		vecOrigin = pev.origin + pev.velocity * -0.02; //VectorMA (ent->s.origin, -0.02, ent->velocity, vecOrigin);

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );

			if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
				m1.WriteShort( g_Game.PrecacheModel("sprites/WXplo1.spr") );
			else
				m1.WriteShort( g_Game.PrecacheModel(pExplosionSprites[Math.RandomLong(0, pExplosionSprites.length() - 1)]) );

			m1.WriteByte( 30 );//scale
			m1.WriteByte( 30 );//framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		/*TraceResult tr;
		Vector vecSpot, vecEnd;

		g_Utility.TraceLine( pev.origin, pev.origin + Vector( 0, 0, -32 ),  ignore_monsters, self.edict(), tr );
		g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0,1) );*/

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/grenlx1a.wav", VOL_NORM, ATTN_NORM );
		g_EntityFuncs.Remove( self );
	}
}

class q2rocket : ScriptBaseEntity
{
	protected EHandle m_hEnemy;
	protected Vector m_vecMoveDir;

	protected EHandle m_hGlow;
	protected CSprite@ m_pGlow
	{
		get const { return cast<CSprite@>(m_hGlow.GetEntity()); }
		set { m_hGlow = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/objects/rocket.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/rockfly.wav", 1, ATTN_NORM );

		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.solid = SOLID_BBOX;
		pev.effects |= EF_DIMLIGHT;

		if( pev.scale == 0 )
			pev.scale = 1.0;

		m_vecMoveDir = pev.velocity / pev.speed;
		Glow();

		if( pev.weapons == 1 )
		{
			SetThink( ThinkFunction(this.HeatseekThink) );
			pev.nextthink = g_Engine.time + 0.025; //FRAME_TIME_MS

			return;
		}

		SetThink( ThinkFunction(this.RocketThink) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void Precache()
	{
		g_Game.PrecacheModel( "models/quake2/objects/rocket.mdl" );
		g_Game.PrecacheModel( "sprites/WXplo1.spr" );
		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		for( uint i = 0; i < pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		g_SoundSystem.PrecacheSound( "quake2/weapons/rockfly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rocklx1a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/railgr1a.wav" );
	}

	void RocketThink()
	{
		pev.angles = Math.VecToAngles( pev.velocity );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void HeatseekThink()
	{
		CBaseEntity@ pTarget = null;
		CBaseEntity@ pAcquire = null;
		CBaseEntity@ pOwner = g_EntityFuncs.Instance( pev.owner );

		if( pOwner is null ) return;

		Vector vecDir;
		Vector vecOldang;
		Vector vecForward;

		float flLen;
		float flOldlen = 0.0;
		float flDot, flOlddot = 1.0;

		g_EngineFuncs.AngleVectors( pev.angles, vecForward, void, void );

		// acquire new target
		while( (@pTarget = g_EntityFuncs.FindEntityInSphere(pTarget, pev.origin, 1024.0, "*", "classname")) !is null ) 
		{
			if( pev.owner is pTarget.edict() )
				continue;

			if( pTarget.pev.takedamage == DAMAGE_NO )
				continue;

			//don't follow fellow oniichans
			if( pOwner.IRelationship(pTarget) <= R_NO )
				continue;

			if( pTarget.pev.health <= 0 )
				continue;

			if( !self.FVisible(pTarget, false) )
				continue;

			vecDir = pev.origin - pTarget.pev.origin;
			flLen = vecDir.Length();

			flDot = DotProduct(vecDir.Normalize(), vecForward ); //vecDir.normalized().dot(vecForward);

			// targets that require us to turn less are preferred
			if( flDot >= flOlddot )
				continue;

			if( pAcquire is null or flDot < flOlddot or flLen < flOldlen )
			{
				@pAcquire = pTarget;
				flOldlen = flLen;
				flOlddot = flDot;
			}
		}

		if( pAcquire !is null )
		{
			vecOldang = pev.angles;
			vecDir = (pAcquire.pev.origin - pev.origin).Normalize();
			float flTurnRatio = 0.075;

			if( pev.frags > 0.0 )
				flTurnRatio = pev.frags;

			m_vecMoveDir = pev.velocity / pev.speed;
			float d = DotProduct( m_vecMoveDir, vecDir ); //self.movedir.dot(vecDir);

			if( d < 0.45 and d > -0.45 )
				vecDir = -vecDir;

			m_vecMoveDir = q2::slerp( m_vecMoveDir, vecDir, flTurnRatio ).Normalize();
			pev.angles = Math.VecToAngles( m_vecMoveDir );

			if( !m_hEnemy.IsValid() )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, "quake2/weapons/railgr1a.wav", VOL_NORM, 0.25 );
				m_hEnemy = EHandle( pAcquire );
			}
		}
		else
			m_hEnemy = null;

		pev.velocity = m_vecMoveDir * pev.speed;
		pev.nextthink = g_Engine.time + 0.025; //FRAME_TIME_MS
	}

	void Glow()
	{
		@m_pGlow = g_EntityFuncs.CreateSprite( "sprites/blueflare1.spr", pev.origin, false ); 
		m_pGlow.SetTransparency( 3, 100, 50, 0, 255, 14 );
		m_pGlow.SetScale( 0.3 * pev.scale );
		m_pGlow.SetAttachment( self.edict(), 1 );
	}

	void Touch( CBaseEntity@ pOther )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rockfly.wav" );

		Vector vecOrigin;
		TraceResult tr = g_Utility.GetGlobalTrace();

		if( pOther.edict() is pev.owner )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			RemoveThink();
			return;
		}

		//if( ent.owner.client )
			//PlayerNoise(ent.owner, ent.s.origin, PNOISE_IMPACT);
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, vecOrigin, NORMAL_EXPLOSION_VOLUME, 3.0, g_EntityFuncs.Instance(pev.owner) );

		//I'm using this to get rocket jumping working properly
		q2::T_RadiusDamage( self, g_EntityFuncs.Instance(pev.owner), 120.0, pOther, 120.0, DMG_BLAST | DMG_LAUNCH, q2::MOD_R_SPLASH );

		vecOrigin = pev.origin + tr.vecPlaneNormal;

		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			q2::T_Damage( pOther, self, g_EntityFuncs.Instance(pev.owner), pev.velocity, pev.origin, tr.vecPlaneNormal, pev.dmg, 0, DMG_GENERIC, q2::MOD_ROCKET );
			//if( !(pOther.pev.FlagBitSet(FL_CLIENT) and !q2::PVP) ) //deals damage to players otherwise
				//pOther.TakeDamage( self.pev, pev.owner.vars, pev.dmg, DMG_GENERIC );
		}
		else
		{
			// don't throw any debris in net games
			/*if (!deathmatch.integer && !coop.integer)
			{
				if (tr.surface && !(tr.surface.flags & (SURF_WARP | SURF_TRANS33 | SURF_TRANS66 | SURF_FLOWING)))
				{
					ThrowGibs(ent, 2, {
						{ (size_t) irandom(5), "models/objects/debris2/tris.md2", GIB_METALLIC | GIB_DEBRIS }
					});
				}
			}*/
		}

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/rocklx1a.wav", VOL_NORM, ATTN_NORM );
		//g_Utility.DecalTrace( tr, DECAL_SCORCH1 + Math.RandomLong(0, 1) );

		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );

			if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
				m1.WriteShort( g_Game.PrecacheModel("sprites/WXplo1.spr") );
			else
				m1.WriteShort( g_Game.PrecacheModel(pExplosionSprites[Math.RandomLong(0, pExplosionSprites.length() - 1)]) );

			m1.WriteByte( int(30 * pev.scale) ); //scale
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		RemoveThink();
	}

	// The only way to ensure that the sound stops playing...
	void RemoveThink()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rockfly.wav" );
		g_EntityFuncs.Remove( self );

		if( m_pGlow !is null )
			g_EntityFuncs.Remove( m_pGlow );
	}

	void UpdateOnRemove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/rockfly.wav" );
		BaseClass.UpdateOnRemove();
	}
}

class q2railbeam : ScriptBaseEntity
{
	Vector m_vecStart, m_vecEnd;
	private int iBrightness;

	protected EHandle m_hRailBeam;
	protected CBeam@ m_pRailBeam
	{
		get const { return cast<CBeam@>(m_hRailBeam.GetEntity()); }
		set { m_hRailBeam = EHandle(@value); }
	}

	protected EHandle m_hRailBeam2;
	protected CBeam@ m_pRailBeam2
	{
		get const { return cast<CBeam@>(m_hRailBeam2.GetEntity()); }
		set { m_hRailBeam2 = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		iBrightness = 255;
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		pev.solid = SOLID_NOT;
		pev.takedamage = DAMAGE_NO;
		pev.movetype = MOVETYPE_NONE;

		CreateBeams();
	}

	void Precache()
	{
		g_Game.PrecacheModel( "sprites/laserbeam.spr" );
	}

	void CreateBeams()
	{
		DestroyBeams();

		@m_pRailBeam = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 50 ); //30
		m_pRailBeam.SetType( BEAM_POINTS );
		m_pRailBeam.SetScrollRate( 50 );
		m_pRailBeam.SetBrightness( 255 );
		m_pRailBeam.SetColor( 255, 255, 255 );
		m_pRailBeam.PointsInit( m_vecStart, m_vecEnd );

		@m_pRailBeam2 = g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 15 ); //5
		m_pRailBeam2.SetType( BEAM_POINTS );
		m_pRailBeam2.SetFlags( BEAM_FSINE );
		m_pRailBeam2.SetScrollRate( 50 );
		m_pRailBeam2.SetNoise( 20 );
		m_pRailBeam2.SetBrightness( 255 );
		m_pRailBeam2.SetColor( 100, 100, 255 );
		m_pRailBeam2.PointsInit( m_vecStart, m_vecEnd );

		SetThink( ThinkFunction(this.FadeBeams) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void DestroyBeams()
	{
		if( m_pRailBeam !is null )
		{
			g_EntityFuncs.Remove( m_pRailBeam );
			@m_pRailBeam = null;
		}

		if( m_pRailBeam2 !is null )
		{
			g_EntityFuncs.Remove( m_pRailBeam2 );
			@m_pRailBeam2 = null;
		}
	}

	void FadeBeams()
	{
		if( m_pRailBeam !is null )
			m_pRailBeam.SetBrightness( iBrightness );

		if( m_pRailBeam2 !is null )
			m_pRailBeam2.SetBrightness( iBrightness );

		if( iBrightness > 7 )
		{
			iBrightness -= 7;
			pev.nextthink = g_Engine.time + 0.01;
		}
		else 
		{
			iBrightness = 0;
			pev.nextthink = g_Engine.time + 0.2;
			SetThink( ThinkFunction(this.SUB_Remove) );
		}
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		NetworkMessage killbeam( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY, null );
			killbeam.WriteByte(TE_KILLBEAM);
			killbeam.WriteShort(self.entindex());
		killbeam.End();

		DestroyBeams();

		g_EntityFuncs.Remove(self);
	}
}

class q2bfg : ScriptBaseEntity
{
	//The sprite won't animate otherwise
	protected EHandle m_hBFG;
	protected CSprite@ m_pBFG
	{
		get const { return cast<CSprite@>(m_hBFG.GetEntity()); }
		set { m_hBFG = EHandle(@value); }
	}

	private float m_flLaserDamageDelay;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, "models/quake2/objects/laser.mdl" );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.solid = SOLID_BBOX;
		pev.movetype = MOVETYPE_FLYMISSILE;
		pev.effects |= EF_DIMLIGHT | EF_BRIGHTFIELD;

		SetThink( ThinkFunction(this.FlyThink) );
		pev.nextthink = g_Engine.time + 0.05;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg__l1a.wav", VOL_NORM, ATTN_NORM );

		@m_pBFG = g_EntityFuncs.CreateSprite( BFG_SPRITE, pev.origin, false ); 
		m_pBFG.SetTransparency( 3, 0, 50, 20, 255, 14 );
		m_pBFG.SetScale( 2 );
		m_pBFG.SetAttachment( self.edict(), 0 );
	}

	void Precache()
	{
		g_Game.PrecacheModel( BFG_SPRITE );
		g_Game.PrecacheModel( BFG_EXPLOSION1 );
		g_Game.PrecacheModel( BFG_EXPLOSION2 );
		g_Game.PrecacheModel( BFG_BEAM );

		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg__l1a.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg__x1b.wav" );
	}

	void FlyThink()
	{
		if( g_Engine.time > m_flLaserDamageDelay )
		{
			CBaseEntity@ pEntity = null;

			while( (@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, pev.origin, 256, "*", "classname")) !is null )
			{
				if( g_EntityFuncs.IsValidEntity(pEntity.edict()) and pEntity !is g_EntityFuncs.Instance(pev.owner) )
				{
					if( pEntity.pev.takedamage == DAMAGE_NO ) continue;

					if( pEntity.pev.FlagBitSet(FL_MONSTER) or pEntity.pev.FlagBitSet(FL_CLIENT) or pEntity.IsBSPModel() )
					{
						NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
							m1.WriteByte( TE_BEAMENTPOINT );
							m1.WriteShort( g_EngineFuncs.IndexOfEdict(self.edict()) ); //start entity
							m1.WriteCoord( pEntity.Center().x ); //end position X Y Z
							m1.WriteCoord( pEntity.Center().y );
							m1.WriteCoord( pEntity.Center().z );
							m1.WriteShort( g_EngineFuncs.ModelIndex(BFG_BEAM) ); //sprite index
							m1.WriteByte( 0 ); //starting frame
							m1.WriteByte( 1 ); //framerate
							m1.WriteByte( 1 ); //life
							m1.WriteByte( 32 ); //line width
							m1.WriteByte( 0 ); //noise amplitude
							m1.WriteByte( 50 ); //r
							m1.WriteByte( 255 ); //g
							m1.WriteByte( 50 ); //b 80 ?
							m1.WriteByte( 80 ); //brightness
							m1.WriteByte( 1 ); //scroll speed
						m1.End();
/*
CL_ParseLaser()
colors = 0xd0d1d2d3
l.ent.skinnum = (colors >> ((rand() % 4)*8)) & 0xff;
*/
						pEntity.TakeDamage( self.pev, pev.owner.vars, 10, DMG_ENERGYBEAM | DMG_ALWAYSGIB );
					}
				}
			}

			m_flLaserDamageDelay = g_Engine.time + 0.1;
		}

		NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
			m2.WriteByte( TE_DLIGHT );
			m2.WriteCoord( pev.origin.x );
			m2.WriteCoord( pev.origin.y );
			m2.WriteCoord( pev.origin.z );
			m2.WriteByte( 16 );//radius
			m2.WriteByte( 155 ); //r
			m2.WriteByte( 255 ); //g
			m2.WriteByte( 150 ); //b
			m2.WriteByte( 4 );//life
			m2.WriteByte( 255 );//decay
		m2.End();

		pev.nextthink = g_Engine.time;
	}

	void Touch( CBaseEntity@ pOther )
	{
		if( pOther is g_EntityFuncs.Instance(pev.owner) )
			return;

		if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_SKY )
		{
			SetThink( ThinkFunction(this.RemoveThink) );
			pev.nextthink = g_Engine.time + 0.1;

			return;
		}

		//if (self->owner->client)
			//PlayerNoise(self->owner, self->s.origin, PNOISE_IMPACT);

		//g_WeaponFuncs.RadiusDamage( pev.origin, self.pev, pevOwner, pev.dmg, 256, CLASS_NONE, DMG_BLAST|DMG_ALWAYSGIB ); //doesn't properly do aoe dmg (try spawning several mobs on the same spot)
		//q2::T_RadiusDamage( self, g_EntityFuncs.Instance(pevOwner), pev.dmg, pOther, 256.0, DMG_BLAST|DMG_ALWAYSGIB/*, MOD_R_SPLASH*/ );
		q2::T_RadiusDamage( self, g_EntityFuncs.Instance(pev.owner), BFG_DAMAGE1, pOther, BFG_RADIUS1, DMG_BLAST|DMG_ALWAYSGIB|DMG_LAUNCH, q2::MOD_BFG_BLAST );

		// core explosion - prevents firing it into the wall/floor
		if( pOther.pev.takedamage != DAMAGE_NO )
		{
			//if( !(pOther.pev.FlagBitSet(FL_CLIENT) and !q2::PVP) ) //deals damage to players otherwise
				//pOther.TakeDamage( self.pev, pevOwner, pev.dmg, DMG_BLAST|DMG_ALWAYSGIB );

			TraceResult tr = g_Utility.GetGlobalTrace();
			q2::T_Damage( pOther, self, g_EntityFuncs.Instance(pev.owner), pev.velocity, pev.origin, tr.vecPlaneNormal, BFG_DAMAGE1, 0, DMG_ENERGYBEAM, q2::MOD_BFG_BLAST );
		}

		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg__l1a.wav" );
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, "quake2/weapons/bfg__x1b.wav", VOL_NORM, ATTN_NORM );

		//quake 2 stuff
		SetTouch( null );
		pev.solid = SOLID_NOT;
		Vector vecOrigin = pev.origin;
		vecOrigin = vecOrigin + pev.velocity * (-1 * 0.1); //gi.frame_time_s
		g_EntityFuncs.SetOrigin( self, vecOrigin );
		pev.velocity = g_vecZero;
		//self->enemy = other;

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(BFG_EXPLOSION1) );
			m1.WriteByte( 10 );//scale
			m1.WriteByte( 10 );//framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		if( m_pBFG !is null )
			g_EntityFuncs.Remove( m_pBFG );

		SetThink( ThinkFunction(this.bfg_explode) );
		pev.nextthink = g_Engine.time + q2::FRAMETIME; //10_hz
	}

	void bfg_explode()
	{
		float flPoints;
		Vector vecWhat;
		float flDist;

		// the BFG effect
		CBaseEntity@ pEntity = null;
		while( (@pEntity = g_EntityFuncs.FindEntityInSphere(pEntity, pev.origin, pev.dmgtime, "*", "classname")) !is null )
		{
			if( pEntity.pev.takedamage == DAMAGE_NO )
				continue;

			if( pEntity.edict() is pev.owner )
				continue;

			if( !q2::CanDamage(EHandle(pEntity), EHandle(self)) )
				continue;

			if( !q2::CanDamage(EHandle(pEntity), EHandle(g_EntityFuncs.Instance(pev.owner))) )
				continue;

			vecWhat = pEntity.pev.mins + pEntity.pev.maxs; //VectorAdd (pEntity->mins, pEntity->maxs, vecWhat);
			vecWhat = pEntity.pev.origin + vecWhat * 0.5; //VectorMA (pEntity->s.origin, 0.5, vecWhat, vecWhat);
			vecWhat = pev.origin - vecWhat; //VectorSubtract (self->s.origin, vecWhat, vecWhat);
			flDist = vecWhat.Length(); //flDist = VectorLength(vecWhat);
			flPoints = pev.dmg * (1.0 - sqrt(flDist/pev.dmgtime));
			if( pEntity.edict() is pev.owner)
				flPoints = flPoints * 0.5;

			/*gi.WriteByte (svc_temp_entity);
			gi.WriteByte (TE_BFG_EXPLOSION);
			gi.WritePosition (pEntity->s.origin);
			gi.multicast (pEntity->s.origin, MULTICAST_PHS);*/

			NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pEntity.pev.origin );
				m1.WriteByte( TE_EXPLOSION );
				m1.WriteCoord( pEntity.pev.origin.x );
				m1.WriteCoord( pEntity.pev.origin.y );
				m1.WriteCoord( pEntity.pev.origin.z );
				m1.WriteShort( g_EngineFuncs.ModelIndex(BFG_EXPLOSION2) );
				m1.WriteByte( 10 );//scale
				m1.WriteByte( 10 );//framerate
				m1.WriteByte( TE_EXPLFLAG_NOSOUND|TE_EXPLFLAG_NOPARTICLES );
			m1.End();

			NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, pEntity.pev.origin );
				m2.WriteByte( TE_DLIGHT );
				m2.WriteCoord( pEntity.pev.origin.x );
				m2.WriteCoord( pEntity.pev.origin.y );
				m2.WriteCoord( pEntity.pev.origin.z );
				m2.WriteByte( 20 + Math.RandomLong(0, 6) ); //radius
				m2.WriteByte( 0 ); //rgb
				m2.WriteByte( 255 );
				m2.WriteByte( 0 );
				m2.WriteByte( 10 ); //lifetime
				m2.WriteByte( 35 ); //decay
			m2.End();
/*
	TE_BFG_EXPLOSION:
		MSG_ReadPos (&net_message, pos);
		ex = CL_AllocExplosion ();
		VectorCopy (pos, ex->ent.origin);
		ex->type = ex_poly;
		ex->ent.flags = RF_FULLBRIGHT;
		ex->start = cl.frame.servertime - 100;
		ex->light = 350;
		ex->lightcolor[0] = 0.0;
		ex->lightcolor[1] = 1.0;
		ex->lightcolor[2] = 0.0;
		ex->ent.model = s_bfg2;
		ex->ent.flags |= RF_TRANSLUCENT;
		ex->ent.alpha = 0.30;
		ex->frames = 4;*/

			q2::T_Damage( pEntity, self, g_EntityFuncs.Instance(pev.owner), pev.velocity, pEntity.pev.origin, g_vecZero, flPoints, 0, DMG_ENERGYBEAM, q2::MOD_BFG_EFFECT );
		}

		/*self->nextthink = level.time + q2::FRAMETIME;
		self->s.frame++;
		if (self->s.frame == 5)
			self->think = G_FreeEdict;*/
		RemoveThink();
	}

	void RemoveThink()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg__l1a.wav" );

		if( m_pBFG !is null )
			g_EntityFuncs.Remove( m_pBFG );

		g_EntityFuncs.Remove( self );
	}

	void UpdateOnRemove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, "quake2/weapons/bfg__l1a.wav" );

		if( m_pBFG !is null )
			g_EntityFuncs.Remove( m_pBFG );

		BaseClass.UpdateOnRemove();
	}
}

void RegisterLaser()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2projectiles::q2laser", "q2laser" );
	g_Game.PrecacheOther( "q2laser" );
}

void RegisterGrenade()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2projectiles::q2grenade", "q2grenade" );
	g_Game.PrecacheOther( "q2grenade" );
}

void RegisterRocket()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2projectiles::q2rocket", "q2rocket" );
	g_Game.PrecacheOther( "q2rocket" );
}

void RegisterRailbeam()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2projectiles::q2railbeam", "q2railbeam" );
	g_Game.PrecacheOther( "q2railbeam" );
}

void RegisterBFG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2projectiles::q2bfg", "q2bfg" );
	g_Game.PrecacheOther( "q2bfg" );
}

void RegisterProjectile( string sType )
{
	if( sType == "laser" )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "q2laser" ) )
			q2projectiles::RegisterLaser();
	}
	else if( sType == "grenade" )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "q2grenade" ) )
			q2projectiles::RegisterGrenade();
	}
	else if( sType == "rocket" )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "q2rocket" ) )
			q2projectiles::RegisterRocket();
	}
	else if( sType == "railbeam" )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "q2railbeam" ) )
			q2projectiles::RegisterRailbeam();
	}
	else if( sType == "bfg" )
	{
		if( !g_CustomEntityFuncs.IsCustomEntity( "q2bfg" ) )
			q2projectiles::RegisterBFG();
	}
}

} //end of namespace q2projectiles

/* FIXME
*/

/* TODO
*/
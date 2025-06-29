namespace npc_q2brains
{

const string NPC_MODEL				= "models/quake2/monsters/brains/brains.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/brains/gibs/arm.mdl";
const string MODEL_GIB_BOOT		= "models/quake2/monsters/brains/gibs/boot.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/brains/gibs/chest.mdl";
const string MODEL_GIB_DOOR		= "models/quake2/monsters/brains/gibs/door.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/brains/gibs/head.mdl";
const string MODEL_GIB_PELVIS		= "models/quake2/monsters/brains/gibs/pelvis.mdl";

const string SPRITE_CABLE				= "sprites/tongue.spr";
const string SPRITE_BEAM				= "sprites/laserbeam.spr";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 56 ); //80 in svencoop ??
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 300;
const float LASER_DAMAGE				= 1.0;

const int AE_SWING_LEFT				= 11;
const int AE_SWING_RIGHT			= 12;
const int AE_HIT_LEFT					= 13;
const int AE_HIT_RIGHT					= 14;
const int AE_CHEST_OPEN				= 15;
const int AE_CHEST_ATTACK			= 16;
const int AE_CHEST_CLOSE			= 17;
const int AE_TONGUE_ATTACK		= 18;
const int AE_LASER_REATTACK		= 20;

const int SPAWNFLAG_BRAIN_NO_LASERS = 8;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/brains/brnlens1.wav",
	"quake2/npcs/brains/brnsght1.wav",
	"quake2/npcs/brains/brnsrch1.wav",
	"quake2/npcs/brains/brnatck1.wav",
	"quake2/npcs/brains/brnatck2.wav",
	"quake2/npcs/brains/brnatck3.wav",
	"quake2/npcs/brains/melee1.wav",
	"quake2/npcs/brains/melee2.wav",
	"quake2/npcs/brains/melee3.wav",
	"quake2/misc/lasfly.wav",
	"quake2/npcs/brains/brnpain1.wav",
	"quake2/npcs/brains/brnpain2.wav",
	"quake2/npcs/brains/brndeth1.wav",
	"quake2/weapons/lashit.wav" //power armor hit sound
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_CHEST_OPEN,
	SND_TENT_EXTEND,
	SND_TENT_RETRACT,
	SND_MELEE1,
	SND_MELEE2,
	SND_MELEE3,
	SND_LASER,
	SND_PAIN1,
	SND_PAIN2
};

final class npc_q2brains : CBaseQ2NPC
{
	private EHandle m_hBeam1;
	private CBeam@ m_pBeam1
	{
		get const { return cast<CBeam@>(m_hBeam1.GetEntity()); }
		set { m_hBeam1 = EHandle(@value); }
	}

	private EHandle m_hBeam2;
	private CBeam@ m_pBeam2
	{
		get const { return cast<CBeam@>(m_hBeam2.GetEntity()); }
		set { m_hBeam2 = EHandle(@value); }
	}

	private EHandle m_hTentacle;
	private CBeam@ m_pTentacle
	{
		get const { return cast<CBeam@>(m_hTentacle.GetEntity()); }
		set { m_hTentacle = EHandle(@value); }
	}

	private bool m_bComboAttack;
	private bool m_bDoLaserAttack;

	private float m_flNextBeamDamage;

	void MonsterSpawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		if( pev.health <= 0 )
			pev.health					= NPC_HEALTH * m_flHealthMultiplier;

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= -0.30;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Brains";

		m_flGibHealth = -150.0;
		SetMass( 400 );

		monsterinfo.power_armor_type = q2::POWER_ARMOR_SCREEN;
		monsterinfo.power_armor_power = 100;

		@this.m_Schedules = @brains_schedules;

		self.MonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_BOOT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_DOOR );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_PELVIS );

		g_Game.PrecacheModel( SPRITE_CABLE );
		g_Game.PrecacheModel( SPRITE_BEAM );

		for( uint i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
	}

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys = 120;
		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	void MonsterRunAI()
	{
		if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.deadflag != DEAD_NO )
		{
			StopLaserAttack();
			DestroyTentacle();
		}

		if( m_bDoLaserAttack )
			brain_laserbeam();
	}

	void MonsterIdle()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void MonsterSearch()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	//melee attacks are handled in GetScheduleOfType
	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) )
			return true;

		return false;
	}

	Schedule@ GetScheduleOfType( int iType )
	{
		switch( iType )
		{
			case SCHED_RANGE_ATTACK1:
			{
				//TESTING
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //tentacle
				//m_bDoLaserAttack = true; //laser
				//return BaseClass.GetScheduleOfType( SCHED_CHASE_ENEMY );

				float flRange = q2::range_to( self, self.m_hEnemy );
				if( flRange <= Q2_RANGE_NEAR )
				{
					if( Math.RandomFloat(0.0, 1.0) < 0.5 )
					{
						StopLaserAttack();
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //M_SetAnimation(self, &brain_move_attack3);
					}
					else if( !HasFlags(m_iSpawnFlags, SPAWNFLAG_BRAIN_NO_LASERS) )
					{
						if( !m_bDoLaserAttack )
							g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_LASER], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP ); //0.05

						m_bDoLaserAttack = true; //M_SetAnimation(self, &brain_move_attack4);

						return BaseClass.GetScheduleOfType( SCHED_CHASE_ENEMY );
					}
				}
				else if( !HasFlags(m_iSpawnFlags, SPAWNFLAG_BRAIN_NO_LASERS) )
				{
					if( !m_bDoLaserAttack )
						g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_LASER], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP ); //0.05

					m_bDoLaserAttack = true; //M_SetAnimation(self, &brain_move_attack4);

					return BaseClass.GetScheduleOfType( SCHED_CHASE_ENEMY );
				}

				break;
			}

			case SCHED_MELEE_ATTACK1:
			{
				//TESTING
				//return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //slashes
				//return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK2 ); //chest

				StopLaserAttack();

				if( Math.RandomFloat(0.0, 1.0) <= 0.5 or m_bComboAttack )
					return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 );
				else
					return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK2 );
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_SWING_LEFT:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE2], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_SWING_RIGHT:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE1], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_HIT_LEFT:
			{
				brain_hit_left();
				break;
			}

			case AE_HIT_RIGHT:
			{
				brain_hit_right();
				break;
			}

			case AE_CHEST_OPEN:
			{
				brain_chest_open();
				break;
			}

			case AE_CHEST_ATTACK:
			{
				brain_tentacle_attack();
				break;
			}

			case AE_CHEST_CLOSE:
			{
				monsterinfo.power_armor_type = q2::POWER_ARMOR_SCREEN; //IT_ITEM_POWER_SCREEN;

				if( m_bComboAttack )
				{
					self.ChangeSchedule( self.GetScheduleOfType(SCHED_MELEE_ATTACK1) );
					m_bComboAttack = false;
				}

				break;
			}

			case AE_TONGUE_ATTACK:
			{
				brain_tounge_attack();
				break;
			}

			case AE_LASER_REATTACK:
			{
				if( Math.RandomFloat(0.0, 1.0) >= 0.5 or !q2::visible(self, self.m_hEnemy) or self.m_hEnemy.GetEntity().pev.health <= 0 )
					StopLaserAttack();

				break;
			}
		}
	}

	void brain_hit_left()
	{
		if( m_bRerelease )
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE_RR, pev.mins.x, 8 );

			if( fire_hit(vecAim, Math.RandomFloat(15.0, 20.0), 40) ) //irandom(15, 20)
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE3], VOL_NORM, ATTN_NORM );
			else
				monsterinfo.melee_debounce_time = g_Engine.time + 3.0;
		}
		else
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE, pev.mins.x, 8 );

			if( fire_hit(vecAim, 15 + Math.RandomFloat(0.0, 5.0), 40) ) //(15 + (rand() %5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE3], VOL_NORM, ATTN_NORM );
		}
	}

	void brain_hit_right()
	{
		if( m_bRerelease )
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE_RR, pev.maxs.x, 8 );

			if( fire_hit(vecAim, Math.RandomFloat(15.0, 20.0), 40) ) //irandom(15, 20)
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE3], VOL_NORM, ATTN_NORM );
			else
				monsterinfo.melee_debounce_time = g_Engine.time + 3.0;
		}
		else
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE, pev.maxs.x, 8 );

			if( fire_hit(vecAim, 15 + Math.RandomFloat(0.0, 5.0), 40) ) //(15 + (rand() %5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE3], VOL_NORM, ATTN_NORM );
		}
	}

	void brain_chest_open()
	{
		if( m_bRerelease )
		{
			m_bComboAttack = false;
			monsterinfo.power_armor_type = q2::POWER_ARMOR_NONE; //IT_NULL;
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_CHEST_OPEN], VOL_NORM, ATTN_NORM );

		}
		else
		{
			m_bComboAttack = false;
			monsterinfo.power_armor_type = q2::POWER_ARMOR_NONE;
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_CHEST_OPEN], VOL_NORM, ATTN_NORM );
		}
	}

	void brain_tentacle_attack()
	{
		if( m_bRerelease )
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE_RR, 0, 8 );
			if( fire_hit(vecAim, Math.RandomFloat(10.0, 15.0), -600) )
				m_bComboAttack = true;
			else
				monsterinfo.melee_debounce_time = g_Engine.time + 3.0;

			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_TENT_RETRACT], VOL_NORM, ATTN_NORM );
		}
		else
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE, 0, 8 );

			if( fire_hit(vecAim, 10 + Math.RandomFloat(0.0, 4.0), -600) and q2npc::g_iDifficulty > q2::DIFF_EASY ) //(10 + (rand() %5))
				m_bComboAttack = true;

			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_TENT_RETRACT], VOL_NORM, ATTN_NORM );
		}
	}

	bool brain_tounge_attack_ok( const Vector &in start, const Vector &in end )
	{
		Vector dir, angles;

		// check for max distance
		dir = start - end;
		if( dir.Length() > 512 )
			return false;

		// check for min/max pitch
		angles = Math.VecToAngles( dir );
		if( angles.x < -180 )
			angles.x += 360;

		if( abs(angles.x) > 30 ) //fabsf
			return false;

		return true;
	}

	void brain_tounge_attack()
	{
		Vector vecStart, vecEnd, vecDir;
		TraceResult tr;
		float flDamage;

		self.GetAttachment( 0, vecStart, void );

		vecEnd = self.m_hEnemy.GetEntity().pev.origin;

		if( !brain_tounge_attack_ok(vecStart, vecEnd) )
		{
			vecEnd.z = self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.maxs.z - 8;
			if( !brain_tounge_attack_ok(vecStart, vecEnd) )
			{
				vecEnd.z = self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.mins.z + 8;
				if( !brain_tounge_attack_ok(vecStart, vecEnd) )
					return;
			}
		}

		vecEnd = self.m_hEnemy.GetEntity().pev.origin;

		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr ); //tr = gi.traceline(vecStart, vecEnd, self, MASK_PROJECTILE);
		if( tr.pHit !is self.m_hEnemy.GetEntity().edict() )
			return;

		flDamage = 5.0;
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_TENT_RETRACT], VOL_NORM, ATTN_NORM );

		UpdateTentacle();

		vecDir = vecStart - vecEnd;
		q2::T_Damage( self.m_hEnemy, self, self, vecDir, self.m_hEnemy.GetEntity().pev.origin, g_vecZero, flDamage, 0, q2::DAMAGE_NO_KNOCKBACK, q2::MOD_BRAINTENTACLE );

		// pull the enemy in
		Vector forward;
		pev.origin.z += 1;
		g_EngineFuncs.AngleVectors( pev.angles, forward, void, void );
		self.m_hEnemy.GetEntity().pev.velocity = forward * -1200;
	}

	void brain_laserbeam()
	{
		if( !m_bDoLaserAttack )
			return;

		Vector vecStart, vecAimdir;
		self.GetAttachment( 1, vecStart, void );
		PredictAim( self.m_hEnemy, vecStart, 0, false, Math.RandomFloat(0.1, 0.2), vecAimdir, void );

		if( q2npc::g_iChaosMode == q2::CHAOS_NONE )
			monster_fire_dabeam( vecStart, vecAimdir, LASER_DAMAGE );
		else
			monster_fire_weapon( q2::WEAPON_RANDOM, vecStart, vecAimdir, LASER_DAMAGE );
	}

	void UpdateTentacle()
	{
		if( m_pTentacle is null )
			CreateTentacle();
	}

	void CreateTentacle()
	{
		DestroyTentacle();

		if( m_pTentacle is null )
		{
			@m_pTentacle = g_EntityFuncs.CreateBeam( SPRITE_CABLE, 16 );

			m_pTentacle.EntsInit( self.entindex(), self.m_hEnemy.GetEntity().entindex() );
			m_pTentacle.SetFlags( BEAM_FSOLID );
			m_pTentacle.SetBrightness( 155 );
			m_pTentacle.SetStartAttachment( 1 );
			m_pTentacle.pev.spawnflags |= SF_BEAM_TEMPORARY;
			m_pTentacle.LiveForTime( 1.0 );
		}
	}

	void DestroyTentacle()
	{
		if( m_pTentacle !is null )
			g_EntityFuncs.Remove(m_pTentacle);
	}

	void monster_fire_dabeam( Vector vecStart, Vector vecAimdir, float flDamage )
	{
		TraceResult tr;
		Vector vecEnd;

		vecEnd = vecStart + vecAimdir * 8192;

		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );

		if( m_flNextBeamDamage < g_Engine.time )
		{
			if( tr.pHit !is null and g_EngineFuncs.PointContents(tr.vecEndPos) != CONTENTS_SKY )
			{
				if( tr.flFraction < 1.0 )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( pHit.pev.takedamage != DAMAGE_NO )
						q2::T_Damage( pHit, self, self, vecAimdir, tr.vecEndPos, tr.vecPlaneNormal, flDamage, q2npc::g_iDifficulty, 0, q2::MOD_TARGET_LASER );
					else
					{
						for( uint i = 0; i < 2; ++i )
							g_Utility.Sparks( tr.vecEndPos );

						//g_SoundSystem.PlaySound( null, CHAN_AUTO, arrsNPCSounds[SND_LASERHIT], 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, tr.vecEndPos );
					}
				}
			}

			m_flNextBeamDamage = g_Engine.time + 0.1;
		}

		UpdateBeams( tr.vecEndPos );
	}

	void UpdateBeams( const Vector &in endPoint )
	{
		if( m_pBeam1 is null or m_pBeam2 is null )
			CreateBeams();

		m_pBeam1.SetStartPos( endPoint );
		m_pBeam2.SetStartPos( endPoint );
	}

	void CreateBeams()
	{
		DestroyBeams();

		@m_pBeam1 = g_EntityFuncs.CreateBeam( SPRITE_BEAM, 10 );
		m_pBeam1.PointEntInit( pev.origin, self.entindex() );
		m_pBeam1.SetScrollRate( 20 );
		m_pBeam1.SetBrightness( 128 );
/*
		if (self->monsterinfo.aiflags & AI_MEDIC)
			beam_ptr->s.skinnum = 0xf3f3f1f1;
		else
			beam_ptr->s.skinnum = 0xf2f2f0f0;
*/
		m_pBeam1.SetColor( 255, 42, 42 );
		m_pBeam1.SetEndAttachment( 2 );
		m_pBeam1.pev.spawnflags |= SF_BEAM_TEMPORARY;

		@m_pBeam2 = g_EntityFuncs.CreateBeam( SPRITE_BEAM, 10 );
		m_pBeam2.PointEntInit( pev.origin, self.entindex() );
		m_pBeam2.SetScrollRate( 20 );
		m_pBeam2.SetBrightness( 128 );
/*
		if (self->monsterinfo.aiflags & AI_MEDIC)
			beam_ptr->s.skinnum = 0xf3f3f1f1;
		else
			beam_ptr->s.skinnum = 0xf2f2f0f0;
*/
		m_pBeam2.SetColor( 255, 42, 42 );
		m_pBeam2.SetEndAttachment( 3 );
		m_pBeam2.pev.spawnflags |= SF_BEAM_TEMPORARY;
	}

	void DestroyBeams()
	{
		if( m_pBeam1 !is null )
			g_EntityFuncs.Remove( m_pBeam1 );

		if( m_pBeam2 !is null )
			g_EntityFuncs.Remove( m_pBeam2 );
	}

	void StopLaserAttack()
	{
		m_bDoLaserAttack = false;
		g_SoundSystem.StopSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_LASER] );
		DestroyBeams();
	}

	void MonsterSetSkin()
	{
		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;
		else
			pev.skin &= ~1;
	}

	void MonsterPain( float flDamage )
	{
		if( g_Engine.time < pain_debounce_time )
			return;

		pain_debounce_time = g_Engine.time + 3.0;

		if( m_bRerelease )
		{
			float r = Math.RandomFloat( 0.0, 1.0 );

			if( r < 0.33 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
			else if( r < 0.66 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );

			if( !M_ShouldReactToPain() )
				return;

			if( r < 0.33 )
				self.ChangeSchedule( slQ2Pain1 );
			else if( r < 0.66 )
				self.ChangeSchedule( slQ2Pain2 );
			else
				self.ChangeSchedule( slQ2Pain3 );

			//clear duck flag
			/*if (self->monsterinfo.aiflags & AI_DUCKED)
				monster_duck_up(self);*/
		}
		else
		{
			if( !M_ShouldReactToPain() )
				return;

			float r = Math.RandomFloat( 0.0, 1.0 );

			if( r < 0.33 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
				self.ChangeSchedule( slQ2Pain1 );
			}
			else if( r < 0.66 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
				self.ChangeSchedule( slQ2Pain2 );
			}
			else
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
				self.ChangeSchedule( slQ2Pain3 );
			}
		}
	}

	void MonsterDead()
	{
		if( m_bRerelease )
		{
			g_EntityFuncs.SetSize( self.pev, NPC_MINS_DEAD, NPC_MAXS_DEAD );
			monster_dead();
		}
		else
		{
			g_EntityFuncs.SetSize( self.pev, NPC_MINS_DEAD, NPC_MAXS_DEAD );
			pev.movetype = MOVETYPE_TOSS;
			//self->svflags |= SVF_DEADMONSTER;
			pev.nextthink = 0;
			g_EntityFuncs.SetOrigin( self, pev.origin ); //gi.linkentity (self);
		}
	}

	//FUCKING ERROR: CustomEntityCallbackHandler::SetThinkFunction: function must be a delegate of the owning object type! BULLSHIT
	void monster_dead()
	{
		SetThink( ThinkFunction(this.monster_dead_think) );
		monster_dead_base();
	}

	void monster_dead_think()
	{
		monster_dead_think_base();
	}

	void MonsterGib()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		q2::ThrowGib( self, 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_ARM, pev.dmg, 28, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_ARM, pev.dmg, 35, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_BOOT, pev.dmg, 45 );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_DOOR, pev.dmg, 25, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_DOOR, pev.dmg, 26, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 4, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_PELVIS, pev.dmg, 1, BREAK_FLESH );
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		DestroyTentacle();
		StopLaserAttack();
	}
}

array<ScriptSchedule@>@ brains_schedules;

enum monsterScheds
{
	TASK_TEMPLATE = LAST_COMMON_TASK + 1
}

void InitSchedules()
{
	InitQ2BaseSchedules();

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3 };

	@brains_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2brains::npc_q2brains", "npc_q2brains" );
	g_Game.PrecacheOther( "npc_q2brains" );
}

} //end of namespace npc_q2brains

/* FIXME
*/

/* TODO
	Check for laser-attack while monster is running ??
*/
namespace npc_q2parasite
{

const string NPC_MODEL				= "models/quake2/monsters/parasite/parasite.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/parasite/gibs/chest.mdl";
const string MODEL_GIB_BLEG		= "models/quake2/monsters/parasite/gibs/bleg.mdl";
const string MODEL_GIB_FLEG		= "models/quake2/monsters/parasite/gibs/fleg.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/parasite/gibs/head.mdl";

const string SPRITE_TONGUE			= "sprites/tongue.spr";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 42 ); //48 in quake 2

const int NPC_HEALTH					= 175;

const int AE_IDLETAP						= 11;
const int AE_IDLESCRATCH				= 12;
const int AE_LAUNCH						= 13;
const int AE_DRAIN						= 14;
const int AE_REELIN						= 15;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/parasite/paridle1.wav",
	"quake2/npcs/parasite/paridle2.wav",
	"quake2/npcs/parasite/parsght1.wav",
	"quake2/npcs/parasite/parsrch1.wav",
	"quake2/npcs/parasite/parpain1.wav",
	"quake2/npcs/parasite/parpain2.wav",
	"quake2/npcs/parasite/pardeth1.wav",
	"quake2/npcs/parasite/paratck1.wav",
	"quake2/npcs/parasite/paratck2.wav",
	"quake2/npcs/parasite/paratck3.wav",
	"quake2/npcs/parasite/paratck4.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_TAP,
	SND_SCRATCH,
	SND_SIGHT,
	SND_SEARCH,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH,
	SND_LAUNCH,
	SND_HIT,
	SND_SUCK,
	SND_REELIN
};

const array<string> arrsNPCAnims =
{
	"pain"
};

enum anim_e
{
	ANIM_PAIN = 0
};

final class npc_q2parasite : CBaseQ2NPC
{
	protected EHandle m_hBeam;
	protected CBeam@ m_pBeam
	{
		get const { return cast<CBeam@>(m_hBeam.GetEntity()); }
		set { m_hBeam = EHandle(@value); }
	}

	private float m_flFidgetLoopCheck;

	void MonsterSpawn()
	{
		AppendAnims();

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
			self.m_FormattedName	= "Parasite";

		m_flGibHealth = -60.0;
		SetMass( 250 );

		@this.m_Schedules = @parasite_schedules;

		self.MonsterInit();
	}

	void AppendAnims()
	{
		for( uint i = 0; i < arrsNPCAnims.length(); i++ )
			arrsQ2NPCAnims.insertLast( arrsNPCAnims[i] );
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_BLEG );
		g_Game.PrecacheModel( MODEL_GIB_FLEG );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		g_Game.PrecacheModel( SPRITE_TONGUE );

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

		return CLASS_ALIEN_MILITARY; //??
	}

	void MonsterAlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void DeathSound() 
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );
	}

	void RunAI()
	{
		if( m_flTriggeredSpawn > 0 )
		{
			m_flTriggeredSpawn = 0.0;
			monster_triggered_spawn();
		}

		BaseClass.RunAI();

		CheckArmorEffect();

		if( !self.m_hEnemy.IsValid() )
			DestroyEffect();
	}

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) )
			return true;

		return false;
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_SCRATCH_LOOP:
			{
				//scratch for at least this long
				m_flFidgetLoopCheck = g_Engine.time + 1.0;
				break;
			}

			default:
			{			
				BaseClass.StartTask( pTask );
				break;
			}
		}
	}

	void RunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_SCRATCH_LOOP:
			{
				if( g_Engine.time > m_flFidgetLoopCheck )
				{
					m_flFidgetLoopCheck = g_Engine.time + 0.4;

					if( Math.RandomFloat(0.0, 1.0) > 0.8 )
						self.TaskComplete();
				}

				break;
			}

			default:
			{
				BaseClass.RunTask( pTask );

				break;
			}
		}
	}

	Schedule@ GetScheduleOfType( int iType )
	{
		switch( iType )
		{
			case SCHED_IDLE_STAND:
			{
				if( ShouldFidget() )
				{
					m_flIdleTime = g_Engine.time + 15.0 + Math.RandomFloat(0.0, 1.0) * 15.0;
					return slParasiteFidget;
				}
				else
					return BaseClass.GetScheduleOfType( iType );
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_IDLETAP:
			{
				if( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
					g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_TAP], 0.75, 2.75 );

				break;
			}

			case AE_IDLESCRATCH:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SCRATCH], 0.75, 2.75 );
				break;
			}

			case AE_LAUNCH:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_LAUNCH], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_DRAIN:
			{
				parasite_drain_attack( atoi(pEvent.options()) );
				break;
			}

			case AE_REELIN:
			{
				DestroyEffect();
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_REELIN], VOL_NORM, ATTN_NORM );
				break;
			}
		}
	}

	bool parasite_drain_attack_ok( Vector vecStart, Vector vecEnd )
	{
		Vector vecDir, vecAngles;

		// check for max distance
		vecDir = ( vecEnd - vecStart );
		if( vecDir.Length() > 256.0 )
			return false;

		// check for min/max pitch
		vecAngles = Math.VecToAngles( vecDir );
		if( vecAngles.x < -180 )
			vecAngles.x += 360;
		else if( vecAngles.x > 180 )
			vecAngles.x -= 360;

		if( fabs(vecAngles.x) > 45 )
			return false;

		return true;
	}

	void parasite_drain_attack( int iFrame )
	{
		Vector vecStart, vecEnd, vecDir;
		TraceResult tr;
		float flDamage;

		Math.MakeVectors( pev.angles );
		vecStart = pev.origin + g_Engine.v_forward * 9.0 + g_Engine.v_up * 36.0;

		vecEnd = self.m_hEnemy.GetEntity().pev.origin;

		if( !parasite_drain_attack_ok(vecStart, vecEnd) )
		{
			vecEnd.z = self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.maxs.z - 8;
			if( !parasite_drain_attack_ok(vecStart, vecEnd) )
			{
				vecEnd.z = self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.mins.z + 8;
				if( !parasite_drain_attack_ok(vecStart, vecEnd) )
				{
					DestroyEffect();
					return;
				}
			}
		}

		vecEnd = self.m_hEnemy.GetEntity().pev.origin;
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );
		if( tr.pHit is null or tr.pHit !is self.m_hEnemy.GetEntity().edict() )
		{
			DestroyEffect();
			return;
		}

		if( iFrame == 2 )
		{
			flDamage = 5.0;
			g_SoundSystem.EmitSound( self.m_hEnemy.GetEntity().edict(), CHAN_AUTO, arrsNPCSounds[SND_HIT], VOL_NORM, ATTN_NORM );
		}
		else
		{
			if( iFrame == 3 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SUCK], VOL_NORM, ATTN_NORM );

			flDamage = 2;
		}

		UpdateEffect();

		vecDir = ( vecEnd - vecStart );
		g_WeaponFuncs.ClearMultiDamage();
		self.m_hEnemy.GetEntity().TraceAttack( self.pev, flDamage, vecDir, tr, DMG_GENERIC );
		g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );
	}

	//from halflife-op4-updated-master
	void UpdateEffect()
	{
		if( m_pBeam is null )
			CreateEffect();
	}

	void CreateEffect()
	{
		DestroyEffect();

		if( !self.m_hEnemy.IsValid() ) return;

		if( m_pBeam is null )
		{
			@m_pBeam = g_EntityFuncs.CreateBeam( SPRITE_TONGUE, 16 );

			m_pBeam.EntsInit( self.entindex(), self.m_hEnemy.GetEntity().entindex() );
			m_pBeam.SetFlags( BEAM_FSOLID );
			m_pBeam.SetBrightness( 155 );
			m_pBeam.SetStartAttachment( 1 );
			m_pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
			m_pBeam.LiveForTime( 1.0 );
		}
	}

	void DestroyEffect()
	{
		if( m_pBeam !is null )
			g_EntityFuncs.Remove(m_pBeam);
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		float psave = CheckPowerArmor( pevInflictor, flDamage );
		flDamage -= psave;

		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;
		else
			pev.skin &= ~1;

		if( pevAttacker !is self.pev )
			pevAttacker.frags += ( flDamage/90 );

		pev.dmg = flDamage;

		if( pev.deadflag == DEAD_NO )
			HandlePain( flDamage );

		M_ReactToDamage( g_EntityFuncs.Instance(pevAttacker) );

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage )
	{
		if( g_Engine.time < m_flPainDebounceTime )
			return;

		m_flPainDebounceTime = g_Engine.time + 3.0;

		if( Math.RandomFloat(0.0, 1.0) < 0.5 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() or self.m_Activity == ACT_RANGE_ATTACK1 )
			return;

		DestroyEffect();

		self.ChangeSchedule( slQ2Pain1 );
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		DestroyEffect();
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		q2::ThrowGib( self, 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_BLEG, pev.dmg, 19, 0 );
		q2::ThrowGib( self, 1, MODEL_GIB_BLEG, pev.dmg, 24, 0 );
		q2::ThrowGib( self, 1, MODEL_GIB_FLEG, pev.dmg, 14, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_FLEG, pev.dmg, 17, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 4, BREAK_FLESH );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}
 
	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
		{
			// this situation can screw up monsters who can't tell their entity pointers are invalid.
			pev.health = 0;
		}

		g_EntityFuncs.Remove(self);
	}
}

array<ScriptSchedule@>@ parasite_schedules;

enum monsterScheds
{
	TASK_SCRATCH_LOOP = LAST_COMMON_TASK + 1
}

ScriptSchedule slParasiteFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Parasite Idle Fidgeting"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slParasiteFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slParasiteFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) ); //fidget start
	slParasiteFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_TWITCH)) ); //fidget loop
	slParasiteFidget.AddTask( ScriptTask(TASK_SCRATCH_LOOP, 0) );
	slParasiteFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL2)) ); //fidget end
	slParasiteFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slParasiteFidget };

	@parasite_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2parasite::npc_q2parasite", "npc_q2parasite" );
	g_Game.PrecacheOther( "npc_q2parasite" );
}

} //end of namespace npc_q2parasite

/* FIXME
*/

/* TODO
	Add rerelease stuff ??
	Make a proper tongue entity that uses the model ??
*/
namespace npc_q2mutant
{

const string NPC_MODEL				= "models/quake2/monsters/mutant/mutant.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/mutant/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/mutant/gibs/foot.mdl";
const string MODEL_GIB_HAND		= "models/quake2/monsters/mutant/gibs/hand.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/mutant/gibs/head.mdl";

const Vector NPC_MINS					= Vector( -32, -32, 0 );
const Vector NPC_MAXS					= Vector( 32, 32, 72 ); //80 in svencoop ??
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 300;

const int AE_STEP							= 11;
const int AE_MELEE_LEFT				= 12;
const int AE_MELEE_RIGHT				= 13;
const int AE_MELEE_REFIRE			= 14;
const int AE_JUMP							= 15;

const int SPAWNFLAG_MUTANT_NOJUMPING = 8;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/mutant/mutidle1.wav",
	"quake2/npcs/mutant/mutsght1.wav",
	"quake2/npcs/mutant/mutsrch1.wav",
	"quake2/npcs/mutant/step1.wav",
	"quake2/npcs/mutant/step2.wav",
	"quake2/npcs/mutant/step3.wav",
	"quake2/npcs/mutant/mutatck1.wav",
	"quake2/npcs/mutant/mutatck2.wav",
	"quake2/npcs/mutant/mutatck3.wav",
	"quake2/npcs/mutant/thud1.wav",
	"quake2/npcs/mutant/mutpain1.wav",
	"quake2/npcs/mutant/mutpain2.wav",
	"quake2/npcs/mutant/mutdeth1.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_STEP1,
	SND_STEP2,
	SND_STEP3,
	SND_MELEE_SWING,
	SND_MELEE_HIT1,
	SND_MELEE_HIT2,
	SND_THUD,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH
};

final class npc_q2mutant : CBaseQ2NPC
{
	private bool m_bJumpAttack;
	private bool m_bJumping;
	private bool m_bBlocked;
	private float m_flFidgetLoopCheck;
	private bool m_bMeleePossible;
	private bool m_bRangePossible;

	bool NoAttacksAvailable()
	{
		return !m_bMeleePossible and !m_bRangePossible;
	}

	void MonsterSpawn()
	{
		m_bRerelease = false;
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
			self.m_FormattedName	= "Mutant";

		m_flGibHealth = -120.0;
		SetMass( 300 );
		monsterinfo.can_jump = !HasFlags( m_iSpawnFlags, SPAWNFLAG_MUTANT_NOJUMPING );
		monsterinfo.drop_height = 256.0;
		monsterinfo.jump_height = 68.0;

		@this.m_Schedules = @mutant_schedules;

		self.MonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_HAND );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

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

		return CLASS_ALIEN_PREDATOR;
	}

	void MonsterRunAI()
	{
		if( m_bJumpAttack )
			mutant_check_landing();
		else if( m_bJumping )
			mutant_jump_wait_land();
		else if( pev.framerate != 1.0 )
			pev.framerate = 1.0;
	}

	void MonsterIdle()
	{
		if( !self.m_hEnemy.IsValid() )
		{
			self.ChangeSchedule( slMutantFidget );
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
		}
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void MonsterSearch()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void DeathSound() 
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );
	}

	//TEST
	void Blocked( CBaseEntity@ pOther )
	{
		//g_Game.AlertMessage( at_notice, "Blocked by %1\n", pOther.GetClassname() );
		m_bBlocked = true;

		BaseClass.Blocked( pOther );
	}

	bool mutant_check_melee()
	{
		if( m_bRerelease )
			return q2::range_to(self, self.m_hEnemy) <= Q2_RANGE_MELEE and monsterinfo.melee_debounce_time <= g_Engine.time;
		else if( q2::range_to(self, self.m_hEnemy) <= Q2_RANGE_MELEE )
			return true;

		return false;
	}

	bool mutant_check_jump()
	{
		if( m_bRerelease )
		{
			Vector v;
			float flDistance;

			// don't jump if there's no way we can reach standing height
			if( pev.absmin.z + 125 < self.m_hEnemy.GetEntity().pev.absmin.z )
				return false;

			v.x = pev.origin.x - self.m_hEnemy.GetEntity().pev.origin.x;
			v.y = pev.origin.y - self.m_hEnemy.GetEntity().pev.origin.y;
			v.z = 0;
			flDistance = v.Length();

			// if we're not trying to avoid a melee, then don't jump
			if( flDistance < 100 and monsterinfo.melee_debounce_time <= g_Engine.time )
				return false;
			// only use it to close distance gaps
			if( flDistance > 265 )
				return false;

			return monsterinfo.attack_finished < g_Engine.time and q2::brandom();
		}
		else
		{
			Vector v;
			float flDistance;

			if( pev.absmin.z > (self.m_hEnemy.GetEntity().pev.absmin.z + 0.75 * self.m_hEnemy.GetEntity().pev.size.z) )
				return false;

			if( pev.absmax.z < (self.m_hEnemy.GetEntity().pev.absmin.z + 0.25 * self.m_hEnemy.GetEntity().pev.size.z) )
				return false;

			v.x = pev.origin.x - self.m_hEnemy.GetEntity().pev.origin.x;
			v.y = pev.origin.y - self.m_hEnemy.GetEntity().pev.origin.y;
			v.z = 0;
			flDistance = v.Length();

			if( flDistance < 100 )
				return false;

			if( flDistance > 100 )
			{
				if( Math.RandomFloat(0.0, 1.0) < 0.9 )
					return false;
			}

			return true;
		}
	}

	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( mutant_check_melee() )
		{
			m_bMeleePossible = true;
			return true;
		}

		m_bMeleePossible = false;
		return false;
	}

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( !HasFlags(m_iSpawnFlags, SPAWNFLAG_MUTANT_NOJUMPING) and mutant_check_jump() and M_CheckAttack(flDist) ) //M_CheckAttack NEEDED ??
		{
			m_bRangePossible = true;
			return true;
		}

		m_bRangePossible = false;
		return false;
	}

	bool CheckRangeAttack2( float flDot, float flDist )
	{
		if( !m_bRerelease or !pev.FlagBitSet(FL_ONGROUND) )
			return false;

		//if( !HasFlags(m_iSpawnFlags, SPAWNFLAG_MUTANT_NOJUMPING) and m_bBlocked and mutant_check_jump() and M_CheckAttack(flDist/2) )
		if( !HasFlags(m_iSpawnFlags, SPAWNFLAG_MUTANT_NOJUMPING) and !self.HasConditions(bits_COND_CAN_MELEE_ATTACK1) and !self.HasConditions(bits_COND_CAN_RANGE_ATTACK1) /*and m_bBlocked*/ and M_CheckAttack(flDist/2) )
		{
			m_bBlocked = false;
			return true;
		}

		m_bJumping = false;
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

	void MonsterRunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_SCRATCH_LOOP:
			{
				if( g_Engine.time > m_flFidgetLoopCheck )
				{
					m_flFidgetLoopCheck = g_Engine.time + 0.4;

					if( Math.RandomFloat(0.0, 1.0) >= 0.75 ) //loop if frandom() < 0.75f
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

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_STEP:
			{
				mutant_step();
				break;
			}

			case AE_MELEE_LEFT:
			{
				mutant_hit_left();
				break;
			}

			case AE_MELEE_RIGHT:
			{
				mutant_hit_right();
				break;
			}

			case AE_MELEE_REFIRE:
			{
				mutant_check_refire();
				break;
			}

			case AE_JUMP:
			{
				if( atoi(pEvent.options()) == 1 )
					mutant_jump_up();
				else
					mutant_jump_takeoff();

				break;
			}
		}
	}

	void mutant_jump_up()
	{
		//original
		/*Vector forward, up;

		g_EngineFuncs.AngleVectors( pev.angles, forward, void, up );
		pev.velocity = pev.velocity + forward * 200 + up * 450;*/

		//from monster_headcrab
		Vector vecJumpVelocity;
		if( self.m_hEnemy.GetEntity() !is null )
		{
			g_EntityFuncs.SetOrigin( self, pev.origin + Vector(0, 0, 10) );

			float gravity = g_EngineFuncs.CVarGetFloat( "sv_gravity" );
			if( gravity <= 1 )
				gravity = 1;

			float height = ( self.m_hEnemy.GetEntity().pev.origin.z + self.m_hEnemy.GetEntity().pev.view_ofs.z - pev.origin.z );
			if( height < 32 )
				height = 32;

			float speed = sqrt( 2 * gravity * height );
			float time = speed / gravity;

			vecJumpVelocity = ( self.m_hEnemy.GetEntity().pev.origin + self.m_hEnemy.GetEntity().pev.view_ofs - pev.origin );
			vecJumpVelocity = vecJumpVelocity * ( 1.0 / time );

			vecJumpVelocity.z = speed;

			float distance = vecJumpVelocity.Length();
			
			if( distance > 650.0 ) //LEAP_DISTANCE_MAX
				vecJumpVelocity = vecJumpVelocity * ( 650.0 / distance );
		}

		pev.velocity = vecJumpVelocity;

		monster_jump_start();
		m_bJumping = true;
	}

	void mutant_jump_down()
	{
		Vector forward, up;

		g_EngineFuncs.AngleVectors( pev.angles, forward, void, up );
		pev.velocity = pev.velocity + forward * 100 + up * 300;
	}

	void mutant_jump_wait_land()
	{
		//g_Game.AlertMessage( at_notice, "mutant_jump_wait_land\n" );
		if( !monster_jump_finished() and !pev.FlagBitSet(FL_ONGROUND) ) //pev.groundentity == nullptr
			pev.framerate = 0.0; //self->monsterinfo.nextframe = self->s.frame;
		else
		{
			m_bJumping = false;
			pev.framerate = 1.0; //self->monsterinfo.nextframe = self->s.frame + 1;
		}
	}

	void mutant_step()
	{
		int iRand = Math.RandomLong( 0, 2 );
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_STEP1 + iRand], VOL_NORM, ATTN_NORM );
	}

	void mutant_hit_left()
	{
		if( m_bRerelease )
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE_RR, pev.mins.x, 8 );

			if( fire_hit(vecAim, Math.RandomFloat(5.0, 15.0), 100) ) //irandom(5, 15)
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT1], VOL_NORM, ATTN_NORM );
			else
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
				monsterinfo.melee_debounce_time = g_Engine.time + 1.5;
			}
		}
		else
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE, pev.mins.x, 8 );

			if( fire_hit(vecAim, 10 + Math.RandomFloat(0.0, 5.0), 100) ) //(10 + (rand() %5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT1], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
		}
	}

	void mutant_hit_right()
	{
		if( m_bRerelease )
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE_RR, pev.maxs.x, 8 );

			if( fire_hit(vecAim, Math.RandomFloat(5.0, 15.0), 100) ) //irandom(5, 15)
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT2], VOL_NORM, ATTN_NORM );
			else
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
				monsterinfo.melee_debounce_time = g_Engine.time + 1.5;
			}
		}
		else
		{
			Vector vecAim = Vector( Q2_MELEE_DISTANCE, pev.maxs.x, 8 );

			if( fire_hit(vecAim, 10 + Math.RandomFloat(0.0, 5.0), 100) ) //(10 + (rand() %5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT2], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
		}
	}

	void mutant_check_refire()
	{
		if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
		{
			if( m_bRerelease )
			{
				if( monsterinfo.melee_debounce_time <= g_Engine.time and (Math.RandomFloat(0.0, 1.0) < 0.5 or q2::range_to(self, self.m_hEnemy) <= Q2_RANGE_MELEE) )
					SetFrame( 7, 0 );
			}
			else
			{
				if( (q2npc::g_iDifficulty == q2::DIFF_NIGHTMARE and Math.RandomFloat(0.0, 1.0) < 0.5) or q2::range_to(self, self.m_hEnemy) <= Q2_RANGE_MELEE )
					SetFrame( 7, 0 );
			}
		}
	}

	void mutant_jump_takeoff()
	{
		Vector vecForward;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );

		g_EngineFuncs.AngleVectors( pev.angles, vecForward, void, void );
		g_EntityFuncs.SetOrigin( self, pev.origin + Vector(0, 0, 1) );
		pev.velocity = vecForward * (m_bRerelease ? 425 : 600);
		pev.velocity.z = m_bRerelease ? 320 : 410; //160 : 250;

		//pev.flags &= ~FL_ONGROUND; //@pev.groundentity = null;
		monsterinfo.aiflags |= q2::AI_DUCKED;
		monsterinfo.attack_finished = g_Engine.time + 3.0;
		m_bJumpAttack = true;
		SetTouch( TouchFunction(this.mutant_jump_touch) );
	}

	void mutant_check_landing()
	{
		if( m_bRerelease )
		{
			monster_jump_finished();

			if( pev.FlagBitSet(FL_ONGROUND) ) //if (self->groundentity)
			{
				m_bJumpAttack = false;
				pev.framerate = 1.0;

				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_THUD], VOL_NORM, ATTN_NORM );
				monsterinfo.attack_finished = g_Engine.time + Math.RandomFloat( 0.5, 1.5 );

				//if (self->monsterinfo.unduck)
					//self->monsterinfo.unduck(self);
				monster_duck_up();

				if( q2::range_to(self, self.m_hEnemy) <= Q2_RANGE_MELEE * 2.0 )
					self.ChangeSchedule( self.GetScheduleOfType(SCHED_MELEE_ATTACK1) ); //monsterinfo.melee(self);

				return;
			}

			if( g_Engine.time > monsterinfo.attack_finished )
			{
				SetFrame( 8, 1 ); //self->monsterinfo.nextframe = FRAME_attack02; //NEEDED ??
				pev.framerate = 1.0;
			}
			else
			{
				SetFrame( 8, 5 ); //4 //self->monsterinfo.nextframe = FRAME_attack05;
				pev.framerate = 0.0;
			}
		}
		else
		{
			if( pev.FlagBitSet(FL_ONGROUND) ) //if (self->groundentity)
			{
				m_bJumpAttack = false;
				pev.framerate = 1.0;

				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_THUD], VOL_NORM, ATTN_NORM );
				monsterinfo.attack_finished = 0;
				monsterinfo.aiflags &= ~q2::AI_DUCKED;
				return;
			}

			if( g_Engine.time > monsterinfo.attack_finished )
			{
				SetFrame( 8, 1 ); //self->monsterinfo.nextframe = FRAME_attack02; //NEEDED ??
				pev.framerate = 1.0;
			}
			else
			{
				SetFrame( 8, 5 ); //4 //self->monsterinfo.nextframe = FRAME_attack05;
				pev.framerate = 0.0;
			}
		}
	}

	void mutant_jump_touch( CBaseEntity @pOther )
	{
		if( pev.health <= 0 )
		{
			SetTouch( null );
			m_bJumpAttack = false;
			pev.framerate = 1.0;
			return;
		}

		if( m_bJumpAttack and pOther.pev.takedamage != DAMAGE_NO )
		{
			// [Paril-KEX] only if we're actually moving fast enough to hurt
			if( pev.velocity.Length() > 30 ) //400
			{
				Vector vecPoint;
				Vector vecNormal;
				float flDamage;

				vecNormal = pev.velocity.Normalize();
				vecPoint = pev.origin + ( vecNormal * pev.maxs.x );
				flDamage = Math.RandomFloat( 40.0, 50.0 );
				q2::T_Damage( pOther, self, self, pev.velocity, vecPoint, vecNormal, flDamage, flDamage, q2::DAMAGE_NONE, q2::MOD_UNKNOWN );
				m_bJumpAttack = false;
				pev.framerate = 1.0;
			}
		}

		if( !M_CheckBottom() )
		{
			if( pev.FlagBitSet(FL_ONGROUND) ) //if (self->groundentity)
			{
				SetFrame( 8, 1 ); //self->monsterinfo.nextframe = FRAME_attack02;
				SetTouch( null );
				m_bJumpAttack = false;
				pev.framerate = 1.0;
			}

			return;
		}

		SetTouch( null );
		m_bJumpAttack = false;
		pev.framerate = 1.0;
	}

	void MonsterSetSkin()
	{
		if( pev.health < (pev.max_health / 2) )
			pev.skin = 1;
		else
			pev.skin = 0;
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
				self.ChangeSchedule( slQ2Pain2 );
			}
		}
	}

	//nameOfMonster_dead
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

		q2::ThrowGib( self, 2, MODEL_GIB_BONE, pev.dmg, -1, 0 );
		q2::ThrowGib( self, 4, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, 24, BREAK_FLESH ); //right
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, 30, BREAK_FLESH ); //left
		q2::ThrowGib( self, 1, MODEL_GIB_HAND, pev.dmg, 8, BREAK_FLESH ); //right
		q2::ThrowGib( self, 1, MODEL_GIB_HAND, pev.dmg, 16, BREAK_FLESH ); //left
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH );
	}
}

array<ScriptSchedule@>@ mutant_schedules;

enum monsterScheds
{
	TASK_SCRATCH_LOOP = LAST_COMMON_TASK + 1
}

ScriptSchedule slMutantFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Mutant Idle Fidgeting"
);

ScriptSchedule slMutantJumpUp
(
	0,
	0,
	"Mutant Jump Up"
);

ScriptSchedule slMutantJumpDown
(
	0,
	0,
	"Mutant Jump Down"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slMutantFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slMutantFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) ); //fidget start
	slMutantFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_TWITCH)) ); //fidget loop
	slMutantFidget.AddTask( ScriptTask(TASK_SCRATCH_LOOP, 0) );
	slMutantFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL2)) ); //fidget end
	slMutantFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	slMutantJumpUp.AddTask( ScriptTask(TASK_STOP_MOVING) );
	//slMutantJumpUp.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_LEAP)) );
	slMutantJumpUp.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_LEAP)) );

	slMutantJumpDown.AddTask( ScriptTask(TASK_STOP_MOVING) );
	//slMutantJumpDown.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_HOP)) );
	slMutantJumpDown.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_HOP)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3, slMutantFidget, slMutantJumpUp, slMutantJumpDown };

	@mutant_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2mutant::npc_q2mutant", "npc_q2mutant" );
	g_Game.PrecacheOther( "npc_q2mutant" );
}

} //end of namespace npc_q2mutant
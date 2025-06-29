namespace npc_q2gunner
{

const string NPC_MODEL				= "models/quake2/monsters/gunner/gunner.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/gunner/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/gunner/gibs/foot.mdl";
const string MODEL_GIB_GARM		= "models/quake2/monsters/gunner/gibs/garm.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/gunner/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/gunner/gibs/head.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 60 ); //88 in svencoop
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 175.0;

const int AE_GRENADE					= 11;
const int AE_CHAINGUN_OPEN		= 12;
const int AE_CHAINGUN_FIRE			= 13;
const int AE_FIDGETCHECK				= 14;
const int AE_REFIRE						= 15;

const float GUN_DAMAGE				= 3.0;

const float GRENADE_DMG				= 50;
const float GRENADE_SPEED			= 600;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/gunner/gunidle1.wav",
	"quake2/npcs/gunner/sight1.wav",
	"quake2/npcs/gunner/gunsrch1.wav",
	"quake2/npcs/gunner/gunatck1.wav",
	"quake2/npcs/gunner/gunatck2.wav",
	"quake2/npcs/gunner/gunatck3.wav",
	"quake2/npcs/gunner/gunpain1.wav",
	"quake2/npcs/gunner/gunpain2.wav",
	"quake2/npcs/gunner/death1.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_CHAINGUN_OPEN,
	SND_CHAINGUN_FIRE,
	SND_GRENADE,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH
};

const array<string> arrsNPCAnims =
{
	"attack_chaingun_start",
	"pain1",
	"pain2",
	"pain3"
};

enum anim_e
{
	ANIM_CGUN_START = 0,
	ANIM_PAIN1,
	ANIM_PAIN2,
	ANIM_PAIN3
};

final class npc_q2gunner : CBaseQ2NPC
{
	private float m_flGrenadeCooldown;

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
			self.m_FormattedName	= "Gunner";

		m_flGibHealth = -70.0;
		SetMass( 200 );

		@this.m_Schedules = @gunner_schedules;

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
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GARM );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
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

		return CLASS_ALIEN_MILITARY;
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

	//attacks are handled in GetScheduleOfType
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }
	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }
	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }

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
			case TASK_CGUN_LOOP:
			{
				if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 or !self.FVisible(self.m_hEnemy, true) or Math.RandomFloat(0.0, 1.0) > 0.5 )
					self.TaskComplete();

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
			case TASK_PLAY_SEQUENCE:
			{
				if( GetAnim(ANIM_CGUN_START) )
				{
					self.MakeIdealYaw( self.m_vecEnemyLKP );
					self.ChangeYaw( int(pev.yaw_speed) );
				}

				BaseClass.RunTask( pTask );

				break;
			}

			case TASK_CGUN_LOOP:
			{
				self.MakeIdealYaw( self.m_vecEnemyLKP );
				self.ChangeYaw( int(pev.yaw_speed) );

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
			case SCHED_RANGE_ATTACK1:
			{
				//TESTING
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 );
				//return slGunnerChaingun; //BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 )

				if( m_bRerelease )
				{
					Vector vecMuzzle;
					self.GetAttachment( 2, vecMuzzle, void );

					float flDist = (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();

					// PGM - gunner needs to use his chaingun if he's being attacked by a tesla.
					if( m_flGrenadeCooldown > g_Engine.time or (flDist <= Q2_RANGE_NEAR * 0.35 and M_CheckClearShot(vecMuzzle)) ) //self->bad_area or
						return slGunnerChaingun;
					else
					{
						if( m_flGrenadeCooldown <= g_Engine.time and Math.RandomFloat(0.0, 1.0) <= 0.5 and gunner_grenade_check() )
						{
							m_flGrenadeCooldown = g_Engine.time + Math.RandomFloat( 2.0, 3.0 );
							return Math.RandomLong(0, 1) == 1 ? BaseClass.GetScheduleOfType(SCHED_RANGE_ATTACK2) : BaseClass.GetScheduleOfType(SCHED_RANGE_ATTACK1);
						}
						else if( M_CheckClearShot(vecMuzzle) )
							return slGunnerChaingun;
					}
				}
				else
				{
					float flDist = (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();

					if( flDist <= Q2_RANGE_MELEE )
						return slGunnerChaingun;
					else
					{
						if( Math.RandomFloat(0.0, 1.0) <= 0.5 )
							return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 );
						else
							return slGunnerChaingun;
					}
				}
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_IDLESOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );

				break;
			}

			//I SURE WISH THE DEVS WOULD HAVE USED ONLY ONE WAY OF DETERMINING WHEN TO FIDGET :aRage:
			case AE_FIDGETCHECK:
			{
				gunner_fidget();
				break;
			}

			case AE_GRENADE:
			{
				GunnerGrenade( atoi(pEvent.options()) );
				break;
			}

			case AE_CHAINGUN_OPEN:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_CHAINGUN_OPEN], VOL_NORM, ATTN_IDLE );
				break;
			}

			case AE_CHAINGUN_FIRE:
			{
				GunnerFire();
				break;
			}

			case AE_REFIRE:
			{
				if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 or !self.FVisible(self.m_hEnemy, true) or Math.RandomFloat(0.0, 1.0) > 0.5 )
					self.TaskComplete();

				break;
			}
		}
	}

	void gunner_fidget()
	{
		if( !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) )
		{
			/*if( HasFlags(monsterinfo.aiflags, AI_STAND_GROUND) )
				return;
			else */if( self.m_hEnemy.IsValid() )
				return;

			if( Math.RandomFloat(0.0, 1.0) <= 0.05 )
				self.ChangeSchedule( slGunnerFidget );
		}
	}

	bool gunner_grenade_check()
	{
		Vector vecDir;

		if( !self.m_hEnemy.IsValid() )
			return false;

		Vector vecMuzzle;
		self.GetAttachment( 0, vecMuzzle, void );
		if( !M_CheckClearShot(vecMuzzle) )
			return false;

		Vector vecTarget;

		// check for flag telling us that we're blindfiring
		//if (self->monsterinfo.aiflags & AI_MANUAL_STEERING)
			//vecTarget = self.m_vecEnemyLKP; //self->monsterinfo.blind_fire_target;
		//else
			vecTarget = self.m_hEnemy.GetEntity().pev.origin;

		vecDir = (vecTarget - vecMuzzle);

		if( vecDir.Length() < 100 )
			return false;

		// check to see that we can trace to the player before we start
		// tossing grenades around.
		Vector vecAim = vecDir.Normalize();

		return M_CalculatePitchToFire( vecTarget, vecMuzzle, vecAim, 600, 2.5, false );
	}

	//THANK YOU FOR FIXING THIS, CHATGPT
	void GunnerGrenade( int iFrame )
	{
		Vector vecMuzzle, vecAim;
		self.GetAttachment( 0, vecMuzzle, void );

		if( m_bRerelease )
		{
			Vector vecTarget;
			float flSpread, flPitch = 0.0;
			//bool bBlindfire = false;

			if( !self.m_hEnemy.IsValid() )
				return;

			//if (self->monsterinfo.aiflags & AI_MANUAL_STEERING)
				//bBlindfire = true;

			if( iFrame == 4 )
				flSpread = -0.10;
			else if( iFrame == 7 )
				flSpread = -0.05;
			else if( iFrame == 10 )
				flSpread = 0.05;
			else
			{
				//self->monsterinfo.aiflags &= ~AI_MANUAL_STEERING;
				flSpread = 0.10;
			}

			/*if( bBlindfire and !self.FVisible(self.m_hEnemy, true) )
			{
				//if (!self->monsterinfo.blind_fire_target)
				if( self.m_vecEnemyLKP == g_vecZero )
					return;

				vecTarget = self.m_vecEnemyLKP;
			}
			else*/
				vecTarget = self.m_hEnemy.GetEntity().pev.origin;

			Vector vecToTarget = vecTarget - pev.origin;
			float flDist = vecToTarget.Length();

			//aim up if they're on the same level as me and far away.
			if( flDist > 512.0 and vecToTarget.z < 64.0 and vecToTarget.z > -64.0 )
				vecToTarget.z += ( flDist - 512.0 );

			vecToTarget = vecToTarget.Normalize();

			flPitch = vecToTarget.z;
			if( flPitch > 0.4 )
				flPitch = 0.4;
			else if( flPitch < -0.5 )
				flPitch = -0.5;

			Math.MakeVectors( pev.angles );
			vecAim = g_Engine.v_forward + (g_Engine.v_right * flSpread) + (g_Engine.v_up * flPitch);

			//try search for best pitch
			if( M_CalculatePitchToFire(vecTarget, vecMuzzle, vecAim, 600, 2.5, false) )
				monster_fire_weapon( q2::WEAPON_GRENADE, vecMuzzle, vecAim, GRENADE_DMG, GRENADE_SPEED, q2::crandom_open() * 10.0, Math.RandomFloat(0.0, 1.0) * 10.0 );
			else
			{
				//normal shot
				Math.MakeVectors( pev.angles );
				vecAim = g_Engine.v_forward;
				monster_fire_weapon( q2::WEAPON_GRENADE, vecMuzzle, vecAim, GRENADE_DMG, GRENADE_SPEED, q2::crandom_open() * 10.0, 200.0 + (q2::crandom_open() * 10.0) );
			}
		}
		else
		{
			Math.MakeVectors( pev.angles );
			vecAim = g_Engine.v_forward;
			monster_fire_weapon( q2::WEAPON_GRENADE, vecMuzzle, vecAim, GRENADE_DMG, GRENADE_SPEED );
		}

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_GRENADE], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		monster_muzzleflash( vecMuzzle, 255, 128, 0, 10 );
	}

	void GunnerFire()
	{
		Vector vecMuzzle, vecAim;
		self.GetAttachment( 2, vecMuzzle, void );

		if( self.m_hEnemy.IsValid() )
		{
			//project enemy back a bit and target there
			PredictAim( self.m_hEnemy, vecMuzzle, 0, true, -0.2, vecAim, void );
		}
		else
		{
			Vector vecBonePos;

			g_EngineFuncs.GetBonePosition( self.edict(), 7, vecBonePos, void );
			self.GetAttachment( 2, vecMuzzle, void );
			vecAim = (vecMuzzle - vecBonePos).Normalize();
		}

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_CHAINGUN_FIRE], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		MachineGunEffects( vecMuzzle, 3 );
		monster_muzzleflash( vecMuzzle, 255, 255, 0, 10 );
		monster_fire_weapon( q2::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
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

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_PAIN1, SND_PAIN2)], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( flDamage <= 10 )
			self.ChangeSchedule( slQ2Pain3 );
		else if( flDamage <= 25 )
			self.ChangeSchedule( slQ2Pain2 );
		else
			self.ChangeSchedule( slQ2Pain1 );
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

		q2::ThrowGib( self, 2, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 6, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_GARM, pev.dmg, 19, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, pev.dmg, 9 );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, Math.RandomLong(0, 1) == 0 ? 4 : 25, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 7, BREAK_FLESH );
	}
}

array<ScriptSchedule@>@ gunner_schedules;

enum monsterScheds
{
	TASK_CGUN_LOOP = LAST_COMMON_TASK + 1
}

ScriptSchedule slGunnerFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Gunner Idle Fidgeting"
);

ScriptSchedule slGunnerChaingun
(
	bits_COND_ENEMY_DEAD,
	0,
	"Gunner Chain Gun"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slGunnerFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slGunnerFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_TWITCH)) );
	slGunnerFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	slGunnerChaingun.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slGunnerChaingun.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	slGunnerChaingun.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) ); //cgun start

	if( q2npc::g_bRerelease )
		slGunnerChaingun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_MELEE_ATTACK2)) ); //cgun loop with muzzleflash
	else
		slGunnerChaingun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_MELEE_ATTACK1)) ); //cgun loop

	slGunnerChaingun.AddTask( ScriptTask(TASK_CGUN_LOOP, 0) );
	slGunnerChaingun.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL2)) ); //cgun end
	slGunnerChaingun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3, slGunnerFidget, slGunnerChaingun };

	@gunner_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "grenade" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2gunner::npc_q2gunner", "npc_q2gunner" );
	g_Game.PrecacheOther( "npc_q2gunner" );
}

} //end of namespace npc_q2gunner

/* FIXME
	The chaingun shooting animation needs fixing , it looks too wobbly
*/

/* TODO
	Remove head at some point ??
*/
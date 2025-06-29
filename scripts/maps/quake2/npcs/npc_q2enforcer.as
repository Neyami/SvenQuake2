namespace npc_q2enforcer
{

const string NPC_MODEL				= "models/quake2/monsters/enforcer/enforcer.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/enforcer/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/enforcer/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/enforcer/gibs/foot.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/enforcer/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/enforcer/gibs/head.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 56 ); //80 in svencoop
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 100;

const int AE_MELEEATTACK				= 11;
const int AE_DECAPITATE				= 12;
const int AE_DEATHSHOT				= 13;
const int AE_SHOOTGUN					= 14;
const int AE_MELEESWING				= 15;

const float GUN_DAMAGE				= 3.0;
const Vector GUN_SPREAD				= VECTOR_CONE_3DEGREES;

const float MELEE_DMG_MIN			= 5.0;
const float MELEE_DMG_MAX			= 10.0;
const float MELEE_KICK					= 50.0;
const float MELEE_CD						= 1.5;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/enforcer/infidle1.wav",
	"quake2/npcs/enforcer/infsght1.wav",
	"quake2/npcs/enforcer/infsrch1.wav",
	"quake2/npcs/enforcer/infatck1.wav",
	"quake2/npcs/enforcer/infatck2.wav",
	"quake2/npcs/enforcer/melee2.wav",
	"quake2/npcs/enforcer/infatck3.wav",
	"quake2/npcs/enforcer/infpain1.wav",
	"quake2/npcs/enforcer/infpain2.wav",
	"quake2/npcs/enforcer/infdeth1.wav",
	"quake2/npcs/enforcer/infdeth2.wav",
	"quake2/npcs/enforcer/inflies1.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_SHOOT,
	SND_MELEE,
	SND_MELEE_HIT,
	SND_PAIN1,
	SND_PAIN2,
	SND_FLIES
};

final class npc_q2enforcer : CBaseQ2NPC
{
	private float m_flStopShooting;

	void MonsterSpawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		if( pev.health <= 0 )
			pev.health						= NPC_HEALTH * m_flHealthMultiplier;

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= -0.30;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Enforcer";

		m_flGibHealth = -65.0;
		SetMass( 200 );
		monsterinfo.aiflags |= q2::AI_STINKY;

		@this.m_Schedules = @enforcer_schedules;

		self.MonsterInit();
	}

	void Precache()
	{
		uint i;

		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_ARM );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );

		for( i = 0; i < arrsNPCSounds.length(); ++i )
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

	void MonsterIdle()
	{
		if( self.m_hEnemy.IsValid() )
			return;

		self.ChangeSchedule( slEnforcerFidget );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_MELEESWING:
			{
				infantry_swing();
				break;
			}

			case AE_MELEEATTACK:
			{
				infantry_smack();
				break;
			}

			case AE_SHOOTGUN:
			{
				infantry_fire();

				break;
			}

			case AE_DEATHSHOT:
			{
				InfantryMachineGun();

				break;
			}

			case AE_DECAPITATE:
			{
				pev.body = 1; //headless

				if( Math.RandomFloat(0.0, 1.0) <= 0.45 ) //0.25 original
				{
					CGib@ pGib = g_EntityFuncs.CreateGib( pev.origin + Vector(0, 0, NPC_MAXS.z), g_vecZero );
					pGib.Spawn( MODEL_GIB_HEAD );

					pGib.pev.velocity = q2::VelocityForDamage( 200 );

					pGib.pev.velocity.x += Math.RandomFloat( -0.15, 0.15 );
					pGib.pev.velocity.y += Math.RandomFloat( -0.25, 0.15 );
					pGib.pev.velocity.z += Math.RandomFloat( -0.2, 1.9 );

					pGib.pev.avelocity.x = Math.RandomFloat( 70, 200 );
					pGib.pev.avelocity.y = Math.RandomFloat( 70, 200 );

					pGib.LimitVelocity();

					pGib.m_bloodColor = BLOOD_COLOR_RED;
					pGib.m_cBloodDecals = 5;
					pGib.m_material = matFlesh;

					g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
				}

				break;
			}
		}
	}

	void infantry_swing()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE], VOL_NORM, ATTN_NORM );
	}

	void infantry_smack()
	{
		if( m_bRerelease )
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE_RR, 0, 0 );

			if( fire_hit(aim, Math.RandomFloat(5.0, 10.0), 50) )
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
			else
				monsterinfo.melee_debounce_time = g_Engine.time + 1.5;
		}
		else
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE, 0, 0 );

			if( fire_hit(aim, 5 + Math.RandomFloat(0.0, 5.0), 50) ) //(5 + (rand() % 5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
		}
	}

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) )
		{
			m_flStopShooting = 0.0;

			return true;
		}

		return false;
	}

	void M_FliesOff()
	{
		m_iEffects &= ~q2::EF_FLIES;
		g_SoundSystem.StopSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_FLIES] );
	}

	void M_FliesOn()
	{
		if( pev.waterlevel > WATERLEVEL_DRY )
			return;

		m_iEffects |= q2::EF_FLIES;
		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsNPCSounds[SND_FLIES], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP );
		SetThink( ThinkFunction(this.M_FliesOff) );
		pev.nextthink = g_Engine.time + 60.0;
	}

	void M_FlyCheck()
	{
		if( pev.waterlevel > WATERLEVEL_DRY )
			return;

		//if( Math.RandomFloat(0.0, 1.0) > 0.5 )
			//return;

		SetThink( ThinkFunction(this.M_FliesOn) );
		pev.nextthink = g_Engine.time + 5 + 10 * Math.RandomLong( 0, 1 );
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

		int iRand = Math.RandomLong( 0, 1 );

		if( iRand == 0 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( iRand == 0 )
			self.ChangeSchedule( slQ2Pain1 );
		else
			self.ChangeSchedule( slQ2Pain2 );
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

			M_FlyCheck();
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
		M_FliesOff();
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		q2::ThrowGib( self, 1, MODEL_GIB_BONE, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 5, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, pev.dmg, 9 );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, 4, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, 17, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_ARM, pev.dmg, 8, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_ARM, pev.dmg, 12, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 6, BREAK_FLESH );
	}

	void infantry_fire()
	{
		if( m_flStopShooting <= 0.0 )
			m_flStopShooting = g_Engine.time + Math.RandomFloat( 0.7, 2.0 );

		InfantryMachineGun();

		if( g_Engine.time < m_flStopShooting )
			SetFrame( 15, 9 );
	}

	void InfantryMachineGun()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecMuzzle, vecAim;

		if( self.m_hEnemy.IsValid() and pev.deadflag == DEAD_NO )
		{
			self.GetAttachment( 0, vecMuzzle, void );
			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
		}
		else
		{
			Vector vecBonePos;

			g_EngineFuncs.GetBonePosition( self.edict(), 9, vecBonePos, void );
			self.GetAttachment( 1, vecMuzzle, void );
			vecAim = (vecMuzzle - vecBonePos).Normalize();
		}

		MachineGunEffects( vecMuzzle, 3 );

		monster_fire_weapon( q2::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
	}

	void UpdateOnRemove()
	{
		M_FliesOff();
		BaseClass.UpdateOnRemove();
	}
}

array<ScriptSchedule@>@ enforcer_schedules;

ScriptSchedule slEnforcerFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Enforcer Idle Fidgeting"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slEnforcerFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slEnforcerFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_TWITCH)) );
	slEnforcerFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slEnforcerFidget };

	@enforcer_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2enforcer::npc_q2enforcer", "npc_q2enforcer" );
	g_Game.PrecacheOther( "npc_q2enforcer" );
}

} //end of namespace npc_q2enforcer

/* FIXME
	Fix the machinegun by using RunTask
*/

/* TODO
	Add newer attacks
	Update attack selection
*/
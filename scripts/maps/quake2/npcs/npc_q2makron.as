namespace npc_q2makron
{

const string NPC_MODEL				= "models/quake2/monsters/makron/makron.mdl";

const Vector NPC_MINS					= Vector( -32, -32, 0 );
const Vector NPC_MAXS					= Vector( 32, 32, 128 ); //90 in quake 2

const int NPC_HEALTH					= 3000;

const int AE_STEP_LEFT					= 11;
const int AE_STEP_RIGHT				= 12;
const int AE_BFG							= 13;
const int AE_BLASTER					= 14;
const int AE_RAILGUN_PRE				= 15;
const int AE_RAILGUN_SAVELOC		= 16;
const int AE_RAILGUN_FIRE			= 17;
const int AE_POPUP						= 18;
const int AE_TAUNT						= 19;
const int AE_FALL							= 20;
const int AE_BRAINSPLORCH			= 21;

const float BLASTER_DAMAGE			= 15.0;
const float BLASTER_SPEED			= 1000.0;

const float RAILGUN_DAMAGE			= 50.0;

const float BFG_DAMAGE				= 50.0;
const float BFG_SPEED					= 300.0;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/makron/bfg_fire.wav",
	"quake2/npcs/makron/blaster.wav",
	"quake2/npcs/makron/rail_up.wav",
	"quake2/weapons/railgf1a.wav",
	"quake2/npcs/makron/step1.wav",
	"quake2/npcs/makron/step2.wav",
	"quake2/npcs/makron/voice4.wav",
	"quake2/npcs/makron/voice3.wav",
	"quake2/npcs/makron/voice.wav",
	"quake2/npcs/makron/popup.wav",
	"quake2/npcs/makron/pain3.wav",
	"quake2/npcs/makron/pain2.wav",
	"quake2/npcs/makron/pain1.wav",
	"quake2/npcs/makron/death.wav",
	"quake2/npcs/makron/bhit.wav",
	"quake2/npcs/makron/brain1.wav",
	"quake2/npcs/makron/spine.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_ATK_BFG,
	SND_ATK_BLASTER,
	SND_ATK_RAILGUN1,
	SND_ATK_RAILGUN2,
	SND_STEP_LEFT,
	SND_STEP_RIGHT,
	SND_TAUNT1,
	SND_TAUNT2,
	SND_TAUNT3,
	SND_POPUP,
	SND_PAIN4,
	SND_PAIN5,
	SND_PAIN6,
	SND_DEATH,
	SND_FALL,
	SND_BRAINSPLORCH,
	SND_SPINE
};

const array<string> arrsNPCAnims =
{
	"activate"
};

enum anim_e
{
	ANIM_ACTIVATE = 0
};

enum attach_e
{
	ATTACH_BFG = 0,
	ATTACH_BLASTER,
	ATTACH_RAILGUN
};

final class npc_q2makron : CBaseQ2NPC
{
	private Vector m_vecRailgunTarget;

	void Spawn()
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
			self.m_FormattedName	= "Makron";

		m_flGibHealth = -2000.0;

		CommonSpawn();

		@this.m_Schedules = @makron_schedules;

		self.MonsterInit();

		if( self.IsPlayerAlly() )
			SetUse( UseFunction(this.FollowerUse) );

		if( pev.weapons == 4269 )
		{
			self.ChangeSchedule( slMakronActivate );
			self.SetState( MONSTERSTATE_SCRIPT );
		}
	}

	void AppendAnims()
	{
		for( uint i = 0; i < arrsNPCAnims.length(); i++ )
			arrsQ2NPCAnims.insertLast( arrsNPCAnims[i] );
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );

		for( uint i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
	}

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
	}

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys = 120;

		switch( self.m_Activity )
		{
			case	ACT_RANGE_ATTACK2:
			case	ACT_MELEE_ATTACK1:
			{
				ys = 0;
				break;
			}
		}

		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	//attacks are handled in GetScheduleOfType
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }
	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		//DESPERATION MOVE >:D
		if( q2npc::g_iDifficulty >= q2npc::DIFF_NIGHTMARE )
		{
			if( pev.health < (pev.max_health * 0.1) )
			{
				m_iWeaponType = q2npc::WEAPON_BFG;
				m_iWeaponType |= 2048;
			}
		}

		if( M_CheckAttack(flDist) )
			return true;

		return false;
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_PLAY_SEQUENCE:
			{
				if( pev.weapons == 4269 )
				{
					if( self.m_hEnemy.IsValid() )
					{
						Vector vecDir = ( self.m_hEnemy.GetEntity().pev.origin - pev.origin );

						pev.angles.y = Math.VecToYaw( vecDir );

						vecDir = vecDir.Normalize();
						pev.velocity = vecDir * 400;
						pev.velocity.z = 200;
					}

					pev.weapons = 0;
				}

				BaseClass.StartTask( pTask );

				break;
			}

			default:
			{			
				BaseClass.StartTask( pTask );
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
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //railgun
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //bfg
				//return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //hyperblaster

				float flRand = Math.RandomFloat( 0.0, 1.0 );

				if( flRand <= 0.3 )
					return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //bfg
				else if( flRand <= 0.6 )
					return BaseClass.GetScheduleOfType( SCHED_MELEE_ATTACK1 ); //hyperblaster
				else
					return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //railgun
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_STEP_LEFT:
			{
				makron_step_left();
				break;
			}

			case AE_STEP_RIGHT:
			{
				makron_step_right();
				break;
			}

			case AE_BFG:
			{
				makronBFG();
				break;
			}

			case AE_BLASTER:
			{
				MakronHyperblaster();
				break;
			}

			case AE_RAILGUN_PRE:
			{
				makron_prerailgun();
				break;
			}

			case AE_RAILGUN_SAVELOC:
			{
				MakronSaveloc();
				break;
			}

			case AE_RAILGUN_FIRE:
			{
				MakronRailgun();
				break;
			}

			case AE_POPUP:
			{
				makron_popup();
				break;
			}

			case AE_TAUNT:
			{
				makron_taunt();
				break;
			}

			case AE_FALL:
			{
				makron_hit();
				break;
			}

			case AE_BRAINSPLORCH:
			{
				makron_brainsplorch();
				break;
			}
		}
	}

	void makron_step_left()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void makron_step_right()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
	}

	void makron_popup()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_POPUP], VOL_NORM, ATTN_NONE );
	}

	void makron_taunt()
	{
		float flRand = Math.RandomFloat( 0.0, 1.0 );

		if( flRand <= 0.3 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_TAUNT1], VOL_NORM, ATTN_NONE );
		else if( flRand <= 0.6 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_TAUNT2], VOL_NORM, ATTN_NONE );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_TAUNT3], VOL_NORM, ATTN_NONE );
	}

	void makron_hit()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_FALL], VOL_NORM, ATTN_NONE );
	}

	void makron_brainsplorch()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_BRAINSPLORCH], VOL_NORM, ATTN_NORM );
	}

	void makron_prerailgun()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_RAILGUN1], VOL_NORM, ATTN_NORM );
	}

	void MakronSaveloc()
	{
		if( self.m_hEnemy.IsValid() )
		{
			m_vecRailgunTarget = self.m_hEnemy.GetEntity().pev.origin;
			m_vecRailgunTarget.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
		}
	}

	void MakronRailgun()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_RAILGUN2], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

		Vector vecMuzzle, vecAim;
		self.GetAttachment( ATTACH_RAILGUN, vecMuzzle, void );
		vecAim = (m_vecRailgunTarget - vecMuzzle);
		vecAim = vecAim.Normalize();

		monster_muzzleflash( vecMuzzle, 128, 128, 255 );
		monster_fire_weapon( q2npc::WEAPON_RAILGUN, vecMuzzle, vecAim, RAILGUN_DAMAGE );
	}

	void makronBFG()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_ATK_BFG], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecMuzzle, vecAim;
		self.GetAttachment( ATTACH_BFG, vecMuzzle, void );

		Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
		vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
		vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();

		monster_muzzleflash( vecMuzzle, 128, 255, 128, 30 );
		monster_fire_weapon( q2npc::WEAPON_BFG, vecMuzzle, vecAim, BFG_DAMAGE, BFG_SPEED );
	}

	void MakronHyperblaster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_BLASTER], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecMuzzle, vecAim;
		self.GetAttachment( ATTACH_BLASTER, vecMuzzle, void );

		Vector vecBonePos;
		g_EngineFuncs.GetBonePosition( self.edict(), 5, vecBonePos, void );

		vecAim = (vecMuzzle - vecBonePos).Normalize();

		if( self.m_hEnemy.IsValid() )
		{
			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;

			Vector vecToEnemy = (vecEnemyOrigin - vecMuzzle).Normalize();

			//Replace only the pitch (x angle) in vecAim (Thanks ChatGPT!)
			vecAim = Math.VecToAngles( vecAim );
			vecAim.x = -Math.VecToAngles( vecToEnemy ).x;
			Math.MakeVectors( vecAim );
			vecAim = g_Engine.v_forward;
		}

		monster_muzzleflash( vecMuzzle, 20, 255, 255, 0 );
		monster_fire_weapon( q2npc::WEAPON_BLASTER, vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
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
			HandlePain( flDamage , pevInflictor.classname );

		//don't send Makron flying unless the damage is very high (nukes?)
		if( flDamage < 500 )
			bitsDamageType &= ~DMG_BLAST|DMG_LAUNCH;

		bitsDamageType &= ~DMG_ALWAYSGIB;
		bitsDamageType |= DMG_NEVERGIB;

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage, string sWeaponName )
	{
		if( g_Engine.time < m_flPainDebounceTime )
			return;

		if( sWeaponName != "weapon_q2chainfist" and flDamage <= 25 )
		{
			if( Math.RandomFloat(0.0, 1.0) < 0.2 )
				return;
		}

		m_flPainDebounceTime = g_Engine.time + 3.0;

		if( m_bRerelease )
		{
			bool bDoPain6 = false;

			if( flDamage <= 40 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN4], VOL_NORM, ATTN_NONE );
			else if( flDamage <= 110 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN5], VOL_NORM, ATTN_NONE );
			else
			{
				if( flDamage <= 150 )
				{
					if( Math.RandomFloat(0.0, 1.0) <= 0.45 )
					{
						bDoPain6 = true;
						g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
					}
				}
				else
				{
					if( Math.RandomFloat(0.0, 1.0) <= 0.35 )
					{
						bDoPain6 = true;
						g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
					}
				}
			}

			if( !M_ShouldReactToPain() )
				return;

			if( flDamage <= 40 )
				self.ChangeSchedule( slQ2Pain1 );
			else if( flDamage <= 110 )
				self.ChangeSchedule( slQ2Pain2 );
			else if( bDoPain6 )
				self.ChangeSchedule( slQ2Pain3 );
		}
		else
		{
			if( !M_ShouldReactToPain() )
				return;

			if( flDamage <= 40 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN4], VOL_NORM, ATTN_NONE );
				self.ChangeSchedule( slQ2Pain1 );
			}
			else if( flDamage <= 110 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN5], VOL_NORM, ATTN_NONE );
				self.ChangeSchedule( slQ2Pain2 );
			}
			else
			{
				if( flDamage <= 150 )
				{
					if( Math.RandomFloat(0.0, 1.0) <= 0.45 )
					{
						g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
						self.ChangeSchedule( slQ2Pain3 );
					}
				}
				else
				{
					if( Math.RandomFloat(0.0, 1.0) <= 0.35 )
					{
						g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN6], VOL_NORM, ATTN_NONE );
						self.ChangeSchedule( slQ2Pain3 );
					}
				}
			}
		}
	}

	bool ShouldGibMonster( int iGib ) { return false; }

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		//prevent spawning more than 1 torso
		if( pev.body != 1 )
			makron_spawn_torso();

		pev.body = 1;
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, Vector(32, 32, 88) );
		BaseClass.Killed( pevAttacker, GIB_NEVER );
	}

	void makron_spawn_torso()
	{
		Math.MakeVectors( pev.angles );
		Vector vecOrigin = pev.origin;
		vecOrigin.z += (pev.size.z - 30);

		CBaseEntity@ pTorso = g_EntityFuncs.Create( "q2makron_torso", vecOrigin + g_Engine.v_forward * -20, Vector(0, pev.angles.y, 0), false, self.edict() );
		pTorso.pev.velocity = g_Engine.v_forward * -120 + g_Engine.v_up * 120;
	}
}

class q2makron_torso : ScriptBaseAnimating
{
	private float m_flRemoveTime;

	void Spawn()
	{
		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, g_vecZero, g_vecZero );
		g_EntityFuncs.SetOrigin( self, pev.origin );

		pev.sequence = self.LookupSequence( "death3" );
		pev.frame = 0;
		self.ResetSequenceInfo();

		pev.solid = SOLID_NOT;
		pev.movetype = MOVETYPE_TOSS;
		pev.takedamage = DAMAGE_NO;
		pev.body = 2;
		pev.skin = 1;
		pev.angles.x = 90;
		pev.avelocity = g_vecZero;

		m_flRemoveTime = g_Engine.time + 60.0; //just in case. pev.owner can be not null even if it's gone :eyeroll:

		SetThink( ThinkFunction(this.TorsoThink) );
		pev.nextthink = g_Engine.time;

		g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SPINE], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP );
	}

	void TorsoThink()
	{
		pev.nextthink = g_Engine.time + 0.1;

		if( pev.owner is null or (pev.rendermode == kRenderTransTexture and pev.renderamt <= 0) )
			SUB_Remove();

		pev.rendermode = pev.owner.vars.rendermode;
		pev.renderamt = pev.owner.vars.renderamt;

		self.StudioFrameAdvance();

		if( pev.angles.x > 0 )
			pev.angles.x = Math.max( 0.0, pev.angles.x - 15 );

		if( m_flRemoveTime < g_Engine.time )
		{
			SetThink( ThinkFunction(this.SUB_Remove) );
			pev.nextthink = g_Engine.time;
		}
	}

	void SUB_Remove()
	{
		UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}

	void UpdateOnRemove()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SPINE] );
		BaseClass.UpdateOnRemove();
	}
}

array<ScriptSchedule@>@ makron_schedules;

ScriptSchedule slMakronActivate
(
	0,
	0,
	"Makron Activate"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slMakronActivate.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slMakronActivate.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3, slMakronActivate };

	@makron_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "laser" );
	q2projectiles::RegisterProjectile( "railbeam" );
	q2projectiles::RegisterProjectile( "bfg" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2makron::q2makron_torso", "q2makron_torso" );
	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2makron::npc_q2makron", "npc_q2makron" );
	g_Game.PrecacheOther( "npc_q2makron" );
}

} //end of namespace npc_q2makron

/* FIXME
*/

/* TODO
*/
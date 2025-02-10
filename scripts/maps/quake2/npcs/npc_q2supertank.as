namespace npc_q2supertank
{

const string NPC_MODEL				= "models/quake2/monsters/supertank/supertank.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_metal.mdl";
const string MODEL_GIB_CGUN		= "models/quake2/monsters/supertank/gibs/cgun.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/supertank/gibs/chest.mdl";
const string MODEL_GIB_CORE		= "models/quake2/monsters/supertank/gibs/core.mdl";
const string MODEL_GIB_LTREAD	= "models/quake2/monsters/supertank/gibs/ltread.mdl";
const string MODEL_GIB_RTREAD	= "models/quake2/monsters/supertank/gibs/rtread.mdl";
const string MODEL_GIB_RGUN		= "models/quake2/monsters/supertank/gibs/rgun.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/supertank/gibs/tube.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/supertank/gibs/head.mdl";

const Vector NPC_MINS					= Vector( -80, -80, 0 );
const Vector NPC_MAXS					= Vector( 80, 80, 142 ); //112 in quake 2

const int NPC_HEALTH					= 1500;

const int AE_TREADSOUND				= 11;
const int AE_CHAINGUN					= 12;
const int AE_GRENADE					= 13;
const int AE_ROCKET						= 14;
const int AE_DEATH						= 15;

const float GUN_DAMAGE				= 6.0;

const float GRENADE_DMG				= 50;

const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 750;

const float ROCKET_DMG_HEAT		= 40;
const float ROCKET_SPEED_HEAT	= 500.0;
const float ROCKET_HEATSEEKING	= 0.075; //turn-rate, higher number means better heatseeking

const int SPAWNFLAG_SUPERTANK_POWERSHIELD = 8;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/supertank/btkunqv1.wav",
	"quake2/npcs/supertank/btkunqv2.wav",
	"quake2/npcs/supertank/btkengn1.wav",
	"quake2/npcs/infantry/infatck1.wav", //machine gun
	"quake2/weapons/grenlf1a.wav", //grenade launcher
	"quake2/npcs/tank/rocket.wav", //rocket launcher
	"quake2/weapons/rocklx1a.wav",
	"quake2/npcs/supertank/btkpain1.wav",
	"quake2/npcs/supertank/btkpain2.wav",
	"quake2/npcs/supertank/btkpain3.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_SEARCH1,
	SND_SEARCH2,
	SND_TREAD,
	SND_CHAINGUN,
	SND_GRENADE,
	SND_ROCKET,
	SND_EXPLOSION,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3
};

const array<string> arrsNPCAnims =
{
	"attack_rocket"
};

enum anim_e
{
	ANIM_ROCKET = 0
};

enum attach_e
{
	ATTACH_CG_MUZZLE = 0,
	ATTACH_ROCKET_MIDDLE,
	ATTACH_GREN_LEFT,
	ATTACH_GREN_RIGHT
};

final class npc_q2supertank : CBaseQ2NPC
{
	private float m_flChaingunMinfire;
	private int m_iDeathExplosions;

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
		self.m_bloodColor			= DONT_BLEED;
		self.m_flFieldOfView		= -0.30;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
		{
			if( (pev.weapons & SPAWNFLAG_SUPERTANK_POWERSHIELD) == 0 )
				self.m_FormattedName	= "Super Tank";
			else
				self.m_FormattedName	= "Super Tank Boss";
		}

		m_flGibHealth = -500.0;
		m_flHeatTurnRate = ROCKET_HEATSEEKING;

		if( (pev.weapons & SPAWNFLAG_SUPERTANK_POWERSHIELD) != 0 )
		{
			pev.skin = 2;
			m_iPowerArmorType = q2npc::POWER_ARMOR_SHIELD;
			m_iPowerArmorPower = 400;
		}

		CommonSpawn();

		@this.m_Schedules = @supertank_schedules;

		self.MonsterInit();

		if( self.IsPlayerAlly() )
			SetUse( UseFunction(this.FollowerUse) );
	}

	void AppendAnims()
	{
		for( uint i = 0; i < arrsNPCAnims.length(); i++ )
			arrsQ2NPCAnims.insertLast( arrsNPCAnims[i] );
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_CGUN );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_CORE );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_LTREAD );
		g_Game.PrecacheModel( MODEL_GIB_RTREAD );
		g_Game.PrecacheModel( MODEL_GIB_RGUN );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

		for( uint i = 0; i < arrsNPCSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsNPCSounds[i] );
	}

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
	}

	void SetYawSpeed() //SUPER IMPORTANT, NPC WON'T DO ANYTHING WITHOUT THIS :aRage:
	{
		int ys = 60;
		pev.yaw_speed = ys;
	}

	int Classify()
	{
		if( self.IsPlayerAlly() ) 
			return CLASS_PLAYER_ALLY;

		return CLASS_ALIEN_MILITARY;
	}

	//don't run away at low health!
	int IgnoreConditions()
	{
		if( self.m_MonsterState == MONSTERSTATE_COMBAT )
			return ( bits_COND_SEE_FEAR | bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE );

		return bits_COND_SEE_FEAR;
	}

	void SearchSound()
	{
		if( Math.RandomFloat(0.0, 1.0) < 0.5 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH1], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH2], VOL_NORM, ATTN_NORM );
	}

	void RunTask( Task@ pTask )
	{
		//g_Game.AlertMessage( at_notice, "RunTask: %1\n", pTask.iTask );

		switch( pTask.iTask )
		{
			case TASK_CGUN_LOOP:
			{
				self.MakeIdealYaw( self.m_vecEnemyLKP );
				self.ChangeYaw( int(pev.yaw_speed) );

				if( m_bRerelease )
				{
					if( !self.m_hEnemy.IsValid() or !self.FVisible(self.m_hEnemy, true) or (m_flChaingunMinfire < g_Engine.time and Math.RandomFloat(0.0, 1.0) >= 0.3) )
						self.TaskComplete();
				}
				else
				{
					if( !self.m_hEnemy.IsValid() or !self.FVisible(self.m_hEnemy, true) or Math.RandomFloat(0.0, 1.0) >= 0.9 )
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
		//g_Game.AlertMessage( at_notice, "GetScheduleOfType: %1\n", iType );

		switch( iType )
		{
			case SCHED_TAKE_COVER_FROM_ENEMY:
			case SCHED_TAKE_COVER_FROM_BEST_SOUND:
			case SCHED_TAKE_COVER_FROM_ORIGIN:
			case SCHED_COWER:
			case SCHED_FIND_ATTACK_POINT:
			case SCHED_RANGE_ATTACK1:
			{
				//TESTING
				//m_flChaingunMinfire = g_Engine.time + Math.RandomFloat(1.5, 2.7 );
				//return slSuperTankCgun;
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //grenade launcher
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //rocket launcher

				if( !self.m_hEnemy.IsValid() ) return BaseClass.GetScheduleOfType( iType );

				if( m_bRerelease )
				{
					Vector vecEnemy = self.m_hEnemy.GetEntity().pev.origin - pev.origin;
					float flDist = (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();

					Vector vecMuzzleGun, vecMuzzleRocket, vecMuzzleGrenade;
					self.GetAttachment( ATTACH_CG_MUZZLE, vecMuzzleGun, void );

					//using offsets because the attachment isn't in the correct place at this time
					Math.MakeVectors( pev.angles );
					vecMuzzleRocket = g_Engine.v_forward * 16.0 + g_Engine.v_right * -22.5 + g_Engine.v_up * 108.7;

					self.GetAttachment( ATTACH_GREN_RIGHT, vecMuzzleGrenade, void );

					bool bChaingunGood = M_CheckClearShot( vecMuzzleGun );
					bool bRocketGood = M_CheckClearShot( vecMuzzleRocket );
					bool bGrenadeGood = M_CheckClearShot( vecMuzzleGrenade );

					//fire rockets more often at distance
					if( bChaingunGood and (!bRocketGood or flDist <= 540 or Math.RandomFloat(0.0, 1.0) < 0.3) )
					{
						//prefer grenade if the enemy is above us
						if( bGrenadeGood and (flDist >= 350 or vecEnemy.z > 120.0 or Math.RandomFloat(0.0, 1.0) < 0.2) )
							return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //grenade launcher
						else
						{
							m_flChaingunMinfire = g_Engine.time + Math.RandomFloat( 1.5, 2.7 ); //fire for at least this amount of time
							return slSuperTankCgun;
						}
					}
					else if( bRocketGood )
					{
						//prefer grenade if the enemy is above us
						if( bGrenadeGood and (vecEnemy.z > 120.0 or Math.RandomFloat(0.0, 1.0) < 0.2) )
							return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //grenade launcher
						else
							return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //rocket launcher
					}
					else if( bGrenadeGood )
						return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK1 ); //grenade launcher
				}
				else
				{
					float flDist = (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length();

					if( flDist <= 160 )
						return slSuperTankCgun;
					else
					{	//fire rockets more often at distance
						if( Math.RandomFloat(0.0, 1.0) < 0.3 )
							return slSuperTankCgun;
						else
							return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //rocket launcher
					}
				}
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_TREADSOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_TREAD], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_CHAINGUN:
			{
				supertankMachineGun();
				break;
			}

			case AE_GRENADE:
			{
				supertankGrenade( atoi(pEvent.options()) );
				break;
			}

			case AE_ROCKET:
			{
				supertankRocket( atoi(pEvent.options()) );
				break;
			}

			case AE_DEATH:
			{
				SetThink( ThinkFunction( this.BossExplode) );
				break;
			}
		}
	}

	void supertankMachineGun()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_CHAINGUN], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		Vector vecMuzzle, vecAim;
		self.GetAttachment( ATTACH_CG_MUZZLE, vecMuzzle, void );

		if( m_bRerelease )
			PredictAim( self.m_hEnemy, vecMuzzle, 0, true, -0.1, vecAim, void );
		else
		{
			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin = vecEnemyOrigin + self.m_hEnemy.GetEntity().pev.velocity * 0;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
		}

		MachineGunEffects( vecMuzzle, 3 );
		monster_muzzleflash( vecMuzzle, 255, 255, 0, 10 );
		monster_fire_weapon( q2npc::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
	}

	void supertankGrenade( int iGrenadeNum )
	{
		if( !self.m_hEnemy.IsValid() )
			return;

		Vector vecMuzzle;
		self.GetAttachment( ATTACH_GREN_LEFT+(iGrenadeNum-1), vecMuzzle, void );
		Vector vecAimPoint, vecForward;

		PredictAim( self.m_hEnemy, vecMuzzle, 0, false, crandom_open() * 0.1, vecForward, vecAimPoint );

		for( float flSpeed = 500.0; flSpeed < 1000.0; flSpeed += 100.0 )
		{
			if( !M_CalculatePitchToFire(vecAimPoint, vecMuzzle, vecForward, flSpeed, 2.5, true) )
				continue;

			monster_fire_weapon( q2npc::WEAPON_GRENADE, vecMuzzle, vecForward, GRENADE_DMG, flSpeed );
			break;
		}
	}

	void supertankRocket( int iRocketNum )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ROCKET], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

		Vector vecMuzzle;
		self.GetAttachment( ATTACH_ROCKET_MIDDLE, vecMuzzle, void );
		Math.MakeVectors( pev.angles );

		if( iRocketNum == 1 )
			vecMuzzle = vecMuzzle + g_Engine.v_right * 8.0;
		else if( iRocketNum == 3 )
			vecMuzzle = vecMuzzle - g_Engine.v_right * 8.0;

		if( m_bRerelease )
		{
			monster_muzzleflash( vecMuzzle, 255, 128, 51 );

			if( (pev.weapons & SPAWNFLAG_SUPERTANK_POWERSHIELD) != 0 )
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
				Vector vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();

				monster_fire_weapon( q2npc::WEAPON_HEATSEEKING, vecMuzzle, vecAim, ROCKET_DMG_HEAT, ROCKET_SPEED_HEAT );
			}
			else
			{
				Vector vecAim;
				PredictAim( self.m_hEnemy, vecMuzzle, ROCKET_SPEED, false, 0.0, vecAim, void );

				monster_fire_weapon( q2npc::WEAPON_ROCKET, vecMuzzle, vecAim, ROCKET_DMG, ROCKET_SPEED );
			}
		}
		else
		{
			monster_muzzleflash( vecMuzzle, 255, 128, 51 );

			Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
			vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
			Vector vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();

			monster_fire_weapon( q2npc::WEAPON_ROCKET, vecMuzzle, vecAim, ROCKET_DMG, ROCKET_SPEED_HEAT );
		}
	}

	//attacks are handled in GetScheduleOfType
	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) )
			return true;

		return false;
	}

	bool CheckMeleeAttack1( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

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

		//don't send the tank flying unless the damage is very high (nukes?)
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

		// Lessen the chance of him going into his pain frames
		if( sWeaponName != "weapon_q2chainfist" )
		{
			if( flDamage <= 25 )
			{
				if( Math.RandomFloat(0.0, 1.0) < 0.2 )
					return;
			}

			// Don't go into pain if he's firing his rockets
			if( GetAnim(ANIM_ROCKET) )
				return;
		}

		if( flDamage <= 10 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
		else if( flDamage <= 25 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN3], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );

		m_flPainDebounceTime = g_Engine.time + 3.0;

		if( !M_ShouldReactToPain() )
			return;

		if( flDamage <= 10 )
			self.ChangeSchedule( slQ2Pain1 );
		else if( flDamage <= 25 )
			self.ChangeSchedule( slQ2Pain2 );
		else
			self.ChangeSchedule( slQ2Pain3 );
	}

	void BossExplode()
	{
		Vector vecOrigin = pev.origin;
		vecOrigin.z += 24 + Math.RandomFloat(0, 14); //(rand()&15)

		switch( m_iDeathExplosions++ )
		{
			case 0:
			{
				vecOrigin.x -= 24;
				vecOrigin.y -= 24;
				break;
			}

			case 1:
			{
				vecOrigin.x += 24;
				vecOrigin.y += 24;
				break;
			}

			case 2:
			{
				vecOrigin.x += 24;
				vecOrigin.y -= 24;
				break;
			}

			case 3:
			{
				vecOrigin.x -= 24;
				vecOrigin.y += 24;
				break;
			}

			case 4:
			{
				vecOrigin.x -= 48;
				vecOrigin.y -= 48;
				break;
			}

			case 5:
			{
				vecOrigin.x += 48;
				vecOrigin.y += 48;
				break;
			}

			case 6:
			{
				vecOrigin.x -= 48;
				vecOrigin.y += 48;
				break;
			}

			case 7:
			{
				vecOrigin.x += 48;
				vecOrigin.y -= 48;
				break;
			}

			case 8:
			{
				GibMonster();
				return;
			}
		}

		Explosion( vecOrigin, 30 );

		pev.nextthink = g_Engine.time + 0.1;
	}

	bool ShouldGibMonster( int iGib ) { return false; }

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_TREAD] );
		BaseClass.Killed( pevAttacker, iGib );
	} 

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 2, MODEL_GIB_MEAT, 500, -1, BREAK_FLESH );
		ThrowGib( 2, MODEL_GIB_METAL, 500, -1, BREAK_METAL );
		ThrowGib( 1, MODEL_GIB_CHEST, 500, 2 );
		ThrowGib( 1, MODEL_GIB_CORE, 500, 1 );
		ThrowGib( 1, MODEL_GIB_LTREAD, 500, 22 );
		ThrowGib( 1, MODEL_GIB_RTREAD, 500, 11 );
		ThrowGib( 1, MODEL_GIB_RGUN, 500, 6 );
		ThrowGib( 1, MODEL_GIB_TUBE, 500, -1 );
		ThrowGib( 1, MODEL_GIB_HEAD, 500, 3, BREAK_METAL );

		Explosion( pev.origin, 90 );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}
 
 	void Explosion( Vector vecOrigin, int iScale )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );
			m1.WriteByte( iScale );//scale
			m1.WriteByte( 30 );//framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_EXPLOSION], VOL_NORM, ATTN_NORM );
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

array<ScriptSchedule@>@ supertank_schedules;

enum monsterScheds
{
	TASK_CGUN_LOOP = LAST_COMMON_TASK + 1
}

ScriptSchedule slSuperTankCgun
(
	bits_COND_ENEMY_DEAD,
	0,
	"Super Tank Chain Gun"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slSuperTankCgun.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slSuperTankCgun.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	slSuperTankCgun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_MELEE_ATTACK1)) ); //cgun loop
	slSuperTankCgun.AddTask( ScriptTask(TASK_CGUN_LOOP, 0) );
	slSuperTankCgun.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) ); //cgun end
	slSuperTankCgun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3, slSuperTankCgun };

	@supertank_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "grenade" );
	q2projectiles::RegisterProjectile( "rocket" );
	q2npc::RegisterNPCPScreen();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2supertank::npc_q2supertank", "npc_q2supertank" );
	g_Game.PrecacheOther( "npc_q2supertank" );
}

} //end of namespace npc_q2supertank

/* FIXME
*/

/* TODO
	Make the tank move properly on slopes ??
*/
namespace npc_q2jorg
{

const string NPC_MODEL				= "models/quake2/monsters/jorg/jorg.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/jorg/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/jorg/gibs/foot.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/jorg/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/jorg/gibs/head.mdl";
const string MODEL_GIB_SPIKE		= "models/quake2/monsters/jorg/gibs/spike.mdl";
const string MODEL_GIB_SPINE		= "models/quake2/monsters/jorg/gibs/spine.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/jorg/gibs/thigh.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/jorg/gibs/tube.mdl";

const Vector NPC_MINS					= Vector( -80, -80, 0 );
const Vector NPC_MAXS					= Vector( 80, 80, 188 ); //140 in quake 2

const int NPC_HEALTH_ORG			= 3000;
const int NPC_HEALTH_RE				= 8000;

const int AE_STEP_LEFT					= 11;
const int AE_STEP_RIGHT				= 12;
const int AE_CHAINGUN					= 13;
const int AE_BFG							= 14;
const int AE_DEATHHIT					= 15;
const int AE_REFIRE						= 16;
const int AE_BOSSEXPLODE_ORG	= 17;
const int AE_MAKRONTOSS_RE		= 18;
const int AE_CHAINGUN_SOUND		= 19;
const int AE_CHAINGUN_END			= 20;

const float GUN_DAMAGE				= 6.0;

const float BFG_DAMAGE				= 50.0;
const float BFG_SPEED					= 300.0;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/jorg/bs3idle1.wav",
	"quake2/npcs/jorg/bs3srch1.wav",
	"quake2/npcs/jorg/bs3srch2.wav",
	"quake2/npcs/jorg/bs3srch3.wav",
	"quake2/npcs/jorg/step1.wav",
	"quake2/npcs/jorg/step2.wav",
	"quake2/npcs/jorg/bs3atck1.wav",
	"quake2/npcs/jorg/w_loop.wav",
	"quake2/npcs/jorg/xfire.wav",
	"quake2/npcs/jorg/bs3atck1_end.wav",
	"quake2/npcs/jorg/bs3atck2.wav",
	"quake2/npcs/jorg/bs3pain1.wav",
	"quake2/npcs/jorg/bs3pain2.wav",
	"quake2/npcs/jorg/bs3pain3.wav",
	"quake2/npcs/jorg/bs3deth1.wav",
	"quake2/npcs/jorg/d_hit.wav",
	"quake2/weapons/rocklx1a.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SEARCH1,
	SND_SEARCH2,
	SND_SEARCH3,
	SND_STEP_LEFT,
	SND_STEP_RIGHT,
	SND_ATK_GUN_START,
	SND_ATK_GUN_LOOP,
	SND_ATK_GUN_FIRE,
	SND_ATK_GUN_END,
	SND_ATK_BFG,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3,
	SND_DEATH,
	SND_DEATHHIT,
	SND_EXPLOSION
};

const array<string> arrsNPCAnims =
{
	"attack_guns_start",
	"attack_guns_loop",
	"attack_guns_end",
	"attack_bfg"
};

enum anim_e
{
	ANIM_GUNS_START = 0,
	ANIM_GUNS_LOOP,
	ANIM_GUNS_END,
	ANIM_ATTACK_BFG
};

final class npc_q2jorg : CBaseQ2NPC
{
	private int m_iDeathExplosions;
	private int m_iTriggerCondition;
	private string m_sTriggerTarget;
	private bool m_bNoRider;

	bool MonsterKeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "norider" )
		{
			if( atoi(szValue) >= 1 )
				m_bNoRider = true;

			return true;
		}

		return false;
	}

	void MonsterSpawn()
	{
		AppendAnims();

		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		if( m_bNoRider )
			pev.body = 1;

		if( pev.health <= 0 )
		{
			if( m_bRerelease )
				pev.health					= NPC_HEALTH_RE * m_flHealthMultiplier;
			else
				pev.health					= NPC_HEALTH_ORG * m_flHealthMultiplier;
		}

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_STEP;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		self.m_flFieldOfView		= -0.30;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Jorg";

		m_flGibHealth = -2000.0;
		SetMass( 1000 );

		@this.m_Schedules = @jorg_schedules;

		self.MonsterInit();

		if( self.m_iTriggerCondition == 4 )
		{
			m_iTriggerCondition = self.m_iTriggerCondition;
			m_sTriggerTarget = self.m_iszTriggerTarget;
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
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_FOOT );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_SPIKE );
		g_Game.PrecacheModel( MODEL_GIB_SPINE );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

		for( uint i = 0; i < q2projectiles::pExplosionSprites.length(); ++i )
			g_Game.PrecacheModel( q2projectiles::pExplosionSprites[i] );

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

	void SearchSound()
	{
		float flRand = Math.RandomFloat( 0.0, 1.0 );

		if( flRand <= 0.3 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH1], VOL_NORM, ATTN_NORM );
		else if( flRand <= 0.6 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH3], VOL_NORM, ATTN_NORM );
	}

	void DeathSound() 
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );
	}

	void StopLoopingSounds()
	{
		g_SoundSystem.StopSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE] ); 
		g_SoundSystem.StopSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_ATK_GUN_LOOP] );
	}

	//attacks are handled in GetScheduleOfType
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack_Base(flDist, 0.8, 0.4, 0.2, 0.0) )
			return true;

		return false;
	}

	void RunAI()
	{
		if( m_flTriggeredSpawn > 0 )
		{
			m_flTriggeredSpawn = 0.0;
			monster_triggered_spawn();
		}

		BaseClass.RunAI();

		DoSearchSound();
		CheckArmorEffect();

		if( m_bRerelease and pev.deadflag == DEAD_DYING )
		{
			pev.takedamage = DAMAGE_NO;
			BossExplodeRerelease();
			pev.nextthink = g_Engine.time + Math.RandomFloat(0.072, 0.25);
		}
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_CGUN_LOOP:
			{
				if( !jorg_reattack1() )
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

	void RunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_PLAY_SEQUENCE:
			{
				if( GetAnim(ANIM_GUNS_START) )
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
				//StopLoopingSounds();
				//g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_GUN_START], VOL_NORM, ATTN_NORM );
				//return slJorgChaingun;
				//StopLoopingSounds();
				//return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //bfg

				if( m_bNoRider or Math.RandomFloat(0.0, 1.0) <= 0.75 )
				{
					StopLoopingSounds();
					g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_GUN_START], VOL_NORM, ATTN_NORM );
					return slJorgChaingun;
				}
				else
				{
					StopLoopingSounds();
					return BaseClass.GetScheduleOfType( SCHED_RANGE_ATTACK2 ); //bfg
				}
			}
		}

		return BaseClass.GetScheduleOfType( iType );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2npc::AE_IDLESOUND:
			{
				if( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_NORM );

				break;
			}

			case AE_STEP_LEFT:
			{
				if( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
					jorg_step_left();

				break;
			}

			case AE_STEP_RIGHT:
			{
				if( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
					jorg_step_right();

				break;
			}

			case AE_CHAINGUN:
			{
				jorg_firebullet();
				break;
			}

			case AE_BFG:
			{
				jorgBFG();
				break;
			}

			case AE_DEATHHIT:
			{
				jorg_death_hit();
				break;
			}

			case AE_REFIRE:
			{
				if( !jorg_reattack1() )
					self.TaskComplete();

				break;
			}

			case AE_BOSSEXPLODE_ORG:
			{
				if( m_bRerelease )
					return;

				pev.takedamage = DAMAGE_NO;
				SetThink( ThinkFunction( this.BossExplodeOriginal) );
				pev.nextthink = g_Engine.time;
				break;
			}

			case AE_MAKRONTOSS_RE:
			{
				if( !m_bRerelease )
					return;

				MakronSpawn();
				GibMonster();
				break;
			}

			case AE_CHAINGUN_SOUND:
			{
				g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, arrsNPCSounds[SND_ATK_GUN_LOOP], VOL_NORM, ATTN_NORM, SND_FORCE_LOOP );
				break;
			}

			case AE_CHAINGUN_END:
			{
				jorg_attack1_end_sound();
				break;
			}
		}
	}

	void jorg_firebullet()
	{
		jorg_firebullet_left();
		jorg_firebullet_right();
	}

	void jorg_firebullet_left()
	{
		Vector vecMuzzle, vecAim;
		self.GetAttachment( 0, vecMuzzle, void );

		if( m_bRerelease )
			PredictAim( self.m_hEnemy, vecMuzzle, 0, false, 0.2, vecAim, void );
		else
			PredictAim( self.m_hEnemy, vecMuzzle, 0, true, -0.2, vecAim, void );

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_GUN_FIRE], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		MachineGunEffects( vecMuzzle, 3 );
		monster_muzzleflash( vecMuzzle, 255, 255, 0, 10 );
		monster_fire_weapon( q2npc::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
	}

	void jorg_firebullet_right()
	{
		Vector vecMuzzle, vecAim;
		self.GetAttachment( 1, vecMuzzle, void );

		if( m_bRerelease )
			PredictAim( self.m_hEnemy, vecMuzzle, 0, false, -0.2, vecAim, void );
		else
			PredictAim( self.m_hEnemy, vecMuzzle, 0, true, -0.2, vecAim, void );

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_GUN_FIRE], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.1, self );

		MachineGunEffects( vecMuzzle, 3 );
		monster_muzzleflash( vecMuzzle, 255, 255, 0, 10 );
		monster_fire_weapon( q2npc::WEAPON_BULLET, vecMuzzle, vecAim, GUN_DAMAGE );
	}

	bool jorg_reattack1()
	{
		if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 )
			return false;

		if( self.FVisible(self.m_hEnemy, true) )
		{
			//TODO fix this
			if( Math.RandomFloat(0.0, 1.0) < 0.9 )
				return true;
			else
				return false;
		}
		else
			return false;
	}

	void jorg_attack1_end_sound()
	{
		StopLoopingSounds();
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_GUN_END], VOL_NORM, ATTN_NORM );
	}

	void jorgBFG()
	{
		if( m_bRerelease )
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATK_BFG], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_ATK_BFG], VOL_NORM, ATTN_NORM );

		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 192, 0.1, self );

		Vector vecMuzzle, vecAim;
		self.GetAttachment( 2, vecMuzzle, void );

		Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
		vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
		vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();

		monster_muzzleflash( vecMuzzle, 128, 255, 128, 30 );
		monster_fire_weapon( q2npc::WEAPON_BFG, vecMuzzle, vecAim, BFG_DAMAGE, BFG_SPEED );
	}

	void jorg_step_left()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_STEP_LEFT], VOL_NORM, ATTN_NORM );
	}

	void jorg_step_right()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_STEP_RIGHT], VOL_NORM, ATTN_NORM );
	}

	void jorg_death_hit()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_DEATHHIT], VOL_NORM, ATTN_NORM );
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

		//don't send Jorg flying unless the damage is very high (nukes?)
		if( flDamage < 500 )
			bitsDamageType &= ~DMG_BLAST|DMG_LAUNCH;

		bitsDamageType &= ~DMG_ALWAYSGIB;
		bitsDamageType |= DMG_NEVERGIB;

		M_ReactToDamage( g_EntityFuncs.Instance(pevAttacker) );

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void HandlePain( float flDamage, string sWeaponName )
	{
		if( g_Engine.time < m_flPainDebounceTime )
			return;

		// Lessen the chance of him going into his pain frames if he takes little damage
		if( sWeaponName != "weapon_q2chainfist" )
		{
			if( flDamage <= 40 )
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.6 )
					return;
			}

			//If he's entering his attack1 or using attack1, lessen the chance of him going into pain
			if( GetAnim(ANIM_GUNS_START) )
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.005 )
					return;
			}

			if( GetAnim(ANIM_GUNS_LOOP) )
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.00005 )
					return;
			}

			if( GetAnim(ANIM_ATTACK_BFG) )
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.005 )
					return;
			}
		}

		m_flPainDebounceTime = g_Engine.time + 3.0;

		bool bDoPain3 = false;

		if( flDamage > 50 )
		{
			if( flDamage <= 100 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
			else
			{
				if( Math.RandomFloat(0.0, 1.0) <= 0.3 )
				{
					bDoPain3 = true;
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN3], VOL_NORM, ATTN_NORM );
				}
			}
		}

		if( !M_ShouldReactToPain() )
			return;

		StopLoopingSounds();

		if( flDamage <= 50 )
			self.ChangeSchedule( slQ2Pain1 );
		else if( flDamage <= 100 )
			self.ChangeSchedule( slQ2Pain2 );
		else if( bDoPain3 )
			self.ChangeSchedule( slQ2Pain3 );
	}

	bool ShouldGibMonster( int iGib ) { return false; }

	void MonsterKilled( entvars_t@ pevAttacker, int iGib )
	{
		StopLoopingSounds();
	}

	void BossExplodeOriginal()
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
				MakronSpawn();
				GibMonster();
				return;
			}
		}

		Explosion( vecOrigin, 30 );

		pev.nextthink = g_Engine.time + 0.1;
	}

	void BossExplodeRerelease()
	{
		if( pev.deadflag >= DEAD_DEAD )
			return;

		Vector vecOrigin = pev.origin + pev.mins;

		vecOrigin.x += Math.RandomFloat(0.0, 1.0) * pev.size.x;
		vecOrigin.y += Math.RandomFloat(0.0, 1.0) * pev.size.y;
		vecOrigin.z += Math.RandomFloat(0.0, 1.0) * pev.size.z;

		bool bNoLight = (m_iDeathExplosions % 3 == 0) ? false : true;
		Explosion( vecOrigin, 15, bNoLight );

		m_iDeathExplosions++;

		pev.nextthink = g_Engine.time + Math.RandomFloat( 0.05, 0.2 );
	}

 	void Explosion( Vector vecOrigin, int iScale, bool bNoLight = false )
	{
		NetworkMessage m1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );
			m1.WriteByte( iScale );//scale
			m1.WriteByte( 30 );//framerate
			if( !bNoLight )
				m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
			else
				m1.WriteByte( TE_EXPLFLAG_NODLIGHTS | TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_EXPLOSION], VOL_NORM, ATTN_NORM );
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		q2::ThrowGib( self, 2, MODEL_GIB_MEAT, 500, -1, BREAK_FLESH );
		q2::ThrowGib( self, 2, MODEL_GIB_METAL, 500, -1, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, 500, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, 500, 30, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, 500, 31, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, 500, 10, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, 500, 19, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, 500, 3, BREAK_FLESH );

		for( uint i = 0; i < 6; i++ )
		{
			if( i <= 2 )
				q2::ThrowGib( self, 1, MODEL_GIB_SPIKE, 500, 4+i, BREAK_METAL );
			else if( i > 2 )
				q2::ThrowGib( self, 1, MODEL_GIB_SPIKE, 500, 10+i, BREAK_METAL );
		}

		q2::ThrowGib( self, 1, MODEL_GIB_SPINE, 500, 22, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_THIGH, 500, 23, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_THIGH, 500, 27, BREAK_METAL );
		q2::ThrowGib( self, 4, MODEL_GIB_TUBE, 500, -1 );

		Explosion( pev.origin, 90 );

		SetThink( ThinkFunction(this.SUB_Remove) );
		pev.nextthink = g_Engine.time;
	}

	void MakronSpawn()
	{
		if( m_bNoRider )
			return;

		CBaseEntity@ pMakronCBE = g_EntityFuncs.Create( "npc_q2makron", pev.origin + Vector(0, 0, 10), pev.angles, false );
		CBaseMonster@ pMakron = pMakronCBE.MyMonsterPointer();

		if( pMakron !is null )
		{
			if( m_iTriggerCondition == 4 ) //Trigger on death
			{
				g_EntityFuncs.DispatchKeyValue( pMakron.edict(), "TriggerCondition", "4" );
				g_EntityFuncs.DispatchKeyValue( pMakron.edict(), "TriggerTarget", m_sTriggerTarget );
			}

			pMakron.pev.team = 4269;

			g_EntityFuncs.DispatchSpawn( pMakron.edict() );

			if( self.m_hEnemy.IsValid() )
				pMakron.m_hEnemy = self.m_hEnemy;
		}
	}

	void SUB_Remove()
	{
		self.UpdateOnRemove();

		if( pev.health > 0 )
			pev.health = 0;

		g_EntityFuncs.Remove(self);
	}
}

array<ScriptSchedule@>@ jorg_schedules;

enum monsterScheds
{
	TASK_CGUN_LOOP = LAST_COMMON_TASK + 1
}

ScriptSchedule slJorgChaingun
(
	0,
	0,
	"Jorg Chain Gun"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slJorgChaingun.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slJorgChaingun.AddTask( ScriptTask(TASK_FACE_ENEMY) );
	slJorgChaingun.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL1)) ); //cgun start
	slJorgChaingun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_RANGE_ATTACK1)) ); //cgun loop
	slJorgChaingun.AddTask( ScriptTask(TASK_CGUN_LOOP, 0) );
	slJorgChaingun.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_SIGNAL2)) ); //cgun end
	slJorgChaingun.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3, slJorgChaingun };

	@jorg_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "bfg" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2jorg::npc_q2jorg", "npc_q2jorg" );
	g_Game.PrecacheOther( "npc_q2jorg" );
}

} //end of namespace npc_q2jorg

/* FIXME
*/

/* TODO
*/
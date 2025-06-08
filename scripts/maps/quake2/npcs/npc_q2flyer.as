namespace npc_q2flyer
{

const string NPC_MODEL				= "models/quake2/monsters/flyer/flyer.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_METAL		= "models/quake2/objects/gibs/sm_metal.mdl";
const string MODEL_GIB_BASE		= "models/quake2/monsters/flyer/gibs/base.mdl";
const string MODEL_GIB_GUN			= "models/quake2/monsters/flyer/gibs/gun.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/flyer/gibs/head.mdl";
const string MODEL_GIB_WING		= "models/quake2/monsters/flyer/gibs/wing.mdl";

const Vector NPC_MINS					= Vector( -32, -32, -16 );
const Vector NPC_MAXS					= Vector( 32, 32, 8 );

const int NPC_HEALTH					= 50;

const int AE_FIRELASER					= 11;
const int AE_MELEE_START				= 12;
const int AE_MELEE_SLICE				= 13;
const int AE_MELEE_REFIRE			= 14;

const float BLASTER_DAMAGE			= 1.0;
const float BLASTER_SPEED			= 1000.0;

const float MELEE_DAMAGE			= 5.0;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/flyer/flyidle1.wav",
	"quake2/npcs/flyer/flysght1.wav",
	"quake2/npcs/flyer/flysrch1.wav",
	"quake2/npcs/flyer/flyatck1.wav",
	"quake2/npcs/flyer/flyatck2.wav",
	"quake2/npcs/flyer/flyatck3.wav",
	"quake2/npcs/flyer/flypain1.wav",
	"quake2/npcs/flyer/flypain2.wav",
	"quake2/npcs/flyer/flydeth1.wav",
	"quake2/weapons/rocklx1a.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_SPROING,
	SND_SLASH,
	SND_SHOOT,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH,
	SND_EXPLODE
};

final class npc_q2flyer : ScriptBaseMonsterEntity, CBaseQ1Flying
{
	void MonsterSpawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, NPC_MODEL );
		g_EntityFuncs.SetSize( self.pev, NPC_MINS, NPC_MAXS );

		//fix for when spawning with commands
		TraceResult tr;
		Vector vecOrigin = pev.origin;
		g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -1) * 4, ignore_monsters, self.edict(), tr );

		if( tr.flFraction < 1.0 )
			vecOrigin.z += 32.0;

		g_EntityFuncs.SetOrigin( self, vecOrigin );

		if( pev.health <= 0 )
			pev.health					= NPC_HEALTH * m_flHealthMultiplier;

		pev.solid						= SOLID_SLIDEBOX;
		pev.movetype				= MOVETYPE_FLY;
		pev.flags						|= FL_FLY;
		pev.scale						= 1.0;
		self.m_bloodColor			= BLOOD_COLOR_RED;
		//self.m_flFieldOfView		= VIEW_FIELD_WIDE;
		self.m_MonsterState		= MONSTERSTATE_NONE;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Flyer";

		@this.m_Schedules = @flyer_schedules;

		SetMass( 50 ); //100 for kamikaze
		FlyMonsterInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_METAL );
		g_Game.PrecacheModel( MODEL_GIB_BASE );
		g_Game.PrecacheModel( MODEL_GIB_GUN );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_WING );

		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

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

	bool MonsterHasMissileAttack() { return true; }
	bool MonsterHasMeleeAttack() { return true; }

	void MonsterIdle()
	{
		m_iAttackState = ATTACK_NONE;
		m_iAIState = STATE_IDLE;
		self.SetActivity( ACT_IDLE );
		m_flMonsterSpeed = 0.0;
	}

	void MonsterSight()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void MonsterWalk()
	{
		m_iAttackState = ATTACK_NONE;
		m_iAIState = STATE_WALK;
		self.SetActivity( ACT_WALK );
		m_flMonsterSpeed = 8.0;
	}

	void MonsterRun()
	{
		m_iAIState = STATE_RUN;
		self.SetActivity( ACT_RUN );
		m_flMonsterSpeed = 16.0;
	}

	void MonsterAttack()
	{
		if( m_Activity == ACT_MELEE_ATTACK1 )
			AI_Charge( 4 );
		else if( m_iAIState == STATE_ATTACK and self.m_fSequenceFinished )
			MonsterRun();

		//always face the target while attacking
		AI_Face();
	}

	void MonsterSide()
	{
		m_iAIState = STATE_RUN;
		self.SetActivity( ACT_RUN );
		m_flMonsterSpeed = 8.0;
	}

	void MonsterMissileAttack()
	{
		m_iAIState = STATE_ATTACK;
		self.SetActivity( ACT_RANGE_ATTACK1 );
	}

	void MonsterMeleeAttack()
	{
		m_iAIState = STATE_ATTACK;
		self.SetActivity( ACT_MELEE_ATTACK1 );
	}

	void MonsterMeleeRefire()
	{
		m_iAIState = STATE_ATTACK;
		self.SetActivity( ACT_SIGNAL2 );
	}

	void MonsterMeleeEnd()
	{
		m_iAIState = STATE_ATTACK;
		self.SetActivity( ACT_SIGNAL3 );
	}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_FIRELASER:
			{
				flyer_fire( atoi(pEvent.options()) );
				break;
			}

			case AE_MELEE_START:
			{
				flyer_pop_blades();
				break;
			}

			case AE_MELEE_SLICE:
			{
				flyer_slash( atoi(pEvent.options()) );
				break;
			}

			case AE_MELEE_REFIRE:
			{
				flyer_check_melee();
				break;
			}
		}
	}

	void flyer_fire( int iSide ) //0 = left, 1 = right
	{	
		if( !self.m_hEnemy.IsValid() )
			return;

		Vector vecMuzzle, vecAim;
		self.GetAttachment( iSide, vecMuzzle, void );

		Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
		vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
		//vecEnemyOrigin.z += (self.m_hEnemy.GetEntity().pev.maxs.z * 0.8); //don't aim too high
		vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();

		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 192, 0.3, self );

		monster_muzzleflash( vecMuzzle, 255, 255, 0, 5 );
		monster_fire_weapon( q2::WEAPON_BLASTER, vecMuzzle, vecAim, BLASTER_DAMAGE, BLASTER_SPEED );
	}

	void flyer_pop_blades()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SPROING], VOL_NORM, ATTN_NORM );
	}

	void flyer_slash( int iSide )
	{
		if( iSide == 0 )
			flyer_slash_left();
		else
			flyer_slash_right();
	}

	void flyer_slash_left()
	{
		Vector vecAim( Q2_MELEE_DISTANCE*1.5, pev.mins.x, 0.0 );

		fire_hit( vecAim, MELEE_DAMAGE, 0.0 );
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SLASH], VOL_NORM, ATTN_NORM );
	}

	void flyer_slash_right()
	{
		Vector vecAim( Q2_MELEE_DISTANCE*1.5, pev.maxs.x, 0.0 );

		fire_hit( vecAim, MELEE_DAMAGE, 0.0 );
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_SLASH], VOL_NORM, ATTN_NORM );
	}

	void flyer_check_melee()
	{
		if( TargetRange(GetEnemy()) == RANGE_MELEE )
		{
			if( Math.RandomFloat(0.0, 1.0) <= 0.8 )
				MonsterMeleeRefire();
			else
				MonsterMeleeEnd();
		}
		else
			MonsterMeleeEnd();
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		float psave = 0.0; //CheckPowerArmor( pevInflictor, flDamage );
		flDamage -= psave;

		SetSkin();

		if( pevAttacker !is self.pev )
			pevAttacker.frags += ( flDamage/90 );

		pev.dmg = flDamage;

		if( pev.deadflag == DEAD_NO )
		{
			M_ReactToDamage( g_EntityFuncs.Instance(pevAttacker) );

			if( /*!HasFlags(monsterinfo.aiflags, AI_DUCKED) and*/ flDamage != 0 )
			{
				HandlePain( flDamage );

				// nightmare mode monsters don't go into pain frames often
				if( q2npc::g_iDifficulty == q2::DIFF_NIGHTMARE )
					m_flPainDebounceTime = g_Engine.time + 5.0;
			}
		}

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void MonsterSetSkin()
	{
		if( pev.health < (pev.max_health / 2) )
			pev.skin = 1;
		else
			pev.skin = 0;
	}

	void HandlePain( float flDamage )
	{
		if( g_Engine.time < m_flPainDebounceTime )
			return;

		m_flPainDebounceTime = g_Engine.time + 3.0;

		int iRand = Math.RandomLong( 0, 2 );

		if( m_bRerelease )
		{
			if( iRand == 0 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
			else if( iRand == 1 )
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN2], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );

			if( !M_ShouldReactToPain() )
				return;

			//flyer_set_fly_parameters(self, false);

			if( iRand == 0 )
				self.ChangeSchedule( slQ2Pain1 );
			else if( iRand == 1 )
				self.ChangeSchedule( slQ2Pain2 );
			else
				self.ChangeSchedule( slQ2Pain3 );
		}
		else
		{
			if( !M_ShouldReactToPain() )
				return;

			if( iRand == 0 )
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN1], VOL_NORM, ATTN_NORM );
				self.ChangeSchedule( slQ2Pain1 );
			}
			else if( iRand == 1 )
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

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );
		g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_EXPLODE], VOL_NORM, ATTN_NORM );

		NetworkMessage m1( MSG_PAS, NetworkMessages::SVC_TEMPENTITY, pev.origin );
			m1.WriteByte( TE_EXPLOSION );
			m1.WriteCoord( pev.origin.x );
			m1.WriteCoord( pev.origin.y );
			m1.WriteCoord( pev.origin.z );

			if( g_EngineFuncs.PointContents(pev.origin) == CONTENTS_WATER )
				m1.WriteShort( g_Game.PrecacheModel("sprites/WXplo1.spr") );
			else
				m1.WriteShort( g_Game.PrecacheModel(q2projectiles::pExplosionSprites[Math.RandomLong(0, q2projectiles::pExplosionSprites.length() - 1)]) );

			m1.WriteByte( int(16 * pev.scale) ); //scale
			m1.WriteByte( 30 ); //framerate
			m1.WriteByte( TE_EXPLFLAG_NOSOUND | TE_EXPLFLAG_NOPARTICLES );
		m1.End();

		GibMonster();

		BaseClass.Killed( pevAttacker, GIB_NORMAL );
	}

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		q2::ThrowGib( self, 2, MODEL_GIB_MEAT, 55, -1, BREAK_FLESH );
		q2::ThrowGib( self, 2, MODEL_GIB_METAL, 55, -1, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_BASE, 55, 1, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, 55, 4, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_GUN, 55, 7, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_WING, 55, 2, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_WING, 55, 5, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, 55, 0, BREAK_FLESH );

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

array<ScriptSchedule@>@ flyer_schedules;

void InitSchedules()
{
	InitQ2BaseSchedules();

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3 };

	@flyer_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "laser" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2flyer::npc_q2flyer", "npc_q2flyer" );
	g_Game.PrecacheOther( "npc_q2flyer" );
}

} //end of namespace npc_q2flyer

/* FIXME
*/

/* TODO
*/
namespace npc_q2gladiator
{

const string NPC_MODEL				= "models/quake2/monsters/gladiator/gladiator.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/gladiator/gibs/chest.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/gladiator/gibs/head.mdl";
const string MODEL_GIB_LARM		= "models/quake2/monsters/gladiator/gibs/larm.mdl";
const string MODEL_GIB_RARM		= "models/quake2/monsters/gladiator/gibs/rarm.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/gladiator/gibs/thigh.mdl";

const Vector NPC_MINS					= Vector( -32, -32, 0 );
const Vector NPC_MAXS					= Vector( 32, 32, 66 ); //90 in svencoop
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 400;

const int AE_ATTACK_MELEE			= 11;
const int AE_ATTACK_SAVELOC		= 12;
const int AE_ATTACK_RAILGUN		= 13;
const int AE_DEATHSOUND				= 14;
const int AE_MELEE_SOUND			= 15;

const float MELEE_DMG_MIN			= 20.0;
const float MELEE_DMG_MAX			= 25.0;
const float MELEE_KICK					= 80.0;

const float RAILGUN_DAMAGE			= 50.0;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/gladiator/gldidle1.wav",
	"quake2/npcs/gladiator/sight.wav",
	"quake2/npcs/gladiator/gldsrch1.wav",
	"quake2/npcs/gladiator/melee1.wav",
	"quake2/npcs/gladiator/melee2.wav",
	"quake2/npcs/gladiator/melee3.wav",
	"quake2/npcs/gladiator/railgun.wav",
	"quake2/npcs/gladiator/pain.wav",
	"quake2/npcs/gladiator/gldpain2.wav",
	"quake2/npcs/gladiator/death.wav",
	"quake2/npcs/gladiator/glddeth2.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE,
	SND_SIGHT,
	SND_SEARCH,
	SND_MELEE,
	SND_MELEE_HIT,
	SND_MELEE_MISS,
	SND_RAILGUN,
	SND_PAIN1,
	SND_PAIN2,
	SND_DEATH1,
	SND_DEATH2
};

const array<string> arrsNPCAnims =
{
	"flinch",
	"painup"
};

enum anim_e
{
	ANIM_PAIN = 0,
	ANIM_PAIN_AIR
};

final class npc_q2gladiator : CBaseQ2NPC
{
	private Vector m_vecEnemyDir;

	void MonsterSpawn()
	{
		AppendAnims();

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
			self.m_FormattedName	= "Gladiator";

		m_flGibHealth = -175.0;
		SetMass( 400 );

		@this.m_Schedules = @gladiator_schedules;

		self.MonsterInit();
	}

	void AppendAnims()
	{
		for( uint i = 0; i < arrsNPCAnims.length(); i++ )
			arrsQ2NPCAnims.insertLast( arrsNPCAnims[i] );
	}

	void Precache()
	{
		uint i;

		g_Game.PrecacheModel( NPC_MODEL );
		g_Game.PrecacheModel( MODEL_GIB_BONE );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_LARM );
		g_Game.PrecacheModel( MODEL_GIB_RARM );
		g_Game.PrecacheModel( MODEL_GIB_THIGH );

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

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case AE_MELEE_SOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_ATTACK_MELEE:
			{
				GladiatorMelee();
				break;
			}

			//save location of enemy a few frames before firing so the player can dodge
			case AE_ATTACK_SAVELOC:
			{
				if( self.m_hEnemy.IsValid() )
				{
					Vector vecMuzzle;
					self.GetAttachment( 0, vecMuzzle, void );

					Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
					vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z; //always headshot
					m_vecEnemyDir = (vecEnemyOrigin - vecMuzzle);
					m_vecEnemyDir = m_vecEnemyDir.Normalize();

					g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_RAILGUN], VOL_NORM, ATTN_NORM );
					pev.framerate = 0.5; //lower the framerate to time the shot with the sound
				}

				break;
			}

			case AE_ATTACK_RAILGUN:
			{
				if( self.m_hEnemy.IsValid() )
					GladiatorGun();

				break;
			}

			case AE_DEATHSOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_DEATH1], VOL_NORM, ATTN_NORM );

				if( Math.RandomLong(0, 1) == 1 )
					g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH2], VOL_NORM, ATTN_NORM );

				break;
			}
		}
	}

	void GladiatorMelee()
	{
		if( m_bRerelease )
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE_RR, pev.mins.x, -4 );

			if( fire_hit(aim, Math.RandomFloat(20.0, 25.0), 300) )
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
			else
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_MELEE_MISS], VOL_NORM, ATTN_NORM );
				monsterinfo.melee_debounce_time = g_Engine.time + 1.0;
			}
		}
		else
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE, pev.mins.x, -4 );

			if( fire_hit(aim, 20 + Math.RandomFloat(0, 5), 300) ) //(20 + (rand() %5))
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
			else
				g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, arrsNPCSounds[SND_MELEE_MISS], VOL_NORM, ATTN_NORM );
		}
	}

	void GladiatorGun()
	{
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

		pev.framerate = 1.0;

		Vector vecMuzzle;
		self.GetAttachment( 0, vecMuzzle, void );

		monster_muzzleflash( vecMuzzle, 128, 128, 255 );
		//monster_fire_railgun( vecMuzzle, m_vecEnemyDir, RAILGUN_DAMAGE, 100 );
		monster_fire_weapon( q2::WEAPON_RAILGUN, vecMuzzle, m_vecEnemyDir, RAILGUN_DAMAGE, 100 );
	}

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		if( M_CheckAttack(flDist) )
			return true;

		// a small safe zone
		float flMeleeDistance = m_bRerelease ? Q2_MELEE_DISTANCE_RR : Q2_MELEE_DISTANCE;
		if( flDist <= (flMeleeDistance + 32) )
				return false;

		return false;
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		float psave = CheckPowerArmor( pevInflictor, flDamage );
		flDamage -= psave;

		SetSkin();

		if( pevAttacker !is self.pev )
			pevAttacker.frags += ( flDamage/90 );

		pev.dmg = flDamage;

		if( pev.deadflag == DEAD_NO )
			HandlePain( flDamage );

		M_ReactToDamage( g_EntityFuncs.Instance(pevAttacker) );

		if( pev.deadflag == DEAD_NO )
			return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		else
			return DeadTakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void MonsterSetSkin()
	{
		if( pev.health < (pev.max_health / 2) )
			pev.skin |= 1;
		else
			pev.skin &= ~1;
	}

	void HandlePain( float flDamage )
	{
		if( g_Engine.time < m_flPainDebounceTime )
		{
			if( pev.velocity.z > 100 and GetAnim(ANIM_PAIN) )
				self.ChangeSchedule( slQ2Pain2 );

			return;
		}

		m_flPainDebounceTime = g_Engine.time + 3.0;

		g_SoundSystem.StopSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_RAILGUN] );
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_PAIN1, SND_PAIN2)], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( pev.velocity.z > 100 )
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

		q2::ThrowGib( self, 2, MODEL_GIB_BONE, pev.dmg, -1 );
		q2::ThrowGib( self, 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_THIGH, pev.dmg, 3 );
		q2::ThrowGib( self, 1, MODEL_GIB_THIGH, pev.dmg, 14 );
		q2::ThrowGib( self, 1, MODEL_GIB_LARM, pev.dmg, 10 );
		q2::ThrowGib( self, 1, MODEL_GIB_RARM, pev.dmg, 8 );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 5 );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 6, BREAK_FLESH );
	}
}

array<ScriptSchedule@>@ gladiator_schedules;

void InitSchedules()
{
	InitQ2BaseSchedules();

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2 };

	@gladiator_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "railbeam" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2gladiator::npc_q2gladiator", "npc_q2gladiator" );
	g_Game.PrecacheOther( "npc_q2gladiator" );
}

} //end of namespace npc_q2gladiator

/* FIXME
	The first pain animation freezes at the end for some reason
*/

/* TODO
*/
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
const Vector NPC_MAXS					= Vector( 32, 32, 90 ); //66 in original

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

	void Spawn()
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

		CommonSpawn();

		@this.m_Schedules = @gladiator_schedules;

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

	void FollowerUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
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

	void IdleSoundQ2()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE], VOL_NORM, ATTN_IDLE );
	}

	void AlertSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void SearchSound()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent )
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
		float flDamage = Math.RandomFloat( MELEE_DMG_MIN, MELEE_DMG_MAX );

		CBaseEntity@ pHurt = CheckTraceHullAttack( Q2_MELEE_DISTANCE, flDamage, DMG_SLASH );
		if( pHurt !is null )
		{
			if( pHurt.pev.FlagBitSet(FL_MONSTER) or pHurt.pev.FlagBitSet(FL_CLIENT) and pHurt.pev.size.z <= 88.0 )
			{
				pHurt.pev.punchangle.x = 5;
				Math.MakeVectors( pev.angles );
				pHurt.pev.velocity = pHurt.pev.velocity + g_Engine.v_forward * MELEE_KICK;
			}

			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE_HIT], VOL_NORM, ATTN_NORM );
		}
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_BODY, arrsNPCSounds[SND_MELEE_MISS], VOL_NORM, ATTN_NORM );
	}

	void GladiatorGun()
	{
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

		pev.framerate = 1.0;

		Vector vecMuzzle;
		self.GetAttachment( 0, vecMuzzle, void );

		monster_muzzleflash( vecMuzzle, 128, 128, 255 );
		monster_fire_weapon( q2npc::WEAPON_RAILGUN, vecMuzzle, m_vecEnemyDir, RAILGUN_DAMAGE );
	}

	bool CheckRangeAttack1( float flDot, float flDist )
	{
		// a small safe zone
		if( flDist <= (Q2_MELEE_DISTANCE + 32) )
				return false;

		if( M_CheckAttack(flDist) )
			return true;

		return false;
	}

	bool CheckMeleeAttack1( float flDot, float flDist )
	{
		if( flDist <= 64 and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND) )
			return true;

		return false;
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

		return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
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

	void GibMonster()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_DEATH_GIB], VOL_NORM, ATTN_NORM );

		ThrowGib( 2, MODEL_GIB_BONE, pev.dmg, -1 );
		ThrowGib( 2, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		ThrowGib( 1, MODEL_GIB_THIGH, pev.dmg, 3 );
		ThrowGib( 1, MODEL_GIB_THIGH, pev.dmg, 14 );
		ThrowGib( 1, MODEL_GIB_LARM, pev.dmg, 10 );
		ThrowGib( 1, MODEL_GIB_RARM, pev.dmg, 8 );
		ThrowGib( 1, MODEL_GIB_CHEST, pev.dmg, 5 );
		ThrowGib( 1, MODEL_GIB_HEAD, pev.dmg, 6, BREAK_FLESH );

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
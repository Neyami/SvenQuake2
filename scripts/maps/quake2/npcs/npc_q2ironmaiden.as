namespace npc_q2ironmaiden
{

const string NPC_MODEL				= "models/quake2/monsters/ironmaiden/ironmaiden.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_ARM			= "models/quake2/monsters/ironmaiden/gibs/arm.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/ironmaiden/gibs/chest.mdl";
const string MODEL_GIB_FOOT		= "models/quake2/monsters/ironmaiden/gibs/foot.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/ironmaiden/gibs/head.mdl";
const string MODEL_GIB_TUBE		= "models/quake2/monsters/ironmaiden/gibs/tube.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 56 ); //80 in svencoop
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 ); //16, 16, 8 in original

const int NPC_HEALTH					= 175;

const int AE_MELEE						= 11;
const int AE_MELEE_REFIRE			= 12;
const int AE_ROCKET_LAUNCH		= 13;
const int AE_ROCKET_REFIRE			= 14;
const int AE_ROCKET_PRELAUNCH	= 15;
const int AE_ROCKET_RELOAD		= 16;
const int AE_FIDGETCHECK				= 17;

const float ROCKET_DMG				= 50;
const float ROCKET_SPEED				= 750;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/ironmaiden/chkidle1.wav",
	"quake2/npcs/ironmaiden/chkidle2.wav",
	"quake2/npcs/ironmaiden/chksght1.wav",
	"quake2/npcs/ironmaiden/chksrch1.wav",
	"quake2/npcs/ironmaiden/chkatck1.wav",
	"quake2/npcs/ironmaiden/chkatck2.wav",
	"quake2/npcs/ironmaiden/chkatck5.wav",
	"quake2/npcs/ironmaiden/chkatck3.wav",
	"quake2/npcs/ironmaiden/chkatck4.wav",
	"quake2/npcs/ironmaiden/chkpain1.wav",
	"quake2/npcs/ironmaiden/chkpain2.wav",
	"quake2/npcs/ironmaiden/chkpain3.wav",
	"quake2/npcs/ironmaiden/chkdeth1.wav",
	"quake2/npcs/ironmaiden/chkdeth2.wav",
	"quake2/npcs/ironmaiden/chkatck3.wav",
	"quake2/npcs/ironmaiden/chkatck4.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE1,
	SND_IDLE2,
	SND_SIGHT,
	SND_SEARCH,
	SND_ROCKET_PRELAUNCH,
	SND_ROCKET_LAUNCH,
	SND_ROCKET_RELOAD,
	SND_MELEE_SWING,
	SND_MELEE_HIT,
	SND_PAIN1,
	SND_PAIN2,
	SND_PAIN3
};

final class npc_q2ironmaiden : CBaseQ2NPC
{
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
			self.m_FormattedName	= "Iron Maiden";

		m_flGibHealth = -70.0;
		SetMass( 200 );

		@this.m_Schedules = @ironmaiden_schedules;

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
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
		g_Game.PrecacheModel( MODEL_GIB_TUBE );

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

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_IDLESOUND:
			{
				ChickMoan();
				break;
			}

			//I SURE WISH THE DEVS WOULD HAVE USED ONLY ONE WAY OF DETERMINING WHEN TO FIDGET :aRage:
			case AE_FIDGETCHECK:
			{
				chick_fidget();
				break;
			}

			case AE_MELEE:
			{
				ChickSlash();
				break;
			}

			case AE_MELEE_REFIRE:
			{
				chick_reslash();
				break;
			}

			case AE_ROCKET_PRELAUNCH:
			{
				ChickPreAttack();
				break;
			}

			case AE_ROCKET_LAUNCH:
			{
				ChickRocket();
				break;
			}

			case AE_ROCKET_REFIRE:
			{
				if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
				{
					if( (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length() > Q2_RANGE_MELEE and self.FVisible(self.m_hEnemy, true) and Math.RandomFloat(0.0, 1.0) <= 0.6 )
						SetFrame( 32, 11 );
				}

				break;
			}

			case AE_ROCKET_RELOAD:
			{
				ChickReload();
				break;
			}
		}
	}

	void chick_fidget()
	{
		if( !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) )
		{
			/*if( HasFlags(monsterinfo.aiflags, AI_STAND_GROUND) )
				return;
			else */if( self.m_hEnemy.IsValid() )
				return;

			if( Math.RandomFloat(0.0, 1.0) <= 0.3 )
				self.ChangeSchedule( slChickFidget );
		}
	}

	void ChickMoan()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_IDLE1, SND_IDLE2)], VOL_NORM, ATTN_IDLE );
	}

	void ChickSlash()
	{
		if( m_bRerelease )
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE_RR, pev.mins.x, 10 );
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
			fire_hit( aim, Math.RandomFloat(10.0, 16.0), 100 );
		}
		else
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE, pev.mins.x, 10 );
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_MELEE_SWING], VOL_NORM, ATTN_NORM );
			fire_hit( aim, 10 + Math.RandomFloat(0.0, 6.0), 100 ); //(10 + (rand() %6))
		}
	}

	void chick_reslash()
	{
		if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.health > 0 )
		{
			float flDistance = m_bRerelease ? Q2_MELEE_DISTANCE_RR : Q2_MELEE_DISTANCE;

			if( (pev.origin - self.m_hEnemy.GetEntity().pev.origin).Length() <= flDistance and Math.RandomFloat(0.0, 1.0) <= 0.9 )
				SetFrame( 16, 3 );
		}
	}

	void ChickPreAttack()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_ROCKET_PRELAUNCH], VOL_NORM, ATTN_NORM );
	}

	void ChickReload()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_ROCKET_RELOAD], VOL_NORM, ATTN_NORM );
	}

	void ChickRocket()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ROCKET_LAUNCH], VOL_NORM, ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 384, 0.3, self );

		Vector vecMuzzle, vecAim;

		if( self.m_hEnemy.IsValid() )
		{
			self.GetAttachment( 0, vecMuzzle, void );

			// don't shoot at feet if they're above where i'm shooting from.
			if( Math.RandomFloat(0.0, 1.0) < 0.66 or vecMuzzle.z < self.m_hEnemy.GetEntity().pev.absmin.z )
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z += self.m_hEnemy.GetEntity().pev.view_ofs.z;
				vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
			}
			else
			{
				Vector vecEnemyOrigin = self.m_hEnemy.GetEntity().pev.origin;
				vecEnemyOrigin.z = self.m_hEnemy.GetEntity().pev.absmin.z + 1;
				vecAim = (vecEnemyOrigin - vecMuzzle).Normalize();
			}

			Vector vecTrace;

			if( Math.RandomFloat(0.0, 1.0) < 0.35 )
				PredictAim( self.m_hEnemy, vecMuzzle, ROCKET_SPEED, false, 0.0, vecAim, vecTrace );

			// paranoia, make sure we're not shooting a target right next to us
			TraceResult tr;
			g_Utility.TraceLine( vecMuzzle, vecTrace, missile, self.edict(), tr );
			if( tr.flFraction > 0.5 or tr.fAllSolid == 0 ) //trace.ent->solid != SOLID_BSP
			{
				monster_muzzleflash( vecMuzzle, 255, 128, 51 );
				monster_fire_weapon( q2::WEAPON_ROCKET, vecMuzzle, vecAim, ROCKET_DMG, ROCKET_SPEED );
			}
		}
	}

	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
	{
		if( M_CheckAttack(flDist) )
			return true;

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
			return;

		m_flPainDebounceTime = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[Math.RandomLong(SND_PAIN1, SND_PAIN3)], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return; // no pain anims in nightmare

		if( flDamage <= 10 )
			self.ChangeSchedule( slQ2Pain1 );
		else if( flDamage <= 25 )
			self.ChangeSchedule( slQ2Pain2 );
		else
			self.ChangeSchedule( slQ2Pain3 );
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
		q2::ThrowGib( self, 3, MODEL_GIB_MEAT, pev.dmg, -1, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_ARM, pev.dmg, 24, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_FOOT, pev.dmg, Math.RandomLong(0, 1) == 0 ? 33 : 36, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_TUBE, pev.dmg, 5 );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH );
	}
}

array<ScriptSchedule@>@ ironmaiden_schedules;

ScriptSchedule slChickFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Chick Idle Fidgeting"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slChickFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slChickFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_TWITCH)) );
	slChickFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2, slQ2Pain3 };

	@ironmaiden_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	q2projectiles::RegisterProjectile( "rocket" );

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2ironmaiden::npc_q2ironmaiden", "npc_q2ironmaiden" );
	g_Game.PrecacheOther( "npc_q2ironmaiden" );
}

} //end of namespace npc_q2ironmaiden

/* FIXME
*/

/* TODO
	Use schedules for refire instead of setframe
	Move death-sounds to script ??
	Update fidget
*/
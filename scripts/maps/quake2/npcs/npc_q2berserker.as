namespace npc_q2berserker
{

const string NPC_MODEL				= "models/quake2/monsters/berserker/berserker.mdl";
const string MODEL_GIB_BONE		= "models/quake2/objects/gibs/bone.mdl";
const string MODEL_GIB_GEAR		= "models/quake2/objects/gibs/gear.mdl";
const string MODEL_GIB_MEAT		= "models/quake2/objects/gibs/sm_meat.mdl";
const string MODEL_GIB_CHEST		= "models/quake2/monsters/berserker/gibs/chest.mdl";
const string MODEL_GIB_HAMMER	= "models/quake2/monsters/berserker/gibs/hammer.mdl";
const string MODEL_GIB_HEAD		= "models/quake2/monsters/berserker/gibs/head.mdl";
const string MODEL_GIB_THIGH		= "models/quake2/monsters/berserker/gibs/thigh.mdl";

const Vector NPC_MINS					= Vector( -16, -16, 0 );
const Vector NPC_MAXS					= Vector( 16, 16, 56 ); //80 in svencoop
const Vector NPC_MINS_DEAD		= Vector( -16, -16, 0 );
const Vector NPC_MAXS_DEAD		= Vector( 16, 16, 8 );

const int NPC_HEALTH					= 240;

const int AE_ATTACK_SPIKE			= 11;
const int AE_ATTACK_CLUB				= 12;
const int AE_ATTACKSOUND			= 13;
const int AE_FIDGETCHECK				= 14;

const array<string> arrsNPCSounds =
{
	"quake2/misc/udeath.wav",
	"quake2/npcs/berserker/beridle1.wav",
	"quake2/npcs/berserker/idle.wav",
	"quake2/npcs/berserker/sight.wav",
	"quake2/npcs/berserker/bersrch1.wav",
	"quake2/npcs/berserker/attack.wav",
	"quake2/npcs/berserker/berpain2.wav",
	"quake2/npcs/berserker/berdeth2.wav"
};

enum q2sounds_e
{
	SND_DEATH_GIB = 0,
	SND_IDLE1,
	SND_IDLE2,
	SND_SIGHT,
	SND_SEARCH,
	SND_ATTACK,
	SND_PAIN,
	SND_DEATH
};

const array<string> arrsNPCAnims =
{
	"death1",
	"death2"
};

enum anim_e
{
	ANIM_DEATH1 = 0,
	ANIM_DEATH2
};

final class npc_q2berserker : CBaseQ2NPC
{
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
		self.m_flFieldOfView		= 0.5;
		self.m_afCapability			= bits_CAP_DOORS_GROUP;

		if( string(self.m_FormattedName).IsEmpty() )
			self.m_FormattedName	= "Berserker";

		m_flGibHealth = -60.0;
		SetMass( 250 );

		@this.m_Schedules = @berserker_schedules;

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
		g_Game.PrecacheModel( MODEL_GIB_GEAR );
		g_Game.PrecacheModel( MODEL_GIB_MEAT );
		g_Game.PrecacheModel( MODEL_GIB_CHEST );
		g_Game.PrecacheModel( MODEL_GIB_HAMMER );
		g_Game.PrecacheModel( MODEL_GIB_HEAD );
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

	void MonsterSight()
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SIGHT], VOL_NORM, ATTN_NORM );
	}

	void MonsterSearch()
	{
		if( Math.RandomLong(0, 1) == 1 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_IDLE2], VOL_NORM, ATTN_NORM );
		else
			g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_SEARCH], VOL_NORM, ATTN_NORM );
	}

	void DeathSound() 
	{
		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_DEATH], VOL_NORM, ATTN_NORM );
	}

	void berserk_fidget()
	{
		if( !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) )
		{
			/*if( HasFlags(monsterinfo.aiflags, AI_STAND_GROUND) )
				return;
			else */if( self.m_hEnemy.IsValid() )
				return;

			if( Math.RandomFloat(0.0, 1.0) > 0.15 )
				return;

			self.ChangeSchedule( slBerserkerFidget );
			//the original plays this out of sync with the animation
			//g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_IDLE1], VOL_NORM, ATTN_IDLE );
		}
	}

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_IDLESOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_IDLE1], VOL_NORM, ATTN_IDLE );
				break;
			}

			//I SURE WISH THE DEVS WOULD HAVE USED ONLY ONE WAY OF DETERMINING WHEN TO FIDGET :aRage:
			case AE_FIDGETCHECK:
			{
				berserk_fidget();
				break;
			}

			case AE_ATTACKSOUND:
			{
				g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, arrsNPCSounds[SND_ATTACK], VOL_NORM, ATTN_NORM );
				break;
			}

			case AE_ATTACK_SPIKE:
			{
				berserk_attack_spike();
				break;
			}

			case AE_ATTACK_CLUB:
			{
				berserk_attack_club();
				break;
			}
		}
	}

	//Faster attack -- upwards and backwards
	void berserk_attack_spike()
	{
		if( m_bRerelease )
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE_RR, 0, -24 );

			if( !fire_hit(aim, Math.RandomFloat(5.0, 11.0), 80) )
				monsterinfo.melee_debounce_time = g_Engine.time + 1.2;
		}
		else
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE, 0, -24 );
			fire_hit( aim, 15 + Math.RandomFloat(0.0, 6.0), 400 ); //(15 + (rand() % 6))
		}
	}

	//Slower attack
	void berserk_attack_club()
	{
		if( m_bRerelease )
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE_RR, pev.mins.x, -4 );

			if( !fire_hit(aim, Math.RandomFloat(15.0, 21.0), 400) )
				monsterinfo.melee_debounce_time = g_Engine.time + 2.5;
		}
		else
		{
			Vector aim = Vector( Q2_MELEE_DISTANCE, pev.mins.x, -4 );
			fire_hit( aim, 5 + Math.RandomFloat(0.0, 6.0), 400 ); //(5 + (rand() % 6))
		}
	}

	bool CheckMeleeAttack2( float flDot, float flDist ) { return false; }
	bool CheckRangeAttack2( float flDot, float flDist ) { return false; }

	bool CheckRangeAttack1( float flDot, float flDist ) //flDist > 64 and flDist <= 784 and flDot >= 0.5
	{
		//if( M_CheckAttack(flDist) )
			//return true;

		return false;
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
		// if we're jumping, don't pain
		/*if ((self.monsterinfo.active_move == &berserk_move_jump) ||
			(self.monsterinfo.active_move == &berserk_move_jump2) ||
			(self.monsterinfo.active_move == &berserk_move_attack_strike))
		{
			return;
		}*/

		if( g_Engine.time < pain_debounce_time )
			return;

		pain_debounce_time = g_Engine.time + 3.0;

		g_SoundSystem.EmitSound( self.edict(), CHAN_VOICE, arrsNPCSounds[SND_PAIN], VOL_NORM, ATTN_NORM );

		if( !M_ShouldReactToPain() )
			return;

		if( flDamage <= 50 or Math.RandomFloat(0.0, 1.0) < 0.5 )
			self.ChangeSchedule( slQ2Pain1 );
		else
			self.ChangeSchedule( slQ2Pain2 );
	}

	void StartTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_DIE:
			{
				if( pev.dmg >= 50 )
					SetAnim( ANIM_DEATH1 );
				else
					SetAnim( ANIM_DEATH2 );

				break;
			}

			default:
			{			
				BaseClass.StartTask( pTask );
				break;
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
		q2::ThrowGib( self, 1, MODEL_GIB_GEAR, pev.dmg, -1, BREAK_METAL );
		q2::ThrowGib( self, 1, MODEL_GIB_CHEST, pev.dmg, 2, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HAMMER, pev.dmg, 10, BREAK_CONCRETE );
		q2::ThrowGib( self, 1, MODEL_GIB_THIGH, pev.dmg, Math.RandomLong(0, 1) == 0 ? 11 : 15, BREAK_FLESH );
		q2::ThrowGib( self, 1, MODEL_GIB_HEAD, pev.dmg, 3, BREAK_FLESH );
	}
}

array<ScriptSchedule@>@ berserker_schedules;

ScriptSchedule slBerserkerFidget
(
	bits_COND_NEW_ENEMY		|
	bits_COND_SEE_FEAR			|
	bits_COND_LIGHT_DAMAGE	|
	bits_COND_HEAVY_DAMAGE	|
	bits_COND_PROVOKED,
	0,
	"Berserker Idle Fidgeting"
);

void InitSchedules()
{
	InitQ2BaseSchedules();

	slBerserkerFidget.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slBerserkerFidget.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_TWITCH)) );
	slBerserkerFidget.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_IDLE)) );

	array<ScriptSchedule@> scheds = { slQ2Pain1, slQ2Pain2 };

	@berserker_schedules = @scheds;
}

void Register()
{
	InitSchedules();

	g_CustomEntityFuncs.RegisterCustomEntity( "npc_q2berserker::npc_q2berserker", "npc_q2berserker" );
	g_Game.PrecacheOther( "npc_q2berserker" );
}

} //end of namespace npc_q2berserker

/* FIXME
*/

/* TODO
	Add stuff from rerelease ??
	Update fidget
*/
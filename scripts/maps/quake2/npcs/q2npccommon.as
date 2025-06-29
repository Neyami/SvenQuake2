const float Q2_MELEE_DISTANCE		= 80.0;
const float Q2_MELEE_DISTANCE_RR	= 64.0; //50 is too short
const float Q2_RANGE_MELEE				= 60.0; //20
const float Q2_RANGE_NEAR				= 440.0; //500
const float Q2_RANGE_MID					= 1000.0;
const float Q2_STEPSIZE					= 18.0;

enum steptype_e
{
	STEP_CONCRETE = 0, // default step sound
	STEP_METAL, // metal floor
	STEP_DIRT, // dirt, sand, rock
	STEP_VENT, // ventilation duct
	STEP_GRATE, // metal grating
	STEP_TILE, // floor tiles
	STEP_SLOSH, // shallow liquid puddle
	STEP_WADE, // wading in liquid
	STEP_LADDER, // climbing ladder
	STEP_WOOD,
	STEP_FLESH,
	STEP_SNOW
};

class monsterinfo_t
{
	//mmove_t@	currentmove;
	int64							aiflags;
	/*int							nextframe;
	float							scale;

	bool							has_search;
	//funcdef void	stand(); //CBaseEntity@ self 
	//funcdef void	idle(); //CBaseEntity@ self
	//funcdef void search( CBaseEntity@ self );
	//funcdef void walk( CBaseEntity@ self );
	//funcdef void	run(); //CBaseEntity@ self
	//funcdef void dodge( CBaseEntity@ self, CBaseEntity@ other, float eta );
	//funcdef void attack( CBaseEntity@ self );
	//funcdef void melee( CBaseEntity@ self );
	//funcdef void	sight( CBaseEntity@ other ); //CBaseEntity@ self, 
	//funcdef void checkattack( CBaseEntity@ self );

	float							pausetime;*/
	float							attack_finished;

	/*Vector						saved_goal;
	float							search_time;
	float							trail_time;
	Vector						last_sighting;
	int							attack_state;
	bool							lefty;
	float							idle_time;
	int							linkcount;*/

	int							power_armor_type;
	int							power_armor_power;

	int							medicTries;
	EHandle					badMedic1, badMedic2; // these medics have declared this monster "unhealable"
	EHandle					healer;

	bool							can_jump; // will the monster jump?
	float							drop_height;
	float							jump_height;

	// used by the spawners to not spawn too much and keep track of #s of monsters spawned
	int							monster_slots; // nb: for spawned monsters, this is how many slots we took from our commander
	int							monster_used;
	EHandle					commander;

	float							melee_debounce_time; // don't melee until this time has passed 
	float							base_health; // health that we had on spawn, before any co-op adjustments
	int							health_scaling; // number of players we've been scaled up to 

	float							surprise_time;
	/*//PathInfo				nav_path; // if AI_PATHING, this is where we are trying to reach 

	// alternate flying mechanics
	float							fly_max_distance, fly_min_distance; // how far we should try to stay
	float							fly_acceleration; // accel/decel speed
	float							fly_speed; // max speed from flying
	Vector						fly_ideal_position; // ideally where we want to end up to hover, relative to our target if not pinned
	float							fly_position_time; // if <= level.time, we can try changing positions //gtime_t
	bool							fly_buzzard, fly_above; // orbit around all sides of their enemy, not just the sides
	bool							fly_pinned; // whether we're currently pinned to ideal position (made absolute)
	bool							fly_thrusters; // slightly different flight mechanics, for melee attacks
	float							fly_recovery_time; //gtime_t // time to try a new dir to get away from hazards
	Vector						fly_recovery_dir;*/

	float							react_to_damage_time;

	reinforcement_list_t	reinforcements; 
	array<uint8>				chosen_reinforcements; // readied for spawn; 255 is value for none //std::array<uint8_t, MAX_REINFORCEMENTS>

	float							jump_time;

	monsterinfo_t() {} // Constructor (optional)
}

class reinforcement_t
{
	string classname;
	int strength;
	Vector mins, maxs;
}

class reinforcement_list_t
{
	array<reinforcement_t@> reinforcements;
	int num_reinforcements;
}

const int MAX_REINFORCEMENTS = 5; // max number of spawns we can do at once.
const float inverse_log_slots = pow( 2, MAX_REINFORCEMENTS );

class CBaseQ2NPC : ScriptBaseMonsterEntity
{
	protected bool m_bRerelease = true; //should monsters have stuff from the rerelease of Quake 2 ?

	monsterinfo_t monsterinfo;

	int m_iSpawnFlags;
	int m_iMonsterFlags; //edict->flags
	int m_iEffects;

	float m_flGibHealth;
	protected float m_flAttackFinished;
	protected float m_flIdleTime;
	protected float m_flNextFidget;
	protected float m_flHeatTurnRate; //for heat-seeking rockets
	protected float m_flHealthMultiplier = 1.0;
	float pain_debounce_time;
	protected float m_flFlySoundDebounceTime;
	protected float m_flTriggeredSpawn;

	protected int m_iStepLeft;
	protected int m_iWeaponType;

	protected float m_flArmorEffectOff;

	protected string m_sItemDrop;
	string m_sItemTarget;
	string m_sDeathTarget;
	string m_sHealthTarget;
	protected bool m_bHasBeenCounted;
	protected bool m_bSound;

	protected Vector m_vecAttackDir; //g_vecAttackDir

	protected array<string> arrsQ2NPCAnims;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "is_player_ally" )
		{
			if( atoi(szValue) >= 1 )
				self.SetPlayerAllyDirect( true );

			return true;
		}
		else if( szKey == "health_multiplier" )
		{
			m_flHealthMultiplier = atof( szValue );

			return true;
		}
		else if( szKey == "power_armor_type" )
		{
			if( atoi(szValue) == 1 )
				monsterinfo.power_armor_type = q2::POWER_ARMOR_SCREEN;
			else if( atoi(szValue) == 2 )
				monsterinfo.power_armor_type = q2::POWER_ARMOR_SHIELD;
			else
				monsterinfo.power_armor_type = q2::POWER_ARMOR_NONE;

			return true;
		}
		else if( szKey == "power_armor_power" )
		{
			monsterinfo.power_armor_power = atoi( szValue );

			return true;
		}
		else if( szKey == "item" )
		{
			m_sItemDrop = szValue;

			return true;
		}
		else if( szKey == "itemtarget" )
		{
			m_sItemTarget = szValue;

			return true;
		}
		else if( szKey == "deathtarget" )
		{
			m_sDeathTarget = szValue;

			return true;
		}
		else if( szKey == "healthtarget" )
		{
			m_sHealthTarget = szValue;

			return true;
		}
		else if( szKey == "weapontype" )
		{
			m_iWeaponType = atoi( szValue );

			return true;
		}
		else if( MonsterKeyValue(szKey, szValue) )
			return true;
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	bool MonsterKeyValue( const string& in szKey, const string& in szValue ) { return false; }

	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) or q2::PVP )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		if( q2npc::g_iChaosMode == q2::CHAOS_LEVEL1 )
		{
			if( q2npc::g_iDifficulty < q2::DIFF_NIGHTMARE )
				m_iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_RAILGUN );
			else
				m_iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_BFG );
		}

		m_iSpawnFlags = pev.spawnflags;
		pev.spawnflags = 0;

		MonsterSpawn();

		if( !HasFlags(monsterinfo.aiflags, q2::AI_DO_NOT_COUNT) and !self.IsPlayerAlly() )
			q2::g_iTotalMonsters++;

		if( HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_TRIGGER_SPAWN) )
		{
			pev.nextthink = 0;
			pev.flags |= FL_NOTARGET;
			pev.effects |= EF_NODRAW;
			pev.takedamage = DAMAGE_NO;
			pev.solid = SOLID_NOT;
			pev.movetype = MOVETYPE_NONE;
		}

		q2npc::G_Monster_ScaleCoopHealth( self );

		// Paril: monsters' old default viewheight (25)
		// is all messed up for certain monsters. Calculate
		// from maxs to make a bit more sense.
		pev.view_ofs.z = pev.maxs.z - 8.0;

		g_EntityFuncs.SetOrigin( self, pev.origin ); //??
	}

	void MonsterSpawn() { }

	void monster_triggered_spawn()
	{
		pev.origin.z += 1;
		q2::KillBox( self );

		pev.flags &= ~FL_NOTARGET;
		pev.effects &= ~EF_NODRAW;
		pev.takedamage = DAMAGE_AIM;
		pev.solid = SOLID_SLIDEBOX;
		pev.movetype = MOVETYPE_STEP;

		//if( self.m_hEnemy.IsValid() and !pev.SpawnFlagBitSet(q2::SPAWNFLAG_MONSTER_AMBUSH) and !self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_NOTARGET) )
		if( pev.enemy !is null and !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) and !pev.enemy.vars.FlagBitSet(FL_NOTARGET) )
		{
			self.m_hEnemy = EHandle( g_EntityFuncs.Instance(pev.enemy) );
			self.ChangeSchedule( self.GetScheduleOfType(SCHED_CHASE_ENEMY) );
		}
		else
			self.m_hEnemy = null;
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_TRIGGER_SPAWN) )
		{
			m_iSpawnFlags &= ~q2::SPAWNFLAG_MONSTER_TRIGGER_SPAWN;

			// we have a one frame delay here so we don't telefrag the guy who activated us
			m_flTriggeredSpawn = pev.nextthink = g_Engine.time + q2::FRAMETIME;

			if( pActivator.pev.FlagBitSet(FL_CLIENT) )
				@pev.enemy = pActivator.edict(); //self.m_hEnemy gets reset
		}
		else if( self.IsPlayerAlly() )
		{
			self.FollowerPlayerUse( pActivator, pCaller, useType, flValue );
			/*CBaseEntity@ pTarget = self.m_hTargetEnt;
			
			if( pTarget is pActivator )
				g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_OK", 1.0, ATTN_NORM, 0, PITCH_NORM );
			else
				g_SoundSystem.PlaySentenceGroup( self.edict(), "BA_WAIT", 1.0, ATTN_NORM, 0, PITCH_NORM );*/
		}
		else
		{
			if( self.m_hEnemy.IsValid() )
				return;

			if( pev.health <= 0 )
				return;

			if( pActivator.pev.FlagBitSet(FL_NOTARGET) )
				return;

			if( !pActivator.pev.FlagBitSet(FL_CLIENT) and !pActivator.IsPlayerAlly() )
				return;

			self.m_hEnemy = EHandle( pActivator );
			self.ChangeSchedule( self.GetScheduleOfType(SCHED_CHASE_ENEMY) );
		}
	}

	bool CheckMeleeAttack1( float flDot, float flDist ) { return CheckMeleeAttackBase( flDot, flDist ); }

	bool CheckMeleeAttack2( float flDot, float flDist ) { return CheckMeleeAttackBase( flDot, flDist ); }

	bool CheckMeleeAttackBase( float flDot, float flDist )
	{
		if( m_bRerelease )
		{
			if( g_Engine.time < monsterinfo.melee_debounce_time )
				return false;

			if( flDist <= Q2_MELEE_DISTANCE_RR /*and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND)*/ )
				return true;
		}
		else
		{
			//don't always melee in easy mode (75% chance?)
			if( q2npc::g_iDifficulty == q2::DIFF_EASY and (Math.RandomLong(0, 32767) & 3) != 0 ) //(rand()&3)
				return false;

			if( flDist <= Q2_MELEE_DISTANCE /*and flDot >= 0.7 and self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_ONGROUND)*/ )
				return true;
		}

		return false;
	}

	int TakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		float psave = CheckPowerArmor( pevInflictor, flDamage );
		flDamage -= psave;

		SetSkin();

		if( pevAttacker !is self.pev )
		{
			if( self.IRelationship(g_EntityFuncs.Instance(pevAttacker)) > R_NO )
				pevAttacker.frags += ( flDamage/90 );
			else
				pevAttacker.frags -= ( flDamage/90 );
		}

		pev.dmg = flDamage;

		if( pev.deadflag == DEAD_NO )
			MonsterPain( flDamage );

		M_ReactToDamage( g_EntityFuncs.Instance(pevAttacker) );

		if( pev.deadflag == DEAD_NO )
			return BaseClass.TakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
		else
			return DeadTakeDamage( pevInflictor, pevAttacker, flDamage, bitsDamageType );
	}

	void MonsterPain( float flDamage ) {}

	bool TakeHealth( float flHealth, int bitsDamageType, int health_cap = 0 )
	{
		SetSkin();
		return BaseClass.TakeHealth( flHealth, bitsDamageType, health_cap = 0 );
	}

	int DeadTakeDamage( entvars_t@ pevInflictor, entvars_t@ pevAttacker, float flDamage, int bitsDamageType )
	{
		int iMod = 0;
		if( HasFlags(bitsDamageType, DMG_CRUSH) )
			iMod = q2::MOD_CRUSH;

		if( M_CheckGib(iMod) )
		{
			Killed( pevAttacker, GIB_ALWAYS );
			return 0;
		}

		pev.health -= flDamage;

		return 1;
	}

	void Killed( entvars_t@ pevAttacker, int iGib )
	{
		if( !m_sItemDrop.IsEmpty() )
		{
			CBaseEntity@ pDropped = DropItem( m_sItemDrop );

			if( !m_sItemTarget.IsEmpty() )
			{
				pDropped.pev.target = m_sItemTarget;
				m_sItemTarget = "";
			}

			m_sItemDrop = "";
		}

		if( !m_sDeathTarget.IsEmpty() )
			pev.target = m_sDeathTarget;

		if( !string(pev.target).IsEmpty() or !string(self.m_iszKillTarget).IsEmpty() )
			self.SUB_UseTargets( self.m_hEnemy.GetEntity(), USE_ON, 0.0 );

		//fire health target (when damaged and killed)
		if( !m_sHealthTarget.IsEmpty() )
		{
			pev.target = m_sHealthTarget;
			self.SUB_UseTargets( self.m_hEnemy.GetEntity(), USE_ON, 0.0 );
		}

		if( !HasFlags(monsterinfo.aiflags, q2::AI_DO_NOT_COUNT) and !self.IsPlayerAlly() and !m_bHasBeenCounted )
		{
			q2::g_iKilledMonsters++;
			m_bHasBeenCounted = true;
		}

		MonsterKilled( pevAttacker, iGib );

		if( self.GetClassname() == "npc_q2jorg" or self.GetClassname() == "npc_q2makron" )
			iGib = GIB_NEVER;

		BaseClass.Killed( pevAttacker, iGib );
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib ) {}

	void GibMonster()
	{
		//medic commander only gets his slots back after the monster is gibbed, since we can revive them
		if( HasFlags(monsterinfo.aiflags, q2::AI_SPAWNED_MEDIC_C) )
		{
			if( monsterinfo.commander.IsValid() and monsterinfo.commander.GetEntity().pev.ClassNameIs("npc_q2medic_commander") )
			{
				CBaseQ2NPC@ pMonster = q2npc::GetQ2Pointer( monsterinfo.commander.GetEntity() );
				pMonster.monsterinfo.monster_used -= monsterinfo.monster_slots;
			}

			monsterinfo.commander = null;
		}

		MonsterGib();
	}

	void MonsterGib() {}

	void RunTask( Task@ pTask )
	{
		switch( pTask.iTask )
		{
			case TASK_DIE:
			{
				//g_Game.AlertMessage( at_notice, "TASK_DIE!\n" );
				if( self.m_fSequenceFinished and pev.frame >= 255 )
				{
					pev.deadflag = DEAD_DEAD;

					SetThink( null );
					self.StopAnimation();

					MonsterDead();
				}

				break;
			}

			default:
			{
				MonsterRunTask( pTask );

				break;
			}
		}
	}

	void MonsterRunTask( Task@ pTask ) { BaseClass.RunTask( pTask ); }
	void MonsterDead() {}

	void monster_dead_think_base()
	{
		// flies
		if( HasFlags(monsterinfo.aiflags, q2::AI_STINKY) and !HasFlags(monsterinfo.aiflags, q2::AI_STUNK) ) //Value is too large for data type ??
		{
			if( m_flFlySoundDebounceTime == 0 )
				m_flFlySoundDebounceTime = g_Engine.time + Math.RandomFloat( 1.0, 2.0 ); //5, 15
			else if( m_flFlySoundDebounceTime < g_Engine.time )
			{
				if( !m_bSound )
				{
					m_iEffects |= q2::EF_FLIES;
					g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "quake2/npcs/enforcer/inflies1.wav", VOL_NORM, ATTN_NORM, SND_FORCE_LOOP );
					m_bSound = true;
					m_flFlySoundDebounceTime = g_Engine.time + 60.0;
				}
				else
				{
					m_iEffects &= ~q2::EF_FLIES;
					g_SoundSystem.StopSound( self.edict(), CHAN_BODY, "quake2/npcs/enforcer/inflies1.wav" );
					m_bSound = false;
					monsterinfo.aiflags |= q2::AI_STUNK;
				}
			}
		}

		/*if (!self->monsterinfo.damage_blood)
		{
			if (self->s.frame != self->monsterinfo.active_move->lastframe)
				self->s.frame++;
		}*/

		pev.nextthink = g_Engine.time + 0.1;
	}

	void monster_dead_base()
	{
		//SetThink( ThinkFunction(this.monster_dead_think) );
		//SetThink( ThinkFunction(cast<CBaseQ2NPC@>(@self).monster_dead_think) );
		//SetThink( ThinkFunction(cast<CBaseQ2NPC@>(CastToScriptClass(self)).monster_dead_think) );
		pev.nextthink = g_Engine.time + 0.1;
		pev.movetype = MOVETYPE_TOSS;
		//pev.solid = SOLID_NOT;
		//self->svflags |= SVF_DEADMONSTER;
		//self->monsterinfo.damage_blood = 0;
		m_flFlySoundDebounceTime = 0;
		monsterinfo.aiflags &= ~q2::AI_STUNK;
		g_EntityFuncs.SetOrigin( self, pev.origin ); //gi.linkentity(self);
	}

	void monster_duck_up()
	{
		if( !HasFlags(monsterinfo.aiflags, q2::AI_DUCKED) )
			return;

		monsterinfo.aiflags &= ~q2::AI_DUCKED;
		//self->maxs[2] = self->monsterinfo.base_height;
		pev.takedamage = DAMAGE_YES;
		// we finished a duck-up successfully, so cut the time remaining in half
		//if (self->monsterinfo.next_duck_time > level.time)
			//self->monsterinfo.next_duck_time = level.time + ((self->monsterinfo.next_duck_time - level.time) / 2);

		g_EntityFuncs.SetOrigin( self, pev.origin ); //gi.linkentity(self);
	}

	void monster_jump_start()
	{
		monster_done_dodge();

		monsterinfo.jump_time = g_Engine.time + 3.0;
	}

	void monster_done_dodge()
	{
		monsterinfo.aiflags &= ~q2::AI_DODGING;
		//if (monsterinfo.attack_state == AS_SLIDING)
			//monsterinfo.attack_state = AS_STRAIGHT;
	}

	bool monster_jump_finished()
	{
		// if we lost our forward velocity, give us more
		Vector vecForward;

		g_EngineFuncs.AngleVectors( pev.angles, vecForward, void, void );

		Vector forward_velocity = Vector( pev.velocity.x * vecForward.x, pev.velocity.y * vecForward.y, pev.velocity.z * vecForward.x ); //pev.velocity.scaled( vecForward );

		if( forward_velocity.Length() < 150.0 )
		{
			float z_velocity = pev.velocity.z;
			pev.velocity = vecForward * 150.0;
			pev.velocity.z = z_velocity;
		}

		return monsterinfo.jump_time < g_Engine.time;
	}

	CBaseEntity@ DropItem( string sItemName )
	{
		CBaseEntity@ pDropped = g_EntityFuncs.Create( sItemName, pev.origin, g_vecZero, true, self.edict() );
		if( pDropped !is null )
		{
			pDropped.pev.spawnflags = q2items::SF_NO_RESPAWN;
			//pDropped->s.renderfx = RF_GLOW;
			//VectorSet (pDropped->mins, -15, -15, -15);
			//VectorSet (pDropped->maxs, 15, 15, 15);
			pDropped.pev.movetype = MOVETYPE_TOSS;  
			//dropped->touch = drop_temp_touch;

			Vector vecForward;
			g_EngineFuncs.AngleVectors( pev.angles, vecForward, void, void );
			pDropped.pev.origin = pev.origin;

			//G_FixStuckObject(dropped, dropped->s.origin); //needed ?? use CheckStuckPlayer from plugin_teleport if so

			pDropped.pev.velocity = vecForward * 100;
			pDropped.pev.velocity.z = 300;

			//pDropped->think = drop_make_touchable;
			//pDropped->nextthink = level.time + 1;

			g_EntityFuncs.DispatchSpawn( pDropped.edict() );
		}
		else
			g_Game.AlertMessage( at_notice, "DropItem Invalid item: %1\n", sItemName );

		return pDropped;
	}

	int ObjectCaps()
	{
		if( self.IsPlayerAlly() ) 
			return (BaseClass.ObjectCaps() | FCAP_IMPULSE_USE);

		return BaseClass.ObjectCaps();
	}

	int IgnoreConditions()
	{
		return ( bits_COND_SEE_FEAR | bits_COND_LIGHT_DAMAGE | bits_COND_HEAVY_DAMAGE );
	}

	void RunAI()
	{
		if( m_flTriggeredSpawn > 0 )
		{
			m_flTriggeredSpawn = 0.0;
			monster_triggered_spawn();
		}

		BaseClass.RunAI();

		//to test model's eye height
		//g_EngineFuncs.ParticleEffect( pev.origin + pev.view_ofs, g_vecZero, 255, 10 );

		DoMonsterIdle();
		DoMonsterSearch();
		CheckArmorEffect();
		M_SetEffects();

		MonsterRunAI();
	}

	void MonsterRunAI() {}

	bool ShouldFidget()
	{
		/*if( g_Engine.time > m_flNextFidget )
		{
			if( m_flNextFidget > 0.0 )
			{
				m_flNextFidget = g_Engine.time + Math.RandomFloat( 15.0, 30.0 );
				return true;
			}
			else
				m_flNextFidget = g_Engine.time + Math.RandomFloat( 0.0, 15.0 );
		}

		return false;*/
		return ( !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) and !self.m_hEnemy.IsValid() and g_Engine.time > m_flIdleTime );
	}

	void DoMonsterIdle()
	{
		if( !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) and self.m_Activity == ACT_IDLE and g_Engine.time > m_flIdleTime )
		{
			if( m_flIdleTime > 0.0 )
			{
				MonsterIdle();
				m_flIdleTime = g_Engine.time + 15.0 + Math.RandomFloat(0.0, 1.0) * 15.0;
			}
			else
				m_flIdleTime = g_Engine.time + Math.RandomFloat(0.0, 1.0) * 15.0;
		}
	}

	void MonsterIdle() {}

	void DoMonsterSearch()
	{
		if( self.m_Activity == ACT_WALK and g_Engine.time > m_flIdleTime )
		{
			if( m_flIdleTime > 0.0 )
			{
				MonsterSearch();
				m_flIdleTime = g_Engine.time + 15 + Math.RandomFloat(0, 1) * 15;
			}
			else
				m_flIdleTime = g_Engine.time + Math.RandomFloat(0, 1) * 15;
		}
	}

	void MonsterSearch() {}

	void AlertSound()
	{
		if( HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) )
			m_iSpawnFlags &= ~q2::SPAWNFLAG_MONSTER_AMBUSH;

		MonsterSight();
	}

	void MonsterSight() {}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2::AE_WALKMOVE:
			{
				//it's too buggy for movement :[
				WalkMove( atoi(pEvent.options()) );

				break;
			}

			case q2::AE_FOOTSTEP:
			{
				if( m_bRerelease and !HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_AMBUSH) )
				{
					if( atoi(pEvent.options()) > 0 )
						monster_footstep( atoi(pEvent.options()) );
					else
						monster_footstep();
				}

				break;
			}

			//HACK
			case q2::AE_FLINCHRESET:
			{
				self.SetActivity( ACT_RESET );
				break;
			}

			default:
			{
				BaseClass.HandleAnimEvent( pEvent );
				break;
			}
		}

		MonsterHandleAnimEvent( pEvent );
	}

	void MonsterHandleAnimEvent( MonsterEvent@ pEvent ) {}

	bool M_CheckAttack( float flDist )
	{
		if( m_bRerelease )
			return M_CheckAttack_Base( flDist, 0.4, 0.25, 0.06, 0.0 );
		else
			return M_CheckAttack_Base( flDist, 0.2, 0.1, 0.02 );
	}

	bool M_CheckAttack_Base( float flDist, float flMeleeChance, float flNearChance, float flMidChance, float flFarChance = 0.0 )
	{
		float flChance;

		if( g_Engine.time < m_flAttackFinished )
			return false;

		if( !m_bRerelease )
		{
			if( flDist >= 1000 ) //RANGE_FAR (> 1000)
				return false;
		}

		if( flDist <= Q2_RANGE_MELEE )
			flChance = flMeleeChance;
		else if( flDist <= Q2_RANGE_NEAR )
			flChance = flNearChance;
		else if( flDist <= Q2_RANGE_MID )
			flChance = flMidChance;
		else if( !m_bRerelease )
			return false;
		else
			flChance = flFarChance;

		if( q2npc::g_iDifficulty == q2::DIFF_EASY )
			flChance *= 0.5;
		else if( q2npc::g_iDifficulty >= q2::DIFF_HARD )
			flChance *= 2.0;

		if( Math.RandomFloat(0.0, 1.0) < flChance )
		{
			m_flAttackFinished = g_Engine.time + Math.RandomFloat( 1.0, 2.0 ); //2*random();

			return true;
		}

		return true;
	}

	//TODO fix this ??
	void SetSkin() { MonsterSetSkin(); }
	void MonsterSetSkin() {}

	bool M_ShouldReactToPain( /*const int &in mod = 0*/ )
	{
		if( HasFlags(monsterinfo.aiflags, (q2::AI_DUCKED | q2::AI_COMBAT_POINT)) )
			return false;

		int mod = q2::GetMeansOfDeath( self );

		return mod == q2::MOD_CHAINFIST or q2npc::g_iDifficulty < q2::DIFF_NIGHTMARE;
	}

	void M_ReactToDamage( CBaseEntity@ pAttacker )
	{
		if( pAttacker !is null )
		{
			if( pAttacker.pev.FlagBitSet(FL_MONSTER | FL_CLIENT) )
			{
				if( !self.m_hEnemy.IsValid() and pev.health > 0 and !pAttacker.pev.FlagBitSet(FL_NOTARGET) and self.IRelationship(pAttacker) > R_NO ) //!(!pAttacker.pev.FlagBitSet(FL_CLIENT) and !pAttacker.IsPlayerAlly())
				{
					self.m_hEnemy = EHandle( pAttacker );
					self.ChangeSchedule( self.GetScheduleOfType(SCHED_CHASE_ENEMY) );
				}
			}
		}
	}

	bool M_CheckClearShot()
	{
		if( self.m_hEnemy.IsValid() and self.FVisible(self.m_hEnemy, true) ) 
			return true;

		return false;
	}

	bool M_CheckClearShot( Vector vecOrigin )
	{
		if( self.m_hEnemy.IsValid() and self.m_hEnemy.GetEntity().FVisible(vecOrigin) ) 
			return true;

		return false;
	}

	//THANK YOU FOR FIXING THIS, CHATGPT
	bool M_CalculatePitchToFire( const Vector &in vecTarget, const Vector &in vecStart, Vector& out vecAim, float flSpeed, float flTimeRemaining, bool bMortar, bool bDestroyOnTouch = false )
	{
		array<float> arrflPitches = { -80.0, -70.0, -60.0, -50.0, -40.0, -30.0, -20.0, -10.0, -5.0 };

		float flBestPitch = 0.0;
		float flBestDist = Math.FLOAT_MAX;

		const float flSimTime = 0.1;
		Vector vecPitchedAim = Math.VecToAngles( vecAim );

		for( uint i = 0; i < arrflPitches.length(); i++ )
		{
			float flPitch = arrflPitches[i];

			if( bMortar and flPitch >= -30.0 )
				break;

			vecPitchedAim.x = flPitch;
			vecPitchedAim.y = Math.VecToAngles(vecTarget - vecStart).y; //Set yaw towards target
			Math.MakeVectors( vecPitchedAim );
			Vector vecForward = g_Engine.v_forward;

			Vector vecVelocity = vecForward * flSpeed;
			Vector vecOrigin = vecStart;

			float flTime = flTimeRemaining;

			while( flTime > 0.0 )
			{
				vecVelocity.z -= g_EngineFuncs.CVarGetFloat("sv_gravity") * flSimTime;

				Vector vecEnd = vecOrigin + ( vecVelocity * flSimTime );
				TraceResult tr;
				g_Utility.TraceLine( vecOrigin, vecEnd, ignore_monsters, self.edict(), tr );

				vecOrigin = tr.vecEndPos;

				if( tr.flFraction < 1.0 )
				{
					if( g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_SKY )
						break;

					vecOrigin = vecOrigin + tr.vecPlaneNormal;

					float flDist = DotProduct( (vecOrigin - vecTarget), (vecOrigin - vecTarget) ); //lengthSquared

					if( (tr.pHit !is null and (tr.pHit is self.m_hEnemy.GetEntity().edict() or tr.pHit.vars.FlagBitSet(FL_CLIENT))) or (tr.vecPlaneNormal.z >= 0.7 and flDist < (128.0 * 128.0) and flDist < flBestDist) )
					{
						flBestPitch = flPitch;
						flBestDist = flDist;
					}

					//if( bDestroyOnTouch or (tr.flPlaneDist & (CONTENTS_MONSTER | CONTENTS_PLAYER | CONTENTS_DEADMONSTER)) != 0 )
					if( bDestroyOnTouch or (tr.pHit !is null and tr.pHit.vars.FlagBitSet(FL_CLIENT|FL_MONSTER)) )
						break;
				}

				flTime -= flSimTime;
			}
		}

		if( flBestDist != Math.FLOAT_MAX ) //If a valid pitch was found
		{
			vecPitchedAim.x = flBestPitch;
			vecPitchedAim.y = Math.VecToAngles(vecTarget - vecStart).y; //Ensure yaw is set towards target
			Math.MakeVectors( vecPitchedAim );
			vecAim = g_Engine.v_forward;

			return true;
		}

		return false; //No valid pitch found
	}

	void PredictAim( EHandle hTarget, const Vector &in vecStart, float flBoltSpeed, bool bEyeHeight, float flOffset, Vector &out vecAimdir, Vector &out vecAimpoint )
	{
		Vector vecDir, vecTemp;
		float flDist, flTime;

		if( !hTarget.IsValid() /*or !hTarget.inuse*/ )
		{
			vecAimdir = g_vecZero;
			return;
		}

		vecDir = hTarget.GetEntity().pev.origin - vecStart;
		if( bEyeHeight )
			vecDir.z += hTarget.GetEntity().pev.view_ofs.z;

		flDist = vecDir.Length();

		//if our current attempt is blocked, try the opposite one
		TraceResult tr;
		g_Utility.TraceLine( vecStart, vecStart + vecDir, missile, self.edict(), tr ); //MASK_PROJECTILE

		if( tr.pHit !is hTarget.GetEntity().edict() )
		{
			bEyeHeight = !bEyeHeight;
			vecDir = hTarget.GetEntity().pev.origin - vecStart;

			if( bEyeHeight )
				vecDir.z += hTarget.GetEntity().pev.view_ofs.z;

			flDist = vecDir.Length();
		}

		if( flBoltSpeed > 0.0 )
			flTime = flDist / flBoltSpeed;
		else
			flTime = 0.0;

		vecTemp = hTarget.GetEntity().pev.origin + ( hTarget.GetEntity().pev.velocity * (flTime - flOffset) );

		// went backwards...
		//if( vecDir.normalized().dot( (vecTemp - vecStart).normalized() ) < 0)
		if( DotProduct(vecDir.Normalize(), (vecTemp - vecStart).Normalize()) < 0 )
			vecTemp = hTarget.GetEntity().pev.origin;
		else
		{
			// if the shot is going to impact a nearby wall from our prediction, just fire it straight.
			g_Utility.TraceLine( vecStart, vecTemp, ignore_monsters, self.edict(), tr ); //MASK_SOLID
			//if (gi.traceline(vecStart, vecTemp, nullptr, MASK_SOLID).fraction < 0.9f)
			if( tr.flFraction < 0.9 )
				vecTemp = hTarget.GetEntity().pev.origin;
		}

		if( bEyeHeight )
			vecTemp.z += hTarget.GetEntity().pev.view_ofs.z;

		vecAimdir = (vecTemp - vecStart).Normalize();
		vecAimpoint = vecTemp;
	}

	CBaseEntity@ CheckTraceHullAttack( float flDist, float flDamage, int iDmgType )
	{
		TraceResult tr;

		if( self.IsPlayer() )
			Math.MakeVectors( pev.angles );
		else
			Math.MakeAimVectors( pev.angles );

		Vector vecStart = pev.origin;
		vecStart.z += pev.size.z * 0.5;
		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist );

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pEntity = g_EntityFuncs.Instance( tr.pHit );

			if( flDamage > 0 )
				pEntity.TakeDamage( self.pev, self.pev, flDamage, iDmgType );

			return pEntity;
		}

		return null;
	}

	float CheckPowerArmor( entvars_t@ pevInflictor, float flDamage )
	{
		float flSave;
		int iDamagePerCell;
		int iPowerUsed;

		if( pev.deadflag != DEAD_NO or flDamage <= 0 )
			return 0;

		//if( (dflags & DAMAGE_NO_ARMOR) != 0 ) // armour does not protect from this damage eg: drowning
			//return 0;

		if( monsterinfo.power_armor_type == q2::POWER_ARMOR_NONE )
			return 0;

		if( monsterinfo.power_armor_power <= 0 )
			return 0;

		if( monsterinfo.power_armor_type == q2::POWER_ARMOR_SCREEN )
		{
			//only works if damage point is in front
			Math.MakeVectors( pev.angles );
			Vector vecDir = (pevInflictor.origin - pev.origin).Normalize();
			float flDot = DotProduct( vecDir, g_Engine.v_forward );

			if( flDot <= 0.3 )
				return 0;

			iDamagePerCell = 1;
			flDamage = flDamage / 3;
		}
		else
		{
			iDamagePerCell = 2;
			flDamage = (2 * flDamage) / 3;
		}

		flSave = monsterinfo.power_armor_power * iDamagePerCell;

		if( flSave <= 0 )
			return 0;

		if( flSave > flDamage )
			flSave = flDamage;

		TraceResult tr = g_Utility.GetGlobalTrace();
		Vector vecDirSparks = ( pevInflictor.origin - self.Center() ).Normalize();
		Vector vecOrigin = tr.vecEndPos - (vecDirSparks * pev.scale) * -42.0;

		NetworkMessage m1( MSG_PVS, NetworkMessages::ShieldRic );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
		m1.End();

		//For the power screen to be oriented correctly
		Vector vecDir = (pevInflictor.origin - pev.origin).Normalize();
		float flYaw = Math.VecToAngles(vecDir).y;

		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, "quake2/weapons/lashit.wav", VOL_NORM, ATTN_NORM );

		if( monsterinfo.power_armor_type == q2::POWER_ARMOR_SCREEN )
			PowerArmorEffect( flYaw );
		else if( monsterinfo.power_armor_type == q2::POWER_ARMOR_SHIELD )
			PowerArmorEffect( flYaw, false );

		iPowerUsed = int(flSave) / iDamagePerCell;

		monsterinfo.power_armor_power -= iPowerUsed;

		if( monsterinfo.power_armor_power <= 0 )
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "quake2/misc/mon_power2.wav", VOL_NORM, ATTN_NORM );

		return flSave;
	}

	void PowerArmorEffect( float flYaw = 0.0, bool bScreen = true )
	{
		if( !bScreen )
		{
			pev.renderfx = kRenderFxGlowShell;
			pev.renderamt = 69;
			pev.rendercolor = Vector( 0, 255, 0 );

			m_flArmorEffectOff = g_Engine.time + 0.2;
		}
		else
		{
			float flOffset = ((pev.size.z * 0.5) * pev.scale);
			CBaseEntity@ pScreenEffect = g_EntityFuncs.Create( "q2pscreen", pev.origin + Vector(0, 0, flOffset), Vector(0, flYaw, 0), false ); //22
			if( pScreenEffect !is null )
			{
				pScreenEffect.pev.scale = ((pev.size.z * 0.42) * pev.scale);
				pScreenEffect.pev.rendermode = kRenderTransColor;
				pScreenEffect.pev.renderamt = 76.5; //30.0

				//Push it out a bit
				Math.MakeVectors( pScreenEffect.pev.angles );
				flOffset = ((pev.size.x * 0.75) * pev.scale);
				g_EntityFuncs.SetOrigin( pScreenEffect, pScreenEffect.pev.origin + g_Engine.v_forward * flOffset );
			}
		}
	}

	void CheckArmorEffect()
	{
		if( m_flArmorEffectOff > 0.0 and g_Engine.time > m_flArmorEffectOff )
		{
			pev.renderfx = kRenderFxNone;
			pev.renderamt = 255;
			pev.rendercolor = Vector( 0, 0, 0 );

			m_flArmorEffectOff = 0.0;
		}
	}

	bool fire_hit( Vector vecAim, float flDamage, int iKick )
	{
		if( m_bRerelease )
			return fire_hit_rr( vecAim, flDamage, iKick );

		return fire_hit_original( vecAim, flDamage, iKick );
	}

	bool fire_hit_original( Vector vecAim, float flDamage, int iKick )
	{
		if( !self.m_hEnemy.IsValid() )
			return false;

		TraceResult	tr;
		Vector			vecForward, vecRight, vecUp;
		Vector			v;
		Vector			vecPoint;
		float				flRange;
		Vector			vecDir;

		//see if enemy is in range
		vecDir = self.m_hEnemy.GetEntity().pev.origin - pev.origin;
		flRange = vecDir.Length();
		if( flRange > vecAim.x )
			return false;

		if( vecAim.y > pev.mins.x and vecAim.y < pev.maxs.x )
		{
			// the hit is straight on so back the range up to the edge of their bbox
			flRange -= self.m_hEnemy.GetEntity().pev.maxs.x;
		}
		else
		{
			// this is a side hit so adjust the "right" value out to the edge of their bbox
			if( vecAim.y < 0 )
				vecAim.y = self.m_hEnemy.GetEntity().pev.mins.x;
			else
				vecAim.y = self.m_hEnemy.GetEntity().pev.maxs.x;
		}

		vecPoint = pev.origin + vecDir * flRange;

		g_Utility.TraceLine( pev.origin, vecPoint, dont_ignore_monsters, self.edict(), tr ); //tr = gi.trace (self->s.origin, NULL, NULL, vecPoint, self, MASK_SHOT);
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit.vars.takedamage == DAMAGE_NO )
				return false;

			// if it will hit any client/monster then hit the one we wanted to hit
			if( tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) ) //(tr.ent->svflags & SVF_MONSTER) or tr.ent->client
				@tr.pHit = self.m_hEnemy.GetEntity().edict();
		}

		g_EngineFuncs.AngleVectors( pev.angles, vecForward, vecRight, vecUp );

		vecPoint = pev.origin + vecForward * flRange + vecRight * vecAim.y + vecUp * vecAim.z;
		vecDir = vecPoint - self.m_hEnemy.GetEntity().pev.origin;

		// do the damage
		q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), self, self, vecDir, vecPoint, g_vecZero, flDamage, iKick/2, q2::DAMAGE_NO_KNOCKBACK, q2::MOD_HIT );
		//g_EntityFuncs.Instance(tr.pHit).TakeDamage( self.pev, self.pev, flDamage, DMG_GENERIC );

		//if( !(tr.ent->svflags & SVF_MONSTER) and (!tr.ent->client) )
		if( !tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) )
			return false;

		// do our special form of knockback here
		v = self.m_hEnemy.GetEntity().pev.absmin + self.m_hEnemy.GetEntity().pev.size * 0.5;
		v = (v - vecPoint).Normalize(); //VectorNormalize (v);
		self.m_hEnemy.GetEntity().pev.velocity = self.m_hEnemy.GetEntity().pev.velocity + v * iKick;

		//if( self.m_hEnemy.GetEntity().pev.velocity.z > 0 )
			//@self.m_hEnemy.GetEntity().pev.groundentity = null;

		return true;
	}

	bool fire_hit_rr( Vector vecAim, float flDamage, int iKick )
	{
		if( !self.m_hEnemy.IsValid() )
			return false;

		TraceResult	tr;
		Vector			forward, right, up;
		Vector			v;
		Vector			point;
		float				range;
		Vector			dir;

		// see if enemy is in range
		range = q2::distance_between_boxes( self.m_hEnemy.GetEntity().pev.absmin, self.m_hEnemy.GetEntity().pev.absmax, pev.absmin, pev.absmax );
		if( range > vecAim.x )
			return false;

		if( !(vecAim.y > pev.mins.x and vecAim.y < pev.maxs.x) )
		{
			// this is a side hit so adjust the "right" value out to the edge of their bbox
			if( vecAim.y < 0 )
				vecAim.y = self.m_hEnemy.GetEntity().pev.mins.x;
			else
				vecAim.y = self.m_hEnemy.GetEntity().pev.maxs.x;
		}

		point = q2::closest_point_to_box( pev.origin, self.m_hEnemy.GetEntity().pev.absmin, self.m_hEnemy.GetEntity().pev.absmax );

		// check that we can hit the point on the bbox
		g_Utility.TraceLine( pev.origin, point, dont_ignore_monsters, self.edict(), tr ); //tr = gi.traceline(self->s.origin, point, self, MASK_PROJECTILE);

		if( tr.flFraction < 1 )
		{
			if( tr.pHit.vars.takedamage == DAMAGE_NO )
				return false;

			// if it will hit any client/monster then hit the one we wanted to hit
			if( tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) ) //if ((tr.ent->svflags & SVF_MONSTER) || (tr.ent->client))
				@tr.pHit = self.m_hEnemy.GetEntity().edict(); //tr.ent = self->enemy;
		}

		// check that we can hit the player from the point
		g_Utility.TraceLine( point, self.m_hEnemy.GetEntity().pev.origin, dont_ignore_monsters, self.edict(), tr );  //tr = gi.traceline(point, self.m_hEnemy.GetEntity().pev.origin, self, MASK_PROJECTILE);

		if( tr.flFraction < 1 )
		{
			if( tr.pHit.vars.takedamage == DAMAGE_NO )
				return false;

			// if it will hit any client/monster then hit the one we wanted to hit
			if( tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) ) //if ((tr.ent->svflags & SVF_MONSTER) || (tr.ent->client))
				@tr.pHit = self.m_hEnemy.GetEntity().edict(); //tr.ent = self->enemy;
		}

		g_EngineFuncs.AngleVectors( pev.angles, forward, right, up );
		point = pev.origin + ( forward * range );
		point = point + ( right * vecAim.y );
		point = point + ( up * vecAim.z );
		dir = point - self.m_hEnemy.GetEntity().pev.origin;

		// do the damage
		q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), self, self, dir, point, g_vecZero, flDamage, iKick / 2, q2::DAMAGE_NO_KNOCKBACK, q2::MOD_HIT );

		if( !tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) ) //if (!(tr.ent->svflags & SVF_MONSTER) && (!tr.ent->client))
			return false;

		// do our special form of knockback here (TOO MUCH??)
		/*v = ( self.m_hEnemy.GetEntity().pev.absmin + self.m_hEnemy.GetEntity().pev.absmax ) * 0.5;
		v = (v - point).Normalize();
		self.m_hEnemy.GetEntity().pev.velocity = self.m_hEnemy.GetEntity().pev.velocity + v * iKick;*/

		//if( self.m_hEnemy.GetEntity().pev.velocity.z > 0 )
			//@self.m_hEnemy.GetEntity().pev.groundentity = null;

		return true;
	}

	//for chaos mode
	void monster_fire_weapon( int iWeaponType, Vector vecMuzzle, Vector vecAim, float flDamage, float flSpeed = 600.0, float flRightAdjust = 0.0, float flUpAdjust = 0.0, int iFlags = 0 )
	{
		if( q2npc::g_iChaosMode == q2::CHAOS_LEVEL1 )
			iWeaponType = m_iWeaponType;
		else if( (m_iWeaponType & 2048) != 0 )
		{
			//DESPERATION MOVE >:D
			m_iWeaponType &= ~2048;
			iWeaponType = m_iWeaponType;
		}
		else if( q2npc::g_iChaosMode == q2::CHAOS_LEVEL2 )
		{
			if( q2npc::g_iDifficulty < q2::DIFF_NIGHTMARE )
				iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_RAILGUN );
			else
				iWeaponType = Math.RandomLong( q2::WEAPON_BULLET, q2::WEAPON_BFG );
		}

		switch( iWeaponType )
		{
			case q2::WEAPON_BULLET:
			{
				monster_fire_bullet( vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2::WEAPON_SHOTGUN:
			{
				pev.weapons = q2::MOD_SHOTGUN;
				monster_fire_shotgun( vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2::WEAPON_BLASTER:
			{
				monster_fire_blaster( vecMuzzle, vecAim, flDamage, flSpeed, iFlags );

				break;
			}

			case q2::WEAPON_BLASTER2:
			{
				monster_fire_blaster2( vecMuzzle, vecAim, flDamage, flSpeed, iFlags );

				break;
			}

			case q2::WEAPON_GRENADE:
			{
				monster_fire_grenade( vecMuzzle, vecAim, flDamage, flSpeed, flRightAdjust, flUpAdjust );
				break;
			}

			case q2::WEAPON_ROCKET:
			{
				monster_fire_rocket( vecMuzzle, vecAim, flDamage, flSpeed );
				break;
			}

			case q2::WEAPON_HEATSEEKING:
			{
				monster_fire_rocket( vecMuzzle, vecAim, flDamage, flSpeed, true );
				break;
			}

			case q2::WEAPON_RAILGUN:
			{
				monster_fire_railgun( vecMuzzle, vecAim, flDamage, flSpeed );
				break;
			}

			case q2::WEAPON_BFG:
			{
				if( pev.classname == "npc_q2jorg" )
					monster_fire_bfg( vecMuzzle, vecAim, flDamage, flSpeed, 200 );
				else if( pev.classname == "npc_q2makron" )
					monster_fire_bfg( vecMuzzle, vecAim, flDamage, flSpeed, 300 );
				else
					monster_fire_bfg( vecMuzzle, vecAim, flDamage, flSpeed, 200 ); //??

				break;
			}
		}
	}

	void monster_fire_bullet( Vector vecStart, Vector vecDir, float flDamage )
	{
		Vector vecSpread = q2npc::DEFAULT_BULLET_SPREAD;

		if( self.GetClassname() == "npc_q2supertank" )
			vecSpread = vecSpread * 3;

		self.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );
	}

	void monster_fire_shotgun( Vector vecStart, Vector vecDir, float flDamage, int iCount = 9 )
	{
		for( int i = 0; i < iCount; i++ )
			self.FireBullets( 1, vecStart, vecDir, q2npc::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );

		//too loud
		//self.FireBullets( iCount, vecStart, vecDir, q2npc::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), self.pev );
	}

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, int iFlags = 0 )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, true, self.edict() ); 
		pLaser.pev.speed = flSpeed;
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pLaser.pev.netname = sMonsterName;

		if( HasFlags(iFlags, q2::EF_HYPERBLASTER) )
			pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
		else if( HasFlags(iFlags, q2::EF_BLASTER) )
			pLaser.pev.weapons = q2::MOD_BLASTER;
		else
		{
			pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
			pLaser.pev.frags = 1.0; //EF_NONE
		}

		if( q2npc::g_iChaosMode > q2::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pLaser.pev.movetype = MOVETYPE_TOSS;

		g_EntityFuncs.DispatchSpawn( pLaser.edict() );

		//needed ??
		TraceResult tr;
		g_Utility.TraceLine( pev.origin, pLaser.pev.origin, ignore_monsters, dont_ignore_glass, pLaser.edict(), tr);

		if( tr.flFraction < 1.0 )
		{
			// Adjust bolt origin to impact point, offset from surface
			Vector vecImpactPoint = tr.vecEndPos + tr.vecPlaneNormal;
			pLaser.pev.origin = vecImpactPoint;

			g_EntityFuncs.SetOrigin( pLaser, vecImpactPoint );
			pLaser.Touch( g_EntityFuncs.Instance(tr.pHit) );
		}
	}

	void monster_fire_blaster2( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, int iFlags = 0 )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, true, self.edict() ); 
		pLaser.pev.speed = flSpeed;
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		//if( effect )
			//bolt->s.effects |= EF_TRACKER;

		//bolt->dmg_radius = 128;
		pLaser.pev.skin = 2;
		pLaser.pev.scale = 2.5;
		//bolt->touch = blaster2_touch;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pLaser.pev.netname = sMonsterName;

		if( HasFlags(iFlags, q2::EF_HYPERBLASTER) )
			pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
		else if( HasFlags(iFlags, q2::EF_BLASTER) )
			pLaser.pev.weapons = q2::MOD_BLASTER;
		else
		{
			pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
			pLaser.pev.frags = 1.0; //EF_NONE
		}

		if( q2npc::g_iChaosMode > q2::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pLaser.pev.movetype = MOVETYPE_TOSS;

		g_EntityFuncs.DispatchSpawn( pLaser.edict() );

		//needed ??
		TraceResult tr;
		g_Utility.TraceLine( pev.origin, pLaser.pev.origin, ignore_monsters, dont_ignore_glass, pLaser.edict(), tr);

		if( tr.flFraction < 1.0 )
		{
			// Adjust bolt origin to impact point, offset from surface
			Vector vecImpactPoint = tr.vecEndPos + tr.vecPlaneNormal;
			pLaser.pev.origin = vecImpactPoint;

			g_EntityFuncs.SetOrigin( pLaser, vecImpactPoint );
			pLaser.Touch( g_EntityFuncs.Instance(tr.pHit) );
		}
	}

	void monster_fire_grenade( Vector vecStart, Vector vecAim, float flDamage, float flSpeed, float flRightAdjust = 0.0, float flUpAdjust = 0.0 )
	{
		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "q2grenade", vecStart, g_vecZero, true, self.edict() );
		q2projectiles::q2grenade@ pGrenade = cast<q2projectiles::q2grenade@>(CastToScriptClass(cbeGrenade));

		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.dmgtime = 2.5;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pGrenade.pev.netname = sMonsterName;

		pGrenade.pev.velocity = vecAim * flSpeed;
		pGrenade.pev.weapons = 2;
		pGrenade.m_flDamageRadius = 160;

		g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

		Math.MakeVectors( pev.angles );

		if( flUpAdjust > 0.0 )
		{
			float flGravityAdjustment = g_EngineFuncs.CVarGetFloat("sv_gravity") / 800.0;
			pGrenade.pev.velocity = pGrenade.pev.velocity + g_Engine.v_up * flUpAdjust * flGravityAdjustment;
		}

		if( flRightAdjust > 0.0 )
			pGrenade.pev.velocity = pGrenade.pev.velocity + g_Engine.v_right * flRightAdjust;
	}

	void monster_fire_rocket( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHeatSeeking = false )
	{
		CBaseEntity@ cbeRocket = g_EntityFuncs.Create( "q2rocket", vecStart, vecDir, true, self.edict() ); 
		q2projectiles::q2rocket@ pRocket = cast<q2projectiles::q2rocket@>(CastToScriptClass(cbeRocket));

		pRocket.pev.speed = flSpeed;
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.m_flDamageRadius = flDamage + 20;
		pRocket.m_flRadiusDamage = flDamage;
		
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		if( self.GetClassname() == "npc_q2supertank" )
			pRocket.pev.scale = 2.0;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pRocket.pev.netname = sMonsterName;

		if( bHeatSeeking )
		{
			pRocket.pev.weapons = 1;
			pRocket.pev.frags = m_flHeatTurnRate;
		}

		g_EntityFuncs.DispatchSpawn( pRocket.self.edict() );

		if( q2npc::g_iChaosMode > q2::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pRocket.pev.movetype = MOVETYPE_TOSS;
	}

	void monster_fire_bfg( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, float flDamageRadius )
	{
		CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfg", vecStart, vecDir, true, self.edict() );
		pBFG.pev.speed = flSpeed;
		pBFG.pev.velocity = vecDir * flSpeed;
		pBFG.pev.dmg = flDamage;
		pBFG.pev.dmgtime = flDamageRadius;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pBFG.pev.netname = sMonsterName;

		if( q2npc::g_iChaosMode > q2::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pBFG.pev.movetype = MOVETYPE_TOSS;

		g_EntityFuncs.DispatchSpawn( pBFG.edict() );
	}

	void monster_fire_railgun( Vector vecStart, Vector vecAim, float flDamage, float flKick = 0 )
	{
		TraceResult tr;

		Vector vecEnd = vecStart + vecAim * 8192;
		Vector railstart = vecStart;
		
		edict_t@ ignore = self.edict();
		
		while( ignore !is null )
		{
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit.IsMonster() or pHit.IsPlayer() or tr.pHit.vars.solid == SOLID_BBOX or (tr.pHit.vars.ClassNameIs( "func_breakable" ) and tr.pHit.vars.takedamage != DAMAGE_NO) )
				@ignore = tr.pHit;
			else
				@ignore = null;

			g_WeaponFuncs.ClearMultiDamage();

			if( tr.pHit !is self.edict() and pHit.pev.takedamage != DAMAGE_NO )
				q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), self, self, vecAim, tr.vecEndPos, tr.vecPlaneNormal, flDamage, flKick, 0, q2::MOD_RAILGUN );
				//pHit.TraceAttack( self.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH );

			g_WeaponFuncs.ApplyMultiDamage( self.pev, self.pev );

			vecStart = tr.vecEndPos;
		}

		CreateRailbeam( railstart, tr.vecEndPos );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null or pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SNIPER );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0,1) );

				int r = 155, g = 255, b = 255;

				NetworkMessage railimpact( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
					railimpact.WriteByte( TE_DLIGHT );
					railimpact.WriteCoord( tr.vecEndPos.x );
					railimpact.WriteCoord( tr.vecEndPos.y );
					railimpact.WriteCoord( tr.vecEndPos.z );
					railimpact.WriteByte( 8 );//radius
					railimpact.WriteByte( int(r) );
					railimpact.WriteByte( int(g) );
					railimpact.WriteByte( int(b) );
					railimpact.WriteByte( 48 );//life
					railimpact.WriteByte( 12 );//decay
				railimpact.End();
			}
		}
	}

	void CreateRailbeam( Vector vecStart, Vector vecEnd )
	{
		CBaseEntity@ cbeBeam = g_EntityFuncs.CreateEntity( "q2railbeam", null, false );
		q2projectiles::q2railbeam@ pBeam = cast<q2projectiles::q2railbeam@>(CastToScriptClass(cbeBeam));
		pBeam.m_vecStart = vecStart;
		pBeam.m_vecEnd = vecEnd;
		g_EntityFuncs.SetOrigin( pBeam.self, vecStart );
		g_EntityFuncs.DispatchSpawn( pBeam.self.edict() );
	}

	void monster_muzzleflash( Vector vecOrigin, int iR, int iG, int iB, int iRadius = 20 )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_DLIGHT );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteByte( iRadius + Math.RandomLong(0, 6) ); //radius
			m1.WriteByte( iR ); //rgb
			m1.WriteByte( iG );
			m1.WriteByte( iB );
			m1.WriteByte( 10 ); //lifetime
			m1.WriteByte( 35 ); //decay
		m1.End();
	}

	void MachineGunEffects( Vector vecOrigin, int iScale = 5 )
	{
		NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m1.WriteByte( TE_SMOKE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z - 10.0 );
			m1.WriteShort( g_EngineFuncs.ModelIndex("sprites/steam1.spr") );
			m1.WriteByte( iScale ); // scale * 10
			m1.WriteByte( 105 ); // framerate
		m1.End();

		/*NetworkMessage m2( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecOrigin );
			m2.WriteByte( TE_DLIGHT );
			m2.WriteCoord( vecOrigin.x );
			m2.WriteCoord( vecOrigin.y );
			m2.WriteCoord( vecOrigin.z );
			m2.WriteByte( 16 ); //radius
			m2.WriteByte( 240 ); //rgb
			m2.WriteByte( 180 );
			m2.WriteByte( 0 );
			m2.WriteByte( 8 ); //lifetime
			m2.WriteByte( 50 ); //decay
		m2.End();*/
	}

	//from pm_shared.c, because model event 2003 doesn't work :aRage:
	void monster_footstep( int iPitch = PITCH_NORM, bool bSetOrigin = false, Vector vecSetOrigin = g_vecZero )
	{
		int iRand;
		float flVol = 1.0;

		if( m_iStepLeft == 0 ) m_iStepLeft = 1;
			else m_iStepLeft = 0;

		iRand = Math.RandomLong(0, 1) + (m_iStepLeft * 2);

		Vector vecOrigin = pev.origin;

		if( bSetOrigin )
			vecOrigin = vecSetOrigin;

		TraceResult tr;
		g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -64),  ignore_monsters, self.edict(), tr );

		edict_t@ pWorld = g_EntityFuncs.Instance(0).edict();
		if( tr.pHit !is null ) @pWorld = tr.pHit;

		string sTexture = g_Utility.TraceTexture( pWorld, vecOrigin, vecOrigin + Vector(0, 0, -64) );
		char chTextureType = g_SoundSystem.FindMaterialType( sTexture );
		int iStep = MapTextureTypeStepType( chTextureType );

		if( pev.waterlevel == WATERLEVEL_FEET ) iStep = STEP_SLOSH;
		else if( pev.waterlevel >= WATERLEVEL_WAIST ) iStep = STEP_WADE;

		switch( iStep )
		{
			case STEP_VENT:
			{
				flVol = 0.7; //fWalking ? 0.4 : 0.7;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_duct4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_DIRT:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_dirt4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_GRATE:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_grate4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_METAL:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_metal4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_SLOSH:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_slosh4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_WADE: { break; }

			case STEP_TILE:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				if( Math.RandomLong(0, 4) == 0 )
					iRand = 4;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 4: g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_tile5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_WOOD:
			{
				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_wood4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_FLESH:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_organic4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_SNOW:
			{
				flVol = 0.55; //fWalking ? 0.25 : 0.55;

				if( Math.RandomLong(0, 1) == 1 )
					iRand += 4;

				switch( iRand )
				{
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 4:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow5.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 5:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow6.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 6:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow7.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 7:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_snow8.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}

			case STEP_CONCRETE:
			default:
			{
				flVol = 0.5; //fWalking ? 0.2 : 0.5;

				switch( iRand )
				{
					// right foot
					case 0:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step1.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 1:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step3.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					// left foot
					case 2:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step2.wav", flVol, ATTN_NORM, 0, iPitch );	break;
					case 3:	g_SoundSystem.EmitSoundDyn( self.edict(), CHAN_BODY, "player/pl_step4.wav", flVol, ATTN_NORM, 0, iPitch );	break;
				}

				break;
			}
		}

		//g_Game.AlertMessage( at_notice, "sTexture: %1\n", sTexture );
		//g_Game.AlertMessage( at_notice, "chTextureType: %1\n", string(chTextureType) );
		//g_Game.AlertMessage( at_notice, "iStep: %1\n", iStep );
	}

	int MapTextureTypeStepType( char chTextureType )
	{
		if( chTextureType == 'C' ) return STEP_CONCRETE;
		else if( chTextureType == 'M' ) return STEP_METAL;
		else if( chTextureType == 'D' ) return STEP_DIRT;
		else if( chTextureType == 'V' ) return STEP_VENT;
		else if( chTextureType == 'G' ) return STEP_GRATE;
		else if( chTextureType == 'T' ) return STEP_TILE;
		else if( chTextureType == 'S' ) return STEP_SLOSH;
		else if( chTextureType == 'W' ) return STEP_WOOD;
		else if( chTextureType == 'F' ) return STEP_FLESH;
		else if( chTextureType == 'O' ) return STEP_SNOW;

		return STEP_CONCRETE;
	}

	//
	// VecCheckToss - returns the velocity at which an object should be lobbed from vecspot1 to land near vecspot2.
	// returns g_vecZero if toss is not feasible.
	// 
	Vector VecCheckToss( const Vector &in vecSpot1, Vector vecSpot2, float flGravityAdj )
	{
		TraceResult tr;
		Vector vecMidPoint;// halfway point between Spot1 and Spot2
		Vector vecApex;// highest point 
		Vector vecScale;
		Vector vecGrenadeVel;
		Vector vecTemp;
		float flGravity = g_EngineFuncs.CVarGetFloat("sv_gravity") * flGravityAdj;

		if( vecSpot2.z - vecSpot1.z > 500 )
		{
			// to high, fail
			return g_vecZero;
		}

		Math.MakeVectors( pev.angles );

		// toss a little bit to the left or right, not right down on the enemy's bean (head). 
		vecSpot2 = vecSpot2 + g_Engine.v_right * ( Math.RandomFloat(-8.0, 8.0) + Math.RandomFloat(-16.0, 16.0) );
		vecSpot2 = vecSpot2 + g_Engine.v_forward * ( Math.RandomFloat(-8.0, 8.0) + Math.RandomFloat(-16.0, 16.0) );

		// calculate the midpoint and apex of the 'triangle'
		// UNDONE: normalize any Z position differences between spot1 and spot2 so that triangle is always RIGHT

		// How much time does it take to get there?

		// get a rough idea of how high it can be thrown
		vecMidPoint = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
		g_Utility.TraceLine( vecMidPoint, vecMidPoint + Vector(0, 0, 500), ignore_monsters, self.edict(), tr );
		vecMidPoint = tr.vecEndPos;
		// (subtract 15 so the grenade doesn't hit the ceiling)
		vecMidPoint.z -= 15;

		if( vecMidPoint.z < vecSpot1.z or vecMidPoint.z < vecSpot2.z )
		{
			// to not enough space, fail
			return g_vecZero;
		}

		// How high should the grenade travel to reach the apex
		float distance1 = (vecMidPoint.z - vecSpot1.z);
		float distance2 = (vecMidPoint.z - vecSpot2.z);

		// How long will it take for the grenade to travel this distance
		float time1 = sqrt( distance1 / (0.5 * flGravity) );
		float time2 = sqrt( distance2 / (0.5 * flGravity) );

		if( time1 < 0.1 )
		{
			// too close
			return g_vecZero;
		}

		// how hard to throw sideways to get there in time.
		vecGrenadeVel = (vecSpot2 - vecSpot1) / (time1 + time2);
		// how hard upwards to reach the apex at the right time.
		vecGrenadeVel.z = flGravity * time1;

		// find the apex
		vecApex  = vecSpot1 + vecGrenadeVel * time1;
		vecApex.z = vecMidPoint.z;

		g_Utility.TraceLine( vecSpot1, vecApex, dont_ignore_monsters, self.edict(), tr );
		if( tr.flFraction != 1.0 )
		{
			// fail!
			return g_vecZero;
		}

		// UNDONE: either ignore monsters or change it to not care if we hit our enemy
		g_Utility.TraceLine( vecSpot2, vecApex, ignore_monsters, self.edict(), tr );
		if( tr.flFraction != 1.0 )
		{
			// fail!
			return g_vecZero;
		}

		return vecGrenadeVel;
	}

	//
	// VecCheckThrow - returns the velocity vector at which an object should be thrown from vecspot1 to hit vecspot2.
	// returns g_vecZero if throw is not feasible.
	//  
	Vector VecCheckThrow( const Vector& in vecSpot1, Vector vecSpot2, float flSpeed, float flGravityAdj )
	{
		float flGravity = g_EngineFuncs.CVarGetFloat("sv_gravity") * flGravityAdj;

		Vector vecGrenadeVel = (vecSpot2 - vecSpot1);

		// throw at a constant time
		float time = vecGrenadeVel.Length() / flSpeed;
		vecGrenadeVel = vecGrenadeVel * (1.0 / time);

		// adjust upward toss to compensate for gravity loss
		vecGrenadeVel.z += flGravity * time * 0.5;

		Vector vecApex = vecSpot1 + (vecSpot2 - vecSpot1) * 0.5;
		vecApex.z += 0.5 * flGravity * (time * 0.5) * (time * 0.5);

		TraceResult tr;
		g_Utility.TraceLine( vecSpot1, vecApex, dont_ignore_monsters, self.edict(), tr );
		if( tr.flFraction != 1.0 )
		{
			// fail!
			return g_vecZero;
		}

		g_Utility.TraceLine( vecSpot2, vecApex, ignore_monsters, self.edict(), tr );
		if( tr.flFraction != 1.0 )
		{
			// fail!
			return g_vecZero;
		}

		return vecGrenadeVel;
	}

	void M_SetEffects()
	{
		//ent->s.effects &= ~(EF_COLOR_SHELL|EF_POWERSCREEN);
		//ent->s.renderfx &= ~(RF_SHELL_RED|RF_SHELL_GREEN|RF_SHELL_BLUE);
		pev.renderfx = kRenderFxNone;
		pev.renderamt = 255;
		pev.rendercolor = Vector( 0, 0, 0 );

		if( HasFlags(monsterinfo.aiflags, q2::AI_RESURRECTING) )
		{
			//g_Game.AlertMessage( at_notice, "M_SetEffects() %1 is being resurrected!\n", self.GetClassname() );
			pev.renderfx = kRenderFxGlowShell;
			pev.renderamt = 69;
			pev.rendercolor = Vector( 255, 0, 0 );
		}
		/*else if( pev.renderfx == kRenderFxGlowShell and m_flArmorEffectOff == 0.0 )
		{
			g_Game.AlertMessage( at_notice, "M_SetEffects() %1 is no longer being resurrected!\n", self.GetClassname() );
			pev.renderfx = kRenderFxNone;
			pev.renderamt = 255;
			pev.rendercolor = Vector( 0, 0, 0 );
		}*/
/*
		if (ent->health <= 0)
			return;

		if (ent->powerarmor_time > level.time)
		{
			if (ent->monsterinfo.power_armor_type == POWER_ARMOR_SCREEN)
			{
				ent->s.effects |= EF_POWERSCREEN;
			}
			else if (ent->monsterinfo.power_armor_type == POWER_ARMOR_SHIELD)
			{
				ent->s.effects |= EF_COLOR_SHELL;
				ent->s.renderfx |= RF_SHELL_GREEN;
			}
		}*/
	}

	void M_SetupReinforcements( string sReinforcements, reinforcement_list_t &out list ) //out ??
	{
		// count up the semicolons
		list.num_reinforcements = 0;

		if( sReinforcements.IsEmpty() )
			return;

		array<string> parsed = sReinforcements.Split( ";" );

		list.num_reinforcements = parsed.length();
		//g_Game.AlertMessage( at_notice, "M_SetupReinforcements length: %1\n", parsed.length() );

		for( uint i = 0; i < parsed.length(); i++ )
		{
			array<string> parsed2 = parsed[i].Split( " " );

			reinforcement_t reinforcement;
			reinforcement.classname = parsed2[ 0 ];
			reinforcement.strength = atoi( parsed2[1] );

			CBaseEntity@ pNewEnt = g_EntityFuncs.Create( reinforcement.classname, g_vecZero, g_vecZero, true );
			CBaseQ2NPC@ pMonster = q2npc::GetQ2Pointer( pNewEnt );

			pMonster.monsterinfo.aiflags |= q2::AI_DO_NOT_COUNT;
			pMonster.pev.spawnflags = 16; //prisoner

			g_EntityFuncs.DispatchSpawn( pMonster.self.edict() );

			reinforcement.mins = pMonster.pev.mins;
			reinforcement.maxs = pMonster.pev.maxs;

			g_EntityFuncs.Remove( pMonster.self );

			list.reinforcements.insertLast( reinforcement );
			//g_Game.AlertMessage( at_notice, "M_SetupReinforcements %1: %2\n", i, parsed[i] );
			//g_Game.AlertMessage( at_notice, "classname: %1, strength: %2\n", parsed2[0], parsed2[1] );
		}

		/*if( list.num_reinforcements > 0 )
		{
			g_Game.AlertMessage( at_notice, "list.num_reinforcements: %1\n", list.num_reinforcements );

			for( int j = 0; j < list.num_reinforcements; j++ )
			{
				g_Game.AlertMessage( at_notice, "ENTRY #%1\n", j );
				g_Game.AlertMessage( at_notice, "classname: %1\n", list.reinforcements[j].classname );
				g_Game.AlertMessage( at_notice, "strength: %1\n", list.reinforcements[j].strength );
				g_Game.AlertMessage( at_notice, "mins: %1\n", list.reinforcements[j].mins.ToString() );
				g_Game.AlertMessage( at_notice, "maxs: %1\n\n", list.reinforcements[j].maxs.ToString() );
			}
		}*/
	}

	// filter out the reinforcement indices we can pick given the space we have left
	void M_PickValidReinforcements( int space, array<uint8> &out output ) //std::vector<uint8_t> &output
	{
		output.resize( 0 ); //output.clear();

		for( int i = 0; i < monsterinfo.reinforcements.num_reinforcements; i++ )
		{
			if( monsterinfo.reinforcements.reinforcements[i].strength <= space )
				output.insertLast( i );
		}
	}

	// pick an array of reinforcements to use; note that this does not modify `self`
	//std::array<uint8_t, MAX_REINFORCEMENTS>
	array<uint8> M_PickReinforcements( int &out num_chosen, int max_slots = 0 )
	{
		array<uint8> available; //static std::vector<uint8_t> available;
		array<uint8> chosen( MAX_REINFORCEMENTS, uint8(255) ); //std::array<uint8_t, MAX_REINFORCEMENTS> //chosen.fill(255);

		// decide how many things we want to spawn;
		// this is on a logarithmic scale
		// so we don't spawn too much too often.
		int num_slots = Math.max( 1, int(log(Math.RandomFloat(0.0, 1.0) * inverse_log_slots) / log(2.0)) ); //int32_t num_slots = max(1, (int32_t) log2(frandom(inverse_log_slots)));

		// we only have this many slots left to use
		int remaining = monsterinfo.monster_slots - monsterinfo.monster_used;

		for( num_chosen = 0; num_chosen < num_slots; num_chosen++ )
		{
			// ran out of slots!
			if( (max_slots != 0 and num_chosen == max_slots) or remaining <= 0 )
				break;

			// get everything we could choose
			M_PickValidReinforcements( remaining, available );

			// can't pick any
			if( available.length() <= 0 )
				break;

			// select monster, TODO fairly
			chosen[num_chosen] = uint8( Math.RandomLong(0, available.length()-1) ); //random_element( available );

			remaining -= monsterinfo.reinforcements.reinforcements[chosen[num_chosen]].strength;
		}

		return chosen;
	}

	int M_SlotsLeft()
	{
		return monsterinfo.monster_slots - monsterinfo.monster_used; 
	} 

	//from quake 2 rerelease
	// PMM - this is used by the medic commander (possibly by the carrier) to find a good spawn point
	// if the startpoint is bad, try above the startpoint for a bit
	/*bool FindSpawnPoint( const Vector &in startpoint, const Vector &in mins, const Vector &in maxs, Vector &out spawnpoint, bool drop = false )
	{
		spawnpoint = startpoint;

		// drop first
		if( !drop or !M_droptofloor_generic(spawnpoint, mins, maxs, false, null, 0, false, spawnpoint) ) //MASK_MONSTERSOLID
		{
			spawnpoint = startpoint;

			// fix stuck if we couldn't drop initially
			/*if (G_FixStuckObject_Generic(spawnpoint, mins, maxs, [] (const Vector &start, const Vector &mins, const Vector &maxs, const Vector &end) {
					return gi.trace(start, mins, maxs, end, nullptr, MASK_MONSTERSOLID);
				}) == stuck_result_t::NO_GOOD_POSITION)
				return false;
			
			//if( !G_FixStuckObject_Generic(spawnpoint, mins, maxs) )
				//return false;

			// fixed, so drop again
			if( drop and !M_droptofloor_generic(spawnpoint, mins, maxs, false, null, 0, false, spawnpoint) ) //MASK_MONSTERSOLID
				return false; // ???
		}

		return true;
	}*/

	bool FindSpawnPoint( const Vector &in startpoint, const Vector &in mins, const Vector &in maxs, Vector &out spawnpoint, string sClassname, bool drop = false )
	{
		g_Game.AlertMessage( at_notice, "FindSpawnPoint for: %1\n", sClassname );
		spawnpoint = startpoint;

		// drop first
		if( !drop or !M_droptofloor_generic(spawnpoint, mins, maxs, false, null, 0, false, spawnpoint, sClassname) ) //MASK_MONSTERSOLID
		{
			spawnpoint = startpoint;

			// fix stuck if we couldn't drop initially
			q2::TraceFn@ trace = function( const Vector &in start, const Vector &in mins, const Vector &in maxs, const Vector &in end )
			{
				//HULL_NUMBER hullNumber = q2::GetClosestHullNumber( mins, maxs );
				HULL_NUMBER hullNumber = head_hull;
				TraceResult tr;
				g_Utility.TraceHull( start, end, dont_ignore_monsters, hullNumber, null, tr );
				q2::StuckTrace result;
				result.startsolid = tr.fStartSolid != 0;
				result.endpos = tr.vecEndPos;
				result.planeNormal = tr.vecPlaneNormal;
				return @result;
			};

			int iResult = q2::G_FixStuckObject_Generic( spawnpoint, mins, maxs, trace, spawnpoint );
			switch( iResult )
			{
				case q2::GOOD_POSITION:
				{
					g_Game.AlertMessage( at_notice, "GOOD_POSITION!\n" );
					break;
				}

				case q2::FIXED:
				{
					g_Game.AlertMessage( at_notice, "FIXED!\n" );
					break;
				}

				case q2::NO_GOOD_POSITION:
				{
					g_Game.AlertMessage( at_notice, "NO_GOOD_POSITION!\n" );
					break;
				}
			}

			//if( q2::G_FixStuckObject_Generic(spawnpoint, mins, maxs, trace) == q2::NO_GOOD_POSITION )
			if( iResult == q2::NO_GOOD_POSITION )
				return false;

			// fixed, so drop again
			if( drop and !M_droptofloor_generic(spawnpoint, mins, maxs, false, null, 0, false, spawnpoint, sClassname) ) //MASK_MONSTERSOLID
				return false; // ???
		}

		return true;
	}

	//from quake 2 rerelease
	bool M_droptofloor_generic( Vector &in origin, const Vector &in mins, const Vector &in maxs, bool ceiling, edict_t@ ignore, int mask, bool bAllowPartial, Vector &out vecOut, string sClassname ) //contents_t mask
	{
		Vector end;
		TraceResult trace;

		if( npc_q2medic::USE_EXPENSIVE_HULLCHECKS )
			TraceMonster( sClassname, origin, origin, trace );
		else
		{
			g_Utility.TraceLine( origin, origin, dont_ignore_monsters, ignore, trace );
			g_Utility.FindHullIntersection( origin, trace, trace, mins, maxs, ignore ); //self.edict() ??
		}

		//if (gi.trace(origin, mins, maxs, origin, ignore, mask).startsolid)
		if( trace.fStartSolid != 0 )
		{
			if( !ceiling )
				origin.z += 1.0;
			else
				origin.z -= 1.0;
		}

		if( !ceiling )
		{
			end = origin;
			end.z -= 256;
		}
		else
		{
			end = origin;
			end.z += 256;
		}

		if( npc_q2medic::USE_EXPENSIVE_HULLCHECKS )
			TraceMonster( sClassname, origin, end, trace );
		else
		{
			g_Utility.TraceLine( origin, end, dont_ignore_monsters, ignore, trace ); //trace = gi.trace(origin, mins, maxs, end, ignore, mask);
			g_Utility.FindHullIntersection( origin, trace, trace, mins, maxs, ignore ); //self.edict() ??
		}

		if( trace.flFraction == 1.0 or trace.fAllSolid != 0 or (!bAllowPartial and trace.fStartSolid != 0) )
			return false;

		vecOut = trace.vecEndPos; //origin

		return true;
	}

	//from quake 2 rerelease
	// PMM - checks volume to make sure we can spawn a monster there (is it solid?)
	//
	// This is all fliers should need
	bool CheckSpawnPoint( const Vector &in origin, const Vector &in mins, const Vector &in maxs, string sClassname = "" )
	{
		TraceResult tr;

		if( mins == g_vecZero or maxs == g_vecZero )
			return false;

		if( npc_q2medic::USE_EXPENSIVE_HULLCHECKS and !sClassname.IsEmpty() )
			TraceMonster( sClassname, origin, origin, tr );
		else
		{
			g_Utility.TraceLine( origin, origin, dont_ignore_monsters, null, tr ); //tr = gi.trace(origin, mins, maxs, origin, nullptr, MASK_MONSTERSOLID);
			g_Utility.FindHullIntersection( origin, tr, tr, mins, maxs, null ); //self.edict() ??
		}

		if( tr.fStartSolid != 0 or tr.fAllSolid != 0 )
			return false;

		if( !tr.pHit.vars.ClassNameIs("worldspawn") ) //tr.ent != world
			return false;

		return true;
	}

	//from quake 2 rerelease
	// PMM - used for walking monsters
	//  checks:
	//		1)	is there a ground within the specified height of the origin?
	//		2)	is the ground non-water?
	//		3)	is the ground flat enough to walk on?
	//
	bool CheckGroundSpawnPoint( const Vector &in origin, const Vector &in entMins, const Vector &in entMaxs, float height, float gravity, string sClassname = "" )
	{
		if( !CheckSpawnPoint(origin, entMins, entMaxs, sClassname) )
			return false;

		if( M_CheckBottom_Fast_Generic(origin + entMins, origin + entMaxs, false) )
			return true;

		if( M_CheckBottom_Slow_Generic(origin, entMins, entMaxs, null, 0, false, false) ) //MASK_MONSTERSOLID
			return true;

		return false;
	}

	//from quake 2 rerelease
	//Returns false if any part of the bottom of the entity is off an edge that is not a staircase.
	bool M_CheckBottom_Fast_Generic( const Vector &in absmins, const Vector &in absmaxs, bool ceiling )
	{
		//  FIXME - this will only handle 0,0,1 and 0,0,-1 gravity vectors
		Vector start;

		start.z = absmins.z - 1;

		if( ceiling )
			start.z = absmaxs.z + 1;

		for( int x = 0; x <= 1; x++ )
		{
			for( int y = 0; y <= 1; y++ )
			{
				start.x = (x != 0) ? absmaxs.x : absmins.x;
				start.y = (y != 0) ? absmaxs.y : absmins.y;

				if( g_EngineFuncs.PointContents(start) != CONTENTS_SOLID )
					return false;
			}
		}

		return true; // we got out easy
	}

	//from quake 2 rerelease
	bool M_CheckBottom_Slow_Generic( const Vector &in origin, const Vector &in mins, const Vector &in maxs, edict_t@ ignore, int mask, bool ceiling, bool allow_any_step_height )
	{
		Vector start;

		// check it for real...
		Vector step_quadrant_size = (maxs - mins) * 0.5;
		step_quadrant_size.z = 0;

		Vector half_step_quadrant = step_quadrant_size * 0.5;
		Vector half_step_quadrant_mins = -half_step_quadrant;

		Vector stop;

		start.x = stop.x = origin.x;
		start.y = stop.y = origin.y;

		if( !ceiling )
		{
			start.z = origin.z + mins.z;
			stop.z = start.z - Q2_STEPSIZE * 2;
		}
		else
		{
			start.z = origin.z + maxs.z;
			stop.z = start.z + Q2_STEPSIZE * 2;
		}

		Vector mins_no_z = mins;
		Vector maxs_no_z = maxs;
		mins_no_z.z = maxs_no_z.z = 0;

		TraceResult trace;

		g_Utility.TraceLine( start, stop, dont_ignore_monsters, ignore, trace ); //gi.trace(start, mins_no_z, maxs_no_z, stop, ignore.edict(), mask);
		g_Utility.FindHullIntersection( start, trace, trace, mins_no_z, maxs_no_z, ignore ); //self.edict() ??

		if( trace.flFraction == 1.0 )
			return false;

		if( allow_any_step_height )
			return true;

		start.x = stop.x = origin.x + ((mins.x + maxs.x) * 0.5);
		start.y = stop.y = origin.y + ((mins.y + maxs.y) * 0.5);

		float mid = trace.vecEndPos.z;

		// the corners must be within 16 of the midpoint
		for( int x = 0; x <= 1; x++ )
		{
			for( int y = 0; y <= 1; y++ )
			{
				Vector quadrant_start = start;

				if( x != 0 )
					quadrant_start.x += half_step_quadrant.x;
				else
					quadrant_start.x -= half_step_quadrant.x;

				if( y != 0 )
					quadrant_start.y += half_step_quadrant.y;
				else
					quadrant_start.y -= half_step_quadrant.y;

				Vector quadrant_end = quadrant_start;
				quadrant_end.z = stop.z;

				g_Utility.TraceLine( quadrant_start, quadrant_end, dont_ignore_monsters, ignore, trace ); //gi.trace(quadrant_start, half_step_quadrant_mins, half_step_quadrant, quadrant_end, ignore.edict(), mask);
				g_Utility.FindHullIntersection( start, trace, trace, half_step_quadrant_mins, half_step_quadrant, ignore ); //self.edict() ??

				//  FIXME - this will only handle 0,0,1 and 0,0,-1 gravity vectors
				if( ceiling )
				{
					if( trace.flFraction == 1.0 or (trace.vecEndPos.z - mid) > Q2_STEPSIZE )
						return false;
				}
				else
				{
					if( trace.flFraction == 1.0 or (mid - trace.vecEndPos.z) > Q2_STEPSIZE )
						return false;
				}
			}
		}

		return true;
	}

	//from quake 2 rerelease
	bool M_CheckBottom()
	{
		// if all of the points under the corners are solid world, don't bother
		// with the tougher checks

		if( M_CheckBottom_Fast_Generic(pev.origin + pev.mins, pev.origin + pev.maxs, false) ) //ent->gravityVector[2] > 0 (gravityVector[2] should always be -1.0 for most monsters)
			return true; // we got out easy

		//contents_t mask = (ent->svflags & SVF_MONSTER) ? MASK_MONSTERSOLID : (MASK_SOLID | CONTENTS_MONSTER | CONTENTS_PLAYER);
		int mask = 0;
		return M_CheckBottom_Slow_Generic( pev.origin, pev.mins, pev.maxs, self.edict(), mask, false, HasFlags(m_iSpawnFlags, q2::SPAWNFLAG_MONSTER_SUPER_STEP) ); //ent->gravityVector[2] > 0
	}

	//from quake 2 rerelease
	CBaseEntity@ CreateGroundMonster( const Vector &in origin, const Vector &in angles, const Vector &in entMins, const Vector &in entMaxs, const string &in sClassname, float height )
	{
		CBaseEntity@ newEnt = null;

		// check the ground to make sure it's there, it's relatively flat, and it's not toxic
		if( !CheckGroundSpawnPoint(origin, entMins, entMaxs, height, -1.0, sClassname) )
			return null;

		@newEnt = CreateMonster( origin, angles, sClassname );
		if( newEnt is null )
			return null;

		return newEnt;
	}

	//from quake 2 rerelease
	CBaseEntity@ CreateMonster( const Vector &in vecOrigin, const Vector &in vecAngles, const string &in sClassname )
	{
		CBaseEntity@ cbeNewEnt = g_EntityFuncs.Create( sClassname, vecOrigin, vecAngles, true, null );
		CBaseQ2NPC@ pNewEnt = q2npc::GetQ2Pointer( cbeNewEnt );

		pNewEnt.monsterinfo.aiflags |= q2::AI_DO_NOT_COUNT;

		//pNewEnt->gravityVector = { 0, 0, -1 };

		g_EntityFuncs.DispatchSpawn( pNewEnt.self.edict() );
		//pNewEnt->s.renderfx |= RF_IR_VISIBLE;

		return cbeNewEnt;
	}

	//from quake 2 rerelease
	// this returns a randomly selected coop player who is visible to self
	// returns nullptr if bad
	CBaseEntity@ PickCoopTarget( CBaseEntity@ pEntity )
	{
		array<CBasePlayer@> arrspTargets;
		int num_targets = 0, targetID;
		CBaseEntity@ ent;

		//if we're not in coop, this is a noop
		if( !q2::IsCoop() )
			return null;

		/*//targets = (edict_t **) alloca(sizeof(edict_t *) * game.maxclients);

		for( int i = 1; i <= g_Engine.maxClients; ++i )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

			if( pPlayer !is null and pPlayer.IsAlive() )
			{
				if( visible(pEntity, pPlayer) )
					arrspTargets[num_targets++] = pPlayer;
			}
		}

		if (!num_targets)
			return null;

		// get a number from 0 to (num_targets-1)
		targetID = irandom(num_targets);*/

		return null; //arrspTargets[ targetID ];
	}

	//from quake 2 rerelease
	Vector M_ProjectFlashSource( const Vector &in offset, const Vector &in forward, const Vector &in right )
	{
		return q2::G_ProjectSource( pev.origin, (pev.scale != 0) ? (offset * pev.scale) : offset, forward, right );
	}

	bool M_CheckGib( const int &in mod )
	{
		if( pev.deadflag != DEAD_NO )
		{
			if( mod == q2::MOD_CRUSH )
				return true;
		}

		return pev.health <= m_flGibHealth;
	}

	void WalkMove( float flDist )
	{
		g_EngineFuncs.WalkMove( self.edict(), self.pev.angles.y, flDist, WALKMOVE_NORMAL );
	}

	bool HasFlags( int iFlagVariable, int iFlags )
	{
		return (iFlagVariable & iFlags) != 0;
	}

	int GetAnim()
	{
		return pev.sequence;
	}

	/*bool GetAnim( int iAnim )
	{
		return pev.sequence == iAnim;
	}*/

	bool GetAnim( int iAnim )
	{
		return pev.sequence == self.LookupSequence( arrsQ2NPCAnims[iAnim] );
	}

	void SetAnim( int iAnim, float flFramerate = 1.0, float flFrame = 0.0 )
	{
		//pev.sequence = iAnim;
		pev.sequence = self.LookupSequence( arrsQ2NPCAnims[iAnim] );
		self.ResetSequenceInfo();
		pev.frame = flFrame;
		pev.framerate = flFramerate;
	}

	int GetFrame( int iMaxFrames )
	{
		return int( (pev.frame/255) * iMaxFrames );
	}

	void SetFrame( float flMaxFrames, float flFrame )
	{
		pev.frame = float( (flFrame / flMaxFrames) * 255 );
	}

	float SetFrame2( float flMaxFrames, float flFrame )
	{
		return float( (flFrame / flMaxFrames) * 255 );
	}

	bool IsBetween( float flValue, float flMin, float flMax )
	{
		return (flValue > flMin and flValue < flMax);
	}

	bool IsBetween( int iValue, int iMin, int iMax )
	{
		return (iValue > iMin and iValue < iMax);
	}

	bool IsBetween2( float flValue, float flMin, float flMax )
	{
		return (flValue >= flMin and flValue <= flMax);
	}

	bool IsBetween2( int iValue, int iMin, int iMax )
	{
		return (iValue >= iMin and iValue <= iMax);
	}

	void SetMass( int iMass )
	{
		CustomKeyvalues@ pCustom = self.GetCustomKeyvalues();
		pCustom.SetKeyvalue( q2npc::KVN_MASS, iMass );
	}

	float realrange( CBaseEntity@ pOther )
	{
		Vector dir;

		dir = pev.origin - pOther.pev.origin;

		return dir.Length();
	}

	float hz( float hertz ) { return 1.0 / hertz; }

	float fabs( float x )
	{
		return ( (x) > 0 ? (x) : 0 - (x) );
	}

/*
float Q_fabs (float f)
{
#if 0
	if (f >= 0)
		return f;
	return -f;
#else
	int tmp = * ( int * ) &f;
	tmp &= 0x7FFFFFFF;
	return * ( float * ) &tmp;
#endif
}
*/
	void TraceMonster( string sClassname, Vector vecStart, Vector vecEnd, TraceResult &out trace )
	{
		CBaseEntity@ pNewEnt = g_EntityFuncs.Create( sClassname, g_vecZero, g_vecZero, true );
		CBaseQ2NPC@ pMonster = q2npc::GetQ2Pointer( pNewEnt );

		pMonster.monsterinfo.aiflags |= q2::AI_DO_NOT_COUNT;
		pMonster.pev.spawnflags = 16; //prisoner

		g_EntityFuncs.DispatchSpawn( pMonster.self.edict() );

		g_Utility.TraceMonsterHull( pMonster.self.edict(), vecStart, vecEnd, dont_ignore_monsters, pMonster.self.edict(), trace );

		g_EntityFuncs.Remove( pMonster.self );
	}

	//TEST
	CBaseEntity@ CreateTraceDummy( const Vector &in origin, const Vector &in mins, const Vector &in maxs )
	{
		dictionary keys;
		keys[ "origin" ] = origin.ToString();
		keys[ "targetname" ] = "trace_dummy";

		CBaseEntity@ pDummy = g_EntityFuncs.CreateEntity( "info_target", keys, false );
		if( pDummy !is null )
		{
			pDummy.pev.mins = mins;
			pDummy.pev.maxs = maxs;
			pDummy.pev.absmin = origin + mins;
			pDummy.pev.absmax = origin + maxs;
		}

		return pDummy;
	}

/*
CBaseEntity@ pTraceDummy = CreateTraceDummy( vecStart, mins, maxs );
g_EntityFuncs.DispatchSpawn( pTraceDummy.edict() );

TraceResult tr;
g_Utility.TraceMonsterHull( pTraceDummy.edict(), vecStart, vecEnd, dont_ignore_monsters, pTraceDummy.edict(), tr ); 

//checks here

g_EntityFuncs.Remove( pTraceDummy );
*/
}

ScriptSchedule slQ2Pain1
(
	0,
	0,
	"Quake 2 Pain 1"
);

ScriptSchedule slQ2Pain2
(
	0,
	0,
	"Quake 2 Pain 2"
);

ScriptSchedule slQ2Pain3
(
	0,
	0,
	"Quake 2 Pain 3"
);

ScriptSchedule slQ2Pain4
(
	0,
	0,
	"Quake 2 Pain 4"
);

void InitQ2BaseSchedules()
{
	slQ2Pain1.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain1.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_FLINCH_STOMACH)) );

	slQ2Pain2.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain2.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_FLINCH_CHEST)) );

	slQ2Pain3.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain3.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_FLINCH_HEAD)) );

	slQ2Pain4.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain4.AddTask( ScriptTask(TASK_SET_ACTIVITY, float(ACT_FLINCH_LEFTARM)) );
}
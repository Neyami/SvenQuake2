const float Q2_MELEE_DISTANCE = 80.0; //50
const float Q2_RANGE_MELEE = 60.0; //20
const float Q2_RANGE_NEAR = 500.0;
const float Q2_RANGE_MID = 1000.0;

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

class CBaseQ2NPC : ScriptBaseMonsterEntity
{
	protected bool m_bRerelease = true; //should monsters have stuff from the rerelease of Quake 2 ?

	protected int m_iSpawnFlags;

	protected float m_flMeleeCooldown;
	protected float m_flGibHealth;
	protected float m_flAttackFinished;
	protected float m_flIdleTime;
	protected float m_flNextFidget;
	protected float m_flHeatTurnRate; //for heat-seeking rockets
	protected float m_flHealthMultiplier = 1.0;
	protected float m_flPainDebounceTime;
	protected float m_flTriggeredSpawn;

	protected int m_iStepLeft;
	protected int m_iWeaponType;

	protected int m_iPowerArmorType;
	protected int m_iPowerArmorPower;
	protected float m_flArmorEffectOff;

	protected string m_sItemDrop;
	protected string m_sItemTarget;
	protected string m_sDeathTarget;
	protected string m_sHealthTarget;
	protected bool m_bHasBeenCounted;

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
				m_iPowerArmorType = q2npc::POWER_ARMOR_SCREEN;
			else if( atoi(szValue) == 2 )
				m_iPowerArmorType = q2npc::POWER_ARMOR_SHIELD;
			else
				m_iPowerArmorType = q2npc::POWER_ARMOR_NONE;

			return true;
		}
		else if( szKey == "power_armor_power" )
		{
			m_iPowerArmorPower = atoi( szValue );

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

		if( q2npc::g_iChaosMode == q2npc::CHAOS_LEVEL1 )
		{
			if( q2npc::g_iDifficulty < q2npc::DIFF_NIGHTMARE )
				m_iWeaponType = Math.RandomLong( q2npc::WEAPON_BULLET, q2npc::WEAPON_RAILGUN );
			else
				m_iWeaponType = Math.RandomLong( q2npc::WEAPON_BULLET, q2npc::WEAPON_BFG );
		}

		m_iSpawnFlags = pev.spawnflags;
		pev.spawnflags = 0;

		MonsterSpawn();

		if( !self.IsPlayerAlly() )
			q2::g_iTotalMonsters++;

		if( HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_TRIGGER_SPAWN) )
		{
			pev.nextthink = 0;
			pev.flags |= FL_NOTARGET;
			pev.effects |= EF_NODRAW;
			pev.takedamage = DAMAGE_NO;
			pev.solid = SOLID_NOT;
			pev.movetype = MOVETYPE_NONE;
		}
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

		//if( self.m_hEnemy.IsValid() and !pev.SpawnFlagBitSet(q2npc::SPAWNFLAG_MONSTER_AMBUSH) and !self.m_hEnemy.GetEntity().pev.FlagBitSet(FL_NOTARGET) )
		if( pev.enemy !is null and !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) and !pev.enemy.vars.FlagBitSet(FL_NOTARGET) )
		{
			self.m_hEnemy = EHandle( g_EntityFuncs.Instance(pev.enemy) );
			self.ChangeSchedule( self.GetScheduleOfType(SCHED_CHASE_ENEMY) );
		}
		else
			self.m_hEnemy = null;
	}

	void Use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_TRIGGER_SPAWN) )
		{
			m_iSpawnFlags &= ~q2npc::SPAWNFLAG_MONSTER_TRIGGER_SPAWN;

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

		// [Paril-KEX] fire health target (when damaged and killed)
		if( !m_sHealthTarget.IsEmpty() )
		{
			pev.target = m_sHealthTarget;
			self.SUB_UseTargets( self.m_hEnemy.GetEntity(), USE_ON, 0.0 );
		}

		MonsterKilled( pevAttacker, iGib );

		if( !self.IsPlayerAlly() and !m_bHasBeenCounted )
		{
			q2::g_iKilledMonsters++;
			m_bHasBeenCounted = true;
		}

		if( self.GetClassname() == "npc_q2jorg" or self.GetClassname() == "npc_q2makron" )
			iGib = GIB_NEVER;

		BaseClass.Killed( pevAttacker, iGib );
	}

	void MonsterKilled( entvars_t@ pevAttacker, int iGib ) {}

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
		DoSearchSound();
		CheckArmorEffect();
	}

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
		return ( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) and !self.m_hEnemy.IsValid() and g_Engine.time > m_flIdleTime );
	}

	void DoMonsterIdle()
	{
		if( !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) and self.m_Activity == ACT_IDLE and g_Engine.time > m_flIdleTime )
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

	void DoSearchSound()
	{
		if( self.m_Activity == ACT_WALK and g_Engine.time > m_flIdleTime )
		{
			if( m_flIdleTime > 0.0 )
			{
				SearchSound();
				m_flIdleTime = g_Engine.time + 15 + Math.RandomFloat(0, 1) * 15;
			}
			else
				m_flIdleTime = g_Engine.time + Math.RandomFloat(0, 1) * 15;
		}
	}

	void SearchSound() {}

	void AlertSound()
	{
		if( HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
			m_iSpawnFlags &= ~q2npc::SPAWNFLAG_MONSTER_AMBUSH;

		MonsterAlertSound();
	}

	void MonsterAlertSound() {}

	void HandleAnimEvent( MonsterEvent@ pEvent )
	{
		switch( pEvent.event )
		{
			case q2npc::AE_WALKMOVE:
			{
				//it's too buggy for movement :[
				WalkMove( atoi(pEvent.options()) );

				break;
			}

			case q2npc::AE_FOOTSTEP:
			{
				if( m_bRerelease and !HasFlags(m_iSpawnFlags, q2npc::SPAWNFLAG_MONSTER_AMBUSH) )
				{
					if( atoi(pEvent.options()) > 0 )
						monster_footstep( atoi(pEvent.options()) );
					else
						monster_footstep();
				}

				break;
			}

			//HACK
			case q2npc::AE_FLINCHRESET:
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

		HandleAnimEventQ2( pEvent );
	}

	void HandleAnimEventQ2( MonsterEvent@ pEvent ) {}

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

		if( q2npc::g_iDifficulty == q2npc::DIFF_EASY )
			flChance *= 0.5;
		else if( q2npc::g_iDifficulty >= q2npc::DIFF_HARD )
			flChance *= 2.0;

		if( Math.RandomFloat(0.0, 1.0) < flChance )
		{
			m_flAttackFinished = g_Engine.time + Math.RandomFloat( 1.0, 2.0 ); //2*random();

			return true;
		}

		return true;
	}

	bool M_ShouldReactToPain()
	{
		if( q2npc::g_iDifficulty >= q2npc::DIFF_NIGHTMARE )
			return false;

		return true;
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

		if( m_iPowerArmorType == q2npc::POWER_ARMOR_NONE )
			return 0;

		if( m_iPowerArmorPower <= 0 )
			return 0;

		if( m_iPowerArmorType == q2npc::POWER_ARMOR_SCREEN )
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

		flSave = m_iPowerArmorPower * iDamagePerCell;

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

		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, "quake2/weapons/laser_hit.wav", VOL_NORM, ATTN_NORM );

		if( m_iPowerArmorType == q2npc::POWER_ARMOR_SCREEN )
			PowerArmorEffect( flYaw );
		else if( m_iPowerArmorType == q2npc::POWER_ARMOR_SHIELD )
			PowerArmorEffect( flYaw, false );

		iPowerUsed = int(flSave) / iDamagePerCell;

		m_iPowerArmorPower -= iPowerUsed;

		if( m_iPowerArmorPower <= 0 )
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

	//for chaos mode
	void monster_fire_weapon( int iWeaponType, Vector vecMuzzle, Vector vecAim, float flDamage, float flSpeed = 600.0, float flRightAdjust = 0.0, float flUpAdjust = 0.0 )
	{
		if( q2npc::g_iChaosMode == q2npc::CHAOS_LEVEL1 )
			iWeaponType = m_iWeaponType;
		else if( (m_iWeaponType & 2048) != 0 )
		{
			//DESPERATION MOVE >:D
			m_iWeaponType &= ~2048;
			iWeaponType = m_iWeaponType;
		}
		else if( q2npc::g_iChaosMode == q2npc::CHAOS_LEVEL2 )
		{
			if( q2npc::g_iDifficulty < q2npc::DIFF_NIGHTMARE )
				iWeaponType = Math.RandomLong( q2npc::WEAPON_BULLET, q2npc::WEAPON_RAILGUN );
			else
				iWeaponType = Math.RandomLong( q2npc::WEAPON_BULLET, q2npc::WEAPON_BFG );
		}

		switch( iWeaponType )
		{
			case q2npc::WEAPON_BULLET:
			{
				monster_fire_bullet( vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2npc::WEAPON_SHOTGUN:
			{
				pev.weapons = q2::MOD_SHOTGUN;
				monster_fire_shotgun( vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2npc::WEAPON_BLASTER:
			{
				if( self.GetClassname() == "npc_q2soldier_light" )
					monster_fire_blaster( vecMuzzle, vecAim, flDamage, flSpeed );
				else
					monster_fire_blaster( vecMuzzle, vecAim, flDamage, flSpeed, true );

				break;
			}

			case q2npc::WEAPON_GRENADE:
			{
				monster_fire_grenade( vecMuzzle, vecAim, flDamage, flSpeed, flRightAdjust, flUpAdjust );
				break;
			}

			case q2npc::WEAPON_ROCKET:
			{
				monster_fire_rocket( vecMuzzle, vecAim, flDamage, flSpeed );
				break;
			}

			case q2npc::WEAPON_HEATSEEKING:
			{
				monster_fire_rocket( vecMuzzle, vecAim, flDamage, flSpeed, true );
				break;
			}

			case q2npc::WEAPON_RAILGUN:
			{
				monster_fire_railgun( vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2npc::WEAPON_BFG:
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

	void monster_fire_blaster( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHyper = false )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, false, self.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pLaser.pev.netname = sMonsterName;

		if( bHyper )
			pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
		else
			pLaser.pev.weapons = q2::MOD_BLASTER;

		if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pLaser.pev.movetype = MOVETYPE_TOSS;
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
		CBaseEntity@ pRocket = g_EntityFuncs.Create( "q2rocket", vecStart, vecDir, true, self.edict() ); 
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		if( self.GetClassname() == "npc_q2supertank" )
			pRocket.pev.scale = 2.0;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pRocket.pev.netname = sMonsterName;

		if( bHeatSeeking )
		{
			pRocket.pev.weapons = 1;
			pRocket.pev.speed = flSpeed;
			pRocket.pev.frags = m_flHeatTurnRate;
		}

		g_EntityFuncs.DispatchSpawn( pRocket.edict() );

		if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pRocket.pev.movetype = MOVETYPE_TOSS;
	}

	void monster_fire_bfg( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, float flDamageRadius )
	{
		CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfg", vecStart, vecDir, false, self.edict() );
		pBFG.pev.velocity = vecDir * flSpeed;
		pBFG.pev.dmg = flDamage;
		pBFG.pev.dmgtime = flDamageRadius;

		string sMonsterName;
		q2npc::g_dicMonsterNames.get( self.GetClassname(), sMonsterName ); //for death messages
		pBFG.pev.netname = sMonsterName;

		if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and self.GetClassname() == "npc_q2supertank" and pev.sequence == self.LookupSequence("attack_grenade") )
			pBFG.pev.movetype = MOVETYPE_TOSS;
	}

	void monster_fire_railgun( Vector vecStart, Vector vecEnd, float flDamage )
	{
		TraceResult tr;

		vecEnd = vecStart + vecEnd * 8192;
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
				pHit.TraceAttack( self.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

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

	Vector closest_point_to_box( const Vector &in from, const Vector &in absmins, const Vector &in absmaxs )
	{
		return Vector(
			(from.x < absmins.x) ? absmins.x : (from.x > absmaxs.x) ? absmaxs.x : from.x,
			(from.y < absmins.y) ? absmins.y : (from.y > absmaxs.y) ? absmaxs.y : from.y,
			(from.z < absmins.z) ? absmins.z : (from.z > absmaxs.z) ? absmaxs.z : from.z
		);
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

	void WalkMove( float flDist )
	{
		g_EngineFuncs.WalkMove( self.edict(), self.pev.angles.y, flDist, WALKMOVE_NORMAL );
	}

	bool visible( CBaseEntity@ pTarget )
	{
		TraceResult tr;

		Vector spot1 = self.EyePosition();
		Vector spot2 = pTarget.EyePosition();

		// see through other monsters
		g_Utility.TraceLine( spot1, spot2, ignore_monsters, ignore_glass, self.edict(), tr );

		if( tr.fInOpen != 0 and tr.fInWater != 0 )
			return false;

		if( tr.flFraction == 1.0 )
			return true;

		return false;
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
	slQ2Pain1.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_FLINCH_STOMACH)) );
	//slQ2Pain1.AddTask( ScriptTask(TASK_PAIN_LOOP, 0) );

	slQ2Pain2.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain2.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_FLINCH_CHEST)) );

	slQ2Pain3.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain3.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_FLINCH_HEAD)) );

	slQ2Pain4.AddTask( ScriptTask(TASK_STOP_MOVING) );
	slQ2Pain4.AddTask( ScriptTask(TASK_PLAY_SEQUENCE, float(ACT_FLINCH_LEFTARM)) );
}

/*
self.m_hTargetEnt
self.MoveToTarget( Activity movementAct, float waitTime ) 
*/
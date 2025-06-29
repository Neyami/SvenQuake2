enum Q2_ATTACKSTATE
{
	ATTACK_NONE = 0,
	ATTACK_STRAIGHT,
	ATTACK_SLIDING,
	ATTACK_MELEE,
	ATTACK_MISSILE
};

enum Q2_AISTATE
{
	STATE_IDLE = 0,
	STATE_WALK,
	STATE_RUN,
	STATE_ATTACK,
	STATE_PAIN,
	STATE_DEAD
};

enum Q2_RANGETYPE
{
	RANGE_MELEE = 0,
	RANGE_NEAR,
	RANGE_MID,
	RANGE_FAR
};

mixin class CBaseQ1Flying
{
	//QUAKE 1
	EHandle m_hGoalEnt;	 //path corner we are heading towards
	EHandle m_hMoveTarget;
	EHandle m_hOldEnemy;

	float m_flSearchTime;
	float m_flPauseTime;

	Q2_AISTATE m_iAIState;
	Q2_ATTACKSTATE m_iAttackState;

	Activity m_Activity; //what the monster is doing (animation)
	Activity m_IdealActivity; //monster should switch to this activity

	float m_flMonsterSpeed;
	float m_flMoveDistance;
	bool m_fLeftY;

	float m_flSightTime;
	EHandle m_hSightEntity;
	int m_iRefireCount;

	float m_flEnemyYaw;
	Q2_RANGETYPE m_iEnemyRange;
	bool m_fEnemyInFront;
	bool m_fEnemyVisible;

	float m_flShowHostile;
	float m_flAttackFinished;

	//OVERRIDES
	void MonsterIdle() {}
	void MonsterSight() {}
	void MonsterRun() {}
	void MonsterWalk() {}
	void MonsterAttack() { AI_Face(); }
	void MonsterMeleeAttack() {}
	void MonsterMissileAttack() {}
	bool MonsterHasMeleeAttack() { return false; }
	bool MonsterHasMissileAttack() { return false; }

	//QUAKE 2
	bool m_bRerelease= true;
	float m_flHealthMultiplier = 1.0;
	float pain_debounce_time;

	//OTHER
	private int m_iWeaponType;
	private float m_flHeatTurnRate = 0.075;

	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
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

		MonsterSpawn();
	}

	void MonsterSpawn() { }

	/*void SetEyePosition()
	{
		//Vector vecEyePosition;
		//void	*pmodel = GET_MODEL_PTR( ENT(pev) );
		//GetEyePosition( pmodel, vecEyePosition );
		//pev.view_ofs = vecEyePosition;

		//if( pev.view_ofs == g_vecZero )
		{
			pev.view_ofs = Vector( 0, 0, 25 );
		}
	}*/

	bool FindTarget()
	{
		CBaseEntity@ pTarget;

		// if the first spawnflag bit is set, the monster will only wake up on
		// really seeing the player, not another monster getting angry

		// spawnflags & 3 is a big hack, because zombie crucified used the first
		// spawn flag prior to the ambush flag, and I forgot about it, so the second
		// spawn flag works as well
		if( m_flSightTime >= (g_Engine.time - 0.1) ) //and !FBitSet(pev.spawnflags, 3)
		{
			@pTarget = m_hSightEntity.GetEntity();
			if( pTarget is null or pTarget.pev.enemy is pev.enemy )
				return false;
		}
		else
		{
			//Look for players first
			for( int i = 1; i <= g_Engine.maxClients; ++i )
			{
				CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

				if( pPlayer !is null and pPlayer.IsAlive() )
				{
					if( !IsTargetValid(pPlayer) )
						continue;

					@pTarget = pPlayer;
				}
			}

			//no valid player found, look for hostile monsters
			if( pTarget is null )
			{
				array<CBaseEntity@> arrpMonsters(8);

				int iNum = g_EntityFuncs.MonstersInSphere( arrpMonsters, pev.origin, 1024.0 );
				if( iNum > 0 )
				{
					for( uint i = 0; i < arrpMonsters.length(); i++ )
					{
						CBaseEntity@ pMonster = arrpMonsters[i];
						if( pMonster !is null and pMonster.IsAlive() )
						{
							if( !IsTargetValid(pMonster) )
								continue;

							@pTarget = pMonster;
						}
					}
				}
			}

			if( pTarget is null )
				return false; // current check entity isn't in PVS

			//g_Game.AlertMessage( at_notice, "pTarget: %1\n", string(pTarget.pev.classname) );
		}

		// got one
		self.m_hEnemy = EHandle( pTarget );

		//if( self.m_hEnemy.GetEntity().GetClassname() != "player" )
		if( !GetEnemyEntity().pev.FlagBitSet(FL_CLIENT|FL_MONSTER) )
		{
			self.m_hEnemy = EHandle( g_EntityFuncs.Instance(pTarget.pev.enemy) );
			if( !self.m_hEnemy.IsValid() or !GetEnemyEntity().pev.FlagBitSet(FL_CLIENT|FL_MONSTER) )
			{
				m_flPauseTime = g_Engine.time + 3.0;
				m_hGoalEnt = m_hMoveTarget;	// restore last path_corner (if present)
				self.m_hEnemy = null;

				return false;
			}
		}

		FoundTarget();

		return true;
	}

	bool IsTargetValid( CBaseEntity@ pTarget )
	{
		if( pTarget is self )
			return false;

		if( pTarget.pev.health <= 0 )
			return false;

		if( pTarget == self.m_hEnemy.GetEntity() )
			return false;

		if( pTarget.pev.FlagBitSet(FL_NOTARGET) )
			return false;

		if( pTarget.pev.FlagBitSet(FL_CLIENT) and self.IsPlayerAlly() )
			return false;

		if( self.IRelationship(pTarget) <= R_NO )
			return false;

		Q2_RANGETYPE range = TargetRange( pTarget );
		if( range == RANGE_FAR )
			return false;

		if( !TargetVisible(pTarget) )
			return false;

		if( !InFront(pTarget) )
			return false;

		return true;
	}

	void FoundTarget()
	{
		if( self.m_hEnemy.IsValid() and GetEnemyEntity().pev.FlagBitSet(FL_CLIENT|FL_MONSTER) ) //self.m_hEnemy.GetEntity().GetClassname() == "player"
		{	
			// let other monsters see this monster for a while
			m_hSightEntity = EHandle( self );
			m_flSightTime = g_Engine.time;
		}

		m_flShowHostile = g_Engine.time + 1.0; // wake up other monsters

		//for path_corner etc
		@pev.enemy = @self.m_hEnemy.GetEntity().edict();

		MonsterSight();
		HuntTarget();
	}

	void HuntTarget()
	{
		m_hGoalEnt = self.m_hEnemy;
		m_iAIState = STATE_RUN;

		pev.ideal_yaw = Math.VecToYaw( self.m_hEnemy.GetEntity().pev.origin - pev.origin );

		SetThink( ThinkFunction(MonsterThink) );
		pev.nextthink = g_Engine.time + 0.1;

		MonsterRun();
		AttackFinished( 1 );	// wait a while before first attack
	}

	bool InFront( CBaseEntity@ pTarget )
	{
		Math.MakeVectors( pev.angles );
		Vector dir = (pTarget.pev.origin - pev.origin).Normalize();

		float flDot = DotProduct( dir, g_Engine.v_forward );

		if( flDot > 0.3 )
			return true;

		return false;
	}

	void AttackFinished( float flFinishTime )
	{
		m_iRefireCount = 0; // refire count for nightmare

		if( q2npc::g_iDifficulty != q2::DIFF_NIGHTMARE )
			m_flAttackFinished = g_Engine.time + flFinishTime;
	}

	Q2_RANGETYPE TargetRange( CBaseEntity@ pTarget )
	{
		Vector spot1 = self.EyePosition();
		Vector spot2 = pTarget.EyePosition();

		float dist = (spot1 - spot2).Length();
		if( dist < 100 ) //120
			return RANGE_MELEE;

		if( dist < Q2_RANGE_NEAR ) //500
			return RANGE_NEAR;

		if( dist < Q2_RANGE_MID ) //1000
			return RANGE_MID;

		return RANGE_FAR;
	}

	bool TargetVisible( CBaseEntity@ pTarget )
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

	bool FacingIdeal()
	{
		float delta = Math.AngleMod( pev.angles.y - pev.ideal_yaw );

		if( delta > 45 and delta < 315 )
			return false;

		return true;
	}

	bool MonsterCheckAttack()
	{
		Vector spot1, spot2;
		CBaseEntity@ pTarget;
		float flChance;

		@pTarget = self.m_hEnemy.GetEntity();

		// see if any entities are in the way of the shot
		spot1 = self.EyePosition();
		spot2 = pTarget.EyePosition();

		TraceResult tr;
		g_Utility.TraceLine( spot1, spot2, dont_ignore_monsters, dont_ignore_glass, self.edict(), tr );

		if( tr.pHit !is pTarget.edict() )
			return false; // don't have a clear shot

		if( tr.fInOpen != 0 and tr.fInWater != 0 )
			return false; // sight line crossed contents

		if( m_iEnemyRange == RANGE_MELEE )
		{	
			if( MonsterHasMeleeAttack() )
			{
				MonsterMeleeAttack();
				return true;
			}
		}

		if( !MonsterHasMissileAttack() )
			return false;

		if( g_Engine.time < m_flAttackFinished )
			return false;

		if( m_iEnemyRange == RANGE_FAR )
			return false;

		if( m_iEnemyRange == RANGE_MELEE )
		{
			flChance = 0.9;
			m_flAttackFinished = 0.0;
		}
		else if( m_iEnemyRange == RANGE_NEAR )
		{
			if( MonsterHasMeleeAttack() )
				flChance = 0.2;
			else
				flChance = 0.4;
		}
		else if( m_iEnemyRange == RANGE_MID )
		{
			if( MonsterHasMeleeAttack() )
				flChance = 0.05;
			else
				flChance = 0.1;
		}
		else
			flChance = 0.0;

		if( Math.RandomFloat(0, 1) < flChance )
		{
			MonsterMissileAttack();
			AttackFinished( Math.RandomFloat(0.0, 2.0) );

			return true;
		}

		return false;
	}

	bool MonsterCheckAnyAttack()
	{
		if( !m_fEnemyVisible )
			return false;

		return MonsterCheckAttack();
	}

	void MonsterUse( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( self.m_hEnemy.IsValid() )
			return;

		if( pev.health <= 0 )
			return;

		//if( pActivator.m_iItems & IT_INVISIBILITY )
			//return;

		if( pActivator.pev.FlagBitSet(FL_NOTARGET) )
			return;

		if( pActivator.GetClassname() != "player" )
			return;

		// delay reaction so if the monster is teleported,
		// its sound is still heard
		self.m_hEnemy = EHandle( pActivator );

		SetThink( ThinkFunction(FoundTarget) );
		pev.nextthink = g_Engine.time + 0.1;
	}

	void MonsterThink()
	{
		pev.nextthink = g_Engine.time + 0.1;
		Vector vecOldOrigin = pev.origin;

		float flInterval = self.StudioFrameAdvance( 0.099 );

		if( m_iAIState != STATE_DEAD and self.m_fSequenceFinished )
		{
			self.ResetSequenceInfo();

			if( m_iAIState == STATE_PAIN )
				MonsterRun();
		}

		self.DispatchAnimEvents( flInterval );

		if( m_iAIState == STATE_IDLE )
			ai_stand();
		else if( m_iAIState == STATE_WALK )
			ai_walk( m_flMonsterSpeed );
		else if( m_iAIState == STATE_ATTACK )
			MonsterAttack();
		else if( m_iAIState == STATE_RUN )
			ai_run( m_flMonsterSpeed );
	}

	void ai_walk( float flDist )
	{
		m_flMoveDistance = flDist;

		if( FindTarget() )
			return;

		MoveToGoal( flDist );
	}

	void ai_run( float flDist )
	{
		Vector delta;

		m_flMoveDistance = flDist;

		// see if the enemy is dead
		if( !self.m_hEnemy.IsValid() or self.m_hEnemy.GetEntity().pev.health <= 0 )
		{
			self.m_hEnemy = null;
			@pev.enemy = null;

			// FIXME: look all around for other targets
			if( m_hOldEnemy.IsValid() and m_hOldEnemy.GetEntity().pev.health > 0 )
			{
				self.m_hEnemy = m_hOldEnemy;
				@pev.enemy = @m_hOldEnemy.GetEntity().edict();
				HuntTarget();
			}
			else
			{
				if( m_hMoveTarget.IsValid() )
				{
					// g-cont. stay over defeated player a few seconds
					// then continue patrol (if present)
					m_flPauseTime = g_Engine.time + 5.0;
					m_hGoalEnt = m_hMoveTarget;
				}

				MonsterIdle();
				return;
			}
		}

		m_flShowHostile = g_Engine.time + 1.0; // wake up other monsters

		// check knowledge of enemy
		m_fEnemyVisible = TargetVisible( self.m_hEnemy.GetEntity() );

		if( m_fEnemyVisible )
			m_flSearchTime = g_Engine.time + 5.0;

		// look for other coop players
		if( m_flSearchTime < g_Engine.time )
		{
			if( FindTarget() )
				return;
		}

		m_fEnemyInFront = InFront( self.m_hEnemy.GetEntity() );
		m_iEnemyRange = TargetRange( self.m_hEnemy.GetEntity() );
		m_flEnemyYaw = Math.VecToYaw( self.m_hEnemy.GetEntity().pev.origin - pev.origin );

		if( m_iAttackState == ATTACK_MISSILE )
		{
			ai_run_missile();
			return;
		}

		if( m_iAttackState == ATTACK_MELEE )
		{
			ai_run_melee();
			return;
		}

		if( MonsterCheckAnyAttack() )
			return; // beginning an attack

		if( m_iAttackState == ATTACK_SLIDING )
		{
			ai_run_slide();
			return;
		}

		// head straight in
		MoveToGoal( flDist );	// done in C code...
	}

	void ai_stand()
	{
		if( FindTarget() )
			return;

		if( g_Engine.time > m_flPauseTime )
		{
			MonsterWalk();
			return;
		}
	}

	void ai_run_melee()
	{
		pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if( FacingIdeal() )
		{
			MonsterMeleeAttack();
			m_iAttackState = ATTACK_STRAIGHT;
		}
	}

	void ai_run_missile()
	{
		pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if( FacingIdeal() )
		{
			MonsterMissileAttack();
			m_iAttackState = ATTACK_STRAIGHT;
		}
	}

	void ai_run_slide()
	{
		float ofs;

		pev.ideal_yaw = m_flEnemyYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		if( m_fLeftY )
			ofs = 90;
		else
			ofs = -90;

		if( WalkMove(pev.ideal_yaw + ofs, m_flMoveDistance) )
			return;

		m_fLeftY = !m_fLeftY;

		WalkMove( pev.ideal_yaw - ofs, m_flMoveDistance );
	}

	void AI_Face()
	{
		if( self.m_hEnemy.IsValid() )
			pev.ideal_yaw = Math.VecToYaw( self.m_hEnemy.GetEntity().pev.origin - pev.origin );

		g_EngineFuncs.ChangeYaw( self.edict() );
	}

	void AI_Charge( float flDist )
	{
		AI_Face();
		MoveToGoal( flDist );
	}

	void FlyMonsterInitThink()
	{
		pev.takedamage = DAMAGE_AIM;
		pev.ideal_yaw = pev.angles.y;

		if( pev.yaw_speed == 0 )
			pev.yaw_speed = 10;

		//SetEyePosition();

		//if( !self.IsPlayerAlly() )
			SetUse( UseFunction(MonsterUse) );

		pev.flags |= (FL_FLY|FL_MONSTER);

		if (!WalkMove( 0, 0 ))
		{
			//g_Game.AlertMessage( at_notice, "Monster %1 stuck in wall--level design error\n", string(pev.classname) ); //at_error
			pev.effects = EF_BRIGHTFIELD;
		}

		if( !string(pev.target).IsEmpty() )
		{
			m_hGoalEnt = EHandle( self.GetNextTarget() );
			m_hMoveTarget = m_hGoalEnt;

			if( !m_hGoalEnt.IsValid() )
				//g_Game.AlertMessage( at_notice, "MonsterInit()--%1 couldn't find target %2", string(pev.classname), string(pev.target) ); //at_error

			if( m_hGoalEnt.IsValid() and m_hGoalEnt.GetEntity().GetClassname() == "path_corner" )
				MonsterWalk();
			else
				m_flPauseTime = 99999999.0;
				MonsterIdle();
		}
		else
		{
			m_flPauseTime = 99999999.0;
			MonsterIdle();
		}

		// run AI for monster
		SetThink( ThinkFunction(MonsterThink) );
		MonsterThink(); //why not just set nextthink ??
	}

	void FlyMonsterInit()
	{
		// spread think times so they don't all happen at same time
		pev.nextthink += Math.RandomFloat( 0.1, 0.4 );
		SetThink( ThinkFunction(FlyMonsterInitThink) );
	}

	bool SV_MoveStep( const Vector &in vecMove, bool relink )
	{
		float dz;
		TraceResult trace;

		// try the move	
		Vector oldorg = pev.origin;
		Vector neworg = pev.origin + vecMove;

		// flying monsters don't step up
		if( pev.FlagBitSet(FL_SWIM|FL_FLY) )
		{
			// try one move with vertical motion, then one without
			for( int i = 0; i < 2; i++ )
			{
				CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();
				neworg = pev.origin + vecMove;

				if( i == 0 and pEnemy !is null )
				{
					dz = pev.origin.z - pEnemy.pev.origin.z;

					if( dz > 40 )
						neworg.z -= 8;

					if( dz < 30 )
						neworg.z += 8;
				}

				g_Utility.TraceMonsterHull( self.edict(), pev.origin, neworg, dont_ignore_monsters, self.edict(), trace ); 
		
				if( trace.flFraction == 1.0 )
				{
					if( pev.FlagBitSet(FL_SWIM) and g_EngineFuncs.PointContents(trace.vecEndPos) == CONTENTS_EMPTY )
						return false; // swim monster left water
		
					pev.origin = trace.vecEndPos;

					if( relink )
						g_EntityFuncs.SetOrigin( self, pev.origin );

					return true;
				}

				if( pEnemy is null )
					break;
			}

			return false;
		}

		return true;
	}

	bool SV_StepDirection( float flYaw, float flDist )
	{
		Vector vecMove, vecOldOrigin;
		float flDelta;

		pev.ideal_yaw = flYaw;
		g_EngineFuncs.ChangeYaw( self.edict() );

		flYaw = flYaw * Math.PI * 2 / 360;
		vecMove.x = cos( flYaw ) * flDist;
		vecMove.y = sin( flYaw ) * flDist;
		vecMove.z = 0.0;

		vecOldOrigin = pev.origin;

		if( SV_MoveStep(vecMove, false) )
		{
			flDelta = pev.angles.y - pev.ideal_yaw;

			if( flDelta > 45 and flDelta < 315 )
			{	
				// not turned far enough, so don't take the step
				pev.origin = vecOldOrigin;
			}

			g_EntityFuncs.SetOrigin( self, pev.origin );

			return true;
		}

		g_EntityFuncs.SetOrigin( self, pev.origin );

		return false;
	}

	bool SV_CloseEnough( CBaseEntity@ pGoal, float flDist )
	{
		for( int i = 0; i < 3; i++ )
		{
			if( pGoal.pev.absmin[i] > pev.absmax[i] + flDist )
				return false;

			if( pGoal.pev.absmax[i] < pev.absmin[i] - flDist )
				return false;
		}

		return true;
	}

	bool WalkMove( float flYaw, float flDist )
	{
		return g_EngineFuncs.WalkMove( self.edict(), flYaw, flDist, WALKMOVE_NORMAL ) != 0;
	}

	void MoveToGoal( float flDist )
	{
		if( !pev.FlagBitSet(FL_ONGROUND|FL_FLY|FL_SWIM) )
			return;

		CBaseEntity@ pGoal = m_hGoalEnt.GetEntity();
		CBaseEntity@ pEnemy = self.m_hEnemy.GetEntity();

		if( pGoal is null )
			return;

		if( pEnemy !is null and SV_CloseEnough(pGoal, flDist) )
			return;

		// bump around...
		if( Math.RandomLong(0, 3) == 1 or !SV_StepDirection(pev.ideal_yaw, flDist) ) //( rand() & 3 ) == 1
			SV_NewChaseDir( pGoal, flDist );
	}

	void SV_NewChaseDir( CBaseEntity@ pEnemy, float flDist )
	{
		float deltax, deltay;
		float tdir, olddir, turnaround;
		Vector d;

		olddir = Math.AngleMod( int(pev.ideal_yaw / 45) * 45 );
		turnaround = Math.AngleMod( olddir - 180 );

		deltax = pEnemy.pev.origin.x - pev.origin.x;
		deltay = pEnemy.pev.origin.y - pev.origin.y;

		if( deltax > 10 )
			d.y = 0;
		else if( deltax < -10 )
			d.y = 180;
		else
			d.y = -1;

		if( deltay < -10 )
			d.z = 270;
		else if( deltay > 10 )
			d.z = 90;
		else
			d.z = -1;

		// try direct route
		if( d.y != -1 and d.z != -1 )
		{
			if( d.y == 0 )
				tdir = d.z == 90 ? 45 : 315;
			else
				tdir = d.z == 90 ? 135 : 215;

			if( tdir != turnaround and SV_StepDirection(tdir, flDist) )
				return;
		}

		// try other directions
		if( (Math.RandomLong(0, 3) & 1) != 0 or abs(deltay) > abs(deltax) ) //((rand() & 3 ) & 1)
		{
			tdir = d.y;
			d.y = d.z;
			d.z = tdir;
		}

		if( d.y != -1 and d.y != turnaround and SV_StepDirection(d.y, flDist) )
			return;

		if( d.z != -1 and d.z != turnaround and SV_StepDirection(d.z, flDist) )
			return;

		// there is no direct path to the player, so pick another direction
		if( olddir != -1 and SV_StepDirection(olddir, flDist) )
			return;

		if( Math.RandomLong(0, 1) == 1 ) // randomly determine direction of search
		{
			for( tdir = 0; tdir <= 315; tdir += 45 )
			{
				if( tdir != turnaround and SV_StepDirection(tdir, flDist) )
					return;
			}
		}
		else
		{
			for( tdir = 315; tdir >= 0; tdir -= 45 )
			{
				if( tdir != turnaround and SV_StepDirection(tdir, flDist) )
					return;
			}
		}

		if( turnaround != -1 and SV_StepDirection(turnaround, flDist) )
			return;

		pev.ideal_yaw = olddir; // can't move

		// if a bridge was pulled out from underneath a monster, it may not have
		// a valid standing position at all
		if( g_EngineFuncs.EntIsOnFloor(self.edict()) == 0 )
			pev.flags |= FL_PARTIALGROUND;
	}

	void SetActivity( Activity NewActivity )
	{
		int iSequence;

		iSequence = self.LookupActivity( NewActivity );

		// Set to the desired anim, or default anim if the desired is not present
		if( iSequence > -1 ) //ACTIVITY_NOT_AVAILABLE
		{
			if( pev.sequence != iSequence or !self.m_fSequenceLoops )
			{
				// don't reset frame between walk and run
				if( !(m_Activity == ACT_WALK or m_Activity == ACT_RUN) or !(NewActivity == ACT_WALK or NewActivity == ACT_RUN) )
					pev.frame = 0;
			}

			pev.sequence = iSequence;	// Set to the reset anim (if it's there)
			self.ResetSequenceInfo();
		}
		else
		{
			// Not available try to get default anim
			//g_Game.AlertMessage( at_notice, "%1 has no sequence for act:%2\n", string(pev.classname), g_ActivityMap.GetName(NewActivity) ); //at_aiconsole
			pev.sequence = 0;	// Set to the reset anim (if it's there)
		}

		m_Activity = NewActivity; // Go ahead and set this so it doesn't keep trying when the anim is not present

		// In case someone calls this with something other than the ideal activity
		m_IdealActivity = m_Activity;
	}

	void SetEnemy( CBaseEntity@ pEntity )
	{
		self.m_hEnemy = EHandle( pEntity );
	}

	EHandle GetEnemy()
	{
		return self.m_hEnemy;
	}

	CBaseEntity@ GetEnemyEntity()
	{
		return self.m_hEnemy.GetEntity();
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

	//for chaos mode
	void monster_fire_weapon( int iWeaponType, Vector vecMuzzle, Vector vecAim, float flDamage, float flSpeed = 600.0, float flRightAdjust = 0.0, float flUpAdjust = 0.0 )
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
				q2::monster_fire_bullet( self, vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2::WEAPON_SHOTGUN:
			{
				q2::monster_fire_shotgun( self, vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2::WEAPON_BLASTER:
			{
				q2::monster_fire_blaster( self, vecMuzzle, vecAim, flDamage, flSpeed, true );
				break;
			}

			case q2::WEAPON_GRENADE:
			{
				q2::monster_fire_grenade( self, vecMuzzle, vecAim, flDamage, flSpeed, flRightAdjust, flUpAdjust );
				break;
			}

			case q2::WEAPON_ROCKET:
			{
				q2::monster_fire_rocket( self, vecMuzzle, vecAim, flDamage, flSpeed );
				break;
			}

			case q2::WEAPON_HEATSEEKING:
			{
				q2::monster_fire_rocket( self, vecMuzzle, vecAim, flDamage, flSpeed, true, m_flHeatTurnRate );
				break;
			}

			case q2::WEAPON_RAILGUN:
			{
				q2::monster_fire_railgun( self, vecMuzzle, vecAim, flDamage );
				break;
			}

			case q2::WEAPON_BFG:
			{
				q2::monster_fire_bfg( self, vecMuzzle, vecAim, flDamage, flSpeed, 200 );
				break;
			}
		}
	}

	//QUAKE 2
	bool fire_hit( Vector aim, float flDamage, int flKick )
	{
		if( !GetEnemy().IsValid() )
			return false;

		TraceResult	tr;
		Vector			forward, right, up;
		Vector			v;
		Vector			point;
		float				range;
		Vector			dir;

		//see if enemy is in range
		dir = GetEnemy().GetEntity().pev.origin - pev.origin;
		range = dir.Length();
		if( range > aim.x )
			return false;

		if( aim.y > pev.mins.x and aim.y < pev.maxs.x )
		{
			// the hit is straight on so back the range up to the edge of their bbox
			range -= GetEnemy().GetEntity().pev.maxs.x;
		}
		else
		{
			// this is a side hit so adjust the "right" value out to the edge of their bbox
			if( aim.y < 0 )
				aim.y = GetEnemy().GetEntity().pev.mins.x;
			else
				aim.y = GetEnemy().GetEntity().pev.maxs.x;
		}

		point = pev.origin + dir * range;

		//tr = gi.trace (self->s.origin, NULL, NULL, point, self, MASK_SHOT);
		g_Utility.TraceLine( pev.origin, point, dont_ignore_monsters, self.edict(), tr );
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit.vars.takedamage == DAMAGE_NO )
				return false;

			// if it will hit any client/monster then hit the one we wanted to hit
			if( tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) ) //(tr.ent->svflags & SVF_MONSTER) or tr.ent->client
				@tr.pHit = GetEnemy().GetEntity().edict();
		}

		g_EngineFuncs.AngleVectors( pev.angles, forward, right, up );

		point = pev.origin + forward * range + right * aim.y + up * aim.z;
		dir = point - GetEnemy().GetEntity().pev.origin;

		// do the damage
		//T_Damage (tr.ent, self, self, dir, point, vec3_origin, flDamage, flKick/2, DAMAGE_NO_KNOCKBACK, MOD_HIT);
		q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), self, self, dir, point, g_vecZero, flDamage, flKick/2, 0, q2::MOD_HIT );
		//g_EntityFuncs.Instance(tr.pHit).TakeDamage( self.pev, self.pev, flDamage, DMG_GENERIC );

		//if( !(tr.ent->svflags & SVF_MONSTER) and (!tr.ent->client) )
		if( !tr.pHit.vars.FlagBitSet(FL_MONSTER|FL_CLIENT) )
			return false;

		// do our special form of knockback here
		v = GetEnemy().GetEntity().pev.absmin + GetEnemy().GetEntity().pev.size * 0.5;
		v = (v - point).Normalize(); //VectorNormalize (v);
		self.m_hEnemy.GetEntity().pev.velocity = GetEnemy().GetEntity().pev.velocity + v * flKick;

		//if( GetEnemy().GetEntity().pev.velocity.z > 0 )
			//@self.m_hEnemy.GetEntity().pev.groundentity = null;

		return true;
	}

	//TODO fix this ??
	void SetSkin() { MonsterSetSkin(); }
	void MonsterSetSkin() {}

	bool M_ShouldReactToPain()
	{
		if( q2npc::g_iDifficulty >= q2::DIFF_NIGHTMARE )
			return false;

		return true;
	}

	void M_ReactToDamage( CBaseEntity@ pAttacker )
	{
		if( !pAttacker.pev.FlagBitSet(FL_MONSTER|FL_CLIENT) )
			return;

		if( pAttacker is self or pAttacker is GetEnemyEntity() )
			return;

		// if we are a good guy monster and our attacker is a player
		// or another good guy, do not get mad at them
		//if( HasFlags(monsterinfo.aiflags, AI_GOOD_GUY) )
		if( self.IsPlayerAlly() )
		{
			if( pAttacker.pev.FlagBitSet(FL_CLIENT) or pAttacker.IsPlayerAlly() ) //or (pAttacker->monsterinfo.aiflags & AI_GOOD_GUY)
				return;
		}

		// we now know that we are not both good guys

		// if attacker is a client, get mad at them because he's good and we're not
		if( pAttacker.pev.FlagBitSet(FL_CLIENT) )
		{
			//monsterinfo.aiflags &= ~AI_SOUND_TARGET;

			// this can only happen in coop (both new and old enemies are clients)
			// only switch if can't see the current enemy
			if( GetEnemy().IsValid() and GetEnemyEntity().pev.FlagBitSet(FL_CLIENT) )
			{
				if( TargetVisible(GetEnemyEntity()) )
				{
					m_hOldEnemy = EHandle( pAttacker );
					return;
				}

				m_hOldEnemy = GetEnemy();
			}

			SetEnemy( pAttacker );

			//if( !HasFlags(monsterinfo.aiflags, AI_DUCKED) )
				FoundTarget();

			return;
		}

		CBaseMonster@ pMonster = pAttacker.MyMonsterPointer();
		if( pMonster is null ) return;

		// it's the same base (walk/swim/fly) type and a different classname and it's not a tank
		// (they spray too much), get mad at them
		if( ((pev.FlagBitSet(FL_FLY|FL_SWIM)) == (pMonster.pev.FlagBitSet(FL_FLY|FL_SWIM))) and //(((self->flags & (FL_FLY|FL_SWIM)) == (pMonster->flags & (FL_FLY|FL_SWIM)))
			self.GetClassname() != pMonster.GetClassname() and 
			pMonster.GetClassname() != "npc_q2tank" and 
			pMonster.GetClassname() != "npc_q2supertank" and 
			pMonster.GetClassname() != "npc_q2makron" and 
			pMonster.GetClassname() != "npc_q2jorg" )
		{
			if( GetEnemy().IsValid() and GetEnemyEntity().pev.FlagBitSet(FL_CLIENT) )
				m_hOldEnemy = GetEnemy();

			SetEnemy( pMonster );

			//if( !HasFlags(monsterinfo.aiflags, AI_DUCKED) )
				FoundTarget();
		}
		// if they *meant* to shoot us, then shoot back
		else if( pMonster.m_hEnemy.GetEntity() is self )
		{
			if( GetEnemy().IsValid() and GetEnemyEntity().pev.FlagBitSet(FL_CLIENT) )
				m_hOldEnemy = GetEnemy();

			SetEnemy( pMonster );

			//if( !HasFlags(monsterinfo.aiflags, AI_DUCKED) )
				FoundTarget();
		}
		// otherwise get mad at whoever they are mad at (help our buddy) unless it is us!
		else if( pMonster.m_hEnemy.IsValid() and pMonster.m_hEnemy.GetEntity() !is self )
		{
			if( GetEnemy().IsValid() and GetEnemyEntity().pev.FlagBitSet(FL_CLIENT) )
				m_hOldEnemy = GetEnemy();

			self.m_hEnemy = pMonster.m_hEnemy;

			//if( !HasFlags(monsterinfo.aiflags, AI_DUCKED) )
				FoundTarget();
		}
	}

	void SetMass( int iMass )
	{
		CustomKeyvalues@ pCustom = self.GetCustomKeyvalues();
		pCustom.SetKeyvalue( q2npc::KVN_MASS, iMass );
	}
}
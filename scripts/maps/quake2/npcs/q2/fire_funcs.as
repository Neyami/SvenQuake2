namespace q2npc
{

void monster_fire_bullet( CBaseEntity@ pSelf, Vector vecStart, Vector vecDir, float flDamage )
{
	Vector vecSpread = q2npc::DEFAULT_BULLET_SPREAD;

	if( pSelf.GetClassname() == "npc_q2supertank" )
		vecSpread = vecSpread * 3;

	pSelf.FireBullets( 1, vecStart, vecDir, vecSpread, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), pSelf.pev );
}

void monster_fire_shotgun( CBaseEntity@ pSelf, Vector vecStart, Vector vecDir, float flDamage, int iCount = 9 )
{
	for( int i = 0; i < iCount; i++ )
		pSelf.FireBullets( 1, vecStart, vecDir, q2npc::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), pSelf.pev );

	//too loud
	//pSelf.FireBullets( iCount, vecStart, vecDir, q2npc::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), pSelf.pev );
}

void monster_fire_blaster( CBaseMonster@ pSelf, Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHyper = false )
{
	CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, false, pSelf.edict() ); 
	pLaser.pev.velocity = vecDir * flSpeed;
	pLaser.pev.dmg = flDamage;
	pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );

	string sMonsterName;
	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), sMonsterName ); //for death messages
	pLaser.pev.netname = sMonsterName;

	if( bHyper )
		pLaser.pev.weapons = q2::MOD_HYPERBLASTER;
	else
		pLaser.pev.weapons = q2::MOD_BLASTER;

	if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
		pLaser.pev.movetype = MOVETYPE_TOSS;
}

void monster_fire_grenade( CBaseEntity@ pSelf, Vector vecStart, Vector vecAim, float flDamage, float flSpeed, float flRightAdjust = 0.0, float flUpAdjust = 0.0 )
{
	CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "q2grenade", vecStart, g_vecZero, true, pSelf.edict() );
	q2projectiles::q2grenade@ pGrenade = cast<q2projectiles::q2grenade@>(CastToScriptClass(cbeGrenade));

	pGrenade.pev.dmg = flDamage;
	pGrenade.pev.dmgtime = 2.5;
	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), pGrenade.pev.netname ); //for death messages
	pGrenade.pev.velocity = vecAim * flSpeed;
	pGrenade.pev.weapons = 2;
	pGrenade.m_flDamageRadius = 160;

	g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

	Math.MakeVectors( pSelf.pev.angles );

	if( flUpAdjust > 0.0 )
	{
		float flGravityAdjustment = g_EngineFuncs.CVarGetFloat("sv_gravity") / 800.0;
		pGrenade.pev.velocity = pGrenade.pev.velocity + g_Engine.v_up * flUpAdjust * flGravityAdjustment;
	}

	if( flRightAdjust > 0.0 )
		pGrenade.pev.velocity = pGrenade.pev.velocity + g_Engine.v_right * flRightAdjust;
}

void monster_fire_rocket( CBaseMonster@ pSelf, Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHeatSeeking = false, float flHeatTurnRate = 0.075 )
{
	CBaseEntity@ pRocket = g_EntityFuncs.Create( "q2rocket", vecStart, vecDir, true, pSelf.edict() ); 
	pRocket.pev.velocity = vecDir * flSpeed;
	pRocket.pev.dmg = flDamage;
	pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );

	if( pSelf.GetClassname() == "npc_q2supertank" )
		pRocket.pev.scale = 2.0;

	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), pRocket.pev.netname ); //for death messages

	if( bHeatSeeking )
	{
		pRocket.pev.weapons = 1;
		pRocket.pev.speed = flSpeed;
		pRocket.pev.frags = flHeatTurnRate;
	}

	g_EntityFuncs.DispatchSpawn( pRocket.edict() );

	if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
		pRocket.pev.movetype = MOVETYPE_TOSS;
}

void monster_fire_bfg( CBaseMonster@ pSelf, Vector vecStart, Vector vecDir, float flDamage, float flSpeed, float flDamageRadius )
{
	CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfg", vecStart, vecDir, false, pSelf.edict() );
	pBFG.pev.velocity = vecDir * flSpeed;
	pBFG.pev.dmg = flDamage;
	pBFG.pev.dmgtime = flDamageRadius;
	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), pBFG.pev.netname ); //for death messages

	if( q2npc::g_iChaosMode > q2npc::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
		pBFG.pev.movetype = MOVETYPE_TOSS;
}

void monster_fire_railgun( CBaseEntity@ pSelf, Vector vecStart, Vector vecEnd, float flDamage )
{
	TraceResult tr;

	vecEnd = vecStart + vecEnd * 8192;
	Vector railstart = vecStart;
	
	edict_t@ ignore = pSelf.edict();
	
	while( ignore !is null )
	{
		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

		CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
		
		if( pHit.IsMonster() or pHit.IsPlayer() or tr.pHit.vars.solid == SOLID_BBOX or (tr.pHit.vars.ClassNameIs( "func_breakable" ) and tr.pHit.vars.takedamage != DAMAGE_NO) )
			@ignore = tr.pHit;
		else
			@ignore = null;

		g_WeaponFuncs.ClearMultiDamage();

		if( tr.pHit !is pSelf.edict() and pHit.pev.takedamage != DAMAGE_NO )
			pHit.TraceAttack( pSelf.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

		g_WeaponFuncs.ApplyMultiDamage( pSelf.pev, pSelf.pev );

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

} //end of namespace q2npc
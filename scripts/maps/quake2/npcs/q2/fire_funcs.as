namespace q2
{

const int DEFAULT_BULLET_HSPREAD							= 300;
const int DEFAULT_BULLET_VSPREAD							= 500;
const int DEFAULT_SHOTGUN_HSPREAD						= 1000;
const int DEFAULT_SHOTGUN_VSPREAD						= 500;
const int DEFAULT_DEATHMATCH_SHOTGUN_COUNT		= 12;
const int DEFAULT_SHOTGUN_COUNT							= 12;
const int DEFAULT_SSHOTGUN_COUNT						= 20;

enum splash_e
{
	SPLASH_UNKNOWN = 0,
	SPLASH_SPARKS,
	SPLASH_BLUE_WATER,
	SPLASH_BROWN_WATER,
	SPLASH_SLIME,
	SPLASH_LAVA,
	SPLASH_BLOOD
};

//UNUSED ??
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
	pLaser.pev.speed = flSpeed;
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

	if( q2npc::g_iChaosMode > q2::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
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
	pRocket.pev.speed = flSpeed;
	pRocket.pev.velocity = vecDir * flSpeed;
	pRocket.pev.dmg = flDamage;
	pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );

	if( pSelf.GetClassname() == "npc_q2supertank" )
		pRocket.pev.scale = 2.0;

	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), pRocket.pev.netname ); //for death messages

	if( bHeatSeeking )
	{
		pRocket.pev.weapons = 1;
		pRocket.pev.frags = flHeatTurnRate;
	}

	g_EntityFuncs.DispatchSpawn( pRocket.edict() );

	if( q2npc::g_iChaosMode > q2::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
		pRocket.pev.movetype = MOVETYPE_TOSS;
}

void monster_fire_bfg( CBaseMonster@ pSelf, Vector vecStart, Vector vecDir, float flDamage, float flSpeed, float flDamageRadius )
{
	CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfg", vecStart, vecDir, false, pSelf.edict() );
	pBFG.pev.speed = flSpeed;
	pBFG.pev.velocity = vecDir * flSpeed;
	pBFG.pev.dmg = flDamage;
	pBFG.pev.dmgtime = flDamageRadius;
	q2npc::g_dicMonsterNames.get( pSelf.GetClassname(), pBFG.pev.netname ); //for death messages

	if( q2npc::g_iChaosMode > q2::CHAOS_NONE and pSelf.GetClassname() == "npc_q2supertank" and pSelf.pev.sequence == pSelf.LookupSequence("attack_grenade") )
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
			//q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), self, self, aimdir, tr.vecEndPos, tr.vecPlaneNormal, flDamage, kick, 0, q2::MOD_RAILGUN );
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

//from quake 2 
void fire_bullet( CBaseEntity@ self, Vector start, Vector aimdir, float damage, int kick, int hspread, int vspread, int mod )
{
	fire_lead( self, start, aimdir, damage, kick, q2::TE_GUNSHOT, hspread, vspread, mod );
}

void fire_shotgun( CBaseEntity@ self, Vector start, Vector aimdir, float damage, int kick, int hspread, int vspread, int count, int mod )
{
	for( int i = 0; i < count; i++ )
		fire_lead( self, start, aimdir, damage, kick, q2::TE_SHOTGUN, hspread, vspread, mod );
}

//This is an internal support routine used for bullet/pellet based weapons.
void fire_lead( CBaseEntity@ pSelf, Vector vecStart, Vector vecAimdir, float flDamage, float flKick, int te_impact, int hspread, int vspread, int mod )
{
	TraceResult tr;
	Vector vecDir;
	Vector vecForward, vecRight, vecUp;
	Vector vecEnd;
	float flRight;
	float flUp;
	Vector vecWaterStart;
	bool bWater = false;
	int content_mask; //= MASK_SHOT | MASK_WATER;
	//MASK_SHOT = (CONTENTS_SOLID|CONTENTS_MONSTER|CONTENTS_WINDOW|CONTENTS_DEADMONSTER)
	//MASK_WATER = (CONTENTS_WATER|CONTENTS_LAVA|CONTENTS_SLIME)

	g_Utility.TraceLine( pSelf.pev.origin, vecStart, dont_ignore_monsters, pSelf.edict(), tr ); //tr = gi.trace (pSelf->s.origin, NULL, NULL, vecStart, pSelf, MASK_SHOT);
	//CreateBeam( pSelf.pev.origin, vecStart, 2 ); //TEMP
	//g_Game.AlertMessage( at_notice, "CreateBeam FIRST!\n" );
	if( !(tr.flFraction < 1.0) )
	{
		vecDir = Math.VecToAngles( vecAimdir ); //vectoangles (vecAimdir, vecDir);
		g_EngineFuncs.AngleVectors( vecDir, vecForward, vecRight, vecUp );

		flRight = q2::crandom() * hspread;
		flUp = q2::crandom() * vspread;

		vecEnd = vecStart + (vecForward * 8192) + (vecRight * flRight) + (vecUp * flUp);

		//if (gi.pointcontents (vecStart) & MASK_WATER)
		if( g_EngineFuncs.PointContents(vecStart) == CONTENTS_WATER or g_EngineFuncs.PointContents(vecStart) == CONTENTS_LAVA or g_EngineFuncs.PointContents(vecStart) == CONTENTS_SLIME )
		{
			//g_Game.AlertMessage( at_notice, "bWater! PointContents: %1\n", g_EngineFuncs.PointContents(vecStart) );
			bWater = true;
			vecWaterStart = vecStart;
			//content_mask &= ~MASK_WATER;
		}

		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, pSelf.edict(), tr ); //tr = gi.trace (vecStart, NULL, NULL, vecEnd, pSelf, content_mask);
		//CreateBeam( vecStart, vecEnd, 4 ); //TEMP
		//g_Game.AlertMessage( at_notice, "CreateBeam SECOND! flFraction: %1\n", tr.flFraction );

		// see if we hit water
		//if (tr.contents & MASK_WATER)
		//if( tr.fInWater != 0 )
		//if( g_EngineFuncs.PointContents(vecStart) == CONTENTS_WATER or g_EngineFuncs.PointContents(vecStart) == CONTENTS_LAVA or g_EngineFuncs.PointContents(vecStart) == CONTENTS_SLIME )
		if( water_bullet_effects(vecStart, tr.vecEndPos, pSelf) )
		{
			int color;

			//g_Game.AlertMessage( at_notice, "bWater! tr.fInWater != 0\n" );
			bWater = true;
			vecWaterStart = tr.vecEndPos;

			//if (!VectorCompare (vecStart, tr.endpos))
			if( vecStart != tr.vecEndPos )
			{
				// change bullet's course when it enters water
				vecDir = vecEnd - vecStart;
				vecDir = Math.VecToAngles( vecDir );
				g_EngineFuncs.AngleVectors( vecDir, vecForward, vecRight, vecUp );
				flRight = q2::crandom() * hspread * 2;
				flUp = q2::crandom() * vspread * 2;
				vecEnd = vecWaterStart + (vecForward * 8192) + (vecRight * flRight) + (vecUp * flUp);
			}

			// re-trace ignoring water this time
			g_Utility.TraceLine( vecWaterStart, vecEnd, dont_ignore_monsters, pSelf.edict(), tr ); //tr = gi.trace (vecWaterStart, NULL, NULL, vecEnd, pSelf, MASK_SHOT);
			//CreateBeam( vecStart, vecEnd, 8 ); //TEMP
			//g_Game.AlertMessage( at_notice, "CreateBeam THIRD (tr.fInWater != 0)!\n" );
		}
	}

	// send gun puff / flash
	//if( !((tr.surface) and (tr.surface->flags & SURF_SKY)) )
	if( g_EngineFuncs.PointContents(tr.vecEndPos) != CONTENTS_SKY )
	{
		if( tr.flFraction < 1.0 )
		{
			if( tr.pHit.vars.takedamage != DAMAGE_NO )
				q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), pSelf, pSelf, vecAimdir, tr.vecEndPos, tr.vecPlaneNormal, flDamage, flKick, q2::DAMAGE_BULLET, mod );
			else
			{
				SpawnDamage( te_impact, tr.vecEndPos, tr.vecPlaneNormal, 0 );
				/*gi.WriteByte (svc_temp_entity);
				gi.WriteByte (te_impact);
				gi.WritePosition (tr.endpos);
				gi.WriteDir (tr.plane.normal);
				gi.multicast (tr.endpos, MULTICAST_PVS);

				if (pSelf->client)
					PlayerNoise(pSelf, tr.endpos, PNOISE_IMPACT);*/
			}
		}
	}

	// if went through water, determine where the end and make a bubble trail
	if( bWater )
	{
		Vector vecPos;

		vecDir = tr.vecEndPos - vecWaterStart;
		vecDir = vecDir.Normalize();
		vecPos = tr.vecEndPos + vecDir * -2;

		if( g_EngineFuncs.PointContents(vecPos) == CONTENTS_WATER ) //& MASK_WATER
			tr.vecEndPos = vecPos;
		else
		{
			g_Utility.TraceLine( vecPos, vecWaterStart, dont_ignore_monsters, pSelf.edict(), tr ); //tr = gi.trace (vecPos, NULL, NULL, vecWaterStart, tr.ent, MASK_WATER);
			//CreateBeam( vecStart, vecEnd, 16 ); //TEMP
			//g_Game.AlertMessage( at_notice, "CreateBeam FOURTH (bWater)!\n" );
		}

		vecPos = vecWaterStart + tr.vecEndPos;
		vecPos = vecPos * 0.5;

		//g_Utility.BubbleTrail( vecWaterStart, tr.vecEndPos, 8 );
		/*gi.WriteByte (svc_temp_entity);
		gi.WriteByte (TE_BUBBLETRAIL);
		gi.WritePosition (vecWaterStart);
		gi.WritePosition (tr.endpos);
		gi.multicast (vecPos, MULTICAST_PVS);*/
	}
}

//from w00tguy's weapon_custom
bool water_bullet_effects( Vector vecStart, Vector vecEnd, CBaseEntity@ pSelf = null )
{
	// bubble trails
	bool startInWater = g_EngineFuncs.PointContents( vecStart ) == CONTENTS_WATER;
	bool endInWater = g_EngineFuncs.PointContents( vecEnd ) == CONTENTS_WATER;

	if( startInWater or endInWater )
	{
		Vector bubbleStart = vecStart;
		Vector bubbleEnd = vecEnd;
		Vector bubbleDir = bubbleEnd - bubbleStart;
		float waterLevel;

		// find water level relative to trace start
		Vector waterPos = startInWater ? bubbleStart : bubbleEnd;
		waterLevel = g_Utility.WaterLevel( waterPos, waterPos.z, waterPos.z + 1024 );
		waterLevel -= bubbleStart.z;

		// get percentage of distance travelled through water
		float waterDist = 1.0;
		if( !startInWater or !endInWater )
			waterDist -= waterLevel / (bubbleEnd.z - bubbleStart.z);

		if( !endInWater )
			waterDist = 1.0 - waterDist;

		// clip trace to just the water  portion
		if( !startInWater )
			bubbleStart = bubbleEnd - bubbleDir * waterDist;
		else if( !endInWater )
			bubbleEnd = bubbleStart + bubbleDir * waterDist;

		// a shitty attempt at recreating the splash effect
		Vector waterEntry = endInWater ? bubbleStart : bubbleEnd;
		if( !startInWater or !endInWater )
		{
			int color = SPLASH_UNKNOWN;
			string sTexture = g_Utility.TraceTexture( null, vecStart, vecEnd );

			if( IsBlueWater(sTexture) )
				color = SPLASH_BLUE_WATER;
			else if( IsBrownWater(sTexture) )
				color = SPLASH_BROWN_WATER;
			else if( IsSlime(sTexture) )
				color = SPLASH_SLIME;
			else if( IsLava(sTexture) )
				color = SPLASH_LAVA;
			else
			{
				if( pSelf !is null )
				{
					if( pSelf.pev.FlagBitSet(FL_CLIENT) )
					{
						CBasePlayer@ pPlayer = cast<CBasePlayer@>( pSelf );
						if( pPlayer.m_hActiveItem.GetEntity() !is null )
						{
							CBasePlayerWeapon@ pWeapon = cast<CBasePlayerWeapon@>( pPlayer.m_hActiveItem.GetEntity() );
							if( pWeapon !is null )
								pWeapon.FireBullets( 1, waterEntry + Vector(0, 0, 2), Vector(0, 0, -1), g_vecZero, 4, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0, pPlayer.pev );
						}
					}
				}
				//else
					//te_spritespray( waterEntry, Vector(0, 0, 1), "sprites/quake2/water_big.spr", 1, 64, 0 );
			}

			//g_Game.AlertMessage( at_notice, "color: %1\n", color );
			if( color != SPLASH_UNKNOWN )
				SpawnDamage( q2::TE_SPLASH, waterEntry, g_vecZero, color );
		}

		// waterlevel must be relative to the starting point
		if( !startInWater or !endInWater )
			waterLevel = bubbleStart.z > bubbleEnd.z ? 0 : bubbleEnd.z - bubbleStart.z;

		// calculate bubbles needed for an even distribution
		int numBubbles = int( (bubbleEnd - bubbleStart).Length() / 128.0 );
		numBubbles = Math.max(1, Math.min(255, numBubbles));

		//g_Utility.BubbleTrail( bubbleStart, bubbleEnd, 16 );
		te_bubbletrail( bubbleStart, bubbleEnd, "sprites/bubble.spr", waterLevel, numBubbles, 16.0 );

		return true;
	}

	return false;
}
/*
		//SpawnDamage( q2::TE_SPLASH, tr.vecEndPos, tr.vecPlaneNormal, color );
		//gi.WriteByte (svc_temp_entity);
		//gi.WriteByte (TE_SPLASH);
		//gi.WriteByte (8);
		//gi.WritePosition (tr.endpos);
		//gi.WriteDir (tr.plane.normal);
		//gi.WriteByte (color);
		//gi.multicast (tr.endpos, MULTICAST_PVS);
*/

void te_bubbletrail(Vector start, Vector end, string sprite="sprites/bubble.spr", float height=128.0, uint8 count=16, float speed=16.0, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_BUBBLETRAIL);m.WriteCoord(start.x);m.WriteCoord(start.y);m.WriteCoord(start.z);m.WriteCoord(end.x);m.WriteCoord(end.y);m.WriteCoord(end.z);m.WriteCoord(height);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(count);m.WriteCoord(speed);m.End(); }
//void te_spritespray(Vector pos, Vector velocity, string sprite="sprites/bubble.spr", uint8 count=8, uint8 speed=16, uint8 noise=255, NetworkMessageDest msgType=MSG_BROADCAST, edict_t@ dest=null) { NetworkMessage m(msgType, NetworkMessages::SVC_TEMPENTITY, dest);m.WriteByte(TE_SPRITE_SPRAY);m.WriteCoord(pos.x);m.WriteCoord(pos.y);m.WriteCoord(pos.z);m.WriteCoord(velocity.x);m.WriteCoord(velocity.y);m.WriteCoord(velocity.z);m.WriteShort(g_EngineFuncs.ModelIndex(sprite));m.WriteByte(count);m.WriteByte(speed);m.WriteByte(noise);m.End(); }

bool IsBlueWater( string sTexture )
{
	if( containi(sTexture, "water2") )
		return true;

	return false;
}

bool IsBrownWater( string sTexture )
{
	if( containi(sTexture, "brwater") )
		return true;

	return false;
}

bool IsSlime( string sTexture )
{
	return false;
}

bool IsLava( string sTexture )
{
	return false;
}

bool containi( string sSource, string sCompare )
{
	uint uiTemp = sSource.ToLowercase().Find( sCompare.ToLowercase() );

	if( uiTemp != Math.SIZE_MAX )
		return true;

	return false;
}

void CreateBeam( Vector vecStart, Vector vecEnd, int iWidth = 4 )
{
	CBeam@ pBeam = g_EntityFuncs.CreateBeam( "sprites/smoke.spr", iWidth );
	pBeam.SetType( BEAM_POINTS );
	pBeam.SetColor( 0, 255, 0 );
	pBeam.SetStartPos( vecStart );
	pBeam.SetEndPos( vecEnd );
	pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
	pBeam.LiveForTime( 0.5 );
}

} //end of namespace q2
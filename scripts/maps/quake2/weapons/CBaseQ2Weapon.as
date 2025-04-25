class CBaseQ2Weapon : ScriptBasePlayerWeaponEntity
{
	bool m_bRerelease = true;
	float m_iAmmoWarning;

	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/noammo.wav", 1, ATTN_NORM );
		}

		return false;
	}

	void PlayDrawSound()
	{
		if( !m_bRerelease ) return;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/change.wav", VOL_NORM, ATTN_NORM );
	}

	float GetSilencedVolume( float flVolume )
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		if( pCustom.GetKeyvalue(q2items::SILENCER_KVN).GetInteger() >= 1 )
			return flVolume * 0.2;

		return flVolume;
	}

	void CheckSilencer()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		int iSilencerShots = pCustom.GetKeyvalue(q2items::SILENCER_KVN).GetInteger();
		if( iSilencerShots > 0 )
		{
			iSilencerShots--;
			pCustom.SetKeyvalue( q2items::SILENCER_KVN, iSilencerShots );

			UpdateSilencerHUD( m_pPlayer, iSilencerShots );
		}
	}

	void UpdateSilencerHUD( CBasePlayer@ pPlayer, int iSilencerShots )
	{
		HUDNumDisplayParams hudParams;
		q2items::GetHudParams( pPlayer, q2::IT_ITEM_SILENCER, hudParams );

		hudParams.value = iSilencerShots;

		g_PlayerFuncs.HudNumDisplay( pPlayer, hudParams );
	}

	bool CheckQuadDamage()
	{
		if( q2items::IsItemActive(m_pPlayer, q2::IT_ITEM_QUAD) )
		{
			m_pPlayer.pev.renderfx = kRenderFxGlowShell;
			m_pPlayer.pev.rendercolor.z = 255;
			m_pPlayer.pev.renderamt = 1;

			return true;
		}

		return false;
	}

	void G_RemoveAmmo( int iAmount )
	{
		if( G_CheckInfiniteAmmo() )
			return;

		bool bPreWarning = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= m_iAmmoWarning;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - iAmount );

		bool bPostWarning = m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= m_iAmmoWarning;

		if( !bPreWarning and bPostWarning )
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_AUTO, "quake2/weapons/lowammo.wav", VOL_NORM, ATTN_NORM );

		if( self.pszAmmo1() == "q2cells" )
			q2::G_CheckPowerArmor( EHandle(m_pPlayer) );
	}

	bool G_CheckInfiniteAmmo()
	{
		//if (item->flags & IF_NO_INFINITE_AMMO)
			//return false;

		return q2weapons::cvar_InfiniteAmmo.GetInt() == 1/* or (q2::PVP and g_instagib->integer)*/;
	}

	void muzzleflash( Vector vecOrigin, int iR, int iG, int iB, int iRadius = 20 )
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

	void fire_bullet( Vector vecStart, Vector vecDir, float flDamage )
	{
		self.FireBullets( 1, vecStart, vecDir, q2weapons::DEFAULT_BULLET_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );
	}

	void fire_shotgun( Vector vecStart, Vector vecDir, float flDamage, int iCount )
	{
		for( int i = 0; i < iCount; i++ )
			self.FireBullets( 1, vecStart, vecDir, q2weapons::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );

		//too loud
		//self.FireBullets( iCount, vecStart, vecDir, q2npc::DEFAULT_SHOTGUN_SPREAD, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 1, int(flDamage), m_pPlayer.pev );
	}

	void fire_blaster( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, bool bHyper = false )
	{
		CBaseEntity@ pLaser = g_EntityFuncs.Create( "q2laser", vecStart, vecDir, false, m_pPlayer.edict() ); 
		pLaser.pev.velocity = vecDir * flSpeed;
		pLaser.pev.dmg = flDamage;
		pLaser.pev.angles = Math.VecToAngles( vecDir.Normalize() );

		if( bHyper )
			pLaser.pev.weapons = 1;
	}

	void fire_grenade( Vector vecStart, Vector vecAim, float flDamage, float flSpeed, float flDamageRadius )
	{
		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "q2grenade", vecStart, g_vecZero, true, m_pPlayer.edict() );
		q2projectiles::q2grenade@ pGrenade = cast<q2projectiles::q2grenade@>(CastToScriptClass(cbeGrenade));

		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.velocity = vecAim * flSpeed;
		pGrenade.pev.dmgtime = 2.5;
		pGrenade.m_flDamageRadius = flDamageRadius;

		g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );

		Math.MakeVectors( vecAim );
		pGrenade.pev.velocity = pGrenade.pev.velocity + g_Engine.v_up * (200 + q2::crandom_open() * 10.0) + g_Engine.v_right * (q2::crandom_open() * 10.0);
	}

	void fire_grenade2( Vector vecStart, Vector vecVelocity, float flDamage, float flTimer, float flDamageRadius )
	{
		CBaseEntity@ cbeGrenade = g_EntityFuncs.Create( "q2grenade", vecStart, g_vecZero, true, m_pPlayer.edict() );
		q2projectiles::q2grenade@ pGrenade = cast<q2projectiles::q2grenade@>(CastToScriptClass(cbeGrenade));

		pGrenade.pev.dmg = flDamage;
		pGrenade.pev.velocity = vecVelocity;
		pGrenade.pev.weapons = 1;
		pGrenade.pev.dmgtime = flTimer;
		pGrenade.m_flDamageRadius = flDamageRadius;

		g_EntityFuncs.DispatchSpawn( pGrenade.self.edict() );
	}

	void fire_rocket( Vector vecStart, Vector vecDir, float flDamage, float flSpeed )
	{
		CBaseEntity@ pRocket = g_EntityFuncs.Create( "q2rocket", vecStart, vecDir, false, m_pPlayer.edict() ); 
		pRocket.pev.velocity = vecDir * flSpeed;
		pRocket.pev.dmg = flDamage;
		pRocket.pev.angles = Math.VecToAngles( vecDir.Normalize() );
		pRocket.pev.scale = m_pPlayer.pev.scale;
	}

	void fire_railgun( Vector vecStart, Vector vecAim, float flDamage )
	{
		TraceResult tr;

		Vector vecEnd = vecStart + vecAim * 8192.0;
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

			if( tr.pHit !is self.edict() and pHit.pev.takedamage != DAMAGE_NO )
			{
				g_WeaponFuncs.ClearMultiDamage();
				pHit.TraceAttack( m_pPlayer.pev, flDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 
				g_WeaponFuncs.ApplyMultiDamage( self.pev, m_pPlayer.pev );
			}

			vecStart = tr.vecEndPos;
		}

		CreateRailbeam( railstart, tr.vecEndPos );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null or pHit.IsBSPModel() == true )
			{
				g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_SNIPER );
				g_Utility.DecalTrace( tr, DECAL_BIGSHOT4 + Math.RandomLong(0, 1) );

				NetworkMessage railimpact( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
					railimpact.WriteByte( TE_DLIGHT );
					railimpact.WriteCoord( tr.vecEndPos.x );
					railimpact.WriteCoord( tr.vecEndPos.y );
					railimpact.WriteCoord( tr.vecEndPos.z );
					railimpact.WriteByte( 8 );//radius
					railimpact.WriteByte( 155 ); //rgb
					railimpact.WriteByte( 255 );
					railimpact.WriteByte( 255 );
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

	void fire_bfg( Vector vecStart, Vector vecDir, float flDamage, float flSpeed, float flDamageRadius )
	{
		CBaseEntity@ pBFG = g_EntityFuncs.Create( "q2bfg", vecStart, vecDir, false, m_pPlayer.edict() );
		pBFG.pev.velocity = vecDir * flSpeed;
		pBFG.pev.dmg = flDamage;
		pBFG.pev.dmgtime = flDamageRadius;
	}

	//CBaseEntity@ CheckTraceHullAttack( float flDist, float flDamage, int iDmgType )
	//bool fire_player_melee( const Vector &in vecStart, const Vector &in vecEnd, float flDist, float flDamage, int kick/*, mod_t mod*/ )
	bool fire_player_melee( const Vector &in vecStart, float flDist, float flDamage, int kick )
	{
		if( flDamage <= 0 ) return false;

		TraceResult tr;

		Math.MakeVectors( m_pPlayer.pev.angles );

		Vector vecEnd = vecStart + (g_Engine.v_forward * flDist);

		g_Utility.TraceHull( vecStart, vecEnd, dont_ignore_monsters, head_hull, self.edict(), tr );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

			//pHit.TakeDamage( self.pev, self.pev, flDamage, DMG_SLASH );
			Vector closest_point_to_check = q2::closest_point_to_box( vecStart, pHit.pev.origin + pHit.pev.mins, pHit.pev.origin + pHit.pev.maxs );
			q2::T_Damage( pHit, self, self, g_Engine.v_forward, closest_point_to_check, -g_Engine.v_forward, flDamage, kick / 2, 0 ); //DAMAGE_DESTROY_ARMOR | DAMAGE_NO_KNOCKBACK

			return true;
		}

		return false;
	}
}
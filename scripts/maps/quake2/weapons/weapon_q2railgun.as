const int	Q2_RG_AMMO_DEFAULT	= 25;
const int	Q2_RG_AMMO_MAX		= 100;
const float Q2_RG_DELAY			= 1.6f;
const int	Q2_RG_DISTANCE		= 8192;

enum q2_RGAnims
{
	RG_IDLE1 = 0,
	RG_IDLE2,
	RG_FIRE,
	RG_DRAW,
	RG_HOLSTER
};

class weapon_q2railgun : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	CBeam@ m_pRailBeam, m_pRailBeam2;
	Vector railStart;
	TraceResult railtr;
	int railbr;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_railgunhd.mdl" );
		self.m_iDefaultAmmo = Q2_RG_AMMO_DEFAULT;
		BaseClass.Spawn();
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.scale = 2.0f;

		@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );

		CommonSpawn();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake2/v_railgunhd.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_railgunhd.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_railgunhd.mdl" );

		g_Game.PrecacheModel( "sprites/laserbeam.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rg_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rg_humloop.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rg_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rg_humloop.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2rg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/rg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_RG_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 6;
		info.iPosition = 12;
		info.iFlags = 0;
		info.iWeight = 1;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage q2rg( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2rg.WriteLong( self.m_iId );
		q2rg.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;
		@m_pRailBeam = null;
		@m_pRailBeam2 = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_railgunhd.mdl"), self.GetP_Model("models/quake2/p_railgunhd.mdl"), RG_DRAW, "sniperscope" );
			float deployTime = 0.74f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/rg_humloop.wav", 1, ATTN_NORM );

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/rg_humloop.wav" );

		BaseClass.Holster( skipLocal );
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

	void PrimaryAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( ammo <= 0 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;
			self.PlayEmptySound();
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_RG_DELAY;
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/rg_fire.wav", 1, ATTN_NORM );
		self.SendWeaponAnim( RG_FIRE, 0, 0 );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		int iDamage = 100;
		float flRecoil = Math.RandomFloat( -4.0f, -0.2f );
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			flRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		q2_FireRailgun( iDamage );

		m_pPlayer.pev.punchangle.x = flRecoil;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 1.5f, 2.0f );
	}

	void q2_FireRailgun( int iDamage )
	{
		TraceResult tr;
		Vector vecStart = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 12 + g_Engine.v_right * 3 + g_Engine.v_up * -3.5f;
		Math.MakeVectors( m_pPlayer.pev.v_angle );
		Vector vecEnd = vecStart + g_Engine.v_forward * Q2_RG_DISTANCE;
		railStart = vecStart;
		
		edict_t@ ignore = m_pPlayer.edict();
		
		while( ignore !is null )
		{
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, ignore, tr );

			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit.IsMonster() || pHit.IsPlayer() || tr.pHit.vars.solid == SOLID_BBOX || (tr.pHit.vars.ClassNameIs( "func_breakable" ) && tr.pHit.vars.takedamage != DAMAGE_NO) )
				@ignore = tr.pHit;
			else
				@ignore = null;

			g_WeaponFuncs.ClearMultiDamage();

			if( tr.pHit !is m_pPlayer.edict() && pHit.pev.takedamage != DAMAGE_NO )
				pHit.TraceAttack( m_pPlayer.pev, iDamage, vecEnd, tr, DMG_ENERGYBEAM | DMG_LAUNCH ); 

			g_WeaponFuncs.ApplyMultiDamage( m_pPlayer.pev, m_pPlayer.pev );

			vecStart = tr.vecEndPos;
		}

		railtr = tr;
		UpdateRailEffect();

		g_Scheduler.SetTimeout( @this, "DestroyRailEffect", 1.2f );

		if( tr.pHit !is null )
		{
			CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
			
			if( pHit is null || pHit.IsBSPModel() == true )
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

	void RailEffect()
	{
		DestroyRailEffect();

		@m_pRailBeam = @g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 30 );
		m_pRailBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
		//@m_pRailBeam.pev.owner = @m_pPlayer.edict();
		m_pRailBeam.SetEndAttachment( 1 );
		m_pRailBeam.SetScrollRate( 50 );
		m_pRailBeam.SetBrightness( 255 );
		m_pRailBeam.SetColor( 255, 255, 255 );
		m_pRailBeam.SetStartPos( railtr.vecEndPos );
		m_pRailBeam.SetEndPos( railStart );

		@m_pRailBeam2 = @g_EntityFuncs.CreateBeam( "sprites/laserbeam.spr", 5 );
		m_pRailBeam2.SetFlags( BEAM_FSINE );
		m_pRailBeam2.pev.spawnflags |= SF_BEAM_TEMPORARY;
		//@m_pRailBeam2.pev.owner = @m_pPlayer.edict();
		m_pRailBeam2.SetEndAttachment( 1 );
		m_pRailBeam2.SetScrollRate( 50 );
		m_pRailBeam2.SetNoise( 20 );
		m_pRailBeam2.SetBrightness( 255 );
		m_pRailBeam2.SetColor( 100, 100, 255 );
		m_pRailBeam2.SetStartPos( railtr.vecEndPos );
		m_pRailBeam2.SetEndPos( railStart );

		railbr = 255;
	}

	void UpdateRailEffect()
	{
		if( m_pRailBeam is null ) RailEffect();

		m_pRailBeam.SetBrightness( railbr );
		m_pRailBeam2.SetBrightness( railbr );

		if( railbr > 0 )
			railbr -= 2;
	}

	void DestroyRailEffect()
	{
		if( m_pRailBeam is null ) return;

		g_EntityFuncs.Remove( m_pRailBeam );
		g_EntityFuncs.Remove( m_pRailBeam2 );
		@m_pRailBeam = null;
		@m_pRailBeam2 = null;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		int anim;
		switch( Math.RandomLong(0, 1) )
		{
			case 0: anim = RG_IDLE1;
			case 1: anim = RG_IDLE2;
		}
			
		self.SendWeaponAnim( anim );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 2, 4 );
	}

	void ItemPreFrame()
	{
		if( m_pRailBeam !is null ) UpdateRailEffect();
		
		BaseClass.ItemPreFrame();
	}

	void RotateThink()
	{
		self.pev.angles.y += 1;
	}

	void UpdateOnRemove()
	{
		if( m_pRotFunc !is null ) g_Scheduler.RemoveTimer( m_pRotFunc );

		BaseClass.UpdateOnRemove();
	}
}

void q2_RegisterWeapon_RAILGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2railgun", "weapon_q2rg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2rg", "quake2/weapons", "slugs" );
}
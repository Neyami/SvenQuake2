enum q2_BlasterAnims
{
	BLASTER_IDLE1 = 0,
	BLASTER_IDLE2,
	BLASTER_FIRE,
	BLASTER_DRAW,
	BLASTER_HOLSTER
};

class weapon_q2blaster : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_blasterhd.mdl" );
		BaseClass.Spawn();
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.scale = 2.0f;

		@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );

		self.m_iClip = -1;
		
		self.pev.angles.x = -75;
		CommonSpawn();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake2/v_blasterhd.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_blasterhd.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_blasterhd.mdl" );
		g_Game.PrecacheModel( "models/quake2/laser.mdl" );

		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/blaster_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/laser_fly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/laser_hit.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/blaster_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/laser_fly.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/laser_hit.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2b.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/blaster_icon.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = -1;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 0;
		info.iPosition = 10;
		info.iFlags = 0;
		info.iWeight = 5;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage q2b( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2b.WriteLong( self.m_iId );
		q2b.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_blasterhd.mdl"), self.GetP_Model("models/quake2/p_blasterhd.mdl"), BLASTER_DRAW, "onehanded" );
			float deployTime = 0.5f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		self.SendWeaponAnim( BLASTER_FIRE, 0, 0 );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/blaster_fire.wav", 1, ATTN_NORM );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition() + g_Engine.v_right * 6 + g_Engine.v_up * -8;
		Vector vecAiming = g_Engine.v_forward;
		
		int iDamage = 15;
		float iRecoil = -1.0f;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			iRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		auto @pBolt = q2_ShootCustomProjectile( "projectile_q2laser", "models/quake2/laser.mdl", vecSrc, vecAiming * 1000, m_pPlayer.pev.v_angle, m_pPlayer );
		pBolt.pev.dmg = iDamage;

		m_pPlayer.pev.punchangle.x = iRecoil;
		self.m_flNextPrimaryAttack = g_Engine.time + 0.5f;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 6, 9 );
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		int anim;

		switch( Math.RandomLong(0, 1) )
		{
			case 0: anim = BLASTER_IDLE1;
			case 1: anim = BLASTER_IDLE2;
		}
			
		self.SendWeaponAnim( anim );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5, 8 );
	}

	void RotateThink()
	{
		self.pev.angles.y += 1;
	}

	void UpdateOnRemove()
	{
		if (m_pRotFunc !is null)
			g_Scheduler.RemoveTimer( m_pRotFunc );
		BaseClass.UpdateOnRemove();
	}
}

void q2_RegisterWeapon_BLASTER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2blaster", "weapon_q2b" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2b", "quake2/weapons" );
}
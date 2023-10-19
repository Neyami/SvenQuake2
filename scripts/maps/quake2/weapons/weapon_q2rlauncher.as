const int	Q2_RL_AMMO_DEFAULT	= 10;
const int	Q2_RL_AMMO_MAX		= 50;
const float Q2_RL_DELAY			= 1.0f;

enum q2_RocketLauncherAnims
{
	RLAUNCHER_IDLE1 = 0,
	RLAUNCHER_IDLE2,
	RLAUNCHER_FIRE,
	RLAUNCHER_DRAW,
	RLAUNCHER_HOLSTER
};

class weapon_q2rlauncher : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	private float m_fLoadDelay;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_rlauncher.mdl" );
		self.m_iDefaultAmmo = Q2_RL_AMMO_DEFAULT;
		BaseClass.Spawn();
		self.FallInit();
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.scale = 2.0f;

		@m_pRotFunc = @g_Scheduler.SetInterval(this, "RotateThink", 0.01, g_Scheduler.REPEAT_INFINITE_TIMES);

		CommonSpawn();
	}

	void Precache()
	{
		self.PrecacheCustomModels();
		g_Game.PrecacheModel( "models/quake2/v_rlauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_rlauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_rlauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/rockethd.mdl" );
		for( uint i = 0; i < pExplosionSprites.length(); i++ )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		g_Game.PrecacheModel( "sprites/blueflare1.spr" );
		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rl_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rl_load.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rocket_fly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/rocket_explode.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rl_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rl_load.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rocket_fly.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/rocket_explode.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2rl.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/rl_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_RL_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 6;
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

		NetworkMessage q2rl( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2rl.WriteLong( self.m_iId );
		q2rl.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_rlauncher.mdl"), self.GetP_Model("models/quake2/p_rlauncher.mdl"), RLAUNCHER_DRAW, "shotgun" );
			float deployTime = 0.91f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
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

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_RL_DELAY;

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		self.SendWeaponAnim( RLAUNCHER_FIRE );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/rl_fire.wav", 1, ATTN_NORM );

		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		int iDamage = 120;
		float flRecoil = -0.5f;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			flRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_right * 3 + g_Engine.v_up * -10;
		Vector vecVelocity = g_Engine.v_forward * 650;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		auto @pRocket = q2_ShootCustomProjectile( "projectile_q2rocket", "models/quake2/rockethd.mdl", vecSrc, vecVelocity, vecAngles, m_pPlayer );
		pRocket.pev.dmg = iDamage;

		m_fLoadDelay = g_Engine.time + 0.1f;

		m_pPlayer.pev.punchangle.x = flRecoil;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 0.4f, 2.0f );
	}
	
	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		int iAnim;
		float flIdleDelay;

		switch( Math.RandomLong(1, 2) )
		{
			case 1:
			{
				iAnim = RLAUNCHER_IDLE1;
				flIdleDelay = Math.RandomFloat( 4.0f, 5.5f );
				break;
			}

			case 2:
			{
				iAnim = RLAUNCHER_IDLE2;
				flIdleDelay = Math.RandomFloat( 5.0f, 6.5f );
				break;
			}
		}

		self.SendWeaponAnim( iAnim );
		self.m_flTimeWeaponIdle = g_Engine.time + flIdleDelay;
	}

	void ItemPostFrame()
	{
		if( m_fLoadDelay > 0 && g_Engine.time > m_fLoadDelay )
		{
			m_fLoadDelay = 0;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/rl_load.wav", 1, ATTN_NORM );
		}

		BaseClass.ItemPostFrame();
	}

	void RotateThink()
	{
		self.pev.angles.y += 1;
	}

	void UpdateOnRemove()
	{
		if( m_pRotFunc !is null )
			g_Scheduler.RemoveTimer( m_pRotFunc );
		BaseClass.UpdateOnRemove();
	}
}

void q2_RegisterWeapon_ROCKETLAUNCHER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2rlauncher", "weapon_q2rl" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2rl", "quake2/weapons", "q2rockets" );
}
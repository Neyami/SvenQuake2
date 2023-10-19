const int	Q2_GL_AMMO_DEFAULT	= 10;
const int	Q2_GL_AMMO_MAX		= 50;
const float Q2_GL_DELAY			= 1.1;

enum q2_GrenadeLauncherAnims
{
	GLAUNCHER_IDLE = 0,
	GLAUNCHER_IDLE_EMPTY,
	GLAUNCHER_FIRE,
	GLAUNCHER_FIRE_EMPTY,
	GLAUNCHER_DRAW,
	GLAUNCHER_DRAW_EMPTY,
	GLAUNCHER_HOLSTER
};

class weapon_q2glauncher : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	private float m_fLoadDelay;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_glauncher.mdl" );
		self.m_iDefaultAmmo = Q2_GL_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_glauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_glauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_glauncher.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_grenade1.mdl" );
		for( uint i = 0; i < pExplosionSprites.length(); i++ )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/gl_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/gl_load.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_bounce1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_bounce2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_explode.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/gl_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/gl_load.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/grenade_bounce1.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/grenade_bounce2.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/grenade_explode.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2gl.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/gl_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_GL_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 5;
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

		NetworkMessage q2gl( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2gl.WriteLong( self.m_iId );
		q2gl.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_glauncher.mdl"), self.GetP_Model("models/quake2/p_glauncher.mdl"), m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 ? GLAUNCHER_DRAW_EMPTY : GLAUNCHER_DRAW, "shotgun" );
			float deployTime = 0.54f;
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

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_GL_DELAY;

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/gl_fire.wav", 1, ATTN_NORM );

		int iDamage = 120;
		float flRecoil = -2.5f;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			flRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		Vector vecSrc = m_pPlayer.GetGunPosition() + g_Engine.v_right * 5 + g_Engine.v_up * -5;
		Vector vecVelocity = g_Engine.v_forward * 1500;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		auto @pGrenade = q2_ShootCustomProjectile( "projectile_q2grenade1", "models/quake2/w_grenade1.mdl", vecSrc, vecVelocity, vecAngles, m_pPlayer );
		pGrenade.pev.dmg = iDamage;

		self.SendWeaponAnim( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 ? GLAUNCHER_FIRE_EMPTY : GLAUNCHER_FIRE );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		m_fLoadDelay = g_Engine.time + 0.1f;

		m_pPlayer.pev.punchangle.x = flRecoil;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomLong( 3,5 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 1 ? GLAUNCHER_IDLE_EMPTY : GLAUNCHER_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 10, 15 );
	}

	void ItemPostFrame()
	{
		if( m_fLoadDelay > 0 && g_Engine.time > m_fLoadDelay )
		{
			m_fLoadDelay = 0;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/gl_load.wav", 1, ATTN_NORM );
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

void q2_RegisterWeapon_GRENADELAUNCHER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2glauncher", "weapon_q2gl" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2gl", "quake2/weapons", "grenades" );
}

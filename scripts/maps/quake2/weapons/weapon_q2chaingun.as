const Vector Q2_CG_CONE( 0.07f, 0.07f, 0 );

const int	Q2_CG_AMMO_DEFAULT	= 50;
const int	Q2_CG_AMMO_MAX		= 200;
const float PRIMARY_DELAY		= 0.1f;
const float SECONDARY_DELAY		= 0.03f;

enum q2_ChaingunAnims
{
	CHAINGUN_IDLE = 0,
	CHAINGUN_FIRE,
	CHAINGUN_DRAW,
	CHAINGUN_HOLSTER
};

class weapon_q2chaingun : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	array<string> pFireSounds = 
	{
		"quake2/weapons/mg_fire1.wav",
		"quake2/weapons/mg_fire2.wav",
		"quake2/weapons/mg_fire3.wav",
		"quake2/weapons/mg_fire4.wav",
		"quake2/weapons/mg_fire5.wav"
	};

	CScheduledFunction@ m_pRotFunc;
	int m_iShell;
	float m_fShoot, m_fFireDelay, m_fStopAttack, m_fAnimDelay;
	bool m_bInAttack, m_bInFastAttack;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_chaingun.mdl" );
		self.m_iDefaultAmmo = Q2_CG_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_chaingun.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_chaingun.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_chaingun.mdl" );
		
		m_iShell = g_Game.PrecacheModel( "models/quake2/w_shell_mg.mdl" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/cg_spinup.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/cg_spinloop.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/cg_spindown.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );
		for( uint i = 0; i < pFireSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pFireSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pFireSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pFireSounds[i] );

		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/cg_spinup.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/cg_spinloop.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/cg_spindown.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2cg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/cg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_CG_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 4;
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

		NetworkMessage q2cg( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2cg.WriteLong( self.m_iId );
		q2cg.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			m_fShoot = 0;
			m_fFireDelay = 0;
			m_bInAttack = false;
			m_fAnimDelay = g_Engine.time;

			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_chaingun.mdl"), self.GetP_Model("models/quake2/p_chaingun.mdl"), CHAINGUN_DRAW, "egon" );
			float deployTime = 0.7f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		m_fShoot = 0;
		m_bInAttack = false;
		m_bInFastAttack = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/cg_spinloop.wav" );
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

		if( !m_bInAttack )
		{
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/cg_spinloop.wav", 1, ATTN_NORM );
			
			if( m_fShoot <= 0 )
				StartAttack();
		}
		
		m_bInAttack = true;
		
		m_fStopAttack = g_Engine.time + 0.9f;//this affects how many bullets are fired when only clicking once, and after releasing attack.
		
		if( m_fShoot > 0 ) return;
		
		ActuallyAttack();
		
		if( m_fFireDelay > 0 )
		{
			if( g_Engine.time < m_fFireDelay ) return;
			m_bInFastAttack = true;
			self.m_flNextPrimaryAttack = g_Engine.time + SECONDARY_DELAY;
			self.m_flFrameRate = 1.5f;
		}
	}

	void StartAttack()
	{
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/cg_spinup.wav", 1, ATTN_NORM );
		
		if( m_fShoot > 0 || m_fStopAttack > 0 ) return;
		m_fFireDelay = g_Engine.time + 0.6f;
	}

	void EndAttack()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/cg_spinloop.wav" );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/cg_spindown.wav", 1, ATTN_NORM );
	}

	void ActuallyAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		self.m_flNextPrimaryAttack = g_Engine.time + PRIMARY_DELAY;
	//self:Light()
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		int iDamage = 15;
		float flRecoil = 0.5f;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			flRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		m_pPlayer.pev.punchangle = Vector( -0.1 * flRecoil, Math.RandomFloat(0.5,-0.5) * flRecoil, Math.RandomFloat(0.2,-0.2) * flRecoil );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pFireSounds[Math.RandomLong(0,4)], 1, ATTN_NORM );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Q2_CG_CONE, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage );

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector vecShellVelocity = m_pPlayer.pev.velocity 
					+ g_Engine.v_right * Math.RandomFloat( 50, 70 ) 
					+ g_Engine.v_up * Math.RandomFloat( 100, 150 ) 
					+ g_Engine.v_forward * 25;
    
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -42 + g_Engine.v_forward * 11 + g_Engine.v_right * 5, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		q2_CreatePelletDecals( vecSrc, vecAiming, Q2_MG_CONE, 1, EHandle(m_pPlayer) );

		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 2, 4 );

		if( m_fAnimDelay <= g_Engine.time )
		{
			float delay = 0.05;//0.2 in SP
			self.SendWeaponAnim( CHAINGUN_FIRE );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );			
			
			m_fAnimDelay = g_Engine.time + delay;
		}
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( CHAINGUN_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 2, 4 );
	}

	void ItemPostFrame()
	{
		if( m_fShoot > 0 && g_Engine.time > m_fShoot )
		{
			if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 ) return;

			ActuallyAttack();

			if( m_bInFastAttack )
				m_fShoot = g_Engine.time + SECONDARY_DELAY;
			else
				m_fShoot = g_Engine.time + PRIMARY_DELAY;
		}

		if( m_fStopAttack > 0 && g_Engine.time > m_fStopAttack || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 && m_bInAttack )
		{
			m_fStopAttack = 0;
			m_fShoot = 0;
			m_bInFastAttack = false;
			self.m_flNextPrimaryAttack = g_Engine.time + 0.6f;
			m_fFireDelay = g_Engine.time + 1.2f;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/cg_spinloop.wav" );
			m_bInAttack = false;
			EndAttack();
		}

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
		{
			if( (m_pPlayer.m_afButtonLast & IN_ATTACK == 0) )
			{
				if( m_bInAttack )
					m_fShoot = self.m_flNextPrimaryAttack;
			}
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

void q2_RegisterWeapon_CHAINGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2chaingun", "weapon_q2cg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2cg", "quake2/weapons", "bullets" );
}
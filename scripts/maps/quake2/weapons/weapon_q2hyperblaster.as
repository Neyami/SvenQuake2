const int	Q2_HB_AMMO_DEFAULT	= 50;
const int	Q2_HB_AMMO_MAX		= 200;
const float Q2_HB_DELAY1		= 0.1f;
const float Q2_HB_DELAY2		= 1.1f;

enum q2_HyperBlasterAnims
{
	HYPERBLASTER_IDLE = 0,
	HYPERBLASTER_FIRE,
	HYPERBLASTER_DRAW,
	HYPERBLASTER_HOLSTER
};

class weapon_q2hyperblaster : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	private bool m_bInAttack;
	private float m_fStopAttack;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_hyperblaster.mdl" );
		self.m_iDefaultAmmo = Q2_HB_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_hyperblaster.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_hyperblaster.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_hyperblaster.mdl" );
		g_Game.PrecacheModel( "models/quake2/laser.mdl" );

		g_Game.PrecacheModel( "sprites/blueflare1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hb_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hb_spinloop.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hb_spindown.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hb_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hb_spinloop.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hb_spindown.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2hb.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/hb_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_HB_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 6;
		info.iPosition = 11;
		info.iFlags = 0;
		info.iWeight = 5;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage q2hb( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2hb.WriteLong( self.m_iId );
		q2hb.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_hyperblaster.mdl"), self.GetP_Model("models/quake2/p_hyperblaster.mdl"), HYPERBLASTER_DRAW, "m16" );
			float deployTime = 0.8f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	void Holster()
	{	
		m_bInAttack = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/hb_spinloop.wav" );
		BaseClass.Holster( 0 );
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
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/hb_spinloop.wav", 0.8f, ATTN_NORM );
		}

		m_bInAttack = true;
		m_fStopAttack = 0;
		
		self.m_flNextPrimaryAttack = g_Engine.time + Q2_HB_DELAY1;

		self.SendWeaponAnim( HYPERBLASTER_FIRE );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hb_fire.wav", 1, ATTN_NORM );

		int iDamage = 15;
		float flRecoil = -0.5f;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			flRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		m_pPlayer.pev.punchangle.x = flRecoil;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

		Vector vecSrc	 = m_pPlayer.GetGunPosition() + g_Engine.v_right * Math.RandomLong(4,8) + g_Engine.v_up * Math.RandomLong(-7,-10);
		Vector vecVelocity = g_Engine.v_forward * 800;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		auto @pBolt = q2_ShootCustomProjectile( "projectile_q2hlaser", "models/quake2/laser.mdl", vecSrc, vecVelocity, vecAngles, m_pPlayer );
		pBolt.pev.dmg = iDamage;

		self.m_flTimeWeaponIdle = g_Engine.time + 1.8f;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( HYPERBLASTER_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5, 8 );
	}

	void ItemPostFrame()
	{
		if( m_fStopAttack > 0 && g_Engine.time > m_fStopAttack || m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) == 0 && m_bInAttack )
		{
			m_fStopAttack = 0;
			self.m_flNextPrimaryAttack = g_Engine.time + Q2_HB_DELAY2;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/hb_spinloop.wav" );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hb_spindown.wav", 1, ATTN_NORM );
			m_bInAttack = false;
			
		}
		
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
		{
			if( (m_pPlayer.m_afButtonReleased & IN_ATTACK == 1) )
			{
				if( m_bInAttack )
					m_fStopAttack = g_Engine.time + 0.25f;
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
		if (m_pRotFunc !is null)
			g_Scheduler.RemoveTimer( m_pRotFunc );
		BaseClass.UpdateOnRemove();
	}
}

void q2_RegisterWeapon_HYPERBLASTER()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2hyperblaster", "weapon_q2hb" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2hb", "quake2/weapons", "cells" );
}
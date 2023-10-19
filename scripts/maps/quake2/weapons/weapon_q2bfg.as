const int Q2_BFG_AMMO_DEFAULT			= 50;
const int Q2_BFG_AMMO_MAX				= 300;
const int Q2_BFG_WEIGHT					= 20;
const float Q2_BFG_DELAY				= 2.5f;
const int Q2_BFG_AMMO_PER_SHOT			= 50;

const int Q2_BFG_DAMAGE					= 200;
const int Q2_BFG_DAMAGE_RADIUS			= 256;
const int Q2_BFG_DAMAGE_LASER			= 10;
const int Q2_BFG_PROJECTILE_SPEED		= 400;
const int Q2_PROJECTILE_LASER_RANGE		= Q2_BFG_DAMAGE_RADIUS;
const float Q2_PROJECTILE_LASER_TICK	= 0.1f;
const Vector BFGBLAST_LASER_COLOR		= Vector( 173,255,47 );
const int BFGBLAST_LASER_BRIGHT			= 32;

enum q2bfg_e
{
	BFG_IDLE = 0,
	BFG_FIRE,
	BFG_DRAW,
	BFG_HOLSTER
};

class weapon_q2bfg : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	float m_fBFG;
	
	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_bfg.mdl" );
		self.m_iDefaultAmmo = Q2_BFG_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_bfg.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_bfg.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_bfg.mdl" );
		g_Game.PrecacheModel( "sprites/quake2/bfg_sprite.spr" );
		g_Game.PrecacheModel( "sprites/quake2/bfg_explosion.spr" );
		g_Game.PrecacheModel( "sprites/quake2/bfg_beam.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg_humloop.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg_fly.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/bfg_explode.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );		

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/bfg_fire.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/bfg_humloop.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/bfg_fly.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/bfg_explode.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2bfg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/bfg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 	= Q2_BFG_AMMO_MAX;
		info.iMaxAmmo2 	= -1;
		info.iMaxClip 	= WEAPON_NOCLIP;
		info.iSlot 		= 6;
		info.iPosition 	= 13;
		info.iFlags 	= 0;
		info.iWeight 	= Q2_BFG_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage q2bfg( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2bfg.WriteLong( self.m_iId );
		q2bfg.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_bfg.mdl"), self.GetP_Model("models/quake2/p_bfg.mdl"), BFG_DRAW, "shotgun" );
			float deployTime = 0.9f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/bfg_humloop.wav", 1, ATTN_NORM );

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		m_fBFG = 0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/weapons/bfg_humloop.wav" );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/bfg_fire.wav" );

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

		if( ammo < Q2_BFG_AMMO_PER_SHOT )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;
			self.PlayEmptySound();
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			return;
		}

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_BFG_DELAY;

		self.SendWeaponAnim( BFG_FIRE );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/bfg_fire.wav", 1, ATTN_NORM );

		m_fBFG = g_Engine.time + 0.8f;

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomLong( 5,8 );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( BFG_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 5, 8 );
	}

	void ItemPostFrame()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );

		if( m_fBFG > 0 && g_Engine.time > m_fBFG )
		{
			m_fBFG = 0;
			ammo -= Q2_BFG_AMMO_PER_SHOT;
			m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );

			int iDamage = Q2_BFG_DAMAGE;
			Vector vecRecoil( -30, Math.RandomFloat(-1,1) * 10, 0 );
			Vector recoil;

			if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
			{
				iDamage *= 4;
				recoil = vecRecoil * 2;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
			}

			m_pPlayer.pev.punchangle = recoil;
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			Vector vecSrc	 = m_pPlayer.GetGunPosition() + g_Engine.v_right * 3 + g_Engine.v_up * -10;
			Vector vecVelocity = g_Engine.v_forward * Q2_BFG_PROJECTILE_SPEED;
			Vector vecAngles = m_pPlayer.pev.v_angle;

			auto @pBFG = q2_ShootCustomProjectile( "projectile_q2bfg", "sprites/quake2/bfg_sprite.spr", vecSrc, vecVelocity, vecAngles, m_pPlayer );
			pBFG.pev.dmg = iDamage;
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

void q2_RegisterWeapon_BFG()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2bfg", "weapon_q2bfg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2bfg", "quake2/weapons", "cells" );
}
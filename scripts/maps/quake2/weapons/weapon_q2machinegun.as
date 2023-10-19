const Vector Q2_MG_CONE( 0.05f, 0.05f, 0 );

const int	Q2_MG_AMMO_DEFAULT	= 50;
const int	Q2_MG_AMMO_MAX		= 200;

enum q2_MGAnims
{
	MG_IDLE = 0,
	MG_FIRE,
	MG_DRAW,
	MG_HOLSTER
};

class weapon_q2machinegun : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	private array<string> pFireSounds = 
	{
		"quake2/weapons/mg_fire1.wav",
		"quake2/weapons/mg_fire2.wav",
		"quake2/weapons/mg_fire3.wav",
		"quake2/weapons/mg_fire4.wav",
		"quake2/weapons/mg_fire5.wav"
	};

	int m_iShell;
	CScheduledFunction@ m_pRotFunc;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_machinegun.mdl" );
		self.m_iDefaultAmmo = Q2_MG_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_machinegun.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_machinegun.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_machinegun.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/quake2/w_shell_mg.mdl" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		for( uint i = 0; i < pFireSounds.length(); i++ )
			g_SoundSystem.PrecacheSound( pFireSounds[i] );

		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );

		for( uint i = 0; i < pFireSounds.length(); i++ )
			g_Game.PrecacheGeneric( "sound/" + pFireSounds[i] );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2mg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/mg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_MG_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 3;
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

		NetworkMessage q2mg( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2mg.WriteLong( self.m_iId );
		q2mg.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_machinegun.mdl"), self.GetP_Model("models/quake2/p_machinegun.mdl"), MG_DRAW, "onehanded" );
			float deployTime = 1.0f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
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

		self.SendWeaponAnim( MG_FIRE );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pFireSounds[Math.RandomLong(0,4)], 1, ATTN_NORM );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		--ammo;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;
		
		int iDamage = 8;
		Vector vecRecoil( 0, Math.RandomFloat(0, 0.7f), Math.RandomFloat(0, 0.7f) );
		Vector recoil = vecRecoil;

		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			recoil = vecRecoil * 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.FireBullets( 1, vecSrc, vecAiming, Q2_MG_CONE, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, iDamage );

		Math.MakeVectors( m_pPlayer.pev.v_angle );

		Vector vecShellVelocity = m_pPlayer.pev.velocity 
					+ g_Engine.v_right * Math.RandomFloat( 50, 70 ) 
					+ g_Engine.v_up * Math.RandomFloat( 100, 150 ) 
					+ g_Engine.v_forward * 25;
    
		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -42 + g_Engine.v_forward * 11 + g_Engine.v_right * 5, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHELL );

		m_pPlayer.pev.punchangle = recoil;
		self.m_flNextPrimaryAttack = g_Engine.time + 0.10f;

		q2_CreatePelletDecals( vecSrc, vecAiming, Q2_MG_CONE, 1, EHandle(m_pPlayer) );
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( MG_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 2, 4 );
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

void q2_RegisterWeapon_MACHINEGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2machinegun", "weapon_q2mg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2mg", "quake2/weapons", "bullets" );
}
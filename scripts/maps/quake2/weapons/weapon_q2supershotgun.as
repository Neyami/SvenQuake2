const Vector Q2_SSG_CONE( 0.18f, 0.06f, 0 );

const int Q2_SSG_AMMO_DEFAULT	= 25;
const int Q2_SSG_AMMO_MAX		= 100;
const uint Q2_SSG_NPELLETS		= 20;
const float Q2_SSG_DELAY		= 1.1f;

enum q2_SSGAnims
{
	SSG_IDLE = 0,
	SSG_FIRE,
	SSG_DRAW,
	SSG_HOLSTER
};

class weapon_q2supershotgun : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iShell;
	CScheduledFunction@ m_pRotFunc;
	private int iDamage = 4;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_ssg.mdl" );
		self.m_iDefaultAmmo = Q2_SSG_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_ssg.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_ssg.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_ssg.mdl" );

		m_iShell = g_Game.PrecacheModel( "models/quake2/w_shell_sg.mdl" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/ssg_fire.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/ssg_fire.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2ssg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/ssg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_SSG_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 2;
		info.iPosition = 10;
		info.iFlags = 0;
		info.iWeight = 1;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage q2ssg( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2ssg.WriteLong( self.m_iId );
		q2ssg.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_ssg.mdl"), self.GetP_Model("models/quake2/p_ssg.mdl"), SSG_DRAW, "shotgun" );
			float deployTime = 0.8f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = self.m_flNextSecondaryAttack = self.m_flNextTertiaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/ssg_fire.wav" );

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

	void EjectShell( const Vector& in vecSrc, uint8 side )
	{
		Vector vecShellVelocity;

		if( side == 0 )//left
		{
			vecShellVelocity = m_pPlayer.pev.velocity 
					 + g_Engine.v_right * Math.RandomFloat( -50, -70 ) 
					 + g_Engine.v_up * Math.RandomFloat( 100, 150 ) 
					 + g_Engine.v_forward * 25;
		}
		else if( side == 1 )//right
		{
			vecShellVelocity = m_pPlayer.pev.velocity 
					 + g_Engine.v_right * Math.RandomFloat( 50, 70 ) 
					 + g_Engine.v_up * Math.RandomFloat( 100, 150 ) 
					 + g_Engine.v_forward * 25;
		}

		g_EntityFuncs.EjectBrass( vecSrc + m_pPlayer.pev.view_ofs + g_Engine.v_up * -42 + g_Engine.v_forward * 11 + g_Engine.v_right * 5, vecShellVelocity, m_pPlayer.pev.angles.y, m_iShell, TE_BOUNCE_SHOTSHELL );
	}

	void PrimaryAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( ammo <= 1 )
		{
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.75f;
			self.PlayEmptySound();
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		self.SendWeaponAnim( SSG_FIRE, 0, 0 );
		
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/ssg_fire.wav", 1, ATTN_NORM );

		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;

		ammo -= 2;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		Vector vecSrc	 = m_pPlayer.GetGunPosition();
		Vector vecAiming = g_Engine.v_forward;

		int iRecoil = -2;
		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			iRecoil *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		self.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.FireBullets( Q2_SSG_NPELLETS, vecSrc, vecAiming, Q2_SSG_CONE, 2048, BULLET_PLAYER_CUSTOMDAMAGE, 0, 0 );

		Math.MakeVectors( m_pPlayer.pev.v_angle );
		EjectShell( vecSrc, 0 );
		EjectShell( vecSrc, 1 );

		m_pPlayer.pev.punchangle.x = iRecoil;
		self.m_flNextPrimaryAttack = g_Engine.time + Q2_SSG_DELAY;

		if( ammo > 1 )
			self.m_flTimeWeaponIdle = g_Engine.time + 5.0f;

		q2_CreateShotgunPelletDecals( vecSrc, vecAiming, Q2_SSG_CONE, Q2_SSG_NPELLETS, iDamage, EHandle(m_pPlayer) );
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;
		
		self.SendWeaponAnim( SSG_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 3, 5 );
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

void q2_RegisterWeapon_SUPERSHOTGUN()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2supershotgun", "weapon_q2ssg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2ssg", "quake2/weapons", "shells" );
}
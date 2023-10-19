const int	Q2_G_AMMO_DEFAULT	= 10;
const int	Q2_G_AMMO_MAX		= 50;
const float Q2_G_DELAY			= 1.1f;
const float Q2_G_DELAY_EXPLODE	= 4.4f;

enum q2_GrenadeAnims
{
	GRENADE_IDLE = 0,
	GRENADE_PRIME,
	GRENADE_THROW,
	GRENADE_DRAW,
	GRENADE_NOAMMO
};

class weapon_q2grenade : ScriptBasePlayerWeaponEntity, item_q2weapon
{
	private CBasePlayer@ m_pPlayer = null;
	CScheduledFunction@ m_pRotFunc;
	private bool m_bInAttack, m_bThrown;
	private float m_fAttackStart, m_fExplode, m_fTimerSound;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, "models/quake2/w_grenade2.mdl" );
		self.m_iDefaultAmmo = Q2_G_AMMO_DEFAULT;
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
		g_Game.PrecacheModel( "models/quake2/v_grenade.mdl" );
		g_Game.PrecacheModel( "models/quake2/p_grenade.mdl" );
		g_Game.PrecacheModel( "models/quake2/w_grenade2.mdl" );
		for( uint i = 0; i < pExplosionSprites.length(); i++ )
			g_Game.PrecacheModel( pExplosionSprites[i] );

		g_Game.PrecacheModel( "sprites/WXplo1.spr" );

		g_SoundSystem.PrecacheSound( "quake2/weapon.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hg_prime.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hg_tick.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/hg_throw.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_bounce1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_bounce2.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/grenade_explode.wav" );
		g_SoundSystem.PrecacheSound( "quake2/weapons/noammo.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sound/quake2/weapon.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/noammo.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hg_prime.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hg_tick.wav" );
		g_Game.PrecacheGeneric( "sound/quake2/weapons/hg_throw.wav" );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/weapon_q2hg.txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/hg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1 = Q2_G_AMMO_MAX;
		info.iMaxAmmo2 = -1;
		info.iMaxClip = WEAPON_NOCLIP;
		info.iSlot = 5;
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

		NetworkMessage q2g( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			q2g.WriteLong( self.m_iId );
		q2g.End();

		g_Scheduler.RemoveTimer( m_pRotFunc );
		@m_pRotFunc = null;

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model("models/quake2/v_grenade.mdl"), self.GetP_Model("models/quake2/p_grenade.mdl"), GRENADE_DRAW, "gren" );
			float deployTime = 0.40f;
			self.m_flTimeWeaponIdle = self.m_flNextPrimaryAttack = g_Engine.time + deployTime;

			return bResult;
		}
	}

	bool CanHolster()
	{
		return( m_fAttackStart == 0 );
	}

	void Holster( int skipLocal = 0 )
	{	
		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_tick.wav" );

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
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + 0.3f;
			self.PlayEmptySound();
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

			return;
		}

		if( m_fAttackStart > 0 ) return;

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_G_DELAY;

		self.SendWeaponAnim( GRENADE_PRIME );
		//m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		m_bInAttack = true;
		m_fAttackStart = g_Engine.time + 0.7f;
		m_fExplode = g_Engine.time + Q2_G_DELAY_EXPLODE;
		m_fTimerSound = g_Engine.time + 0.5f;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_prime.wav", 1, ATTN_NORM );

		self.m_flTimeWeaponIdle = g_Engine.time + 3;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) > 0 )
			self.SendWeaponAnim( GRENADE_IDLE );
		else
			self.SendWeaponAnim( GRENADE_NOAMMO );

		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 3, 5 );
	}

	void ItemPreFrame()
	{
		if( m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) <= 0 )
			self.SendWeaponAnim( GRENADE_NOAMMO );

		if( m_fTimerSound > 0 && g_Engine.time > m_fTimerSound )
		{
			m_fTimerSound = 0;
			if( !m_bInAttack ) return;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_tick.wav", 1, ATTN_NORM );
		}

		if( m_fExplode > 0 && g_Engine.time > m_fExplode )
		{
			m_fExplode = 0;
			Explode();
		}

		if( !m_bInAttack || (m_pPlayer.pev.button & IN_ATTACK == 1) || g_Engine.time < m_fAttackStart ) return;

		self.m_flNextPrimaryAttack = g_Engine.time + Q2_G_DELAY;
		self.SendWeaponAnim( GRENADE_THROW );
		m_bThrown = true;
		m_bInAttack = false;
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_throw.wav", 1, ATTN_NORM );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_tick.wav" );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomLong( 3, 5 );
		m_fExplode = 0;

		Vector angThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

		if ( angThrow.x < 0 )
			angThrow.x = -10 + angThrow.x * ( ( 90 - 10 ) / 90.0 );
		else
			angThrow.x = -10 + angThrow.x * ( ( 90 + 10 ) / 90.0 );

		float flVel = ( 90.0f - angThrow.x ) * 6;

		if ( flVel > 750.0f )
			flVel = 750.0f;

		Math.MakeVectors ( angThrow );

		Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
		Vector vecVelocity = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;
		Vector vecAngles = m_pPlayer.pev.v_angle;

		int iDamage = 125;

		if( !(m_pPlayer.HasNamedPlayerItem("item_q2quad") is null) )
		{
			iDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, "quake2/quad_fire.wav", 1, ATTN_NORM );
		}

		float time = 4 - (g_Engine.time - (m_fAttackStart - 0.6f));

		if( time < 0 )
			time = 0;

		auto @pGrenade = q2_ShootCustomProjectile( "projectile_q2grenade2", "models/quake2/w_grenade2.mdl", vecSrc, vecVelocity, vecAngles, m_pPlayer, time );
		pGrenade.pev.dmg = iDamage;

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType ) - 1 );
		m_fAttackStart = 0;

		BaseClass.ItemPreFrame();
	}

	void Explode()
	{
		if( (m_pPlayer.pev.button & IN_ATTACK) != 1 ) return;
	
		g_WeaponFuncs.RadiusDamage( self.pev.origin, self.pev, self.pev.owner.vars, 160, 90, CLASS_NONE, DMG_BLAST );
		g_SoundSystem.EmitSound( self.edict(), CHAN_AUTO, "quake2/weapons/grenade_explode.wav", 1, ATTN_NORM );

		NetworkMessage exp1( MSG_BROADCAST, NetworkMessages::SVC_TEMPENTITY );
			exp1.WriteByte( TE_EXPLOSION );
			exp1.WriteCoord( self.pev.origin.x );
			exp1.WriteCoord( self.pev.origin.y );
			exp1.WriteCoord( self.pev.origin.z );
			exp1.WriteShort( g_EngineFuncs.ModelIndex(pExplosionSprites[Math.RandomLong(0,pExplosionSprites.length() - 1)]) );
			exp1.WriteByte( 60 );
			exp1.WriteByte( 20 );
			exp1.WriteByte( 4 );
		exp1.End();

		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, self.m_iPrimaryAmmoType - 1 );
		self.SendWeaponAnim( GRENADE_DRAW );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, "quake2/weapons/hg_tick.wav" );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomFloat( 3, 5 );
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

void q2_RegisterWeapon_GRENADE()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "weapon_q2grenade", "weapon_q2hg" );
	g_ItemRegistry.RegisterWeapon( "weapon_q2hg", "quake2/weapons", "grenades" );
}
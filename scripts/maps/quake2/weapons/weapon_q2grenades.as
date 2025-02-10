namespace q2grenades
{

const string WEAPON_NAME				= "weapon_q2grenades";

const int Q2W_DEFAULT_GIVE				= 0; //in Quake 2 you get the hand grenades as soon as you get ammo for the launcher

const float Q2W_DAMAGE					= 125;
const float Q2W_RADIUS					= 165;
const float Q2W_MINSPEED				= 400;
const float Q2W_MAXSPEED				= 800;
const float Q2W_RECOIL						= -1.0;
const float Q2W_TIME_DELAY				= 1.1;
const float Q2W_TIME_EXPLODE			= 4.4;
const float Q2W_TIME_DRAW				= 0.4;
const float Q2W_TIME_IDLE				= 1.0; //length of animation
const float Q2W_TIME_IDLE_MIN		= 5; //the above + random between these two
const float Q2W_TIME_IDLE_MAX		= 10;
const float Q2W_TIME_FIRE_TO_IDLE	= 1.0;

const string Q2W_ANIMEXT				= "gren";

const string MODEL_VIEW					= "models/quake2/weapons/v_grenades.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_grenades.mdl";
const string MODEL_WORLD				= "models/quake2/items/ammo/grenades.mdl";

enum q2w_e
{
	ANIM_IDLE = 0,
	ANIM_PRIME,
	ANIM_THROW,
	ANIM_DRAW,
	ANIM_NOAMMO
};

enum q2wsounds_e
{
	SND_EMPTY = 1,
	SND_QUAD_FIRE,
	SND_PRIME,
	SND_TICK,
	SND_THROW
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/hgrena1b.wav",
	"quake2/weapons/hgrenc1b.wav",
	"quake2/weapons/hgrent1a.wav"
};

class weapon_q2grenades : CBaseQ2Weapon
{
	private bool m_bInAttack, m_bThrown;
	private float m_fAttackStart, m_flExplode, m_fTimerSound;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = Q2W_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		for( uint i = 0; i < pQ2WSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pQ2WSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pQ2WSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pQ2WSounds[i] );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/" + WEAPON_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/hg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_GRENADES_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::GRENADES_SLOT - 1;
		info.iPosition			= q2weapons::GRENADES_POSITION - 1;
		info.iWeight			= q2weapons::GRENADES_WEIGHT;

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m.WriteLong( g_ItemRegistry.GetIdForName(WEAPON_NAME) );
		m.End();

		return true;
	}

	bool Deploy()
	{
		bool bResult;
		{
			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, Q2W_ANIMEXT, 0 );
			self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (Q2W_TIME_DRAW + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MAX));
			
			PlayDrawSound();

			return bResult;
		}
	}

	bool CanHolster()
	{
		return( m_fAttackStart <= 0.0 );
	}

	void Holster( int skipLocal = 0 )
	{	
		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0.0;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_TICK] );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( ammo <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.3;
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		if( m_fAttackStart > 0.0 )
			return;

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;

		self.SendWeaponAnim( ANIM_PRIME );

		m_bInAttack = true;
		m_fAttackStart = g_Engine.time + 0.7;
		m_flExplode = g_Engine.time + Q2W_TIME_EXPLODE;
		m_fTimerSound = g_Engine.time + 0.5;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_PRIME], VOL_NORM, ATTN_NORM );

		self.m_flTimeWeaponIdle = g_Engine.time + 3.0;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
			self.SendWeaponAnim( ANIM_IDLE );
		else
			self.SendWeaponAnim( ANIM_NOAMMO );

		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_IDLE + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MAX) );
	}

	void ItemPreFrame()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
			self.SendWeaponAnim( ANIM_NOAMMO );

		if( m_fTimerSound > 0.0 and g_Engine.time > m_fTimerSound )
		{
			if( !m_bInAttack )
				return;

			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_TICK], VOL_NORM, ATTN_NORM );
			m_fTimerSound = g_Engine.time + 1.0;
		}

		if( m_flExplode > 0.0 and g_Engine.time > m_flExplode )
		{
			m_flExplode = 0.0;
			Explode();
			self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
			self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_FIRE_TO_IDLE + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MAX) );
		}

		if( !m_bInAttack or (m_pPlayer.pev.button & IN_ATTACK) != 0 or m_fAttackStart <= 0.0 or g_Engine.time < m_fAttackStart )
			return;

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.SendWeaponAnim( ANIM_THROW );
		m_bThrown = true;
		m_bInAttack = false;
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_THROW], VOL_NORM, ATTN_NORM );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_TICK] );
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );
		self.m_flTimeWeaponIdle = g_Engine.time + Math.RandomLong( 3, 5 );
		m_flExplode = 0.0;

		Vector vecAngThrow = m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle;

		if( vecAngThrow.x < 0 )
			vecAngThrow.x = -10 + vecAngThrow.x * ( ( 90 - 10 ) / 90.0 );
		else
			vecAngThrow.x = -10 + vecAngThrow.x * ( ( 90 + 10 ) / 90.0 );

		float flVel = ( 90.0 - vecAngThrow.x ) * 6;

		if( flVel < Q2W_MINSPEED )
			flVel = Q2W_MINSPEED;

		if( flVel > Q2W_MAXSPEED )
			flVel = Q2W_MAXSPEED;

		Math.MakeVectors( vecAngThrow );

		Vector vecSrc = m_pPlayer.pev.origin + m_pPlayer.pev.view_ofs + g_Engine.v_forward * 16;
		Vector vecThrow = g_Engine.v_forward * flVel + m_pPlayer.pev.velocity;

		float flDamage = Q2W_DAMAGE;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], VOL_NORM, ATTN_NORM );
		}

		float flTime = 4 - (g_Engine.time - (m_fAttackStart - 0.6));
		if( flTime < 0.0 )
			flTime = 0.0;

		fire_grenade2( pev.origin, vecThrow, Q2W_DAMAGE, flTime, Q2W_RADIUS );

		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
		m_fAttackStart = 0.0;

		BaseClass.ItemPreFrame();
	}

	void Explode()
	{
		if( (m_pPlayer.pev.button & IN_ATTACK) == 0 ) return;

		fire_grenade2( pev.origin, g_vecZero, Q2W_DAMAGE, 0.0, Q2W_RADIUS ); //instantly explode

		m_bThrown = false;
		m_bInAttack = false;
		m_fAttackStart = 0.0;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) - 1 );
		self.SendWeaponAnim( ANIM_DRAW );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_TICK] );
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "grenade" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2grenades::weapon_q2grenades", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2grenades" );
}

} //namespace q2grenades END
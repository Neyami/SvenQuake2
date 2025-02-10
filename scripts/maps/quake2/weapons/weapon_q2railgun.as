namespace q2railgun
{

const string WEAPON_NAME				= "weapon_q2railgun";

const int Q2W_DEFAULT_GIVE				= 25;

const float Q2W_DAMAGE					= 150; //100 in DM
const float Q2W_RECOIL						= -3.0;
const float Q2W_TIME_DELAY				= 1.6;
const float Q2W_TIME_DRAW				= 0.4;
const float Q2W_TIME_IDLE				= 3.8;
const float Q2W_TIME_FIRE_TO_IDLE	= 1.5;

const string Q2W_ANIMEXT				= "mp5"; //gauss, sniper ??

const string MODEL_VIEW					= "models/quake2/weapons/v_railgun.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_railgun.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_railgun.mdl";

enum q2w_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_DRAW,
	ANIM_HOLSTER
};

enum q2wsounds_e
{
	SND_EMPTY = 1,
	SND_QUAD_FIRE,
	SND_SHOOT,
	SND_IDLE
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/railgf1a.wav",
	"quake2/weapons/rg_hum.wav"
};

class weapon_q2railgun : CBaseQ2Weapon
{
	private bool m_bPlayIdleSound;

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
		g_Game.PrecacheGeneric( "sprites/quake2/rg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_SLUGS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::RAILGUN_SLOT - 1;
		info.iPosition			= q2weapons::RAILGUN_POSITION - 1;
		info.iWeight			= q2weapons::RAILGUN_WEIGHT;

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
			self.m_flTimeWeaponIdle = g_Engine.time + (Q2W_TIME_DRAW + Math.RandomFloat(0.5, (Q2W_TIME_DRAW*2)));

			PlayDrawSound();

			m_bPlayIdleSound = true;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		m_bPlayIdleSound = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_IDLE] );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		if( ammo <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( ANIM_SHOOT );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 12 + g_Engine.v_right * 3 + g_Engine.v_up * -3.5;

		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		m_pPlayer.pev.punchangle.x = Q2W_RECOIL;

		fire_railgun( vecMuzzle, g_Engine.v_forward, Q2W_DAMAGE );

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_IDLE + Math.RandomFloat(0.5, (Q2W_TIME_IDLE*2)) );
	}

	void ItemPostFrame()
	{
		if( m_bPlayIdleSound )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_IDLE], GetSilencedVolume(0.15), ATTN_NORM, SND_FORCE_LOOP );
			m_bPlayIdleSound = false;
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "railbeam" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2railgun::weapon_q2railgun", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2slugs" );
}

} //namespace q2railgun END

/* FIXME
*/

/* TODO
*/
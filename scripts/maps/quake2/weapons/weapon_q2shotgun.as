namespace q2shotgun
{

const string WEAPON_NAME				= "weapon_q2shotgun";

const int Q2W_DEFAULT_GIVE				= 25;

const float Q2W_DAMAGE					= 4;
const float Q2W_PELLETS					= 12;
const float Q2W_RECOIL						= -2.0;
const float Q2W_TIME_DELAY				= 1.1;
const float Q2W_TIME_DRAW				= 0.8;
const float Q2W_TIME_IDLE				= 1.8; //length of animation
const float Q2W_TIME_IDLE_MIN		= 5; //the above + random between these two
const float Q2W_TIME_IDLE_MAX		= 10;
const float Q2W_TIME_FIRE_TO_IDLE	= 1.1;

const string Q2W_ANIMEXT				= "shotgun";

const string MODEL_VIEW					= "models/quake2/weapons/v_shotgun.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_shotgun.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_shotgun.mdl";

enum q2w_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_SHOOT_LAST,
	ANIM_DRAW,
	ANIM_HOLSTER
};

enum q2wsounds_e
{
	SND_EMPTY = 1,
	SND_QUAD_FIRE,
	SND_SHOOT,
	SND_COCK
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav", //only here for the precache
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/shotgf1b.wav",
	"quake2/weapons/shotgr1b.wav"
};

class weapon_q2shotgun : CBaseQ2Weapon
{
	private float m_flCockSound;

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
		g_Game.PrecacheGeneric( "sprites/quake2/sg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_SHELLS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::SHOTGUN_SLOT - 1;
		info.iPosition			= q2weapons::SHOTGUN_POSITION - 1;
		info.iWeight			= q2weapons::SHOTGUN_WEIGHT;

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

	void Holster( int skipLocal = 0 )
	{
		m_flCockSound = 0.0;

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		G_RemoveAmmo( 1 );

		//Quake 2 monsters aren't alerted to gunshots ??
		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0) ? ANIM_SHOOT : ANIM_SHOOT_LAST );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition();
		Vector vecAim = g_Engine.v_forward;

		float flRecoil = Q2W_RECOIL;
		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		m_pPlayer.pev.punchangle.x = flRecoil;

		muzzleflash( vecMuzzle, 255, 255, 0, 4 );
		fire_shotgun( vecMuzzle, vecAim, flDamage, Q2W_PELLETS );

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
			m_flCockSound = g_Engine.time + 0.2; //0.1 in the original, but it feels off

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_FIRE_TO_IDLE + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MAX) );
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_IDLE + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MAX) );
	}

	void ItemPostFrame()
	{
		if( m_flCockSound > 0.0 and m_flCockSound < g_Engine.time )
		{
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, pQ2WSounds[SND_COCK], GetSilencedVolume(VOL_NORM), ATTN_NORM );
			m_flCockSound = 0.0;
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2shotgun::weapon_q2shotgun", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2shells" );
}

} //namespace q2shotgun END

/* FIXME
*/

/* TODO
*/
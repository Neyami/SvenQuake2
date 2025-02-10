namespace q2grenadelauncher
{

const string WEAPON_NAME				= "weapon_q2grenadelauncher";

const int Q2W_DEFAULT_GIVE				= 10;

const float Q2W_DAMAGE					= 120;
const float Q2W_RADIUS					= 160;
const float Q2W_SPEED						= 600;
const float Q2W_RECOIL						= -1.0;
const float Q2W_TIME_DELAY				= 1.1;
const float Q2W_TIME_DRAW				= 0.6;
const float Q2W_TIME_IDLE				= 4.3;
const float Q2W_TIME_IDLE_MIN		= 5; //the above + random between these two
const float Q2W_TIME_IDLE_MAX		= 10;
const float Q2W_TIME_FIRE_TO_IDLE	= 1.1;

const string Q2W_ANIMEXT				= "gauss";

const string MODEL_VIEW					= "models/quake2/weapons/v_glauncher.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_glauncher.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_glauncher.mdl";

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
	SND_RELOAD
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/grenlf1a.wav",
	"quake2/weapons/grenlr1b.wav"
};

class weapon_q2grenadelauncher : CBaseQ2Weapon
{
	private float m_flReloadSound;

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
		g_Game.PrecacheGeneric( "sprites/quake2/gl_icon.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_GRENADES_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::GLAUNCHER_SLOT - 1;
		info.iPosition			= q2weapons::GLAUNCHER_POSITION - 1;
		info.iWeight			= q2weapons::GLAUNCHER_WEIGHT;

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
		Vector vecMuzzle = m_pPlayer.GetGunPosition() + g_Engine.v_forward * 5 + g_Engine.v_right * 5 + g_Engine.v_up * -5;
		Vector vecAim = g_Engine.v_forward;

		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		m_pPlayer.pev.punchangle.x = Q2W_RECOIL;

		muzzleflash( vecMuzzle, 255, 128, 0 );
		fire_grenade( vecMuzzle, vecAim, flDamage, Q2W_SPEED, Q2W_RADIUS );

		if( ammo > 0 )
			m_flReloadSound = g_Engine.time + 0.1;

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
		if( m_flReloadSound > 0 and g_Engine.time > m_flReloadSound )
		{
			m_flReloadSound = 0.0;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_AUTO, pQ2WSounds[SND_RELOAD], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "grenade" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2grenadelauncher::weapon_q2grenadelauncher", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2grenades" );
}

} //namespace q2grenadelauncher END
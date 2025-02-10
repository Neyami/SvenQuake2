namespace q2chaingun
{

const string WEAPON_NAME				= "weapon_q2chaingun";

const int Q2W_DEFAULT_GIVE				= 50;

const float Q2W_DAMAGE					= 8; //6 in DM
const float Q2W_RECOIL						= -1.0;
const float Q2W_TIME_DELAY1			= 0.1;
const float Q2W_TIME_DELAY2			= 0.03;
const float Q2W_TIME_DRAW				= 0.5;
const float Q2W_TIME_IDLE				= 3.0;
const float Q2W_TIME_FIRE_TO_IDLE	= 2.7;

const string Q2W_ANIMEXT				= "egon";

const string MODEL_VIEW					= "models/quake2/weapons/v_chaingun.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_chaingun.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_chaingun.mdl";

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
	SND_SPINUP,
	SND_SPINLOOP,
	SND_SHOOT1,
	SND_SHOOT2,
	SND_SHOOT3,
	SND_SHOOT4,
	SND_SHOOT5,
	SND_SPINDOWN
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/chngnu1a.wav",
	"quake2/weapons/chngnl1a.wav",
	"quake2/weapons/machgf1b.wav",
	"quake2/weapons/machgf2b.wav",
	"quake2/weapons/machgf3b.wav",
	"quake2/weapons/machgf4b.wav",
	"quake2/weapons/machgf5b.wav",
	"quake2/weapons/chngnd1a.wav"
};

class weapon_q2chaingun : CBaseQ2Weapon
{
	private float m_flShoot, m_flFireDelay, m_flStopAttack, m_flAnimDelay;
	private bool m_bInAttack, m_bInFastAttack;

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
		g_Game.PrecacheGeneric( "sprites/quake2/cg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_BULLETS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::CHAINGUN_SLOT - 1;
		info.iPosition			= q2weapons::CHAINGUN_POSITION - 1;
		info.iWeight			= q2weapons::CHAINGUN_WEIGHT;

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
			m_flAnimDelay = g_Engine.time;

			bResult = self.DefaultDeploy( self.GetV_Model(MODEL_VIEW), self.GetP_Model(MODEL_PLAYER), ANIM_DRAW, Q2W_ANIMEXT, 0 );
			self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DRAW;
			self.m_flTimeWeaponIdle = g_Engine.time + (Q2W_TIME_DRAW + Math.RandomFloat(0.5, (Q2W_TIME_DRAW*2)));
			
			PlayDrawSound();

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{
		m_flShoot = 0.0;
		m_bInAttack = false;
		m_bInFastAttack = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );

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

		if( !m_bInAttack )
		{
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP], GetSilencedVolume(VOL_NORM), ATTN_NORM );

			if( m_flShoot <= 0.0 )
				StartAttack();
		}

		m_bInAttack = true;

		if( m_bRerelease )
			m_flStopAttack = g_Engine.time + 1.0; //this affects how many bullets are fired when only clicking once, and after releasing attack.
		else
			m_flStopAttack = g_Engine.time + 0.9;

		if( m_flShoot > 0.0 ) return;

		Fire();

		if( m_flFireDelay > 0.0 )
		{
			if( g_Engine.time < m_flFireDelay ) return;

			m_bInFastAttack = true;
			self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY2;
			self.m_flFrameRate = 1.5;
		}
	}

	void StartAttack()
	{
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SPINUP], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		if( m_flShoot > 0.0 or m_flStopAttack > 0.0 ) return;
		m_flFireDelay = g_Engine.time + 0.6;
	}

	void EndAttack()
	{
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );
		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SPINDOWN], GetSilencedVolume(VOL_NORM), ATTN_NORM );
	}

	void Fire()
	{
		int ammo = m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType );
		--ammo;
		m_pPlayer.m_rgAmmo( self.m_iPrimaryAmmoType, ammo );
		m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;
		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT5)], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition();
		Vector vecAim = g_Engine.v_forward;

		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		//m_pPlayer.pev.punchangle.x = Q2W_RECOIL;
		for( int i=0 ; i<3 ; i++)
		{
			//ent->client->kick_origin[i] = crandom() * 0.35;
			//ent->client->kick_angles[i] = crandom() * 0.7;
			m_pPlayer.pev.punchangle[i] = crandom_open() * 0.7;
		}

		muzzleflash( vecMuzzle, 255, 255, 0, 2 );
		fire_bullet( vecMuzzle, vecAim, flDamage );

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY1;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;

		if( m_flAnimDelay <= g_Engine.time )
		{
			self.SendWeaponAnim( ANIM_SHOOT );
			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );			

			m_flAnimDelay = g_Engine.time + 0.05; //0.2 in SP
		}
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
		if( m_flShoot > 0.0 and g_Engine.time > m_flShoot )
		{
			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) == 0 ) return;

			Fire();

			if( m_bInFastAttack )
				m_flShoot = g_Engine.time + Q2W_TIME_DELAY2;
			else
				m_flShoot = g_Engine.time + Q2W_TIME_DELAY1;
		}

		if( m_flStopAttack > 0.0 and g_Engine.time > m_flStopAttack or m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) == 0 and m_bInAttack )
		{
			m_flStopAttack = 0.0;
			m_flShoot = 0.0;
			m_bInFastAttack = false;
			self.m_flNextPrimaryAttack = g_Engine.time + 0.6;
			m_flFireDelay = g_Engine.time + 1.2;
			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );
			m_bInAttack = false;
			EndAttack();
		}

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			if( (m_pPlayer.m_afButtonLast & IN_ATTACK) == 0 )
			{
				if( m_bInAttack )
					m_flShoot = self.m_flNextPrimaryAttack;
			}
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2chaingun::weapon_q2chaingun", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2bullets" );
}

} //namespace q2chaingun END

/* FIXME
*/

/* TODO
	Try to figure out the more advanced muzzleflash stuff ??
*/
namespace q2bfg
{

const string WEAPON_NAME				= "weapon_q2bfg";

const int Q2W_DEFAULT_GIVE				= 50;
const int Q2W_AMMO_PER_SHOT		= 50;

const float Q2W_DAMAGE					= 500; //200 in DM
const float Q2W_RADIUS					= 1000;
const float Q2W_SPEED						= 400;
const float Q2W_RECOIL						= -40.0;
const float Q2W_TIME_DELAY				= 2.5;
const float Q2W_TIME_DRAW				= 1.04;
const float Q2W_TIME_IDLE				= 3.44;
const float Q2W_TIME_FIRE_TO_IDLE	= 2.64;

const string Q2W_ANIMEXT				= "gauss";

const string MODEL_VIEW					= "models/quake2/weapons/v_bfg.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_bfg.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_bfg.mdl";

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
	"quake2/weapons/bfg__f1y.wav",
	"quake2/weapons/bfg_hum.wav"
};

class weapon_q2bfg : CBaseQ2Weapon
{
	private float m_flBFG;
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
		g_Game.PrecacheGeneric( "sprites/quake2/bfg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_CELLS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::BFG_SLOT - 1;
		info.iPosition			= q2weapons::BFG_POSITION - 1;
		info.iWeight			= q2weapons::BFG_WEIGHT;

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
			self.m_flTimeWeaponIdle = g_Engine.time + (Q2W_TIME_DRAW + Math.RandomFloat(0.5, (Q2W_TIME_DRAW*2)));

			PlayDrawSound();

			m_bPlayIdleSound = true;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		m_flBFG = 0.0;
		m_bPlayIdleSound = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_IDLE] );
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT] );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < Q2W_AMMO_PER_SHOT )
		{
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		self.SendWeaponAnim( ANIM_SHOOT );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		m_flBFG = g_Engine.time + 0.8;

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

		if( m_flBFG > 0.0 and g_Engine.time > m_flBFG )
		{
			m_flBFG = 0.0;

			if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) < Q2W_AMMO_PER_SHOT )
			{
				self.PlayEmptySound();
				self.SendWeaponAnim( ANIM_IDLE );
				self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
				m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );

				return;
			}

			G_RemoveAmmo( Q2W_AMMO_PER_SHOT );
			q2::G_CheckPowerArmor( m_pPlayer );

			float flDamage = Q2W_DAMAGE;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			if( CheckQuadDamage() )
			{
				flDamage *= 4;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
			}

			m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

			//Quake 2 monsters aren't alerted to gunshots ??
			if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
				m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecMuzzle = m_pPlayer.GetGunPosition() + g_Engine.v_right * 3 + g_Engine.v_up * -10;
			Vector vecAim = g_Engine.v_forward;

			fire_bfg( vecMuzzle, vecAim, Q2W_DAMAGE, Q2W_SPEED, Q2W_RADIUS );

			m_pPlayer.pev.punchangle.x = Q2W_RECOIL;
			m_pPlayer.pev.punchangle.z = q2::crandom() * 8;

			CheckSilencer();
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "bfg" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2bfg::weapon_q2bfg", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2cells" );
}

} //namespace q2bfg END

/* FIXME
*/

/* TODO
*/
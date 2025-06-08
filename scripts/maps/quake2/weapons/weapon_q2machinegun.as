namespace q2machinegun
{

const bool USE_ORIGINAL_RECOIL		= false; //too nauseating imo
const string WEAPON_NAME				= "weapon_q2machinegun";

const int Q2W_DEFAULT_GIVE				= 50;

const float Q2W_DAMAGE					= 8;
const float Q2W_RECOIL						= -1.5;
const float Q2W_TIME_DELAY				= 0.1;
const float Q2W_TIME_DRAW				= 0.4;
const float Q2W_TIME_IDLE				= 4.0;
const float Q2W_TIME_FIRE_TO_IDLE	= 0.2;

const string Q2W_ANIMEXT				= "mp5";

const string MODEL_VIEW					= "models/quake2/weapons/v_machinegun.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_machinegun.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_machinegun.mdl";

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
	SND_SHOOT1,
	SND_SHOOT2,
	SND_SHOOT3,
	SND_SHOOT4,
	SND_SHOOT5
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/machgf1b.wav",
	"quake2/weapons/machgf2b.wav",
	"quake2/weapons/machgf3b.wav",
	"quake2/weapons/machgf4b.wav",
	"quake2/weapons/machgf5b.wav"
};

class weapon_q2machinegun : CBaseQ2Weapon
{
	private int m_iMachinegunShots;

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
		g_Game.PrecacheGeneric( "sprites/quake2/mg_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_BULLETS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::MGUN_SLOT - 1;
		info.iPosition			= q2weapons::MGUN_POSITION - 1;
		info.iWeight			= q2weapons::MGUN_WEIGHT;

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

			return bResult;
		}
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

		self.SendWeaponAnim( ANIM_SHOOT );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[Math.RandomLong(SND_SHOOT1, SND_SHOOT5)], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition();
		Vector vecAim = g_Engine.v_forward;

		float flKick = 2;
		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flKick *= 4;
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		if( USE_ORIGINAL_RECOIL )
		{
			for( int i=1 ; i<3 ; i++ )
			{
				//ent->client->kick_origin[i] = crandom() * 0.35;
				//ent->client->kick_angles[i] = crandom() * 0.7;
				m_pPlayer.pev.punchangle[i] = q2::crandom() * 0.7;
			}

			//ent->client->kick_origin[0] = crandom() * 0.35;
			m_pPlayer.pev.punchangle.x = m_iMachinegunShots * Q2W_RECOIL;
			//ent->client->kick_angles[0] = ent->client->machinegun_shots * -1.5;

			// raise the gun as it is firing
			if( !q2::PVP )
			{
				m_iMachinegunShots++;
				if( m_iMachinegunShots > 9 )
					m_iMachinegunShots = 9;
			}
		}
		else
			m_pPlayer.pev.punchangle.x = Q2W_RECOIL;

		muzzleflash( vecMuzzle, 255, 255, 0, 2 );

		if( !m_bUseQ2Bullets )
			fire_bullet( vecMuzzle, vecAim, flDamage );
		else
		{
			vecAim.z = -vecAim.z;
			q2::fire_bullet( m_pPlayer, vecMuzzle, vecAim, flDamage, flKick, q2::DEFAULT_BULLET_HSPREAD, q2::DEFAULT_BULLET_VSPREAD, q2::MOD_MACHINEGUN );
		}

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		m_iMachinegunShots = 0;
		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_IDLE + Math.RandomFloat(0.5, (Q2W_TIME_IDLE*2)) );
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2machinegun::weapon_q2machinegun", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2bullets" );
}

} //namespace q2machinegun END

/* FIXME
*/

/* TODO
*/
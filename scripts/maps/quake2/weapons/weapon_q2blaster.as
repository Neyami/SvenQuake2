namespace q2blaster
{

const string WEAPON_NAME				= "weapon_q2blaster";

const float Q2W_DAMAGE					= 10; //15 in DM
const float Q2W_SPEED						= 1000;
const float Q2W_RECOIL						= -1.0;
const float Q2W_TIME_DELAY				= 0.5;
const float Q2W_TIME_DRAW				= 0.5;
const float Q2W_TIME_IDLE				= 1.2;
const float Q2W_TIME_IDLE_MIN		= 5; //the above + random between these two
const float Q2W_TIME_IDLE_MAX		= 10;
const float Q2W_TIME_FIRE_TO_IDLE	= 0.4;

const string Q2W_ANIMEXT				= "onehanded";

const string MODEL_VIEW					= "models/quake2/weapons/v_blaster.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_blaster.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_blaster.mdl";

enum q2w_e
{
	ANIM_IDLE1 = 0,
	ANIM_IDLE2,
	ANIM_SHOOT,
	ANIM_DRAW,
	ANIM_HOLSTER
};

enum q2wsounds_e
{
	SND_QUAD_FIRE = 1,
	SND_SHOOT
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/blastf1a.wav"
};

class weapon_q2blaster : CBaseQ2Weapon
{
	private int m_iIdleState; //HACK :aRage:

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_flCustomDmg = pev.dmg;
		self.m_iClip = -1; //NEEDED for WeaponIdle to be called on weapons that don't use ammo

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
		g_Game.PrecacheGeneric( "sprites/quake2/blaster_icon.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iSlot				= q2weapons::BLASTER_SLOT - 1;
		info.iPosition			= q2weapons::BLASTER_POSITION - 1;
		info.iWeight			= q2weapons::BLASTER_WEIGHT;

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
			self.m_flNextPrimaryAttack = self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_DRAW;
			m_iIdleState = 0;

			PlayDrawSound();

			return bResult;
		}
	}

	void PrimaryAttack()
	{
		//Quake 2 monsters aren't alerted to gunshots ??
		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.m_iWeaponFlash = BRIGHT_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( ANIM_SHOOT );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition() + g_Engine.v_right * 6 + g_Engine.v_up * -8;
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

		muzzleflash( vecMuzzle, 255, 255, 0 );
		fire_blaster( vecMuzzle, vecAim, flDamage, Q2W_SPEED );

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;
		m_iIdleState = 0;
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		if( m_iIdleState == 0 )
		{
			self.SendWeaponAnim( ANIM_IDLE1 );
			self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_IDLE;
			m_iIdleState = 1;
			return;
		}
		else if( m_iIdleState == 1 )
		{
			self.SendWeaponAnim( ANIM_IDLE2 );
			m_iIdleState = 0;
		}

		self.m_flTimeWeaponIdle = g_Engine.time + ( Q2W_TIME_IDLE + Math.RandomFloat(Q2W_TIME_IDLE_MIN, Q2W_TIME_IDLE_MIN) );
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "laser" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2blaster::weapon_q2blaster", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons" );
}

} //namespace q2blaster END
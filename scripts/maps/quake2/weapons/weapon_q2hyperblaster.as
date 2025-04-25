namespace q2hyperblaster
{

const string WEAPON_NAME				= "weapon_q2hyperblaster";

const int Q2W_DEFAULT_GIVE				= 50;

const float Q2W_DAMAGE					= 20; //15 in DM
const float Q2W_SPEED						= 800;
const float Q2W_RECOIL						= -1.0;
const float Q2W_TIME_DELAY1			= 0.1; //firing
const float Q2W_TIME_DELAY2			= 1.1; //cooldown
const float Q2W_TIME_DRAW				= 0.7;
const float Q2W_TIME_IDLE				= 3.0;
const float Q2W_TIME_IDLE_MIN		= 1; //the above + random between these two
const float Q2W_TIME_IDLE_MAX		= 2;
const float Q2W_TIME_FIRE_TO_IDLE	= 1.5;

const string Q2W_ANIMEXT				= "gauss"; //m16 causes a muzzleflash that can't be removed (??) :aRage:

const string MODEL_VIEW					= "models/quake2/weapons/v_hyperblaster.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_hyperblaster.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_hyperblaster.mdl";

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
	SND_SPINLOOP,
	SND_SPINDOWN
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/hyprbf1a.wav",
	"quake2/weapons/hyprbl1a.wav",
	"quake2/weapons/hyprbd1a.wav"
};

class weapon_q2hyperblaster : CBaseQ2Weapon
{
	private bool m_bInAttack;
	private float m_flStopAttack;
	private int m_iRotationState;

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
		g_Game.PrecacheGeneric( "sprites/quake2/hb_icon.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/ammo.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_CELLS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::HPB_SLOT - 1;
		info.iPosition			= q2weapons::HPB_POSITION - 1;
		info.iWeight			= q2weapons::HPB_WEIGHT;

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

	bool PlayEmptySound()
	{
		if( self.m_bPlayEmptySound )
		{
			self.m_bPlayEmptySound = false;
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_EMPTY], GetSilencedVolume(VOL_NORM), ATTN_NORM );
		}

		return false;
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
        m_bInAttack = false;
        m_flStopAttack = 0.0;
        g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );

        return BaseClass.CanHolster();
    }
	
	void Holster( int skipLocal = 0 )
	{	
		m_bInAttack = false;
		m_iRotationState = 1;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );

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

		if( !m_bInAttack )
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP], GetSilencedVolume(0.8), ATTN_NORM );

		m_bInAttack = true;
		m_flStopAttack = 0.0;

		G_RemoveAmmo( 1 );
		q2::G_CheckPowerArmor( m_pPlayer );

		//Quake 2 monsters aren't alerted to gunshots ??
		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.m_iWeaponFlash = NORMAL_GUN_FLASH;
		m_pPlayer.pev.effects |= EF_MUZZLEFLASH;
		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( ANIM_SHOOT );

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], GetSilencedVolume(VOL_NORM), ATTN_NORM );

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, int(386 * GetSilencedVolume(1.0)), 3.0, self );

		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
		Vector vecMuzzle = m_pPlayer.GetGunPosition() + g_Engine.v_right * 6 + g_Engine.v_up * -8;

		float flRotation = m_iRotationState * 2 * Math.PI / 6;
		Vector vecOffset;
		vecOffset.x = -4 * sin(flRotation);
		vecOffset.y = 0;
		vecOffset.z = 4 * cos(flRotation);
		vecMuzzle = vecMuzzle + vecOffset;

		m_iRotationState++;
		if( m_iRotationState >= 7 ) m_iRotationState = 1;

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
		fire_blaster( vecMuzzle, vecAim, flDamage, Q2W_SPEED, true );

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY1;
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
		if( (m_flStopAttack > 0.0 and g_Engine.time > m_flStopAttack) or (m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 and m_bInAttack) )
		{
			m_flStopAttack = 0.0;
			self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY2;

			g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_SPINLOOP] );
			g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SPINDOWN], GetSilencedVolume(VOL_NORM), ATTN_NORM );
			m_bInAttack = false;
			m_iRotationState = 1;
		}

		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) > 0 )
		{
			if( (m_pPlayer.m_afButtonReleased & IN_ATTACK) != 0 )
			{
				if( m_bInAttack )
					m_flStopAttack = g_Engine.time + 0.25;
			}
		}

		BaseClass.ItemPostFrame();
	}
}

void Register()
{
	q2projectiles::RegisterProjectile( "laser" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2hyperblaster::weapon_q2hyperblaster", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2cells" );
}

} //namespace q2hyperblaster END
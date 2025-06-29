namespace q2chainfist
{

const bool USE_IDLE_SMOKE				= true; //added a bool since I can't get it to look as good as the original

const string WEAPON_NAME				= "weapon_q2chainfist";

const float Q2W_DAMAGE					= 7.0; //15 in DM
const float Q2W_RANGE						= 24.0;
const float Q2W_TIME_DELAY				= 0.8;
const float Q2W_TIME_DRAW				= 0.5;
const float Q2W_TIME_IDLE				= 2.5; //length of animation
const float Q2W_TIME_FIRE_TO_IDLE	= 0.9;

const string Q2W_ANIMEXT				= "squeak";

const string MODEL_VIEW					= "models/quake2/weapons/v_chainfist.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_chainfist.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_chainfist.mdl";
const string SPRITE_SMOKE				= "sprites/xsmoke4.spr";

enum q2w_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT1,
	ANIM_SHOOT2,
	ANIM_SHOOT3,
	ANIM_DRAW,
	ANIM_HOLSTER
};

enum q2wsounds_e
{
	SND_DRAW = 0,
	SND_QUAD_FIRE,
	SND_SHOOT,
	SND_IDLE,
	SND_HIT
};

const array<string> pQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/sawhit.wav", //yeah, the name makes no sense, gg Q2 devs
	"quake2/weapons/sawidle.wav",
	"quake2/weapons/sawslice.wav" //ditto :megaRoll:
};

class weapon_q2chainfist : CBaseQ2Weapon
{
	private bool m_bPlayIdleSound;
	private int m_iComboState;
	private float m_flResetCombo;
	private float m_flHitSound;
	private float m_flSmokeCheck;

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
		g_Game.PrecacheModel( SPRITE_SMOKE );

		for( uint i = 0; i < pQ2WSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( pQ2WSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < pQ2WSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + pQ2WSounds[i] );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/" + WEAPON_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/chainfist_icon.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxAmmo2	= -1;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iSlot				= q2weapons::CHAINFIST_SLOT - 1;
		info.iPosition			= q2weapons::CHAINFIST_POSITION - 1;
		info.iWeight			= q2weapons::CHAINFIST_WEIGHT;

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
			self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_DRAW;

			PlayDrawSound();

			m_bPlayIdleSound = true;

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		m_iComboState = 0;
		m_flResetCombo = 0.0;
		m_flHitSound = 0.0;
		m_flSmokeCheck = 0.0;
		m_bPlayIdleSound = false;

		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_IDLE] );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		//Quake 2 monsters aren't alerted to gunshots ??
		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		if( m_iComboState == 0 )
			self.SendWeaponAnim( ANIM_SHOOT1 );
		else if( m_iComboState == 1 )
			self.SendWeaponAnim( ANIM_SHOOT2 );
		else if( m_iComboState == 2 )
			self.SendWeaponAnim( ANIM_SHOOT3 );

		m_iComboState++;
		if( m_iComboState > 2 )
			m_iComboState = 0;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_SHOOT], VOL_NORM, ATTN_NORM );

		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 386, 3.0, self );

		Math.MakeVectors( (m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle) + Vector(0, 0, -4) );
		Vector vecMuzzle = m_pPlayer.GetGunPosition();

		float flDamage = Q2W_DAMAGE;
		if( self.m_flCustomDmg > 0 )
			flDamage = self.m_flCustomDmg;

		if( CheckQuadDamage() )
		{
			flDamage *= 4;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, pQ2WSounds[SND_QUAD_FIRE], VOL_NORM, ATTN_NORM );
		}

		if( fire_player_melee(vecMuzzle, m_pPlayer.pev.v_angle, Q2W_RANGE, flDamage, 100, q2::MOD_CHAINFIST) )
		{
			if( m_flHitSound < g_Engine.time )
			{
				m_flHitSound = g_Engine.time + 0.5;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, pQ2WSounds[SND_HIT], VOL_NORM, ATTN_NORM );
			}
		}

		m_flResetCombo = g_Engine.time + Q2W_TIME_DELAY + 0.1; //0.1??
		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;
	}

	void ItemPostFrame()
	{
		if( m_bPlayIdleSound )
		{
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_STATIC, pQ2WSounds[SND_IDLE], 0.15, ATTN_NORM, SND_FORCE_LOOP );
			m_bPlayIdleSound = false;
		}

		if( m_flResetCombo > 0.0 and m_flResetCombo < g_Engine.time )
		{
			m_flResetCombo = 0.0;
			m_iComboState = 0;
		}

		BaseClass.ItemPostFrame();

		if( !USE_IDLE_SMOKE ) return;

		if( (m_pPlayer.pev.button & IN_ATTACK) == 0 )
		{
			if( m_flSmokeCheck > 0.0 and m_flSmokeCheck < g_Engine.time )
			{
				if( Math.RandomLong(0, 8) != 0 and Math.RandomFloat(0.0, 1.0) < 0.4 )
					chainfist_smoke();

				m_flSmokeCheck = g_Engine.time + 0.9;
			}
		}
	}

	void WeaponIdle()
	{
		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		self.SendWeaponAnim( ANIM_IDLE );
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_IDLE;

		if( USE_IDLE_SMOKE )
			m_flSmokeCheck = g_Engine.time + 0.9;
	}

	void chainfist_smoke()
	{
		Vector vecOrigin = m_pPlayer.GetGunPosition();
		Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle ) ;
		vecOrigin = vecOrigin + g_Engine.v_forward * 8.0 + g_Engine.v_right * 8.0 + g_Engine.v_up * -4.0;

		NetworkMessage m1( MSG_ONE, NetworkMessages::SVC_TEMPENTITY, m_pPlayer.edict() );
			m1.WriteByte( TE_SPRITE );
			m1.WriteCoord( vecOrigin.x );
			m1.WriteCoord( vecOrigin.y );
			m1.WriteCoord( vecOrigin.z );
			m1.WriteShort( g_EngineFuncs.ModelIndex(SPRITE_SMOKE) );
			m1.WriteByte( 2 ); // scale * 10
			m1.WriteByte( 128 ); // brightness
		m1.End();
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2chainfist::weapon_q2chainfist", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons" );
}

} //namespace q2chainfist END
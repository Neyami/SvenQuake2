namespace q2plasmabeam
{

const string WEAPON_NAME				= "weapon_q2plasmabeam";

const int Q2W_DEFAULT_GIVE				= 50;
const int Q2W_AMMO_WARNING			= 50;

const float Q2W_DAMAGE_SP				= 15;
const float Q2W_DAMAGE_DM				= 15;
const float Q2W_TIME_DELAY				= 0.1;
const float Q2W_TIME_DRAW				= 0.9;
const float Q2W_TIME_IDLE				= 3.1; //length of animation
const float Q2W_TIME_FIRE_TO_IDLE	= 0.1;

const string Q2W_ANIMEXT				= "egon";

const string MODEL_VIEW					= "models/quake2/weapons/v_beamer.mdl";
const string MODEL_PLAYER				= "models/quake2/weapons/p_beamer.mdl";
const string MODEL_WORLD				= "models/quake2/weapons/w_beamer.mdl";

const string SPRITE_BEAM					= "sprites/quake2/beam2.spr";

enum q2w_e
{
	ANIM_IDLE = 0,
	ANIM_SHOOT,
	ANIM_DRAW,
	ANIM_HOLSTER
};

enum q2wsounds_e
{
	SND_DRAW = 0,
	SND_EMPTY,
	SND_QUAD_FIRE,
	SND_SHOOT,
	SND_LASERHIT
};

const array<string> arrsQ2WSounds =
{
	"quake2/weapons/change.wav",
	"quake2/weapons/noammo.wav",
	"quake2/items/damage3.wav",
	"quake2/weapons/bfg__l1a.wav",
	"quake2/weapons/lashit.wav",
	"quake2/weapons/lowammo.wav"
};

const array<Vector> arrvecBeamColors =
{
	Vector( 255, 255, 211 ),
	Vector( 255, 255, 167 ),
	Vector( 255, 255, 127 ),
	Vector( 255, 255, 83 ),
	Vector( 255, 255, 39 ),
	Vector( 255, 235, 31 ),
	Vector( 255, 215, 23 ),
	Vector( 255, 191, 15 ),
	Vector( 255, 171, 7 )
};

class weapon_q2plasmabeam : CBaseQ2Weapon
{
	protected EHandle m_hBeam;
	protected CBeam@ m_pBeam
	{
		get const { return cast<CBeam@>(m_hBeam.GetEntity()); }
		set { m_hBeam = EHandle(@value); }
	}

	private uint m_uiBeamColorIndex;
	private int m_iBodyConfig;
	private bool m_bShootingSound;
	private bool m_bInAttack;
	private float m_flNextDamage;

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_WORLD );
		self.m_iDefaultAmmo = Q2W_DEFAULT_GIVE;
		self.m_flCustomDmg = pev.dmg;

		m_iBodyConfig = 0;
		m_iAmmoWarning = Q2W_AMMO_WARNING;

		self.FallInit();
	}

	void Precache()
	{
		self.PrecacheCustomModels();

		g_Game.PrecacheModel( MODEL_VIEW );
		g_Game.PrecacheModel( MODEL_PLAYER );
		g_Game.PrecacheModel( MODEL_WORLD );

		g_Game.PrecacheModel( SPRITE_BEAM );

		for( uint i = 0; i < arrsQ2WSounds.length(); ++i )
			g_SoundSystem.PrecacheSound( arrsQ2WSounds[i] );

		//Precache these for downloading
		for( uint i = 0; i < arrsQ2WSounds.length(); ++i )
			g_Game.PrecacheGeneric( "sound/" + arrsQ2WSounds[i] );

		g_Game.PrecacheGeneric( "sprites/quake2/weapons/" + WEAPON_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/plasmabeam_icon.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= q2weapons::AMMO_CELLS_MAX;
		info.iMaxClip 			= WEAPON_NOCLIP;
		info.iAmmo1Drop	= Q2W_DEFAULT_GIVE;
		info.iSlot				= q2weapons::PLASMABEAM_SLOT - 1;
		info.iPosition			= q2weapons::PLASMABEAM_POSITION - 1;
		info.iWeight			= q2weapons::PLASMABEAM_WEIGHT;

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

			return bResult;
		}
	}

	void Holster( int skipLocal = 0 )
	{	
		EndAttack();
		m_bShootingSound = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, arrsQ2WSounds[SND_SHOOT] );

		BaseClass.Holster( skipLocal );
	}

	void PrimaryAttack()
	{
		if( m_pPlayer.m_rgAmmo(self.m_iPrimaryAmmoType) <= 0 )
		{
			EndAttack();
			self.PlayEmptySound();
			self.m_flNextPrimaryAttack = g_Engine.time + 0.75;
			m_pPlayer.SetSuitUpdate( "!HEV_AMO0", false, 0 );
			return;
		}

		G_RemoveAmmo( 2 );

		//Quake 2 monsters aren't alerted to gunshots ??
		if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			m_pPlayer.m_iWeaponVolume = LOUD_GUN_VOLUME;

		m_pPlayer.SetAnimation( PLAYER_ATTACK1 );

		self.SendWeaponAnim( ANIM_SHOOT, 0, GetBodygroup() );

		if( !m_bShootingSound )
		{
			m_bShootingSound = true;
			g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_WEAPON, arrsQ2WSounds[SND_SHOOT], 0.5, ATTN_NORM, SND_FORCE_LOOP );
		}

		//if( q2::arrsQuake2Maps.find(g_Engine.mapname) < 0 )
			//GetSoundEntInstance().InsertSound( bits_SOUND_COMBAT, pev.origin, 386, 3.0, self );

		m_bInAttack = true;

		CheckSilencer();

		self.m_flNextPrimaryAttack = g_Engine.time + Q2W_TIME_DELAY;
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_FIRE_TO_IDLE;
	}

	//bug fix
	void SecondaryAttack()
	{
		WeaponIdle();
		self.m_flNextSecondaryAttack = g_Engine.time + Q2W_TIME_DELAY;
	}

	void WeaponIdle()
	{
		self.ResetEmptySound();

		if( self.m_flTimeWeaponIdle > g_Engine.time )
			return;

		EndAttack();
		m_bShootingSound = false;
		g_SoundSystem.StopSound( m_pPlayer.edict(), CHAN_WEAPON, arrsQ2WSounds[SND_SHOOT] );

		self.SendWeaponAnim( ANIM_IDLE, 0, GetBodygroup() );
		self.m_flTimeWeaponIdle = g_Engine.time + Q2W_TIME_IDLE;
	}

	void ItemPostFrame()
	{
		if( (m_pPlayer.pev.button & IN_ATTACK) == 0 )
			m_bInAttack = false;

		if( m_bInAttack )
		{
			Math.MakeVectors( m_pPlayer.pev.v_angle + m_pPlayer.pev.punchangle );
			Vector vecMuzzle = m_pPlayer.GetGunPosition();

			float flDamage = q2::PVP ? Q2W_DAMAGE_DM : Q2W_DAMAGE_SP;
			if( self.m_flCustomDmg > 0 )
				flDamage = self.m_flCustomDmg;

			if( CheckQuadDamage() )
			{
				flDamage *= 4;
				g_SoundSystem.EmitSoundDyn( m_pPlayer.edict(), CHAN_ITEM, arrsQ2WSounds[SND_QUAD_FIRE], VOL_NORM, ATTN_NORM );
			}

			fire_heatbeam( vecMuzzle, g_Engine.v_forward, flDamage, 100 );
		}

		BaseClass.ItemPostFrame();
	}

	void fire_heatbeam( Vector vecStart, Vector vecAimdir, float flDamage, int iKick )
	{
		TraceResult tr;
		Vector vecEnd;
		Vector vecWaterStart;
		bool bWater = false, bUnderwater = false;

		vecEnd = vecStart + vecAimdir * 8192;

		if( g_EngineFuncs.PointContents(vecStart) == CONTENTS_WATER )
		{
			bUnderwater = true;
			vecWaterStart = vecStart;
		}

		g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, m_pPlayer.edict(), tr );

		if( m_flNextDamage < g_Engine.time )
		{
			// see if we hit water
			if( g_EngineFuncs.PointContents(tr.vecEndPos) == CONTENTS_WATER )
			{
				bWater = true;
				vecWaterStart = tr.vecEndPos;

				if( vecStart != tr.vecEndPos )
				{
					NetworkMessage m1( MSG_PVS, NetworkMessages::SVC_TEMPENTITY, vecWaterStart );
						m1.WriteByte( TE_PARTICLEBURST );
						m1.WriteCoord( vecWaterStart.x );
						m1.WriteCoord( vecWaterStart.y );
						m1.WriteCoord( vecWaterStart.z );
						m1.WriteShort( 1 ); //radius
						m1.WriteByte( 128 ); //color
						m1.WriteByte( 1 ); //duration
					m1.End();
				}
			}

			if( bWater )
				flDamage /= 2;

			if( tr.pHit !is null and g_EngineFuncs.PointContents(tr.vecEndPos) != CONTENTS_SKY )
			{
				if( tr.flFraction < 1.0 )
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( pHit.pev.takedamage != DAMAGE_NO )
						q2::T_Damage( pHit, m_pPlayer, m_pPlayer, vecAimdir, tr.vecEndPos, tr.vecPlaneNormal, flDamage, iKick, DMG_ENERGYBEAM );
					else
					{
						if( !bWater )
						{
							for( uint i = 0; i < 2; ++i )
								g_Utility.Sparks( tr.vecEndPos );

							g_SoundSystem.PlaySound( null, CHAN_AUTO, arrsQ2WSounds[SND_LASERHIT], 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, tr.vecEndPos );

							//PlayerNoise( m_pPlayer, tr.vecEndPos, PNOISE_IMPACT );
						}
					}
				}
			}

			if( bWater or bUnderwater )
			{
				g_Utility.BubbleTrail( vecWaterStart, tr.vecEndPos, 8 );

				g_SoundSystem.PlaySound( null, CHAN_AUTO, arrsQ2WSounds[SND_LASERHIT], 0.5, ATTN_NORM, 0, PITCH_NORM, 0, true, tr.vecEndPos );
			}

			m_flNextDamage = g_Engine.time + 0.1;
		}

		UpdateBeam( tr.vecEndPos );
	}

	void UpdateBeam( const Vector &in endPoint )
	{
		if( m_pBeam is null )
			CreateBeam();

		m_pBeam.SetColor( int(arrvecBeamColors[m_uiBeamColorIndex].x), int(arrvecBeamColors[m_uiBeamColorIndex].y), int(arrvecBeamColors[m_uiBeamColorIndex].z) );
		m_uiBeamColorIndex++;

		if( m_uiBeamColorIndex >= arrvecBeamColors.length() )
			m_uiBeamColorIndex = 0;

		m_pBeam.SetStartPos( endPoint );
	}

	void CreateBeam()
	{
		DestroyBeam();

		@m_pBeam = g_EntityFuncs.CreateBeam( SPRITE_BEAM, 20 );
		m_pBeam.PointEntInit( pev.origin, m_pPlayer.entindex() );
		m_pBeam.SetScrollRate( 20 );
		m_pBeam.SetBrightness( 128 );
		m_pBeam.SetColor( 255, 255, 39 );
		m_pBeam.SetEndAttachment( 1 );
		m_pBeam.pev.spawnflags |= SF_BEAM_TEMPORARY;
	}

	void DestroyBeam()
	{
		if( m_pBeam !is null )
			g_EntityFuncs.Remove( m_pBeam );
	}

	void EndAttack()
	{
		m_bInAttack = false;
		m_uiBeamColorIndex = 0;
		DestroyBeam();
	}

	private int GetBodygroup()
	{
		int iBodyState = (m_pPlayer.pev.button & IN_ATTACK == 0) ? 0 : 1;
		m_iBodyConfig = g_ModelFuncs.SetBodygroup( g_ModelFuncs.ModelIndex(MODEL_VIEW), m_iBodyConfig, 0, iBodyState );

		return m_iBodyConfig;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2plasmabeam::weapon_q2plasmabeam", WEAPON_NAME );
	g_ItemRegistry.RegisterWeapon( WEAPON_NAME, "quake2/weapons", "q2cells" );
}

} //namespace q2plasmabeam END
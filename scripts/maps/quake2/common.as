#include "ammo"
#include "items"
#include "weapons/projectiles"
#include "weapons/weapon_q2blaster"
#include "weapons/weapon_q2shotgun"
#include "weapons/weapon_q2supershotgun"
#include "weapons/weapon_q2machinegun"
#include "weapons/weapon_q2chaingun"
#include "weapons/weapon_q2glauncher"
#include "weapons/weapon_q2grenade"
#include "weapons/weapon_q2rlauncher"
#include "weapons/weapon_q2hyperblaster"
#include "weapons/weapon_q2railgun"
#include "weapons/weapon_q2bfg"

const int ITEM_LEVITATE_HEIGHT = 36;
const int PLAYER_MAX_HEALTH = 100;
const int PLAYER_MAX_ARMOR = 100;
const uint8 Q2_FALLDAMAGE = 1;

const array<string> pStepSounds = 
{
	"quake2/player/step1.wav",
	"quake2/player/step2.wav",
	"quake2/player/step3.wav",
	"quake2/player/step4.wav"
};

void q2_InitCommon()
{
	q2_PrecachePlayerSounds();
	q2_RegisterProjectiles();
	q2_RegisterAmmo();
	q2_RegisterItems();
	q2_RegisterWeapon_BLASTER();
	q2_RegisterWeapon_SUPERSHOTGUN();
	q2_RegisterWeapon_SHOTGUN();
	q2_RegisterWeapon_MACHINEGUN();
	q2_RegisterWeapon_CHAINGUN();
	q2_RegisterWeapon_GRENADELAUNCHER();
	q2_RegisterWeapon_GRENADE();
	q2_RegisterWeapon_ROCKETLAUNCHER();
	q2_RegisterWeapon_HYPERBLASTER();
	q2_RegisterWeapon_RAILGUN();
	q2_RegisterWeapon_BFG();

	g_Hooks.RegisterHook( Hooks::Player::PlayerSpawn, @q2_PlayerSpawn );
	g_Hooks.RegisterHook( Hooks::Player::PlayerKilled, @q2_PlayerKilled );
	g_Hooks.RegisterHook( Hooks::Player::PlayerPostThink, @q2_PlayerPostThink );
}

HookReturnCode q2_PlayerSpawn(CBasePlayer@ pPlayer)
{
	q2_SetAmmoCaps( pPlayer );
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );
	pCustom.SetKeyvalue( "$fl_lastPain", 0.0f );

	return HOOK_CONTINUE;
}

HookReturnCode q2_PlayerKilled( CBasePlayer@ pPlayer, CBaseEntity@ pAttacker, int iGib )
{
	if( pPlayer.pev.health > -30 )
	{
		if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "quake2/player/female/drown1.wav", 1, ATTN_NORM );
		}
		else
		{
			int iNum = Math.RandomLong( 1, 4 );
			string sName = "quake2/player/female/death" + string(iNum) + ".wav";
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
		}	
	}
/*
	// spawn a backpack, moving player's weapon and ammo into it
	item_qbackpack@ pPack = q1_SpawnBackpack(pPlayer);
	@pPack.m_pWeapon = @pPlayer.m_pActiveItem;
	pPlayer.RemovePlayerItem(pPlayer.m_pActiveItem);
	pPack.m_iAmmoShells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"));
	pPack.m_iAmmoNails = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"));
	pPack.m_iAmmoRockets = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"));
	pPack.m_iAmmoCells = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"));
	pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("buckshot"), 0);
	pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("bolts"), 0);
	pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("rockets"), 0);
	pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("uranium"), 0);
	if (pPack.m_pWeapon is null && pPack.m_iAmmoShells == 0 && pPack.m_iAmmoNails == 0 && pPack.m_iAmmoRockets == 0 && pPack.m_iAmmoCells == 0)
		g_EntityFuncs.Remove(pPack.self);
*/
	return HOOK_CONTINUE;
}

HookReturnCode q2_PlayerPostThink( CBasePlayer@ pPlayer )
{
	q2_doFallDamage( EHandle(pPlayer) );
	q2_PlayPlayerPainSounds( EHandle(pPlayer) );
	q2_PlayPlayerJumpSounds( EHandle(pPlayer) );

	return HOOK_CONTINUE;
}

void q2_doFallDamage( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	if( pPlayer.pev.FlagBitSet(FL_ONGROUND) && pPlayer.pev.health > 0 && pPlayer.m_flFallVelocity >= 350.0f )
	{
		//g_Game.AlertMessage( at_console, "falling %1\n", pPlayer.m_flFallVelocity );

		if( g_EngineFuncs.PointContents(pPlayer.pev.origin) == CONTENTS_WATER )
		{
			g_Game.AlertMessage( at_console, "in water!\n"  );
			// Did he hit the world or a non-moving entity?
			// BUG - this happens all the time in water, especially when 
			// BUG - water has current force
			// if ( !pev.groundentity || VARS(pev.groundentity).velocity.z == 0 )
				// EMIT_SOUND(ENT(pev), CHAN_BODY, "player/pl_wade1.wav", 1, ATTN_NORM);
		}
		else if( pPlayer.m_flFallVelocity > 580 )
		{
			
			float flFallDamage;
			
			switch( Q2_FALLDAMAGE )
			{
				case 0: flFallDamage = 10; break;
				case 1:
					pPlayer.m_flFallVelocity -= 580;
					flFallDamage = pPlayer.m_flFallVelocity * 0.25f;
				break;
			}			

			if( flFallDamage > pPlayer.pev.health )
			{
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, "quake2/gib.wav", 1, ATTN_NORM );
			}

			if( flFallDamage > 0 )
			{
				pPlayer.TakeDamage( g_EntityFuncs.Instance(0).pev, g_EntityFuncs.Instance(0).pev, flFallDamage, flFallDamage > pPlayer.pev.health ? (DMG_FALL|DMG_ALWAYSGIB) : DMG_FALL );
				pPlayer.pev.punchangle.x = 0;
			}
		}
    }

	if( pPlayer.pev.FlagBitSet(FL_ONGROUND) )
	{		
		if( pPlayer.m_flFallVelocity > 64 )
		{
			//CSoundEnt::InsertSound ( bits_SOUND_PLAYER, pev.origin, pPlayer.m_flFallVelocity, 0.2 );
			if( pPlayer.m_flFallVelocity < 347 )
				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, pStepSounds[Math.RandomLong(0,3)], 1, ATTN_NORM );

			//g_Game.AlertMessage( at_console, "landed %1\n", pPlayer.m_flFallVelocity );
		}

		if( pPlayer.m_flFallVelocity > 347 )
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_BODY, "quake2/player/land1.wav", 1, ATTN_NORM );

			pPlayer.m_flFallVelocity = 0;
	}
}

void q2_PlayPlayerPainSounds( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flLastHealth = pCustom.GetKeyvalue("$fl_lastHealth").GetFloat();
	float flLastPain = pCustom.GetKeyvalue("$fl_lastPain").GetFloat();

	//if( flLastHealth <= pPlayer.pev.health ) return;
	pCustom.SetKeyvalue( "$fl_lastHealth", pPlayer.pev.health );
	if( flLastPain > g_Engine.time ) return;
	if( pPlayer.pev.health <= 0 ) return;

	float flDmg = pPlayer.m_lastPlayerDamageAmount;
	if( flDmg < 5.0f || (flLastHealth - pPlayer.pev.health < 5.0f) ) return;

	int iDmgType = pPlayer.m_bitsDamageType;
	string sName;
	if( (iDmgType & DMG_BURN) != 0 || (iDmgType & DMG_ACID) != 0 )
	{
		sName = "quake2/player/burn" + string( Math.RandomLong(1, 2) ) + ".wav";
	}
	else if( (iDmgType & DMG_FALL) != 0 )
	{
		if( flDmg >= 55.0f )
			sName = "quake2/player/female/fall1.wav";
		else
			sName = "quake2/player/female/fall2.wav";
	}
	else
	{
		int l;
		int r = Math.RandomLong(1, 2);
		if( pPlayer.pev.health < 25 )
			l = 25;
		else if( pPlayer.pev.health < 50 )
			l = 50;
		else if( pPlayer.pev.health < 75 )
			l = 75;
		else
			l = 100;

		sName = "quake2/player/female/pain" + string(l) + "_" + string(r) + ".wav";
	}

	pCustom.SetKeyvalue( "$fl_lastPain", g_Engine.time + 0.7f );
	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, sName, 1, ATTN_NORM );
}

void q2_PlayPlayerJumpSounds( EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );

	if( !pPlayer.IsAlive() ) return;

	if( (pPlayer.m_afButtonPressed & IN_JUMP) != 0 && (pPlayer.pev.waterlevel < WATERLEVEL_WAIST) )
	{
		TraceResult tr;
		g_Utility.TraceHull( pPlayer.pev.origin, pPlayer.pev.origin + Vector(0, 0, -5), dont_ignore_monsters, human_hull, pPlayer.edict(), tr );

		if( tr.flFraction < 1.0 )
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_VOICE, "quake2/player/female/jump1.wav", 1, ATTN_NORM );
	}
}

void q2_PrecachePlayerSounds()
{
	g_SoundSystem.PrecacheSound( "quake2/player/burn1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/burn2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/land1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/land1.wav" );
	for( uint i = 0; i < pStepSounds.length(); i++ )
		g_SoundSystem.PrecacheSound( pStepSounds[i] );

	g_SoundSystem.PrecacheSound( "quake2/player/female/pain100_1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain100_2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain75_1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain75_2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain50_1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain50_2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain25_1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/pain25_2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/fall1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/fall2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/death1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/death2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/death3.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/death4.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/drown1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/player/female/jump1.wav" );

	g_SoundSystem.PrecacheSound( "quake2/null.wav" );
	g_SoundSystem.PrecacheSound( "quake2/gib.wav" );
	g_SoundSystem.PrecacheSound( "quake2/misc/talk.wav" );
}

void q2_CreatePelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
	TraceResult tr;	
	float x, y;
	
	for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
	{
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
				+ x * vecSpread.x * g_Engine.v_right 
				+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 2048;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );

				if( pHit.pev.classname == "func_door" || pHit.pev.classname == "func_door_rotating" )
				{
					g_Utility.Sparks( tr.vecEndPos );
					/*NetworkMessage sparks( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
						sparks.WriteByte( TE_GUNSHOT );
						sparks.WriteCoord( tr.vecEndPos.x );
						sparks.WriteCoord( tr.vecEndPos.y );
						sparks.WriteCoord( tr.vecEndPos.z );
					sparks.End();*/

					NetworkMessage sparks( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
						sparks.WriteByte( TE_PARTICLEBURST );
						sparks.WriteCoord( tr.vecEndPos.x );
						sparks.WriteCoord( tr.vecEndPos.y );
						sparks.WriteCoord( tr.vecEndPos.z );
						sparks.WriteShort( 1 );//radius
						sparks.WriteByte( 255 );//color
						sparks.WriteByte( 1 );//duration
					sparks.End();
				}
			}
		}
	}
}

void q2_CreateShotgunPelletDecals( const Vector& in vecSrc, const Vector& in vecAiming, const Vector& in vecSpread, const uint uiPelletCount, int iDamage, EHandle& in ePlayer )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( ePlayer.GetEntity() );
	TraceResult tr;	
	float x, y;

	for( uint uiPellet = 0; uiPellet < uiPelletCount; ++uiPellet )
	{
		g_Utility.GetCircularGaussianSpread( x, y );
		
		Vector vecDir = vecAiming 
				+ x * vecSpread.x * g_Engine.v_right 
				+ y * vecSpread.y * g_Engine.v_up;

		Vector vecEnd	= vecSrc + vecDir * 2048;

		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, pPlayer.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			if( tr.pHit !is null )
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					g_WeaponFuncs.DecalGunshot( tr, BULLET_PLAYER_BUCKSHOT );
				
				if( pHit.pev.takedamage != DAMAGE_NO && pHit.IsAlive() == true )
				{
					g_WeaponFuncs.ClearMultiDamage();
					pHit.TraceAttack( pPlayer.pev, iDamage, vecDir, tr, DMG_LAUNCH ); 
					g_WeaponFuncs.ApplyMultiDamage( pPlayer.pev, pPlayer.pev );
				}	
				
				if( pHit.pev.classname == "func_door" || pHit.pev.classname == "func_door_rotating" )
				{
					g_Utility.Sparks( tr.vecEndPos );
					/*NetworkMessage sparks( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
						sparks.WriteByte( TE_GUNSHOT );
						sparks.WriteCoord( tr.vecEndPos.x );
						sparks.WriteCoord( tr.vecEndPos.y );
						sparks.WriteCoord( tr.vecEndPos.z );
					sparks.End();*/

					NetworkMessage sparks( MSG_PVS, NetworkMessages::SVC_TEMPENTITY );
						sparks.WriteByte( TE_PARTICLEBURST );
						sparks.WriteCoord( tr.vecEndPos.x );
						sparks.WriteCoord( tr.vecEndPos.y );
						sparks.WriteCoord( tr.vecEndPos.z );
						sparks.WriteShort( 1 );//radius
						sparks.WriteByte( 255 );//color
						sparks.WriteByte( 1 );//duration
					sparks.End();
				}
			}
		}
	}
}
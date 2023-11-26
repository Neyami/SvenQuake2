#include "../maps/hunger/weapons/baseweapon"

#include "../maps/quake2/ammo"
#include "../maps/quake2/items"
#include "../maps/quake2/weapons/projectiles"
#include "../maps/quake2/weapons/weapon_q2bfg"
#include "../maps/quake2/weapons/weapon_q2blaster"
#include "../maps/quake2/weapons/weapon_q2chaingun"
#include "../maps/quake2/weapons/weapon_q2glauncher"
#include "../maps/quake2/weapons/weapon_q2grenade"
#include "../maps/quake2/weapons/weapon_q2hyperblaster"
#include "../maps/quake2/weapons/weapon_q2machinegun"
#include "../maps/quake2/weapons/weapon_q2railgun"
#include "../maps/quake2/weapons/weapon_q2rlauncher"
#include "../maps/quake2/weapons/weapon_q2shotgun"
#include "../maps/quake2/weapons/weapon_q2supershotgun"

const int ITEM_LEVITATE_HEIGHT = 36;
const int PLAYER_MAX_HEALTH = 100;
const int PLAYER_MAX_ARMOR = 100;

void PluginInit()
{
	g_Module.ScriptInfo.SetAuthor("Nero");
	g_Module.ScriptInfo.SetContactInfo("https://discord.gg/0wtJ6aAd7XOGI6vI");
}

void MapInit()
{
	q2_RegisterProjectiles();
	q2_RegisterAmmo();
	q2_RegisterWeapon_BLASTER();
	q2_RegisterWeapon_SHOTGUN();
	q2_RegisterWeapon_SUPERSHOTGUN();
	q2_RegisterWeapon_MACHINEGUN();
	q2_RegisterWeapon_CHAINGUN();
	q2_RegisterWeapon_GRENADE();
	q2_RegisterWeapon_GRENADELAUNCHER();
	q2_RegisterWeapon_ROCKETLAUNCHER();
	q2_RegisterWeapon_HYPERBLASTER();
	q2_RegisterWeapon_RAILGUN();
	q2_RegisterWeapon_BFG();
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

#include "enums"
#include "items/item_quad"
#include "items/item_invulnerability"
#include "items/item_silencer"
#include "items/item_breather"
#include "items/item_enviro"
#include "items/item_adrenaline"
#include "items/item_power_screen"
#include "items/item_power_shield"

namespace q2items
{

bool g_bRerelease;

const int ITEM_LEVITATE_HEIGHT		= 36;
const int PLAYER_MAX_HEALTH			= 100;

const int SF_NO_RESPAWN					= 1024;

const string SOUND_RESPAWN			= "quake2/items/respawn1.wav";

const string NAME_HEALTH_SMALL		= "item_health_small";
const string NAME_HEALTH_MEDIUM	= "item_health";
const string NAME_HEALTH_LARGE		= "item_health_large";
const string NAME_HEALTH_MEGA		= "item_health_mega";
const string NAME_ANCHIENT_HEAD	= "item_ancient_head";

const string NAME_ARMOR_SHARD		= "item_armor_shard";
const string NAME_ARMOR_JACKET		= "item_armor_jacket";
const string NAME_ARMOR_COMBAT	= "item_armor_combat";
const string NAME_ARMOR_BODY		= "item_armor_body";

const string NAME_BANDOLIER			= "item_bandolier";
const string NAME_PACK						= "item_pack";

const float WEAPON_RESPAWN_TIME	= 30.0;
const float AMMO_RESPAWN_TIME		= 30.0;
const float HEALTH_RESPAWN_TIME	= 30.0;
const float ARMOR_RESPAWN_TIME		= 20.0;

const string PARMOR_KVN					= "$i_q2powerarmor";
const string PARMOR_KVN_EFFECT		= "$f_q2parmoreffect";
const string MAX_HEALTH_KVN			= "$i_q2maxhealth";

//HACK because I don't like the inventory window
const string INVWEAP_NAME				= "weapon_q2inventory";

const int INVWEAP_SLOT					= 5;
const int INVWEAP_POSITION				= 12;
const int PSHIELD_SLOT						= 5;
const int PSHIELD_POSITION				= 13;
const int PSCREEN_SLOT					= 5;
const int PSCREEN_POSITION				= 14;
const int INVUL_SLOT							= 5;
const int INVUL_POSITION					= 15;
const int QUAD_SLOT							= 5;
const int QUAD_POSITION					= 16;
const int ENVIRO_SLOT						= 5;
const int ENVIRO_POSITION				= 17;
const int BREATHER_SLOT					= 5;
const int BREATHER_POSITION			= 18;
const int SILENCER_SLOT					= 5;
const int SILENCER_POSITION			= 19;
const int ADRENALINE_SLOT				= 5;
const int ADRENALINE_POSITION		= 20;

const int SILENCER_HUD_CHANNEL		= 15;
const int PARMOR_HUD_CHANNEL		= 14;
const int INVUL_HUD_CHANNEL			= 13;
const int QUAD_HUD_CHANNEL			= 12;
const int BREATHER_HUD_CHANNEL	= 11;
const int ENVIRO_HUD_CHANNEL		= 10;

//AMMO, AMMUNITION ITEMS
class ammo_q2shells : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2shells()
	{
		m_sModel = "models/quake2/items/ammo/shells.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2shells";
		m_iAmount = q2weapons::AMMO_SHELLS_GIVE;
		m_iAmountMax = q2weapons::AMMO_SHELLS_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

class ammo_q2bullets : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2bullets()
	{
		m_sModel = "models/quake2/items/ammo/bullets.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2bullets";
		m_iAmount = q2weapons::AMMO_BULLETS_GIVE;
		m_iAmountMax = q2weapons::AMMO_BULLETS_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

class ammo_q2grenades : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2grenades()
	{
		m_sModel = "models/quake2/items/ammo/grenades.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2grenades";
		m_iAmount = q2weapons::AMMO_GRENADES_GIVE;
		m_iAmountMax = q2weapons::AMMO_GRENADES_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

class ammo_q2rockets : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2rockets()
	{
		m_sModel = "models/quake2/items/ammo/rockets.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2rockets";
		m_iAmount = q2weapons::AMMO_ROCKETS_GIVE;
		m_iAmountMax = q2weapons::AMMO_ROCKETS_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

class ammo_q2cells : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2cells()
	{
		m_sModel = "models/quake2/items/ammo/cells.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2cells";
		m_iAmount = q2weapons::AMMO_CELLS_GIVE;
		m_iAmountMax = q2weapons::AMMO_CELLS_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

class ammo_q2slugs : ScriptBaseItemEntity, item_q2pickup
{
	ammo_q2slugs()
	{
		m_sModel = "models/quake2/items/ammo/slugs.mdl";
		m_sSound = "quake2/misc/am_pkup.wav";
		m_sAmmoName = "q2slugs";
		m_iAmount = q2weapons::AMMO_SLUGS_GIVE;
		m_iAmountMax = q2weapons::AMMO_SLUGS_MAX;
		m_flRespawnTime = AMMO_RESPAWN_TIME;
	}
}

//HEALTH ITEMS
final class item_health_small : ScriptBaseItemEntity, item_q2pickup
{
	item_health_small()
	{
		m_iItemID = IT_HEALTH_SMALL;
		m_sModel = "models/quake2/items/healing/stimpack.mdl";
		m_sSound = "quake2/items/s_health.wav";
		m_iAmount = 2;
		m_flRespawnTime = HEALTH_RESPAWN_TIME;
	}
}

final class item_health : ScriptBaseItemEntity, item_q2pickup
{
	item_health()
	{
		m_iItemID = IT_HEALTH_MEDIUM;
		m_sModel = "models/quake2/items/healing/medium.mdl";
		m_sSound = "quake2/items/n_health.wav";
		m_iAmount = 10;
		m_flRespawnTime = HEALTH_RESPAWN_TIME;
	}
}

final class item_health_large : ScriptBaseItemEntity, item_q2pickup
{
	item_health_large()
	{
		m_iItemID = IT_HEALTH_LARGE;
		m_sModel = "models/quake2/items/healing/large.mdl";
		m_sSound = "quake2/items/l_health.wav";
		m_iAmount = 25;
		m_flRespawnTime = HEALTH_RESPAWN_TIME;
	}
}

final class item_health_mega : ScriptBaseItemEntity, item_q2pickup
{
	item_health_mega()
	{
		m_iItemID = IT_HEALTH_MEGA;
		m_sModel = "models/quake2/items/mega_h.mdl";
		m_sSound = "quake2/items/m_health.wav";
		m_iAmount = 100;
		m_flRespawnTime = HEALTH_RESPAWN_TIME/3; //from when the last player who picked it up has gone back to normal health or died
	}
}

final class item_ancient_head : ScriptBaseItemEntity, item_q2pickup
{
	item_ancient_head()
	{
		m_iItemID = IT_ITEM_ANCIENT_HEAD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/c_head.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = HEALTH_RESPAWN_TIME*2;
	}
}

//ARMOR ITEMS
final class item_armor_shard : ScriptBaseItemEntity, item_q2pickup
{
	item_armor_shard()
	{
		m_iItemID = IT_ARMOR_SHARD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/armor/shard.mdl";
		m_sSound = "quake2/misc/ar2_pkup.wav";
		m_iAmount = 2;
		m_flRespawnTime = ARMOR_RESPAWN_TIME;
	}
}

final class item_armor_jacket : ScriptBaseItemEntity, item_q2pickup
{
	item_armor_jacket()
	{
		m_iItemID = IT_ARMOR_JACKET;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/armor/jacket.mdl";
		m_sSound = "quake2/misc/ar1_pkup.wav";
		m_iAmount = 25;
		m_iAmountMax = 50;
		m_flRespawnTime = ARMOR_RESPAWN_TIME;
	}
}

final class item_armor_combat : ScriptBaseItemEntity, item_q2pickup
{
	item_armor_combat()
	{
		m_iItemID = IT_ARMOR_COMBAT;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/armor/combat.mdl";
		m_sSound = "quake2/misc/ar1_pkup.wav";
		m_iAmount = 50;
		m_iAmountMax = 100;
		m_flRespawnTime = ARMOR_RESPAWN_TIME;
	}
}

final class item_armor_body : ScriptBaseItemEntity, item_q2pickup
{
	item_armor_body()
	{
		m_iItemID = IT_ARMOR_BODY;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/armor/body.mdl";
		m_sSound = "quake2/misc/ar3_pkup.wav";
		m_iAmount = 100;
		m_iAmountMax = 200;
		m_flRespawnTime = ARMOR_RESPAWN_TIME;
	}
}

//WEAPON PICKUPS
final class item_q2shotgun : ScriptBaseItemEntity, item_q2pickup
{
	item_q2shotgun()
	{
		m_sWeaponName = q2shotgun::WEAPON_NAME;
		m_sModel = q2shotgun::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2supershotgun : ScriptBaseItemEntity, item_q2pickup
{
	item_q2supershotgun()
	{
		m_sWeaponName = q2supershotgun::WEAPON_NAME;
		m_sModel = q2supershotgun::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2machinegun : ScriptBaseItemEntity, item_q2pickup
{
	item_q2machinegun()
	{
		m_sWeaponName = q2machinegun::WEAPON_NAME;
		m_sModel = q2machinegun::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2chaingun : ScriptBaseItemEntity, item_q2pickup
{
	item_q2chaingun()
	{
		m_sWeaponName = q2chaingun::WEAPON_NAME;
		m_sModel = q2chaingun::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2grenades : ScriptBaseItemEntity, item_q2pickup
{
	item_q2grenades()
	{
		m_sWeaponName = q2grenades::WEAPON_NAME;
		m_sModel = q2grenades::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2grenadelauncher : ScriptBaseItemEntity, item_q2pickup
{
	item_q2grenadelauncher()
	{
		m_sWeaponName = q2grenadelauncher::WEAPON_NAME;
		m_sModel = q2grenadelauncher::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2rocketlauncher : ScriptBaseItemEntity, item_q2pickup
{
	item_q2rocketlauncher()
	{
		m_sWeaponName = q2rocketlauncher::WEAPON_NAME;
		m_sModel = q2rocketlauncher::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2hyperblaster : ScriptBaseItemEntity, item_q2pickup
{
	item_q2hyperblaster()
	{
		m_sWeaponName = q2hyperblaster::WEAPON_NAME;
		m_sModel = q2hyperblaster::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2railgun : ScriptBaseItemEntity, item_q2pickup
{
	item_q2railgun()
	{
		m_sWeaponName = q2railgun::WEAPON_NAME;
		m_sModel = q2railgun::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

final class item_q2bfg : ScriptBaseItemEntity, item_q2pickup
{
	item_q2bfg()
	{
		m_sWeaponName = q2bfg::WEAPON_NAME;
		m_sModel = q2bfg::MODEL_WORLD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sSound = "quake2/misc/w_pkup.wav";
		m_flRespawnTime = WEAPON_RESPAWN_TIME;
	}
}

//OTHER ITEMS
final class item_bandolier : ScriptBaseItemEntity, item_q2pickup
{
	item_bandolier()
	{
		m_iItemID = IT_ITEM_BANDOLIER;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/bandolier.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_iAmount = 60;
		m_iAmountMax = 150; //shells, only used for checking
		m_flRespawnTime = 60.0;
	}
}

final class item_pack : ScriptBaseItemEntity, item_q2pickup
{
	item_pack()
	{
		m_iItemID = IT_ITEM_PACK;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/pack.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_iAmount = 180;
		m_iAmountMax = 200; //shells, only used for checking
		m_flRespawnTime = 60.0;
	}
}

/*final class item_template : ScriptBaseItemEntity, item_q2pickup
{
	item_template()
	{
		m_iItemID = IT_NULL;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/template.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = 60.0;
	}
}*/

mixin class item_q2pickup
{
	protected string m_sModel;
	protected string m_sSound;
	protected string m_sWeaponName = "";
	protected string m_sAmmoName = "";

	protected int m_iAmount;
	protected int m_iAmountMax;
	protected float m_flRespawnTime = 2; //20

	protected int m_iWorldModelFlags = 0;
	protected int m_iItemID;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "m_flCustomRespawnTime" )
		{
			if( atof(szValue) >= 0.0 )
				m_flRespawnTime = atof(szValue);

			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_sModel );

		BaseClass.Spawn();

		if( !m_sWeaponName.IsEmpty() )
		{
			pev.body = 1;
			SetTouch( TouchFunction(this.WeaponTouch) );
		}
		else if( !m_sAmmoName.IsEmpty() )
			SetTouch( TouchFunction(this.AmmoTouch) );
		else
			SelectTouchFunction();

		if( (m_iWorldModelFlags & EF_ROTATE) != 0 )
		{
			TraceResult tr;
			Vector vecStart = pev.origin;
			Vector vecEnd = vecStart + Vector( 0, 0, -72 );
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );

			if( tr.flFraction < 1.0 )
			{
				if (tr.pHit !is null)
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );

					if( pHit is null or pHit.IsBSPModel() )
					{
						Vector vecOrigin = pev.origin;
						vecOrigin.z = tr.vecEndPos.z + ITEM_LEVITATE_HEIGHT;
						g_EntityFuncs.SetOrigin( self, vecOrigin );
					}
				}
			}

			SetThink( ThinkFunction(this.RotateThink) );
			pev.nextthink = g_Engine.time + 0.01;
		}

		if( (m_iWorldModelFlags & EF_BOB) != 0 )
		{
			pev.movetype = MOVETYPE_TOSS;
			pev.gravity = 0.5;
		}
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );

		g_SoundSystem.PrecacheSound( SOUND_RESPAWN );
		g_SoundSystem.PrecacheSound( m_sSound );
	}

	void RotateThink()
	{
        pev.angles.y += 1.0;

		if( (m_iWorldModelFlags & EF_BOB) != 0 and g_bRerelease )
		{
			//HACK
			if( pev.velocity.z == 0.0 )
				pev.velocity.z = 200.0;
			//scale = 0.005 + cent->currentState.number * 0.00001;
			//cent->lerpOrigin[2] += 4 + cos( ( cg.time + 1000 ) *  scale ) * 4;

			/*float flCurrentTime = g_Engine.time * 1000; // Convert to milliseconds
			float flScale = 0.005 + self.entindex() * 0.00001;
			float flBobOffset = 4 + cos((flCurrentTime + 1000) * flScale) * 4;
			//g_Game.AlertMessage( at_notice, "flBobOffset: %1\n", flBobOffset );

			Vector vecOrigin = pev.origin;
			//if( flBobOffset >= 5.0 )
			{
				vecOrigin.z += flBobOffset;
				g_EntityFuncs.SetOrigin( self, vecOrigin );
			}

			pev.velocity.z -= pev.gravity * g_EngineFuncs.CVarGetFloat("sv_gravity") * 0.1; //FRAMETIME;*/
		}

		pev.nextthink = g_Engine.time + 0.01;
	}

	void MegaHealthThink()
	{
		pev.nextthink = g_Engine.time + 1.0;

		CBasePlayer@ pOwner = cast<CBasePlayer@>( g_EntityFuncs.Instance(pev.owner) );

		if( pOwner is null or !pOwner.IsConnected() or pOwner.pev.deadflag != DEAD_NO or pOwner.pev.health <= pOwner.pev.max_health )
		{
			@pev.owner = null;

			if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
				SetupRespawn();
			else
				g_EntityFuncs.Remove( self );
		}
	}

	void HealthTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CustomKeyvalues@ pCustom = pOther.GetCustomKeyvalues();
		float flPlayerMaxHealth = PLAYER_MAX_HEALTH + pCustom.GetKeyvalue(MAX_HEALTH_KVN).GetInteger();

		if( m_iItemID != IT_HEALTH_SMALL and m_iItemID != IT_HEALTH_MEGA )
		{
			if( pOther.pev.health >= flPlayerMaxHealth )
				return;
		}

		pOther.pev.health += m_iAmount;

		if( pOther.pev.health > PLAYER_MAX_HEALTH )
		{
			if( m_iItemID != IT_HEALTH_SMALL and m_iItemID != IT_HEALTH_MEGA )
			{
				pOther.pev.max_health = flPlayerMaxHealth;
				pOther.pev.health = flPlayerMaxHealth;
			}
			else if( m_iItemID == IT_HEALTH_SMALL )
				pOther.pev.max_health = flPlayerMaxHealth + m_iAmount;
			else if( m_iItemID == IT_HEALTH_MEGA )
				pOther.pev.max_health = flPlayerMaxHealth;
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::ItemPickup, pOther.edict() );
			m1.WriteString( string(pev.classname) );
		m1.End();

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( m_iItemID != IT_HEALTH_MEGA )
		{
			if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
				SetupRespawn();
			else
				g_EntityFuncs.Remove( self );
		}
		else
		{
			SetupRespawn( false );

			@pev.owner = pOther.edict();
			SetThink( ThinkFunction(this.MegaHealthThink) );
			pev.nextthink = g_Engine.time + 5.0;
		}
	}

	void ArmorTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		if( m_iItemID != IT_ARMOR_SHARD )
		{
			if( pOther.pev.armorvalue >= m_iAmountMax )
				return;
		}

		pOther.pev.armorvalue += m_iAmount;

		if( m_iItemID != IT_ARMOR_BODY )
		{
			if( pOther.pev.armorvalue > m_iAmountMax )
			{
				if( m_iItemID != IT_ARMOR_SHARD )
					pOther.pev.armorvalue = m_iAmountMax;
				else
					pOther.pev.armortype += m_iAmount;
			}
		}
		else
		{
			if( pOther.pev.armorvalue > m_iAmountMax )
			{
				pOther.pev.armorvalue = m_iAmountMax;
				pOther.pev.armortype = m_iAmountMax;
			}
		}

		NetworkMessage m1( MSG_ONE, NetworkMessages::ItemPickup, pOther.edict() );
			m1.WriteString( string(pev.classname) );
		m1.End();

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void QuadTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(QUADWEAP_NAME) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( QUADWEAP_NAME );

		if( !pCustom.GetKeyvalue(QUAD_KVN).Exists() )
		{
			pCustom.InitializeKeyvalueWithDefault( QUAD_KVN );
			pCustom.InitializeKeyvalueWithDefault( QUAD_KVN_TIME );
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void InvulTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(INVULWEAP_NAME) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( INVULWEAP_NAME );

		if( !pCustom.GetKeyvalue(INVUL_KVN).Exists() )
		{
			pCustom.InitializeKeyvalueWithDefault( INVUL_KVN );
			pCustom.InitializeKeyvalueWithDefault( INVUL_KVN_TIME );
			pCustom.InitializeKeyvalueWithDefault( INVUL_KVN_SOUND );
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void SilencerTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(SILENCERWEAP_NAME) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( SILENCERWEAP_NAME );

		if( !pCustom.GetKeyvalue(SILENCER_KVN).Exists() )
			pCustom.InitializeKeyvalueWithDefault( SILENCER_KVN );

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void HealthBoostTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		//the original gets applied immediately
		if( m_iItemID == IT_ITEM_ADRENALINE )
		{
			if( q2items::g_bRerelease )
			{
				if( pPlayer.HasNamedPlayerItem(ADRENALINEWEAP_NAME) !is null )
					return;

				pPlayer.GiveNamedItem( ADRENALINEWEAP_NAME );
			}
			else
				ApplyAdrenaline( pPlayer );
		}
		else
		{
			int iAmount = 2;

			if( q2items::g_bRerelease )
			{
				iAmount = 5;
				pPlayer.pev.health += iAmount;
			}

			int iMaxHealthBoost = pCustom.GetKeyvalue(MAX_HEALTH_KVN).GetInteger();
			pCustom.SetKeyvalue( MAX_HEALTH_KVN, iMaxHealthBoost + iAmount );
			pPlayer.pev.max_health += iAmount;
		}

		if( !pCustom.GetKeyvalue(MAX_HEALTH_KVN).Exists() )
			pCustom.InitializeKeyvalueWithDefault( MAX_HEALTH_KVN );

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void RebreatherTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(BREATHERWEAP_NAME) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( BREATHERWEAP_NAME );

		if( !pCustom.GetKeyvalue(BREATHER_KVN).Exists() )
		{
			pCustom.InitializeKeyvalueWithDefault( BREATHER_KVN );
			pCustom.InitializeKeyvalueWithDefault( BREATHER_KVN_TIME );
			pCustom.InitializeKeyvalueWithDefault( BREATHER_KVN_SOUND );
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void EnvirosuitTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(ENVIROWEAP_NAME) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( ENVIROWEAP_NAME );

		if( !pCustom.GetKeyvalue(ENVIRO_KVN).Exists() )
		{
			pCustom.InitializeKeyvalueWithDefault( ENVIRO_KVN );
			pCustom.InitializeKeyvalueWithDefault( ENVIRO_KVN_TIME );
			pCustom.InitializeKeyvalueWithDefault( BREATHER_KVN_SOUND );
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void BandolierTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

		G_AdjustAmmoCap( pPlayer, "q2bullets", 250 );
		G_AdjustAmmoCap( pPlayer, "q2shells", 150 );
		G_AdjustAmmoCap( pPlayer, "q2cells", 250 );
		G_AdjustAmmoCap( pPlayer, "q2slugs", 75 );
		//G_AdjustAmmoCap( pPlayer, AMMO_MAGSLUG, 75 );
		//G_AdjustAmmoCap( pPlayer, AMMO_FLECHETTES, 250 );
		//G_AdjustAmmoCap( pPlayer, AMMO_DISRUPTOR, 21 );

		G_AddAmmoAndCapQuantity( pPlayer, "q2bullets" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2shells" );
 
		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void PackTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);

		G_AdjustAmmoCap( pPlayer, "q2bullets", 300 );
		G_AdjustAmmoCap( pPlayer, "q2shells", 200 );
		G_AdjustAmmoCap( pPlayer, "q2rockets", 100 );
		G_AdjustAmmoCap( pPlayer, "q2grenades", 100 );
		G_AdjustAmmoCap( pPlayer, "q2cells", 300 );
		G_AdjustAmmoCap( pPlayer, "q2slugs", 100 );
		//G_AdjustAmmoCap( pPlayer, AMMO_MAGSLUG, 100 );
		//G_AdjustAmmoCap( pPlayer, AMMO_FLECHETTES, 300 );
		//G_AdjustAmmoCap( pPlayer, AMMO_DISRUPTOR, 30 );

		G_AddAmmoAndCapQuantity( pPlayer, "q2bullets" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2shells" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2rockets" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2grenades" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2cells" );
		G_AddAmmoAndCapQuantity( pPlayer, "q2slugs" );
		//G_AddAmmoAndCapQuantity( pPlayer, AMMO_MAGSLUG );
		//G_AddAmmoAndCapQuantity( pPlayer, AMMO_FLECHETTES );
		//G_AddAmmoAndCapQuantity( pPlayer, AMMO_DISRUPTOR );
 
		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void ParmorTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( (pev.classname == PSCREENITEM_NAME and pPlayer.HasNamedPlayerItem(PSCREENWEAP_NAME) !is null) or (pev.classname == PSHIELDITEM_NAME and pPlayer.HasNamedPlayerItem(PSHIELDWEAP_NAME) !is null) )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( (pev.classname == PSCREENITEM_NAME) ? PSCREENWEAP_NAME : PSHIELDWEAP_NAME );

		if( !pCustom.GetKeyvalue(PARMOR_KVN).Exists() )
		{
			pCustom.InitializeKeyvalueWithDefault( PARMOR_KVN );
			pCustom.InitializeKeyvalueWithDefault( PARMOR_KVN_EFFECT );
		}

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	bool G_AddAmmoAndCap( CBasePlayer@ pPlayer, string sAmmoName, int iMax, int iQuantity )
	{
		pPlayer.GiveAmmo( iQuantity, sAmmoName, iMax );

		q2::G_CheckPowerArmor( EHandle(pPlayer) );

		return true;
	}

	bool G_AddAmmoAndCapQuantity( CBasePlayer@ pPlayer, string sAmmoName )
	{
		return G_AddAmmoAndCap( pPlayer, sAmmoName, pPlayer.GetMaxAmmo(sAmmoName), m_iAmount );
	}

	void G_AdjustAmmoCap( CBasePlayer@ pPlayer, string sAmmoName, int iNewMax )
	{
		pPlayer.SetMaxAmmo( sAmmoName, Math.max(pPlayer.GetMaxAmmo(sAmmoName), iNewMax) );
	}

	void WeaponTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>(pOther);
		if( pPlayer.HasNamedPlayerItem(m_sWeaponName) !is null )
			return;

		CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

		pPlayer.GiveNamedItem( m_sWeaponName );

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	void AmmoTouch( CBaseEntity@ pOther )
	{
		if( !pOther.IsPlayer() or !pOther.IsAlive() )
			return;

		if( !AddAmmo(pOther) )
			return;

		g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, m_sSound, VOL_NORM, ATTN_NORM );

		if( (pev.spawnflags & SF_NO_RESPAWN) == 0 )
			SetupRespawn();
		else
			g_EntityFuncs.Remove( self );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( pOther.GiveAmmo(m_iAmount, m_sAmmoName, m_iAmountMax) != -1 )
			return true;

		return false;
	}

	void SetupRespawn( bool bSetThink = true )
	{
		SetTouch( null );
		pev.effects |= EF_NODRAW;

		g_EntityFuncs.SetOrigin( self, pev.origin );

		if( bSetThink )
		{
			SetThink( ThinkFunction(this.Materialize) );
			pev.nextthink = g_Engine.time + m_flRespawnTime;
		}
	}

	void Materialize()
	{
		if( (pev.effects & EF_NODRAW) != 0 )
		{
			g_SoundSystem.EmitSound( self.edict(), CHAN_WEAPON, SOUND_RESPAWN, VOL_NORM, ATTN_NORM );
			pev.effects &= ~EF_NODRAW;
			pev.effects |= EF_MUZZLEFLASH;
		}

		if( !m_sWeaponName.IsEmpty() )
			SetTouch( TouchFunction(this.WeaponTouch) );
		else if( !m_sAmmoName.IsEmpty() )
			SetTouch( TouchFunction(this.AmmoTouch) );
		else
			SelectTouchFunction();

		if( (m_iWorldModelFlags & EF_ROTATE) != 0 )
		{
			SetThink( ThinkFunction(this.RotateThink) );
			pev.nextthink = g_Engine.time;
		}
	}

	void SelectTouchFunction( bool bRespawn = false )
	{
		switch( m_iItemID )
		{
			case IT_ITEM_QUAD:
			{
				SetTouch( TouchFunction(this.QuadTouch) );
				break;
			}

			case IT_ITEM_INVULNERABILITY:
			{
				SetTouch( TouchFunction(this.InvulTouch) );
				break;
			}

			case IT_ITEM_SILENCER:
			{
				SetTouch( TouchFunction(this.SilencerTouch) );
				break;
			}

			case IT_ITEM_BANDOLIER:
			{
				SetTouch( TouchFunction(this.BandolierTouch) );
				break;
			}

			case IT_ITEM_PACK:
			{
				SetTouch( TouchFunction(this.PackTouch) );
				break;
			}

			case IT_ITEM_POWER_SCREEN:
			case IT_ITEM_POWER_SHIELD:
			{
				SetTouch( TouchFunction(this.ParmorTouch) );
				break;
			}

			case IT_ITEM_REBREATHER:
			{
				SetTouch( TouchFunction(this.RebreatherTouch) );
				break;
			}

			case IT_ITEM_ENVIROSUIT:
			{
				SetTouch( TouchFunction(this.EnvirosuitTouch) );
				break;
			}

			case IT_ARMOR_BODY:
			case IT_ARMOR_COMBAT:
			case IT_ARMOR_JACKET:
			case IT_ARMOR_SHARD:
			{
				SetTouch( TouchFunction(this.ArmorTouch) );
				break;
			}

			case IT_HEALTH_SMALL:
			case IT_HEALTH_MEDIUM:
			case IT_HEALTH_LARGE:
			case IT_HEALTH_MEGA:
			{
				SetTouch( TouchFunction(this.HealthTouch) );

				//stop the rotation
				if( bRespawn )
					SetThink( null );

				break;
			}

			case IT_ITEM_ADRENALINE:
			case IT_ITEM_ANCIENT_HEAD:
			{
				SetTouch( TouchFunction(this.HealthBoostTouch) );
				break;
			}
		}
	}
}

class weapon_q2inventory : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		self.FallInit();
	}

	void Precache()
	{
		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + INVWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/weapon_q2inventory.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= INVWEAP_SLOT - 1;
		info.iPosition			= INVWEAP_POSITION - 1;
		info.iFlags 				= 0;
		info.iWeight			= 0; //-1 ??

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		return true;
	}

	bool Deploy() { return self.DefaultDeploy( "", "", 0, "" ); }

	CBasePlayerItem@ DropItem() { return null; }

	void Think()
	{
		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		BaseClass.Think();
	}
}

void UpdatePowerArmorHUD( CBasePlayer@ pPlayer )
{
	HUDNumDisplayParams hudParams;
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	if( q2::PowerArmorType(pPlayer) == q2items::POWER_ARMOR_NONE )
	{
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::PARMOR_HUD_CHANNEL, false );
		return;
	}
	else if( q2::PowerArmorType(pPlayer) == q2items::POWER_ARMOR_SCREEN )
		q2items::GetHudParams( pPlayer, q2items::IT_ITEM_POWER_SCREEN, hudParams );
	else if( q2::PowerArmorType(pPlayer) == q2items::POWER_ARMOR_SHIELD )
		q2items::GetHudParams( pPlayer, q2items::IT_ITEM_POWER_SHIELD, hudParams );

	int iAmmo = pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex("q2cells") );
	if( iAmmo > 0 )
	{
		hudParams.value = iAmmo;
		g_PlayerFuncs.HudNumDisplay( pPlayer, hudParams );
	}
	else
		g_PlayerFuncs.HudToggleElement( pPlayer, q2items::PARMOR_HUD_CHANNEL, false );
}

void GetHudParams( CBasePlayer@ pPlayer, int iItem, HUDNumDisplayParams &out hudNumParams )
{
	hudNumParams.color1 = RGBA_SVENCOOP;

	switch( iItem )
	{
		case IT_ITEM_SILENCER:
		{
			hudNumParams.spritename = SILENCER_ICON;
			hudNumParams.channel = SILENCER_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_RIGHT_ALIGN | HUD_NUM_DONT_DRAW_ZERO; //HUD_ELEM_DEFAULT_ALPHA ??
			hudNumParams.x = 0.85;
			hudNumParams.y = 0.94;
			hudNumParams.defdigits = 2;
			hudNumParams.maxdigits = 2;

			break;
		}

		case IT_ITEM_REBREATHER:
		{
			hudNumParams.spritename = BREATHER_ICON;
			hudNumParams.channel = BREATHER_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_LEADING_ZEROS | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN;
			hudNumParams.x = -0.41;
			hudNumParams.y = 0.94;
			hudNumParams.defdigits = 2;
			hudNumParams.maxdigits = 2;
			hudNumParams.value = BREATHER_DURATION;

			break;
		}

		case IT_ITEM_ENVIROSUIT:
		{
			hudNumParams.spritename = ENVIRO_ICON;
			hudNumParams.channel = ENVIRO_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_LEADING_ZEROS | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN;
			hudNumParams.x = -0.41;
			hudNumParams.y = 0.89;
			hudNumParams.defdigits = 2;
			hudNumParams.maxdigits = 2;
			hudNumParams.value = ENVIRO_DURATION;

			break;
		}

		case IT_ITEM_POWER_SCREEN:
		case IT_ITEM_POWER_SHIELD:
		{
			hudNumParams.spritename = (iItem == IT_ITEM_POWER_SCREEN) ? PSCREEN_HUD_ICON : PSHIELD_HUD_ICON;
			hudNumParams.channel = PARMOR_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_LEADING_ZEROS;
			hudNumParams.x = -0.345;
			hudNumParams.y = 0.94;
			hudNumParams.defdigits = 3;
			hudNumParams.maxdigits = 3;
			hudNumParams.value = pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells"));

			break;
		}

		case IT_ITEM_INVULNERABILITY:
		{
			hudNumParams.spritename = INVUL_ICON;
			hudNumParams.channel = INVUL_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_LEADING_ZEROS | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN;
			hudNumParams.x = -0.5;
			hudNumParams.y = 0.94;
			hudNumParams.defdigits = 2;
			hudNumParams.maxdigits = 2;
			hudNumParams.value = INVUL_DURATION;

			break;
		}

		case IT_ITEM_QUAD:
		{
			hudNumParams.spritename = QUAD_ICON;
			hudNumParams.channel = QUAD_HUD_CHANNEL;
			hudNumParams.flags = HUD_ELEM_SCR_CENTER_X | HUD_NUM_RIGHT_ALIGN | HUD_NUM_LEADING_ZEROS | HUD_TIME_SECONDS | HUD_TIME_COUNT_DOWN;
			hudNumParams.x = 0.85;
			hudNumParams.y = 0.89;
			hudNumParams.defdigits = 2;
			hudNumParams.maxdigits = 2;

			break;
		}
	}
}

bool IsItemActive( CBasePlayer@ pPlayer, int iItem )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	switch( iItem )
	{
		case IT_ITEM_QUAD:
			return pCustom.GetKeyvalue(QUAD_KVN).GetInteger() >= 1;

		case IT_ITEM_INVULNERABILITY:
			return pCustom.GetKeyvalue(INVUL_KVN).GetInteger() >= 1;

		case IT_ITEM_SILENCER:
			return pCustom.GetKeyvalue(SILENCER_KVN).GetInteger() >= 1;

		case IT_ITEM_POWER_SCREEN:
		case IT_ITEM_POWER_SHIELD:
			return pCustom.GetKeyvalue(PARMOR_KVN).GetInteger() >= 1;

		case IT_ITEM_REBREATHER:
			return pCustom.GetKeyvalue(BREATHER_KVN).GetInteger() >= 1;

		case IT_ITEM_ENVIROSUIT:
			return pCustom.GetKeyvalue(ENVIRO_KVN).GetInteger() >= 1;
	}

	return false;
}

void InitializeItems()
{
	Register();
	g_Hooks.RegisterHook( Hooks::Player::PlayerTakeDamage, @q2items::PlayerTakeDamage );
}

HookReturnCode PlayerTakeDamage( DamageInfo@ pDamageInfo )
{
	if( pDamageInfo.bitsDamageType & (DMG_BURN | DMG_ACID) != 0 and pDamageInfo.pInflictor.pev.classname == "trigger_hurt" )
		return HOOK_CONTINUE;

	CustomKeyvalues@ pCustom = pDamageInfo.pVictim.GetCustomKeyvalues();

	if( pCustom.GetKeyvalue(INVUL_KVN).GetInteger() >= 1 )
	{
		if( pCustom.GetKeyvalue(INVUL_KVN_SOUND).GetFloat() < g_Engine.time )
		{
			g_SoundSystem.EmitSound( pDamageInfo.pVictim.edict(), CHAN_ITEM, "quake2/items/protect4.wav", VOL_NORM, ATTN_NORM );
			pCustom.SetKeyvalue( INVUL_KVN_SOUND, g_Engine.time + 2.0 );
		}

		return HOOK_CONTINUE;
	}

	int iPowerArmorType = q2::PowerArmorType( cast<CBasePlayer@>(pDamageInfo.pVictim) );

	if( iPowerArmorType != q2items::POWER_ARMOR_NONE )
	{
		float flTake = pDamageInfo.flDamage;
		//g_Game.AlertMessage( at_notice, "flDamage: %1\n", flTake );

		TraceResult tr = g_Utility.GetGlobalTrace();

		float flPsave = q2::CheckPowerArmor( EHandle(pDamageInfo.pVictim), tr.vecEndPos, tr.vecPlaneNormal, flTake, pDamageInfo.bitsDamageType );
		//g_Game.AlertMessage( at_notice, "flPsave: %1\n", flPsave );

		flTake -= flPsave;
		//g_Game.AlertMessage( at_notice, "flTake: %1\n", flTake );
		pDamageInfo.flDamage = flTake;
	}

	return HOOK_CONTINUE;
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2shells", "ammo_q2shells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2bullets", "ammo_q2bullets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2grenades", "ammo_q2grenades" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2rockets", "ammo_q2rockets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2cells", "ammo_q2cells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::ammo_q2slugs", "ammo_q2slugs" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_health_small", NAME_HEALTH_SMALL );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_health", NAME_HEALTH_MEDIUM );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_health_large", NAME_HEALTH_LARGE );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_health_mega", NAME_HEALTH_MEGA );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_ancient_head", NAME_ANCHIENT_HEAD );
	g_Game.PrecacheOther( NAME_HEALTH_SMALL );
	g_Game.PrecacheOther( NAME_HEALTH_MEDIUM );
	g_Game.PrecacheOther( NAME_HEALTH_LARGE );
	g_Game.PrecacheOther( NAME_HEALTH_MEGA );
	g_Game.PrecacheOther( NAME_ANCHIENT_HEAD );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_armor_shard", NAME_ARMOR_SHARD );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_armor_jacket", NAME_ARMOR_JACKET );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_armor_combat", NAME_ARMOR_COMBAT );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_armor_body", NAME_ARMOR_BODY );
	g_Game.PrecacheOther( NAME_ARMOR_SHARD );
	g_Game.PrecacheOther( NAME_ARMOR_JACKET );
	g_Game.PrecacheOther( NAME_ARMOR_COMBAT );
	g_Game.PrecacheOther( NAME_ARMOR_BODY );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2shotgun", "item_q2shotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2supershotgun", "item_q2supershotgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2machinegun", "item_q2machinegun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2chaingun", "item_q2chaingun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2grenadelauncher", "item_q2grenadelauncher" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2rocketlauncher", "item_q2rocketlauncher" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2hyperblaster", "item_q2hyperblaster" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2railgun", "item_q2railgun" );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_q2bfg", "item_q2bfg" );
	g_Game.PrecacheOther( "item_q2shotgun" );
	g_Game.PrecacheOther( "item_q2supershotgun" );
	g_Game.PrecacheOther( "item_q2machinegun" );
	g_Game.PrecacheOther( "item_q2chaingun" );
	g_Game.PrecacheOther( "item_q2grenadelauncher" );
	g_Game.PrecacheOther( "item_q2rocketlauncher" );
	g_Game.PrecacheOther( "item_q2hyperblaster" );
	g_Game.PrecacheOther( "item_q2railgun" );
	g_Game.PrecacheOther( "item_q2bfg" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2inventory", INVWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( INVWEAP_NAME, "quake2/items" );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_quad", QUADITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2quad", QUADWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( QUADWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( QUADWEAP_NAME );
	g_Game.PrecacheOther( QUADITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_invulnerability", INVULITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2invulnerability", INVULWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( INVULWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( INVULWEAP_NAME );
	g_Game.PrecacheOther( INVULITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_silencer", SILENCERITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2silencer", SILENCERWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( SILENCERWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( SILENCERWEAP_NAME );
	g_Game.PrecacheOther( SILENCERITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_adrenaline", ADRENALINEITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2adrenaline", ADRENALINEWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( ADRENALINEWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( ADRENALINEWEAP_NAME );
	g_Game.PrecacheOther( ADRENALINEITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_breather", BREATHERITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2breather", BREATHERWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( BREATHERWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( BREATHERWEAP_NAME );
	g_Game.PrecacheOther( BREATHERITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_enviro", ENVIROITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2envirosuit", ENVIROWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( ENVIROWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( ENVIROWEAP_NAME );
	g_Game.PrecacheOther( ENVIROITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_bandolier", NAME_BANDOLIER );
	g_Game.PrecacheOther( NAME_BANDOLIER );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_pack", NAME_PACK );
	g_Game.PrecacheOther( NAME_PACK );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_power_screen", PSCREENITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2powerscreen", PSCREENWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( PSCREENWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( PSCREENWEAP_NAME );
	g_Game.PrecacheOther( PSCREENITEM_NAME );

	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::item_power_shield", PSHIELDITEM_NAME );
	g_CustomEntityFuncs.RegisterCustomEntity( "q2items::weapon_q2powershield", PSHIELDWEAP_NAME );
	g_ItemRegistry.RegisterWeapon( PSHIELDWEAP_NAME, "quake2/items" );
	g_Game.PrecacheOther( PSHIELDWEAP_NAME );
	g_Game.PrecacheOther( PSHIELDITEM_NAME );
}

} //end of namespace q2items

/* FIXME
*/

/* TODO
	Add rerelease items

	Make the armor pickups behave more like Quake 2 ?? (some math stuff)
	Make the weapon-based items actual items that go in the Inventory ?? (nooooo :D)
	Make the weapon-based items droppable ??
	Consolidate the weapon-based items ??
	Consolidate the Touch functions ??
	Keep max ammo from bandolier/pack if a player dies ??


	item_power_screen
	item_power_shield
		Somehow remove them from m_pPlayer.SelectLastItem() ??
		Add auto-shield ??
		Add effect to power screen ??

	item_quad and the like
		quad > quadfire > doubledmg > invul > invis > enviro > breather

		Add screen fades ??

		[[nodiscard]] constexpr bool G_PowerUpExpiringRelative(gtime_t left)
		{
			return left.milliseconds() > 3000 || (left.milliseconds() % 1000) < 500;
		}

		if (G_PowerUpExpiringRelative(remaining))
			G_AddBlend(0, 0, 1, 0.08f, ent->client->ps.screen_blend);

		SV_AddBlend (0, 0, 1, 0.08, ent->client->ps.blend);
*/
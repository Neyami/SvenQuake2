const int Q2_AMMO_SHELLS_MAX	= 100;
const int Q2_AMMO_BULLETS_MAX	= 200;
const int Q2_AMMO_GRENADES_MAX	= 50;
const int Q2_AMMO_ROCKETS_MAX	= 50;
const int Q2_AMMO_CELLS_MAX		= 200;
const int Q2_AMMO_SLUGS_MAX		= 50;

const int Q2_AMMO_SHELLS_GIVE	= 50;
const int Q2_AMMO_BULLETS_GIVE	= 50;
const int Q2_AMMO_GRENADES_GIVE	= 10;
const int Q2_AMMO_ROCKETS_GIVE	= 10;
const int Q2_AMMO_CELLS_GIVE	= 50;
const int Q2_AMMO_SLUGS_GIVE	= 10;

class ammo_q2generic : ScriptBasePlayerAmmoEntity
{
	string m_sModel;
	string m_sAmmo;
	int m_iGive;
	int m_iMax;
	float m_flRespawnTime;

	void CommonSpawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, m_sModel );

		BaseClass.Spawn();
		g_EntityFuncs.DispatchKeyValue( self.edict(), "m_flCustomRespawnTime", m_flRespawnTime );
	}

	void Spawn()
	{
		CommonSpawn();
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( "quake2/ammo.wav" );
	}

	bool AddAmmo( CBaseEntity@ pOther )
	{
		if( pOther is null ) return false;

		if( pOther.GiveAmmo(m_iGive, m_sAmmo, m_iMax) != -1 )
		{
			g_SoundSystem.EmitSound( pOther.edict(), CHAN_ITEM, "quake2/ammo.wav", 1, ATTN_NORM );

			return true;
		}

		return false;
	}
}

class ammo_q2shells : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_shellshd.mdl";
		m_sAmmo = "shells";
		m_iGive = Q2_AMMO_SHELLS_GIVE;
		m_iMax = Q2_AMMO_SHELLS_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

class ammo_q2bullets : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_bulletshd.mdl";
		m_sAmmo = "bullets";
		m_iGive = Q2_AMMO_BULLETS_GIVE;
		m_iMax = Q2_AMMO_BULLETS_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

class ammo_q2grenades : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_grenadeshd.mdl";
		m_sAmmo = "grenades";
		m_iGive = Q2_AMMO_GRENADES_GIVE;
		m_iMax = Q2_AMMO_GRENADES_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

class ammo_q2rockets : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_rocketshd.mdl";
		m_sAmmo = "q2rockets";
		m_iGive = Q2_AMMO_ROCKETS_GIVE;
		m_iMax = Q2_AMMO_ROCKETS_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

class ammo_q2cells : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_cellshd.mdl";
		m_sAmmo = "cells";
		m_iGive = Q2_AMMO_CELLS_GIVE;
		m_iMax = Q2_AMMO_CELLS_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

class ammo_q2slugs : ammo_q2generic
{
	void Spawn()
	{
		m_sModel = "models/quake2/w_slugshd.mdl";
		m_sAmmo = "slugs";
		m_iGive = Q2_AMMO_SLUGS_GIVE;
		m_iMax = Q2_AMMO_SLUGS_MAX;
		m_flRespawnTime = 3;//30
		CommonSpawn();
	}
}

void q2_SetAmmoCaps( CBasePlayer@ pPlayer )
{
	pPlayer.SetMaxAmmo( "shells", Q2_AMMO_SHELLS_MAX );
	pPlayer.SetMaxAmmo( "bullets", Q2_AMMO_BULLETS_MAX );
	pPlayer.SetMaxAmmo( "grenades", Q2_AMMO_GRENADES_MAX );
	pPlayer.SetMaxAmmo( "q2rockets", Q2_AMMO_ROCKETS_MAX );
	pPlayer.SetMaxAmmo( "cells", Q2_AMMO_CELLS_MAX );
	pPlayer.SetMaxAmmo( "slugs", Q2_AMMO_SLUGS_MAX );
}

void q2_RegisterAmmo()
{
	g_Game.PrecacheModel( "models/quake2/w_shellshd.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_bulletshd.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_grenadeshd.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_rocketshd.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_cellshd.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_slugshd.mdl" );
	g_SoundSystem.PrecacheSound( "quake2/ammo.wav" );// for backpacks

	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2shells", "ammo_q2shells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2bullets", "ammo_q2bullets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2grenades", "ammo_q2grenades" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2rockets", "ammo_q2rockets" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2cells", "ammo_q2cells" );
	g_CustomEntityFuncs.RegisterCustomEntity( "ammo_q2slugs", "ammo_q2slugs" );
}

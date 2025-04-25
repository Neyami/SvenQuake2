/*QUAKED target_splash (1 0 0) (-8 -8 -8) (8 8 8)
Creates a particle splash effect when used.

Set "sounds" to one of the following:
  1) sparks
  2) blue water
  3) brown water
  4) slime
  5) lava
  6) blood

"count"	how many pixels in the splash
"dmg"	if set, does a radius damage at this location when it splashes
		useful for lava/sparks
*/

namespace q2target_splash
{

class target_splash : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private int m_iCount;
	private int m_iEffect;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "count" )
		{
			m_iCount = atoi( szValue );
			return true;
		}
		else if( szKey == "sounds" )
		{
			m_iEffect = atoi( szValue );
			return true;
		}
		else
			return BaseClass.KeyValue( szKey, szValue );
	}

	void Spawn()
	{
		if( !q2::ShouldEntitySpawn(self) )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		SetUse( UseFunction(this.use_target_splash) );
		G_SetMovedir( pev.angles, pev.movedir);

		if( m_iCount == 0 )
			m_iCount = 32;

		g_EntityFuncs.SetOrigin( self, pev.origin );
	}

	void use_target_splash( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		//array<float> arrflSplashColor = { 0, 224, 176, 80, 208, 224, 232 }; //Quake 2 palette
		array<float> arrflSplashColor = { 0, 92, 208, 90, 195, 92, 229 };
/*
        1 : "Sparks"			= 6
        2 : "Blue water"		= 4
        3 : "Brown water"	
        4 : "Slime"
        5 : "Lava"
        6 : "Blood"
*/
		//count 255 causes a particle explosion! :O
		g_EngineFuncs.ParticleEffect( pev.origin, pev.movedir, arrflSplashColor[Math.clamp(0, arrflSplashColor.length()-1, m_iEffect)], m_iCount );

		if( pev.dmg != 0 )
			q2::T_RadiusDamage( self, pActivator, pev.dmg, null, pev.dmg + 40.0, DMG_GENERIC ); //MOD_SPLASH
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2target_splash::target_splash", "target_splash" );
	g_Game.PrecacheOther( "target_splash" );
}

} //end of namespace q2target_splash
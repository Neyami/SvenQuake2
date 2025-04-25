/*QUAKED func_timer (0.3 0.1 0.6) (-8 -8 -8) (8 8 8) START_ON
"wait"			base time between triggering all targets, default is 1
"random"		wait variance, default is 0

so, the basic time between firing is a random time between
(wait - random) and (wait + random)

"delay"			delay before first firing when turned on, default is 0

"pausetime"		additional delay used only the very first time
				and only if spawned with START_ON

These can used but not touched.
*/

namespace q2func_timer
{

const int SPAWNFLAG_TIMER_START_ON = 1;

class func_timer : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private EHandle m_hActivator;
	private float m_flDelay;
	private float m_flRandom;
	private float m_flWait = 1.0;
	private float m_flPausetime;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "delay" )
		{
			m_flDelay = atof( szValue );
			return true;
		}
		else if( szKey == "random" )
		{
			m_flRandom = atof( szValue );
			return true;
		}
		else if( szKey == "wait" )
		{
			m_flWait = atof( szValue );
			return true;
		}
		else if( szKey == "pausetime" )
		{
			m_flPausetime = atof( szValue );
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

		g_EntityFuncs.SetOrigin( self, pev.origin );

		if( m_flWait == 0 )
			m_flWait = 1.0;

		SetUse( UseFunction(this.func_timer_use) );
		SetThink( ThinkFunction(this.func_timer_think) );

		if( m_flRandom >= m_flWait )
		{
			m_flRandom = m_flWait - q2::FRAMETIME;
			g_Game.AlertMessage( at_error, "func_timer at %1 has random >= wait\n", pev.origin.ToString() );
		}

		if( HasFlags(pev.spawnflags, SPAWNFLAG_TIMER_START_ON) )
		{
			pev.nextthink = g_Engine.time + 1.0 + m_flPausetime + m_flDelay + m_flWait + q2::crandom() * m_flRandom;
			m_hActivator = EHandle( self );
		}
	}

	void func_timer_think()
	{
		G_UseTargets( m_hActivator.GetEntity(), USE_TOGGLE, 0.0 );
		pev.nextthink = g_Engine.time + m_flWait + q2::crandom() * m_flRandom;
	}

	void func_timer_use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		m_hActivator = EHandle( pActivator );

		// if on, turn it off
		if( pev.nextthink > 0 )
		{
			pev.nextthink = 0;
			return;
		}

		// turn it on
		if( m_flDelay > 0.0 )
			pev.nextthink = g_Engine.time + m_flDelay;
		else
			func_timer_think();
	}

}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2func_timer::func_timer", "func_timer" );
}

} //end of namespace q2func_timer
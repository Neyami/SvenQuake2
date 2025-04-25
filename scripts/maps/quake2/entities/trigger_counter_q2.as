/*QUAKED trigger_counter_q2 (.5 .5 .5) ? nomessage
Acts as an intermediary for an action that takes multiple inputs.

If nomessage is not set, t will print "1 more.. " etc when triggered and "sequence complete" when finished.

After the counter has been triggered "count" times (default 2), it will fire all of it's targets and remove itself.
*/

namespace q2trigger_counter_q2
{

const int SPAWNFLAG_COUNTER_NOMESSAGE = 1;

class trigger_counter_q2 : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private EHandle m_hActivator;
	private int m_iCount;
	private float m_flWait;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "count" )
		{
			m_iCount = atoi( szValue );
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

		Precache();

		g_EntityFuncs.SetOrigin( self, pev.origin );

		m_flWait = -1;

		if( m_iCount <= 0 )
			m_iCount = 2;

		SetUse( UseFunction(this.trigger_counter_use) );
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake2/misc/talk1.wav" );
	}

	void trigger_counter_use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		if( m_iCount == 0 )
			return;

		m_iCount--;

		if( m_iCount != 0 )
		{
			if( !HasFlags(pev.spawnflags, SPAWNFLAG_COUNTER_NOMESSAGE) )
			{
				if( pActivator.pev.FlagBitSet(FL_CLIENT) )
				{
					CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
					g_EngineFuncs.ClientPrintf( pPlayer, print_center, string(m_iCount) + " more to go..." );
				}

				g_SoundSystem.EmitSound( pActivator.edict(), CHAN_AUTO, "quake2/misc/talk1.wav", VOL_NORM, ATTN_NORM );
			}

			return;
		}

		if( !HasFlags(pev.spawnflags, SPAWNFLAG_COUNTER_NOMESSAGE) )
		{
			if( pActivator.pev.FlagBitSet(FL_CLIENT) )
			{
				CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );
				g_EngineFuncs.ClientPrintf( pPlayer, print_center, "Sequence completed!" );
			}

			g_SoundSystem.EmitSound( pActivator.edict(), CHAN_AUTO, "quake2/misc/talk1.wav", VOL_NORM, ATTN_NORM );
		}

		m_hActivator = EHandle( pActivator );
		multi_trigger();
	}

	void multi_trigger()
	{
		if( pev.nextthink != 0 )
			return; // already been triggered

		self.SUB_UseTargets( m_hActivator.GetEntity(), USE_TOGGLE, 0.0 );

		pev.nextthink = g_Engine.time + 0.1;
		pev.flags = FL_KILLME;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2trigger_counter_q2::trigger_counter_q2", "trigger_counter_q2" );
	g_Game.PrecacheOther( "trigger_counter_q2" );
}

} //end of namespace q2trigger_counter_q2
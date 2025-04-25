/*QUAKED trigger_key (.5 .5 .5) (-8 -8 -8) (8 8 8)
A relay trigger that only fires it's targets if player has the proper key.
Use "item" to specify the required key, for example "key_data_cd"
*/

namespace q2trigger_key
{

class trigger_key : ScriptBaseEntity, q2entities::CBaseQ2Entity
{
	private EHandle m_hItem;
	private string m_sItemName;
	private float m_flTouchDebounceTime;

	bool KeyValue( const string& in szKey, const string& in szValue )
	{
		if( szKey == "item" )
		{
			m_sItemName = szValue;
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

		if( m_sItemName.IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "no key item for trigger_key at %1\n", pev.origin.ToString() );
			g_EntityFuncs.Remove( self );
			return;
		}

		//delay this ??
		m_hItem = EHandle( g_EntityFuncs.FindEntityByClassname(null, m_sItemName) );

		if( !m_hItem.IsValid() )
		{
			g_Game.AlertMessage( at_error, "item %1 not found for trigger_key at %2\n", m_sItemName, pev.origin.ToString() );
			//g_EntityFuncs.Remove( self );
			//return;
		}

		if( string(pev.target).IsEmpty() )
		{
			g_Game.AlertMessage( at_error, "%1 at %2 has no target\n", self.GetClassname(), pev.origin.ToString() );
			g_EntityFuncs.Remove( self );
			return;
		}

		Precache();

		SetUse( UseFunction(this.trigger_key_use) );
	}

	void Precache()
	{
		g_SoundSystem.PrecacheSound( "quake2/misc/keytry.wav" );
		g_SoundSystem.PrecacheSound( "quake2/misc/keyuse.wav" );
	}

	void trigger_key_use( CBaseEntity@ pActivator, CBaseEntity@ pCaller, USE_TYPE useType, float flValue )
	{
		//int index;

		//if( !m_hItem.IsValid() )
			//return;

		if( !m_hItem.IsValid() )
			m_hItem = EHandle( g_EntityFuncs.FindEntityByClassname(null, m_sItemName) );

		if( !pActivator.pev.FlagBitSet(FL_CLIENT) )
			return;

		CBasePlayer@ pPlayer = cast<CBasePlayer@>( pActivator );

		if( q2items::HasNamedPlayerItem(pPlayer, m_sItemName) is null )
		{
			if( g_Engine.time < m_flTouchDebounceTime )
				return;

			m_flTouchDebounceTime = g_Engine.time + 3.0; //5
			g_EngineFuncs.ClientPrintf( pPlayer, print_center, "You need the " + m_hItem.GetEntity().pev.netname );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/misc/keytry.wav", VOL_NORM, ATTN_NORM );

			return;
		}

		g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/misc/keyuse.wav", VOL_NORM, ATTN_NORM );

		if( q2::IsCoop() )
		{
			//edict_t	*ent;

			if( m_sItemName == "key_power_cube" )
			{
				/*int	cube;

				for (cube = 0; cube < 8; cube++)
				{
					if (activator->client->pers.power_cubes & (1 << cube))
						break;
				}

				for( int i = 1; i <= g_Engine.maxClients; ++i )
				{
					CBasePlayer@ pAllPlayers = g_PlayerFuncs.FindPlayerByIndex( i );

					if( pAllPlayers !is null )
					{
						if (ent->client->pers.power_cubes & (1 << cube))
						{
							ent->client->pers.inventory[index]--;
							ent->client->pers.power_cubes &= ~(1 << cube);
						}
					}
				}*/
			}
			else
			{
				for( int i = 1; i <= g_Engine.maxClients; ++i )
				{
					CBasePlayer@ pAllPlayers = g_PlayerFuncs.FindPlayerByIndex( i );

					if( pAllPlayers !is null )
					{
						CItemInventory@ pKey = q2items::HasNamedPlayerItem( pAllPlayers, m_sItemName );
						if( pKey !is null )
							pKey.SUB_Remove();
					}
				}
			}
		}
		else
		{
			CItemInventory@ pKey = q2items::HasNamedPlayerItem( pPlayer, m_sItemName );
			if( pKey !is null )
				pKey.SUB_Remove();
		}

		G_UseTargets( pActivator, useType, flValue );

		SetUse( null );
	}

	CItemInventory@ FindItemByClassname( string sItemName )
	{
		for( int i = 1; i <= g_Engine.maxClients; ++i )
		{
			CBasePlayer@ pPlayer = g_PlayerFuncs.FindPlayerByIndex( i );

			if( pPlayer !is null and pPlayer.IsAlive() )
			{
				CItemInventory@ pKey = q2items::HasNamedPlayerItem( pPlayer, sItemName );
				if( pKey !is null )
					return pKey;
			}
		}

		return null;
	}
}

void Register()
{
	g_CustomEntityFuncs.RegisterCustomEntity( "q2trigger_key::trigger_key", "trigger_key" );
	g_Game.PrecacheOther( "trigger_key" );
}

} //end of namespace q2trigger_key
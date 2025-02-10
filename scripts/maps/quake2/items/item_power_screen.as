namespace q2items
{

const string PSCREENITEM_NAME			= "item_power_screen";
const string PSCREENWEAP_NAME			= "weapon_q2powerscreen";
const string MODEL_PSCREEN					= "models/quake2/items/screen.mdl";
const string PSCREEN_HUD_ICON			= "quake2/pics/i_powerscreen.spr";

final class item_power_screen : ScriptBaseItemEntity, item_q2pickup
{
	item_power_screen()
	{
		m_iItemID = IT_ITEM_POWER_SCREEN;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/screen.mdl";
		m_sSound = "quake2/misc/ar3_pkup.wav";
		m_flRespawnTime = 2.0; //60
	}
}

class weapon_q2powerscreen : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	private bool m_bSelectLastItem;

	void Spawn()
	{
		Precache();

		g_EntityFuncs.SetModel( self, MODEL_PSCREEN );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_PSCREEN );

		g_SoundSystem.PrecacheSound( "quake2/misc/power1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/misc/power2.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + PSCREENWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/powerscreen.spr" );
		g_Game.PrecacheGeneric( "sprites/" + PSCREEN_HUD_ICON );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= PSCREEN_SLOT - 1;
		info.iPosition			= PSCREEN_POSITION - 1;
		info.iFlags 				= ITEM_FLAG_SELECTONEMPTY | ITEM_FLAG_NOAUTOSWITCHEMPTY;
		info.iWeight			= 0; //-1 ??

		return true;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		if( !BaseClass.AddToPlayer(pPlayer) )
			return false;

		@m_pPlayer = pPlayer;

		NetworkMessage m1( MSG_ONE, NetworkMessages::WeapPickup, pPlayer.edict() );
			m1.WriteLong( g_ItemRegistry.GetIdForName(PSCREENWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		if( m_pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells")) <= 0 )
			return false;

		return true;
	}

	bool Deploy()
	{
		if( m_pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells")) <= 0 )
		{
			m_pPlayer.SelectLastItem();
			return false; //??
		}

		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(PARMOR_KVN).GetInteger() == 0 )
		{
			HUDNumDisplayParams hudParams;

			//always use the power shield if the player has it
			if( m_pPlayer.HasNamedPlayerItem(PSHIELDWEAP_NAME) !is null )
			{
				q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_POWER_SHIELD, hudParams );
				pCustom.SetKeyvalue( PARMOR_KVN, q2items::POWER_ARMOR_SHIELD );
			}
			else
			{
				q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_POWER_SCREEN, hudParams );
				pCustom.SetKeyvalue( PARMOR_KVN, q2items::POWER_ARMOR_SCREEN );
			}

			g_PlayerFuncs.HudNumDisplay( m_pPlayer, hudParams );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "quake2/misc/power1.wav", VOL_NORM, ATTN_NORM );
			m_bSelectLastItem = true;
		}
		else if( pCustom.GetKeyvalue(PARMOR_KVN).GetInteger() >= 1 )
		{
			g_PlayerFuncs.HudToggleElement( m_pPlayer, q2items::PARMOR_HUD_CHANNEL, false );

			pCustom.SetKeyvalue( PARMOR_KVN, 0 );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "quake2/misc/power2.wav", VOL_NORM, ATTN_NORM );
			m_bSelectLastItem = true;
		}

		return self.DefaultDeploy( "", "", 0, "" );
	}

	void ItemPostFrame()
	{
		if( m_bSelectLastItem )
		{
			m_pPlayer.SelectLastItem();
			m_bSelectLastItem = false;
		}
	}

	void InactiveItemPreFrame()
	{
		if( !m_pPlayer.IsAlive() )
		{
			ResetPlayer();
			KillSelf();
			return;
		}

		BaseClass.InactiveItemPreFrame();
	}

	void Think()
	{
		if( pev.owner is null )
		{
			g_EntityFuncs.Remove( self );
			return;
		}

		BaseClass.Think();
	}

	CBasePlayerItem@ DropItem() { return null; }

	void ResetPlayer()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
		pCustom.SetKeyvalue( PARMOR_KVN, 0 );
		pCustom.SetKeyvalue( PARMOR_KVN_EFFECT, 0.0 );
	}

	void KillSelf()
	{
		if( m_pPlayer !is null and m_pPlayer.IsConnected() )
		{
			if( m_pPlayer.HasPlayerItem(self) )
				m_pPlayer.RemovePlayerItem( self );
		}

		g_EntityFuncs.Remove( self );
	}
}

} //end of namespace q2items
namespace q2items
{

const string SILENCERITEM_NAME		= "item_silencer";
const string SILENCERWEAP_NAME		= "weapon_q2silencer";
const int SILENCER_SHOTS					= 30;
const string MODEL_SILENCER			= "models/quake2/items/silencer.mdl";
const string SILENCER_KVN				= "$i_q2silencer";
const string SILENCER_ICON				= "quake2/pics/p_silencer.spr";

/*
It affects almost all weaponry, including the mighty BFG10K and even the Chainfist, but it doesn't make a difference to hand grenades, Tesla Mines and Traps, since throwing these is already "silent" in practical terms. 

There is a second effect of the Silencer, concerning projectiles. Idle Strogg can be alerted not only by the sound of your gunfire, but also the presence of a projectile (such as a rocket from your Rocket Launcher) being fired in their direction, 
even if they were too far away to hear the actual shot. A Silencer makes both of these things less likely to alert enemies. 
*/

final class item_silencer : ScriptBaseItemEntity, item_q2pickup
{
	item_silencer()
	{
		m_iItemID = IT_ITEM_SILENCER;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = "models/quake2/items/silencer.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = 60.0;
	}
}

class weapon_q2silencer : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_SILENCER );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_SILENCER );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + SILENCERWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/silencer.spr" );
		g_Game.PrecacheGeneric( "sprites/" + SILENCER_ICON );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= SILENCER_SLOT - 1;
		info.iPosition			= SILENCER_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(SILENCERWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(SILENCER_KVN).GetInteger() >= 1 )
			return false;

		return true;
	}

	bool Deploy()
	{
		//it deploys if it's in the player's inventory when they die for some reason....
		if( m_pPlayer.IsAlive() )
		{
			CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();
			HUDNumDisplayParams hudParams;
			q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_SILENCER, hudParams );

			int iShots = SILENCER_SHOTS;
			if( pCustom.GetKeyvalue(SILENCER_KVN).GetInteger() >= 1 )
				iShots += pCustom.GetKeyvalue(SILENCER_KVN).GetInteger(); //add any remaining shots

			hudParams.value = iShots;
			g_PlayerFuncs.HudNumDisplay( m_pPlayer, hudParams );

			pCustom.SetKeyvalue( SILENCER_KVN, iShots );

			m_pPlayer.SelectLastItem();
			m_pPlayer.SetItemPickupTimes( 0.0 );
		}

		KillSelf();

		return self.DefaultDeploy( "", "", 0, "" );
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
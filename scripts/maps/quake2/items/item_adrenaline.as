namespace q2items
{

const string ADRENALINEITEM_NAME		= "item_adrenaline";
const string ADRENALINEWEAP_NAME		= "weapon_q2adrenaline";
const string MODEL_ADRENALINE			= "models/quake2/items/adrenaline.mdl";

final class item_adrenaline : ScriptBaseItemEntity, item_q2pickup
{
	item_adrenaline()
	{
		m_iItemID = q2::IT_ITEM_ADRENALINE;
		m_iWorldModelFlags = q2::EF_ROTATE;
		m_sModel = "models/quake2/items/adrenaline.mdl";
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = 60.0;
	}
}

class weapon_q2adrenaline : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_ADRENALINE );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_ADRENALINE );

		g_SoundSystem.PrecacheSound( "quake2/items/n_health.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + ADRENALINEWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/adrenaline.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= ADRENALINE_SLOT - 1;
		info.iPosition			= ADRENALINE_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(ADRENALINEWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		return false; //THIS MAKES NO SENSE :aRage:
	}

	bool Deploy()
	{
		ApplyAdrenaline( m_pPlayer );

		m_pPlayer.SelectLastItem();
		m_pPlayer.SetItemPickupTimes( 0.0 );

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

void ApplyAdrenaline( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	int iMaxHealthBoost = pCustom.GetKeyvalue(MAX_HEALTH_KVN).GetInteger();
	pCustom.SetKeyvalue( MAX_HEALTH_KVN, iMaxHealthBoost + 1 );
	pPlayer.pev.max_health += 1;

	if( pPlayer.pev.health < pPlayer.pev.max_health )
		pPlayer.pev.health = pPlayer.pev.max_health;

	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, "quake2/items/n_health.wav", VOL_NORM, ATTN_NORM );
}

} //end of namespace q2items
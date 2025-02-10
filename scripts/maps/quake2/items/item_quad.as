namespace q2items
{

const string QUADITEM_NAME				= "item_quad";
const string QUADWEAP_NAME			= "weapon_q2quad";
const float QUAD_DURATION				= 30.0;
const float QUAD_RESPAWN				= 60.0;
const string MODEL_QUAD					= "models/quake2/items/quaddama.mdl";
const string QUAD_KVN						= "$i_q2quaddamage";
const string QUAD_KVN_TIME				= "$f_q2quadtime";
const string QUAD_ICON					= "quake2/pics/p_quad.spr";

final class item_quad : ScriptBaseItemEntity, item_q2pickup
{
	item_quad()
	{
		m_iItemID = IT_ITEM_QUAD;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = MODEL_QUAD;
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = QUAD_RESPAWN;
	}
}

class weapon_q2quad : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_QUAD );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_QUAD );

		g_SoundSystem.PrecacheSound( "quake2/items/damage.wav" );
		g_SoundSystem.PrecacheSound( "quake2/items/damage3.wav" );
		g_SoundSystem.PrecacheSound( "quake2/items/damage2.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + QUADWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/quaddamage.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/pics/p_quad.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= QUAD_SLOT - 1;
		info.iPosition			= QUAD_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(QUADWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(QUAD_KVN).GetInteger() >= 1 )
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
			q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_QUAD, hudParams );

			float flDuration = QUAD_DURATION;
			if( pCustom.GetKeyvalue(QUAD_KVN).GetInteger() >= 1 )
				flDuration += pCustom.GetKeyvalue(QUAD_KVN_TIME).GetFloat() - g_Engine.time; //add the remaining time

			hudParams.value = flDuration;
			g_PlayerFuncs.HudTimeDisplay( m_pPlayer, hudParams );
			g_SoundSystem.EmitSound( self.edict(), CHAN_ITEM, "quake2/items/damage.wav", VOL_NORM, ATTN_NORM );

			pCustom.SetKeyvalue( QUAD_KVN, 1 );
			pCustom.SetKeyvalue( QUAD_KVN_TIME, g_Engine.time + flDuration ); //start the fading sound

			m_pPlayer.pev.renderfx = kRenderFxGlowShell;
			m_pPlayer.pev.rendercolor.z = 255;
			m_pPlayer.pev.renderamt = 1;
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

void FadeQuadDamage( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flItemFadeTime= pCustom.GetKeyvalue(QUAD_KVN_TIME).GetFloat();

	if( flItemFadeTime > 0.0 )
	{
		int iItemState = pCustom.GetKeyvalue(QUAD_KVN).GetInteger();

		if( g_Engine.time > (flItemFadeTime - 2.983) and iItemState == 1 )
		{
			QuadFadeMessage( pPlayer );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/items/damage2.wav", VOL_NORM, ATTN_NORM ); //CHAN_ITEM
			pCustom.SetKeyvalue( QUAD_KVN, 2 );
		}
		else if( g_Engine.time > flItemFadeTime and iItemState == 2 )
		{
			flItemFadeTime = 0.0;
			QuadResetPlayer( pPlayer );
		}
	}
}

void QuadFadeMessage( CBasePlayer@ pPlayer )
{
	HUDTextParams textParms;
		textParms.fxTime = 30;
		textParms.fadeinTime = 0.0;
		textParms.holdTime = 3.0;
		textParms.fadeoutTime = 0.0;
		textParms.effect = 0;
		textParms.channel = 3;
		textParms.x = 0.25;
		textParms.y = 0.67;
		textParms.r1 = 0;
		textParms.g1 = 255;
		textParms.b1 = 255;
		textParms.r2 = 0;
		textParms.g2 = 0;
		textParms.b2 = 255;

	g_PlayerFuncs.HudMessage( pPlayer, textParms, "Quad Damage is wearing off!\n" );
}

void QuadResetPlayer( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( QUAD_KVN, 0 );
	pCustom.SetKeyvalue( QUAD_KVN_TIME, 0.0 );
	pPlayer.pev.renderfx = kRenderFxNone;
	pPlayer.pev.rendercolor = g_vecZero;
	pPlayer.pev.renderamt = 0;

	g_PlayerFuncs.HudToggleElement( pPlayer, q2items::QUAD_HUD_CHANNEL, false );
}

} //end of namespace q2items
namespace q2items
{

const string INVISITEM_NAME				= "item_invisibility";
const string INVISWEAP_NAME			= "weapon_q2invisibility";
const float INVIS_DURATION				= 30.0;
const float INVISIBILITY_TIME			= 2.0; //seconds until we are fully invisible after making a racket
const float INVIS_RESPAWN				= 300.0;
const string MODEL_INVIS					= "models/quake2/items/cloaker.mdl";
const string INVIS_KVN						= "$i_q2invisdamage";
const string INVIS_KVN_TIME				= "$f_q2invistime"; //client->invisible_time
const string INVIS_KVN_FADETIME		= "$f_q2invisfadetime"; //client->invisibility_fade_time
const string INVIS_ICON						= "quake2/pics/p_cloaker.spr";

final class item_invisibility : ScriptBaseItemEntity, item_q2pickup
{
	item_invisibility()
	{
		m_iItemID = q2::IT_ITEM_INVISIBILITY;
		m_iWorldModelFlags = q2::EF_ROTATE;
		m_sModel = MODEL_INVIS;
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = INVIS_RESPAWN;
	}
}

class weapon_q2invisibility : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_INVIS );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_INVIS );

		g_SoundSystem.PrecacheSound( "quake2/items/protect.wav" );
		g_SoundSystem.PrecacheSound( "quake2/items/protect2.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + INVISWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/invisibility.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/pics/p_cloaker.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= INVIS_SLOT - 1;
		info.iPosition			= INVIS_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(INVISWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(INVIS_KVN).GetInteger() >= 1 )
			return false;

		return true;
	}

	bool Deploy()
	{
		//it deploys if it's in the player's inventory when they die for some reason....
		if( m_pPlayer.IsAlive() )
		{
			InvisActivate( m_pPlayer );

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

void InvisActivate( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	HUDNumDisplayParams hudParams;
	q2items::GetHudParams( pPlayer, q2::IT_ITEM_INVISIBILITY, hudParams );

	float flDuration = INVIS_DURATION;
	if( pCustom.GetKeyvalue(INVIS_KVN).GetInteger() >= 1 )
		flDuration += pCustom.GetKeyvalue(INVIS_KVN_TIME).GetFloat() - g_Engine.time; //add the remaining time

	hudParams.value = flDuration;
	g_PlayerFuncs.HudTimeDisplay( pPlayer, hudParams );
	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, "quake2/items/protect.wav", VOL_NORM, ATTN_NORM );

	pCustom.SetKeyvalue( INVIS_KVN, 1 );
	pCustom.SetKeyvalue( INVIS_KVN_TIME, g_Engine.time + flDuration ); //start the fading sound

	if( IsItemActive(pPlayer, q2::IT_ITEM_SILENCER) )
		pCustom.SetKeyvalue( INVIS_KVN_FADETIME, g_Engine.time + (INVISIBILITY_TIME / 5) );
	else
		pCustom.SetKeyvalue( INVIS_KVN_FADETIME, g_Engine.time + INVISIBILITY_TIME );

	pPlayer.pev.flags |= FL_NOTARGET;
	pPlayer.pev.rendermode = kRenderTransColor;
	pPlayer.pev.renderamt = 255;
	//pPlayer.pev.renderfx = 0;
	//pPlayer.pev.effects |= EF_NODRAW;
}

void RunInvisibility( CBasePlayer@ pPlayer )
{
	if( IsItemActive(pPlayer, q2::IT_ITEM_INVISIBILITY) )
	{
		//g_Game.AlertMessage( at_notice, "IT_ITEM_INVISIBILITY!\n" );
		//if (ent->client->invisible_time > level.time)
		{
			CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
			float flInvisibilityFadeTime = pCustom.GetKeyvalue(INVIS_KVN_FADETIME).GetFloat();

			if( flInvisibilityFadeTime <= g_Engine.time)
			{
				if( pPlayer.pev.rendermode != kRenderTransColor )
					pPlayer.pev.rendermode = kRenderTransColor;

				pPlayer.pev.renderamt = 255 * 0.1;
				pPlayer.pev.flags |= FL_NOTARGET;
			}
			else
			{
				if( pPlayer.pev.rendermode != kRenderTransColor )
					pPlayer.pev.rendermode = kRenderTransColor;

				float x = (flInvisibilityFadeTime - g_Engine.time) / INVISIBILITY_TIME;
				pPlayer.pev.renderamt = Math.clamp( (255 * 0.1), 255, x * 255 );
				pPlayer.pev.flags &= ~FL_NOTARGET;
				//g_Game.AlertMessage( at_notice, "RunInvisibility x: %1, renderamt: %2\n", x, pPlayer.pev.renderamt );
			}
		}
	}
}

//G_AddBlend(0.8f, 0.8f, 0.8f, 0.08f, ent->client->ps.screen_blend);
void FadeInvisibility( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flItemEffectTime= pCustom.GetKeyvalue(INVIS_KVN_TIME).GetFloat();

	if( flItemEffectTime > 0.0 )
	{
		int iItemState = pCustom.GetKeyvalue(INVIS_KVN).GetInteger();

		if( g_Engine.time > (flItemEffectTime - 2.983) and iItemState == 1 )
		{
			InvisFadeMessage( pPlayer );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/items/protect2.wav", VOL_NORM, ATTN_NORM ); //CHAN_ITEM
			pCustom.SetKeyvalue( INVIS_KVN, 2 );
		}
		else if( g_Engine.time > flItemEffectTime and iItemState == 2 )
		{
			flItemEffectTime = 0.0;
			InvisResetPlayer( pPlayer );
		}
	}
}

void InvisFadeMessage( CBasePlayer@ pPlayer )
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

	g_PlayerFuncs.HudMessage( pPlayer, textParms, "Invisibility is wearing off!\n" );
}

void InvisResetPlayer( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( INVIS_KVN, 0 );
	pCustom.SetKeyvalue( INVIS_KVN_TIME, 0.0 );
	pCustom.SetKeyvalue( INVIS_KVN_FADETIME, 0.0 );

	pPlayer.pev.flags &= ~FL_NOTARGET;
	pPlayer.pev.rendermode = kRenderNormal;
	pPlayer.pev.renderamt = 0;
	//pPlayer.pev.renderfx = 0;
	//pPlayer.pev.effects &= ~EF_NODRAW;

	g_PlayerFuncs.HudToggleElement( pPlayer, INVIS_HUD_CHANNEL, false );
}

} //end of namespace q2items
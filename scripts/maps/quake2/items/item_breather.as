namespace q2items
{

const string BREATHERITEM_NAME		= "item_breather";
const string BREATHERWEAP_NAME		= "weapon_q2breather";
const float BREATHER_DURATION		= 30.0;
const float BREATHER_RESPAWN			= 60.0;
const string MODEL_BREATHER			= "models/quake2/items/breather.mdl";
const string BREATHER_KVN				= "$i_q2breather";
const string BREATHER_KVN_TIME		= "$f_q2breathertime";
const string BREATHER_KVN_SOUND	= "$i_q2breathersound";
const string BREATHER_ICON				= "quake2/pics/p_rebreather.spr";

final class item_breather : ScriptBaseItemEntity, item_q2pickup
{
	item_breather()
	{
		m_iItemID = IT_ITEM_REBREATHER;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = MODEL_BREATHER;
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = BREATHER_RESPAWN;
	}
}

class weapon_q2breather : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_BREATHER );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_BREATHER );

		g_SoundSystem.PrecacheSound( "quake2/items/airout.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/u_breath1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/u_breath2.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + BREATHERWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/rebreather.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/pics/p_rebreather.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= BREATHER_SLOT - 1;
		info.iPosition			= BREATHER_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(BREATHERWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(BREATHER_KVN).GetInteger() >= 1 )
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
			q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_REBREATHER, hudParams );

			float flDuration = BREATHER_DURATION;
			if( pCustom.GetKeyvalue(BREATHER_KVN).GetInteger() >= 1 )
				flDuration += pCustom.GetKeyvalue(BREATHER_KVN_TIME).GetFloat() - g_Engine.time; //add the remaining time

			hudParams.value = flDuration;
			g_PlayerFuncs.HudTimeDisplay( m_pPlayer, hudParams );

			pCustom.SetKeyvalue( BREATHER_KVN, 1 );
			pCustom.SetKeyvalue( BREATHER_KVN_TIME, g_Engine.time + flDuration ); //start the fading sound

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

void RunRebreather( CBasePlayer@ pPlayer )
{
	if( IsItemActive(pPlayer, IT_ITEM_REBREATHER) and !IsItemActive(pPlayer, IT_ITEM_ENVIROSUIT) )
	{
		if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			pPlayer.pev.air_finished = g_Engine.time + 10;

			CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
			float flBreatherTime = pCustom.GetKeyvalue(BREATHER_KVN_TIME).GetFloat();
			float remainingTime = flBreatherTime - g_Engine.time;
			float elapsedTime = (flBreatherTime - remainingTime) * 1000;

			if( int(elapsedTime) % 2500 < 100 )
			{
				int iItemSound = pCustom.GetKeyvalue(BREATHER_KVN_SOUND).GetInteger();
				string sSound = (iItemSound == 0) ? "quake2/player/u_breath1.wav" : "quake2/player/u_breath2.wav";

				g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, sSound, VOL_NORM, ATTN_NORM );

				pCustom.SetKeyvalue( BREATHER_KVN_SOUND, 1 - iItemSound );
				//PlayerNoise(current_player, current_player->s.origin, PNOISE_SELF);

				//TODO: release a bubble?
			}
		}
	}
}
//G_AddBlend(0.4f, 1, 0.4f, 0.04f, ent->client->ps.screen_blend); 
void FadeRebreather( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flItemFadeTime= pCustom.GetKeyvalue(BREATHER_KVN_TIME).GetFloat();

	if( flItemFadeTime > 0.0 )
	{
		int iItemState = pCustom.GetKeyvalue(BREATHER_KVN).GetInteger();

		if( g_Engine.time > (flItemFadeTime - 2.983) and iItemState == 1 )
		{
			BreatherFadeMessage( pPlayer );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/items/airout.wav", VOL_NORM, ATTN_NORM ); //CHAN_ITEM
			pCustom.SetKeyvalue( BREATHER_KVN, 2 );
		}
		else if( g_Engine.time > flItemFadeTime and iItemState == 2 )
		{
			flItemFadeTime = 0.0;
			BreatherResetPlayer( pPlayer );
		}
	}
}

void BreatherFadeMessage( CBasePlayer@ pPlayer )
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

	g_PlayerFuncs.HudMessage( pPlayer, textParms, "Rebreather is wearing off!\n" );
}

void BreatherResetPlayer( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( BREATHER_KVN, 0 );
	pCustom.SetKeyvalue( BREATHER_KVN_TIME, 0.0 );

	g_PlayerFuncs.HudToggleElement( pPlayer, q2items::BREATHER_HUD_CHANNEL, false );
}

} //end of namespace q2items
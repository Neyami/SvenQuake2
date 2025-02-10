namespace q2items
{
/*
	if (waterlevel && (current_player->watertype & (CONTENTS_LAVA | CONTENTS_SLIME)) && current_player->slime_debounce_time <= level.time)
	{
		if (current_player->watertype & CONTENTS_LAVA)
		{
			if (current_player->health > 0 && current_player->pain_debounce_time <= level.time && current_client->invincible_time < level.time)
			{
				if (brandom())
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/burn1.wav"), 1, ATTN_NORM, 0);
				else
					gi.sound(current_player, CHAN_VOICE, gi.soundindex("player/burn2.wav"), 1, ATTN_NORM, 0);
				current_player->pain_debounce_time = level.time + 1_sec;
			}

			int dmg = (envirosuit ? 1 : 3) * waterlevel; // take 1/3 damage with envirosuit

			T_Damage(current_player, world, world, vec3_origin, current_player->s.origin, vec3_origin, dmg, 0, DAMAGE_NONE, MOD_LAVA);
			current_player->slime_debounce_time = level.time + 10_hz;
		}

		if (current_player->watertype & CONTENTS_SLIME)
		{
			if (!envirosuit)
			{ // no damage from slime with envirosuit
				T_Damage(current_player, world, world, vec3_origin, current_player->s.origin, vec3_origin, 1 * waterlevel, 0, DAMAGE_NONE, MOD_SLIME);
				current_player->slime_debounce_time = level.time + 10_hz;
			}
		}
	}
*/
const string ENVIROITEM_NAME		= "item_enviro";
const string ENVIROWEAP_NAME		= "weapon_q2envirosuit";
const float ENVIRO_DURATION		= 30.0;
const float ENVIRO_RESPAWN			= 60.0;
const string MODEL_ENVIRO			= "models/quake2/items/enviro.mdl";
const string ENVIRO_KVN				= "$i_q2enviro";
const string ENVIRO_KVN_TIME		= "$f_q2envirotime";
const string ENVIRO_ICON				= "quake2/pics/p_envirosuit.spr";

final class item_enviro : ScriptBaseItemEntity, item_q2pickup
{
	item_enviro()
	{
		m_iItemID = IT_ITEM_ENVIROSUIT;
		m_iWorldModelFlags = EF_ROTATE;
		m_sModel = MODEL_ENVIRO;
		m_sSound = "quake2/items/pkup.wav";
		m_flRespawnTime = ENVIRO_RESPAWN;
	}
}

class weapon_q2envirosuit : ScriptBasePlayerWeaponEntity
{
	protected CBasePlayer@ m_pPlayer
	{
		get const { return cast<CBasePlayer@>(self.m_hPlayer.GetEntity()); }
		set { self.m_hPlayer = EHandle(@value); }
	}

	void Spawn()
	{
		Precache();
		g_EntityFuncs.SetModel( self, MODEL_ENVIRO );

		self.FallInit();
	}

	void Precache()
	{
		g_Game.PrecacheModel( MODEL_ENVIRO );

		g_SoundSystem.PrecacheSound( "quake2/items/airout.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/u_breath1.wav" );
		g_SoundSystem.PrecacheSound( "quake2/player/u_breath2.wav" );

		//Precache these for downloading
		g_Game.PrecacheGeneric( "sprites/quake2/items/" + ENVIROWEAP_NAME + ".txt" );
		g_Game.PrecacheGeneric( "sprites/quake2/items/envirosuit.spr" );
		g_Game.PrecacheGeneric( "sprites/quake2/pics/p_envirosuit.spr" );
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iMaxAmmo1	= -1;
		info.iMaxClip			= WEAPON_NOCLIP;
		info.iSlot				= ENVIRO_SLOT - 1;
		info.iPosition			= ENVIRO_POSITION - 1;
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
			m1.WriteLong( g_ItemRegistry.GetIdForName(ENVIROWEAP_NAME) );
		m1.End();

		return true;
	}

	bool CanDeploy()
	{
		CustomKeyvalues@ pCustom = m_pPlayer.GetCustomKeyvalues();

		if( pCustom.GetKeyvalue(ENVIRO_KVN).GetInteger() >= 1 )
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
			q2items::GetHudParams( m_pPlayer, q2items::IT_ITEM_ENVIROSUIT, hudParams );

			float flDuration = ENVIRO_DURATION;
			if( pCustom.GetKeyvalue(ENVIRO_KVN).GetInteger() >= 1 )
				flDuration += pCustom.GetKeyvalue(ENVIRO_KVN_TIME).GetFloat() - g_Engine.time; //add the remaining time

			hudParams.value = flDuration;
			g_PlayerFuncs.HudTimeDisplay( m_pPlayer, hudParams );

			pCustom.SetKeyvalue( ENVIRO_KVN, 1 );
			pCustom.SetKeyvalue( ENVIRO_KVN_TIME, g_Engine.time + flDuration ); //start the fading sound

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

void RunEnvirosuit( CBasePlayer@ pPlayer )
{
	if( IsItemActive(pPlayer, IT_ITEM_ENVIROSUIT) )
	{
		if( pPlayer.pev.waterlevel == WATERLEVEL_HEAD )
		{
			pPlayer.pev.air_finished = g_Engine.time + 10;

			CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
			float flBreatherTime = pCustom.GetKeyvalue(ENVIRO_KVN_TIME).GetFloat();
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
//G_AddBlend(0, 1, 0, 0.08f, ent->client->ps.screen_blend);
void FadeEnvirosuit( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flItemFadeTime= pCustom.GetKeyvalue(ENVIRO_KVN_TIME).GetFloat();

	if( flItemFadeTime > 0.0 )
	{
		int iItemState = pCustom.GetKeyvalue(ENVIRO_KVN).GetInteger();

		if( g_Engine.time > (flItemFadeTime - 2.983) and iItemState == 1 )
		{
			EnviroFadeMessage( pPlayer );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/items/airout.wav", VOL_NORM, ATTN_NORM ); //CHAN_ITEM
			pCustom.SetKeyvalue( ENVIRO_KVN, 2 );
		}
		else if( g_Engine.time > flItemFadeTime and iItemState == 2 )
		{
			flItemFadeTime = 0.0;
			EnviroResetPlayer( pPlayer );
		}
	}
}

void EnviroFadeMessage( CBasePlayer@ pPlayer )
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

	g_PlayerFuncs.HudMessage( pPlayer, textParms, "Envirosuit is wearing off!\n" );
}

void EnviroResetPlayer( CBasePlayer@ pPlayer )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( ENVIRO_KVN, 0 );
	pCustom.SetKeyvalue( ENVIRO_KVN_TIME, 0.0 );

	g_PlayerFuncs.HudToggleElement( pPlayer, q2items::ENVIRO_HUD_CHANNEL, false );
}

} //end of namespace q2items
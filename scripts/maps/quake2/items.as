mixin class item_q2generic
{
	private CBasePlayer@ m_pPlayer = null;
	string m_sModel;
	string m_sSound;
	float m_flRespawnTime;
	bool m_bIsHealthItem = false;
	CScheduledFunction@ m_pRotFunc;
	CScheduledFunction@ m_pEndFunc;

	void CommonSpawn()
	{
		Precache();
		BaseClass.Spawn();
		self.FallInit();
		g_EntityFuncs.SetModel( self, m_sModel );
		self.pev.movetype = MOVETYPE_NONE;
		self.pev.scale = 2.0f;
		self.pev.noise = m_sSound; // this actually doesn't work, so have to schedule later
		g_EntityFuncs.DispatchKeyValue( self.edict(), "m_flCustomRespawnTime", m_flRespawnTime );

		if( !m_bIsHealthItem )
			@m_pRotFunc = @g_Scheduler.SetInterval( this, "RotateThink", 0.01f, g_Scheduler.REPEAT_INFINITE_TIMES );

		@m_pEndFunc = null;

		if( !m_bIsHealthItem )
		{
			TraceResult tr;
			Vector vecStart = self.pev.origin;
			Vector vecEnd = vecStart + g_Engine.v_up * -ITEM_LEVITATE_HEIGHT;
			g_Utility.TraceLine( vecStart, vecEnd, dont_ignore_monsters, self.edict(), tr );
			
			if( tr.flFraction < 1.0f )
			{
				if (tr.pHit !is null)
				{
					CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
					
					if( pHit is null || pHit.IsBSPModel() == true )
						self.pev.origin.z = tr.vecEndPos.z + ITEM_LEVITATE_HEIGHT;
				}
			}
		}
	}

	void Precache()
	{
		g_Game.PrecacheModel( m_sModel );
		g_SoundSystem.PrecacheSound( m_sSound );
	}

	void RotateThink()
	{
		self.pev.angles.y += 1.0f;
	}

	bool AddToPlayer( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		// CBasePlayerItem@ pPrev = pPlayer.m_pActiveItem;
		if( BaseClass.AddToPlayer(pPlayer) )
		{
			// pPlayer.SwitchWeapon(pPrev);
			if( ApplyEffects(pPlayer) )
			{
				NetworkMessage message( MSG_ONE, NetworkMessages::ItemPickup, pPlayer.edict() );
					message.WriteString( self.pszName() );
				message.End();

				g_Scheduler.RemoveTimer( m_pRotFunc );
				@m_pRotFunc = null;
				q2_ScheduleItemSound( pPlayer, m_sSound );
				return true;
			}
		}
		return false;
	}

	void UpdateOnRemove()
	{
		if( !(m_pRotFunc is null) )
			g_Scheduler.RemoveTimer( m_pRotFunc );

		if( !(m_pEndFunc is null) )
			g_Scheduler.RemoveTimer( m_pEndFunc );

		BaseClass.UpdateOnRemove();
	}

	void KillSelf()
	{
		if( m_pPlayer.HasPlayerItem(self) )
			m_pPlayer.RemovePlayerItem( self );

		g_EntityFuncs.Remove( self );
	}

	CBasePlayerWeapon@ GetWeaponPtr()
	{
		return null;
	}
}

mixin class item_q2weapon
{
	void CommonSpawn()
	{
		TraceResult tr;
		Vector vecSrc = self.pev.origin;
		Vector vecEnd = vecSrc + g_Engine.v_up * -ITEM_LEVITATE_HEIGHT;
		g_Utility.TraceLine( vecSrc, vecEnd, dont_ignore_monsters, self.edict(), tr );
		
		if( tr.flFraction < 1.0f )
		{
			if (tr.pHit !is null)
			{
				CBaseEntity@ pHit = g_EntityFuncs.Instance( tr.pHit );
				
				if( pHit is null || pHit.IsBSPModel() == true )
					self.pev.origin.z = tr.vecEndPos.z + ITEM_LEVITATE_HEIGHT;
			}
		}
	}
}

class item_q2quad : ScriptBasePlayerItemEntity, item_q2generic
{
	private CBasePlayer@ m_pPlayer = null;

	void Spawn()
	{
		m_sModel = "models/quake2/w_quad.mdl";
		m_sSound = "quake2/quad_activate.wav";
		g_SoundSystem.PrecacheSound( "quake2/quad_fire.wav" );
		CommonSpawn();
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor.z = 255;
		pPlayer.pev.renderamt = 16;
		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "FadeSound", 27.017f );

		return true;
	}

	void FadeSound()
	{
		if( m_pPlayer is null ) return;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/quad_fade.wav", 1.0f, ATTN_NORM );
		
		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "RemoveEffects", 2.983f );
	}

	void RemoveEffects()
	{
		if( m_pPlayer is null ) return;

		m_pPlayer.pev.rendercolor.z = 0;

		if( m_pPlayer.HasNamedPlayerItem("item_qsuit") is null && m_pPlayer.HasNamedPlayerItem("item_q2invul") is null )
		{
			m_pPlayer.pev.renderfx = kRenderFxNone;
			m_pPlayer.pev.renderamt = 0;
		}

		KillSelf();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;

		return true;
	}
}

class item_q2invul : ScriptBasePlayerItemEntity, item_q2generic
{
	private CBasePlayer@ m_pPlayer = null;
	void Spawn()
	{
		m_sModel = "models/quake2/w_invul.mdl";
		m_sSound = "quake2/invul_activate.wav";
		g_SoundSystem.PrecacheSound( "quake2/invul_hit.wav" );
		CommonSpawn();
	}

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;
		pPlayer.pev.renderfx = kRenderFxGlowShell;
		pPlayer.pev.rendercolor.x = 255;
		pPlayer.pev.renderamt = 16;
		pPlayer.pev.flags |= FL_GODMODE;
		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "FadeSound", 27.017f );
		return true;
	}

	void FadeSound()
	{
		if( m_pPlayer is null ) return;

		g_SoundSystem.EmitSound( m_pPlayer.edict(), CHAN_STATIC, "quake2/invul_fade.wav", 1.0f, ATTN_NORM );
		
		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "RemoveEffects", 2.983f );
	}

	void RemoveEffects()
	{
		if( m_pPlayer is null ) return;

		m_pPlayer.pev.rendercolor.x = 0;

		if( m_pPlayer.HasNamedPlayerItem("item_q2quad") is null )
		{
			m_pPlayer.pev.renderfx = kRenderFxNone;
			m_pPlayer.pev.renderamt = 0;
		}

		m_pPlayer.pev.flags &= ~FL_GODMODE;
		KillSelf();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;
		return true;
	}
}

mixin class item_q2armor
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iArmor;
	int m_iArmorMax;
	bool m_bArmorShard = false;
	bool m_bArmorBody = false;

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;

		if( !m_bArmorShard )
			if( pPlayer.pev.armorvalue >= m_iArmorMax ) return false;

		pPlayer.pev.armorvalue += m_iArmor;

		if( !m_bArmorBody )
		{
			if( pPlayer.pev.armorvalue > m_iArmorMax )
			{
				if( !m_bArmorShard )
				{
					pPlayer.pev.armorvalue = m_iArmorMax;
					pPlayer.pev.armortype = PLAYER_MAX_ARMOR;
				}
				else
					pPlayer.pev.armortype = pPlayer.pev.armorvalue;
			}
		}
		else
		{
			if( pPlayer.pev.armorvalue > m_iArmorMax )
			{
				pPlayer.pev.armorvalue = m_iArmorMax;
				pPlayer.pev.armortype = m_iArmorMax;
			}
		}

		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "RemoveEffects", 0.1f );

		return true;
	}

	void RemoveEffects()
	{
		if( m_pPlayer is null ) return;

		KillSelf();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;

		return true;
	}
}
//Armor Shard
class item_q2armor1 : ScriptBasePlayerItemEntity, item_q2generic, item_q2armor
{
	void Spawn()
	{
		m_iArmor = 2;
		m_bArmorShard = true;
		m_sModel = "models/quake2/w_q2armor1.mdl";
		m_sSound = "quake2/item_q2armor1.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Jacket Armor
class item_q2armor2 : ScriptBasePlayerItemEntity, item_q2generic, item_q2armor
{
	void Spawn()
	{
		m_iArmor = 25;
		m_iArmorMax = 50;
		m_sModel = "models/quake2/w_q2armor2.mdl";
		m_sSound = "quake2/item_q2armor2.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Combat Armor
class item_q2armor3 : ScriptBasePlayerItemEntity, item_q2generic, item_q2armor
{
	void Spawn()
	{
		m_iArmor = 50;
		m_iArmorMax = 100;
		m_sModel = "models/quake2/w_q2armor3.mdl";
		m_sSound = "quake2/item_q2armor2.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Body Armor
class item_q2armor4 : ScriptBasePlayerItemEntity, item_q2generic, item_q2armor
{
	void Spawn()
	{
		m_iArmor = 100;
		m_iArmorMax = 200;
		m_bArmorBody = true;
		m_sModel = "models/quake2/w_q2armor4.mdl";
		m_sSound = "quake2/item_q2armor2.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}

mixin class item_q2health
{
	private CBasePlayer@ m_pPlayer = null;
	int m_iHealth;
	bool m_bStimpack = false;
	bool m_bMegaHealth = false;

	bool ApplyEffects( CBasePlayer@ pPlayer )
	{
		@m_pPlayer = pPlayer;

		if( !m_bStimpack && !m_bMegaHealth )
			if( pPlayer.pev.health >= PLAYER_MAX_HEALTH ) return false;

		pPlayer.pev.health += m_iHealth;

		if( pPlayer.pev.health > PLAYER_MAX_HEALTH )
		{
			if( !m_bStimpack && !m_bMegaHealth )
			{
				pPlayer.pev.health = PLAYER_MAX_HEALTH;
				pPlayer.pev.max_health = PLAYER_MAX_HEALTH;
			}
			else if( m_bStimpack )
				pPlayer.pev.max_health = pPlayer.pev.health;
			else if( m_bMegaHealth )
				pPlayer.pev.max_health = PLAYER_MAX_HEALTH;
		}

		@m_pEndFunc = @g_Scheduler.SetTimeout( this, "RemoveEffects", 0.1f );

		return true;
	}

	void RemoveEffects()
	{
		if( m_pPlayer is null ) return;

		KillSelf();
	}

	bool GetItemInfo( ItemInfo& out info )
	{
		info.iWeight = -1;

		return true;
	}
}
//Stimpack
class item_q2health1 : ScriptBasePlayerItemEntity, item_q2generic, item_q2health
{
	void Spawn()
	{
		m_iHealth = 2;
		m_bStimpack = true;
		m_bIsHealthItem = true;
		m_sModel = "models/quake2/w_q2health1.mdl";
		m_sSound = "quake2/item_q2health1.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Medium Health
class item_q2health2 : ScriptBasePlayerItemEntity, item_q2generic, item_q2health
{
	void Spawn()
	{
		m_iHealth = 10;
		m_bIsHealthItem = true;
		m_sModel = "models/quake2/w_q2health2.mdl";
		m_sSound = "quake2/item_q2health2.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Large Health
class item_q2health3 : ScriptBasePlayerItemEntity, item_q2generic, item_q2health
{
	void Spawn()
	{
		m_iHealth = 25;
		m_bIsHealthItem = true;
		m_sModel = "models/quake2/w_q2health3.mdl";
		m_sSound = "quake2/item_q2health3.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}
//Mega Health
class item_q2health4 : ScriptBasePlayerItemEntity, item_q2generic, item_q2health
{
	void Spawn()
	{
		m_iHealth = 100;
		m_bIsHealthItem = true;
		m_bMegaHealth = true;
		m_sModel = "models/quake2/w_q2health4.mdl";
		m_sSound = "quake2/item_q2health4.wav";
		m_flRespawnTime = 2;//20
		CommonSpawn();
		self.pev.scale = 0.9f;
	}
}

void q2_ScheduleItemSound( CBasePlayer @pPlayer, string m_sSound )
{
	g_Scheduler.SetTimeout( "q2_ScheduledItemSound", 0.001f, @pPlayer, m_sSound );
}

void q2_ScheduledItemSound( CBasePlayer @pPlayer, string m_sSound )
{
	g_SoundSystem.StopSound( pPlayer.edict(), CHAN_ITEM, "items/gunpickup2.wav", true );
	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_ITEM, m_sSound, 1.0, ATTN_NORM );
}

void q2_RegisterItems()
{
	g_Game.PrecacheModel( "models/quake2/w_quad.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_invul.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2armor1.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2armor2.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2armor3.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2armor4.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2health1.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2health2.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2health3.mdl" );
	g_Game.PrecacheModel( "models/quake2/w_q2health4.mdl" );
	g_SoundSystem.PrecacheSound( "quake2/item_respawn.wav" );

	//needed here for spawning in-game.
	g_SoundSystem.PrecacheSound( "quake2/quad_activate.wav" );
	g_SoundSystem.PrecacheSound( "quake2/quad_fire.wav" );
	g_SoundSystem.PrecacheSound( "quake2/quad_fade.wav" );
	g_SoundSystem.PrecacheSound( "quake2/invul_activate.wav" );
	g_SoundSystem.PrecacheSound( "quake2/invul_hit.wav" );
	g_SoundSystem.PrecacheSound( "quake2/invul_fade.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2armor1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2armor2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2health1.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2health2.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2health3.wav" );
	g_SoundSystem.PrecacheSound( "quake2/item_q2health4.wav" );

	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2quad", "item_q2quad" );
	g_ItemRegistry.RegisterItem( "item_q2quad", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity("item_q2invul", "item_q2invul");
	g_ItemRegistry.RegisterItem("item_q2invul", "quake2/items");
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2armor1", "item_q2armor1" );
	g_ItemRegistry.RegisterItem( "item_q2armor1", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2armor2", "item_q2armor2" );
	g_ItemRegistry.RegisterItem( "item_q2armor2", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2armor3", "item_q2armor3" );
	g_ItemRegistry.RegisterItem( "item_q2armor3", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2armor4", "item_q2armor4" );
	g_ItemRegistry.RegisterItem( "item_q2armor4", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2health1", "item_q2health1" );
	g_ItemRegistry.RegisterItem( "item_q2health1", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2health2", "item_q2health2" );
	g_ItemRegistry.RegisterItem( "item_q2health2", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2health3", "item_q2health3" );
	g_ItemRegistry.RegisterItem( "item_q2health3", "quake2/items" );
	g_CustomEntityFuncs.RegisterCustomEntity( "item_q2health4", "item_q2health4" );
	g_ItemRegistry.RegisterItem( "item_q2health4", "quake2/items" );

	/*g_CustomEntityFuncs.RegisterCustomEntity("item_qbackpack", "item_qbackpack");
	g_ItemRegistry.RegisterItem("item_qbackpack", "quake2/items");*/
}
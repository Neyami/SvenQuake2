namespace q2
{

const string KVN_FOOTSTEP			= "$f_q2footstep";
const string KVN_FOOTSTEP_LEFT	= "$i_q2footstepleft";
const string KVN_FOOTSTEP_SKIP	= "$i_q2footstepskip";

const int CHAR_TEX_ENERGY			= 40; //E
const int CHAR_TEX_CARPET			= 41; //A

const int STEP_ENERGY					= 40;
const int STEP_CARPET					= 41;

dictionary pQ2Textures;

//from quake 2 rerelease
Vector slerp( const Vector &in vecFrom, const Vector &in vecTo, float t )
{
	float flDot = DotProduct( vecFrom, vecTo );
    float aFactor;
    float bFactor;

    if( flDot > 0.9995 ) //fabsf(flDot)
    {
        aFactor = 1.0 - t;
        bFactor = t;
    }
    else
    {
        float ang = acos( flDot );
        float sinOmega = sin( ang );
        float sinAOmega = sin( (1.0 - t) * ang );
        float sinBOmega = sin( t * ang );
        aFactor = sinAOmega / sinOmega;
        bFactor = sinBOmega / sinOmega;
    }

    return vecFrom * aFactor + vecTo * bFactor;
}

//from quake 2 rerelease
void T_RadiusDamage( CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, float flDamage, CBaseEntity@ pIgnore, float flRadius, int bitsDamageType, int mod = MOD_UNKNOWN )
{
	if( pIgnore is null ) @pIgnore = pInflictor;

	float flPoints;
	CBaseEntity@ pEnt = null;
	Vector vecWhat;
	Vector vecDir;
	Vector vecInflictorCenter;

//This boolean indicates whether the entity is currently linked into the world or not. It is the replacement of checking for `area.prev` being non-null.
	//if( pInflictor.linked )
		vecInflictorCenter = (pInflictor.pev.absmax + pInflictor.pev.absmin) * 0.5;
	//else
		//vecInflictorCenter = pInflictor.pev.origin;

	while( (@pEnt = g_EntityFuncs.FindEntityInSphere(pEnt, vecInflictorCenter, flRadius, "*", "classname")) !is null )
	{
		if( pEnt is pIgnore )
			continue;

		if( pEnt.pev.takedamage == DAMAGE_NO )
			continue;

		if( pEnt.pev.solid == SOLID_BSP /*and pEnt.linked*/ )
			vecWhat = closest_point_to_box( vecInflictorCenter, pEnt.pev.absmin, pEnt.pev.absmax );
		else
		{
			vecWhat = pEnt.pev.mins + pEnt.pev.maxs;
			vecWhat = pEnt.pev.origin + (vecWhat * 0.5);
		}

		vecWhat = vecInflictorCenter - vecWhat;
		flPoints = flDamage - 0.5 * vecWhat.Length();

		if( pEnt is pAttacker )
			flPoints *= 0.5;

		if( flPoints > 0 )
		{
			if( CanDamage(pEnt, pInflictor) )
			{
				vecDir = (pEnt.pev.origin - vecInflictorCenter).Normalize();

				T_Damage( pEnt, pInflictor, pAttacker, vecDir, closest_point_to_box(vecInflictorCenter, pEnt.pev.absmin, pEnt.pev.absmax), vecDir, flPoints, flPoints, bitsDamageType/* | DAMAGE_RADIUS*/, mod );
				//if( !((pEnt.pev.FlagBitSet(FL_CLIENT) and pEnt !is pAttacker) and !q2::PVP) ) //deals damage to players otherwise
					//pEnt.TakeDamage( pInflictor.pev, pAttacker.pev, flPoints, bitsDamageType );
			}
		}
	}
}

//from quake 2
void T_Damage( CBaseEntity@ pTarget, CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, Vector vecDir, Vector vecPoint, Vector vecNormal, float flDamage, float flKnockback, int bitsDamageType, int mod = MOD_UNKNOWN )
{
	if( pTarget.pev.takedamage == DAMAGE_NO )
		return;

	float flTake;
	float flSave;
	float flAsave;
	float flPsave;
	//int te_sparks;

	// friendly fire avoidance
	// if enabled you can't hurt teammates (but you can hurt yourself)
	if( pAttacker !is null and pAttacker.pev.FlagBitSet(FL_CLIENT) )
	{
		if( pTarget !is pAttacker and pTarget.pev.FlagBitSet(FL_CLIENT) and !q2::PVP )
		{
			flDamage = 0.0;
			flKnockback = 0.0;
		}
	}

	//meansOfDeath = mod;

	// easy mode takes half damage
	if( q2npc::g_iDifficulty == q2npc::DIFF_EASY and !q2::PVP and pTarget.pev.FlagBitSet(FL_CLIENT) )
	{
		flDamage *= 0.5;
		if( flDamage <= 0.0 )
			flDamage = 1.0;
	}
/*
	if( (bitsDamageType & DAMAGE_BULLET) != 0 )
		te_sparks = TE_BULLET_SPARKS;
	else
		te_sparks = TE_SPARKS;*/

	vecDir = vecDir.Normalize();
/*
// bonus damage for suprising a monster
	if( !(bitsDamageType & DAMAGE_RADIUS) and (pTarget.svflags & SVF_MONSTER) and pAttacker.pev.FlagBitSet(FL_CLIENT) and (!pTarget.enemy) and pTarget.pev.health > 0 )
		flDamage *= 2.0;

	if( pTarget.flags & FL_NO_KNOCKBACK )
		flKnockback = 0.0;
*/
	//figure momentum add
	if( (bitsDamageType & DMG_LAUNCH) != 0 )
	{
		bitsDamageType &= ~DMG_LAUNCH;

		if( flKnockback > 0.0 and pTarget.pev.movetype != MOVETYPE_NONE and pTarget.pev.movetype != MOVETYPE_BOUNCE and pTarget.pev.movetype != MOVETYPE_PUSH/* and (pTarget.movetype != MOVETYPE_STOP)*/ )
		{
			Vector vecKvel;
			float flMass = 200; //player

			float flTargetMass = GetMassForTarget( pTarget, 200, 50, 2000 );
			if( flTargetMass < 50 )
				flMass = 50;
			else
				flMass = flTargetMass;

			if( pTarget.pev.FlagBitSet(FL_CLIENT) and pAttacker is pTarget )
				vecKvel = vecDir * (1600.0 * flKnockback / flMass); //rocket jump hack
			else
				vecKvel = vecDir * (500.0 * flKnockback / flMass);

			pTarget.pev.velocity = pTarget.pev.velocity + vecKvel;
		}
	}

	flTake = flDamage;
	flSave = 0.0;

	// check for godmode
	if( pTarget.pev.FlagBitSet(FL_GODMODE)/* and !(bitsDamageType & DAMAGE_NO_PROTECTION)*/ )
	{
		flTake = 0.0;
		flSave = flDamage;
		//SpawnDamage (te_sparks, vecPoint, vecNormal, flSave);
	}

	flPsave = CheckPowerArmor( pTarget, vecPoint, vecNormal, flTake, bitsDamageType );
	flTake -= flPsave;

	flAsave = CheckArmor( pTarget, vecPoint, vecNormal, flTake );
	flTake -= flAsave;

	//treat cheat/powerup savings the same as armor
	flAsave += flSave;

	//do the damage
	if( flTake > 0.0 )
	{
		/*if( pTarget.pev.FlagBitSet(FL_MONSTER) or pTarget.pev.FlagBitSet(FL_CLIENT) )
			SpawnDamage (TE_BLOOD, vecPoint, vecNormal, flTake);
		else
			SpawnDamage (te_sparks, vecPoint, vecNormal, flTake);*/

		if( pTarget !is null )
		{
			CustomKeyvalues@ pCustom = pTarget.GetCustomKeyvalues();
			pCustom.SetKeyvalue( KVN_MOD, mod );
			//g_Game.AlertMessage( at_notice, "MODE OF DEATH SET TO %1\n", mod );
		}

		//this works with the custom death messages
		entvars_t@ entAttacker;
		if( pAttacker is null )
			@entAttacker = pInflictor.pev;
		else
			@entAttacker = pAttacker.pev;

		pTarget.TakeDamage( pInflictor.pev, entAttacker, flTake, bitsDamageType ); //bitsDamageType

		//this doesn't
		/*pTarget.pev.health = pTarget.pev.health - flTake;
		if( pTarget.pev.health <= 0 )
		{
			//if( pTarget.pev.FlagBitSet(FL_MONSTER) or pTarget.pev.FlagBitSet(FL_CLIENT) )
				//pTarget.flags |= FL_NO_KNOCKBACK;

			pTarget.Killed( pAttacker.pev, GIB_NORMAL );
			//Killed( pTarget, pInflictor, pAttacker, flTake, vecPoint );
		}*/
	}

/*
	if (targ->svflags & SVF_MONSTER)
	{
		M_ReactToDamage (targ, attacker);
		if (!(targ->monsterinfo.aiflags & AI_DUCKED) && (take))
		{
			targ->pain (targ, attacker, knockback, take);
			// nightmare mode monsters don't go into pain frames often
			if (skill->value == 3)
				targ->pain_debounce_time = level.time + 5;
		}
	}
*/
}

float GetMassForTarget( CBaseEntity@ pTarget, float flBaseScale, float flMinScale, float flMaxScale, float flScaleIncrease = 0.4, float flScaleDecrease = 1.5 )
{
	float flBaseMobVolume = 73728; //player size
	float flScale;

	float flMobVolume = (pTarget.pev.size.x * pTarget.pev.size.y * pTarget.pev.size.z);
	if( flMobVolume > flBaseMobVolume ) flScale = (flBaseScale * (flMobVolume/flBaseMobVolume)) * flScaleIncrease;
	else if( flMobVolume < flBaseMobVolume ) flScale = (flBaseScale / (flBaseMobVolume/flMobVolume)) * flScaleDecrease;
	else flScale = flBaseScale;

	return Math.clamp( flMinScale, flMaxScale, flScale );
}

//from quake 2 rerelease
bool CanDamage( CBaseEntity@ pTarget, CBaseEntity@ pInflictor )
{
	Vector vecDest;
	TraceResult trace;

	// bmodels need special checking because their origin is 0,0,0
	Vector vecIinflictorCenter;

	//if( pInflictor.linked )
	if( pInflictor.pev.solid == SOLID_BSP )
		vecIinflictorCenter = (pInflictor.pev.absmin + pInflictor.pev.absmax) * 0.5;
	else
		vecIinflictorCenter = pInflictor.pev.origin;

	if( pTarget.pev.solid == SOLID_BSP )
	{
		vecDest = closest_point_to_box( vecIinflictorCenter, pTarget.pev.absmin, pTarget.pev.absmax );

		//trace = gi.traceline(vecIinflictorCenter, vecDest, pInflictor, MASK_SOLID);
		g_Utility.TraceLine( vecIinflictorCenter, vecDest, ignore_monsters, pInflictor.edict(), trace );
		if( trace.flFraction == 1.0 )
			return true;
	}

	Vector vecTargCenter;

	//if( pTarget.linked )
		vecTargCenter = (pTarget.pev.absmin + pTarget.pev.absmax) * 0.5;
	//else
		//vecTargCenter = pTarget.pev.origin;

	g_Utility.TraceLine( vecIinflictorCenter, vecTargCenter, ignore_monsters, pInflictor.edict(), trace ); //MASK_SOLID
	if( trace.flFraction == 1.0 )
		return true;

	vecDest = vecTargCenter;
	vecDest.x += 15.0;
	vecDest.y += 15.0;

	g_Utility.TraceLine( vecIinflictorCenter, vecDest, ignore_monsters, pInflictor.edict(), trace ); //MASK_SOLID
	if (trace.flFraction == 1.0 )
		return true;

	vecDest = vecTargCenter;
	vecDest.x += 15.0;
	vecDest.y -= 15.0;

	g_Utility.TraceLine( vecIinflictorCenter, vecDest, ignore_monsters, pInflictor.edict(), trace ); //MASK_SOLID
	if( trace.flFraction == 1.0 )
		return true;

	vecDest = vecTargCenter;
	vecDest.x -= 15.0;
	vecDest.y += 15.0;

	g_Utility.TraceLine( vecIinflictorCenter, vecDest, ignore_monsters, pInflictor.edict(), trace ); //MASK_SOLID
	if( trace.flFraction == 1.0 )
		return true;

	vecDest = vecTargCenter;
	vecDest.x -= 15.0;
	vecDest.y -= 15.0;

	g_Utility.TraceLine( vecIinflictorCenter, vecDest, ignore_monsters, pInflictor.edict(), trace ); //MASK_SOLID
	if( trace.flFraction == 1.0 )
		return true;

	return false;
}

//from quake 2
float CheckPowerArmor( CBaseEntity@ pEnt, Vector vecPoint, Vector vecNormal, float flDamage, int bitsDamageType )
{
	float flSave;
	int iPowerArmorType;
	int iDamagePerCell;
	//int			pa_te_type;
	int iPower;
	int iPowerUsed;

	if( pEnt.pev.health <= 0.0 )
		return 0;

	if( flDamage <= 0.0 )
		return 0;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

	if( pPlayer !is null and pPlayer.IsAlive() )
	{
		iPowerArmorType = PowerArmorType( pPlayer );

		if( iPowerArmorType != q2::POWER_ARMOR_NONE )
			iPower = pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex("q2cells") );
	}
	else
		return 0;

	if( iPowerArmorType == q2::POWER_ARMOR_NONE )
		return 0;

	if( iPower <= 0 )
		return 0;

	if( iPowerArmorType == q2::POWER_ARMOR_SCREEN )
	{
		Vector vecDir;
		float flDot;
		Vector vecForward;

		//Only protect from frontal attacks
		Math.MakeVectors( pPlayer.pev.angles );
		vecDir = vecPoint - pPlayer.pev.origin;
		flDot = DotProduct( vecDir , g_Engine.v_forward );

		//if( flDot <= 0.3 )
		if( flDot > 0.3 ) //GetGlobalTrace is borked
			return 0;

		//g_Game.AlertMessage( at_notice, "HIT POWER SCREEN!\n" );
		iDamagePerCell = 1;
		//pa_te_type = TE_SCREEN_SPARKS;
		flDamage = flDamage / 3;
	}
	else
	{
		//g_Game.AlertMessage( at_notice, "HIT POWER SHIELD!\n" );
		iDamagePerCell = 2;
		//pa_te_type = TE_SHIELD_SPARKS;
		flDamage = (2 * flDamage) / 3;
	}

	flDamage = Math.max( 1.0, flDamage );

	flSave = iPower * iDamagePerCell;

	if( flSave <= 0.0 )
		return 0.0;

	//energy damage should do more to power armor, not ETF Rifle shots.
	if( (bitsDamageType & DMG_ENERGYBEAM) != 0 )
		flSave = Math.max( 1.0, flSave / 2 );

	if( flSave > flDamage )
		flSave = flDamage;

	// [Paril-KEX] energy damage should do more to power armor, not ETF Rifle shots.
	if( (bitsDamageType & DMG_ENERGYBEAM) != 0 )
		iPowerUsed = int( (flSave / iDamagePerCell) * 2 );
	else
		iPowerUsed = int( flSave / iDamagePerCell );

	iPowerUsed = Math.max( 1, iPowerUsed );

	//SpawnDamage (pa_te_type, vecPoint, vecNormal, flSave);
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	pCustom.SetKeyvalue( q2items::PARMOR_KVN_EFFECT, g_Engine.time + 0.2 );

	g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/weapons/lashit.wav", VOL_NORM, ATTN_NORM );

	/*case TE_SCREEN_SPARKS:
	case TE_SHIELD_SPARKS:
		MSG_ReadPos (&net_message, pos);
		MSG_ReadDir (&net_message, dir);
		if (type == TE_SCREEN_SPARKS)
			CL_ParticleEffect (pos, dir, 0xd0, 40);
		else
			CL_ParticleEffect (pos, dir, 0xb0, 40);
		//FIXME : replace or remove this sound
		S_StartSound (pos, 0, 0, cl_sfx_lashit, 1, ATTN_NORM, 0);
		break;*/

	pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex("q2cells"), pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells")) - iPowerUsed );

	//adjustment so that power armor
	//always uses iDamagePerCell even if it does
	//only a single point of damage
	iPower = Math.max( 0, iPower - Math.max(iDamagePerCell, iPowerUsed) );

	// check power armor turn-off states
	G_CheckPowerArmor( pEnt );

	return flSave;
}

//from quake 2
int PowerArmorType( CBasePlayer@ pPlayer )
{
	if( pPlayer is null or !pPlayer.IsAlive() )
		return q2::POWER_ARMOR_NONE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	if( !pCustom.GetKeyvalue(q2items::PARMOR_KVN).Exists() )
		return q2::POWER_ARMOR_NONE;

	//just return q2items::PARMOR_KVN ??
	if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() == q2::POWER_ARMOR_SHIELD )
		return q2::POWER_ARMOR_SHIELD;

	if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() == q2::POWER_ARMOR_SCREEN )
		return q2::POWER_ARMOR_SCREEN;

	return q2::POWER_ARMOR_NONE;
}

//from quake 2
float CheckArmor( CBaseEntity@ pEnt, Vector vecPoint, Vector vecNormal, float flDamage )
{
	float flSave;

	if( flDamage <= 0.0 )
		return 0;

	CBasePlayer@ pPlayer = cast<CBasePlayer@>(pEnt);

	if( pPlayer is null or !pPlayer.IsAlive() )
		return 0;

	if( pEnt.pev.armorvalue <= 0 )
		return 0;

	flSave = Math.Ceil( flDamage * 0.6 ); //jacket armor: 0.3, combat armor: 0.6, body armor: 0.8

	if( flSave >= pEnt.pev.armorvalue )
		flSave = pEnt.pev.armorvalue;

	if( flSave <= 0 )
		return 0;

	pEnt.pev.armorvalue -= flSave;

	return flSave;
}

//from quake 2 rerelease
void G_CheckPowerArmor( CBaseEntity@ pEnt )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>( pEnt );
	if( pPlayer is null ) return;

	q2items::UpdatePowerArmorHUD( pPlayer );

	bool bHasEnoughCells;

	if( pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells")) <= 0)
		bHasEnoughCells = false;
	//else if (pEnt->client->pers.autoshield >= AUTO_SHIELD_AUTO)
		//bHasEnoughCells = (pEnt->flags & FL_WANTS_POWER_ARMOR) and pEnt->client->pers.inventory[IT_AMMO_CELLS] > pEnt->client->pers.autoshield;
	else
		bHasEnoughCells = true;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() > 0 )
	{
		if( !bHasEnoughCells )
		{
			// ran out of cells for power armor
			pCustom.SetKeyvalue( q2items::PARMOR_KVN, 0 );
			g_SoundSystem.EmitSound( pPlayer.edict(), CHAN_AUTO, "quake2/misc/power2.wav", VOL_NORM, ATTN_NORM );
		}
	}
	/*else
	{
		// special case for power armor, for auto-shields
		if (pEnt->client->pers.autoshield != AUTO_SHIELD_MANUAL and
			bHasEnoughCells and (pEnt->client->pers.inventory[IT_ITEM_POWER_SCREEN] or
				pEnt->client->pers.inventory[IT_ITEM_POWER_SHIELD]))
		{
			pEnt->flags |= FL_POWER_ARMOR;
			gi.sound(pEnt, CHAN_AUTO, gi.soundindex("misc/power1.wav"), 1, ATTN_NORM, 0);
		}
	}*/
}

//from quake 2 rerelease
Vector closest_point_to_box( const Vector &in from, const Vector &in absmins, const Vector &in absmaxs )
{
	return Vector(
		(from.x < absmins.x) ? absmins.x : (from.x > absmaxs.x) ? absmaxs.x : from.x,
		(from.y < absmins.y) ? absmins.y : (from.y > absmaxs.y) ? absmaxs.y : from.y,
		(from.z < absmins.z) ? absmins.z : (from.z > absmaxs.z) ? absmaxs.z : from.z
	);
}

void PM_UpdateStepSound( CBasePlayer@ pPlayer )
{
	bool bWalking;
	float fvol;
	float flSpeed;
	float flVelRun;
	float flVelWalk;
	float flDuck;
	bool bLadder;
	int iStep;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();
	float flTimeStepSound = pCustom.GetKeyvalue( KVN_FOOTSTEP ).GetFloat();

	if( flTimeStepSound > g_Engine.time )
		return;

	if( pPlayer.pev.FlagBitSet(FL_FROZEN) )
		return;

	//PM_CatagorizeTextureType();

	flSpeed = pPlayer.pev.velocity.Length();

	bLadder = ( pPlayer.pev.movetype == MOVETYPE_FLY );// IsOnLadder();

	if( pPlayer.pev.FlagBitSet(FL_DUCKING) or bLadder )
	{
		flVelWalk = 60;
		flVelRun = 80;
		flDuck = 0.1; //100
	}
	else
	{
		flVelWalk = 80; //120
		flVelRun = 210;
		flDuck = 0.0;
	}

	// If we're on a ladder or on the ground, and we're moving fast enough,
	//  play step sound.  Also, if flTimeStepSound is zero, get the new
	//  sound right away - we just started moving in new level.
	if( (bLadder or pPlayer.pev.FlagBitSet(FL_ONGROUND)) and pPlayer.pev.velocity.Length() > 0.0 and (flSpeed >= flVelWalk or flTimeStepSound <= 0.0) )
	{
		bWalking = flSpeed < flVelRun;

		// find out what we're stepping in or on...
		if( bLadder )
		{
			iStep = STEP_LADDER;
			fvol = 0.35;
			flTimeStepSound = 0.35; //350
		}
		else if( pPlayer.pev.waterlevel >= WATERLEVEL_WAIST )
		{
			iStep = STEP_WADE;
			fvol = 0.65;
			flTimeStepSound = 0.6; //600
		}
		else if( pPlayer.pev.waterlevel == WATERLEVEL_FEET )
		{
			iStep = STEP_SLOSH;
			fvol = bWalking ? 0.2 : 0.5;
			flTimeStepSound = bWalking ? 0.4 : 0.3; //400 : 300
		}
		else
		{
			iStep = MapTextureTypeStepType( CatagorizeTextureType(pPlayer) );

			switch( iStep )
			{
				case CHAR_TEX_WOOD:
				case CHAR_TEX_FLESH:
				case CHAR_TEX_SNOW:
				case CHAR_TEX_DIRT:
				{
					fvol = bWalking ? 0.25 : 0.55;
					flTimeStepSound = bWalking ? 0.4 : 0.3; //400 : 300
					break;
				}

				case CHAR_TEX_VENT:
				{
					fvol = bWalking ? 0.4 : 0.7;
					flTimeStepSound = bWalking ? 0.4 : 0.3; //400 : 300
					break;
				}

				case CHAR_TEX_METAL:
				case CHAR_TEX_GRATE:
				case CHAR_TEX_TILE:
				case CHAR_TEX_SLOSH:
				case CHAR_TEX_CARPET:
				case CHAR_TEX_ENERGY:
				case CHAR_TEX_CONCRETE:
				default:
				{
					fvol = bWalking ? 0.2 : 0.5;
					flTimeStepSound = bWalking ? 0.4 : 0.3; //400 : 300
					break;
				}
			}
		}
		
		flTimeStepSound += flDuck; // slower step time if ducking
		pCustom.SetKeyvalue( KVN_FOOTSTEP, g_Engine.time + flTimeStepSound );

		if( pPlayer.pev.FlagBitSet(FL_DUCKING) )
			fvol *= 0.35;

		PM_PlayStepSound( pPlayer, iStep, fvol );
	}
}

char CatagorizeTextureType( CBasePlayer@ pPlayer )
{
	Vector vecOrigin = pPlayer.pev.origin;

	TraceResult tr;
	g_Utility.TraceLine( vecOrigin, vecOrigin + Vector(0, 0, -64),  ignore_monsters, pPlayer.edict(), tr );

	edict_t@ pWorld = g_EntityFuncs.Instance(0).edict();
	if( tr.pHit !is null ) @pWorld = tr.pHit;

	string sTexture = g_Utility.TraceTexture( pWorld, vecOrigin, vecOrigin + Vector(0, 0, -64) );

	if( q2::pQ2Textures.exists(sTexture.ToLowercase()) )
		return string( pQ2Textures[sTexture] );

	return g_SoundSystem.FindMaterialType( sTexture );
}

void PM_PlayStepSound( CBasePlayer@ pPlayer, int iStep, float flVol )
{
	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	int iSkipStep = 0;
	int iRand;
	Vector hvel;

	int iStepLeft = pCustom.GetKeyvalue( KVN_FOOTSTEP_LEFT ).GetInteger();
	if( iStepLeft == 0 ) pCustom.SetKeyvalue( KVN_FOOTSTEP_LEFT, 1 );
		else pCustom.SetKeyvalue( KVN_FOOTSTEP_LEFT, 0 );

	iRand = Math.RandomLong(0, 1) + (iStepLeft * 2);

	hvel = pPlayer.pev.velocity;
	hvel.z = 0.0;

	//if ( pmove->multiplayer and (!g_onladder && hvel.Length() <= 220) )
		//return;

	// irand - 0,1 for right foot, 2,3 for left foot
	// used to alternate left and right foot
	switch( iStep )
	{
		case STEP_METAL:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/clank1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/clank3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/clank2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/clank4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_DIRT:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/grass1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/grass3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/grass2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/grass4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_VENT:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/boot1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/boot3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/boot2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/boot4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_GRATE:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/mech1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/mech3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/mech2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/mech4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_TILE:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/tile1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/tile3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/tile2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/tile4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_SLOSH:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/splash1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/splash3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/splash2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/splash4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_WADE:
		{
			iSkipStep = pCustom.GetKeyvalue( KVN_FOOTSTEP_SKIP ).GetInteger();

			if( iSkipStep == 0 )
			{
				iSkipStep++;
				pCustom.SetKeyvalue( KVN_FOOTSTEP_SKIP, iSkipStep );
				break;
			}

			if( iSkipStep++ == 3 ) //??
				iSkipStep = 0;

			pCustom.SetKeyvalue( KVN_FOOTSTEP_SKIP, iSkipStep );

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/wade1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/wade2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/wade3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/wade1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_LADDER:
		{
			if( g_PlayerFuncs.SharedRandomLong(pPlayer.random_seed, 0, 4) == 0 )
				iRand = 4;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/ladder1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/ladder3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/ladder2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/ladder4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 4:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/ladder5.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_WOOD:
		{
			if( g_PlayerFuncs.SharedRandomLong(pPlayer.random_seed, 0, 4) == 0 )
				iRand = 4;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/wood1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/wood3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/wood2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/wood4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 4:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/wood5.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_FLESH:
		{
			if( g_PlayerFuncs.SharedRandomLong(pPlayer.random_seed, 0, 4) == 0 )
				iRand = 4;

			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/meat1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/meat3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/meat2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/meat4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 4:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/meat5.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_SNOW:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/snow1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/snow3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/snow2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/snow4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_ENERGY:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/energy1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/energy3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/energy2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/energy4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_CARPET:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/carpet1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/carpet3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/carpet2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/carpet4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}

		case STEP_CONCRETE:
		default:
		{
			switch( iRand )
			{
				// right foot
				case 0:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/step1.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 1:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/step3.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				// left foot
				case 2:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/step2.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
				case 3:	g_SoundSystem.EmitSoundDyn( pPlayer.edict(), CHAN_BODY, "quake2/player/steps/step4.wav", flVol, ATTN_NORM, 0, PITCH_NORM );	break;
			}

			break;
		}
	}

	//g_Game.AlertMessage( at_notice, "sTexture: %1\n", sTexture );
	//g_Game.AlertMessage( at_notice, "chTextureType: %1\n", string(chTextureType) );
	//g_Game.AlertMessage( at_notice, "iStep: %1\n", iStep );
}

int MapTextureTypeStepType( char chTextureType )
{
	if( chTextureType == 'C' ) return STEP_CONCRETE;
	else if( chTextureType == 'M' ) return STEP_METAL;
	else if( chTextureType == 'D' ) return STEP_DIRT;
	else if( chTextureType == 'V' ) return STEP_VENT;
	else if( chTextureType == 'G' ) return STEP_GRATE;
	else if( chTextureType == 'T' ) return STEP_TILE;
	else if( chTextureType == 'S' ) return STEP_SLOSH;
	else if( chTextureType == 'W' ) return STEP_WOOD;
	else if( chTextureType == 'F' ) return STEP_FLESH;
	else if( chTextureType == 'O' ) return STEP_SNOW;
	else if( chTextureType == 'E' ) return STEP_ENERGY;
	else if( chTextureType == 'A' ) return STEP_CARPET;

	return STEP_CONCRETE;
}

//from quake 2
void ThrowGib( CBaseEntity@ pEntity, int iCount, const string &in sGibName, float flDamage, int iBone = -1, int iType = 0, int iSkin = 0 )
{
	float vscale;

	for( int i = 0; i < iCount; i++ )
	{
		CGib@ pGib = g_EntityFuncs.CreateGib( pEntity.pev.origin, g_vecZero );
		pGib.Spawn( sGibName );
		pGib.pev.skin = iSkin;
		pGib.pev.scale = pEntity.pev.scale;

		if( iBone >= 0 )
		{
			Vector vecBonePos;
			g_EngineFuncs.GetBonePosition( pEntity.edict(), iBone, vecBonePos, void );
			g_EntityFuncs.SetOrigin( pGib, vecBonePos );
		}
		else
		{
			Vector vecSize = pEntity.pev.size * 0.5;
			// since absmin is bloated by 1, un-bloat it here
			Vector vecOrigin = (pEntity.pev.absmin + Vector(1.0, 1.0, 1.0)) + vecSize;

			int i;

			for( i = 0; i < 3; i++ )
			{
				Vector vecRandom( crandom()*vecSize.x, crandom()*vecSize.y, crandom()*vecSize.z );
				pGib.pev.origin = vecOrigin + vecRandom; //Vector(crandom(), crandom(), crandom()).scaled(vecSize);
				g_EntityFuncs.SetOrigin( pGib, pGib.pev.origin );

				// try 3 times to get a good, non-solid position
				if( g_EngineFuncs.PointContents(pGib.pev.origin) != CONTENTS_SOLID )
					break;
				//if (!(gi.pointcontents(gib->s.origin) & MASK_SOLID))
					//break;
			}
		}

		if( (iType & GIB_METALLIC) == 0 )
		{
			//pGib.pev.movetype = MOVETYPE_TOSS;
			vscale = (iType & GIB_ACID) != 0 ? 3.0 : 0.5;
		}
		else
		{
			//pGib.pev.movetype = MOVETYPE_BOUNCE;
			vscale = 1.0;
		}

		if( (iType & GIB_DEBRIS) != 0 )
		{
			Vector v;
			v.x = 100 * crandom();
			v.y = 100 * crandom();
			v.z = 100 + 100 * crandom();
			pGib.pev.velocity = pEntity.pev.velocity + (v * flDamage);
		}
		else
		{
			Vector vd = VelocityForDamage( flDamage );
			pGib.pev.velocity = pEntity.pev.velocity + (vd * vscale);
			ClipGibVelocity( pGib );
		}

		/*if (type & GIB_UPRIGHT)
		{
			gib->touch = gib_touch;
			gib->flags |= FL_ALWAYS_TOUCH;
		}*/

		pGib.pev.avelocity.x = Math.RandomFloat( 0, 600 );
		pGib.pev.avelocity.y = Math.RandomFloat( 0, 600 );
		pGib.pev.avelocity.z = Math.RandomFloat( 0, 600 );

		pGib.pev.angles.x = Math.RandomFloat( 0, 359 );
		pGib.pev.angles.y = Math.RandomFloat( 0, 359 );
		pGib.pev.angles.z = Math.RandomFloat( 0, 359 );

		if( iType == BREAK_FLESH )
		{
			pGib.m_bloodColor = BLOOD_COLOR_RED;
			pGib.m_cBloodDecals = 5;
			pGib.m_material = matFlesh;
			g_WeaponFuncs.SpawnBlood( pGib.pev.origin, BLOOD_COLOR_RED, 400 );
		}
		else
			pGib.m_bloodColor = DONT_BLEED;
	}
}

Vector VelocityForDamage( float flDamage )
{
	Vector v;

	v.x = 100.0 * crandom_open(); //crandom()
	v.y = 100.0 * crandom_open(); //crandom()
	v.z = Math.RandomFloat( 200.0, 300.0 );

	if( flDamage < 50 )
		return v * 0.7;
	else
		return v * 1.2;
}

//from Quake 2
/*
=================
KillBox

Kills all entities that would touch the proposed new positioning
of ent.  Ent should be unlinked before calling this!
=================
*/
bool KillBox( CBaseEntity@ pEntity )
{
	TraceResult tr;

	while( true )
	{
		//tr = gi.trace (ent->s.origin, ent->mins, ent->maxs, ent->s.origin, NULL, MASK_PLAYERSOLID);
		g_Utility.TraceMonsterHull( pEntity.edict(), pEntity.pev.origin, pEntity.pev.origin, dont_ignore_monsters, pEntity.edict(), tr );

		if( tr.pHit is null )
			break;

		// nail it
		q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), pEntity, pEntity, g_vecZero, pEntity.pev.origin, g_vecZero, 100000, 0, DMG_CRUSH | DMG_ALWAYSGIB ); //DAMAGE_NO_PROTECTION, MOD_TELEFRAG
		//g_EntityFuncs.Instance(tr.pHit).TakeDamage( pEntity.pev, pEntity.pev, 100000, DMG_CRUSH | DMG_ALWAYSGIB );

		// if we didn't kill it, fail
		//if( tr.ent->solid )
		if( tr.pHit.vars.deadflag == DEAD_NO )
			return false;
	}

	return true;		// all clear
}

/*
//From Half-Life
Vector VelocityForDamage( float flDamage )
{
	Vector vec( Math.RandomFloat(-200, 200), Math.RandomFloat(-200, 200), Math.RandomFloat(300, 400) );

	if( flDamage > 50 )
		vec = vec * 0.7;
	else if( flDamage > 200 )
		vec = vec * 2;
	else
		vec = vec * 10;

	return vec;
}*/

void ClipGibVelocity( CBaseEntity@ ent )
{
	if( ent.pev.velocity.x < -300 )
		ent.pev.velocity.x = -300;
	else if( ent.pev.velocity.x > 300 )
		ent.pev.velocity.x = 300;

	if( ent.pev.velocity.y < -300 )
		ent.pev.velocity.y = -300;
	else if( ent.pev.velocity.y > 300 )
		ent.pev.velocity.y = 300;

	if( ent.pev.velocity.z < 200 )
		ent.pev.velocity.z = 200; //always some upwards
	else if( ent.pev.velocity.z > 500 )
		ent.pev.velocity.z = 500;
} 
/*
inline void G_AddBlend(float r, float g, float b, float a, std::array<float, 4> &v_blend)
{
	if (a <= 0)
		return;

	float a2 = v_blend[3] + (1 - v_blend[3]) * a; // new total alpha
	float a3 = v_blend[3] / a2;					// fraction of color from old

	v_blend.x = v_blend.x * a3 + r * (1 - a3);
	v_blend.y = v_blend.y * a3 + g * (1 - a3);
	v_blend.z = v_blend.z * a3 + b * (1 - a3);
	v_blend[3] = a2;
}

void SV_AddBlend (float r, float g, float b, float a, float *v_blend)
{
	float	a2, a3;

	if (a <= 0)
		return;
	a2 = v_blend[3] + (1-v_blend[3])*a;	// new total alpha
	a3 = v_blend[3]/a2;		// fraction of color from old

	v_blend.x = v_blend.x*a3 + r*(1-a3);
	v_blend.y = v_blend.y*a3 + g*(1-a3);
	v_blend.z = v_blend.z*a3 + b*(1-a3);
	v_blend[3] = a2;
}
*/

float crandom()
{
	float flRandom = Math.RandomFloat( 0.0, 1.0 );
	return (flRandom - 0.5) * 2.0;
	//return Math.RandomFloat( -1.0, 1.0 );
}

float crandom_open()
{
	float flRandom = Math.RandomFloat( 0.0, 1.0 );

	// Scale and shift to match the range [-1.0, 1.0)
	return (flRandom - 0.5) * 2.0;
}

/*
//??
float crandom_open()
{
	float flRandom;

	do
	{
		flRandom = Math.RandomFloat( -1.0, 1.0 );
	} while( flRandom == -1.0 or flRandom == 1.0 ); // Reject boundary values

	return flRandom;
}
*/
//I can't figure these out :aRage:
/*
// uniform float [-1, 1)
// note: closed on min but not max
// to match vanilla behavior
[[nodiscard]] inline float crandom()
{
	return std::uniform_real_distribution<float>(-1.f, 1.f)(mt_rand);
}

// uniform float (-1, 1)
[[nodiscard]] inline float crandom_open()
{
	return std::uniform_real_distribution<float>(std::nextafterf(-1.f, 0.f), 1.f)(mt_rand);
} 
*/
} //end of namespace q2
namespace q2
{

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
void T_RadiusDamage( EHandle &in eInflictor, EHandle &in eAttacker, float flDamage, EHandle &in eIgnore, float flRadius, int bitsDamageType/*, mod_t mod*/ )
{
	CBaseEntity@ pInflictor = eInflictor.GetEntity();
	CBaseEntity@ pAttacker = eAttacker.GetEntity();
	CBaseEntity@ pIgnore = eIgnore.GetEntity();
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
			if( CanDamage(EHandle(pEnt), EHandle(pInflictor)) )
			{
				vecDir = (pEnt.pev.origin - vecInflictorCenter).Normalize();

				T_Damage( EHandle(pEnt), EHandle(pInflictor), EHandle(pAttacker), vecDir, closest_point_to_box(vecInflictorCenter, pEnt.pev.absmin, pEnt.pev.absmax), vecDir, flPoints, flPoints, bitsDamageType/* | DAMAGE_RADIUS, mod*/ );
				//if( !((pEnt.pev.FlagBitSet(FL_CLIENT) and pEnt !is pAttacker) and !q2::PVP) ) //deals damage to players otherwise
					//pEnt.TakeDamage( pInflictor.pev, pAttacker.pev, flPoints, bitsDamageType );
			}
		}
	}
}

//from quake 2
void T_Damage( EHandle &in eTarget, EHandle &in eInflictor, EHandle &in eAttacker, Vector vecDir, Vector vecPoint, Vector vecNormal, float flDamage, float flKnockback, int bitsDamageType/*, int mod*/ )
{
	CBaseEntity@ pTarget = eTarget.GetEntity();
	CBaseEntity@ pInflictor = eInflictor.GetEntity();
	CBaseEntity@ pAttacker = eAttacker.GetEntity();

	//gclient_t	*client;
	float flTake;
	float flSave;
	float flAsave;
	float flPsave;
	//int te_sparks;

	if( pTarget.pev.takedamage == DAMAGE_NO )
		return;

	// friendly fire avoidance
	// if enabled you can't hurt teammates (but you can hurt yourself)
	if( pTarget !is pAttacker and pTarget.pev.FlagBitSet(FL_CLIENT) and !q2::PVP )
	{
		flDamage = 0.0;
		flKnockback = 0.0;
	}
/*
	meansOfDeath = mod;

	// easy mode takes half damage
	if( skill.value == 0 and deathmatch.value == 0 and pTarget.pev.FlagBitSet(FL_CLIENT) )
	{
		flDamage *= 0.5;
		if( flDamage <= 0.0 )
			flDamage = 1.0;
	}

	client = pTarget.client;

	if( (bitsDamageType & DAMAGE_BULLET) != 0 )
		te_sparks = TE_BULLET_SPARKS;
	else
		te_sparks = TE_SPARKS;*/

	//VectorNormalize(vecDir);
	vecDir = vecDir.Normalize();
/*
// bonus damage for suprising a monster
	if( !(bitsDamageType & DAMAGE_RADIUS) and (pTarget.svflags & SVF_MONSTER) and (pAttacker.client) and (!pTarget.enemy) and (pTarget.health > 0) )
		flDamage *= 2.0;

	if( pTarget.flags & FL_NO_KNOCKBACK )
		flKnockback = 0.0;
*/
	//figure momentum add
	//if( (bitsDamageType & DAMAGE_NO_KNOCKBACK) == 0 )
	{
		if( flKnockback > 0.0 and pTarget.pev.movetype != MOVETYPE_NONE and pTarget.pev.movetype != MOVETYPE_BOUNCE and pTarget.pev.movetype != MOVETYPE_PUSH/* and (pTarget.movetype != MOVETYPE_STOP)*/ )
		{
			Vector vecKvel;
			float flMass = 200; //player

			/*if (pTarget.mass < 50)
				flMass = 50;
			else
				flMass = pTarget.mass;*/

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

		//this works with the custom death messages
		entvars_t@ entAttacker;
		if( entAttacker is null )
			@entAttacker = pInflictor.pev;
		else
			@entAttacker = pAttacker.pev;

		pTarget.TakeDamage( pInflictor.pev, entAttacker, flTake, 0 ); //bitsDamageType

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
}

//from quake 2 rerelease
bool CanDamage( EHandle &in eTarget, EHandle &in eInflictor )
{
	CBaseEntity@ pTarget = eTarget.GetEntity();
	CBaseEntity@ pInflictor = eInflictor.GetEntity();

	Vector vecDest;
	TraceResult trace;

	// bmodels need special checking because their origin is 0,0,0
	Vector vecIinflictorCenter;

	//if( pInflictor.linked )
		vecIinflictorCenter = (pInflictor.pev.absmin + pInflictor.pev.absmax) * 0.5;
	//else
		//vecIinflictorCenter = pInflictor.pev.origin;

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
float CheckPowerArmor( EHandle &in eEnt, Vector vecPoint, Vector vecNormal, float flDamage, int bitsDamageType )
{
	CBaseEntity@ pEnt = eEnt.GetEntity();
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

		if( iPowerArmorType != q2items::POWER_ARMOR_NONE )
			iPower = pPlayer.m_rgAmmo( g_PlayerFuncs.GetAmmoIndex("q2cells") );
	}
	else
		return 0;

	if( iPowerArmorType == q2items::POWER_ARMOR_NONE )
		return 0;

	if( iPower <= 0 )
		return 0;

	if( iPowerArmorType == q2items::POWER_ARMOR_SCREEN )
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
	G_CheckPowerArmor( eEnt );

	return flSave;
}

//from quake 2
int PowerArmorType( CBasePlayer@ pPlayer )
{
	if( pPlayer is null or !pPlayer.IsAlive() )
		return q2items::POWER_ARMOR_NONE;

	CustomKeyvalues@ pCustom = pPlayer.GetCustomKeyvalues();

	if( !pCustom.GetKeyvalue(q2items::PARMOR_KVN).Exists() )
		return q2items::POWER_ARMOR_NONE;

	//just return q2items::PARMOR_KVN ??
	if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() == q2items::POWER_ARMOR_SHIELD )
		return q2items::POWER_ARMOR_SHIELD;

	if( pCustom.GetKeyvalue(q2items::PARMOR_KVN).GetInteger() == q2items::POWER_ARMOR_SCREEN )
		return q2items::POWER_ARMOR_SCREEN;

	return q2items::POWER_ARMOR_NONE;
}

//from quake 2
float CheckArmor( EHandle &in eEnt, Vector vecPoint, Vector vecNormal, float flDamage )
{
	CBaseEntity@ pEnt = eEnt.GetEntity();
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
void G_CheckPowerArmor( EHandle &in eEnt )
{
	CBasePlayer@ pPlayer = cast<CBasePlayer@>(eEnt.GetEntity());
	if( pPlayer is null ) return;

	q2items::UpdatePowerArmorHUD( pPlayer );

	bool bHasEnoughCells;

	if( pPlayer.m_rgAmmo(g_PlayerFuncs.GetAmmoIndex("q2cells")) <= 0)
		bHasEnoughCells = false;
	//else if (pEnt->client->pers.autoshield >= AUTO_SHIELD_AUTO)
		//bHasEnoughCells = (pEnt->flags & FL_WANTS_POWER_ARMOR) && pEnt->client->pers.inventory[IT_AMMO_CELLS] > pEnt->client->pers.autoshield;
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
		if (pEnt->client->pers.autoshield != AUTO_SHIELD_MANUAL &&
			bHasEnoughCells && (pEnt->client->pers.inventory[IT_ITEM_POWER_SCREEN] ||
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

/*
inline void G_AddBlend(float r, float g, float b, float a, std::array<float, 4> &v_blend)
{
	if (a <= 0)
		return;

	float a2 = v_blend[3] + (1 - v_blend[3]) * a; // new total alpha
	float a3 = v_blend[3] / a2;					// fraction of color from old

	v_blend[0] = v_blend[0] * a3 + r * (1 - a3);
	v_blend[1] = v_blend[1] * a3 + g * (1 - a3);
	v_blend[2] = v_blend[2] * a3 + b * (1 - a3);
	v_blend[3] = a2;
}

void SV_AddBlend (float r, float g, float b, float a, float *v_blend)
{
	float	a2, a3;

	if (a <= 0)
		return;
	a2 = v_blend[3] + (1-v_blend[3])*a;	// new total alpha
	a3 = v_blend[3]/a2;		// fraction of color from old

	v_blend[0] = v_blend[0]*a3 + r*(1-a3);
	v_blend[1] = v_blend[1]*a3 + g*(1-a3);
	v_blend[2] = v_blend[2]*a3 + b*(1-a3);
	v_blend[3] = a2;
}
*/
} //end of namespace q2
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
void T_RadiusDamage( CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, float flDamage, CBaseEntity@ pIgnore, float flRadius, int dflags, int iMeansOfDeath = MOD_UNKNOWN )
{
	if( pIgnore is null ) @pIgnore = pInflictor;

	float flPoints;
	CBaseEntity@ pEnt = null;
	Vector vecOffsetToInflictor;
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
			vecOffsetToInflictor = closest_point_to_box( vecInflictorCenter, pEnt.pev.absmin, pEnt.pev.absmax );
		else
		{
			vecOffsetToInflictor = pEnt.pev.mins + pEnt.pev.maxs;
			vecOffsetToInflictor = pEnt.pev.origin + (vecOffsetToInflictor * 0.5);
		}

		vecOffsetToInflictor = vecInflictorCenter - vecOffsetToInflictor;
		flPoints = flDamage - 0.5 * vecOffsetToInflictor.Length();

		if( pEnt is pAttacker )
			flPoints *= 0.5;

		if( flPoints > 0 )
		{
			if( CanDamage(pEnt, pInflictor) )
			{
				vecDir = (pEnt.pev.origin - vecInflictorCenter).Normalize();

				T_Damage( pEnt, pInflictor, pAttacker, vecDir, closest_point_to_box(vecInflictorCenter, pEnt.pev.absmin, pEnt.pev.absmax), vecDir, flPoints, flPoints, dflags | q2::DAMAGE_RADIUS, iMeansOfDeath );
			}
		}
	}
}

//from quake 2
/*
============
T_Damage

pTarget		entity that is being damaged
pInflictor	entity that is causing the damage
pAttacker	entity that caused the pInflictor to damage pTarget
	example: pTarget=monster, pInflictor=rocket, pAttacker=player

vecDir			direction of the attack
vecPoint		point at which the damage is being inflicted
vecNormal		normal vector from that point
flDamage		amount of damage being inflicted
flKnockback	force to be applied against targ as a result of the damage

dflags		these flags are used to control how T_Damage works
	DAMAGE_RADIUS			damage was indirect (from a nearby explosion)
	DAMAGE_NO_ARMOR			armor does not protect from this damage
	DAMAGE_ENERGY			damage is from an energy based weapon
	DAMAGE_NO_KNOCKBACK		do not affect velocity, just view angles
	DAMAGE_BULLET			damage is from a bullet (used for ricochets)
	DAMAGE_NO_PROTECTION	kills godmode, armor, everything
============
*/
void T_Damage( CBaseEntity@ pTarget, CBaseEntity@ pInflictor, CBaseEntity@ pAttacker, Vector vecDir, Vector vecPoint, Vector vecNormal, float flDamage, float flKnockback, int dflags, int iMeansOfDeath )
{
	if( pTarget.pev.takedamage == DAMAGE_NO )
		return;

	float flTake;
	float flSave;
	float flAsave;
	float flPsave;
	int te_sparks;

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

	// easy mode takes half damage
	if( q2npc::g_iDifficulty == q2::DIFF_EASY and !q2::PVP and pTarget.pev.FlagBitSet(FL_CLIENT) )
	{
		flDamage *= 0.5;
		if( flDamage <= 0.0 )
			flDamage = 1.0;
	}

	if( HasFlags(dflags, DAMAGE_BULLET) )
		te_sparks = q2::TE_BULLET_SPARKS;
	else
		te_sparks = q2::TE_SPARKS;

	vecDir = vecDir.Normalize();

	// bonus damage for suprising a monster
	CBaseQ2NPC@ pMonster = q2npc::GetQ2Pointer( pTarget );
	if( !HasFlags(dflags, q2::DAMAGE_RADIUS) and pTarget.pev.FlagBitSet(FL_MONSTER) and pAttacker.pev.FlagBitSet(FL_CLIENT) and (!pTarget.MyMonsterPointer().m_hEnemy.IsValid() or (pMonster !is null and pMonster.monsterinfo.surprise_time == g_Engine.time)) and pTarget.pev.health > 0 )
	{
		flDamage *= 2.0;

		if( pMonster !is null )
			pMonster.monsterinfo.surprise_time = g_Engine.time;
	}

	if( HasFlags(q2npc::GetMonsterFlags(pTarget), q2::FL_NO_KNOCKBACK) )
		flKnockback = 0.0;

	//figure momentum add
	if( !HasFlags(dflags, q2::DAMAGE_NO_KNOCKBACK) )
	{
		if( flKnockback > 0.0 and pTarget.pev.movetype != MOVETYPE_NONE and pTarget.pev.movetype != MOVETYPE_BOUNCE and pTarget.pev.movetype != MOVETYPE_PUSH/* and (pTarget.movetype != MOVETYPE_STOP)*/ )
		{
			Vector vecKvel;
			float flMass = 200; //player

			float flTargetMass = q2npc::GetMass( pTarget );
			if( flTargetMass == 0 )
				flTargetMass = GetMassForTarget( pTarget, 200, 50, 2000 );

			if( flTargetMass < 50 )
				flMass = 50;
			else
				flMass = flTargetMass;

			//g_Game.AlertMessage( at_notice, "flMass %1\n", flMass );
			if( pTarget.pev.FlagBitSet(FL_CLIENT) and pAttacker is pTarget )
				vecKvel = vecDir * (500.0 * flKnockback / flMass); //rocket jump hack (NOT NEEDED IN SVEN?!) //1600.0
			else
				vecKvel = vecDir * (500.0 * flKnockback / flMass);

			pTarget.pev.velocity = pTarget.pev.velocity + vecKvel;
		}
	}

	flTake = flDamage;
	flSave = 0.0;

	// check for godmode
	if( pTarget.pev.FlagBitSet(FL_GODMODE) and !HasFlags(dflags, q2::DAMAGE_NO_PROTECTION) )
	{
		flTake = 0.0;
		flSave = flDamage;
		SpawnDamage( te_sparks, vecPoint, vecNormal, flSave );
	}

	flPsave = CheckPowerArmor( pTarget, vecPoint, vecNormal, flTake, dflags );
	flTake -= flPsave;

	flAsave = CheckArmor( pTarget, vecPoint, vecNormal, flTake );
	flTake -= flAsave;

	//treat cheat/powerup savings the same as armor
	flAsave += flSave;

	//do the damage
	if( flTake > 0.0 )
	{
		if( pTarget.pev.FlagBitSet(FL_MONSTER|FL_CLIENT) )
			SpawnDamage( q2::TE_BLOOD, vecPoint, vecNormal, flTake );
		else
			SpawnDamage( te_sparks, vecPoint, vecNormal, flTake );

		if( pTarget !is null )
		{
			q2::SetMeansOfDeath( pTarget, iMeansOfDeath );
			//CustomKeyvalues@ pCustom = pTarget.GetCustomKeyvalues();
			//pCustom.SetKeyvalue( KVN_MOD, iMeansOfDeath );
			//g_Game.AlertMessage( at_notice, "MEANS OF DEATH SET TO %1\n", iMeansOfDeath );
		}

		//this works with the custom death messages
		entvars_t@ entAttacker;
		if( pAttacker is null )
			@entAttacker = pInflictor.pev;
		else
			@entAttacker = pAttacker.pev;

		pTarget.TakeDamage( pInflictor.pev, entAttacker, flTake, 0 );
		//g_Game.AlertMessage( at_notice, "DAMAGE DEALT: %1\n", flTake );

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

const array <int>splash_color = { 0, 93, 40, 159, 253, 93, 231 }; 
//{ 0x00, 0xe0, 0xb0, 0x50, 0xd0, 0xe0, 0xe8 }
//{ 0, 224, 176, 80, 208, 224, 232 }
//(0, 0, 0), (156, 31, 1), (70, 71, 115), (20, 7, 1), (255, 255, 211), (156, 31, 1), (240, 0, 1)

void SpawnDamage( int iType, Vector vecOrigin, Vector vecNormal, float flDamage )
{
	int iDamage = int( flDamage );
	if( iDamage > 255 )
		iDamage = 255;

	switch( iType )
	{
		case q2::TE_BLOOD:	//bullet hitting flesh
		{
			//CL_ParticleEffect (pos, dir, 0xe8, 60);
			//void CL_ParticleEffect (vec3_t org, vec3_t dir, int color, int count)
			g_EngineFuncs.ParticleEffect( vecOrigin, vecNormal, 231, 60 ); //0xe8 (232) (240, 0, 1)
			//g_WeaponFuncs.SpawnBlood( vecOrigin, BLOOD_COLOR_RED, iDamage ); //60
			break;
		}

		case q2::TE_GUNSHOT:	// bullet hitting wall
		case q2::TE_SPARKS:
		case q2::TE_BULLET_SPARKS:
		{
			if( iType == q2::TE_GUNSHOT )
				g_EngineFuncs.ParticleEffect( vecOrigin, vecNormal, 0, 40 ); //CL_ParticleEffect (vecOrigin, dir, 0, 40);
			else
				g_EngineFuncs.ParticleEffect( vecOrigin, vecNormal, 93, 6 ); //CL_ParticleEffect (vecOrigin, dir, 0xe0, 6); //0xe0 (224) (156, 31, 1)

			if( iType != q2::TE_SPARKS )
			{
				//CL_SmokeAndFlash(vecOrigin);

				// impact sound
				int cnt = Math.RandomLong(0, 32767) & 15; //rand()&15;
				if( cnt == 1 )
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/ric1.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM, 0, true, vecOrigin );
				else if( cnt == 2 )
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/ric2.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM, 0, true, vecOrigin );
				else if( cnt == 3 )
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/ric3.wav", VOL_NORM, ATTN_NORM, 0, PITCH_NORM, 0, true, vecOrigin );
			}

			break;
		}

		case q2::TE_SHOTGUN: // bullet hitting wall
		{
			//MSG_ReadPos (&net_message, pos);
			//MSG_ReadDir (&net_message, dir);
			g_EngineFuncs.ParticleEffect( vecOrigin, vecNormal, 0, 20 ); //CL_ParticleEffect (pos, dir, 0, 20);
			//CL_SmokeAndFlash(pos);
			break;
		}

		case q2::TE_SPLASH: // bullet hitting water
		{
			/*cnt = MSG_ReadByte (&net_message);
			MSG_ReadPos (&net_message, pos);
			MSG_ReadDir (&net_message, dir);
			r = MSG_ReadByte (&net_message);*/

			int color;
			if( iDamage > 6 )
				color = 0x00;
			else
				color = splash_color[ iDamage ];

			g_EngineFuncs.ParticleEffect( vecOrigin, vecNormal, color, 8 ); //CL_ParticleEffect (pos, dir, color, cnt);

			if( iDamage == 1 ) //SPLASH_SPARKS
			{
				int r = Math.RandomLong(0, 32767) & 3; //rand() & 3;

				if( r == 0 )
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/spark5.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_NORM, 0, true, vecOrigin );
				else if( r == 1 )
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/spark6.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_NORM, 0, true, vecOrigin );
				else
					g_SoundSystem.PlaySound( null, CHAN_AUTO, "quake2/world/spark7.wav", VOL_NORM, ATTN_STATIC, 0, PITCH_NORM, 0, true, vecOrigin );
			}

			break;
		}
	}

	/*gi.WriteByte (svc_temp_entity);
	gi.WriteByte (iType);
//	gi.WriteByte (iDamage);
	gi.WritePosition (origin);
	gi.WriteDir (normal);
	gi.multicast (origin, MULTICAST_PVS);*/
}

float GetMassForTarget( CBaseEntity@ pTarget, float flBaseMass, float flMinMass, float flMaxMass, float flMassIncrease = 0.4, float flMassDecrease = 1.5 )
{
	float flBaseMobVolume = 73728; //player size
	float flMass;

	float flMobVolume = (pTarget.pev.size.x * pTarget.pev.size.y * pTarget.pev.size.z);
	if( flMobVolume > flBaseMobVolume ) flMass = (flBaseMass * (flMobVolume/flBaseMobVolume)) * flMassIncrease;
	else if( flMobVolume < flBaseMobVolume ) flMass = (flBaseMass / (flBaseMobVolume/flMobVolume)) * flMassDecrease;
	else flMass = flBaseMass;

	return Math.clamp( flMinMass, flMaxMass, flMass );
}

//from quake 2 rerelease
bool CanDamage( CBaseEntity@ pTarget, CBaseEntity@ pInflictor )
{
	Vector vecDest;
	TraceResult trace;

	// bmodels need special checking because their origin is 0,0,0
	Vector vecIinflictorCenter;

	//if( pInflictor.linked )
	if( pInflictor !is null and pInflictor.pev.solid == SOLID_BSP )
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

//from quake 2 rerelease
float CheckPowerArmor( CBaseEntity@ pEnt, Vector vecPoint, Vector vecNormal, float flDamage, int dflags )
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

	if( dflags & (q2::DAMAGE_NO_ARMOR | q2::DAMAGE_NO_POWER_ARMOR) != 0 )
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
	if( (dflags & q2::DAMAGE_ENERGY) != 0 )
		flSave = Math.max( 1.0, flSave / 2 );

	if( flSave > flDamage )
		flSave = flDamage;

	//energy damage should do more to power armor, not ETF Rifle shots.
	if( (dflags & q2::DAMAGE_ENERGY) != 0 )
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
Vector G_ProjectSource( const Vector &in point, const Vector &in distance, const Vector &in forward, const Vector &in right )
{
	return point + (forward * distance.x) + (right * distance.y) + Vector( 0.0, 0.0, distance.z );
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
	//g_Game.AlertMessage( at_notice, "chTextureType: %1\n", string(chTextureType) );

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

			//int i;
			//for( i = 0; i < 3; i++ )
			for( int j = 0; j < 3; j++ )
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
			pGib.m_material = matMetal;
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
		q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), pEntity, pEntity, g_vecZero, pEntity.pev.origin, g_vecZero, 100000, 0, 0, q2::MOD_TELEFRAG ); //DAMAGE_NO_PROTECTION, MOD_TELEFRAG
		//q2::T_Damage( g_EntityFuncs.Instance(tr.pHit), pEntity, pEntity, g_vecZero, pEntity.pev.origin, g_vecZero, 100000, 0, DMG_CRUSH | DMG_ALWAYSGIB ); //DAMAGE_NO_PROTECTION, MOD_TELEFRAG
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

//from quake 2
//returns true if the entity is visible to self, even if not infront ()
bool visible( CBaseEntity@ pSelf, CBaseEntity@ pOther )
{
	if( pOther is null )
		return false;

	TraceResult tr;

	Vector spot1 = pSelf.EyePosition();
	Vector spot2 = pOther.EyePosition();

	g_Utility.TraceLine( spot1, spot2, ignore_monsters, ignore_glass, pSelf.edict(), tr );

	//if( tr.fInOpen != 0 and tr.fInWater != 0 ) //replicating MASK_OPAQUE (CONTENTS_SOLID|CONTENTS_SLIME|CONTENTS_LAVA)
		//return false;

	if( tr.flFraction == 1.0 )
		return true;

	return false;
}

//from quake 2 rerelease
//returns true if the entity is visible to self, even if not infront ()
bool visible_rr( CBaseEntity@ pSelf, CBaseEntity@ pOther, bool bThroughGlass )
{
    // never visible
    if( pOther.pev.FlagBitSet(FL_NOTARGET) )
        return false;

    // [Paril-KEX] bit of a hack, but we'll tweak monster-player visibility
    // if they have the invisibility powerup.
    if( pOther.pev.FlagBitSet(FL_CLIENT) )
    {
        // always visible in rtest
        //if (pSelf->hackflags & HACKFLAG_ATTACK_PLAYER)
            //return pSelf->inuse;

        // fix intermission
        if( pOther.pev.solid == SOLID_NOT )
            return false;

        //if (pOther->client->invisible_time > level.time)
		if( pOther.pev.FlagBitSet(FL_NOTARGET) )
        {
            // can't see us at all after this time
			CustomKeyvalues@ pCustom = pOther.GetCustomKeyvalues();
            if( pCustom.GetKeyvalue(q2items::INVIS_KVN_FADETIME).GetFloat() <= g_Engine.time )
                return false;

            // otherwise, throw in some randomness
            if( Math.RandomFloat(0.0, 1.0) * 255 > pOther.pev.renderamt )
                return false;
        }
    }

	TraceResult tr;

	Vector spot1 = pSelf.EyePosition();
	Vector spot2 = pOther.EyePosition();

	g_Utility.TraceLine( spot1, spot2, ignore_monsters, bThroughGlass ? ignore_glass : dont_ignore_glass, pSelf.edict(), tr );

	//if( tr.fInOpen != 0 and tr.fInWater != 0 ) //replicating MASK_OPAQUE (CONTENTS_SOLID|CONTENTS_SLIME|CONTENTS_LAVA)
		//return false;

    return tr.flFraction == 1.0 or g_EntityFuncs.Instance(tr.pHit) is pOther;
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

/*
=============
range_to

returns the distance of an entity relative to self.
in general, the results determine how an AI reacts:
melee	melee range, will become hostile even if back is turned
near	visibility and infront, or visibility and show hostile
mid	    infront and show hostile
> mid	only triggered by damage
=============
*/
//from quake 2 rerelease
float range_to( CBaseEntity@ pSelf, CBaseEntity@ pOther )
{
    return distance_between_boxes( pSelf.pev.absmin, pSelf.pev.absmax, pOther.pev.absmin, pOther.pev.absmax );
}

//from quake 2 rerelease
float distance_between_boxes( const Vector &in absminsa, const Vector &in absmaxsa, const Vector &in absminsb, const Vector &in absmaxsb )
{
    float len = 0;

	for( size_t i = 0; i < 3; i++ )
    {
        if( absmaxsa[i] < absminsb[i] )
        {
            float d = absmaxsa[i] - absminsb[i];
            len += d * d;
        }
        else if( absminsa[i] > absmaxsb[i] )
        {
            float d = absminsa[i] - absmaxsb[i];
            len += d * d;
        }
    }

    return sqrt( len );
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

//from quake 2 rerelease, converted by ChatGPT
enum stuck_result_t
{
	GOOD_POSITION,
	FIXED,
	NO_GOOD_POSITION
};

class StuckTrace
{
	bool startsolid;
	Vector endpos;
	Vector planeNormal;
}

funcdef StuckTrace@ TraceFn( const Vector &in start, const Vector &in mins, const Vector &in maxs, const Vector &in end );

stuck_result_t G_FixStuckObject_Generic( const Vector &in vecOrigin, const Vector &in own_mins, const Vector &in own_maxs, TraceFn@ trace, Vector &out vecOut )
{
	StuckTrace@ tr = trace( vecOrigin, own_mins, own_maxs, vecOrigin );

	if( !tr.startsolid )
		return GOOD_POSITION;

	array<Vector> good_origins;
	array<float> distances;

	array<array<int>> side_checks =
	{
		{0, 0, 1}, {0, 0, -1}, {1, 0, 0}, {-1, 0, 0}, {0, 1, 0}, {0, -1, 0}
	};

	array<array<int>> side_mins =
	{
		{-1, -1, 0}, {-1, -1, 0}, {0, -1, -1}, {0, -1, -1}, {-1, 0, -1}, {-1, 0, -1}
	};

	array<array<int>> side_maxs =
	{
		{1, 1, 0}, {1, 1, 0}, {0, 1, 1}, {0, 1, 1}, {1, 0, 1}, {1, 0, 1}
	};

	for( uint sn = 0; sn < side_checks.length(); ++sn )
	{
		Vector start = vecOrigin;
		Vector mins, maxs;

		for (uint i = 0; i < 3; ++i)
		{
			if( side_checks[sn][i] < 0 )
				start[i] += own_mins[i];
			else if( side_checks[sn][i] > 0 )
				start[i] += own_maxs[i];

			mins[i] = (side_mins[sn][i] == -1) ? own_mins[i] : (side_mins[sn][i] == 1) ? own_maxs[i] : 0;
			maxs[i] = (side_maxs[sn][i] == -1) ? own_mins[i] : (side_maxs[sn][i] == 1) ? own_maxs[i] : 0;
		}

		StuckTrace@ side_trace = trace( start, mins, maxs, start );
		int fix_axis = -1;
		int fix_dir = 0;

		if( side_trace.startsolid )
		{
			for( uint e = 0; e < 3; ++e )
			{
				if( side_checks[sn][e] != 0 )
					continue;

				Vector ep = start;
				ep[e] += 1;
				StuckTrace@ tr1 = trace( ep, mins, maxs, ep );
				if( !tr1.startsolid )
				{
					start = ep;
					fix_axis = e;
					fix_dir = 1;
					break;
				}

				ep[e] -= 2;
				StuckTrace@ tr2 = trace( ep, mins, maxs, ep );
				if( !tr2.startsolid )
				{
					start = ep;
					fix_axis = e;
					fix_dir = -1;
					break;
				}
			}
		}

		if( trace(start, mins, maxs, start).startsolid )
			continue;

		Vector opposite = vecOrigin;
		uint opp = sn ^ 1;

		for( uint i = 0; i < 3; ++i )
		{
			if( side_checks[opp][i] < 0 ) opposite[i] += own_mins[i];
			else if( side_checks[opp][i] > 0 ) opposite[i] += own_maxs[i];
		}

		if( fix_axis >= 0 ) opposite[fix_axis] += fix_dir;

		StuckTrace@ final_trace = trace( start, mins, maxs, opposite );
		if( final_trace.startsolid ) continue;

		Vector end = final_trace.endpos + Vector(side_checks[sn][0], side_checks[sn][1], side_checks[sn][2]) * 0.125f;
		Vector delta = end - opposite;
		Vector new_origin = vecOrigin + delta;

		if( fix_axis >= 0 ) new_origin[fix_axis] += fix_dir;

		if( !trace(new_origin, own_mins, own_maxs, new_origin).startsolid )
		{
			good_origins.insertLast( new_origin );
			distances.insertLast( delta.Length() ); //LengthSquared
		}
	}

	if( good_origins.length() > 0 )
	{
		int best = 0;
		float best_dist = distances[0];

		for( uint i = 1; i < distances.length(); ++i )
		{
			if( distances[i] < best_dist )
			{
				best = i;
				best_dist = distances[i];
			}
		}

		vecOut = good_origins[best];
		return FIXED;
	}

	return NO_GOOD_POSITION;
}

//from ChatGPT
HULL_NUMBER GetClosestHullNumber( const Vector &in mins, const Vector &in maxs )
{
	Vector size = maxs - mins;

	// Define known hull dimensions (approximate from SC engine)
	// Format: { hull type, size }
	const array<dictionary> hullSizes =
	{
		{ {"type", 0},	{"size", Vector(0, 0, 0)} },
		{ {"type", 1},	{"size", Vector(32, 32, 72)} },
		{ {"type", 2},	{"size", Vector(64, 64, 64)} },
		{ {"type", 3},	{"size", Vector(32, 32, 36)} }
		/*{ {"type", point_hull},	{"size", Vector(0, 0, 0)} },
		{ {"type", human_hull},	{"size", Vector(32, 32, 72)} },
		{ {"type", large_hull},	{"size", Vector(64, 64, 64)} },
		{ {"type", head_hull},	{"size", Vector(32, 32, 36)} }*/
	};

	const array<HULL_NUMBER> hulls =
	{
		point_hull,
		human_hull,
		large_hull,
		head_hull
	};

	HULL_NUMBER bestHull = human_hull;
	float bestDiff = 1e6;

	for( uint i = 0; i < hullSizes.length(); ++i )
	{
		Vector refSize;
		hullSizes[i].get( "size", refSize );

		// Difference in bounding box size
		//float diff = ( refSize - size.Abs() ).Length();
		float diff = ( refSize - size ).Length();

		if( diff < bestDiff )
		{
			bestDiff = diff;
			uint uiHullNum;
			hullSizes[i].get( "type", uiHullNum );
			bestHull = hulls[ uiHullNum ];
		}
	}

	//g_Game.AlertMessage( at_notice, "bestHull: %1!\n", int(bestHull) );
	return bestHull;
}

} //end of namespace q2
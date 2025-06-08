namespace q2
{

enum sflag_e
{
	SPAWNFLAG_MONSTER_AMBUSH = 1,
	SPAWNFLAG_MONSTER_TRIGGER_SPAWN = 2,
	SPAWNFLAG_MONSTER_DEAD = 65536/*,
	SPAWNFLAG_MONSTER_SUPER_STEP = 131072,
	SPAWNFLAG_MONSTER_NO_DROP = 262144,
	SPAWNFLAG_MONSTER_SCENIC = 524288*/
};

enum animev_e
{
	AE_IDLESOUND = 3,
	AE_WALKMOVE,
	AE_FOOTSTEP,
	AE_FLINCHRESET //HACK
};

/*
	No pain animations in nightmare
	Not much else at the moment
*/
enum diff_e
{
	DIFF_EASY = 0,
	DIFF_NORMAL,
	DIFF_HARD,
	DIFF_NIGHTMARE,
	DIFF_LAST
};

/*
	0 = npc weapons are normal
	1 = npc weapons are randomly decided at spawn
	2 = npc weapons are random on every shot
*/
enum chaos_e
{
	CHAOS_NONE = 0,
	CHAOS_LEVEL1,
	CHAOS_LEVEL2,
	CHAOS_LAST
};

enum weapons_e
{
	WEAPON_BULLET = 0,
	WEAPON_SHOTGUN,
	WEAPON_BLASTER,
	WEAPON_BLASTER2,
	WEAPON_GRENADE,
	WEAPON_ROCKET,
	WEAPON_HEATSEEKING,
	WEAPON_RAILGUN,
	WEAPON_BFG,
	WEAPON_RANDOM	//only here for clarification
};

enum parmor_e
{
	POWER_ARMOR_NONE = 0,
	POWER_ARMOR_SCREEN,
	POWER_ARMOR_SHIELD
};

enum effects_t
{
    EF_NONE						= 0,				// no effects
    EF_ROTATE					= 1 << 0,		// rotate (bonus items)
    //EF_GIB							= 1 << 1,		// leave a trail
    EF_BOB							= 1 << 2,		// bob (bonus items)
    EF_BLASTER					= 1 << 3,		// redlight + trail
    //EF_ROCKET					= 1 << 4,		// redlight + trail
    //EF_GRENADE					= 1 << 5,
    EF_HYPERBLASTER			= 1 << 6,/*
    EF_BFG							= 1 << 7,
    EF_COLOR_SHELL			= 1 << 8,
    EF_POWERSCREEN			= 1 << 9,
    EF_ANIM01					= 1 << 10,	// cycle between frames 0 and 1 at 2 Hz
    EF_ANIM23					= 1 << 11,	// cycle between frames 2 and 3 at 2 Hz
    EF_ANIM_ALL				= 1 << 12,	// cycle through all frames at 2 Hz
    EF_ANIM_ALLFAST			= 1 << 13,	// cycle through all frames at 10 Hz*/
    EF_FLIES						= 1 << 14/*,
    EF_QUAD						= 1 << 15,
    EF_PENT						= 1 << 16,
    EF_TELEPORTER				= 1 << 17,	// particle fountain
    EF_FLAG1						= 1 << 18,
    EF_FLAG2						= 1 << 19,
    EF_IONRIPPER				= 1 << 20,
    EF_GREENGIB				= 1 << 21,
    EF_BLUEHYPERBLASTER	= 1 << 22,
    EF_SPINNINGLIGHTS		= 1 << 23,
    EF_PLASMA					= 1 << 24,
    EF_TRAP						= 1 << 25,
    EF_TRACKER					= 1 << 26,
    EF_DOUBLE					= 1 << 27,
    EF_SPHERETRANS			= 1 << 28,
    EF_TAGTRAIL					= 1 << 29,
    EF_HALF_DAMAGE			= 1 << 30,
    EF_TRACKERTRAIL			= 1 << 31,
    EF_DUALFIRE				= 1 << 32,	// [KEX] dualfire damage color shell
    EF_HOLOGRAM				= 1 << 33,	// [Paril-KEX] N64 hologram
    EF_FLASHLIGHT				= 1 << 34,	// [Paril-KEX] project flashlight, only for players
    EF_BARREL_EXPLODING	= 1 << 35,
    EF_TELEPORTER2			= 1 << 36,	// [Paril-KEX] N64 teleporter
    EF_GRENADE_LIGHT		= 1 << 37*/
};

enum temp_event_t
{
	TE_GUNSHOT,
	TE_BLOOD,
	/*TE_BLASTER,
	TE_RAILTRAIL,*/
	TE_SHOTGUN,
	/*TE_EXPLOSION1,
	TE_EXPLOSION2,
	TE_ROCKET_EXPLOSION,
	TE_GRENADE_EXPLOSION,*/
	TE_SPARKS,
	TE_SPLASH,
	/*TE_BUBBLETRAIL,
	TE_SCREEN_SPARKS,
	TE_SHIELD_SPARKS,*/
	TE_BULLET_SPARKS/*,
	TE_LASER_SPARKS,
	TE_PARASITE_ATTACK,
	TE_ROCKET_EXPLOSION_WATER,
	TE_GRENADE_EXPLOSION_WATER,
	TE_MEDIC_CABLE_ATTACK,
	TE_BFG_EXPLOSION,
	TE_BFG_BIGEXPLOSION,
	TE_BOSSTPORT,			// used as '22' in a map, so DON'T RENUMBER!!!
	TE_BFG_LASER,
	TE_GRAPPLE_CABLE,
	TE_WELDING_SPARKS,
	TE_GREENBLOOD,
	TE_BLUEHYPERBLASTER,
	TE_PLASMA_EXPLOSION,
	TE_TUNNEL_SPARKS,
	TE_BLASTER2, //ROGUE
	TE_RAILTRAIL2,
	TE_FLAME,
	TE_LIGHTNING,
	TE_DEBUGTRAIL,
	TE_PLAIN_EXPLOSION,
	TE_FLASHLIGHT,
	TE_FORCEWALL,
	TE_HEATBEAM,
	TE_MONSTER_HEATBEAM,
	TE_STEAM,
	TE_BUBBLETRAIL2,
	TE_MOREBLOOD,
	TE_HEATBEAM_SPARKS,
	TE_HEATBEAM_STEAM,
	TE_CHAINFIST_SMOKE,
	TE_ELECTRIC_SPARKS,
	TE_TRACKER_EXPLOSION,
	TE_TELEPORT_EFFECT,
	TE_DBALL_GOAL,
	TE_WIDOWBEAMOUT,
	TE_NUKEBLAST,
	TE_WIDOWSPLASH,
	TE_EXPLOSION1_BIG,
	TE_EXPLOSION1_NP,
	TE_FLECHETTE //ROGUE
    TE_BLUEHYPERBLASTER, // [Paril-KEX]
    TE_BFG_ZAP,
    TE_BERSERK_SLAM,
    TE_GRAPPLE_CABLE_2,
    TE_POWER_SPLASH,
    TE_LIGHTNING_BEAM,
    TE_EXPLOSION1_NL,
    TE_EXPLOSION2_NL// [Paril-KEX]*/
};

enum itemids_e
{
	IT_NULL,

	IT_ARMOR_BODY,
	IT_ARMOR_COMBAT,
	IT_ARMOR_JACKET,
	IT_ARMOR_SHARD,

	IT_ITEM_POWER_SCREEN,
	IT_ITEM_POWER_SHIELD,

	IT_ITEM_QUAD,
	IT_ITEM_INVULNERABILITY,
	IT_ITEM_INVISIBILITY,
	IT_ITEM_SILENCER,
	IT_ITEM_REBREATHER,
	IT_ITEM_ENVIROSUIT,
	IT_ITEM_ANCIENT_HEAD,
	IT_ITEM_ADRENALINE,
	IT_ITEM_BANDOLIER,
	IT_ITEM_PACK,

	IT_KEY_RED_KEY,

	IT_HEALTH_SMALL,
	IT_HEALTH_MEDIUM,
	IT_HEALTH_LARGE,
	IT_HEALTH_MEGA,

	IT_TOTAL
};

// means of death
enum mod_e
{
	MOD_UNKNOWN					= 0,
	MOD_BLASTER,
	MOD_SHOTGUN,
	MOD_SSHOTGUN,
	MOD_MACHINEGUN,
	MOD_CHAINGUN,					//5
	MOD_GRENADE,
	MOD_G_SPLASH,
	MOD_ROCKET,
	MOD_R_SPLASH,
	MOD_HYPERBLASTER,			//10
	MOD_RAILGUN,
	MOD_BFG_LASER,
	MOD_BFG_BLAST,
	MOD_BFG_EFFECT,
	MOD_HANDGRENADE,			//15
	MOD_HG_SPLASH,
	MOD_WATER,
	MOD_SLIME,
	MOD_LAVA,
	MOD_CRUSH,						//20
	MOD_TELEFRAG,
	MOD_TELEFRAG_SPAWN,
	MOD_FALLING,
	MOD_SUICIDE,
	MOD_HELD_GRENADE,			//25
	MOD_EXPLOSIVE,
	MOD_BARREL,
	MOD_BOMB,
	MOD_EXIT,
	MOD_SPLASH,						//30
	MOD_TARGET_LASER,
	MOD_TRIGGER_HURT,
	MOD_HIT,
	MOD_TARGET_BLASTER,
	MOD_RIPPER,						//35
	MOD_PHALANX,
	MOD_BRAINTENTACLE,
	MOD_BLASTOFF,
	MOD_GEKK,
	MOD_TRAP,							//40
	MOD_CHAINFIST,
	MOD_DISINTEGRATOR,
	MOD_ETF_RIFLE,
	MOD_BLASTER2,
	MOD_HEATBEAM,					//45
	MOD_TESLA,
	MOD_PROX,
	MOD_NUKE,
	MOD_VENGEANCE_SPHERE,
	MOD_HUNTER_SPHERE,			//50
	MOD_DEFENDER_SPHERE,
	MOD_TRACKER,
	MOD_DBALL_CRUSH,
	MOD_DOPPLE_EXPLODE,
	MOD_DOPPLE_VENGEANCE,	//55
	MOD_DOPPLE_HUNTER,
	MOD_GRAPPLE,
	MOD_BLUEBLASTER
};

enum gib_type_t
{
	GIB_NONE =      0, // no flags (organic)
	GIB_METALLIC =  1, // bouncier
	GIB_ACID =		2, // acidic (gekk)
	GIB_HEAD =		4, // head gib; the input entity will transform into this
	GIB_DEBRIS =	8, // explode outwards rather than in velocity, no blood
	GIB_SKINNED =	16, // use skinnum
	GIB_UPRIGHT =   32 // stay upright on ground
};

const int64 AI_NONE									= 0;					//0
const int64 AI_STAND_GROUND					= bit64( 0 );		//1
/*const int64 AI_TEMP_STAND_GROUND		= bit64( 1 );		//2
const int64 AI_SOUND_TARGET					= bit64( 2 );		//4
const int64 AI_LOST_SIGHT						= bit64( 3 );		//8
const int64 AI_PURSUIT_LAST_SEEN			= bit64( 4 );		//16
const int64 AI_PURSUE_NEXT						= bit64( 5 );		//32
const int64 AI_PURSUE_TEMP						= bit64( 6 );		//64
const int64 AI_HOLD_FRAME						= bit64( 7 );		//128
const int64 AI_GOOD_GUY							= bit64( 8 );		//256
const int64 AI_BRUTAL								= bit64( 9 );		//512
const int64 AI_NOSTEP								= bit64( 10 );	//1024
const int64 AI_DUCKED								= bit64( 11 );	//2048
const int64 AI_COMBAT_POINT					= bit64( 12 );	//4096*/
const int64 AI_MEDIC									= bit64( 13 );	//8192
const int64 AI_RESURRECTING					= bit64( 14 );	//16384
const int64 AI_MANUAL_STEERING				= bit64( 15 );	//32768
/*const int64 AI_TARGET_ANGER					= bit64( 16 );	//65536
const int64 AI_DODGING							= bit64( 17 );	//131072
const int64 AI_CHARGING							= bit64( 18 );	//262144
const int64 AI_HINT_PATH							= bit64( 19 );	//524288*/
const int64 AI_IGNORE_SHOTS					= bit64( 20 );	//1048576
const int64 AI_DO_NOT_COUNT					= bit64( 21 );	//2097152 // set for healed monsters
const int64 AI_SPAWNED_CARRIER				= bit64( 22 );	//4194304 // both do_not_count and spawned are set for spawned monsters
const int64 AI_SPAWNED_MEDIC_C				= bit64( 23 );	//8388608 // both do_not_count and spawned are set for spawned monsters
const int64 AI_SPAWNED_WIDOW				= bit64( 24 );	//16777216 // both do_not_count and spawned are set for spawned monsters
/*const int64 AI_BLOCKED								= bit64( 25 );	//33554432 // attacking while blocked
const int64 AI_SPAWNED_ALIVE					= bit64( 26 );	//67108864 // for spawning dead
const int64 AI_SPAWNED_DEAD					= bit64( 27 );	//134217728 
const int64 AI_HIGH_TICK_RATE					= bit64( 28 );	//268435456 // not limited by 10hz actions
const int64 AI_NO_PATH_FINDING				= bit64( 29 );	//536870912 // don't try nav nodes
const int64 AI_PATHING								= bit64( 30 );	//1073741824 // using nav nodes*/
const int64 AI_STINKY								= bit64( 31 );	//2147483648 // spawn flies
const int64 AI_STUNK								= bit64( 32 );	//4294967296 // already spawned flies
/*const int64 AI_ALTERNATE_FLY					= bit64( 33 );	//8589934592 // alternate flying mechanics
const int64 AI_TEMP_MELEE_COMBAT			= bit64( 34 );	//17179869184 // switch to melee
const int64 AI_FORGET_ENEMY					= bit64( 35 );	//34359738368 // forget current enemy
const int64 AI_DOUBLE_TROUBLE				= bit64( 36 );	//68719476736 // JORG only
const int64 AI_REACHED_HOLD_COMBAT	= bit64( 37 );	//137438953472
const int64 AI_THIRD_EYE							= bit64( 38 );	//274877906944*/

const int64 AI_SPAWNED_MASK = AI_SPAWNED_CARRIER | AI_SPAWNED_MEDIC_C | AI_SPAWNED_WIDOW; // mask to catch all three flavors of spawned 

const int64 FL_NONE									= 0;					//0	// no flags
/*const int64 FL_FLY										= bit64( 0 );		//1
const int64 FL_SWIM									= bit64( 1 );		//2	// implied immunity to drowning
const int64 FL_IMMUNE_LASER					= bit64( 2 );		//4
const int64 FL_INWATER								= bit64( 3 );		//8
const int64 FL_GODMODE							= bit64( 4 );		//16
const int64 FL_NOTARGET							= bit64( 5 );		//32
const int64 FL_IMMUNE_SLIME					= bit64( 6 );		//64
const int64 FL_IMMUNE_LAVA						= bit64( 7 );		//128
const int64 FL_PARTIALGROUND					= bit64( 8 );		//256	// not all corners are valid
const int64 FL_WATERJUMP							= bit64( 9 );		//512	// player jumping out of water
const int64 FL_TEAMSLAVE							= bit64( 10 );	//1024	// not the first on the team*/
const int64 FL_NO_KNOCKBACK					= bit64( 11 );	//2048
/*const int64 FL_POWER_ARMOR					= bit64( 12 );	//4096	// power armor (if any) is active
const int64 FL_MECHANICAL						= bit64( 13 );	//8192	// entity is mechanical, use sparks not blood
const int64 FL_SAM_RAIMI							= bit64( 14 );	//16384	// entity is in sam raimi cam mode
const int64 FL_DISGUISED							= bit64( 15 );	//32768	// entity is in disguise, monsters will not recognize.
const int64 FL_NOGIB								= bit64( 16 );	//65536	// player has been vaporized by a nuke, drop no gibs
const int64 FL_DAMAGEABLE						= bit64( 17 );	//131072
const int64 FL_STATIONARY						= bit64( 18 );	//262144
const int64 FL_ALIVE_KNOCKBACK_ONLY	= bit64( 19 );	//524288	// only apply knockback if alive or on same frame as death
const int64 FL_NO_DAMAGE_EFFECTS			= bit64( 20 );	//1048576
const int64 FL_COOP_HEALTH_SCALE			= bit64( 21 );	//2097152	////gets scaled by coop health scaling
const int64 FL_FLASHLIGHT						= bit64( 22 );	//4194304	// enable flashlight
const int64 FL_KILL_VELOCITY					= bit64( 23 );	//8388608	// for berserker slam
const int64 FL_NOVISIBLE							= bit64( 24 );	//16777216	// super invisibility
const int64 FL_DODGE								= bit64( 25 );	//33554432	// monster should try to dodge this
const int64 FL_TEAMMASTER						= bit64( 26 );	//67108864	// is a team master (only here so that entities abusing teammaster/teamchain for stuff don't break)
const int64 FL_LOCKED								= bit64( 27 );	//134217728	// entity is locked for the purposes of navigation
const int64 FL_ALWAYS_TOUCH					= bit64( 28 );	//268435456	// always touch, even if we normally wouldn't
const int64 FL_NO_STANDING						= bit64( 29 );	//536870912	// don't allow "standing" on non-brush entities
const int64 FL_WANTS_POWER_ARMOR		= bit64( 30 );	//1073741824	// for players, auto-shield
const int64 FL_RESPAWN							= bit64( 31 );	//2147483648	// used for item respawning
const int64 FL_TRAP									= bit64( 32 );	//4294967296	// entity is a trap of some kind
const int64 FL_TRAP_LASER_FIELD				= bit64( 33 );	//8589934592	// enough of a special case to get it's own flag...
const int64 FL_IMMORTAL							= bit64( 34 );	//17179869184	// never go below 1hp*/

// damage flags
enum damageflags_t
{
	DAMAGE_NONE = 0,							// no damage flags
	DAMAGE_RADIUS = 1,						// damage was indirect
	DAMAGE_NO_ARMOR = 2,					// armour does not protect from this damage
	DAMAGE_ENERGY = 4,						// damage is from an energy based weapon
	DAMAGE_NO_KNOCKBACK = 8,			// do not affect velocity, just view angles
	DAMAGE_BULLET = 16,						// damage is from a bullet (used for ricochets)
	DAMAGE_NO_PROTECTION = 32,		// armor, shields, invulnerability, and godmode have no effect
	DAMAGE_DESTROY_ARMOR = 64,		// damage is done to armor and health.
	DAMAGE_NO_REG_ARMOR = 128,		// damage skips regular armor
	DAMAGE_NO_POWER_ARMOR = 256,	// damage skips power armor
	DAMAGE_NO_INDICATOR = 512			// for clients: no damage indicators
};

int64 bit64( int n ) { return int64( 1 ) << n; }

} //end of namespace q2
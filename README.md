# SvenQuake2
Weapons, items, and NPCs from Quake 2 ported to Sven Co-op.  
Maps are a work in progress that I may or may not finish.

1) Download and put it in svencoop_addons, keeping directories
2) Add `map_script quake2/q2` to the map.cfg
3) uuuuuhhhh
4) common.as has some settings
5) Check sven-quake2.fgd and sven-quake2-items.fgd
6) If you want weapon pickups to levitate and spin, use the item_q2weaponname entities, weapon_q2weaponname (should) work like normal
7) Edit the text files in scripts\maps\quake2\data\ to your liking
8) If you're using the items (item_quad etc), make sure players spawn with weapon_q2inventory (it's a separator to prevent accidental item activation)
9) Players should also start with weapon_q2grenades for now (they start with 0 grenades so can't be used until finding ammo_q2grenades or the grenade launcher)  

Plugin TBM  

Models, textures, sounds, sprites, maps by iD Software.  

<BR>  

# NPCS #  

<BR>


## STROGG GUARD ##  
[Video](https://youtu.be/-_un4iP4fSQ?si=OQuB892iQe9vUACN)  
`npc_q2soldier`  

Refer to `sven-quake2.fgd` to see the keyvalues that set the weapons  


<BR>


## STROGG ENFORCER ##  
[Video](https://youtu.be/NX65qHFANG4?si=1CG-YtByvuoslJW2)  
`npc_q2enforcer`  


<BR>


## PARASITE ##  
`npc_q2parasite`  


<BR>


## GUNNER ##  
[Video](https://www.youtube.com/watch?v=tCUHC1iecLA)  
`npc_q2gunner`  


<BR>


## IRON MAIDEN ##  
[Video](https://youtu.be/_mOfQfemmFs?si=pDq6O0BbQIZNdi4g)  
`npc_q2ironmaiden`  


<BR>


## BERSERKER ##  
[Video](https://youtu.be/R6l1_VMTJeI?si=7GmLt90k4zb9akv2)  
`npc_q2berserker`  


<BR>


## GLADIATOR ##  
[Video](https://youtu.be/yO9gGEOXl5k?si=vuvS8mBnJ1117vBe)  
`npc_q2gladiator`  


<BR>


## TANK & TANK COMMANDER ##  
[Video1](https://youtu.be/LKZdsmOXIAE?si=AFAOJ9OJVEApDvye)  
`npc_q2tank`  
`npc_q2tankc`  


<BR>


## SUPER TANK ##  
[Video](https://youtu.be/s3EWMImdQoA?si=1WZc40cI0_HF2uSJ)  
`npc_q2supertank`  


<BR>


## JORG ##  
`npc_q2jorg`  


<BR>


## MAKRON ##  
`npc_q2makron`  


<BR>

<BR>

<BR>

# WEAPONS #  

item_q2weaponname levitates  
weapon_q2weaponname doesn't  

<BR>


## BLASTER ##  
Weapon Entity: `weapon_q2blaster`  


<BR> 


## SHOTGUN ##  
Weapon Entity: `weapon_q2shotgun`  
Pickup Entity: `item_q2shotgun`  
Ammo Name: `q2shells`  
Ammo Entity: `ammo_q2shells`  


<BR> 


## SUPER SHOTGUN ##  
Weapon Entity: `weapon_q2supershotgun`  
Pickup Entity: `item_q2supershotgun`  
Ammo Name: `q2shells`  
Ammo Entity: `ammo_q2shells` 


<BR> 


## MACHINE GUN ##  
Weapon Entity: `weapon_q2machinegun`  
Pickup Entity: `item_q2machinegun`  
Ammo Name: `q2bullets`  
Ammo Entity: `ammo_q2bullets`  


<BR> 


## CHAINGUN ##  
Weapon Entity: `weapon_q2chaingun`  
Pickup Entity: `item_q2chaingun`  
Ammo Name: `q2bullets`  
Ammo Entity: `ammo_q2bullets`  


<BR> 


## HAND GRENADES ##  
Weapon Entity: `weapon_q2grenades`  
Ammo Name: `q2grenades`  
Ammo Entity: `ammo_q2grenades`  


<BR> 


## GRENADE LAUNCHER ##  
Weapon Entity: `weapon_q2grenadelauncher`  
Pickup Entity: `item_q2grenadelauncher`  
Ammo Name: `q2grenades`  
Ammo Entity: `ammo_q2grenades`  


<BR> 


## ROCKET LAUNCHER ##  
Weapon Entity: `weapon_q2rocketlauncher`  
Pickup Entity: `item_q2rocketlauncher`  
Ammo Name: `q2rockets`  
Ammo Entity: `ammo_q2rockets`  


<BR> 


## HYPER BLASTER ##  
Weapon Entity: `weapon_q2hyperblaster`  
Pickup Entity: `item_q2hyperblaster`  
Ammo Name: `q2cells`  
Ammo Entity: `ammo_q2cells`  


<BR> 


## RAILGUN ##  
Weapon Entity: `weapon_q2railgun`  
Pickup Entity: `item_q2railgun`  
Ammo Name: `q2slugs`  
Ammo Entity: `ammo_q2slugs`  


<BR> 


## BFG 10K ##  
Weapon Entity: `weapon_q2bfg`  
Pickup Entity: `item_q2bfg`  
Ammo Name: `q2cells`  
Ammo Entity: `ammo_q2cells`  


<BR>

<BR>

<BR>

# HEALTH AND ARMOR ITEMS #  


<BR>


## STIMPACK ##  
`item_health_small`  


<BR>


## FIRST AID ##  
`item_health`  


<BR>


## MEDKIT ##  
`item_health_large`  


<BR>


## MEGAHEALTH ##  
`item_health_mega`  


<BR>


## ADRENALINE ##  
`item_adrenaline`  


<BR>


## ANCIENT HEAD ##  
`item_ancient_head`  


<BR>


## ARMOR SHARD ##  
`item_armor_shard`  


<BR>


## JACKET ARMOR ##  
`item_armor_jacket`  


<BR>


## COMBAT ARMOR ##  
`item_armor_combat`  


<BR>


## BODY ARMOR ##  
`item_armor_body`  


<BR>

<BR>


# HEALTH AND ARMOR ITEMS #  


<BR>


## STIMPACK ##  
`item_health_small`  
+2 health (ignores max health)  


<BR>


## FIRST AID ##  
`item_health`  


<BR>


## MEDKIT ##  
`item_health_large`  


<BR>


## MEGAHEALTH ##  
`item_health_mega`  


<BR>


## ADRENALINE ##  
`item_adrenaline`  


<BR>


## ANCIENT HEAD ##  
`item_ancient_head`  


<BR>


## ARMOR SHARD ##  
`item_armor_shard`  


<BR>


## JACKET ARMOR ##  
`item_armor_jacket`  


<BR>


## COMBAT ARMOR ##  
`item_armor_combat`  


<BR>


## BODY ARMOR ##  
`item_armor_body`  


<BR>

<BR>


# HEALTH AND ARMOR ITEMS #  


<BR>


## STIMPACK ##  
`item_health_small`  
+2 health (ignores max health)  


<BR>


## FIRST AID ##  
`item_health`  
+10 health  


<BR>


## MEDKIT ##  
`item_health_large`  
+25 health  


<BR>


## MEGAHEALTH ##  
`item_health_mega`  
+100 health (ignores max health)  


<BR>


## ADRENALINE ##  
`item_adrenaline`  
Full heal and +1 to max health  


<BR>


## ANCIENT HEAD ##  
`item_ancient_head`  
+5 to max health  


<BR>


## ARMOR SHARD ##  
`item_armor_shard`  
+2 armor (ignores max armor)  


<BR>


## JACKET ARMOR ##  
`item_armor_jacket`  
+25 armor (up to 50)  


<BR>


## COMBAT ARMOR ##  
`item_armor_combat`  
+50 armor (up to 100)  


<BR>


## BODY ARMOR ##  
`item_armor_body`  
+100 armor (up to 200)  


<BR>

<BR>


# OTHER ITEMS #  


<BR>


## QUAD DAMAGE ##  
`item_quad`  
Multiplies the damage of all your Quake 2 weapons by 4 for 30 seconds  


<BR>


## INVULNERABILITY ##  
`item_invulnerability`  
Makes you invulnerable for 30 seconds  


<BR>


## REBREATHER ##  
`item_breather`  
Lets you breathe under water for 30 seconds  


<BR>


## ENVIRO-SUIT ##  
`item_enviro`  
Lets you breathe under water for 30 seconds  
Makes you immune to slime (acid) damage, and reduces damage from swimming in lava  


<BR>


## SILENCER ##  
`item_silencer`  
All your Quake 2 weapons will be silenced (drawing less attention from enemies)  


<BR>


## POWER SCREEN ##  
`item_power_screen`  
Reduces damage taken while active, drains q2cells when hit, toggleable  


<BR>


## POWER SHIELD ##  
`item_power_shield`  
Reduces damage taken while active, drains q2cells when hit, toggleable  


<BR>


## BANDOLIER ##  
`item_bandolier`  
Increases max ammo for q2bullets, shells, cells, and slugs  
Gives 60 bullets and shells (without going over the max)  


<BR>


## AMMO PACK ##  
`item_pack`  
Increases max ammo for all Quake 2 ammo  
Gives 180 to all ammo (without going over the max)  


<BR>

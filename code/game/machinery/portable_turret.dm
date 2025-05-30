/*		Portable Turrets:
		Constructed from metal, a gun of choice, and a prox sensor.
		This code is slightly more documented than normal, as requested by XSI on IRC.
*/

#define TURRET_PRIORITY_TARGET 2
#define TURRET_SECONDARY_TARGET 1
#define TURRET_NOT_TARGET 0

/obj/machinery/porta_turret
	name = "turret"
	icon = 'icons/obj/turrets.dmi'
	icon_state = "turretCover"
	anchored = TRUE

	density = FALSE
	idle_power_usage = 50		//when inactive, this turret takes up constant 50 Equipment power
	active_power_usage = 300	//when active, this turret takes up constant 300 Equipment power
	power_channel = EQUIP	//drains power from the EQUIPMENT channel
	max_health = 80

	var/raised = 0			//if the turret cover is "open" and the turret is raised
	var/raising= 0			//if the turret is currently opening or closing its cover
	var/auto_repair = 0		//if 1 the turret slowly repairs itself.
	var/locked = 1			//if the turret's behaviour control access is locked
	var/controllock = 0		//if the turret responds to control panels

	var/installation = /obj/item/gun/energy/gun		//the type of weapon installed
	var/gun_charge = 0		//the charge of the gun inserted
	var/projectile = null	//holder for bullettype
	var/eprojectile = null	//holder for the shot when emagged
	var/reqpower = 500		//holder for power needed
	var/iconholder = null	//holder for the icon_state. 1 for orange sprite, null for blue.
	var/egun = null			//holder to handle certain guns switching bullettypes

	var/last_fired = 0		//1: if the turret is cooling down from a shot, 0: turret is ready to fire
	var/shot_delay = 15		//1.5 seconds between each shot

	var/check_arrest = 1	//checks if the perp is set to arrest
	var/check_records = 1	//checks if a security record exists at all
	var/check_weapons = 0	//checks if it can shoot people that have a weapon they aren't authorized to have
	var/check_access = 1	//if this is active, the turret shoots everything that does not meet the access requirements
	var/check_anomalies = 1	//checks if it can shoot at unidentified lifeforms
	var/check_synth	 = 0 	//if active, will shoot at anything not an AI or cyborg
	var/ailock = 0 			// AI cannot use this

	var/attacked = 0		//if set to 1, the turret gets pissed off and shoots at people nearby (unless they have sec access!)

	var/enabled = 1				//determines if the turret is on
	var/lethal = 0			//whether in lethal or stun mode
	var/disabled = 0

	var/shot_sound 			//what sound should play when the turret fires
	var/eshot_sound			//what sound should play when the emagged turret fires

	var/wrenching = 0
	var/last_target			//last target fired at, prevents turrets from erratically firing at all valid targets in range

	initial_access = list(list(access_security, access_bridge))

/obj/machinery/porta_turret/crescent
	enabled = 0
	ailock = 1
	check_synth	 = 0
	check_access = 1
	check_arrest = 1
	check_records = 1
	check_weapons = 1
	check_anomalies = 1
	initial_access = list(access_cent_specops)

/obj/machinery/porta_turret/stationary
	ailock = 1
	lethal = 1
	installation = /obj/item/gun/energy/laser

/obj/machinery/porta_turret/Initialize()
	. = ..()
	setup()

/obj/machinery/porta_turret/proc/setup()
	var/obj/item/gun/energy/E = installation	//All energy-based weapons are applicable
	//var/obj/item/ammo_casing/shottype = E.projectile_type

	projectile = initial(E.projectile_type)
	eprojectile = projectile
	shot_sound = initial(E.fire_sound)
	eshot_sound = shot_sound

	weapon_setup(installation)

/obj/machinery/porta_turret/proc/weapon_setup(var/guntype)
	switch(guntype)
		if(/obj/item/gun/energy/laser/practice)
			iconholder = 1
			eprojectile = /obj/item/projectile/beam

		if(/obj/item/gun/energy/captain)
			iconholder = 1

		if(/obj/item/gun/energy/lasercannon)
			iconholder = 1

		if(/obj/item/gun/energy/taser)
			eprojectile = /obj/item/projectile/beam
			eshot_sound = 'sound/weapons/Laser.ogg'

		if(/obj/item/gun/energy/gun)
			eprojectile = /obj/item/projectile/beam	//If it has, going to kill mode
			eshot_sound = 'sound/weapons/Laser.ogg'
			egun = 1

		if(/obj/item/gun/energy/gun/nuclear)
			eprojectile = /obj/item/projectile/beam	//If it has, going to kill mode
			eshot_sound = 'sound/weapons/Laser.ogg'
			egun = 1

var/global/list/turret_icons

/obj/machinery/porta_turret/on_update_icon()
	if(!turret_icons)
		turret_icons = list()
		turret_icons["open"] = image(icon, "openTurretCover")

	underlays.Cut()
	underlays += turret_icons["open"]

	if(stat & BROKEN)
		icon_state = "destroyed_target_prism"
	else if(raised || raising)
		if(!(stat & NOPOWER) && enabled)
			if(iconholder)
				//lasers have a orange icon
				icon_state = "orange_target_prism"
			else
				//almost everything has a blue icon
				icon_state = "target_prism"
		else
			icon_state = "grey_target_prism"
	else
		icon_state = "turretCover"

/obj/machinery/porta_turret/proc/isLocked(mob/user)
	if(ailock && issilicon(user))
		to_chat(user, "<span class='notice'>There seems to be a firewall preventing you from accessing this device.</span>")
		return 1

	if(locked && !issilicon(user))
		to_chat(user, "<span class='notice'>Access denied.</span>")
		return 1

	return 0

/obj/machinery/porta_turret/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/porta_turret/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/data[0]
	data["access"] = !isLocked(user)
	data["locked"] = locked
	data["enabled"] = enabled
	data["is_lethal"] = 1
	data["lethal"] = lethal

	if(data["access"])
		var/settings[0]
		settings[++settings.len] = list("category" = "Neutralize All Non-Synthetics", "setting" = "check_synth", "value" = check_synth)
		settings[++settings.len] = list("category" = "Check Weapon Authorization", "setting" = "check_weapons", "value" = check_weapons)
		settings[++settings.len] = list("category" = "Check Security Records", "setting" = "check_records", "value" = check_records)
		settings[++settings.len] = list("category" = "Check Arrest Status", "setting" = "check_arrest", "value" = check_arrest)
		settings[++settings.len] = list("category" = "Check Access Authorization", "setting" = "check_access", "value" = check_access)
		settings[++settings.len] = list("category" = "Check misc. Lifeforms", "setting" = "check_anomalies", "value" = check_anomalies)
		data["settings"] = settings

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "turret_control.tmpl", "Turret Controls", 500, 300)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/porta_turret/proc/HasController()
	var/area/A = get_area(src)
	return A && A.turret_controls.len > 0

/obj/machinery/porta_turret/CanUseTopic(var/mob/user)
	if(HasController())
		to_chat(user, "<span class='notice'>Turrets can only be controlled using the assigned turret controller.</span>")
		return STATUS_CLOSE

	if(isLocked(user))
		return STATUS_CLOSE

	if(!anchored)
		to_chat(usr, "<span class='notice'>\The [src] has to be secured first!</span>")
		return STATUS_CLOSE

	return ..()


/obj/machinery/porta_turret/Topic(href, href_list)
	if(..())
		return 1

	if(href_list["command"] && href_list["value"])
		var/value = text2num(href_list["value"])
		if(href_list["command"] == "enable")
			enabled = value
		else if(href_list["command"] == "lethal")
			lethal = value
		else if(href_list["command"] == "check_synth")
			check_synth = value
		else if(href_list["command"] == "check_weapons")
			check_weapons = value
		else if(href_list["command"] == "check_records")
			check_records = value
		else if(href_list["command"] == "check_arrest")
			check_arrest = value
		else if(href_list["command"] == "check_access")
			check_access = value
		else if(href_list["command"] == "check_anomalies")
			check_anomalies = value

		return 1

/obj/machinery/porta_turret/physically_destroyed(skip_qdel)
	if(installation)
		var/obj/item/gun/energy/Gun = new installation(loc)
		var/obj/item/cell/power_supply = Gun.get_cell()
		power_supply?.charge = gun_charge
		Gun.update_icon()
	if(prob(50))
		SSmaterials.create_object(/decl/material/solid/metal/steel, loc, rand(1,4))
	if(prob(50))
		new /obj/item/assembly/prox_sensor(loc)
	. = ..()

// TODO: remove these or refactor to use construct states
/obj/machinery/porta_turret/attackby(obj/item/I, mob/user)
	if(stat & BROKEN)
		if(IS_CROWBAR(I))
			//If the turret is destroyed, you can remove it with a crowbar to
			//try and salvage its components
			to_chat(user, "<span class='notice'>You begin prying the metal coverings off.</span>")
			if(do_after(user, 20, src))
				if(prob(70))
					to_chat(user, "<span class='notice'>You remove the turret and salvage some components.</span>")
					physically_destroyed()
				else
					to_chat(user, "<span class='notice'>You remove the turret but did not manage to salvage anything.</span>")
			return TRUE
		return FALSE

	else if(IS_WRENCH(I))
		if(enabled || raised)
			to_chat(user, "<span class='warning'>You cannot unsecure an active turret!</span>")
			return TRUE
		if(wrenching)
			to_chat(user, "<span class='warning'>Someone is already [anchored ? "un" : ""]securing the turret!</span>")
			return TRUE
		if(!anchored && isspaceturf(get_turf(src)))
			to_chat(user, "<span class='warning'>Cannot secure turrets in space!</span>")
			return TRUE

		user.visible_message( \
				"<span class='warning'>[user] begins [anchored ? "un" : ""]securing the turret.</span>", \
				"<span class='notice'>You begin [anchored ? "un" : ""]securing the turret.</span>" \
			)

		wrenching = 1
		if(do_after(user, 5 SECONDS, src))
			//This code handles moving the turret around. After all, it's a portable turret!
			playsound(loc, 'sound/items/Ratchet.ogg', 100, TRUE)
			anchored = !anchored
			update_icon()
			to_chat(user, "<span class='notice'>You [anchored ? "secure" : "unsecure"] the exterior bolts on [src].</span>")
		wrenching = 0
		return TRUE

	else if(istype(I, /obj/item/card/id)||istype(I, /obj/item/modular_computer))
		//Behavior lock/unlock mangement
		if(allowed(user))
			locked = !locked
			to_chat(user, "<span class='notice'>Controls are now [locked ? "locked" : "unlocked"].</span>")
			updateUsrDialog()
		else
			to_chat(user, "<span class='notice'>Access denied.</span>")
		return TRUE

	else
		//if the turret was attacked with the intention of harming it:
		var/force = I.get_attack_force(user) * 0.5
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		take_damage(force, I.atom_damage_type)
		if(force > 1) //if the force of impact dealt at least 1 damage, the turret gets pissed off
			if(!attacked && !emagged)
				attacked = 1
				spawn()
					sleep(6 SECONDS)
					attacked = 0
		return TRUE

/obj/machinery/porta_turret/emag_act(var/remaining_charges, var/mob/user)
	if(!emagged)
		//Emagging the turret makes it go bonkers and stun everyone. It also makes
		//the turret shoot much, much faster.
		to_chat(user, "<span class='warning'>You short out [src]'s threat assessment circuits.</span>")
		visible_message("[src] hums oddly...")
		emagged = 1
		iconholder = 1
		controllock = 1
		enabled = 0 //turns off the turret temporarily
		sleep(60) //6 seconds for the traitor to gtfo of the area before the turret decides to ruin his shit
		enabled = 1 //turns it back on. The cover popUp() popDown() are automatically called in process(), no need to define it here
		return 1

/obj/machinery/porta_turret/take_damage(damage, damage_type = BRUTE, damage_flags, inflicter, armor_pen = 0, silent, do_update_health)
	if(!raised && !raising)
		damage = damage / 8
		if(damage < 5)
			return

	current_health -= damage
	if (damage > 5 && prob(45))
		spark_at(src, amount = 5)
	if(current_health <= 0)
		die()	//the death process :(

/obj/machinery/porta_turret/bullet_act(obj/item/projectile/Proj)
	var/damage = Proj.get_structure_damage()

	if(!damage)
		return

	if(enabled)
		if(!attacked && !emagged)
			attacked = 1
			spawn()
				sleep(60)
				attacked = 0

	..()

	take_damage(damage)

/obj/machinery/porta_turret/emp_act(severity)
	if(enabled)
		//if the turret is on, the EMP no matter how severe disables the turret for a while
		//and scrambles its settings, with a slight chance of having an emag effect
		check_arrest = prob(50)
		check_records = prob(50)
		check_weapons = prob(50)
		check_access = prob(20)	// check_access is a pretty big deal, so it's least likely to get turned on
		check_anomalies = prob(50)
		if(prob(5))
			emagged = 1

	disabled = 1
	var/power = 4 - severity
	addtimer(CALLBACK(src, TYPE_PROC_REF(/obj/machinery/porta_turret, enable)), rand(60*power,600*power))

	..()

/obj/machinery/porta_turret/proc/enable()
	if(disabled)
		disabled = 0

/obj/machinery/porta_turret/explosion_act(severity)
	. = ..()
	if(. && !QDELETED(src))
		if(severity == 1 || (severity == 2 && prob(25)))
			physically_destroyed()
		else if(severity == 2)
			take_damage(initial(current_health) * 8)
		else
			take_damage(initial(current_health) * 8 / 3)

/obj/machinery/porta_turret/proc/die()	//called when the turret dies, ie, health <= 0
	current_health = 0
	set_broken(TRUE)
	spark_at(src, amount = 5)
	atom_flags |= ATOM_FLAG_CLIMBABLE // they're now climbable

/obj/machinery/porta_turret/Process()

	if(stat & (NOPOWER|BROKEN))
		//if the turret has no power or is broken, make the turret pop down if it hasn't already
		popDown()
		return

	if(!enabled)
		//if the turret is off, make it pop down
		popDown()
		return

	var/list/targets = list()			//list of primary targets
	var/list/secondarytargets = list()	//targets that are least important

	for(var/mob/M in mobs_in_view(world.view, src))
		assess_and_assign(M, targets, secondarytargets)

	if(!tryToShootAt(targets) && !tryToShootAt(secondarytargets)) // if no valid targets, go for secondary targets
		popDown() // no valid targets, close the cover

	var/current_max_health = get_max_health()
	if(auto_repair && (current_health < current_max_health))
		use_power_oneoff(20000)
		current_health = min(current_health+1, current_max_health) // 1HP for 20kJ

/obj/machinery/porta_turret/proc/assess_and_assign(var/mob/living/L, var/list/targets, var/list/secondarytargets)
	switch(assess_living(L))
		if(TURRET_PRIORITY_TARGET)
			targets += L
		if(TURRET_SECONDARY_TARGET)
			secondarytargets += L

/obj/machinery/porta_turret/proc/assess_living(var/mob/living/L)
	if(!istype(L) || !L.simulated)
		return TURRET_NOT_TARGET

	if(L.invisibility >= INVISIBILITY_LEVEL_ONE) // Cannot see him. see_invisible is a mob-var
		return TURRET_NOT_TARGET

	if(!emagged && issilicon(L))	// Don't target silica
		return TURRET_NOT_TARGET

	if(L.stat && !emagged)		//if the perp is dead/dying, no need to bother really
		return TURRET_NOT_TARGET	//move onto next potential victim!

	if(get_dist(src, L) > 7)	//if it's too far away, why bother?
		return TURRET_NOT_TARGET

	if(!(L in check_trajectory(L, src)))	//check if we have true line of sight
		return TURRET_NOT_TARGET

	if(emagged)		// If emagged not even the dead get a rest
		return L.stat ? TURRET_SECONDARY_TARGET : TURRET_PRIORITY_TARGET

	if(lethal && locate(/mob/living/silicon/ai) in get_turf(L))		//don't accidentally kill the AI!
		return TURRET_NOT_TARGET

	if(check_synth)	//If it's set to attack all non-silicons, target them!
		if(L.current_posture.prone)
			return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET
		return TURRET_PRIORITY_TARGET

	if(iscuffed(L)) // If the target is cuffed, leave it alone
		return TURRET_NOT_TARGET

	if(isanimal(L) || issmall(L)) // Animals are not so dangerous
		return check_anomalies ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	if(assess_perp(L) < 4) //if the target is a human, analyze threat level
		return TURRET_NOT_TARGET	//if threat level < 4, keep going

	if(L.current_posture.prone)		//if the perp is lying down, it's still a target but a less-important target
		return lethal ? TURRET_SECONDARY_TARGET : TURRET_NOT_TARGET

	return TURRET_PRIORITY_TARGET	//if the perp has passed all previous tests, congrats, it is now a "shoot-me!" nominee

/obj/machinery/porta_turret/proc/assess_perp(var/mob/living/perp)
	if(!istype(perp))
		return 0
	if(emagged)
		return 10
	return perp.assess_perp(src, check_access, check_weapons, check_records, check_arrest)

/obj/machinery/porta_turret/proc/tryToShootAt(var/list/mob/living/targets)
	if(length(targets) && last_target && (last_target in targets) && target(last_target))
		return 1

	while(length(targets))
		var/mob/living/M = pick_n_take(targets)
		if(target(M))
			return TRUE

/obj/machinery/porta_turret/proc/popUp()	//pops the turret up
	if(disabled)
		return
	if(raising || raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = new /atom/movable/porta_turret_cover(loc)
	flick_holder.layer = layer + 0.1
	flick("popup", flick_holder)
	sleep(10)
	qdel(flick_holder)

	set_raised_raising(1, 0)
	update_icon()

/obj/machinery/porta_turret/proc/popDown()	//pops the turret down
	set waitfor = FALSE
	last_target = null
	if(disabled)
		return
	if(raising || !raised)
		return
	if(stat & BROKEN)
		return
	set_raised_raising(raised, 1)
	update_icon()

	var/atom/flick_holder = new /atom/movable/porta_turret_cover(loc)
	flick_holder.layer = layer + 0.1
	flick("popdown", flick_holder)
	sleep(10)
	qdel(flick_holder)

	set_raised_raising(0, 0)
	update_icon()

/obj/machinery/porta_turret/proc/set_raised_raising(var/raised, var/raising)
	src.raised = raised
	src.raising = raising
	set_density(raised || raising)

/obj/machinery/porta_turret/proc/target(var/mob/living/target)
	if(disabled)
		return
	if(target)
		last_target = target
		spawn()
			popUp()				//pop the turret up if it's not already up.
		set_dir(get_dir(src, target))	//even if you can't shoot, follow the target
		spawn()
			shootAt(target)
		return 1
	return

/obj/machinery/porta_turret/proc/shootAt(var/mob/living/target)
	//any emagged turrets will shoot extremely fast! This not only is deadly, but drains a lot power!
	if(!(emagged || attacked))		//if it hasn't been emagged or attacked, it has to obey a cooldown rate
		if(last_fired || !raised)	//prevents rapid-fire shooting, unless it's been emagged
			return
		last_fired = 1
		spawn()
			sleep(shot_delay)
			last_fired = 0

	var/turf/T = get_turf(src)
	var/turf/U = get_turf(target)
	if(!istype(T) || !istype(U))
		return

	if(!raised) //the turret has to be raised in order to fire - makes sense, right?
		return

	update_icon()
	var/obj/item/projectile/A
	if(emagged || lethal)
		A = new eprojectile(loc)
		playsound(loc, eshot_sound, 75, 1)
	else
		A = new projectile(loc)
		playsound(loc, shot_sound, 75, 1)

	// Lethal/emagged turrets use twice the power due to higher energy beams
	// Emagged turrets again use twice as much power due to higher firing rates
	use_power_oneoff(reqpower * (2 * (emagged || lethal)) * (2 * emagged))

	//Turrets aim for the center of mass by default.
	//If the target is grabbing someone then the turret smartly aims for extremities
	var/def_zone = get_exposed_defense_zone(target)
	//Shooting Code:
	A.launch(target, def_zone)

/datum/turret_checks
	var/enabled
	var/lethal
	var/check_synth
	var/check_access
	var/check_records
	var/check_arrest
	var/check_weapons
	var/check_anomalies
	var/ailock

/obj/machinery/porta_turret/proc/setState(var/datum/turret_checks/TC)
	if(controllock)
		return
	src.enabled = TC.enabled
	src.lethal = TC.lethal
	src.iconholder = TC.lethal

	check_synth = TC.check_synth
	check_access = TC.check_access
	check_records = TC.check_records
	check_arrest = TC.check_arrest
	check_weapons = TC.check_weapons
	check_anomalies = TC.check_anomalies
	ailock = TC.ailock

	src.power_change()

/atom/movable/porta_turret_cover
	icon = 'icons/obj/turrets.dmi'




#undef TURRET_PRIORITY_TARGET
#undef TURRET_SECONDARY_TARGET
#undef TURRET_NOT_TARGET

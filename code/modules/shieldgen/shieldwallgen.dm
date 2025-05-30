////FIELD GEN START //shameless copypasta from fieldgen, powersink, and grille
/obj/machinery/shieldwallgen
	name = "Shield Generator"
	desc = "A shield generator."
	icon = 'icons/obj/machines/shieldgen.dmi'
	icon_state = "Shield_Gen"
	anchored = FALSE
	density = TRUE
	initial_access = list(list(access_engine_equip, access_research))
	var/active = 0
	var/power = 0
	var/locked = 1
	var/max_range = 8
	var/storedpower = 0
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	//There have to be at least two posts, so these are effectively doubled
	var/power_draw = 30 KILOWATTS //30 kW. How much power is drawn from powernet. Increase this to allow the generator to sustain longer shields, at the cost of more power draw.
	var/max_stored_power = 50 KILOWATTS //50 kW
	use_power = POWER_USE_OFF	//Draws directly from power net. Does not use APC power.
	active_power_usage = 1200

/obj/machinery/shieldwallgen/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1, var/datum/topic_state/state = global.default_topic_state)
	var/list/data = list()
	data["draw"] = round(power_draw)
	data["power"] = round(storedpower)
	data["maxpower"] = round(max_stored_power)
	data["current_draw"] = ((clamp(max_stored_power - storedpower, 500, power_draw)) + power ? active_power_usage : 0)
	data["online"] = active == 2 ? 1 : 0

	ui = SSnano.try_update_ui(user, src, ui_key, ui, data, force_open)
	if (!ui)
		ui = new(user, src, ui_key, "shield.tmpl", "Shielding", 800, 500, state = state)
		ui.set_initial_data(data)
		ui.open()
		ui.set_auto_update(1)

/obj/machinery/shieldwallgen/on_update_icon()
//	if(stat & BROKEN) -TODO: Broken icon
	if(!active)
		icon_state = "Shield_Gen"
	else
		icon_state = "Shield_Gen +a"

/obj/machinery/shieldwallgen/OnTopic(var/mob/user, href_list)
	if(href_list["toggle"])
		if(src.active >= 1)
			src.active = 0
			update_icon()

			user.visible_message("\The [user] turned the shield generator off.", \
				"You turn off the shield generator.", \
				"You hear heavy droning fade out.")
			for(var/dir in list(1,2,4,8)) src.cleanup(dir)
		else
			src.active = 1
			update_icon()
			user.visible_message("\The [user] turned the shield generator on.", \
				"You turn on the shield generator.", \
				"You hear heavy droning.")
		return TOPIC_REFRESH

/obj/machinery/shieldwallgen/explosion_act(var/severity)
	. = ..()
	if(.)
		switch(severity)
			if(1)
				active = 0
				storedpower = 0
			if(2)
				storedpower -= rand(min(storedpower,max_stored_power/2), max_stored_power)
			if(3)
				storedpower -= rand(0, max_stored_power)

/obj/machinery/shieldwallgen/emp_act(var/severity)
	switch(severity)
		if(1)
			storedpower = 0
		if(2)
			storedpower -= rand(storedpower/2, storedpower)
		if(3)
			storedpower -= rand(storedpower/4, storedpower/2)
	..()

/obj/machinery/shieldwallgen/CanUseTopic(mob/user)
	if(!anchored)
		to_chat(user, "<span class='warning'>The shield generator needs to be firmly secured to the floor first.</span>")
		return STATUS_CLOSE
	if(src.locked && !issilicon(user))
		to_chat(user, "<span class='warning'>The controls are locked!</span>")
		return STATUS_CLOSE
	if(power != 1)
		to_chat(user, "<span class='warning'>The shield generator needs to be powered by wire underneath.</span>")
		return STATUS_CLOSE
	return ..()

/obj/machinery/shieldwallgen/interface_interact(mob/user)
	ui_interact(user)
	return TRUE

/obj/machinery/shieldwallgen/proc/power()
	if(!anchored)
		power = 0
		return 0

	var/turf/T = src.loc
	if(!T)
		power = 0
		return 0

	var/obj/structure/cable/C = T.get_cable_node()
	var/datum/powernet/PN
	if(C)	PN = C.powernet		// find the powernet of the connected cable

	if(PN)
		var/shieldload = clamp(max_stored_power - storedpower, 500, power_draw)	//what we try to draw
		shieldload = PN.draw_power(shieldload) //what we actually get
		storedpower += shieldload

	//If we're still in the red, then there must not be enough available power to cover our load.
	if(storedpower <= 0)
		power = 0
		return 0

	power = 1	// IVE GOT THE POWER!
	return 1

/obj/machinery/shieldwallgen/Process()
	..()
	power = 0
	if(!(stat & BROKEN))
		power()
	if(power)
		storedpower -= active_power_usage //the generator post itself uses some power

	if(storedpower >= max_stored_power)
		storedpower = max_stored_power
	if(storedpower <= 0)
		storedpower = 0

	if(src.active == 1)
		if(!src.anchored == 1)
			src.active = 0
			return
		spawn(1)
			setup_field(1)
		spawn(2)
			setup_field(2)
		spawn(3)
			setup_field(4)
		spawn(4)
			setup_field(8)
		src.active = 2
	if(src.active >= 1)
		if(src.power == 0)
			src.visible_message("<span class='warning'>\The [src] shuts down due to lack of power!</span>", \
				"You hear heavy droning fade away.")
			src.active = 0
			update_icon()
			for(var/dir in list(1,2,4,8)) src.cleanup(dir)

/obj/machinery/shieldwallgen/proc/setup_field(var/NSEW = 0)
	var/turf/T = get_turf(src)
	if(!T) return
	var/turf/T2 = T
	var/obj/machinery/shieldwallgen/G
	var/steps = 0
	var/oNSEW = 0

	if(!NSEW)//Make sure its ran right
		return

	if(NSEW == 1)
		oNSEW = 2
	else if(NSEW == 2)
		oNSEW = 1
	else if(NSEW == 4)
		oNSEW = 8
	else if(NSEW == 8)
		oNSEW = 4

	for(var/dist = 0, dist <= (max_range+1), dist += 1) // checks out to 8 tiles away for another generator
		T = get_step(T2, NSEW)
		T2 = T
		steps += 1
		if(locate(/obj/machinery/shieldwallgen) in T)
			G = (locate(/obj/machinery/shieldwallgen) in T)
			steps -= 1
			if(!G.active)
				return
			G.cleanup(oNSEW)
			break

	if(isnull(G))
		return

	T2 = src.loc

	for(var/dist = 0, dist < steps, dist += 1) // creates each field tile
		var/field_dir = get_dir(T2,get_step(T2, NSEW))
		T = get_step(T2, NSEW)
		T2 = T
		var/obj/machinery/shieldwall/CF = new(T, src, G) //(ref to this gen, ref to connected gen)
		CF.set_dir(field_dir)


/obj/machinery/shieldwallgen/attackby(obj/item/W, mob/user)
	if(IS_WRENCH(W))
		if(active)
			to_chat(user, "Turn off the field generator first.")
			return TRUE
		if(!anchored)
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
			to_chat(user, "You secure the external reinforcing bolts to the floor.")
			src.anchored = TRUE
			return TRUE
		playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
		to_chat(user, "You undo the external reinforcing bolts.")
		src.anchored = FALSE
		return TRUE

	if(istype(W, /obj/item/card/id)||istype(W, /obj/item/modular_computer))
		if (src.allowed(user))
			src.locked = !src.locked
			to_chat(user, "Controls are now [src.locked ? "locked." : "unlocked."]")
		else
			to_chat(user, "<span class='warning'>Access denied.</span>")
		return TRUE
	return ..()


/obj/machinery/shieldwallgen/proc/cleanup(var/NSEW)
	var/obj/machinery/shieldwall/F
	var/obj/machinery/shieldwallgen/G
	var/turf/T = src.loc
	var/turf/T2 = src.loc

	for(var/dist = 0, dist <= (max_range+1), dist += 1) // checks out to 8 tiles away for fields
		T = get_step(T2, NSEW)
		T2 = T
		if(locate(/obj/machinery/shieldwall) in T)
			F = (locate(/obj/machinery/shieldwall) in T)
			qdel(F)

		if(locate(/obj/machinery/shieldwallgen) in T)
			G = (locate(/obj/machinery/shieldwallgen) in T)
			if(!G.active)
				break

/obj/machinery/shieldwallgen/Destroy()
	src.cleanup(NORTH)
	src.cleanup(SOUTH)
	src.cleanup(EAST)
	src.cleanup(WEST)
	. = ..()


//////////////Containment Field START
/obj/machinery/shieldwall
	name = "shield"
	desc = "An energy shield."
	icon = 'icons/effects/effects.dmi'
	icon_state = "shieldwall"
	anchored = TRUE
	density = TRUE
	light_range = 3
	frame_type = null
	construct_state = /decl/machine_construction/noninteractive
	var/needs_power = FALSE
	var/obj/machinery/shieldwallgen/gen_primary
	var/obj/machinery/shieldwallgen/gen_secondary
	var/power_usage = 800	//how much power it takes to sustain the shield
	var/generate_power_usage = 5000	//how much power it takes to start up the shield

/obj/machinery/shieldwall/proc/use_generator_power(amount)
	if(!needs_power)
		return
	var/obj/machinery/shieldwallgen/G = pick(gen_primary, gen_secondary) // if we use power and still exist, we assume we have both generators
	G.storedpower -= amount

/obj/machinery/shieldwall/take_damage(amount, damtype, silent)
	if(amount <= 0)
		return
	if(damtype != BRUTE && damtype != BURN && damtype != ELECTROCUTE)
		return
	. = ..() // mostly just plays sound effects on damage
	use_generator_power(500 * amount)

// This should never be deleted via anything but the generator running out of power.
/obj/machinery/shieldwall/dismantle()
	return FALSE // nope!

/obj/machinery/shieldwall/Initialize(mapload, obj/machinery/shieldwallgen/A, obj/machinery/shieldwallgen/B)
	. = ..(mapload)
	update_nearby_tiles()
	gen_primary = A
	gen_secondary = B
	if(gen_primary?.active && gen_secondary?.active)
		needs_power = TRUE
		use_generator_power(generate_power_usage)
	else
		return INITIALIZE_HINT_QDEL

/obj/machinery/shieldwall/Destroy()
	gen_primary = null
	gen_secondary = null
	update_nearby_tiles()
	. = ..()

/obj/machinery/shieldwall/Process()
	if(!needs_power)
		return
	if(QDELETED(gen_primary) || QDELETED(gen_secondary))
		qdel(src)
		return
	if(!gen_primary.active || !gen_secondary.active)
		qdel(src)
		return
	use_generator_power(power_usage)

/obj/machinery/shieldwall/explosion_act(severity)
	SHOULD_CALL_PARENT(FALSE)
	if(!needs_power)
		return
	take_damage(100/severity, BRUTE, TRUE) // will drain power according to damage

/obj/machinery/shieldwall/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(!height || air_group || !density)
		return TRUE
	if(istype(mover) && mover.checkpass(PASS_FLAG_GLASS))
		return prob(20)
	if (istype(mover, /obj/item/projectile))
		return prob(10)
	return FALSE

/obj/machinery/shieldwallgen/online
	anchored = TRUE
	active = TRUE

/obj/machinery/shieldwallgen/online/Initialize()
	storedpower = max_stored_power
	. = ..()
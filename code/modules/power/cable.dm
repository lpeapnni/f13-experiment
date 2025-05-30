///////////////////////////////
//CABLE STRUCTURE
///////////////////////////////


////////////////////////////////
// Definitions
////////////////////////////////

/* Cable directions (d1 and d2)


>  9   1   5
>    \ | /
>  8 - 0 - 4
>    / | \
>  10  2   6

If d1 = 0 and d2 = 0, there's no cable
If d1 = 0 and d2 = dir, it's a O-X cable, getting from the center of the tile to dir (knot cable)
If d1 = dir1 and d2 = dir2, it's a full X-X cable, getting from dir1 to dir2
By design, d1 is the smallest direction and d2 is the highest
*/

/obj/structure/cable
	name = "power cable"
	desc = "A flexible superconducting cable for heavy-duty power transfer."
	icon = 'icons/obj/power_cond_white.dmi'
	icon_state =  "0-1"
	layer =       EXPOSED_WIRE_LAYER
	color =       COLOR_MAROON
	paint_color = COLOR_MAROON
	anchored = TRUE
	obj_flags = OBJ_FLAG_MOVES_UNSUPPORTED
	level = LEVEL_BELOW_PLATING

	/// The base cable stack that should be produced, not including color.
	/// cable_type::stack_merge_type should equal cable_type, ideally
	var/cable_type = /obj/item/stack/cable_coil
	/// Whether this cable type can be (re)colored.
	var/can_have_color = TRUE
	var/d1
	var/d2
	var/datum/powernet/powernet
	var/obj/machinery/power/breakerbox/breaker_box

/obj/structure/cable/drain_power(var/drain_check, var/surge, var/amount = 0)

	if(drain_check)
		return 1

	var/datum/powernet/PN = get_powernet()
	if(!PN) return 0

	return PN.draw_power(amount)

/obj/structure/cable/yellow
	color = COLOR_AMBER
	paint_color = COLOR_AMBER

/obj/structure/cable/green
	color = COLOR_GREEN
	paint_color = COLOR_GREEN

/obj/structure/cable/blue
	color = COLOR_CYAN_BLUE
	paint_color = COLOR_CYAN_BLUE

/obj/structure/cable/pink
	color = COLOR_PURPLE
	paint_color = COLOR_PURPLE

/obj/structure/cable/orange
	color = COLOR_ORANGE
	paint_color = COLOR_ORANGE

/obj/structure/cable/cyan
	color = COLOR_SKY_BLUE
	paint_color = COLOR_SKY_BLUE

/obj/structure/cable/white
	color = COLOR_SILVER
	paint_color = COLOR_SILVER

/obj/structure/cable/Initialize(var/ml)
	// ensure d1 & d2 reflect the icon_state for entering and exiting cable
	. = ..(ml)
	var/turf/T = src.loc			// hide if turf is not intact
	if(level == LEVEL_BELOW_PLATING && T)
		hide(!T.is_plating())
	global.cable_list += src //add it to the global cable list

/obj/structure/cable/Destroy()     // called when a cable is deleted
	if(powernet)
		cut_cable_from_powernet()  // update the powernets
	global.cable_list -= src              // remove it from global cable list
	. = ..()                       // then go ahead and delete the cable

// Ghost examining the cable -> tells him the power
/obj/structure/cable/attack_ghost(mob/user)
	if(user.client && user.client.inquisitive_ghost)
		user.examinate(src)
		// following code taken from attackby (multitool)
		if(powernet && (powernet.avail > 0))
			to_chat(user, SPAN_WARNING("[get_wattage()] in power network."))
		else
			to_chat(user, SPAN_WARNING("\The [src] is not powered."))
	return

///////////////////////////////////
// General procedures
///////////////////////////////////

/obj/structure/cable/proc/get_wattage()
	if(powernet.avail >=  1 GIGAWATTS)
		return "[round(powernet.avail/(1 MEGAWATTS), 0.01)] MW"
	if(powernet.avail >= 1 MEGAWATTS)
		return "[round(powernet.avail/(1 KILOWATTS), 0.01)] kW"
	return "[round(powernet.avail)] W"

//If underfloor, hide the cable
/obj/structure/cable/hide(var/i)
	if(isturf(loc))
		set_invisibility(i ? 101 : 0)
	update_icon()

/obj/structure/cable/hides_under_flooring()
	return 1

/obj/structure/cable/on_update_icon()
	..()
	// It is really gross to do this here but the order of icon updates to init seems
	// unreliable and I have now had to spend hours across two PRs chasing down
	// cable node weirdness due to the way this was handled previously. NO MORE.
	if(isnull(d1) || isnull(d2))
		var/dir_components = splittext(icon_state, "-")
		if(length(dir_components) < 2)
			CRASH("Cable segment updating dirs with invalid icon_state: [d1], [d2]")
		d1 = text2num(dir_components[1])
		d2 = text2num(dir_components[2])
		if(!(d1 in global.cabledirs) || !(d2 in global.cabledirs))
			CRASH("Cable segment updating dirs with invalid values: [d1], [d2]")

	icon_state = "[d1]-[d2]"
	alpha = invisibility ? 127 : 255

/obj/structure/cable/shuttle_rotate(angle)
	// DON'T CALL PARENT, we never change our actual dir
	if(d1 == 0)
		d2 = turn(d2, angle)
	else
		var/nd1 = min(turn(d1, angle), turn(d2, angle))
		var/nd2 = max(turn(d1, angle), turn(d2, angle))
		d1 = nd1
		d2 = nd2
	update_icon()

// returns the powernet this cable belongs to
/obj/structure/cable/proc/get_powernet()			//TODO: remove this as it is obsolete
	return powernet

// Items usable on a cable :
//   - Wirecutters : cut it duh !
//   - Cable coil : merge cables
//   - Multitool : get the power currently passing through the cable
//

// TODO: take a closer look at cable attackby, make it call parent?
/obj/structure/cable/attackby(obj/item/used_item, mob/user)

	if(IS_WIRECUTTER(used_item))
		cut_wire(used_item, user)
		return TRUE

	if(IS_COIL(used_item))
		var/obj/item/stack/cable_coil/coil = used_item
		if (coil.get_amount() < 1)
			to_chat(user, "You don't have enough cable to lay down.")
			return TRUE
		coil.cable_join(src, user)
		return TRUE

	if(IS_MULTITOOL(used_item))
		if(powernet && (powernet.avail > 0))		// is it powered?
			to_chat(user, SPAN_WARNING("[get_wattage()] in power network."))
			shock(user, 5, 0.2)
		else
			to_chat(user, SPAN_WARNING("\The [src] is not powered."))
		return TRUE

	if(used_item.edge)
		var/delay_holder
		if(used_item.get_attack_force(user) < 5)
			visible_message(SPAN_WARNING("[user] starts sawing away roughly at \the [src] with \the [used_item]."))
			delay_holder = 8 SECONDS
		else
			visible_message(SPAN_WARNING("[user] begins to cut through \the [src] with \the [used_item]."))
			delay_holder = 3 SECONDS
		if(user.do_skilled(delay_holder, SKILL_ELECTRICAL, src))
			cut_wire(used_item, user)
			if(used_item.obj_flags & OBJ_FLAG_CONDUCTIBLE)
				shock(user, 66, 0.7)
		else
			visible_message(SPAN_WARNING("[user] stops cutting before any damage is done."))
		return TRUE

	return ..()

/obj/structure/cable/proc/cut_wire(obj/item/used_item, mob/user)
	var/turf/T = get_turf(src)
	if(!T || !T.is_plating())
		return

	if(d1 == UP || d2 == UP)
		to_chat(user, SPAN_WARNING("You must cut this [name] from above."))
		return

	if(breaker_box)
		to_chat(user, SPAN_WARNING("This [name] is connected to a nearby breaker box. Use the breaker box to interact with it."))
		return

	if (shock(user, 50))
		return

	new cable_type(T, (src.d1 ? 2 : 1), color)

	visible_message(SPAN_WARNING("[user] cuts \the [src]."))

	if(HasBelow(z))
		for(var/turf/turf in GetBelow(src))
			for(var/obj/structure/cable/c in turf)
				if(c.d1 == UP || c.d2 == UP)
					qdel(c)

	investigate_log("was cut by [key_name(usr, usr.client)] in [get_area_name(user)]","wires")

	qdel(src)

// shock the user with probability prb
/obj/structure/cable/proc/shock(mob/user, prb, var/siemens_coeff = 1.0)
	if(!prob(prb) || powernet?.avail <= 0)
		return FALSE
	if (electrocute_mob(user, powernet, src, siemens_coeff))
		spark_at(src, amount=5, cardinal_only = TRUE)
		if(HAS_STATUS(usr, STAT_STUN))
			return TRUE
	return FALSE

// TODO: generalize to matter list and parts_type.
/obj/structure/cable/create_dismantled_products(turf/T)
	SHOULD_CALL_PARENT(FALSE)
	new /obj/item/stack/cable_coil(loc, (d1 ? 2 : 1), color)

//explosion handling
/obj/structure/cable/explosion_act(severity)
	. = ..()
	if(. && (severity == 1 || (severity == 2 && prob(50)) || (severity == 3 && prob(25))))
		physically_destroyed()

/obj/structure/cable/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	var/turf/T = get_turf(src)
	if(!T || !T.is_plating())
		return
	. = ..()

/obj/structure/cable/proc/cableColor(var/colorC)
	if(!can_have_color)
		return
	var/color_n = "#dd0000"
	if(colorC)
		color_n = colorC
	set_color(color_n)

/////////////////////////////////////////////////
// Cable laying helpers
////////////////////////////////////////////////

//handles merging diagonally matching cables
//for info : direction^3 is flipping horizontally, direction^12 is flipping vertically
/obj/structure/cable/proc/mergeDiagonalsNetworks(var/direction)

	//search for and merge diagonally matching cables from the first direction component (north/south)
	var/turf/T  = get_step_resolving_mimic(src, direction & (NORTH|SOUTH))

	for(var/obj/structure/cable/C in T)

		if(!C)
			continue

		if(src == C)
			continue

		if(C.d1 == (direction ^ (NORTH|SOUTH)) || C.d2 == (direction ^ (NORTH|SOUTH))) //we've got a diagonally matching cable
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

	//the same from the second direction component (east/west)
	T  = get_step_resolving_mimic(src, direction & (EAST|WEST))

	for(var/obj/structure/cable/C in T)

		if(!C)
			continue

		if(src == C)
			continue
		if(C.d1 == (direction ^ (EAST|WEST)) || C.d2 == (direction ^ (EAST|WEST))) //we've got a diagonally matching cable
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the given direction
/obj/structure/cable/proc/mergeConnectedNetworks(var/direction)

	var/fdir = direction ? global.reverse_dir[direction] : 0 //flip the direction, to match with the source position on its turf

	if(!(d1 == direction || d2 == direction)) //if the cable is not pointed in this direction, do nothing
		return

	var/turf/TB  = get_zstep_resolving_mimic(src, direction)

	for(var/obj/structure/cable/C in TB)

		if(!C)
			continue

		if(src == C)
			continue

		if(C.d1 == fdir || C.d2 == fdir) //we've got a matching cable in the neighbor turf
			if(!C.powernet) //if the matching cable somehow got no powernet, make him one (should not happen for cables)
				var/datum/powernet/newPN = new()
				newPN.add_cable(C)

			if(powernet) //if we already have a powernet, then merge the two powernets
				merge_powernets(powernet,C.powernet)
			else
				C.powernet.add_cable(src) //else, we simply connect to the matching cable powernet

// merge with the powernets of power objects in the source turf
/obj/structure/cable/proc/mergeConnectedNetworksOnTurf()
	var/list/to_connect = list()

	if(!powernet) //if we somehow have no powernet, make one (should not happen for cables)
		var/datum/powernet/newPN = new()
		newPN.add_cable(src)

	//first let's add turf cables to our powernet
	//then we'll connect machines on turf with a node cable is present
	for(var/AM in loc)
		if(istype(AM,/obj/structure/cable))
			var/obj/structure/cable/C = AM
			if(C.d1 == d1 || C.d2 == d1 || C.d1 == d2 || C.d2 == d2) //only connected if they have a common direction
				if(C.powernet == powernet)	continue
				if(C.powernet)
					merge_powernets(powernet, C.powernet)
				else
					powernet.add_cable(C) //the cable was powernetless, let's just add it to our powernet

		else if(istype(AM,/obj/machinery/power/apc))
			var/obj/machinery/power/apc/N = AM
			var/obj/machinery/power/terminal/terminal = N.terminal()
			if(!terminal)	continue // APC are connected through their terminal

			if(terminal.powernet == powernet)
				continue

			to_connect += terminal //we'll connect the machines after all cables are merged

		else if(istype(AM,/obj/machinery/power)) //other power machines
			var/obj/machinery/power/M = AM

			if(M.powernet == powernet)
				continue

			to_connect += M //we'll connect the machines after all cables are merged

	//now that cables are done, let's connect found machines
	for(var/obj/machinery/power/PM in to_connect)
		if(!PM.connect_to_network())
			PM.disconnect_from_network() //if we somehow can't connect the machine to the new powernet, remove it from the old nonetheless

//////////////////////////////////////////////
// Powernets handling helpers
//////////////////////////////////////////////

/obj/structure/cable/proc/get_cable_connections(var/skip_assigned_powernets = FALSE)
	. = list()	// this will be a list of all connected power objects
	var/turf/T

	// Handle standard cables in adjacent turfs
	for(var/cable_dir in list(d1, d2))
		if(cable_dir == 0)
			continue
		var/reverse = global.reverse_dir[cable_dir]
		T = get_zstep_resolving_mimic(src, cable_dir)
		if(T)
			for(var/obj/structure/cable/C in T)
				if(C.d1 == reverse || C.d2 == reverse)
					. += C
		if(cable_dir & (cable_dir - 1)) // Diagonal, check for /\/\/\ style cables along cardinal directions
			for(var/pair in list(NORTH|SOUTH, EAST|WEST))
				T = get_step_resolving_mimic(src, cable_dir & pair)
				if(T)
					var/req_dir = cable_dir ^ pair
					for(var/obj/structure/cable/C in T)
						if(C.d1 == req_dir || C.d2 == req_dir)
							. += C

	// Handle cables on the same turf as us
	for(var/obj/structure/cable/C in loc)
		if(C.d1 == d1 || C.d2 == d1 || C.d1 == d2 || C.d2 == d2) // if either of C's d1 and d2 match either of ours
			. += C

	// if asked, skip any cables with powernts
	if(skip_assigned_powernets)
		for(var/obj/structure/cable/C in .)
			if(C.powernet)
				. -= C

/obj/structure/cable/proc/get_machine_connections(var/skip_assigned_powernets = FALSE)
	. = list()	// this will be a list of all connected power objects
	if(d1 == 0)
		for(var/obj/machinery/power/P in loc)
			if(P.powernet == 0) continue // exclude APCs with powernet=0
			if(!skip_assigned_powernets || !P.powernet)
				. += P

/obj/structure/cable/proc/get_connections(var/skip_assigned_powernets = FALSE)
	return get_cable_connections(skip_assigned_powernets) + get_machine_connections(skip_assigned_powernets)

//should be called after placing a cable which extends another cable, creating a "smooth" cable that no longer terminates in the centre of a turf.
//needed as this can, unlike other placements, disconnect cables
/obj/structure/cable/proc/denode()
	var/turf/T1 = loc
	if(!T1) return

	var/list/powerlist = power_list(T1,src,0,0) //find the other cables that ended in the centre of the turf, with or without a powernet
	if(powerlist.len>0)
		var/datum/powernet/PN = new()
		propagate_network(powerlist[1],PN) //propagates the new powernet beginning at the source cable

		if(PN.is_empty()) //can happen with machines made nodeless when smoothing cables
			qdel(PN)

// cut the cable's powernet at this cable and updates the powergrid
/obj/structure/cable/proc/cut_cable_from_powernet()
	var/turf/T1 = loc
	var/list/P_list
	if(!T1)	return
	if(d1)
		T1 = get_zstep_resolving_mimic(T1, d1)
		P_list = power_list(T1, src, turn(d1,180),0,cable_only = 1)	// what adjacently joins on to cut cable...

	P_list += power_list(loc, src, d1, 0, cable_only = 1)//... and on turf


	if(P_list.len == 0)//if nothing in both list, then the cable was a lone cable, just delete it and its powernet
		powernet.remove_cable(src)

		for(var/obj/machinery/power/P in T1)//check if it was powering a machine
			if(!P.connect_to_network()) //can't find a node cable on a the turf to connect to
				P.disconnect_from_network() //remove from current network (and delete powernet)
		return

	// remove the cut cable from its turf and powernet, so that it doesn't get count in propagate_network worklist
	forceMove(null)
	powernet.remove_cable(src) //remove the cut cable from its powernet

	var/datum/powernet/newPN = new()// creates a new powernet...
	propagate_network(P_list[1], newPN)//... and propagates it to the other side of the cable

	// Disconnect machines connected to nodes
	if(d1 == 0) // if we cut a node (O-X) cable
		for(var/obj/machinery/power/P in T1)
			if(!P.connect_to_network()) //can't find a node cable on a the turf to connect to
				P.disconnect_from_network() //remove from current network

	powernet = null // And finally null the powernet var.

///////////////////////////////////////////////
// The cable coil object, used for laying cable
///////////////////////////////////////////////

////////////////////////////////
// Definitions
////////////////////////////////

#define MAXCOIL 30

/obj/item/stack/cable_coil
	name = "multipurpose cable coil"
	icon = 'icons/obj/items/cable_coil.dmi'
	icon_state = ICON_STATE_WORLD
	randpixel = 2
	amount = MAXCOIL
	max_amount = MAXCOIL
	color = COLOR_MAROON
	paint_color = COLOR_MAROON
	desc = "A coil of wiring, suitable for both delicate electronics and heavy duty power supply."
	singular_name = "length"
	w_class = ITEM_SIZE_NORMAL
	throw_speed = 2
	throw_range = 5
	material = /decl/material/solid/metal/copper
	matter = list(
		/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/organic/plastic = MATTER_AMOUNT_TRACE
	)
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_LOWER_BODY
	item_state = "coil"
	attack_verb = list("whipped", "lashed", "disciplined", "flogged")
	stack_merge_type = /obj/item/stack/cable_coil
	matter_multiplier = 0.15
	/// Whether or not this cable coil can even have a color in the first place.
	var/can_have_color = TRUE
	/// The type of cable structure produced when laying down this cable.
	/// src.cable_type::cable_type should equal stack_merge_type, ideally
	var/cable_type = /obj/structure/cable

/obj/item/stack/cable_coil/single
	amount = 1

/obj/item/stack/cable_coil/cyborg
	name = "cable coil synthesizer"
	desc = "A device that makes cable."
	gender = NEUTER
	matter = null
	uses_charge = 1
	charge_costs = list(1)
	max_health = ITEM_HEALTH_NO_DAMAGE
	is_spawnable_type = FALSE

/obj/item/stack/cable_coil/Initialize(mapload, c_length, var/param_color = null)
	. = ..(mapload, c_length)
	set_extension(src, /datum/extension/tool/variable/simple, list(
		TOOL_CABLECOIL = TOOL_QUALITY_DEFAULT,
		TOOL_SUTURES =   TOOL_QUALITY_MEDIOCRE
	))
	if (can_have_color && param_color) // It should be red by default, so only recolor it if parameter was specified.
		set_color(param_color)
	update_icon()
	update_wclass()

///////////////////////////////////
// General procedures
///////////////////////////////////

//you can use wires to heal robotics
/obj/item/stack/cable_coil/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	var/obj/item/organ/external/affecting = istype(target) && GET_EXTERNAL_ORGAN(target, user?.get_target_zone())
	if(affecting && user.a_intent == I_HELP)
		if(!affecting.is_robotic())
			to_chat(user, SPAN_WARNING("\The [target]'s [affecting.name] is not robotic. \The [src] cannot repair it."))
		else if(BP_IS_BRITTLE(affecting))
			to_chat(user, SPAN_WARNING("\The [target]'s [affecting.name] is hard and brittle. \The [src] cannot repair it."))
		else
			var/use_amt = min(src.amount, ceil(affecting.burn_dam/3), 5)
			if(can_use(use_amt) && affecting.robo_repair(3*use_amt, BURN, "some damaged wiring", src, user))
				use(use_amt)
		return TRUE
	return ..()

/obj/item/stack/cable_coil/on_update_icon()
	. = ..()
	if (!paint_color && can_have_color)
		var/list/possible_cable_colours = get_global_cable_colors()
		set_color(possible_cable_colours[pick(possible_cable_colours)])
	if(amount == 1)
		icon_state = "coil1"
		SetName("cable piece")
	else if(amount == 2)
		icon_state = "coil2"
		SetName("cable piece")
	else if(amount > 2 && amount != max_amount)
		icon_state = "coil"
		SetName(initial(name))
	else
		icon_state = "coil-max"
		SetName(initial(name))

/obj/item/stack/cable_coil/proc/set_cable_color(var/selected_color, var/user)
	if(!selected_color || !can_have_color)
		return

	var/list/possible_cable_colours = get_global_cable_colors()
	var/final_color = possible_cable_colours[selected_color]
	if(!final_color)
		selected_color = "Red"
		final_color = possible_cable_colours[selected_color]
	set_color(final_color)
	to_chat(user, SPAN_NOTICE("You change \the [src]'s color to [lowertext(selected_color)]."))

/obj/item/stack/cable_coil/proc/update_wclass()
	if(amount == 1)
		w_class = ITEM_SIZE_TINY
	else
		w_class = ITEM_SIZE_SMALL

/obj/item/stack/cable_coil/examine(mob/user, distance)
	. = ..()
	if(distance > 1)
		return

	if(get_amount() == 1)
		to_chat(user, "\A [singular_name] of cable.")
	else if(get_amount() == 2)
		to_chat(user, "Two [plural_name] of cable.")
	else
		to_chat(user, "A coil of power cable. There are [get_amount()] [plural_name] of cable in the coil.")


/obj/item/stack/cable_coil/verb/make_restraint()
	set name = "Make Cable Restraints"
	set category = "Object"
	var/mob/M = usr

	if(ishuman(M) && !M.incapacitated())
		if(!isturf(usr.loc)) return
		if(!src.use(15))
			to_chat(usr, SPAN_WARNING("You need at least 15 [plural_name] of cable to make restraints!"))
			return
		var/obj/item/handcuffs/cable/B = new /obj/item/handcuffs/cable(usr.loc)
		B.set_color(color)
		to_chat(usr, SPAN_NOTICE("You wind some [plural_name] of cable together to make some restraints."))
	else
		to_chat(usr, SPAN_NOTICE("You cannot do that."))

/obj/item/stack/cable_coil/cyborg/verb/set_colour()
	set name = "Change Colour"
	set category = "Object"

	var/selected_type = input("Pick new colour.", "Cable Colour", null, null) as null|anything in get_global_cable_colors()
	set_cable_color(selected_type, usr)

// Items usable on a cable coil :
//   - Wirecutters : cut them duh !
//   - Cable coil : merge cables
/obj/item/stack/cable_coil/can_merge_stacks(var/obj/item/stack/other)
	return !other || (istype(other) && other.color == color)

/obj/item/stack/cable_coil/cyborg/can_merge_stacks(var/obj/item/stack/other)
	return TRUE

/obj/item/stack/cable_coil/transfer_to(obj/item/stack/cable_coil/coil)
	if(!istype(coil))
		return 0
	if(!(can_merge_stacks(coil) || coil.can_merge_stacks(src)))
		return 0

	return ..()

///////////////////////////////////////////////
// Cable laying procedures
//////////////////////////////////////////////

// called when cable_coil is clicked on a turf
/obj/item/stack/cable_coil/proc/turf_place(turf/F, mob/user)
	if(!isturf(user.loc))
		return

	if(get_amount() < 1) // Out of cable
		to_chat(user, SPAN_WARNING("There is no [plural_name] of cable left."))
		return

	if(get_dist(F,user) > 1) // Too far
		to_chat(user, SPAN_WARNING("You can't lay cable at a place that far away."))
		return

	if(!F.is_plating())		// Ff floor is intact, complain
		to_chat(user, SPAN_WARNING("You can't lay cable there unless the floor tiles are removed."))
		return

	var/dirn
	if(user.loc == F)
		dirn = user.dir			// if laying on the tile we're on, lay in the direction we're facing
	else
		dirn = get_dir(F, user)

	var/end_dir = 0
	if(istype(F) && F.is_open())
		if(!can_use(2))
			to_chat(user, SPAN_WARNING("You don't have enough [plural_name] of cable to do this!"))
			return
		end_dir = DOWN

	for(var/obj/structure/cable/LC in F)
		if((LC.d1 == dirn && LC.d2 == end_dir ) || ( LC.d2 == dirn && LC.d1 == end_dir))
			to_chat(user, SPAN_WARNING("There's already a cable at that position."))
			return

	put_cable(F, user, end_dir, dirn)
	if(end_dir == DOWN)
		put_cable(GetBelow(F), user, UP, 0)
	return TRUE

// called when cable_coil is click on an installed obj/cable
// or click on a turf that already contains a "node" cable
/obj/item/stack/cable_coil/proc/cable_join(obj/structure/cable/C, mob/user)
	var/turf/U = user.loc
	if(!isturf(U))
		return

	var/turf/T = C.loc

	if(!isturf(T) || !T.is_plating())		// sanity checks, also stop use interacting with T-scanner revealed cable
		return

	if(get_dist(C, user) > 1)		// make sure it's close enough
		to_chat(user, SPAN_WARNING("You can't lay cable at a place that far away."))
		return

	if(U == T) //if clicked on the turf we're standing on, try to put a cable in the direction we're facing
		return turf_place(T,user)

	var/dirn = get_dir(C, user)

	// one end of the clicked cable is pointing towards us
	if(C.d1 == dirn || C.d2 == dirn)
		if(!U.is_plating())						// can't place a cable if the floor is complete
			to_chat(user, SPAN_WARNING("You can't lay cable there unless the floor tiles are removed."))
			return
		else
			// cable is pointing at us, we're standing on an open tile
			// so create a stub pointing at the clicked cable on our tile

			var/fdirn = turn(dirn, 180)		// the opposite direction

			for(var/obj/structure/cable/LC in U)		// check to make sure there's not a cable there already
				if(LC.d1 == fdirn || LC.d2 == fdirn)
					to_chat(user, SPAN_WARNING("There's already a cable at that position."))
					return
			put_cable(U,user,0,fdirn)
			return TRUE

	// exisiting cable doesn't point at our position, so see if it's a stub
	else if(C.d1 == 0)
							// if so, make it a full cable pointing from it's old direction to our dirn
		var/nd1 = C.d2	// these will be the new directions
		var/nd2 = dirn


		if(nd1 > nd2)		// swap directions to match icons/states
			nd1 = dirn
			nd2 = C.d2


		for(var/obj/structure/cable/LC in T)		// check to make sure there's no matching cable
			if(LC == C)			// skip the cable we're interacting with
				continue
			if((LC.d1 == nd1 && LC.d2 == nd2) || (LC.d1 == nd2 && LC.d2 == nd1) )	// make sure no cable matches either direction
				to_chat(user, SPAN_WARNING("There's already a cable at that position."))
				return


		C.cableColor(color)

		C.d1 = nd1
		C.d2 = nd2

		C.add_fingerprint()
		C.update_icon()


		C.mergeConnectedNetworks(C.d1) //merge the powernets...
		C.mergeConnectedNetworks(C.d2) //...in the two new cable directions
		C.mergeConnectedNetworksOnTurf()

		if(C.d1 & (C.d1 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d1)

		if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
			C.mergeDiagonalsNetworks(C.d2)

		use(1)

		if (C.shock(user, 50))
			if (prob(50)) //fail
				new/obj/item/stack/cable_coil(C.loc, 2, C.color)
				qdel(C)
				return

		C.denode()// this call may have disconnected some cables that terminated on the centre of the turf, if so split the powernets.
		return TRUE

	else if(C.d1 == UP) //Special cases for zcables, since they behave weirdly
		. = turf_place(T, user)
		if(.)
			to_chat(user, SPAN_NOTICE("You connect the cable hanging from the ceiling."))
		return .

/obj/item/stack/cable_coil/proc/put_cable(turf/F, mob/user, d1, d2)
	if(!istype(F))
		return FALSE

	var/obj/structure/cable/C = new cable_type(F)
	C.cableColor(color)
	C.d1 = d1
	C.d2 = d2
	C.add_fingerprint(user)
	C.update_icon()

	//create a new powernet with the cable, if needed it will be merged later
	var/datum/powernet/PN = new()
	PN.add_cable(C)

	C.mergeConnectedNetworks(C.d1) //merge the powernets...
	C.mergeConnectedNetworks(C.d2) //...in the two new cable directions
	C.mergeConnectedNetworksOnTurf()

	if(C.d1 & (C.d1 - 1))// if the cable is layed diagonally, check the others 2 possible directions
		C.mergeDiagonalsNetworks(C.d1)

	if(C.d2 & (C.d2 - 1))// if the cable is layed diagonally, check the others 2 possible directions
		C.mergeDiagonalsNetworks(C.d2)

	. = use(1)
	if (C.shock(user, 50))
		if (prob(50)) //fail
			new/obj/item/stack/cable_coil(C.loc, 1, C.color)
			qdel(C)
			return FALSE

//////////////////////////////
// Misc.
/////////////////////////////

/obj/item/stack/cable_coil/cut
	item_state = "coil2"

/obj/item/stack/cable_coil/cut/Initialize()
	. = ..()
	src.amount = rand(1,2)
	update_icon()
	update_wclass()

/obj/item/stack/cable_coil/yellow
	color = COLOR_AMBER
	paint_color = COLOR_AMBER

/obj/item/stack/cable_coil/blue
	color = COLOR_CYAN_BLUE
	paint_color = COLOR_CYAN_BLUE

/obj/item/stack/cable_coil/green
	color = COLOR_GREEN
	paint_color = COLOR_GREEN

/obj/item/stack/cable_coil/pink
	color = COLOR_PURPLE
	paint_color = COLOR_PURPLE

/obj/item/stack/cable_coil/orange
	color = COLOR_ORANGE
	paint_color = COLOR_ORANGE

/obj/item/stack/cable_coil/cyan
	color = COLOR_SKY_BLUE
	paint_color = COLOR_SKY_BLUE

/obj/item/stack/cable_coil/white
	color = COLOR_SILVER
	paint_color = COLOR_SILVER

/obj/item/stack/cable_coil/lime
	color = COLOR_LIME
	paint_color = COLOR_LIME

/obj/item/stack/cable_coil/random/Initialize(mapload, c_length, param_color)
	var/list/possible_cable_colours = get_global_cable_colors()
	set_color(possible_cable_colours[pick(possible_cable_colours)])
	. = ..()

// Produces cable coil from a rig power cell.
/obj/item/stack/cable_coil/fabricator
	name = "cable fabricator"
	var/cost_per_cable = 10

/obj/item/stack/cable_coil/fabricator/split(var/tamount, var/force=FALSE)
	return

/obj/item/stack/cable_coil/fabricator/get_cell()
	if(istype(loc, /obj/item/rig_module))
		var/obj/item/rig_module/module = loc
		return module.get_cell()
	if(isrobot(loc))
		var/mob/living/silicon/robot/R = loc
		return R.get_cell()

/obj/item/stack/cable_coil/fabricator/use(var/used)
	var/obj/item/cell/cell = get_cell()
	return cell?.use(used * cost_per_cable)

/obj/item/stack/cable_coil/fabricator/get_amount()
	var/obj/item/cell/cell = get_cell()
	. = (cell ? floor(cell.charge / cost_per_cable) : 0)

/obj/item/stack/cable_coil/fabricator/get_max_amount()
	var/obj/item/cell/cell = get_cell()
	. = (cell ? floor(cell.maxcharge / cost_per_cable) : 0)

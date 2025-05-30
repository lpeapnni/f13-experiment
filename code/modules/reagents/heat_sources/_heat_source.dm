#define MINIMUM_GLOW_TEMPERATURE 323
#define MINIMUM_GLOW_VALUE       25
#define MAXIMUM_GLOW_VALUE       255
#define HEATER_MODE_HEAT         "heat"
#define HEATER_MODE_COOL         "cool"

/obj/machinery/reagent_temperature
	name = "hotplate"
	desc = "A small electric hotplate, used to heat cookware, beakers, or vials of chemicals."
	icon = 'icons/obj/machines/heat_sources.dmi'
	icon_state = "hotplate"
	atom_flags = ATOM_FLAG_CLIMBABLE
	density =    TRUE
	anchored =   TRUE
	idle_power_usage = 0
	active_power_usage = 1.2 KILOWATTS
	construct_state = /decl/machine_construction/default/panel_closed
	uncreated_component_parts = null
	stat_immune = 0

	var/image/glow_icon
	var/image/beaker_icon
	var/image/on_icon

	var/heater_mode =          HEATER_MODE_HEAT
	var/list/permitted_types = list(/obj/item/chems/glass)
	var/max_temperature =      200 CELSIUS
	var/min_temperature =      40  CELSIUS
	var/heating_power =        10 // K
	var/last_temperature
	var/target_temperature
	var/obj/item/container

/obj/machinery/reagent_temperature/cooler
	name = "chemical cooler"
	desc = "A small electric cooler, used to chill beakers and vials of chemicals."
	icon_state = "coldplate"
	heater_mode =      HEATER_MODE_COOL
	max_temperature =  30 CELSIUS
	min_temperature = -80 CELSIUS

/obj/machinery/reagent_temperature/Initialize()
	target_temperature = min_temperature
	. = ..()

/obj/machinery/reagent_temperature/Destroy()
	if(container)
		container.dropInto(loc)
		container = null
	. = ..()

/obj/machinery/reagent_temperature/RefreshParts()
	heating_power = initial(heating_power) * clamp(total_component_rating_of_type(/obj/item/stock_parts/capacitor), 0, 10)

	var/comp = 0.25 KILOWATTS * total_component_rating_of_type(/obj/item/stock_parts/micro_laser)
	if(comp)
		change_power_consumption(max(0.5 KILOWATTS, initial(active_power_usage) - comp), POWER_USE_ACTIVE)
	..()

/obj/machinery/reagent_temperature/Process()
	..()
	if(temperature != last_temperature)
		queue_icon_update()
	if(((stat & (BROKEN|NOPOWER)) || !anchored) && use_power >= POWER_USE_ACTIVE)
		update_use_power(POWER_USE_IDLE)

/obj/machinery/reagent_temperature/interface_interact(var/mob/user)
	interact(user)
	return TRUE

/obj/machinery/reagent_temperature/ProcessAtomTemperature()
	if(use_power >= POWER_USE_ACTIVE)

		var/last_temperature = temperature
		if(heater_mode == HEATER_MODE_HEAT && temperature < target_temperature)
			temperature = min(target_temperature, temperature + heating_power)
		else if(heater_mode == HEATER_MODE_COOL && temperature > target_temperature)
			temperature = max(target_temperature, temperature - heating_power)
		if(temperature != last_temperature)
			if(container)
				queue_temperature_atoms(container)
			queue_icon_update()

		// Hackery to heat pots placed onto a hotplate without also grilling/baking stuff.
		if(isturf(loc))
			for(var/obj/item/chems/cooking_vessel/pot in loc.get_contained_external_atoms())
				pot.handle_external_heating(temperature, src)

		return TRUE // Don't kill this processing loop unless we're not powered.
	. = ..()

/obj/machinery/reagent_temperature/attackby(var/obj/item/thing, var/mob/user)

	if(istype(thing, /obj/item/chems/cooking_vessel))
		if(!user.try_unequip(thing, get_turf(src)))
			return TRUE
		thing.reset_offsets(anim_time = 0)
		user.visible_message(SPAN_NOTICE("\The [user] places \the [thing] onto \the [src]."))
		return TRUE

	if(IS_WRENCH(thing))
		if(use_power == POWER_USE_ACTIVE)
			to_chat(user, SPAN_WARNING("Turn \the [src] off first!"))
		else
			anchored = !anchored
			visible_message(SPAN_NOTICE("\The [user] [anchored ? "secured" : "unsecured"] \the [src]."))
			playsound(src.loc, 'sound/items/Ratchet.ogg', 75, 1)
		return TRUE

	if(thing.reagents)
		for(var/checktype in permitted_types)
			if(istype(thing, checktype))
				if(container)
					to_chat(user, SPAN_WARNING("\The [src] is already holding \the [container]."))
				else if(user.try_unequip(thing))
					thing.forceMove(src)
					container = thing
					visible_message(SPAN_NOTICE("\The [user] places \the [container] on \the [src]."))
					update_icon()
				return TRUE
		to_chat(user, SPAN_WARNING("\The [src] cannot accept \the [thing]."))
		return FALSE

	. = ..()

/obj/machinery/reagent_temperature/on_update_icon()

	var/list/adding_overlays

	if(use_power >= POWER_USE_ACTIVE)
		if(!on_icon)
			on_icon = image(icon, "[icon_state]-on")
		LAZYADD(adding_overlays, on_icon)
		if(temperature > MINIMUM_GLOW_TEMPERATURE) // 50C
			if(!glow_icon)
				glow_icon = image(icon, "[icon_state]-glow")
			glow_icon.alpha = clamp(temperature - MINIMUM_GLOW_TEMPERATURE, MINIMUM_GLOW_VALUE, MAXIMUM_GLOW_VALUE)
			LAZYADD(adding_overlays, glow_icon)
			set_light(1, l_color = COLOR_RED)
		else
			set_light(0)
	else
		set_light(0)

	if(container)
		if(!beaker_icon)
			beaker_icon = image(icon, "[icon_state]-beaker")
		LAZYADD(adding_overlays, beaker_icon)

	overlays = adding_overlays

/obj/machinery/reagent_temperature/interact(var/mob/user)

	var/dat = list()
	dat += "<table>"
	dat += "<tr><td>Target temperature:</td><td>"

	if(target_temperature > min_temperature)
		dat += "<a href='byond://?src=\ref[src];adjust_temperature=-[heating_power]'>-</a> "

	dat += "[target_temperature - T0C]C"

	if(target_temperature < max_temperature)
		dat += " <a href='byond://?src=\ref[src];adjust_temperature=[heating_power]'>+</a>"

	dat += "</td></tr>"

	dat += "<tr><td>Current temperature:</td><td>[floor(temperature - T0C)]C</td></tr>"

	dat += "<tr><td>Loaded container:</td>"
	dat += "<td>[container ? "[container.name] ([floor(container.temperature - T0C)]C) <a href='byond://?src=\ref[src];remove_container=1'>Remove</a>" : "None."]</td></tr>"

	dat += "<tr><td>Switched:</td><td><a href='byond://?src=\ref[src];toggle_power=1'>[use_power == POWER_USE_ACTIVE ? "On" : "Off"]</a></td></tr>"
	dat += "</table>"

	var/datum/browser/popup = new(user, "\ref[src]-reagent_temperature_window", "[capitalize(name)]")
	popup.set_content(jointext(dat, null))
	popup.open()

/obj/machinery/reagent_temperature/CanUseTopic(var/mob/user, var/state, var/href_list)
	if(href_list && href_list["remove_container"])
		. = ..(user, global.physical_topic_state, href_list)
		if(. == STATUS_CLOSE)
			to_chat(user, SPAN_WARNING("You are too far away."))
		return
	return ..()

/obj/machinery/reagent_temperature/proc/ToggleUsePower()

	if(stat & (BROKEN|NOPOWER))
		return TOPIC_HANDLED

	update_use_power(use_power <= POWER_USE_IDLE ? POWER_USE_ACTIVE : POWER_USE_IDLE)
	queue_temperature_atoms(src)
	update_icon()

	return TOPIC_REFRESH

/obj/machinery/reagent_temperature/OnTopic(var/mob/user, var/href_list)

	if(href_list["adjust_temperature"])
		target_temperature = clamp(target_temperature + text2num(href_list["adjust_temperature"]), min_temperature, max_temperature)
		. = TOPIC_REFRESH

	if(href_list["toggle_power"])
		. = ToggleUsePower()
		if(. != TOPIC_REFRESH)
			to_chat(user, SPAN_WARNING("The button clicks, but nothing happens."))

	if(href_list["remove_container"])
		if(container)
			container.dropInto(loc)
			user.put_in_hands(container)
			container = null
			update_icon()
		. = TOPIC_REFRESH

	if(. == TOPIC_REFRESH)
		interact(user)

#undef MINIMUM_GLOW_TEMPERATURE
#undef MINIMUM_GLOW_VALUE
#undef MAXIMUM_GLOW_VALUE
#undef HEATER_MODE_HEAT
#undef HEATER_MODE_COOL
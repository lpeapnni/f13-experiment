/obj/item/gun/magnetic
	name = "improvised coilgun"
	desc = "A coilgun hastily thrown together out of a basic frame and advanced power storage components. Is it safe for it to be duct-taped together like that?"
	icon = 'icons/obj/guns/coilgun.dmi'
	icon_state = ICON_STATE_WORLD
	one_hand_penalty = 5
	fire_delay = 20
	origin_tech = @'{"combat":5,"materials":4,"esoteric":2,"magnets":4}'
	w_class = ITEM_SIZE_LARGE
	bulk = GUN_BULK_RIFLE
	combustion = 1

	var/obj/item/stock_parts/capacitor/capacitor               // Installed capacitor. Higher rating == faster charge between shots.
	var/removable_components = TRUE                            // Whether or not the gun can be dismantled.
	var/gun_unreliable = 15                                    // Percentage chance of detonating in your hands.

	var/obj/item/loaded                                        // Currently loaded object, for retrieval/unloading.
	var/load_type = /obj/item/stack/material/rods              // Type of stack to load with.
	var/load_sheet_max = 1                                     // Maximum number of "sheets" you can load from a stack.
	var/projectile_type = /obj/item/projectile/bullet/magnetic // Actual fire type, since this isn't throw_at rod launcher.

	var/power_cost = 950                                       // Cost per fire, should consume almost an entire basic cell.
	var/power_per_tick                                         // Capacitor charge per process(). Updated based on capacitor rating.

/obj/item/gun/magnetic/setup_power_supply(loaded_cell_type, accepted_cell_type, power_supply_extension_type, charge_value)
	return ..(loaded_cell_type, /obj/item/cell, (removable_components ? /datum/extension/loaded_cell : /datum/extension/loaded_cell/unremovable), charge_value)

/obj/item/gun/magnetic/preloaded
	capacitor = /obj/item/stock_parts/capacitor/adv

/obj/item/gun/magnetic/preloaded/setup_power_supply(loaded_cell_type, accepted_cell_type, power_supply_extension_type, charge_value)
	return ..(/obj/item/cell/high, accepted_cell_type, power_supply_extension_type, charge_value)

/obj/item/gun/magnetic/Initialize()
	START_PROCESSING(SSobj, src)
	setup_power_supply()
	if (ispath(capacitor))
		capacitor = new capacitor()
		capacitor.charge = capacitor.max_charge
	if (ispath(loaded))
		loaded = new loaded(src, load_sheet_max)

	if(capacitor)
		power_per_tick = (power_cost*0.15) * capacitor.rating
	update_icon()
	. = ..()

/obj/item/gun/magnetic/Destroy()
	STOP_PROCESSING(SSobj, src)
	QDEL_NULL(loaded)
	QDEL_NULL(capacitor)
	. = ..()

/obj/item/gun/magnetic/Process()
	if(capacitor)
		var/obj/item/cell/cell = get_cell()
		if(cell)
			if(capacitor.charge < capacitor.max_charge && cell.checked_use(power_per_tick))
				capacitor.charge(power_per_tick)
		else
			if(capacitor)
				capacitor.use(capacitor.charge * 0.05)
	update_icon()

/obj/item/gun/magnetic/on_update_icon()
	. = ..()
	var/obj/item/cell/cell = get_cell()
	if(removable_components)
		if(cell)
			add_overlay("[icon_state]_cell")
		if(capacitor)
			add_overlay("[icon_state]_capacitor")
	if(!cell || !capacitor)
		add_overlay("[icon_state]_red")
	else if(capacitor.charge < power_cost)
		add_overlay("[icon_state]_amber")
	else
		add_overlay("[icon_state]_green")
	if(loaded)
		add_overlay("[icon_state]_loaded")
		var/obj/item/magnetic_ammo/mag = loaded
		if(istype(mag))
			if(mag.remaining)
				add_overlay("[icon_state]_ammo")

/obj/item/gun/magnetic/proc/show_ammo(var/mob/user)
	if(loaded)
		to_chat(user, "<span class='notice'>It has \a [loaded] loaded.</span>")

/obj/item/gun/magnetic/examine(mob/user)
	. = ..()
	if(!get_cell() || !capacitor)
		to_chat(user, "<span class='notice'>The capacitor charge indicator is blinking [SPAN_RED("red")]. Maybe you should check the cell or capacitor.</span>")
	else
		to_chat(user, "<span class='notice'>The installed [capacitor.name] has a charge level of [round((capacitor.charge/capacitor.max_charge)*100)]%.</span>")
		if(capacitor.charge < power_cost)
			to_chat(user, "<span class='notice'>The capacitor charge indicator is [SPAN_ORANGE("amber")].</span>")
		else
			to_chat(user, "<span class='notice'>The capacitor charge indicator is [SPAN_GREEN("green")].</span>")

/obj/item/gun/magnetic/attackby(var/obj/item/thing, var/mob/user)

	if(removable_components)
		if(IS_SCREWDRIVER(thing))
			if(!capacitor)
				to_chat(user, "<span class='warning'>\The [src] has no capacitor installed.</span>")
				return TRUE
			user.put_in_hands(capacitor)
			user.visible_message("<span class='notice'>\The [user] unscrews \the [capacitor] from \the [src].</span>")
			playsound(loc, 'sound/items/Screwdriver.ogg', 50, 1)
			capacitor = null
			update_icon()
			return TRUE
		if(istype(thing, /obj/item/stock_parts/capacitor))
			if(capacitor)
				to_chat(user, "<span class='warning'>\The [src] already has \a [capacitor] installed.</span>")
				return TRUE
			if(!user.try_unequip(thing, src))
				return TRUE
			capacitor = thing
			playsound(loc, 'sound/machines/click.ogg', 10, 1)
			power_per_tick = (power_cost*0.15) * capacitor.rating
			user.visible_message("<span class='notice'>\The [user] slots \the [capacitor] into \the [src].</span>")
			update_icon()
			return TRUE

	if(!istype(thing, load_type))
		return ..()

	// This is not strictly necessary for the magnetic gun but something using
	// specific ammo types may exist down the track.
	var/obj/item/stack/ammo = thing
	if(!istype(ammo))
		if(loaded)
			to_chat(user, "<span class='warning'>\The [src] already has \a [loaded] loaded.</span>")
			return TRUE
		var/obj/item/magnetic_ammo/mag = thing
		if(istype(mag))
			if(!(load_type == mag.basetype))
				to_chat(user, "<span class='warning'>\The [src] doesn't seem to accept \a [mag].</span>")
				return TRUE
			projectile_type = mag.projectile_type
		if(!user.try_unequip(thing, src))
			return TRUE

		loaded = thing
	else if(load_sheet_max > 1)
		var ammo_count = 0
		var/obj/item/stack/loaded_ammo = loaded
		if(!istype(loaded_ammo))
			ammo_count = min(load_sheet_max,ammo.amount)
			loaded = new load_type(src, ammo_count)
		else
			ammo_count = min(load_sheet_max-loaded_ammo.amount,ammo.amount)
			loaded_ammo.amount += ammo_count
		if(ammo_count <= 0)
			// This will also display when someone tries to insert a stack of 0, but that shouldn't ever happen anyway.
			to_chat(user, "<span class='warning'>\The [src] is already fully loaded.</span>")
			return TRUE
		ammo.use(ammo_count)
	else
		if(loaded)
			to_chat(user, "<span class='warning'>\The [src] already has \a [loaded] loaded.</span>")
			return TRUE
		loaded = new load_type(src, 1)
		ammo.use(1)

	user.visible_message("<span class='notice'>\The [user] loads \the [src] with \the [loaded].</span>")
	playsound(loc, 'sound/weapons/flipblade.ogg', 50, 1)
	update_icon()
	return TRUE

/obj/item/gun/magnetic/attack_hand(var/mob/user)
	if(!user.is_holding_offhand(src) || !user.check_dexterity(DEXTERITY_HOLD_ITEM, TRUE))
		return ..()
	var/obj/item/removing
	if(loaded)
		removing = loaded
		loaded = null
	else if(removable_components && get_cell())
		return ..()
	if(removing)
		user.put_in_hands(removing)
		user.visible_message(SPAN_NOTICE("\The [user] removes \the [removing] from \the [src]."))
		playsound(loc, 'sound/machines/click.ogg', 10, 1)
		update_icon()
	return TRUE

/obj/item/gun/magnetic/proc/check_ammo()
	return loaded

/obj/item/gun/magnetic/proc/use_ammo()
	qdel(loaded)
	loaded = null

/obj/item/gun/magnetic/consume_next_projectile()

	if(!check_ammo() || !capacitor || capacitor.charge < power_cost)
		return

	use_ammo()
	capacitor.use(power_cost)
	update_icon()

	if(gun_unreliable && prob(gun_unreliable))
		spawn(3) // So that it will still fire - considered modifying Fire() to return a value but burst fire makes that annoying.
			visible_message("<span class='danger'>\The [src] explodes with the force of the shot!</span>")
			explosion(get_turf(src), -1, 0, 2)
			qdel(src)

	return new projectile_type(src)

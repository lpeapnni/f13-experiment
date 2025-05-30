//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/obj/machinery/recharger
	name = "recharger"
	desc = "An all-purpose recharger for a variety of devices."
	icon = 'icons/obj/machines/recharger.dmi'
	icon_state = "recharger0"
	anchored = TRUE
	idle_power_usage = 4
	active_power_usage = 30 KILOWATTS
	var/obj/item/charging = null
	var/list/allowed_devices = list(/obj/item/gun/energy, /obj/item/gun/magnetic/railgun, /obj/item/baton, /obj/item/cell, /obj/item/modular_computer/, /obj/item/suit_sensor_jammer, /obj/item/stock_parts/computer/battery_module, /obj/item/shield_diffuser, /obj/item/clothing/mask/smokable/ecig, /obj/item/radio)
	var/icon_state_charged = "recharger2"
	var/icon_state_charging = "recharger1"
	var/icon_state_idle = "recharger0" //also when unpowered
	var/portable = 1

	uncreated_component_parts = null
	construct_state = /decl/machine_construction/default/panel_closed

/obj/machinery/recharger/Destroy()
	charging = null
	. = ..()

/obj/machinery/recharger/attackby(obj/item/G, mob/user)
	var/allowed = 0
	for (var/allowed_type in allowed_devices)
		if (istype(G, allowed_type)) allowed = 1

	if(allowed)
		. = TRUE
		if(charging)
			to_chat(user, "<span class='warning'>\A [charging] is already charging here.</span>")
			return
		// Checks to make sure the recharger is powered.
		if(stat & NOPOWER)
			to_chat(user, "<span class='warning'>\The [src] blinks red as you try to insert \the [G]!</span>")
			return
		if (istype(G, /obj/item/gun/energy/))
			var/obj/item/gun/energy/E = G
			if(E.self_recharge)
				to_chat(user, "<span class='notice'>You can't find a charging port on \the [E].</span>")
				return
		if(!G.get_cell())
			to_chat(user, "This device does not have a battery installed.")
			return

		if(user.try_unequip(G))
			G.forceMove(src)
			charging = G
			update_icon()
		return

	if(portable && IS_WRENCH(G) && !panel_open)
		. = TRUE
		if(charging)
			to_chat(user, "<span class='warning'>Remove [charging] first!</span>")
			return
		anchored = !anchored
		to_chat(user, "You [anchored ? "attached" : "detached"] the recharger.")
		playsound(loc, 'sound/items/Ratchet.ogg', 75, 1)
		return

	return ..()

/obj/machinery/recharger/physical_attack_hand(mob/user)
	if(charging)
		charging.update_icon()
		user.put_in_hands(charging)
		charging = null
		update_icon()
		return TRUE
	return FALSE

/obj/machinery/recharger/Process()
	if(stat & (NOPOWER|BROKEN) || !anchored)
		update_use_power(POWER_USE_OFF)
		icon_state = icon_state_idle
		return

	if(!charging)
		update_use_power(POWER_USE_IDLE)
		icon_state = icon_state_idle
	else
		var/obj/item/cell/C = charging.get_cell()
		if(istype(C))
			if(!C.fully_charged())
				icon_state = icon_state_charging
				C.give(active_power_usage*CELLRATE)
				update_use_power(POWER_USE_ACTIVE)
			else
				icon_state = icon_state_charged
				update_use_power(POWER_USE_IDLE)

/obj/machinery/recharger/emp_act(severity)
	if(stat & (NOPOWER|BROKEN) || !anchored)
		..(severity)
		return
	if(charging)
		var/obj/item/cell/C = charging.get_cell()
		if(istype(C))
			C.emp_act(severity)
	..(severity)

/obj/machinery/recharger/on_update_icon()	//we have an update_icon() in addition to the stuff in process to make it feel a tiny bit snappier.
	if(charging)
		icon_state = icon_state_charging
	else
		icon_state = icon_state_idle

/obj/machinery/recharger/examine(mob/user)
	. = ..()
	if(isnull(charging))
		return

	var/obj/item/cell/C = charging.get_cell()
	if(!isnull(C))
		to_chat(user, "Item's charge at [round(C.percent())]%.")

/obj/machinery/recharger/wallcharger
	name = "wall recharger"
	desc = "A heavy duty wall recharger specialized for energy weaponry."
	icon = 'icons/obj/machines/recharger_wall.dmi'
	icon_state = "wrecharger0"
	active_power_usage = 50 KILOWATTS	//It's more specialized than the standalone recharger (guns and batons only) so make it more powerful
	allowed_devices = list(/obj/item/gun/magnetic/railgun, /obj/item/gun/energy, /obj/item/baton)
	icon_state_charged = "wrecharger2"
	icon_state_charging = "wrecharger1"
	icon_state_idle = "wrecharger0"
	portable = 0
	obj_flags = OBJ_FLAG_MOVES_UNSUPPORTED

	construct_state = /decl/machine_construction/wall_frame/panel_closed
	frame_type = /obj/item/frame/button/wall_charger
	directional_offset = @'{"NORTH":{"y":-24}, "SOUTH":{"y":32}, "EAST":{"x":-28}, "WEST":{"x":28}}'
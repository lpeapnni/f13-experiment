//Contains the rapid construction device.

/obj/item/rcd
	name = "rapid construction device"
	desc = "Small, portable, and far, far heavier than it looks, this gun-shaped device has a port into which one may insert compressed matter cartridges."
	icon = 'icons/obj/items/device/rcd.dmi'
	icon_state = "rcd"
	opacity = FALSE
	density = FALSE
	anchored = FALSE
	obj_flags = OBJ_FLAG_CONDUCTIBLE
	slot_flags = SLOT_LOWER_BODY|SLOT_HOLSTER
	throw_speed = 1
	throw_range = 5
	w_class = ITEM_SIZE_NORMAL
	origin_tech = @'{"engineering":4,"materials":2}'
	material = /decl/material/solid/metal/steel
	_base_attack_force = 10
	var/stored_matter = 0
	var/max_stored_matter = 120
	var/work_id = 0
	var/decl/hierarchy/rcd_mode/work_mode
	var/static/list/work_modes
	var/canRwall = 0
	var/disabled = 0
	var/crafting = FALSE //Rapid Crossbow Device memes

/obj/item/rcd/Initialize()
	. = ..()

	if(!work_modes)
		var/decl/hierarchy/h = GET_DECL(/decl/hierarchy/rcd_mode)
		work_modes = h.children
	work_mode = work_modes[1]

/obj/item/rcd/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)
	return FALSE

/obj/item/rcd/proc/can_use(var/mob/user,var/turf/T)
	return (user.Adjacent(T) && user.get_active_held_item() == src && !user.incapacitated())

/obj/item/rcd/examine(mob/user)
	. = ..()
	if(src.type == /obj/item/rcd && loc == user)
		to_chat(user, "The current mode is '[work_mode]'.")
		to_chat(user, "It currently holds [stored_matter]/[max_stored_matter] matter-units.")

/obj/item/rcd/Initialize()
	. = ..()
	update_icon()	//Initializes the ammo counter

/obj/item/rcd/attackby(obj/item/W, mob/user)
	if(istype(W, /obj/item/rcd_ammo))
		var/obj/item/rcd_ammo/cartridge = W
		if((stored_matter + cartridge.remaining) > max_stored_matter)
			to_chat(user, "<span class='notice'>The RCD can't hold that many additional matter-units.</span>")
			return TRUE
		stored_matter += cartridge.remaining
		qdel(W)
		playsound(src.loc, 'sound/machines/click.ogg', 50, 1)
		to_chat(user, "<span class='notice'>The RCD now holds [stored_matter]/[max_stored_matter] matter-units.</span>")
		update_icon()
		return TRUE
	if(IS_SCREWDRIVER(W))
		crafting = !crafting
		if(!crafting)
			to_chat(user, SPAN_NOTICE("You reassemble the RCD."))
		else
			to_chat(user, "<span class='notice'>The RCD can now be modified.</span>")
		src.add_fingerprint(user)
		return TRUE
	return ..()

/obj/item/rcd/attack_self(mob/user)
	//Change the mode
	work_id++
	work_mode = next_in_list(work_mode, work_modes)
	to_chat(user, "<span class='notice'>Changed mode to '[work_mode]'</span>")
	playsound(src.loc, 'sound/effects/pop.ogg', 50, 0)
	if(prob(20))
		spark_at(src, amount = 5)

/obj/item/rcd/afterattack(atom/A, mob/user, proximity)
	if(!proximity)
		return FALSE
	if(disabled && !isrobot(user))
		return FALSE
	if(istype(get_turf(A), /turf/space/transit))
		return FALSE
	var/area/area = get_area(A)
	if(!istype(area) || (area.area_flags & AREA_FLAG_SHUTTLE))
		return FALSE
	work_id++
	work_mode.do_work(src, A, user)

/obj/item/rcd/proc/useResource(var/amount, var/mob/user)
	if(stored_matter < amount)
		return 0
	stored_matter -= amount
	queue_icon_update()	//Updates the ammo counter if ammo is succesfully used
	return 1

/obj/item/rcd/on_update_icon()	//For the fancy "ammo" counter
	. = ..()
	var/ratio = 0
	ratio = stored_matter / max_stored_matter
	ratio = max(round(ratio, 0.10) * 100, 10)
	add_overlay("rcd-[ratio]")

/obj/item/rcd/proc/lowAmmo(var/mob/user)	//Kludge to make it animate when out of ammo, but I guess you can make it blow up when it's out of ammo or something
	to_chat(user, "<span class='warning'>The \'Low Ammo\' light on the device blinks yellow.</span>")
	flick("[icon_state]-empty", src)

/obj/item/rcd_ammo
	name = "compressed matter cartridge"
	desc = "A highly-compressed matter cartridge usable in rapid construction (and deconstruction) devices, such as railguns."
	icon = 'icons/obj/ammo.dmi'
	icon_state = "rcd"
	item_state = "rcdammo"
	w_class = ITEM_SIZE_SMALL
	origin_tech = @'{"materials":2}'
	material = /decl/material/solid/metal/steel
	var/remaining = 30

// Full override due to the weirdness of compressed matter cart legacy matter units.
// TODO: make this use actual matter.
/obj/item/rcd_ammo/create_matter()
	// Formula: 3 MU per wall == 6 steel sheets == 2 sheets per MU, /2 for glass and steel, with a
	// discount for the outlay of materials (and to make the final costs less obscene). Technically
	// this means you can generate steel from nothing by building walls with an RCD and then
	// deconstructing them but until we have a unified matter/material system on /atom I think we're
	// just going to have to cop it.
	var/sheets = round((remaining * SHEET_MATERIAL_AMOUNT) * 0.75)
	matter = list(
		/decl/material/solid/metal/steel = sheets,
		/decl/material/solid/glass       = sheets
	)

/obj/item/rcd_ammo/examine(mob/user, distance)
	. = ..()
	if(distance <= 1)
		to_chat(user, "<span class='notice'>It has [remaining] unit\s of matter left.</span>")

/obj/item/rcd_ammo/large
	name = "high-capacity matter cartridge"
	desc = "Do not ingest."
	icon_state = "rcdlarge"
	remaining = 120
	origin_tech = @'{"materials":4}'

/obj/item/rcd/borg
	canRwall = 1

/obj/item/rcd/borg/useResource(var/amount, var/mob/user)
	if(isrobot(user))
		var/mob/living/silicon/robot/R = user
		if(R.cell)
			var/cost = amount*30
			if(R.cell.charge >= cost)
				R.cell.use(cost)
				return 1
	return 0

/obj/item/rcd/borg/attackby()
	return FALSE

/obj/item/rcd/borg/can_use(var/mob/user,var/turf/T)
	return (user.Adjacent(T) && !user.incapacitated())


/obj/item/rcd/mounted/useResource(var/amount, var/mob/user)
	var/cost = amount*70 //Arbitary number that hopefully gives it as many uses as a plain RCD.
	var/obj/item/cell/cell
	if(istype(loc,/obj/item/rig_module))
		var/obj/item/rig_module/module = loc
		if(module.holder && module.holder.cell)
			cell = module.holder.cell
	else if(loc) cell = loc.get_cell()
	if(cell && cell.charge >= cost)
		cell.use(cost)
		return 1
	return 0

/obj/item/rcd/mounted/attackby()
	return FALSE

/obj/item/rcd/mounted/can_use(var/mob/user,var/turf/T)
	return (user.Adjacent(T) && !user.incapacitated())


/decl/hierarchy/rcd_mode
	abstract_type = /decl/hierarchy/rcd_mode
	expected_type = /decl/hierarchy/rcd_mode
	var/cost
	var/delay
	var/handles_type
	var/work_type

/decl/hierarchy/rcd_mode/proc/do_work(var/obj/item/rcd/rcd, var/atom/target, var/user)
	for(var/child in children)
		var/decl/hierarchy/rcd_mode/rcdm = child
		if(!rcdm.can_handle_work(rcd, target))
			continue
		if(!rcd.useResource(rcdm.cost, user))
			rcd.lowAmmo(user)
			return FALSE

		playsound(get_turf(user), 'sound/machines/click.ogg', 50, 1)
		rcdm.work_message(target, user, rcd)

		if(rcdm.delay)
			var/work_id = rcd.work_id
			if(!(do_after(user, rcdm.delay, target) && work_id == rcd.work_id && rcd.can_use(user, target) && rcdm.can_handle_work(rcd, target)))
				return FALSE

		rcdm.do_handle_work(target)
		playsound(get_turf(user), 'sound/items/Deconstruct.ogg', 50, 1)
		return TRUE

	return FALSE

/decl/hierarchy/rcd_mode/proc/can_handle_work(var/obj/item/rcd/rcd, var/atom/target)
	return istype(target, handles_type)

/decl/hierarchy/rcd_mode/proc/do_handle_work(var/atom/target)
	var/result = get_work_result(target)
	if(ispath(result,/turf))
		var/turf/T = target
		T.ChangeTurf(result, keep_air = TRUE)
	else if(result)
		new result(target)
	else
		qdel(target)

/decl/hierarchy/rcd_mode/proc/get_work_result(var/atom/target)
	return work_type

/decl/hierarchy/rcd_mode/proc/work_message(var/atom/target, var/mob/user, var/rcd)
	var/message
	if(work_type)
		var/atom/work = work_type
		message = "<span class='notice'>You begin constructing \a [initial(work.name)].</span>"
	else
		message = "<span class='notice'>You begin construction.</span>"
	user.visible_message("<span class='notice'>\The [user] uses \a [rcd] to construct something.</span>", message)

/*
	Airlock construction
*/
/decl/hierarchy/rcd_mode/airlock
	name = "Airlock"

/decl/hierarchy/rcd_mode/airlock/basic
	cost = 10
	delay = 5 SECONDS
	handles_type = /turf/floor
	work_type = /obj/machinery/door/airlock

/decl/hierarchy/rcd_mode/airlock/basic/can_handle_work(var/rcd, var/turf/target)
	return ..() && !target.contains_dense_objects() && !(locate(/obj/machinery/door/airlock) in target)

/*
	Floor and Wall construction
*/
/decl/hierarchy/rcd_mode/floor_and_walls
	name = "Floor & Walls"

/decl/hierarchy/rcd_mode/floor_and_walls/base_turf
	cost = 1
	delay = 2 SECONDS
	work_type = /turf/floor/plating/airless

/decl/hierarchy/rcd_mode/floor_and_walls/base_turf/can_handle_work(var/rcd, var/turf/target)
	return istype(target) && (isspaceturf(target) || istype(target, get_base_turf_by_area(target)))

/decl/hierarchy/rcd_mode/floor_and_walls/floor_turf
	cost = 3
	delay = 2 SECONDS
	handles_type = /turf/floor
	work_type = /turf/wall

/*
	Deconstruction
*/
/decl/hierarchy/rcd_mode/deconstruction
	name = "Deconstruction"

/decl/hierarchy/rcd_mode/deconstruction/work_message(var/atom/target, var/mob/user, var/rcd)
	user.visible_message("<span class='warning'>\The [user] is using \a [rcd] to deconstruct \the [target]!</span>", "<span class='warning'>You are deconstructing \the [target]!</span>")

/decl/hierarchy/rcd_mode/deconstruction/airlock
	cost = 30
	delay = 5 SECONDS
	handles_type = /obj/machinery/door/airlock

/decl/hierarchy/rcd_mode/deconstruction/floor
	cost = 9
	delay = 2 SECONDS
	handles_type = /turf/floor

/decl/hierarchy/rcd_mode/deconstruction/floor/get_work_result(var/target)
	return get_base_turf_by_area(target)

/decl/hierarchy/rcd_mode/deconstruction/wall
	cost = 9
	delay = 2 SECONDS
	handles_type = /turf/wall
	work_type = /turf/floor/plating

/decl/hierarchy/rcd_mode/deconstruction/wall/can_handle_work(var/obj/item/rcd/rcd, var/turf/wall/target)
	return ..() && (rcd.canRwall || !target.reinf_material)

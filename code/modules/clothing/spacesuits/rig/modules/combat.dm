/*
 * Contains
 * /obj/item/rig_module/device/flash
 * /obj/item/rig_module/device/flash/advanced
 * /obj/item/rig_module/grenade_launcher (cleaner, smoke, mfoam)
 * /obj/item/rig_module/mounted
 * /obj/item/rig_module/mounted/lcannon
 * /obj/item/rig_module/mounted/egun
 * /obj/item/rig_module/mounted/taser
 * /obj/item/rig_module/mounted/plasmacutter
 * /obj/item/rig_module/mounted/energy_blade
 * /obj/item/rig_module/fabricator
 * /obj/item/rig_module/fabricator/wf_sign
 */

/obj/item/rig_module/device/flash
	name = "mounted flash"
	desc = "You are the law."
	icon_state = "flash"

	selectable = 0
	toggleable = 1
	activates_on_touch = 1
	module_cooldown = 0
	usable = 1
	active_power_cost = 100
	use_power_cost = 18000 //10 Whr

	engage_string = "Flash"
	activate_string = "Activate Flash Module"
	deactivate_string = "Deactivate Flash Module"

	interface_name = "mounted flash"
	interface_desc = "Disorientates your target by blinding them with this intense palm-mounted light."
	device = /obj/item/flash

	origin_tech = @'{"combat":2,"magnets":3,"engineering":5}'
	material = /decl/material/solid/organic/plastic
	matter = list(
		/decl/material/solid/metal/steel = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/glass = MATTER_AMOUNT_TRACE
	)

/obj/item/rig_module/device/flash/advanced
	name = "advanced mounted flash"
	device = /obj/item/flash/advanced
	origin_tech = @'{"combat":3,"magnets":3,"engineering":5}'

/obj/item/rig_module/device/flash/installed()
	. = ..()
	if(!holder?.gloves)//gives select option for gloveless suits, why even use rig at this point
		selectable = 1
		activates_on_touch = 0
		toggleable = 0
	else
		selectable = 0
		activates_on_touch = 1
		toggleable = 1

/obj/item/rig_module/device/flash/engage(atom/target)
	if(!check() || !device)
		return 0

	if(!holder.cell.check_charge(use_power_cost * CELLRATE))
		to_chat(holder.wearer,SPAN_WARNING("Not enough stored power."))
		return 0

	if(!target)
		if(device.attack_self(holder.wearer))
			holder.cell.use(use_power_cost * CELLRATE)
		return 1

	if(!target.Adjacent(holder.wearer) || !ismob(target))
		return 0

	var/resolved = target.attackby(device,holder.wearer)
	if(resolved)
		holder.cell.use(use_power_cost * CELLRATE)
	return resolved

/obj/item/rig_module/device/flash/activate()
	if(active || !check())
		return

	to_chat(holder.wearer, SPAN_NOTICE("Your hardsuit gauntlets heat up and lock into place, ready to be used."))
	playsound(src.loc, 'sound/items/goggles_charge.ogg', 20, 1)
	active = 1

/obj/item/rig_module/grenade_launcher
	name = "mounted grenade launcher"
	desc = "A forearm-mounted micro-explosive dispenser."
	selectable = 1
	icon_state = "grenadelauncher"
	use_power_cost = 2 KILOWATTS	// 2kJ per shot, a mass driver that propels the grenade?

	suit_overlay_active = "grenade"

	interface_name = "integrated grenade launcher"
	interface_desc = "Discharges loaded grenades against the wearer's location."

	var/fire_force = 30
	var/fire_distance = 10

	charges = list(
		list("flashbang",   "flashbang",   /obj/item/grenade/flashbang,  3),
		list("smoke bomb",  "smoke bomb",  /obj/item/grenade/smokebomb,  3),
		list("EMP grenade", "EMP grenade", /obj/item/grenade/empgrenade, 3),
		)

/obj/item/rig_module/grenade_launcher/accepts_item(var/obj/item/input_device, var/mob/living/user)

	if(!istype(input_device) || !istype(user))
		return 0

	var/datum/rig_charge/accepted_item
	for(var/charge in charges)
		var/datum/rig_charge/charge_datum = charges[charge]
		if(input_device.type == charge_datum.product_type)
			accepted_item = charge_datum
			break

	if(!accepted_item)
		return 0

	if(accepted_item.charges >= 5)
		to_chat(user, SPAN_DANGER("Another grenade of that type will not fit into the module."))
		return 0

	to_chat(user, SPAN_BLUE("<b>You slot \the [input_device] into the suit module.</b>"))
	qdel(input_device)
	accepted_item.charges++
	return 1

/obj/item/rig_module/grenade_launcher/engage(atom/target)

	if(!..())
		return 0

	if(!target)
		return 0

	var/mob/living/human/wearer = holder.wearer

	if(!charge_selected)
		to_chat(wearer, SPAN_DANGER("You have not selected a grenade type."))
		return 0

	var/datum/rig_charge/charge = charges[charge_selected]

	if(!charge)
		return 0

	if(charge.charges <= 0)
		to_chat(wearer, SPAN_DANGER("Insufficient grenades!"))
		return 0

	charge.charges--
	var/obj/item/grenade/new_grenade = new charge.product_type(get_turf(wearer))
	wearer.visible_message(SPAN_DANGER("[wearer] launches \a [new_grenade]!"), SPAN_DANGER("You launch \a [new_grenade]!"))
	log_and_message_admins("fired a grenade ([new_grenade.name]) from a rigsuit grenade launcher.")
	new_grenade.activate(wearer)
	new_grenade.throw_at(target,fire_force,fire_distance)

/obj/item/rig_module/grenade_launcher/cleaner
	name = "mounted cleaning grenade launcher"
	interface_name = "cleaning grenade launcher"
	desc = "A shoulder-mounted micro-explosive dispenser designed only to accept standard cleaning foam grenades."

	charges = list(
		list("cleaning grenade",   "cleaning grenade",   /obj/item/grenade/chem_grenade/cleaner,  9),
		)

/obj/item/rig_module/grenade_launcher/smoke
	name = "mounted smoke grenade launcher"
	interface_name = "smoke grenade launcher"
	desc = "A shoulder-mounted micro-explosive dispenser designed only to accept standard smoke grenades."

	charges = list(
		list("smoke bomb",   "smoke bomb",   /obj/item/grenade/smokebomb,  6),
		)

/obj/item/rig_module/grenade_launcher/mfoam
	name = "mounted foam grenade launcher"
	interface_name = "foam grenade launcher"
	desc = "A shoulder-mounted micro-explosive dispenser designed only to accept standard metal foam grenades."

	charges = list(
		list("metal foam grenade",   "metal foam grenade",   /obj/item/grenade/chem_grenade/metalfoam,  4),
		)

/obj/item/rig_module/grenade_launcher/light
	name = "mounted illumination grenade launcher"
	interface_name = "illumination grenade launcher"
	desc = "A shoulder-mounted micro-explosive dispenser designed only to accept standard illumination grenades."

	charges = list(
		list("illumination grenade",   "illumination grenade",   /obj/item/grenade/light,  6),
		)

/obj/item/rig_module/mounted

	name = "mounted gun"
	desc = "Somesort of mounted gun."
	selectable = 1
	usable = 1
	module_cooldown = 0
	icon_state = "lcannon"

	suit_overlay_active = "mounted-lascannon"

	engage_string = "Configure"

	interface_name = "mounted gun"
	interface_desc = "A shoulder-mounted cell-powered laser gun."

	var/obj/item/gun/gun

/obj/item/rig_module/mounted/Destroy()
	QDEL_NULL(gun)
	. = ..()

/obj/item/rig_module/mounted/Initialize()
	. = ..()
	if(ispath(gun))
		gun = new gun(src)
		gun.canremove = 0

/obj/item/rig_module/mounted/Destroy()
	QDEL_NULL(gun)
	. = ..()

/obj/item/rig_module/mounted/engage(atom/target)

	if(!..() || !gun)
		return 0

	if(!target)
		gun.attack_self(holder.wearer)
		return

	gun.Fire(target,holder.wearer)
	return 1

/obj/item/rig_module/mounted/lcannon

	name = "mounted laser cannon"
	desc = "A shoulder-mounted battery-powered laser cannon mount."
	usable = 0

	interface_name = "mounted laser cannon"
	interface_desc = "A shoulder-mounted cell-powered laser cannon."

	gun = /obj/item/gun/energy/lasercannon/mounted

/obj/item/rig_module/mounted/egun

	name = "mounted energy gun"
	desc = "A shoulder-mounted energy projector."
	icon_state = "egun"

	suit_overlay_active = "mounted-taser"

	interface_name = "mounted energy gun"
	interface_desc = "A shoulder-mounted suit-powered energy gun."
	origin_tech = @'{"powerstorage":6,"combat":6,"engineering":6}'
	material = /decl/material/solid/metal/steel
	matter = list(
		/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/organic/plastic = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/gold = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/silver = MATTER_AMOUNT_TRACE
	)

	gun = /obj/item/gun/energy/gun/mounted

/obj/item/rig_module/mounted/taser

	name = "mounted electrolaser"
	desc = "A shoulder-mounted nonlethal energy projector."
	icon_state = "taser"
	usable = 0

	suit_overlay_active = "mounted-taser"

	interface_name = "mounted electrolaser"
	interface_desc = "A shoulder-mounted, cell-powered electrolaser."
	origin_tech = @'{"powerstorage":5,"combat":5,"engineering":6}'
	material = /decl/material/solid/metal/steel
	matter = list(
		/decl/material/solid/organic/plastic = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/fiberglass = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/gold = MATTER_AMOUNT_TRACE
	)
	gun = /obj/item/gun/energy/taser/mounted

/obj/item/rig_module/mounted/plasmacutter

	name = "mounted plasma cutter"
	desc = "A forearm-mounted plasma cutter."
	icon_state = "plasmacutter"
	usable = 0

	suit_overlay_active = "plasmacutter"

	interface_name = "mounted plasma cutter"
	interface_desc = "A forearm-mounted suit-powered plasma cutter."
	origin_tech = @'{"materials":5,"exoticmatter":4,"engineering":7,"combat":5}'

	gun = /obj/item/gun/energy/plasmacutter/mounted
	material = /decl/material/solid/metal/steel
	matter = list(
		/decl/material/solid/fiberglass = MATTER_AMOUNT_REINFORCEMENT,
		/decl/material/solid/organic/plastic = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/gold = MATTER_AMOUNT_TRACE,
		/decl/material/solid/metal/uranium = MATTER_AMOUNT_TRACE
	)

/obj/item/rig_module/mounted/plasmacutter/engage(atom/target)

	if(!check() || !gun)
		return 0

	if(holder.wearer.a_intent == I_HURT || !target.Adjacent(holder.wearer))
		gun.Fire(target,holder.wearer)
		return 1
	else
		var/resolved = target.attackby(gun,holder.wearer)
		if(!resolved && gun && target)
			gun.afterattack(target,holder.wearer,1)
			return 1

/obj/item/rig_module/mounted/energy_blade

	name = "energy blade projector"
	desc = "A powerful cutting beam projector."
	icon_state = "eblade"

	suit_overlay_active = null

	activate_string = "Project Blade"
	deactivate_string = "Cancel Blade"

	interface_name = "energy blade"
	interface_desc = "A lethal energy projector that can shape a blade projected from the hand of the wearer."

	usable = 0
	selectable = 1
	toggleable = 1
	use_power_cost = 10 KILOWATTS
	active_power_cost = 0.5 KILOWATTS
	passive_power_cost = 0

/obj/item/rig_module/mounted/energy_blade/Process()

	if(holder && holder.wearer)
		if(!(locate(/obj/item/energy_blade/projected) in holder.wearer))
			deactivate()
			return 0

	return ..()

/obj/item/rig_module/mounted/energy_blade/activate()
	var/mob/living/M = holder?.wearer

	if(!M.get_empty_hand_slot())
		to_chat(M, SPAN_WARNING("Your hands are full."))
		deactivate()
		return

	var/obj/item/energy_blade/projected/blade = new(M)
	blade.creator = M
	M.put_in_hands(blade)

	if(!..() || !gun)
		return 0

/obj/item/rig_module/mounted/energy_blade/deactivate()
	..()
	for(var/obj/item/energy_blade/projected/blade in (holder?.wearer))
		qdel(blade)

/obj/item/rig_module/fabricator

	name = "matter fabricator"
	desc = "A self-contained microfactory system for hardsuit integration."
	selectable = TRUE
	usable = TRUE
	use_power_cost = 5 KILOWATTS
	icon_state = "enet"

	engage_string = "Fabricate Star"

	interface_name = "throwing star launcher"
	interface_desc = "An integrated microfactory that produces throwing stars from thin air and electricity."

	var/fabrication_type = /obj/item/star
	var/fire_force = 30
	var/fire_distance = 10

/obj/item/rig_module/fabricator/engage(atom/target)

	if(!..())
		return FALSE

	var/mob/living/wearer = holder.wearer

	if(target)
		var/obj/item/firing = new fabrication_type()
		firing.dropInto(loc)
		wearer.visible_message(SPAN_DANGER("\The [wearer] launches \a [firing]!"), SPAN_DANGER("You launch \a [firing]!"))
		firing.throw_at(target,fire_force,fire_distance)
	else
		if(!wearer.get_empty_hand_slot())
			to_chat(wearer, SPAN_WARNING("Your hands are full."))
		else
			var/obj/item/new_weapon = new fabrication_type()
			new_weapon.forceMove(wearer)
			to_chat(wearer, SPAN_BLUE("<b>You quickly fabricate \a [new_weapon].</b>"))
			wearer.put_in_hands(new_weapon)

	return TRUE

/obj/item/rig_module/fabricator/wf_sign
	name = "wet floor sign fabricator"
	use_power_cost = 50 KILOWATTS
	engage_string = "Fabricate Sign"

	interface_name = "work saftey launcher"
	interface_desc = "An integrated microfactory that produces wet floor signs from thin air and electricity."

	fabrication_type = /obj/item/caution

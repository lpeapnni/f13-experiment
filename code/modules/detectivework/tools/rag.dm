/obj/item/chems/glass/rag
	name = "rag"
	desc = "For cleaning up messes, you suppose."
	w_class = ITEM_SIZE_TINY
	icon = 'icons/obj/toy/toy.dmi'
	icon_state = "rag"
	amount_per_transfer_from_this = 5
	possible_transfer_amounts = @"[5]"
	volume = 10
	item_flags = ITEM_FLAG_NO_BLUDGEON
	atom_flags = ATOM_FLAG_OPEN_CONTAINER
	material = /decl/material/solid/organic/cloth
	material_alteration = MAT_FLAG_ALTERATION_NAME

	var/on_fire = 0
	var/burn_time = 20 //if the rag burns for too long it turns to ashes

/obj/item/chems/glass/rag/can_lid()
	return FALSE

/obj/item/chems/glass/rag/get_edible_material_amount(mob/eater)
	return 0

/obj/item/chems/glass/rag/get_utensil_food_type()
	return null

/obj/item/chems/glass/rag/get_atoms_can_be_placed_into()
	return null

/obj/item/chems/glass/rag/Initialize()
	. = ..()
	update_name()

/obj/item/chems/glass/rag/Destroy()
	var/obj/item/chems/drinks/bottle/bottle = loc
	if(istype(bottle) && bottle.rag == src)
		bottle.rag = null
		bottle.update_icon()
	STOP_PROCESSING(SSobj, src) //so we don't continue turning to ash while gc'd
	. = ..()

/obj/item/chems/glass/rag/attack_self(mob/user)

	if(on_fire && user.try_unequip(src))
		user.visible_message(SPAN_NOTICE("\The [user] stamps out [src]."), SPAN_NOTICE("You stamp out [src]."))
		extinguish()
		return TRUE

	if(reagents?.total_volume)
		remove_contents(user)
		return TRUE

	return ..()

/obj/item/chems/glass/rag/attackby(obj/item/W, mob/user)
	if(W.isflamesource())
		if(on_fire)
			to_chat(user, SPAN_WARNING("\The [src] is already blazing merrily!"))
			return TRUE
		ignite()
		if(on_fire)
			visible_message(SPAN_DANGER("\The [user] lights \the [src] with \the [W]."))
		else
			to_chat(user, SPAN_WARNING("You attempt to light \the [src] with \the [W], but it doesn't seem to be flammable."))
		update_name()
		return TRUE
	return ..()

/obj/item/chems/glass/rag/update_name()
	. = ..()
	if(on_fire)
		SetName("burning [name]")
	else if(reagents && reagents.total_volume)
		SetName("damp [name]")
	else
		SetName("dry [name]")

/obj/item/chems/glass/rag/on_update_icon()
	. = ..()
	icon_state = "rag[on_fire? "lit" : ""]"
	var/obj/item/chems/drinks/bottle/B = loc
	if(istype(B))
		B.update_icon()

/obj/item/chems/glass/rag/proc/remove_contents(mob/user, atom/trans_dest = null)
	if(!trans_dest && !user.loc)
		return
	if(reagents?.total_volume <= 0)
		return
	var/target_text = trans_dest? "\the [trans_dest]" : "\the [user.loc]"
	user.visible_message(
		SPAN_NOTICE("\The [user] begins to wring out [src] over [target_text]."),
		SPAN_NOTICE("You begin to wring out \the [src] over [target_text].")
	)
	if(!do_after(user, reagents.total_volume*5, progress = 0) || !reagents?.total_volume) //50 for a fully soaked rag
		return
	if(trans_dest)
		reagents.trans_to(trans_dest, reagents.total_volume)
	else
		reagents.splash(user.loc, reagents.total_volume)
	user.visible_message(
		SPAN_NOTICE("\The [user] wrings out \the [src] over [target_text]."),
		SPAN_NOTICE("You finish to wringing out \the [src].")
	)
	update_name()

/obj/item/chems/glass/rag/proc/wipe_down(atom/target, mob/user)

	if(!reagents?.total_volume)
		to_chat(user, SPAN_WARNING("The [initial(name)] is dry."))
		return

	user.visible_message(SPAN_NOTICE("\The [user] starts to wipe down \the [target] with \the [src]."))
	if(do_after(user, 3 SECONDS, target, check_holding = TRUE))
		user.visible_message(SPAN_NOTICE("\The [user] finishes wiping off \the [target]."))
		reagents.touch_atom(target)

/obj/item/chems/glass/rag/use_on_mob(mob/living/target, mob/living/user, animate = TRUE)

	if(on_fire)
		user.visible_message(
			SPAN_DANGER("\The [user] hits \the [target] with \the [src]!"),
			SPAN_DANGER("You hit \the [target] with \the [src]!")
		)
		user.do_attack_animation(target)
		admin_attack_log(user, target, "used \the [src] (ignited) to attack", "was attacked using \the [src] (ignited)", "attacked with \the [src] (ignited)")
		target.IgniteMob()
		return TRUE

	if(reagents.total_volume)
		if(user.get_target_zone() != BP_MOUTH)
			wipe_down(target, user)
			return TRUE

		if (!target.has_danger_grab(user))
			to_chat(user, SPAN_WARNING("You need to have a firm grip on \the [target] before you can use \the [src] on them!"))
			return TRUE

		user.do_attack_animation(src)
		user.visible_message(
			SPAN_DANGER("\The [user] brings \the [src] up to \the [target]'s mouth!"),
			SPAN_DANGER("You bring \the [src] up to \the [target]'s mouth!"),
			SPAN_WARNING("You hear some struggling and muffled cries of surprise.")
		)

		var/grab_time = 6 SECONDS
		if (user.skill_check(SKILL_COMBAT, SKILL_ADEPT))
			grab_time = 3 SECONDS

		if (do_after(user, grab_time, target))
			user.visible_message(
				SPAN_DANGER("\The [user] smothers \the [target] with \the [src]!"),
				SPAN_DANGER("You smother \the [target] with \the [src]!")
			)
			var/trans_amt = reagents.trans_to_mob(target, amount_per_transfer_from_this, CHEM_INHALE)
			var/contained_reagents = reagents.get_reagents()
			admin_inject_log(user, target, src, contained_reagents, trans_amt)
			update_name()
		return TRUE

	return ..()

/obj/item/chems/glass/rag/afterattack(atom/A, mob/user, proximity)
	if(!proximity)
		return

	if(istype(A, /obj/structure/reagent_dispensers))
		if(!REAGENTS_FREE_SPACE(reagents))
			to_chat(user, "<span class='warning'>\The [src] is already soaked.</span>")
			return

		if(A.reagents && A.reagents.trans_to_obj(src, reagents.maximum_volume))
			user.visible_message("<span class='notice'>\The [user] soaks [src] using [A].</span>", "<span class='notice'>You soak [src] using [A].</span>")
			update_name()
		return

	if(!on_fire && istype(A) && (src in user))
		if(ATOM_IS_OPEN_CONTAINER(A) && !isturf(A) && !(A in user))
			remove_contents(user, A)
		else if(!ismob(A)) //mobs are handled in use_on_mob() - this prevents us from wiping down people while smothering them.
			wipe_down(A, user)
		return

/obj/item/chems/glass/rag/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(exposed_temperature >= 50 + T0C)
		ignite()
	if(exposed_temperature >= 900 + T0C)
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		qdel(src)
		return
	return ..()

//rag must have a minimum of 2 units welder fuel and at least 80% of the reagents must be welder fuel.
//maybe generalize flammable reagents someday
/obj/item/chems/glass/rag/proc/can_ignite()
	var/total_fuel = 0
	var/total_volume = 0
	if(reagents)
		total_volume += reagents.total_volume
		for(var/rtype in reagents.reagent_volumes)
			var/decl/material/R = GET_DECL(rtype)
			total_fuel += REAGENT_VOLUME(reagents, rtype) * R.accelerant_value
	. = (total_fuel >= 2 && total_fuel >= total_volume*0.5)

/obj/item/chems/glass/rag/proc/ignite()
	if(on_fire)
		return
	if(!can_ignite())
		return
	START_PROCESSING(SSobj, src)
	set_light(2, 1, "#e38f46")
	on_fire = 1
	update_name()
	update_icon()

/obj/item/chems/glass/rag/proc/extinguish()
	STOP_PROCESSING(SSobj, src)
	set_light(0)
	on_fire = 0

	//rags sitting around with 1 second of burn time left is dumb.
	//ensures players always have a few seconds of burn time left when they light their rag
	if(burn_time <= 5)
		visible_message("<span class='warning'>\The [src] falls apart!</span>")
		new /obj/effect/decal/cleanable/ash(get_turf(src))
		qdel(src)
	update_name()
	update_icon()

/obj/item/chems/glass/rag/Process()
	if(!can_ignite())
		visible_message("<span class='warning'>\The [src] burns out.</span>")
		extinguish()

	//copied from matches
	if(isliving(loc))
		var/mob/living/M = loc
		M.IgniteMob()
	var/turf/location = get_turf(src)
	if(location)
		location.hotspot_expose(700, 5)

	if(burn_time <= 0)
		STOP_PROCESSING(SSobj, src)
		new /obj/effect/decal/cleanable/ash(location)
		qdel(src)
		return

	if(reagents?.total_volume)
		remove_from_reagents(/decl/material/liquid/fuel, reagents.maximum_volume/25)
	update_name()
	burn_time--

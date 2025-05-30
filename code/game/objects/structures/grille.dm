/obj/structure/grille
	name = "grille"
	desc = "A flimsy lattice of rods, with screws to secure it to the floor."
	icon = 'icons/obj/structures/grille.dmi'
	icon_state = "grille"
	density = TRUE
	anchored = TRUE
	obj_flags = OBJ_FLAG_CONDUCTIBLE | OBJ_FLAG_MOVES_UNSUPPORTED
	layer = BELOW_OBJ_LAYER
	explosion_resistance = 1
	rad_resistance_modifier = 0.1
	color = COLOR_STEEL
	material = /decl/material/solid/metal/steel
	parts_type = /obj/item/stack/material/rods
	parts_amount = 2

	handle_generic_blending = TRUE
	material_alteration = MAT_FLAG_ALTERATION_COLOR | MAT_FLAG_ALTERATION_NAME
	max_health = 20

	var/destroyed = 0
	var/list/connections
	var/list/other_connections

/obj/structure/grille/clear_connections()
	connections = null
	other_connections = null

/obj/structure/grille/get_material_health_modifier()
	. = (1/15)

/obj/structure/grille/set_connections(dirs, other_dirs)
	connections = dirs_to_corner_states(dirs)
	other_connections = dirs_to_corner_states(other_dirs)

/obj/structure/grille/update_material_desc(override_desc)
	if(material)
		desc = "A lattice of [material.solid_name] rods, with screws to secure it to the floor."
	else
		..()

/obj/structure/grille/Initialize()
	. = ..()
	if(!istype(material))
		. = INITIALIZE_HINT_QDEL
	if(. != INITIALIZE_HINT_QDEL)
		. = INITIALIZE_HINT_LATELOAD

/obj/structure/grille/LateInitialize()
	..()
	update_connections(1)
	update_icon()

/obj/structure/grille/explosion_act(severity)
	..()
	if(!QDELETED(src))
		physically_destroyed()

/obj/structure/grille/on_update_icon()
	..()
	var/on_frame = is_on_frame()
	if(destroyed)
		if(on_frame)
			icon_state = "broken_onframe"
		else
			icon_state = "broken"
	else
		var/image/I
		icon_state = ""
		if(on_frame)
			for(var/i = 1 to 4)
				var/conn = connections ? connections[i] : "0"
				if(other_connections && other_connections[i] != "0")
					I = image(icon, "grille_other_onframe[conn]", dir = BITFLAG(i-1))
				else
					I = image(icon, "grille_onframe[conn]", dir = BITFLAG(i-1))
				add_overlay(I)
		else
			for(var/i = 1 to 4)
				var/conn = connections ? connections[i] : "0"
				if(other_connections && other_connections[i] != "0")
					I = image(icon, "grille_other[conn]", dir = BITFLAG(i-1))
				else
					I = image(icon, "grille[conn]", dir = BITFLAG(i-1))
				add_overlay(I)

/obj/structure/grille/Bumped(atom/user)
	if(ismob(user))
		shock(user, 70)

/obj/structure/grille/attack_hand(mob/user)

	if(user.a_intent != I_HURT)
		return ..()

	user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
	playsound(loc, 'sound/effects/grillehit.ogg', 80, 1)
	user.do_attack_animation(src)

	if(shock(user, 70))
		return TRUE

	var/damage_dealt = 1
	var/attack_message = "kicks"
	if(ishuman(user))
		var/mob/living/human/H = user
		if(H.species.can_shred(H))
			attack_message = "mangles"
			damage_dealt = 5
	attack_generic(user,damage_dealt,attack_message)
	return TRUE

/obj/structure/grille/CanPass(atom/movable/mover, turf/target, height=0, air_group=0)
	if(air_group || (height==0)) return 1
	if(istype(mover) && mover.checkpass(PASS_FLAG_GRILLE))
		return 1
	else
		if(istype(mover, /obj/item/projectile))
			return prob(30)
		else
			return !density

/obj/structure/grille/bullet_act(var/obj/item/projectile/Proj)
	if(!Proj)	return

	//Flimsy grilles aren't so great at stopping projectiles. However they can absorb some of the impact
	var/damage = Proj.get_structure_damage()
	var/passthrough = 0

	if(!damage) return

	//20% chance that the grille provides a bit more cover than usual. Support structure for example might take up 20% of the grille's area.
	//If they click on the grille itself then we assume they are aiming at the grille itself and the extra cover behaviour is always used.
	switch(Proj.atom_damage_type)
		if(BRUTE)
			//bullets
			if(Proj.original == src || prob(20))
				Proj.damage *= clamp(Proj.damage/60, 0, 0.5)
				if(prob(max((damage-10)/25, 0))*100)
					passthrough = 1
			else
				Proj.damage *= clamp(Proj.damage/60, 0, 1)
				passthrough = 1
		if(BURN)
			//beams and other projectiles are either blocked completely by grilles or stop half the damage.
			if(!(Proj.original == src || prob(20)))
				Proj.damage *= 0.5
				passthrough = 1

	if(passthrough)
		. = PROJECTILE_CONTINUE
		damage = clamp((damage - Proj.damage)*(Proj.atom_damage_type == BRUTE? 0.4 : 1), 0, 10) //if the bullet passes through then the grille avoids most of the damage

	take_damage(damage*0.2, Proj.atom_damage_type)

/obj/structure/grille/proc/cut_grille()
	playsound(loc, 'sound/items/Wirecutter.ogg', 100, 1)
	if(destroyed)
		qdel(src)
	else
		set_density(0)
		if(material)
			var/res = material.create_object(get_turf(src), 1, parts_type)
			if(paint_color)
				for(var/obj/item/thing in res)
					thing.set_color(paint_color)
		destroyed = TRUE
		parts_amount = 1
		update_icon()

/obj/structure/grille/attackby(obj/item/W, mob/user)
	if(IS_WIRECUTTER(W))
		if(!material.conductive || !shock(user, 100))
			cut_grille()
		return TRUE

	if((IS_SCREWDRIVER(W)))
		var/turf/turf = loc
		if(((istype(turf) && turf.simulated) || anchored))
			if(!shock(user, 90))
				playsound(loc, 'sound/items/Screwdriver.ogg', 100, 1)
				anchored = !anchored
				user.visible_message(
					SPAN_NOTICE("[user] [anchored ? "fastens" : "unfastens"] the grille."),
					SPAN_NOTICE("You have [anchored ? "fastened the grille to" : "unfastened the grill from"] the floor.")
				)
				update_connections(1)
				update_icon()
			return TRUE

	//window placing
	if(istype(W,/obj/item/stack/material))
		var/obj/item/stack/material/ST = W
		if(ST.material.opacity > 0.7)
			return FALSE

		var/dir_to_set = 5
		if(!is_on_frame())
			if(loc == user.loc)
				dir_to_set = user.dir
			else
				dir_to_set = get_dir(loc, user)
				if(dir_to_set & (dir_to_set - 1)) //Only works for cardinal direcitons, diagonals aren't supposed to work like this.
					to_chat(user, "<span class='notice'>You can't reach.</span>")
					return TRUE
		place_window(user, loc, dir_to_set, ST)
		return TRUE

	if(!(W.obj_flags & OBJ_FLAG_CONDUCTIBLE) || !shock(user, 70))
		user.setClickCooldown(DEFAULT_ATTACK_COOLDOWN)
		user.do_attack_animation(src)
		playsound(loc, 'sound/effects/grillehit.ogg', 80, 1)
		switch(W.atom_damage_type)
			if(BURN)
				take_damage(W.get_attack_force(user))
			if(BRUTE)
				take_damage(W.get_attack_force(user) * 0.1)
		return TRUE

	return ..()

/obj/structure/grille/physically_destroyed(var/skip_qdel)
	SHOULD_CALL_PARENT(FALSE)
	if(!destroyed)
		visible_message(SPAN_DANGER("\The [src] falls to pieces!"))
	cut_grille()
	. = TRUE

// shock user with probability prb (if all connections & power are working)
// returns 1 if shocked, 0 otherwise
/obj/structure/grille/proc/shock(mob/user, prb)
	if(!anchored || destroyed)		// anchored/destroyed grilles are never connected
		return FALSE
	if(!(material.conductive))
		return FALSE
	if(!prob(prb))
		return FALSE
	if(!in_range(src, user))//To prevent TK and exosuit users from getting shocked
		return FALSE
	var/turf/my_turf = get_turf(src)
	var/obj/structure/cable/cable = my_turf.get_cable_node()
	if(!cable)
		return FALSE
	if(!electrocute_mob(user, cable, src))
		return FALSE
	if(cable.powernet)
		cable.powernet.trigger_warning()
	spark_at(src, cardinal_only = TRUE)
	return !!HAS_STATUS(user, STAT_STUN)

/obj/structure/grille/fire_act(datum/gas_mixture/air, exposed_temperature, exposed_volume)
	if(!destroyed)
		if(exposed_temperature > material.temperature_damage_threshold)
			take_damage(1, BURN)
	..()

// Used in mapping to avoid
/obj/structure/grille/broken
	destroyed = 1
	icon_state = "broken"
	density = FALSE

/obj/structure/grille/broken/Initialize()
	. = ..()
	take_damage(rand(1, 5)) //In the destroyed but not utterly threshold.

/obj/structure/grille/proc/is_on_frame()
	if(locate(/obj/structure/wall_frame) in loc)
		return TRUE

/proc/place_grille(mob/user, loc, obj/item/stack/material/rods/ST)
	if(ST.in_use)
		return
	if(ST.get_amount() < 2)
		to_chat(user, SPAN_WARNING("You need at least two rods to do this."))
		return
	user.visible_message(SPAN_NOTICE("\The [user] begins assembling a [ST.material.solid_name] grille."))
	if(do_after(user, 1 SECOND, ST) && ST.use(2))
		var/obj/structure/grille/F = new(loc, ST.material.type)
		user.visible_message(SPAN_NOTICE("\The [user] finishes building \a [F]."))
		F.add_fingerprint(user)

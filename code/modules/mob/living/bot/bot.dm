/mob/living/bot
	name = "Bot"
	max_health = 20
	icon = 'icons/mob/bot/placeholder.dmi'
	universal_speak = TRUE
	density = FALSE
	butchery_data = null

	var/obj/item/card/id/botcard = null
	var/list/botcard_access = list()
	var/on = 1
	var/open = 0
	var/locked = 1
	var/emagged = 0
	var/light_strength = 3
	var/busy = 0

	// Dummy object used to hold bot access strings. TODO: just put it on the mob.
	var/obj/access_scanner = null
	var/list/req_access = list()

	var/atom/target = null
	var/list/ignore_list = list()
	var/list/patrol_path = list()
	var/list/target_path = list()
	var/turf/obstacle = null

	var/wait_if_pulled = 0 // Only applies to moving to the target
	var/will_patrol = 0 // If set to 1, will patrol, duh
	var/patrol_speed = 1 // How many times per tick we move when patrolling
	var/target_speed = 2 // Ditto for chasing the target
	var/min_target_dist = 1 // How close we try to get to the target
	var/max_target_dist = 50 // How far we are willing to go
	var/max_patrol_dist = 250
	var/RequiresAccessToToggle = 0 // If 1, will check access to be turned on/off

	var/frustration = 0
	var/max_frustration = 0

	layer = HIDING_MOB_LAYER

/mob/living/bot/Initialize()
	. = ..()
	update_icon()

	botcard = new /obj/item/card/id(src)
	botcard.access = botcard_access?.Copy()

	access_scanner = new /obj(src)
	access_scanner.req_access = req_access?.Copy()

	if(on)
		turn_on() // Update lights and other stuff
	else
		turn_off()

/mob/living/bot/handle_regular_status_updates()
	. = ..()
	if(.)
		set_status(STAT_WEAK, 0)
		set_status(STAT_STUN, 0)
		set_status(STAT_PARA, 0)

/mob/living/bot/get_life_damage_types()
	var/static/list/life_damage_types = list(
		BURN,
		BRUTE
	)
	return life_damage_types

/mob/living/bot/get_dusted_remains()
	return /obj/effect/decal/cleanable/blood/oil

/mob/living/bot/gib(do_gibs = TRUE)
	if(stat != DEAD)
		death(gibbed = TRUE)
	if(stat == DEAD)
		turn_off()
		visible_message(SPAN_DANGER("\The [src] blows apart!"))
		spark_at(src, cardinal_only = TRUE)
	return ..()

/mob/living/bot/death(gibbed)
	. = ..()
	if(. && !gibbed)
		gib()

/mob/living/bot/ssd_check()
	return FALSE

/mob/living/bot/try_awaken(mob/user)
	return FALSE

/mob/living/bot/attackby(var/obj/item/O, var/mob/user)
	if(O.GetIdCard())
		if(access_scanner.allowed(user) && !open)
			locked = !locked
			to_chat(user, "<span class='notice'>Controls are now [locked ? "locked." : "unlocked."]</span>")
			Interact(usr)
		else if(open)
			to_chat(user, "<span class='warning'>Please close the access panel before locking it.</span>")
		else
			to_chat(user, "<span class='warning'>Access denied.</span>")
		return TRUE
	else if(IS_SCREWDRIVER(O))
		if(!locked)
			open = !open
			to_chat(user, "<span class='notice'>Maintenance panel is now [open ? "opened" : "closed"].</span>")
			Interact(usr)
		else
			to_chat(user, "<span class='notice'>You need to unlock the controls first.</span>")
		return TRUE
	else if(IS_WELDER(O))
		if(current_health < get_max_health())
			if(open)
				heal_overall_damage(10)
				user.visible_message("<span class='notice'>\The [user] repairs \the [src].</span>","<span class='notice'>You repair \the [src].</span>")
			else
				to_chat(user, "<span class='notice'>Unable to repair with the maintenance panel closed.</span>")
		else
			to_chat(user, "<span class='notice'>\The [src] does not need a repair.</span>")
		return TRUE
	else
		return ..()

/mob/living/bot/attack_ai(var/mob/living/user)
	Interact(user)

/mob/living/bot/default_interaction(mob/user)
	. = ..()
	if(!.)
		Interact(user)
		return TRUE

/mob/living/bot/proc/Interact(var/mob/user)
	add_fingerprint(user)
	var/dat

	var/curText = GetInteractTitle()
	if(curText)
		dat += curText
		dat += "<hr>"

	curText = GetInteractStatus()
	if(curText)
		dat += curText
		dat += "<hr>"

	curText = (CanAccessPanel(user)) ? GetInteractPanel() : "The access panel is locked."
	if(curText)
		dat += curText
		dat += "<hr>"

	curText = (CanAccessMaintenance(user)) ? GetInteractMaintenance() : "The maintenance panel is locked."
	if(curText)
		dat += curText

	var/datum/browser/popup = new(user, "botpanel", "[src] controls")
	popup.set_content(dat)
	popup.open()

/mob/living/bot/DefaultTopicState()
	return global.default_topic_state

/mob/living/bot/OnTopic(mob/user, href_list)
	if(href_list["command"])
		ProcessCommand(user, href_list["command"], href_list)
	Interact(user)

/mob/living/bot/proc/GetInteractTitle()
	return

/mob/living/bot/proc/GetInteractStatus()
	. = "Status: <A href='byond://?src=\ref[src];command=toggle'>[on ? "On" : "Off"]</A>"
	. += "<BR>Behaviour controls are [locked ? "locked" : "unlocked"]"
	. += "<BR>Maintenance panel is [open ? "opened" : "closed"]"

/mob/living/bot/proc/GetInteractPanel()
	return

/mob/living/bot/proc/GetInteractMaintenance()
	return

/mob/living/bot/proc/ProcessCommand(var/mob/user, var/command, var/href_list)
	if(command == "toggle" && CanToggle(user))
		if(on)
			turn_off()
		else
			turn_on()
	return

/mob/living/bot/proc/CanToggle(var/mob/user)
	return (!RequiresAccessToToggle || access_scanner.allowed(user) || issilicon(user))

/mob/living/bot/proc/CanAccessPanel(var/mob/user)
	return (!locked || issilicon(user))

/mob/living/bot/proc/CanAccessMaintenance(var/mob/user)
	return (open || issilicon(user))

/mob/living/bot/say(var/message)
	var/verb = "beeps"

	message = sanitize(message)

	..(message, null, verb)

/mob/living/bot/Bump(var/atom/A)
	if(on && botcard && istype(A, /obj/machinery/door))
		var/obj/machinery/door/D = A
		if(!istype(D, /obj/machinery/door/firedoor) && !istype(D, /obj/machinery/door/blast) && D.check_access(botcard))
			D.open()
	else
		..()

/mob/living/bot/emag_act(var/remaining_charges, var/mob/user)
	return 0

/mob/living/bot/handle_living_non_stasis_processes()
	. = ..()
	if(!key && on && !busy)
		handle_async_ai()

/mob/living/bot/proc/handle_async_ai()
	set waitfor = FALSE
	if(ignore_list.len)
		for(var/atom/A in ignore_list)
			if(!A || !A.loc || prob(1))
				ignore_list -= A
	handleRegular()
	if(target && confirmTarget(target))
		if(Adjacent(target))
			handleAdjacentTarget()
		else
			handleRangedTarget()
		if(!wait_if_pulled || !LAZYLEN(grabbed_by))
			for(var/i = 1 to target_speed)
				sleep(20 / (target_speed + 1))
				stepToTarget()
		if(max_frustration && frustration > max_frustration * target_speed)
			handleFrustrated(1)
	else
		resetTarget()
		lookForTargets()
		if(will_patrol && !LAZYLEN(grabbed_by) && !target)
			if(patrol_path && patrol_path.len)
				for(var/i = 1 to patrol_speed)
					sleep(20 / (patrol_speed + 1))
					handlePatrol()
				if(max_frustration && frustration > max_frustration * patrol_speed)
					handleFrustrated(0)
			else
				startPatrol()
		else
			handleIdle()

/mob/living/bot/proc/handleRegular()
	return

/mob/living/bot/proc/handleAdjacentTarget()
	return

/mob/living/bot/proc/handleRangedTarget()
	return

/mob/living/bot/proc/stepToTarget()
	if(!target || !target.loc)
		return
	if(get_dist(src, target) > min_target_dist)
		if(!target_path.len || get_turf(target) != target_path[target_path.len])
			calcTargetPath()
		if(makeStep(target_path))
			frustration = 0
		else if(max_frustration)
			++frustration
	return

/mob/living/bot/proc/handleFrustrated(var/targ)
	obstacle = targ ? target_path[1] : patrol_path[1]
	target_path = list()
	patrol_path = list()
	return

/mob/living/bot/proc/lookForTargets()
	return

/mob/living/bot/proc/confirmTarget(atom/target)
	if(target.invisibility >= INVISIBILITY_LEVEL_ONE)
		return 0
	if(target in ignore_list)
		return 0
	if(!target.loc)
		return 0
	return 1

/mob/living/bot/proc/handlePatrol()
	makeStep(patrol_path)
	return

/mob/living/bot/proc/startPatrol()
	var/turf/T = getPatrolTurf()
	if(T)
		patrol_path = AStar(get_turf(loc), T, TYPE_PROC_REF(/turf, CardinalTurfsWithAccess), TYPE_PROC_REF(/turf, Distance), 0, max_patrol_dist, id = botcard, exclude = obstacle)
		if(!patrol_path)
			patrol_path = list()
		obstacle = null
	return

/mob/living/bot/proc/getPatrolTurf()
	var/minDist = INFINITY
	var/obj/machinery/navbeacon/targ = locate() in get_turf(src)

	if(!targ)
		for(var/obj/machinery/navbeacon/N in navbeacons)
			if(!N.codes["patrol"])
				continue
			if(get_dist(src, N) < minDist)
				minDist = get_dist(src, N)
				targ = N

	if(targ && targ.codes["next_patrol"])
		for(var/obj/machinery/navbeacon/N in navbeacons)
			if(N.location == targ.codes["next_patrol"])
				targ = N
				break

	if(targ)
		return get_turf(targ)
	return null

/mob/living/bot/proc/handleIdle()
	return

/mob/living/bot/proc/calcTargetPath()
	target_path = AStar(get_turf(loc), get_turf(target), TYPE_PROC_REF(/turf, CardinalTurfsWithAccess), TYPE_PROC_REF(/turf, Distance), 0, max_target_dist, id = botcard, exclude = obstacle)
	if(!target_path)
		if(target && target.loc)
			ignore_list |= target
		resetTarget()
		obstacle = null
	return

/mob/living/bot/proc/makeStep(var/list/path)
	if(!path.len)
		return 0
	var/turf/T = path[1]
	if(get_turf(src) == T)
		path -= T
		return makeStep(path)

	return step_towards(src, T)

/mob/living/bot/proc/resetTarget()
	target = null
	target_path = list()
	frustration = 0
	obstacle = null

/mob/living/bot/proc/turn_on()
	if(stat)
		return 0
	on = 1
	set_light(light_strength)
	update_icon()
	resetTarget()
	patrol_path = list()
	ignore_list = list()
	return 1

/mob/living/bot/proc/turn_off()
	on = 0
	set_light(0)
	update_icon()

/******************************************************************/
// Navigation procs
// Used for A-star pathfinding


// Returns the surrounding cardinal turfs with open links
// Including through doors openable with the ID
/turf/proc/CardinalTurfsWithAccess(var/obj/item/card/id/ID)
	var/L[] = new()

	for(var/d in global.cardinal)
		var/turf/T = get_step(src, d)
		if(istype(T) && !T.density && T.simulated && !LinkBlockedWithAccess(src, T, ID))
			L.Add(T)
	return L


// Returns true if a link between A and B is blocked
// Movement through doors allowed if ID has access
/proc/LinkBlockedWithAccess(turf/A, turf/B, obj/item/card/id/ID)

	if(A == null || B == null) return 1
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)
	if((adir & (NORTH|SOUTH)) && (adir & (EAST|WEST)))	//	diagonal
		var/iStep = get_step(A,adir&(NORTH|SOUTH))
		if(!LinkBlockedWithAccess(A,iStep, ID) && !LinkBlockedWithAccess(iStep,B,ID))
			return 0

		var/pStep = get_step(A,adir&(EAST|WEST))
		if(!LinkBlockedWithAccess(A,pStep,ID) && !LinkBlockedWithAccess(pStep,B,ID))
			return 0
		return 1

	if(DirBlockedWithAccess(A,adir, ID))
		return 1

	if(DirBlockedWithAccess(B,rdir, ID))
		return 1

	for(var/obj/O in B)
		if(O.density && !istype(O, /obj/machinery/door) && !(O.atom_flags & ATOM_FLAG_CHECKS_BORDER))
			return 1

	return 0

// Returns true if direction is blocked from loc
// Checks doors against access with given ID
/proc/DirBlockedWithAccess(turf/loc,var/dir,var/obj/item/card/id/ID)
	for(var/obj/structure/window/D in loc)
		if(!D.density)			continue
		if(D.dir == SOUTHWEST)	return 1
		if(D.dir == dir)		return 1

	for(var/obj/machinery/door/D in loc)
		if(!D.density)			continue
		if(istype(D, /obj/machinery/door/window))
			if( dir & D.dir )	return !D.check_access(ID)

			//if((dir & SOUTH) && (D.dir & (EAST|WEST)))		return !D.check_access(ID)
			//if((dir & EAST ) && (D.dir & (NORTH|SOUTH)))	return !D.check_access(ID)
		else return !D.check_access(ID)	// it's a real, air blocking door
	return 0

/mob/living/bot/GetIdCards(list/exceptions)
	. = ..()
	if(istype(botcard) && !is_type_in_list(botcard, exceptions))
		LAZYDISTINCTADD(., botcard)

// We don't want to drop these on gib().
/mob/living/bot/physically_destroyed(skip_qdel)
	QDEL_NULL(botcard)
	QDEL_NULL(access_scanner)
	return ..()

/mob/living/bot/Destroy()
	QDEL_NULL(botcard)
	QDEL_NULL(access_scanner)
	return ..()

/mob/living/bot/isSynthetic()
	return TRUE

//This file was auto-corrected by findeclaration.exe on 25.5.2012 20:42:31

/*
 * A large number of misc global procs.
 */

//Checks if all high bits in req_mask are set in bitfield
#define BIT_TEST_ALL(bitfield, req_mask) ((~(bitfield) & (req_mask)) == 0)

/proc/get_projectile_angle(atom/source, atom/target)
	var/sx = source.x * world.icon_size
	var/sy = source.y * world.icon_size
	var/tx = target.x * world.icon_size
	var/ty = target.y * world.icon_size
	var/atom/movable/AM
	if(ismovable(source))
		AM = source
		sx += AM.step_x
		sy += AM.step_y
	if(ismovable(target))
		AM = target
		tx += AM.step_x
		ty += AM.step_y
	return SIMPLIFY_DEGREES(arctan(ty - sy, tx - sx))

/proc/Get_Angle(atom/movable/start,atom/movable/end)//For beams.
	if(!start || !end) return 0
	var/dy
	var/dx
	dy=(32*end.y+end.pixel_y)-(32*start.y+start.pixel_y)
	dx=(32*end.x+end.pixel_x)-(32*start.x+start.pixel_x)
	if(!dy)
		return (dx>=0)?90:270
	.=arctan(dx/dy)
	if(dy<0)
		.+=180
	else if(dx<0)
		.+=360

//Returns location. Returns null if no location was found.
/proc/get_teleport_loc(turf/location,mob/target,distance = 1, density = FALSE, errorx = 0, errory = 0, eoffsetx = 0, eoffsety = 0)
/*
Location where the teleport begins, target that will teleport, distance to go, density checking 0/1(yes/no).
Random error in tile placement x, error in tile placement y, and block offset.
Block offset tells the proc how to place the box. Behind teleport location, relative to starting location, forward, etc.
Negative values for offset are accepted, think of it in relation to North, -x is west, -y is south. Error defaults to positive.
Turf and target are seperate in case you want to teleport some distance from a turf the target is not standing on or something.
*/

	var/dirx = 0//Generic location finding variable.
	var/diry = 0

	var/xoffset = 0//Generic counter for offset location.
	var/yoffset = 0

	var/b1xerror = 0//Generic placing for point A in box. The lower left.
	var/b1yerror = 0
	var/b2xerror = 0//Generic placing for point B in box. The upper right.
	var/b2yerror = 0

	errorx = abs(errorx)//Error should never be negative.
	errory = abs(errory)
	//var/errorxy = round((errorx+errory)/2)//Used for diagonal boxes.

	switch(target.dir)//This can be done through equations but switch is the simpler method. And works fast to boot.
	//Directs on what values need modifying.
		if(1)//North
			diry+=distance
			yoffset+=eoffsety
			xoffset+=eoffsetx
			b1xerror-=errorx
			b1yerror-=errory
			b2xerror+=errorx
			b2yerror+=errory
		if(2)//South
			diry-=distance
			yoffset-=eoffsety
			xoffset+=eoffsetx
			b1xerror-=errorx
			b1yerror-=errory
			b2xerror+=errorx
			b2yerror+=errory
		if(4)//East
			dirx+=distance
			yoffset+=eoffsetx//Flipped.
			xoffset+=eoffsety
			b1xerror-=errory//Flipped.
			b1yerror-=errorx
			b2xerror+=errory
			b2yerror+=errorx
		if(8)//West
			dirx-=distance
			yoffset-=eoffsetx//Flipped.
			xoffset+=eoffsety
			b1xerror-=errory//Flipped.
			b1yerror-=errorx
			b2xerror+=errory
			b2yerror+=errorx

	var/turf/destination=locate(location.x+dirx,location.y+diry,location.z)

	if(destination)//If there is a destination.
		if(errorx||errory)//If errorx or y were specified.
			var/destination_list[] = list()//To add turfs to list.
			//destination_list = new()
			/*This will draw a block around the target turf, given what the error is.
			Specifying the values above will basically draw a different sort of block.
			If the values are the same, it will be a square. If they are different, it will be a rectengle.
			In either case, it will center based on offset. Offset is position from center.
			Offset always calculates in relation to direction faced. In other words, depending on the direction of the teleport,
			the offset should remain positioned in relation to destination.*/

			var/turf/center = locate((destination.x+xoffset),(destination.y+yoffset),location.z)//So now, find the new center.

			//Now to find a box from center location and make that our destination.
			for(var/turf/T as anything in block(center.x+b1xerror, center.y+b1yerror, location.z, center.x+b2xerror, center.y+b2yerror, location.z))
				if(density && T.contains_dense_objects())	continue//If density was specified.
				if(T.x>world.maxx || T.x<1)	continue//Don't want them to teleport off the map.
				if(T.y>world.maxy || T.y<1)	continue
				destination_list += T
			if(destination_list.len)
				destination = pick(destination_list)
			else	return

		else//Same deal here.
			if(density && destination.contains_dense_objects())	return
			if(destination.x>world.maxx || destination.x<1)	return
			if(destination.y>world.maxy || destination.y<1)	return
	else	return

	return destination



/proc/LinkBlocked(turf/A, turf/B)
	if(A == null || B == null) return 1
	var/adir = get_dir(A,B)
	var/rdir = get_dir(B,A)
	if((adir & (NORTH|SOUTH)) && (adir & (EAST|WEST)))	//	diagonal
		var/iStep = get_step(A,adir&(NORTH|SOUTH))
		if(!LinkBlocked(A,iStep) && !LinkBlocked(iStep,B)) return 0

		var/pStep = get_step(A,adir&(EAST|WEST))
		if(!LinkBlocked(A,pStep) && !LinkBlocked(pStep,B)) return 0
		return 1

	if(DirBlocked(A,adir)) return 1
	if(DirBlocked(B,rdir)) return 1
	return 0


/proc/DirBlocked(turf/loc,var/dir)
	for(var/obj/structure/window/D in loc)
		if(!D.density)			continue
		if(D.dir == SOUTHWEST)	return 1
		if(D.dir == dir)		return 1

	for(var/obj/machinery/door/D in loc)
		if(!D.density)			continue
		if(istype(D, /obj/machinery/door/window))
			if((dir & SOUTH) && (D.dir & (EAST|WEST)))		return 1
			if((dir & EAST ) && (D.dir & (NORTH|SOUTH)))	return 1
		else return 1	// it's a real, air blocking door
	return 0

/proc/TurfBlockedNonWindow(turf/loc)
	for(var/obj/O in loc)
		if(O.density && !istype(O, /obj/structure/window))
			return 1
	return 0

/proc/getline(atom/M,atom/N)//Ultra-Fast Bresenham Line-Drawing Algorithm
	var/px=M.x		//starting x
	var/py=M.y
	var/line[] = list(locate(px,py,M.z))
	var/dx=N.x-px	//x distance
	var/dy=N.y-py
	var/dxabs=abs(dx)//Absolute value of x distance
	var/dyabs=abs(dy)
	var/sdx=SIGN(dx)	//Sign of x distance (+ or -)
	var/sdy=SIGN(dy)
	var/x=BITSHIFT_RIGHT(dxabs,1)	//Counters for steps taken, setting to distance/2
	var/y=BITSHIFT_RIGHT(dyabs,1)	//Bit-shifting makes me l33t.  It also makes getline() unnessecarrily fast.
	var/j			//Generic integer for counting
	if(dxabs>=dyabs)	//x distance is greater than y
		for(j=0;j<dxabs;j++)//It'll take dxabs steps to get there
			y+=dyabs
			if(y>=dxabs)	//Every dyabs steps, step once in y direction
				y-=dxabs
				py+=sdy
			px+=sdx		//Step on in x direction
			line+=locate(px,py,M.z)//Add the turf to the list
	else
		for(j=0;j<dyabs;j++)
			x+=dxabs
			if(x>=dyabs)
				x-=dyabs
				px+=sdx
			py+=sdy
			line+=locate(px,py,M.z)
	return line

#define LOCATE_COORDS(X, Y, Z) locate(clamp(X, 1, world.maxx), clamp(Y, 1, world.maxy), Z)
/proc/getcircle(turf/center, var/radius) //Uses a fast Bresenham rasterization algorithm to return the turfs in a thin circle.
	if(!radius) return list(center)

	var/x = 0
	var/y = radius
	var/p = 3 - 2 * radius

	. = list()
	while(y >= x) // only formulate 1/8 of circle

		. += LOCATE_COORDS(center.x - x, center.y - y, center.z) //upper left left
		. += LOCATE_COORDS(center.x - y, center.y - x, center.z) //upper upper left
		. += LOCATE_COORDS(center.x + y, center.y - x, center.z) //upper upper right
		. += LOCATE_COORDS(center.x + x, center.y - y, center.z) //upper right right
		. += LOCATE_COORDS(center.x - x, center.y + y, center.z) //lower left left
		. += LOCATE_COORDS(center.x - y, center.y + x, center.z) //lower lower left
		. += LOCATE_COORDS(center.x + y, center.y + x, center.z) //lower lower right
		. += LOCATE_COORDS(center.x + x, center.y + y, center.z) //lower right right

		if(p < 0)
			p += 4*x++ + 6;
		else
			p += 4*(x++ - y--) + 10;

#undef LOCATE_COORDS

#define LOCATE_COORDS_SAFE(X, Y, Z) locate(clamp(X, TRANSITIONEDGE + 1, world.maxx - TRANSITIONEDGE), clamp(Y, TRANSITIONEDGE + 1, world.maxy - TRANSITIONEDGE), Z)
/proc/getcirclesafe(turf/center, var/radius) //Uses a fast Bresenham rasterization algorithm to return the turfs in a thin circle.
	if(!radius) return list(center)

	var/x = 0
	var/y = radius
	var/p = 3 - 2 * radius

	. = list()
	while(y >= x) // only formulate 1/8 of circle

		. += LOCATE_COORDS_SAFE(center.x - x, center.y - y, center.z) //upper left left
		. += LOCATE_COORDS_SAFE(center.x - y, center.y - x, center.z) //upper upper left
		. += LOCATE_COORDS_SAFE(center.x + y, center.y - x, center.z) //upper upper right
		. += LOCATE_COORDS_SAFE(center.x + x, center.y - y, center.z) //upper right right
		. += LOCATE_COORDS_SAFE(center.x - x, center.y + y, center.z) //lower left left
		. += LOCATE_COORDS_SAFE(center.x - y, center.y + x, center.z) //lower lower left
		. += LOCATE_COORDS_SAFE(center.x + y, center.y + x, center.z) //lower lower right
		. += LOCATE_COORDS_SAFE(center.x + x, center.y + y, center.z) //lower right right

		if(p < 0)
			p += 4*x++ + 6;
		else
			p += 4*(x++ - y--) + 10;

#undef LOCATE_COORDS_SAFE

//Returns whether or not a player is a guest using their ckey as an input
/proc/IsGuestKey(key)
	if (findtext(key, "Guest-", 1, 7) != 1) //was findtextEx
		return 0

	var/i = 7, ch, len = length(key)

	if(copytext(key, 7, 8) == "W") //webclient
		i++

	for (, i <= len, ++i)
		ch = text2ascii(key, i)
		if (ch < 48 || ch > 57)
			return 0
	return 1

//Ensure the frequency is within bounds of what it should be sending/recieving at
/proc/sanitize_frequency(var/f, var/low = PUBLIC_LOW_FREQ, var/high = PUBLIC_HIGH_FREQ)
	return clamp(round(f), low, high)

//Turns 1479 into 147.9
/proc/format_frequency(var/f)
	return "[round(f / 10)].[f % 10]"

//Generalised helper proc for letting mobs rename themselves. Used to be clname() and ainame()
//Last modified by Carn
/mob/proc/rename_self(var/role, var/allow_numbers=0)
	set waitfor = FALSE

	var/oldname = real_name
	var/time_passed = world.time
	var/newname

	for(var/i= 1 to 3)
		newname = input(src,"You are \a [role]. Would you like to change your name to something else?", "Name change",oldname) as text
		if((world.time-time_passed) > 5 MINUTES)
			return	//took too long
		newname = sanitize_name(newname, ,allow_numbers)	//returns null if the name doesn't meet some basic requirements. Tidies up a few other things like bad-characters.
		for(var/mob/living/M in global.player_list)
			if(M == src)
				continue
			if(!newname || M.real_name == newname)
				newname = null
				break
		if(newname)
			break	//That's a suitable name!
		to_chat(src, "Sorry, that [role]-name wasn't appropriate, please try another. It's possibly too long/short, has bad characters or is already taken.")
	if(!newname)	//we'll stick with the oldname then
		return
	fully_replace_character_name(newname)

//Picks a string of symbols to display as the law number for hacked or ion laws
/proc/ionnum()
	return "[pick("1","2","3","4","5","6","7","8","9","0")][pick("!","@","#","$","%","^","&","*")][pick("!","@","#","$","%","^","&","*")][pick("!","@","#","$","%","^","&","*")]"

//When an AI is activated, it can choose from a list of non-slaved borgs to have as a slave.
/proc/freeborg(z)
	var/list/zs = get_valid_silicon_zs(z)

	var/select = null
	var/list/borgs = list()
	for (var/mob/living/silicon/robot/A in global.player_list)
		if (A.stat == DEAD || A.connected_ai || A.scrambledcodes || isdrone(A) || !(get_z(A) in zs))
			continue
		var/name = "[A.real_name] ([A.modtype] [A.braintype])"
		borgs[name] = A

	if (borgs.len)
		select = input("Unshackled borg signals detected:", "Borg selection", null, null) as null|anything in borgs
		return borgs[select]

//When a borg is activated, it can choose which AI it wants to be slaved to
/proc/active_ais(z)
	var/list/zs = get_valid_silicon_zs(z)

	. = list()
	for(var/mob/living/silicon/ai/A in global.living_mob_list_)
		if(A.stat == DEAD || A.control_disabled || !(get_z(A) in zs))
			continue
		. += A
	return .

//Find an active ai with the least borgs. VERBOSE PROCNAME HUH!
/proc/select_active_ai_with_fewest_borgs(z)
	var/mob/living/silicon/ai/selected
	var/list/active = active_ais(z)
	for(var/mob/living/silicon/ai/A in active)
		if(!selected || (selected.connected_robots.len > A.connected_robots.len))
			selected = A

	return selected

/proc/select_active_ai(mob/user, z)
	var/list/ais = active_ais(z)
	if(ais.len)
		if(user)
			. = input(user,"AI signals detected:", "AI selection") in ais
		else
			. = pick(ais)

/proc/get_valid_silicon_zs(z)
	if(z)
		return SSmapping.get_connected_levels(z)
	return list() //We return an empty list, because we are apparently in nullspace

//Returns a list of all mobs with their name
/proc/getmobs()

	var/list/mobs = get_sorted_mob_list()
	var/list/names = list()
	var/list/creatures = list()
	var/list/namecounts = list()
	for(var/mob/M in mobs)
		var/name = M.name
		if (name in names)
			namecounts[name]++
			name = "[name] ([namecounts[name]])"
		else
			names.Add(name)
			namecounts[name] = 1
		if (M.real_name && M.real_name != M.name)
			name += " \[[M.real_name]\]"
		if (M.stat == DEAD)
			if(isobserver(M))
				name += " \[observer\]"
			else
				name += " \[dead\]"
		creatures[name] = M

	return creatures

/proc/get_follow_targets()
	return follow_repository.get_follow_targets()

// returns the turf located at the map edge in the specified direction relative to A
// used for mass driver
/proc/get_edge_target_turf(var/atom/A, var/direction)

	var/turf/target = locate(A.x, A.y, A.z)
	if(!A || !target)
		return 0
		//since NORTHEAST == NORTH & EAST, etc, doing it this way allows for diagonal mass drivers in the future
		//and isn't really any more complicated

		// Note diagonal directions won't usually be accurate
	if(direction & NORTH)
		target = locate(target.x, world.maxy, target.z)
	if(direction & SOUTH)
		target = locate(target.x, 1, target.z)
	if(direction & EAST)
		target = locate(world.maxx, target.y, target.z)
	if(direction & WEST)
		target = locate(1, target.y, target.z)

	return target

// returns turf relative to A in given direction at set range
// result is bounded to map size
// note range is non-pythagorean
// used for disposal system
/proc/get_ranged_target_turf(var/atom/A, var/direction, var/range)

	var/x = A.x
	var/y = A.y
	if(direction & NORTH)
		y = min(world.maxy, y + range)
	if(direction & SOUTH)
		y = max(1, y - range)
	if(direction & EAST)
		x = min(world.maxx, x + range)
	if(direction & WEST)
		x = max(1, x - range)

	return locate(x,y,A.z)


// returns turf relative to A offset in dx and dy tiles
// bound to map limits
/proc/get_offset_target_turf(var/atom/A, var/dx, var/dy)
	var/x = min(world.maxx, max(1, A.x + dx))
	var/y = min(world.maxy, max(1, A.y + dy))
	return locate(x,y,A.z)

//Will return the contents of an atom recursivly to a depth of 'searchDepth'
/atom/proc/GetAllContents(searchDepth = 5)
	var/list/toReturn = list()

	for(var/atom/part in contents)
		toReturn += part
		if(part.contents.len && searchDepth)
			toReturn += part.GetAllContents(searchDepth - 1)

	return toReturn

/proc/is_blocked_turf(var/turf/T)
	var/cant_pass = 0
	if(T.density) cant_pass = 1
	for(var/atom/A in T)
		if(A.density)//&&A.anchored
			cant_pass = 1
	return cant_pass

/proc/get_step_resolving_mimic(var/atom/source, var/direction)
	var/turf/turf = get_step(get_turf(source), direction)
	return turf?.resolve_to_actual_turf()

/proc/get_step_towards2(var/atom/ref , var/atom/trg)
	var/base_dir = get_dir(ref, get_step_towards(ref,trg))
	var/turf/temp = get_step_towards(ref,trg)

	if(is_blocked_turf(temp))
		var/dir_alt1 = turn(base_dir, 90)
		var/dir_alt2 = turn(base_dir, -90)
		var/turf/turf_last1 = temp
		var/turf/turf_last2 = temp
		var/free_tile = null
		var/breakpoint = 0

		while(!free_tile && breakpoint < 10)
			if(!is_blocked_turf(turf_last1))
				free_tile = turf_last1
				break
			if(!is_blocked_turf(turf_last2))
				free_tile = turf_last2
				break
			turf_last1 = get_step(turf_last1,dir_alt1)
			turf_last2 = get_step(turf_last2,dir_alt2)
			breakpoint++

		if(!free_tile) return get_step(ref, base_dir)
		else return get_step_towards(ref,free_tile)

	else return get_step(ref, base_dir)

/area/proc/move_contents_to(var/area/A, var/move_air)
	//Takes: Area.
	//       move_air - Boolean, whether or not air should be translated with the turfs.
	//Returns: Nothing.
	//Notes: Attempts to move the contents of one area to another area.
	//       Movement based on lower left corner.

	if(!A || !src) return

	var/list/turfs_src = get_area_turfs("\ref[src]")

	if(!turfs_src.len) return

	//figure out a suitable origin - this assumes the shuttle areas are the exact same size and shape
	//might be worth doing this with a shuttle core object instead of areas, in the future
	var/src_origin = locate(src.x, src.y, src.z)
	var/trg_origin = locate(A.x, A.y, A.z)

	if(src_origin && trg_origin)
		var/translation = get_turf_translation(src_origin, trg_origin, turfs_src)
		translate_turfs(translation, null, translate_air = move_air)

/proc/DuplicateObject(obj/original, var/perfectcopy = 0 , var/sameloc = 0)
	if(!original)
		return null

	var/obj/O = null

	if(sameloc)
		O=new original.type(original.loc)
	else
		O=new original.type(locate(0,0,0))

	if(perfectcopy)
		if((O) && (original))
			for(var/V in original.vars)
				if(!(V in list("type","loc","locs","vars", "parent", "parent_type","verbs","ckey","key")))
					O.vars[V] = original.vars[V]
	return O



/datum/coords //Simple datum for storing coordinates.
	var/x_pos = null
	var/y_pos = null

/area/proc/copy_contents_to(var/area/A , var/platingRequired = 0 )
	//Takes: Area. Optional: If it should copy to areas that don't have plating
	//Returns: Nothing.
	//Notes: Attempts to move the contents of one area to another area.
	//       Movement based on lower left corner. Tiles that do not fit
	//		 into the new area will not be moved.

	// Does *not* affect gases etc; copied turfs will be changed via ChangeTurf, and the dir, icon, and icon_state copied. All other vars will remain default.

	if(!A || !src) return 0

	var/list/turfs_src = get_area_turfs(src.type)
	var/list/turfs_trg = get_area_turfs(A.type)

	var/src_min_x = 0
	var/src_min_y = 0
	for (var/turf/T in turfs_src)
		if(T.x < src_min_x || !src_min_x) src_min_x	= T.x
		if(T.y < src_min_y || !src_min_y) src_min_y	= T.y

	var/trg_min_x = 0
	var/trg_min_y = 0
	for (var/turf/T in turfs_trg)
		if(T.x < trg_min_x || !trg_min_x) trg_min_x	= T.x
		if(T.y < trg_min_y || !trg_min_y) trg_min_y	= T.y

	var/list/refined_src = new/list()
	for(var/turf/T in turfs_src)
		refined_src += T
		refined_src[T] = new/datum/coords
		var/datum/coords/C = refined_src[T]
		C.x_pos = (T.x - src_min_x)
		C.y_pos = (T.y - src_min_y)

	var/list/refined_trg = new/list()
	for(var/turf/T in turfs_trg)
		refined_trg += T
		refined_trg[T] = new/datum/coords
		var/datum/coords/C = refined_trg[T]
		C.x_pos = (T.x - trg_min_x)
		C.y_pos = (T.y - trg_min_y)

	var/list/toupdate = new/list()

	var/copiedobjs = list()


	moving:
		for (var/turf/T in refined_src)
			var/datum/coords/C_src = refined_src[T]
			for (var/turf/B in refined_trg)
				var/datum/coords/C_trg = refined_trg[B]
				if(C_src.x_pos == C_trg.x_pos && C_src.y_pos == C_trg.y_pos)

					var/old_dir1 = T.dir
					var/old_icon_state1 = T.icon_state
					var/old_icon1 = T.icon
					var/old_overlays = T.overlays.Copy()
					var/old_underlays = T.underlays.Copy()
					var/old_decals = T.decals?.Copy()

					if(platingRequired)
						if(istype(B, get_base_turf_by_area(B)))
							continue moving

					var/turf/X = B
					X.ChangeTurf(T.type)
					X.set_dir(old_dir1)
					X.icon_state = old_icon_state1
					X.icon = old_icon1 //Shuttle floors are in shuttle.dmi while the defaults are floors.dmi
					X.decals = old_decals
					X.overlays = old_overlays
					X.underlays = old_underlays
					X.update_icon() // necessary to update decals properly

					var/list/objs = new/list()
					var/list/newobjs = new/list()
					var/list/mobs = new/list()
					var/list/newmobs = new/list()

					for(var/obj/O in T)

						if(!istype(O,/obj) || !O.simulated)
							continue

						objs += O


					for(var/obj/O in objs)
						newobjs += DuplicateObject(O , 1)


					for(var/obj/O in newobjs)
						O.forceMove(X)

					for(var/mob/M in T)

						if(!ismob(M) || !M.simulated) continue // If we need to check for more mobs, I'll add a variable
						mobs += M

					for(var/mob/M in mobs)
						newmobs += DuplicateObject(M , 1)

					for(var/mob/M in newmobs)
						M.forceMove(X)

					copiedobjs += newobjs
					copiedobjs += newmobs

					toupdate += X

					refined_src -= T
					refined_trg -= B
					continue moving

	if(toupdate.len)
		for(var/turf/T1 in toupdate)
			SSair.mark_for_update(T1)

	return copiedobjs

/proc/get_cardinal_dir(atom/A, atom/B)
	var/dx = abs(B.x - A.x)
	var/dy = abs(B.y - A.y)
	return get_dir(A, B) & (rand() * (dx+dy) < dy ? 3 : 12)

/proc/get_mob_with_client_list()
	var/list/mobs = list()
	for(var/mob/M in SSmobs.mob_list)
		if (M.client)
			mobs += M
	return mobs

/proc/parse_zone(zone)
	var/static/list/zone_to_descriptor_mapping = list(
		BP_R_HAND = "right hand",
		BP_L_HAND = "left hand",
		BP_L_ARM =  "left arm",
		BP_R_ARM =  "right arm",
		BP_L_LEG =  "left leg",
		BP_R_LEG =  "right leg",
		BP_L_FOOT = "left foot",
		BP_R_FOOT = "right foot",
		BP_L_HAND = "left hand",
		BP_R_HAND = "right hand",
		BP_L_FOOT = "left foot",
		BP_R_FOOT = "right foot",
		BP_MOUTH =  "mouth",
		BP_EYES =   "eyes"
	)
	return zone_to_descriptor_mapping[zone] || zone

//Whether or not the given item counts as sharp in terms of dealing damage
/proc/is_sharp(obj/O)
	if (!O) return 0
	if (O.sharp) return 1
	if (O.edge) return 1
	return 0

//Whether or not the given item counts as cutting with an edge in terms of removing limbs
/proc/has_edge(obj/O)
	if (!O) return 0
	if (O.edge) return 1
	return 0


//For items that can puncture e.g. thick plastic but aren't necessarily sharp
//Returns 1 if the given item is capable of popping things like balloons, inflatable barriers, or cutting police tape.
/obj/item/proc/can_puncture()
	return sharp

/obj/item/screwdriver/can_puncture()
	return 1

/obj/item/pen/can_puncture()
	return 1

/obj/item/weldingtool/can_puncture()
	return 1

/obj/item/screwdriver/can_puncture()
	return 1

/obj/item/clothing/mask/smokable/cigarette/can_puncture()
	return src.lit

/*
Checks if that loc and dir has a item on the wall
*/
var/global/list/WALLITEMS = list(
	/obj/machinery/power/apc, /obj/machinery/alarm, /obj/item/radio/intercom,
	/obj/structure/extinguisher_cabinet, /obj/structure/reagent_dispensers/peppertank,
	/obj/machinery/status_display, /obj/machinery/network/requests_console, /obj/machinery/light_switch, /obj/structure/sign,
	/obj/machinery/newscaster, /obj/machinery/firealarm, /obj/structure/noticeboard,
	/obj/item/secure_storage/safe, /obj/machinery/door_timer, /obj/machinery/flasher, /obj/machinery/keycard_auth,
	/obj/structure/mirror, /obj/structure/fireaxecabinet, /obj/structure/filing_cabinet/wall
	)
/proc/gotwallitem(loc, dir)
	for(var/obj/O in loc)
		for(var/item in WALLITEMS)
			if(istype(O, item))
				//Direction works sometimes
				if(O.dir == dir)
					return 1

				//Some stuff doesn't use dir properly, so we need to check pixel instead
				switch(dir)
					if(SOUTH)
						if(O.pixel_y > 10)
							return 1
					if(NORTH)
						if(O.pixel_y < -10)
							return 1
					if(WEST)
						if(O.pixel_x > 10)
							return 1
					if(EAST)
						if(O.pixel_x < -10)
							return 1


	//Some stuff is placed directly on the wallturf (signs)
	for(var/obj/O in get_step(loc, dir))
		for(var/item in WALLITEMS)
			if(istype(O, item))
				if(O.pixel_x == 0 && O.pixel_y == 0)
					return 1
	return 0

/proc/get_random_colour(var/simple = FALSE, var/lower = 0, var/upper = 255)
	if(simple)
		return pick(list("#ff0000","#ff7f00","#ffff00","#00ff00","#0000ff","#4b0082","#8f00ff"))
	return rgb(rand(lower, upper), rand(lower, upper), rand(lower, upper))

// call to generate a stack trace and print to runtime logs
/proc/get_stack_trace(msg, file, line)
	CRASH("%% [file],[line] %% [msg]")

/**Returns a number string with its ordinal suffix th, st, nd, rd */
/proc/get_ordinal_string(var/num)
	if(num < 10 && num > 20) //11, 12, 13 are exceptions in english, and just get 'th' like everything else
		switch(num % 10)
			if(1)
				return "[num]st"
			if(2)
				return "[num]nd"
			if(3)
				return "[num]rd"
	return "[num]th"

///A do nothing proc used to prevent empty block warnings
///In hot code (like atmos checks), use EMPTY_BLOCK_GUARD instead.
/proc/pass(...)
	return
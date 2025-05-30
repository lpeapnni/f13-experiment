// This is a set of datums instantiated by SSpersistence.
// They basically just handle loading, processing and saving specific forms
// of persistent data like graffiti and round to round filth.

/decl/persistence_handler
	var/name                       // Unique descriptive name. Used for generating filename.
	var/filename                   // Set at runtime. Full path and .json extension for loading saved data.
	var/entries_expire_at          // Entries are removed if they are older than this number of rounds.
	var/entries_decay_at           // Entries begin to decay if they are older than this number of rounds (if applicable).
	var/entry_decay_weight = 0.5   // A modifier for the rapidity of decay.
	var/has_admin_data             // If set, shows up on the admin persistence panel.
	var/ignore_area_flags = FALSE  // Set to TRUE to skip area flag checks such as nonpersistent areas.
	var/ignore_invalid_loc = FALSE // Set to TRUE to skip checking for a non-null station turf for the entry.

/decl/persistence_handler/Initialize()
	SetFilename()
	. = ..()

/decl/persistence_handler/proc/SetFilename()
	if(name)
		filename = "data/persistent/[ckey(global.using_map.name)]-[ckey(name)].json"
	if(!isnull(entries_decay_at) && !isnull(entries_expire_at))
		entries_decay_at = floor(entries_expire_at * entries_decay_at)

/decl/persistence_handler/proc/GetValidTurf(var/turf/T, var/list/tokens)
	if(T && isStationLevel(T.z) && CheckTurfContents(T, tokens))
		return T

/decl/persistence_handler/proc/CheckTurfContents(var/turf/T, var/list/tokens)
	return TRUE

/decl/persistence_handler/proc/CheckTokenSanity(var/list/tokens)
	if(!islist(tokens))
		return FALSE
	if(isnull(tokens["x"]) || isnull(tokens["y"]) || isnull(tokens["z"]))
		return FALSE
	if(!isnull(entries_expire_at))
		if(isnull(tokens["age"]))
			return FALSE
		if(tokens["age"] > entries_expire_at)
			return FALSE
	return TRUE

/decl/persistence_handler/proc/CreateEntryInstance(var/turf/creating, var/list/tokens)
	return

/decl/persistence_handler/proc/ProcessAndApplyTokens(var/list/tokens)

	// If it's old enough we start to trim down any textual information and scramble strings.
	if(tokens["message"] && !isnull(entries_decay_at) && !isnull(entry_decay_weight))
		var/_n = tokens["age"]
		var/_message = tokens["message"]
		if(_n >= entries_decay_at)
			var/decayed_message = ""
			for(var/i = 1 to length(_message))
				var/char = copytext(_message, i, i + 1)
				if(prob(round(_n * entry_decay_weight)))
					if(prob(99))
						decayed_message += pick(".",",","-","'","\\","/","\"",":",";")
				else
					decayed_message += char
			_message = decayed_message
		if(length(_message))
			tokens["message"] = _message
		else
			return

	. = GetValidTurf(locate(tokens["x"], tokens["y"], tokens["z"]), tokens)
	if(.)
		. = CreateEntryInstance(., tokens)

/decl/persistence_handler/proc/IsValidEntry(var/atom/entry)
	if(!istype(entry))
		return FALSE
	if(!isnull(entries_expire_at) && GetEntryAge(entry) >= entries_expire_at)
		return FALSE
	var/turf/T = get_turf(entry)
	if(!ignore_invalid_loc && (!T || !isStationLevel(T.z)))
		return FALSE
	var/area/A = get_area(T)
	if(!ignore_area_flags && (!A || (A.area_flags & AREA_FLAG_IS_NOT_PERSISTENT)))
		return FALSE
	return TRUE

/decl/persistence_handler/proc/GetEntryAge(var/atom/entry)
	return 0

/decl/persistence_handler/proc/CompileEntry(var/atom/entry)
	var/turf/T = get_turf(entry)
	. = list()
	.["x"] =   T?.x || 0
	.["y"] =   T?.y || 0
	.["z"] =   T?.z || 0
	.["age"] = GetEntryAge(entry)

/decl/persistence_handler/proc/FinalizeTokens(var/list/tokens)
	. = tokens || list()

/decl/persistence_handler/Initialize()

	. = ..()

	if(!fexists(filename))
		return

	var/list/entries = cached_json_decode(safe_file2text(filename, FALSE))
	if(!length(entries))
		return

	var/list/encoding_flag = entries[1]
	if(encoding_flag && ("url_encoded" in encoding_flag))
		entries -= encoding_flag
		for(var/list/entry in entries)
			for(var/i in 1 to entry.len)
				var/item = entry[i]
				var/decoded_value = (istext(entry[item]) ? url_decode(entry[item]) : entry[item])
				var/decoded_key = url_decode(item)
				entry[i] = decoded_key
				entry[decoded_key] = decoded_value

	for(var/list/entry in entries)
		entry = FinalizeTokens(entry)
		if(CheckTokenSanity(entry))
			ProcessAndApplyTokens(entry)

/decl/persistence_handler/proc/Shutdown()
	var/list/entries = list()
	for(var/thing in SSpersistence.tracking_values[type])
		if(IsValidEntry(thing))
			entries += list(CompileEntry(thing))

	if(fexists(filename))
		fdel(filename)
	to_file(file(filename), json_encode(entries))

/decl/persistence_handler/proc/RemoveValue(var/atom/value)
	qdel(value)

/decl/persistence_handler/proc/GetAdminSummary(var/mob/user, var/can_modify)
	. = list("<tr><td colspan = 4><b>[capitalize(name)]</b></td></tr>")
	. += "<tr><td colspan = 4><hr></td></tr>"
	for(var/thing in SSpersistence.tracking_values[type])
		if(IsValidEntry(thing))
			. += "<tr>[GetAdminDataStringFor(thing, can_modify, user)]</tr>"
	. += "<tr><td colspan = 4><hr></td></tr>"

/decl/persistence_handler/proc/GetAdminDataStringFor(var/thing, var/can_modify, var/mob/user)
	if(can_modify)
		. = "<td colspan = 3>[thing]</td><td><a href='byond://?src=\ref[src];caller=\ref[user];remove_entry=\ref[thing]'>Destroy</a></td>"
	else
		. = "<td colspan = 4>[thing]</td>"

/decl/persistence_handler/Topic(var/href, var/href_list)
	. = ..()
	if(!.)
		if(href_list["remove_entry"])
			var/datum/value = locate(href_list["remove_entry"])
			if(istype(value))
				RemoveValue(value)
				. = TRUE
		if(.)
			var/mob/user = locate(href_list["caller"])
			if(user)
				SSpersistence.show_info(user)

var/global/list/symbiote_starting_points = list()

/decl/background_detail/faction/symbiotic
	name = "Symbiote Host"
	description = "Your culture has always welcomed a form of brain-slug called cortical borers into their bodies, \
	and your upbringing taught that this was a normal and beneficial state of affairs. Taking this background will \
	allow symbiote players to join as your mind-partner. Symbiotes can secrete beneficial chemicals, translate languages \
	and are rendered docile by sugar. Unlike feral cortical borers, they cannot take control of your body or cause brain damage."
	economic_power = 0.8
	uid = "heritage_symbiote"
	var/matches_to_role = /datum/job/symbiote

/datum/job/symbiote
	title = "Symbiote"
	total_positions = -1
	spawn_positions = -1
	supervisors = "your host"
	selection_color = "#ad6bad"
	access = list()
	minimal_access = list()
	minimal_player_age = 14
	economic_power = 0
	defer_roundstart_spawn = TRUE
	hud_icon = "hudblank"
	outfit_type = /decl/outfit/job/symbiote_host
	create_record = FALSE
	var/check_whitelist // = "Symbiote"
	var/static/mob/living/simple_animal/borer/preview_slug

/decl/outfit/job/symbiote_host
	name = "Job - Symbiote Host"

/datum/job/symbiote/post_equip_job_title(var/mob/person, var/alt_title)

	var/mob/living/simple_animal/borer/symbiote = person
	symbiote.SetName(symbiote.truename)
	symbiote.real_name = symbiote.truename

	to_chat(person, "<b>You are a [alt_title || title].</b>")
	to_chat(person, "<b>As the [alt_title || title] you answer directly to [supervisors]. Special circumstances may change this.</b>")

	if(symbiote.host)
		if(symbiote.host.mind)
			var/a_the = (symbiote.host.mind.assigned_job?.total_positions == 1) ? "the" : "a"
			var/use_title = symbiote.host.mind.role_alt_title || symbiote.host.mind.assigned_role
			to_chat(symbiote, SPAN_NOTICE("Your current host is <b>\the [symbiote.host.real_name]</b>, [a_the] <b>[use_title]</b>. Help them stay safe and happy, and assist them in achieving their goals. <b>Remember, your host's desires take precedence over everyone else's.</b>"))
			to_chat(symbiote.host, SPAN_NOTICE("Your current symbiote, <b>[symbiote.name]</b>, has awakened. They will help you in whatever way they can. Treat them kindly."))
		else
			to_chat(symbiote, SPAN_NOTICE("Your host is <b>\the [symbiote.host.real_name]</b>. They are mindless and you should probably find a new one soon."))
	else
		to_chat(symbiote, SPAN_DANGER("You do not currently have a host."))

/datum/job/symbiote/is_restricted(var/datum/preferences/prefs, var/feedback)
	. = ..()
	if(. && check_whitelist && prefs?.client && !is_alien_whitelisted(prefs.client.mob, check_whitelist))
		if(feedback)
			to_chat(prefs.client.mob, SPAN_WARNING("You are not whitelisted for [check_whitelist] roles."))
		. = FALSE

/datum/job/symbiote/handle_variant_join(var/mob/living/human/H, var/alt_title)

	var/mob/living/simple_animal/borer/symbiote/symbiote = new
	var/mob/living/human/host
	try
		// No clean way to handle kicking them back to the lobby at this point, so dump
		// them into xenobio or latejoin instead if there are zero viable hosts left.
		var/list/available_hosts = find_valid_hosts()
		while(length(available_hosts) && (!host || !(host in available_hosts)))
			host = input(H, "Who do you wish to be your mind-partner?", "Symbiote Spawn") as anything in available_hosts
			var/list/current_hosts = find_valid_hosts() // Is the host still available?
			if(QDELETED(host) || QDELETED(H) || !H.key || !(host in current_hosts))
				host = null
				available_hosts = current_hosts
	catch(var/exception/e)
		log_debug("Exception during symbiote join: [EXCEPTION_TEXT(e)]")

	if(host)
		var/obj/item/organ/external/head = GET_EXTERNAL_ORGAN(host, BP_HEAD)
		symbiote.host = host
		LAZYADD(head.implants, symbiote)
		symbiote.forceMove(head)
		if(!symbiote.host_brain)
			symbiote.host_brain = new(symbiote)
		symbiote.host_brain.SetName(host.real_name)
		symbiote.host_brain.real_name = host.real_name
	else
		to_chat(symbiote, SPAN_DANGER("There are no longer any hosts available, so you are being placed in a safe area."))
		if(length(global.symbiote_starting_points))
			symbiote.forceMove(pick(global.symbiote_starting_points))
		else
			symbiote.forceMove(get_random_spawn_turf(SPAWN_FLAG_JOBS_CAN_SPAWN))

	if(H.mind)
		H.mind.transfer_to(symbiote)
	else
		symbiote.key = H.key
	qdel(H)
	return symbiote

/datum/job/symbiote/equip_preview(var/mob/living/human/H, var/alt_title, var/datum/mil_branch/branch, var/datum/mil_rank/grade, var/additional_skips)
	if(!preview_slug)
		preview_slug = new
	H.appearance = preview_slug
	return TRUE

/datum/job/symbiote/proc/find_valid_hosts(var/just_checking)
	. = list()
	for(var/mob/living/human/H in global.player_list)
		if(H.stat == DEAD || !H.client || !H.ckey || !H.has_brain())
			continue
		var/obj/item/organ/external/head = GET_EXTERNAL_ORGAN(H, BP_HEAD)
		if(BP_IS_PROSTHETIC(head) || BP_IS_CRYSTAL(head) || head.has_growths())
			continue
		/*
		// F13 REMOVAL - NO BACKGROUNDS
		var/decl/background_detail/faction/symbiotic/background = H.get_background_datum_by_flag(BACKGROUND_FLAG_IDEOLOGY)
		if(!istype(background) || background.matches_to_role != type)
			continue
		*/
		. += H
		if(just_checking)
			return

/datum/job/symbiote/is_position_available()
	. = ..() && length(find_valid_hosts(TRUE))

/obj/abstract/landmark/symbiote_start
	name = "Symbiote Start"
	delete_me = TRUE

/obj/abstract/landmark/symbiote_start/Initialize()
	global.symbiote_starting_points |= get_turf(src)
	. = ..()

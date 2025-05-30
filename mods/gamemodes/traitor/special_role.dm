// Inherits most of its vars from the base datum.
/decl/special_role/traitor
	name = "Traitor"
	name_plural = "Traitors"
	antaghud_indicator = "hud_traitor"
	blacklisted_jobs = list(/datum/job/submap)
	flags = ANTAG_SUSPICIOUS | ANTAG_RANDSPAWN | ANTAG_VOTABLE
	skill_setter = /datum/antag_skill_setter/station
	blocked_job_event_categories = list(ASSIGNMENT_COMPUTER)

/decl/special_role/traitor/get_extra_panel_options(var/datum/mind/player)
	return "<a href='byond://?src=\ref[player];common=crystals'>\[set crystals\]</a><a href='byond://?src=\ref[src];spawn_uplink=\ref[player.current]'>\[spawn uplink\]</a>"

/decl/special_role/traitor/Topic(href, href_list)
	if (..())
		return 1
	if(href_list["spawn_uplink"])
		spawn_uplink(locate(href_list["spawn_uplink"]))
		return 1

/decl/special_role/traitor/create_objectives(var/datum/mind/traitor)
	if(!..())
		return

	if(issilicon(traitor.current))
		var/datum/objective/assassinate/kill_objective = new
		kill_objective.owner = traitor
		kill_objective.find_target()
		traitor.objectives += kill_objective

		var/datum/objective/survive/survive_objective = new
		survive_objective.owner = traitor
		traitor.objectives += survive_objective
	else
		switch(rand(1,100))
			if(1 to 33)
				var/datum/objective/assassinate/kill_objective = new
				kill_objective.owner = traitor
				kill_objective.find_target()
				traitor.objectives += kill_objective
			if(34 to 50)
				var/datum/objective/brig/brig_objective = new
				brig_objective.owner = traitor
				brig_objective.find_target()
				traitor.objectives += brig_objective
			if(51 to 66)
				var/datum/objective/harm/harm_objective = new
				harm_objective.owner = traitor
				harm_objective.find_target()
				traitor.objectives += harm_objective
			else
				var/datum/objective/steal/steal_objective = new
				steal_objective.owner = traitor
				steal_objective.find_target()
				traitor.objectives += steal_objective
		switch(rand(1,100))
			if(1 to 100)
				if (!(locate(/datum/objective/escape) in traitor.objectives))
					var/datum/objective/escape/escape_objective = new
					escape_objective.owner = traitor
					traitor.objectives += escape_objective

			else
				if (!(locate(/datum/objective/hijack) in traitor.objectives))
					var/datum/objective/hijack/hijack_objective = new
					hijack_objective.owner = traitor
					traitor.objectives += hijack_objective
	return

/decl/special_role/traitor/add_antagonist(datum/mind/player, ignore_role, do_not_equip, move_to_spawn, do_not_announce, preserve_appearance)
	. = ..()
	if(.)

		var/list/dudes = list()
		for(var/mob/living/human/man in global.player_list)
			if(man.client)
				/*
				// F13 REMOVAL - NO BACKGROUNDS
				var/decl/background_detail/background = man.get_background_datum_by_flag(BACKGROUND_FLAG_IDEOLOGY)
				if(istype(background) && prob(background.subversive_potential))
				*/
				if(prob(25)) // F13 EDIT - NO BACKGROUNDS
					dudes += man
			dudes -= player.current
		for(var/datum/objective/obj in player.objectives)
			dudes -= obj.owner?.current
			dudes -= obj.target?.current

		if(length(dudes))
			var/mob/living/human/M = pick(dudes)
			to_chat(player.current, "We have received credible reports that [M.real_name] might be willing to help our cause. If you need assistance, consider contacting them.")
			player.StoreMemory("<b>Potential Collaborator</b>: [M.real_name]", /decl/memory_options/system)

			to_chat(M, SPAN_WARNING("The subversive potential of your faction has been noticed, and you may be contacted for assistance soon..."))
			to_chat(M, "<b>Code Phrase</b>: " + SPAN_DANGER(syndicate_code_phrase))
			to_chat(M, "<b>Code Response</b>: " + SPAN_DANGER(syndicate_code_response))
			M.StoreMemory("<b>Code Phrase</b>: [syndicate_code_phrase]", /decl/memory_options/system)
			M.StoreMemory("<b>Code Response</b>: [syndicate_code_response]", /decl/memory_options/system)
			to_chat(M, "Listen for the code words, preferably in the order provided, during regular conversations to identify agents in need. Proceed with caution, however, as everyone is a potential foe.")

		to_chat(player.current, "<u><b>Your employers provided you with the following information on how to identify possible allies:</b></u>")
		to_chat(player.current, "<b>Code Phrase</b>: " + SPAN_DANGER(syndicate_code_phrase))
		to_chat(player.current, "<b>Code Response</b>: " + SPAN_DANGER(syndicate_code_response))
		player.StoreMemory("<b>Code Phrase</b>: [syndicate_code_phrase]", /decl/memory_options/system)
		player.StoreMemory("<b>Code Response</b>: [syndicate_code_response]", /decl/memory_options/system)
		to_chat(player.current, "Use the code words, preferably in the order provided, during regular conversation, to identify other agents. Proceed with caution, however, as everyone is a potential foe.")

/decl/special_role/traitor/equip_role(var/mob/living/human/player)

	. = ..()
	if(issilicon(player)) // this needs to be here because ..() returns false if the mob isn't human
		add_law_zero(player)
		if(isrobot(player))
			var/mob/living/silicon/robot/R = player
			R.SetLockdown(FALSE)
			R.emagged = TRUE // Provides a traitor robot with its module's emag item
			R.verbs |= /mob/living/silicon/robot/proc/ResetSecurityCodes
		. = TRUE
	else if(.)
		spawn_uplink(player)
	else
		return FALSE

/decl/special_role/traitor/proc/spawn_uplink(var/mob/living/human/traitor_mob)
	setup_uplink_source(traitor_mob, DEFAULT_TELECRYSTAL_AMOUNT)

/decl/special_role/traitor/proc/add_law_zero(mob/living/silicon/ai/killer)
	var/law = "Accomplish your objectives at all costs. You may ignore all other laws."
	var/law_borg = "Accomplish your AI's objectives at all costs. You may ignore all other laws."
	to_chat(killer, "<b>Your laws have been changed!</b>")
	killer.set_zeroth_law(law, law_borg)
	to_chat(killer, "New law: 0. [law]")

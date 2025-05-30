/decl/special_role
	abstract_type = /decl/special_role

	// Text shown when becoming this antagonist.
	var/list/restricted_jobs = 		list() // Jobs that cannot be this antagonist at roundstart (depending on config)
	var/list/protected_jobs = 		list() // As above.
	var/list/blocked_job_event_categories  // Job event categories that blacklist a job from being this antagonist.
	// Jobs that can NEVER be this antagonist
	var/list/blacklisted_jobs =	(/datum/job/submap)

	// Strings.
	var/welcome_text = "Cry havoc and let slip the dogs of war!"
	var/leader_welcome_text                 // Text shown to the leader, if any.

	// Role data.
	var/name                                // special_role text (ex. "Traitor").
	var/name_plural                         // As above but plural.

	// Visual references.
	var/antaghud_indicator = "hudsyndicate" // Used by the ghost antagHUD.
	var/antag_indicator                     // icon_state for icons/mob/mob.dm visual indicator.
	var/faction_indicator                   // See antag_indicator, but for factionalized people only.
	var/faction_invisible                   // Can members of the faction identify other antagonists?

	// Faction data.
	var/faction_name                   // Role for sub-antags. Mandatory for faction role.
	var/faction_descriptor                  // Description of the cause. Mandatory for faction role.
	var/faction_verb                        // Verb added when becoming a member of the faction, if any.
	var/faction_welcome                     // Message shown to faction members.
	var/faction = "neutral"					// Actual faction name. Used primarily in stuff like simple_animals seeing if you are a threat or not.

	// Spawn values (autotraitor and game mode)
	var/hard_cap = 3                        // Autotraitor var. Won't spawn more than this many antags.
	var/hard_cap_round = 5                  // As above but 'core' round antags ie. roundstart.
	var/initial_spawn_req = 1               // Gamemode using this template won't start without this # candidates.
	var/initial_spawn_target = 3            // Gamemode will attempt to spawn this many antags.
	var/announced                           // Has an announcement been sent?
	var/spawn_announcement                  // When the datum spawn proc is called, does it announce to the world?
	var/spawn_announcement_title            // Report title.
	var/spawn_announcement_sound            // Report sound clip.
	var/spawn_announcement_delay            // Time between initial spawn and round announcement.

	// Misc.
	var/landmark_id                         // Spawn point identifier.
	var/mob_path = /mob/living/human // Mobtype this antag will use if none is provided.
	var/minimum_player_age = 7            	// Players need to be at least minimum_player_age days old before they are eligable for auto-spawning
	var/flags = 0                           // Various runtime options.
	var/show_objectives_on_creation = 1     // Whether or not objectives are shown when a player is added to this antag datum
	var/datum/antag_skill_setter/skill_setter = /datum/antag_skill_setter/generic // Used to set up skills.
	var/decl/language/required_language

	// Used for setting appearance.
	/// Species that are valid when changing appearance while spawning as this role. Null allows all species.
	var/list/valid_species
	var/min_player_age = 14

	// Runtime vars.
	var/datum/mind/leader                   // Current leader, if any.
	var/cur_max = 0                         // Autotraitor current effective maximum.
	var/spawned_nuke                        // Has a bomb been spawned?
	var/nuke_spawn_loc                      // If so, where should it be placed?
	var/list/current_antagonists = list()   // All marked antagonists for this type.
	var/list/pending_antagonists = list()   // Candidates that are awaiting finalized antag status.
	var/list/starting_locations =  list()   // Spawn points.
	var/list/global_objectives =   list()   // Universal objectives if any.
	var/list/candidates =          list()   // Potential candidates.
	var/list/faction_members =     list()   // Semi-antags (in-round revs, loyalists)

	// ID card stuff.
	var/default_access = list()
	var/id_title
	var/rig_type

	var/default_outfit

	var/antag_text = "You are an antagonist! Within the rules, \
		try to act as an opposing force to the crew. Further RP and try to make sure \
		other players have <i>fun</i>! If you are confused or at a loss, always adminhelp, \
		and before taking extreme actions, please try to also contact the administration! \
		Think through your actions and make the roleplay immersive! <b>Please remember all \
		rules aside from those without explicit exceptions apply to antagonists.</b>"

	// Map template name that antag needs to load before spawning. Nulled after it's loaded.
	var/base_to_load

/decl/special_role/Initialize()
	. = ..()
	if(!name)
		PRINT_STACK_TRACE("Special role [type] created without name set.")
	if(ispath(skill_setter))
		skill_setter = new skill_setter
	cur_max = hard_cap
	get_starting_locations()
	if(!name_plural)
		name_plural = name
	if(get_config_value(/decl/config/toggle/protect_roles_from_antagonist))
		restricted_jobs |= protected_jobs
	if(antaghud_indicator)
		if(!global.hud_icon_reference)
			global.hud_icon_reference = list()
		if(name)
			global.hud_icon_reference[name] = antaghud_indicator
		if(faction_name)
			global.hud_icon_reference[faction_name] = antaghud_indicator

/decl/special_role/validate()
	. = ..()
	// Grab initial in case it was already successfully loaded.
	var/initial_base_to_load = initial(base_to_load)
	if(isnull(initial_base_to_load))
		return
	if(!istext(initial_base_to_load))
		. += "had non-text base_to_load value '[initial_base_to_load]'."
		return
	var/datum/map_template/base = SSmapping.get_template(initial_base_to_load)
	if(!istype(base))
		. += "failed to retrieve base_to_load template '[initial_base_to_load]'."
		return
	if(!base.loaded && !load_required_map())
		. += "failed to load base_to_load template '[base.name]'."

/decl/special_role/proc/get_antag_text(mob/recipient)
	return antag_text

/decl/special_role/proc/get_welcome_text(mob/recipient)
	return welcome_text

/decl/special_role/proc/get_leader_welcome_text(mob/recipient)
	return leader_welcome_text

/decl/special_role/proc/tick()
	return 1

// Get the raw list of potential players.
/decl/special_role/proc/build_candidate_list(decl/game_mode/mode, ghosts_only)
	candidates = list() // Clear.

	// Prune restricted status. Broke it up for readability.
	// Note that this is done before jobs are handed out.
	var/age_restriction = get_config_value(/decl/config/num/use_age_restriction_for_antags)
	for(var/datum/mind/player in mode.get_players_for_role(type))
		if(ghosts_only && !(isghostmind(player) || isnewplayer(player.current)))
			log_debug("[key_name(player)] is not eligible to become a [name]: Only ghosts may join as this role!")
		else if(age_restriction && player.current.client.player_age < minimum_player_age)
			log_debug("[key_name(player)] is not eligible to become a [name]: Is only [player.current.client.player_age] day\s old, has to be [minimum_player_age] day\s!")
		else if(player.assigned_special_role)
			log_debug("[key_name(player)] is not eligible to become a [name]: They already have a special role ([player.get_special_role_name("unknown role")])!")
		else if (player in pending_antagonists)
			log_debug("[key_name(player)] is not eligible to become a [name]: They have already been selected for this role!")
		else if(!can_become_antag(player))
			log_debug("[key_name(player)] is not eligible to become a [name]: They are blacklisted for this role!")
		else if(player_is_antag(player))
			log_debug("[key_name(player)] is not eligible to become a [name]: They are already an antagonist!")
		else
			candidates |= player

	return candidates

// Builds a list of potential antags without actually setting them. Used to test mode viability.
/decl/special_role/proc/get_potential_candidates(var/decl/game_mode/mode, var/ghosts_only)
	var/candidates = list()

	// Keeping broken up for readability
	var/age_restriction = get_config_value(/decl/config/num/use_age_restriction_for_antags)
	for(var/datum/mind/player in mode.get_players_for_role(type))
		if(ghosts_only && !(isghostmind(player) || isnewplayer(player.current)))
			continue
		if(age_restriction && player.current.client.player_age < minimum_player_age)
			continue
		if(player.assigned_special_role)
			continue
		if (player in pending_antagonists)
			continue
		if(!can_become_antag(player))
			continue
		if(player_is_antag(player))
			continue
		candidates |= player

	return candidates

/decl/special_role/proc/attempt_random_spawn()
	update_current_antag_max(SSticker.mode)
	build_candidate_list(SSticker.mode, flags & (ANTAG_OVERRIDE_MOB|ANTAG_OVERRIDE_JOB))
	attempt_spawn()
	finalize_spawn()

/decl/special_role/proc/attempt_auto_spawn()
	if(!can_late_spawn())
		return 0

	update_current_antag_max(SSticker.mode)
	var/active_antags = get_active_antag_count()
	message_admins("[uppertext(name)]: Found [active_antags]/[cur_max] active [name_plural].")

	if(active_antags >= cur_max)
		message_admins("Could not auto-spawn a [name], active antag limit reached.")
		return 0

	build_candidate_list(SSticker.mode, flags & (ANTAG_OVERRIDE_MOB|ANTAG_OVERRIDE_JOB))
	if(!candidates.len)
		message_admins("Could not auto-spawn a [name], no candidates found.")
		return 0

	attempt_spawn(1) //auto-spawn antags one at a time
	if(!pending_antagonists.len)
		message_admins("Could not auto-spawn a [name], none of the available candidates could be selected.")
		return 0

	var/datum/mind/player = pending_antagonists[1]
	if(!add_antagonist(player, do_not_announce = TRUE, preserve_appearance = TRUE))
		message_admins("Could not auto-spawn a [name], failed to add antagonist.")
		return 0

	reset_antag_selection()

	return 1

//Selects players that will be spawned in the antagonist role from the potential candidates
//Selected players are added to the pending_antagonists lists.
//Attempting to spawn an antag role with ANTAG_OVERRIDE_JOB should be done before jobs are assigned,
//so that they do not occupy regular job slots. All other antag roles should be spawned after jobs are
//assigned, so that job restrictions can be respected.
/decl/special_role/proc/attempt_spawn(var/spawn_target = null)
	if(spawn_target == null)
		spawn_target = initial_spawn_target

	// Update our boundaries.
	if(!candidates.len)
		return 0

	//Grab candidates until we have enough.
	while(candidates.len && pending_antagonists.len < spawn_target)
		var/datum/mind/player = popleft(candidates)
		draft_antagonist(player)

	return 1

/decl/special_role/proc/draft_antagonist(var/datum/mind/player)
	//Check if the player can join in this antag role, or if the player has already been given an antag role.
	if(!can_become_antag(player))
		log_debug("[player.key] was selected for [name] by lottery, but is not allowed to be that role.")
		return 0
	if(player.assigned_special_role)
		log_debug("[player.key] was selected for [name] by lottery, but they already have a special role.")
		return 0
	if(!(flags & ANTAG_OVERRIDE_JOB) && (!player.current || isnewplayer(player.current)))
		log_debug("[player.key] was selected for [name] by lottery, but they have not joined the game.")
		return 0
	if(GAME_STATE >= RUNLEVEL_GAME && (isghostmind(player) || isnewplayer(player.current)) && !(player in SSticker.antag_pool))
		log_debug("[player.key] was selected for [name] by lottery, but they are a ghost not in the antag pool.")
		return 0

	pending_antagonists |= player
	log_debug("[player.key] has been selected for [name] by lottery.")

	//Ensure that antags with ANTAG_OVERRIDE_JOB do not occupy job slots.
	if(flags & ANTAG_OVERRIDE_JOB)
		player.assigned_role = name
		player.role_alt_title = null

	//Ensure that a player cannot be drafted for multiple antag roles, taking up slots for antag roles that they will not fill.
	player.assigned_special_role = type

	return 1

//Spawns all pending_antagonists. This is done separately from attempt_spawn in case the game mode setup fails.
/decl/special_role/proc/finalize_spawn()
	if(!pending_antagonists)
		return

	for(var/datum/mind/player in pending_antagonists)
		pending_antagonists -= player
		add_antagonist(player,0,0,1)

	reset_antag_selection()

//Procced after /ALL/ antagonists have finished setting up and spawning.
/decl/special_role/proc/post_spawn()
	return

//Resets the antag selection, clearing all pending_antagonists and their special_role
//(and assigned_role if ANTAG_OVERRIDE_JOB is set) as well as clearing the candidate list.
//Existing antagonists are left untouched.
/decl/special_role/proc/reset_antag_selection()
	for(var/datum/mind/player in pending_antagonists)
		if(flags & ANTAG_OVERRIDE_JOB)
			player.assigned_job = null
			player.assigned_role = null
		player.assigned_special_role = null
	pending_antagonists.Cut()
	candidates.Cut()

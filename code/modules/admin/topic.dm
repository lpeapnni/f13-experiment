#define MAX_JOBBAN_CELLS 5

/datum/admins/Topic(href, href_list)
	..()

	if(usr.client != src.owner || !check_rights(0))
		log_admin("[key_name(usr)] tried to use the admin panel without authorization.")
		message_admins("[usr.key] has attempted to override the admin panel!")
		return

	if(SSticker.mode && SSticker.mode.round_status_topic(href, href_list))
		show_round_status()
		return

	if(href_list["dbsearchckey"] || href_list["dbsearchadmin"])

		var/adminckey = href_list["dbsearchadmin"]
		var/playerckey = href_list["dbsearchckey"]
		var/playerip = href_list["dbsearchip"]
		var/playercid = href_list["dbsearchcid"]
		var/dbbantype = text2num(href_list["dbsearchbantype"])
		var/match = 0

		if("dbmatch" in href_list)
			match = 1

		DB_ban_panel(playerckey, adminckey, playerip, playercid, dbbantype, match)
		return

	else if(href_list["dbbanedit"])
		var/banedit = href_list["dbbanedit"]
		var/banid = text2num(href_list["dbbanid"])
		if(!banedit || !banid)
			return

		DB_ban_edit(banid, banedit)
		return

	else if(href_list["dbbanaddtype"])

		var/bantype = text2num(href_list["dbbanaddtype"])
		var/banckey = href_list["dbbanaddckey"]
		var/banip = href_list["dbbanaddip"]
		var/bancid = href_list["dbbanaddcid"]
		var/banduration = text2num(href_list["dbbaddduration"])
		var/banjob = href_list["dbbanaddjob"]
		var/banreason = href_list["dbbanreason"]

		banckey = ckey(banckey)

		switch(bantype)
			if(BANTYPE_PERMA)
				if(!banckey || !banreason)
					to_chat(usr, "Not enough parameters (Requires ckey and reason)")
					return
				banduration = null
				banjob = null
			if(BANTYPE_TEMP)
				if(!banckey || !banreason || !banduration)
					to_chat(usr, "Not enough parameters (Requires ckey, reason and duration)")
					return
				banjob = null
			if(BANTYPE_JOB_PERMA)
				if(!banckey || !banreason || !banjob)
					to_chat(usr, "Not enough parameters (Requires ckey, reason and job)")
					return
				banduration = null
			if(BANTYPE_JOB_TEMP)
				if(!banckey || !banreason || !banjob || !banduration)
					to_chat(usr, "Not enough parameters (Requires ckey, reason and job)")
					return

		var/mob/playermob

		for(var/mob/M in global.player_list)
			if(M.ckey == banckey)
				playermob = M
				break


		banreason = "(MANUAL BAN) "+banreason

		if(!playermob)
			if(banip)
				banreason = "[banreason] (CUSTOM IP)"
			if(bancid)
				banreason = "[banreason] (CUSTOM CID)"
		else
			message_admins("Ban process: A mob matching [playermob.ckey] was found at location [playermob.x], [playermob.y], [playermob.z]. Custom ip and computer id fields replaced with the ip and computer id from the located mob")
		notes_add(banckey,banreason,usr)

		DB_ban_record(bantype, playermob, banduration, banreason, banjob, null, banckey, banip, bancid )

	else if(href_list["editrights"])
		if(!check_rights(R_PERMISSIONS))
			message_admins("[key_name_admin(usr)] attempted to edit the admin permissions without sufficient rights.")
			log_admin("[key_name(usr)] attempted to edit the admin permissions without sufficient rights.")
			return

		var/adm_ckey

		var/task = href_list["editrights"]
		if(task == "add")
			var/new_ckey = ckey(input(usr,"New admin's ckey","Admin ckey", null) as text|null)
			if(!new_ckey)	return
			if(new_ckey in admin_datums)
				to_chat(usr, SPAN_WARNING("Error: Topic 'editrights': [new_ckey] is already an admin"))
				return
			adm_ckey = new_ckey
			task = "rank"
		else if(task != "show")
			adm_ckey = ckey(href_list["ckey"])
			if(!adm_ckey)
				to_chat(usr, SPAN_WARNING("Error: Topic 'editrights': No valid ckey"))
				return

		var/datum/admins/D = admin_datums[adm_ckey]

		if(task == "remove")
			if(alert("Are you sure you want to remove [adm_ckey]?","Message","Yes","Cancel") == "Yes")
				if(!D)	return
				admin_datums -= adm_ckey
				D.disassociate()

				message_admins("[key_name_admin(usr)] removed [adm_ckey] from the admins list")
				log_admin("[key_name(usr)] removed [adm_ckey] from the admins list")
				log_admin_rank_modification(adm_ckey, "Removed")

		else if(task == "rank")
			var/new_rank
			if(admin_ranks.len)
				new_rank = input("Please select a rank", "New rank", null, null) as null|anything in (admin_ranks|"*New Rank*")
			else
				new_rank = input("Please select a rank", "New rank", null, null) as null|anything in list("Game Master","Game Admin", "Trial Admin", "Admin Observer","*New Rank*")

			var/rights = 0
			if(D)
				rights = D.rights
			switch(new_rank)
				if(null,"") return
				if("*New Rank*")
					new_rank = input("Please input a new rank", "New custom rank", null, null) as null|text
					if(get_config_value(/decl/config/toggle/on/admin_legacy_system))
						new_rank = ckeyEx(new_rank)
					if(!new_rank)
						to_chat(usr, SPAN_WARNING("Error: Topic 'editrights': Invalid rank"))
						return
					if(get_config_value(/decl/config/toggle/on/admin_legacy_system))
						if(admin_ranks.len)
							if(new_rank in admin_ranks)
								rights = admin_ranks[new_rank]		//we typed a rank which already exists, use its rights
							else
								admin_ranks[new_rank] = 0			//add the new rank to admin_ranks
				else
					if(get_config_value(/decl/config/toggle/on/admin_legacy_system))
						new_rank = ckeyEx(new_rank)
						rights = admin_ranks[new_rank]				//we input an existing rank, use its rights

			if(D)
				D.disassociate()								//remove adminverbs and unlink from client
				D.rank = new_rank								//update the rank
				D.rights = rights								//update the rights based on admin_ranks (default: 0)
			else
				D = new /datum/admins(new_rank, rights, adm_ckey)

			var/client/C = global.ckey_directory[adm_ckey]					//find the client with the specified ckey (if they are logged in)
			D.associate(C)											//link up with the client and add verbs

			to_chat(C, "[key_name_admin(usr)] has set your admin rank to: [new_rank].")
			message_admins("[key_name_admin(usr)] edited the admin rank of [adm_ckey] to [new_rank]")
			log_admin("[key_name(usr)] edited the admin rank of [adm_ckey] to [new_rank]")
			log_admin_rank_modification(adm_ckey, new_rank)

		else if(task == "permissions")
			if(!D)	return
			var/list/permissionlist = list()
			for(var/i=1, i<=R_MAXPERMISSION, i<<=1)		//that <<= is shorthand for i = i << 1. Which is a left BITSHIFT_LEFT
				permissionlist[rights2text(i)] = i
			var/new_permission = input("Select a permission to turn on/off", "Permission toggle", null, null) as null|anything in permissionlist
			if(!new_permission)	return
			D.rights ^= permissionlist[new_permission]

			var/client/C = global.ckey_directory[adm_ckey]
			to_chat(C, "[key_name_admin(usr)] has toggled your permission: [new_permission].")
			message_admins("[key_name_admin(usr)] toggled the [new_permission] permission of [adm_ckey]")
			log_admin("[key_name(usr)] toggled the [new_permission] permission of [adm_ckey]")
			log_admin_permission_modification(adm_ckey, permissionlist[new_permission])

		edit_admin_permissions()

	else if(href_list["call_shuttle"])

		if(!check_rights(R_ADMIN))	return

		if(!SSticker.mode || !SSevac.evacuation_controller)
			return

		if(SSticker.mode.name == "blob")
			alert("You can't call the shuttle during blob!")
			return

		switch(href_list["call_shuttle"])
			if("1")
				if (SSevac.evacuation_controller.call_evacuation(usr, TRUE))
					log_and_message_admins("called an evacuation.")
			if("2")
				if (SSevac.evacuation_controller.cancel_evacuation())
					log_and_message_admins("cancelled an evacuation.")

		href_list["secretsadmin"] = "show_round_status"

	else if(href_list["delay_round_end"])
		if(!check_rights(R_SERVER))	return

		SSticker.delay_end = !SSticker.delay_end
		log_and_message_admins("[SSticker.delay_end ? "delayed the round end" : "has made the round end normally"].")
		href_list["secretsadmin"] = "show_round_status"

	else if(href_list["simplemake"])

		if(!check_rights(R_SPAWN))	return

		var/mob/M = locate(href_list["mob"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		var/delmob = 0
		switch(alert("Delete old mob?","Message","Yes","No","Cancel"))
			if("Cancel")
				return
			if("Yes")
				delmob = TRUE

		var/transform_key = replacetext(href_list["simplemake"], "_", " ")
		if(M.try_rudimentary_transform(transform_key, delmob, href_list["species"]))
			log_and_message_admins("has used rudimentary transformation on [key_name_admin(M)]. Transforming to [transform_key]; deletemob=[delmob]")

	/////////////////////////////////////new ban stuff
	else if(href_list["unbanf"])
		if(!check_rights(R_BAN))	return

		var/banfolder = href_list["unbanf"]
		Banlist.cd = "/base/[banfolder]"
		var/key = Banlist["key"]
		if(alert(usr, "Are you sure you want to unban [key]?", "Confirmation", "Yes", "No") == "Yes")
			if(RemoveBan(banfolder))
				unbanpanel()
			else
				alert(usr, "This ban has already been lifted / does not exist.", "Error", "Ok")
				unbanpanel()

	else if(href_list["warn"])
		usr.client.warn(href_list["warn"])

	else if(href_list["unbane"])
		if(!check_rights(R_BAN))	return

		UpdateTime()
		var/reason

		var/banfolder = href_list["unbane"]
		Banlist.cd = "/base/[banfolder]"
		var/reason2 = Banlist["reason"]
		var/temp = Banlist["temp"]

		var/minutes = Banlist["minutes"]

		var/banned_key = Banlist["key"]
		Banlist.cd = "/base"

		var/duration

		switch(alert("Temporary Ban?",,"Yes","No"))
			if("Yes")
				temp = 1
				var/mins = 0
				if(minutes > CMinutes)
					mins = minutes - CMinutes
				mins = input(usr,"How long (in minutes)? (Default: 1440)","Ban time",mins ? mins : 1440) as num|null
				if(!mins)	return
				mins = min(525599,mins)
				minutes = CMinutes + mins
				duration = GetExp(minutes)
				reason = sanitize(input(usr,"Reason?","reason",reason2) as text|null)
				if(!reason)	return
			if("No")
				temp = 0
				duration = "Perma"
				reason = sanitize(input(usr,"Reason?","reason",reason2) as text|null)
				if(!reason)	return

		ban_unban_log_save("[key_name(usr)] edited [banned_key]'s ban. Reason: [reason] Duration: [duration]")
		log_and_message_admins("edited [banned_key]'s ban. Reason: [reason] Duration: [duration]")
		Banlist.cd = "/base/[banfolder]"
		to_savefile(Banlist, "reason",   reason)
		to_savefile(Banlist, "temp",     temp)
		to_savefile(Banlist, "minutes",  minutes)
		to_savefile(Banlist, "bannedby", usr.ckey)
		Banlist.cd = "/base"
		SSstatistics.add_field("ban_edit",1)
		unbanpanel()

	/////////////////////////////////////new ban stuff

	else if(href_list["jobban_panel_target"])
//		if(!check_rights(R_BAN))	return

		var/mob/M = locate(href_list["jobban_panel_target"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		if(!(LAST_CKEY(M)))	//sanity
			to_chat(usr, "This mob has no ckey")
			return

		var/dat = ""
		var/header = "<head><title>Job-Ban Panel: [M.name]</title></head>"
		var/body
		var/jobs = ""

	/***********************************WARNING!************************************
				      The jobban stuff looks mangled and disgusting
						      But it looks beautiful in-game
						                -Nodrak
	************************************WARNING!***********************************/
		var/counter = 0
		var/list/all_departments = decls_repository.get_decls_of_subtype(/decl/department)
		for(var/dtype in all_departments)
			var/decl/department/dept = all_departments[dtype]
			var/list/print_jobs = SSjobs.titles_by_department(dtype)
			jobs += "<table cellpadding='1' cellspacing='0' width='100%'>"
			jobs += "<tr align='center' bgcolor='[dept.display_color]'><th colspan='[length(print_jobs)]'><a href='byond://?src=\ref[src];jobban_category=[dept.name];jobban_mob_target=\ref[M]'>[capitalize(dept.name)] Positions</a></th></tr><tr align='center'>"
			for(var/jobPos in print_jobs)
				var/datum/job/job = SSjobs.get_by_title(jobPos)
				if(!job)
					continue
				if(jobban_isbanned(M, job.title))
					jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[job.title];jobban_mob_target=\ref[M]'><font color=red>[replacetext(job.title, " ", "&nbsp")]</font></a></td>"
					counter++
				else
					jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[job.title];jobban_mob_target=\ref[M]'>[replacetext(job.title, " ", "&nbsp")]</a></td>"
					counter++
				if(counter >= MAX_JOBBAN_CELLS)
					jobs += "</tr><tr>"
					counter = 0
			jobs += "</tr></table>"

	// Other non-human bans.
		counter = 0
		jobs += "<table cellpadding='1' cellspacing='0' width='100%'>"
		jobs += "<tr bgcolor='ccffcc'><th colspan='2><a href='byond://?src=\ref[src];jobban_category=miscnonhumanroles;jobban_mob_target=\ref[M]'>Other Positions</a></th></tr><tr align='center'>"
		if(jobban_isbanned(M, "pAI"))
			jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=pAI;jobban_mob_target=\ref[M]'><font color=red>pAI</font></a></td>"
		else
			jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=pAI;jobban_mob_target=\ref[M]'>pAI</a></td>"
		if(jobban_isbanned(M, "AntagHUD"))
			jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=AntagHUD;jobban_mob_target=\ref[M]'><font color=red>AntagHUD</font></a></td>"
		else
			jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=AntagHUD;jobban_mob_target=\ref[M]'>AntagHUD</a></td>"
		jobs += "</tr></table>"

	//Antagonist (Orange)
		jobs += "<table cellpadding='1' cellspacing='0' width='100%'>"
		jobs += "<tr bgcolor='ffeeaa'><th colspan='10'><a href='byond://?src=\ref[src];jobban_category=Syndicate;jobban_mob_target=\ref[M]'>Antagonist Positions</a></th></tr><tr align='center'>"

		// Antagonists.
		#define ANTAG_COLUMNS 5
		var/list/all_antag_types = decls_repository.get_decls_of_subtype(/decl/special_role)
		var/i = 1
		for(var/antag_type in all_antag_types)
			var/decl/special_role/antag = all_antag_types[antag_type]
			if(!antag)
				continue
			if(jobban_isbanned(M, antag.type))
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=\ref[antag];jobban_mob_target=\ref[M]'><font color=red>[replacetext("[antag.name]", " ", "&nbsp")]</font></a></td>"
			else
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=\ref[antag];jobban_mob_target=\ref[M]'>[replacetext("[antag.name]", " ", "&nbsp")]</a></td>"
			if(i % ANTAG_COLUMNS == 0 && i < length(all_antag_types))
				jobs += "</tr><tr align='center'>"
			i++
		jobs += "</tr></table>"
		#undef ANTAG_COLUMNS

		var/list/misc_roles = list("Botany Roles", "Graffiti")
		//Other roles  (BLUE, because I have no idea what other color to make this)
		jobs += "<table cellpadding='1' cellspacing='0' width='100%'>"
		jobs += "<tr bgcolor='ccccff'><th colspan='[LAZYLEN(misc_roles)]'>Other Roles</th></tr><tr align='center'>"
		for(var/entry in misc_roles)
			if(jobban_isbanned(M, entry))
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[entry];jobban_mob_target=\ref[M]'><font color=red>[entry]</font></a></td>"
			else
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[entry];jobban_mob_target=\ref[M]'>[entry]</a></td>"
		jobs += "</tr></table>"

	// Channels
		jobs += "<table cellpadding='1' cellspacing='0' width='100%'>"
		var/list/channels = decls_repository.get_decls_of_subtype(/decl/communication_channel)
		jobs += "<tr bgcolor='ccccff'><th colspan='[LAZYLEN(channels)]'>Channel Bans</th></tr><tr align='center'>"
		for(var/channel_type in channels)
			var/decl/communication_channel/channel = channels[channel_type]
			if(jobban_isbanned(M, channel.name))
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[channel.name];jobban_mob_target=\ref[M]'><font color=red>[channel.name]</font></a></td>"
			else
				jobs += "<td width='20%'><a href='byond://?src=\ref[src];jobban_category=[channel.name];jobban_mob_target=\ref[M]'>[channel.name]</a></td>"
		jobs += "</tr></table>"

	// Finalize and display.
		body = "<body>[jobs]</body>"
		dat = "<tt>[header][body]</tt>"
		show_browser(usr, dat, "window=jobban_panel_target;size=800x490")
		return

	//JOBBAN'S INNARDS
	else if(href_list["jobban_category"])
		if(!check_rights(R_MOD,0) && !check_rights(R_ADMIN,0))
			to_chat(usr, "<span class='warning'>You do not have the appropriate permissions to add job bans!</span>")
			return

		if(check_rights(R_MOD,0) && !check_rights(R_ADMIN,0) && !get_config_value(/decl/config/toggle/mods_can_job_tempban)) // If mod and tempban disabled
			to_chat(usr, "<span class='warning'>Mod jobbanning is disabled!</span>")
			return

		var/mob/M = locate(href_list["jobban_mob_target"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		if(M != usr)																//we can jobban ourselves
			if(M.client && M.client.holder && (M.client.holder.rights & R_BAN))		//they can ban too. So we can't ban them
				alert("You cannot perform this action. You must be of a higher administrative rank!")
				return

		//get jobs for department if specified, otherwise just returnt he one job in a list.
		var/list/job_list = list()
		var/decl/department/ban_dept = SSjobs.get_department_by_name(href_list["jobban_category"])
		if(ban_dept)
			for(var/jobPos in SSjobs.titles_by_department(ban_dept.type))
				var/datum/job/temp = SSjobs.get_by_title(jobPos)
				if(temp)
					job_list |= temp.title
		switch(href_list["jobban_category"])
			if("miscnonhumanroles")
				job_list |= "pAI"
			if("Syndicate")
				var/list/all_antag_types = decls_repository.get_decls_of_subtype(/decl/special_role)
				for(var/antagPos in all_antag_types)
					var/decl/special_role/temp = all_antag_types[antagPos]
					job_list |= temp.name
		if(!length(job_list))
			job_list += href_list["jobban_category"]

		//Create a list of unbanned jobs within job_list
		var/list/notbannedlist = list()
		for(var/job in job_list)
			if(!jobban_isbanned(M, job))
				notbannedlist += job

		//Banning comes first
		if(notbannedlist.len) //at least 1 unbanned job exists in job_list so we have stuff to ban.
			switch(alert("Temporary Ban?",,"Yes","No", "Cancel"))
				if("Yes")
					if(!check_rights(R_MOD,0) && !check_rights(R_BAN, 0))
						to_chat(usr, "<span class='warning'> You cannot issue temporary job-bans!</span>")
						return
					if(get_config_value(/decl/config/toggle/on/ban_legacy_system))
						to_chat(usr, "<span class='warning'>Your server is using the legacy banning system, which does not support temporary job bans. Consider upgrading. Aborting ban.</span>")
						return
					var/mins = input(usr,"How long (in minutes)?","Ban time",1440) as num|null
					if(!mins)
						return
					var/mod_job_tempban_max = get_config_value(/decl/config/num/mod_job_tempban_max)
					if(check_rights(R_MOD, 0) && !check_rights(R_BAN, 0) && mins > mod_job_tempban_max)
						to_chat(usr, "<span class='warning'> Moderators can only job tempban up to [mod_job_tempban_max] minutes!</span>")
						return
					var/reason = sanitize(input(usr,"Reason?","Please State Reason","") as text|null)
					if(!reason)
						return

					var/msg
					var/mins_readable = minutes_to_readable(mins)
					for(var/job in notbannedlist)
						ban_unban_log_save("[key_name(usr)] temp-jobbanned [key_name(M)] from [job] for [mins_readable]. reason: [reason]")
						log_admin("[key_name(usr)] temp-jobbanned [key_name(M)] from [job] for [mins_readable]")
						SSstatistics.add_field("ban_job_tmp",1)
						DB_ban_record(BANTYPE_JOB_TEMP, M, mins, reason, job)
						SSstatistics.add_field_details("ban_job_tmp","- [job]")
						jobban_fullban(M, job, "[reason]; By [usr.ckey] on [time2text(world.realtime)]") //Legacy banning does not support temporary jobbans.
						if(!msg)
							msg = job
						else
							msg += ", [job]"
					notes_add(LAST_CKEY(M), "Banned  from [msg] - [reason]", usr)
					message_admins("[key_name_admin(usr)] banned [key_name_admin(M)] from [msg] for [mins_readable]", 1)
					to_chat(M, "<span class='danger'>You have been jobbanned by [usr.client.ckey] from: [msg].</span>")
					to_chat(M, "<span class='warning'>The reason is: [reason]</span>")
					to_chat(M, "<span class='warning'>This jobban will be lifted in [mins_readable].</span>")
					href_list["jobban_panel_target"] = 1 // lets it fall through and refresh
					return 1
				if("No")
					if(!check_rights(R_BAN))  return
					var/reason = sanitize(input(usr,"Reason?","Please State Reason","") as text|null)
					if(reason)
						var/msg
						for(var/job in notbannedlist)
							ban_unban_log_save("[key_name(usr)] perma-jobbanned [key_name(M)] from [job]. reason: [reason]")
							log_admin("[key_name(usr)] perma-banned [key_name(M)] from [job]")
							SSstatistics.add_field("ban_job",1)
							DB_ban_record(BANTYPE_JOB_PERMA, M, -1, reason, job)
							SSstatistics.add_field_details("ban_job","- [job]")
							jobban_fullban(M, job, "[reason]; By [usr.ckey] on [time2text(world.realtime)]")
							if(!msg)	msg = job
							else		msg += ", [job]"
						notes_add(LAST_CKEY(M), "Banned  from [msg] - [reason]", usr)
						message_admins("[key_name_admin(usr)] banned [key_name_admin(M)] from [msg]", 1)
						to_chat(M, "<span class='danger'>You have been jobbanned by [usr.client.ckey] from: [msg].</span>")
						to_chat(M, "<span class='warning'>The reason is: [reason]</span>")
						to_chat(M, "<span class='warning'>Jobban can be lifted only upon request.</span>")
						href_list["jobban_panel_target"] = 1 // lets it fall through and refresh
						return 1
				if("Cancel")
					return

		//Unbanning job list
		//all jobs in job list are banned already OR we didn't give a reason (implying they shouldn't be banned)
		if(LAZYLEN(SSjobs.titles_to_datums)) //at least 1 banned job exists in job list so we have stuff to unban.
			if(!get_config_value(/decl/config/toggle/on/ban_legacy_system))
				to_chat(usr, "Unfortunately, database based unbanning cannot be done through this panel")
				DB_ban_panel(M.ckey)
				return
			var/msg
			for(var/job in SSjobs.titles_to_datums)
				var/reason = jobban_isbanned(M, job)
				if(!reason) continue //skip if it isn't jobbanned anyway
				switch(alert("Job: '[job]' Reason: '[reason]' Un-jobban?","Please Confirm","Yes","No"))
					if("Yes")
						ban_unban_log_save("[key_name(usr)] unjobbanned [key_name(M)] from [job]")
						log_admin("[key_name(usr)] unbanned [key_name(M)] from [job]")
						DB_ban_unban(M.ckey, BANTYPE_JOB_PERMA, job)
						SSstatistics.add_field("ban_job_unban",1)
						SSstatistics.add_field_details("ban_job_unban","- [job]")
						jobban_unban(M, job)
						if(!msg)	msg = job
						else		msg += ", [job]"
					else
						continue
			if(msg)
				message_admins("[key_name_admin(usr)] unbanned [key_name_admin(M)] from [msg]", 1)
				to_chat(M, "<span class='danger'>You have been un-jobbanned by [usr.client.ckey] from [msg].</span>")
				href_list["jobban_panel_target"] = 1 // lets it fall through and refresh
			return 1
		return 0 //we didn't do anything!

	else if(href_list["boot2"])
		var/mob/M = locate(href_list["boot2"])
		if (ismob(M))
			if(!check_if_greater_rights_than(M.client))
				return
			var/reason = sanitize(input("Please enter reason"))
			if(!reason)
				to_chat(M, SPAN_WARNING("You have been kicked from the server."))
			else
				to_chat(M, SPAN_WARNING("You have been kicked from the server: [reason]"))
			log_and_message_admins("booted [key_name_admin(M)].")
			//M.client = null
			qdel(M.client)

	else if(href_list["removejobban"])
		if(!check_rights(R_BAN))	return

		var/t = href_list["removejobban"]
		if(t)
			if((alert("Do you want to unjobban [t]?","Unjobban confirmation", "Yes", "No") == "Yes") && t) //No more misclicks! Unless you do it twice.
				log_and_message_admins("[key_name_admin(usr)] removed [t]")
				jobban_remove(t)
				href_list["ban"] = 1 // lets it fall through and refresh
				var/t_split = splittext(t, " - ")
				var/key = t_split[1]
				var/job = t_split[2]
				DB_ban_unban(ckey(key), BANTYPE_JOB_PERMA, job)

	else if(href_list["newban"])
		if(!check_rights(R_MOD,0) && !check_rights(R_BAN, 0))
			to_chat(usr, "<span class='warning'>You do not have the appropriate permissions to add bans!</span>")
			return

		if(check_rights(R_MOD,0) && !check_rights(R_ADMIN, 0) && !get_config_value(/decl/config/toggle/mods_can_job_tempban)) // If mod and tempban disabled
			to_chat(usr, "<span class='warning'>Mod jobbanning is disabled!</span>")
			return

		var/mob/M = locate(href_list["newban"])
		if(!ismob(M)) return

		if(M.client && M.client.holder)	return	//admins cannot be banned. Even if they could, the ban doesn't affect them anyway

		var/given_key = href_list["last_key"]
		if(!given_key)
			to_chat(usr, SPAN_DANGER("This mob has no known last occupant and cannot be banned."))
			return

		switch(alert("Temporary Ban?",,"Yes","No", "Cancel"))
			if("Yes")
				var/mins = input(usr,"How long (in minutes)?","Ban time",1440) as num|null
				if(!mins)
					return
				var/mod_tempban_max = get_config_value(/decl/config/num/mod_tempban_max)
				if(check_rights(R_MOD, 0) && !check_rights(R_BAN, 0) && mins > mod_tempban_max)
					to_chat(usr, "<span class='warning'>Moderators can only job tempban up to [mod_tempban_max] minutes!</span>")
					return
				if(mins >= 525600) mins = 525599
				var/reason = sanitize(input(usr,"Reason?","reason","Griefer") as text|null)
				if(!reason)
					return
				var/mob_key = LAST_CKEY(M)
				if(mob_key != given_key)
					to_chat(usr, SPAN_DANGER("This mob's occupant has changed from [given_key] to [mob_key]. Please try again."))
					show_player_panel(M)
					return
				AddBan(mob_key, M.computer_id, reason, usr.ckey, 1, mins)
				var/mins_readable = minutes_to_readable(mins)
				ban_unban_log_save("[usr.client.ckey] has banned [mob_key]. - Reason: [reason] - This will be removed in [mins_readable].")
				notes_add(mob_key,"[usr.client.ckey] has banned [mob_key]. - Reason: [reason] - This will be removed in [mins_readable].",usr)
				to_chat(M, "<span class='danger'>You have been banned by [usr.client.ckey].\nReason: [reason].</span>")
				to_chat(M, "<span class='warning'>This is a temporary ban, it will be removed in [mins_readable].</span>")
				SSstatistics.add_field("ban_tmp",1)
				DB_ban_record(BANTYPE_TEMP, M, mins, reason)
				SSstatistics.add_field("ban_tmp_mins",mins)
				var/banappeals = get_config_value(/decl/config/text/banappeals)
				if(banappeals)
					to_chat(M, "<span class='warning'>To try to resolve this matter head to [banappeals]</span>")
				else
					to_chat(M, "<span class='warning'>No ban appeals URL has been set.</span>")
				log_and_message_admins("has banned [mob_key].\nReason: [reason]\nThis will be removed in [mins_readable].")

				qdel(M.client)
				//qdel(M)	// See no reason why to delete mob. Important stuff can be lost. And ban can be lifted before round ends.
			if("No")
				if(!check_rights(R_BAN))   return
				var/reason = sanitize(input(usr,"Reason?","reason","Griefer") as text|null)
				if(!reason)
					return
				var/mob_key = LAST_CKEY(M)
				if(mob_key != given_key)
					to_chat(usr, SPAN_DANGER("This mob's occupant has changed from [given_key] to [mob_key]. Please try again."))
					show_player_panel(M)
					return
				switch(alert(usr,"IP ban?",,"Yes","No","Cancel"))
					if("Cancel")	return
					if("Yes")
						AddBan(mob_key, M.computer_id, reason, usr.ckey, 0, 0, M.lastKnownIP)
					if("No")
						AddBan(mob_key, M.computer_id, reason, usr.ckey, 0, 0)
				to_chat(M, "<span class='danger'>You have been banned by [usr.client.ckey].\nReason: [reason].</span>")
				to_chat(M, "<span class='warning'>This is a ban until appeal.</span>")
				var/banappeals = get_config_value(/decl/config/text/banappeals)
				if(banappeals)
					to_chat(M, "<span class='warning'>To try to resolve this matter head to [banappeals]</span>")
				else
					to_chat(M, "<span class='warning'>No ban appeals URL has been set.</span>")
				ban_unban_log_save("[usr.client.ckey] has permabanned [mob_key]. - Reason: [reason] - This is a ban until appeal.")
				notes_add(mob_key,"[usr.client.ckey] has permabanned [mob_key]. - Reason: [reason] - This is a ban until appeal.",usr)
				log_and_message_admins("has banned [mob_key].\nReason: [reason]\nThis is a ban until appeal.")
				SSstatistics.add_field("ban_perma",1)
				DB_ban_record(BANTYPE_PERMA, M, -1, reason)

				qdel(M.client)
				//qdel(M)
			if("Cancel")
				return

	else if(href_list["mute"])
		if(!check_rights(R_MOD,0) && !check_rights(R_ADMIN))  return

		var/mob/M = locate(href_list["mute"])
		if(!ismob(M))	return
		if(!M.client)	return

		var/mute_type = href_list["mute_type"]
		if(istext(mute_type))	mute_type = text2num(mute_type)
		if(!isnum(mute_type))	return

		cmd_admin_mute(M, mute_type)

	else if(href_list["c_mode"])
		if(!check_rights(R_ADMIN))	return

		if(SSticker.mode)
			return alert(usr, "The game has already started.", null, null, null, null)
		var/dat = {"<B>What mode do you wish to play?</B><HR>"}
		var/list/mode_names = get_config_value(/decl/config/lists/mode_names)
		for(var/mode in get_config_value(/decl/config/lists/mode_allowed))
			dat += {"<A href='byond://?src=\ref[src];c_mode2=[mode]'>[mode_names[mode]]</A><br>"}
		dat += {"<A href='byond://?src=\ref[src];c_mode2=secret'>Secret</A><br>"}
		dat += {"<A href='byond://?src=\ref[src];c_mode2=random'>Random</A><br>"}
		dat += {"Now: [SSticker.master_mode]"}
		show_browser(usr, dat, "window=c_mode")

	else if(href_list["f_secret"])
		if(!check_rights(R_ADMIN))	return

		if(SSticker.mode)
			return alert(usr, "The game has already started.", null, null, null, null)
		if(SSticker.master_mode != "secret")
			return alert(usr, "The game mode has to be secret!", null, null, null, null)
		var/dat = {"<B>What game mode do you want to force secret to be? Use this if you want to change the game mode, but want the players to believe it's secret. This will only work if the current game mode is secret.</B><HR>"}
		var/list/mode_names = get_config_value(/decl/config/lists/mode_names)
		for(var/mode in get_config_value(/decl/config/lists/mode_allowed))
			dat += {"<A href='byond://?src=\ref[src];f_secret2=[mode]'>[mode_names[mode]]</A><br>"}
		dat += {"<A href='byond://?src=\ref[src];f_secret2=secret'>Random (default)</A><br>"}
		dat += {"Now: [secret_force_mode]"}
		show_browser(usr, dat, "window=f_secret")

	else if(href_list["c_mode2"])
		if(!check_rights(R_ADMIN|R_SERVER))	return

		if (SSticker.mode)
			return alert(usr, "The game has already started.", null, null, null, null)
		SSticker.master_mode = href_list["c_mode2"]
		SSticker.bypass_gamemode_vote = 1
		log_and_message_admins("set the mode as [SSticker.master_mode].")
		to_world("<span class='notice'><b>The mode is now: [SSticker.master_mode]</b></span>")
		Game() // updates the main game menu
		world.save_mode(SSticker.master_mode)
		.(href, list("c_mode"=1))

	else if(href_list["f_secret2"])
		if(!check_rights(R_ADMIN|R_SERVER))	return

		if(SSticker.mode)
			return alert(usr, "The game has already started.", null, null, null, null)
		if(SSticker.master_mode != "secret")
			return alert(usr, "The game mode has to be secret!", null, null, null, null)
		secret_force_mode = href_list["f_secret2"]
		log_and_message_admins("set the forced secret mode as [secret_force_mode].")
		Game() // updates the main game menu
		.(href, list("f_secret"=1))

	else if(href_list["monkeyone"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/human/H = locate(href_list["monkeyone"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return

		log_and_message_admins("attempting to monkeyize [key_name_admin(H)]")
		H.monkeyize()

	else if(href_list["corgione"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/human/H = locate(href_list["corgione"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return

		log_and_message_admins("attempting to corgize [key_name_admin(H)]")
		H.corgize()

	else if(href_list["forcespeech"])
		if(!check_rights(R_FUN))	return

		var/mob/M = locate(href_list["forcespeech"])
		if(!ismob(M))
			to_chat(usr, "this can only be used on instances of type /mob")

		var/speech = input("What will [key_name(M)] say?.", "Force speech", "")// Don't need to sanitize, since it does that in say(), we also trust our admins.
		if(!speech)	return
		M.say(speech)
		speech = sanitize(speech) // Nah, we don't trust them
		log_and_message_admins("forced [key_name_admin(M)] to say: [speech]")

	else if(href_list["revive"])
		if(!check_rights(R_REJUVENATE))	return

		var/mob/living/L = locate(href_list["revive"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /mob/living")
			return

		if(get_config_value(/decl/config/toggle/on/admin_revive))
			L.revive()
			log_and_message_admins("healed/revived [key_name(L)]")
		else
			to_chat(usr, "Admin rejuvenates have been disabled")

	else if(href_list["makeai"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/human/H = locate(href_list["makeai"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return

		log_and_message_admins("AIized [key_name_admin(H)]!")
		H.AIize()

	else if(href_list["makerobot"])
		if(!check_rights(R_SPAWN))	return

		var/mob/living/human/H = locate(href_list["makerobot"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return

		usr.client.cmd_admin_robotize(H)

	else if(href_list["makeanimal"])
		if(!check_rights(R_SPAWN))	return

		var/mob/M = locate(href_list["makeanimal"])
		if(isnewplayer(M))
			to_chat(usr, "This cannot be used on instances of type /mob/new_player")
			return

		usr.client.cmd_admin_animalize(M)

	else if(href_list["adminplayeropts"])
		var/mob/M = locate(href_list["adminplayeropts"])
		show_player_panel(M)

	else if(href_list["adminplayerobservejump"])
		if(!check_rights(R_MOD|R_ADMIN))	return

		var/mob/M = locate(href_list["adminplayerobservejump"])
		var/client/C = usr.client
		if(!M)
			to_chat(C, "<span class='warning'>Unable to locate mob.</span>")
			return

		if(!isghost(usr))	C.admin_ghost()
		sleep(2)
		C.jumptomob(M)

	else if(href_list["adminplayerobservefollow"])
		if(!check_rights(R_MOD|R_ADMIN))
			return

		var/mob/M = locate(href_list["adminplayerobservefollow"])
		var/client/C = usr.client
		if(!M)
			to_chat(C, "<span class='warning'>Unable to locate mob.</span>")
			return

		if(!isobserver(usr))	C.admin_ghost()
		var/mob/observer/ghost/G = C.mob
		if(istype(G))
			sleep(2)
			G.ManualFollow(M)

	else if(href_list["show_round_status"])
		show_round_status()

	// call dibs on IC messages (prays, emergency comms, faxes)
	else if(href_list["take_ic"])

		var/mob/M = locate(href_list["take_question"])
		if(ismob(M))
			var/take_msg = "<span class='notice'><b>[key_name(usr.client)]</b> is attending to <b>[key_name(M)]'s</b> message.</span>"
			for(var/client/X in global.admins)
				if((R_ADMIN|R_MOD) & X.holder.rights)
					to_chat(X, take_msg)
			to_chat(M, "<span class='notice'><b>Your message is being attended to by [usr.client]. Thanks for your patience!</b></span>")
		else
			to_chat(usr, "<span class='warning'>Unable to locate mob.</span>")

	else if(href_list["take_ticket"])
		var/datum/ticket/ticket = locate(href_list["take_ticket"])

		if(isnull(ticket))
			return

		ticket.take(client_repository.get_lite_client(usr.client))

	else if(href_list["adminplayerobservecoodjump"])
		if(!check_rights(R_ADMIN))	return

		var/x = text2num(href_list["X"])
		var/y = text2num(href_list["Y"])
		var/z = text2num(href_list["Z"])

		var/client/C = usr.client
		if(!isghost(usr))	C.admin_ghost()
		sleep(2)
		C.jumptocoord(x,y,z)

	else if(href_list["adminchecklaws"])
		output_ai_laws()

	else if(href_list["adminmoreinfo"])
		var/mob/M = locate(href_list["adminmoreinfo"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob")
			return

		var/location_description = ""
		var/special_role_description = ""
		var/health_description = ""
		var/turf/T = get_turf(M)

		//Location
		if(isturf(T))
			if(isarea(T.loc))
				location_description = "([M.loc == T ? "at coordinates " : "in [M.loc] at coordinates "] [T.x], [T.y], [T.z] in area <b>[T.loc]</b>)"
			else
				location_description = "([M.loc == T ? "at coordinates " : "in [M.loc] at coordinates "] [T.x], [T.y], [T.z])"

		//Job + antagonist
		if(M.mind)
			special_role_description = "Role: <b>[M.mind.assigned_role]</b>; Antagonist: <font color='red'><b>[M.mind.get_special_role_name("unknown role")]</b></font>; Has been rev: [(M.mind.has_been_rev)?"Yes":"No"]"
		else
			special_role_description = "Role: <i>Mind datum missing</i> Antagonist: <i>Mind datum missing</i>; Has been rev: <i>Mind datum missing</i>;"

		//Health
		if(isliving(M))
			var/mob/living/L = M
			var/status
			switch (M.stat)
				if (0) status = "Alive"
				if (1) status = "<font color='orange'><b>Unconscious</b></font>"
				if (2) status = "<font color='red'><b>Dead</b></font>"
			health_description = "Status = [status]"
			health_description += "<BR>Oxy: [L.get_damage(OXY)] - Tox: [L.get_damage(TOX)] - Fire: [L.get_damage(BURN)] - Brute: [L.get_damage(BRUTE)] - Clone: [L.get_damage(CLONE)] - Brain: [L.get_damage(BRAIN)]"
		else
			health_description = "This mob type has no health to speak of."

		to_chat(src.owner, "<b>Info about [M.name]:</b> ")
		to_chat(src.owner, "Mob type = [M.type]; Gender = [M.gender] Damage = [health_description]")
		to_chat(src.owner, "Name = <b>[M.name]</b>; Real_name = [M.real_name]; Mind_name = [M.mind?"[M.mind.name]":""]; Key = <b>[M.key]</b>;")
		to_chat(src.owner, "Location = [location_description];")
		to_chat(src.owner, "[special_role_description]")
		to_chat(src.owner, "(<a href='byond://?src=\ref[usr];priv_msg=\ref[M]'>PM</a>) (<A HREF='byond://?src=\ref[src];adminplayeropts=\ref[M]'>PP</A>) (<A HREF='byond://?_src_=vars;Vars=\ref[M]'>VV</A>) ([admin_jump_link(M, src)]) (<A HREF='byond://?src=\ref[src];secretsadmin=show_round_status'>RS</A>)")

	else if(href_list["adminspawnprayreward"])
		if(!check_rights(R_ADMIN|R_FUN))	return

		var/mob/living/human/H = locate(href_list["adminspawnprayreward"])
		if(!ishuman(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return

		var/obj/item/C = new global.using_map.pray_reward_type(get_turf(H))
		H.put_in_hands(C)
		if(C.loc !=H)
			message_admins("[key_name(H)] has their hands full, so they did not receive their [C.name], spawned by [key_name(src.owner)].")
			qdel(C)
			return

		log_admin("[key_name(H)] got their [C.name], spawned by [key_name(src.owner)]")
		message_admins("[key_name(H)] got their [C.name], spawned by [key_name(src.owner)]")
		SSstatistics.add_field("admin_pray_rewards_spawned",1)
		to_chat(H, SPAN_NOTICE("Your prayers have been answered!! You received the <b>best [C.name]</b>!"))
		return

	else if(href_list["Artillery"])
		if(!check_rights(R_ADMIN|R_FUN))	return

		var/mob/living/M = locate(href_list["Artillery"])
		if(!isliving(M))
			to_chat(usr, "This can only be used on instances of type /mob/living")
			return

		if(alert(src.owner, "Are you sure you wish to hit [key_name(M)] with Blue Space Artillery?",  "Confirm Firing?" , "Yes" , "No") != "Yes")
			return

		if(BSACooldown)
			to_chat(src.owner, "Standby!  Reload cycle in progress!  Gunnary crews ready in five seconds!")
			return

		BSACooldown = 1
		spawn(50)
			BSACooldown = 0

		to_chat(M, "You've been hit by wormhole artillery!")
		log_admin("[key_name(M)] has been hit by wormhole artillery fired by [src.owner]")
		message_admins("[key_name(M)] has been hit by wormhole artillery fired by [src.owner]")

		var/obj/effect/stop/S
		S = new /obj/effect/stop(M.loc)
		S.victim = M
		spawn(20)
			qdel(S)

		var/turf/floor/T = get_turf(M)
		if(istype(T))
			if(prob(80))	T.break_tile_to_plating()
			else			T.break_tile()

		if(M.current_health == 1)
			M.gib()
		else
			M.take_damage(min(99, M.current_health - 1))
			SET_STATUS_MAX(M, STAT_STUN, 20)
			SET_STATUS_MAX(M, STAT_WEAK, 20)
			M.set_status(STAT_STUTTER, 20)

	else if(href_list["CentcommReply"])
		var/mob/living/L = locate(href_list["CentcommReply"])
		if(!istype(L))
			to_chat(usr, "This can only be used on instances of type /mob/living/")
			return

		if(L.can_centcom_reply())
			var/input = sanitize(input(src.owner, "Please enter a message to reply to [key_name(L)] via their headset.","Outgoing message from Centcomm", ""))
			if(!input)		return

			to_chat(src.owner, "You sent [input] to [L] via a secure channel.")
			log_admin("[src.owner] replied to [key_name(L)]'s Centcomm message with the message [input].")
			message_admins("[src.owner] replied to [key_name(L)]'s Centcom message with: \"[input]\"")
			if(!isAI(L))
				to_chat(L, "<span class='info'>You hear something crackle in your headset for a moment before a voice speaks.</span>")
			to_chat(L, "<span class='info'>Please stand by for a message from Central Command.</span>")
			to_chat(L, "<span class='info'>Message as follows.</span>")
			to_chat(L, "<span class='notice'>[input]</span>")
			to_chat(L, "<span class='info'>Message ends.</span>")
		else
			to_chat(src.owner, "The person you are trying to contact does not have functional radio equipment.")


	else if(href_list["SyndicateReply"])
		var/mob/living/human/H = locate(href_list["SyndicateReply"])
		if(!istype(H))
			to_chat(usr, "This can only be used on instances of type /mob/living/human")
			return
		var/obj/item/l_ear = H.get_equipped_item(slot_l_ear_str)
		var/obj/item/r_ear = H.get_equipped_item(slot_r_ear_str)
		if(!istype(l_ear, /obj/item/radio/headset) && !istype(r_ear, /obj/item/radio/headset))
			to_chat(usr, "The person you are trying to contact is not wearing a headset")
			return

		var/input = sanitize(input(src.owner, "Please enter a message to reply to [key_name(H)] via their headset.","Outgoing message from a shadowy figure...", ""))
		if(!input)	return

		to_chat(src.owner, "You sent [input] to [H] via a secure channel.")
		log_admin("[src.owner] replied to [key_name(H)]'s illegal message with the message [input].")
		to_chat(H, "You hear something crackle in your headset for a moment before a voice speaks.  \"Please stand by for a message from your benefactor.  Message as follows, agent. <b>\"[input]\"</b>  Message ends.\"")

	else if(href_list["AdminFaxView"])
		var/obj/item/fax = locate(href_list["AdminFaxView"])
		if (istype(fax, /obj/item/paper))
			var/obj/item/paper/P = fax
			P.interact(usr, TRUE, admin_interact = TRUE)
		else if (istype(fax, /obj/item/photo))
			var/obj/item/photo/H = fax
			H.interact(usr)
		else if (istype(fax, /obj/item/paper_bundle))
			//having multiple people turning pages on a paper_bundle can cause issues
			//open a browse window listing the contents instead
			var/data = ""
			var/obj/item/paper_bundle/B = fax

			for (var/page = 1, page <= B.pages.len, page++)
				var/obj/pageobj = B.pages[page]
				data += "<A href='byond://?src=\ref[src];AdminFaxViewPage=[page];paper_bundle=\ref[B]'>Page [page] - [pageobj.name]</A><BR>"

			show_browser(usr, data, "window=[B.name]")
		else
			to_chat(usr, "<span class='warning'>The faxed item is not viewable. This is probably a bug, and should be reported on the tracker: [fax.type]</span>")
	else if (href_list["AdminFaxViewPage"])
		var/page = text2num(href_list["AdminFaxViewPage"])
		var/obj/item/paper_bundle/bundle = locate(href_list["paper_bundle"])

		if (!bundle) return

		if (istype(bundle.pages[page], /obj/item/paper))
			var/obj/item/paper/P = bundle.pages[page]
			P.interact(src.owner, TRUE)
		else if (istype(bundle.pages[page], /obj/item/photo))
			var/obj/item/photo/H = bundle.pages[page]
			H.interact(src.owner)
		return

	else if(href_list["FaxReply"])
		var/mob/sender = locate(href_list["FaxReply"])
		var/obj/machinery/faxmachine/fax = locate(href_list["originfax"])
		var/replyorigin = href_list["replyorigin"]

		var/obj/item/paper/admin/P = new /obj/item/paper/admin
		faxreply = P
		P.admindatum = src
		P.origin = replyorigin
		P.destination_ref = weakref(fax)
		P.sender = sender
		P.adminbrowse()

	else if(href_list["jumpto"])
		if(!check_rights(R_ADMIN))	return

		var/mob/M = locate(href_list["jumpto"])
		usr.client.jumptomob(M)

	else if(href_list["getmob"])
		if(!check_rights(R_ADMIN))	return

		if(alert(usr, "Confirm?", "Message", "Yes", "No") != "Yes")	return
		var/mob/M = locate(href_list["getmob"])
		usr.client.Getmob(M)

	else if(href_list["sendmob"])
		if(!check_rights(R_ADMIN))	return

		var/mob/M = locate(href_list["sendmob"])
		usr.client.sendmob(M)

	else if(href_list["narrateto"])
		if(!check_rights(R_INVESTIGATE))	return

		var/mob/M = locate(href_list["narrateto"])
		usr.client.cmd_admin_direct_narrate(M)

	else if(href_list["show_special_roles"])
		if(!check_rights(R_ADMIN|R_MOD))	return

		if(GAME_STATE < RUNLEVEL_GAME)
			alert("The game hasn't started yet!")
			return

		var/mob/M = locate(href_list["show_special_roles"])
		if(!ismob(M))
			to_chat(usr, "This can only be used on instances of type /mob.")
			return
		show_special_roles(M)

	else if(href_list["skillpanel"])
		if(!check_rights(R_INVESTIGATE))
			return

		if(GAME_STATE < RUNLEVEL_GAME)
			alert("The game hasn't started yet!")
			return

		var/mob/M = locate(href_list["skillpanel"])
		show_skills(M)

	else if(href_list["create_object"])
		if(!check_rights(R_SPAWN))	return
		return create_object(usr)

	else if(href_list["quick_create_object"])
		if(!check_rights(R_SPAWN))	return
		return quick_create_object(usr)

	else if(href_list["create_turf"])
		if(!check_rights(R_SPAWN))	return
		return create_turf(usr)

	else if(href_list["create_mob"])
		if(!check_rights(R_SPAWN))	return
		return create_mob(usr)

	else if(href_list["object_list"])			//this is the laggiest thing ever
		if(!check_rights(R_SPAWN))	return

		if(!get_config_value(/decl/config/toggle/on/admin_spawning))
			to_chat(usr, "Spawning of items is not allowed.")
			return

		var/atom/loc = usr.loc

		var/dirty_paths
		if (istext(href_list["object_list"]))
			dirty_paths = list(href_list["object_list"])
		else if (istype(href_list["object_list"], /list))
			dirty_paths = href_list["object_list"]

		var/paths = list()
		var/removed_paths = list()

		for(var/dirty_path in dirty_paths)
			var/path = text2path(dirty_path)
			if(!path)
				removed_paths += dirty_path
				continue
			else if(!ispath(path, /obj) && !ispath(path, /turf) && !ispath(path, /mob))
				removed_paths += dirty_path
				continue
			paths += path

		if(!paths)
			alert("The path list you sent is empty")
			return
		if(length(paths) > 5)
			alert("Select fewer object types, (max 5)")
			return
		else if(length(removed_paths))
			alert("Removed:\n" + jointext(removed_paths, "\n"))

		var/list/offset = splittext(href_list["offset"],",")
		var/number = clamp(text2num(href_list["object_count"]), 1, 100)
		var/X = offset.len > 0 ? text2num(offset[1]) : 0
		var/Y = offset.len > 1 ? text2num(offset[2]) : 0
		var/Z = offset.len > 2 ? text2num(offset[3]) : 0
		var/tmp_dir = href_list["object_dir"]
		var/obj_dir = tmp_dir ? text2num(tmp_dir) : 2
		if(!obj_dir || !(obj_dir in list(1,2,4,8,5,6,9,10)))
			obj_dir = 2
		var/obj_name = sanitize(href_list["object_name"])
		var/where = href_list["object_where"]
		if (!( where in list("onfloor","inhand","inmarked") ))
			where = "onfloor"

		if( where == "inhand" )
			to_chat(usr, "Support for inhand not available yet. Will spawn on floor.")
			where = "onfloor"

		if ( where == "inhand" )	//Can only give when human or monkey
			if ( !( ishuman(usr) || issmall(usr) ) )
				to_chat(usr, "Can only spawn in hand when you're a human or a monkey.")
				where = "onfloor"
			else if ( usr.get_active_held_item() )
				to_chat(usr, "Your active hand is full. Spawning on floor.")
				where = "onfloor"

		if ( where == "inmarked" )
			var/marked_datum = marked_datum()
			if ( !marked_datum )
				to_chat(usr, "You don't have any object marked. Abandoning spawn.")
				return
			else
				if ( !istype(marked_datum,/atom) )
					to_chat(usr, "The object you have marked cannot be used as a target. Target must be of type /atom. Abandoning spawn.")
					return

		var/atom/target //Where the object will be spawned
		switch ( where )
			if ( "onfloor" )
				switch (href_list["offset_type"])
					if ("absolute")
						target = locate(0 + X,0 + Y,0 + Z)
					if ("relative")
						target = locate(loc.x + X,loc.y + Y,loc.z + Z)
			if ( "inmarked" )
				target = marked_datum()

		if(target)
			for (var/path in paths)
				for (var/i = 0; i < number; i++)
					if(path in typesof(/turf))
						var/turf/O = target
						var/turf/N = O.ChangeTurf(path)
						if(N)
							if(obj_name)
								N.SetName(obj_name)
					else
						var/atom/O = new path(target)
						if(O)
							O.set_dir(obj_dir)
							if(obj_name)
								O.SetName(obj_name)
								if(ismob(O))
									var/mob/M = O
									M.real_name = obj_name

		log_and_message_admins("created [number] [english_list(paths)] at ([target.x],[target.y],[target.z])")
		return

	else if(href_list["admin_secrets_panel"])
		var/datum/admin_secret_category/AC = locate(href_list["admin_secrets_panel"]) in admin_secrets.categories
		src.Secrets(AC)

	else if(href_list["admin_secrets"])
		var/datum/admin_secret_item/item = locate(href_list["admin_secrets"]) in admin_secrets.items
		item.execute(usr)

	else if(href_list["ac_view_wanted"])            //Admin newscaster Topic() stuff be here
		src.admincaster_screen = 18                 //The ac_ prefix before the hrefs stands for AdminCaster.
		src.access_news_network()

	else if(href_list["ac_set_channel_name"])
		src.admincaster_feed_channel.channel_name = sanitize_safe(input(usr, "Provide a Feed Channel Name", "Network Channel Handler", ""))
		src.access_news_network()

	else if(href_list["ac_set_channel_lock"])
		src.admincaster_feed_channel.locked = !src.admincaster_feed_channel.locked
		src.access_news_network()

	else if(href_list["ac_submit_new_channel"])
		var/check = 0
		for(var/datum/feed_channel/FC in news_network.network_channels)
			if(FC.channel_name == src.admincaster_feed_channel.channel_name)
				check = 1
				break
		if(src.admincaster_feed_channel.channel_name == "" || src.admincaster_feed_channel.channel_name == "\[REDACTED\]" || check )
			src.admincaster_screen=7
		else
			var/choice = alert("Please confirm Feed channel creation","Network Channel Handler","Confirm","Cancel")
			if(choice=="Confirm")
				news_network.CreateFeedChannel(admincaster_feed_channel.channel_name, admincaster_signature, admincaster_feed_channel.locked, 1)
				SSstatistics.add_field("newscaster_channels",1)                  //Adding channel to the global network
				log_admin("[key_name_admin(usr)] created command feed channel: [src.admincaster_feed_channel.channel_name]!")
				src.admincaster_screen=5
		src.access_news_network()

	else if(href_list["ac_set_channel_receiving"])
		var/list/available_channels = list()
		for(var/datum/feed_channel/F in news_network.network_channels)
			available_channels += F.channel_name
		src.admincaster_feed_channel.channel_name = sanitize_safe(input(usr, "Choose receiving Feed Channel", "Network Channel Handler") in available_channels )
		src.access_news_network()

	else if(href_list["ac_set_new_message"])
		src.admincaster_feed_message.body = sanitize(input(usr, "Write your Feed story", "Network Channel Handler", ""))
		src.access_news_network()

	else if(href_list["ac_submit_new_message"])
		if(src.admincaster_feed_message.body =="" || src.admincaster_feed_message.body =="\[REDACTED\]" || src.admincaster_feed_channel.channel_name == "" )
			src.admincaster_screen = 6
		else
			SSstatistics.add_field("newscaster_stories",1)
			news_network.SubmitArticle(src.admincaster_feed_message.body, src.admincaster_signature, src.admincaster_feed_channel.channel_name, null, 1)
			src.admincaster_screen=4

		log_admin("[key_name_admin(usr)] submitted a feed story to channel: [src.admincaster_feed_channel.channel_name]!")
		src.access_news_network()

	else if(href_list["ac_create_channel"])
		src.admincaster_screen=2
		src.access_news_network()

	else if(href_list["ac_create_feed_story"])
		src.admincaster_screen=3
		src.access_news_network()

	else if(href_list["ac_menu_censor_story"])
		src.admincaster_screen=10
		src.access_news_network()

	else if(href_list["ac_menu_censor_channel"])
		src.admincaster_screen=11
		src.access_news_network()

	else if(href_list["ac_menu_wanted"])
		var/already_wanted = 0
		if(news_network.wanted_issue)
			already_wanted = 1

		if(already_wanted)
			src.admincaster_feed_message.author = news_network.wanted_issue.author
			src.admincaster_feed_message.body = news_network.wanted_issue.body
		src.admincaster_screen = 14
		src.access_news_network()

	else if(href_list["ac_set_wanted_name"])
		src.admincaster_feed_message.author = sanitize(input(usr, "Provide the name of the Wanted person", "Network Security Handler", ""))
		src.access_news_network()

	else if(href_list["ac_set_wanted_desc"])
		src.admincaster_feed_message.body = sanitize(input(usr, "Provide the a description of the Wanted person and any other details you deem important", "Network Security Handler", ""))
		src.access_news_network()

	else if(href_list["ac_submit_wanted"])
		var/input_param = text2num(href_list["ac_submit_wanted"])
		if(src.admincaster_feed_message.author == "" || src.admincaster_feed_message.body == "")
			src.admincaster_screen = 16
		else
			var/choice = alert("Please confirm Wanted Issue [(input_param==1) ? ("creation.") : ("edit.")]","Network Security Handler","Confirm","Cancel")
			if(choice=="Confirm")
				if(input_param==1)          //If input_param == 1 we're submitting a new wanted issue. At 2 we're just editing an existing one. See the else below
					var/datum/feed_message/WANTED = new /datum/feed_message
					WANTED.author = src.admincaster_feed_message.author               //Wanted name
					WANTED.body = src.admincaster_feed_message.body                   //Wanted desc
					WANTED.backup_author = src.admincaster_signature                  //Submitted by
					WANTED.is_admin_message = 1
					news_network.wanted_issue = WANTED
					for(var/obj/machinery/newscaster/NEWSCASTER in allCasters)
						NEWSCASTER.newsAlert()
						NEWSCASTER.update_icon()
					src.admincaster_screen = 15
				else
					news_network.wanted_issue.author = src.admincaster_feed_message.author
					news_network.wanted_issue.body = src.admincaster_feed_message.body
					news_network.wanted_issue.backup_author = src.admincaster_feed_message.backup_author
					src.admincaster_screen = 19
				log_admin("[key_name_admin(usr)] issued a Wanted Notification for [src.admincaster_feed_message.author]!")
		src.access_news_network()

	else if(href_list["ac_cancel_wanted"])
		var/choice = alert("Please confirm Wanted Issue removal","Network Security Handler","Confirm","Cancel")
		if(choice=="Confirm")
			news_network.wanted_issue = null
			for(var/obj/machinery/newscaster/NEWSCASTER in allCasters)
				NEWSCASTER.update_icon()
			src.admincaster_screen=17
		src.access_news_network()

	else if(href_list["ac_censor_channel_author"])
		var/datum/feed_channel/FC = locate(href_list["ac_censor_channel_author"])
		if(FC.author != "<B>\[REDACTED\]</B>")
			FC.backup_author = FC.author
			FC.author = "<B>\[REDACTED\]</B>"
		else
			FC.author = FC.backup_author
		src.access_news_network()

	else if(href_list["ac_censor_channel_story_author"])
		var/datum/feed_message/MSG = locate(href_list["ac_censor_channel_story_author"])
		if(MSG.author != "<B>\[REDACTED\]</B>")
			MSG.backup_author = MSG.author
			MSG.author = "<B>\[REDACTED\]</B>"
		else
			MSG.author = MSG.backup_author
		src.access_news_network()

	else if(href_list["ac_censor_channel_story_body"])
		var/datum/feed_message/MSG = locate(href_list["ac_censor_channel_story_body"])
		if(MSG.body != "<B>\[REDACTED\]</B>")
			MSG.backup_body = MSG.body
			MSG.body = "<B>\[REDACTED\]</B>"
		else
			MSG.body = MSG.backup_body
		src.access_news_network()

	else if(href_list["ac_pick_d_notice"])
		var/datum/feed_channel/FC = locate(href_list["ac_pick_d_notice"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen=13
		src.access_news_network()

	else if(href_list["ac_toggle_d_notice"])
		var/datum/feed_channel/FC = locate(href_list["ac_toggle_d_notice"])
		FC.censored = !FC.censored
		src.access_news_network()

	else if(href_list["ac_view"])
		src.admincaster_screen=1
		src.access_news_network()

	else if(href_list["ac_setScreen"]) //Brings us to the main menu and resets all fields~
		src.admincaster_screen = text2num(href_list["ac_setScreen"])
		if (src.admincaster_screen == 0)
			if(src.admincaster_feed_channel)
				src.admincaster_feed_channel = new /datum/feed_channel
			if(src.admincaster_feed_message)
				src.admincaster_feed_message = new /datum/feed_message
		src.access_news_network()

	else if(href_list["ac_show_channel"])
		var/datum/feed_channel/FC = locate(href_list["ac_show_channel"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen = 9
		src.access_news_network()

	else if(href_list["ac_pick_censor_channel"])
		var/datum/feed_channel/FC = locate(href_list["ac_pick_censor_channel"])
		src.admincaster_feed_channel = FC
		src.admincaster_screen = 12
		src.access_news_network()

	else if(href_list["ac_refresh"])
		src.access_news_network()

	else if(href_list["ac_set_signature"])
		src.admincaster_signature = sanitize(input(usr, "Provide your desired signature", "Network Identity Handler", ""))
		src.access_news_network()

	else if(href_list["vsc"])
		if(check_rights(R_ADMIN|R_SERVER))
			if(href_list["vsc"] == "airflow")
				vsc.ChangeSettingsDialog(usr,vsc.settings)
			if(href_list["vsc"] == "contam")
				vsc.ChangeSettingsDialog(usr,vsc.contaminant_control.settings)
			if(href_list["vsc"] == "default")
				vsc.SetDefault(usr)

	else if(href_list["toglang"])
		if(check_rights(R_SPAWN))
			var/mob/M = locate(href_list["toglang"])
			if(!istype(M))
				to_chat(usr, "[M] is illegal type, must be /mob!")
				return
			var/decl/language/L = locate(href_list["lang"])
			if(istype(L))
				if(L in M.languages)
					if(!M.remove_language(L.type))
						to_chat(usr, "Failed to remove language '[L.name]' from \the [M]!")
				else
					if(!M.add_language(L.type))
						to_chat(usr, "Failed to add language '[L.name]' to \the [M]!")
			else
				to_chat(usr, "Failed to toggle unknown language on \the [M]!")

			show_player_panel(M)

	// player info stuff

	if(href_list["add_player_info"])
		var/key = href_list["add_player_info"]
		var/add = sanitize(input("Add Player Info") as null|text)
		if(!add) return

		notes_add(key,add,usr)
		show_player_info(key)

	if(href_list["remove_player_info"])
		var/key = href_list["remove_player_info"]
		var/index = text2num(href_list["remove_index"])

		notes_del(key, index)
		show_player_info(key)

	if(href_list["notes"])
		if(href_list["notes"] == "set_filter")
			var/choice = input(usr,"Please specify a text filter to use or cancel to clear.","Player Notes",null) as text|null
			PlayerNotesPage(choice)
		else
			var/ckey = href_list["ckey"]
			if(!ckey)
				var/mob/M = locate(href_list["mob"])
				if(ismob(M))
					ckey = LAST_CKEY(M)
			show_player_info(ckey)
		return

	if(href_list["setstaffwarn"])
		var/mob/M = locate(href_list["setstaffwarn"])
		if(!ismob(M)) return

		if(M.client && M.client.holder) return // admins don't get staffnotify'd about

		switch(alert("Really set staff warn?",,"Yes","No"))
			if("Yes")
				var/last_ckey = LAST_CKEY(M)
				var/reason = sanitize(input(usr,"Staff warn message","Staff Warn","Problem Player") as text|null)
				if (!reason || reason == "")
					return
				notes_add(last_ckey,"\[AUTO\] Staff warn enabled: [reason]",usr)
				reason += "\n-- Set by [usr.client.ckey]([usr.client.holder.rank])"
				DB_staffwarn_record(last_ckey, reason)
				if(M.client)
					M.client.staffwarn = reason
				SSstatistics.add_field("staff_warn",1)
				log_and_message_admins("has enabled staffwarn on [last_ckey].\nMessage: [reason]\n")
				show_player_panel(M)
			if("No")
				return

	if(href_list["removestaffwarn"])
		var/mob/M = locate(href_list["removestaffwarn"])
		if(!ismob(M)) return

		switch(alert("Really remove staff warn?",,"Yes","No"))
			if("Yes")
				var/last_ckey = LAST_CKEY(M)
				if(!DB_staffwarn_remove(last_ckey))
					return
				notes_add(last_ckey,"\[AUTO\] Staff warn disabled",usr)
				if(M.client)
					M.client.staffwarn = null
				log_and_message_admins("has removed the staffwarn on [last_ckey].\n")
				show_player_panel(M)
			if("No")
				return

	if(href_list["pilot"])
		var/mob/M = locate(href_list["pilot"])
		if(!ismob(M)) return

		show_player_panel(M)

	if(href_list["asf_pick_fax"])
		var/obj/machinery/faxmachine/F = locate(href_list["destination"])
		if(istype(F))
			close_browser(src.owner, "faxpicker")
			var/datum/extension/network_device/D = get_extension(F, /datum/extension/network_device)
			if(!D)
				log_debug("'[log_info_line(F)]' couldn't get network_device extension!")
				return
			var/datum/computer_network/CN = D.get_network()
			if(CN)
				var/obj/item/paper/admin/P = new /obj/item/paper/admin
				faxreply      = P //Store the message instance
				P.admindatum  = src
				P.origin      = href_list["sender"] || (input(src.owner, "Please specify the sender's name", "Origin", global.using_map.boss_name) as text | null)
				P.destination_ref = weakref(F)
				P.adminbrowse()
			else
				log_debug("Couldn't get computer network for [log_info_line(D)], where network_id is '[D.network_id]'.")
		else
			log_debug("Tried to send a fax to an invalid machine!:[log_info_line(F)]\nhref:[log_info_line(href_list)]")

	if(href_list["toggle_mutation"])
		var/mob/M = locate(href_list["toggle_mutation"])
		var/decl/genetic_condition/condition = locate(href_list["block"])
		if(istype(condition) && istype(M) && !QDELETED(M))
			var/result
			var/had_condition
			if(M.has_genetic_condition(condition.type))
				had_condition = TRUE
				result = M.remove_genetic_condition(condition.type)
			else
				had_condition = FALSE
				result = M.add_genetic_condition(condition.type)
			if(!isnull(result))
				if(result)
					if(had_condition)
						log_debug("Removed genetic condition [condition.name] from \the [M] ([M.ckey]).")
					else
						log_debug("Added genetic condition [condition.name] to \the [M] ([M.ckey]).")
				else
					log_debug("Failed to toggle genetic condition [condition.name] on \the [M] ([M.ckey]).")
			else
				log_debug("Could not apply genetic condition [condition.name] to \the [M] ([M.ckey]).")
			show_player_panel(M)
		return

/mob/living/proc/can_centcom_reply()
	return 0

/mob/living/human/can_centcom_reply()
	for(var/slot in global.ear_slots)
		var/obj/item/radio/headset/radio = get_equipped_item(slot)
		if(istype(radio))
			return TRUE

/mob/living/silicon/ai/can_centcom_reply()
	return silicon_radio != null && !check_unable(2)

/datum/proc/extra_admin_link(var/prefix, var/sufix, var/short_links)
	return list()

/atom/movable/extra_admin_link(var/source, var/prefix, var/sufix, var/short_links)
	return list("<A HREF='byond://?[source];adminplayerobservefollow=\ref[src]'>[prefix][short_links ? "J" : "JMP"][sufix]</A>")

/client/extra_admin_link(source, var/prefix, var/sufix, var/short_links)
	return mob ? mob.extra_admin_link(source, prefix, sufix, short_links) : list()

/mob/extra_admin_link(var/source, var/prefix, var/sufix, var/short_links)
	. = ..()
	if(client && eyeobj)
		. += "<A HREF='byond://?[source];adminplayerobservefollow=\ref[eyeobj]'>[prefix][short_links ? "E" : "EYE"][sufix]</A>"

/mob/observer/ghost/extra_admin_link(var/source, var/prefix, var/sufix, var/short_links)
	. = ..()
	if(mind && (mind.current && !isghost(mind.current)))
		. += "<A HREF='byond://?[source];adminplayerobservefollow=\ref[mind.current]'>[prefix][short_links ? "B" : "BDY"][sufix]</A>"

/proc/admin_jump_link(var/datum/target, var/source, var/delimiter = "|", var/prefix, var/sufix, var/short_links)
	if(!istype(target))
		CRASH("Invalid admin jump link target: [log_info_line(target)]")
	// The way admin jump links handle their src is weirdly inconsistent...
	if(istype(source, /datum/admins))
		source = "src=\ref[source]"
	else
		source = "_src_=holder"
	return jointext(target.extra_admin_link(source, prefix, sufix, short_links), delimiter)

/datum/proc/get_admin_jump_link(var/atom/target)
	return

/mob/get_admin_jump_link(var/atom/target, var/delimiter, var/prefix, var/sufix)
	return client && client.get_admin_jump_link(target, delimiter, prefix, sufix)

/client/get_admin_jump_link(var/atom/target, var/delimiter, var/prefix, var/sufix)
	if(holder)
		var/short_links = get_preference_value(/datum/client_preference/ghost_follow_link_length) == PREF_SHORT
		return admin_jump_link(target, src, delimiter, prefix, sufix, short_links)

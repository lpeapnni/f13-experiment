/datum/map/f13
	default_job_type = /datum/job/f13
	default_department_type = /decl/department/f13
	id_hud_icons = 'maps/f13/hud.dmi'

/datum/job/f13
	title = "Tourist"
	total_positions = -1
	spawn_positions = -1
	supervisors = "your conscience"
	description = "You need to goof off, have fun, and be silly."
	economic_power = 1
	access = list()
	minimal_access = list()
	outfit_type = /decl/outfit/job/tourist
	department_types = list(
		/decl/department/f13
		)

/decl/outfit/job/tourist
	name = "Job - Testing Site Tourist"

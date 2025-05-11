// Muh macro redefined
#define EVAC_STATE_IDLE 0
#define EVAC_STATE_PREPPING 1
#define EVAC_STATE_LAUNCHING 2
#define EVAC_STATE_IN_TRANSIT 3
#define EVAC_STATE_COOLDOWN 4
#define EVAC_STATE_COMPLETE 5

/datum/evacuation_controller/no_shuttle
	name = "no escape controller"
	evac_prep_delay = 1 MINUTES

/datum/evacuation_controller/no_shuttle/can_cancel()
	return 0

/datum/evacuation_controller/no_shuttle/call_evacuation(var/mob/user, var/_emergency_evac, var/forced, var/skip_announce = FALSE, var/autotransfer)
	if(state != EVAC_STATE_IDLE)
		return 0

	if(!can_evacuate(user, forced))
		return 0

	evac_called_at = world.time
	evac_ready_time = evac_called_at + evac_prep_delay

	state = EVAC_STATE_PREPPING

	if(!skip_announce)
		global.using_map.emergency_shuttle_called_announcement()

	return 1

/datum/evacuation_controller/no_shuttle/process()
	if(state == EVAC_STATE_PREPPING && recall && world.time >= auto_recall_time)
		cancel_evacuation()
		return

	if(state == EVAC_STATE_PREPPING)
		if(world.time >= evac_ready_time)
			finish_evacuation()
	else if(state == EVAC_STATE_COOLDOWN)
		if(world.time >= evac_cooldown_time)
			state = EVAC_STATE_IDLE

#undef EVAC_STATE_IDLE
#undef EVAC_STATE_PREPPING
#undef EVAC_STATE_LAUNCHING
#undef EVAC_STATE_IN_TRANSIT
#undef EVAC_STATE_COOLDOWN
#undef EVAC_STATE_COMPLETE
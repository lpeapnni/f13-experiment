
/decl/emote/visible/tail
	abstract_type = /decl/emote/visible/tail

/decl/emote/visible/tail/mob_can_use(mob/living/user, assume_available = FALSE)
	return istype(user) && ..()

/*
// F13 REMOVAL - 4 SPRITES FOR A SINGLE TAIL IS FUCKING INSANE
/decl/emote/visible/tail/swish
	key = "swish"

/decl/emote/visible/tail/swish/do_emote(mob/living/user)
	user.animate_tail_once()
	return TRUE
*/

/decl/emote/visible/tail/wag
	key = "wag"

/decl/emote/visible/tail/wag/do_emote(mob/living/user)
	user.animate_tail_start()
	return TRUE

/*
// F13 REMOVAL
/decl/emote/visible/tail/sway
	key = "sway"

/decl/emote/visible/tail/sway/do_emote(mob/living/user)
	user.animate_tail_start()
	return TRUE

/decl/emote/visible/tail/qwag
	key = "qwag"

/decl/emote/visible/tail/qwag/do_emote(mob/living/user)
	user.animate_tail_fast()
	return TRUE

/decl/emote/visible/tail/fastsway
	key = "fastsway"

/decl/emote/visible/tail/fastsway/do_emote(mob/living/user)
	user.animate_tail_fast()
	return TRUE

/decl/emote/visible/tail/swag
	key = "swag"

/decl/emote/visible/tail/swag/do_emote(mob/living/user)
	user.set_tail_animation_state(null, TRUE)
	return TRUE

/decl/emote/visible/tail/stopsway
	key = "stopsway"

/decl/emote/visible/tail/stopsway/do_emote(mob/living/user)
	user.set_tail_animation_state(null, TRUE)
	return TRUE
*/

// F13 EDIT START
/decl/emote/visible/tail/stopwag
	key = "stopwag"

/decl/emote/visible/tail/stopwag/do_emote(mob/living/user)
	user.set_tail_animation_state(null, TRUE)
	return TRUE
// F13 EDIT END

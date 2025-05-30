/datum/spellbound_type
	var/name = "Stuff"
	var/desc = "spells n shit"
	var/equipment = list()
	var/spells = list()

/datum/spellbound_type/proc/spawn_servant(var/atom/a, var/mob/master, var/mob/user)
	set waitfor = 0
	var/mob/living/human/H = new(a)
	H.ckey = user.ckey
	H.change_appearance(APPEARANCE_GENDER|APPEARANCE_BODY|APPEARANCE_EYE_COLOR|APPEARANCE_HAIR|APPEARANCE_FACIAL_HAIR|APPEARANCE_HAIR_COLOR|APPEARANCE_FACIAL_HAIR_COLOR|APPEARANCE_SKIN)

	var/obj/item/implant/translator/natural/I = new()
	I.implant_in_mob(H, BP_HEAD)
	if (length(master.languages))
		var/decl/language/lang = master.languages[1]
		H.add_language(lang.type)
		H.set_default_language(lang.type)
		I.languages[lang.name] = 1

	modify_servant(equip_servant(H), H)
	set_antag(H.mind, master)
	var/name_choice = sanitize(input(H, "Choose a name. If you leave this blank, it will be defaulted to your current characters.", "Name change") as null|text, MAX_NAME_LEN)
	if(name_choice)
		H.SetName(name_choice)
		H.real_name = name_choice

/datum/spellbound_type/proc/equip_servant(var/mob/living/human/H)
	for(var/stype in spells)
		var/spell/S = new stype()
		if(S.spell_flags & NEEDSCLOTHES)
			S.spell_flags &= ~NEEDSCLOTHES
		H.add_spell(S)
	. = list()
	for(var/etype in equipment)
		var/obj/item/I = new etype(get_turf(H))
		if(istype(I, /obj/item/clothing))
			I.canremove = 0
		H.equip_to_slot_if_possible(I,equipment[etype],0,1,1,1)
		. += I

/datum/spellbound_type/proc/set_antag(var/datum/mind/M, var/mob/master)
	return

/datum/spellbound_type/proc/modify_servant(var/list/items, var/mob/living/human/H)
	return

/datum/spellbound_type/apprentice
	name = "Apprentice"
	desc = "Summon your trusty apprentice, equipped with their very own spellbook."
	equipment = list(/obj/item/clothing/head/wizard = slot_head_str,
					/obj/item/clothing/jumpsuit/lightpurple = slot_w_uniform_str,
					/obj/item/clothing/shoes/sandal = slot_shoes_str,
					/obj/item/staff = BP_R_HAND,
					/obj/item/book/spell/apprentice = BP_L_HAND,
					/obj/item/clothing/suit/wizrobe = slot_wear_suit_str)
	spells = list(/spell/noclothes)

/datum/spellbound_type/apprentice/set_antag(var/datum/mind/M, var/mob/master)
	var/decl/special_role/wizard/wizards = GET_DECL(/decl/special_role/wizard)
	wizards.add_antagonist_mind(M, 1, "Wizard's Apprentice", "<b>You are an apprentice-type Servant! You're just an ordinary Wizard-To-Be, with no special abilities, but do not need robes to cast spells. Follow your teacher's orders!</b>")

/datum/spellbound_type/servant
	var/spiel = "You don't do anything in particular."

/datum/spellbound_type/servant/set_antag(var/datum/mind/M, var/mob/master)
	var/decl/special_role/wizard/wizards = GET_DECL(/decl/special_role/wizard)
	wizards.add_antagonist_mind(M, 1, "Spellbound Servant", "<b>You are a [name]-type Servant!</b> [spiel]")

/datum/spellbound_type/servant/caretaker
	name = "Caretaker"
	desc = "A healer, a medic, a shoulder to cry on. This servant will heal you, even from near death."
	spiel = "<i>'The last enemy that will be destroyed is death.'</i> You can perceive any injuries with simple sight, and heal them with the Trance spell; potentially even reversing death itself! However, this comes at a price; Trance will become increasingly harder to use as you use it, until you can use it no longer. Be cautious, and aid your Master in any way possible!"
	equipment = list(/obj/item/clothing/costume/caretaker = slot_w_uniform_str,
					/obj/item/clothing/shoes/dress/caretakershoes = slot_shoes_str)
	spells = list(/spell/toggle_armor/caretaker,
				/spell/targeted/heal_target/touch,
				/spell/aoe_turf/knock/slow,
				/spell/targeted/heal_target/area/slow,
				/spell/targeted/analyze,
				/spell/targeted/heal_target/trance
				)

/datum/spellbound_type/servant/champion
	name = "Champion"
	desc = "A knight in shining armor; a warrior, a protector, and a loyal friend."
	spiel = "Your sword and armor are second to none, but you have no unique supernatural powers beyond summoning the sword to your hands. Protect your Master with your life!"
	equipment = list(
		/obj/item/clothing/pants/champion = slot_w_uniform_str,
		/obj/item/clothing/shoes/jackboots/medievalboots = slot_shoes_str
	)
	spells = list(
		/spell/toggle_armor/champion,
		/spell/toggle_armor/excalibur
	)

/datum/spellbound_type/servant/familiar
	name = "Familiar"
	desc = "A friend! Or are they a pet? They can transform into animals, and take some particular traits from said creatures."
	spiel = "This form of yours is weak in comparison to your transformed form, but that certainly won't pose a problem, considering the fact that you have an alternative. Whatever it is you can turn into, use its powers wisely and serve your Master as well as possible!"
	equipment = list(
		/obj/item/clothing/head/bandana/familiarband = slot_head_str,
		/obj/item/clothing/pants/familiar = slot_w_uniform_str
	)

/datum/spellbound_type/servant/familiar/modify_servant(var/list/equipment, var/mob/living/human/H)
	var/familiar_type
	switch(input(H,"Choose your desired animal form:", "Form") as anything in list("Space Pike", "Mouse", "Cat", "Bear"))
		if("Space Pike")
			H.add_genetic_condition(GENE_COND_NO_BREATH)
			H.add_genetic_condition(GENE_COND_SPACE_RESISTANCE)
			familiar_type = /mob/living/simple_animal/hostile/carp/pike
		if("Mouse")
			H.verbs |= /mob/living/proc/ventcrawl
			familiar_type = /mob/living/simple_animal/passive/mouse
		if("Cat")
			H.add_genetic_condition(GENE_COND_RUNNING)
			familiar_type = /mob/living/simple_animal/passive/cat
		if("Bear")
			familiar_type = /mob/living/simple_animal/hostile/bear
	var/spell/targeted/shapeshift/familiar/F = new()
	F.possible_transformations = list(familiar_type)
	H.add_spell(F)

/datum/spellbound_type/servant/fiend
	name = "Fiend"
	desc = "A practitioner of dark and evil magics, almost certainly a demon, and possibly a lawyer."
	spiel = "The Summoning Ritual has bound you to this world with limited access to your infernal powers; you'll have to be strategic in how you use them. Follow your Master's orders as well as you can!"
	spells = list(/spell/targeted/projectile/dumbfire/fireball/firebolt,
				/spell/targeted/ethereal_jaunt,
				/spell/targeted/torment,
				/spell/area_teleport,
				/spell/hand/charges/blood_shard
				)

/datum/spellbound_type/servant/fiend/equip_servant(var/mob/living/human/H)
	if(H.gender == MALE)
		equipment = list(/obj/item/clothing/costume/fiendsuit = slot_w_uniform_str,
						/obj/item/clothing/shoes/dress/devilshoes = slot_shoes_str)
		spells += /spell/toggle_armor/fiend
	else
		equipment = list(/obj/item/clothing/dress/devil = slot_w_uniform_str,
					/obj/item/clothing/shoes/dress/devilshoes = slot_shoes_str)
		spells += /spell/toggle_armor/fiend/fem
	..()

/datum/spellbound_type/servant/infiltrator
	name = "Infiltrator"
	desc = "A spy and a manipulator to the end, capable of hiding in plain sight and falsifying information to your heart's content."
	spiel = "On the surface, you are a completely normal person, but is that really all you are? People are so easy to fool, do as your Master says, and do it with style!"
	spells = list(
		/spell/toggle_armor/infil_items,
		/spell/targeted/exude_pleasantness,
		/spell/targeted/genetic/blind/hysteria
	)

/datum/spellbound_type/servant/infiltrator/equip_servant(var/mob/living/human/H)
	if(H.gender == MALE)
		equipment = list(/obj/item/clothing/pants/slacks/outfit/tie = slot_w_uniform_str,
						/obj/item/clothing/shoes/dress/infilshoes = slot_shoes_str)
		spells += /spell/toggle_armor/infiltrator
	else
		equipment = list(/obj/item/clothing/dress/white = slot_w_uniform_str,
					/obj/item/clothing/shoes/dress/infilshoes = slot_shoes_str)
		spells += /spell/toggle_armor/infiltrator/fem
	..()

/datum/spellbound_type/servant/overseer
	name = "Overseer"
	desc = "A ghost, or an imaginary friend; the Overseer is immune to space and can turn invisible at a whim, but has little offensive capabilities."
	spiel = "Physicality is not something you are familiar with. Indeed, injuries cannot slow you down, but you can't fight back, either! In addition to this, you can reach into the void and return the soul of a single departed crewmember via the revoke death verb, if so desired; this can even revive your Master, should they fall in combat before you do. Serve them well."
	equipment = list(
		/obj/item/clothing/pants/casual/blackjeans/outfit = slot_w_uniform_str,
		/obj/item/clothing/suit/jacket/hoodie/grim        = slot_wear_suit_str,
		/obj/item/clothing/shoes/sandal/grimboots         = slot_shoes_str,
		/obj/item/contract/wizard/xray                    = BP_L_HAND,
		/obj/item/contract/wizard/telepathy               = BP_R_HAND
	)
	spells = list(
		/spell/toggle_armor/overseer,
		/spell/targeted/ethereal_jaunt,
		/spell/invisibility,
		/spell/targeted/revoke
	)

/datum/spellbound_type/servant/overseer/equip_servant(var/mob/living/human/H)
	..()
	H.add_aura(new /obj/aura/regenerating(H))

/obj/effect/cleanable/spellbound
	name = "strange rune"
	desc = "some sort of runic symbol drawn in... crayon?"
	icon = 'icons/obj/rune.dmi'
	icon_state = "spellbound"
	is_spawnable_type = FALSE // invalid without spell_type passed
	var/datum/spellbound_type/stype
	var/last_called = 0

/obj/effect/cleanable/spellbound/Initialize(mapload, var/spell_type)
	. = ..(mapload)
	stype = new spell_type()

/obj/effect/cleanable/spellbound/attack_hand(var/mob/user)
	SHOULD_CALL_PARENT(FALSE)
	if(last_called > world.time)
		return TRUE
	last_called = world.time + 30 SECONDS
	var/decl/ghosttrap/G = GET_DECL(/decl/ghosttrap/wizard_familiar)
	for(var/mob/observer/ghost/ghost in global.player_list)
		if(G.assess_candidate(ghost,null,FALSE))
			to_chat(ghost, "[SPAN_NOTICE("<b>A wizard is requesting a Spell-Bound Servant!</b>")] (<a href='byond://?src=\ref[src];master=\ref[user]'>Join</a>)")
	return TRUE

/obj/effect/cleanable/spellbound/CanUseTopic(var/mob)
	if(isliving(mob))
		return STATUS_CLOSE
	return STATUS_INTERACTIVE

/obj/effect/cleanable/spellbound/OnTopic(var/mob/user, href_list, state)
	if(href_list["master"])
		var/mob/master = locate(href_list["master"])
		stype.spawn_servant(get_turf(src),master,user)
		qdel(src)
	return TOPIC_HANDLED

/obj/effect/cleanable/spellbound/Destroy()
	qdel(stype)
	stype = null
	return ..()

/obj/item/summoning_stone
	name = "summoning stone"
	desc = "a small non-descript stone of dubious origin."
	icon = 'icons/obj/items/summoning_stone.dmi'
	icon_state = "stone"
	throw_speed = 5
	throw_range = 10
	w_class = ITEM_SIZE_SMALL
	material = /decl/material/solid/stone/basalt

/obj/item/summoning_stone/attack_self(var/mob/user)
	if(isAdminLevel(user.z))
		to_chat(user, "<span class='warning'>You cannot use \the [src] here.</span>")
		return
	user.set_machine(src)
	interact(user)

/obj/item/summoning_stone/interact(var/mob/user)
	var/list/types = subtypesof(/datum/spellbound_type) - /datum/spellbound_type/servant
	var/decl/special_role/wizard/wizards = GET_DECL(/decl/special_role/wizard)
	if(user.mind && !wizards.is_antagonist(user.mind))
		use_type(pick(types),user)
		return
	var/dat = "<center><b><h3>Summoning Stone</h3></b><i>Choose a companion to help you.</i><br><br></center>"
	for(var/type in types)
		var/datum/spellbound_type/SB = type
		dat += "<br><a href='byond://?src=\ref[src];type=[type]'>[initial(SB.name)]</a> - [initial(SB.desc)]"
	show_browser(user,dat,"window=summoning")
	onclose(user,"summoning")

/obj/item/summoning_stone/proc/use_type(var/type, var/mob/user)
	new /obj/effect/cleanable/spellbound(get_turf(src),type)
	if(prob(20))
		var/list/base_areas = maintlocs //Have to do it this way as its a macro
		var/list/pareas = base_areas.Copy()
		while(pareas.len)
			var/a = pick(pareas)
			var/area/picked_area = pareas[a]
			pareas -= a
			var/list/turfs = get_area_turfs(picked_area)
			for(var/t in turfs)
				var/turf/T = t
				if(T.density)
					turfs -= T
			if(turfs.len)
				src.visible_message("<span class='notice'>\The [src] vanishes!</span>")
				src.forceMove(pick(turfs))
	show_browser(user, null, "window=summoning")
	qdel(src)

/obj/item/summoning_stone/OnTopic(user, href_list, state)
	if(href_list["type"])
		use_type(href_list["type"],user)
	return TOPIC_HANDLED
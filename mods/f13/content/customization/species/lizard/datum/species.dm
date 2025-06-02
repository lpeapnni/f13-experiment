/decl/butchery_data/humanoid/lizard
	meat_name = "lizard"
	skin_material = /decl/material/solid/organic/skin/lizard

/decl/species/lizard
	name = SPECIES_LIZARD
	name_plural = SPECIES_LIZARD
	butchery_data = /decl/butchery_data/humanoid/lizard

	available_bodytypes = list(
		/decl/bodytype/lizard,
		/decl/bodytype/lizard/masculine
	)
	unarmed_attacks = list(
		/decl/natural_attack/stomp,
		/decl/natural_attack/tail,
		/decl/natural_attack/claws,
		/decl/natural_attack/punch,
		/decl/natural_attack/bite/sharp
	)

	available_accessory_categories = list(
		SAC_HORNS,
		SAC_FRILLS,
		SAC_COSMETICS,
		SAC_MARKINGS,
		SAC_TAIL
	)

	primitive_form = "Stok"
	gluttonous = GLUT_TINY
	strength = STR_HIGH
	breath_pressure = 18
	brute_mod = 0.8
	blood_volume = 800

	hunger_factor = DEFAULT_HUNGER_FACTOR * 2
	thirst_factor = DEFAULT_THIRST_FACTOR * 2

	body_temperature = null // cold-blooded, implemented the same way nabbers do it

	description = "A heavily reptillian species. They prefer warmer temperatures than most species and \
	their native tongue is a heavy hissing laungage."

	spawn_flags = SPECIES_CAN_JOIN | SPECIES_NO_ROBOTIC_INTERNAL_ORGANS

	flesh_color = "#34af10"
	// organs_icon = 'mods/species/bayliens/unathi/icons/organs.dmi'

	preview_outfit = /decl/outfit/job/generic/doctor

	blood_types = list(
		/decl/blood_type/reptile/splus,
		/decl/blood_type/reptile/sminus,
		/decl/blood_type/reptile/xplus,
		/decl/blood_type/reptile/xminus,
		/decl/blood_type/reptile/sxplus,
		/decl/blood_type/reptile/sxminus,
		/decl/blood_type/reptile/oplus,
		/decl/blood_type/reptile/ominus,
	)
	move_trail = /obj/effect/decal/cleanable/blood/tracks/claw

	breathing_sound = 'mods/f13/content/customization/sound/lizard_breathing.ogg'

	pain_emotes_with_pain_level = list(
		list(/decl/emote/audible/wheeze, /decl/emote/audible/roar, /decl/emote/audible/bellow, /decl/emote/audible/howl) = 80,
		list(/decl/emote/audible/grunt, /decl/emote/audible/groan, /decl/emote/audible/wheeze, /decl/emote/audible/hiss) = 50,
		list(/decl/emote/audible/grunt, /decl/emote/audible/groan, /decl/emote/audible/hiss) = 20,
	)

	exertion_effect_chance = 10
	exertion_hydration_scale = 1
	exertion_reagent_scale = 1
	exertion_reagent_path = /decl/material/liquid/lactate
	exertion_emotes_biological = list(
		/decl/emote/exertion/biological,
		/decl/emote/exertion/biological/breath,
		/decl/emote/exertion/biological/pant
	)

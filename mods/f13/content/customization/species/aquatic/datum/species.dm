/decl/species/aquatic
	name = SPECIES_AQUATIC
	name_plural = "Aquatics"
	base_external_prosthetics_model = null

	description = "A non-descript aquatic creature. If you are reading this, you are probably an aquatic."
	hidden_from_codex = FALSE
	available_bodytypes = list(
		/decl/bodytype/aquatic,
		/decl/bodytype/aquatic/masculine
	)

	spawn_flags = SPECIES_CAN_JOIN

	unarmed_attacks = list(
		/decl/natural_attack/stomp,
		/decl/natural_attack/kick,
		/decl/natural_attack/punch,
		/decl/natural_attack/bite/sharp
	)

	move_trail = /obj/effect/decal/cleanable/blood/tracks/claw

	exertion_effect_chance = 10
	exertion_hydration_scale = 1
	exertion_reagent_scale = 1
	exertion_reagent_path = /decl/material/liquid/lactate
	exertion_emotes_biological = list(
		/decl/emote/exertion/biological,
		/decl/emote/exertion/biological/breath,
		/decl/emote/exertion/biological/pant
	)

	available_accessory_categories = list(
		SAC_HAIR,
		SAC_FACIAL_HAIR,
		SAC_HORNS,
		SAC_FRILLS,
		// SAC_NECK,
		SAC_EARS,
		SAC_SNOUT,
		SAC_TAIL,
		// SAC_WINGS,
		SAC_COSMETICS,
		SAC_MARKINGS
	)

	additional_langs = list(/decl/language/human/common, /decl/language/sign)

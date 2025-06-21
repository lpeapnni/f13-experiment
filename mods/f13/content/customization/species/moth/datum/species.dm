/decl/species/moth
	name = SPECIES_MOTH
	name_plural = "Moths"
	base_external_prosthetics_model = null

	description = "A funny looking moth thing. If you are reading this, you are probably a moth."
	hidden_from_codex = FALSE
	available_bodytypes = list(
		/decl/bodytype/moth
	)

	spawn_flags = SPECIES_CAN_JOIN

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
		SAC_EARS,
		// SAC_NECK,
		// SAC_WINGS,
		SAC_COSMETICS,
		SAC_MARKINGS
	)

	additional_langs = list(/decl/language/human/common, /decl/language/sign)

/decl/species/anthro
	name = SPECIES_ANTHRO
	name_plural = "Anthros"
	base_external_prosthetics_model = null

	description = "A non-descript creature with fur. If you are reading this, you are probably an anthro."
	hidden_from_codex = FALSE
	available_bodytypes = list(
		/decl/bodytype/anthro,
		/decl/bodytype/anthro/masculine
	)

	spawn_flags = SPECIES_CAN_JOIN

	unarmed_attacks = list(
		/decl/natural_attack/stomp,
		/decl/natural_attack/kick,
		/decl/natural_attack/punch,
		/decl/natural_attack/bite/sharp
	)

	move_trail = /obj/effect/decal/cleanable/blood/tracks/paw

	exertion_effect_chance = 10
	exertion_hydration_scale = 1
	exertion_reagent_scale = 1
	exertion_reagent_path = /decl/material/liquid/lactate
	exertion_emotes_biological = list(
		/decl/emote/exertion/biological,
		/decl/emote/exertion/biological/breath,
		/decl/emote/exertion/biological/pant
	)

	additional_langs = list(/decl/language/human/common, /decl/language/sign)

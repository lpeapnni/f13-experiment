/decl/species/human/demihuman
	name = SPECIES_DEMIHUMAN
	name_plural = "Demihumans"
	description = "A medium-sized creature with ears prone to great ambition. If you are reading this, you are probably a demihuman (and should really just play an anthro)."

	available_bodytypes = list(
		/decl/bodytype/human/demihuman,
		/decl/bodytype/human/masculine/demihuman
	)

	available_accessory_categories = list(
		SAC_HAIR,
		SAC_FACIAL_HAIR,
		SAC_EARS,
		SAC_TAIL,
		SAC_COSMETICS,
		SAC_MARKINGS
	)

	additional_langs = list(/decl/language/human/common, /decl/language/sign)

/decl/species/human/demihuman/get_root_species_name(var/mob/living/human/H)
	return SPECIES_DEMIHUMAN
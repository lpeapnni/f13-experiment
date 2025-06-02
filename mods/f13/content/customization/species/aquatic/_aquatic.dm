#define BODYTYPE_AQUATIC "aquatic body"

/mob/living/human/aquatic/Initialize(mapload, species_name, datum/mob_snapshot/supplied_appearance)
	. = ..(species_name = SPECIES_AQUATIC)

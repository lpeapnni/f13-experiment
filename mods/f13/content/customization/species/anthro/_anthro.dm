#define BODYTYPE_ANTHRO "anthro body"

/mob/living/human/anthro/Initialize(mapload, species_name, datum/mob_snapshot/supplied_appearance)
	. = ..(species_name = SPECIES_ANTHRO)

#define BODYTYPE_ANTHRO "anthro body"
#define BODY_EQUIP_FLAG_FELINE BITFLAG(7)

/mob/living/human/anthro/Initialize(mapload, species_name, datum/mob_snapshot/supplied_appearance)
	. = ..(species_name = SPECIES_ANTHRO)

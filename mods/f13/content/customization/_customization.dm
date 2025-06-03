// furry goon content

#define SPECIES_ANTHRO "Anthro"
#define SPECIES_AQUATIC "Aquatic"
#define SPECIES_LIZARD "Lizard"
#define SPECIES_MOTH "Moth"

#define SAC_SNOUT /decl/sprite_accessory_category/snout
#define SAC_WINGS /decl/sprite_accessory_category/wings
#define SAC_NECK /decl/sprite_accessory_category/neck

// TODO: add genitals
#define SAC_PENIS /decl/sprite_accessory_category/penis
#define SAC_TESTES /decl/sprite_accessory_category/testes
#define SAC_BREASTS /decl/sprite_accessory_category/breasts
#define SAC_VAGINA /decl/sprite_accessory_category/vagina

/decl/modpack/f13_customization
	name = "F13 Player Customization"

/decl/modpack/f13_customization/pre_initialize()
	..()
	SSmodpacks.default_submap_whitelisted_species |= SPECIES_ANTHRO
	SSmodpacks.default_submap_whitelisted_species |= SPECIES_AQUATIC
	SSmodpacks.default_submap_whitelisted_species |= SPECIES_LIZARD
	SSmodpacks.default_submap_whitelisted_species |= SPECIES_MOTH

// sprite accessory overrides for species compatability
/decl/sprite_accessory/hair
	species_allowed = list(SPECIES_HUMAN, SPECIES_ANTHRO, SPECIES_AQUATIC, SPECIES_LIZARD, SPECIES_MOTH)

/decl/sprite_accessory/facial_hair
	species_allowed = list(SPECIES_HUMAN, SPECIES_ANTHRO, SPECIES_AQUATIC, SPECIES_LIZARD, SPECIES_MOTH)

/decl/sprite_accessory/marking
	species_allowed = list(SPECIES_HUMAN, SPECIES_ANTHRO, SPECIES_AQUATIC, SPECIES_LIZARD)

/decl/sprite_accessory/tail
	species_allowed = list(SPECIES_HUMAN, SPECIES_ANTHRO, SPECIES_AQUATIC)

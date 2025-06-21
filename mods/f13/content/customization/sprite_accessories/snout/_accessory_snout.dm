/decl/sprite_accessory_category/snout
	name = "Snout"
	base_accessory_type = /decl/sprite_accessory/snout
	default_accessory = /decl/sprite_accessory/snout/none
	uid = "acc_cat_snout"

/decl/sprite_accessory/snout
	hidden_by_gear_slot = slot_wear_mask_str
	hidden_by_gear_flag = HIDEFACE|HIDEMASK
	body_parts = list(BP_HEAD)
	sprite_overlay_layer = FLOAT_LAYER-1
	is_heritable = TRUE
	icon = 'mods/f13/content/customization/icons/sprite_accessories/snout/snouts.dmi'
	accessory_category = SAC_SNOUT
	abstract_type = /decl/sprite_accessory/snout
	color_blend = ICON_MULTIPLY
	species_allowed = list(SPECIES_ANTHRO, SPECIES_AQUATIC)
	accessory_metadata_types = list(SAM_COLOR)

/decl/sprite_accessory/snout/none
	name                        = "No Snout"
	icon_state                  = "none"
	uid                         = "acc_snout_none"
	bodytypes_allowed           = null
	bodytypes_denied            = null
	species_allowed             = null
	subspecies_allowed          = null
	bodytype_categories_allowed = null
	bodytype_categories_denied  = null
	body_flags_allowed          = null
	body_flags_denied           = null
	grooming_flags              = null
	draw_accessory              = FALSE

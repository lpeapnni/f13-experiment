/decl/sprite_accessory_category/neck
	name = "Neck Fluff"
	base_accessory_type = /decl/sprite_accessory/neck
	default_accessory = /decl/sprite_accessory/neck/none
	uid = "acc_cat_neck"

/decl/sprite_accessory/neck
	body_parts = list(BP_CHEST)
	sprite_overlay_layer = FLOAT_LAYER
	is_heritable = TRUE
	icon = 'mods/f13/customization/icons/sprite_accessories/neck.dmi'
	accessory_category = SAC_NECK
	abstract_type = /decl/sprite_accessory/neck
	color_blend = ICON_MULTIPLY
	species_allowed = list(SPECIES_MOTH)

/decl/sprite_accessory/neck/none
	name                        = "No Neck Fluff"
	icon_state                  = "none"
	uid                         = "acc_neck_none"
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

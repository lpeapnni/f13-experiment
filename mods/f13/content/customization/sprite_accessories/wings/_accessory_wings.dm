/decl/sprite_accessory_category/wings
	name = "Wings"
	base_accessory_type = /decl/sprite_accessory/wings
	default_accessory = /decl/sprite_accessory/wings/none
	uid = "acc_cat_wings"

/decl/sprite_accessory/wings
	body_parts = list(BP_WINGS)
	sprite_overlay_layer = FLOAT_LAYER
	is_heritable = TRUE
	icon = 'mods/f13/customization/icons/sprite_accessories/wings.dmi'
	accessory_category = SAC_WINGS
	abstract_type = /decl/sprite_accessory/wings
	color_blend = ICON_MULTIPLY

/decl/sprite_accessory/wings/none
	name                        = "No Wings"
	icon_state                  = "none"
	uid                         = "acc_wings_none"
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

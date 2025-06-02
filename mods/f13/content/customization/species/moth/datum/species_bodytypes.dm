/decl/bodytype/moth
	name                 = "moth"
	uid                  = "bodytype_moth"
	bodytype_category    = BODYTYPE_ANTHRO

	limb_blend           = ICON_MULTIPLY
	icon_base            = 'mods/f13/content/customization/icons/species/moth/body.dmi'
	icon_deformed        = 'mods/f13/content/customization/icons/species/moth/deformed_body.dmi'
	bandages_icon        = 'icons/mob/bandage.dmi'
	cosmetics_icon       = 'icons/mob/human_races/species/default_cosmetics.dmi'
	eye_icon             = 'mods/f13/content/customization/icons/species/moth/eyes.dmi'

	appearance_flags     = HAS_UNDERWEAR | HAS_SKIN_COLOR
	base_color           = "#ffffff"
	base_eye_color       = "#444444"

	nail_noun            = "claws"

	/*
	// TODO: MARKINGS
	default_sprite_accessories = list(
		SAC_HAIR     = list(/decl/sprite_accessory/hair/avian    = list(SAM_COLOR = "#252525")),
		SAC_MARKINGS = list(/decl/sprite_accessory/marking/avian = list(SAM_COLOR = "#454545"))
	)
	*/

	override_emote_sounds = list(
		"scream" = list(
			'mods/f13/content/customization/sound/moth_scream.ogg'
		)
	)

/decl/bodytype/moth/get_default_grooming_results(obj/item/organ/external/limb, obj/item/grooming/tool)
	if(tool?.grooming_flags & GROOMABLE_BRUSH)
		return list(
			"success"    = GROOMING_RESULT_SUCCESS,
			"descriptor" = "[limb.name] fluff"
		)
	return ..()

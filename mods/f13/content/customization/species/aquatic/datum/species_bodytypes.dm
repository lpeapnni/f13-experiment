/decl/bodytype/aquatic
	name                 = "feminine"
	uid                  = "bodytype_aquatic_fem"
	bodytype_category    = BODYTYPE_AQUATIC

	limb_blend           = ICON_MULTIPLY
	icon_base            = 'mods/f13/content/customization/icons/species/aquatic/body_female.dmi'
	icon_deformed        = 'mods/f13/content/customization/icons/species/aquatic/deformed_body_female.dmi'
	bandages_icon        = 'icons/mob/bandage.dmi'
	cosmetics_icon       = 'icons/mob/human_races/species/default_cosmetics.dmi'

	appearance_flags     = HAS_UNDERWEAR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	base_color           = "#ffffff"
	base_eye_color       = "#444444"

	default_sprite_accessories = list(
		SAC_SNOUT = list(
			/decl/sprite_accessory/snout/shark = list(SAM_COLOR = "#D8D7D7", SAM_COLOR_INNER = "#ffffff")
		),
		SAC_EARS = list(
			/decl/sprite_accessory/ears/f13/shark = list(SAM_COLOR = "#D8D7D7")
		)
	)

	nail_noun            = "claws"

	associated_gender     = FEMALE
	onmob_state_modifiers = list(slot_w_uniform_str = "f")

	override_limb_types = list(
		BP_TAIL = /obj/item/organ/external/tail/anthro
	)

	additional_emotes = list(
		/decl/emote/visible/tail/wag,
		/decl/emote/visible/tail/stopwag
	)

/decl/bodytype/aquatic/masculine
	name                  = "masculine"
	uid                   = "bodytype_aquatic_masc"

	icon_base             = 'mods/f13/content/customization/icons/species/aquatic/body_male.dmi'
	icon_deformed         = 'mods/f13/content/customization/icons/species/aquatic/deformed_body_male.dmi'

	associated_gender     = MALE
	onmob_state_modifiers = null

	override_emote_sounds = list(
		"cough" = list(
			'sound/voice/emotes/m_cougha.ogg',
			'sound/voice/emotes/m_coughb.ogg',
			'sound/voice/emotes/m_coughc.ogg'
		),
		"sneeze" = list(
			'sound/voice/emotes/m_sneeze.ogg'
		)
	)

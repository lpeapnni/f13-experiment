/decl/bodytype/anthro
	name                 = "feminine"
	uid                  = "bodytype_anthro_fem"
	bodytype_category    = BODYTYPE_FELINE

	limb_blend           = ICON_MULTIPLY
	icon_base            = 'mods/species/bayliens/tajaran/icons/body.dmi'
	icon_deformed        = 'mods/species/bayliens/tajaran/icons/deformed_body.dmi'
	bandages_icon        = 'icons/mob/bandage.dmi'
	cosmetics_icon       = 'mods/species/bayliens/tajaran/icons/cosmetics.dmi'

	appearance_flags     = HAS_UNDERWEAR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	base_color           = "#ae7d32"
	base_eye_color       = "#00aa00"

	nail_noun            = "claws"

	associated_gender     = FEMALE
	onmob_state_modifiers = list(slot_w_uniform_str = "f")

	override_limb_types = list(
		BP_TAIL = /obj/item/organ/external/tail/cat
	)

	default_sprite_accessories = list(
		SAC_HAIR     = list(/decl/sprite_accessory/hair/taj/lynx        = list(SAM_COLOR = "#46321c")),
		SAC_MARKINGS = list(/decl/sprite_accessory/marking/tajaran/ears = list(SAM_COLOR = "#ae7d32"))
	)

/decl/bodytype/anthro/get_default_grooming_results(obj/item/organ/external/limb, obj/item/grooming/tool)
	if(tool?.grooming_flags & GROOMABLE_BRUSH)
		return list(
			"success"    = GROOMING_RESULT_SUCCESS,
			"descriptor" = "[limb.name] fur"
		)
	return ..()

/decl/bodytype/anthro/masculine
	name                  = "masculine"
	uid                   = "bodytype_anthro_masc"

	icon_base             = 'icons/mob/human_races/species/human/body_male.dmi'
	icon_deformed         = 'icons/mob/human_races/species/human/deformed_body_male.dmi'

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

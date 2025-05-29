/decl/bodytype/anthro
	name                 = "feminine"
	uid                  = "bodytype_anthro_fem"
	bodytype_category    = BODYTYPE_ANTHRO

	limb_blend           = ICON_MULTIPLY
	icon_base            = 'mods/f13/content/customization/icons/species/anthro/body_female.dmi'
	icon_deformed        = 'mods/f13/content/customization/icons/species/anthro/deformed_body_female.dmi'
	bandages_icon        = 'icons/mob/bandage.dmi'
	cosmetics_icon       = 'icons/mob/human_races/species/default_cosmetics.dmi'

	appearance_flags     = HAS_UNDERWEAR | HAS_SKIN_COLOR | HAS_EYE_COLOR
	base_color           = "#ffffff"
	base_eye_color       = "#444444"

	nail_noun            = "claws"

	associated_gender     = FEMALE
	onmob_state_modifiers = list(slot_w_uniform_str = "f")

	override_limb_types = list(
		BP_TAIL = /obj/item/organ/external/tail/anthro
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

	icon_base             = 'mods/f13/content/customization/icons/species/anthro/body_male.dmi'
	icon_deformed         = 'mods/f13/content/customization/icons/species/anthro/deformed_body_male.dmi'

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

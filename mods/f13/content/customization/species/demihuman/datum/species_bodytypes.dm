/decl/bodytype/human/demihuman
	uid                   = "bodytype_demihuman_fem"

	default_sprite_accessories = list(
		SAC_TAIL = list(
			/decl/sprite_accessory/tail/f13/cat = list(SAM_COLOR = "#202020")
		),
		SAC_EARS = list(
			/decl/sprite_accessory/ears/f13/kitty = list(SAM_COLOR = "#202020", SAM_COLOR_INNER = "#ff90ff")
		)
	)

	override_limb_types = list(
		BP_TAIL = /obj/item/organ/external/tail/anthro
	)

	additional_emotes = list(
		/decl/emote/visible/tail/wag,
		/decl/emote/visible/tail/stopwag
	)

/decl/bodytype/human/masculine/demihuman
	uid                   = "bodytype_demihuman_masc"

	default_sprite_accessories = list(
		SAC_TAIL = list(
			/decl/sprite_accessory/tail/f13/cat = list(SAM_COLOR = "#202020")
		),
		SAC_EARS = list(
			/decl/sprite_accessory/ears/f13/kitty = list(SAM_COLOR = "#202020", SAM_COLOR_INNER = "#ff90ff")
		)
	)

	override_limb_types = list(
		BP_TAIL = /obj/item/organ/external/tail/anthro
	)

	additional_emotes = list(
		/decl/emote/visible/tail/wag,
		/decl/emote/visible/tail/stopwag
	)
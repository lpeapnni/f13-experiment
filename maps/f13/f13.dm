#if !defined(USING_MAP_DATUM)

	#ifdef UNIT_TEST
		#include "../../code/unit_tests/offset_tests.dm"
	#endif

	// stock nebula mods
	#include "../../mods/content/mundane.dm"
	#include "../../mods/content/scaling_descriptors.dm"
	#include "../../mods/content/byond_membership/_byond_membership.dm"
	#include "../../mods/content/matchmaking/_matchmaking.dme"
	#include "../../mods/content/mouse_highlights/_mouse_highlight.dme"

	// f13 mods
	#include "../../mods/f13/content/round_loop/_round_loop.dme"
	#include "../../mods/f13/content/customization/_customization.dme"

	// map files
	#include "f13_areas.dm"
	#include "f13_departments.dm"
	#include "f13_jobs.dm"
	#include "f13_unit_testing.dm"

	#include "f13-1.dmm"

	#define USING_MAP_DATUM /datum/map/f13

#elif !defined(MAP_OVERRIDE)

	#warn A map has already been included, ignoring Testing Site

#endif

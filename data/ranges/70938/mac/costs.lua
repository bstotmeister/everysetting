-- The frame rate on WoW Forever 1.60.1 (build 70938), on a Mac with Metal, on 14 November
-- 2026: each of the six heavy tuned settings at the low and the high end of its range.
-- data/ranges/README.md describes a line.
return {
	version = "1.60.1", build = "70938", platform = "Mac, Metal",
	note = "Standing still on a snowy road with the window closed, the game in front: snow and pines in view, no water and little ground cover. "
		.. "The rest as the player has it: graphics quality 9 (Ultra), render scale 0.5, vertical sync on, no frame rate cap (`useMaxFPS` 0), "
		.. "the cap in the background at 30 (`maxFPSBk`, not in play). Each value set, 4 seconds to settle, then `GetFramerate()` every quarter "
		.. "second for 5 seconds, and the old value put back. The frame rate stayed near 80 for all six: none moved it by more than 5%, and three "
		.. "went up. At this spot something else holds the frame rate, so these back no rating, and the six stay on guides' word (`guide`).",
	costs = {
		{ "farclip", "1000", "10000", 80.8, 83.1 },
		{ "groundEffectDensity", "16", "256", 77.6, 79.6, note = "Little ground cover in the snow." },
		{ "groundEffectDist", "40", "500", 83.9, 80.1, note = "Little ground cover in the snow." },
		{ "shadowTextureSize", "512", "4096", 84.2, 81.1 },
		{ "reflectionMode", "0", "3", 83.0, 83.6, note = "No water in view." },
		{ "volumeFog", "0", "1", 83.5, 82.6 },
	},
}

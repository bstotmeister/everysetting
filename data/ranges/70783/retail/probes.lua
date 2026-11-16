-- What the engine kept in the WoW retail client, 12.1.5 (build 70783), on a Mac with Metal,
-- on 14 November 2026: each tuned setting's range ends or options, through a copy of Every
-- Setting whose .toc gave retail's interface number; and on 15 November, the CVars only
-- retail has and the controls retail's own options menu gives. data/ranges/README.md
-- describes a line.
return {
	game = "WoW retail", version = "12.1.5", build = "70783", platform = "Mac, Metal",
	note = "Each tuned setting's range ends or options, tried one setting at a time with `EverySetting.Probe`, the function behind "
		.. "`/every probe`, through a copy of Every Setting whose `.toc` gave retail's interface number, 120105. Not one step past the ends. "
		.. "The engine's words are from the console's own saved lines: retail left `Logs/General.log` empty. "
		.. "Of the 59 tuned settings tried, the engine kept both ends of all but two: `shadowTextureSize` (not 768, 1536 or 4096) "
		.. "and `cameraDistanceMaxZoomFactor` (not 4: retail stops it at 2.6). "
		.. "Seven tuned settings have no CVar in retail: the loot sparkle (`outlineModeShowLootEffectWhenDisabled`), "
		.. "`HDROutput`, `useHDRBrightness`, `useHDRPeakBrightness`, `giQuality`, `bloomEnable` and `classicStyleWorldText`. "
		.. "Not tried, as in Forever: `nameplateMotionSpeed`, which retail also marks as not to be set in combat; the six `test_camera` settings, "
		.. "which raise the game's warning when one is changed; and `DynamicRenderScale`, which changes the size the game renders at. "
		.. "Retail's CVar list (`data/ranges/70783/retail/cvars.lua` in the repository) has 1,683 CVars on this character, to Forever's 1,797. "
		.. "17 are only in retail, two of them made by an addon (Details' `LibOpenRaidTempCache` and `LibOpenRaidTempCacheDebug`), "
		.. "and 131 only in Forever. Of the 1,666 in both, 39 have another default (`cameraDistanceMaxZoomFactor` 1.9, not 1; "
		.. "`nameplateMaxDistance` 60, not 45; `volumeFog` 0, not 1), 15 that Forever lists with no default have one in retail, "
		.. "and 4 have other flags: two kiosk CVars are read-only in retail, and `nameplateShowClassColor` and "
		.. "`nameplateShowFriendlyClassColor` are secure in retail and stored per account in Forever. "
		.. "The 1,712 values a snapshot read (every CVar, and the settings that aren't CVars it can) were the same after as before. "
		.. "On 15 November, on another character, Every Setting with retail's range set `cameraDistanceMaxZoomFactor` to 2, and its "
		.. "Photo style set it to 2.6 (the style's 4, held to retail's range): the engine kept both, and every value was the same after as before. "
		.. "Later on 15 November, on that same other character and its account, each control `CVars.lua` gives retail of its own (`RETAIL_CVARS`) was tried "
		.. "the same way, one CVar at a time, from `SSAOType` on, but for `nameplateStyle`, which retail marks as not to be set in combat, and the "
		.. "graphics quality levels (`graphicsComputeEffects`, `graphicsParticleDensity`), which set other CVars. Six of the 17 CVars only retail has "
		.. "weren't in the client on that account at all (`activeCUFProfile`, `auctionDisplayOnCharacter`, `nameplateShowFriends`, "
		.. "`playerStatLeftDropdown`, `playerStatRightDropdown`, `unlockedExpansionLandingPages`): an earlier version's, kept in the first account's "
		.. "saved settings. The 1,713 values a snapshot read were the same after as before.",
	probes = {
		{ "farclip", "1000", "10000", "1000", "10000" },
		{ "horizonStart", "400", "4000", "400", "4000" },
		{ "horizonClip", "1600", "10000", "1600", "10000" },
		{ "groundEffectDensity", "16", "256", "16", "256" },
		{ "groundEffectDist", "40", "500", "40", "500" },
		{ "lodObjectFadeScale", "50", "5000", "50", "5000" },
		{ "lodObjectCullSize", "1", "100", "1", "100" },
		{ "terrainLodDist", "200", "650", "200", "650" },
		{ "wmoLodDist", "250", "400", "250", "400" },
		{ "doodadLodScale", "50", "150", "50", "150" },
		{ "entityLodDist", "5", "10", "5", "10" },
		{ "terrainMipLevel", "0", "1", "0", "1" },
		{ "componentTextureLevel", "0", "1", "0", "1" },
		{ "componentTextureLevel", "2", "2", "2", "2" },
		{ "particleDensity", "0", "100", "0", "100" },
		{ "spellVisualDensityFilterSetting", "1", "2", "1", "2" },
		{ "spellVisualDensityFilterSetting", "3", "4", "3", "4" },
		{ "weatherDensity", "0", "1", "0", "1" },
		{ "weatherDensity", "2", "3", "2", "3" },
		{ "showfootprintparticles", "0", "1", "0", "1" },
		{ "ffxGlow", "0", "1", "0", "1" },
		{ "ffxDeath", "0", "1", "0", "1" },
		{ "ffxNether", "0", "1", "0", "1" },
		{ "sunShafts", "0", "1", "0", "1" },
		{ "sunShafts", "2", "2", "2", "2" },
		{ "volumeFog", "0", "1", "0", "1" },
		{ "volumeFogLevel", "0", "4", "0", "4" },
		{ "volumeFogInterior", "0", "1", "0", "1" },
		{ "specular", "0", "1", "0", "1" },
		{ "reflectionMode", "0", "1", "0", "1" },
		{ "reflectionMode", "2", "3", "2", "3" },
		{ "refraction", "0", "2", "0", "2" },
		{ "rippleDetail", "0", "2", "0", "2" },
		{ "DepthBasedOpacity", "0", "1", "0", "1" },
		{ "shadowMode", "0", "1", "0", "1" },
		{ "shadowMode", "2", "3", "2", "3" },
		{ "shadowMode", "4", "4", "4", "4" },
		{ "shadowTextureSize", "512", "768", "512", "512", note = "Unsupported shadow texture size." },
		{ "shadowTextureSize", "1024", "1536", "1024", "1024", note = "Unsupported shadow texture size." },
		{ "shadowTextureSize", "2048", "4096", "2048", "2048", note = "Unsupported shadow texture size." },
		{ "shadowNumCascades", "1", "4", "1", "4" },
		{ "entityShadowFadeScale", "10", "50", "10", "50" },
		{ "shadowSoft", "0", "1", "0", "1" },
		{ "shadowBlendCascades", "0", "1", "0", "1" },
		{ "ResampleAlwaysSharpen", "0", "1", "0", "1" },
		{ "CMAA2Quality", "0", "1", "0", "1" },
		{ "CMAA2Quality", "2", "3", "2", "3" },
		{ "CMAA2ExtraSharpness", "0", "1", "0", "1" },
		{ "maxFPSLoading", "10", "100", "10", "100" },
		{ "screenshotQuality", "1", "10", "1", "10" },
		{ "screenshotFormat", "jpeg", "png", "jpeg", "png" },
		{ "screenshotFormat", "tga", "tga", "tga", "tga" },
		{ "cameraDistanceMaxZoomFactor", "1", "4", "1", "1", note = "Value out of range (1.000000 - 2.600000)" },
		{ "cameraDistanceMaxZoomFactor", "2", "2.6", "2", "2.6", note = "Set through Every Setting, 2.6 by the Photo style." },
		{ "cameraZoomSpeed", "1", "50", "1", "50" },
		{ "cameraDistanceRateMult", "0.1", "10", "0.1", "10" },
		{ "cameraYawMoveSpeed", "1", "360", "1", "360" },
		{ "cameraPitchMoveSpeed", "1", "360", "1", "360" },
		{ "cameraYawSmoothSpeed", "1", "360", "1", "360" },
		{ "cameraPitchSmoothSpeed", "1", "360", "1", "360" },
		{ "cameraZSmooth", "1", "2", "1", "2" },
		{ "CameraKeepCharacterCentered", "0", "1", "0", "1" },
		{ "CameraReduceUnexpectedMovement", "0", "1", "0", "1" },
		{ "mouseAcceleration", "-1", "0", "-1", "0" },
		{ "mouseAcceleration", "1", "1", "1", "1" },
		{ "threatWarning", "0", "1", "0", "1" },
		{ "threatWarning", "2", "3", "2", "3" },
		{ "FootstepSounds", "0", "1", "0", "1" },
		{ "Sound_EnableArmorFoleySoundForSelf", "0", "1", "0", "1" },
		{ "Sound_EnableArmorFoleySoundForOthers", "0", "1", "0", "1" },
		{ "Sound_ListenerAtCharacter", "0", "1", "0", "1" },
		{ "Sound_EnableDSPEffects", "0", "1", "0", "1" },
		{ "SpellQueueWindow", "0", "400", "0", "400" },
		{ "SSAOType", "1", "9", "1", "1", note = "Unsupported SSAO type." },
		{ "SSAOType", "2", "3", "0", "0", note = "Unsupported SSAO type, for each." },
		{ "useShadowMapping", "0", "2", "0", "2" },
		{ "volumeFogDisableLightScattering", "0", "1", "0", "1" },
		{ "volumeFogDisableNoise", "0", "1", "0", "1" },
		{ "volumeFogDisableShadows", "0", "1", "0", "1" },
		{ "volumeFogUse16BitTexture", "0", "1", "0", "1" },
		{ "advFlyKeyboardMinPitchFactor", "1", "10", "1", "10" },
		{ "advFlyKeyboardMaxPitchFactor", "1", "10", "1", "10" },
		{ "advFlyKeyboardMinTurnFactor", "1", "10", "1", "10" },
		{ "advFlyKeyboardMaxTurnFactor", "1", "10", "1", "10" },
		{ "advFlyPitchControlCameraChase", "10", "30", "10", "30" },
		{ "advFlyPitchControl", "1", "2", "1", "2" },
		{ "LowLatencyMode", "1", "4", "1", "1", note = "Not Intel XeLL, on a Mac: retail's own menu offers only what the computer supports." },
		{ "Outline", "0", "3", "0", "3" },
		{ "encounterTimelineEnabled", "0", "1", "0", "1" },
	},
}

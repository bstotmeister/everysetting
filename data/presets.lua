-- What each of the game's graphics quality settings sets, level by level, in the
-- WoW Forever client (1.60.1.70888). Found in game: each setting's CVar was set
-- to every level in turn, and the CVars that changed were read back. Setting
-- the raid twin of a setting (raidGraphicsViewDistance) sets the raid twins of
-- the same CVars (RAIDfarclip) to the same values.
--
-- Used by the tests: a knob whose range comes from the presets (src = "preset")
-- must cover these values. Not shipped with the addon.
--
-- Each setting: its levels from the lowest (0) up, for every CVar it sets.
return {
	graphicsViewDistance = { -- levels 0 to 9
		wmoLodDist = { 250, 250, 300, 300, 350, 350, 400, 400, 400, 400 },
		farclip = { 3000, 3000, 3000, 5000, 6000, 6000, 7000, 8000, 8000, 10000 },
		horizonStart = { 400, 600, 800, 1000, 1400, 1700, 1900, 2400, 3000, 4000 },
		terrainLodDist = { 200, 225, 250, 350, 400, 500, 500, 600, 650, 650 },
		horizonClip = { 3000, 3000, 3000, 5000, 6000, 6000, 7000, 8000, 8000, 10000 },
		entityShadowFadeScale = { 10, 10, 10, 15, 20, 20, 25, 30, 40, 50 },
		entityLodDist = { 5, 5, 5, 7, 8, 8, 10, 10, 10, 10 },
		TerrainLodDiv = { 384, 384, 384, 512, 512, 512, 512, 768, 768, 768 },
	},
	graphicsEnvironmentDetail = { -- levels 0 to 9
		lodObjectFadeScale = { 50, 50, 80, 80, 90, 90, 100, 110, 125, 150 },
		lodObjectCullSize = { 35, 30, 27, 22, 20, 19, 18, 17, 16, 14 },
		lodObjectMinSize = { 0, 0, 0, 0, 0, 0, 0, 0, 30, 20 },
		doodadLodScale = { 50, 50, 75, 75, 100, 100, 100, 125, 150, 150 },
	},
	graphicsGroundClutter = { -- levels 0 to 9
		groundEffectDist = { 40, 55, 70, 110, 160, 185, 200, 260, 300, 320 },
		groundEffectDensity = { 16, 16, 16, 32, 32, 32, 48, 48, 48, 48 },
	},
	graphicsShadowQuality = { -- levels 0 to 5
		shadowMode = { 2, 2, 2, 3, 3, 4 },
		shadowNumCascades = { 3, 3, 3, 3, 3, 4 },
		shadowTextureSize = { 512, 768, 1024, 1536, 2048, 2048 },
		shadowSoft = { 0, 0, 0, 0, 1, 1 },
	},
	graphicsLiquidDetail = { -- levels 0 to 3
		rippleDetail = { 0, 0, 1, 2 },
		waterDetail = { 0, 1, 2, 3 },
		reflectionMode = { 0, 2, 2, 3 },
	},
	graphicsParticleDensity = { -- levels 0 to 4
		particleMTDensity = { 20, 35, 70, 100, 100 },
		particleDensity = { 10, 25, 50, 80, 100 },
		weatherDensity = { 0, 1, 1, 3, 3 },
	},
	graphicsSSAO = { -- levels 0 to 4
		SSAO = { 0, 1, 2, 3, 4 },
	},
	graphicsDepthEffects = { -- levels 0 to 3
		refraction = { 0, 0, 1, 2 },
		DepthBasedOpacity = { 0, 1, 1, 1 },
		sunShafts = { 0, 0, 1, 2 },
	},
	graphicsComputeEffects = { -- levels 0 to 4
		volumeFogLevel = { 0, 1, 2, 3, 4 },
	},
	graphicsOutlineMode = { -- levels 0 to 2
		OutlineEngineMode = { 0, 1, 2 },
	},
	graphicsSpellDensity = { -- levels 0 to 2
		spellClutter = { 1, 2, 4 },
		spellVisualDensityFilterSetting = { 1, 2, 4 },
	},
	graphicsProjectedTextures = { -- levels 0 to 1
		projectedTextures = { 0, 1 },
	},
	graphicsTextureResolution = { -- levels 0 to 2
		terrainMipLevel = { 1, 1, 0 },
		worldBaseMip = { 2, 1, 0 },
		componentTextureLevel = { 1, 1, 0 },
	},
	graphicsLightMode = { -- levels 0 to 3
		giQuality = { 1, 2, 3, 4 },
		RenderFormat = { 1, 2, 2, 2 },
	},
	graphicsPBRLiquidDetail = { -- levels 0 to 2
		pbrLiquidDetail = { 0, 1, 2 },
	},
}

-- Every Setting's knobs: the CVars worth tuning, each with the range or options the
-- game accepts, and a few settings that aren't CVars ("@click:SELFCAST", or a console
-- command, "@console:pitchLimit": Core.lua's SETTERS has how the game reads and
-- writes each). Core.lua describes a knob's fields. The words, each group's title and
-- each knob's label, tip and options, are in the locale table (Locales/enUS.lua).
--
-- The game has no API for a CVar's range, so each one here says where its
-- range comes from (`src`):
--   ui      Blizzard's settings code (the forever branch of wow-ui-source)
--   help    the CVar's help text in the client
--   api     a function the client provides
--   probe   setting it in the 1.60.1 client: the engine keeps the values in
--           the range and turns down the ones outside it, usually saying the
--           range in its log ("Value must be between 16 and 256.")
--   preset  the engine keeps any number for these. The range covers the
--           values the game's own quality settings set, from their lowest
--           level to their highest, and the engine's default (data/presets.lua).
--           The slider, styles and presets stay inside it; a number typed in
--           the box beside the slider can go past it.
--   command the engine keeps any number for these. They're toggles because the
--           game's own console command for them only sets 0 and 1 (and the
--           engine's default is 0):
--           /console ActionCam full sets them to 1, and the Disable button on
--           the game's warning puts them back to 0.
-- A knob isn't added without one of these. CVars that mirror a control in the
-- game's own options one for one are left to the options menu.
--
-- The ranges are WoW Forever's. Where retail's engine keeps another one (tried in
-- the 12.1.5 client), the knob has it in `retail`, with its own `src`, and retail
-- uses that. A knob whose CVar retail lacks gets no row there.
--
-- The window lists a group under the section CVars.lua gives its CVars, so a
-- group's knobs are all from one section.
--
-- A knob that costs frame rate as it's turned up says how much (`cost`: light,
-- medium or heavy), on evidence of its own (`costSrc`):
--   probe   measured in the client: the frame rate at each end of the knob's
--           range, from the same spot (data/ranges/README.md). Heavy is a fall of
--           a fifth or more, medium of a twentieth or more, light less than that.
--   guide   graphics guides and other graphics addons rate it so. Frame rates
--           measured that don't show the cost leave it on their word.
--
-- A knob that one of the game's graphics quality settings sets has `tiers`:
-- the values the built-in presets (EverySetting.TIERS: Low, Medium, High, Ultra)
-- give it. They're four of that setting's levels (data/presets.lua), spread
-- evenly from its lowest to its highest: of 10 levels, the 1st, 4th, 7th and
-- 10th.

local _, ns = ...
local EverySetting = ns.EverySetting
local L = ns.L

-- A modified click's options: a key held, and for a click that's always with one
-- mouse button, that key with a button.
local CLICK_KEYS = { { "NONE", L.NONE }, { "SHIFT", L.SHIFT }, { "CTRL", L.CTRL }, { "ALT", L.ALT } }
local CLICK_BUTTONS = { CLICK_KEYS[1], CLICK_KEYS[2], CLICK_KEYS[3], CLICK_KEYS[4],
	{ "SHIFT-BUTTON1", L.SHIFT_CLICK }, { "CTRL-BUTTON1", L.CTRL_CLICK }, { "ALT-BUTTON1", L.ALT_CLICK },
	{ "SHIFT-BUTTON2", L.SHIFT_RIGHT_CLICK }, { "CTRL-BUTTON2", L.CTRL_RIGHT_CLICK }, { "ALT-BUTTON2", L.ALT_RIGHT_CLICK } }

-- The combat audio alerts' options, as the game's Audio Assist options have them.
local CAA_PERCENT = { { 0, L.OFF }, { 1, L.EVERY_10 }, { 2, L.EVERY_20 }, { 3, L.EVERY_30 }, { 4, L.EVERY_40 }, { 5, L.EVERY_50 } }
local CAA_FORMAT = { { 0, L.FULL }, { 1, L.NO_PERCENT }, { 2, L.NO_PERCENT_VALUE_10 }, { 3, L.NO_RESOURCE_NAME },
	{ 4, L.NUMBER_ONLY }, { 5, L.NUMBER_ONLY_VALUE_10 } }
local CAA_TARGETED = { { 0, L.OFF }, { 1, L.VOICE_AGGRO }, { 2, L.VOICE_YOURE_TARGETED }, { 3, L.VOICE_TARGETED_BY_AND_THE_NAME } }

-- Said about each of the game's experimental camera settings (the test_camera CVars).
local EXPERIMENTAL = " " .. L.EXPERIMENTAL_CAMERA

EverySetting.GROUPS = {
	{ title = L.DRAW_DISTANCE, items = {
		{ cvar = "farclip", label = L.VIEW_DISTANCE, type = "slider", min = 1000, max = 10000, step = 100,
		  src = "preset", raid = "RAIDfarclip", cost = "heavy", costSrc = "guide",
		  tiers = { 3000, 5000, 7000, 10000 },
		  tip = L.VIEW_DISTANCE_TIP },
		{ cvar = "horizonStart", label = L.HORIZON_START, type = "slider", min = 400, max = 4000, step = 100,
		  src = "preset", raid = "RAIDhorizonStart",
		  tiers = { 400, 1000, 1900, 4000 },
		  tip = L.HORIZON_START_TIP },
		{ cvar = "horizonClip", label = L.HORIZON_DISTANCE, type = "slider", min = 1600, max = 10000, step = 100,
		  src = "preset", raid = "RAIDhorizonClip",
		  tiers = { 3000, 5000, 7000, 10000 },
		  tip = L.HORIZON_DISTANCE_TIP },
	} },

	{ title = L.GROUND_CLUTTER, items = {
		{ cvar = "groundEffectDensity", label = L.GROUND_CLUTTER_DENSITY, type = "slider", min = 16, max = 256, step = 8,
		  src = "probe", raid = "RAIDgroundEffectDensity", cost = "heavy", costSrc = "guide",
		  tiers = { 16, 32, 48, 48 },
		  tip = L.GROUND_CLUTTER_DENSITY_TIP },
		{ cvar = "groundEffectDist", label = L.GROUND_CLUTTER_DISTANCE, type = "slider", min = 40, max = 500, step = 10,
		  src = "probe", raid = "RAIDgroundEffectDist", cost = "heavy", costSrc = "guide",
		  tiers = { 40, 110, 200, 320 },
		  tip = L.GROUND_CLUTTER_DISTANCE_TIP },
	} },

	{ title = L.LEVEL_OF_DETAIL, items = {
		{ cvar = "lodObjectFadeScale", label = L.OBJECT_FADE_DISTANCE, type = "slider", min = 50, max = 5000, step = 10,
		  src = "probe", raid = "RAIDlodObjectFadeScale",
		  tiers = { 50, 80, 100, 150 },
		  tip = L.OBJECT_FADE_DISTANCE_TIP },
		{ cvar = "lodObjectCullSize", label = L.SMALL_OBJECT_CULLING, type = "slider", min = 1, max = 100, step = 1,
		  src = "probe", raid = "RAIDlodObjectCullSize",
		  tiers = { 35, 22, 18, 14 },
		  tip = L.SMALL_OBJECT_CULLING_TIP },
		{ cvar = "terrainLodDist", label = L.TERRAIN_DETAIL_DISTANCE, type = "slider", min = 200, max = 650, step = 25,
		  src = "preset", raid = "RAIDterrainLodDist",
		  tiers = { 200, 350, 500, 650 },
		  tip = L.TERRAIN_DETAIL_DISTANCE_TIP },
		{ cvar = "wmoLodDist", label = L.BUILDING_DETAIL_DISTANCE, type = "slider", min = 250, max = 400, step = 10,
		  src = "preset", raid = "RAIDwmoLodDist",
		  tiers = { 250, 300, 400, 400 },
		  tip = L.BUILDING_DETAIL_DISTANCE_TIP },
		{ cvar = "doodadLodScale", label = L.PROP_DETAIL_DISTANCE, type = "slider", min = 50, max = 150, step = 5,
		  src = "preset", raid = "RAIDdoodadLodScale",
		  tiers = { 50, 75, 100, 150 },
		  tip = L.PROP_DETAIL_DISTANCE_TIP },
		{ cvar = "entityLodDist", label = L.CREATURE_DETAIL_DISTANCE, type = "slider", min = 5, max = 10, step = 1,
		  src = "preset", raid = "RAIDentityLodDist",
		  tiers = { 5, 7, 10, 10 },
		  tip = L.CREATURE_DETAIL_DISTANCE_TIP },
	} },

	{ title = L.TEXTURES, items = {
		{ cvar = "terrainMipLevel", label = L.GROUND_TEXTURE_BLENDING, type = "choice", src = "probe", raid = "RAIDterrainMipLevel",
		  options = { { 0, L.FULL_DETAIL }, { 1, L.REDUCED } },
		  tiers = { 1, 1, 1, 0 },
		  tip = L.GROUND_TEXTURE_BLENDING_TIP },
		{ cvar = "componentTextureLevel", label = L.CHARACTER_TEXTURES, type = "choice", src = "probe", raid = "RAIDcomponentTextureLevel",
		  options = { { 0, L.FULL_DETAIL }, { 1, L.REDUCED }, { 2, L.LOWEST } },
		  tiers = { 1, 1, 1, 0 },
		  tip = L.CHARACTER_TEXTURES_TIP },
	} },

	{ title = L.EFFECTS, items = {
		{ cvar = "outlineModeShowLootEffectWhenDisabled", label = L.LOOT_SPARKLES, type = "toggle", src = "help",
		  with = { graphicsOutlineMode = "0", raidGraphicsOutlineMode = "0" },
		  restart = "login", restartTo = "0", restartSrc = "probe",
		  tip = L.LOOT_SPARKLES_TIP },
		{ cvar = "particleDensity", label = L.PARTICLE_DENSITY, type = "slider", min = 0, max = 100, step = 5,
		  src = "probe", raid = "RAIDparticleDensity",
		  tiers = { 10, 25, 80, 100 },
		  tip = L.PARTICLE_DENSITY_TIP },
		{ cvar = "spellVisualDensityFilterSetting", label = L.SPELL_EFFECT_DENSITY, type = "choice", src = "help",
		  options = { { 1, L.MINIMUM }, { 2, L.REDUCED }, { 3, L.PERFORMANCE }, { 4, L.FULL } },
		  tiers = { 1, 2, 2, 4 },
		  tip = L.SPELL_EFFECT_DENSITY_TIP },
		{ cvar = "weatherDensity", label = L.WEATHER, type = "choice", src = "probe", raid = "RAIDweatherDensity",
		  options = { { 0, L.NONE }, { 1, L.LIGHT }, { 2, L.MEDIUM }, { 3, L.HEAVY } },
		  tiers = { 0, 1, 3, 3 },
		  tip = L.WEATHER_TIP },
		{ cvar = "showfootprintparticles", label = L.FOOTPRINTS, type = "toggle", src = "help",
		  tip = L.FOOTPRINTS_TIP },
		{ cvar = "ffxGlow", label = L.FULL_SCREEN_GLOW, type = "toggle", src = "help",
		  tip = L.FULL_SCREEN_GLOW_TIP },
		{ cvar = "ffxDeath", label = L.DEATH_EFFECT, type = "toggle", src = "help",
		  tip = L.DEATH_EFFECT_TIP },
		{ cvar = "ffxNether", label = L.NETHER_EFFECT, type = "toggle", src = "help",
		  tip = L.NETHER_EFFECT_TIP },
	} },

	{ title = L.LIGHTING_AND_WATER, items = {
		{ cvar = "sunShafts", label = L.SUN_SHAFTS, type = "choice", src = "probe", raid = "RAIDsunShafts",
		  options = { { 0, L.OFF }, { 1, L.LOW }, { 2, L.HIGH } },
		  tiers = { 0, 0, 1, 2 },
		  tip = L.SUN_SHAFTS_TIP },
		{ cvar = "giQuality", label = L.INDIRECT_LIGHTING, type = "slider", min = 1, max = 4, step = 1,
		  src = "preset", raid = "RAIDgiQuality",
		  tiers = { 1, 2, 3, 4 },
		  tip = L.INDIRECT_LIGHTING_TIP },
		{ cvar = "volumeFog", label = L.VOLUMETRIC_FOG, type = "toggle", src = "probe", raid = "RAIDVolumeFog",
		  cost = "heavy", costSrc = "guide",
		  tip = L.VOLUMETRIC_FOG_TIP },
		{ cvar = "volumeFogLevel", label = L.VOLUMETRIC_FOG_QUALITY, type = "slider", min = 0, max = 4, step = 1,
		  src = "probe", raid = "RAIDVolumeFogLevel",
		  tiers = { 0, 1, 3, 4 },
		  tip = L.VOLUMETRIC_FOG_QUALITY_TIP },
		{ cvar = "volumeFogInterior", label = L.FOG_INDOORS, type = "toggle", src = "probe",
		  tip = L.FOG_INDOORS_TIP },
		{ cvar = "bloomEnable", label = L.BLOOM, type = "toggle", src = "help",
		  tip = L.BLOOM_TIP },
		{ cvar = "specular", label = L.SHINE, type = "slider", min = 0, max = 1, step = 0.05, src = "help",
		  tip = L.SHINE_TIP },
		{ cvar = "reflectionMode", label = L.WATER_REFLECTIONS, type = "choice", src = "probe", raid = "RAIDreflectionMode",
		  cost = "heavy", costSrc = "guide",
		  options = { { 0, L.NONE }, { 1, L.SCREEN_SPACE_WITHOUT_THE_SKY }, { 2, L.SCREEN_SPACE }, { 3, L.PLANAR } },
		  tiers = { 0, 2, 2, 3 },
		  tip = L.WATER_REFLECTIONS_TIP },
		{ cvar = "refraction", label = L.REFRACTION, type = "slider", min = 0, max = 2, step = 1,
		  src = "probe", raid = "RAIDrefraction",
		  tiers = { 0, 0, 1, 2 },
		  tip = L.REFRACTION_TIP },
		{ cvar = "rippleDetail", label = L.WATER_RIPPLES, type = "slider", min = 0, max = 2, step = 1,
		  src = "probe", raid = "RAIDrippleDetail",
		  tiers = { 0, 0, 1, 2 },
		  tip = L.WATER_RIPPLES_TIP },
		{ cvar = "DepthBasedOpacity", label = L.SOFT_EDGES, type = "toggle", src = "help", raid = "RAIDDepthBasedOpacity",
		  tiers = { 0, 1, 1, 1 },
		  tip = L.SOFT_EDGES_TIP },
	} },

	{ title = L.SHADOWS, items = {
		{ cvar = "shadowMode", label = L.SHADOW_TYPE, type = "choice", src = "probe", raid = "RAIDshadowMode",
		  options = { { 0, L.BLOB_SHADOWS }, { 1, L.N1_BAND_ON_UNITS }, { 2, L.N2_BANDS_ON_UNITS_AND_TERRAIN },
		              { 3, L.N3_BANDS_ON_UNITS_AND_TERRAIN }, { 4, L.N4_BANDS_ON_UNITS_AND_TERRAIN } },
		  tiers = { 2, 2, 3, 4 },
		  tip = L.SHADOW_TYPE_TIP },
		{ cvar = "shadowTextureSize", label = L.SHADOW_RESOLUTION, type = "choice", src = "probe", raid = "RAIDshadowTextureSize",
		  cost = "heavy", costSrc = "guide",
		  options = { { 512, "512" }, { 768, "768" }, { 1024, "1024" }, { 1536, "1536" }, { 2048, "2048" }, { 4096, "4096" } },
		  retail = { options = { { 512, "512" }, { 1024, "1024" }, { 2048, "2048" } }, src = "probe" },
		  tiers = { 512, 1024, 1536, 2048 },
		  tip = L.SHADOW_RESOLUTION_TIP },
		{ cvar = "shadowNumCascades", label = L.SHADOW_CASCADES, type = "slider", min = 1, max = 4, step = 1,
		  src = "preset", raid = "RAIDshadowNumCascades",
		  tiers = { 3, 3, 3, 4 },
		  tip = L.SHADOW_CASCADES_TIP },
		{ cvar = "entityShadowFadeScale", label = L.CREATURE_SHADOW_DISTANCE, type = "slider", min = 10, max = 50, step = 5,
		  src = "preset", raid = "RAIDentityShadowFadeScale",
		  tiers = { 10, 15, 25, 50 },
		  tip = L.CREATURE_SHADOW_DISTANCE_TIP },
		{ cvar = "shadowSoft", label = L.SOFT_SHADOWS, type = "toggle", src = "probe", raid = "RAIDshadowSoft",
		  tiers = { 0, 0, 0, 1 },
		  tip = L.SOFT_SHADOWS_TIP },
		{ cvar = "shadowBlendCascades", label = L.BLEND_SHADOW_BANDS, type = "toggle", src = "probe", raid = "RAIDshadowBlendCascades",
		  tip = L.BLEND_SHADOW_BANDS_TIP },
	} },

	{ title = L.SHARPNESS_AND_SMOOTHING, items = {
		{ cvar = "ResampleAlwaysSharpen", label = L.ALWAYS_SHARPEN, type = "toggle", src = "help",
		  tip = L.ALWAYS_SHARPEN_TIP },
		{ cvar = "CMAA2Quality", label = L.CMAA2_QUALITY, type = "choice", src = "help",
		  options = { { 0, L.LOW }, { 1, L.MEDIUM }, { 2, L.HIGH }, { 3, L.ULTRA } },
		  tip = L.CMAA2_QUALITY_TIP },
		{ cvar = "CMAA2ExtraSharpness", label = L.CMAA2_EXTRA_SHARPNESS, type = "toggle", src = "help",
		  tip = L.CMAA2_EXTRA_SHARPNESS_TIP },
		{ cvar = "DynamicRenderScale", label = L.DYNAMIC_RENDER_SCALE_BETA, type = "toggle", src = "help",
		  tip = L.DYNAMIC_RENDER_SCALE_BETA_TIP },
	} },

	{ title = L.HDR, items = {
		{ cvar = "HDROutput", label = L.HDR_OUTPUT, type = "toggle", src = "help",
		  restart = "gx", restartTo = "0", restartSrc = "probe",
		  tip = L.HDR_OUTPUT_TIP },
		{ cvar = "useHDRBrightness", label = L.SET_THE_BRIGHTNESS, type = "toggle", src = "help",
		  tip = L.SET_THE_BRIGHTNESS_TIP },
		{ cvar = "useHDRPeakBrightness", label = L.SET_THE_PEAK_BRIGHTNESS, type = "toggle", src = "help",
		  tip = L.SET_THE_PEAK_BRIGHTNESS_TIP },
	} },

	{ title = L.FRAME_RATE_AND_SCREENSHOTS, items = {
		{ cvar = "maxFPSLoading", label = L.LOADING_SCREEN_FRAME_RATE, type = "slider", min = 10, max = 100, step = 5, src = "probe",
		  tip = L.LOADING_SCREEN_FRAME_RATE_TIP },
		{ cvar = "screenshotQuality", label = L.SCREENSHOT_QUALITY, type = "slider", min = 1, max = 10, step = 1, src = "help",
		  tip = L.SCREENSHOT_QUALITY_TIP },
		{ cvar = "screenshotFormat", label = L.SCREENSHOT_FORMAT, type = "choice", src = "probe",
		  options = { { "jpeg", "JPEG" }, { "png", "PNG" }, { "tga", "TGA" } },
		  tip = L.SCREENSHOT_FORMAT_TIP },
	} },

	{ title = L.CAMERA, items = {
		{ cvar = "cameraDistanceMaxZoomFactor", label = L.MAX_CAMERA_DISTANCE, type = "slider", min = 1, max = 4, step = 0.1,
		  src = "probe",
		  retail = { max = 2.6, src = "probe", tip = L.MAX_CAMERA_DISTANCE_TIP_RETAIL },
		  tip = L.MAX_CAMERA_DISTANCE_TIP },
		{ cvar = "cameraZoomSpeed", label = L.ZOOM_SPEED, type = "slider", min = 1, max = 50, step = 1, src = "probe",
		  tip = L.ZOOM_SPEED_TIP },
		{ cvar = "cameraDistanceRateMult", label = L.ZOOM_CATCH_UP_RATE, type = "slider", min = 0.1, max = 10, step = 0.1, src = "probe",
		  tip = L.ZOOM_CATCH_UP_RATE_TIP },
		{ cvar = "cameraYawMoveSpeed", label = L.CAMERA_TURN_SPEED_SIDEWAYS, type = "slider", min = 1, max = 360, step = 1, src = "probe",
		  tip = L.CAMERA_TURN_SPEED_SIDEWAYS_TIP },
		{ cvar = "cameraPitchMoveSpeed", label = L.CAMERA_TURN_SPEED_UP_AND_DOWN, type = "slider", min = 1, max = 360, step = 1, src = "probe",
		  tip = L.CAMERA_TURN_SPEED_UP_AND_DOWN_TIP },
		{ cvar = "cameraYawSmoothSpeed", label = L.CAMERA_FOLLOW_SPEED_SIDEWAYS, type = "slider", min = 1, max = 360, step = 1, src = "probe",
		  tip = L.CAMERA_FOLLOW_SPEED_SIDEWAYS_TIP },
		{ cvar = "cameraPitchSmoothSpeed", label = L.CAMERA_FOLLOW_SPEED_UP_AND_DOWN, type = "slider", min = 1, max = 360, step = 1, src = "probe",
		  tip = L.CAMERA_FOLLOW_SPEED_UP_AND_DOWN_TIP },
		{ cvar = "cameraZSmooth", label = L.SMOOTH_CAMERA_HEIGHT, type = "choice", src = "help",
		  options = { { 1, L.ONLY_WHILE_MOVING }, { 2, L.ALSO_WHILE_STANDING_STILL } },
		  tip = L.SMOOTH_CAMERA_HEIGHT_TIP },
	} },

	{ title = L.ACTION_CAMERA, items = {
		{ cvar = "test_cameraOverShoulder", label = L.OVER_THE_SHOULDER, type = "toggle", src = "command",
		  tip = L.OVER_THE_SHOULDER_TIP .. EXPERIMENTAL },
		{ cvar = "CameraKeepCharacterCentered", label = L.KEEP_YOUR_CHARACTER_CENTERED, type = "toggle", src = "ui",
		  tip = L.KEEP_YOUR_CHARACTER_CENTERED_TIP },
		{ cvar = "CameraReduceUnexpectedMovement", label = L.REDUCE_CAMERA_MOVEMENT, type = "toggle", src = "ui",
		  tip = L.REDUCE_CAMERA_MOVEMENT_TIP },
		{ cvar = "test_cameraDynamicPitch", label = L.DYNAMIC_PITCH, type = "toggle", src = "command",
		  tip = L.DYNAMIC_PITCH_TIP .. EXPERIMENTAL },
		{ cvar = "test_cameraDynamicPitchBaseFovPad", label = L.DYNAMIC_PITCH_YOUR_CHARACTERS_HEIGHT, type = "slider",
		  min = 0, max = 1, step = 0.05, src = "probe",
		  tip = L.DYNAMIC_PITCH_YOUR_CHARACTERS_HEIGHT_TIP .. EXPERIMENTAL },
		{ cvar = "test_cameraDynamicPitchBaseFovPadFlying", label = L.DYNAMIC_PITCH_YOUR_CHARACTERS_HEIGHT_WHERE_YOU_CAN_FLY, type = "slider",
		  min = 0, max = 1, step = 0.05, src = "probe",
		  tip = L.DYNAMIC_PITCH_YOUR_CHARACTERS_HEIGHT_WHERE_YOU_CAN_FLY_TIP .. EXPERIMENTAL },
		{ cvar = "test_cameraTargetFocusEnemyEnable", label = L.TURN_TOWARD_YOUR_ENEMY, type = "toggle", src = "command",
		  tip = L.TURN_TOWARD_YOUR_ENEMY_TIP .. EXPERIMENTAL },
		{ cvar = "test_cameraTargetFocusInteractEnable", label = L.TURN_TOWARD_WHAT_YOU_INTERACT_WITH, type = "toggle", src = "command",
		  tip = L.TURN_TOWARD_WHAT_YOU_INTERACT_WITH_TIP .. EXPERIMENTAL },
	} },

	{ title = L.MOUSE, items = {
		{ cvar = "mouseAcceleration", label = L.MOUSE_ACCELERATION, type = "choice", src = "help",
		  options = { { -1, L.USE_THE_DESKTOPS_SETTING }, { 0, L.OFF }, { 1, L.ON } },
		  tip = L.MOUSE_ACCELERATION_TIP },
	} },

	-- Not CVars: the game keeps these with the key bindings (Core.lua's SETTERS).
	-- Its options have menus for five, of ALT, CTRL, SHIFT and NONE. The forms with a
	-- mouse button are Bindings_Camelot.xml's, which has each default.
	{ title = L.MODIFIED_CLICKS, items = {
		{ cvar = "@click:SELFCAST", label = L.SELF_CAST_KEY, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.SELF_CAST_KEY_TIP },
		{ cvar = "@click:FOCUSCAST", label = L.FOCUS_CAST_KEY, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.FOCUS_CAST_KEY_TIP },
		{ cvar = "@click:MOUSEOVERCAST", label = L.MOUSEOVER_CAST_KEY, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.MOUSEOVER_CAST_KEY_TIP },
		{ cvar = "@click:AUTOLOOTTOGGLE", label = L.AUTO_LOOT_KEY, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.AUTO_LOOT_KEY_TIP },
		{ cvar = "@click:PICKUPACTION", label = L.PICK_UP_ACTION_KEY, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.PICK_UP_ACTION_KEY_TIP },
		{ cvar = "@click:CHATLINK", label = L.LINK_IN_CHAT, type = "choice", src = "ui", options = CLICK_BUTTONS,
		  tip = L.LINK_IN_CHAT_TIP },
		{ cvar = "@click:DRESSUP", label = L.TRY_ON, type = "choice", src = "ui", options = CLICK_BUTTONS,
		  tip = L.TRY_ON_TIP },
		{ cvar = "@click:EXPANDITEM", label = L.SHOW_AN_ITEMS_POWERS, type = "choice", src = "ui", options = CLICK_BUTTONS,
		  tip = L.SHOW_AN_ITEMS_POWERS_TIP },
		{ cvar = "@click:SPLITSTACK", label = L.SPLIT_A_STACK, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.SPLIT_A_STACK_TIP },
		{ cvar = "@click:PICKUPITEM", label = L.PICK_UP_A_BANK_BAG, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.PICK_UP_A_BANK_BAG_TIP },
		{ cvar = "@click:OPENALLBAGS", label = L.OPEN_ALL_BAGS, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.OPEN_ALL_BAGS_TIP },
		{ cvar = "@click:COMPAREITEMS", label = L.COMPARE_ITEMS, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.COMPARE_ITEMS_TIP },
		{ cvar = "@click:EXPANDTOOLTIP", label = L.LONGER_TOOLTIP, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.LONGER_TOOLTIP_TIP },
		{ cvar = "@click:MAILAUTOLOOTTOGGLE", label = L.TAKE_ALL_FROM_A_LETTER, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.TAKE_ALL_FROM_A_LETTER_TIP },
		{ cvar = "@click:QUESTWATCHTOGGLE", label = L.TRACK_A_QUEST, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.TRACK_A_QUEST_TIP },
		{ cvar = "@click:RECIPEWATCHTOGGLE", label = L.TRACK_A_RECIPE, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.TRACK_A_RECIPE_TIP },
		{ cvar = "@click:TOKENWATCHTOGGLE", label = L.SHOW_A_CURRENCY_ON_THE_BACKPACK, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.SHOW_A_CURRENCY_ON_THE_BACKPACK_TIP },
		{ cvar = "@click:SHOWITEMFLYOUT", label = L.EQUIPMENT_FLYOUT, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.EQUIPMENT_FLYOUT_TIP },
		{ cvar = "@click:SHOWMULTICASTFLYOUT", label = L.TOTEM_BAR_FLYOUT, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.TOTEM_BAR_FLYOUT_TIP },
		{ cvar = "@click:STICKYCAMERA", label = L.STICKY_CAMERA, type = "choice", src = "ui", options = CLICK_KEYS,
		  tip = L.STICKY_CAMERA_TIP },
	} },

	-- Not a CVar either. Movement keys changed by hand (Custom) are left alone.
	{ title = L.MOVEMENT_KEYS, items = {
		{ cvar = "@keys:TurnStrafe", label = L.TURN_AND_STRAFE_KEYS, type = "choice", src = "ui",
		  options = { { "0", L.ENHANCED }, { "1", L.CLASSIC } },
		  tip = L.TURN_AND_STRAFE_KEYS_TIP },
	} },

	{ title = L.NAMEPLATES, items = {
		{ cvar = "nameplateMotionSpeed", label = L.NAMEPLATE_MOVEMENT_SPEED, type = "slider", min = 0, max = 1, step = 0.005, src = "help",
		  tip = L.NAMEPLATE_MOVEMENT_SPEED_TIP },
	} },

	{ title = L.THREAT, items = {
		{ cvar = "threatWarning", label = L.THREAT_WARNING, type = "choice", src = "help",
		  options = { { 0, L.OFF }, { 1, L.IN_DUNGEONS }, { 2, L.IN_A_PARTY_OR_RAID }, { 3, L.ALWAYS } },
		  tip = L.THREAT_WARNING_TIP },
	} },

	-- Not CVars: console commands that take a value, each tried in the 1.60.1 client
	-- (#71). They're listed under Console commands, after the CVars. The game can't
	-- be asked for the first two's value. data/ranges has what each printed and did.
	{ title = L.CAMERA_AND_PHYSICS, items = {
		{ cvar = "@console:pitchLimit", label = L.CAMERA_TILT_LIMIT, type = "slider", min = 45, max = 90, step = 1, src = "probe",
		  tip = L.CAMERA_TILT_LIMIT_TIP },
		{ cvar = "@console:physEnable", label = L.PHYSICS, type = "toggle", src = "probe",
		  tip = L.PHYSICS_TIP },
	} },
	-- The game's console window, which /console enable turns on. The ranges are the
	-- commands' help: [10-50], and a class with [Red 0-255] [Green 0-255] [Blue 0-255].
	{ title = L.CONSOLE_WINDOW, items = {
		{ cvar = "@console:fontsize", label = L.TEXT_SIZE, type = "slider", min = 10, max = 50, step = 1, src = "help",
		  tip = L.TEXT_SIZE_TIP },
		{ cvar = "@console:fontcolor:input", label = L.COLOR_INPUT, type = "color", src = "help",
		  tip = L.COLOR_INPUT_TIP },
		{ cvar = "@console:fontcolor:echo", label = L.COLOR_ECHO, type = "color", src = "help",
		  tip = L.COLOR_ECHO_TIP },
		{ cvar = "@console:fontcolor:warning", label = L.COLOR_WARNING, type = "color", src = "help",
		  tip = L.COLOR_WARNING_TIP },
		{ cvar = "@console:fontcolor:admin", label = L.COLOR_ADMIN, type = "color", src = "help",
		  tip = L.COLOR_ADMIN_TIP },
		{ cvar = "@console:fontcolor:global", label = L.COLOR_GLOBAL, type = "color", src = "help",
		  tip = L.COLOR_GLOBAL_TIP },
	} },

	{ title = L.SOUND, items = {
		{ cvar = "FootstepSounds", label = L.FOOTSTEPS, type = "toggle", src = "help",
		  tip = L.FOOTSTEPS_TIP },
		{ cvar = "Sound_EnableArmorFoleySoundForSelf", label = L.ARMOR_SOUNDS_YOURS, type = "toggle", src = "probe",
		  tip = L.ARMOR_SOUNDS_YOURS_TIP },
		{ cvar = "Sound_EnableArmorFoleySoundForOthers", label = L.ARMOR_SOUNDS_OTHER_PLAYERS, type = "toggle", src = "probe",
		  tip = L.ARMOR_SOUNDS_OTHER_PLAYERS_TIP },
		{ cvar = "Sound_ListenerAtCharacter", label = L.LISTEN_FROM_YOUR_CHARACTER, type = "toggle", src = "help",
		  tip = L.LISTEN_FROM_YOUR_CHARACTER_TIP },
		{ cvar = "Sound_EnableDSPEffects", label = L.SOUND_PROCESSING_EFFECTS, type = "toggle", src = "probe",
		  tip = L.SOUND_PROCESSING_EFFECTS_TIP },
	} },

	{ title = L.COMBAT_TEXT, items = {
		{ cvar = "classicStyleWorldText", label = L.CLASSIC_COMBAT_TEXT, type = "toggle", src = "help",
		  tip = L.CLASSIC_COMBAT_TEXT_TIP },
	} },

	{ title = L.SPELLS, items = {
		{ cvar = "SpellQueueWindow", label = L.SPELL_QUEUE_WINDOW, type = "slider", min = 0, max = 400, step = 1, src = "probe",
		  tip = L.SPELL_QUEUE_WINDOW_TIP },
	} },

	-- Not CVars, from here on (Core.lua's SETTERS). The game's options lay the bars
	-- out at once; Every Setting's change shows at the next reload (seen in game).
	{ title = L.ACTION_BARS, items = {
		{ cvar = "@bar:2", label = L.ACTION_BAR_2, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_2_TIP },
		{ cvar = "@bar:3", label = L.ACTION_BAR_3, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_3_TIP },
		{ cvar = "@bar:4", label = L.ACTION_BAR_4, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_4_TIP },
		{ cvar = "@bar:5", label = L.ACTION_BAR_5, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_5_TIP },
		{ cvar = "@bar:6", label = L.ACTION_BAR_6, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_6_TIP },
		{ cvar = "@bar:7", label = L.ACTION_BAR_7, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_7_TIP },
		{ cvar = "@bar:8", label = L.ACTION_BAR_8, type = "toggle", src = "ui", restart = "reload", restartSrc = "probe",
		  tip = L.ACTION_BAR_8_TIP },
	} },

	{ title = L.ITEM_QUALITY_COLOURS, items = {
		{ cvar = "@color:Poor", label = L.POOR, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.POOR_TIP },
		{ cvar = "@color:Common", label = L.COMMON, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.COMMON_TIP },
		{ cvar = "@color:Uncommon", label = L.UNCOMMON, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.UNCOMMON_TIP },
		{ cvar = "@color:Rare", label = L.RARE, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.RARE_TIP },
		{ cvar = "@color:Epic", label = L.EPIC, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.EPIC_TIP },
		{ cvar = "@color:Legendary", label = L.LEGENDARY, type = "color", src = "ui", restart = "reload", restartSrc = "ui",
		  tip = L.LEGENDARY_TIP },
	} },

	-- Set for the specialisation in use. A voice is a box, as the voices' CVars
	-- are in the list of every CVar: the game has more (176 here) than a menu shows.
	{ title = L.AUDIO_ALERTS_PER_SPEC, items = {
		{ cvar = "@caa:Resource1Percent", label = L.SAY_YOUR_MAIN_RESOURCE, type = "choice", src = "ui", options = CAA_PERCENT,
		  tip = L.SAY_YOUR_MAIN_RESOURCE_TIP },
		{ cvar = "@caa:Resource1Format", label = L.MAIN_RESOURCE_WHATS_SAID, type = "choice", src = "ui", options = CAA_FORMAT,
		  tip = L.MAIN_RESOURCE_WHATS_SAID_TIP },
		{ cvar = "@caa:Resource1Voice", label = L.MAIN_RESOURCE_VOICE, type = "text", raw = true, src = "ui",
		  tip = L.MAIN_RESOURCE_VOICE_TIP },
		{ cvar = "@caa:Resource1Volume", label = L.MAIN_RESOURCE_VOLUME, type = "slider", min = 0, max = 100, step = 1, src = "ui",
		  tip = L.MAIN_RESOURCE_VOLUME_TIP },
		{ cvar = "@caa:Resource2Percent", label = L.SAY_YOUR_SECOND_RESOURCE, type = "choice", src = "ui", options = CAA_PERCENT,
		  tip = L.SAY_YOUR_SECOND_RESOURCE_TIP },
		{ cvar = "@caa:Resource2Format", label = L.SECOND_RESOURCE_WHATS_SAID, type = "choice", src = "ui", options = CAA_FORMAT,
		  tip = L.SECOND_RESOURCE_WHATS_SAID_TIP },
		{ cvar = "@caa:Resource2Voice", label = L.SECOND_RESOURCE_VOICE, type = "text", raw = true, src = "ui",
		  tip = L.SECOND_RESOURCE_VOICE_TIP },
		{ cvar = "@caa:Resource2Volume", label = L.SECOND_RESOURCE_VOLUME, type = "slider", min = 0, max = 100, step = 1, src = "ui",
		  tip = L.SECOND_RESOURCE_VOLUME_TIP },
		{ cvar = "@caa:SayIfTargeted", label = L.SAY_WHEN_YOURE_TARGETED, type = "choice", src = "ui", options = CAA_TARGETED,
		  tip = L.SAY_WHEN_YOURE_TARGETED_TIP },
	} },

	{ title = L.SOCIAL, items = {
		{ cvar = "@social:DisableChat", label = L.DISABLE_CHAT, type = "toggle", src = "ui",
		  tip = L.DISABLE_CHAT_TIP },
		{ cvar = "@social:BlockGuildInvites", label = L.BLOCK_GUILD_INVITES, type = "toggle", src = "ui",
		  tip = L.BLOCK_GUILD_INVITES_TIP },
		{ cvar = "@social:RecentAlliesSeeLocation", label = L.WHO_SEES_YOUR_LOCATION, type = "choice", src = "ui",
		  options = { { "0", L.FRIENDS_AND_GUILD }, { "1", L.FRIENDS_GUILD_AND_RECENT_ALLIES } },
		  tip = L.WHO_SEES_YOUR_LOCATION_TIP },
	} },

	{ title = L.MINIMAP_TRACKING, items = {
		{ cvar = "@track:Auctioneer", label = L.AUCTIONEER, type = "toggle", src = "ui",
		  tip = L.AUCTIONEER_TIP },
		{ cvar = "@track:Banker", label = L.BANKER, type = "toggle", src = "ui",
		  tip = L.BANKER_TIP },
		{ cvar = "@track:AccountBanker", label = L.BANKER_ACCOUNT_BANK, type = "toggle", src = "ui",
		  tip = L.BANKER_ACCOUNT_BANK_TIP },
		{ cvar = "@track:Barber", label = L.BARBER, type = "toggle", src = "ui",
		  tip = L.BARBER_TIP },
		{ cvar = "@track:Battlemaster", label = L.BATTLEMASTER, type = "toggle", src = "ui",
		  tip = L.BATTLEMASTER_TIP },
		{ cvar = "@track:TaxiNode", label = L.FLIGHT_MASTER, type = "toggle", src = "ui",
		  tip = L.FLIGHT_MASTER_TIP },
		{ cvar = "@track:VenderFood", label = L.FOOD_DRINK, type = "toggle", src = "ui",
		  tip = L.FOOD_DRINK_TIP },
		{ cvar = "@track:VendorAmmo", label = L.AMMUNITION, type = "toggle", src = "ui",
		  tip = L.AMMUNITION_TIP },
		{ cvar = "@track:Innkeeper", label = L.INNKEEPER, type = "toggle", src = "ui",
		  tip = L.INNKEEPER_TIP },
		{ cvar = "@track:ItemUpgrade", label = L.ITEM_UPGRADE, type = "toggle", src = "ui",
		  tip = L.ITEM_UPGRADE_TIP },
		{ cvar = "@track:Mailbox", label = L.MAILBOX, type = "toggle", src = "ui",
		  tip = L.MAILBOX_TIP },
		{ cvar = "@track:TrainerClass", label = L.CLASS_TRAINER, type = "toggle", src = "ui",
		  tip = L.CLASS_TRAINER_TIP },
		{ cvar = "@track:TrainerProfession", label = L.PROFESSION_TRAINERS, type = "toggle", src = "ui",
		  tip = L.PROFESSION_TRAINERS_TIP },
		{ cvar = "@track:VendorReagent", label = L.REAGENTS, type = "toggle", src = "ui",
		  tip = L.REAGENTS_TIP },
		{ cvar = "@track:Repair", label = L.REPAIR, type = "toggle", src = "ui",
		  tip = L.REPAIR_TIP },
		{ cvar = "@track:Stablemaster", label = L.STABLE_MASTER, type = "toggle", src = "ui",
		  tip = L.STABLE_MASTER_TIP },
		{ cvar = "@track:Transmogrifier", label = L.TRANSMOGRIFIER, type = "toggle", src = "ui",
		  tip = L.TRANSMOGRIFIER_TIP },
		{ cvar = "@track:TrivialQuests", label = L.LOW_LEVEL_QUESTS, type = "toggle", src = "ui",
		  tip = L.LOW_LEVEL_QUESTS_TIP },
		{ cvar = "@track:AccountCompletedQuests", label = L.ACCOUNT_COMPLETED_QUESTS, type = "toggle", src = "ui",
		  tip = L.ACCOUNT_COMPLETED_QUESTS_TIP },
		{ cvar = "@track:POI", label = L.POINTS_OF_INTEREST, type = "toggle", src = "ui",
		  tip = L.POINTS_OF_INTEREST_TIP },
		{ cvar = "@track:Target", label = L.TARGET, type = "toggle", src = "ui",
		  tip = L.TARGET_TIP },
		{ cvar = "@track:Focus", label = L.FOCUS_TARGET, type = "toggle", src = "ui",
		  tip = L.FOCUS_TARGET_TIP },
		{ cvar = "@track:QuestPOIs", label = L.TRACK_QUEST_POIS, type = "toggle", src = "ui",
		  tip = L.TRACK_QUEST_POIS_TIP },
		{ cvar = "@track:Digsites", label = L.TRACK_DIGSITES, type = "toggle", src = "ui",
		  tip = L.TRACK_DIGSITES_TIP },
	} },
}

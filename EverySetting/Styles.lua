-- Every Setting's styles: built-in presets that span sections and set a whole look
-- and feel in one pick.
--
-- A style can start from one of the built-in graphics presets (`tier`, an index
-- in EverySetting.TIERS) and then sets its own values (`set`): for knobs the tier
-- doesn't cover, or instead of the tier's. EverySetting.StylePreset (Core.lua) puts
-- the two together. A style without a tier sets only its own values: one part,
-- to pick for that part along with another style.
--
-- Every CVar in `set` is a knob from Knobs.lua, so its range is known, and its
-- value is inside that range. None is secure. Each value says why it's there.

local _, ns = ...
local EverySetting = ns.EverySetting
local L = ns.L

-- Only Cinematic, Immersive and Action set a camera (#56). Competitive, Photo,
-- Ultra+ and True Max set none of the action camera's CVars, not even over the
-- shoulder to 0: the game raises its experimental camera warning when a
-- test_camera CVar is written, whatever the value. So picked after Action they
-- leave the camera over your shoulder, as they leave any other camera.
--
-- The game keeps one of its two motion sickness controls on: its Motion Sickness
-- checkbox swaps CameraKeepCharacterCentered for CameraReduceUnexpectedMovement.
-- Seen in 1.60.1: with the first off, dynamic pitch shows the same with the
-- second on, and over the shoulder doesn't show until the second is off too. So
-- Cinematic and Immersive swap the two as the checkbox does, and Action turns
-- both off. Each style's tip says which, in the game's words for the two.
local SWAPS = " " .. L.STYLE_SWAPS

-- The camera Cinematic and Immersive give, so picking one after Action takes the
-- camera off your shoulder: behind you, tilting down as you zoom out, and turning
-- toward nothing on its own.
local CAMERA = {
	test_cameraOverShoulder = 0, -- behind you, not over your shoulder (Action's)
	CameraKeepCharacterCentered = 0, -- lets dynamic pitch move your character off center
	CameraReduceUnexpectedMovement = 1, -- the game's other motion sickness control, on in its place: dynamic pitch shows with it
	test_cameraDynamicPitch = 1, -- tilts down as you zoom out
	test_cameraTargetFocusEnemyEnable = 0, -- doesn't turn toward the enemy you target
	test_cameraTargetFocusInteractEnable = 0, -- nor toward who you talk to
}

-- A style's own values with CAMERA added.
local function WithCamera(set)
	for cvar, value in pairs(CAMERA) do set[cvar] = value end
	return set
end

EverySetting.STYLES = {
	{ name = L.CINEMATIC, tier = 4, -- Ultra
	  tip = L.CINEMATIC_TIP .. SWAPS,
	  set = WithCamera({
		volumeFog = 1, -- Ultra's fog quality does nothing with fog off
		bloomEnable = 1, -- glow around bright lights
		shadowBlendCascades = 1, -- hides the line between shadow bands
		ffxGlow = 1, -- the soft full-screen glow
		specular = 1, -- full shine
		showfootprintparticles = 1, -- footprints and dust
		cameraYawMoveSpeed = 90, -- mouse look at half speed: the slowest the game's own slider goes
		cameraPitchMoveSpeed = 45, -- half of that, as the game's slider sets it
		cameraYawSmoothSpeed = 100, -- the camera trails behind at about half pace
		cameraPitchSmoothSpeed = 25, -- a quarter of that, as the game's slider sets it
		cameraZSmooth = 2, -- smooths the camera's height while standing still too
		cameraZoomSpeed = 10, -- zooms at half speed
		cameraDistanceRateMult = 0.5, -- glides to its new distance at half rate
	  }) },

	{ name = L.IMMERSIVE, tier = 3, -- High
	  tip = L.IMMERSIVE_TIP .. SWAPS,
	  set = WithCamera({
		volumeFog = 1, -- High's fog quality does nothing with fog off
		bloomEnable = 1, -- glow around bright lights
		shadowBlendCascades = 1, -- hides the line between shadow bands
		ffxGlow = 1, -- the soft full-screen glow
		specular = 1, -- full shine
		showfootprintparticles = 1, -- footprints and dust
		FootstepSounds = 1, -- the game's sound defaults, pinned so the feel is whole
		Sound_EnableArmorFoleySoundForSelf = 1,
		Sound_EnableArmorFoleySoundForOthers = 1,
		Sound_ListenerAtCharacter = 1, -- you hear the world from where your character stands
		Sound_EnableDSPEffects = 1,
	  }) },

	{ name = L.COMPETITIVE, tier = 2, -- Medium: Low's view distance and particles cost clarity
	  tip = L.COMPETITIVE_TIP,
	  set = {
		groundEffectDensity = 16, -- the least grass, which hides effects on the ground
		groundEffectDist = 40, -- the same
		weatherDensity = 0, -- no rain or snow in the way
		particleDensity = 50, -- the game's middle level: very low values hide spell effects
		reflectionMode = 0, -- reflections cost frames and show nothing useful
		volumeFog = 0, -- no haze over the distance
		bloomEnable = 0, -- no glare
		ffxGlow = 0, -- a crisper picture
		showfootprintparticles = 0, -- less dust underfoot
		cameraDistanceMaxZoomFactor = 4, -- as far out as the client allows
	  } },

	{ name = L.PHOTO, tier = 4, -- Ultra
	  tip = L.PHOTO_TIP,
	  set = {
		shadowTextureSize = 4096, -- sharper shadows than Ultra's 2048
		groundEffectDensity = 256, -- thicker ground cover than Ultra's 48
		groundEffectDist = 500, -- ground cover further out than Ultra's 320
		volumeFog = 1, -- Ultra's fog quality does nothing with fog off
		bloomEnable = 1, -- glow around bright lights
		shadowBlendCascades = 1, -- hides the line between shadow bands
		ffxGlow = 1, -- the soft full-screen glow
		specular = 1, -- full shine
		showfootprintparticles = 1, -- footprints and dust
		CMAA2Quality = 3, -- the top quality, when CMAA2 is the anti-aliasing in use
		screenshotFormat = "png", -- no detail lost
		screenshotQuality = 10, -- the best JPEG, if the format is switched back
		cameraDistanceMaxZoomFactor = 4, -- room to frame a shot
	  } },

	{ name = L.ULTRA_PLUS, tier = 4, -- Ultra, plus the effects its quality settings leave alone (not "Ultra", which is the built-in preset)
	  tip = L.ULTRA_PLUS_TIP,
	  set = {
		volumeFog = 1, -- Ultra's fog quality does nothing with fog off
		bloomEnable = 1, -- glow around bright lights
		shadowBlendCascades = 1, -- hides the line between shadow bands
		ffxGlow = 1, -- the soft full-screen glow
		specular = 1, -- full shine
		showfootprintparticles = 1, -- footprints and dust
	  } },

	{ name = L.TRUE_MAX, tier = 4, -- Ultra, where that's already the far end of the knob's range. Called Eleven when the addon was Up to Eleven.
	  tip = L.TRUE_MAX_TIP,
	  set = {
		groundEffectDensity = 256, -- the knob's maximum (Ultra: 48)
		groundEffectDist = 500, -- the knob's maximum (Ultra: 320)
		lodObjectFadeScale = 5000, -- the knob's maximum (Ultra: 150)
		lodObjectCullSize = 1, -- the knob's minimum, which draws the smallest objects (Ultra: 14)
		shadowTextureSize = 4096, -- the biggest option (Ultra: 2048)
		volumeFog = 1, -- Ultra's fog quality does nothing with fog off
		bloomEnable = 1, -- every effect on, from here down
		shadowBlendCascades = 1,
		ffxGlow = 1,
		ffxDeath = 1,
		ffxNether = 1,
		specular = 1,
		showfootprintparticles = 1,
		CMAA2Quality = 3, -- the top quality, when CMAA2 is the anti-aliasing in use
		DynamicRenderScale = 0, -- never lower the render scale to hold a frame rate
	  } },

	{ name = L.ACTION, -- no tier: just the action camera, to pick for that part with any style
	  tip = L.ACTION_TIP,
	  set = {
		test_cameraOverShoulder = 1, -- you look past your character's shoulder
		CameraKeepCharacterCentered = 0, -- over the shoulder doesn't show while it's on
		CameraReduceUnexpectedMovement = 0, -- nor while this is: Cinematic and Immersive turn it on
		test_cameraDynamicPitch = 1, -- tilts down as you zoom out
		test_cameraTargetFocusEnemyEnable = 1, -- keeps the enemy you target in view
		test_cameraTargetFocusInteractEnable = 1, -- turns toward who you talk to
	  } },
}

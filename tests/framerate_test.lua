-- The frame rate before and after a change to a graphics setting, or a style:
-- GetFramerate() averaged over the seconds either side, skipped while the scene
-- moves, and said in the status line. And what a heavy setting says it costs.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a graphics knob that costs frame rate, one that
-- doesn't, a camera knob and two styles. The frame rate limits are the game's
-- defaults: no cap, a cap of 30 in the background, vertical sync on.
local function Start(saved)
	local K, ns = W.Load(saved)
	W.AddCVar("groundEffectDensity", "16")
	W.AddCVar("ffxGlow", "1")
	W.AddCVar("cameraZoomSpeed", "20")
	W.AddCVar("maxFPS", "120")
	W.AddCVar("useMaxFPS", "0")
	W.AddCVar("maxFPSBk", "30")
	W.AddCVar("useMaxFPSBk", "1")
	W.AddCVar("vsync", "1")
	K.GROUPS = {
		{ title = "Ground clutter", items = {
			{ cvar = "groundEffectDensity", label = "Ground clutter density", tip = "How thick the grass is.", type = "slider",
			  min = 16, max = 256, step = 8, src = "probe", cost = "heavy", costSrc = "probe" },
			{ cvar = "ffxGlow", label = "Glow", tip = "A glow.", type = "toggle", src = "help" },
		} },
		{ title = "Camera", items = {
			{ cvar = "cameraZoomSpeed", label = "Zoom speed", tip = "How fast it zooms.", type = "slider", min = 1, max = 50, step = 1, src = "probe" },
		} },
	}
	K.SECTIONS = { "Graphics", "Camera" }
	K.CVARS = { groundEffectDensity = "1", ffxGlow = "1", cameraZoomSpeed = "2", maxFPS = "1", useMaxFPS = "1", maxFPSBk = "1", useMaxFPSBk = "1", vsync = "1" }
	K.STYLES = {
		{ name = "Thick", tip = "A test.", set = { groundEffectDensity = 256, ffxGlow = 1 } },
		{ name = "Fast", tip = "A test.", set = { cameraZoomSpeed = 50 } },
	}
	W.Login()
	return K, ns.Options
end

local function Status(o) return o.refs.status:GetText() end

-- Moves the clock on by `seconds` at `fps`.
local function Run(seconds, fps)
	W.fps = fps
	W.Advance(seconds)
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

local function Tip(row)
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	return table.concat(lines, "\n")
end

T.test("framerate: a change to a graphics setting is read before and after, averaged, and said in the status line", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	-- Two seconds before, at 70 and 90 in turn: 80 on average.
	Run(1, 60) -- older than the two seconds, so left out
	for _ = 1, 4 do Run(0.25, 70) Run(0.25, 90) end
	K.Set("groundEffectDensity", 256)
	T.eq(Status(o), "Ground clutter density 16 to 256: measuring the frame rate...")
	Run(1, 20) -- the second after the change settles, and is left out
	Run(3, 60)
	local r = K.Reading()
	T.eq(r.before, 80, "the mean of the two seconds before")
	T.eq(r.after, 60, "and of the three after the settle")
	T.eq(Status(o), "Ground clutter density 16 to 256: 80 to 60 fps, vsync on")
	Run(5, 60)
	T.eq(Status(o), "Ground clutter density 16 to 256: 80 to 60 fps, vsync on", "it stays while the window is open")
	EverySetting_OpenOptions()
	EverySetting_OpenOptions()
	T.ok(Status(o):find("setting kept", 1, true), "and is let go when it opens again")
end)

T.test("framerate: only for graphics, and only while the window is open", function()
	local K, o = Start()
	K.Set("groundEffectDensity", 256)
	T.eq(K.Reading(), nil, "nothing is read with the window closed")
	EverySetting_OpenOptions()
	Run(3, 60)
	K.Set("cameraZoomSpeed", 40)
	T.eq(K.Reading(), nil, "a camera setting isn't read")
	K.Set("ffxGlow", 1)
	T.eq(K.Reading(), nil, "nor a change to the value it has")
	K.Set("ffxGlow", 0)
	T.eq(Status(o), "Glow On to Off: measuring the frame rate...")
	-- Closed while it's under way, the window still gets the reading, and the sampling then stops.
	EverySetting_OpenOptions()
	Run(5, 60)
	T.eq(K.Reading().after, 60)
	T.eq(#W.timers, 0, "sampling stops once it's done")
end)

T.test("framerate: skipped while moving, turning, with the camera moving, in combat, or too soon", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	T.eq(K.Set("groundEffectDensity", 24), "24")
	T.eq(Status(o), "Ground clutter density 16 to 24: no frame rate, too soon to measure.", "the window has only just opened")
	Run(3, 60)
	K.Set("groundEffectDensity", 32)
	Run(1, 60)
	K.Set("groundEffectDensity", 40)
	T.eq(Status(o), "Ground clutter density 32 to 40: no frame rate, too soon to measure.", "the last change is under two seconds old")

	local function Try(what, move, stop)
		Run(5, 60)
		K.Set("groundEffectDensity", K.Get("groundEffectDensity") == "48" and 56 or 48)
		Run(1, 60)
		move()
		Run(0.5, 60)
		stop()
		Run(3, 60)
		T.ok(Status(o):find("no frame rate, " .. what .. "%.$"), what .. ": " .. Status(o))
	end
	Try("you moved", function() W.speed = 7 end, function() W.speed = 0 end)
	Try("you moved", function() W.falling = true end, function() W.falling = false end)
	Try("the camera moved", function() W.facing = 1.5 end, function() end)
	Try("the camera moved", function() W.zoom = 20 end, function() end)
	Try("the camera moved", function() W.mouselook = true end, function() W.mouselook = false end)
	Try("the camera moved", function() W.leftButton = true end, function() W.leftButton = false end)
	Try("in combat", function() W.Combat(true) end, function() W.Combat(false) end)

	-- The left button held over the window is a click or a drag there, not the camera.
	rawset(EverySettingOptions, "IsMouseOver", function() return true end)
	Run(5, 60)
	W.leftButton = true
	Run(1, 60)
	K.Set("groundEffectDensity", 64)
	Run(4, 60)
	W.leftButton = false
	T.ok(Status(o):find(" to 64: 60 to 60 fps, vsync on$"), Status(o))
	rawset(EverySettingOptions, "IsMouseOver", nil)

	-- Moving before the change counts too.
	Run(5, 60)
	W.speed = 7
	Run(0.5, 60)
	W.speed = 0
	K.Set("groundEffectDensity", 72)
	T.eq(Status(o), "Ground clutter density 64 to 72: no frame rate, you moved.", "moving before the change")
end)

T.test("framerate: the status line says when a frame rate cap is in the way, or vertical sync is on", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	C_CVar.SetCVar("useMaxFPS", "1")
	C_CVar.SetCVar("maxFPS", "60")
	Run(3, 59)
	K.Set("groundEffectDensity", 256)
	Run(4, 41)
	T.eq(Status(o), "Ground clutter density 16 to 256: 59 to 41 fps|cffff7059, capped at 60|r", "the reading before sits at the cap")
	C_CVar.SetCVar("useMaxFPS", "0")
	Run(3, 30)
	K.Set("groundEffectDensity", 16)
	Run(4, 30)
	T.eq(Status(o), "Ground clutter density 256 to 16: 30 to 30 fps|cffff7059, capped at 30|r", "or at the cap in the background")
	C_CVar.SetCVar("vsync", "0")
	Run(3, 50)
	K.Set("groundEffectDensity", 256)
	Run(4, 40)
	T.eq(Status(o), "Ground clutter density 16 to 256: 50 to 40 fps", "nothing in the way")
end)

T.test("framerate: applying a style is read the same, and the style remembers it", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	Run(3, 80)
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	T.eq(MenuItem("Thick").tip, "A test.\n\nSets 2 settings.", "nothing to remember yet")
	W.Run(MenuItem("Thick"), "OnClick")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(C_CVar.GetCVar("groundEffectDensity"), "256")
	T.eq(Status(o), "Thick: measuring the frame rate...")
	Run(4, 40)
	T.eq(Status(o), "Thick: 80 to 40 fps, vsync on")
	T.eq(EverySettingDB.fps.Thick[1], 80, "kept for this machine")
	T.eq(EverySettingDB.fps.Thick[2], 40)
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	T.eq(MenuItem("Thick").tip, "A test.\n\nSets 2 settings.\n\nThe last time you applied it here: 80 to 40 fps.", "the style's tip has the number")
	W.Run(o.refs.stylesPanel.cancel, "OnClick")

	-- A style that sets nothing in Graphics isn't read.
	Run(5, 40)
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Fast"), "OnClick")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(C_CVar.GetCVar("cameraZoomSpeed"), "50")
	T.eq(Status(o), "Thick: 80 to 40 fps, vsync on", "the last reading stays")

	-- A preset picked for one part is read under its name and the part's, and isn't remembered.
	Run(5, 40)
	K.ApplyPreset({ groundEffectDensity = "16" }, "Thick for Ground clutter")
	Run(4, 70)
	T.eq(Status(o), "Thick for Ground clutter: 40 to 70 fps, vsync on")
	T.eq(EverySettingDB.fps.Thick[2], 40)

	-- After a reload, the number is still there.
	local saved = EverySettingDB
	local K2 = Start(saved)
	T.eq(select(2, K2.StyleFramerate("Thick")), 40)
end)

T.test("framerate: a heavy setting says so under its name and in its tooltip, with where that comes from", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	local row = RowFor(o, "groundEffectDensity")
	T.eq(row.past:GetText(), "|cffff7059heavy|r", "a small mark under the name")
	local tip = Tip(row)
	T.ok(tip:find("Heavy: turned up, this can cost a lot of frame rate. Measured in the game (RANGES.md has the numbers).", 1, true), tip)
	T.ok(tip:find("The top of the window shows the frame rate before and after you change it.", 1, true))
	row = RowFor(o, "ffxGlow")
	T.eq(row.past:GetText(), "", "nothing on a setting with no cost")
	T.ok(not Tip(row):find("frame rate", 1, true))
end)

-- Labels.lua: the game's own names for the CVars its options menu has, read
-- from the game's strings in the game's language.

local T = ...
local W = dofile("tests/wow.lua")

-- The game's strings, as globals, for a client in English.
local STRINGS = {
	FOLLOW_TERRAIN = "Follow Terrain",
	OPTION_TOOLTIP_FOLLOW_TERRAIN = "Adjust camera pitch to follow the terrain.",
}

-- Gives the client `strings` of STRINGS, and takes the rest away.
local function Strings(strings)
	for name in pairs(STRINGS) do _G[name] = nil end
	for _, name in ipairs(strings) do _G[name] = STRINGS[name] end
end

-- A logged-in client with the window open, with two of the game's CVars: one
-- its options menu has, and one it hasn't.
local function Open()
	local EverySetting, ns = W.Load()
	W.AddCVar("cameraTerrainTilt", "0", { help = "Turn on terrain tilt" })
	W.AddCVar("cameraTerrainTiltTimeMin", "0", { help = "Seconds before the camera tilts" })
	EverySetting.GROUPS = {}
	EverySetting.SECTIONS = { "Camera" }
	EverySetting.CVARS = { cameraTerrainTilt = "1|t", cameraTerrainTiltTimeMin = "1" }
	EverySetting.NAMES = {} -- the game's names only, no plain names
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

-- The CVars the list shows, in order.
local function Shown(o)
	local out = {}
	for _, item in ipairs(o.view) do
		if item.knob then out[#out + 1] = item.knob.cvar end
	end
	return table.concat(out, " ")
end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

T.test("labels: every CVar in each game's table is one that game's client has, and only the names of the game's strings", function()
	local EverySetting = W.Load()
	for game, path in pairs({ forever = "data/cvars.lua", retail = "data/ranges/70783/retail/cvars.lua" }) do
		local client = {}
		for _, cvar in ipairs(dofile(path).cvars) do client[cvar[1]] = true end
		local count = 0
		for cvar, names in pairs(EverySetting.LABELS[game]) do
			T.ok(client[cvar], cvar .. " isn't a CVar in " .. path)
			T.ok(type(names[1]) == "string" and names[1]:match("^[%u_][%u%d_]*$"), cvar .. ": its label isn't a string's name")
			T.ok(names[2] == nil or names[2]:match("^[%u_][%u%d_]*$"), cvar .. ": its tooltip isn't a string's name")
			count = count + 1
		end
		T.ok(count > 200, game .. "'s list looks short: " .. count)
	end
end)

T.test("labels: each game names a row by its own options menu", function()
	_G.FOLLOW_TERRAIN, _G.SHOW_TOAST_BROADCAST_TEXT = "Follow Terrain", "Broadcast Updates"
	for _, game in ipairs({ "forever", "retail" }) do
		local EverySetting = W.Load(nil, nil, nil, game)
		W.AddCVar("cameraTerrainTilt", "0")
		W.AddCVar("showToastBroadcast", "0")
		W.Login()
		local tilt, broadcast = EverySetting.RawKnob("cameraTerrainTilt", ""), EverySetting.RawKnob("showToastBroadcast", "")
		-- Forever's menu has Follow Terrain, and retail's has Broadcast Updates. Retail's
		-- hasn't Follow Terrain: there it's the plain name CVars.lua gives it.
		T.eq(tilt.label, game == "forever" and "Follow Terrain" or "Follow terrain", game)
		T.eq(broadcast.label, game == "retail" and "Broadcast Updates" or "showToastBroadcast", game)
	end
	_G.FOLLOW_TERRAIN, _G.SHOW_TOAST_BROADCAST_TEXT = nil, nil
end)

T.test("labels: a row the game names shows its name, the CVar under it, and the game's tooltip", function()
	Strings({ "FOLLOW_TERRAIN", "OPTION_TOOLTIP_FOLLOW_TERRAIN" })
	local _, o = Open()
	o.refs.search:SetText("terrain")
	local row = RowFor(o, "cameraTerrainTilt")
	T.eq(row.label:GetText(), "Follow Terrain")
	T.eq(row.past:GetText(), "|cff888888cameraTerrainTilt|r", "the CVar, under it")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	T.eq(GameTooltip:GetText(), "Follow Terrain")
	T.ok(lines[1]:find("Adjust camera pitch to follow the terrain.", 1, true), "the game's tooltip")
	T.ok(not lines[1]:find("Turn on terrain tilt", 1, true), "in place of the CVar's help")
	T.ok(lines[1]:find("CVar: cameraTerrainTilt.", 1, true), "and the CVar's name at the end")
	T.ok(not lines[1]:find("no plain name", 1, true), "and no word of a name it lacks")
	-- One the menu doesn't have keeps its CVar's name, nothing under it, and its tooltip says why.
	row = RowFor(o, "cameraTerrainTiltTimeMin")
	T.eq(row.label:GetText(), "cameraTerrainTiltTimeMin")
	T.eq(row.past:GetText(), "")
	lines = {}
	W.Run(row.name, "OnEnter")
	T.ok(lines[1]:find("no plain name for this one yet, so it's listed by its CVar's name.|r\n\n|cff888888CVar: cameraTerrainTiltTimeMin.", 1, true),
		"no plain name yet, just before the CVar's name: " .. lines[1])
	Strings({})
end)

T.test("labels: search finds a row by the game's name and by the CVar", function()
	Strings({ "FOLLOW_TERRAIN", "OPTION_TOOLTIP_FOLLOW_TERRAIN" })
	local _, o = Open()
	o.refs.search:SetText("follow terrain")
	T.eq(Shown(o), "cameraTerrainTilt")
	o.refs.search:SetText("cameraTerrainTilt")
	T.eq(Shown(o), "cameraTerrainTilt cameraTerrainTiltTimeMin")
	o.refs.search:SetText("camera pitch")
	T.eq(Shown(o), "cameraTerrainTilt", "and by the game's tooltip")
	Strings({})
end)

T.test("labels: a string the client doesn't have leaves the CVar's name and help", function()
	Strings({})
	local EverySetting = Open()
	local knob = EverySetting.RawKnob("cameraTerrainTilt", "Turn on terrain tilt")
	T.eq(knob.label, "cameraTerrainTilt")
	T.eq(knob.tip, "Turn on terrain tilt")
	T.eq(knob.named, nil)
	-- The tooltip alone is still the game's.
	_G.OPTION_TOOLTIP_FOLLOW_TERRAIN = STRINGS.OPTION_TOOLTIP_FOLLOW_TERRAIN
	EverySetting = Open()
	knob = EverySetting.RawKnob("cameraTerrainTilt", "Turn on terrain tilt")
	T.eq(knob.label, "cameraTerrainTilt")
	T.eq(knob.tip, STRINGS.OPTION_TOOLTIP_FOLLOW_TERRAIN)
	Strings({})
end)

T.test("labels: a tuned knob keeps its own name", function()
	local EverySetting = W.Load()
	local strings = EverySetting.LABELS.forever.cameraDistanceMaxZoomFactor
	T.ok(strings, "a tuned knob the game's menu has too")
	_G[strings[1]] = "The game's name"
	W.AddCVar("cameraDistanceMaxZoomFactor", "1.9")
	W.Login()
	local knob = EverySetting.RawKnob("cameraDistanceMaxZoomFactor", "")
	T.ok(not knob.raw and knob.label ~= "The game's name", "Knobs.lua's: " .. knob.label)
	_G[strings[1]] = nil
end)

Strings({})

T.test("labels: settings the game makes in other ways than a Setup call have their names too", function()
	local LABELS = W.Load().LABELS
	for _, game in ipairs({ "forever", "retail" }) do
		local labels = LABELS[game]
		-- A proxy that gets and sets one CVar (Settings.CreateCVarAccessorClosures).
		T.eq(labels.vsync and labels.vsync[1], "VERTICAL_SYNC", game .. ": vsync")
		T.eq(labels.maxFPS and labels.maxFPS[1], "MAXFPS", game .. ": maxFPS")
		-- The label the control shows, where the code registers both settings as Render Scale.
		T.eq(labels.useUiScale and labels.useUiScale[1], "USE_UISCALE", game .. ": useUiScale")
		T.eq(labels.uiScale and labels.uiScale[1], "UI_SCALE", game .. ": uiScale")
		-- And the setting's own where the control gives both the same.
		T.eq(labels.Sound_EnableGameplaySFX and labels.Sound_EnableGameplaySFX[1], "ENABLE_GAMEPLAY_SFX", game)
	end
	-- The gamepad settings' own slider, and a menu of ticks, which only Forever's menu has.
	T.eq(LABELS.forever.GamePadCameraPitchSpeed[1], "GAMEPAD_PITCH_SPEED")
	T.eq(LABELS.forever.floatingCombatTextAuras_v2[1], "COMBAT_TEXT_SHOW_AURAS_TEXT")
	T.eq(LABELS.forever.floatingCombatTextAuras_v2[2], "OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURAS")
end)

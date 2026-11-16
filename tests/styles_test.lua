-- Styles.lua: every style is well formed, sets only knobs, and keeps each
-- value inside the knob's range. Then the window's Styles panel.

local T = ...
local W = dofile("tests/wow.lua")

local EverySetting = W.Load()
local STYLES = EverySetting.STYLES
local client = {} -- lower-case CVar name -> { name, default, category, help, flags }
for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do client[cvar[1]:lower()] = cvar end

local knobs = {} -- CVar name -> knob
for _, group in ipairs(EverySetting.GROUPS) do
	for _, knob in ipairs(group.items) do knobs[knob.cvar] = knob end
end

local function Count(t)
	local n = 0
	for _ in pairs(t) do n = n + 1 end
	return n
end

T.test("styles: each has a name, a description, a built-in preset to start from and values of its own", function()
	T.ok(#STYLES > 0, "no styles")
	local seen = {}
	for _, style in ipairs(STYLES) do
		local name = tostring(style.name)
		T.ok(type(style.name) == "string" and style.name ~= "", "a style has no name")
		T.ok(not seen[name:lower()], name .. " is listed twice")
		T.ok(name:lower() ~= "keep mine" and name:lower() ~= "mixed", "Keep mine and Mixed are the Styles panel's own words")
		seen[name:lower()] = true
		T.ok(type(style.tip) == "string" and style.tip:match("%.$"), name .. " needs a tip that ends in a full stop")
		T.ok(style.tier == nil or EverySetting.TIERS[style.tier], name .. ": tier, if it has one, must be one of the built-in presets")
		T.ok(type(style.set) == "table" and next(style.set), name .. " sets nothing of its own")
	end
	T.ok(seen.cinematic, "Cinematic is one of them")
end)

T.test("styles: every CVar is a knob, and its value is in the knob's range or one of its options", function()
	for _, style in ipairs(STYLES) do
		for cvar, value in pairs(style.set) do
			local what = style.name .. ": " .. cvar
			local knob = knobs[cvar]
			T.ok(knob, what .. " isn't a knob in Knobs.lua (spelled as the knob spells it)")
			local shown = EverySetting.Normalize(knob, value)
			T.ok(shown ~= nil and (tonumber(shown) or shown) == value, what .. " = " .. tostring(value) .. " isn't a value the knob can show")
		end
	end
end)

T.test("styles: none sets a CVar that's secure, locked or read-only", function()
	for _, style in ipairs(STYLES) do
		for cvar in pairs(style.set) do
			T.ok(not client[cvar:lower()][5]:find("[slr]"), style.name .. ": " .. cvar .. " is secure, locked or read-only in the client")
		end
	end
end)

T.test("styles: a value isn't restated when the built-in preset already gives it", function()
	for _, style in ipairs(STYLES) do
		for cvar, value in pairs(style.set) do
			local tiers = knobs[cvar].tiers
			T.ok(not tiers or tiers[style.tier] ~= value, style.name .. ": " .. cvar .. " is what " .. tostring(EverySetting.TIERS[style.tier]) .. " sets already")
		end
	end
end)

-------------------------------------------------------------------------------
-- StylePreset and the window
-------------------------------------------------------------------------------

-- A logged-in client with two sections, a style that sets CVars in both, one
-- that leaves Camera alone, and a group (Sound) that no style sets.
local function Start()
	local K, ns = W.Load()
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	W.AddCVar("shadowSoft", "1")
	W.AddCVar("ffxGlow", "1")
	W.AddCVar("cameraZoomSpeed", "20")
	W.AddCVar("FootstepSounds", "1")
	K.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100,
			  raid = "RAIDfarclip", tiers = { 3000, 5000, 7000, 10000 } },
		} },
		{ title = "Shadows", items = {
			{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle", tiers = { 0, 0, 0, 1 } },
			{ cvar = "ffxGlow", label = "Glow", type = "toggle" },
			{ cvar = "sunShafts", label = "Sun shafts", type = "toggle", tiers = { 0, 0, 1, 1 } }, -- not in this client
		} },
		{ title = "Camera", items = {
			{ cvar = "cameraZoomSpeed", label = "Zoom speed", type = "slider", min = 1, max = 50, step = 1 },
		} },
		{ title = "Sound", items = {
			{ cvar = "FootstepSounds", label = "Footsteps", type = "toggle" },
		} },
	}
	K.SECTIONS = { "Graphics", "Camera" }
	K.CVARS = { farclip = "1", RAIDfarclip = "1", shadowSoft = "1", ffxGlow = "1", sunShafts = "1", cameraZoomSpeed = "2", FootstepSounds = "2" }
	K.STYLES = {
		{ name = "Film", tier = 4, tip = "A test.", set = { ffxGlow = 0, cameraZoomSpeed = 10 } },
		{ name = "Fight", tier = 2, tip = "A test.", set = { farclip = 4000 } },
	}
	W.Login()
	return K, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

-- The open menu's items and headings, in order.
local function Menu()
	local labels = {}
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and (w.value ~= nil or w.heading) and w:IsVisible() then labels[#labels + 1] = w.label:GetText() end
	end
	return table.concat(labels, ", ")
end

T.test("styles: a style's preset is its built-in preset's values, then its own", function()
	local K = Start()
	local film = K.StylePreset(K.STYLES[1])
	T.eq(film.farclip, "10000", "from Ultra")
	T.eq(film.shadowSoft, "1", "from Ultra")
	T.eq(film.ffxGlow, "0", "its own")
	T.eq(film.cameraZoomSpeed, "10", "its own, in another section")
	T.eq(film.sunShafts, nil, "a knob the client lacks is left out")
	T.eq(Count(film), 4)
	local fight = K.StylePreset(K.STYLES[2])
	T.eq(fight.farclip, "4000", "its own value, not Medium's")
	T.eq(fight.shadowSoft, "0", "from Medium")
	T.eq(Count(fight), 2)
	local part = K.StylePreset(K.STYLES[1], K.GROUPS[2])
	T.eq(part.shadowSoft, "1", "one part: the group's knobs")
	T.eq(part.ffxGlow, "0")
	T.eq(Count(part), 2)
	T.eq(next(K.StylePreset(K.STYLES[2], K.GROUPS[3])), nil, "a part the style leaves alone is empty")
end)

T.test("styles: how many settings each one pins in the Forever client", function()
	W.Load()
	for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	local want = { Cinematic = 47, Immersive = 45, Competitive = 33, Photo = 38, ["Ultra+"] = 34, ["True Max"] = 38, Action = 6 }
	for _, style in ipairs(_G.EverySetting.STYLES) do
		T.eq(Count(_G.EverySetting.StylePreset(style)), want[style.name], style.name .. ": how many settings it pins")
	end
end)

-------------------------------------------------------------------------------
-- The camera, and the game's two motion sickness controls
-------------------------------------------------------------------------------

local CENTERED, REDUCED, SHOULDER = "CameraKeepCharacterCentered", "CameraReduceUnexpectedMovement", "test_cameraOverShoulder"

-- Whether a CVar is one of the game's experimental camera settings, or one of
-- its two motion sickness controls.
local function IsCamera(cvar)
	return cvar:find("^test_camera") ~= nil or cvar == CENTERED or cvar == REDUCED
end

-- A logged-in Forever client with every CVar at the game's default.
local function Forever()
	local K = W.Load()
	for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	return K
end

-- Applies the style `name` whole, as the Styles panel does with every row on it.
local function ApplyStyle(K, name)
	for _, style in ipairs(K.STYLES) do
		if style.name == name then return K.ApplyPreset(K.StylePreset(style)) end
	end
	error("no style " .. name)
end

T.test("styles: only Cinematic, Immersive and Action set the camera or a motion sickness control", function()
	local sets = {}
	for _, style in ipairs(STYLES) do
		for cvar in pairs(style.set) do
			if IsCamera(cvar) then sets[#sets + 1] = style.name .. ":" .. cvar end
		end
	end
	table.sort(sets)
	local names = {}
	for _, set in ipairs(sets) do
		local name = set:match("^[^:]+")
		if names[#names] ~= name then names[#names + 1] = name end
	end
	T.eq(table.concat(names, ", "), "Action, Cinematic, Immersive")
end)

T.test("styles: Competitive, Photo, Ultra+ and True Max write no camera CVar, so the game's warning has nothing to ask about", function()
	for _, name in ipairs({ "Competitive", "Photo", "Ultra+", "True Max" }) do
		local K = Forever()
		local before = #W.sets
		ApplyStyle(K, name)
		T.ok(#W.sets > before, name .. " sets something")
		for i = before + 1, #W.sets do
			T.ok(not IsCamera(W.sets[i][1]), name .. " wrote " .. W.sets[i][1])
		end
		T.eq(Get(CENTERED), "1", name .. ": the game's default motion sickness control is still on")
		T.eq(Get(REDUCED), "0", name)
	end
end)

T.test("styles: Cinematic and Immersive swap the game's motion sickness controls, as its Motion Sickness checkbox does", function()
	for _, name in ipairs({ "Cinematic", "Immersive" }) do
		local K = Forever()
		ApplyStyle(K, name)
		T.eq(Get(CENTERED), "0", name .. ": dynamic pitch moves your character off center")
		T.eq(Get(REDUCED), "1", name .. ": the other control, on in its place")
		T.eq(tonumber(Get("test_cameraDynamicPitch")), 1, name)
		T.ok(K.IsStored(REDUCED), name .. " keeps it")
	end
end)

T.test("styles: a style that turns off keeping your character centered says so, in the game's words", function()
	for _, style in ipairs(STYLES) do
		if style.set[CENTERED] == 0 then
			T.ok(style.tip:find("motion sickness control", 1, true) and style.tip:find("keeps your character centered", 1, true)
				and style.tip:find("reduces camera movement", 1, true), style.name .. "'s tip names both controls")
			-- Only the action camera alone leaves both off: over the shoulder doesn't show while either is on.
			if style.set[REDUCED] ~= 1 then
				T.eq(style.name, "Action", "the one style that leaves both off")
				T.eq(style.tier, nil, "it's the camera alone")
				T.eq(style.set[SHOULDER], 1)
				T.ok(style.tip:find("turns off both", 1, true), "and its tip says both")
			end
		else
			T.eq(style.set[REDUCED], nil, style.name .. " leaves the other control alone too")
		end
	end
end)

T.test("styles: Action after Cinematic is over the shoulder with both controls off, and Immersive after it swaps them back", function()
	local K = Forever()
	ApplyStyle(K, "Cinematic")
	ApplyStyle(K, "Action")
	T.eq(tonumber(Get(SHOULDER)), 1)
	T.eq(Get(CENTERED), "0")
	T.eq(Get(REDUCED), "0", "over the shoulder doesn't show while it's on")
	ApplyStyle(K, "Immersive")
	T.eq(tonumber(Get(SHOULDER)), 0, "off your shoulder")
	T.eq(Get(REDUCED), "1")
end)

T.test("styles: Competitive after Action leaves the camera over your shoulder", function()
	local K = Forever()
	ApplyStyle(K, "Action")
	local before = #W.sets
	ApplyStyle(K, "Competitive")
	for i = before + 1, #W.sets do
		T.ok(not IsCamera(W.sets[i][1]), "Competitive wrote " .. W.sets[i][1])
	end
	T.eq(tonumber(Get(SHOULDER)), 1, "as Action left it")
	T.ok(K.IsStored(SHOULDER), "and still kept")
end)

-- The Styles panel's row for the part `title`.
local function Part(o, title)
	for _, row in ipairs(o.refs.stylesPanel.rows) do
		if row.title:IsShown() and row.title:GetText() == title then return row.pick end
	end
end

-- What each row is on, in order, and the top's label.
local function Choices(o)
	local t = {}
	for _, row in ipairs(o.refs.stylesPanel.rows) do
		if row.pick:IsShown() then t[#t + 1] = row.pick.label:GetText() end
	end
	return table.concat(t, ", "), o.refs.stylesPanel.top.label:GetText()
end

T.test("styles: the panel has a row for each part a style sets", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	T.eq(o.refs.styles.label:GetText(), "Styles")
	W.Run(o.refs.styles, "OnEnter")
	W.Run(o.refs.styles, "OnClick")
	local panel = o.refs.stylesPanel
	T.ok(panel:IsShown())
	T.ok(Part(o, "Draw distance") and Part(o, "Shadows") and Part(o, "Camera"))
	T.ok(not Part(o, "Sound"), "no row for a part no style sets")
	local rows, top = Choices(o)
	T.eq(rows, "Keep mine, Keep mine, Keep mine", "nothing is set yet")
	T.eq(top, "Keep mine")
	T.ok(not panel.apply:IsEnabled(), "nothing to apply")
	W.Run(Part(o, "Camera"), "OnClick")
	T.ok(MenuItem("Film") and MenuItem("Keep mine") and not MenuItem("Fight"), "a row lists the styles that set something there")
	W.Run(MenuItem("Keep mine"), "OnClick")
	W.Run(o.refs.styles, "OnClick")
	T.ok(not panel:IsShown(), "Styles closes it again")
	W.Run(o.refs.styles, "OnClick")
	EverySetting_OpenOptions()
	T.ok(not panel:IsShown(), "and so does closing the window")
end)

T.test("styles: picking a style puts every row on it, and Apply sets and keeps it as one change", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	K.Set("shadowSoft", false) -- kept already, at another value
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	T.ok(MenuItem("Film") and MenuItem("Fight"), "a menu of the styles")
	T.eq(MenuItem("Film").tip, "A test.\n\nSets 4 settings.", "what it's for, and how much it sets")
	W.Run(MenuItem("Film"), "OnEnter")
	T.eq(GameTooltip:GetText(), "Film", "hovering a style shows its tooltip")
	W.Run(MenuItem("Film"), "OnLeave")
	W.Run(MenuItem("Film"), "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "Film, Film, Film")
	T.eq(top, "Film")
	T.eq(Get("farclip"), "1000", "nothing is set before Apply")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.ok(not o.refs.stylesPanel:IsShown(), "Apply closes the panel")
	T.eq(Get("farclip"), "10000")
	T.eq(Get("RAIDfarclip"), "10000", "the raid twin too")
	T.eq(Get("shadowSoft"), "1")
	T.eq(Get("ffxGlow"), "0")
	T.eq(Get("cameraZoomSpeed"), "10", "in another section")
	T.ok(K.IsStored("farclip") and K.IsStored("ffxGlow") and K.IsStored("cameraZoomSpeed"), "the profile keeps them")
	T.eq(o.refs.side[1].count:GetText(), "3", "counted under Graphics")
	T.eq(o.refs.side[2].count:GetText(), "1", "and under Camera")
	W.Run(o.refs.styles, "OnClick")
	rows, top = Choices(o)
	T.eq(rows, "Film, Film, Film", "the rows start on what's set now")
	T.eq(top, "Film")
	W.Run(o.refs.stylesPanel.cancel, "OnClick")
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("farclip"), "1000", "one Undo for the whole style")
	T.eq(Get("ffxGlow"), "1")
	T.eq(Get("cameraZoomSpeed"), "20")
	T.eq(Get("shadowSoft"), "0", "back to what was kept before")
	T.ok(K.IsStored("shadowSoft") and not K.IsStored("farclip"))
end)

T.test("styles: a part can keep yours, or come from another style", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Fight"), "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "Fight, Fight, Keep mine", "Keep mine where the style sets nothing")
	T.eq(top, "Fight")
	W.Run(Part(o, "Camera"), "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	W.Run(Part(o, "Shadows"), "OnClick")
	W.Run(MenuItem("Keep mine"), "OnClick")
	rows, top = Choices(o)
	T.eq(rows, "Fight, Keep mine, Film")
	T.eq(top, "Mixed")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(Get("farclip"), "4000", "Draw distance from Fight")
	T.eq(Get("cameraZoomSpeed"), "10", "Camera from Film")
	T.eq(Get("ffxGlow"), "1", "Shadows left alone")
	T.ok(not K.IsStored("shadowSoft") and not K.IsStored("ffxGlow"))
	W.Run(o.refs.styles, "OnClick")
	T.eq(Choices(o), "Fight, Keep mine, Film", "the rows start on what's set now")
	W.Run(o.refs.stylesPanel.cancel, "OnClick")
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("farclip"), "1000", "one Undo")
	T.eq(Get("cameraZoomSpeed"), "20")
	T.eq(next(K.GetKept()), nil, "nothing kept")
end)

T.test("styles: Cancel sets nothing", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	W.Run(o.refs.stylesPanel.cancel, "OnClick")
	T.ok(not o.refs.stylesPanel:IsShown())
	T.eq(Get("farclip"), "1000")
	T.eq(next(K.GetKept()), nil)
end)

T.test("styles: not in combat", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	W.Combat(true)
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Fight"), "OnClick")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(Get("farclip"), "1000")
	T.ok(W.chat[#W.chat]:find("out of combat", 1, true))
end)

-- The Styles panel's lock box for the part `title`.
local function PartLock(o, title)
	for _, row in ipairs(o.refs.stylesPanel.rows) do
		if row.title:IsShown() and row.title:GetText() == title then return row.lock end
	end
end

-- The lock box on the list's header for the group `title`.
local function GroupLock(o, title)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.header and row.item.group and row.item.group.title == title then return row.lock end
	end
end

T.test("styles: a part's lock box is its group's box in the list, both ways", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	local lock = PartLock(o, "Shadows")
	T.ok(lock:IsShown() and not lock:GetChecked())
	W.Run(lock, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock Shadows")
	lock:SetChecked(true)
	W.Run(lock, "OnClick")
	T.ok(K.IsLocked("shadowSoft") and K.IsLocked("ffxGlow") and K.IsLocked("sunShafts"), "every knob in the group")
	T.ok(GroupLock(o, "Shadows"):GetChecked(), "the group's box in the list")
	local rows, top = Choices(o)
	T.eq(rows, "Film, Locked, Film")
	T.eq(top, "Film", "a locked part doesn't make it Mixed")
	T.ok(not Part(o, "Shadows"):IsEnabled() and Part(o, "Camera"):IsEnabled(), "a locked part's menu is off")
	-- The list's box shows in the panel.
	local distance = GroupLock(o, "Draw distance")
	distance:SetChecked(true)
	W.Run(distance, "OnClick")
	T.ok(K.IsLocked("farclip") and PartLock(o, "Draw distance"):GetChecked())
	T.eq(Choices(o), "Locked, Locked, Film")
	-- The top pick doesn't move a locked row.
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Fight"), "OnClick")
	rows, top = Choices(o)
	T.eq(rows, "Locked, Locked, Keep mine")
	T.eq(top, "Keep mine", "nothing left to apply")
	T.ok(not o.refs.stylesPanel.apply:IsEnabled())
	distance:SetChecked(false)
	W.Run(distance, "OnClick")
	T.ok(not PartLock(o, "Draw distance"):GetChecked())
	rows, top = Choices(o)
	T.eq(rows, "Film, Locked, Keep mine", "unlocked, a row shows its pick again")
	T.eq(top, "Mixed")
end)

T.test("styles: Apply leaves a locked part alone, and a locked setting in a part", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	K.SetLocked("farclip", true) -- all of Draw distance
	K.SetLocked("ffxGlow", true) -- part of Shadows
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	T.eq(Choices(o), "Locked, Film, Film", "a part that's partly locked isn't Locked")
	T.ok(not PartLock(o, "Shadows"):GetChecked())
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(Get("farclip"), "1000", "the locked part")
	T.eq(Get("RAIDfarclip"), "1000", "and its raid twin")
	T.eq(Get("ffxGlow"), "1", "the locked setting")
	T.ok(K.IsStored("shadowSoft"), "the rest of its part is kept")
	T.eq(Get("cameraZoomSpeed"), "10")
	T.ok(not K.IsStored("farclip") and not K.IsStored("ffxGlow"))
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("cameraZoomSpeed"), "20", "one Undo")
	T.eq(next(K.GetKept()), nil)
end)

T.test("styles: a part's menu has its styles, then the group's built-in and saved presets, then Keep mine", function()
	local K, o = Start()
	K.SavePreset("No glow", { ffxGlow = "0" })
	K.SavePreset("Far", { farclip = "9000" })
	K.SavePreset("Far, no glow", { farclip = "9000", ffxGlow = "0" }) -- spans two parts, so it's in neither
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(Part(o, "Shadows"), "OnClick")
	T.eq(Menu(), "Film, Fight, Presets, Low / Medium / High, Ultra, No glow, Keep mine",
		"built-in presets that give the same values are one item")
	W.Run(Part(o, "Shadows"), "OnClick") -- closes it
	W.Run(Part(o, "Draw distance"), "OnClick")
	T.eq(Menu(), "Film, Fight, Presets, Low, Medium, High, Ultra, Far, Keep mine")
	W.Run(Part(o, "Draw distance"), "OnClick")
	W.Run(Part(o, "Camera"), "OnClick")
	T.eq(Menu(), "Film, Keep mine", "no heading with nothing under it")
	W.Run(Part(o, "Camera"), "OnClick")
end)

T.test("styles: Apply sets a part's built-in or saved preset, as one change", function()
	local K, o = Start()
	K.SavePreset("No glow", { ffxGlow = "0" })
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(Part(o, "Draw distance"), "OnClick")
	W.Run(MenuItem("tier:2"), "OnClick")
	W.Run(Part(o, "Shadows"), "OnClick")
	W.Run(MenuItem("preset:No glow"), "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "Medium, No glow, Keep mine")
	T.eq(top, "Mixed", "a row on a preset isn't on any one style")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.eq(Get("farclip"), "5000", "Medium's")
	T.eq(Get("RAIDfarclip"), "5000", "and its raid twin")
	T.eq(Get("ffxGlow"), "0", "the saved preset's")
	T.eq(Get("shadowSoft"), "1", "what the saved preset doesn't list is left alone")
	T.eq(Get("cameraZoomSpeed"), "20", "Keep mine")
	T.ok(K.IsStored("farclip") and K.IsStored("ffxGlow") and not K.IsStored("shadowSoft"))
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("farclip"), "1000", "one Undo")
	T.eq(Get("ffxGlow"), "1")
	T.eq(next(K.GetKept()), nil)
end)

-- Picks `value` from the Presets menu on the list's header for the group `title`.
local function PickPreset(o, title, value)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.header and row.item.group and row.item.group.title == title then
			W.Run(row.presets, "OnClick")
			return W.Run(MenuItem(value), "OnClick")
		end
	end
end

T.test("styles: a row starts on a built-in or saved preset once the profile keeps it", function()
	local K, o = Start()
	K.SavePreset("Usual zoom", { cameraZoomSpeed = "20" })
	EverySetting_OpenOptions()
	PickPreset(o, "Shadows", "tier:4")
	PickPreset(o, "Camera", "preset:Usual zoom")
	K.Set("farclip", 7000)
	W.Run(o.refs.styles, "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "High, Ultra, Usual zoom", "the first one whose values are all kept")
	T.eq(top, "Mixed")
	W.Run(Part(o, "Draw distance"), "OnClick")
	T.ok(MenuItem("tier:3").active and not MenuItem("Keep mine").active, "it's marked in the row's menu")
	W.Run(MenuItem("Keep mine"), "OnClick")
	T.eq(Choices(o), "Keep mine, Ultra, Usual zoom")
	W.Run(o.refs.stylesPanel.cancel, "OnClick")
	K.Set("farclip", 10000)
	W.Run(o.refs.styles, "OnClick")
	T.eq(Choices(o), "Film, Ultra, Usual zoom", "a style comes before a built-in preset with the same values")
end)

T.test("styles: a fresh profile opens on Keep mine, though the game's values match a built-in preset", function()
	local K, o = Start()
	T.eq(Get("shadowSoft"), "1", "soft shadows are on, as the built-in Ultra has them")
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "Keep mine, Keep mine, Keep mine", "nothing is kept")
	T.eq(top, "Keep mine")
	T.ok(not o.refs.stylesPanel.apply:IsEnabled())
	T.eq(next(K.GetKept()), nil)
end)

T.test("styles: a locked setting counts as kept, since Apply leaves it as it is", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	K.SetLocked("shadowSoft", true) -- on already, as Film has it
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	T.ok(not K.IsStored("shadowSoft") and K.IsStored("ffxGlow"))
	W.Run(o.refs.styles, "OnClick")
	local rows, top = Choices(o)
	T.eq(rows, "Film, Film, Film")
	T.eq(top, "Film")
end)

T.test("styles: the top lock box locks every part, in step with the rows and the list", function()
	local K, o = Start()
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	local panel = o.refs.stylesPanel
	W.Run(panel.top, "OnClick")
	W.Run(MenuItem("Film"), "OnClick")
	local all = panel.lock
	T.ok(all:IsShown() and not all:GetChecked())
	W.Run(all, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock every part")
	W.Run(all, "OnLeave")
	all:SetChecked(true)
	W.Run(all, "OnClick")
	T.ok(K.IsLocked("farclip") and K.IsLocked("shadowSoft") and K.IsLocked("ffxGlow") and K.IsLocked("sunShafts")
		and K.IsLocked("cameraZoomSpeed"), "every part's settings")
	T.ok(not K.IsLocked("FootstepSounds"), "not a group no style sets")
	T.ok(PartLock(o, "Draw distance"):GetChecked() and PartLock(o, "Shadows"):GetChecked() and PartLock(o, "Camera"):GetChecked(),
		"the rows' boxes")
	T.ok(GroupLock(o, "Draw distance"):GetChecked() and GroupLock(o, "Shadows"):GetChecked() and GroupLock(o, "Camera"):GetChecked(),
		"and the list's")
	local rows, top = Choices(o)
	T.eq(rows, "Locked, Locked, Locked")
	T.eq(top, "Keep mine")
	T.ok(not panel.apply:IsEnabled(), "nothing left to apply")
	-- A part unlocked here unticks it, and locked again in the list ticks it.
	local shadows = PartLock(o, "Shadows")
	shadows:SetChecked(false)
	W.Run(shadows, "OnClick")
	T.ok(not all:GetChecked())
	T.eq(Choices(o), "Locked, Film, Locked", "the row's pick comes back")
	local group = GroupLock(o, "Shadows")
	group:SetChecked(true)
	W.Run(group, "OnClick")
	T.ok(all:GetChecked() and shadows:GetChecked())
	all:SetChecked(false)
	W.Run(all, "OnClick")
	T.ok(not K.IsLocked("farclip") and not K.IsLocked("ffxGlow") and not K.IsLocked("cameraZoomSpeed"), "unticked, it unlocks them all")
	T.ok(not PartLock(o, "Camera"):GetChecked() and not GroupLock(o, "Draw distance"):GetChecked())
	rows, top = Choices(o)
	T.eq(rows, "Film, Film, Film")
	T.eq(top, "Film")
	T.ok(panel.apply:IsEnabled())
end)

T.test("styles: picking Competitive puts the Action camera row on Keep mine, and Cinematic takes it", function()
	local _, ns = W.Load()
	for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	local o = ns.Options
	EverySetting_OpenOptions()
	W.Run(o.refs.styles, "OnClick")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Competitive"), "OnClick")
	T.eq(Part(o, "Action camera").label:GetText(), "Keep mine", "the camera is left as it is")
	T.eq(Part(o, "Camera").label:GetText(), "Competitive", "but for how far out it zooms")
	T.eq(o.refs.stylesPanel.top.label:GetText(), "Competitive")
	W.Run(o.refs.stylesPanel.top, "OnClick")
	W.Run(MenuItem("Cinematic"), "OnClick")
	T.eq(Part(o, "Action camera").label:GetText(), "Cinematic")
end)

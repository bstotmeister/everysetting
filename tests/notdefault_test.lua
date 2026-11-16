-- Not default: every CVar off the game's default, kept or not; Keep these; and search by value.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with the window open. Some CVars are off their default,
-- set the way the game's options, a command or another addon would; one is
-- kept by Every Setting.
local function Open()
	local EverySetting, ns = W.Load()
	W.AddCVar("farclip", "1000") -- a graphics quality setting sets it
	W.AddCVar("RAIDfarclip", "1000")
	W.AddCVar("graphicsViewDistance", "5") -- the quality setting itself
	W.AddCVar("nameplateMaxDistance", "60.000000")
	W.AddCVar("nameplateOtherDistance", "60.000000")
	W.AddCVar("autoLootDefault", "0")
	W.AddCVar("Sound_MusicVolume", "0.4")
	W.AddCVar("gxMonitor", "0", { readOnly = true, takes = true })
	W.AddCVar("debugThing", "0")
	W.AddCVar("closedInfoFrames", "")
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100,
			  src = "preset", raid = "RAIDfarclip" },
		} },
	}
	EverySetting.SECTIONS = { "Graphics", "Raid graphics", "Nameplates", "Interface", "Debug and development", "Other" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "2", graphicsViewDistance = "1", gxMonitor = "1",
		nameplateMaxDistance = "3", nameplateOtherDistance = "3", autoLootDefault = "4|t",
		Sound_MusicVolume = "4|s|0|1|0.05", debugThing = "5|t", closedInfoFrames = "6" }
	W.Login()
	C_CVar.SetCVar("farclip", "10000")
	C_CVar.SetCVar("RAIDfarclip", "10000")
	C_CVar.SetCVar("graphicsViewDistance", "9")
	C_CVar.SetCVar("nameplateMaxDistance", "60") -- the same number, written another way
	C_CVar.SetCVar("autoLootDefault", "1")
	C_CVar.SetCVar("gxMonitor", "1")
	C_CVar.SetCVar("debugThing", "1")
	C_CVar.SetCVar("closedInfoFrames", "7")
	EverySetting_OpenOptions()
	EverySetting.RawKnob("Sound_MusicVolume", "")
	EverySetting.Set("Sound_MusicVolume", 0.2)
	return EverySetting, ns.Options
end

-- What the list shows: [a header], a CVar, or ... for the button that unfolds a section's other CVars.
local function Shown(o)
	local out = {}
	for _, item in ipairs(o.view) do
		out[#out + 1] = item.others and "[others]" or item.header and ("[" .. (item.group or item.section).title .. "]")
			or item.more and "..." or item.knob.cvar
	end
	return table.concat(out, " ")
end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

local function Side(o, title)
	for _, b in ipairs(o.refs.side) do
		if b.label:GetText() == title then return b end
	end
end

-- Each section's count on its sidebar button, in order.
local function Counts(o)
	local out = {}
	for _, b in ipairs(o.refs.side) do out[#out + 1] = b.count:GetText() end
	return table.concat(out, ",")
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

local function Tick(box, on)
	box:SetChecked(on)
	W.Run(box, "OnClick")
end

T.test("not default: lists every CVar off its default, kept or not, and counts each section's", function()
	local _, o = Open()
	T.eq(Counts(o), ",,,1,,,", "Every Setting's count, before")
	Tick(o.refs.notDefault, true)
	T.eq(Shown(o), "[Graphics] graphicsViewDistance gxMonitor [Interface] autoLootDefault Sound_MusicVolume",
		"not view distance and its raid twin, which a quality setting sets; not 60 for 60.000000; not Debug and Other")
	T.eq(Counts(o), "2,,,2,1,1,", "Debug and Other are counted all the same")
	-- Picking a section it leaves out lists that one.
	W.Run(Side(o, "Other"), "OnClick")
	T.eq(Shown(o), "[Graphics] graphicsViewDistance gxMonitor [Interface] autoLootDefault Sound_MusicVolume [Other] closedInfoFrames")
	T.ok(o.refs.notDefault:GetChecked(), "and leaves the filter on")
	Tick(o.refs.notDefault, false)
	Tick(o.refs.notDefault, true)
	T.ok(not Shown(o):find("closedInfoFrames", 1, true), "until it's ticked again")
	-- With a search too, only what matches both.
	o.refs.search:SetText("auto")
	T.eq(Shown(o), "[Interface] autoLootDefault")
	T.eq(Counts(o), ",,,1,,,")
	o.refs.search:SetText("")
	Tick(o.refs.notDefault, false)
	T.eq(Counts(o), ",,,1,,,", "Every Setting's count again")
end)

T.test("not default: a row off its default that Every Setting doesn't keep has a grey bar", function()
	local EverySetting, o = Open()
	T.ok(not RowFor(o, "farclip").off:IsShown(), "not one a quality setting sets")
	Tick(o.refs.notDefault, true)
	local loot, volume = RowFor(o, "autoLootDefault"), RowFor(o, "Sound_MusicVolume")
	T.ok(loot.off:IsShown() and not loot.kept:IsShown(), "grey, not kept")
	T.ok(volume.kept:IsShown() and not volume.off:IsShown(), "kept: the amber bar")
	Tick(o.refs.notDefault, false)
	o.refs.search:SetText("nameplate")
	T.ok(not RowFor(o, "nameplateMaxDistance").off:IsShown(), "60 is 60.000000")
	EverySetting.Set("autoLootDefault", false)
	o.refs.search:SetText("auto")
	T.ok(not RowFor(o, "autoLootDefault").off:IsShown() and RowFor(o, "autoLootDefault").kept:IsShown(),
		"kept at its default: the amber bar alone")
end)

T.test("not default: Keep these keeps what the list shows without setting anything, and one Undo takes it back", function()
	local EverySetting, o = Open()
	EverySetting.SetLocked("graphicsViewDistance", true) -- styles and presets leave it alone
	T.ok(o.refs.status:IsShown() and not o.refs.keep:IsShown())
	Tick(o.refs.notDefault, true)
	T.ok(o.refs.keep:IsShown() and not o.refs.status:IsShown(), "Keep these in the status line's place")
	T.eq(o.refs.keep.label:GetText(), "Keep these (2)", "not one it keeps already, nor a read-only one, nor Debug's")
	local sets = #W.sets
	W.Run(o.refs.keep, "OnClick")
	W.Run(MenuItem("here"), "OnClick")
	local kept = EverySettingDB.profiles.Default
	T.eq(kept.graphicsViewDistance, "9", "locked or not: nothing is set")
	T.eq(kept.autoLootDefault, "1")
	T.eq(kept.Sound_MusicVolume, "0.2")
	T.eq(kept.gxMonitor, nil)
	T.eq(kept.debugThing, nil)
	T.eq(#W.sets, sets, "nothing set")
	T.ok(RowFor(o, "autoLootDefault").kept:IsShown())
	T.eq(o.refs.keep.label:GetText(), "Keep these (0)")
	T.ok(not o.refs.keep:IsEnabled())
	-- Reset keeps the value: it's the one from before Every Setting kept it.
	EverySetting.Reset("autoLootDefault")
	T.eq(C_CVar.GetCVar("autoLootDefault"), "1")
	EverySetting.Undo()
	T.ok(EverySetting.IsStored("autoLootDefault"))
	EverySetting.Undo()
	T.ok(not EverySetting.IsStored("autoLootDefault") and not EverySetting.IsStored("graphicsViewDistance"), "one Undo")
	T.ok(EverySetting.IsStored("Sound_MusicVolume"), "what was kept before stays")
	T.eq(C_CVar.GetCVar("autoLootDefault"), "1")
	T.eq(C_CVar.GetCVar("graphicsViewDistance"), "9")
	T.eq(o.refs.keep.label:GetText(), "Keep these (2)")
	-- In combat it waits, as a preset does.
	W.Combat(true)
	T.ok(not o.refs.keep:IsShown() and o.refs.status:IsShown(), "the status line says it's combat")
	T.eq(EverySetting.KeepAsIs({ "autoLootDefault" }), 0)
	W.Combat(false)
end)

T.test("not default: Keep these into a new profile", function()
	local EverySetting, o = Open()
	Tick(o.refs.notDefault, true)
	W.Run(o.refs.keep, "OnClick")
	W.Run(MenuItem("new"), "OnClick")
	local dialog = o.refs.dialog
	T.ok(dialog.text:GetText():find("Saves a copy of Default", 1, true) and dialog.text:GetText():find("the 2 settings", 1, true))
	dialog.name:SetText("Default")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.error:GetText(), "There's already a profile named Default.")
	dialog.name:SetText("Mine")
	W.Run(dialog.ok, "OnClick")
	T.eq(EverySetting.GetProfile(), "Mine")
	local mine, default = EverySettingDB.profiles.Mine, EverySettingDB.profiles.Default
	T.eq(mine.autoLootDefault, "1")
	T.eq(mine.graphicsViewDistance, "9")
	T.eq(mine.Sound_MusicVolume, "0.2", "a copy of the profile it was on")
	T.eq(default.autoLootDefault, nil, "which is left as it was")
	EverySetting.Undo()
	T.eq(mine.autoLootDefault, nil, "one Undo")
	T.eq(mine.Sound_MusicVolume, "0.2")
end)

T.test("not default: leaves out the values the game writes for itself, and so does Keep these", function()
	local EverySetting, ns = W.Load()
	W.AddCVar("textLocale", "") -- the launcher's language
	W.AddCVar("hwDetect", "1") -- 0 once the game has detected the hardware
	W.AddCVar("GxApi", "auto") -- the graphics API, which the game picks
	W.AddCVar("ClientSettings_WORK_OPTIMS_BY_API_MASK", "") -- stamped with the interface version
	W.AddCVar("autoLootDefault", "0") -- a player's choice
	EverySetting.GROUPS = {}
	EverySetting.SECTIONS = { "Graphics", "Interface", "Network and system", "Other" }
	EverySetting.CVARS = { textLocale = "3", hwDetect = "3", GxApi = "1|gx", autoLootDefault = "2|t",
		ClientSettings_WORK_OPTIMS_BY_API_MASK = "1" }
	W.Login()
	C_CVar.SetCVar("textLocale", "enUS")
	C_CVar.SetCVar("hwDetect", "0")
	C_CVar.SetCVar("GxApi", "MTL")
	C_CVar.SetCVar("ClientSettings_WORK_OPTIMS_BY_API_MASK", "16001,0xe,0x0,0x1ff")
	C_CVar.SetCVar("autoLootDefault", "1")
	EverySetting_OpenOptions()
	local o = ns.Options
	Tick(o.refs.notDefault, true)
	T.eq(Shown(o), "[Interface] autoLootDefault", "not the locale, hardware detection, the API or the mask")
	T.eq(Counts(o), ",1,,", "nor counted")
	T.eq(o.refs.keep.label:GetText(), "Keep these (1)")
	W.Run(o.refs.keep, "OnClick")
	W.Run(MenuItem("here"), "OnClick")
	local kept = EverySettingDB.profiles.Default
	T.eq(kept.autoLootDefault, "1")
	for _, cvar in ipairs({ "textLocale", "hwDetect", "GxApi", "ClientSettings_WORK_OPTIMS_BY_API_MASK" }) do
		T.eq(kept[cvar], nil, cvar .. " isn't kept")
	end
	-- Each is still in its section, with no grey bar, and a value set in its row is kept.
	Tick(o.refs.notDefault, false)
	o.refs.search:SetText("GxApi")
	T.ok(not RowFor(o, "GxApi").off:IsShown())
	EverySetting.Set("GxApi", "metal", true)
	T.eq(kept.GxApi, "metal")
end)

T.test("not default: what it leaves out as the game's own is in the client, and so is every ClientSettings_ CVar", function()
	local _, ns = W.Load()
	local cvars, have, masks = dofile("data/cvars.lua").cvars, {}, 0
	for _, c in ipairs(cvars) do have[c[1]:lower()] = true end
	for cvar in pairs(ns.Options.own) do T.ok(have[cvar], cvar .. " is a CVar in data/cvars.lua") end
	-- Listed under Graphics, as CVars.lua has them, and each off its default.
	W.AddCVar("autoLootDefault", "0")
	for _, c in ipairs(cvars) do
		if c[1]:find("^ClientSettings_") then
			masks = masks + 1
			W.AddCVar(c[1], c[2]).value = "16001,0x0,0x0,0x1ff"
		end
	end
	T.ok(masks >= 30, "the client has them")
	W.Login()
	C_CVar.SetCVar("autoLootDefault", "1")
	EverySetting_OpenOptions()
	local o = ns.Options
	Tick(o.refs.notDefault, true)
	T.eq(o.refs.keep.label:GetText(), "Keep these (1)", "not one of the " .. masks)
end)

T.test("not default: a raid twin at a value of its own is kept at it", function()
	local EverySetting = W.Load()
	W.AddCVar("volumeFog", "1")
	W.AddCVar("RAIDVolumeFog", "1")
	EverySetting.GROUPS = { { title = "Fog", items = {
		{ cvar = "volumeFog", label = "Volumetric fog", type = "toggle", src = "probe", raid = "RAIDVolumeFog" },
	} } }
	EverySetting.SECTIONS = { "Graphics", "Raid graphics" }
	EverySetting.CVARS = { volumeFog = "1", RAIDVolumeFog = "2|t" }
	W.Login()
	C_CVar.SetCVar("volumeFog", "0")
	T.eq(EverySetting.KeepAsIs({ "volumeFog" }), 1)
	T.eq(EverySettingDB.profiles.Default.RAIDVolumeFog, "1", "so the knob doesn't set it at the next login")
	W.Load(EverySettingDB)
	W.AddCVar("volumeFog", "1")
	W.AddCVar("RAIDVolumeFog", "1")
	C_CVar.SetCVar("volumeFog", "0")
	W.Login()
	T.eq(C_CVar.GetCVar("RAIDVolumeFog"), "1")
end)

T.test("search: =value finds the settings at that value, in either format", function()
	local _, o = Open()
	o.refs.search:SetText("=60")
	T.eq(Shown(o), "[Nameplates] nameplateMaxDistance nameplateOtherDistance", "60 and 60.000000")
	o.refs.search:SetText("=10000")
	T.eq(Shown(o), "[Graphics] farclip [Raid graphics] RAIDfarclip")
	o.refs.search:SetText("=1 loot")
	T.eq(Shown(o), "[Interface] autoLootDefault", "with a word too")
	o.refs.search:SetText("=7")
	T.eq(Shown(o), "[Other] closedInfoFrames")
	o.refs.search:SetText("=")
	T.ok(#o.view > 10, "= alone narrows nothing")
end)

T.test("not default: every value is read once, not a row at a time, and again after a CVar changes", function()
	local EverySetting, o = Open()
	local get, reads = C_CVar.GetCVar, 0
	rawset(C_CVar, "GetCVar", function(name)
		if name == "debugThing" then reads = reads + 1 end -- never in a row: Debug is left out
		return get(name)
	end)
	Tick(o.refs.notDefault, true)
	T.eq(reads, 1)
	o.refs.search:SetText("auto")
	o.refs.search:SetText("")
	W.Run(o.refs.list, "OnMouseWheel", -1)
	T.eq(reads, 1, "not again as the list narrows or scrolls")
	EverySetting.Set("autoLootDefault", false)
	T.eq(reads, 2, "after a change")
	T.ok(not Shown(o):find("autoLootDefault", 1, true), "which shows: it's at its default now")
	rawset(C_CVar, "GetCVar", get)
end)

T.test("not default: the CVars the graphics quality settings set are the ones data/presets.lua has, with their raid twins", function()
	local _, ns = W.Load()
	local quality, want = ns.Options.quality, {}
	for _, cvars in pairs(dofile("data/presets.lua")) do
		for cvar in pairs(cvars) do
			want[cvar:lower()], want[("RAID" .. cvar):lower()] = true, true
		end
	end
	for cvar in pairs(want) do T.ok(quality[cvar], cvar .. " is left out") end
	for cvar in pairs(quality) do T.ok(want[cvar], cvar .. " is in data/presets.lua") end
end)

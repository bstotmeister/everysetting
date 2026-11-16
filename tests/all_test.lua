-- Every CVar: raw knobs, their hints from CVars.lua, and where the window lists them.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with one knob from Knobs.lua and a few other CVars.
local function Start(saved, before)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("shadowSoft", "0", { help = "Soft shadows" })
	W.AddCVar("nameplateMaxDistance", "45.000000", { secure = true, help = "The max distance to show nameplates." })
	W.AddCVar("Sound_MusicVolume", "0.4", { help = "music volume (0.0 to 1.0)" })
	W.AddCVar("CAAPlayerCastMode", "0", { help = "When the player's casts should be announced" })
	W.AddCVar("autoLootDefault", "0", { help = "Automatically loot items when the loot window opens" })
	W.AddCVar("TurnSpeed", "180", { min = 1, help = "capped by the server" })
	W.AddCVar("screenshotSizeOverride", "0x0", { help = "Set the size of screenshots" })
	W.AddCVar("brandNewInAPatch", "7")
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	EverySetting.GROUPS = {
		{ title = "Shadows", items = {
			{ cvar = "shadowSoft", label = "Soft shadows", tip = "Blurs the edges of shadows.", type = "toggle", src = "probe" },
		} },
	}
	EverySetting.SECTIONS = { "Graphics", "Nameplates", "Sound", "Interface", "Other" }
	EverySetting.CVARS = {
		shadowSoft = "1|t",
		gxMonitor = "1",
		screenshotSizeOverride = "1",
		nameplateMaxDistance = "2",
		Sound_MusicVolume = "3|s|0|1|0.05",
		CAAPlayerCastMode = "3|c|0=Off|1=Cast start|2=Cast end",
		autoLootDefault = "4|t",
		TurnSpeed = "4|S|90|270|10|x",
	}
	if before then before(EverySetting) end
	W.Login()
	return EverySetting, ns.Options
end

T.test("all: every CVar gets a knob, with the control CVars.lua suggests", function()
	local EverySetting = Start()
	local volume = EverySetting.RawKnob("Sound_MusicVolume", "music volume (0.0 to 1.0)")
	T.eq(volume.type, "slider")
	T.eq(volume.min, 0) T.eq(volume.max, 1) T.eq(volume.step, 0.05)
	T.eq(volume.label, "Sound_MusicVolume", "named by its CVar")
	T.eq(volume.tip, "music volume (0.0 to 1.0)", "described by the game's help")
	T.ok(volume.raw and volume.found)
	local mode = EverySetting.RawKnob("CAAPlayerCastMode", "")
	T.eq(mode.type, "choice")
	T.eq(#mode.options, 3)
	T.eq(mode.options[2][1], "1") T.eq(mode.options[2][2], "Cast start")
	T.eq(mode.tip, nil, "no help text")
	T.eq(EverySetting.RawKnob("autoLootDefault", "").type, "toggle")
	T.eq(EverySetting.RawKnob("nameplateMaxDistance", "").type, "text", "no suggestion: just a box")
	T.eq(EverySetting.RawKnob("nameplateMaxDistance", "").secure, true)
	T.eq(EverySetting.RawKnob("brandNewInAPatch", "").type, "text", "not in CVars.lua at all")
	T.eq(EverySetting.RawKnob("gxMonitor", "").locked, true)
	T.eq(EverySetting.RawKnob("noSuchCVar", ""), nil)
	T.eq(EverySetting.RawKnob("shadowSoft", "Soft shadows").label, "Soft shadows", "the knob from Knobs.lua wins")
	T.eq(EverySetting.RawKnob("sound_musicvolume", ""), volume, "made once, whatever the case")
end)

T.test("all: a raw knob's box takes any value, its slider keeps to the range", function()
	local EverySetting = Start()
	EverySetting.RawKnob("Sound_MusicVolume", "")
	T.eq(EverySetting.Set("Sound_MusicVolume", 0.724), "0.7", "the slider snaps")
	T.eq(EverySetting.Set("Sound_MusicVolume", 5), "1", "and clamps")
	T.eq(EverySetting.Set("Sound_MusicVolume", "2.5", true), "2.5", "the box sets what's typed")
	T.eq(C_CVar.GetCVar("Sound_MusicVolume"), "2.5")
	EverySetting.RawKnob("screenshotSizeOverride", "")
	T.eq(EverySetting.Set("screenshotSizeOverride", "7680x4320", true), "7680x4320", "text too")
	EverySetting.RawKnob("gxMonitor", "")
	T.eq(EverySetting.Set("gxMonitor", "1", true), nil, "not a locked one")
	-- A CVar the server enforces is left alone. In danger mode it's set, and
	-- keeps to its range even in the box.
	local turn = EverySetting.RawKnob("TurnSpeed", "")
	T.eq(turn.type, "slider", "the control before the x")
	T.eq(turn.max, 270)
	T.eq(EverySetting.Set("TurnSpeed", "200", true), nil, "hands off")
	EverySetting.SetDanger(true)
	T.eq(EverySetting.Set("TurnSpeed", "1000000", true), "270")
	-- A knob from Knobs.lua isn't set as typed (but for a number past a range from the presets: past_test.lua).
	T.eq(EverySetting.Set("shadowSoft", "7", true), "0")
end)

T.test("all: raw values are kept, set again at login, and reset", function()
	local saved = { values = { nameplateMaxDistance = "60", Sound_MusicVolume = "0.2" }, before = { nameplateMaxDistance = "45.000000" } }
	local EverySetting = Start(saved, function() C_CVar.SetCVar("Sound_MusicVolume", "0.9") end)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60", "set again at login")
	T.eq(C_CVar.GetCVar("Sound_MusicVolume"), "0.2")
	T.ok(EverySetting.IsStored("nameplateMaxDistance"))
	EverySetting.Reset("nameplateMaxDistance")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "45.000000")
	T.eq(EverySetting.ResetAll(), 1, "Reset all covers raw knobs")
	T.eq(C_CVar.GetCVar("Sound_MusicVolume"), "0.9", "back to what it was at login")
	T.eq(next(EverySettingDB.profiles.Default), nil)
end)

T.test("all: a raid twin kept at its own value is left alone by its knob", function()
	local EverySetting = W.Load()
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	EverySetting.GROUPS = { { title = "Draw distance", items = {
		{ cvar = "farclip", label = "View distance", tip = "How far.", type = "slider", min = 1000, max = 10000, step = 100,
		  src = "preset", raid = "RAIDfarclip" },
	} } }
	EverySetting.SECTIONS = { "Graphics", "Raid graphics" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "2|s|1000|10000|100" }
	W.Login()
	EverySetting.RawKnob("RAIDfarclip", "")
	EverySetting.Set("RAIDfarclip", 4000)
	EverySetting.Set("farclip", 8000)
	T.eq(C_CVar.GetCVar("RAIDfarclip"), "4000", "not overwritten by the knob")
	EverySetting.Reset("farclip")
	T.eq(C_CVar.GetCVar("farclip"), "1000")
	T.eq(C_CVar.GetCVar("RAIDfarclip"), "4000", "nor reset with it")
	EverySetting.Reset("RAIDfarclip")
	T.eq(C_CVar.GetCVar("RAIDfarclip"), "1000")
	EverySetting.Set("farclip", 8000)
	T.eq(C_CVar.GetCVar("RAIDfarclip"), "8000", "follows the knob again")
end)

T.test("all: the groups are CVars.lua's sections, each in name order", function()
	local EverySetting = Start()
	local groups = EverySetting.AllGroups()
	local got = {}
	for _, group in ipairs(groups) do
		local names = {}
		for _, knob in ipairs(group.items) do names[#names + 1] = knob.cvar end
		got[#got + 1] = group.title .. ": " .. table.concat(names, " ")
	end
	T.eq(got[1], "Graphics: gxMonitor screenshotSizeOverride shadowSoft")
	T.eq(got[2], "Nameplates: nameplateMaxDistance")
	T.eq(got[3], "Sound: CAAPlayerCastMode Sound_MusicVolume", "name order ignores case")
	T.eq(got[4], "Interface: autoLootDefault TurnSpeed")
	T.eq(got[5], "Other: brandNewInAPatch", "a CVar CVars.lua doesn't know goes last")
	T.eq(#groups, 5)
	T.eq(EverySetting.AllGroups(), groups, "made once")
end)

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
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

-- The row with the button that unfolds the section `title`.
local function More(o, title)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.more and row.item.section.title == title then return row.more end
	end
end

-- The menu's button for `value`, if the menu is open.
local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

T.test("all: a section lists its knobs, and unfolds to its other CVars by name", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	T.eq(Shown(o), "[Graphics] shadowSoft ... [Nameplates] ... [Sound] ... [Interface] ... [Other] ...")
	T.eq(o.refs.side[3].label:GetText(), "Sound")
	T.eq(#o.refs.side, 6, "a sidebar button for each section, and one for Danger")
	T.ok(o.refs.side[5]:IsShown() and not o.refs.side[6]:IsShown(), "which is hidden outside danger mode")
	T.eq(RowFor(o, "shadowSoft").label:GetText(), "Soft shadows", "a knob from Knobs.lua keeps its name")
	local more = More(o, "Graphics")
	T.eq(more.label:GetText(), "Show 2 more CVars")
	W.Run(more, "OnEnter")
	W.Run(more, "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft ... gxMonitor screenshotSizeOverride [Nameplates] ... [Sound] ... [Interface] ... [Other] ...",
		"in name order, without the knob that's listed above")
	T.eq(more.label:GetText(), "Hide 2 more CVars")
	T.ok(RowFor(o, "gxMonitor").label:GetText():find("(read-only)", 1, true))
	W.Run(RowFor(o, "gxMonitor").name, "OnEnter") -- its tooltip says the game offers no way to change it
	W.Run(more, "OnClick")
	T.ok(not RowFor(o, "gxMonitor"), "folded away again")
	-- The sidebar unfolds a section that has nothing else to show.
	T.eq(More(o, "Nameplates").label:GetText(), "Show 1 CVar")
	W.Run(o.refs.side[2], "OnClick")
	W.Run(o.refs.side[3], "OnClick")
	W.Run(o.refs.side[4], "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft ... [Nameplates] ... nameplateMaxDistance [Sound] ... CAAPlayerCastMode Sound_MusicVolume"
		.. " [Interface] ... autoLootDefault TurnSpeed [Other] ...")
	W.Run(o.refs.side[1], "OnClick")
	T.ok(not RowFor(o, "gxMonitor"), "but not one with knobs of its own")
	local row = RowFor(o, "nameplateMaxDistance")
	T.eq(row.label:GetText(), "Nameplate distance", "a plain name from CVars.lua")
	T.ok(row.box:IsShown() and not row.slider:IsShown() and not row.check:IsShown(), "just a box")
	T.eq(row.box:GetText(), "45.000000", "the value as the game stores it")
	T.eq(row.box:GetWidth(), 210 + 8 + 56, "a wide one")
	local volume = RowFor(o, "Sound_MusicVolume")
	T.ok(volume.slider:IsShown() and volume.box:IsShown())
	T.eq(volume.box:GetWidth(), 56)
	local toggle = RowFor(o, "autoLootDefault")
	T.ok(toggle.check:IsShown() and toggle.box:IsShown(), "a checkbox, and the box beside it")
	local choice = RowFor(o, "CAAPlayerCastMode")
	T.ok(choice.dropdown:IsShown() and choice.box:IsShown())
	T.eq(choice.dropdown.label:GetText(), "Off")
end)

T.test("all: typing in a raw knob's box sets it, and Reset puts it back", function()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	for i = 2, 4 do W.Run(o.refs.side[i], "OnClick") end
	local row = RowFor(o, "nameplateMaxDistance")
	row.box:SetFocus()
	row.box:SetText("80")
	W.Run(row.box, "OnEnterPressed")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80")
	T.ok(row.kept:IsShown() and row.reset:IsShown())
	T.eq(o.refs.side[2].count:GetText(), "1")
	W.Run(row.reset, "OnClick")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "45.000000")
	-- A slider's box goes past the slider's range; the thumb stops at its end.
	local volume = RowFor(o, "Sound_MusicVolume")
	volume.box:SetFocus()
	volume.box:SetText("1.5")
	W.Run(volume.box, "OnEnterPressed")
	T.eq(C_CVar.GetCVar("Sound_MusicVolume"), "1.5")
	T.eq(volume.slider.fraction, 1)
	-- The checkbox and the dropdown still set their own values.
	local toggle = RowFor(o, "autoLootDefault")
	toggle.check:SetChecked(true)
	W.Run(toggle.check, "OnClick")
	T.eq(C_CVar.GetCVar("autoLootDefault"), "1")
	T.ok(EverySetting.IsStored("autoLootDefault"))
	T.eq(o.refs.side[4].count:GetText(), "1")
	T.ok(o.refs.status:GetText():find("2|r settings kept", 1, true), "the status counts them all")
end)

T.test("all: a menu's values can be text, and a value in parts goes by its first", function()
	local EverySetting, o = Start(nil, function(addon)
		W.AddCVar("statusTextDisplay", "NONE")
		-- The engine keeps a quality with its coverage: 2 is "2,0".
		W.AddCVar("MSAAQuality", "0", { validate = function(value) return value:match("^[1-9]$") and value .. ",0" or true end })
		addon.CVARS.statusTextDisplay = "4|c|NUMERIC=Numeric value|PERCENT=Percentage|BOTH=Both|NONE=None"
		addon.CVARS.MSAAQuality = "1|c|0=None|1=2x|2=4x|3=8x"
	end)
	EverySetting_OpenOptions()
	o.refs.search:SetText("statusTextDisplay")
	local row = RowFor(o, "statusTextDisplay")
	T.ok(row.dropdown:IsShown() and row.box:IsShown(), "a menu, and the box beside it")
	T.eq(row.dropdown.label:GetText(), "None", "a text value's label")
	T.eq(EverySetting.Normalize(row.item.knob, "PERCENT"), "PERCENT")
	T.eq(EverySetting.Normalize(row.item.knob, "SOME"), nil, "only its options")
	W.Run(row.dropdown, "OnClick")
	T.ok(MenuItem("NONE").active, "the value it has is marked")
	W.Run(MenuItem("BOTH"), "OnClick")
	T.eq(C_CVar.GetCVar("statusTextDisplay"), "BOTH")
	T.eq(row.dropdown.label:GetText(), "Both")
	T.eq(row.box:GetText(), "BOTH")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	T.ok(lines[1]:find("Now: |cffffffffBoth|r    Game default: |cffffffffNone|r", 1, true), "the tooltip has the labels too")
	T.ok(lines[1]:find("Reset puts it back to None.", 1, true))

	o.refs.search:SetText("MSAAQuality")
	row = RowFor(o, "MSAAQuality")
	T.eq(row.dropdown.label:GetText(), "None")
	W.Run(row.dropdown, "OnClick")
	W.Run(MenuItem("2"), "OnClick")
	T.eq(C_CVar.GetCVar("MSAAQuality"), "2,0", "kept with its coverage")
	T.eq(row.box:GetText(), "2,0")
	T.eq(row.dropdown.label:GetText(), "4x", "and still the option for its quality")
	W.Run(row.dropdown, "OnClick")
	T.ok(MenuItem("2").active and not MenuItem("0").active, "which the menu marks")
	W.Run(MenuItem("0"), "OnClick")
	T.eq(row.dropdown.label:GetText(), "None")
	EverySetting.Set("MSAAQuality", "9,1", true)
	T.eq(row.dropdown.label:GetText(), "Custom (9,1)", "a quality that's no option has no label")
end)

T.test("all: a menu greys out the options the game says this computer can't use, and says why", function()
	local EverySetting, o = Start(nil, function(addon)
		W.AddCVar("shadowRt", "0")
		W.AddCVar("RAIDshadowRt", "0")
		W.AddCVar("LowLatencyMode", "0")
		addon.CVARS.shadowRt = "1|c|0=Disabled|1=Fair|2=Good|3=High"
		addon.CVARS.RAIDshadowRt = "1|c|0=Disabled|1=Fair|2=Good"
		addon.CVARS.LowLatencyMode = "1|c|0=Auto detect|1=Disabled|5=Intel XeLL"
	end)
	-- A card without ray tracing, and not an Intel one, as the game's check says.
	_G.VRN_GRAPHICS = "Unsupported for graphics related reasons"
	_G.VRN_NEEDS_INTEL_GPU = "Requires an Intel graphics card"
	_G.IsGraphicsCVarValueSupported = function(cvar, value)
		if cvar == "shadowRt" and value > 0 then return 3 end
		if cvar == "LowLatencyMode" and value == 5 then return 16 end
		return 0
	end
	T.eq(EverySetting.Unsupported("shadowRt", "2"), "Unsupported for graphics related reasons")
	T.eq(EverySetting.Unsupported("shadowRt", "0"), nil, "one it can use")
	T.eq(EverySetting.Unsupported("RAIDshadowRt", "1"), "Unsupported for graphics related reasons", "a raid twin goes by its main CVar")
	T.eq(EverySetting.Unsupported("LowLatencyMode", "5"), "Requires an Intel graphics card")
	T.eq(EverySetting.Unsupported("LowLatencyMode", "1"), nil)
	T.eq(EverySetting.Unsupported("CAAPlayerCastMode", "2"), nil, "a menu the game doesn't check")
	EverySetting_OpenOptions()
	o.refs.search:SetText("shadowRt")
	local row = RowFor(o, "shadowRt")
	W.Run(row.dropdown, "OnClick")
	T.ok(MenuItem("0") and not MenuItem("0").unsupported, "Disabled can be picked")
	T.eq(MenuItem("2").unsupported, "Unsupported for graphics related reasons")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(MenuItem("2"), "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	T.ok(lines[1] and lines[1]:find("Unsupported for graphics related reasons", 1, true), "its tooltip says why")
	W.Run(MenuItem("2"), "OnClick")
	T.eq(C_CVar.GetCVar("shadowRt"), "0", "it can't be picked")
	T.ok(MenuItem("2") and MenuItem("2"):IsVisible(), "and the menu stays open")
	W.Run(MenuItem("0"), "OnClick")
	-- On a card the game can use them on, nothing is greyed.
	_G.IsGraphicsCVarValueSupported = function() return 0 end
	W.Run(row.dropdown, "OnClick")
	T.ok(not MenuItem("2").unsupported, "a card with ray tracing")
	W.Run(MenuItem("2"), "OnClick")
	T.eq(C_CVar.GetCVar("shadowRt"), "2")
	-- And a client without the game's check greys nothing.
	_G.IsGraphicsCVarValueSupported = nil
	T.eq(EverySetting.Unsupported("shadowRt", "2"), nil)
	_G.VRN_GRAPHICS, _G.VRN_NEEDS_INTEL_GPU = nil, nil
end)

T.test("all: a color's swatch opens the game's color picker, and OK sets it once", function()
	local EverySetting, o = Start(nil, function(addon)
		W.AddCVar("raidFramesHealthBarColor", "FF2B9305")
		addon.CVARS.raidFramesHealthBarColor = "4|h"
	end)
	local function Get() return C_CVar.GetCVar("raidFramesHealthBarColor") end
	-- A color as its red, green and blue from 0 to 255.
	local function Bytes(color)
		return ("%d %d %d"):format(math.floor(color[1] * 255 + 0.5), math.floor(color[2] * 255 + 0.5), math.floor(color[3] * 255 + 0.5))
	end
	EverySetting_OpenOptions()
	o.refs.search:SetText("raidFramesHealthBarColor")
	local row = RowFor(o, "raidFramesHealthBarColor")
	local knob = row.item.knob
	T.eq(knob.type, "color")
	T.ok(row.swatch:IsShown() and row.box:IsShown() and not row.dropdown:IsShown(), "a swatch, and the box beside it")
	T.eq(row.box:GetText(), "FF2B9305")
	T.eq(Bytes(row.swatch.color.color), "43 147 5", "the swatch shows the color")
	T.eq(EverySetting.Normalize(knob, "ff0000ff"), "FF0000FF")
	T.eq(EverySetting.Normalize(knob, "00ff00"), "FF00FF00", "six digits are a color too")
	T.eq(EverySetting.Normalize(knob, "green"), nil)
	local undo = EverySetting.HistorySize()
	W.Run(row.swatch, "OnClick")
	T.ok(W.picker:IsShown(), "the game's picker opens")
	T.eq(Bytes({ W.picker.info.r, W.picker.info.g, W.picker.info.b }), "43 147 5", "on the color it has")
	W.PickColor(1, 0, 0)
	W.PickColor(0, 0.5, 1)
	T.eq(Get(), "FF2B9305", "nothing is set while colors are tried")
	W.ClosePicker(true)
	T.eq(Get(), "FF0080FF", "OK sets the last one")
	T.eq(EverySetting.HistorySize(), undo + 1, "as one change")
	T.eq(row.box:GetText(), "FF0080FF")
	T.eq(Bytes(row.swatch.color.color), "0 128 255")
	T.ok(row.kept:IsShown() and row.reset:IsShown())
	W.Run(row.swatch, "OnClick")
	W.PickColor(1, 1, 1)
	W.ClosePicker(false)
	T.eq(Get(), "FF0080FF", "cancelling sets nothing")
	-- The picker opened by something else is none of the row's business.
	W.picker:SetupColorPickerAndShow({ r = 1, g = 1, b = 1, swatchFunc = function() end })
	W.ClosePicker(true)
	T.eq(Get(), "FF0080FF")
	T.eq(EverySetting.HistorySize(), undo + 1)
	-- Nor is one something else takes over while the row's is open, with a color picked.
	W.Run(row.swatch, "OnClick")
	W.PickColor(1, 0, 0)
	W.picker:SetupColorPickerAndShow({ r = 1, g = 1, b = 1, swatchFunc = function() end })
	W.ClosePicker(false)
	T.eq(Get(), "FF0080FF", "the red picked before it was taken over isn't set")
	T.eq(EverySetting.HistorySize(), undo + 1)
	-- A color that isn't opaque keeps how see-through it is, and six digits show as a color.
	row.box:SetFocus()
	row.box:SetText("80141414")
	W.Run(row.box, "OnEnterPressed")
	W.Run(row.swatch, "OnClick")
	W.PickColor(1, 0, 0)
	W.ClosePicker(true)
	T.eq(Get(), "80FF0000", "the first two digits are left as they were")
	W.Run(row.reset, "OnClick")
	T.eq(Get(), "FF2B9305")
	-- The box still takes a color as text, and Reset puts the old one back.
	row.box:SetFocus()
	row.box:SetText("FF141414")
	W.Run(row.box, "OnEnterPressed")
	T.eq(Bytes(row.swatch.color.color), "20 20 20")
	W.Run(row.reset, "OnClick")
	T.eq(Get(), "FF2B9305")
	o.refs.search:SetText("")
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("color"), "OnClick")
	T.eq(Shown(o), "[Interface] raidFramesHealthBarColor", "the type menu finds it")
end)

T.test("all: search and Changed reach the CVars that are folded away", function()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	o.refs.search:SetText("loot window")
	T.eq(Shown(o), "[Interface] autoLootDefault", "the game's help text")
	o.refs.search:SetText("NAMEPLATE")
	T.eq(Shown(o), "[Nameplates] nameplateMaxDistance", "the CVar's name")
	o.refs.search:SetText("sound")
	T.eq(Shown(o), "[Sound] CAAPlayerCastMode Sound_MusicVolume", "a section's name finds everything in it")
	o.refs.search:SetText("graphics")
	T.eq(Shown(o), "[Graphics] shadowSoft [others] gxMonitor screenshotSizeOverride", "the other CVars are set apart from the knobs")
	T.eq(o.rows[3].title:GetText(), "Other CVars")
	T.ok(not o.rows[3].presets:IsShown() and o.rows[1].presets:IsShown(), "that header has no presets of its own")
	for _, row in ipairs(o.rows) do
		if row:IsShown() then W.Run(row.name, "OnEnter") end
	end
	o.refs.search:SetText("")
	EverySetting.RawKnob("Sound_MusicVolume", "")
	EverySetting.Set("Sound_MusicVolume", 0.5)
	o.refs.changed:SetChecked(true)
	W.Run(o.refs.changed, "OnClick")
	T.eq(Shown(o), "[Sound] Sound_MusicVolume")
end)

T.test("all: Tuned leaves out the other CVars, and a type shows only its kind", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	o.refs.tuned:SetChecked(true)
	W.Run(o.refs.tuned, "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft")
	o.refs.search:SetText("sound")
	T.eq(Shown(o), "", "even from a search")
	T.ok(o.refs.noMatch:IsShown())
	o.refs.search:SetText("")
	o.refs.tuned:SetChecked(false)
	W.Run(o.refs.tuned, "OnClick")
	T.eq(o.refs.kind.label:GetText(), "Any type")
	W.Run(o.refs.kind, "OnClick")
	T.ok(MenuItem("any").active, "the type in use is marked")
	W.Run(MenuItem("slider"), "OnClick")
	T.eq(o.refs.kind.label:GetText(), "Sliders")
	T.eq(Shown(o), "[Sound] Sound_MusicVolume [Interface] TurnSpeed")
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("text"), "OnClick")
	T.eq(Shown(o), "[Graphics] gxMonitor screenshotSizeOverride [Nameplates] nameplateMaxDistance [Other] brandNewInAPatch")
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("toggle"), "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft [Interface] autoLootDefault", "knobs from Knobs.lua too")
	-- The sidebar clears a filter that hides its section.
	W.Run(o.refs.side[3], "OnClick")
	T.eq(o.refs.kind.label:GetText(), "Any type")
	T.eq(Shown(o), "[Graphics] shadowSoft ... [Nameplates] ... [Sound] ... CAAPlayerCastMode Sound_MusicVolume [Interface] ... [Other] ...")
	for _, w in ipairs({ o.refs.tuned, o.refs.kind, o.refs.changed, o.refs.search }) do W.Run(w, "OnEnter") end
end)

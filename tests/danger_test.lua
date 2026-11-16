-- Danger mode: the settings the game's server enforces or the client locks,
-- which Every Setting leaves alone outside it and changes only by hand in it.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a danger setting of each kind among ordinary ones
-- (mouseSpeed among those is secure):
--   TurnSpeed                     the server's (and secure, as in the game)
--   VoiceOutputVolume             locked by the client, and set through the game's own function
--   accountNeedsTurnStrafeDialog  locked, with none: the game offers no way to change it
--   portal                        read-only, and a write doesn't take
--   gxMonitor                     read-only, and a knob from Knobs.lua
-- Network has nothing but portal. `saved` is last session's saved variables,
-- and `extras` adds that many knobs to Graphics, for a list too long to see whole.
-- With `unlisted` the list of every CVar isn't made yet, as before the window first opens.
local function Start(saved, extras, unlisted)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	W.AddCVar("Sound_MusicVolume", "0.4")
	W.AddCVar("VoiceOutputVolume", "100", { locked = true, takes = true })
	W.AddCVar("mouseSpeed", "1", { secure = true })
	W.AddCVar("TurnSpeed", "180", { min = 1, max = 540, secure = true, help = "capped by the server" })
	W.AddCVar("accountNeedsTurnStrafeDialog", "1", { locked = true })
	W.AddCVar("portal", "us", { readOnly = true })
	local shadows = {
		{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle", tiers = { 0, 0, 1, 1 } },
		{ cvar = "gxMonitor", label = "Monitor", type = "choice", tiers = { 0, 1, 0, 1 },
		  options = { { 0, "Primary" }, { 1, "Second" } } },
	}
	EverySetting.CVARS = { shadowSoft = "1", gxMonitor = "1", Sound_MusicVolume = "2|s|0|1|0.05",
		VoiceOutputVolume = "2|s|0|100|1", mouseSpeed = "3", TurnSpeed = "3|S|1|540|1|x",
		accountNeedsTurnStrafeDialog = "3|t", portal = "4" }
	for i = 1, extras or 0 do
		W.AddCVar("extra" .. i, "0")
		shadows[#shadows + 1] = { cvar = "extra" .. i, label = "Extra " .. i, type = "toggle" }
		EverySetting.CVARS["extra" .. i] = "1"
	end
	EverySetting.GROUPS = { { title = "Shadows", items = shadows } }
	EverySetting.SECTIONS = { "Graphics", "Sound and voice", "Mouse and keyboard", "Network" }
	EverySetting.STYLES = { { name = "Film", tier = 4, tip = "A test.", set = { gxMonitor = 1 } } }
	W.Login()
	if not unlisted then EverySetting.AllGroups() end -- a knob for every CVar, as the window makes them
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

-------------------------------------------------------------------------------
-- Core.lua
-------------------------------------------------------------------------------

T.test("danger: a setting the server enforces or the client locks is one, by kind", function()
	local EverySetting = Start()
	local kinds = { TurnSpeed = "server", VoiceOutputVolume = "locked", accountNeedsTurnStrafeDialog = "locked",
		portal = "readonly", gxMonitor = "readonly" }
	for cvar, kind in pairs(kinds) do
		local knob = EverySetting.RawKnob(cvar, "")
		T.eq(knob.danger, kind, cvar)
		T.eq(knob.locked, true, cvar .. " is left alone")
	end
	for _, cvar in ipairs({ "shadowSoft", "Sound_MusicVolume", "mouseSpeed" }) do
		local knob = EverySetting.RawKnob(cvar, "")
		T.eq(knob.danger, nil, cvar)
		T.eq(knob.locked, false, cvar)
	end
	local turn = EverySetting.Knob("TurnSpeed")
	T.eq(turn.type, "slider", "the control before the x")
	T.eq(turn.min, 1) T.eq(turn.max, 540) T.eq(turn.step, 1)
	T.eq(turn.raw, false, "its box is held to the range")
	T.eq(EverySetting.GetDanger(), false, "danger mode is off at first")
end)

T.test("danger: outside danger mode they're never written", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set("TurnSpeed", 300), nil)
	T.eq(EverySetting.Set("VoiceOutputVolume", 50), nil)
	T.eq(EverySetting.Set("portal", "eu", true), nil)
	T.eq(EverySetting.Set("gxMonitor", 1), nil)
	EverySetting.Reset("TurnSpeed", true)
	T.eq(W.SetCount("TurnSpeed") + W.SetCount("VoiceOutputVolume") + W.SetCount("portal") + W.SetCount("gxMonitor"), 0)
	T.eq(next(EverySettingDB.profiles.Default), nil, "nothing kept")
	-- One a profile keeps all the same isn't set at login, or by switching to the profile.
	EverySetting = Start({ profiles = { Default = { TurnSpeed = "250" }, Fast = { VoiceOutputVolume = "50" } } })
	EverySetting.SetProfile("Fast")
	T.eq(W.SetCount("TurnSpeed") + W.SetCount("VoiceOutputVolume"), 0)
end)

T.test("danger: in danger mode one set by hand is kept, and set again at login", function()
	local EverySetting = Start()
	EverySetting.SetDanger(true)
	T.eq(EverySettingDB.danger, true, "for every character")
	T.eq(EverySetting.Set("TurnSpeed", 300), "300")
	T.eq(EverySetting.Set("TurnSpeed", "9999", true), "540", "its box is held to the range")
	T.eq(EverySetting.Set("VoiceOutputVolume", 50), "50")
	T.ok(EverySetting.IsStored("TurnSpeed") and EverySetting.IsStored("VoiceOutputVolume"), "kept in the profile")
	T.eq(EverySettingDB.before.TurnSpeed, "180", "with the value Reset puts back")
	EverySetting = Start(EverySettingDB)
	T.eq(EverySetting.GetDanger(), true, "still on after a reload")
	T.eq(Get("TurnSpeed"), "540", "set again at login")
	T.eq(Get("VoiceOutputVolume"), "50")
	EverySetting.Reset("TurnSpeed")
	T.eq(Get("TurnSpeed"), "180", "Reset puts it back")
	T.ok(EverySetting.Undo())
	T.eq(Get("TurnSpeed"), "540", "and Undo takes that back")
	T.eq(EverySetting.ResetAll(), 2, "Reset all covers them")
	T.eq(Get("TurnSpeed"), "180")
	T.eq(Get("VoiceOutputVolume"), "100")
end)

T.test("danger: in danger mode profiles keep one like any other setting", function()
	local EverySetting = Start({ danger = true })
	EverySetting.NewProfile("Fast")
	EverySetting.Set("TurnSpeed", 500)
	EverySetting.SetProfile("Default")
	T.eq(Get("TurnSpeed"), "180", "what only the other profile keeps goes back")
	EverySetting.SetProfile("Fast")
	T.eq(Get("TurnSpeed"), "500", "and is set when it's switched to")
	EverySetting.SetProfile("Default")
	EverySetting.CopyProfile("Fast")
	T.eq(Get("TurnSpeed"), "500", "Reset all to another profile takes it")
	T.eq(EverySettingDB.profiles.Default.TurnSpeed, "500")
end)

T.test("danger: turning it off leaves the CVars as they are, and nothing keeps them", function()
	local EverySetting = Start({ danger = true })
	EverySetting.Set("TurnSpeed", 300)
	EverySetting.Set("mouseSpeed", "2", true)
	EverySetting.NewProfile("Fast")
	EverySetting.Set("TurnSpeed", 500)
	EverySetting.SetDanger(false)
	T.eq(EverySettingDB.danger, nil)
	T.eq(Get("TurnSpeed"), "500", "left as it is")
	T.eq(EverySettingDB.profiles.Default.TurnSpeed, nil, "dropped from every profile")
	T.eq(EverySettingDB.profiles.Fast.TurnSpeed, nil)
	T.eq(EverySettingDB.before.TurnSpeed, nil, "with nothing left for Reset")
	T.eq(EverySettingDB.profiles.Fast.mouseSpeed, "2", "the other settings are still kept")
	T.eq(EverySettingDB.before.mouseSpeed, "1")
	-- Undo and Reset don't bring it back.
	T.eq(EverySetting.Set("TurnSpeed", 200), nil)
	T.ok(EverySetting.Undo(), "the change to 500 is still in the history")
	T.eq(Get("TurnSpeed"), "500")
	T.ok(not EverySetting.IsStored("TurnSpeed"))
	T.eq(EverySettingDB.before.TurnSpeed, nil)
	T.ok(EverySetting.Redo())
	T.eq(Get("TurnSpeed"), "500")
	T.ok(not EverySetting.IsStored("TurnSpeed"))
	EverySetting.Reset("TurnSpeed", true)
	T.eq(EverySetting.ResetAll(), 1, "just mouseSpeed")
	T.eq(Get("TurnSpeed"), "500")
	-- Nor does the next login.
	Start(EverySettingDB)
	T.eq(W.SetCount("TurnSpeed"), 0)
end)

T.test("danger: turning it off drops a change that was waiting for combat to end", function()
	local EverySetting = Start({ danger = true })
	W.Combat(true)
	T.eq(EverySetting.Set("TurnSpeed", 400), "400")
	T.ok(EverySetting.IsPending("TurnSpeed"), "it's secure, so it waits")
	EverySetting.SetDanger(false)
	T.ok(not EverySetting.IsPending("TurnSpeed") and not EverySetting.IsStored("TurnSpeed"))
	W.Combat(false)
	T.eq(Get("TurnSpeed"), "180")
	T.eq(W.SetCount("TurnSpeed"), 0)
end)

T.test("danger: presets, styles, situations, imports and exports leave them alone, in danger mode or not", function()
	for _, on in ipairs({ false, true }) do
		local what = on and " in danger mode" or " outside it"
		local EverySetting = Start({ danger = on or nil })
		EverySetting.ApplyPreset({ TurnSpeed = "300", VoiceOutputVolume = "50", mouseSpeed = "2" })
		T.eq(Get("mouseSpeed"), "2", "a preset sets the rest" .. what)
		T.eq(Get("TurnSpeed"), "180", "a preset" .. what)
		T.eq(Get("VoiceOutputVolume"), "100", "a preset" .. what)
		T.ok(not EverySetting.IsStored("TurnSpeed") and not EverySetting.IsStored("VoiceOutputVolume"))

		local style = EverySetting.StylePreset(EverySetting.STYLES[1])
		T.eq(style.shadowSoft, "1", "a style sets the rest" .. what)
		T.eq(style.gxMonitor, nil, "a style" .. what)

		EverySetting.SavePreset("Ride", { VoiceOutputVolume = "50", Sound_MusicVolume = "0.8" })
		EverySetting.SetSituation("mounted", "Ride")
		W.Mount(true)
		T.eq(Get("Sound_MusicVolume"), "0.8", "a situation sets the rest" .. what)
		T.eq(Get("VoiceOutputVolume"), "100", "a situation" .. what)
		W.Mount(false)

		local text = "EverySetting:1:Sound_MusicVolume=0.6,TurnSpeed=300,VoiceOutputVolume=50"
		T.eq(EverySetting.ImportPreset("Shared", text), nil)
		local shared = EverySetting.GetPresets().Shared
		T.eq(shared.Sound_MusicVolume, "0.6", "an imported preset has the rest" .. what)
		T.ok(shared.TurnSpeed == nil and shared.VoiceOutputVolume == nil, "an imported preset" .. what)
		T.eq(EverySetting.ImportProfile("Theirs", text), nil)
		T.eq(Get("Sound_MusicVolume"), "0.6")
		T.eq(Get("TurnSpeed"), "180", "an imported profile" .. what)
		T.eq(Get("VoiceOutputVolume"), "100", "an imported profile" .. what)
		T.eq(EverySettingDB.profiles.Theirs.TurnSpeed, nil)

		if on then
			T.eq(EverySetting.Set("VoiceOutputVolume", 50), "50")
			T.eq(EverySetting.Changes().VoiceOutputVolume, nil, "nor can a situation take one changed by hand")
		end
		T.eq(EverySetting.ExportProfile(), "EverySetting:1:Sound_MusicVolume=0.6", "an export" .. what)
		T.eq(EverySetting.ExportProfile({ mouseSpeed = "2", TurnSpeed = "300", portal = "eu" }), "EverySetting:1:mouseSpeed=2",
			"an export of part of a profile" .. what)
	end
end)

T.test("danger: a CVar named in another letter case is the same danger setting", function()
	-- CVar names ignore case, and an import or /every probe takes the name as it's typed.
	-- Before the window has listed every CVar, that name is the first the knob is made by.
	local EverySetting = Start(nil, nil, true)
	T.eq(EverySetting.ImportProfile("Theirs", "EverySetting:1:mousespeed=2,turnspeed=300"), nil)
	T.eq(Get("TurnSpeed"), "180", "an imported line doesn't carry one in under another spelling")
	T.eq(Get("mouseSpeed"), "2")
	local knob = EverySetting.RawKnob("TURNSPEED", "")
	T.eq(knob.cvar, "TurnSpeed", "the knob has the name CVars.lua gives it")
	T.eq(knob.danger, "server")
	T.eq(knob.type, "slider", "and its control")
	T.eq(EverySetting.Set("turnspeed", 300), nil)
	T.eq(EverySetting.Section("turnspeed"), EverySetting.Section("TurnSpeed"), "and its section")
	W.chat = {}
	SlashCmdList.EVERYSETTING("probe turnspeed 100 200")
	T.eq(Get("TurnSpeed"), "180")
	T.ok(W.chat[1]:find("danger setting", 1, true), W.chat[1])
end)

T.test("danger: a locked setting the game has a function of its own for is set through it", function()
	local EverySetting = Start({ danger = true })
	local cvar = W.cvars.voiceoutputvolume
	cvar.takes = nil -- the game turns down a change to the CVar itself
	T.eq(EverySetting.Knob("VoiceOutputVolume").setter, true)
	T.eq(EverySetting.Knob("portal").setter, nil)
	W.chat = {}
	T.eq(EverySetting.Set("VoiceOutputVolume", 60), nil, "a client without the function")
	T.ok(W.chat[1]:find("/run C_VoiceChat.SetOutputVolume(60)", 1, true), W.chat[1])

	local calls = {}
	_G.C_VoiceChat = { SetOutputVolume = function(volume)
		calls[#calls + 1] = volume
		cvar.value = tostring(volume)
	end }
	T.eq(EverySetting.Set("VoiceOutputVolume", 60), "60")
	T.eq(calls[1], 60, "given a number")
	T.ok(EverySetting.IsStored("VoiceOutputVolume"))
	T.eq(EverySetting.Command("VoiceOutputVolume", "60"), "/run C_VoiceChat.SetOutputVolume(60)")
	T.eq(EverySetting.Command("VoiceOutputVolume", "loud"), '/run SetCVar("VoiceOutputVolume", "loud")', "which only takes one")
	EverySetting.Reset("VoiceOutputVolume")
	T.eq(Get("VoiceOutputVolume"), "100", "Reset goes through it too")
	T.eq(calls[2], 100)
	_G.C_VoiceChat = nil
end)

T.test("danger: one the game doesn't change isn't kept, and a line says so", function()
	local EverySetting = Start({ danger = true })
	W.chat = {}
	T.eq(EverySetting.Set("portal", "eu", true), nil)
	T.eq(Get("portal"), "us")
	T.ok(not EverySetting.IsStored("portal"), "not kept")
	T.eq(EverySettingDB.before.portal, nil, "with nothing for Reset")
	T.eq(EverySetting.HistorySize(), 0, "or for Undo")
	T.eq(#W.chat, 1, "one line")
	T.ok(W.chat[1]:find("didn't take eu for portal", 1, true), W.chat[1])
	T.ok(not W.chat[1]:find("/run", 1, true), "no command: the game turns that down too")
	-- The value it already has is no refusal, and what's kept stays through a later one.
	T.eq(EverySetting.Set("portal", "us", true), "us")
	T.eq(EverySetting.Set("portal", "kr", true), nil)
	T.eq(EverySetting.GetKept().portal, "us")
	T.eq(#W.chat, 2)
	-- Nor is a slider's end, asked for again.
	T.eq(EverySetting.Set("TurnSpeed", 540), "540")
	T.eq(EverySetting.Set("TurnSpeed", "9999", true), "540")
	T.eq(#W.chat, 2)
end)

T.test("danger: the command for a value quotes it unless it's a number", function()
	local EverySetting = Start()
	T.eq(EverySetting.Command("TurnSpeed", 540), '/run SetCVar("TurnSpeed", 540)')
	T.eq(EverySetting.Command("TurnSpeed", "540"), '/run SetCVar("TurnSpeed", 540)')
	T.eq(EverySetting.Command("cameraPitch", "-5"), '/run SetCVar("cameraPitch", -5)', "negative")
	T.eq(EverySetting.Command("Sound_MusicVolume", "0.25"), '/run SetCVar("Sound_MusicVolume", 0.25)', "decimal")
	T.eq(EverySetting.Command("portal", "eu"), '/run SetCVar("portal", "eu")', "text")
	T.eq(EverySetting.Command("portal", 'a "b" c\\d'), '/run SetCVar("portal", "a \\"b\\" c\\\\d")', "a quote and a backslash")
	T.eq(EverySetting.Command("portal", ""), '/run SetCVar("portal", "")', "empty")
	T.eq(EverySetting.Command("portal", "1e5"), '/run SetCVar("portal", "1e5")', "only plain numbers go bare")
	T.eq(EverySetting.Command("petJournalFilters", "007"), '/run SetCVar("petJournalFilters", "007")', "a number Lua would change is quoted")
	T.eq(EverySetting.Command("lastAttemptedExternalEventURLHash", "12345678901234567890"),
		'/run SetCVar("lastAttemptedExternalEventURLHash", "12345678901234567890")', "and one too long for it")
	T.eq(EverySetting.Command("TurnSpeed", "180.000000"), '/run SetCVar("TurnSpeed", "180.000000")')
end)

T.test("danger: /every danger turns it on and off", function()
	local EverySetting = Start()
	W.Slash("danger")
	T.eq(EverySetting.GetDanger(), true, "no argument toggles it")
	T.ok(W.chat[#W.chat]:find("danger mode is on", 1, true), W.chat[#W.chat])
	W.Slash("danger")
	T.eq(EverySetting.GetDanger(), false)
	T.ok(W.chat[#W.chat]:find("danger mode is off", 1, true), W.chat[#W.chat])
	W.Slash("danger ON")
	T.eq(EverySetting.GetDanger(), true)
	W.Slash("danger on")
	T.eq(EverySetting.GetDanger(), true, "on stays on")
	W.Slash("danger maybe")
	T.eq(EverySetting.GetDanger(), true)
	T.ok(W.chat[#W.chat]:find("usage: /every danger [on|off]", 1, true), W.chat[#W.chat])
	W.Slash("danger off")
	T.eq(EverySetting.GetDanger(), false)
end)

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------

local function Open(saved, extras)
	local EverySetting, o = Start(saved, extras)
	EverySetting_OpenOptions()
	return EverySetting, o
end

local OFF = "[Graphics] shadowSoft gxMonitor [Sound and voice] ... [Mouse and keyboard] ... [Network] ..."
local DANGER = "[Danger] [Server-enforced] TurnSpeed [Locked, set indirectly] VoiceOutputVolume "
	.. "[Locked, can't be changed] accountNeedsTurnStrafeDialog [Read-only] portal"
local ON = "[Graphics] shadowSoft gxMonitor [Sound and voice] ... [Mouse and keyboard] ... " .. DANGER

-- What the list shows: [a header], a CVar, or ... for the button that unfolds a section's other CVars.
local function Shown(o)
	local out = {}
	for _, item in ipairs(o.view) do
		out[#out + 1] = item.others and "[others]" or item.header and ("[" .. (item.group or item.section).title .. "]")
			or item.more and "..." or item.knob.cvar
	end
	return table.concat(out, " ")
end

-- The row showing `cvar`, the one with the header `title`, and the button that
-- unfolds the section `title`, if they're scrolled into view.
local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

local function Header(o, title)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.header and (row.item.group or row.item.section).title == title then return row end
	end
end

local function More(o, title)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.more and row.item.section.title == title then return row.more end
	end
end

-- The sidebar's button for the section `title`.
local function Side(o, title)
	for _, b in ipairs(o.refs.side) do
		if b.label:GetText() == title then return b end
	end
end

-- The menu's button for `value`, if the menu is open.
local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

-- Ticks or unticks a checkbox, as a click does.
local function Tick(box, on)
	box:SetChecked(on)
	W.Run(box, "OnClick")
end

-- Types `text` in a row's box and presses Enter.
local function Type(row, text)
	row.box:SetFocus()
	row.box:SetText(text)
	W.Run(row.box, "OnEnterPressed")
end

-- The tooltip a row's name gives: its lines, as one string.
local function Tip(row)
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	return table.concat(lines, "\n")
end

-- The colour `run` gives a font string last, as "r g b".
local function Color(text, run)
	local color
	rawset(text, "SetTextColor", function(_, r, g, b) color = ("%.2f %.2f %.2f"):format(r, g, b) end)
	run()
	rawset(text, "SetTextColor", nil)
	return color
end

T.test("danger: outside danger mode they sit in their sections, greyed out", function()
	local _, o = Open()
	T.eq(Shown(o), OFF)
	T.eq(o.refs.side[#o.refs.side], Side(o, "Danger"), "Danger's sidebar button is the last")
	T.ok(not Side(o, "Danger"):IsShown() and Side(o, "Network"):IsShown(), "and hidden")
	T.eq(More(o, "Mouse and keyboard").label:GetText(), "Show 3 CVars")
	W.Run(More(o, "Mouse and keyboard"), "OnClick")
	W.Run(More(o, "Network"), "OnClick")
	local turn, dialog, portal = RowFor(o, "TurnSpeed"), RowFor(o, "accountNeedsTurnStrafeDialog"), RowFor(o, "portal")
	T.ok(turn.label:GetText():find("(hands off)", 1, true), "the server's")
	T.ok(dialog.label:GetText():find("(locked)", 1, true), "the client's")
	T.ok(portal.label:GetText():find("(read-only)", 1, true), "read-only")
	T.eq(turn.slider.off, true)
	T.ok(not turn.box:IsEnabled() and not dialog.check:IsEnabled() and not portal.box:IsEnabled())
	T.ok(turn.lock:IsShown() and not turn.command:IsShown(), "no command button")
	T.ok(RowFor(o, "shadowSoft").lock:IsShown() and RowFor(o, "shadowSoft").command:IsShown(),
		"an ordinary row has its lock box and the command button")
	T.ok(Tip(turn):find("server enforces this setting, so Every Setting leaves it alone", 1, true))
	T.ok(Tip(turn):find("/every danger", 1, true), "the tooltip points at danger mode")
	T.ok(Tip(dialog):find("game locks this setting and offers no way to change it", 1, true))
	T.ok(not Tip(dialog):find("Danger mode", 1, true), "danger mode can't change it either, so it isn't offered")
	T.ok(Tip(portal):find("read-only and offers no way to change it", 1, true) and not Tip(portal):find("Danger mode", 1, true))
	W.Run(More(o, "Sound and voice"), "OnClick")
	T.ok(Tip(RowFor(o, "VoiceOutputVolume")):find("Danger mode", 1, true), "one with the game's own function points at danger mode")
	o.refs.search:SetText("turnspeed")
	T.eq(Shown(o), "[Mouse and keyboard] TurnSpeed", "search finds it there")
end)

T.test("danger: in danger mode the window gathers them under Danger, the last section", function()
	local EverySetting, o = Open()
	W.Run(Header(o, "Sound and voice").presets, "OnClick")
	T.ok(MenuItem("import") and not MenuItem("save"), "nothing changed there to save as a preset")
	W.Run(Header(o, "Sound and voice").presets, "OnClick")
	EverySetting.SetDanger(true)
	T.eq(Shown(o), ON, "a group for each kind, each in name order")
	T.eq(More(o, "Mouse and keyboard").label:GetText(), "Show 1 CVar", "they've left their own sections")
	T.eq(More(o, "Sound and voice").label:GetText(), "Show 1 CVar")
	T.ok(Side(o, "Danger"):IsShown(), "the sidebar has Danger")
	T.ok(not Side(o, "Network"):IsShown(), "and not a section that has nothing left")
	local RED, AMBER = "1.00 0.44 0.35", "1.00 0.69 0.00"
	T.eq(Color(Side(o, "Danger").label, function() W.Run(Side(o, "Danger"), "OnLeave") end), RED, "in red")
	T.eq(Color(Header(o, "Danger").title, EverySetting.Changed), RED, "like its title in the list")
	T.eq(Color(Header(o, "Read-only").title, EverySetting.Changed), RED, "and its groups'")
	T.eq(Color(Header(o, "Graphics").title, EverySetting.Changed), AMBER, "the others stay amber")
	for _, title in ipairs({ "Danger", "Server-enforced", "Locked, set indirectly", "Locked, can't be changed", "Read-only" }) do
		local header = Header(o, title)
		T.ok(not header.presets:IsShown() and not header.lock:IsShown(), title .. " has no Presets and no lock box")
		T.ok(header.fold:IsShown(), title .. " folds")
	end
	T.ok(Header(o, "Graphics").presets:IsShown() and Header(o, "Graphics").lock:IsShown(), "the other headers keep theirs")
	T.eq(#EverySetting.GROUPS, 1, "Danger's groups aren't among the tuned ones")
	W.Run(o.refs.lockAll, "OnClick")
	T.ok(EverySetting.IsLocked("shadowSoft") and not EverySetting.IsLocked("TurnSpeed"), "so Lock all leaves them out")

	-- A row's own control sets it, and shows what the game kept.
	local turn, voice, portal = RowFor(o, "TurnSpeed"), RowFor(o, "VoiceOutputVolume"), RowFor(o, "portal")
	T.eq(turn.label:GetText(), "TurnSpeed", "no longer marked")
	T.eq(turn.slider.off, false)
	T.ok(not turn.lock:IsShown() and turn.command:IsShown(), "a command button where the lock box was")
	T.ok(RowFor(o, "shadowSoft").lock:IsShown() and RowFor(o, "shadowSoft").command:IsShown(), "an ordinary row keeps both")
	T.ok(Tip(turn):find("may disconnect you", 1, true), "the tooltip warns")
	T.ok(Tip(turn):find("/ button", 1, true), "and points at the command")
	T.ok(Tip(voice):find("the game's own function", 1, true), "one it has a function for says so")
	T.ok(Tip(portal):find("offers no way to change it", 1, true) and Tip(portal):find("in danger mode too", 1, true),
		"and one it has none for says the game offers no way")
	T.ok(not Tip(portal):find("The box takes any value", 1, true), "and nothing about a box it can't take")
	T.ok(Tip(RowFor(o, "VoiceOutputVolume")):find("The box takes any value", 1, true), "as one it can still says")
	W.Run(turn.command, "OnEnter")
	Type(turn, "300")
	T.eq(Get("TurnSpeed"), "300")
	T.ok(turn.kept:IsShown() and turn.reset:IsShown(), "kept, with a Reset")
	T.eq(Side(o, "Danger").count:GetText(), "1", "and counted under Danger")
	Type(turn, "9999")
	T.eq(turn.box:GetText(), "540", "held to its range")
	Type(voice, "50")
	T.eq(Get("VoiceOutputVolume"), "50")
	W.Run(Header(o, "Sound and voice").presets, "OnClick")
	T.ok(MenuItem("import") and not MenuItem("save"), "what's changed under Danger isn't its old section's to save or export")
	W.Run(Header(o, "Sound and voice").presets, "OnClick")
	-- One the game offers no way to change stays greyed out, with its command to copy.
	T.ok(portal.label:GetText():find("(read-only)", 1, true))
	T.ok(not portal.box:IsEnabled() and not portal.lock:IsShown() and portal.command:IsShown())
	local dialog = RowFor(o, "accountNeedsTurnStrafeDialog")
	T.ok(not dialog.check:IsEnabled() and dialog.command:IsShown() and dialog.label:GetText():find("(locked)", 1, true))
	W.Run(turn.reset, "OnClick")
	T.eq(Get("TurnSpeed"), "180")

	-- A knob from Knobs.lua stays in its group, and the group's presets leave it out.
	local monitor = RowFor(o, "gxMonitor")
	T.ok(monitor.command:IsShown() and not monitor.lock:IsShown() and monitor.dropdown.off == true, "read-only: greyed out, with its command")
	W.Run(Header(o, "Graphics").presets, "OnClick")
	T.eq(MenuItem("tier:1").label:GetText(), "Low / Medium", "as shadowSoft's alone would have them")
	W.Run(MenuItem("style:Film"), "OnClick")
	T.eq(Get("shadowSoft"), "0", "locked just now")
	T.eq(Get("gxMonitor"), "0")

	EverySetting.SetDanger(false)
	T.eq(Shown(o), OFF, "and back")
	T.ok(not Side(o, "Danger"):IsShown() and Side(o, "Network"):IsShown())
	T.eq(Side(o, "Sound and voice").count:GetText(), "", "nothing is kept for them any more")
end)

T.test("danger: the sidebar has no place for a section with nothing listed", function()
	local EverySetting, o = Open()
	local danger, network = Side(o, "Danger"), Side(o, "Network")
	-- How far down the sidebar a turn of the wheel puts a button.
	local function Down(button)
		local down
		rawset(button, "SetPoint", function(_, _, _, y) down = -y end)
		W.Run(o.refs.sidebar, "OnMouseWheel", -1)
		rawset(button, "SetPoint", nil)
		return down
	end
	T.eq(Down(network), 75, "Network is the fourth")
	T.ok(not danger:IsShown(), "and Danger has no button outside danger mode")
	EverySetting.SetDanger(true)
	T.eq(Down(danger), 75, "in danger mode Danger is the fourth")
	T.ok(not network:IsShown(), "Network has nothing left")
	T.ok(not danger.groups[1]:IsShown(), "Danger's groups wait until it's in view")
	o.refs.search:SetText("turnspeed")
	T.ok(danger.groups[1]:IsShown() and danger.groups[3]:IsShown(), "and are under it then")
	EverySetting.SetDanger(false)
	T.ok(not danger:IsShown() and not danger.groups[1]:IsShown() and network:IsShown(), "all gone with danger mode")
end)

T.test("danger: the Danger section folds, is searched and filtered, and is left out by Tuned", function()
	local EverySetting, o = Open({ danger = true })
	W.Run(Header(o, "Locked, can't be changed").fold, "OnClick")
	T.eq(EverySettingDB.folded["Danger/Locked, can't be changed"], true, "saved like any group's")
	T.eq(Shown(o), "[Graphics] shadowSoft gxMonitor [Sound and voice] ... [Mouse and keyboard] ... "
		.. "[Danger] [Server-enforced] TurnSpeed [Locked, set indirectly] VoiceOutputVolume [Locked, can't be changed] [Read-only] portal")
	W.Run(Header(o, "Danger").fold, "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft gxMonitor [Sound and voice] ... [Mouse and keyboard] ... [Danger]")
	W.Run(o.refs.foldAll, "OnClick")
	T.eq(Shown(o), "[Graphics] [Sound and voice] [Mouse and keyboard] [Danger]")
	T.eq(EverySettingDB.folded.Network, nil, "a section with nothing listed isn't folded")
	T.eq(o.refs.foldAll.label:GetText(), "Expand all", "or waited for")
	W.Run(o.refs.foldAll, "OnClick")
	T.eq(Shown(o), ON)
	W.Run(o.refs.foldAll, "OnClick")
	W.Run(Side(o, "Danger"), "OnClick")
	T.eq(Shown(o), "[Graphics] [Sound and voice] [Mouse and keyboard] " .. DANGER, "the sidebar unfolds it")
	W.Run(o.refs.foldAll, "OnClick")
	W.Run(o.refs.foldAll, "OnClick")

	o.refs.search:SetText("turnspeed")
	T.eq(Shown(o), "[Danger] [Server-enforced] TurnSpeed", "search finds it under Danger")
	o.refs.search:SetText("read-only")
	T.eq(Shown(o), "[Danger] [Read-only] portal", "by its group's title too")
	o.refs.search:SetText("")
	Tick(o.refs.tuned, true)
	T.eq(Shown(o), "[Graphics] shadowSoft gxMonitor", "Tuned leaves Danger out")
	o.refs.search:SetText("turnspeed")
	T.eq(Shown(o), "", "even from a search")
	o.refs.search:SetText("")
	W.Run(Header(o, "Graphics").fold, "OnClick")
	W.Run(Side(o, "Danger"), "OnClick")
	T.ok(not o.refs.tuned:GetChecked(), "the sidebar unticks Tuned to show it")
	Tick(o.refs.tuned, true)
	T.eq(Shown(o), "[Graphics]", "a folded Danger too")
	Tick(o.refs.tuned, false)
	W.Run(Header(o, "Graphics").fold, "OnClick")

	EverySetting.Set("TurnSpeed", 300)
	Tick(o.refs.changed, true)
	T.eq(Shown(o), "[Danger] [Server-enforced] TurnSpeed", "Changed")
	Tick(o.refs.changed, false)
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("slider"), "OnClick")
	T.eq(Shown(o), "[Sound and voice] Sound_MusicVolume [Danger] [Server-enforced] TurnSpeed [Locked, set indirectly] VoiceOutputVolume",
		"and the type menu")
end)

T.test("danger: a row's / button shows the command for its value, or for the one typed in its box", function()
	local _, o = Open({ danger = true })
	local turn = RowFor(o, "TurnSpeed")
	W.Run(turn.command, "OnClick")
	local dialog = o.refs.dialog
	T.ok(dialog:IsShown() and dialog.scroll:IsShown() and not dialog.name:IsShown() and not dialog.ok:IsShown(),
		"just the command and a Close button")
	T.eq(dialog.body:GetText(), '/run SetCVar("TurnSpeed", 180)')
	dialog.body.text = "oops"
	W.Run(dialog.body, "OnTextChanged", true)
	T.eq(dialog.body:GetText(), '/run SetCVar("TurnSpeed", 180)', "it can't be changed by typing in it")
	W.Run(dialog.cancel, "OnClick")
	turn.box:SetFocus()
	turn.box:SetText("700")
	W.Run(turn.command, "OnClick")
	T.eq(dialog.body:GetText(), '/run SetCVar("TurnSpeed", 700)', "what's typed, though it's past the slider's range")
	T.ok(not turn.box:HasFocus(), "what was typed is let go")
	T.eq(turn.box:GetText(), "180")
	T.eq(W.SetCount("TurnSpeed"), 0, "showing it sets nothing")
	W.Run(dialog.cancel, "OnClick")
	W.Run(RowFor(o, "portal").command, "OnClick")
	T.eq(dialog.body:GetText(), '/run SetCVar("portal", "us")', "text is quoted")
	W.Run(RowFor(o, "gxMonitor").command, "OnClick")
	T.eq(dialog.body:GetText(), '/run SetCVar("gxMonitor", 0)', "a row with no box gives the value it has")
end)

T.test("danger: every other row's / button gives its command too, and says what Every Setting does after", function()
	local EverySetting, o = Open()
	local dialog
	local TEXT = "Type this in chat to set %s yourself. Press Ctrl+C (Cmd+C on a Mac) to copy it. "
	local NOW = "That sets it now. Every Setting doesn't keep a value set this way."
	-- What the dialog says for a row, and the command it gives.
	local function Says(row)
		W.Run(row.command, "OnClick")
		dialog = o.refs.dialog -- made the first time it's needed
		local text, command = dialog.text:GetText(), dialog.body:GetText()
		W.Run(dialog.cancel, "OnClick")
		return text, command
	end
	local soft = RowFor(o, "shadowSoft")
	W.Run(soft.command, "OnClick")
	dialog = o.refs.dialog -- made the first time it's needed
	T.ok(dialog:IsShown() and not dialog.ok:IsShown(), "just the command and a Close button")
	T.eq(dialog.title:GetText(), "Command for shadowSoft")
	T.eq(dialog.body:GetText(), '/run SetCVar("shadowSoft", 0)', "a checkbox has no box: the value it has")
	T.eq(dialog.text:GetText(), TEXT:format("shadowSoft") .. NOW, "not kept")
	W.Run(dialog.cancel, "OnClick")
	W.Run(More(o, "Sound and voice"), "OnClick")
	local music = RowFor(o, "Sound_MusicVolume")
	T.ok(music.lock:IsShown() and music.command:IsShown(), "a raw slider has both")
	music.box:SetFocus()
	music.box:SetText("0.25")
	T.eq(select(2, Says(music)), '/run SetCVar("Sound_MusicVolume", 0.25)', "what's typed in its box")
	T.eq(music.box:GetText(), "0.4", "is let go")
	T.eq(W.SetCount("Sound_MusicVolume"), 0, "showing it sets nothing")
	-- In the game, pressing / takes the focus from the box before the click.
	rawset(music.command, "IsMouseOver", function() return true end)
	music.box:SetFocus()
	music.box:SetText("0.3")
	W.leftButton = true
	music.box:ClearFocus()
	T.eq(W.SetCount("Sound_MusicVolume"), 0, "what's typed isn't set as the box lets go")
	W.leftButton = false
	T.eq(select(2, Says(music)), '/run SetCVar("Sound_MusicVolume", 0.3)', "but is the command's")
	T.eq(music.box:GetText(), "0.4", "and the box shows the value it has again")
	T.eq(W.SetCount("Sound_MusicVolume"), 0)
	Type(music, "0.35")
	T.eq(Get("Sound_MusicVolume"), "0.35", "Enter sets it, with the pointer resting on / too")
	rawset(music.command, "IsMouseOver", nil)
	EverySetting.Reset("Sound_MusicVolume")

	-- One Every Setting keeps is set again at the next login, or a second later with Put back.
	EverySetting.Set("shadowSoft", true)
	T.eq(Says(soft), TEXT:format("shadowSoft") .. "That sets it now. Every Setting doesn't keep a value set this way, "
		.. "and sets the one you keep for it again at your next login.")
	EverySetting.SetPutBack(true)
	T.eq(Says(soft), TEXT:format("shadowSoft") .. "That sets it now. Every Setting doesn't keep a value set this way, "
		.. "and with Put back on it puts the one you keep for it back a second later.")
	T.eq(Says(music), TEXT:format("Sound_MusicVolume") .. NOW, "Put back doesn't touch one it doesn't keep")
	-- One the game locks in combat says so.
	o.refs.search:SetText("mousespeed")
	T.eq(Says(RowFor(o, "mouseSpeed")), TEXT:format("mouseSpeed") .. NOW .. " The game doesn't let it be set in combat.")

	-- In danger mode the danger settings' rows say what they did before.
	o.refs.search:SetText("")
	EverySetting.SetDanger(true)
	soft = RowFor(o, "shadowSoft")
	T.ok(soft.lock:IsShown() and soft.command:IsShown())
	o.refs.search:SetText("turnspeed")
	T.eq(Says(RowFor(o, "TurnSpeed")), TEXT:format("TurnSpeed") .. "Every Setting doesn't keep a value set this way.",
		"though TurnSpeed is secure too")
	o.refs.search:SetText("portal")
	T.eq(Says(RowFor(o, "portal")), TEXT:format("portal")
		.. "The game offers no way to change this setting, from an addon or typed in chat, so expect nothing to change.")
end)

T.test("danger: the checkbox at the bottom turns it on and goes to Danger", function()
	local EverySetting, o = Open(nil, 30)
	local box = o.refs.danger
	T.eq(box.text:GetText(), "Danger mode")
	T.ok(not box:GetChecked(), "unticked at first")
	W.Run(box, "OnEnter")
	Tick(box, true)
	T.eq(EverySetting.GetDanger(), true)
	T.ok(Header(o, "Danger") and RowFor(o, "TurnSpeed"), "scrolled into view, past the rest of the list")
	Tick(box, false)
	T.eq(EverySetting.GetDanger(), false)
	T.eq(o.rows[1].title:GetText(), "Graphics", "and back to the top once it's gone")
	W.Slash("danger on")
	T.ok(box:GetChecked(), "the box follows the command")
	EverySetting, o = Open(EverySettingDB)
	T.ok(EverySetting.GetDanger() and o.refs.danger:GetChecked(), "and a reload")
end)

T.test("danger: the footer's note about a game restart waits while Restart graphics has its place", function()
	local EverySetting, o = Open()
	EverySetting.restart.client = true
	EverySetting.Changed()
	T.ok(o.refs.note:GetText():find("next time you start the game", 1, true))
	EverySetting.restart.gx = true
	EverySetting.Changed()
	T.ok(o.refs.restartGx:IsShown())
	T.eq(o.refs.note:GetText(), "", "there's room for one of them beside Danger mode")
	W.Run(o.refs.restartGx, "OnClick")
	T.ok(not o.refs.restartGx:IsShown() and o.refs.note:GetText() ~= "", "it's back once the graphics have restarted")
end)

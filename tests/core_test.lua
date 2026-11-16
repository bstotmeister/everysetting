-- Core.lua: setting, resetting and re-applying knobs, against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A client with a few CVars and a knob for each, logged in. `saved` is last
-- session's saved variables, and `before` runs before login (as a preset would).
-- With `worldFirst` the world loads before the game's variables. `savedChar`
-- is the character's saved variables.
local function Start(saved, before, worldFirst, savedChar)
	local EverySetting = W.Load(saved, savedChar)
	W.AddCVar("groundEffectDist", "70", { min = 40, max = 600 })
	W.AddCVar("RAIDgroundEffectDist", "50", { min = 40, max = 600 })
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("ffxAntiAliasingMode", "0")
	W.AddCVar("RenderScale", "1", { min = 0.5, max = 2 })
	W.AddCVar("nameplateMaxDistance", "60", { secure = true })
	W.AddCVar("Sound_NumChannels", "64")
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	W.AddCVar("untouched", "5")
	EverySetting.GROUPS = {
		{ title = "Graphics", items = {
			{ cvar = "groundEffectDist", label = "Ground clutter distance", type = "slider", min = 40, max = 800, step = 10,
			  raid = "RAIDgroundEffectDist" },
			{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
			{ cvar = "ffxAntiAliasingMode", label = "Anti-aliasing", type = "choice", restart = "gx",
			  options = { { 0, "None" }, { 1, "FXAA low" }, { 2, "FXAA high" } } },
			{ cvar = "RenderScale", label = "Render scale", type = "slider", min = 0, max = 9, step = 0.05,
			  bounds = function() return 0.5, 2 end },
			{ cvar = "gxMonitor", label = "Monitor", type = "slider", min = 0, max = 3, step = 1 },
			{ cvar = "notInThisClient", label = "Missing", type = "toggle" },
		} },
		{ title = "Other", items = {
			{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
			{ cvar = "Sound_NumChannels", label = "Sound channels", type = "slider", min = 20, max = 128, step = 1, restart = "client" },
		} },
	}
	if before then before() end
	W.Login(worldFirst)
	return EverySetting
end

-- A test of the login, run once for each order its two events may come in.
local function EitherOrder(name, fn)
	T.test(name, function() fn(false) end)
	T.test(name .. " (the world loads first)", function() fn(true) end)
end

T.test("core: a slider value is clamped to the range and snapped to the step", function()
	local EverySetting = Start()
	local knob = EverySetting.Knob("groundEffectDist")
	T.eq(EverySetting.Normalize(knob, 123), "120", "snapped down")
	T.eq(EverySetting.Normalize(knob, 125), "130", "snapped up")
	T.eq(EverySetting.Normalize(knob, 5), "40", "clamped to min")
	T.eq(EverySetting.Normalize(knob, 99999), "800", "clamped to max")
	T.eq(EverySetting.Normalize(knob, "abc"), nil, "not a number")
	local scale = EverySetting.Knob("renderscale") -- CVar names ignore case
	T.eq(EverySetting.Normalize(scale, 0.724), "0.7", "fractional step")
	T.eq(EverySetting.Normalize(scale, 0.75), "0.75", "keeps the decimals it needs")
	T.eq(EverySetting.Normalize(scale, 1), "1", "no trailing zeros")
	T.eq(EverySetting.Normalize(scale, 5), "2", "the range from the bounds function")
end)

T.test("core: toggles and choices only take their own values", function()
	local EverySetting = Start()
	local toggle, choice = EverySetting.Knob("shadowSoft"), EverySetting.Knob("ffxAntiAliasingMode")
	T.eq(EverySetting.Normalize(toggle, true), "1")
	T.eq(EverySetting.Normalize(toggle, "1"), "1")
	T.eq(EverySetting.Normalize(toggle, false), "0")
	T.eq(EverySetting.Normalize(choice, 2), "2")
	T.eq(EverySetting.Normalize(choice, 7), nil, "not one of the options")
end)

T.test("core: Set stores what the engine kept, and sets the raid twin", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set("groundEffectDist", 800), "600", "the engine's cap is lower than the knob's")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "600")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "600", "raid twin")
	T.eq(EverySettingDB.profiles.Default.groundEffectDist, "600", "remembered")
	T.ok(EverySetting.IsStored("groundEffectDist"))
end)

T.test("core: knobs that are missing or locked can't be set", function()
	local EverySetting = Start()
	T.eq(EverySetting.Knob("notInThisClient").found, false)
	T.eq(EverySetting.Set("notInThisClient", 1), nil, "missing")
	T.eq(EverySetting.Knob("gxMonitor").locked, true)
	T.eq(EverySetting.Set("gxMonitor", 2), nil, "read-only")
	T.eq(EverySetting.Set("untouched", 9), nil, "not a knob")
	T.eq(EverySetting.Set("ffxAntiAliasingMode", 7), nil, "not an option")
	T.eq(next(EverySettingDB.profiles.Default), nil, "nothing remembered")
	T.eq(C_CVar.GetCVar("untouched"), "5")
end)

T.test("core: Reset puts back the value from before Every Setting, and forgets its own", function()
	local EverySetting = Start(nil, function()
		C_CVar.SetCVar("groundEffectDist", "320") -- the graphics preset's value, not the default (70)
		C_CVar.SetCVar("RAIDgroundEffectDist", "185")
	end)
	EverySetting.Set("groundEffectDist", 400)
	EverySetting.Set("groundEffectDist", 500) -- a second change doesn't move what Reset goes back to
	T.eq(EverySetting.Before("groundEffectDist"), "320")
	EverySetting.Reset("groundEffectDist")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "320")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "185", "the raid twin goes back to its own value")
	T.eq(EverySettingDB.profiles.Default.groundEffectDist, nil)
	T.eq(next(EverySettingDB.before), nil, "nothing left behind")
	T.ok(not EverySetting.IsStored("groundEffectDist"))
end)

T.test("core: Reset goes back to what a preset set since, when there's nothing older", function()
	-- Last session Every Setting set 300 over the preset's 110. Since then a new preset set 200.
	local saved = { values = { groundEffectDist = "300" }, before = { groundEffectDist = "110", RAIDgroundEffectDist = "50" } }
	local EverySetting = Start(saved, function() C_CVar.SetCVar("groundEffectDist", "200") end)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300", "set again at login")
	EverySetting.Reset("groundEffectDist")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "200", "the newer preset's value")
	-- A knob Every Setting has no older value for falls back to the game's default.
	EverySettingDB.profiles.Default.shadowSoft = "1"
	EverySetting.Reset("shadowSoft")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
end)

T.test("core: ResetAll only resets what Every Setting set", function()
	local EverySetting = Start()
	EverySetting.Set("groundEffectDist", 300)
	EverySetting.Set("shadowSoft", true)
	C_CVar.SetCVar("Sound_NumChannels", "128") -- changed in the options menu
	T.eq(EverySetting.ResetAll(), 2)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
	T.eq(C_CVar.GetCVar("Sound_NumChannels"), "128", "not Every Setting's to reset")
end)

EitherOrder("core: remembered values are set again at login, and nothing else is", function(worldFirst)
	local saved = { values = { groundEffectDist = "300", shadowSoft = "1" } }
	Start(saved, function()
		C_CVar.SetCVar("groundEffectDist", "110") -- a graphics preset overwrote it
		C_CVar.SetCVar("shadowSoft", "1") -- already what Every Setting wants
	end, worldFirst)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "300")
	T.eq(W.SetCount("shadowSoft"), 1, "not set again when it already matches")
	T.eq(W.SetCount("untouched"), 0)
	T.eq(W.SetCount("Sound_NumChannels"), 0)
	-- Another loading screen doesn't apply them again.
	C_CVar.SetCVar("groundEffectDist", "110")
	W.Fire("PLAYER_ENTERING_WORLD", false, false)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "110")
end)

T.test("core: a secure knob changed in combat applies when combat ends", function()
	local EverySetting = Start()
	W.Combat(true)
	T.eq(EverySetting.Set("nameplateMaxDistance", 80), "80")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60", "not set in combat")
	T.eq(EverySetting.Get("nameplateMaxDistance"), "80", "the window shows the value that's waiting")
	T.ok(EverySetting.IsPending("nameplateMaxDistance"))
	EverySetting.Set("groundEffectDist", 300)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300", "other knobs don't wait")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80")
	T.ok(not EverySetting.IsPending("nameplateMaxDistance"))
	-- A reset waits the same way.
	W.Combat(true)
	EverySetting.Reset("nameplateMaxDistance")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80")
	T.eq(EverySetting.Get("nameplateMaxDistance"), "60", "the window shows what it's going back to")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60")
	T.eq(EverySettingDB.profiles.Default.nameplateMaxDistance, nil)
end)

EitherOrder("core: a secure knob remembered from last time waits out a login in combat", function(worldFirst)
	Start({ values = { nameplateMaxDistance = "80" } }, function() W.combat = true end, worldFirst)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80")
end)

EitherOrder("core: a character on another profile gets it at login, raid twins included", function(worldFirst)
	-- The last character played was on Default; this one uses Pretty.
	local saved = {
		applied = "Default",
		profiles = { Default = { shadowSoft = "1" }, Pretty = { groundEffectDist = "300" } },
		before = { shadowSoft = "0" },
	}
	local EverySetting = Start(saved, function() C_CVar.SetCVar("shadowSoft", "1") end, worldFirst, { profile = "Pretty" })
	T.eq(EverySetting.GetProfile(), "Pretty")
	T.eq(EverySettingDB.applied, "Pretty")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "300", "its raid twin")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0", "what only the other character's profile keeps is put back")
end)

EitherOrder("core: a login after a crash puts back what a situation held, and holds it again", function(worldFirst)
	-- The last session ended in a city, with the situation's value still set.
	local saved = {
		values = { groundEffectDist = "300" },
		before = { groundEffectDist = "70", RAIDgroundEffectDist = "50" },
		presets = { City = { groundEffectDist = "500" } },
		situations = { resting = "City" },
		under = { groundEffectDist = "300", RAIDgroundEffectDist = "300" },
	}
	local function Crashed()
		C_CVar.SetCVar("groundEffectDist", "500")
		C_CVar.SetCVar("RAIDgroundEffectDist", "500")
	end
	Start(saved, Crashed, worldFirst)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300", "back to the profile's value")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "300")
	T.eq(EverySettingDB.before.groundEffectDist, "70", "not taken for a change the game made")
	T.eq(next(EverySettingDB.under), nil)
	-- Logging in where the situation is on holds it again.
	saved.under = { groundEffectDist = "300", RAIDgroundEffectDist = "300" }
	local EverySetting = Start(saved, function() Crashed() W.resting = true end, worldFirst)
	T.eq(C_CVar.GetCVar("groundEffectDist"), "500")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "500", "the raid twin too")
	T.eq(EverySetting.Get("groundEffectDist"), "300", "the window shows the profile's value")
	T.eq(EverySettingDB.under.groundEffectDist, "300")
end)

T.test("core: changing a knob that needs a restart is flagged until it's done", function()
	local EverySetting = Start()
	EverySetting.Set("ffxAntiAliasingMode", 0)
	T.eq(EverySetting.restart.gx, nil, "the value didn't change")
	EverySetting.Set("ffxAntiAliasingMode", 2)
	T.eq(EverySetting.restart.gx, true)
	EverySetting.RestartGraphics()
	T.eq(W.restarts.gx, 1)
	T.eq(EverySetting.restart.gx, nil)
	EverySetting.Set("Sound_NumChannels", 128)
	T.eq(EverySetting.restart.client, true)
	W.Combat(true)
	EverySetting.restart.gx = true
	EverySetting.RestartGraphics()
	T.eq(W.restarts.gx, 1, "not in combat")
end)

T.test("core: changes made elsewhere refresh the window once", function()
	local EverySetting = Start()
	local refreshes = 0
	EverySetting.RefreshOptions = function() refreshes = refreshes + 1 end
	for i = 1, 20 do C_CVar.SetCVar("untouched", tostring(i)) end -- a preset changes many CVars
	W.RunTimers()
	T.eq(refreshes, 1)
end)

T.test("core: a change made elsewhere doesn't refresh the window while the mouse button is down", function()
	local EverySetting = Start()
	local refreshes = 0
	EverySetting.RefreshOptions = function() refreshes = refreshes + 1 end
	W.leftButton = true -- a click under way, which a redraw would cancel
	C_CVar.SetCVar("untouched", "1")
	W.Advance(1)
	T.eq(refreshes, 0, "not while it's down")
	C_CVar.SetCVar("untouched", "2")
	W.Advance(1)
	T.eq(refreshes, 0)
	W.leftButton = false
	W.Advance(0.2)
	T.eq(refreshes, 1, "once it's up, once")
end)

T.test("core: /every probe reports what the engine keeps and puts the value back", function()
	local EverySetting = Start()
	C_CVar.SetCVar("groundEffectDist", "110")
	local low, high = EverySetting.Probe("groundEffectDist", "0", "99999")
	T.eq(low, "40")
	T.eq(high, "600")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "110")
	T.eq(EverySetting.Probe("nope", "0", "1"), nil)
	W.chat = {}
	W.Slash("probe groundEffectDist 0 99999")
	T.ok(W.chat[1]:find("kept |cffffffff40|r", 1, true), W.chat[1])
	T.ok(W.chat[1]:find("kept |cffffffff600|r", 1, true), W.chat[1])
	W.Slash("probe nope 0 1")
	T.ok(W.chat[2]:find("no CVar named nope", 1, true), W.chat[2])
end)

T.test("core: /every probe leaves a danger setting alone outside danger mode", function()
	local EverySetting = Start(nil, function() W.AddCVar("TurnSpeed", "180") end) -- the server's, in CVars.lua
	W.chat = {}
	W.Slash("probe TurnSpeed 1 9999")
	W.Slash("probe gxMonitor 0 1")
	T.eq(W.SetCount("TurnSpeed") + W.SetCount("gxMonitor"), 0, "not set, even to put it back")
	T.ok(W.chat[1]:find("TurnSpeed is a danger setting", 1, true), W.chat[1])
	T.ok(W.chat[2]:find("gxMonitor is a danger setting", 1, true), W.chat[2])
	EverySetting.SetDanger(true)
	W.Slash("probe TurnSpeed 1 9999")
	T.ok(W.chat[3]:find("kept |cffffffff9999|r", 1, true), W.chat[3])
	T.eq(C_CVar.GetCVar("TurnSpeed"), "180", "put back")
end)

T.test("core: /every check finds a range the engine doesn't keep", function()
	Start()
	W.Slash("check")
	local byCVar = {}
	for _, r in ipairs(EverySettingDB.check) do byCVar[r.cvar] = r end
	T.eq(byCVar.groundEffectDist.ok, false, "the knob says 800, the engine caps at 600")
	T.eq(byCVar.groundEffectDist.max, "600")
	T.eq(byCVar.RenderScale.ok, true)
	T.eq(byCVar.RenderScale.above, "2", "one step past the end is clamped")
	T.eq(byCVar.ffxAntiAliasingMode.ok, true)
	T.eq(byCVar.gxMonitor, nil, "locked knobs aren't probed")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70", "values are put back")
end)

T.test("core: what dump and check saved is dropped at the next login", function()
	Start({ values = {}, dump = { cvars = {} }, check = {} })
	T.eq(EverySettingDB.dump, nil)
	T.eq(EverySettingDB.check, nil)
end)

T.test("core: /every dump saves the client's CVars, and its console commands apart from them", function()
	Start()
	W.AddCommand("reloadui", "Reloads the UI")
	W.chat = {}
	W.Slash("dump")
	local dump = EverySettingDB.dump
	T.eq(dump.version, "1.60.1")
	T.eq(dump.client, "forever", "and which game, for scripts/gen-probes.lua")
	T.eq(#dump.cvars, #W.cvarList)
	T.eq(#dump.commands, 1, "what isn't a CVar")
	T.eq(dump.commands[1].name, "reloadui")
	T.eq(dump.commands[1].commandType, 1)
	T.eq(dump.commands[1].category, 2)
	T.eq(dump.commands[1].help, "Reloads the UI")
	T.ok(W.chat[1]:find(("saved %d CVars and 1 console commands"):format(#W.cvarList), 1, true), W.chat[1])
	T.eq(dump.cvars[1].name, "ffxAntiAliasingMode", "sorted by name")
	local byName = {}
	for _, c in ipairs(dump.cvars) do byName[c.name] = c end
	T.eq(byName.nameplateMaxDistance.secure, true)
	T.eq(byName.gxMonitor.readOnly, true)
	T.eq(byName.groundEffectDist.default, "70")
end)

T.test("core: /every reset and help", function()
	local EverySetting = Start()
	EverySetting.Set("shadowSoft", true)
	W.Slash("reset")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
	T.ok(W.chat[#W.chat]:find("1 settings put back", 1, true), W.chat[#W.chat])
	W.chat = {}
	W.Slash("help")
	T.ok(#W.chat > 3, "lists the commands")
end)

T.test("core: /every and /everysetting are one command", function()
	Start()
	T.eq(_G.SLASH_EVERYSETTING1, "/every")
	T.eq(_G.SLASH_EVERYSETTING2, "/everysetting")
	T.eq(_G.SLASH_EVERYSETTING3, nil)
end)

T.test("core: /kui opens the window too, unless another addon has the command", function()
	Start()
	T.eq(_G.SLASH_EVERYSETTINGKUI1, "/kui")
	T.eq(SlashCmdList.EVERYSETTINGKUI, SlashCmdList.EVERYSETTING, "the same commands as /every")

	-- An addon that loads later and has /kui takes it, even if the chat box remembers ours.
	_G.hash_SlashCmdList = { ["/KUI"] = SlashCmdList.EVERYSETTING }
	_G.SLASH_KEYUI1, SlashCmdList.KEYUI = "/KUI", function() end
	W.Fire("ADDON_LOADED", "KeyUI")
	T.eq(_G.SLASH_EVERYSETTINGKUI1, nil)
	T.eq(SlashCmdList.EVERYSETTINGKUI, nil)
	T.eq(_G.hash_SlashCmdList["/KUI"], nil)
	_G.hash_SlashCmdList, _G.SLASH_KEYUI1 = nil, nil

	-- One that was there at login keeps it.
	Start(nil, function() _G.SLASH_KEYUI1, SlashCmdList.KEYUI = "/kui", function() end end)
	T.eq(_G.SLASH_EVERYSETTINGKUI1, nil)
	T.eq(SlashCmdList.EVERYSETTINGKUI, nil)
	_G.SLASH_KEYUI1 = nil
end)

T.test("core: the Disable button on the game's camera warning stops keeping the test_camera CVars", function()
	local EverySetting = Start(nil, function()
		W.AddCVar("test_cameraDynamicPitch", "0.000000", { float = true })
		table.insert(_G.EverySetting.GROUPS[2].items, { cvar = "test_cameraDynamicPitch", label = "Dynamic pitch", type = "toggle" })
	end)
	EverySetting.Set("test_cameraDynamicPitch", true)
	EverySetting.Set("groundEffectDist", 300)
	T.eq(EverySetting.IsStored("test_cameraDynamicPitch"), true)
	ResetTestCvars()
	T.eq(C_CVar.GetCVar("test_cameraDynamicPitch"), "0.000000", "the game put it back")
	T.eq(EverySetting.IsStored("test_cameraDynamicPitch"), false, "no longer kept, so the next login doesn't set it again")
	T.eq(EverySettingDB.before.test_cameraDynamicPitch, nil, "nothing left to put back")
	T.eq(EverySetting.IsStored("groundEffectDist"), true, "other knobs are still kept")
end)

T.test("core: the game's camera warning can be hidden, leaving the settings on", function()
	local EverySetting = Start(nil, function()
		W.AddCVar("test_cameraDynamicPitch", "0.000000", { float = true })
		table.insert(_G.EverySetting.GROUPS[2].items, { cvar = "test_cameraDynamicPitch", label = "Dynamic pitch", type = "toggle" })
	end)
	EverySetting.Set("test_cameraDynamicPitch", true)
	T.eq(EverySetting.GetHideCameraWarning(), false, "shown by default")
	StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING")
	T.eq(W.popups.EXPERIMENTAL_CVAR_WARNING, true)
	W.Slash("warning off")
	T.eq(EverySetting.GetHideCameraWarning(), true)
	T.eq(W.popups.EXPERIMENTAL_CVAR_WARNING, nil, "the one showing goes")
	StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING")
	T.eq(W.popups.EXPERIMENTAL_CVAR_WARNING, nil, "and it doesn't come back")
	StaticPopup_Show("SOMETHING_ELSE")
	T.eq(W.popups.SOMETHING_ELSE, true, "other popups are left alone")
	T.eq(EverySetting.IsStored("test_cameraDynamicPitch"), true, "the setting is still kept")
	T.eq(EverySettingDB.hideCameraWarning, true, "for every character")
	W.Slash("warning")
	T.eq(EverySetting.GetHideCameraWarning(), false, "no argument toggles it")
	StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING")
	T.eq(W.popups.EXPERIMENTAL_CVAR_WARNING, true)
end)

T.test("core: while the camera warning is hidden, the game's event for it is let go, so it never opens", function()
	local EVENT = "EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED"
	local EverySetting = Start()
	T.eq(W.gameEvents[EVENT], W.blizzardWarning, "shown: the game's own handler is left alone")
	EverySetting.SetHideCameraWarning(true)
	T.eq(W.gameEvents[EVENT], nil, "hidden: let go")
	EverySetting.SetHideCameraWarning(false)
	W.gameEvents[EVENT]()
	T.eq(W.popups.EXPERIMENTAL_CVAR_WARNING, true, "shown again: the event brings it up")
	Start({ hideCameraWarning = true })
	T.eq(W.gameEvents[EVENT], nil, "hidden from the last session: let go at load")
end)

T.test("core: the window's size stays from 75% to 150%", function()
	local EverySetting = Start()
	T.eq(EverySetting.GetScale(), 1, "100% by default")
	EverySetting.SetScale(1.234)
	T.eq(EverySetting.GetScale(), 1.23, "to the nearest percent")
	EverySetting.SetScale(9)
	T.eq(EverySettingDB.scale, 1.5)
	EverySetting.SetScale(1)
	T.eq(EverySettingDB.scale, nil, "100% isn't saved")
	T.eq(Start({ scale = 5 }).GetScale(), 1.5, "a saved size out of range is brought in")
	T.eq(Start({ scale = "x" }).GetScale(), 1, "and one that isn't a number is 100%")
end)

-- Put back: with the option on, a setting you keep is set again a second after
-- something else changes it. A change made on its own in the game's options is
-- kept instead, and a fight with another addon ends after three rounds. Against
-- a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with the window open: view distance, ground clutter (with
-- its raid twin), soft shadows, a nameplate distance the game locks in combat,
-- and anti-aliasing, whose change waits for a graphics restart. Put back is on
-- unless `off`. `saved` is last session's saved variables. Returns the addon and
-- the window's parts.
local function Start(saved, off)
	saved = saved or {}
	saved.putBack = not off or nil
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000", { min = 185, max = 10000 })
	W.AddCVar("groundEffectDist", "70", { min = 40, max = 600 })
	W.AddCVar("RAIDgroundEffectDist", "70", { min = 40, max = 600 })
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("nameplateMaxDistance", "60", { secure = true })
	W.AddCVar("ffxAntiAliasingMode", "0")
	local selfcast -- a setting that isn't a CVar, as Knobs.lua has it
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			if knob.cvar == "@click:SELFCAST" then selfcast = knob end
		end
	end
	EverySetting.GROUPS = { { title = "Graphics", items = {
		{ cvar = "farclip", label = "View distance", type = "slider", min = 185, max = 10000, step = 5 },
		{ cvar = "groundEffectDist", label = "Ground clutter distance", type = "slider", min = 40, max = 600, step = 10,
		  raid = "RAIDgroundEffectDist" },
		{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
		{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
		{ cvar = "ffxAntiAliasingMode", label = "Anti-aliasing", type = "choice", restart = "gx",
		  options = { { 0, "None" }, { 1, "FXAA low" }, { 2, "FXAA high" } } },
		selfcast,
	} } }
	EverySetting.SECTIONS = { "Graphics" }
	EverySetting.CVARS = { farclip = "1", groundEffectDist = "1", RAIDgroundEffectDist = "1", shadowSoft = "1",
		nameplateMaxDistance = "1", ffxAntiAliasingMode = "1" }
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

-- The game's own code setting CVars: its options, or a graphics quality level
-- there, which sets many at once.
local function Game(cvars)
	W.FromAddon("Blizzard_Settings", function()
		for cvar, value in pairs(cvars) do SetCVar(cvar, value) end
	end)
end

-- How many times `cvar` was set to `value` since `from` (an index in W.sets).
local function Writes(cvar, value, from)
	local n = 0
	for i = from + 1, #W.sets do
		if W.sets[i][1] == cvar and W.sets[i][2] == value then n = n + 1 end
	end
	return n
end

T.test("put back: it's off unless it's turned on, and a preset's change then waits for Apply now", function()
	local EverySetting = Start(nil, true)
	T.eq(EverySetting.GetPutBack(), false)
	EverySetting.Set("farclip", 5000)
	Game({ farclip = "1000" })
	W.Advance(5)
	T.eq(C_CVar.GetCVar("farclip"), "1000", "not put back")
	T.eq(#EverySetting.Overwritten(), 1, "but told")
end)

T.test("put back: a preset that overwrites several kept settings is put back once, a second after the last change", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("groundEffectDist", 300)
	EverySetting.Set("shadowSoft", 1)
	local undo = EverySetting.HistorySize()
	local from = #W.sets
	Game({ farclip = "1000", groundEffectDist = "100", RAIDgroundEffectDist = "100" })
	W.Advance(0.6)
	Game({ shadowSoft = "0" }) -- more of the same preset, a moment later
	W.Advance(0.9)
	T.eq(C_CVar.GetCVar("farclip"), "1000", "not yet: the last change was less than a second ago")
	W.Advance(0.2)
	T.eq(C_CVar.GetCVar("farclip"), "5000")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "300", "the raid twin too")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	W.Advance(5)
	T.eq(Writes("farclip", "5000", from), 1, "once")
	T.eq(Writes("shadowSoft", "1", from), 1, "once")
	T.eq(EverySetting.HistorySize(), undo, "Undo doesn't take a put-back back")
	T.eq(EverySetting.Before("farclip"), "1000", "Reset goes back to what the game set, as after Apply now")
	T.eq(#EverySetting.Overwritten(), 0)
	EverySetting_OpenOptions() -- closed and opened again, which lets go of the frame rate reading
	EverySetting_OpenOptions()
	T.ok(o.refs.status:GetText():find("put back when something changes them", 1, true), o.refs.status:GetText())
end)

T.test("put back: a setting changed on its own in the game's options is kept at the new value", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("groundEffectDist", 300)
	SettingsPanel:Show()
	Game({ farclip = "3000" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "not put back")
	T.eq(EverySettingDB.profiles.Default.farclip, "3000", "kept at the new value")
	T.ok(W.chat[#W.chat]:find("you changed View distance (farclip) in the game's options, so Every Setting keeps 3000 now.", 1, true), W.chat[#W.chat])
	-- A setting with a raid twin: the twin follows.
	Game({ groundEffectDist = "200" })
	W.Advance(1.5)
	T.eq(EverySettingDB.profiles.Default.groundEffectDist, "200")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "200", "the raid twin is set to it")
	-- Two at once is a preset, open options or not.
	Game({ farclip = "1000", shadowSoft = "1" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "put back")
	-- And one alone with the options closed was something else.
	SettingsPanel:Hide()
	Game({ farclip = "1000" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "put back")
	-- So was one another addon changed while they're open.
	SettingsPanel:Show()
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "1000")
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "put back")
end)

T.test("put back: a setting whose change waits for a restart is left to Apply now", function()
	local EverySetting = Start()
	EverySetting.Set("ffxAntiAliasingMode", 2)
	EverySetting.RestartGraphics()
	Game({ ffxAntiAliasingMode = "0" })
	W.Advance(2)
	T.eq(C_CVar.GetCVar("ffxAntiAliasingMode"), "0", "not put back")
	T.eq(EverySetting.restart.gx, nil, "so no restart is owed")
	T.eq(#EverySetting.Overwritten(), 1, "told")
	EverySetting.ApplyNow()
	T.eq(C_CVar.GetCVar("ffxAntiAliasingMode"), "2", "Apply now sets it")
end)

T.test("put back: a setting that isn't a CVar is left to Apply now", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("@click:SELFCAST", "CTRL")
	SetModifiedClick("SELFCAST", "ALT") -- in the game's own options: no CVAR_UPDATE
	Game({ farclip = "1000" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "5000", "the CVar is put back")
	T.eq(GetModifiedClick("SELFCAST"), "ALT", "the modified click isn't")
	T.eq(#EverySetting.Overwritten(), 1, "but it's told")
	EverySetting.ApplyNow()
	T.eq(GetModifiedClick("SELFCAST"), "CTRL", "Apply now sets it")
end)

T.test("put back: in combat, a setting the game locks in combat waits for it to end", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("nameplateMaxDistance", 80)
	Game({ farclip = "1000", nameplateMaxDistance = "60" })
	W.Combat(true)
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "5000", "put back in combat")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60", "waits")
	T.ok(EverySetting.IsPending("nameplateMaxDistance"))
	Game({ farclip = "2000" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "5000", "a change in combat is put back in combat")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80", "put back when combat ends")
end)

T.test("put back: a setting a situation holds keeps the situation's value", function()
	local EverySetting = Start({ presets = { City = { farclip = "3000" } }, situations = { resting = "City" } })
	EverySetting.Set("farclip", 5000)
	W.Rest(true)
	W.Advance(2)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "the situation's value, not put back")
	Game({ farclip = "1000" })
	W.Advance(2)
	T.eq(C_CVar.GetCVar("farclip"), "1000", "the value underneath is yours: nothing to put back")
	T.eq(EverySetting.Get("farclip"), "5000")
	-- The situation ends and leaves the game's value, as it always has: now that's put back.
	W.Rest(false)
	T.eq(C_CVar.GetCVar("farclip"), "1000")
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "5000")
end)

T.test("put back: a fight with another addon over one setting ends after three rounds, with a line in chat", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("shadowSoft", 1)
	-- Leatrix Plus keeps its own view distance: whenever it changes, it sets 3000 again.
	local leatrix = CreateFrame("Frame")
	leatrix:RegisterEvent("CVAR_UPDATE")
	leatrix:SetScript("OnEvent", function(_, _, cvar)
		if cvar == "farclip" and C_CVar.GetCVar("farclip") ~= "3000" then
			W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
		end
	end)
	local from = #W.sets
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
	W.Advance(20)
	T.eq(Writes("farclip", "5000", from), 3, "three rounds")
	T.eq(C_CVar.GetCVar("farclip"), "3000", "Leatrix Plus has it")
	local lines = {}
	for _, line in ipairs(W.chat) do
		if line:find("keeps changing", 1, true) then lines[#lines + 1] = line end
	end
	T.eq(#lines, 1)
	T.ok(lines[1]:find("Leatrix_Plus keeps changing View distance (farclip), so Every Setting has stopped putting it back until you log in again. To keep yours, turn that setting off in Leatrix_Plus.", 1, true), lines[1])
	-- Only that setting is let go.
	Game({ shadowSoft = "0" })
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("shadowSoft"), "1", "another one is still put back")
	T.eq(C_CVar.GetCVar("farclip"), "3000")
	-- The next session tries again.
	leatrix:UnregisterEvent("CVAR_UPDATE")
	Start(EverySettingDB)
	T.eq(C_CVar.GetCVar("farclip"), "5000")
end)

T.test("put back: rounds far apart aren't a fight", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	for _ = 1, 6 do
		Game({ farclip = "1000" })
		W.Advance(15)
		T.eq(C_CVar.GetCVar("farclip"), "5000")
	end
end)

T.test("put back: /every putback and the box in the game's options turn it on and off", function()
	local EverySetting = Start(nil, true)
	EverySetting.Set("farclip", 5000)
	Game({ farclip = "1000" })
	W.Advance(2)
	W.Slash("putback on")
	T.ok(EverySetting.GetPutBack())
	T.ok(W.chat[#W.chat]:find("put back a second after something else changes it", 1, true), W.chat[#W.chat])
	W.Advance(1.5)
	T.eq(C_CVar.GetCVar("farclip"), "5000", "turning it on puts back what had changed")
	W.Slash("putback")
	T.eq(EverySetting.GetPutBack(), false, "with no word, it switches")
	T.eq(EverySettingDB.putBack, nil)
	W.Slash("putback maybe")
	T.ok(W.chat[#W.chat]:find("usage: /every putback [on|off]", 1, true), W.chat[#W.chat])
	EverySettingPanel:Show()
	T.eq(EverySettingPanel.putBack:GetChecked(), false)
	EverySettingPanel.putBack:SetChecked(true)
	W.Run(EverySettingPanel.putBack, "OnClick")
	T.ok(EverySetting.GetPutBack(), "the box")
end)

T.test("put back: another addon's change is told with what happens next", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
	T.ok(W.chat[#W.chat]:find("Leatrix_Plus changed View distance (farclip) to 3000, away from the 5000 you keep. Every Setting puts yours back.", 1, true), W.chat[#W.chat])
end)

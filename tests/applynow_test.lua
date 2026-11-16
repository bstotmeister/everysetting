-- Apply now: the kept values set again mid-session, as at login (/every apply, the
-- window's button, the minimap entry's menu), and the status line that says when
-- something else has changed settings you keep. Against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with the window open: view distance, ground clutter (with
-- its raid twin), soft shadows, and a nameplate distance the game locks in
-- combat. `saved` is last session's saved variables, and `before` runs before
-- login. Returns the addon and the window's parts.
local function Start(saved, before)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000", { min = 185, max = 10000 })
	W.AddCVar("groundEffectDist", "70", { min = 40, max = 600 })
	W.AddCVar("RAIDgroundEffectDist", "70", { min = 40, max = 600 })
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("nameplateMaxDistance", "60", { secure = true })
	W.AddCVar("untouched", "5")
	EverySetting.GROUPS = { { title = "Graphics", items = {
		{ cvar = "farclip", label = "View distance", type = "slider", min = 185, max = 20000, step = 5 },
		{ cvar = "groundEffectDist", label = "Ground clutter distance", type = "slider", min = 40, max = 600, step = 10,
		  raid = "RAIDgroundEffectDist" },
		{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
		{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
	} } }
	EverySetting.SECTIONS = { "Graphics" }
	EverySetting.CVARS = { farclip = "1", groundEffectDist = "1", RAIDgroundEffectDist = "1", shadowSoft = "1",
		nameplateMaxDistance = "1", untouched = "1" }
	if before then before() end
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

-- The game's own options picking a graphics quality level: Blizzard's code sets
-- many CVars at once. Then the window's refresh, a tenth of a second later.
local function Quality(cvars)
	W.FromAddon("Blizzard_Settings", function()
		for cvar, value in pairs(cvars) do SetCVar(cvar, value) end
	end)
	W.Advance(0.2)
end

local function Status(o) return o.refs.status:GetText() end

-- Closes the window and opens it again, which lets go of the frame rate reading
-- a change made there leaves in the status line.
local function Reopen()
	EverySetting_OpenOptions()
	EverySetting_OpenOptions()
end

T.test("apply now: a preset that overwrites several kept settings is told, and /every apply sets them again", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("groundEffectDist", 300)
	EverySetting.Set("shadowSoft", 1)
	Reopen()
	T.ok(Status(o):find("3|r settings kept", 1, true), Status(o))
	T.ok(not o.refs.applyNow:IsShown(), "no Apply now while nothing has changed")
	local undo = EverySetting.HistorySize()

	Quality({ farclip = "1000", groundEffectDist = "100", RAIDgroundEffectDist = "100", shadowSoft = "0", untouched = "9" })
	T.eq(#EverySetting.Overwritten(), 3, "three kept settings changed, and one that isn't kept")
	T.ok(Status(o):find("The game changed\n|cffffb0003|r kept settings.", 1, true), Status(o))
	T.ok(o.refs.applyNow:IsShown(), "Apply now shows")

	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.eq(C_CVar.GetCVar("RAIDgroundEffectDist"), "300", "the raid twin too")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	T.eq(C_CVar.GetCVar("untouched"), "9", "what isn't kept is left alone")
	T.ok(W.chat[#W.chat]:find("3 settings set again to the values you keep.", 1, true), W.chat[#W.chat])
	T.eq(EverySetting.Before("farclip"), "1000", "Reset goes back to what the game set, as after a login")
	T.eq(EverySetting.HistorySize(), undo, "not a change of yours: Undo doesn't take it back")
	T.eq(EverySetting.ChangedBy("farclip"), "EverySetting")
	T.eq(#EverySetting.Overwritten(), 0)
	T.ok(not o.refs.applyNow:IsShown(), "Apply now goes")
	Reopen()
	T.ok(Status(o):find("3|r settings kept", 1, true), Status(o))

	local sets = #W.sets
	W.Slash("apply")
	T.eq(#W.sets, sets, "nothing to set the second time")
	T.ok(W.chat[#W.chat]:find("every setting you keep has your value already", 1, true), W.chat[#W.chat])
end)

T.test("apply now: the status line says an addon or the game changed them, or Something", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("shadowSoft", 1)
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
	W.Advance(0.2)
	T.ok(Status(o):find("An addon changed\n|cffffb0001|r kept setting.", 1, true), Status(o))
	Quality({ shadowSoft = "0" })
	T.ok(Status(o):find("Something changed\n|cffffb0002|r kept settings.", 1, true), Status(o))
	EverySetting.ApplyNow()
	W.Console("shadowSoft", "0")
	W.Advance(0.2)
	T.ok(Status(o):find("The game changed\n|cffffb0001|r kept setting.", 1, true), "the console is the game too: " .. Status(o))
	W.FromChat('SetCVar("shadowSoft", "1")')
	W.FromChat('SetCVar("farclip", "2000")')
	W.Advance(0.2)
	T.ok(Status(o):find("Something changed\n|cffffb0001|r kept setting.", 1, true), "a /run line: " .. Status(o))
end)

T.test("apply now: the window's button and the minimap entry's menu set them again", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	Quality({ farclip = "1000" })
	W.Run(o.refs.applyNow, "OnClick")
	T.eq(C_CVar.GetCVar("farclip"), "5000", "the button")
	T.ok(not o.refs.applyNow:IsShown())
	Quality({ farclip = "1000" })
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	T.ok(W.Find("Apply now").tooltip, "the entry has a tooltip")
	W.Pick("Apply now")
	T.eq(C_CVar.GetCVar("farclip"), "5000", "the menu's entry")
	T.ok(W.chat[#W.chat]:find("1 setting set again", 1, true), W.chat[#W.chat])
end)

T.test("apply now: Keep these takes Apply now's place while Not default is ticked", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	Quality({ farclip = "1000" })
	T.ok(o.refs.applyNow:IsShown())
	o.refs.notDefault:SetChecked(true)
	W.Run(o.refs.notDefault, "OnClick")
	T.ok(o.refs.keep:IsShown() and not o.refs.applyNow:IsShown(), "Keep these, not Apply now")
	o.refs.notDefault:SetChecked(false)
	W.Run(o.refs.notDefault, "OnClick")
	T.ok(o.refs.applyNow:IsShown() and not o.refs.keep:IsShown(), "Apply now again")
end)

T.test("apply now: a setting a situation holds isn't taken for one the game changed", function()
	local EverySetting, o = Start({ presets = { City = { farclip = "3000" } }, situations = { resting = "City" } })
	EverySetting.Set("farclip", 5000)
	W.Rest(true)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "the situation holds it")
	T.eq(#EverySetting.Overwritten(), 0, "the situation's value isn't the game's")
	T.ok(not o.refs.applyNow:IsShown())
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "3000", "Apply now leaves the situation be")
	T.ok(W.chat[#W.chat]:find("has your value already", 1, true), W.chat[#W.chat])

	-- The game overwrites it while it's held: the value underneath is still yours.
	Quality({ farclip = "1000" })
	T.eq(#EverySetting.Overwritten(), 0, "held, so not yet")
	-- When the situation ends, the game's change stays, as it always has. Now it's yours that changed.
	W.Rest(false)
	W.Advance(0.2)
	T.eq(C_CVar.GetCVar("farclip"), "1000")
	T.eq(#EverySetting.Overwritten(), 1)
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
end)

T.test("apply now: in combat, a setting the game locks in combat waits for it to end", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("nameplateMaxDistance", 80)
	Quality({ farclip = "1000", nameplateMaxDistance = "60" })
	W.Combat(true)
	T.eq(#EverySetting.Overwritten(), 2)
	T.ok(o.refs.applyNow:IsShown(), "Apply now is there in combat too")
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "5000", "set in combat")
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "60", "waits")
	T.ok(EverySetting.IsPending("nameplateMaxDistance"))
	T.ok(W.chat[#W.chat]:find("2 settings set again to the values you keep. Settings the game locks in combat wait until it ends.", 1, true), W.chat[#W.chat])
	T.eq(#EverySetting.Overwritten(), 0, "the one waiting isn't told again")
	-- A change in combat is told, and set again in combat.
	Quality({ farclip = "2000" })
	T.eq(#EverySetting.Overwritten(), 1)
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80", "set when combat ends")
	T.ok(not EverySetting.IsPending("nameplateMaxDistance"))
	T.eq(#EverySetting.Overwritten(), 0)
end)

T.test("apply now: a value the engine turns down isn't taken for a change", function()
	-- Kept from a client whose engine took more. This one keeps 10000 at most.
	local saved = { values = { farclip = "15000", shadowSoft = "1" } }
	local EverySetting, o = Start(saved, function() C_CVar.SetCVar("shadowSoft", "1") end)
	T.eq(C_CVar.GetCVar("farclip"), "10000", "the engine's most")
	T.eq(#EverySetting.Overwritten(), 0, "Every Setting set what's there")
	T.ok(not o.refs.applyNow:IsShown())
	-- The next login finds it at 10000, sets it again and nothing changes: no change is seen at all.
	EverySetting = Start(EverySettingDB, function() C_CVar.SetCVar("farclip", "10000") end)
	T.eq(#EverySetting.Overwritten(), 0, "nor when the write changed nothing")
end)

T.test("apply now: another addon that sets its own value back from inside the write is still told", function()
	local EverySetting, o = Start()
	EverySetting.Set("farclip", 5000)
	-- Leatrix Plus keeps its own view distance: whenever it changes, it sets 3000 again.
	local leatrix = CreateFrame("Frame")
	leatrix:RegisterEvent("CVAR_UPDATE")
	leatrix:SetScript("OnEvent", function(_, _, cvar)
		if cvar == "farclip" and C_CVar.GetCVar("farclip") ~= "3000" then W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000") end
	end)
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
	W.Advance(0.2)
	W.Slash("apply")
	W.Advance(0.2)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "Leatrix Plus set it back")
	T.eq(#EverySetting.Overwritten(), 1, "not taken for the engine turning it down")
	T.ok(Status(o):find("An addon changed", 1, true), Status(o))
end)

T.test("apply now: a value taken for the engine's is told again once something else changes it", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	-- Code that's no addon's (a /run line's frame) sets 2000 back from inside Every
	-- Setting's write. The first addon on the stack is Every Setting, so it reads as its own,
	-- and the 2000 is taken for what the engine kept.
	local fighter = CreateFrame("Frame")
	fighter:RegisterEvent("CVAR_UPDATE")
	fighter:SetScript("OnEvent", function(_, _, cvar)
		if cvar == "farclip" and C_CVar.GetCVar("farclip") ~= "2000" then SetCVar("farclip", "2000") end
	end)
	W.FromChat('SetCVar("farclip", "1000")')
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "2000")
	T.eq(#EverySetting.Overwritten(), 0, "taken for the engine's")
	fighter:UnregisterEvent("CVAR_UPDATE")
	-- Another addon changes it, then sets that same 2000: that's no longer the engine's.
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "3000")
	W.FromAddon("Leatrix_Plus", SetCVar, "farclip", "2000")
	T.eq(#EverySetting.Overwritten(), 1)
	W.Slash("apply")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
end)

T.test("apply now: before the login's work is done, there's nothing to apply", function()
	local EverySetting = W.Load({ values = { shadowSoft = "1" } })
	W.AddCVar("shadowSoft", "0")
	EverySetting.GROUPS = { { title = "Graphics", items = { { cvar = "shadowSoft", label = "Soft shadows", type = "toggle" } } } }
	W.Fire("ADDON_LOADED", "EverySetting")
	W.Fire("VARIABLES_LOADED")
	T.eq(EverySetting.ApplyNow(), 0)
	T.eq(C_CVar.GetCVar("shadowSoft"), "0", "the login sets it")
	T.eq(#EverySetting.Overwritten(), 0)
end)

T.test("apply now: a lock's tooltip says what a lock doesn't do", function()
	local _, o = Start()
	local row
	for _, r in ipairs(o.rows) do
		if r:IsShown() and r.item and r.item.knob and r.item.knob.cvar == "farclip" then row = r end
	end
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.lock, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	T.ok(lines[1]:find("A lock doesn't stop the game or another addon changing it.", 1, true), lines[1])
end)

-- Loot sparkles: one checkbox for the pair of settings the sparkle needs (a knob's
-- `with`), against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

local SPARKLE = "outlineModeShowLootEffectWhenDisabled"

-- A logged-in client with outlines at High, as the game's top quality level has them.
local function Start(saved)
	local EverySetting = W.Load(saved)
	W.AddCVar(SPARKLE, "0")
	W.AddCVar("graphicsOutlineMode", "1")
	W.AddCVar("raidGraphicsOutlineMode", "1")
	W.Console("graphicsOutlineMode", "2")
	W.Console("raidGraphicsOutlineMode", "2")
	W.Login()
	return EverySetting
end

local function Values()
	return C_CVar.GetCVar(SPARKLE) .. " " .. C_CVar.GetCVar("graphicsOutlineMode") .. " " .. C_CVar.GetCVar("raidGraphicsOutlineMode")
end

T.test("sparkle: turning it on turns outlines off, raids too, and keeps all three as one change", function()
	local EverySetting = Start()
	T.eq(EverySetting.Knob(SPARKLE).label, "Loot sparkles")
	T.eq(EverySetting.Set(SPARKLE, true), "1")
	T.eq(Values(), "1 0 0")
	local kept = EverySetting.GetKept()
	T.eq(kept[SPARKLE], "1")
	T.eq(kept.graphicsOutlineMode, "0")
	T.eq(kept.raidGraphicsOutlineMode, "0")
	T.eq(EverySetting.HistorySize(), 1, "one change")
	T.ok(EverySetting.Undo())
	T.eq(Values(), "0 2 2", "Undo takes back all three")
	T.eq(next(EverySetting.GetKept()), nil, "and keeps none of them")
	T.ok(EverySetting.Redo())
	T.eq(Values(), "1 0 0")
end)

T.test("sparkle: turning it off puts outlines back as they were, and waits for the next login", function()
	local EverySetting = Start()
	EverySetting.Set(SPARKLE, true)
	T.eq(EverySetting.restart.login, nil, "turning it on shows at once")
	T.eq(EverySetting.Set(SPARKLE, false), "0")
	T.eq(Values(), "0 2 2")
	local kept = EverySetting.GetKept()
	T.eq(kept[SPARKLE], "0", "the sparkle is kept off")
	T.eq(kept.graphicsOutlineMode, nil, "outlines aren't kept")
	T.eq(EverySetting.restart.login, true, "turning it off waits for the next login")
	T.eq(EverySetting.HistorySize(), 2)
	EverySetting.Undo()
	T.eq(Values(), "1 0 0", "one Undo turns it all on again")
end)

T.test("sparkle: Reset puts all three back, and to the defaults with them", function()
	local EverySetting = Start()
	EverySetting.Set(SPARKLE, true)
	EverySetting.Reset(SPARKLE)
	T.eq(Values(), "0 2 2")
	T.eq(next(EverySetting.GetKept()), nil)
	EverySetting.Undo()
	T.eq(Values(), "1 0 0", "one Undo for the Reset")
	EverySetting.Reset(SPARKLE, true)
	T.eq(Values(), "0 1 1", "the game's defaults")
end)

T.test("sparkle: at login outlines are turned off again, after the game's quality setting turned them on", function()
	local EverySetting = Start()
	EverySetting.Set(SPARKLE, true)
	local saved = EverySettingDB
	EverySetting = W.Load(saved)
	W.AddCVar(SPARKLE, "1")
	W.AddCVar("graphicsOutlineMode", "1") -- a lower quality level
	W.AddCVar("raidGraphicsOutlineMode", "0")
	W.Login()
	T.eq(Values(), "1 0 0")
	EverySetting.Reset(SPARKLE)
	T.eq(Values(), "0 1 2", "Reset puts back what the game had set, and what was there first")
end)

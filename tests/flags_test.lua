-- Flags: CVars that pack a set of on/off flags into one value, each flag set
-- through the game and the packed value kept like any other.

local T = ...
local W = dofile("tests/wow.lua")

local AURAS, STACKING, SIMPLE = "nameplateEnemyNpcAuraDisplay", "nameplateStackingTypes", "nameplateSimplifiedTypes"

-- A logged-in client with some packed CVars as the 1.60.1 client has them
-- ("\002G" is flags 1, 2 and 3), and two made up: one never set, one locked.
local function Start(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar(AURAS, "\002G", { help = "How auras are displayed on enemy Npc nameplates." })
	W.AddCVar(STACKING, "\002")
	W.AddCVar(SIMPLE, "\002", { secure = true })
	W.AddCVar("seenTips", "")
	W.AddCVar("lockedFlags", "\002A", { locked = true })
	W.AddCVar("shadowSoft", "0")
	EverySetting.GROUPS = {
		{ title = "Shadows", items = { { cvar = "shadowSoft", label = "Soft shadows", type = "toggle" } } },
	}
	EverySetting.SECTIONS = { "Graphics", "Nameplates" }
	EverySetting.CVARS = {
		shadowSoft = "1",
		[AURAS] = "2|f|1=Buffs|2=Debuffs|3=Crowd control",
		[STACKING] = "2|f|1=Enemy units|2=Friendly units",
		[SIMPLE] = "2|f|1=Minions|2=Minor enemies|3=Friendly players|4=Friendly NPCs",
		seenTips = "2|f|2=Second|9=Ninth",
		lockedFlags = "2|f|1=One|2=Two",
	}
	W.Login()
	for cvar in pairs(EverySetting.CVARS) do EverySetting.RawKnob(cvar, "") end
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

-- The row showing `cvar`, if it's scrolled into view.
local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

-- The menu's button for `value`, if the menu is open.
local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

T.test("flags: a packed CVar gets a knob with its flags, each by its index", function()
	local EverySetting = Start()
	local knob = EverySetting.Knob(AURAS)
	T.eq(knob.type, "flags")
	T.ok(knob.raw, "its box takes any value")
	T.eq(#knob.options, 3)
	T.eq(knob.options[3][1], 3, "the index, a number")
	T.eq(knob.options[3][2], "Crowd control")
	T.eq(EverySetting.Normalize(knob, "\002C"), "\002C", "a packed value is taken as it is")
	T.ok(EverySetting.Flag("\002G", 1) and EverySetting.Flag("\002G", 3), "G: bits 0 to 2")
	T.ok(not EverySetting.Flag("\002G", 4))
	T.ok(not EverySetting.Flag("\002E", 2), "E: bits 0 and 2")
	T.ok(EverySetting.Flag("\002@D", 9), "six flags to a byte")
	T.ok(not EverySetting.Flag("\002@D", 3))
	T.ok(not EverySetting.Flag("\002", 1) and not EverySetting.Flag("", 1) and not EverySetting.Flag(nil, 1), "nothing on")
	for index = 1, 3 do
		T.eq(EverySetting.Flag(Get(AURAS), index), C_CVar.GetCVarBitfield(AURAS, index), "read as the game reads it")
	end
end)

T.test("flags: a flag is set through the game, and the packed value is kept", function()
	local EverySetting = Start()
	T.eq(EverySetting.SetFlag(AURAS, 2, false), "\002E", "what the engine has now")
	T.eq(Get(AURAS), "\002E")
	T.eq(C_CVar.GetCVarBitfield(AURAS, 2), false)
	T.eq(C_CVar.GetCVarBitfield(AURAS, 3), true, "the others as they were")
	T.eq(#W.flagSets, 1, "by the game's function for one flag")
	T.eq(W.SetCount(AURAS), 0, "not as a value")
	T.ok(EverySetting.IsStored(AURAS))
	T.eq(EverySettingDB.profiles.Default[AURAS], "\002E", "the profile keeps the packed value")
	T.eq(EverySetting.Before(AURAS), "\002G", "and Reset has the one from before")
	EverySetting.SetFlag(AURAS, 1, false)
	T.eq(EverySetting.SetFlag(AURAS, 3, false), "\002", "nothing on")
	T.eq(EverySetting.SetFlag(AURAS, 3, false), "\002", "off already")
	-- One that was never set, and a flag past the first six.
	T.eq(EverySetting.SetFlag("seenTips", 9, true), "\002@D")
	T.eq(EverySetting.SetFlag("seenTips", 2, true), "\002BD")
	T.eq(EverySetting.SetFlag("seenTips", 9, false), "\002B")
	-- Only a flags knob has flags, and a danger setting is left alone.
	T.eq(EverySetting.SetFlag("shadowSoft", 1, true), nil)
	T.eq(EverySetting.SetFlag("noSuchCVar", 1, true), nil)
	T.eq(EverySetting.SetFlag("lockedFlags", 2, true), nil, "locked by the game")
	T.eq(#W.flagSets, 7, "not even tried")
	EverySetting.SetDanger(true)
	T.eq(EverySetting.SetFlag("lockedFlags", 2, true), nil, "in danger mode it's tried, and the game turns it down")
	T.eq(#W.flagSets, 8)
	T.ok(not EverySetting.IsStored("lockedFlags"), "so nothing is kept")
	T.ok(W.chat[#W.chat]:find("the game didn't take", 1, true))
end)

T.test("flags: Undo, Redo and Reset put the packed value back", function()
	local EverySetting = Start()
	EverySetting.SetFlag(AURAS, 2, false)
	EverySetting.SetFlag(AURAS, 3, false)
	T.eq(Get(AURAS), "\002A")
	T.ok(EverySetting.Undo())
	T.eq(Get(AURAS), "\002E", "one flag at a time")
	T.ok(EverySetting.Undo())
	T.eq(Get(AURAS), "\002G")
	T.eq(C_CVar.GetCVarBitfield(AURAS, 2), true, "the game has the flag again")
	T.ok(not EverySetting.IsStored(AURAS), "and nothing is kept, as before")
	T.ok(EverySetting.Redo())
	T.eq(Get(AURAS), "\002E")
	T.eq(EverySetting.GetKept()[AURAS], "\002E")
	EverySetting.Reset(AURAS)
	T.eq(Get(AURAS), "\002G", "Reset: the value from before")
	T.ok(not EverySetting.IsStored(AURAS))
	C_CVar.SetCVar(AURAS, "\002C") -- changed in the game's own options
	EverySetting.SetFlag(AURAS, 1, false)
	T.eq(Get(AURAS), "\002B")
	EverySetting.Reset(AURAS, true)
	T.eq(Get(AURAS), "\002G", "right-click Reset: the game's default")
end)

T.test("flags: kept flags are set again at login, shared, and used by a preset", function()
	local saved = { profiles = { Default = { [AURAS] = "\002E" } } }
	local EverySetting = Start(saved)
	T.eq(Get(AURAS), "\002E", "set again, as a value")
	T.eq(C_CVar.GetCVarBitfield(AURAS, 2), false)
	T.eq(EverySetting.Before(AURAS), "\002G", "what the game had")
	local text = EverySetting.ExportProfile()
	T.eq(text, "EverySetting:1:" .. AURAS .. "=%02E")
	T.eq(EverySetting.ImportProfile("Shared", text), nil)
	T.eq(EverySetting.GetKept()[AURAS], "\002E", "the same flags in the imported profile")
	EverySetting.ApplyPreset({ [STACKING] = "\002C" })
	T.eq(C_CVar.GetCVarBitfield(STACKING, 1) and C_CVar.GetCVarBitfield(STACKING, 2), true)
	T.eq(EverySetting.GetKept()[STACKING], "\002C")
	EverySetting.SetProfile("Default")
	T.eq(Get(STACKING), "\002", "a profile without it puts it back")
end)

T.test("flags: a secure one changed in combat waits for combat to end", function()
	local EverySetting = Start()
	W.Combat(true)
	T.eq(EverySetting.SetFlag(SIMPLE, 2, true), "\002B", "the value it will have")
	T.eq(Get(SIMPLE), "\002", "not set yet")
	T.ok(EverySetting.IsPending(SIMPLE))
	T.ok(EverySetting.Flag(EverySetting.Get(SIMPLE), 2), "the window shows it ticked")
	T.eq(EverySetting.SetFlag(SIMPLE, 4, true), "\002J", "a second one on top")
	T.eq(EverySetting.SetFlag(SIMPLE, 2, false), "\002H")
	T.eq(EverySetting.SetFlag(SIMPLE, 15, true), "\002H@D", "packed the way the game packs it")
	T.eq(EverySetting.SetFlag(SIMPLE, 15, false), "\002H", "with nothing left on the end")
	T.eq(#W.flagSets, 0, "the game isn't asked in combat")
	-- One that isn't secure is set there and then.
	T.eq(EverySetting.SetFlag(STACKING, 1, true), "\002A")
	T.eq(Get(STACKING), "\002A")
	W.Combat(false)
	T.eq(Get(SIMPLE), "\002H")
	T.eq(C_CVar.GetCVarBitfield(SIMPLE, 4), true)
	T.eq(C_CVar.GetCVarBitfield(SIMPLE, 2), false)
	T.ok(not EverySetting.IsPending(SIMPLE))
	T.eq(EverySetting.GetKept()[SIMPLE], "\002H")
end)

T.test("flags: while a situation holds one, a flag changes the value underneath", function()
	local EverySetting = Start()
	EverySetting.SavePreset("Ride", { [STACKING] = "\002A" })
	EverySetting.SetSituation("mounted", "Ride")
	W.Mount(true)
	T.eq(Get(STACKING), "\002A", "the situation's flags")
	T.eq(EverySetting.SetFlag(STACKING, 2, true), "\002B", "yours: just the one you ticked")
	T.eq(Get(STACKING), "\002A", "the situation still has it")
	T.eq(#W.flagSets, 0)
	W.Mount(false)
	T.eq(Get(STACKING), "\002B", "and yours comes back when it ends")
	T.eq(EverySetting.GetKept()[STACKING], "\002B")
end)

T.test("flags: the row has a menu of ticks that stays open, and no box", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	o.refs.search:SetText(AURAS)
	local row = RowFor(o, AURAS)
	T.ok(row.dropdown:IsShown() and not row.box:IsShown() and not row.check:IsShown() and not row.slider:IsShown(),
		"no box: the packed value isn't text to read or type")
	T.eq(row.dropdown:GetWidth(), 274)
	T.eq(row.dropdown.label:GetText(), "Buffs, Debuffs, Crowd control", "the flags that are on")
	W.Run(row.dropdown, "OnClick")
	T.ok(MenuItem(1).active and MenuItem(2).active and MenuItem(3).active, "each one ticked")
	T.eq(MenuItem(2).label:GetText(), "Debuffs")
	W.Run(MenuItem(2), "OnClick")
	T.eq(Get(AURAS), "\002E")
	T.ok(MenuItem(2), "the menu stays open")
	T.ok(not MenuItem(2).active and MenuItem(1).active, "with the tick gone")
	T.eq(row.dropdown.label:GetText(), "Buffs, Crowd control")
	T.ok(row.kept:IsShown() and row.reset:IsShown(), "kept from now on")
	W.Run(MenuItem(2), "OnClick")
	T.ok(MenuItem(2).active, "and back on")
	-- A change from elsewhere shows in the open menu: Reset puts the tick back.
	W.Run(MenuItem(2), "OnClick")
	T.ok(not MenuItem(2).active)
	W.Run(row.reset, "OnClick")
	T.ok(MenuItem(2) and MenuItem(2).active, "the open menu follows a Reset")
	-- Typing in the search box shows other rows, so the menu closes: it was this row's.
	o.refs.search:SetText("nameplate")
	T.ok(not MenuItem(1), "a search closes it")
	o.refs.search:SetText(AURAS)
	row = RowFor(o, AURAS)
	W.Run(row.dropdown, "OnClick")
	for index = 1, 3 do W.Run(MenuItem(index), "OnClick") end
	T.eq(Get(AURAS), "\002")
	T.eq(row.dropdown.label:GetText(), "None")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	W.Run(row.reset, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	T.ok(lines[1]:find("Now: |cffffffffNone|r    Game default: |cffffffffBuffs, Debuffs, Crowd control|r", 1, true),
		"the tooltip lists the flags that are on")
	T.ok(lines[2]:find("back to |cffffffffBuffs, Debuffs, Crowd control|r", 1, true), "Reset's too")
	T.ok(not lines[1]:find("The box takes any value", 1, true), "and says nothing of a box the row doesn't have")
	W.Run(row.dropdown, "OnClick")
	T.ok(not MenuItem(1), "the dropdown closes its menu")
	-- A packed value set whole shows as its flags, and Undo goes back a flag at a time.
	EverySetting.Set(AURAS, "\002C", true)
	T.eq(row.dropdown.label:GetText(), "Buffs, Debuffs")
	W.Run(o.refs.undo, "OnClick")
	W.Run(o.refs.undo, "OnClick")
	T.eq(row.dropdown.label:GetText(), "Crowd control")
	W.Run(row.reset, "OnClick")
	T.eq(Get(AURAS), "\002G")
	T.eq(row.dropdown.label:GetText(), "Buffs, Debuffs, Crowd control")
	-- Another menu marks one option again, and closes when it's picked.
	o.refs.search:SetText("")
	W.Run(o.refs.kind, "OnClick")
	T.ok(MenuItem("any").active and not MenuItem("flags").active)
	W.Run(MenuItem("flags"), "OnClick")
	T.ok(not MenuItem("flags"), "closed")
	T.eq(o.refs.kind.label:GetText(), "Flag menus")
	local shown = {}
	for _, item in ipairs(o.view) do
		if item.knob then shown[#shown + 1] = item.knob.cvar end
	end
	T.eq(table.concat(shown, " "), "lockedFlags " .. AURAS .. " " .. SIMPLE .. " " .. STACKING .. " seenTips", "the type menu finds them")
	T.ok(RowFor(o, "lockedFlags").dropdown.off, "a locked one's menu doesn't open")
end)

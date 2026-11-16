-- A value past a tuned slider's range: the box takes one where the range is the
-- game's own quality levels (src = "preset") and the engine keeps any number.
-- The slider, styles, presets and imported text stay inside it.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a slider of each kind: horizonStart, whose range is
-- from the presets and which the engine keeps at any number, and
-- groundEffectDist, whose range the engine enforces. `before` runs before login.
local function Start(saved, before)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("horizonStart", "1000")
	W.AddCVar("RAIDhorizonStart", "1000")
	W.AddCVar("groundEffectDist", "70", { validate = W.Range(40, 500, "Value must be between 40 and 500.") })
	EverySetting.GROUPS = { { title = "Draw distance", items = {
		{ cvar = "horizonStart", label = "Horizon start", tip = "How far away the far horizon begins.", type = "slider",
		  min = 400, max = 4000, step = 100, src = "preset", raid = "RAIDhorizonStart", tiers = { 400, 1000, 1900, 4000 } },
		{ cvar = "groundEffectDist", label = "Ground clutter distance", tip = "How far away grass is drawn.", type = "slider",
		  min = 40, max = 500, step = 10, src = "probe" },
	} } }
	EverySetting.SECTIONS = { "Graphics" }
	EverySetting.CVARS = { horizonStart = "1", RAIDhorizonStart = "1", groundEffectDist = "1" }
	EverySetting.STYLES = {}
	if before then before() end
	W.Login()
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

-- Types `text` in a row's box and presses Enter.
local function Type(row, text)
	row.box:SetFocus()
	row.box:SetText(text)
	W.Run(row.box, "OnEnterPressed")
end

-- The body of a row's tooltip.
local function Tip(row)
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	return table.concat(lines, "\n")
end

T.test("past: the box sets a preset knob past its range as typed, above it and below", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set("horizonStart", "6000", true), "6000", "above")
	T.eq(Get("horizonStart"), "6000")
	T.eq(Get("RAIDhorizonStart"), "6000", "its raid twin too")
	T.eq(EverySettingDB.profiles.Default.horizonStart, "6000", "kept")
	T.eq(EverySetting.Set("horizonStart", "250", true), "250", "below")
	T.eq(EverySetting.Set("horizonStart", "6050.5", true), "6050.5", "off the slider's steps")
	T.eq(EverySetting.Set("horizonStart", "1234", true), "1200", "inside the range it snaps to a step, as before")
	T.eq(EverySetting.Set("horizonStart", "abc", true), nil, "not a number")
	T.eq(EverySetting.Set("horizonStart", math.huge, true), "4000", "nor is infinity one to set")
	local knob = EverySetting.Knob("horizonStart")
	T.eq(EverySetting.Past(knob, "6000"), 1)
	T.eq(EverySetting.Past(knob, "250"), -1)
	T.eq(EverySetting.Past(knob, "4000.000000"), nil, "its ends are inside")
	T.eq(EverySetting.Past(knob, "400"), nil)
end)

T.test("past: the slider keeps to the range, and so does a probe knob's box", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set("horizonStart", 6000), "4000", "the slider, above")
	T.eq(EverySetting.Set("horizonStart", 250), "400", "and below")
	T.eq(EverySetting.Set("groundEffectDist", "9999", true), "500", "a probe knob's box, above")
	T.eq(EverySetting.Set("groundEffectDist", "5", true), "40", "and below")
	T.eq(#W.log, 0, "the engine was never given a value to turn down")
	local knob = EverySetting.Knob("groundEffectDist")
	T.ok(not EverySetting.GoesPast(knob))
	T.eq(EverySetting.Past(knob, "9999"), nil, "nothing to mark: its range is the engine's")
end)

T.test("past: a value past the range is kept over a login, reset and undone", function()
	local saved = { profiles = { Default = { horizonStart = "6000" } }, applied = "Default", before = { horizonStart = "1900" } }
	local EverySetting = Start(saved, function() C_CVar.SetCVar("horizonStart", "4000") end) -- the Graphics menu wrote over it
	T.eq(Get("horizonStart"), "6000", "set again at login")
	T.eq(Get("RAIDhorizonStart"), "6000")
	EverySetting.Reset("horizonStart")
	T.eq(Get("horizonStart"), "4000", "Reset: the value the game had at login")
	T.ok(not EverySetting.IsStored("horizonStart"))
	T.ok(EverySetting.Undo())
	T.eq(Get("horizonStart"), "6000", "Undo takes the reset back")
	T.eq(EverySettingDB.profiles.Default.horizonStart, "6000", "and it's kept again")
	T.ok(EverySetting.Redo())
	T.eq(Get("horizonStart"), "4000")
end)

T.test("past: a preset never sets a value outside the range, though it holds one", function()
	local EverySetting = Start()
	EverySetting.Set("horizonStart", "6000", true)
	T.eq(EverySetting.SavePreset("Far", { horizonStart = EverySetting.GetKept().horizonStart }), nil)
	T.eq(EverySetting.GetPresets().Far.horizonStart, "6000", "saved as it was typed")
	EverySetting.Reset("horizonStart")
	EverySetting.ApplyPreset(EverySetting.GetPresets().Far)
	T.eq(Get("horizonStart"), "4000", "applied inside the range")
	T.eq(Get("RAIDhorizonStart"), "4000")
	EverySetting.ApplyPreset({ horizonStart = "250" })
	T.eq(Get("horizonStart"), "400", "below it too")
	EverySetting.ApplyPreset({ horizonStart = "1900" })
	T.eq(Get("horizonStart"), "1900", "a value inside it is set as it is")
end)

T.test("past: an imported line is held to the range, as a profile and as a preset", function()
	local EverySetting = Start()
	EverySetting.Set("horizonStart", "6000", true)
	local text = EverySetting.ExportProfile()
	T.eq(text, "EverySetting:1:horizonStart=6000", "exported as it's kept")
	-- On purpose: only a value typed in the box goes past the range.
	T.eq(EverySetting.ImportProfile("Theirs", text), nil)
	T.eq(EverySettingDB.profiles.Theirs.horizonStart, "4000")
	T.eq(Get("horizonStart"), "4000")
	T.eq(EverySetting.ImportPreset("Low horizon", "EverySetting:1:horizonStart=250"), nil)
	T.eq(EverySetting.GetPresets()["Low horizon"].horizonStart, "400")
	T.eq(Get("horizonStart"), "400")
end)

T.test("past: the row and its tooltip say a value is past the range", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	local row = RowFor(o, "horizonStart")
	T.eq(row.past:GetText(), "", "nothing to say inside the range")
	local tip = Tip(row)
	T.ok(tip:find("Usual range: |cffffffff400|r to |cffffffff4000|r", 1, true), "the range is the usual one: " .. tip)
	T.ok(tip:find("The box takes a number past it", 1, true), "and the tooltip says the box goes past it")
	T.ok(not tip:find("This is", 1, true))

	Type(row, "6000")
	T.eq(Get("horizonStart"), "6000")
	T.eq(row.box:GetText(), "6000", "the box shows what the game kept")
	T.eq(row.slider.fraction, 1, "the slider stops at its end")
	T.ok(row.past:GetText():find("past the game's top level", 1, true), "the row says so")
	T.ok(Tip(row):find("This is past the game's top level.", 1, true), "and the tooltip")
	T.ok(row.kept:IsShown() and row.reset:IsShown())

	Type(row, "250")
	T.eq(Get("horizonStart"), "250")
	T.eq(row.slider.fraction, 0)
	T.ok(row.past:GetText():find("below the game's lowest level", 1, true))
	T.ok(Tip(row):find("This is below the game's lowest level.", 1, true))

	-- Dragging the slider brings it back inside.
	W.cursor = { 9999, 0 }
	W.Run(row.slider, "OnMouseDown")
	W.Run(row.slider, "OnMouseUp")
	T.eq(Get("horizonStart"), "4000")
	T.eq(row.past:GetText(), "")

	Type(row, "6000")
	W.Run(row.reset, "OnClick")
	T.eq(Get("horizonStart"), "1000", "Reset puts back the value from before")
	T.eq(row.past:GetText(), "")
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("horizonStart"), "6000", "and Undo the one typed")
	T.ok(row.past:GetText():find("past the game's top level", 1, true))

	-- A value the game was given some other way is marked too.
	C_CVar.SetCVar("horizonStart", "9000")
	W.RunTimers()
	T.ok(row.past:GetText():find("past the game's top level", 1, true))
end)

T.test("past: a probe knob's row clamps what's typed, and its tooltip gives the range as the range", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	local row = RowFor(o, "groundEffectDist")
	Type(row, "9999")
	T.eq(Get("groundEffectDist"), "500")
	T.eq(row.box:GetText(), "500")
	T.eq(row.past:GetText(), "")
	local tip = Tip(row)
	T.ok(tip:find("\nRange: |cffffffff40|r to |cffffffff500|r", 1, true), tip)
	T.ok(not tip:find("past it", 1, true))
end)

T.test("past: in Knobs.lua, the knobs whose box goes past the range are the ten from the presets", function()
	local EverySetting = W.Load()
	local names = {}
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			if knob.src == "preset" then T.eq(knob.type, "slider", knob.cvar .. " is from the presets, so it's a slider") end
			if EverySetting.GoesPast(knob) then names[#names + 1] = knob.cvar end
		end
	end
	T.eq(table.concat(names, " "), "farclip horizonStart horizonClip terrainLodDist wmoLodDist doodadLodScale entityLodDist"
		.. " giQuality shadowNumCascades entityShadowFadeScale")
end)

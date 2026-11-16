-- Lines from a guide: Import reads /console, /run SetCVar, SET and name value
-- lines for a name and a value, and never runs them. Export writes /console lines.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a few tuned settings, some other CVars, two danger
-- settings and three console commands. `saved` is last session's saved variables.
--   horizonStart         its range is the game's quality levels (src = "preset"), so its box goes past it
--   groundEffectDensity  a step of 8 from 16
--   maxFPSBk             the engine turns down a number over 200
local function Start(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	W.AddCVar("horizonStart", "1000")
	W.AddCVar("RAIDhorizonStart", "1000")
	W.AddCVar("groundEffectDensity", "16")
	W.AddCVar("groundEffectDist", "70")
	W.AddCVar("weatherDensity", "2")
	W.AddCVar("ffxGlow", "1")
	W.AddCVar("cameraDistanceMaxZoomFactor", "1.000000", { float = true })
	W.AddCVar("scriptErrors", "0")
	W.AddCVar("autoSelfCast", "1")
	W.AddCVar("maxFPSBk", "30", { validate = W.Range(8, 200) })
	W.AddCVar("SpellQueueWindow", "400")
	W.AddCVar("someRawCVar", "")
	W.AddCVar("packedFlags", "")
	W.AddCVar("TurnSpeed", "180", { min = 1, max = 540, secure = true })
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	W.AddCommand("ActionCam")
	W.AddCommand("cvar_default")
	W.AddCommand("GxRestart")
	W.AddCommand("reloadUI", "Reloads the user interface")
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100, src = "preset", raid = "RAIDfarclip" },
			{ cvar = "horizonStart", label = "Horizon start", type = "slider", min = 400, max = 4000, step = 100, src = "preset", raid = "RAIDhorizonStart" },
		} },
		{ title = "Ground clutter", items = {
			{ cvar = "groundEffectDensity", label = "Ground clutter density", type = "slider", min = 16, max = 256, step = 8, src = "probe" },
			{ cvar = "groundEffectDist", label = "Ground clutter distance", type = "slider", min = 40, max = 500, step = 10, src = "probe" },
		} },
		{ title = "Effects", items = {
			{ cvar = "weatherDensity", label = "Weather", type = "choice", src = "probe",
			  options = { { 0, "None" }, { 1, "Light" }, { 2, "Medium" }, { 3, "Heavy" } } },
			{ cvar = "ffxGlow", label = "Full-screen glow", type = "toggle", src = "help" },
		} },
		{ title = "Camera", items = {
			{ cvar = "cameraDistanceMaxZoomFactor", label = "Max camera distance", type = "slider", min = 1, max = 4, step = 0.1, src = "ui" },
		} },
	}
	EverySetting.SECTIONS = { "Graphics", "Camera", "Interface" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "1", horizonStart = "1", RAIDhorizonStart = "1",
		groundEffectDensity = "1", groundEffectDist = "1", weatherDensity = "1", ffxGlow = "1", gxMonitor = "1",
		maxFPSBk = "1|s|8|200|1", cameraDistanceMaxZoomFactor = "2", TurnSpeed = "2|S|1|540|1|x",
		scriptErrors = "3|t", autoSelfCast = "3|t", SpellQueueWindow = "3", someRawCVar = "3", packedFlags = "3" }
	EverySetting.STYLES = {}
	W.Login()
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

-- How many lines a report accounts for: those it set, and those it lists as
-- set nothing (a value turned down or changed was set, and is listed too).
local function Accounted(report)
	local count = tonumber(report[1]:match("^Set (%d+) setting")) or 0
	for _, line in ipairs(report) do
		local label, n = line:match("^(%S.-) %((%d+)%):$")
		if label and label ~= "Turned down or changed" then count = count + tonumber(n) end
	end
	return count
end

T.test("import: each kind of line is read for a name and a value, mixed, one per line", function()
	local EverySetting = Start()
	local text = table.concat({
		-- The issue's own block, its dots and all.
		"/console groundEffectDensity 256",
		'\194\183/\194\183r\194\183un SetCVar("cameraDistanceMaxZoomFactor", 4)',
		'/script C_CVar.SetCVar("weatherDensity", "3")',
		'SET horizonStart "4000"',
		"groundEffectDist\194\160500", -- a non-breaking space, from a web page
		"/run SetCVar([[scriptErrors]], 1)", -- as vgtimes writes it
		"/RUN  SetCVar( 'autoSelfCast' , '0' ) ;",
		"/console\226\128\139 set farclip 5000", -- a zero-width space, and the console's own set
		'/console spellqueuewindow "120"', -- a name in another case
	}, "\r\n")
	local why, report = EverySetting.ImportProfile("", text)
	T.eq(why, nil)
	T.eq(report[1], "Set 9 settings. Undo takes the whole import back in one step.")
	T.eq(#report, 1, "nothing else to say")
	T.eq(Get("groundEffectDensity"), "256")
	T.eq(Get("cameraDistanceMaxZoomFactor"), "4.000000")
	T.eq(Get("weatherDensity"), "3")
	T.eq(Get("horizonStart"), "4000")
	T.eq(Get("RAIDhorizonStart"), "4000", "a raid twin goes along")
	T.eq(Get("groundEffectDist"), "500")
	T.eq(Get("scriptErrors"), "1")
	T.eq(Get("autoSelfCast"), "0")
	T.eq(Get("farclip"), "5000")
	T.eq(Get("SpellQueueWindow"), "120")
	T.eq(EverySetting.GetKept().SpellQueueWindow, "120", "kept by the CVar's own name")
	T.eq(EverySetting.GetProfile(), "Default", "set in the profile in use: no name needed, and no new profile")
	T.eq(#EverySetting.GetProfiles(), 1)
end)

T.test("import: one Undo takes the whole import back, and Redo makes it again", function()
	local EverySetting = Start()
	EverySetting.Set("ffxGlow", false)
	EverySetting.ImportProfile("", "/console farclip 9000\n/console horizonStart 2000\n/run SetCVar(\"scriptErrors\", 1)")
	T.eq((EverySetting.HistorySize()), 2, "one step for the whole import")
	T.ok(EverySetting.Undo())
	T.eq(Get("farclip"), "1000")
	T.eq(Get("RAIDfarclip"), "1000")
	T.eq(Get("horizonStart"), "1000")
	T.eq(Get("scriptErrors"), "0")
	T.ok(not EverySetting.IsStored("farclip") and not EverySetting.IsStored("scriptErrors"), "and none of it is kept")
	T.eq(Get("ffxGlow"), "0", "the change before it stays")
	T.ok(EverySetting.Redo())
	T.eq(Get("farclip"), "9000")
	T.eq(Get("RAIDhorizonStart"), "2000")
	T.ok(EverySetting.IsStored("scriptErrors"))
	-- Importing what's set and kept already changes nothing, and adds no step.
	local _, report = EverySetting.ImportProfile("", "/console farclip 9000")
	T.eq(report[1], "Set 1 setting. Each already had that value.")
	T.eq((EverySetting.HistorySize()), 2)
end)

T.test("import: a value is held to the range, and the report says what was kept", function()
	local EverySetting = Start()
	local _, report = EverySetting.ImportProfile("", "/console horizonStart 6000\n/console groundEffectDensity 250\n/console maxFPSBk 900\n/console farclip 7000")
	T.eq(table.concat(report, "\n"), table.concat({
		"Set 4 settings. Undo takes the whole import back in one step.",
		"Turned down or changed (3):",
		"  groundEffectDensity: typed 250, kept 248",
		"  horizonStart: typed 6000, kept 4000",
		"  maxFPSBk: typed 900, kept 30",
	}, "\n"))
	T.eq(Get("horizonStart"), "4000", "an import is held to the range, though the box goes past it")
	T.eq(Get("RAIDhorizonStart"), "4000")
	T.eq(EverySetting.GetKept().horizonStart, "4000")
	T.eq(Get("maxFPSBk"), "30", "the game turned it down")
	T.eq(Get("farclip"), "7000")
	T.eq(EverySetting.Set("horizonStart", "6000", true), "6000", "the box still takes it")
end)

T.test("import: unknown names, commands and other lines are reported, and set nothing", function()
	local EverySetting = Start()
	local lines = {
		"/console notInThisClient 1",
		'SET fooBar "1"',
		"/console ActionCam full",
		"/console gxRestart",
		"/console cvar_default autoSelfCast",
		"/console reloadUI",
		'Template 1: "The Sweet Spot"',
		"/dance",
		"/console farclip",
		"/console weatherDensity 7",
		"/console ffxGlow 0",
		"",
		"/console ffxGlow 0",
	}
	local sets = #W.sets
	local why, report = EverySetting.ImportProfile("", table.concat(lines, "\n"))
	T.eq(why, nil)
	T.eq(table.concat(report, "\n"), table.concat({
		"Set 1 setting. Undo takes the whole import back in one step.",
		"A value the setting doesn't take (1):",
		"  weatherDensity 7",
		"",
		"No setting by that name in this client (2):",
		"  notInThisClient",
		"  fooBar",
		"",
		"A command, not a setting, so not run (4):",
		"  /console ActionCam full",
		"  /console gxRestart",
		"  /console cvar_default autoSelfCast",
		"  /console reloadUI",
		"",
		"Named again: the last line counts (1):",
		"  ffxGlow",
		"",
		"Not read (3):",
		'  Template 1: "The Sweet Spot"',
		"  /dance",
		"  /console farclip",
	}, "\n"))
	T.eq(Accounted(report), 12, "every line but the blank one")
	for i = sets + 1, #W.sets do T.eq(W.sets[i][1], "ffxGlow", "only the setting was set") end
	T.eq(Get("weatherDensity"), "2")
	T.eq(Get("autoSelfCast"), "1", "cvar_default isn't run")
	local long = "/dance " .. ("x"):rep(80)
	T.eq(select(2, EverySetting.ImportProfile("", "/console gxRestart\n" .. long))[6], "  " .. long:sub(1, 57) .. "...", "a long line is cut short")
end)

T.test("import: no line is ever run as Lua", function()
	local EverySetting = Start()
	local lines = {
		"/run EverySettingRan = true",
		"/script EverySettingRan = true",
		'/run SetCVar("farclip", 5000) EverySettingRan = true',
		'/run SetCVar("farclip", 5000); EverySettingRan = true',
		'/run SetCVar("farclip", (function() EverySettingRan = true return 5000 end)())',
		'/run SetCVar("farclip", 5000 + 0)',
		'/run SetCVar("farclip", "5000")--]] EverySettingRan = true',
		'/run C_CVar.SetCVar("farclip", 5000, "EverySettingRan")',
		'/run _G.SetCVar("farclip", 5000)',
		"/run SetCVar(EverySettingRan, 1)",
		"/run SetCVar([[autoSelfCast]], GetCVarDefault([[autoSelfCast]]))", -- from vgtimes
		"/run print(GetCVar([[autoLootDefault]]))", -- from vgtimes
		'/run SetCVar("farclip\\", EverySettingRan = true, \\"", 5000)', -- a quote that ends nothing
		"/console farclip 5000; EverySettingRan = true",
		'/run SetCVar("ffxGlow", 0)', -- the one line that's a setting
	}
	-- Every way Lua could be run from a string, watched.
	local names, saved, ran = { "load", "loadstring", "loadfile", "dofile", "RunScript", "ConsoleExec" }, {}, {}
	for _, name in ipairs(names) do
		saved[name] = _G[name]
		_G[name] = function() ran[#ran + 1] = name end
	end
	local why, report = EverySetting.ImportProfile("", table.concat(lines, "\n"))
	for _, name in ipairs(names) do _G[name] = saved[name] end
	T.eq(_G.EverySettingRan, nil, "nothing pasted was run")
	T.eq(#ran, 0, "nor handed to anything that runs it: " .. table.concat(ran, ", "))
	T.eq(why, nil)
	T.eq(Get("farclip"), "1000")
	T.eq(W.SetCount("farclip"), 0)
	T.eq(Get("autoSelfCast"), "1")
	T.eq(Get("ffxGlow"), "0")
	T.eq(report[1], "Set 1 setting. Undo takes the whole import back in one step.")
	local text = table.concat(report, "\n")
	T.ok(text:find("Not run: a /run or /script line is only read when it's one SetCVar call (12):", 1, true), text)
	T.ok(text:find("No setting by that name in this client (1):\n  farclip\", EverySettingRan = true, \"", 1, true), text)
	T.ok(text:find("A value the setting doesn't take (1):\n  farclip 5000; EverySettingRan = true", 1, true), text)
	T.eq(Accounted(report), #lines)
end)

T.test("import: danger settings and locked ones are left alone, in danger mode or not", function()
	for _, on in ipairs({ false, true }) do
		local EverySetting = Start({ danger = on or nil })
		EverySetting.SetLocked("farclip", true)
		local _, report = EverySetting.ImportProfile("", "/console TurnSpeed 300\n/console gxMonitor 1\n/console farclip 5000\n/console ffxGlow 0")
		T.eq(table.concat(report, "\n"), table.concat({
			"Set 1 setting. Undo takes the whole import back in one step.",
			"Danger settings, left alone (2):",
			"  TurnSpeed",
			"  gxMonitor",
			"",
			"Locked, so left alone (1):",
			"  farclip",
		}, "\n"), on and "in danger mode" or "outside it")
		T.eq(Get("TurnSpeed"), "180")
		T.eq(W.SetCount("TurnSpeed"), 0)
		T.eq(Get("gxMonitor"), "0")
		T.eq(Get("farclip"), "1000", "a lock box's setting, as for a preset")
		T.eq(Get("ffxGlow"), "0")
	end
end)

T.test("import: not in combat", function()
	local EverySetting = Start()
	W.Combat(true)
	T.eq(EverySetting.ImportProfile("", "/console ffxGlow 0"), "Settings can't be imported in combat.")
	T.eq(EverySetting.ImportPreset("Guide", "/console ffxGlow 0"), "A preset can't be applied in combat.")
	T.eq(Get("ffxGlow"), "1")
	T.ok(not EverySetting.IsStored("ffxGlow"))
	T.eq(next(EverySetting.GetPresets()), nil)
	W.Combat(false)
	T.eq(EverySetting.ImportProfile("", "/console ffxGlow 0"), nil)
	T.eq(Get("ffxGlow"), "0")
end)

T.test("import: a section's Import takes lines too, saves them as a preset, and only what's under it", function()
	local EverySetting = Start()
	local function Camera(cvar) return cvar == "cameraDistanceMaxZoomFactor" end
	T.eq(EverySetting.ImportPreset("", "/console farclip 5000", Camera), "Type a name for the preset.")
	local why, report = EverySetting.ImportPreset("Guide", "/console cameraDistanceMaxZoomFactor 2.6\n/console farclip 10000\n/console gxRestart", Camera)
	T.eq(why, nil)
	T.eq(table.concat(report, "\n"), table.concat({
		"Set 1 setting, saved as the preset Guide. Undo takes the whole import back in one step.",
		"A command, not a setting, so not run (1):",
		"  /console gxRestart",
		"",
		"Not in this part of the list (1):",
		"  farclip",
	}, "\n"))
	T.eq(EverySetting.GetPresets().Guide.cameraDistanceMaxZoomFactor, "2.6")
	T.eq(EverySetting.GetPresets().Guide.farclip, nil)
	T.eq(Get("cameraDistanceMaxZoomFactor"), "2.600000")
	T.eq(Get("farclip"), "1000")
	T.ok(EverySetting.Undo())
	T.eq(Get("cameraDistanceMaxZoomFactor"), "1.000000")
	T.ok(EverySetting.GetPresets().Guide, "Undo takes back the values, not the preset")
	report = select(2, EverySetting.ImportPreset("Far", "/console farclip 5000", Camera))
	T.eq(report[1], "Nothing was set.")
	T.eq(EverySetting.GetPresets().Far, nil, "and no preset is saved")
end)

T.test("import: text that's neither a profile string nor a line that sets something is turned down", function()
	local EverySetting = Start()
	local why = "That isn't an Every Setting profile string, or lines that set something, like /console farclip 5000."
	T.eq(EverySetting.ImportProfile("", "hello there"), why)
	T.eq(EverySetting.ImportProfile("Mine", ""), why)
	T.eq(EverySetting.ImportProfile("Mine", nil), why)
	T.eq(EverySetting.ImportPreset("Mine", "Template 1\n/dance"), why)
	T.eq((EverySetting.HistorySize()), 0)
	T.eq(next(EverySetting.GetPresets()), nil)
end)

T.test("export: a profile or part of one as /console lines, which import back the same", function()
	local EverySetting = Start({ danger = true })
	EverySetting.AllGroups() -- a knob for every CVar, as the window makes them
	EverySetting.Set("farclip", 9000)
	EverySetting.Set("ffxGlow", false)
	EverySetting.Set("someRawCVar", 'a "b" c\\d', true)
	EverySetting.Set("SpellQueueWindow", "", true)
	EverySetting.Set("packedFlags", "\002G\tx", true)
	EverySetting.Set("TurnSpeed", 300) -- a danger setting, kept in danger mode
	T.eq(EverySetting.ExportLines(), table.concat({
		'/run SetCVar("SpellQueueWindow", "")',
		"/console farclip 9000",
		"/console ffxGlow 0",
		'/run SetCVar("packedFlags", "\\002G\\009x")',
		'/run SetCVar("someRawCVar", "a \\"b\\" c\\\\d")',
	}, "\n"), "in name order, danger settings left out, and /run where /console can't carry the value")
	T.eq(EverySetting.ExportLines({ farclip = "9000", TurnSpeed = "300" }), "/console farclip 9000", "a part of it")
	local kept = {}
	for cvar, value in pairs(EverySetting.GetKept()) do kept[cvar] = value end
	local lines = EverySetting.ExportLines()
	EverySetting.ResetAll()
	T.eq(next(EverySetting.GetKept()), nil)
	local _, report = EverySetting.ImportProfile("", lines)
	T.eq(report[1], "Set 5 settings. Undo takes the whole import back in one step.")
	for cvar, value in pairs(kept) do
		if cvar ~= "TurnSpeed" then T.eq(EverySetting.GetKept()[cvar], value, cvar) end
	end
end)

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------

local function Open()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	return EverySetting, o
end

-- The header row of the section or group `title`.
local function Header(o, title)
	for _, row in ipairs(o.rows) do
		local item = row:IsShown() and row.item
		if item and item.header and (item.group or item.section).title == title then return row end
	end
end

-- Picks `value` from a header's Presets menu.
local function Pick(row, value)
	W.Run(row.presets, "OnClick")
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return W.Run(w, "OnClick") end
	end
	error("no menu item " .. value)
end

T.test("import: the Import dialog takes lines, and shows the report in its place", function()
	local EverySetting, o = Open()
	W.Run(o.refs.profileImport, "OnClick")
	local dialog = o.refs.dialog
	T.eq(dialog.title:GetText(), "Import")
	T.ok(dialog.text:GetText():find("the commands from any guide", 1, true))
	dialog.body:SetText("/console horizonStart 6000\n/console gxRestart")
	W.Run(dialog.ok, "OnClick")
	T.ok(dialog:IsShown(), "the report")
	T.eq(dialog.title:GetText(), "Imported")
	T.eq(dialog.text:GetText(), "Set 1 setting. Undo takes the whole import back in one step.")
	T.eq(dialog.body:GetText(), "Turned down or changed (1):\n  horizonStart: typed 6000, kept 4000\n\nA command, not a setting, so not run (1):\n  /console gxRestart")
	T.ok(not dialog.ok:IsShown() and not dialog.name:IsShown())
	T.eq(dialog.cancel.label:GetText(), "Close")
	T.eq(o.refs.profile.label:GetText(), "Default", "still the same profile")
	T.eq(Get("horizonStart"), "4000")
	W.Run(dialog.cancel, "OnClick")
	T.ok(not dialog:IsShown())
	-- A report with nothing more to say has no box.
	W.Run(o.refs.profileImport, "OnClick")
	dialog.body:SetText("/console ffxGlow 0")
	W.Run(dialog.ok, "OnClick")
	T.ok(dialog:IsShown() and not dialog.scroll:IsShown())
	T.eq(dialog.text:GetText(), "Set 1 setting. Undo takes the whole import back in one step.")
	-- Text that isn't a line keeps the dialog open, with why.
	W.Run(o.refs.profileImport, "OnClick")
	dialog.body:SetText("hello there")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.title:GetText(), "Import")
	T.ok(dialog.error:GetText():find("lines that set something", 1, true), dialog.error:GetText())
	T.ok(EverySetting.Undo())
	T.eq(Get("ffxGlow"), "1")
end)

T.test("export: the Export dialog and a header's show the same settings as /console lines, and back", function()
	local EverySetting, o = Open()
	EverySetting.Set("farclip", 9000)
	EverySetting.Set("cameraDistanceMaxZoomFactor", 2.6)
	W.Run(o.refs.profileExport, "OnClick")
	local dialog = o.refs.dialog
	T.eq(dialog.body:GetText(), "EverySetting:1:cameraDistanceMaxZoomFactor=2.600000,farclip=9000")
	T.eq(dialog.ok.label:GetText(), "As /console")
	W.Run(dialog.ok, "OnClick")
	T.ok(dialog:IsShown())
	T.eq(dialog.title:GetText(), "Export Default")
	T.eq(dialog.body:GetText(), "/console cameraDistanceMaxZoomFactor 2.600000\n/console farclip 9000")
	T.ok(dialog.text:GetText():find("Danger settings, and the settings that aren't CVars, are left out", 1, true))
	T.eq(dialog.ok.label:GetText(), "As a string")
	T.eq(dialog.cancel.label:GetText(), "Close")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.body:GetText(), "EverySetting:1:cameraDistanceMaxZoomFactor=2.600000,farclip=9000", "and back")
	W.Run(dialog.cancel, "OnClick")
	-- A section's Export: only what's kept under it.
	Pick(Header(o, "Camera"), "export")
	T.eq(dialog.title:GetText(), "Export Camera")
	T.eq(dialog.body:GetText(), "EverySetting:1:cameraDistanceMaxZoomFactor=2.600000")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.body:GetText(), "/console cameraDistanceMaxZoomFactor 2.600000")
	-- A group's.
	W.Run(dialog.cancel, "OnClick")
	Pick(Header(o, "Draw distance"), "export")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.body:GetText(), "/console farclip 9000")
end)

T.test("import: a header's Import takes lines, and shows the report", function()
	local EverySetting, o = Open()
	Pick(Header(o, "Camera"), "import")
	local dialog = o.refs.dialog
	T.ok(dialog.text:GetText():find("the commands from any guide", 1, true))
	dialog.name:SetText("Guide")
	dialog.body:SetText("/console cameraDistanceMaxZoomFactor 2.6\n/console farclip 10000")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.title:GetText(), "Imported")
	T.eq(dialog.text:GetText(), "Set 1 setting, saved as the preset Guide. Undo takes the whole import back in one step.")
	T.eq(dialog.body:GetText(), "Not in this part of the list (1):\n  farclip")
	T.eq(Get("cameraDistanceMaxZoomFactor"), "2.600000")
	T.eq(Get("farclip"), "1000")
	T.ok(EverySetting.GetPresets().Guide)
end)

-------------------------------------------------------------------------------
-- Blocks from the guides
-------------------------------------------------------------------------------

-- A logged-in client with every CVar the Forever client has, the knobs from
-- Knobs.lua and CVars.lua, and the console commands the guides use.
local function Real()
	local EverySetting = W.Load()
	for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do
		local flags = cvar[5]
		W.AddCVar(cvar[1], cvar[2] or "", { locked = flags:find("l") ~= nil, readOnly = flags:find("r") ~= nil, secure = flags:find("s") ~= nil })
	end
	for _, command in ipairs({ "ActionCam", "cvar_default", "GxRestart" }) do W.AddCommand(command) end
	W.Login()
	return EverySetting
end

-- Lines as each guide prints them, copied from its page.
local GUIDES = {
	-- pro-gamer.gg: its first macro template, then lines from its text
	["pro-gamer.gg"] = { lines = {
		"/console farclip 10000",
		"/console horizonStart 6000",
		"/console horizonClip 10000",
		"/console groundEffectDensity 256",
		"/console groundEffectDist 500",
		"/console shadowMode 4",
		"/console shadowTextureSize 2048",
		"/console SSAO 4",
		"/console waterDetail 3",
		"/console particleDensity 100",
		"/console physicsLevel 2",
		"/console weatherDensity 3",
		"/console ffxGlow 0",
		"/console ffxDeath 0",
		"/console cameraDistanceMaxZoomFactor 2.6",
		"/console SpellQueueWindow 120",
		"/console scriptErrors 0",
		"/console gxRestart",
		"/console ActionCam full",
		"/console cameraYawMoveSpeed 120",
		"/console nameplateMotion 1",
		"/console rawMouseEnable 1",
		"/console Sound_EnableSoundWhenGameIsInBG 1",
	}, set = 19, report = {
		"Turned down or changed (1):", "  horizonStart: typed 6000, kept 4000",
		"No setting by that name in this client (2):", "  nameplateMotion", "  rawMouseEnable",
		"A command, not a setting, so not run (2):", "  /console gxRestart", "  /console ActionCam full",
	} },
	vgtimes = { lines = {
		"/console groundEffectDensity 256",
		"/console groundEffectDist 500",
		"/console groundEffectFade 370",
		"/console ResampleAlwaysSharpen 1",
		"/console cameraDistanceMaxZoomFactor 4.0",
		"/console weatherDensity 3",
		"/run SetCVar([[scriptErrors]], 1)",
		"/console cvar_default autoSelfCast",
		"/run SetCVar([[autoSelfCast]], GetCVarDefault([[autoSelfCast]]))",
	}, set = 7 },
	conquestcapped = { lines = {
		"/console groundEffectDensity 256",
		"/console groundEffectDist 500",
		"/console groundEffectFade 370",
		"/console ResampleAlwaysSharpen 1",
		"/console cameraDistanceMaxZoomFactor 4.0",
		"/console weatherDensity 3",
	}, set = 6 },
	lagofast = { lines = {
		"/console autoLootDefault 1",
		"/console lootUnderMouse 1",
		"/console alwaysCompareItems 1",
		"/console ResampleAlwaysSharpen 1",
		"/console renderScale 1",
		"/console cameraDistanceMaxZoomFactor 4.0",
		"/console floatingCombatTextCombatDamage 1",
		"/console floatingCombatTextCombatHealing 1",
		"/console floatingCombatTextCombatLogPeriodicSpells 1",
		"/console nameplateShowEnemies 1",
	}, set = 7 },
	iggm = { lines = {
		"/console ResampleAlwaysSharpen 1",
		"/console groundEffectDensity 256",
		"/console farclip 5000",
		"/console graphicsViewDistance 9",
		"/console lodObjectCullSize 8",
		"/console lodObjectFadeScale 200",
		"/console cvar_default farclip",
	}, set = 6 },
	["wow.gg"] = { lines = {
		"/console outlineModeShowLootEffectWhenDisabled 1",
		"/console graphicsOutlineMode 0",
	}, set = 2 },
}

T.test("import: a block copied from each guide imports, and the report accounts for every line", function()
	for name, guide in pairs(GUIDES) do
		local EverySetting = Real()
		local why, report = EverySetting.ImportProfile("", table.concat(guide.lines, "\n"))
		T.eq(why, nil, name)
		T.eq(report[1]:match("^Set (%d+) setting"), tostring(guide.set), name .. ": " .. table.concat(report, "\n"))
		T.eq(Accounted(report), #guide.lines, name .. ": " .. table.concat(report, "\n"))
		for _, line in ipairs(guide.report or {}) do
			T.ok(table.concat(report, "\n"):find("\n" .. line .. "\n", 1, true) or report[#report] == line, name .. ": " .. line)
		end
		for _, line in ipairs(guide.lines) do
			local cvar, value = line:match("^/console (%S+) (%S+)$")
			local knob = cvar and EverySetting.Knob(cvar)
			if knob and cvar ~= "horizonStart" then
				T.ok(tonumber(Get(cvar)) == tonumber(value), name .. ": " .. line .. " kept " .. tostring(Get(cvar)))
			end
		end
		T.eq((EverySetting.HistorySize()), 1, name .. ": one step for Undo")
	end
end)

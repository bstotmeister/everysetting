-- The console commands that aren't CVars: the window's Console commands section,
-- which lists them with what they do, a button to run each that's safe to run, and another to copy it.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a knob and three commands: one the game describes, one
-- CVars.lua does, and one nobody does. The window is open.
local function Open()
	local EverySetting, ns = W.Load()
	W.AddCVar("shadowSoft", "0")
	W.AddCommand("cvarlist", "List CVars (filtered by substring if provided)")
	W.AddCommand("GxRestart")
	W.AddCommand("mystery")
	EverySetting.GROUPS = { { title = "Shadows", items = { { cvar = "shadowSoft", label = "Soft shadows", type = "toggle" } } } }
	EverySetting.SECTIONS = { "Graphics" }
	EverySetting.CVARS = { shadowSoft = "1" }
	EverySetting.COMMANDS = { GxRestart = "Restarts the game's graphics." }
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

local function Shown(o)
	local out = {}
	for _, item in ipairs(o.view) do
		out[#out + 1] = item.header and ("[" .. (item.group or item.section).title .. "]") or item.more and "..." or item.knob.cvar
	end
	return table.concat(out, " ")
end

local function RowFor(o, name)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == name then return row end
	end
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

T.test("commands: a knob for each console command that isn't a CVar, in name order", function()
	local EverySetting = Open()
	local commands = EverySetting.ConsoleCommands()
	T.eq(#commands, 3, "not the CVars")
	T.eq(commands[1].cvar, "cvarlist")
	T.eq(commands[2].cvar, "GxRestart", "in any letter case")
	T.eq(commands[1].type, "command")
	T.eq(commands[1].tip, "List CVars (filtered by substring if provided)", "the game's help")
	T.eq(commands[2].tip, "Restarts the game's graphics.", "or CVars.lua's word for it")
	T.eq(commands[3].tip, nil, "or nothing")
	T.eq(EverySetting.Knob("GxRestart"), nil, "not a setting")
	T.eq(EverySetting.Set("GxRestart", "1"), nil, "so nothing sets it")
	T.eq(EverySetting.ConsoleCommands(), commands, "made once")
end)

T.test("commands: they're listed after the CVars, each with what it does", function()
	local _, o = Open()
	T.eq(Shown(o), "[Graphics] shadowSoft [Console commands] ...", "after the CVars, folded away")
	T.eq(o.refs.side[2].label:GetText(), "Console commands", "with a button in the sidebar")
	local header = o.rows[3]
	T.ok(not header.presets:IsShown() and not header.lock:IsShown(), "no presets and no lock box: nothing to set")
	T.eq(o.rows[4].more.label:GetText(), "Show 3 commands")
	W.Run(o.rows[4].more, "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft [Console commands] ... cvarlist GxRestart mystery")
	T.eq(o.rows[4].more.label:GetText(), "Hide 3 commands")
	local row = RowFor(o, "GxRestart")
	T.eq(row.label:GetText(), "GxRestart")
	T.eq(row.what:GetText(), "Restarts the game's graphics.")
	T.ok(row.command:IsShown(), "the / button")
	for _, control in ipairs({ row.lock, row.check, row.slider, row.box, row.dropdown, row.swatch, row.reset }) do
		T.ok(not control:IsShown(), "no control and no lock box")
	end
	T.eq(RowFor(o, "cvarlist").what:GetText(), "List CVars (filtered by substring if provided)")
	T.eq(RowFor(o, "mystery").what:GetText(), "")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(RowFor(o, "mystery").name, "OnEnter")
	T.ok(lines[1]:find("The game gives no description for this one.", 1, true), lines[1])
	T.ok(lines[1]:find("Every Setting doesn't run this one", 1, true), "and that this one isn't run")
	T.ok(lines[1]:find("Console command: mystery.", 1, true))
end)

T.test("commands: Run runs one tried and found safe, and says in chat what it printed", function()
	local _, o = Open()
	W.Run(o.rows[4].more, "OnClick")
	local row = RowFor(o, "GxRestart")
	T.ok(row.run:IsShown() and not row.run.unsupported, "on a command's row, where RUNNABLE has it")
	T.ok(not RowFor(o, "shadowSoft").run:IsShown(), "and not on a setting's")
	W.Run(row.run, "OnClick")
	T.eq(W.consoled[#W.consoled], "GxRestart")
	T.ok(not (o.refs.dialog and o.refs.dialog:IsShown()), "no dialog")
	W.Fire("CONSOLE_MESSAGE", "Restarting graphics\n")
	W.chat = {}
	W.RunTimers()
	T.ok(W.chat[1]:find("/console GxRestart printed:", 1, true), W.chat[1])
	T.eq(W.chat[2], "  Restarting graphics", "each line, without its line break")
	W.Fire("CONSOLE_MESSAGE", "later")
	T.eq(#W.chat, 2, "only what came while it ran")
	W.Run(RowFor(o, "cvarlist").run, "OnClick")
	for i = 1, 12 do W.Fire("CONSOLE_MESSAGE", "line " .. i) end
	W.chat = {}
	W.RunTimers()
	T.eq(#W.chat, 12, "a heading, ten lines and how many more")
	T.eq(W.chat[11], "  line 10")
	T.ok(W.chat[12]:find("...and 2 more lines, in the game's console window.", 1, true), W.chat[12])
	W.Run(row.run, "OnClick")
	W.chat = {}
	W.RunTimers()
	T.ok(W.chat[1]:find("Ran /console GxRestart. It printed nothing.", 1, true), W.chat[1])
end)

T.test("commands: Run is greyed out for any other, which can only be copied", function()
	local _, o = Open()
	W.Run(o.rows[4].more, "OnClick")
	local row = RowFor(o, "mystery")
	T.ok(row.run:IsShown() and row.run.unsupported, "shown, muted")
	T.ok(row.run:IsEnabled(), "not disabled, or the game would show no tooltip for it")
	W.Run(row.run, "OnClick")
	T.eq(#W.consoled, 0, "nothing run, however it's clicked")
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.run, "OnEnter")
	T.ok(lines[1]:find("This one can only be copied", 1, true), lines[1])
	lines = {}
	W.Run(row.name, "OnEnter")
	T.ok(lines[1]:find("Every Setting doesn't run this one", 1, true), lines[1])
	T.ok(not RowFor(o, "GxRestart").run.unsupported, "a row used for another command again isn't muted")
end)

T.test("commands: the toggles and reloadUI are run", function()
	local EverySetting = W.Load()
	for _, name in ipairs({ "reloadUI", "showPlayer", "LogFps", "ToggleWindowMode" }) do
		T.eq(EverySetting.RUNNABLE[name], true, name)
	end
end)

T.test("commands: the game's refused and harmful ones aren't run", function()
	local EverySetting = W.Load()
	for _, name in ipairs({ "quit", "logout", "cvar_default", "cvar_reset", "set", "NeighborhoodGetInvites", "spectate" }) do
		T.eq(EverySetting.RUNNABLE[name], nil, name)
		EverySetting.RunCommand(name)
	end
	T.eq(#W.consoled, 0)
end)

T.test("commands: the / button gives the command to copy, and runs nothing", function()
	local _, o = Open()
	W.Run(o.rows[4].more, "OnClick")
	W.Run(RowFor(o, "GxRestart").command, "OnClick")
	local dialog = o.refs.dialog
	T.ok(dialog:IsShown() and not dialog.ok:IsShown(), "just the command and a Close button")
	T.eq(dialog.title:GetText(), "Console command GxRestart")
	T.eq(dialog.body:GetText(), "/console GxRestart")
	dialog.body.text = "/console quit"
	W.Run(dialog.body, "OnTextChanged", true)
	T.eq(dialog.body:GetText(), "/console GxRestart", "it can't be changed")
	T.eq(#W.consoled, 0, "nothing was run")
	T.eq(W.restarts.gx, nil)
end)

T.test("commands: search finds them by name and by what they do, and the type menu has them", function()
	local EverySetting, o = Open()
	o.refs.search:SetText("substring")
	T.eq(Shown(o), "[Console commands] cvarlist", "what it does")
	o.refs.search:SetText("gxrestart")
	T.eq(Shown(o), "[Console commands] GxRestart", "its name, any case")
	o.refs.search:SetText("")
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("command"), "OnClick")
	T.eq(o.refs.kind.label:GetText(), "Commands")
	T.eq(Shown(o), "[Console commands] cvarlist GxRestart mystery")
	o.refs.tuned:SetChecked(true)
	W.Run(o.refs.tuned, "OnClick")
	T.eq(Shown(o), "", "Tuned leaves them out, as it does the other CVars")
	o.refs.tuned:SetChecked(false)
	W.Run(o.refs.tuned, "OnClick")
	EverySetting.Set("shadowSoft", true)
	o.refs.changed:SetChecked(true)
	W.Run(o.refs.changed, "OnClick")
	W.Run(o.refs.kind, "OnClick")
	W.Run(MenuItem("any"), "OnClick")
	T.eq(Shown(o), "[Graphics] shadowSoft", "Changed: nothing is kept for one")
	o.refs.changed:SetChecked(false)
	W.Run(o.refs.changed, "OnClick")
	o.refs.notDefault:SetChecked(true)
	W.Run(o.refs.notDefault, "OnClick")
	T.ok(not Shown(o):find("Console commands", 1, true), "Not default: a command has no value")
	o.refs.notDefault:SetChecked(false)
	W.Run(o.refs.notDefault, "OnClick")
	o.refs.search:SetText("=1")
	T.eq(Shown(o), "[Graphics] shadowSoft", "nor does a search by value find one")
end)

-- A client with Every Setting's own knobs, and the console commands that have a
-- row of their own, logged in with last session's saved variables if given.
local function Real(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("shadowSoft", "0")
	for _, command in ipairs({ "pitchLimit", "physEnable", "fontsize", "fontcolor", "GxRestart" }) do W.AddCommand(command) end
	W.Login()
	return EverySetting, ns.Options
end

T.test("commands: one that takes a value has a row, kept and run again at login", function()
	local EverySetting = Real()
	T.eq(EverySetting.Get("@console:pitchLimit"), nil, "the game can't be asked")
	T.eq(EverySetting.Set("@console:pitchLimit", 89), "89")
	T.eq(W.consoled[#W.consoled], "pitchLimit 89")
	T.ok(EverySetting.IsStored("@console:pitchLimit"))
	T.eq(EverySetting.Get("@console:pitchLimit"), "89", "the last value it was given")
	T.eq(EverySetting.Set("@console:pitchLimit", 1000), "90", "held to the slider's range")
	T.eq(EverySetting.Command("@console:pitchLimit", "75"), "/console pitchLimit 75")
	T.ok(EverySetting.Undo())
	T.eq(W.consoled[#W.consoled], "pitchLimit 89", "Undo runs it with the value before")
	-- A login runs it again: the game doesn't keep it.
	local saved = EverySettingDB
	Real(saved)
	T.eq(W.consoled[1], "pitchLimit 89")
	T.eq(EverySetting.Knob("@console:pitchLimit").found, true)
end)

T.test("commands: Reset runs the game's own value where it's known, and nothing where it isn't", function()
	local EverySetting = Real()
	EverySetting.Set("@console:physEnable", false)
	T.eq(W.consoled[#W.consoled], "physEnable 0")
	EverySetting.Reset("@console:physEnable")
	T.eq(W.consoled[#W.consoled], "physEnable 1", "physics is on until it's turned off")
	T.ok(not EverySetting.IsStored("@console:physEnable"))
	EverySetting.Set("@console:pitchLimit", 60)
	local runs = #W.consoled
	EverySetting.Reset("@console:pitchLimit")
	T.eq(#W.consoled, runs, "its own value isn't known, so nothing is run")
	T.ok(not EverySetting.IsStored("@console:pitchLimit"), "and it's no longer kept")
end)

T.test("commands: the console window's text size and colors are read back from the game", function()
	local EverySetting = Real()
	T.eq(EverySetting.Get("@console:fontsize"), "14")
	T.eq(EverySetting.Set("@console:fontsize", 20), "20")
	T.eq(W.consoled[#W.consoled], "fontsize 20")
	T.eq(EverySetting.Set("@console:fontsize", 60), "50", "held to 10 to 50")
	T.eq(EverySetting.Get("@console:fontcolor:echo"), "FF808080")
	T.eq(EverySetting.Set("@console:fontcolor:echo", "C86432"), "FFC86432")
	T.eq(W.consoled[#W.consoled], "fontcolor echo 200 100 50")
	T.eq(EverySetting.Command("@console:fontcolor:echo", "FFC86432"), "/console fontcolor echo 200 100 50")
	EverySetting.Reset("@console:fontcolor:echo")
	T.eq(W.consoled[#W.consoled], "fontcolor echo 128 128 128", "back to what it was")
end)

T.test("commands: one with a row has the / button, which gives the command for the value in its box", function()
	local _, o = Real()
	EverySetting_OpenOptions()
	o.refs.search:SetText("tilt")
	local row = RowFor(o, "@console:pitchLimit")
	T.ok(row.lock:IsShown() and row.command:IsShown(), "a lock box and the command button")
	row.box:SetFocus()
	row.box:SetText("85")
	W.Run(row.command, "OnClick")
	local dialog = o.refs.dialog
	T.eq(dialog.title:GetText(), "Command for Camera tilt limit")
	T.eq(dialog.body:GetText(), "/console pitchLimit 85")
	T.eq(#W.consoled, 0, "nothing was run")
end)

T.test("commands: a client without the command lists its row as not found", function()
	local EverySetting, ns = W.Load()
	W.Login()
	T.eq(EverySetting.Knob("@console:pitchLimit").found, false)
	T.eq(EverySetting.Set("@console:pitchLimit", 60), nil)
	T.eq(#W.consoled, 0)
	EverySetting_OpenOptions()
	ns.Options.refs.search:SetText("tilt")
	local row = RowFor(ns.Options, "@console:pitchLimit")
	T.ok(row and not row.command:IsShown(), "and gives no command for it")
end)

T.test("commands: Export gives a /console line for each, and Import takes them back", function()
	local EverySetting = Real()
	EverySetting.Set("@console:pitchLimit", 89)
	EverySetting.Set("@console:fontcolor:echo", "FFC86432")
	EverySetting.Set("shadowSoft", 1)
	T.eq(EverySetting.ExportLines(), "/console fontcolor echo 200 100 50\n/console pitchLimit 89\n/console shadowSoft 1")
	T.ok(EverySetting.ExportProfile():find("^EverySetting:2:"), "the string's version for settings that aren't CVars")
	EverySetting.Reset("@console:fontcolor:echo")
	local runs = #W.consoled
	local why, report = EverySetting.ImportProfile("", table.concat({
		"/console pitchLimit 1000",
		"/console fontcolor echo 10 20 30",
		"fontcolor warning 300 0 0",
		"/console physEnable 0",
		"/console GxRestart",
	}, "\n"))
	T.eq(why, nil)
	T.eq(table.concat(report, "\n"), table.concat({
		"Set 3 settings. Undo takes the whole import back in one step.",
		"Turned down or changed (1):",
		"  pitchLimit: typed 1000, kept 90",
		"",
		"A value the setting doesn't take (1):",
		"  fontcolor warning 300 0 0",
		"",
		"A command, not a setting, so not run (1):",
		"  /console GxRestart",
	}, "\n"))
	local ran = {}
	for i = runs + 1, #W.consoled do ran[#ran + 1] = W.consoled[i] end
	table.sort(ran)
	T.eq(table.concat(ran, ", "), "fontcolor echo 10 20 30, physEnable 0, pitchLimit 90",
		"Every Setting's own command for each value it took, and nothing pasted")
	T.eq(EverySetting.GetKept()["@console:fontcolor:echo"], "FF0A141E")
	T.ok(EverySetting.Undo())
	T.eq(EverySetting.GetKept()["@console:physEnable"], nil, "one Undo takes it back")
end)

T.test("commands: the ones with a row are listed under Console commands, before the rest", function()
	local EverySetting, o = Real()
	EverySetting_OpenOptions()
	local titles, after = {}, {}
	for _, item in ipairs(o.view) do
		if item.section.commands then
			if item.header then titles[#titles + 1] = (item.group or item.section).title end
			if item.knob then after[#after + 1] = item.knob.cvar end
			if item.more then after[#after + 1] = "..." end
		end
	end
	T.eq(table.concat(titles, ", "), "Console commands, Camera and physics, Console window")
	T.eq(table.concat(after, " "), "@console:pitchLimit @console:physEnable @console:fontsize @console:fontcolor:input "
		.. "@console:fontcolor:echo @console:fontcolor:warning @console:fontcolor:admin @console:fontcolor:global ...")
	local commands = {}
	for _, knob in ipairs(EverySetting.ConsoleCommands()) do commands[#commands + 1] = knob.cvar end
	T.eq(table.concat(commands, " "), "GxRestart", "the rest, to copy")
	-- A search that finds both: the rest under a header of their own.
	o.refs.search:SetText("console")
	local headers = {}
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.header and row.item.section.commands then headers[#headers + 1] = row.title:GetText() end
	end
	T.eq(headers[#headers], "Other commands")
	-- The tilt limit, kept, has no value from before to go back to.
	EverySetting.Set("@console:pitchLimit", 70)
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.knob and row.item.knob.cvar == "@console:pitchLimit" then W.Run(row.name, "OnEnter") end
	end
	T.ok(lines[1]:find("Reset stops that, and leaves it as it is.", 1, true), lines[1])
	T.ok(lines[1]:find("The game can't be asked for this one's value", 1, true))
end)

T.test("commands: one run through ConsoleExec from anywhere is noted, and the row shows it", function()
	local EverySetting, o = Real()
	EverySetting_OpenOptions()
	o.refs.search:SetText("tilt")
	local row = RowFor(o, "@console:pitchLimit")
	T.eq(row.box:GetText(), "", "the game can't be asked")
	-- /console in chat, or the console window: the game's own code runs the line.
	W.FromAddon("Blizzard_ChatFrameBase", ConsoleExec, "pitchLimit 70")
	T.eq(EverySetting.Get("@console:pitchLimit"), "70", "the value it was given")
	T.eq(row.box:GetText(), "70", "shown at once")
	T.eq(select(2, EverySetting.ChangedBy("@console:pitchLimit")), "the console or the game")
	T.ok(not EverySetting.IsStored("@console:pitchLimit"), "and not kept")
	W.FromAddon("Blizzard_Console", ConsoleExec, "PITCHLIMIT 75")
	T.eq(EverySetting.Get("@console:pitchLimit"), "75", "the command in any case")
	W.FromAddon("Blizzard_Console", ConsoleExec, "pitchLimit lots")
	T.eq(EverySetting.Get("@console:pitchLimit"), "75", "a value it can't take changes nothing")
	W.FromAddon("Blizzard_Console", ConsoleExec, "pitchLimit")
	T.eq(EverySetting.Get("@console:pitchLimit"), "75", "nor does none")
	W.FromChat('ConsoleExec("physEnable 0")')
	T.eq(EverySetting.Get("@console:physEnable"), "0")
	T.eq(select(2, EverySetting.ChangedBy("@console:physEnable")), "a /run line or a macro")
	-- One the game can be asked about is read back, and noted the same way.
	o.refs.search:SetText("console text size")
	W.FromAddon("Blizzard_ChatFrameBase", ConsoleExec, "fontsize 16")
	T.eq(RowFor(o, "@console:fontsize").box:GetText(), "16", "the window shows it at once")
	W.FromAddon("Blizzard_ChatFrameBase", ConsoleExec, "fontcolor echo 200 100 50")
	T.eq(select(2, EverySetting.ChangedBy("@console:fontcolor:echo")), "the console or the game")
	W.FromAddon("Blizzard_ChatFrameBase", ConsoleExec, "GxRestart")
	T.eq(select(2, EverySetting.ChangedBy("GxRestart")), nil, "a command with no row isn't noted")
end)

T.test("commands: another addon's change to a kept one is told, and Apply now sets it back", function()
	local EverySetting = Real()
	EverySetting.Set("@console:pitchLimit", 89)
	T.eq(EverySetting.ChangedBy("@console:pitchLimit"), "EverySetting", "its own")
	W.FromAddon("DynamicCam", ConsoleExec, "pitchLimit 60")
	T.eq(EverySetting.ChangedBy("@console:pitchLimit"), "DynamicCam")
	T.ok(W.chat[#W.chat]:find("DynamicCam changed Camera tilt limit to 60, away from the 89 you keep.", 1, true), W.chat[#W.chat])
	local list = EverySetting.Overwritten()
	T.eq(#list, 1)
	T.eq(list[1].cvar, "@console:pitchLimit")
	EverySetting.ApplyNow()
	T.eq(W.consoled[#W.consoled], "pitchLimit 89")
	T.eq(EverySetting.Get("@console:pitchLimit"), "89")
	T.eq(#EverySetting.Overwritten(), 0)
end)

T.test("commands: with Put back on, a kept one changed by another addon is set again at login, not put back", function()
	local EverySetting = Real()
	EverySetting.Set("@console:pitchLimit", 89)
	EverySetting.SetPutBack(true)
	W.FromAddon("DynamicCam", ConsoleExec, "pitchLimit 60")
	T.ok(W.chat[#W.chat]:find("away from the 89 you keep. Every Setting sets yours again at the next login", 1, true), W.chat[#W.chat])
	W.Advance(2)
	T.eq(EverySetting.Get("@console:pitchLimit"), "60", "Put back leaves it, as it leaves every setting that isn't a CVar")
end)

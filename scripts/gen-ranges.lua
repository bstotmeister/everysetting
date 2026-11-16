-- Writes RANGES.md: where each setting's range comes from, how sure that makes it, and
-- what the client kept when it was tried. Runs on plain Lua (5.1 to 5.5), from the repo root:
--
--   lua scripts/gen-ranges.lua > RANGES.md
--
-- It reads the addon's version (EverySetting/EverySetting.toc), the client's version and
-- CVar list (data/cvars.lua), each knob's source (`src` in EverySetting/Knobs.lua), the
-- evidence noted on each line of EverySetting/CVars.lua, what the game's quality settings
-- set (data/presets.lua), and what the client kept and the frame rates it gave (data/ranges/,
-- which has a README).
--
-- RANGES.md is kept in git and ships with the addon. The tests fail while it isn't what
-- this writes, so it's written again whenever one of those files changes.

local take = ... -- the tests pass a function that takes the page. From the shell it's printed.

-------------------------------------------------------------------------------
-- What it reads
-------------------------------------------------------------------------------

local toc = {} -- the .toc's "## Key: value" lines
for line in io.lines("EverySetting/EverySetting.toc") do
	local key, value = line:match("^## ([%w-]+):%s*(.-)%s*$")
	if key then toc[key] = value end
end

local client = dofile("data/cvars.lua")

-- WoW Forever's client on Windows has a few CVars a Mac's doesn't, as /every dump saved
-- them there. CVars.lua has a line for each of those too, so the controls and the counts
-- below are of `forever`: the Mac's CVars, then the ones only Windows has.
local WINDOWS = "data/ranges/70938/windows-d3d12/cvars.lua"
local forever, windowsOnly, onMac = {}, {}, {}
for _, cvar in ipairs(client.cvars) do
	onMac[cvar[1]] = true
	forever[#forever + 1] = cvar
end
for _, cvar in ipairs(dofile(WINDOWS).cvars) do
	if not onMac[cvar[1]] then
		forever[#forever + 1] = cvar
		windowsOnly[#windowsOnly + 1] = cvar[1]
	end
end

-- Knobs.lua and CVars.lua only fill in tables of the addon's, in its English words.
-- CVars.lua's lines are read as Forever has them. Retail's own are read apart.
local EverySetting = { Client = function() return "forever" end }
local ns = { EverySetting = EverySetting }
for _, file in ipairs({ "Locales/enUS.lua", "Knobs.lua", "CVars.lua" }) do
	assert(loadfile("EverySetting/" .. file))("EverySetting", ns)
end

-- Every knob in Knobs.lua whose setting is a CVar, in order; CVar -> its knob. The
-- settings that aren't CVars (named "@...") have the options the game's own
-- settings have, and are only counted, but for the console commands
-- ("@console:..."), which were tried in the client and are listed apart.
local knobs, knobOf, others, consoled = {}, {}, 0, {}
for _, group in ipairs(EverySetting.GROUPS) do
	for _, knob in ipairs(group.items) do
		if knob.cvar:find("^@console:") then
			consoled[#consoled + 1] = knob
		elseif knob.cvar:find("^@") then
			others = others + 1
		else
			knobs[#knobs + 1] = knob
			knobOf[knob.cvar] = knob
		end
	end
end

-- The evidence for a control is the comment that ends its line in CVars.lua, in
-- Forever's lines (CVARS) or retail's own (RETAIL_CVARS).
local noteOf, retailNoteOf = {}, {} -- CVar -> that comment
local notes = noteOf
for line in io.lines("EverySetting/CVars.lua") do
	if line:find("^EverySetting%.RETAIL_CVARS") then notes = retailNoteOf end
	local name, note = line:match('^%s*%[?"?([^%s"%]]+)"?%]?%s*=%s*".-",%s*%-%-%s*(.-)%s*$')
	if name and (EverySetting.CVARS[name] or EverySetting.RETAIL_CVARS[name]) then notes[name] = note end
end

local presetSets = {} -- the CVars a graphics quality setting sets
for _, setting in pairs(dofile("data/presets.lua")) do
	for cvar in pairs(setting) do presetSets[cvar] = true end
end
local presetsBuild -- the build they were found on, which only the file's first lines say
for line in io.lines("data/presets.lua") do
	presetsBuild = presetsBuild or line:match("^%-%-.-%(%d+%.%d+%.%d+%.(%d+)%)")
end

-- The lines `command` prints.
local function Lines(command)
	local lines = {}
	local p = assert(io.popen(command))
	for line in p:lines() do lines[#lines + 1] = line end
	p:close()
	return lines
end

-- The retail client's CVar list, the newest build's (data/ranges/<build>/retail/cvars.lua),
-- and the interface number each client's .toc line gives: Forever's starts 16.
local retailPaths = Lines("ls data/ranges/*/retail/cvars.lua 2>/dev/null")
table.sort(retailPaths, function(a, b) return tonumber(a:match("%d+")) > tonumber(b:match("%d+")) end)
local retail = retailPaths[1] and dofile(retailPaths[1])
local interface = {}
for n in (toc.Interface or ""):gmatch("%d+") do interface[n:find("^16") and "forever" or "retail"] = n end

local runs = {} -- what the client kept: one for each data/ranges/<build>/<platform>/probes.lua
for _, path in ipairs(Lines("ls data/ranges/*/*/probes.lua 2>/dev/null")) do
	local run = dofile(path)
	run.path = path
	runs[#runs + 1] = run
end
local function Newest(a, b) -- the newest build first
	if a.build ~= b.build then return tonumber(a.build) > tonumber(b.build) end
	return a.path < b.path
end
table.sort(runs, Newest)

local measured = {} -- the frame rates measured: one for each data/ranges/<build>/<platform>/costs.lua
for _, path in ipairs(Lines("ls data/ranges/*/*/costs.lua 2>/dev/null")) do
	local run = dofile(path)
	run.path = path
	measured[#measured + 1] = run
end
table.sort(measured, Newest)

-------------------------------------------------------------------------------
-- Sources
-------------------------------------------------------------------------------

-- Every source a knob (`src`) or a line of CVars.lua (its comment) can name: where the
-- range comes from, and how sure that makes it. A new kind needs a line here.
local SOURCES = {
	{ "ui", "Blizzard's settings code (the `forever` branch of wow-ui-source, or `live` for a line of retail's) has that control for it.",
	  "The game's own options offer the same values." },
	{ "help", "The CVar's help text in the client gives the range or lists the values.",
	  "The game's own words for it. Not every one has been tried against the engine." },
	{ "api", "A function the client provides gives the range.",
	  "Asked of the client as it runs." },
	{ "probe", "It was set in the client, and the engine kept these values. Past its own range the engine turns a value down, and usually says the range in its log.",
	  "Measured, in the clients under [What the client kept](#what-the-client-kept). Another build, platform or graphics API may keep other values." },
	{ "preset", "The values the game's own graphics quality settings give it, from their lowest level to their highest, and the engine's default.",
	  "The engine keeps any number for these. The range is the one the game itself uses, not a limit: the slider, styles and presets stay inside it, and the box beside the slider takes a number past it." },
	{ "command", "The game's own console command for it (`/console ActionCam full`) only sets 0 and 1.",
	  "The engine keeps any number for these. It's a checkbox because that's how the game sets it." },
	{ "code", "Blizzard's interface code only reads or sets it as on or off.",
	  "A checkbox for how the game uses it. The engine may keep other values." },
	{ "name", "Its name: showX, enableX and the like.",
	  "The weakest: nothing but the name says it's on or off." },
	{ "as X", "It's a raid twin, given the control of the CVar it stands in for.",
	  "As sure as that CVar's." },
}
local sourceOf = {}
for _, source in ipairs(SOURCES) do sourceOf[source[1]] = source end

-- The source a line of CVars.lua names: the first word of its comment.
local function Evidence(note)
	return note:match("^as ") and "as X" or note:match("^%a+")
end

-- What a change to a setting can wait for (a knob's `restart`, or the marker on a line of
-- CVars.lua), and the evidence a marker can go on (`restartSrc`, or "restart: ui" in the
-- line's comment). A new kind of either needs a line here.
local RESTARTS = {
	gx = "Shows after a graphics restart",
	window = "Shows once the game's window is updated",
	reload = "Shows after a reload of the interface",
	login = "Shows after logging out and in again",
	client = "Takes effect the next time the game starts",
}
local RESTART_SOURCES = {
	{ "ui", "Blizzard's settings code restarts the graphics or updates the window after a change to it, or says the game needs restarting." },
	{ "help", "The CVar's help text in the client says so." },
	{ "probe", "Seen in the client: a change showed only after it. [What the client kept](#what-the-client-kept) has the note." },
	{ "guide", "Another addon's page or a guide says so. Not seen in the client." },
}
local restartSourceOf = {}
for _, source in ipairs(RESTART_SOURCES) do restartSourceOf[source[1]] = source end

-- What a change to a CVar waits for: the kind, the one value a change to waits (nil when
-- any change does), and the evidence. Nothing for a CVar whose changes show at once.
local function Restart(name)
	local knob = knobOf[name]
	if knob then return knob.restart, knob.restartTo, knob.restartSrc end
	local spec = (EverySetting.CVARS[name] or ""):gsub("|x$", "")
	local kind, to = spec:match("|(%l+):?([^=|]*)$")
	if RESTARTS[kind] then return kind, to ~= "" and to or nil, (noteOf[name] or ""):match("restart: (%a+)") end
end

-- What a knob's `cost` can be, and the evidence it can go on (`costSrc`). A new kind of
-- either needs a line here.
local COSTS = { heavy = true, medium = true, light = true }
local COST_SOURCES = {
	{ "probe", "Measured in the client: the frame rate at each end of the setting's range, under [Frame rates](#frame-rates)." },
	{ "guide", "Graphics guides and other graphics addons rate it so. Frame rates measured for it, if any, are under [Frame rates](#frame-rates), and didn't show the cost." },
}
local costSourceOf = {}
for _, source in ipairs(COST_SOURCES) do costSourceOf[source[1]] = source end

-- The cost a measurement gives: how far the frame rate fell from the low end of the
-- range to the high end. A fifth or more is heavy, a twentieth or more medium.
local function Rating(low, high)
	local fall = (low - high) / low
	return fall >= 0.2 and "heavy" or fall >= 0.05 and "medium" or "light"
end

-- The newest measurement of a CVar's frame rate: { cvar, low, high, fpsLow, fpsHigh }.
local function Measurement(name)
	for _, run in ipairs(measured) do
		for _, line in ipairs(run.costs) do
			if line[1] == name then return line end
		end
	end
end

-------------------------------------------------------------------------------
-- Text
-------------------------------------------------------------------------------

-- A number as the page shows it: 0.05, 10000. The same on every Lua.
local function Num(n)
	if type(n) ~= "number" then return tostring(n) end
	return (("%.4f"):format(n):gsub("(%.%d-)0+$", "%1"):gsub("%.$", ""))
end

-- A count with its thousands apart: 1,797.
local function Count(n)
	local text = ("%d"):format(n)
	while true do
		local found
		text, found = text:gsub("^(%d+)(%d%d%d)", "%1,%2")
		if found == 0 then return text end
	end
end

local function Share(n)
	return ("%.1f%%"):format(100 * n / #forever)
end

local function Code(text)
	return "`" .. text .. "`"
end

local out = {}
local function Line(text, ...)
	out[#out + 1] = select("#", ...) > 0 and text:format(...) or text
end

-- A table: its head, then each row, as lists of cells.
local function Table(head, rows)
	local function Row(cells)
		for i, cell in ipairs(cells) do cells[i] = tostring(cell):gsub("|", "\\|") end
		Line("| " .. table.concat(cells, " | ") .. " |")
	end
	local rule = {}
	for i = 1, #head do rule[i] = "---" end
	Row(head)
	Row(rule)
	for _, row in ipairs(rows) do Row(row) end
	Line("")
end

-- A knob's range or options, in words.
local function Range(knob)
	if knob.type == "slider" then
		return ("%s to %s, in steps of %s"):format(Num(knob.min), Num(knob.max), Num(knob.step))
	elseif knob.type == "choice" then
		local options = {}
		for i, option in ipairs(knob.options) do
			local value = Num(option[1])
			options[i] = option[2] == value and value or value .. " = " .. option[2]
		end
		return table.concat(options, "; ")
	elseif knob.type == "toggle" then
		return "On or off (1 or 0)"
	end
	return knob.type == "flags" and "A menu of ticks" or "A color"
end

-- The control a line of CVars.lua suggests, as a knob: { type, min, max, step, options }.
local KINDS = { t = "toggle", s = "slider", S = "slider", c = "choice", f = "flags", h = "color" }
local function Suggested(spec)
	local parts = {}
	for part in (spec .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
	local knob = { type = KINDS[parts[2] or ""] }
	if knob.type == "slider" then
		knob.min, knob.max, knob.step = tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5])
	elseif knob.type == "choice" then
		knob.options = {}
		for i = 3, #parts do
			local value, label = parts[i]:match("^(.-)=(.*)$") -- a key in the locale table, or the label itself
			if value then knob.options[#knob.options + 1] = { value, ns.EN[label] or label } end
		end
	end
	return knob.type and knob or nil
end

-- Whether two CVar values are the same: "1" and "1.000" are.
local function Same(a, b)
	local x, y = tonumber(a), tonumber(b)
	if x and y then return math.abs(x - y) < 1e-6 end
	return a == b
end

-------------------------------------------------------------------------------
-- Counts
-------------------------------------------------------------------------------

local tuned, suggested = {}, {} -- source -> how many knobs; how many lines of CVars.lua
local controls = {} -- kind of control -> how many lines of CVars.lua suggest it
local probed = {} -- the CVars whose suggested control rests on a probe
local held = {} -- the ones whose box is held to the range too: an S in CVars.lua
-- suggested: lines of CVars.lua with a control. ui: CVars the game's own options have a
-- control for. sets: the others a graphics quality setting sets. twins: the raid twins of both.
local total = { suggested = 0, ui = 0, sets = 0, twins = 0 }

-- Whether the game's own options have a control for a CVar.
local function InOptions(name)
	if knobOf[name] then return knobOf[name].src == "ui" end
	return noteOf[name] ~= nil and noteOf[name]:match("^%a+") == "ui"
end

for _, knob in ipairs(knobs) do
	if not sourceOf[knob.src] then error(knob.cvar .. " has a source this script doesn't know: " .. tostring(knob.src), 0) end
	tuned[knob.src] = (tuned[knob.src] or 0) + 1
end

for _, cvar in ipairs(forever) do
	local name = cvar[1]
	local control = Suggested(EverySetting.CVARS[name] or "")
	if control and not knobOf[name] then
		local source = Evidence(noteOf[name] or "")
		if not sourceOf[source or ""] then error(name .. " has a control in CVars.lua, and no evidence this script knows", 0) end
		suggested[source] = (suggested[source] or 0) + 1
		controls[control.type] = (controls[control.type] or 0) + 1
		total.suggested = total.suggested + 1
		if source == "probe" then probed[#probed + 1] = name end
		if EverySetting.CVARS[name]:find("^%d+|S|") then held[#held + 1] = Code(name) end
		local twinOf = noteOf[name]:match("^as (%S+)")
		if twinOf and (InOptions(twinOf) or presetSets[twinOf]) then total.twins = total.twins + 1 end
	end
	if InOptions(name) then
		total.ui = total.ui + 1
	elseif presetSets[name] then
		total.sets = total.sets + 1
	end
end

local flagCount = {}
for _, cvar in ipairs(client.cvars) do
	for flag in cvar[5]:gmatch(".") do flagCount[flag] = (flagCount[flag] or 0) + 1 end
end
local server = {} -- the ones the game's server enforces: a line of CVars.lua that ends in x
for _, cvar in ipairs(client.cvars) do
	if (EverySetting.CVARS[cvar[1]] or ""):find("|x$") then server[#server + 1] = Code(cvar[1]) end
end

-------------------------------------------------------------------------------
-- The page
-------------------------------------------------------------------------------

local repo = toc["X-Website"]

Line("# Where the ranges come from")
Line("")
Line("Every Setting %s, for WoW Forever %s (build %s)%s.", toc.Version, client.version, client.build,
	retail and (" and WoW retail %s (build %s)"):format(retail.version, retail.build) or "")
Line("")
Line("The game can't be asked for a CVar's range. So every slider, menu and checkbox in Every Setting")
Line("has a source, and this page lists them: where each range comes from, how sure that makes it,")
Line("and what the client kept when it was tried.")
Line("")
Line("The page is written for each release by `scripts/gen-ranges.lua` in [the addon's repository](%s),", repo)
Line("from the addon's own files and the results kept in `data/ranges/` there.")
Line("")

Line("## The clients")
Line("")
Line("- WoW Forever %s, build %s (interface %s).", client.version, client.build, interface.forever or toc.Interface)
Line("- %s CVars, as `/every dump` saved them on a Mac (`data/cvars.lua`).", Count(#client.cvars))
local windowsNames = {}
for _, name in ipairs(windowsOnly) do windowsNames[#windowsNames + 1] = Code(name) end
Line("- %s more on Windows, which a Mac's client doesn't have, as `/every dump` saved them there", Count(#windowsOnly))
Line("  (`%s`): %s.", WINDOWS, table.concat(windowsNames, ", "))
if presetsBuild and presetsBuild ~= client.build then
	Line("- What its graphics quality settings set, level by level, is from build %s (`data/presets.lua`).", presetsBuild)
end
Line("- The client locks %s of them and marks %s read-only, and the game's server enforces %s (%s).", Count(flagCount.l or 0), Count(flagCount.r or 0), Count(#server), table.concat(server, ", "))
Line("  Every Setting leaves those alone outside danger mode. %s can't be set in combat.", Count(flagCount.s or 0))
Line("")
if retail then
	Line("Every Setting runs in WoW retail too: %s, build %s (interface %s), whose %s CVars are in", retail.version, retail.build, interface.retail, Count(#retail.cvars))
	Line("`%s`. The ranges here are Forever's: [The tuned settings](#the-tuned-settings) says where", retailPaths[1])
	Line("retail's differ, and which of them retail lacks, and [In WoW retail](#in-wow-retail) has the lines")
	Line("retail has of its own for the other CVars.")
	Line("")
end

Line("## Sources")
Line("")
Line("The engine holds only some CVars to a range. For the rest it keeps whatever it's given, so")
Line("a range here is either one the engine enforces or one the game itself uses.")
Line("")
local rows = {}
for _, source in ipairs(SOURCES) do
	rows[#rows + 1] = { Code(source[1]), source[2], source[3], Count(tuned[source[1]] or 0), Count(suggested[source[1]] or 0) }
end
Table({ "Source", "Where the range comes from", "How sure", "Tuned settings", "Other CVars" }, rows)

Line("## The tuned settings")
Line("")
Line("The %s settings in `EverySetting/Knobs.lua`. Every Setting holds each to the range or options here, but for", Count(#knobs))
Line("a number typed in the box of one whose source is `preset`.")
Line("")
rows = {}
for _, group in ipairs(EverySetting.GROUPS) do
	local first = true
	for _, knob in ipairs(group.items) do
		if knobOf[knob.cvar] == knob then
			rows[#rows + 1] = { first and group.title or "", knob.label, Code(knob.cvar), Range(knob), Code(knob.src) }
			first = false
		end
	end
end
Table({ "Group", "Setting", "CVar", "Range or options", "Source" }, rows)
if retail then
	local has, lacks = {}, {}
	for _, cvar in ipairs(retail.cvars) do has[cvar[1]:lower()] = true end
	rows = {}
	for _, knob in ipairs(knobs) do
		if not has[knob.cvar:lower()] then lacks[#lacks + 1] = Code(knob.cvar) end
		if knob.retail then
			local own = setmetatable({}, { __index = knob })
			for field, value in pairs(knob.retail) do own[field] = value end
			if not sourceOf[own.src] then error(knob.cvar .. "'s retail range has a source this script doesn't know: " .. tostring(own.src), 0) end
			rows[#rows + 1] = { own.label, Code(knob.cvar), Range(own), Code(own.src) }
		end
	end
	Line("In WoW retail the engine keeps another range for %s of them, and Every Setting holds them to that one there,", Count(#rows))
	Line("styles and presets too:")
	Line("")
	Table({ "Setting", "CVar", "Range or options in retail", "Source" }, rows)
	Line("Retail has no CVar for %s of them, and its window leaves them out: %s.", Count(#lacks), table.concat(lacks, ", "))
	Line("")
end
if others > 0 then
	Line("`Knobs.lua` also has %s settings that aren't CVars, such as the modified clicks and the action bars.", Count(others))
	Line("Each has the control and the options the game's own settings have, and none is here.")
	Line("")
end
if #consoled > 0 then
	Line("And %s that are console commands, each set with `/console <command> <value>` and listed under", Count(#consoled))
	Line("Console commands in the window. [What the client kept](#what-the-client-kept) has what each printed and did.")
	Line("")
	rows = {}
	for _, knob in ipairs(consoled) do
		rows[#rows + 1] = { knob.label, Code(knob.cvar:match("^@console:(%a+)")), Range(knob), Code(knob.src) }
	end
	Table({ "Setting", "Command", "Range or options", "Source" }, rows)
end

Line("## Every other CVar")
Line("")
Line("`EverySetting/CVars.lua`, which ships with the addon, has a line for each of the client's CVars,")
Line("on a Mac and on Windows.")
Line("%s of them suggest a control, and name the evidence for it at the end of the line. A suggested", Count(total.suggested))
Line("control is only that: the box beside it still takes any value%s. The other", #held > 0 and (" (except " .. table.concat(held, ", ") .. "'s)") or "")
Line("%s CVars have just the box.", Count(#forever - #knobs - total.suggested))
Line("")
rows = {}
for _, kind in ipairs({ { "toggle", "Checkbox" }, { "slider", "Slider" }, { "choice", "Menu" }, { "flags", "Menu of ticks" }, { "color", "Color swatch" } }) do
	rows[#rows + 1] = { kind[2], Count(controls[kind[1]] or 0) }
end
Table({ "Control", "CVars" }, rows)
Line("The ones whose control rests on a probe:")
Line("")
rows = {}
for _, name in ipairs(probed) do
	local control = Suggested(EverySetting.CVARS[name])
	rows[#rows + 1] = { Code(name), Range(control), (noteOf[name]:gsub("^probe:?%s*", "")) }
end
Table({ "CVar", "Range or options", "Noted with it" }, rows)

-- What a line of CVars.lua gives a CVar, in words: its control, or just the box, and what a
-- change waits for.
local function Given(spec)
	local control = Suggested(spec)
	local kind = spec:gsub("|x$", ""):match("|(%l+):?[^=|]*$")
	local words = control and Range(control) or "Just the box"
	return RESTARTS[kind] and (words .. ". " .. RESTARTS[kind]) or words
end

if retail then
	local foreverName = {} -- lower-case name -> Forever's name for it
	for _, cvar in ipairs(client.cvars) do foreverName[cvar[1]:lower()] = cvar[1] end
	local only, other, lineless = 0, 0, {}
	rows = {}
	for _, cvar in ipairs(retail.cvars) do
		local name = cvar[1]
		local spec = EverySetting.RETAIL_CVARS[name]
		if spec then
			local note = retailNoteOf[name] or ""
			local control = Suggested(spec)
			if control and not sourceOf[Evidence(note) or ""] then error(name .. " has a control in retail's lines, and no evidence this script knows", 0) end
			local kind = spec:gsub("|x$", ""):match("|(%l+):?[^=|]*$")
			if RESTARTS[kind] and not restartSourceOf[note:match("restart: (%a+)") or ""] then
				error(name .. " is marked in retail's lines as waiting for a restart, on no evidence this script knows", 0)
			end
			if foreverName[name:lower()] then other = other + 1 else only = only + 1 end
			rows[#rows + 1] = { Code(name), EverySetting.SECTIONS[tonumber(spec:match("^%d+"))], Given(spec),
				foreverName[name:lower()] and Given(EverySetting.CVARS[foreverName[name:lower()]] or "") or "Only in retail", note }
		elseif not foreverName[name:lower()] then
			lineless[#lineless + 1] = Code(name)
		end
	end
	Line("### In WoW retail")
	Line("")
	Line("Retail's own lines are at the end of `CVars.lua` (`RETAIL_CVARS`), and take the place of Forever's in retail:")
	Line("%s for the CVars only retail has, and %s for CVars both games have, where retail's options menu", Count(only), Count(other))
	Line("gives a control Forever's doesn't, or another one. Its other CVars have Forever's line. `ui` on one of these is")
	Line("retail's settings code (the `live` branch of wow-ui-source). One with just the box says why.")
	Line("")
	Table({ "CVar", "Section", "In retail", "In Forever", "Noted with it" }, rows)
	if #lineless > 0 then
		Line("Retail's list has %s more that only it has, and that no line names: %s. Like any CVar `CVars.lua`", Count(#lineless), table.concat(lineless, ", "))
		Line("doesn't have, each is listed under the last section, with a box.")
		Line("")
	end
end

Line("## Settings that wait for a restart")
Line("")
Line("A change to one of these doesn't show at once. Its tooltip in Every Setting says what it waits")
Line("for, the window offers Restart graphics or Update window when that's what it is, and situations")
Line("leave these settings out.")
Line("")
rows = {}
for _, cvar in ipairs(forever) do
	local name = cvar[1]
	local kind, to, source = Restart(name)
	if kind then
		if not RESTARTS[kind] then error(name .. " waits for a restart this script doesn't know: " .. tostring(kind), 0) end
		if not restartSourceOf[source or ""] then error(name .. " is marked as waiting for a restart, on no evidence this script knows", 0) end
		rows[#rows + 1] = { Code(name), RESTARTS[kind] .. (to and (", when it's set to " .. to) or ""), Code(source) }
	end
end
Table({ "CVar", "A change", "Evidence" }, rows)
rows = {}
for _, source in ipairs(RESTART_SOURCES) do rows[#rows + 1] = { Code(source[1]), source[2] } end
Table({ "Evidence", "What it is" }, rows)

Line("## What the heavy settings cost")
Line("")
Line("A tuned setting that costs frame rate as it's turned up says so in its tooltip and under its")
Line("name: light, medium or heavy. A measured cost is how far the frame rate fell from the low end of")
Line("the setting's range to the high end, from the same spot: heavy for a fifth or more, medium for a")
Line("twentieth or more, light for less. Another machine may fall further or less, so the window also")
Line("shows the frame rate before and after a change to any graphics setting, or a style.")
Line("")
-- A knob's range, as its two ends: the values a measurement sets.
local function Ends(knob)
	if knob.type == "slider" then return Num(knob.min), Num(knob.max) end
	if knob.type == "choice" then return Num(knob.options[1][1]), Num(knob.options[#knob.options][1]) end
	return "0", "1"
end
rows = {}
for _, knob in ipairs(knobs) do
	if knob.cost then
		if not COSTS[knob.cost] then error(knob.cvar .. " has a cost this script doesn't know: " .. tostring(knob.cost), 0) end
		if not costSourceOf[knob.costSrc or ""] then error(knob.cvar .. " has a cost, on no evidence this script knows", 0) end
		if knob.costSrc == "probe" then
			local line = Measurement(knob.cvar)
			if not line then error(knob.cvar .. "'s cost is measured, and data/ranges has no frame rates for it", 0) end
			local low, high = Ends(knob)
			if line[2] ~= low or line[3] ~= high then error(knob.cvar .. "'s frame rates are for " .. line[2] .. " and " .. line[3] .. ", not the ends of its range", 0) end
			local rating = Rating(line[4], line[5])
			if rating ~= knob.cost then error(knob.cvar .. " is rated " .. knob.cost .. ", and its frame rates say " .. rating, 0) end
		end
		rows[#rows + 1] = { knob.label, Code(knob.cvar), knob.cost, Code(knob.costSrc) }
	elseif knob.costSrc then
		error(knob.cvar .. " has a costSrc, and no cost", 0)
	end
end
Table({ "Setting", "CVar", "Cost", "Evidence" }, rows)
rows = {}
for _, source in ipairs(COST_SOURCES) do rows[#rows + 1] = { Code(source[1]), source[2] } end
Table({ "Evidence", "What it is" }, rows)
Line("### Frame rates")
Line("")
Line("Each is `GetFramerate()` averaged over several seconds, standing still, with the setting at one")
Line("end of its range and then the other, one setting at a time, and put back after.")
Line("")
if #measured == 0 then
	Line("Nothing is on record yet.")
	Line("")
end
for _, run in ipairs(measured) do
	Line("#### %s %s (build %s), %s", run.game or "WoW Forever", run.version, run.build, run.platform)
	Line("")
	if run.note then
		Line(run.note)
		Line("")
	end
	rows = {}
	for _, line in ipairs(run.costs) do
		local fall = (line[4] - line[5]) / line[4]
		rows[#rows + 1] = { Code(line[1]), line[2], ("%.0f fps"):format(line[4]), line[3], ("%.0f fps"):format(line[5]),
			("%.0f%%"):format(100 * fall), line.note or "" }
	end
	Table({ "CVar", "Low end", "Frame rate", "High end", "Frame rate", "Fall", "Notes" }, rows)
end

Line("## What the client kept")
Line("")
Line("From `/every probe` and `/every check`: each sets a CVar, reads back what the engine kept, and")
Line("puts the old value back. A value is under Not kept when the CVar read something else after")
Line("it was set: the engine turned it down, or changed it. The notes are what the engine said in")
Line("its log, or what was seen.")
Line("")
if #runs == 0 then
	Line("Nothing is on record yet.")
	Line("")
end
for _, run in ipairs(runs) do
	Line("### %s %s (build %s), %s", run.game or "WoW Forever", run.version, run.build, run.platform)
	Line("")
	if run.note then
		Line(run.note)
		Line("")
	end
	local order, byCVar = {}, {}
	for _, probe in ipairs(run.probes) do
		local name = probe[1]
		local row = byCVar[name]
		if not row then
			row = { kept = {}, turned = {}, notes = {}, seen = {} }
			byCVar[name] = row
			order[#order + 1] = name
		end
		for i = 2, 3 do
			local value, kept = probe[i], probe[i + 2]
			if not row.seen[value] then
				row.seen[value] = true
				local list = Same(value, kept) and row.kept or row.turned
				list[#list + 1] = value
			end
		end
		if probe.note then row.notes[#row.notes + 1] = probe.note end
	end
	rows = {}
	local tried = 0 -- how many of the tuned settings
	-- Numbers go lowest first. Anything else stays in the order it was tried.
	local function Sort(list)
		for _, value in ipairs(list) do
			if not tonumber(value) then return end
		end
		table.sort(list, function(a, b) return tonumber(a) < tonumber(b) end)
	end
	for _, name in ipairs(order) do
		local row = byCVar[name]
		Sort(row.kept)
		Sort(row.turned)
		rows[#rows + 1] = { Code(name), table.concat(row.kept, ", "), table.concat(row.turned, ", "), table.concat(row.notes, " ") }
		if knobOf[name] then tried = tried + 1 end
	end
	Line("%s CVars, %s of them tuned settings.", Count(#order), Count(tried))
	Line("")
	Table({ "CVar", "Kept", "Not kept", "Notes" }, rows)
	if run.commands then
		Line("Console commands that aren't CVars, each run with a value or none. A command has nothing to")
		Line("read it back by, so what it did is what the console printed, and what was seen or read elsewhere.")
		Line("")
		rows = {}
		for _, command in ipairs(run.commands) do
			rows[#rows + 1] = { Code(command[1]), command[2] == "" and "none" or Code(command[2]), command[3], command.note or "" }
		end
		Table({ "Command", "Value", "Printed", "Seen" }, rows)
	end
end

Line("## Counts")
Line("")
Line("Of the client's %s CVars, on a Mac or on Windows:", Count(#forever))
Line("")
local reached = total.ui + total.sets + total.twins
local has = #knobs + total.suggested
Table({ "", "CVars", "Share" }, {
	{ "Have a control in the game's own options (`ui`)", Count(total.ui), Share(total.ui) },
	{ "Have none, and are set by one of the options' graphics quality settings (`data/presets.lua`)", Count(total.sets), Share(total.sets) },
	{ "Are the raid twin of one of either (`as X`)", Count(total.twins), Share(total.twins) },
	{ "Those three together: what the game's options reach", Count(reached), Share(reached) },
	{ "Are tuned in Every Setting", Count(#knobs), Share(#knobs) },
	{ "Have a control in Every Setting, tuned or suggested", Count(has), Share(has) },
})

local page = table.concat(out, "\n")
if type(take) == "function" then take(page) else io.write(page) end

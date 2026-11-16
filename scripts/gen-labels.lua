-- Writes EverySetting/Labels.lua from Blizzard's interface code. Runs on plain Lua (5.1 to 5.5).
--
-- The game's settings code names each setting by a global string, which the
-- game has in every language it ships in:
--
--   Settings.SetupCVarCheckbox(category, "cameraTerrainTilt", FOLLOW_TERRAIN, OPTION_TOOLTIP_FOLLOW_TERRAIN)
--
-- This reads those calls from two checkouts of Gethe/wow-ui-source, one for each
-- game: the `forever` branch for WoW Forever, and `live` for retail. For each game
-- it writes, for each CVar that game's client has, the names of the two strings.
-- Forever's CVars are data/cvars.lua, retail's data/ranges/<build>/retail/cvars.lua
-- for the build the checkout is of (its version.txt). Only the names: the window
-- reads the text from the game, in the game's language. From the repo root:
--
--   lua scripts/gen-labels.lua <forever checkout> <live checkout> > labels.new
--   mv labels.new EverySetting/Labels.lua
--
-- Read: Settings.SetupCVarCheckbox, SetupCVarSlider, SetupCVarDropdown and
-- SetupCVarColorSwatch, the gamepad settings' CreateCVarSlider, the graphics
-- settings' own helpers (the quality settings' addFunc, AddCompatSettingsCheckbox),
-- and Settings.RegisterCVarSetting with the tooltip from the control made for its
-- setting. A setting of the interface's own (Settings.RegisterProxySetting) is read
-- where it gets and sets one CVar through Settings.CreateCVarAccessorClosures, or
-- where its getter and setter are functions of the file's that get and set that one
-- CVar and nothing else, through those or by GetCVar and SetCVar; and so is a menu
-- of ticks whose rows are { LABEL, TOOLTIP, "cvar" }. The
-- CVars a proxy sets some other way aren't read. A raid twin (raidGraphicsQuality)
-- is left out: the window names it by the CVar it stands in for, with "(raid)".
-- What was left out, and why, is printed to stderr.

local foreverRoot, retailRoot = ...
if not foreverRoot or not retailRoot then
	io.stderr:write("usage: lua scripts/gen-labels.lua <forever checkout> <live checkout>\n")
	os.exit(1)
end

local function Read(path)
	local f = assert(io.open(path, "rb"))
	local text = f:read("*a")
	f:close()
	return text
end

-- The text with its comments blanked out, strings kept, so a call that's
-- commented out isn't read.
local function Uncomment(text)
	local out, i, n = {}, 1, #text
	while i <= n do
		local c = text:sub(i, i)
		if c == "-" and text:sub(i + 1, i + 1) == "-" then
			local level = text:match("^%[(=*)%[", i + 2)
			local stop
			if level then
				stop = select(2, text:find("]" .. level .. "]", i, true)) or n
			else
				stop = (text:find("\n", i, true) or n + 1) - 1
			end
			out[#out + 1] = text:sub(i, stop):gsub("[^\n]", " ")
			i = stop + 1
		elseif c == '"' or c == "'" then
			local j = i + 1
			while j <= n and text:sub(j, j) ~= c do
				if text:sub(j, j) == "\\" then j = j + 1 end
				j = j + 1
			end
			out[#out + 1] = text:sub(i, j)
			i = j + 1
		else
			local level = text:match("^%[(=*)%[", i)
			if level then
				local stop = select(2, text:find("]" .. level .. "]", i, true)) or n
				out[#out + 1] = text:sub(i, stop)
				i = stop + 1
			else
				out[#out + 1] = c
				i = i + 1
			end
		end
	end
	return table.concat(out)
end

-- The arguments of the call whose ( is at `open`, each as its source text, and
-- the position of its ).
local CLOSE = { ["("] = ")", ["{"] = "}", ["["] = "]" }
local function Args(text, open)
	local args, depth, start, i = {}, 0, open + 1, open + 1
	local stack = {}
	while i <= #text do
		local c = text:sub(i, i)
		if c == '"' or c == "'" then
			local j = i + 1
			while j <= #text and text:sub(j, j) ~= c do
				if text:sub(j, j) == "\\" then j = j + 1 end
				j = j + 1
			end
			i = j
		elseif CLOSE[c] then
			depth = depth + 1
			stack[depth] = CLOSE[c]
		elseif c == ")" and depth == 0 then
			local last = text:sub(start, i - 1):match("^%s*(.-)%s*$")
			if last ~= "" or #args > 0 then args[#args + 1] = last end
			return args, i
		elseif depth > 0 and c == stack[depth] then
			depth = depth - 1
		elseif c == "," and depth == 0 then
			args[#args + 1] = text:sub(start, i - 1):match("^%s*(.-)%s*$")
			start = i + 1
		end
		i = i + 1
	end
end

-- Whether an argument is a global string's name: FOLLOW_TERRAIN.
local function StringName(arg)
	return arg and arg:match("^[%u_][%u%d_]*$") and arg ~= "_" and arg or nil
end

-- Each call to `fn` in `text`, as (its arguments, where it starts, where it ends).
-- A function's definition isn't a call.
local function Calls(text, fn)
	local pattern = fn:gsub("%.", "%%.") .. "%s*%("
	local from = 1
	return function()
		while true do
			local s, e = text:find(pattern, from)
			if not s then return nil end
			from = e + 1
			local before = text:sub(math.max(1, s - 40), s - 1)
			if not before:match("function%s+$") and not before:match("[%w_%.:]$") then
				local args, close = Args(text, e)
				if args then return args, s, close end
			end
		end
	end
end

-- The calls that make a setting's control: which argument is the setting, which its
-- tooltip, and which its label, where the control shows one of its own and not the
-- setting's. Some make two, a checkbox and the control beside it.
local CONTROLS = {
	{ "Settings.CreateCheckbox", { 2, 3 } },
	{ "Settings.CreateCheckboxWithOptions", { 2, 4 } },
	{ "Settings.CreateSlider", { 2, 4 } },
	{ "Settings.CreateDropdown", { 2, 4 } },
	{ "Settings.CreateColorSwatch", { 2, 3 } },
	{ "Settings.CreateControlInitializer", { 2, 4 } },
	{ "Settings.CreateSettingInitializerData", { 1, 3 } },
	{ "Settings.CreateCheckboxInitializer", { 1, 3 } },
	{ "Settings.CreateSliderInitializer", { 1, 3 } },
	{ "Settings.CreateDropdownInitializer", { 1, 3 } },
	{ "CreateSettingsCheckboxSliderInitializer", { 1, 3, 2 }, { 4, 7, 6 } },
	{ "CreateSettingsCheckboxDropdownInitializer", { 1, 3, 2 }, { 4, 7, 6 } },
	{ "CreateSettingsCheckboxWithButtonInitializer", { 1, 6 } },
	{ "CreateSettingsCheckboxWithColorSwatchInitializer", { 1, 2 } },
}

-- The Setup calls: which argument is the label, which the tooltip, and which the
-- CVar, where it isn't the second.
local SETUPS = {
	{ "Settings.SetupCVarCheckbox", 3, 4 },
	{ "Settings.SetupCVarSlider", 4, 5 },
	{ "Settings.SetupCVarDropdown", 5, 6 },
	{ "Settings.SetupCVarColorSwatch", 3, 4 },
	{ "CreateCVarSlider", 4, 5 }, -- the gamepad settings' own (category, cvar, variable, label, tooltip, ...)
	{ "addFunc", 4, nil, 3 }, -- GraphicsOverrides' quality settings (settings, category, cvar, label, proxy)
	{ "AddCompatSettingsCheckbox", 3, 4, 1 }, -- the graphics compatibility settings (cvar, proxy, label, tooltip)
}

-- The CVar a call at `at` names: a string, or a name given one last before it
-- in the file (local cvar = "LowLatencyMode").
local function CVarName(arg, text, at)
	local name = arg:match('^"([^"]+)"$') or arg:match("^'([^']+)'$")
	if name or not arg:match("^[%a_][%w_]*$") then return name end
	for pos, value in text:gmatch("()[^%w_%.]" .. arg .. "%s*=%s*\"([%w_]+)\"") do
		if pos > at then break end
		name = value
	end
	return name
end

-- Where the code has several pairs of names for a CVar, which one the game's
-- client loads: the game's own override first, then the shared one, then the
-- other's. Forever's own is Camelot's, retail's mainline's.
local RANKS = {
	forever = function(file)
		if file:find("/Camelot/", 1, true) then return 1 end
		if file:find("/Mainline/", 1, true) then return 3 end
		return 2
	end,
	retail = function(file)
		return file:find("/Mainline/", 1, true) and 1 or 2
	end,
}

-- The control for the setting a call at `s` (whose ")" is at `close`) makes: by the name
-- the setting is given, the first control made for it before that name is given another.
-- Its tooltip, and its label where it shows one of its own: a checkbox and the control
-- beside it with a label each (Use UI Scale and UI Scale, where the code registers both
-- settings as Render Scale). Where both have the same, the setting's own is kept.
local function Control(text, s, close)
	local var = text:sub(math.max(1, s - 80), s - 1):match("([%a_][%w_%.]*)%s*=%s*$")
	if not var then return nil end
	local rest = text:sub(close + 1)
	local stop = rest:find("[^%w_%.]" .. var:gsub("%.", "%%.") .. "%s*=[^=]") or #rest
	rest = rest:sub(1, stop)
	local first, tooltip, label
	for _, control in ipairs(CONTROLS) do
		for cargs, cs in Calls(rest, control[1]) do
			for k = 2, #control do
				local at = control[k]
				if cargs[at[1]] == var and (not first or cs < first) then
					local own = at[3] and control[2][3] and control[3][3]
						and cargs[control[2][3]] ~= cargs[control[3][3]]
					first, tooltip, label = cs, cargs[at[2]], own and cargs[at[3]] or nil
				end
			end
		end
	end
	return tooltip, label
end

-- The CVars the function `fn`, as a proxy setting at `at` is given it, gets or sets: a
-- function of the file's, defined last before `at`, by GetCVar, SetCVar and the like
-- and by what CreateCVarAccessorClosures gave; or one of those itself. As a set by
-- lower-case name, and its body where it's a function of the file's. nil if it's neither.
local ACCESSORS = "()local%s+([^\n=]-)=%s*Settings%.CreateCVarAccessorClosures%(%s*([^,%)]+)"
local function Touches(text, at, fn)
	if not (fn and fn:match("^[%a_][%w_]*$")) then return nil end
	local before = text:sub(1, at - 1)
	local def
	for pos in before:gmatch("()local%s+function%s+" .. fn .. "%s*%(") do def = pos end
	for pos in before:gmatch("()local%s+" .. fn .. "%s*=%s*function%s*%(") do
		if not def or pos > def then def = pos end
	end
	-- Its body: to the end on its own line, or on the line it's defined on (one-liners).
	local body
	if def then
		local first = text:match("^[^\n]*", def)
		local indent = before:sub(1, def - 1):match("([ \t]*)$")
		body = first:find("%f[%w_]end%f[^%w_]") and first
			or text:sub(def, text:find("\n" .. indent .. "end%f[^%w_]", def) or at)
	end
	local cvars, accessor = {}, {} -- an accessor's name -> the CVar it gets or sets
	for pos, names, arg in text:sub(1, def or at):gmatch(ACCESSORS) do
		local cvar = CVarName(arg, text, pos)
		for name in names:gmatch("[%a_][%w_]*") do accessor[name] = cvar end
	end
	if not body then
		if not accessor[fn] then return nil end
		cvars[accessor[fn]:lower()] = true
		return cvars
	end
	for cvar in body:gmatch('[GS]etCVar%a*%(%s*"([%w_]+)"') do cvars[cvar:lower()] = true end
	for name, cvar in pairs(accessor) do
		if body:find("%f[%w_]" .. name .. "%s*%(") then cvars[cvar:lower()] = true end
	end
	return cvars, body
end

-- The one CVar a proxy setting at `at`, with this getter and setter, gets and sets:
-- where its getter is a function of the file's, they touch that CVar and no other,
-- and the setter sets no other setting (Self Cast's key).
local function ProxyCVar(text, at, getter, setter)
	local gets, own = Touches(text, at, getter)
	local sets, setterBody = Touches(text, at, setter)
	if not (own and sets and next(gets) and next(sets)) then return nil end
	if setterBody and setterBody:find(":SetValue%s*%(") then return nil end
	local cvar = next(gets)
	if next(gets, cvar) or next(sets, next(sets)) or not sets[cvar] then return nil end
	return cvar
end

-- One game's table: its build, and its lines, from the checkout at `root`.
local function Labels(root, game)
	local build = Read(root .. "/version.txt"):match("[%d%.]+")
	local path = game == "forever" and "data/cvars.lua" or ("data/ranges/%s/retail/cvars.lua"):format(build:match("(%d+)$"))
	local ok, list = pcall(dofile, path)
	if not ok then
		io.stderr:write(("%s's checkout is of %s, and there's no CVar list for it at %s\n"):format(game, build, path))
		os.exit(1)
	end
	local client = {} -- lower-case name -> the name as the client has it
	for _, cvar in ipairs(list.cvars) do client[cvar[1]:lower()] = cvar[1] end

	local found = {} -- lower-case CVar name -> { { label, tooltip, file }, ... }
	local skipped = {} -- what was left out, for stderr

	local files = {}
	local find = assert(io.popen("find '" .. root .. "/Interface' -name '*.lua' | LC_ALL=C sort"))
	for file in find:lines() do
		local text = Read(file)
		if text:find("Settings.", 1, true) then
			files[#files + 1] = { path = file:sub(#root + 2), text = Uncomment(text) }
		end
	end
	find:close()

	local function Add(arg, label, tooltip, file, text, at)
		local where = file .. ":" .. select(2, text:sub(1, at):gsub("\n", "")) + 1
		local cvar = CVarName(arg, text, at)
		if not cvar then
			skipped[#skipped + 1] = ("%s: %s, a CVar not named in the code"):format(where, arg)
		elseif not client[cvar:lower()] then
			skipped[#skipped + 1] = ("%s: %s, not in the client"):format(where, cvar)
		elseif client[(cvar:lower():match("^raid(.+)$") or "")] then
			skipped[#skipped + 1] = ("%s: %s, a raid twin"):format(where, cvar)
		elseif not StringName(label) then
			skipped[#skipped + 1] = ("%s: %s, its label isn't a global string (%s)"):format(where, cvar, tostring(label))
		else
			local key = cvar:lower()
			found[key] = found[key] or {}
			-- A tooltip that's the label again says nothing: the CVar's help is kept.
			table.insert(found[key], { label, tooltip ~= label and StringName(tooltip) or nil, file })
		end
	end

	for _, file in ipairs(files) do
		local text = file.text
		for _, setup in ipairs(SETUPS) do
			for args, s in Calls(text, setup[1]) do
				Add(args[setup[4] or 2], args[setup[2]], setup[3] and args[setup[3]], file.path, text, s)
			end
		end
		for args, s, close in Calls(text, "Settings.RegisterCVarSetting") do
			local tooltip, label = Control(text, s, close)
			Add(args[2], StringName(label) and label or args[4], tooltip, file.path, text, s)
		end
		-- A proxy that gets and sets one CVar: the getter CreateCVarAccessorClosures
		-- gives, passed to the next RegisterProxySetting, whose label is its fourth.
		for args, s, close in Calls(text, "Settings.CreateCVarAccessorClosures") do
			local line = text:sub(1, s - 1):match("[^\n]*$")
			local getter = line:match("^%s*local%s+([%a_][%w_]*)%s*,") or line:match("^%s*([%a_][%w_]*)%s*,")
			local nextClosures = text:find("Settings.CreateCVarAccessorClosures", close, true) or #text
			for pargs, ps, pclose in Calls(text:sub(1, nextClosures), "Settings.RegisterProxySetting") do
				if ps > close then
					local uses = false
					for k = 5, #pargs do uses = uses or pargs[k] == getter end
					if getter and uses then
						local tooltip, label = Control(text, ps, pclose)
						Add(args[1], StringName(label) and label or pargs[4], tooltip, file.path, text, s)
						break
					end
				end
			end
		end
		-- A proxy whose getter is a function of the file's that gets one CVar, and whose
		-- setter sets that one and no other (Triple Buffering, Graphics API, Sharpness).
		for pargs, ps, pclose in Calls(text, "Settings.RegisterProxySetting") do
			local cvar = ProxyCVar(text, ps, pargs[6], pargs[7])
			if cvar then
				local tooltip, label = Control(text, ps, pclose)
				Add('"' .. cvar .. '"', StringName(label) and label or pargs[4], tooltip, file.path, text, ps)
			end
		end
		-- A menu of ticks, a CVar to a row: { LABEL, TOOLTIP, "cvar" }.
		for at, label, tooltip, cvar in text:gmatch('(){%s*([%u_][%u%d_]*)%s*,%s*([%u_][%u%d_]*)%s*,%s*("[%w_]+")%s*}') do
			Add(cvar, label, tooltip, file.path, text, at)
		end
	end

	local Rank = RANKS[game]
	local names = {}
	for key in pairs(found) do names[#names + 1] = key end
	table.sort(names)

	local lines = {}
	local tips, conflicts = 0, 0
	for _, key in ipairs(names) do
		local picks = found[key]
		table.sort(picks, function(a, b)
			if Rank(a[3]) ~= Rank(b[3]) then return Rank(a[3]) < Rank(b[3]) end
			if (a[2] ~= nil) ~= (b[2] ~= nil) then return a[2] ~= nil end
			return a[3] < b[3]
		end)
		local pick = picks[1]
		if pick[2] then tips = tips + 1 end
		for i = 2, #picks do
			if picks[i][1] ~= pick[1] then
				conflicts = conflicts + 1
				io.stderr:write(("%s: %s: %s (%s), not %s (%s)\n"):format(game, client[key], pick[1], pick[3], picks[i][1], picks[i][3]))
			end
		end
		local cvar = client[key]
		local field = cvar:match("^[%a_][%w_]*$") and cvar or ('["' .. cvar .. '"]')
		lines[#lines + 1] = ("\t\t%s = { %q%s },"):format(field, pick[1], pick[2] and (", %q"):format(pick[2]) or "")
	end

	for _, line in ipairs(skipped) do io.stderr:write(game .. ": left out: " .. line .. "\n") end
	io.stderr:write(("%s: %d CVars with the game's label, %d with a tooltip too; %d left out; %d with more than one label\n"):format(
		game, #names, tips, #skipped, conflicts))
	return build, lines
end

local foreverBuild, foreverLines = Labels(foreverRoot, "forever")
local retailBuild, retailLines = Labels(retailRoot, "retail")

local out = { ([[
-- Generated by scripts/gen-labels.lua from Blizzard's interface code, WoW Forever's
-- (%s) and retail's (%s). Don't edit it by hand.
--
-- The CVars each game's options menu has, by the game (EverySetting.Client()), each
-- with the names of the game's global strings for its label and tooltip there: the
-- game has those in every language it ships in. A row for one of these CVars is
-- named by its game's label, in the game's language (Core.lua, RawKnob). Only the
-- names are here.

local _, ns = ...

ns.EverySetting.LABELS = {]]):format(foreverBuild, retailBuild) }
out[#out + 1] = "\tforever = {"
for _, line in ipairs(foreverLines) do out[#out + 1] = line end
out[#out + 1] = "\t},"
out[#out + 1] = "\tretail = {"
for _, line in ipairs(retailLines) do out[#out + 1] = line end
out[#out + 1] = "\t},"
out[#out + 1] = "}"
io.write(table.concat(out, "\n"), "\n")

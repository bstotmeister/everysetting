-- Knobs.lua: every knob is well formed, and matches the client it was made for.

local T = ...
local W = dofile("tests/wow.lua")

local EverySetting = W.Load()
local client = {} -- lower-case CVar name -> { name, default, category, help, flags }
for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do client[cvar[1]:lower()] = cvar end

local levels = {} -- lower-case CVar name -> the values its quality setting gives it, lowest level first
for _, setting in pairs(dofile("data/presets.lua")) do
	for cvar, values in pairs(setting) do levels[cvar:lower()] = values end
end

local SOURCES = { ui = true, help = true, api = true, probe = true, preset = true, command = true }
local RESTARTS = { gx = true, window = true, reload = true, login = true, client = true }
local RESTART_SOURCES = { ui = true, probe = true, guide = true }
local COSTS = { light = true, medium = true, heavy = true }
local COST_SOURCES = { probe = true, guide = true }

local function EachKnob(fn)
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do fn(knob, group) end
	end
end

-- A setting that isn't a CVar has a name of its own that starts with "@".
local function IsCVar(knob) return not knob.cvar:find("^@") end

-- Only the knobs whose setting is a CVar.
local function EachCVarKnob(fn)
	EachKnob(function(knob, group) if IsCVar(knob) then fn(knob, group) end end)
end

T.test("knobs: groups have a title and knobs", function()
	T.ok(#EverySetting.GROUPS > 0, "no groups")
	local seen = {}
	for _, group in ipairs(EverySetting.GROUPS) do
		T.ok(type(group.title) == "string" and group.title ~= "", "a group has no title")
		T.ok(not seen[group.title], group.title .. " is listed twice")
		seen[group.title] = true
		T.ok(#group.items > 0, group.title .. " has no knobs")
	end
end)

T.test("knobs: a group's knobs are all in one of CVars.lua's sections", function()
	for _, group in ipairs(EverySetting.GROUPS) do
		local section = EverySetting.Section(group.items[1].cvar)
		for _, knob in ipairs(group.items) do
			T.ok(EverySetting.CVARS[knob.cvar] or not IsCVar(knob), knob.cvar .. " isn't in CVars.lua")
			T.eq(EverySetting.Section(knob.cvar), section, knob.cvar .. " is in another section than the rest of " .. group.title)
		end
	end
end)

T.test("knobs: each has a name, a description and a source for its range", function()
	EachKnob(function(knob)
		local name = tostring(knob.cvar)
		T.ok(type(knob.cvar) == "string", "a knob has no cvar")
		T.ok(type(knob.label) == "string" and knob.label ~= "", name .. " has no label")
		T.ok(type(knob.tip) == "string" and knob.tip:match("%.$"), name .. " needs a tip that ends in a full stop")
		T.ok(SOURCES[knob.src], name .. " doesn't say where its range comes from (src)")
		T.ok(knob.restart == nil or RESTARTS[knob.restart], name .. " has an unknown restart")
		T.ok(knob.restart == nil or RESTART_SOURCES[knob.restartSrc], name .. " doesn't say what its restart goes on (restartSrc)")
		T.ok(knob.restart or (knob.restartTo == nil and knob.restartSrc == nil), name .. " has a restartTo or restartSrc, and no restart")
		T.ok(knob.cost == nil or COSTS[knob.cost], name .. " has an unknown cost")
		T.ok(knob.cost == nil or COST_SOURCES[knob.costSrc], name .. " doesn't say what its cost goes on (costSrc)")
		T.ok(knob.cost or knob.costSrc == nil, name .. " has a costSrc, and no cost")
	end)
end)

T.test("knobs: the heavy settings every guide warns about say what they cost", function()
	local costs = {}
	EachKnob(function(knob) costs[knob.cvar] = knob.cost end)
	for _, cvar in ipairs({ "groundEffectDensity", "groundEffectDist", "shadowTextureSize", "farclip", "reflectionMode", "volumeFog" }) do
		T.ok(costs[cvar], cvar .. " has no cost")
	end
end)

T.test("knobs: no CVar has two knobs", function()
	local seen = {}
	EachKnob(function(knob)
		local key = knob.cvar:lower()
		T.ok(not seen[key], knob.cvar .. " has two knobs")
		seen[key] = true
		if knob.raid then
			T.ok(not seen[knob.raid:lower()], knob.raid .. " is a raid twin and a knob")
			seen[knob.raid:lower()] = true
		end
	end)
end)

T.test("knobs: sliders have a range their step divides", function()
	EachKnob(function(knob)
		if knob.type ~= "slider" then return end
		local name = knob.cvar
		T.ok(type(knob.min) == "number" and type(knob.max) == "number", name .. " needs min and max")
		T.ok(knob.min < knob.max, name .. ": min must be below max")
		T.ok(type(knob.step) == "number" and knob.step > 0, name .. " needs a step")
		local steps = (knob.max - knob.min) / knob.step
		T.ok(math.abs(steps - math.floor(steps + 0.5)) < 1e-6, name .. ": the step doesn't land on max")
		T.eq(EverySetting.Normalize(knob, knob.max), EverySetting.Normalize(knob, knob.max + knob.step), name .. " past max")
		T.ok(knob.bounds == nil or type(knob.bounds) == "function", name .. ": bounds must be a function")
	end)
end)

T.test("knobs: choices have options, each with a value and a label", function()
	EachKnob(function(knob)
		if knob.type ~= "choice" then return end
		local name = knob.cvar
		T.ok(type(knob.options) == "table" and #knob.options >= 2, name .. " needs at least two options")
		local seen = {}
		for _, option in ipairs(knob.options) do
			T.ok(option[1] ~= nil and type(option[2]) == "string" and option[2] ~= "", name .. " has an option without a label")
			T.ok(not seen[tostring(option[1])], name .. " lists " .. tostring(option[1]) .. " twice")
			seen[tostring(option[1])] = true
		end
	end)
end)

T.test("knobs: every type is one the window can show", function()
	EachKnob(function(knob)
		T.ok(knob.type == "slider" or knob.type == "choice" or knob.type == "toggle" or ((knob.type == "color" or knob.type == "text") and not IsCVar(knob)),
			knob.cvar .. " has type " .. tostring(knob.type))
	end)
end)

T.test("knobs: the Forever client has every CVar, and none is locked", function()
	EachCVarKnob(function(knob)
		local cvar = client[knob.cvar:lower()]
		T.ok(cvar, knob.cvar .. " isn't in the 1.60.1 client")
		T.eq(knob.cvar, cvar[1], "spelled as the client spells it")
		T.ok(not cvar[5]:find("[lr]"), knob.cvar .. " is locked or read-only in the client")
		if knob.raid then
			local twin = client[knob.raid:lower()]
			T.ok(twin, knob.raid .. " isn't in the 1.60.1 client")
			T.eq(knob.raid, twin[1], "spelled as the client spells it")
		end
	end)
end)

T.test("knobs: a range from the presets covers what the game's quality settings set", function()
	EachKnob(function(knob)
		if knob.src ~= "preset" then return end
		local values = levels[knob.cvar:lower()]
		T.ok(values, knob.cvar .. " says its range is from the presets, but no quality setting sets it")
		local default = tonumber(client[knob.cvar:lower()][2])
		local low, high = default, default
		for _, value in ipairs(values) do
			low, high = math.min(low, value), math.max(high, value)
		end
		T.eq(knob.min, low, knob.cvar .. ": min is the lowest of the presets' values and the default")
		T.eq(knob.max, high, knob.cvar .. ": max is the highest")
	end)
end)

T.test("knobs: the built-in presets give a knob four of its quality setting's levels", function()
	T.eq(#EverySetting.TIERS, 4)
	local count = 0
	EachKnob(function(knob)
		local values = levels[knob.cvar:lower()]
		if not values then
			T.ok(knob.tiers == nil, knob.cvar .. " has tiers, but no quality setting sets it")
			return
		end
		count = count + 1
		T.ok(type(knob.tiers) == "table" and #knob.tiers == 4, knob.cvar .. " needs a value for each of the built-in presets")
		for t, value in ipairs(knob.tiers) do
			-- Spread evenly from the lowest level to the highest: of 10 levels, the 1st, 4th, 7th and 10th.
			local level = math.floor((t - 1) * (#values - 1) / 3 + 0.5) + 1
			T.eq(value, values[level], knob.cvar .. ": " .. EverySetting.TIERS[t] .. " is level " .. level - 1)
			T.eq(tonumber(EverySetting.Normalize(knob, value)), value, knob.cvar .. ": " .. EverySetting.TIERS[t] .. " is a value the knob can show")
		end
	end)
	T.eq(count, 28, "the knobs a quality setting sets")
end)

T.test("knobs: the game's default is a value the knob can show", function()
	EachCVarKnob(function(knob)
		local default = client[knob.cvar:lower()][2]
		local shown = EverySetting.Normalize(knob, default)
		T.ok(shown and tonumber(shown) == tonumber(default) or shown == default,
			knob.cvar .. ": the default " .. tostring(default) .. " isn't in its range or options")
	end)
end)

T.test("knobs: a setting that isn't a CVar is one the game has, with its default among the options", function()
	local count = 0
	local K = W.Load()
	for _, command in ipairs({ "pitchLimit", "physEnable", "fontsize", "fontcolor" }) do W.AddCommand(command) end
	W.Login()
	for _, group in ipairs(K.GROUPS) do
		for _, knob in ipairs(group.items) do
			if not IsCVar(knob) then
				count = count + 1
				T.ok(knob.cvar:match("^@%l+:%w+$") or knob.cvar:match("^@console:%a+:%l+$"), knob.cvar .. ": @kind:Name")
				T.ok(not client[knob.cvar:sub(2):lower()], knob.cvar .. " is a CVar's name too")
				T.eq(knob.found, true, knob.cvar .. " is one SETTERS has, and the client too")
				T.ok(type(knob.calls) == "string", knob.cvar .. " names the game's functions for it")
				T.eq(K.Normalize(knob, knob.default), knob.default, knob.cvar .. ": the default " .. tostring(knob.default))
			end
		end
	end
	T.eq(count, 78, "settings that aren't CVars")
end)

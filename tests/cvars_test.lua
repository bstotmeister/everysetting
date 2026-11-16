-- CVars.lua: the section and suggested control for every CVar, checked against the client's
-- list on a Mac and on Windows.

local T = ...
local W = dofile("tests/wow.lua")

local EverySetting = W.Load()
local client = {} -- CVar name -> { name, default, category, help, flags }
local count = 0
for _, cvar in ipairs(W.ForeverCVars()) do
	client[cvar[1]] = cvar
	count = count + 1
end
local knobs = {} -- lower-case names of the knobs in Knobs.lua
for _, group in ipairs(EverySetting.GROUPS) do
	for _, knob in ipairs(group.items) do knobs[knob.cvar:lower()] = true end
end

local function Parts(spec)
	local parts = {}
	for part in (spec .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
	return parts
end

local RESTARTS = { gx = true, window = true, reload = true, login = true, client = true }

-- Takes a restart marker off the end of a line's parts ("gx", "client:0"), and
-- returns what a change waits for and the one value it's marked for, if any.
local function TakeRestart(parts)
	local restart, to = (parts[#parts] or ""):match("^(%l+):?([^=]*)$")
	if #parts > 1 and RESTARTS[restart] then
		parts[#parts] = nil
		return restart, to ~= "" and to or nil
	end
end

T.test("cvars: every CVar in the client, on a Mac or on Windows, is listed, and nothing else", function()
	local listed = 0
	for name in pairs(EverySetting.CVARS) do
		T.ok(client[name], name .. " isn't in the 1.60.1 client, on a Mac or on Windows")
		listed = listed + 1
	end
	T.eq(listed, count, "CVars listed")
	T.ok(count > 1700, "the client's list looks short")
end)

T.test("cvars: every entry names a section", function()
	T.ok(#EverySetting.SECTIONS >= 2, "no sections")
	for name, spec in pairs(EverySetting.CVARS) do
		local section = tonumber(Parts(spec)[1])
		T.ok(section and EverySetting.SECTIONS[section], name .. " has no section: " .. spec)
		T.eq(EverySetting.Section(name), section, name)
	end
	local used = {}
	for name in pairs(EverySetting.CVARS) do used[EverySetting.Section(name)] = true end
	for i, title in ipairs(EverySetting.SECTIONS) do T.ok(used[i], title .. " has no CVars") end
end)

-- Checks that each of `lines`' suggested controls (CVar -> its line) is well formed, and
-- takes `list`'s default for it (CVar -> its entry in that client's list).
local function WellFormed(lines, list)
	for name, spec in pairs(lines) do
		local parts = Parts(spec)
		if #parts > 1 and parts[#parts] == "x" then parts[#parts] = nil end -- the server's: a danger setting
		TakeRestart(parts)
		local kind, default = parts[2], list[name][2]
		if kind == "t" then
			T.eq(#parts, 2, name)
			T.ok(default == "0" or default == "1", name .. " is a toggle with default " .. tostring(default))
		elseif kind == "s" or kind == "S" then
			local min, max, step = tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5])
			T.ok(min and max and step and #parts == 5, name .. " needs min, max and step: " .. spec)
			T.ok(min < max and step > 0, name .. ": bad range " .. spec)
			local steps = (max - min) / step
			T.ok(math.abs(steps - math.floor(steps + 0.5)) < 1e-6, name .. ": the step doesn't land on max")
		elseif kind == "c" then
			T.ok(#parts >= 4, name .. " needs at least two options")
			local seen = {}
			for i = 3, #parts do
				local value, label = parts[i]:match("^(.-)=(.+)$")
				T.ok(value and label, name .. " has a bad option: " .. parts[i])
				T.ok(not seen[value], name .. " lists " .. value .. " twice")
				seen[value] = true
			end
		elseif kind == "f" then
			T.ok(#parts >= 3, name .. " needs a flag")
			local seen = {}
			for i = 3, #parts do
				local index, label = parts[i]:match("^(%-?%d+)=(.+)$")
				index = tonumber(index)
				T.ok(index and index ~= 0 and label, name .. " has a bad flag: " .. parts[i])
				index = math.abs(index) -- a box ticked while the flag is off
				T.ok(not seen[index], name .. " lists flag " .. index .. " twice")
				seen[index] = true
			end
			-- The client's default is packed flags (a version byte, then a byte for
			-- every six), or nothing, or 0 (no flag on: packed, or the bits of a
			-- number). Each flag it has on has a name.
			default = default or ""
			T.ok(default == "" or default == "0" or default:match("^\002[@-\127]*$"), name .. "'s default isn't packed flags")
			for index = 1, 6 * (#default - 1) do
				T.ok(seen[index] or not EverySetting.Flag(default, index), name .. " has flag " .. index .. " on by default, and no name for it")
			end
		elseif kind == "h" then
			T.eq(#parts, 2, name)
			T.ok(#default == 8 and not default:find("%X"), name .. " is a color with default " .. tostring(default))
		else
			T.ok(kind == nil, name .. " has an unknown control: " .. spec)
		end
	end
end

T.test("cvars: every suggested control is well formed", function()
	WellFormed(EverySetting.CVARS, client)
end)

T.test("cvars: knobs from Knobs.lua keep their own control", function()
	for name, spec in pairs(EverySetting.CVARS) do
		if knobs[name:lower()] then T.eq(#Parts(spec), 1, name .. " has a knob, so only its section belongs here") end
	end
end)

T.test("cvars: a raw knob can be made for every CVar", function()
	for _, cvar in ipairs(W.ForeverCVars()) do
		W.AddCVar(cvar[1], cvar[2] or "", { help = cvar[4], secure = cvar[5]:find("s") and true,
			locked = cvar[5]:find("l") and true, readOnly = cvar[5]:find("r") and true })
	end
	W.Login()
	local groups = EverySetting.AllGroups()
	local total = 0
	for _, group in ipairs(groups) do
		total = total + #group.items
		for _, knob in ipairs(group.items) do
			-- Whatever control it has must accept the game's own default.
			if knob.type ~= "text" and knob.default ~= "" and not knob.locked and knob.raw then
				T.ok(EverySetting.Normalize(knob, knob.default) ~= nil or knob.type == "choice", knob.cvar .. " can't show its default")
			end
		end
	end
	T.eq(total, count, "every CVar is in a group")
	T.eq(#groups, #EverySetting.SECTIONS)
	T.eq(EverySetting.Knob("TurnSpeed").danger, "server", "the server's, so a danger setting")
	T.eq(EverySetting.Set("TurnSpeed", "1000000", true), nil, "left alone outside danger mode")
	EverySetting.SetDanger(true)
	T.eq(EverySetting.Set("TurnSpeed", "1000000", true), "540", "in it, kept to the range the game keeps")
	EverySetting.SetDanger(false)
	-- A plain name is a raw knob's label, for a CVar the client has and Knobs.lua doesn't.
	-- One for a CVar only retail has is retail's (retail_test.lua).
	for name, label in pairs(EverySetting.NAMES) do
		if client[name] or not EverySetting.RETAIL_CVARS[name] then
			T.ok(client[name] and EverySetting.CVARS[name], name .. " is a CVar, spelled as the client spells it")
			T.ok(not knobs[name:lower()], name .. " has a knob, and a name of its own there")
			T.eq(EverySetting.RawKnob(name, "").label, label, name)
		end
	end
	T.eq(EverySetting.RawKnob("nameplateMaxDistance", "").label, "Nameplate distance")
	T.eq(EverySetting.RawKnob("nameplateMaxDistance", "").named, true, "its row has the CVar's name under it")
	T.eq(EverySetting.RawKnob("nameplateMotionSpeed", "").label, "Nameplate movement speed", "a knob from Knobs.lua")
	T.eq(EverySetting.RawKnob("nameplateOccludedAlphaMult", "").label, "nameplateOccludedAlphaMult", "the rest by the CVar's own name")
end)

T.test("cvars: the settings Blizzard's code restarts the graphics, the window or the game for are marked", function()
	local flagged = { GxApi = "gx", GxAdapter = "gx", GxMaxFrameLatency = "gx", GxCompatOptionalGpuFeatures = "gx",
		GxCompatAsyncShaderCompilation = "gx", GxCompatCommandListMultiThreading = "gx", GxCompatWorkSubmitOptimizations = "gx",
		GxMonitor = "window", GxMaximize = "window", vsync = "window", NotchedDisplayMode = "window",
		GxWindowedResolution = "window", GxFullscreenResolution = "window", physicsLevel = "client" }
	for name, restart in pairs(flagged) do T.eq(EverySetting.Knob(name).restart, restart, name) end
	T.eq(#EverySetting.Knob("GxMaxFrameLatency").options, 2, "its menu is as it was")
	-- Two marked for turning off only, both seen in game: HDR output, and the loot sparkle, whose knob has it.
	T.eq(EverySetting.Knob("HDROutput").restart, "gx")
	T.eq(EverySetting.Knob("HDROutput").restartTo, "0")
	T.eq(EverySetting.Knob("outlineModeShowLootEffectWhenDisabled").restart, "login")
	T.eq(EverySetting.Knob("outlineModeShowLootEffectWhenDisabled").restartTo, "0")
	-- A marker is read as the line has it, and one for a single value names a value the control takes.
	-- A knob from Knobs.lua has its own.
	for name, spec in pairs(EverySetting.CVARS) do
		if not knobs[name:lower()] then
			local parts = Parts(spec)
			if parts[#parts] == "x" then parts[#parts] = nil end
			local restart, to = TakeRestart(parts)
			local knob = EverySetting.Knob(name)
			T.eq(knob.restart, restart, name)
			T.eq(knob.restartTo, to, name)
			T.ok(to == nil or knob.type == "text" or EverySetting.Normalize(knob, to) == to, name .. " is marked for a value its control doesn't take: " .. tostring(to))
		end
	end
end)

T.test("cvars: every CVar the client locks or the server enforces is a danger setting, and no other", function()
	local kinds = { server = 0, locked = 0, readonly = 0 }
	for _, cvar in ipairs(W.ForeverCVars()) do
		local knob = EverySetting.Knob(cvar[1])
		local want = (EverySetting.CVARS[cvar[1]] or ""):find("|x$") and "server"
			or cvar[5]:find("l") and "locked" or cvar[5]:find("r") and "readonly" or nil
		T.eq(knob.danger, want, cvar[1])
		T.eq(knob.locked, want ~= nil, cvar[1] .. " is left alone just when it's one")
		if want then kinds[want] = kinds[want] + 1 end
	end
	T.eq(kinds.server, 1, "TurnSpeed")
	T.ok(kinds.locked > 0 and kinds.readonly > 0, "the client has some of each")
end)

T.test("cvars: the client's packed defaults read as the flags the game has on", function()
	-- The names of the flags a CVar has on by default.
	local function On(name)
		local knob, on = EverySetting.Knob(name), {}
		T.eq(knob.type, "flags", name)
		for _, flag in ipairs(knob.options) do
			if EverySetting.Flag(knob.default, flag[1]) then on[#on + 1] = flag[2] end
		end
		return table.concat(on, ", ")
	end
	T.eq(On("nameplateCastBarDisplay"), "Spell name, Spell icon, Highlight important casts, Highlight casts at you")
	T.eq(On("nameplateEnemyNpcAuraDisplay"), "Buffs, Debuffs, Crowd control")
	T.eq(On("nameplateFriendlyPlayerAuraDisplay"), "Buffs, Debuffs")
	T.eq(On("nameplateInfoDisplay"), "Rarity icon")
	T.eq(On("nameplateStackingTypes"), "", "none")
	for name, spec in pairs(EverySetting.CVARS) do
		local knob = EverySetting.Knob(name)
		if spec:find("|f|", 1, true) then
			T.ok(not knob.locked or knob.setter, name .. " is locked, and has no function of the game's to set its flags")
		end
	end
end)

-- Retail: its own lines (RETAIL_CVARS), checked against retail's list.
local RETAIL = "data/ranges/70783/retail/cvars.lua"
-- The CVars in retail's list that an addon made on the client it was saved from, not the
-- game (Details' LibOpenRaid): like any other addon's CVar, they have no line.
local ADDONS = { LibOpenRaidTempCache = true, LibOpenRaidTempCacheDebug = true }
local retailClient, retailCount = {}, 0
for _, cvar in ipairs(dofile(RETAIL).cvars) do
	retailClient[cvar[1]] = cvar
	retailCount = retailCount + 1
end

-- A logged-in retail client with every CVar of retail's list, each with its flags.
local function Retail()
	local game = W.Load(nil, nil, nil, "retail")
	for _, cvar in ipairs(dofile(RETAIL).cvars) do
		W.AddCVar(cvar[1], cvar[2] or "", { help = cvar[4], secure = cvar[5]:find("s") and true,
			locked = cvar[5]:find("l") and true, readOnly = cvar[5]:find("r") and true })
	end
	W.Login()
	return game
end

T.test("cvars: retail's own lines are for CVars retail has, and with Forever's every one of retail's CVars has a line", function()
	local only = 0
	for name, spec in pairs(EverySetting.RETAIL_CVARS) do
		T.ok(retailClient[name], name .. " isn't in the 12.1.5 client, spelled so")
		if client[name] then
			T.ok(spec ~= EverySetting.CVARS[name], name .. "'s line in retail is Forever's: it needs no line of its own")
		else
			only = only + 1
		end
	end
	local game = W.Load(nil, nil, nil, "retail")
	local without = 0
	for name in pairs(retailClient) do
		if ADDONS[name] then
			T.ok(not client[name] and not game.CVARS[name], name .. " is an addon's, and has no line")
			without = without + 1
		else
			T.ok(game.CVARS[name], name .. " has no line in retail")
			T.eq(game.CVARS[name], EverySetting.RETAIL_CVARS[name] or EverySetting.CVARS[name], name .. ": retail's line if it has one, else Forever's")
		end
	end
	T.eq(only + without, 17, "the CVars only retail has")
	T.eq(W.Load().CVARS.SSAOType, nil, "Forever has none of retail's own")
end)

T.test("cvars: retail's own lines name a section, and each suggested control is well formed for retail's defaults", function()
	local game = W.Load(nil, nil, nil, "retail")
	for name, spec in pairs(EverySetting.RETAIL_CVARS) do
		local section = tonumber(Parts(spec)[1])
		T.ok(section and game.SECTIONS[section], name .. " has no section: " .. spec)
		T.eq(game.Section(name), section, name)
	end
	local lines = {}
	for name, spec in pairs(game.CVARS) do
		if retailClient[name] then lines[name] = spec end
	end
	WellFormed(lines, retailClient)
end)

T.test("cvars: in retail a raw knob can be made for every CVar, with retail's control", function()
	local game = Retail()
	local total = 0
	for _, group in ipairs(game.AllGroups()) do
		total = total + #group.items
		for _, knob in ipairs(group.items) do
			if knob.type ~= "text" and knob.default ~= "" and not knob.locked and knob.raw then
				T.ok(game.Normalize(knob, knob.default) ~= nil or knob.type == "choice", knob.cvar .. " can't show its default")
			end
		end
	end
	T.eq(total, retailCount, "every CVar is in a group")
	-- A line of retail's own: its control, its restart, and what the client says of it.
	T.eq(game.Knob("volumeFogDisableShadows").type, "toggle")
	T.eq(game.Knob("volumeFogUse16BitTexture").restart, "gx")
	T.eq(game.Knob("cacaoBilateralSimilarityDistanceSigma").type, "text")
	T.eq(game.Knob("KioskCharacterTemplateSet").danger, "readonly")
	T.eq(game.Knob("lastLaunchedExternalEventURL").danger, "locked")
	T.eq(game.Section("activeCUFProfile"), #game.SECTIONS, "what the game remembers")
	T.eq(game.Section("LibOpenRaidTempCache"), #game.SECTIONS, "an addon's, under the last section")
	T.eq(game.Knob("LibOpenRaidTempCache").type, "text", "with a box")
	-- Retail's menu, where it isn't Forever's.
	local options = {}
	for _, option in ipairs(game.Knob("LowLatencyMode").options) do options[#options + 1] = option[1] .. "=" .. option[2] end
	T.eq(table.concat(options, " "), "0=Disabled 1=Built-in 2=NVIDIA Reflex 3=NVIDIA Reflex + Boost 4=Intel XeLL")
	T.eq(game.Knob("advFlyKeyboardMaxTurnFactor").max, 10, "a slider retail's menu has, and Forever's doesn't")
	T.eq(game.Knob("encounterTimelineEnabled").type, "toggle")
end)

T.test("cvars: a raid twin is named after the CVar it stands in for in raids, where that has a name", function()
	local game = W.Load()
	for _, cvar in ipairs(W.ForeverCVars()) do W.AddCVar(cvar[1], cvar[2] or "") end
	_G.RT_SHADOW_QUALITY = "Ray Traced Shadows" -- the game's string its menu names shadowRt by
	game.NAMES.graphicsShadowQuality = "Shadow quality" -- a name for the main CVar of a twin spelled raid…
	W.Login()
	local label = {}
	for _, name in ipairs({ "RAIDfarclip", "RAIDshadowRt", "raidGraphicsShadowQuality", "RAIDworldBaseMip", "raidFramesDisplayClassColor" }) do
		label[name] = game.RawKnob(name, "").label
	end
	local named = game.RawKnob("RAIDshadowRt", "").named
	_G.RT_SHADOW_QUALITY, game.NAMES.graphicsShadowQuality = nil, nil
	T.eq(label.RAIDfarclip, "View distance (raid)", "a tuned setting's name")
	T.eq(label.RAIDshadowRt, "Ray Traced Shadows (raid)", "the game's own name")
	T.eq(named, true, "its row has the CVar's name under it")
	T.eq(label.raidGraphicsShadowQuality, "Shadow quality (raid)", "raid in any case")
	T.eq(label.RAIDworldBaseMip, "RAIDworldBaseMip", "worldBaseMip has no name, so neither has its twin")
	T.ok(not label.raidFramesDisplayClassColor:find("%(raid%)"), "raidFrames... is no twin: there's no FramesDisplayClassColor")
end)

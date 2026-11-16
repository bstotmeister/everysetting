-- Every Setting: one window for the game's console variables (CVars), each with its
-- real range and options, in WoW Forever and in retail.
--
-- How it works
--   Knobs.lua lists the CVars worth tuning (EverySetting.GROUPS), each with the range
--   or options the game accepts. The game has no API for a CVar's range, so
--   every range in that list comes from Blizzard's settings code, the CVar's
--   help text, a runtime function, or setting it in game and reading back what
--   the engine kept (/every probe).
--
--   The same files run in both clients (EverySetting.Client). Where retail's
--   engine keeps another range, a knob has that one too, and retail uses it. A
--   tuned CVar a client lacks gets no row there.
--
--   Set() clamps a value to the knob's range, sets the CVar, reads it back and
--   remembers what the engine kept. Where the range is the game's own quality
--   levels and not a limit of the engine's, a value typed in the knob's box can
--   go past it. Remembered values are set again at every
--   login, because the game's graphics presets overwrite raw CVars, and with
--   Apply now. Only values set through Every Setting are remembered, so it never
--   touches anything else.
--
--   Reset() puts back the value the CVar had before Every Setting changed it, not the
--   engine's default: the graphics presets set most raw CVars well away from
--   their defaults (view distance is 10000 at the top preset, 1000 by default).
--
--   Secure CVars can't be set in combat: those wait until combat ends.
--
--   Some of the game's settings aren't CVars (the modified clicks, the turn and
--   strafe keys, the action bars, item quality colours, social options, minimap
--   tracking and the combat audio alerts kept for each specialisation). Each has
--   a name of its own and the game's functions to read and write it (SETTERS),
--   and is kept, set again at login, undone and reset like a CVar.
--
--   Hooks on the game's CVar functions note what last changed each CVar (another
--   addon, the game...), for the tooltip, and a line in chat says when another
--   addon changes one Every Setting keeps.
--
--   The values Every Setting keeps are a profile. Profiles are shared by every
--   character on the account, and each character remembers which one it uses.
--   A profile can be shared as a line of text, or as /console lines. Import
--   takes those lines from any guide too, and never runs what's pasted. Each
--   change this session can be undone and redone.
--
--   A preset is part of a profile under a name: a few CVars' values, which
--   are added to whichever profile is in use and leave the rest of it alone.
--   A style (Styles.lua) is a built-in preset that spans sections. Styles and
--   presets leave a locked setting alone.
--
--   A danger setting is one the game's server enforces, or the client says is
--   locked or read-only. Every Setting leaves those alone unless danger mode is
--   on, and then they change by hand only.
--
--   A situation (in combat, mounted...) uses a preset while it's on, without
--   changing the profile: each CVar goes back when it ends.
--
--   The window can also list every CVar the client has. Those that aren't in
--   Knobs.lua get a "raw" knob: CVars.lua may suggest a slider, menu,
--   checkbox, menu of flags or color swatch for it, but its box takes any value.

local ADDON, ns = ...
local L = ns.L

local EverySetting = {}
ns.EverySetting = EverySetting
_G.EverySetting = EverySetting

local PREFIX = "|cffffb000" .. L.ADDON_NAME .. "|r: "
function EverySetting.Print(msg, ...)
	if select("#", ...) > 0 then msg = msg:format(...) end
	DEFAULT_CHAT_FRAME:AddMessage(PREFIX .. msg)
end
local Print = EverySetting.Print

-------------------------------------------------------------------------------
-- Knobs
-------------------------------------------------------------------------------

-- The window's list, filled in by Knobs.lua: { title = "Shadows", items = { knob, ... } }
-- per group. A knob:
--   cvar     the CVar's name, or the name of a setting that isn't a CVar, which
--            starts with "@" (see SETTERS)
--   label    what the window calls it
--   tip      a sentence on what it does
--   type     "slider", "toggle" (0 or 1) or "choice". A raw knob can also be "text"
--            (just a box), "flags" (its CVar packs a set of on/off flags: see Flags)
--            or "color" (eight hex digits: alpha, red, green, blue)
--   min, max, step   a slider's range
--   bounds   (optional) a function returning min, max, for a range the client
--            works out at runtime
--   options  a choice's values in order, each { value, "Label" }; or a flags
--            knob's flags, each { index, "Label" }
--   list     (optional) a function returning a choice's options as the game has
--            them now (see SETTERS and EverySetting.Options)
--   src      where the range or options come from: "ui" (Blizzard's settings
--            code), "help" (the CVar's help text), "api" (a runtime function),
--            "probe" (set in game: what the engine kept, and what it said) or
--            "preset" (the values the game's own quality presets set: the engine
--            keeps any number, so the knob's box takes one past the range)
--   raid     (optional) the CVar used instead in raids, which is set to the same value
--   with     (optional) for a toggle: other settings it only shows with, { cvar = value }.
--            Turning it on sets and keeps them too; turning it off or resetting it puts
--            them back as they were. One change for Undo.
--   tiers    (optional) the values the built-in presets give it, one for each
--            of EverySetting.TIERS: levels of the game's quality setting that sets it
--   restart  (optional) what a change needs before it shows: "gx" (a graphics
--            restart), "window" (an update of the game's window), "reload" (a
--            reload of the interface), "login" (logging out and in again) or
--            "client" (a game restart). A raw knob's is the marker on its line in
--            CVars.lua.
--   restartTo   (optional) the one value a change to needs it: "0" for a setting
--            that turns on at once and off only with the restart
--   restartSrc  the evidence for it, in a knob from Knobs.lua: "ui", "probe" or
--            "guide" (see CVars.lua, which notes a raw knob's on its line)
--   cost     (optional) how much frame rate turning it up costs: "light",
--            "medium" or "heavy" (see Knobs.lua)
--   costSrc  the evidence for it: "probe" (measured in the client) or "guide"
--   retail   (optional) the fields that differ in retail, where its engine keeps
--            another range: { max = 2.6, src = "probe" }. They take the place of
--            the knob's own there, once the CVars are read.
--   raw      made by RawKnob for the list of every CVar: its range or options
--            are a suggestion, and its box takes any value
--   named    (optional) made by RawKnob for a CVar this game's options menu has
--            (Labels.lua): its label is the game's name for it, not the CVar's
-- Read from the client once it has loaded its CVars:
--   found    the client has this CVar
--   default  its default value
--   secure   it can't be set in combat
--   locked   it's a danger setting: left alone, unless danger mode is on (see Danger mode)
--   danger   what kind: "server" (the game's server enforces it: an "x" in
--            CVars.lua), "locked" or "readonly" (the client says so). nil for the rest.
--   setter   true for a locked one the game has a function of its own for (SETTERS)
--   storage  where the game saves it: "account" or "character" (on Blizzard's
--            servers), "computer" (in Config.wtf), "bindings" (with the key bindings),
--            "server" (on Blizzard's servers, the game doesn't say whose) or "session"
--            (a console command the game isn't known to save)
--   calls    for a setting that isn't a CVar: the game's functions for it, as the
--            tooltip names them. nil for a CVar.
--   unread   true for a console command the game can't be asked the value of
EverySetting.GROUPS = {}

local BY_CVAR = {} -- lower-case CVar name -> knob (CVar names ignore case)

-- Which game this is: "retail", the modern game, or "forever", WoW Forever. Retail
-- is the mainline project. Forever has one of its own, WOW_PROJECT_CAMELOT, which
-- retail doesn't define (seen in 12.1.5).
function EverySetting.Client()
	return WOW_PROJECT_ID ~= nil and WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and "retail" or "forever"
end

function EverySetting.Knob(cvar)
	return type(cvar) == "string" and BY_CVAR[cvar:lower()] or nil
end

-- The game's own function for a setting it locks, where it has one. The game
-- turns down a change to the CVar itself, so a danger setting with one is set
-- through it: found in game for the voice chat settings. Each is the function,
-- _G[table][name], and maybe:
--   args  what the function takes for a value of the CVar's, a string: a list
--         of arguments, or nil for a value it can't take. Without it the
--         function takes the value as one number.
--   list  a menu's options for the knob, { value, "Label" } each, for a setting
--         whose options the game only knows as it runs
--   late  true where the game changes the CVar a moment after the call, not
--         during it (see Sent)
--   bits  true for a flags knob whose CVar holds its flags as the bits of a
--         number (see Flag), not packed as text
--   command  (optional) command(value, knob): the line of Lua for a value, where
--         the arguments written out would be too long to type. Needed with `put`.
--   put   (optional) put(value, current, knob): for a setting the game changes a
--         part at a time (a flag, or an entry of a list), makes a call for each
--         part that differs between `current`, the CVar's value now, and `value`.
--         The function named is then only what the client must have. Used only
--         where the CVar has a knob.
--   zero  (optional) what the game means by "0", the CVar's default: the flags it
--         has on until something is changed. The CVar is read as this while it's 0.
--   ids   (optional) for a list (see List): returns the entries the game has now.
--         The CVar is read as those, not as its own text.
--   A global function is _G[name]: { "_G", "SetPVPRoles" }.
--
-- A setting that isn't a CVar has a name of its own, which starts with "@" (no
-- CVar's does), so a profile or a shared string can't mistake it for one. Its
-- entry here says how the game reads and writes it:
--   get      returns its value as text. The client lacks the setting if it errors.
--   set      sets it to a value, a string, as the game's own options do
--   command  the line to type in chat that does the same, as EverySetting.Command
--            gives it: a /run line, or a /console one for a console command
--   default  the game's default, or a function that returns it
--   section  the index in EverySetting.SECTIONS of the section it's listed under,
--            or "commands" for the window's Console commands, after them
--   storage, calls   what a knob has (see above). "server" is a storage of its own
--            here: the game's server keeps it, for the account or the character
--   late     as above: the game reads back the old value for a moment after a change
-- The game sends no CVAR_UPDATE for one, so the window reads it again each time
-- it opens or refreshes, and when a console command's runs (see ConsoleExec
-- below). It's set out of combat only, as a secure CVar is, and situations leave
-- it alone.

-- The push-to-talk key: the CVar has the keys' names with a tab between them
-- ("LCTRL\tLSHIFT"), and the game's custom binding code takes them as a list.
local function Keys(value)
	local keys = {}
	for key in value:gmatch("%S+") do keys[#keys + 1] = key end
	return { keys }
end

-- The voice chat devices the game offers now (`list` names the function that
-- gives them): a menu's options, and the argument for a value. The system's
-- own device has an ID to be set by, and the CVar is empty while it's in use.
local function Devices(list)
	local function Offered()
		local get = _G.C_VoiceChat and _G.C_VoiceChat[list]
		return get and get() or {}
	end
	local function Options()
		local options = {}
		for _, device in ipairs(Offered()) do
			options[#options + 1] = { device.isSystemDefault and "" or device.deviceID, device.displayName }
		end
		return options
	end
	local function Args(value)
		if value ~= "" then return { value } end
		for _, device in ipairs(Offered()) do
			if device.isSystemDefault then return { device.deviceID } end
		end
	end
	return Options, Args
end
local inputs, input = Devices("GetAvailableInputDevices")
local outputs, output = Devices("GetAvailableOutputDevices")

-- The group finder's roles: the CVar holds a bit for each (see Flag), and the
-- game's function takes true or false for each. `...` are the roles' flags, in
-- the order the function takes them.
local function Roles(...)
	local flags = { ... }
	return function(value)
		if not tonumber(value) then return nil end
		local args = {}
		for i, flag in ipairs(flags) do args[i] = EverySetting.Flag(value, flag) end
		return args
	end
end

-- The pet journal's sort: the CVar counts the game's four from 0, and its
-- function from 1.
local function PetSort(value)
	return tonumber(value) and { tonumber(value) + 1 }
end

-- A checkbox the game's function takes as true or false.
local function Shown(value)
	return { tonumber(value) == 1 }
end

-- The group finder's advanced filter: one table, which the game keeps in three
-- CVars and saves whole. A change sets one part of the table the game has now.
-- Its true or false fields are lfgListAdvancedFilters' flags, in the table's order.
local FILTERS = { "needsTank", "needsHealer", "needsDamage", "needsMyClass", "hasTank", "hasHealer",
	"difficultyNormal", "difficultyHeroic", "difficultyMythic", "difficultyMythicPlus",
	"generalPlaystyle1", "generalPlaystyle2", "generalPlaystyle3", "generalPlaystyle4" }
local function AdvancedFilter()
	local api = _G.C_LFGList
	return api and api.GetAdvancedFilter and api.GetAdvancedFilter()
end
local function Filters(value)
	local options = AdvancedFilter()
	if not options then return nil end
	for i, field in ipairs(FILTERS) do options[field] = EverySetting.Flag(value, i) end
	return { options }
end
local function MinRating(value)
	local options = AdvancedFilter()
	if not (options and tonumber(value)) then return nil end
	options.minimumRating = tonumber(value)
	return { options }
end

-- The commands for them: the table from the game, changed and saved.
local FILTER_COMMAND = "/run local f=C_LFGList.GetAdvancedFilter() %s C_LFGList.SaveAdvancedFilter(f)"
local function FiltersCommand(value)
	local set = { "for k,v in pairs(f) do f[k]=v~=true and v end" } -- every flag off
	for i, field in ipairs(FILTERS) do
		if EverySetting.Flag(value, i) then set[#set + 1] = "f." .. field .. "=true" end
	end
	return FILTER_COMMAND:format(table.concat(set, " "))
end
local function MinRatingCommand(value)
	return FILTER_COMMAND:format("f.minimumRating=" .. tonumber(value))
end

-- A flags knob the game sets one flag at a time (the journals' filters, guild news):
-- api[name](index, ticked), where `index` is the game's for the flag (`how.index`
-- maps a flag to it, where they differ), and `ticked` whether the flag's box in the
-- knob's menu is ticked (a box can stand for a flag that's off: see Flag). Or
-- api[names[flag]](ticked), with a function of its own for each flag. With
-- `how.number`, ticked goes in as 1 or 0. `how.bits` and `how.zero` are the entry's
-- (see above). A change makes a call for each flag of the menu that differs; the
-- command, one for each.
local function PerFlag(api, name, how)
	local function Calls(value, current, knob)
		local calls = {}
		for _, option in ipairs(knob and knob.options or {}) do
			local ticked = EverySetting.Flag(value, option[1])
			if current == nil or ticked ~= EverySetting.Flag(current, option[1]) then
				local flag, arg = math.abs(option[1]), ticked
				if how.number then arg = ticked and 1 or 0 end
				if how.names then
					calls[#calls + 1] = { how.names[flag], { arg } }
				else
					calls[#calls + 1] = { name, { how.index and how.index[flag] or flag, arg } }
				end
			end
		end
		return calls
	end
	return { api, how.names and how.names[1] or name, bits = how.bits, zero = how.zero,
		put = function(value, current, knob)
			for _, call in ipairs(Calls(value, current, knob)) do _G[api][call[1]](unpack(call[2])) end
		end,
		-- The function once in a local, to keep the line short enough for chat.
		command = function(value, knob)
			local line = { how.names and "local t=" .. api or "local f=" .. (api == "_G" and "" or api .. ".") .. name }
			for _, call in ipairs(Calls(value, nil, knob)) do
				for i, arg in ipairs(call[2]) do call[2][i] = tostring(arg) end
				line[#line + 1] = (how.names and "t." .. call[1] or "f") .. "(" .. table.concat(call[2], ",") .. ")"
			end
			return "/run " .. table.concat(line, " ")
		end,
	}
end

-- A list's entries, from its text: IDs (or names) with spaces or commas between,
-- each once, numbers in order and then names. "783, 26" is { 26, 783 }.
local function Entries(text)
	local list, seen = {}, {}
	for entry in tostring(text or ""):gmatch("[^%s,]+") do
		if not seen[entry] then
			seen[entry] = true
			list[#list + 1] = entry:match("^%-?%d+$") and tonumber(entry) or entry
		end
	end
	table.sort(list, function(a, b)
		if type(a) == type(b) then return a < b end
		return type(a) == "number"
	end)
	return list
end

-- The same as text: "26 783".
local function EntriesText(list)
	local parts = {}
	for i, entry in ipairs(Entries(table.concat(list, " "))) do parts[i] = tostring(entry) end
	return table.concat(parts, " ")
end

-- A list as the game writes it in a CVar: "v21", then four characters for each
-- entry, its digits in base 93 counted from "#" ("###$" is 1, "##&)" is 285).
-- Seen in game for the tutorials, the recipes and the advanced filter's dungeons.
local function Decode(text)
	local list = {}
	for entry in tostring(text or ""):sub(4):gmatch("....") do
		local n = 0
		for i = 1, 4 do n = n * 93 + entry:byte(i) - 35 end
		list[#list + 1] = n
	end
	return list
end

-- A list the game changes an entry at a time (what's tracked, and the like). Every
-- Setting reads it as the game's own getter has it, `how.ids()`, not as the CVar's
-- text, which for some the game writes only at a reload or logout: its entries with
-- a space between, in order ("26 783"), and its box takes them so. A change calls
-- `how.remove(entry)` for each entry the game has that the value hasn't, then
-- `how.add(entry)` for each the other way. Where nothing takes one entry off,
-- `how.clear()` takes them all off first, and the value's are added again. The
-- command takes every entry off and adds the value's: `how.line` is its Lua,
-- { head, clear, add }, with `add` a format for one entry ("f(%s)").
local function List(api, name, how)
	return { api, name, ids = how.ids,
		put = function(value, current)
			local want, have, gone = {}, {}, false
			for _, entry in ipairs(Entries(value)) do want[entry] = true end
			for _, entry in ipairs(Entries(current)) do
				have[entry] = true
				if not want[entry] then
					gone = true
					if how.remove then how.remove(entry) end
				end
			end
			if gone and how.clear then
				how.clear()
				have = {}
			end
			for _, entry in ipairs(Entries(value)) do
				if not have[entry] then how.add(entry) end
			end
		end,
		command = function(value)
			local line = { "/run", how.line[1], how.line[2] }
			for _, entry in ipairs(Entries(value)) do line[#line + 1] = how.line[3]:format(tostring(entry)) end
			return table.concat(line, " ")
		end,
	}
end

-- The recipes tracked, or the recrafts: by the game's getter, which changes at
-- once, where the CVar changes at the next reload (seen in game). A recipe the
-- character doesn't know is tracked too.
local function Recipes(recraft)
	local r = tostring(recraft)
	return List("C_TradeSkillUI", "SetRecipeTracked", {
		ids = function() return _G.C_TradeSkillUI.GetRecipesTracked(recraft) end,
		add = function(id) _G.C_TradeSkillUI.SetRecipeTracked(id, true, recraft) end,
		remove = function(id) _G.C_TradeSkillUI.SetRecipeTracked(id, false, recraft) end,
		line = { "local t=C_TradeSkillUI", "for _,i in ipairs(t.GetRecipesTracked(" .. r .. ")) do t.SetRecipeTracked(i,false," .. r .. ") end",
			"t.SetRecipeTracked(%s,true," .. r .. ")" },
	})
end

-- The search languages ticked in the group finder, by name ("esMX"): the game
-- saves them whole, as a table of the ones ticked, and keeps them as the bits of a
-- number (esMX alone is 128, seen in game).
local function Languages(value)
	local enabled = {}
	for _, lang in ipairs(Entries(value)) do enabled[tostring(lang)] = true end
	return enabled
end

-- The advanced filter's dungeons left out, by activity group (the CVar, as the game
-- writes it when the filter is saved: see Decode). The filter's table has the ones
-- ticked, `activities`: a change ticks each that comes off the list and unticks each
-- that goes on, and saves it.
local REMOVED = "lfgListAdvancedFilterRemovedActivities"
local function Removed() return Decode(C_CVar.GetCVar(REMOVED)) end
local function Ticked(ticked, value, current)
	local out, drop, keep = {}, {}, {}
	for _, id in ipairs(Entries(value)) do drop[id] = true end
	for _, id in ipairs(Entries(current)) do keep[id] = not drop[id] or nil end
	for _, id in ipairs(ticked or {}) do
		if not drop[id] then keep[id] = true end
	end
	for id in pairs(keep) do out[#out + 1] = id end
	table.sort(out)
	return out
end

-- The dungeons ticked in the dungeon finder: a flag for each, by its ID counted
-- from 0, packed as text (see Flag). Dungeon 5 is "\002`", flag 6 (seen in game).
local DUNGEONS = "lfdSelectedDungeons"
local function Dungeons()
	local list, value = {}, C_CVar.GetCVar(DUNGEONS) or ""
	for id = 0, (#value - 1) * 6 - 1 do
		if EverySetting.Flag(value, id + 1) then list[#list + 1] = id end
	end
	return list
end

local SETTERS = {
	-- The tutorials the game has shown, by ID: by the game's getter, as the recipes are.
	-- FlagTutorial adds one, and ResetTutorials takes them all off: nothing takes one off.
	flaggedTutorials = List("_G", "FlagTutorial", {
		ids = function()
			local list = {}
			for id = 1, 300 do
				if _G.IsTutorialFlagged(id) then list[#list + 1] = id end
			end
			return list
		end,
		add = function(id) _G.FlagTutorial(id) end,
		clear = function() _G.ResetTutorials() end,
		line = { "local f=FlagTutorial", "ResetTutorials()", "f(%s)" },
	}),
	guildNewsFilter = PerFlag("_G", "SetGuildNewsFilter", { number = true, bits = true }),
	-- The quests watched by hand (watch type 1, Manual), as the game's getters have them: the CVar
	-- changes at the next reload, as the recipes' does. AddQuestWatch watches one by hand (a quest
	-- just accepted is watched so too, seen in game), and RemoveQuestWatch takes a watch off.
	hardTrackedQuests = List("C_QuestLog", "AddQuestWatch", {
		ids = function()
			local api, list = _G.C_QuestLog, {}
			for i = 1, api.GetNumQuestWatches() do
				local id = api.GetQuestIDForQuestWatchIndex(i)
				if id and api.GetQuestWatchType(id) == 1 then list[#list + 1] = id end
			end
			return list
		end,
		add = function(id) _G.C_QuestLog.AddQuestWatch(id) end,
		remove = function(id) _G.C_QuestLog.RemoveQuestWatch(id) end,
		line = { "local q=C_QuestLog", "for i=q.GetNumQuestWatches(),1,-1 do local d=q.GetQuestIDForQuestWatchIndex(i)"
			.. " if q.GetQuestWatchType(d)==1 then q.RemoveQuestWatch(d) end end", "q.AddQuestWatch(%s)" },
	}),
	heirloomCollectedFilters = PerFlag("C_Heirloom", nil, { names = { "SetCollectedHeirloomFilter", "SetUncollectedHeirloomFilter" } }),
	heirloomSourceFilters = PerFlag("C_Heirloom", "SetHeirloomSourceFilter", {}),
	lfdSelectedDungeons = List("_G", "SetLFGDungeonEnabled", {
		ids = Dungeons,
		add = function(id) _G.SetLFGDungeonEnabled(id, true) end,
		remove = function(id) _G.SetLFGDungeonEnabled(id, false) end,
		line = { 'local f,v=SetLFGDungeonEnabled,C_CVar.GetCVar("' .. DUNGEONS .. '")',
			"for b=2,#v do for k=0,5 do if math.floor(v:byte(b)/2^k)%2>0 then f((b-2)*6+k,false) end end end", "f(%s,true)" },
	}),
	[REMOVED] = { "C_LFGList", "SaveAdvancedFilter", ids = Removed,
		put = function(value, current)
			local options = AdvancedFilter()
			options.activities = Ticked(options.activities, value, current)
			_G.C_LFGList.SaveAdvancedFilter(options)
		end,
		command = function(value)
			return FILTER_COMMAND:format("f.activities={" .. table.concat(Ticked(AdvancedFilter().activities, value, EntriesText(Removed())), ",") .. "}")
		end,
	},
	lfgListAdvancedFilterMinRating = { "C_LFGList", "SaveAdvancedFilter", args = MinRating, command = MinRatingCommand },
	lfgListAdvancedFilters = { "C_LFGList", "SaveAdvancedFilter", args = Filters, command = FiltersCommand },
	lfgListSearchLanguages = { "C_LFGList", "SaveLanguageSearchFilter",
		ids = function()
			local list = {}
			for lang, on in pairs(_G.C_LFGList.GetLanguageSearchFilter()) do
				if on then list[#list + 1] = lang end
			end
			return list
		end,
		put = function(value) _G.C_LFGList.SaveLanguageSearchFilter(Languages(value)) end,
		command = function(value)
			local set = {}
			for _, lang in ipairs(Entries(value)) do set[#set + 1] = tostring(lang) .. "=true" end
			return "/run C_LFGList.SaveLanguageSearchFilter({" .. table.concat(set, ",") .. "})"
		end,
	},
	lfgSelectedRoles = { "_G", "SetLFGRoles", args = Roles(1, 2, 3, 4), bits = true }, -- leader, tank, healer, damage
	-- The mount journal's: a bit for each filter that's ticked. 0 is its defaults: collected only, the
	-- two sources this client has, and every type.
	mountJournalGeneralFilters = PerFlag("C_MountJournal", "SetCollectedFilterSetting", { bits = true, zero = "1" }),
	mountJournalSourcesFilter = PerFlag("C_MountJournal", "SetSourceFilter", { bits = true, zero = "260" }),
	mountJournalTypeFilter = PerFlag("C_MountJournal", "SetTypeFilter", { bits = true, zero = "31" }),
	petJournalFilters = PerFlag("C_PetJournal", "SetFilterChecked", { zero = "\002B" }), -- 0: not collected hidden
	petJournalSort = { "C_PetJournal", "SetPetSortParameter", args = PetSort },
	-- A bit for each that's ticked, and 0 while they all are.
	petJournalSourceFilters = PerFlag("C_PetJournal", "SetPetSourceChecked", { bits = true, zero = "4095" }),
	petJournalTypeFilters = PerFlag("C_PetJournal", "SetPetTypeFilter", { bits = true, zero = "1023" }),
	pvpSelectedRoles = { "_G", "SetPVPRoles", args = Roles(2, 3, 4), bits = true }, -- tank, healer, damage
	toyBoxCollectedFilters = PerFlag("C_ToyBox", nil, { names = { "SetCollectedShown", "SetUncollectedShown", "SetUnusableShown" } }),
	toyBoxExpansionFilters = PerFlag("C_ToyBox", "SetExpansionTypeFilter", {}),
	toyBoxSourceFilters = PerFlag("C_ToyBox", "SetSourceTypeFilter", {}),
	trackedProfessionRecipes = Recipes(false),
	trackedProfessionRecraftRecipes = Recipes(true),
	transmogrifySetsFilters = PerFlag("C_TransmogSets", "SetSetsFilter", {}),
	VoiceCommunicationMode = { "C_VoiceChat", "SetCommunicationMode" },
	VoiceInputDevice = { "C_VoiceChat", "SetInputDevice", args = input, list = inputs, late = true },
	VoiceInputVolume = { "C_VoiceChat", "SetInputVolume" },
	VoiceOutputDevice = { "C_VoiceChat", "SetOutputDevice", args = output, list = outputs, late = true },
	VoiceOutputVolume = { "C_VoiceChat", "SetOutputVolume" },
	VoicePushToTalkKeybind = { "C_VoiceChat", "SetPushToTalkBinding", args = Keys },
	VoiceVADSensitivity = { "C_VoiceChat", "SetVADSensitivity" },
	wardrobeSetsFilters = PerFlag("C_TransmogSets", "SetBaseSetsFilter", {}),
	wardrobeShowCollected = { "C_TransmogCollection", "SetCollectedShown", args = Shown },
	wardrobeShowUncollected = { "C_TransmogCollection", "SetUncollectedShown", args = Shown },
	-- The game numbers its six sources 1 to 6, and keeps them as flags 2 to 5, 8 and 9 (seen in game).
	wardrobeSourceFilters = PerFlag("C_TransmogCollection", "SetSourceTypeFilter",
		{ index = { [2] = 1, [3] = 2, [4] = 3, [5] = 4, [8] = 5, [9] = 6 } }),
}

-- The modified clicks: the key held, or the key and the mouse button, that
-- changes what a click does. The game keeps them with its key bindings, and
-- saves them as its own options do. Each default is Bindings_Camelot.xml's.
local CLICKS = {
	SELFCAST = "ALT", EXPANDTOOLTIP = "SHIFT", FOCUSCAST = "NONE", MOUSEOVERCAST = "NONE", AUTOLOOTTOGGLE = "SHIFT",
	MAILAUTOLOOTTOGGLE = "SHIFT", STICKYCAMERA = "CTRL", CHATLINK = "SHIFT-BUTTON1", DRESSUP = "CTRL-BUTTON1",
	EXPANDITEM = "SHIFT-BUTTON2", SPLITSTACK = "SHIFT", PICKUPACTION = "SHIFT", PICKUPITEM = "SHIFT", COMPAREITEMS = "SHIFT",
	OPENALLBAGS = "SHIFT", QUESTWATCHTOGGLE = "SHIFT", RECIPEWATCHTOGGLE = "SHIFT", TOKENWATCHTOGGLE = "SHIFT",
	SHOWITEMFLYOUT = "ALT", SHOWMULTICASTFLYOUT = "ALT",
}
for action, default in pairs(CLICKS) do
	SETTERS["@click:" .. action] = {
		get = function() return GetModifiedClick(action) end,
		set = function(value)
			SetModifiedClick(action, value)
			SaveBindings(GetCurrentBindingSet())
		end,
		command = function(value) return ('/run SetModifiedClick("%s", "%s") SaveBindings(GetCurrentBindingSet())'):format(action, value) end,
		default = default, section = 11, storage = "bindings", calls = L.CALLS_TWO:format("GetModifiedClick", "SetModifiedClick"),
	}
end

-- The turn and strafe keys: the game's two sets of movement key bindings,
-- Enhanced (Enum.TurnStrafeStyle.Modern, 0) and Classic (Legacy, 1), which its
-- Preset options set with a button each and then save. Movement keys changed by
-- hand read as Custom (2), which the game can't set back: those are left alone.
SETTERS["@keys:TurnStrafe"] = {
	get = function() return C_KeyBindings.GetTurnStrafeStyle() end,
	set = function(value)
		if C_KeyBindings.GetTurnStrafeStyle() == Enum.TurnStrafeStyle.Custom then return end
		C_KeyBindings.SetTurnStrafeStyle(tonumber(value))
		SaveBindings(GetCurrentBindingSet())
	end,
	-- Custom (2) is left alone here too.
	command = function(value)
		return ("/run local k=C_KeyBindings if k.GetTurnStrafeStyle()~=2 then k.SetTurnStrafeStyle(%s) SaveBindings(GetCurrentBindingSet()) end")
			:format(tonumber(value) or ("%q"):format(tostring(value)))
	end,
	default = "0", section = 11, storage = "bindings", calls = L.CALLS_TWO:format("C_KeyBindings.GetTurnStrafeStyle", "SetTurnStrafeStyle"),
}

-- On or off, as "1" or "0", read and written by a pair of the game's functions.
-- `run` is the command's line, with %s for true or false.
local function Switch(get, set, run, entry)
	entry.get = function() return get() and "1" or "0" end
	entry.set = function(value) set(value == "1") end
	entry.command = function(value) return run:format(tostring(value == "1")) end
	return entry
end

-- Action bars 2 to 8. The game sets all seven at once: a change keeps the other
-- six as they are. It shows or hides a bar at the next reload, when the game
-- lays its bars out (its own options lay them out again at once, from code an
-- addon would taint).
for n = 2, 8 do
	SETTERS["@bar:" .. n] = Switch(function() return (select(n - 1, GetActionBarToggles())) end, function(on)
		local bars = { GetActionBarToggles() }
		bars[n - 1] = on
		SetActionBarToggles(unpack(bars, 1, 7))
	end, "/run local t={GetActionBarToggles()} t[" .. (n - 1) .. "]=%s SetActionBarToggles(unpack(t,1,7))", { default = "0", section = 9, storage = "character", calls = L.CALLS_TWO:format("GetActionBarToggles", "SetActionBarToggles") })
end

-- The item quality colours, Poor to Legendary (Enum.ColorOverride 0 to 5, the
-- qualities' own numbers), as eight hex digits. One the player hasn't picked is
-- the game's own, and picking that removes the override. The game's chat and
-- tooltips show a change at once; its tables of colours, which bags and the like
-- read, are filled again at the next reload (its own options fill them at once,
-- from code an addon would taint).
for n, quality in ipairs({ "Poor", "Common", "Uncommon", "Rare", "Epic", "Legendary" }) do
	local override = n - 1
	local function Default() return C_ColorOverrides.GetDefaultColorForQuality(override):GenerateHexColor():upper() end
	SETTERS["@color:" .. quality] = {
		get = function()
			local info = C_ColorOverrides.GetColorOverrideInfo(override)
			return info and info.overrideColor:GenerateHexColor():upper() or Default()
		end,
		set = function(value)
			if value:upper() == Default() then
				C_ColorOverrides.RemoveColorOverride(override)
			else
				C_ColorOverrides.SetColorOverride(override, CreateColorFromHexString(value))
			end
		end,
		command = function(value)
			value = tostring(value):upper()
			if #value == 6 then value = "FF" .. value end
			local ok, default = pcall(Default)
			if ok and value == default then return ("/run C_ColorOverrides.RemoveColorOverride(%d)"):format(override) end
			return ('/run C_ColorOverrides.SetColorOverride(%d, CreateColorFromHexString("%s"))'):format(override, value)
		end,
		default = Default, section = 13, storage = "account",
		calls = L.CALLS_THREE:format("C_ColorOverrides.GetColorOverrideInfo", "SetColorOverride", "RemoveColorOverride"),
	}
end

-- Account and social options, which the game's server keeps. Two read back as
-- they were for a moment after a change (seen: half a second, and two).
SETTERS["@social:BlockGuildInvites"] = Switch(function() return GetAutoDeclineGuildInvites() end,
	function(on) SetAutoDeclineGuildInvites(on) end, "/run SetAutoDeclineGuildInvites(%s)",
	{ default = "0", late = true, section = 6, storage = "server", calls = L.CALLS_TWO:format("GetAutoDeclineGuildInvites", "SetAutoDeclineGuildInvites") })
SETTERS["@social:RecentAlliesSeeLocation"] = Switch(function() return GetAllowRecentAlliesSeeLocation() end,
	function(on) SetAllowRecentAlliesSeeLocation(on) end, "/run SetAllowRecentAlliesSeeLocation(%s)",
	{ default = "1", late = true, section = 6, storage = "server", calls = L.CALLS_TWO:format("GetAllowRecentAlliesSeeLocation", "SetAllowRecentAlliesSeeLocation") })
-- As the game's own options turn chat off or on: its chat settings and
-- communities follow (ChatConfigFrame_OnChatDisabledChanged).
SETTERS["@social:DisableChat"] = Switch(function() return C_SocialRestrictions.IsChatDisabled() end, function(on)
	C_SocialRestrictions.SetChatDisabled(on)
	if ChatConfigFrame_OnChatDisabledChanged then ChatConfigFrame_OnChatDisabledChanged(on) end
end, "/run local on=%s C_SocialRestrictions.SetChatDisabled(on) if ChatConfigFrame_OnChatDisabledChanged then ChatConfigFrame_OnChatDisabledChanged(on) end",
	{ default = "0", section = 6, storage = "account", calls = L.CALLS_TWO:format("C_SocialRestrictions.IsChatDisabled", "SetChatDisabled") })

-- The minimap's tracking, by its filter's name in Enum.MinimapTrackingFilter. The
-- game numbers what it offers from 1, in an order of its own. A filter it doesn't
-- offer isn't there. The defaults are the CVar minimapTrackedInfov4's, which
-- keeps them for each character.
local function Tracking(filter)
	local id = Enum.MinimapTrackingFilter[filter]
	for i = 1, C_Minimap.GetNumTrackingTypes() do
		local info = C_Minimap.GetTrackingFilter(i)
		if info and info.filterID == id then return i end
	end
end
local TRACKED = { TaxiNode = true, Innkeeper = true, QuestPOIs = true, AccountCompletedQuests = true }
for _, filter in ipairs({ "Auctioneer", "Banker", "AccountBanker", "Barber", "Battlemaster", "TaxiNode", "VenderFood",
	"VendorAmmo", "Innkeeper", "ItemUpgrade", "Mailbox", "TrainerClass", "TrainerProfession", "VendorReagent", "Repair",
	"Stablemaster", "Transmogrifier", "TrivialQuests", "AccountCompletedQuests", "POI", "Target", "Focus", "QuestPOIs",
	"Digsites" }) do
	SETTERS["@track:" .. filter] = Switch(function() return C_Minimap.GetTrackingInfo(assert(Tracking(filter))).active end,
		function(on)
			local i = Tracking(filter)
			if i then C_Minimap.SetTracking(i, on) end
		end,
		-- The command finds the filter as `set` does, so it holds wherever the game lists it.
		"/run local m,f=C_Minimap,Enum.MinimapTrackingFilter." .. filter .. " for i=1,m.GetNumTrackingTypes() do local t=m.GetTrackingFilter(i)"
			.. " if t and t.filterID==f then m.SetTracking(i,%s) end end",
		{ default = TRACKED[filter] and "1" or "0", section = 14, storage = "character", calls = L.CALLS_TWO:format("C_Minimap.GetTrackingInfo", "SetTracking") })
end

-- The combat audio alerts the game keeps for each specialisation, packed in a
-- CVar each (CAAResource1Percents...). These read and set the specialisation in use.
for setting, default in pairs({ Resource1Percent = "0", Resource1Format = "1", Resource1Voice = "0", Resource1Volume = "100",
	Resource2Percent = "0", Resource2Format = "1", Resource2Voice = "0", Resource2Volume = "100", SayIfTargeted = "1" }) do
	local function Setting() return Enum.CombatAudioAlertSpecSetting[setting] end
	SETTERS["@caa:" .. setting] = {
		get = function() return C_CombatAudioAlert.GetSpecSetting(Setting()) end,
		set = function(value)
			if tonumber(value) then C_CombatAudioAlert.SetSpecSetting(Setting(), tonumber(value)) end
		end,
		command = function(value)
			return ("/run C_CombatAudioAlert.SetSpecSetting(Enum.CombatAudioAlertSpecSetting.%s, %s)")
				:format(setting, tonumber(value) or ("%q"):format(tostring(value)))
		end,
		default = default, section = 13, storage = "character", calls = L.CALLS_TWO:format("C_CombatAudioAlert.GetSpecSetting", "SetSpecSetting"),
	}
end

-- Console commands that are settings in all but name, each tried in the game
-- (#71). One is set with ConsoleExec("<command> <value>"), and listed under
-- Console commands (section "commands"). The game can't be asked for
-- pitchLimit's or physEnable's value, so Every Setting goes by the last one the
-- command was given this session, by Every Setting or anything else that ran it
-- through ConsoleExec (nil until then, which a login takes as a value to set
-- again). The console window's text size and colors can be read back. Each has:
--   console  the command
--   line     the command's arguments for a value, or nil for one it can't take
local consoleNames -- lower-case name -> true, for every console command and CVar the client has
local given = {} -- a setting -> the value its command was last given (see ConsoleExec below)
local CONSOLE_COLORS = { input = "InputColor", echo = "EchoColor", warning = "WarningColor", admin = "AdminColor", global = "GlobalColor" }

local function ConsoleSetting(key, command, line, read, default, storage)
	local name = "@console:" .. key
	SETTERS[name] = {
		get = function()
			if not consoleNames then
				consoleNames = {}
				for _, info in ipairs(ConsoleGetAllCommands()) do consoleNames[info.command:lower()] = true end
			end
			assert(consoleNames[command:lower()]) -- the client has no such command
			if read then return read() end
			return given[name]
		end,
		set = function(value)
			local args = line(value)
			if not args then return end
			ConsoleExec(command .. " " .. args)
			given[name] = value
		end,
		command = function(value) return "/console " .. command .. " " .. (line(value) or value) end,
		console = command, line = line, default = default, section = "commands", storage = storage or "session",
		calls = L.CALLS_CONSOLE:format(command), unread = not read or nil,
	}
end

local function Number(value) return tonumber(value) and value end
ConsoleSetting("pitchLimit", "pitchLimit", Number)
ConsoleSetting("physEnable", "physEnable", function(value) return (value == "0" or value == "1") and value end, nil, "1")
ConsoleSetting("fontsize", "fontsize", Number, function() return tostring(math.floor(ConsoleGetFontHeight() + 0.5)) end, "14", "computer")
for class, colorType in pairs(CONSOLE_COLORS) do
	ConsoleSetting("fontcolor:" .. class, "fontcolor", function(value)
		local r, g, b = value:match("^%x%x(%x%x)(%x%x)(%x%x)$")
		return r and ("%s %d %d %d"):format(class, tonumber(r, 16), tonumber(g, 16), tonumber(b, 16))
	end, function()
		local r, g, b = ConsoleGetColorFromType(Enum.ConsoleColorType[colorType]):GetRGB()
		local function Byte(c) return math.floor(c * 255 + 0.5) end
		return ("FF%02X%02X%02X"):format(Byte(r), Byte(g), Byte(b))
	end, ({ input = "FF80C4FF", echo = "FF808080", warning = "FFFFFF00" })[class] or "FFFFFFFF")
end

-- For a CVar with a setter: the function, if the client has it, then the
-- arguments it takes for `value`, if it can take it, and the setter. For a
-- setting that isn't a CVar: its `set`, and `value` as text.
local function Setter(cvar, value)
	local setter = SETTERS[cvar]
	if not setter then return end
	if setter.set then return setter.set, { tostring(value) }, setter end
	local args
	if setter.put then
		args = EverySetting.Knob(cvar) and {} -- put makes the calls, from the knob's menu
	elseif setter.args then
		args = setter.args(tostring(value))
	elseif tonumber(value) then
		args = { tonumber(value) }
	end
	local api = args and _G[setter[1]]
	return api and api[setter[2]], args, setter
end

-- Fills in what the client says about a knob's CVar, or SETTERS about a setting
-- that isn't one.
local function ReadKnob(knob)
	local setter = SETTERS[knob.cvar]
	if setter and setter.get then
		knob.found = (pcall(setter.get))
		knob.default, knob.storage, knob.calls, knob.unread = setter.default, setter.storage, setter.calls, setter.unread
		if type(knob.default) == "function" then -- known only as the game runs
			local ok, default = pcall(knob.default)
			knob.default = ok and default or nil
		end
		knob.secure, knob.locked = true, false
		BY_CVAR[knob.cvar:lower()] = knob
		return
	end
	local value, default, account, character, locked, secure, readOnly = C_CVar.GetCVarInfo(knob.cvar)
	knob.found = value ~= nil
	knob.default = default == "0" and setter and setter.zero or default
	if setter and setter.ids then knob.default = "" end -- an empty list
	knob.storage = account and "account" or character and "character" or "computer"
	knob.secure = secure and true or false
	knob.locked = (locked or readOnly) and true or false
	knob.danger = locked and "locked" or readOnly and "readonly" or nil
	knob.setter = SETTERS[knob.cvar] and true or nil
	BY_CVAR[knob.cvar:lower()] = knob
end

-- CVars.lua's entry for a CVar, "section|kind|...": the section it's listed
-- under, and maybe a control to suggest for it.
--   "1"                  just the section
--   "1|t"                a toggle
--   "1|s|0|1|0.05"       a slider: min, max, step ("S": the box is held to the range too)
--   "1|c|0=Off|1=On"     a choice: value=Label for each option
--   "1|f|1=Mine|2=Yours" flags: index=Label for each flag
--   "1|h"                a color
--   "...|gx"             a change shows after a graphics restart ("window", "reload",
--                        "login", "client": after a window update, a reload, logging
--                        out and in again, a game restart). "...|client:0": only a
--                        change to 0
--   "...|x"              (last) the game's server enforces it: a danger setting
EverySetting.SECTIONS = {}
EverySetting.CVARS = {}
-- CVars.lua's word on what a console command that isn't a CVar does, by its name,
-- where the game's own help says nothing or not enough.
EverySetting.COMMANDS = {}
EverySetting.NAMES = {} -- CVars.lua's plain names: CVar -> what its raw knob is called

-- What a change can need before it shows (a knob's `restart`).
local RESTARTS = { gx = true, window = true, reload = true, login = true, client = true }

-- A CVar's name as CVars.lua has it. CVar names ignore case, and a name can come
-- typed or in an imported line: in whatever case, it's the same CVar, with the
-- same line. A CVar with no line keeps the name it was given.
local specTable, specNames
local function SpecName(name)
	if specTable ~= EverySetting.CVARS then
		specTable, specNames = EverySetting.CVARS, {}
		for cvar in pairs(specTable) do specNames[cvar:lower()] = cvar end
	end
	if specTable[name] then return name end
	return specNames[name:lower()] or name
end

-- The index in EverySetting.SECTIONS of the section a CVar, or a setting that
-- isn't one, is listed under. One past the last for a console command's.
function EverySetting.Section(name)
	local section = SETTERS[name] and SETTERS[name].section
	if section == "commands" then return #EverySetting.SECTIONS + 1 end
	if section then return section end
	return tonumber((EverySetting.CVARS[SpecName(name)] or ""):match("^%d+")) or #EverySetting.SECTIONS
end

-- The name a player knows a CVar by, or nil: a tuned setting's, the game's own from
-- this game's options menu (in the game's language), or a plain name from CVars.lua.
function EverySetting.PlainName(name)
	local knob = EverySetting.Knob(name)
	if knob and (knob.src or knob.named) then return knob.label end
	name = SpecName(name)
	local strings = EverySetting.LABELS[EverySetting.Client()][name]
	local label = strings and _G[strings[1]]
	if type(label) == "string" and label ~= "" then return label end
	return EverySetting.NAMES[name]
end

-- The knob for any CVar the client has: the one from Knobs.lua, or a raw one
-- made here, called by the CVar's name or the plain name CVars.lua gives it.
-- `help` is the game's help text for it. nil if there's no such CVar.
function EverySetting.RawKnob(name, help)
	local knob = EverySetting.Knob(name)
	if knob then return knob end
	if C_CVar.GetCVar(name) == nil then return nil end
	name = SpecName(name)
	knob = { cvar = name, label = name, tip = help ~= "" and help or nil, type = "text", raw = true }
	-- The game's own name and tooltip for it, where this game's options menu has
	-- it, in the game's language. A string this client doesn't have leaves the CVar's.
	local strings = EverySetting.LABELS[EverySetting.Client()][name]
	if strings then
		local label, tip = _G[strings[1]], strings[2] and _G[strings[2]]
		if type(label) == "string" and label ~= "" then knob.label, knob.named = label, true end
		if type(tip) == "string" and tip ~= "" then knob.tip = tip end
	end
	-- Or a plain name players know it by, from CVars.lua, for one the menu doesn't have.
	if not knob.named and EverySetting.NAMES[name] then knob.label, knob.named = EverySetting.NAMES[name], true end
	-- Or, for a raid twin (RAIDfarclip, raidGraphicsShadowQuality), the name of the CVar it
	-- stands in for in raids: its own name without "raid", in any case.
	local main = not knob.named and name:match("^[Rr][Aa][Ii][Dd](.+)$")
	local mainName = main and C_CVar.GetCVar(main) ~= nil and EverySetting.PlainName(main)
	if mainName then knob.label, knob.named = L.RAID_TWIN:format(mainName), true end
	local parts = { strsplit("|", EverySetting.CVARS[name] or "") }
	local server = #parts > 1 and parts[#parts] == "x"
	if server then parts[#parts] = nil end
	local restart, to = (parts[#parts] or ""):match("^(%l+):?([^=]*)$") -- not an option, which has an =
	if #parts > 1 and RESTARTS[restart] then
		knob.restart, knob.restartTo = restart, to ~= "" and to or nil
		parts[#parts] = nil
	end
	local kind = parts[2]
	if kind == "t" then
		knob.type = "toggle"
	elseif kind == "s" or kind == "S" then
		knob.type = "slider"
		knob.min, knob.max, knob.step = tonumber(parts[3]), tonumber(parts[4]), tonumber(parts[5])
		knob.raw = kind == "s"
	elseif kind == "c" or kind == "f" then
		knob.type = kind == "c" and "choice" or "flags"
		knob.options = {}
		for i = 3, #parts do
			-- The label's key in the locale table, or a label to show as it is (SDL, 03:27).
			local value, label = parts[i]:match("^(.-)=(.*)$")
			knob.options[#knob.options + 1] = { kind == "f" and tonumber(value) or value, L[label] or label }
		end
	elseif kind == "h" then
		knob.type = "color"
	end
	local setter = SETTERS[name]
	if setter and setter.list then knob.type, knob.list, knob.options = "choice", setter.list, {} end
	ReadKnob(knob)
	if server then knob.locked, knob.danger = true, "server" end
	return knob
end

local all -- every CVar's knob, by section; made when it's first asked for

-- The groups for the list of every CVar: { title, items } per section, each
-- sorted by name. A CVar that CVars.lua doesn't know goes in the last section.
function EverySetting.AllGroups()
	if all then return all end
	local sections = {}
	for i, title in ipairs(EverySetting.SECTIONS) do sections[i] = { title = title, items = {} } end
	local cvarType = Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.commandType == cvarType then
			local knob = EverySetting.RawKnob(info.command, info.help)
			local section = sections[EverySetting.Section(info.command)] or sections[#sections]
			if knob and section then section.items[#section.items + 1] = knob end
		end
	end
	all = {}
	for _, section in ipairs(sections) do
		if #section.items > 0 then
			table.sort(section.items, function(a, b) return a.cvar:lower() < b.cvar:lower() end)
			all[#all + 1] = section
		end
	end
	return all
end

local commandKnobs -- the console commands' knobs; made when they're first asked for

-- The console commands the client has that aren't CVars, for the window's
-- Console commands section, but for those with a setting's row (see
-- ConsoleSetting): a knob each, of type "command", in name order. Its
-- `cvar` is the command's name, its `tip` what EverySetting.COMMANDS says it does
-- or else the game's help, and `runs` true for one EverySetting.RUNNABLE has (see
-- RunCommand). The row gives each to copy and type in chat.
function EverySetting.ConsoleCommands()
	if commandKnobs then return commandKnobs end
	commandKnobs = {}
	local cvarType = Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
	local rows = {} -- the commands with a setting's row of their own
	for _, setter in pairs(SETTERS) do
		if setter.console then rows[setter.console:lower()] = true end
	end
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.commandType ~= cvarType and not rows[info.command:lower()] then
			local tip = EverySetting.COMMANDS[info.command] or info.help or ""
			commandKnobs[#commandKnobs + 1] = { cvar = info.command, label = info.command, type = "command",
				tip = tip ~= "" and tip or nil, found = true, runs = EverySetting.RUNNABLE[info.command] }
		end
	end
	table.sort(commandKnobs, function(a, b) return a.cvar:lower() < b.cvar:lower() end)
	return commandKnobs
end

-- What a command run by RunCommand prints goes to the console window, which most
-- players never open. The lines printed in the half second after it are said in
-- chat instead: the first ECHO_LINES, then how many more there were.
local ECHO_LINES = 10
local echo -- the lines printed since RunCommand ran its command, or nil
local consoleOut = CreateFrame("Frame")
consoleOut:RegisterEvent("CONSOLE_MESSAGE")
consoleOut:SetScript("OnEvent", function(_, _, message)
	if not echo then return end
	message = tostring(message or ""):gsub("%s+$", "")
	if message ~= "" then echo[#echo + 1] = message end
end)

-- Runs a console command with nothing after it, if EverySetting.RUNNABLE has it.
function EverySetting.RunCommand(command)
	if not EverySetting.RUNNABLE[command] then return end
	local lines = {}
	echo = lines
	ConsoleExec(command)
	C_Timer.After(0.5, function()
		if echo == lines then echo = nil end
		if #lines == 0 then return Print(L.RAN_NOTHING, command) end
		Print(L.RAN_PRINTED, command)
		for i = 1, math.min(#lines, ECHO_LINES) do DEFAULT_CHAT_FRAME:AddMessage("  " .. lines[i]) end
		if #lines > ECHO_LINES then Print(L.RAN_MORE, #lines - ECHO_LINES) end
	end)
end

local function ReadKnobs()
	local client = EverySetting.Client()
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			for field, value in pairs(knob[client] or {}) do knob[field] = value end -- this client's range
			ReadKnob(knob)
		end
	end
end

-- A slider's range: min, max.
function EverySetting.Bounds(knob)
	if knob.bounds then
		local ok, min, max = pcall(knob.bounds)
		if ok and type(min) == "number" and type(max) == "number" then return min, max end
	end
	return knob.min, knob.max
end

-- Why the game says this computer can't use a value, by the number its
-- IsGraphicsCVarValueSupported returns (Enum.GraphicsValidationResult): the names of
-- the game's own strings, in the order its Graphics options list them. 0 is a
-- value it can use, and a number past the end says nothing.
local UNSUPPORTED = {
	"VRN_ILLEGAL", "VRN_UNSUPPORTED", "VRN_GRAPHICS", "VRN_DUALCORE", "VRN_QUADCORE",
	"VRN_CPUMEM_2GB", "VRN_CPUMEM_4GB", "VRN_CPUMEM_8GB", "VRN_NEEDS_5_0", "VRN_NEEDS_6_0",
	"VRN_NEEDS_RT", "VRN_NEEDS_DX12", "VRN_NEEDS_DX12_VRS2", "VRN_NEEDS_APPLE_GPU", "VRN_NEEDS_AMD_GPU",
	"VRN_NEEDS_INTEL_GPU", "VRN_NEEDS_NVIDIA_GPU", "VRN_NEEDS_QUALCOMM_GPU", "VRN_NEEDS_MACOS_10_13",
	"VRN_NEEDS_MACOS_10_14", "VRN_NEEDS_MACOS_10_15", "VRN_NEEDS_MACOS_11_0", "VRN_NEEDS_MACOS_12_0",
	"VRN_NEEDS_MACOS_13_0", "VRN_NEEDS_WINDOWS_10", "VRN_NEEDS_WINDOWS_11", "VRN_MACOS_UNSUPPORTED",
	"VRN_WINDOWS_UNSUPPORTED", "VRN_LEGACY_UNSUPPORTED", "VRN_DX11_UNSUPPORTED", "VRN_DX12_WIN7_UNSUPPORTED",
	"VRN_REMOTE_DESKTOP_UNSUPPORTED", "VRN_WINE_UNSUPPORTED", "VRN_NVAPI_WINE_UNSUPPORTED",
	"VRN_APPLE_UNSUPPORTED", "VRN_AMD_UNSUPPORTED", "VRN_INTEL_UNSUPPORTED", "VRN_NVIDIA_UNSUPPORTED",
	"VRN_QUALCOMM_UNSUPPORTED", "VRN_GPU_DRIVER", "VRN_COMPAT_MODE",
}

-- The menus whose options the game's own Graphics options check, one by one, and
-- grey out where this computer can't use them, and the CVar each is checked as. A
-- raid twin goes by its main CVar: the game doesn't check RAIDshadowRt, and the
-- engine keeps no more of it than of shadowRt.
local CHECKED = {
	LowLatencyMode = "LowLatencyMode",
	ResampleQuality = "ResampleQuality",
	shadowRt = "shadowRt",
	RAIDshadowRt = "shadowRt",
	textureFilteringMode = "textureFilteringMode",
	vrsValar = "vrsValar",
}

-- Why this computer can't use a value of a CVar's menu, in the game's own words, or
-- nil if it can, or the game doesn't check that CVar. Ray-traced shadows on a card
-- without ray tracing, or Intel XeLL on another maker's card, say why.
function EverySetting.Unsupported(cvar, value)
	local checked = CHECKED[cvar]
	if not checked or type(IsGraphicsCVarValueSupported) ~= "function" or not tonumber(value) then return nil end
	local ok, result = pcall(IsGraphicsCVarValueSupported, checked, tonumber(value))
	local name = ok and UNSUPPORTED[result]
	return name and (_G[name] or _G[UNSUPPORTED[2]] or name) or nil
end

-- A choice's options. A knob with a `list` has them as the game gives them now. An
-- option this computer can't use has why in `unsupported`.
function EverySetting.Options(knob)
	if knob.list then knob.options = knob.list() end
	if CHECKED[knob.cvar] and knob.type == "choice" then
		for _, option in ipairs(knob.options) do option.unsupported = EverySetting.Unsupported(knob.cvar, option[1]) end
	end
	return knob.options
end

-- How many decimals a step needs: 0 for 1, 2 for 0.05.
local function Decimals(step)
	local fraction = ("%.4f"):format(step):match("%.(%d-)0*$")
	return #fraction
end

-- Whether a number typed in the knob's box can go past its range. It can where
-- the range is the game's own quality levels (src = "preset"): the engine keeps
-- any number for those. The slider, styles, presets and imported text stay inside.
function EverySetting.GoesPast(knob)
	return knob.type == "slider" and knob.src == "preset"
end

-- Which side of such a knob's range `value` is past: 1 above it, -1 below it.
-- nil inside it, and for any other knob.
function EverySetting.Past(knob, value)
	value = tonumber(value)
	if not (value and EverySetting.GoesPast(knob)) then return nil end
	local min, max = EverySetting.Bounds(knob)
	return value > max and 1 or value < min and -1 or nil
end

-- `value` as the knob's CVar takes it: a string, clamped to the range and
-- snapped to the step. nil if the knob can't take it at all. With `asTyped`, a
-- number past the range of a knob whose box takes one (GoesPast) is left there.
function EverySetting.Normalize(knob, value, asTyped)
	if knob.type == "text" or knob.type == "flags" then
		return tostring(value)
	elseif knob.type == "toggle" then
		return (value == true or tonumber(value) == 1) and "1" or "0"
	elseif knob.type == "color" then
		-- Eight hex digits, or six for a color with nothing see-through about it.
		value = tostring(value):upper()
		if #value == 6 then value = "FF" .. value end
		return value:match("^" .. ("%x"):rep(8) .. "$")
	elseif knob.type == "choice" then
		value = tostring(value)
		for _, option in ipairs(EverySetting.Options(knob)) do
			if tostring(option[1]) == value then return value end
		end
		return nil
	end
	value = tonumber(value)
	if not value then return nil end
	local min, max = EverySetting.Bounds(knob)
	local step = knob.step or 1
	local decimals = Decimals(step)
	if asTyped and EverySetting.Past(knob, value) and math.abs(value) < math.huge then
		decimals = 4 -- off the slider's steps too
	else
		value = min + math.floor((value - min) / step + 0.5) * step
		value = math.min(max, math.max(min, value))
	end
	local text = ("%." .. decimals .. "f"):format(value)
	return (text:gsub("(%.%d-)0+$", "%1"):gsub("%.$", ""))
end

-- A value a style or a built-in preset gives the knob, held to this client's
-- range: Normalize's, or for a number a menu doesn't offer here, the nearest
-- option below it (retail has no 4096 shadows: 2048). nil if there's none.
function EverySetting.Fit(knob, value)
	local fit = EverySetting.Normalize(knob, value)
	if fit or knob.type ~= "choice" or not tonumber(value) then return fit end
	local best
	for _, option in ipairs(EverySetting.Options(knob)) do
		local n = tonumber(option[1])
		if n and n <= tonumber(value) and (not best or n > best) then best = n end
	end
	return best and tostring(best)
end

-- Whether two CVar values are the same: "1" and "1.000" are.
local function Same(a, b)
	local x, y = tonumber(a), tonumber(b)
	if x and y then return math.abs(x - y) < 1e-6 end
	return a == b
end
EverySetting.Same = Same

-------------------------------------------------------------------------------
-- Setting and resetting
-------------------------------------------------------------------------------

-- EverySettingDB, the account's:
--   profiles[name][cvar]  the value a profile keeps
--   applied               the profile whose values are set in the client now
--   before[cvar]          the value a CVar had before Every Setting changed it, which Reset puts back
--   presets[name][cvar]   the value a saved preset gives a CVar
--   situations[key]       the preset each situation uses, or true for its own (see Situations)
--   under[cvar]           while a situation holds a CVar: the value it goes back to
--   locked[cvar]          true for a setting styles and presets leave alone, whatever the profile
--   danger                true while danger mode is on (see Danger mode)
--   folded[key]           true for a part of the window's list folded down to its title: a
--                         section by its title, a group as "section/group"
--   scale                 the window's size, 1 for 100%; nil while it's 1
--   fps[style]            { before, after }: the frame rate around the last time the style was
--                         applied whole, on this machine (see Frame rate)
-- EverySettingCharDB, each character's:
--   profile               the profile this character uses, put in use when it logs in
local db
local values -- the profile in use: db.profiles[db.applied]
local pending = {} -- CVar -> value to set when combat ends; false to reset it

local sent = {} -- CVar -> the value a late setter was just given (see Sent)

-- While a situation holds a CVar (Situations, below), Every Setting's own changes go
-- to the value underneath it, which comes back when the situation ends. Read
-- and Put read and set that value; any other CVar is read and set as it is.
local function Read(cvar)
	local under = db and db.under[cvar]
	if under ~= nil then return under end
	local setter = SETTERS[cvar]
	if not sent[cvar] and setter and setter.get then -- a setting that isn't a CVar
		local ok, value = pcall(setter.get)
		return ok and value ~= nil and tostring(value) or nil
	end
	if not sent[cvar] and setter and setter.ids then -- a list, as the game's getter gives it
		local ok, list = pcall(setter.ids)
		if ok and type(list) == "table" then return EntriesText(list) end
	end
	local value = sent[cvar] or C_CVar.GetCVar(cvar)
	if value == "0" and setter and setter.zero then return setter.zero end -- the game's default
	return value
end

-- The game changes a late setter's CVar a moment after its function is called.
-- Until it does, the CVar is read as the value the function was given, so the
-- change is kept, shown and undone like any other. After three seconds
-- without one, it's read as the game has it again.
local function Sent(cvar, value)
	sent[cvar] = value
	C_Timer.After(3, function()
		if sent[cvar] == value then
			sent[cvar] = nil
			EverySetting.Changed()
		end
	end)
end

-- Since Every Setting loaded, what last changed each CVar: lower-case name ->
-- { addon, by, value }. `heard` has the CVars CVAR_UPDATE named that no hook has
-- noted yet. See Who changed a setting, below.
local changedBy, heard = {}, {}

local function Put(cvar, value)
	local set, args, setter = Setter(cvar, value)
	if db.under[cvar] ~= nil then
		db.under[cvar] = tostring(value)
	elseif set then
		if setter.put then setter.put(tostring(value), Read(cvar), EverySetting.Knob(cvar)) else set(unpack(args)) end
		if setter.late then Sent(cvar, tostring(value)) end
		-- The game's function doesn't go through C_CVar.SetCVar, which is hooked below.
		heard[cvar:lower()] = nil
		changedBy[cvar:lower()] = { addon = ADDON, by = L.ADDON_NAME, value = Read(cvar) }
	else
		C_CVar.SetCVar(cvar, value)
	end
end

local DEFAULT_PROFILE = "Default"
EverySetting.DEFAULT_PROFILE = DEFAULT_PROFILE

-- What a change needs before it shows: restart.gx, restart.window, restart.reload,
-- restart.login, restart.client.
EverySetting.restart = {}

-- Call after changing anything the window shows.
function EverySetting.Changed()
	if EverySetting.RefreshOptions then EverySetting.RefreshOptions() end
end

-- The knob's raid twin, unless the twin is kept at a value of its own (set in
-- the list of every CVar): then it's left alone.
local function Twin(knob)
	return knob.raid and values[knob.raid] == nil and knob.raid or nil
end

-- Notes the restart a knob's change to `value` waits for, if it waits for one.
local function Owe(knob, value)
	if knob.restart and (knob.restartTo == nil or Same(value, knob.restartTo)) then EverySetting.restart[knob.restart] = true end
end

-- Sets the knob's CVar (and its raid twin) and returns what the engine kept.
local function Write(knob, value)
	local old = Read(knob.cvar)
	local twin = Twin(knob)
	Put(knob.cvar, value)
	if twin then Put(twin, value) end
	local kept = Read(knob.cvar)
	if not Same(kept, old) then Owe(knob, kept) end
	return kept
end

-- Notes what the knob's CVar (and its raid twin) is now, for Reset to go back
-- to, unless that's noted already.
local function NoteBefore(knob)
	local twin = Twin(knob)
	if db.before[knob.cvar] == nil then db.before[knob.cvar] = Read(knob.cvar) end
	if twin and db.before[twin] == nil then db.before[twin] = Read(twin) end
end

-- Puts back the values from before Every Setting changed the knob.
local function Restore(knob)
	local old = Read(knob.cvar)
	local twin = Twin(knob)
	Put(knob.cvar, db.before[knob.cvar] or knob.default)
	db.before[knob.cvar] = nil
	if twin then
		Put(twin, db.before[twin] or C_CVar.GetCVarDefault(twin) or knob.default)
		db.before[twin] = nil
	end
	local now = Read(knob.cvar)
	if not Same(now, old) then Owe(knob, now) end
end

-- Whether a style, preset, situation or import may set the knob: never a
-- danger setting.
local function CanSet(knob)
	return db and knob and knob.found and not knob.locked
end

-- Whether it can be set by hand: a danger setting too, while danger mode is on.
local function CanSetByHand(knob)
	return db and knob and knob.found and (not knob.locked or db.danger == true)
end

-- The knob's value: the CVar's, or the one waiting for combat to end.
function EverySetting.Get(cvar)
	local knob = EverySetting.Knob(cvar)
	if not (knob and knob.found) then return nil end
	local waiting = pending[knob.cvar]
	if waiting == false then return EverySetting.Before(cvar) end
	return waiting or Read(knob.cvar)
end

-- The value Reset puts back: the one from before Every Setting changed the knob.
function EverySetting.Before(cvar)
	local knob = EverySetting.Knob(cvar)
	if not (db and knob and knob.found) then return nil end
	return db.before[knob.cvar] or knob.default
end

-- Whether Every Setting remembers a value for this knob, and sets it at every login.
function EverySetting.IsStored(cvar)
	local knob = EverySetting.Knob(cvar)
	return db ~= nil and knob ~= nil and values[knob.cvar] ~= nil
end

-- The profile in use: CVar -> the value Every Setting keeps for it. To read, not to change.
function EverySetting.GetKept() return values end

-- Whether the knob's change is waiting for combat to end.
function EverySetting.IsPending(cvar)
	local knob = EverySetting.Knob(cvar)
	return knob ~= nil and pending[knob.cvar] ~= nil
end

-- What's folded in the window's list (see db.folded above), to read and change.
function EverySetting.GetFolded() return db.folded end

-------------------------------------------------------------------------------
-- Undo and redo
-------------------------------------------------------------------------------

-- For this session, each profile remembers the changes made to it. Each entry
-- is one action: a list of { cvar, from, to }, where `from` and `to` are the
-- CVar's state either side of it (State below).
local MAX_UNDO = 50
local history = setmetatable({}, { __mode = "k" }) -- profile -> { undo = {}, redo = {} }
local action -- the action being recorded: CVar -> its state beforehand

-- The history of the profile in use.
local function History()
	local h = history[values]
	if not h then
		h = { undo = {}, redo = {} }
		history[values] = h
	end
	return h
end

-- A CVar's value, the value Every Setting keeps for it, and the one from before Every Setting.
local function State(cvar)
	return { value = Read(cvar), kept = values[cvar], before = db.before[cvar] }
end

-- Notes the state of a knob's CVar (and its raid twin) before the action being
-- recorded changes it.
local function Touch(knob)
	if not action then return end
	local twin = Twin(knob)
	if not action[knob.cvar] then action[knob.cvar] = State(knob.cvar) end
	if twin and not action[twin] then action[twin] = State(twin) end
end

local function ForgetHistory()
	history[values] = nil
end

-- Runs `fn` as one action that Undo can take back. A change made in combat
-- can't be taken back (a secure CVar isn't set until combat ends), and neither
-- can anything before it.
local function Record(fn)
	if InCombatLockdown() then
		ForgetHistory()
		return fn()
	end
	if action then return fn() end -- inside another: part of that change
	action = {}
	fn()
	local changes = {}
	for cvar, from in pairs(action) do
		local to = State(cvar)
		if from.value ~= to.value or from.kept ~= to.kept or from.before ~= to.before then
			changes[#changes + 1] = { cvar = cvar, from = from, to = to }
		end
	end
	action = nil
	if #changes > 0 then
		local h = History()
		h.undo[#h.undo + 1] = changes
		if #h.undo > MAX_UNDO then table.remove(h.undo, 1) end
		h.redo = {}
	end
end

-- Moves the last action on `from` to `to`, putting each of its CVars in the
-- state named `which` ("from" to undo it, "to" to redo it).
local function Step(from, to, which)
	if #from == 0 then return false end
	if InCombatLockdown() then
		Print(L.WAIT_FOR_COMBAT_CHAT)
		return false
	end
	local changes = table.remove(from)
	for _, change in ipairs(changes) do
		local state = change[which]
		local knob = EverySetting.Knob(change.cvar)
		-- A danger setting's change stays as it is once danger mode is off.
		if not (knob and knob.locked and db.danger ~= true) then
			if Read(change.cvar) ~= state.value then
				Put(change.cvar, state.value)
				if knob then Owe(knob, state.value) end
			end
			values[change.cvar] = state.kept
			db.before[change.cvar] = state.before
		end
	end
	to[#to + 1] = changes
	EverySetting.Changed()
	return true
end

-- Takes back the last change made to this profile this session. Returns
-- whether there was one.
function EverySetting.Undo()
	local h = History()
	return Step(h.undo, h.redo, "from")
end

-- Makes the change Undo last took back again.
function EverySetting.Redo()
	local h = History()
	return Step(h.redo, h.undo, "to")
end

-- How many changes can be undone, and redone.
function EverySetting.HistorySize()
	local h = History()
	return #h.undo, #h.redo
end

-------------------------------------------------------------------------------
-- Frame rate
-------------------------------------------------------------------------------

-- Around a change to a graphics setting, or a preset or style that sets one, the
-- frame rate before and after: GetFramerate() averaged over the BEFORE seconds up
-- to the change, and over the AFTER seconds that follow a SETTLE after it. It's
-- sampled every STEP seconds while the window is open, and until a reading under
-- way is done. A reading is skipped when the number would mean nothing, with why:
-- "moving", "camera" (it moved, or you turned), "combat", or "soon" (the window
-- opened, or the last reading began, too short a time before).
local STEP, BEFORE, SETTLE, AFTER = 0.25, 2, 1, 3
local samples = {} -- { at, fps, busy, facing, zoom }, oldest first
local watching, ticking = false, false
local since -- when the samples began
local lastReading -- when the last reading began
-- The reading: { knob, from, to } for a change to a knob, or { label, whole } for a
-- preset or style (`whole`: it's that style, whole). Then `at`, `before` and
-- `after` once measured, or `why` it's skipped; `cap`, the frame rate limit a
-- number sits at; `vsync`, whether vertical sync is on.
local reading

-- Whether a CVar is in the Graphics section, the first: the one a reading is taken for.
local function Graphics(cvar)
	return EverySetting.Section(cvar) == 1
end

-- Why the frame rate means nothing now, if it doesn't. `last` is the sample before.
-- A camera turned with the left button isn't mouselook, and moves neither where
-- you face nor the zoom (seen in 1.60.1): the button held off the window is.
local function Busy(last, facing, zoom)
	if InCombatLockdown() or UnitAffectingCombat("player") then return "combat" end
	if GetUnitSpeed("player") > 0 or IsFalling() then return "moving" end
	if IsMouselooking() or (IsMouseButtonDown("LeftButton") and not (EverySettingOptions and EverySettingOptions:IsMouseOver()))
		or (last and (last.facing ~= facing or last.zoom ~= zoom)) then
		return "camera"
	end
end

-- The mean frame rate of the samples taken after `first` seconds, up to `last`,
-- or nil and why there's none.
local function Average(first, last)
	local sum, n = 0, 0
	for _, s in ipairs(samples) do
		if s.at > first and s.at <= last then
			if s.busy then return nil, s.busy end
			sum, n = sum + s.fps, n + 1
		end
	end
	if n == 0 then return nil, "soon" end
	return sum / n
end

-- The frame rate limit `fps` sits at, if it's at one: the cap, or the cap while
-- the game is in the background.
local function Cap(fps)
	for _, cap in ipairs({ { "useMaxFPS", "maxFPS" }, { "useMaxFPSBk", "maxFPSBk" } }) do
		local limit = tonumber(C_CVar.GetCVar(cap[2]))
		if C_CVar.GetCVar(cap[1]) == "1" and limit and math.abs(fps - limit) <= limit * 0.05 then return limit end
	end
end

local function Tick()
	local now = GetTime()
	local facing, zoom = GetPlayerFacing(), GetCameraZoom()
	local busy = Busy(samples[#samples], facing, zoom)
	samples[#samples + 1] = { at = now, fps = GetFramerate(), busy = busy, facing = facing, zoom = zoom }
	while samples[1].at < now - (BEFORE + SETTLE + AFTER + 1) do table.remove(samples, 1) end
	local r = reading
	if r and not (r.after or r.why) then
		if busy then
			r.why = busy
		elseif now >= r.at + SETTLE + AFTER then
			r.after, r.why = Average(r.at + SETTLE, math.huge)
			if r.after then
				r.cap = Cap(r.before) or Cap(r.after)
				r.vsync = C_CVar.GetCVar("vsync") == "1"
				if r.whole then db.fps[r.label] = { math.floor(r.before + 0.5), math.floor(r.after + 0.5) } end
			end
		end
		if r.after or r.why then EverySetting.Changed() end
	end
	if watching or (r and not (r.after or r.why)) then
		C_Timer.After(STEP, Tick)
	else
		ticking = false
		wipe(samples)
	end
end

-- Begins a reading of the frame rate around a change just made, while the window is open.
local function Measure(r)
	if not watching then return end
	local now = GetTime()
	r.at = now
	if since > now - BEFORE or (lastReading and lastReading + SETTLE > now - BEFORE) then
		r.why = "soon"
	else
		r.before, r.why = Average(now - BEFORE, now)
	end
	lastReading = now
	reading = r
end

-- The window calls this as it opens and closes. A reading that's done is let go
-- when it opens again.
function EverySetting.WatchFramerate(on)
	watching = on
	if on and reading and (reading.after or reading.why) then reading = nil end
	if on and not ticking then
		ticking, since = true, GetTime()
		Tick()
	end
end

-- The reading of the frame rate around the last change (see `reading` above), if
-- there's one to show.
function EverySetting.Reading() return reading end

-- The frame rate before and after the style `name` was last applied whole, on this machine.
function EverySetting.StyleFramerate(name)
	local fps = db.fps[name]
	if fps then return fps[1], fps[2] end
end

-------------------------------------------------------------------------------
-- Changing knobs
-------------------------------------------------------------------------------

-- Whether two of a knob's values are the same. A flags knob's are where every
-- flag of its menu is: "0", nothing and "\002" have none on.
local function SameAs(knob, a, b)
	if SETTERS[knob.cvar] and SETTERS[knob.cvar].ids then return EntriesText(Entries(a)) == EntriesText(Entries(b)) end
	if knob.type ~= "flags" then return Same(a, b) end
	for _, option in ipairs(knob.options) do
		if EverySetting.Flag(a, option[1]) ~= EverySetting.Flag(b, option[1]) then return false end
	end
	return true
end
EverySetting.SameAs = SameAs

-- Sets a knob that can be set to `value`, a string. What the engine kept is
-- remembered, and returned. A danger setting the game doesn't change isn't
-- remembered: nil, and a line with the command to try. `write` (optional) does
-- the setting in Write's place.
local function Change(knob, value, write)
	local refused = false
	Record(function()
		Touch(knob)
		local old, before = Read(knob.cvar), db.before[knob.cvar]
		NoteBefore(knob)
		if knob.secure and InCombatLockdown() then
			pending[knob.cvar] = value
			values[knob.cvar] = value
		else
			pending[knob.cvar] = nil
			local kept = (write or Write)(knob, value)
			if knob.danger and SameAs(knob, kept, old) and not SameAs(knob, old, value) then
				db.before[knob.cvar], refused = before, true
			else
				values[knob.cvar] = kept
			end
		end
	end)
	EverySetting.Changed()
	if refused then
		if knob.danger == "server" or knob.setter then
			Print(L.NOT_TAKEN_TRY, value, knob.cvar, EverySetting.Command(knob.cvar, value))
		else
			Print(L.NOT_TAKEN_LOCKED, value, knob.cvar)
		end
		return nil
	end
	return values[knob.cvar]
end

-- Sets a knob. `value` is clamped to the knob's range; what the engine kept is
-- remembered, and returned. Returns nil if the knob can't be set. `asTyped`
-- sets a raw knob to exactly `value`, as its box does, and lets a number go
-- past the range of a knob whose box takes one (GoesPast). A danger setting the
-- game doesn't change isn't remembered: nil, and a line with the command to try.
-- A change to a graphics setting has its frame rate read (Measure). A toggle
-- with `with` sets those settings too when it's turned on, and puts them back
-- when it's turned off, in the same change.
function EverySetting.Set(cvar, value, asTyped)
	local knob = EverySetting.Knob(cvar)
	if not CanSetByHand(knob) then return nil end
	if asTyped and knob.raw then
		value = tostring(value)
	else
		value = EverySetting.Normalize(knob, value, asTyped)
	end
	if not value then return nil end
	local old = Read(knob.cvar)
	local kept
	Record(function()
		kept = Change(knob, value)
		for name, with in pairs(kept and knob.with or {}) do
			local other = EverySetting.RawKnob(name, "")
			if not Same(kept, "1") then
				EverySetting.Reset(name)
			elseif CanSetByHand(other) then
				Change(other, with)
			end
		end
	end)
	if kept and not Same(kept, old) and Graphics(knob.cvar) then
		Measure({ knob = knob, from = old, to = kept })
		EverySetting.Changed()
	end
	return kept
end

-- Flags: a flags knob's CVar packs a set of on/off flags into a string. Its
-- first byte is the format's version, and each byte after it holds six flags:
-- bit 6, and a bit for each flag that's on ("\002G" has flags 1, 2 and 3 on).
-- Bytes with no flag on are left off the end. The game sets one flag at a
-- time, by its index from 1 (C_CVar.SetCVarBitfield), and takes the string
-- whole too: Blizzard's own options set these CVars that way, and so does
-- Every Setting when a kept value is set again, undone or reset.
--
-- A few CVars the game locks hold their flags as the bits of a number instead
-- (the group finder's roles: "2" is flag 2 alone, "6" flags 2 and 3), and the
-- game's function for each takes the whole value (SETTERS, `bits`), or sets one
-- flag at a time (PerFlag). "0", nothing and "\002" all have no flag on, but
-- where the game reads 0 as its defaults (SETTERS, `zero`).
--
-- Most of the game's filters keep a flag for each filter that's off, where the
-- game's menu ticks the ones that are on. A menu of ticks does the same with a
-- negative index: box -2 is ticked while flag 2 is off.

-- Where a flag is in the string: its byte's place, and its bit's value in that byte.
local function FlagAt(index)
	return 2 + math.floor((index - 1) / 6), 2 ^ ((index - 1) % 6)
end

-- Whether flag `index` is on in `value`, a flags knob's CVar as the game keeps it:
-- packed, or a number. A packed value never reads as a number but for "0", which
-- has no flag on either way.
function EverySetting.Flag(value, index)
	if index < 0 then return not EverySetting.Flag(value, -index) end
	local n = tonumber(value)
	if n then return math.floor(n / 2 ^ (index - 1)) % 2 == 1 end
	local at, mask = FlagAt(index)
	local byte = (value or ""):byte(at)
	return byte ~= nil and math.floor(byte / mask) % 2 == 1
end

-- `value` with flag `index` on or off, packed the way the game packs it, or as
-- a number if `bits`.
local function WithFlag(value, index, on, bits)
	if EverySetting.Flag(value, index) == on then return value end
	if bits then return ("%d"):format((tonumber(value) or 0) + (on and 1 or -1) * 2 ^ (index - 1)) end
	local at, mask = FlagAt(index)
	if value == "" or value == "0" then value = "\002" end -- never set: the version the 1.60.1 client writes
	value = value .. ("@"):rep(at - #value)
	value = value:sub(1, at - 1) .. string.char(value:byte(at) + (on and mask or -mask)) .. value:sub(at + 1)
	return value:sub(1, 1) .. value:sub(2):gsub("@+$", "")
end

-- Turns one flag of a flags knob on or off, the way Set sets a knob: the
-- packed value the engine then has is remembered, and returned. The game packs
-- the flag itself. Where the CVar can't be set now (in combat, for a secure
-- one, or while a situation holds it) the value is packed here instead. A
-- setting the game locks is set whole, through the game's function for it.
function EverySetting.SetFlag(cvar, index, on)
	local knob = EverySetting.Knob(cvar)
	if not (CanSetByHand(knob) and knob.type == "flags") then return nil end
	on = on and true or false
	if index < 0 then index, on = -index, not on end -- a box that's ticked while its flag is off
	local setter = SETTERS[knob.cvar]
	local packed = WithFlag(EverySetting.Get(cvar) or "", index, on, setter and setter.bits)
	if setter then return Change(knob, packed) end
	return Change(knob, packed, function(_, value)
		if db.under[knob.cvar] ~= nil then return Write(knob, value) end
		C_CVar.SetCVarBitfield(knob.cvar, index, on)
		return Read(knob.cvar)
	end)
end

-- Stops keeping a knob's value, and puts back the one from before Every Setting: or
-- the game's default, if `toDefault`.
local function ResetKnob(knob, toDefault)
	Touch(knob)
	if toDefault then
		local twin = Twin(knob)
		db.before[knob.cvar] = nil
		if twin then db.before[twin] = nil end
	end
	values[knob.cvar] = nil
	if knob.secure and InCombatLockdown() then
		pending[knob.cvar] = false
	else
		pending[knob.cvar] = nil
		Restore(knob)
	end
end

-- Puts a knob back the way it was before Every Setting changed it, and forgets its
-- value. With `toDefault` it goes to the game's default instead, kept or not.
-- The settings a knob's `with` set go back with it, if the profile keeps them.
function EverySetting.Reset(cvar, toDefault)
	local knob = EverySetting.Knob(cvar)
	if not CanSetByHand(knob) then return end
	if not toDefault and values[knob.cvar] == nil then return end
	Record(function()
		ResetKnob(knob, toDefault)
		for name in pairs(knob.with or {}) do
			if EverySetting.IsStored(name) then EverySetting.Reset(name, toDefault) end
		end
	end)
	EverySetting.Changed()
end

-- Resets every knob the profile keeps a value for: to how it was before Every Setting,
-- or to the game's defaults if `toDefault`. Returns how many.
function EverySetting.ResetAll(toDefault)
	if not db then return 0 end
	local count = 0
	Record(function()
		for cvar in pairs(values) do
			local knob = EverySetting.Knob(cvar)
			if CanSetByHand(knob) then
				ResetKnob(knob, toDefault)
				count = count + 1
			end
		end
	end)
	EverySetting.Changed()
	return count
end

-- Where Apply last set a CVar to a value the engine didn't take: CVar -> {
-- want, got, last }, what was set, what the engine kept, and what ChangedBy
-- noted then. While the profile keeps `want` and nothing has changed the CVar
-- since, `got` is the value it should have.
local turnedDown = {}

-- Whether a CVar the profile keeps at `value` has another value now: something
-- has changed it since Every Setting set it. A console command the game can't be
-- asked about has no value until Every Setting gives it one, as at each login.
local function Strayed(cvar, value)
	local now, down = Read(cvar), turnedDown[cvar]
	if now == nil and SETTERS[cvar] and SETTERS[cvar].unread then return true end
	if down and not (Same(down.want, value) and down.last == changedBy[cvar:lower()]) then down = nil end
	return now ~= nil and not Same(now, down and down.got or value)
end

-- Sets every remembered value again: at login, and with Apply now. A secure
-- knob waits for combat to end, and one already waiting is left to wait. A CVar
-- that isn't at Every Setting's value any more was changed by the game (a
-- graphics preset does that): what it is now is what Reset should put back.
-- Returns how many knobs it set, or left waiting for combat to end. With
-- `skip`, a knob it returns true for is left as it is.
local function Apply(skip)
	local count = 0
	for cvar, value in pairs(values) do
		local knob = EverySetting.Knob(cvar)
		if CanSetByHand(knob) and pending[knob.cvar] == nil and not (skip and skip(knob)) then
			local twin = Twin(knob)
			local changed, twinChanged = Strayed(knob.cvar, value), twin and Strayed(twin, value)
			if changed or twinChanged then
				count = count + 1
				if knob.secure and InCombatLockdown() then
					pending[knob.cvar] = value
				else
					if changed then db.before[knob.cvar] = Read(knob.cvar) end
					if twinChanged then db.before[twin] = Read(twin) end
					local was = { changedBy[knob.cvar:lower()], twin and changedBy[twin:lower()] }
					Write(knob, value)
					for i, c in ipairs({ knob.cvar, twin }) do
						-- Turned down by the engine, unless another addon set a value of its
						-- own from inside the write (from CVAR_UPDATE): then it's that addon's.
						local last = changedBy[c:lower()]
						local theirs = last ~= was[i] and last.addon ~= ADDON
						turnedDown[c] = not Same(Read(c), value) and not theirs and { want = value, got = Read(c), last = last } or nil
					end
				end
			end
		end
	end
	return count
end

local function ApplyPending()
	for cvar, value in pairs(pending) do
		local knob = EverySetting.Knob(cvar)
		pending[cvar] = nil
		if value == false then
			Restore(knob)
		else
			values[cvar] = Write(knob, value)
		end
	end
end

-- Restarts the game's graphics, which some changed knobs are waiting for, and
-- updates its window for the ones waiting for that: what the game's own options
-- do when they're applied. (A reload, a login and a game restart are up to the player.)
function EverySetting.RestartGraphics()
	if InCombatLockdown() then return Print(L.WAIT_FOR_COMBAT_CHAT) end
	local owed = EverySetting.restart
	if owed.gx or not owed.window then RestartGx() end
	if owed.window then UpdateWindow() end
	owed.gx, owed.window = nil, nil
	EverySetting.Changed()
end

-------------------------------------------------------------------------------
-- Profiles
-------------------------------------------------------------------------------

-- A profile is a named set of kept values, shared by every character on the
-- account. Each character remembers which one it uses, and changes go straight
-- into that profile.

function EverySetting.GetProfile() return EverySettingCharDB and EverySettingCharDB.profile end

-- The profiles' names: Default first, then the rest by name.
function EverySetting.GetProfiles()
	local names = {}
	for name in pairs(db.profiles) do
		if name ~= DEFAULT_PROFILE then names[#names + 1] = name end
	end
	table.sort(names, function(a, b) return a:lower() < b:lower() end)
	table.insert(names, 1, DEFAULT_PROFILE)
	return names
end

-- The profile called `name`, whatever its case: its name as saved, or nil.
function EverySetting.FindProfile(name)
	if type(name) ~= "string" then return nil end
	name = strtrim(name):lower()
	for existing in pairs(db.profiles) do
		if existing:lower() == name then return existing end
	end
end

-- A new name, trimmed, for a `what` ("profile" or "preset"); or nil, and why
-- it can't be used. `taken` has the names in use as its keys.
local WHY_NOT = { profile = { L.NAME_PROFILE, L.NAME_TAKEN_PROFILE }, preset = { L.NAME_PRESET, L.NAME_TAKEN_PRESET } }
local function NewName(name, what, taken)
	name = strtrim(name or "")
	if name == "" then return nil, WHY_NOT[what][1] end
	if #name > 32 then return nil, L.NAME_TOO_LONG end
	for existing in pairs(taken) do
		if existing:lower() == name:lower() then return nil, WHY_NOT[what][2]:format(existing) end
	end
	return name
end

-- Makes the CVars match the profile `name` and puts it in use.
local function Use(name)
	local target = db.profiles[name]
	-- What only the old profile keeps goes back to how it was before Every Setting...
	for cvar in pairs(values) do
		local knob = EverySetting.Knob(cvar)
		if target[cvar] == nil and CanSetByHand(knob) then
			pending[cvar] = nil
			Restore(knob)
		end
	end
	db.applied, values = name, target
	-- ...and what the new one keeps is set.
	for cvar, value in pairs(target) do
		local knob = EverySetting.RawKnob(cvar, "")
		if CanSetByHand(knob) then
			NoteBefore(knob)
			Write(knob, value)
		end
	end
end

local IN_COMBAT = L.PROFILES_IN_COMBAT

-- Switches this character to the profile `name`. Returns its name, or nil and
-- why not.
function EverySetting.SetProfile(name)
	name = EverySetting.FindProfile(name)
	if not name then return nil, L.NO_SUCH_PROFILE end
	if InCombatLockdown() then return nil, IN_COMBAT end
	EverySettingCharDB.profile = name
	if name ~= db.applied then Use(name) end
	EverySetting.Changed()
	return name
end

-- Saves a copy of the profile in use as `name` and switches to it. Returns
-- why not, if the name can't be used.
function EverySetting.NewProfile(name)
	local newName, why = NewName(name, "profile", db.profiles)
	if not newName then return why end
	local copy = {}
	for cvar, value in pairs(values) do copy[cvar] = value end
	-- The copy keeps what's set already, so no CVar changes.
	db.profiles[newName] = copy
	db.applied, values = newName, copy
	EverySettingCharDB.profile = newName
	EverySetting.Changed()
end

-- Deletes the profile in use and switches to Default, which can't be deleted.
-- Other characters using it switch to Default when they next log in. Returns
-- why not if it can't.
function EverySetting.DeleteProfile()
	local name = db.applied
	if name == DEFAULT_PROFILE then return L.CANT_DELETE_DEFAULT:format(DEFAULT_PROFILE) end
	if InCombatLockdown() then return IN_COMBAT end
	EverySettingCharDB.profile = DEFAULT_PROFILE
	Use(DEFAULT_PROFILE)
	db.profiles[name] = nil
	EverySetting.Changed()
end

-- Sharing: a profile as one line of text, "EverySetting:1:" and then cvar=value
-- pairs separated by commas, in name order. Names and values are %-escaped.
-- Version 2 is the same with settings that aren't CVars among them, which an
-- older Every Setting would take for CVars it doesn't have. A string of CVars
-- alone is still version 1, which every version reads.
local SHARE_VERSION = 2

local function Escape(s)
	return (s:gsub("[^%w_%.%-]", function(c) return ("%%%02X"):format(c:byte()) end))
end

local function Unescape(s)
	return (s:gsub("%%(%x%x)", function(h) return string.char(tonumber(h, 16)) end))
end

-- The CVars in `part` ({ cvar = value }) that an export takes, in name order:
-- all but the danger settings.
local function Exported(part)
	local names = {}
	for cvar in pairs(part) do
		local knob = EverySetting.RawKnob(cvar, "")
		if not (knob and knob.locked) then names[#names + 1] = cvar end
	end
	table.sort(names)
	return names
end

-- The profile in use as a string, or just `part` of it ({ cvar = value }).
-- Danger settings are left out.
function EverySetting.ExportProfile(part)
	part = part or values
	local names = Exported(part)
	local version = 1
	for i, cvar in ipairs(names) do
		if SETTERS[cvar] and SETTERS[cvar].get then version = SHARE_VERSION end
		names[i] = Escape(cvar) .. "=" .. Escape(part[cvar])
	end
	return "EverySetting:" .. version .. ":" .. table.concat(names, ",")
end

-- The same as lines to type in chat or put in a guide, one per setting:
-- /console name value. A value /console can't carry as it is (nothing, or one
-- with a space, a quote, a backslash or a control character in it) gets a /run
-- SetCVar line instead, with each control character written as \ddd. A console
-- command's setting gets its own /console line. Any other setting that isn't a
-- CVar has no such line, and is left out.
function EverySetting.ExportLines(part)
	part = part or values
	local lines = {}
	for _, cvar in ipairs(Exported(part)) do
		local value = tostring(part[cvar])
		if SETTERS[cvar] and SETTERS[cvar].console then
			lines[#lines + 1] = SETTERS[cvar].command(value)
		elseif not (SETTERS[cvar] and SETTERS[cvar].get) then
			if value:match('^[^%s%c"\\]+$') then
				lines[#lines + 1] = ("/console %s %s"):format(cvar, value)
			else
				lines[#lines + 1] = EverySetting.Command(cvar, value):gsub("%c", function(c) return ("\\%03d"):format(c:byte()) end)
			end
		end
	end
	return table.concat(lines, "\n")
end

-- The values in a profile string; or nil, and why it can't be used. Only
-- CVars this client has and lets Every Setting change are taken, and a knob's value
-- is held to its range: also where the knob's box goes past it (GoesPast), since
-- only a value typed there by hand does.
local function DecodeProfile(text)
	local version, body = (text or ""):gsub("%s", ""):match("^EverySetting:(%d+):(.*)$")
	if not version then return nil, L.NOT_A_PROFILE_STRING end
	if tonumber(version) > SHARE_VERSION then return nil, L.NEWER_PROFILE end
	local t, used = {}, 0
	for key, value in body:gmatch("([^,=]+)=([^,]*)") do
		local knob = EverySetting.RawKnob(Unescape(key), "")
		value = Unescape(value)
		if CanSet(knob) then
			if not knob.raw then value = EverySetting.Normalize(knob, value) end
			if value and t[knob.cvar] == nil then
				t[knob.cvar] = value
				used = used + 1
			end
		end
	end
	if used == 0 then return nil, L.PROFILE_DAMAGED end
	return t
end

-- Whether `text` is a profile string, and not lines from a guide.
local function IsProfileString(text)
	return (text or ""):gsub("%s", ""):match("^EverySetting:") ~= nil
end

-------------------------------------------------------------------------------
-- Lines from a guide
-------------------------------------------------------------------------------

-- Hidden settings reach players as lines to type in chat: /console name value,
-- a /run or /script line that calls SetCVar, the SET name "value" of the
-- game's Config.wtf, or just name value. Import takes any of them, one per
-- line, and reads each for a CVar's name and a value. Nothing pasted is ever
-- run: a /run or /script line is read only when it's one call to SetCVar or
-- C_CVar.SetCVar with the name and the value written out, and every line that
-- isn't a setting is skipped and reported.

-- What copying from a web page can leave in a line: zero-width spaces and
-- joiners, byte-order marks, soft hyphens, and the dots some pages show for them.
local INVISIBLE = { "\226\128\139", "\226\128\140", "\226\128\141", "\226\129\160", "\239\187\191", "\194\173", "\194\183" }

local function Clean(line)
	for _, c in ipairs(INVISIBLE) do line = line:gsub(c, "") end
	return strtrim((line:gsub("\194\160", " "))) -- a non-breaking space
end

-- The Lua literal at the start of `s`: a string in quotes or [[ ]], or a plain
-- number. Returns its value as text, the rest of `s`, and whether it's a
-- string. nil if `s` doesn't start with one.
local function ReadLiteral(s)
	local quote = s:sub(1, 1)
	if quote == '"' or quote == "'" then
		local out, i = {}, 2
		while i <= #s do
			local c = s:sub(i, i)
			if c == quote then return table.concat(out), s:sub(i + 1), true end
			if c == "\\" then
				local digits = s:match("^%d%d?%d?", i + 1)
				c = s:sub(i + 1, i + 1)
				if digits and tonumber(digits) < 256 then
					c, i = string.char(tonumber(digits)), i + #digits - 1
				elseif c ~= "\\" and c ~= '"' and c ~= "'" then
					return nil
				end
				i = i + 1
			end
			out[#out + 1] = c
			i = i + 1
		end
		return nil
	end
	local long, rest = s:match("^%[%[(.-)%]%](.*)$")
	if long then return long, rest, true end
	local number
	number, rest = s:match("^(%-?[%d%.]+)(.*)$")
	if number and (number:match("^%-?%d+%.?%d*$") or number:match("^%-?%.%d+$")) then return number, rest, false end
end

-- What a line asks for: "set", a CVar's name and a value ("bare" when the line
-- is just name value); "lua" for a /run or /script line that's anything but
-- one SetCVar call; nil for any other line. The value is nil if there's none.
local function ReadLine(line)
	local slash, rest = line:match("^/(%a+)%s*(.*)$")
	slash = slash and slash:lower()
	if slash == "run" or slash == "script" then
		local fn, args = rest:match("^([%w_%.]+)%s*%((.*)$")
		if fn ~= "SetCVar" and fn ~= "C_CVar.SetCVar" then return "lua" end
		local name, value, text
		name, rest, text = ReadLiteral(args:match("^%s*(.*)$"))
		rest = text and rest:match("^%s*,%s*(.*)$")
		if rest then value, rest = ReadLiteral(rest) end
		if value and rest:match("^%s*%)%s*;?$") then return "set", name, value end
		return "lua"
	end
	local kind = "set"
	if slash ~= "console" then
		if slash then return nil end
		rest, kind = line, "bare"
	end
	local name, value = rest:match("^(%S+)%s*(.-)$")
	if name and name:lower() == "set" then -- the console's set, and Config.wtf's SET
		name, value = value:match("^(%S+)%s*(.-)$")
		kind = "set"
	end
	if not name then return nil end
	value = value:match('^"(.*)"$') or value
	return kind, name, value ~= "" and value or nil
end

-- The console commands this client has that aren't CVars, by lower-case name.
local function Commands()
	local cvarType = Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
	local commands = {}
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.commandType ~= cvarType then commands[info.command:lower()] = true end
	end
	return commands
end

-- The report's parts, in its order: a setting that came out other than its
-- line has it, and each kind of line that set nothing.
local REPORT = {
	{ "changed", L.REPORT_CHANGED },
	{ "cant", L.REPORT_CANT },
	{ "unknown", L.REPORT_UNKNOWN },
	{ "command", L.REPORT_COMMAND },
	{ "lua", L.REPORT_LUA },
	{ "danger", L.REPORT_DANGER },
	{ "locked", L.REPORT_LOCKED },
	{ "elsewhere", L.REPORT_ELSEWHERE },
	{ "again", L.REPORT_AGAIN },
	{ "other", L.REPORT_OTHER },
}

local NOT_READ = L.NOT_READ

-- A line as the report shows it, cut short if it's long.
local function Quote(line)
	if #line <= 60 then return line end
	return (line:sub(1, 57):gsub("[\192-\255][\128-\191]*$", "")) .. "..."
end

-- A console command a pasted line names that has a setting's row (see
-- ConsoleSetting): its knob, and the line's value as the knob takes it. A
-- fontcolor line names its color by class, and gives it as three numbers.
local function CommandSetting(name, value)
	local class, r, g, b = (value or ""):match("^(%a+)%s+(%d+)%s+(%d+)%s+(%d+)$")
	if name:lower() == "fontcolor" then
		if not (class and tonumber(r) < 256 and tonumber(g) < 256 and tonumber(b) < 256) then
			return EverySetting.Knob("@console:fontcolor:" .. (class or "")), value
		end
		return EverySetting.Knob("@console:fontcolor:" .. class), ("FF%02X%02X%02X"):format(tonumber(r), tonumber(g), tonumber(b))
	end
	return EverySetting.Knob("@console:" .. name), value
end

-- How the report names a setting: a console command's by the command (and a
-- color's class), any other by its name.
local function Named(cvar)
	return ((cvar:match("^@console:(.+)$") or cvar):gsub(":", " "))
end

-- Sets what pasted lines set, the way a preset is applied: as one change that
-- Undo takes back, a value held to its knob's range, and a locked or danger
-- setting left alone. With `fits`, only the CVars it returns true for are
-- taken. With `preset`, they're saved as a preset by that name too. Returns
-- why not, if no line could be read; or else nil and the report, a list of
-- lines with a summary first.
local function ImportLines(text, fits, preset)
	if InCombatLockdown() then return L.IMPORT_IN_COMBAT end
	local t, typed, found, commands = {}, {}, {}, Commands()
	local function Note(what, item)
		found[what] = found[what] or {}
		table.insert(found[what], item)
	end
	for pasted in (text or ""):gmatch("[^\r\n]+") do
		local line = Clean(pasted)
		if line ~= "" then
			local kind, name, value = ReadLine(line)
			local knob = name and EverySetting.RawKnob(name, "")
			if name and not knob then knob, value = CommandSetting(name, value) end
			if kind == "lua" then
				Note("lua", Quote(line))
			elseif not kind then
				Note("other", Quote(line))
			elseif not (knob and knob.found) then
				if commands[name:lower()] then
					Note("command", Quote(line))
				else
					Note(kind == "bare" and "other" or "unknown", kind == "bare" and Quote(line) or name)
				end
			elseif value == nil then
				Note("other", Quote(line))
			elseif knob.locked then
				Note("danger", knob.cvar)
			elseif EverySetting.IsLocked(knob.cvar) then
				Note("locked", Named(knob.cvar))
			elseif fits and not fits(knob.cvar) then
				Note("elsewhere", Named(knob.cvar))
			else
				local normal = knob.raw and value or EverySetting.Normalize(knob, value)
				if not normal then
					Note("cant", (SETTERS[knob.cvar] and SETTERS[knob.cvar].console or knob.cvar) .. " " .. value)
				else
					if t[knob.cvar] then Note("again", Named(knob.cvar)) end
					t[knob.cvar], typed[knob.cvar] = normal, value
				end
			end
		end
	end
	local count, read = 0, false
	for _ in pairs(t) do count = count + 1 end
	for what in pairs(found) do read = read or what ~= "other" end
	if count == 0 and not read then return NOT_READ end

	local h = History()
	local last = h.undo[#h.undo]
	if count > 0 then
		if preset then db.presets[preset] = t end
		EverySetting.ApplyPreset(t)
		for cvar, value in pairs(typed) do
			if not Same(values[cvar], value) then Note("changed", L.REPORT_TYPED_KEPT:format(Named(cvar), value, tostring(values[cvar]))) end
		end
		if found.changed then table.sort(found.changed) end
	end
	local report = { L.NOTHING_SET }
	if count > 0 then
		local set = preset and (count == 1 and L.SET_PRESET_ONE or L.SET_PRESET):format(count, preset)
			or (count == 1 and L.SET_ONE or L.SET):format(count)
		report[1] = set .. " " .. (h.undo[#h.undo] ~= last and L.IMPORT_UNDO or L.IMPORT_SAME)
	end
	for _, part in ipairs(REPORT) do
		local items = found[part[1]]
		if items then
			if #report > 1 then report[#report + 1] = "" end
			report[#report + 1] = ("%s (%d):"):format(part[2], #items)
			for _, item in ipairs(items) do report[#report + 1] = "  " .. item end
		end
	end
	return nil, report
end

-- Makes a new profile from an exported string, and switches to it. Lines from
-- a guide are set in the profile in use instead (ImportLines). Returns why not,
-- if the name or the text can't be used; for lines, nil and the report.
function EverySetting.ImportProfile(name, text)
	if not IsProfileString(text) then return ImportLines(text) end
	local newName, why = NewName(name, "profile", db.profiles)
	if not newName then return why end
	if InCombatLockdown() then return IN_COMBAT end
	local t
	t, why = DecodeProfile(text)
	if not t then return why end
	db.profiles[newName] = t
	EverySetting.SetProfile(newName)
end

-- Sets each of `source`'s values ({ cvar = value }) and keeps it in the
-- profile in use. For use inside Record.
local function Keep(source)
	for cvar, value in pairs(source) do
		local knob = EverySetting.RawKnob(cvar, "")
		if CanSetByHand(knob) then
			Touch(knob)
			NoteBefore(knob)
			values[knob.cvar] = Write(knob, value)
		end
	end
end

-- Makes the profile in use keep what the profile `name` keeps, and nothing else.
function EverySetting.CopyProfile(name)
	local source = db.profiles[EverySetting.FindProfile(name) or ""]
	if not source or source == values then return end
	if InCombatLockdown() then return Print(L.WAIT_FOR_COMBAT_CHAT) end
	Record(function()
		for cvar in pairs(values) do
			local knob = EverySetting.Knob(cvar)
			if source[cvar] == nil and CanSetByHand(knob) then ResetKnob(knob) end
		end
		Keep(source)
	end)
	EverySetting.Changed()
end

-------------------------------------------------------------------------------
-- Situations
-------------------------------------------------------------------------------

-- A situation uses one of the saved presets while it's on: in combat, mounted,
-- in a city or inn, or in an instance. Its values are only borrowed. They never
-- go into a profile, `before` or Undo, and when it ends each CVar goes back to
-- the value underneath (db.under), unless something else has changed it since.
-- When two are on, the one higher in the list wins a CVar. Secure CVars (which
-- can't change in combat) and ones that need a restart are left out.
--
-- EverySettingDB, the account's:
--   situations[key]  the name of the preset each situation uses
--   under[cvar]      while a situation holds a CVar: the value it goes back to

local inCombat = false -- from the combat events: InCombatLockdown() is still false as combat starts

-- Highest first. Each one: its key in the saved variables, its name in the
-- window, whether it's on now, and the events that can turn it on or off.
-- Every situation is checked again at each loading screen, and as combat starts
-- and ends. To add a situation, add a line.
--
-- `preset` is the situation's own, built in: what it sets if it's picked for it
-- (db.situations[key] = true). None is picked until the player picks one. Each
-- value is held to the knob's range in the game it's set in (EverySetting.Fit),
-- so a slider's top is retail's in retail. None is secure or needs a restart.
-- `sets` says in a few words what it does, for its menu.
EverySetting.SITUATIONS = {
	{ key = "combat", label = L.SITUATION_COMBAT, on = function() return inCombat end,
	  sets = L.SITUATION_COMBAT_SETS, preset = {
		nameplateShowEnemies = 1, -- the enemies' nameplates, for the fight only
		weatherDensity = 0, -- no rain or snow in the way
		cameraDistanceMaxZoomFactor = 4, -- room to zoom out on the whole fight (retail's top is 2.6)
	  } },
	{ key = "mounted", label = L.SITUATION_MOUNTED, on = function() return IsMounted() end,
	  events = { "PLAYER_MOUNT_DISPLAY_CHANGED" },
	  sets = L.SITUATION_MOUNTED_SETS, preset = {
		farclip = 10000, -- see where you're going: the game's top level of view distance
		horizonStart = 4000, -- the same for the horizon
		horizonClip = 10000,
		cameraDistanceMaxZoomFactor = 4, -- room to zoom out round a big mount
	  } },
	{ key = "resting", label = L.SITUATION_RESTING, on = function() return IsResting() end,
	  events = { "PLAYER_UPDATE_RESTING" },
	  sets = L.SITUATION_RESTING_SETS, preset = {
		spellVisualDensityFilterSetting = 2, -- Reduced spell effects: a crowd's, as the game's Medium level sets it
		particleDensity = 50, -- the game's middle level of particles, where crowds cost frames
	  } },
	{ key = "instance", label = L.SITUATION_INSTANCE, on = function() return (IsInInstance()) end,
	  sets = L.SITUATION_INSTANCE_SETS, preset = {
		advancedCombatLogging = 1, -- the detail log sites ask for, while combat is logged (/combatlog)
		weatherDensity = 0, -- no rain or snow in the way
	  } },
}

-- The preset a situation uses: its own, a saved one, or nil for none. Its own
-- values are held to this game's ranges here; a saved one's are as saved.
local function SituationPreset(s)
	local name = db.situations[s.key]
	if name ~= true then return db.presets[name or ""] end
	local preset = {}
	for cvar, value in pairs(s.preset) do
		local knob = EverySetting.RawKnob(cvar, "")
		local fit = knob and EverySetting.Fit(knob, value)
		if fit then preset[cvar] = fit end
	end
	return preset
end

local started = false -- situations start once the character is in the world
local active = {} -- key -> whether the situation is on
local over = {} -- CVar -> { value = what a situation set, kept = what the engine kept, by = its label }

-- What the situations that are on want: CVar -> { value, by }.
local function Wanted()
	local want = {}
	for i = #EverySetting.SITUATIONS, 1, -1 do
		local s = EverySetting.SITUATIONS[i]
		local preset = active[s.key] and SituationPreset(s)
		for cvar, value in pairs(preset or {}) do
			local knob = EverySetting.RawKnob(cvar, "")
			if CanSet(knob) and not knob.secure and not knob.restart then
				want[knob.cvar] = { value = value, by = s.label }
				local twin = Twin(knob)
				if twin then want[twin] = want[knob.cvar] end
			end
		end
	end
	return want
end

local QueuePutBack -- see Putting kept values back

-- Stops holding a CVar. The value underneath goes back, unless something else
-- has changed the CVar since: then that stays, and may be put back.
local function Release(cvar)
	if Same(C_CVar.GetCVar(cvar), over[cvar].kept) then C_CVar.SetCVar(cvar, db.under[cvar]) else QueuePutBack() end
	over[cvar], db.under[cvar] = nil, nil
end

local function Resolve()
	local want = Wanted()
	for cvar in pairs(over) do
		if not want[cvar] then Release(cvar) end
	end
	for cvar, w in pairs(want) do
		local held = over[cvar]
		if held and held.value == w.value then
			held.by = w.by -- set already: not again, in case something else has changed it
		else
			if not held then db.under[cvar] = C_CVar.GetCVar(cvar) end
			C_CVar.SetCVar(cvar, w.value)
			over[cvar] = { value = w.value, kept = C_CVar.GetCVar(cvar), by = w.by }
		end
	end
	EverySetting.Changed()
end

local function UpdateSituations()
	if not started then return end
	for _, s in ipairs(EverySetting.SITUATIONS) do active[s.key] = s.on() and true or false end
	Resolve()
end

-- At login: puts back what the last session's situations held. A logout puts
-- it back already, but a crash doesn't.
local function Recover()
	for cvar, value in pairs(db.under) do
		if C_CVar.GetCVar(cvar) ~= nil then C_CVar.SetCVar(cvar, value) end
	end
	wipe(db.under)
end

-- At logout (and /reload): each held CVar goes back to the value underneath,
-- so that's the one the game saves. The record stays for Recover, in case the
-- game doesn't save it.
local function Unhold()
	for cvar, held in pairs(over) do
		if Same(C_CVar.GetCVar(cvar), held.kept) then
			C_CVar.SetCVar(cvar, db.under[cvar])
		else
			db.under[cvar] = nil
		end
	end
end

-- The name of the preset a situation uses (nil for none), whether it's on now,
-- and whether the preset is the situation's own (named L.SITUATION_OWN).
function EverySetting.GetSituation(key)
	local name = db.situations[key]
	if name == true then return L.SITUATION_OWN, active[key] or false, true end
	return name, active[key] or false, false
end

-- Makes a situation use the saved preset `name`, its own if `name` is true, or
-- none if it's nil.
function EverySetting.SetSituation(key, name)
	db.situations[key] = name
	UpdateSituations()
end

-- If a situation holds the CVar now: the value it set, and the situation's name.
function EverySetting.Held(cvar)
	local knob = EverySetting.Knob(cvar)
	local held = knob and over[knob.cvar]
	if held then return held.kept, held.by end
end

-- What you've changed since login (this session's changes to the profile in
-- use, which Undo can take back) that a situation can use: CVar -> its value
-- now. Also each changed CVar's state at login, for putting it back.
local function Changes()
	local first = {}
	for _, changes in ipairs(History().undo) do
		for _, change in ipairs(changes) do
			if first[change.cvar] == nil then first[change.cvar] = change.from end
		end
	end
	local twins = {} -- a raid twin goes along with its knob
	for cvar in pairs(first) do
		local knob = EverySetting.Knob(cvar)
		if knob and knob.raid then twins[knob.raid:lower()] = true end
	end
	local found = {}
	for cvar, was in pairs(first) do
		local knob = EverySetting.RawKnob(cvar, "")
		local now = Read(cvar)
		if not twins[cvar:lower()] and CanSet(knob) and not knob.secure and not knob.restart and not Same(now, was.value) then
			found[knob.cvar] = now
		end
	end
	return found, first
end

-- What you've changed since login that a situation can use: CVar -> value.
function EverySetting.Changes()
	return (Changes())
end

-- Gives the situation `key` what you've changed since login: it's added to the
-- situation's preset (one named after the situation if it has none), and put
-- back in the profile the way it was at login, as one change for Undo. In the
-- situation the settings look just as before. Returns how many settings and
-- the preset's name, or nil and why not.
function EverySetting.TakeChanges(key)
	local situation
	for _, s in ipairs(EverySetting.SITUATIONS) do
		if s.key == key then situation = s end
	end
	if not situation then return nil, L.NO_SUCH_SITUATION end
	if InCombatLockdown() then return nil, L.WAIT_FOR_COMBAT end
	local found, first = Changes()
	if not next(found) then return nil, L.NO_CHANGES_FOR_SITUATION end
	local name = db.situations[key]
	if name == true or not db.presets[name or ""] then
		-- A new preset, named after the situation: from its own preset's values
		-- if it was using that, so your changes go on top of them.
		local own = name == true and SituationPreset(situation) or {}
		name = situation.label
		local n = 1
		while not NewName(name, "preset", db.presets) do
			n = n + 1
			name = situation.label .. " " .. n
		end
		db.presets[name] = own
	end
	local preset, count = db.presets[name], 0
	Record(function()
		for cvar, value in pairs(found) do
			local knob = EverySetting.RawKnob(cvar, "")
			preset[cvar] = value
			count = count + 1
			Touch(knob)
			for _, c in ipairs({ knob.cvar, Twin(knob) }) do
				local was = first[c]
				if was then
					values[c], db.before[c] = was.kept, was.before
					Put(c, was.value)
				end
			end
		end
	end)
	db.situations[key] = name
	UpdateSituations()
	EverySetting.Changed()
	return count, name
end

-------------------------------------------------------------------------------
-- Who changed a setting
-------------------------------------------------------------------------------

-- Each change made through C_CVar.SetCVar (the game's SetCVar calls it) or
-- C_CVar.SetCVarBitfield is put down to what made it, from the stack: the
-- first addon on it that isn't one of Blizzard's; or else a line of Lua typed
-- in chat or run by a macro; or else the game. A CVar that changes some other
-- way (/console, the engine) is put down to the console or the game. Only the
-- name is kept, for this session: what changed a CVar before Every Setting
-- loaded isn't known.
--
-- The game sends CVAR_UPDATE during a write that changes the CVar, before the
-- hooks are called, and none for one that changes nothing (seen in 1.60.1).

local SCRIPT, GAME, CONSOLE = L.BY_SCRIPT, L.BY_GAME, L.BY_CONSOLE
local told = {} -- CVar -> true once another addon's change to it was told in chat

-- What made the change the hook below was called for: an addon's folder name
-- (nil if it wasn't one), and the words for it.
local function Caller()
	-- From the hook's caller on: 1 is this function, 2 the hook.
	local stack = debugstack(3) or ""
	for addon in stack:gmatch("AddOns[\\/]([^\\/]+)[\\/]") do
		if not addon:find("^Blizzard_") then return addon, addon == ADDON and L.ADDON_NAME or addon end
	end
	-- /run, typed or in a macro, runs its line through RunScript.
	return nil, stack:find("RunScript", 1, true) and SCRIPT or GAME
end

-- A knob as a line in chat calls it: "View distance (farclip)", or just its CVar.
-- A setting that isn't a CVar by its name alone ("Text size").
local function Name(knob)
	if knob.calls then return knob.label end
	return knob.label ~= knob.cvar and ("%s (%s)"):format(knob.label, knob.cvar) or knob.cvar
end

-- Says once a session, per setting, when another addon changes one the profile keeps.
local function Tell(cvar, addon, now)
	local knob = EverySetting.Knob(cvar)
	if not (started and knob and values[knob.cvar] ~= nil) or told[knob.cvar] then return end
	local want = over[knob.cvar] and over[knob.cvar].kept or values[knob.cvar]
	if Same(now, want) then return end
	told[knob.cvar] = true
	-- A packed set of flags is no value to show.
	local change = knob.type == "flags" and L.TOLD_FLAGS:format(addon, Name(knob)) or L.TOLD:format(addon, Name(knob), now, want)
	-- Put back leaves a setting that isn't a CVar alone, as it does one waiting for a restart.
	Print("%s %s", change, db.putBack and not knob.restart and not knob.calls and L.TOLD_PUT_BACK or L.TOLD_AT_LOGIN)
end

-- After a write: noted if CVAR_UPDATE came during it. Another change inside it
-- (from another addon's CVAR_UPDATE) is noted first, and stays the last.
local function Noted(cvar)
	if type(cvar) ~= "string" or not heard[cvar:lower()] then return end
	heard[cvar:lower()] = nil
	local now = C_CVar.GetCVar(cvar)
	local addon, by = Caller()
	changedBy[cvar:lower()] = { addon = addon, by = by, value = now }
	if db and addon and addon ~= ADDON then Tell(cvar, addon, now) end
end
hooksecurefunc(C_CVar, "SetCVar", Noted)
hooksecurefunc(C_CVar, "SetCVarBitfield", Noted)

-- A console command's setting (pitchLimit, fontsize...) sends no CVAR_UPDATE. The
-- game's /console and its console window both run their line through ConsoleExec
-- (Blizzard_ChatFrameBase's SlashCommands.lua, Blizzard_Console.lua), and so does
-- any addon or /run line, so a line for one is noted here as a CVar's change is:
-- what made it (the console, when it was none of those), and for one the game
-- can't be asked about, the value it was given. The window shows it at once.
local function Ran(line)
	local command, rest = tostring(line or ""):match("^%s*(%S+)%s*(.-)%s*$")
	if not command or rest == "" then return end
	local knob, value = CommandSetting(command, rest)
	local setter = knob and SETTERS[knob.cvar]
	if not (setter and setter.line and setter.line(value)) then return end -- one the command can't take changes nothing
	local addon, by = Caller()
	if by == GAME then by = CONSOLE end
	if setter.unread then given[knob.cvar] = value end
	local now = Read(knob.cvar)
	changedBy[knob.cvar:lower()] = { addon = addon, by = by, value = now }
	if addon == ADDON then return end -- Every Setting's own change refreshes the window after it
	if db and addon then Tell(knob.cvar, addon, now) end
	EverySetting.Changed()
end
hooksecurefunc("ConsoleExec", Ran)

-- A little after CVAR_UPDATE: a CVar it named that no hook noted changed some
-- other way, unless it has the value last noted.
local function Unheard()
	for cvar in pairs(heard) do
		heard[cvar] = nil
		local now, last = C_CVar.GetCVar(cvar), changedBy[cvar]
		if now ~= nil and not (last and Same(last.value, now)) then changedBy[cvar] = { by = CONSOLE, value = now } end
	end
end

-- What last changed a CVar since Every Setting loaded: the addon's folder name
-- (EverySetting for its own changes), or nil if it wasn't an addon; and the
-- words for it ("Leatrix_Plus", "Every Setting", "the game"...). Nothing if
-- no change has been seen.
function EverySetting.ChangedBy(cvar)
	local last = type(cvar) == "string" and changedBy[cvar:lower()]
	if last then return last.addon, last.by end
end

-------------------------------------------------------------------------------
-- Presets
-------------------------------------------------------------------------------

-- The names of the built-in presets, lowest first. A knob's `tiers` has a
-- value for each.
EverySetting.TIERS = { L.LOW, L.MEDIUM, L.HIGH, L.ULTRA }

-- A locked setting is one that styles and presets leave alone. It can still be
-- changed by hand, and Undo, Reset all, profiles and situations treat it as
-- before. Locks are the account's, not a profile's. (Not knob.locked: that's
-- the game not letting a CVar be set at all.)

-- Whether styles and presets leave this setting alone.
function EverySetting.IsLocked(cvar)
	local knob = EverySetting.RawKnob(cvar, "")
	return db ~= nil and knob ~= nil and db.locked[knob.cvar] == true
end

-- Locks a setting, or unlocks it.
function EverySetting.SetLocked(cvar, on)
	local knob = EverySetting.RawKnob(cvar, "")
	if not (db and knob) then return end
	db.locked[knob.cvar] = on and true or nil
	EverySetting.Changed()
end

-- Locks every setting in `cvars` (a list), or unlocks them, with one refresh
-- for them all.
function EverySetting.SetLockedList(cvars, on)
	if not db then return end
	for _, cvar in ipairs(cvars) do
		local knob = EverySetting.RawKnob(cvar, "")
		if knob then db.locked[knob.cvar] = on and true or nil end
	end
	EverySetting.Changed()
end

-- Sets a preset's values ({ cvar = value }) and keeps them in the profile in
-- use, as one change for Undo. The rest of the profile is left alone, and so
-- is a locked setting (with its raid twin, which is set along with it) and a
-- danger one, in danger mode or not. A value past the range of a knob whose box
-- takes one (a saved preset can hold what was typed there) is held to the range.
-- With `name`, what the window calls it, one that sets a graphics setting has its
-- frame rate read (Measure); `whole` says it's that style, whole, and the
-- reading is remembered (StyleFramerate).
function EverySetting.ApplyPreset(preset, name, whole)
	if InCombatLockdown() then return Print(L.WAIT_FOR_COMBAT_CHAT) end
	local unlocked, graphics = {}, false
	for cvar, value in pairs(preset) do
		local knob = EverySetting.RawKnob(cvar, "")
		if knob and EverySetting.Past(knob, value) then value = EverySetting.Normalize(knob, value) end
		if not EverySetting.IsLocked(cvar) and not (knob and knob.locked) then
			unlocked[cvar] = value
			graphics = graphics or Graphics(cvar)
		end
	end
	Record(function() Keep(unlocked) end)
	if name and graphics then Measure({ label = name, whole = whole }) end
	EverySetting.Changed()
end

-- Keeps each CVar in `cvars` (a list) at the value it has now, in the profile
-- in use, as one change for Undo: the window's Keep these. Nothing is set.
-- Danger settings are left out, and so is what the profile keeps already. A
-- knob's raid twin at another value is kept at its own, so the knob doesn't
-- set it at the next login. Returns how many it kept.
function EverySetting.KeepAsIs(cvars)
	if InCombatLockdown() then
		Print(L.WAIT_FOR_COMBAT_CHAT)
		return 0
	end
	local count = 0
	Record(function()
		for _, cvar in ipairs(cvars) do
			local knob = EverySetting.RawKnob(cvar, "")
			if CanSet(knob) and values[knob.cvar] == nil then
				Touch(knob)
				NoteBefore(knob)
				local twin = Twin(knob)
				if twin and not Same(Read(twin), Read(knob.cvar)) then values[twin] = Read(twin) end
				values[knob.cvar] = Read(knob.cvar)
				count = count + 1
			end
		end
	end)
	EverySetting.Changed()
	return count
end

-- The built-in styles, filled in by Styles.lua: presets that span sections.
-- Each is { name, tip, tier, set }.
EverySetting.STYLES = {}

-- A style as a preset ({ cvar = value }): the value its `set` gives a knob, or
-- else the knob's value in the built-in preset it starts from (`tier`), held to
-- this client's range (Fit). Knobs the client lacks and danger settings are
-- left out. With `part` (one of EverySetting.GROUPS), just that part of the
-- style: the group's knobs.
function EverySetting.StylePreset(style, part)
	local preset = {}
	for _, group in ipairs(part and { part } or EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			local value = style.set[knob.cvar]
			if value == nil and knob.tiers then value = knob.tiers[style.tier] end
			if value ~= nil and knob.found and not knob.locked then preset[knob.cvar] = EverySetting.Fit(knob, value) end
		end
	end
	return preset
end

-- The saved presets: name -> { cvar = value }. To read, not to change.
function EverySetting.GetPresets() return db.presets end

-- A new preset's name, or nil and why it can't be used.
local function NewPresetName(name)
	local newName, why = NewName(name, "preset", db.presets)
	for _, tier in ipairs(EverySetting.TIERS) do
		if newName and newName:lower() == tier:lower() then return nil, L.TIER_NAME_TAKEN:format(tier) end
	end
	return newName, why
end

-- Saves `preset` ({ cvar = value }) under `name`. Returns why not, if it can't.
function EverySetting.SavePreset(name, preset)
	local newName, why = NewPresetName(name)
	if not newName then return why end
	local copy = {}
	for cvar, value in pairs(preset) do copy[cvar] = value end
	if next(copy) == nil then return L.NOTHING_TO_SAVE end
	db.presets[newName] = copy
	EverySetting.Changed()
end

-- Deletes a saved preset. Situations that use it stop.
function EverySetting.DeletePreset(name)
	db.presets[name] = nil
	for key, preset in pairs(db.situations) do
		if preset == name then db.situations[key] = nil end
	end
	UpdateSituations()
	EverySetting.Changed()
end

-- Saves an exported string, or lines from a guide, as the preset `name`, and
-- applies it. With `fits`, only the CVars it returns true for are taken.
-- Returns why not, if the name or the text can't be used; for lines, nil and
-- the report (ImportLines).
function EverySetting.ImportPreset(name, text, fits)
	local newName, why = NewPresetName(name)
	if not newName then return why end
	if InCombatLockdown() then return L.PRESET_IN_COMBAT end
	if not IsProfileString(text) then return ImportLines(text, fits, newName) end
	local t
	t, why = DecodeProfile(text)
	if not t then return why end
	for cvar in pairs(t) do
		if fits and not fits(cvar) then t[cvar] = nil end
	end
	if next(t) == nil then return L.NOTHING_BELONGS end
	db.presets[newName] = t
	EverySetting.ApplyPreset(t)
end

-------------------------------------------------------------------------------
-- Finding ranges (for developing the knob list)
-------------------------------------------------------------------------------

-- Sets `cvar` to `low` and then `high`, and returns what the engine kept for
-- each. The old value is put back.
function EverySetting.Probe(cvar, low, high)
	local old = C_CVar.GetCVar(cvar)
	if old == nil then return nil end
	C_CVar.SetCVar(cvar, low)
	local keptLow = C_CVar.GetCVar(cvar)
	C_CVar.SetCVar(cvar, high)
	local keptHigh = C_CVar.GetCVar(cvar)
	C_CVar.SetCVar(cvar, old)
	return keptLow, keptHigh
end

-- Saves every CVar the client has (name, value, default, category, help and
-- flags) and its other console commands (name, type, category and help) in the
-- saved variables, so the lists can be read from disk after a /reload.
local function Dump()
	local cvarType = Enum and Enum.ConsoleCommandType and Enum.ConsoleCommandType.Cvar or 0
	local list, commands = {}, {}
	for _, info in ipairs(ConsoleGetAllCommands()) do
		if info.commandType == cvarType then
			local value, default, account, character, locked, secure, readOnly = C_CVar.GetCVarInfo(info.command)
			list[#list + 1] = {
				name = info.command, value = value, default = default,
				category = info.category, help = info.help,
				account = account or nil, character = character or nil,
				locked = locked or nil, secure = secure or nil, readOnly = readOnly or nil,
			}
		else
			commands[#commands + 1] = { name = info.command, commandType = info.commandType, category = info.category, help = info.help }
		end
	end
	local function ByName(a, b) return a.name:lower() < b.name:lower() end
	table.sort(list, ByName)
	table.sort(commands, ByName)
	local version, build = GetBuildInfo()
	db.dump = { version = version, build = build, client = EverySetting.Client(), cvars = list, commands = commands }
	Print(L.DUMP_SAVED, #list, #commands, ADDON)
end

-- Probes every knob's CVar at its range's ends and one step past them, and
-- reports the knobs whose range isn't what the engine keeps. The results are
-- saved too. A setting that isn't a CVar is left out.
local function Check()
	local results, wrong = {}, 0
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			if CanSet(knob) and not knob.calls and not (knob.secure and InCombatLockdown()) then
				local r = { cvar = knob.cvar }
				if knob.type == "slider" then
					local min, max = EverySetting.Bounds(knob)
					local step = knob.step or 1
					r.min, r.max = EverySetting.Probe(knob.cvar, min, max)
					r.below, r.above = EverySetting.Probe(knob.cvar, min - step, max + step)
					r.ok = Same(r.min, min) and Same(r.max, max)
				else
					local tries = { "0", "1" }
					if knob.type == "choice" then
						tries = {}
						for i, option in ipairs(knob.options) do tries[i] = tostring(option[1]) end
					end
					r.ok, r.kept = true, {}
					for i, value in ipairs(tries) do
						r.kept[i] = EverySetting.Probe(knob.cvar, value, value)
						r.ok = r.ok and Same(r.kept[i], value)
					end
				end
				if not r.ok then
					wrong = wrong + 1
					Print(L.CHECK_WRONG, knob.cvar)
				end
				results[#results + 1] = r
			end
		end
	end
	db.check = results
	Print(L.CHECK_DONE, #results, wrong)
end

-------------------------------------------------------------------------------
-- The game's experimental camera settings
-------------------------------------------------------------------------------

-- Changing a test_camera CVar brings up the game's warning about experimental
-- camera settings. Its Disable button (ResetTestCvars) puts every one of them
-- back to its default. The profile in use stops keeping them then, or Every Setting
-- would set them again at the next login and the warning would come back.
if ResetTestCvars then
	hooksecurefunc("ResetTestCvars", function()
		if not db then return end
		for cvar in pairs(values) do
			if cvar:lower():find("^test_camera") then values[cvar], db.before[cvar] = nil, nil end
		end
		EverySetting.Changed()
	end)
end

-- The warning can be hidden instead, for every character. Hiding it leaves the
-- settings on: the Disable button isn't pressed.
--
-- The game's UI shows it on an event it routes through GameEvent. While it's
-- hidden that event is let go, so the popup never opens: one closed as it opens
-- still makes its open and close sounds. Blizzard's own handler is left in place
-- unless the warning was hidden this session.
local WARNING_EVENT = "EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED"
local warningUnrouted = false

local function RouteWarning()
	local game = GameEvent
	if not (game and game.UnregisterInternalEvent and game.RegisterInternalEvent) then return end
	if db.hideCameraWarning and not warningUnrouted then
		game.UnregisterInternalEvent(WARNING_EVENT)
		warningUnrouted = true
	elseif not db.hideCameraWarning and warningUnrouted then
		game.RegisterInternalEvent(WARNING_EVENT, function(...) game.HandleExperimentalCVarConfirmationNeeded(...) end)
		warningUnrouted = false
	end
end

function EverySetting.GetHideCameraWarning()
	return db.hideCameraWarning == true
end

function EverySetting.SetHideCameraWarning(on)
	db.hideCameraWarning = on and true or nil
	RouteWarning()
	if on and StaticPopup_Hide then StaticPopup_Hide("EXPERIMENTAL_CVAR_WARNING") end
	EverySetting.Changed()
end

-- The window's size, for every character: from 75% to 150%.
EverySetting.MIN_SCALE, EverySetting.MAX_SCALE = 0.75, 1.5

local function ClampScale(s)
	return math.min(EverySetting.MAX_SCALE, math.max(EverySetting.MIN_SCALE, s))
end

function EverySetting.GetScale()
	return ClampScale(tonumber(db.scale) or 1)
end

function EverySetting.SetScale(s)
	s = math.floor(ClampScale(s) * 100 + 0.5) / 100
	db.scale = s ~= 1 and s or nil
end

-- In case the warning comes some other way, it's closed as it opens.
if StaticPopup_Show then
	hooksecurefunc("StaticPopup_Show", function(which)
		if which == "EXPERIMENTAL_CVAR_WARNING" and db and db.hideCameraWarning then
			StaticPopup_Hide(which)
		end
	end)
end

-------------------------------------------------------------------------------
-- Danger mode
-------------------------------------------------------------------------------

-- A danger setting (knob.danger) is one Every Setting leaves alone: the game's
-- server enforces it, or the client says it's locked or read-only. Danger mode,
-- for every character, lets those be changed by hand, and a value set that way
-- is kept and set again at login like any other. Styles, presets, situations,
-- imports and exports leave them alone whether it's on or off.

function EverySetting.GetDanger()
	return db.danger == true
end

-- Turning it off leaves the CVars as they are, and nothing keeps them any more.
function EverySetting.SetDanger(on)
	db.danger = on and true or nil
	if not on then
		local function Drop(t)
			for cvar in pairs(t) do
				local knob = EverySetting.RawKnob(cvar, "")
				if knob and knob.locked then t[cvar] = nil end
			end
		end
		for _, profile in pairs(db.profiles) do Drop(profile) end
		Drop(pending)
		Drop(db.before)
	end
	EverySetting.Changed()
end

-- A value as a line of Lua has it: a number bare, text in quotes, a list in braces.
local function Literal(value)
	if type(value) == "table" then
		local items = {}
		for i, item in ipairs(value) do items[i] = Literal(item) end
		return "{" .. table.concat(items, ", ") .. "}"
	elseif type(value) == "string" then
		return '"' .. value:gsub('[\\"]', "\\%0") .. '"'
	end
	return tostring(value)
end

-- Whether a setting has a command to type in chat: every CVar has, and a setting
-- that isn't one where its entry in SETTERS gives one (each of them does).
function EverySetting.HasCommand(cvar)
	local setter = SETTERS[cvar]
	if setter and setter.set then return setter.command ~= nil end
	return type(cvar) == "string" and cvar:sub(1, 1) ~= "@"
end

-- The command that sets a CVar to `value`, to type in chat: the game's own
-- function for it where it has one, or else SetCVar. Nil for a setting with none.
function EverySetting.Command(cvar, value)
	if not EverySetting.HasCommand(cvar) then return nil end
	value = tostring(value)
	local _, args, setter = Setter(cvar, value)
	if args and setter.command then return setter.command(value, EverySetting.Knob(cvar)) end
	if args then
		for i, arg in ipairs(args) do args[i] = Literal(arg) end
		local api = setter[1] == "_G" and "" or setter[1] .. "."
		return ("/run %s%s(%s)"):format(api, setter[2], table.concat(args, ", "))
	end
	-- A plain number goes in bare. One Lua would read back as something else (007,
	-- or more digits than it holds) is quoted like text, so the CVar gets it as it is.
	if tostring(tonumber(value)) ~= value then value = Literal(value) end
	return ('/run SetCVar("%s", %s)'):format(cvar, value)
end

-------------------------------------------------------------------------------
-- /kui
-------------------------------------------------------------------------------

-- /kui opens the window too, but only while no other addon has the command
-- (KeyUI and KeyboardUI Next register it). When two addons register the same
-- command the game picks one of them, so Every Setting takes /kui at login, once
-- every addon has loaded, and gives it up if one that loads later has it.
local function ClaimKui()
	local taken = false
	for name in pairs(SlashCmdList) do
		local i = 1
		while name ~= "EVERYSETTINGKUI" and _G["SLASH_" .. name .. i] do
			if _G["SLASH_" .. name .. i]:lower() == "/kui" then taken = true end
			i = i + 1
		end
	end
	if not taken then
		SLASH_EVERYSETTINGKUI1, SlashCmdList.EVERYSETTINGKUI = "/kui", SlashCmdList.EVERYSETTING
	elseif SlashCmdList.EVERYSETTINGKUI then
		SLASH_EVERYSETTINGKUI1, SlashCmdList.EVERYSETTINGKUI = nil, nil
		-- The chat box may already have looked /kui up and remembered ours.
		if hash_SlashCmdList and hash_SlashCmdList["/KUI"] == SlashCmdList.EVERYSETTING then
			hash_SlashCmdList["/KUI"] = nil
		end
	end
end

-------------------------------------------------------------------------------
-- Events
-------------------------------------------------------------------------------

local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("VARIABLES_LOADED")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("PLAYER_REGEN_DISABLED")
events:RegisterEvent("PLAYER_REGEN_ENABLED")
events:RegisterEvent("CVAR_UPDATE")
events:RegisterEvent("PLAYER_LOGOUT")
local situationEvents = {} -- the events that can turn a situation on or off
for _, s in ipairs(EverySetting.SITUATIONS) do
	for _, event in ipairs(s.events or {}) do
		events:RegisterEvent(event)
		situationEvents[event] = true
	end
end

local loggedIn = false -- remembered values are set once per login or reload
local variablesLoaded, enteredWorld = false, false -- the two events may come in either order
local refreshQueued = false

-- The window's refresh after CVAR_UPDATE, which waits while the left mouse
-- button is down: redrawing the list then would cancel the click under way.
-- Seen in 1.60.1: with TurnSpeed kept past the server's cap, the game changes
-- it every frame, and no Run button in the list could be clicked.
local function RefreshAfterUpdate()
	if IsMouseButtonDown("LeftButton") then return C_Timer.After(0.1, RefreshAfterUpdate) end
	refreshQueued = false
	Unheard()
	EverySetting.Changed()
end
local lostProfile -- the deleted profile this character was using, told at login
local switchAfterCombat = false -- this character's profile still has to be put in use

-- At login, and with Apply now: if another character's profile is set in the
-- client, this character's is put in use instead. Otherwise its values are set
-- again. Returns how many Apply set. `skip` goes to Apply.
local function Login(skip)
	local count = 0
	if EverySettingCharDB.profile == db.applied then
		count = Apply(skip)
	elseif InCombatLockdown() then
		switchAfterCombat = true
	else
		Use(EverySettingCharDB.profile)
	end
	if lostProfile then
		Print(L.PROFILE_LOST, lostProfile, DEFAULT_PROFILE)
		lostProfile = nil
	end
	return count
end

-- The first login's work, once the knobs are read and the character is in the
-- world, whichever comes last.
local function FirstLogin()
	if loggedIn or not (variablesLoaded and enteredWorld) then return end
	loggedIn = true
	inCombat = InCombatLockdown()
	-- What the game knows of a setting that isn't a CVar can come later than its
	-- CVars (the minimap's tracking): those are read again now.
	for _, knob in pairs(BY_CVAR) do
		if knob.calls then ReadKnob(knob) end
	end
	Recover()
	Login()
	started = true
	ClaimKui()
	UpdateSituations()
	EverySetting.Changed()
end

-- Sets every value the profile keeps again now, with login's rules: /every
-- apply, and Apply now in the window and the minimap entry's menu. It isn't a
-- change of yours, so Undo doesn't take it back. Returns how many settings it
-- set, or left waiting for combat to end.
function EverySetting.ApplyNow()
	if not loggedIn then return 0 end
	local count = Login()
	EverySetting.Changed()
	return count
end

-- The settings the profile keeps that something else has changed since Every
-- Setting set them, a list of knobs: what Apply now would set again. Not one
-- waiting for combat to end, nor one a situation holds (Read looks underneath
-- it), nor one at the value the engine kept when it turned Every Setting's down.
function EverySetting.Overwritten()
	local list = {}
	if not loggedIn then return list end
	for cvar, value in pairs(values) do
		local knob = EverySetting.Knob(cvar)
		local twin = knob and Twin(knob)
		if CanSetByHand(knob) and pending[knob.cvar] == nil and (Strayed(knob.cvar, value) or twin and Strayed(twin, value)) then
			list[#list + 1] = knob
		end
	end
	return list
end

-- Putting kept values back: with db.putBack on (for every character), a kept
-- setting something else changes is set again by itself, a second after the
-- last CVAR_UPDATE, so a preset that writes twenty CVars is answered once. It
-- runs what Apply now runs, but:
--   * one setting changed alone by the game's own code while its Options are
--     open is the player's change: it's kept at its new value, and that's told
--   * a setting whose change waits for a restart is left to Apply now, and so is
--     one that isn't a CVar: no CVAR_UPDATE says when it changes, or who changed it
--   * a setting put back more than ROUNDS times, each within FIGHT seconds of
--     the last, is being fought over: it's left alone until the next login,
--     and that's told
local PUT_BACK_AFTER, ROUNDS, FIGHT = 1, 3, 10
local changing = {} -- lower-case CVar -> true, for each CVAR_UPDATE since the last put-back
local putBackAt -- when the put-back that's queued is due
local fights = {} -- CVar -> { n = rounds, at = when it was last put back }
local givenUp = {} -- CVar -> true once a fight over it was given up

local function Skip(knob)
	local setter = SETTERS[knob.cvar]
	return knob.restart ~= nil or (setter and setter.get) ~= nil or givenUp[knob.cvar] == true
end

local function PutBack()
	local names = {} -- what changed, but for Every Setting's own writes
	for cvar in pairs(changing) do
		if EverySetting.ChangedBy(cvar) ~= ADDON then names[#names + 1] = cvar end
	end
	wipe(changing)
	if not (loggedIn and db.putBack) then return end
	local list, strays = EverySetting.Overwritten(), {}
	for _, knob in ipairs(list) do strays[knob.cvar:lower()] = knob end
	local mine = #names == 1 and strays[names[1]]
	local addon, by = EverySetting.ChangedBy(names[1] or "")
	if mine and not addon and by == GAME and SettingsPanel and SettingsPanel:IsShown() then
		values[mine.cvar] = Read(mine.cvar)
		Print(L.YOU_CHANGED, Name(mine), mine.type == "flags" and L.WHAT_YOU_PICKED or values[mine.cvar])
	else
		mine = nil
	end
	local now = GetTime()
	for _, knob in ipairs(list) do
		if knob ~= mine and not Skip(knob) then
			local fight = fights[knob.cvar]
			if not (fight and now - fight.at < FIGHT) then fight = { n = 0 } end
			fight.n, fight.at = fight.n + 1, now
			fights[knob.cvar] = fight
			if fight.n > ROUNDS then
				givenUp[knob.cvar] = true
				local other, words = EverySetting.ChangedBy(knob.cvar)
				Print("%s%s", L.FIGHT:format(words and (words:gsub("^%l", string.upper)) or L.SOMETHING, Name(knob)),
					other and " " .. L.FIGHT_TURN_OFF:format(other) or "")
			end
		end
	end
	Login(Skip)
	EverySetting.Changed()
end

-- Puts back what's changed a second after the last CVAR_UPDATE.
function QueuePutBack()
	local queued = putBackAt ~= nil
	putBackAt = GetTime() + PUT_BACK_AFTER
	if queued then return end
	local function Due()
		local left = putBackAt - GetTime()
		if left > 0.01 then return C_Timer.After(left, Due) end
		putBackAt = nil
		PutBack()
	end
	C_Timer.After(PUT_BACK_AFTER, Due)
end

function EverySetting.GetPutBack()
	return db.putBack == true
end

-- Whether a change something else makes to a setting the profile keeps is put back.
function EverySetting.PutsBack(cvar)
	local knob = EverySetting.Knob(cvar)
	return db.putBack == true and knob ~= nil and values[knob.cvar] ~= nil and not Skip(knob)
end

-- Turning it on puts back what has changed already.
function EverySetting.SetPutBack(on)
	db.putBack = on and true or nil
	wipe(changing)
	if on and loggedIn then QueuePutBack() end
	EverySetting.Changed()
end

events:SetScript("OnEvent", function(_, event, arg1)
	if event == "ADDON_LOADED" then
		if arg1 ~= ADDON then
			if loggedIn then ClaimKui() end -- an addon loaded late may have /kui
			return
		end
		if type(EverySettingDB) ~= "table" then EverySettingDB = {} end
		db = EverySettingDB
		if type(db.profiles) ~= "table" then db.profiles = {} end
		if type(db.values) == "table" then -- from before there were profiles
			db.profiles[DEFAULT_PROFILE] = db.profiles[DEFAULT_PROFILE] or db.values
			db.values = nil
		end
		if type(db.profiles[DEFAULT_PROFILE]) ~= "table" then db.profiles[DEFAULT_PROFILE] = {} end
		if type(db.profiles[db.applied]) ~= "table" then db.applied = DEFAULT_PROFILE end
		values = db.profiles[db.applied]
		if type(db.before) ~= "table" then db.before = {} end
		if type(db.presets) ~= "table" then db.presets = {} end
		if type(db.situations) ~= "table" then db.situations = {} end
		if type(db.under) ~= "table" then db.under = {} end
		if type(db.locked) ~= "table" then db.locked = {} end
		if type(db.folded) ~= "table" then db.folded = {} end
		if type(db.fps) ~= "table" then db.fps = {} end
		-- This character's profile. One deleted on another character is gone.
		if type(EverySettingCharDB) ~= "table" then EverySettingCharDB = {} end
		local mine = EverySettingCharDB.profile
		if type(mine) ~= "string" or type(db.profiles[mine]) ~= "table" then
			if type(mine) == "string" then lostProfile = mine end
			EverySettingCharDB.profile = DEFAULT_PROFILE
		end
		-- What /every dump and check saved was read from disk last session.
		db.dump, db.check = nil, nil
		RouteWarning()

	elseif event == "VARIABLES_LOADED" then
		ReadKnobs()
		-- Values kept for CVars that aren't in Knobs.lua need a knob too.
		for cvar in pairs(values) do EverySetting.RawKnob(cvar, "") end
		variablesLoaded = true
		FirstLogin()

	elseif event == "PLAYER_ENTERING_WORLD" then
		-- Also after every loading screen, which may lead into or out of an instance.
		enteredWorld = true
		if loggedIn then
			UpdateSituations()
			EverySetting.Changed()
		else
			FirstLogin()
		end

	elseif event == "PLAYER_REGEN_ENABLED" then
		if switchAfterCombat then
			switchAfterCombat = false
			Use(EverySettingCharDB.profile)
		end
		ApplyPending()
		inCombat = false
		UpdateSituations()
		EverySetting.Changed()

	elseif event == "PLAYER_REGEN_DISABLED" then
		inCombat = true
		UpdateSituations()
		EverySetting.Changed()

	elseif situationEvents[event] then
		UpdateSituations()

	elseif event == "PLAYER_LOGOUT" then
		Unhold()

	elseif event == "CVAR_UPDATE" then
		-- Something changed a CVar (the options menu, a preset, another addon).
		-- Show it, but don't fight it. A preset changes many at once.
		local knob = EverySetting.Knob(arg1)
		if knob then sent[knob.cvar] = nil end -- the game has answered a late setter
		if type(arg1) == "string" then heard[arg1:lower()] = true end
		if type(arg1) == "string" and loggedIn and db.putBack then
			changing[arg1:lower()] = true
			QueuePutBack()
		end
		if refreshQueued then return end
		refreshQueued = true
		C_Timer.After(0.1, RefreshAfterUpdate)
	end
end)

-------------------------------------------------------------------------------
-- Slash commands
-------------------------------------------------------------------------------

SLASH_EVERYSETTING1 = "/every"
SLASH_EVERYSETTING2 = "/everysetting"
SlashCmdList.EVERYSETTING = function(msg)
	msg = strtrim(msg or "")
	local cmd, rest = msg:match("^(%S*)%s*(.-)$")
	cmd = cmd:lower()

	if (cmd == "" or cmd == "options" or cmd == "config") and EverySetting_OpenOptions then
		EverySetting_OpenOptions()
	elseif cmd == "apply" then
		local count = EverySetting.ApplyNow()
		if count == 0 then return Print(L.APPLY_NONE) end
		Print("%s%s", (count == 1 and L.APPLY_DONE_ONE or L.APPLY_DONE):format(count),
			InCombatLockdown() and next(pending) and " " .. L.APPLY_COMBAT or "")
	elseif cmd == "putback" then
		rest = rest:lower()
		if rest ~= "" and rest ~= "on" and rest ~= "off" then return Print(L.USAGE_PUTBACK) end
		local on
		if rest == "" then on = not EverySetting.GetPutBack() else on = rest == "on" end
		EverySetting.SetPutBack(on)
		Print(on and L.PUTBACK_ON or L.PUTBACK_OFF)
	elseif cmd == "reset" then
		Print(L.RESET_DONE, EverySetting.ResetAll())
	elseif cmd == "undo" or cmd == "redo" then
		local done = cmd == "undo" and EverySetting.Undo() or cmd == "redo" and EverySetting.Redo()
		if not done and not InCombatLockdown() then Print(cmd == "undo" and L.NOTHING_TO_UNDO or L.NOTHING_TO_REDO) end
	elseif cmd == "profile" then
		if rest == "" then
			local list = EverySetting.GetProfiles()
			for i, name in ipairs(list) do
				if name == EverySetting.GetProfile() then list[i] = "|cffffffff" .. name .. "|r " .. L.IN_USE end
			end
			return Print(L.PROFILES_LIST, table.concat(list, ", "))
		end
		local name, why = EverySetting.SetProfile(rest)
		Print(name and L.NOW_USING:format(name) or why)
	elseif cmd == "situations" then
		local list = {}
		for _, s in ipairs(EverySetting.SITUATIONS) do
			local name, on = EverySetting.GetSituation(s.key)
			list[#list + 1] = (on and L.SITUATION_ON or L.SITUATION):format(s.label, name or L.NO_PRESET)
		end
		Print(L.SITUATIONS_LIST, table.concat(list, ", "))
	elseif cmd == "warning" then
		rest = rest:lower()
		if rest ~= "" and rest ~= "on" and rest ~= "off" then return Print(L.USAGE_WARNING) end
		local hide
		if rest == "" then hide = not EverySetting.GetHideCameraWarning() else hide = rest == "off" end
		EverySetting.SetHideCameraWarning(hide)
		Print(hide and L.WARNING_HIDDEN or L.WARNING_SHOWN)
	elseif cmd == "danger" then
		rest = rest:lower()
		if rest ~= "" and rest ~= "on" and rest ~= "off" then return Print(L.USAGE_DANGER) end
		local on
		if rest == "" then on = not EverySetting.GetDanger() else on = rest == "on" end
		EverySetting.SetDanger(on)
		Print(on and L.DANGER_ON or L.DANGER_OFF)
	elseif cmd == "dump" then
		Dump()
	elseif cmd == "probe" then
		local cvar, low, high = rest:match("^(%S+)%s+(%S+)%s+(%S+)$")
		if not cvar then return Print(L.USAGE_PROBE) end
		if InCombatLockdown() then return Print(L.PROBE_IN_COMBAT) end
		local knob = EverySetting.RawKnob(cvar, "")
		if knob and knob.locked and not EverySetting.GetDanger() then
			return Print(L.PROBE_DANGER, knob.cvar)
		end
		local keptLow, keptHigh = EverySetting.Probe(cvar, low, high)
		if keptLow == nil then return Print(L.NO_SUCH_CVAR, cvar) end
		Print(L.PROBE_RESULT,
			cvar, low, keptLow, high, keptHigh, tostring(C_CVar.GetCVar(cvar)))
	elseif cmd == "check" then
		Check()
	else
		Print(L.HELP)
		for _, line in ipairs({ L.HELP_OPEN, L.HELP_APPLY, L.HELP_PUTBACK, L.HELP_RESET, L.HELP_UNDO, L.HELP_PROFILE,
			L.HELP_SITUATIONS, L.HELP_WARNING, L.HELP_DANGER, L.HELP_PROBE, L.HELP_CHECK, L.HELP_DUMP }) do
			Print("  " .. line)
		end
	end
end

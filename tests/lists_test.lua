-- The lists the game locks and changes an entry at a time: the recipes tracked, the
-- tutorials shown, the group finder's languages and the advanced filter's dungeons left
-- out, and the dungeon finder's dungeons. Every Setting reads each as the game has it, as
-- its entries in order, and changes it with a call for each entry that differs.

local T = ...
local W = dofile("tests/wow.lua")

local RECIPES, RECRAFTS, TUTORIALS = "trackedProfessionRecipes", "trackedProfessionRecraftRecipes", "flaggedTutorials"
local QUESTS = "hardTrackedQuests"
local LANGUAGES, REMOVED, DUNGEONS = "lfgListSearchLanguages", "lfgListAdvancedFilterRemovedActivities", "lfdSelectedDungeons"
local LISTS = { RECIPES, RECRAFTS, TUTORIALS, LANGUAGES, REMOVED, DUNGEONS, QUESTS }

local calls -- each call to the game's functions for a list: "name args"
local game -- what the game has: recipes[recraft], tutorials, languages, activities (ticked)

local function Call(name, ...)
	local args = {}
	for i = 1, select("#", ...) do args[i] = tostring((select(i, ...))) end
	calls[#calls + 1] = name .. " " .. table.concat(args, ",")
end

local function Has(list, id)
	for i, have in ipairs(list) do
		if have == id then return i end
	end
end

local function Copy(list)
	local copy = {}
	for i, v in ipairs(list) do copy[i] = v end
	return copy
end

-- A list as the game writes it in a CVar: "v21", then four base-93 digits from "#" for each.
local function Encode(list)
	local out = { "v21" }
	for _, n in ipairs(list) do
		local digits = ""
		for _ = 1, 4 do
			digits = string.char(35 + n % 93) .. digits
			n = math.floor(n / 93)
		end
		out[#out + 1] = digits
	end
	return table.concat(out)
end

-- The game's functions for these lists, as the 1.60.1 client has them (seen in game): the
-- recipes and tutorials change in the game's getters at once, and in their CVars only at
-- the next reload; the advanced filter, when it's saved, writes the dungeons it leaves out
-- (of the one this client offers, 285); a dungeon picked in the dungeon finder is a flag
-- of its CVar, its ID counted from 0; a quest in the log watched by hand has watch type 1,
-- Manual, and one the game watched by itself 0. An ID of 99 is one the game doesn't take.
local function Lists()
	calls = {}
	game = { recipes = { [false] = {}, [true] = {} }, tutorials = {}, languages = {}, activities = { 285 },
		log = { [179] = true, [783] = true, [3361] = true }, watches = {} }
	_G.C_QuestLog = {
		GetNumQuestWatches = function() return #game.watches end,
		GetQuestIDForQuestWatchIndex = function(i) return game.watches[i] and game.watches[i][1] end,
		GetQuestWatchType = function(id)
			for _, watch in ipairs(game.watches) do
				if watch[1] == id then return watch[2] end
			end
		end,
		AddQuestWatch = function(id)
			Call("AddQuestWatch", id)
			if not game.log[id] then return false end
			for _, watch in ipairs(game.watches) do
				if watch[1] == id then watch[2] = 1 return true end
			end
			game.watches[#game.watches + 1] = { id, 1 }
			return true
		end,
		RemoveQuestWatch = function(id)
			Call("RemoveQuestWatch", id)
			for i, watch in ipairs(game.watches) do
				if watch[1] == id then table.remove(game.watches, i) return true end
			end
			return false
		end,
	}
	_G.C_TradeSkillUI = {
		GetRecipesTracked = function(recraft) return Copy(game.recipes[recraft]) end,
		SetRecipeTracked = function(id, tracked, recraft)
			Call("SetRecipeTracked", id, tracked, recraft)
			local list = game.recipes[recraft]
			if tracked and id ~= 99 and not Has(list, id) then list[#list + 1] = id end
			if not tracked and Has(list, id) then table.remove(list, Has(list, id)) end
		end,
	}
	_G.IsTutorialFlagged = function(id) return Has(game.tutorials, id) ~= nil end
	_G.FlagTutorial = function(id)
		Call("FlagTutorial", id)
		if id ~= 99 and not Has(game.tutorials, id) then game.tutorials[#game.tutorials + 1] = id end
	end
	_G.ResetTutorials = function()
		Call("ResetTutorials")
		game.tutorials = {}
	end
	_G.C_LFGList = {
		GetLanguageSearchFilter = function()
			local enabled = {}
			for lang in pairs(game.languages) do enabled[lang] = true end
			return enabled
		end,
		SaveLanguageSearchFilter = function(enabled)
			local langs = {}
			for lang, on in pairs(enabled) do
				if on then langs[#langs + 1] = lang end
			end
			table.sort(langs)
			Call("SaveLanguageSearchFilter", table.concat(langs, " "))
			game.languages = {}
			for _, lang in ipairs(langs) do game.languages[lang] = true end
			W.cvars.lfglistsearchlanguages.value = game.languages.esMX and "128" or "0"
		end,
		GetAdvancedFilter = function() return { needsTank = false, minimumRating = 0, activities = Copy(game.activities) } end,
		SaveAdvancedFilter = function(options)
			Call("SaveAdvancedFilter", table.concat(options.activities, " "))
			game.activities = Copy(options.activities)
			W.cvars[REMOVED:lower()].value = Encode(Has(game.activities, 285) and {} or { 285 })
		end,
	}
	_G.SetLFGDungeonEnabled = function(id, on)
		Call("SetLFGDungeonEnabled", id, on)
		local cvar = W.cvars[DUNGEONS:lower()]
		local bytes = { 2 }
		for i = 2, #cvar.value do bytes[i] = cvar.value:byte(i) end
		local at, bit = 2 + math.floor(id / 6), 2 ^ (id % 6)
		for i = #bytes + 1, at do bytes[i] = 64 end
		local set = math.floor(bytes[at] / bit) % 2 == 1
		if on and not set then bytes[at] = bytes[at] + bit elseif not on and set then bytes[at] = bytes[at] - bit end
		while #bytes > 1 and bytes[#bytes] == 64 do bytes[#bytes] = nil end
		cvar.value = string.char(unpack(bytes))
	end
end

-- A logged-in client in danger mode with these lists, each with its line from CVars.lua.
-- `saved` is last session's saved variables, and `setup(game)` changes what the game has
-- as the client starts.
local function Start(saved, setup)
	saved = saved or {}
	saved.danger = true
	local EverySetting, ns = W.Load(saved)
	for _, cvar in ipairs({ RECIPES, RECRAFTS, TUTORIALS, REMOVED, QUESTS }) do W.AddCVar(cvar, "", { locked = true }) end
	W.AddCVar(LANGUAGES, "0", { locked = true })
	W.AddCVar(DUNGEONS, "", { locked = true })
	W.cvars[TUTORIALS:lower()].value = "v21###$###5###4"
	EverySetting.GROUPS = {}
	Lists()
	game.tutorials = { 1, 18, 17 }
	if setup then setup(game) end
	W.Login()
	EverySetting.AllGroups()
	return EverySetting, ns.Options
end

local function Calls()
	local text = table.concat(calls, "; ")
	calls = {}
	return text
end

-- Runs a command as the game's chat would: the Lua after /run.
local function Type(command)
	assert(#command <= 255, "longer than chat takes: " .. command)
	assert((loadstring or load)(assert(command:match("^/run (.*)$"), command)))()
end

T.test("lists: a list reads as the game's getter has it, and a change is a call for each entry that differs", function()
	local EverySetting = Start(nil, function(g) g.recipes[false] = { 7 } end)
	local knob = EverySetting.Knob(RECIPES)
	T.eq(knob.setter, true)
	T.eq(knob.type, "text", "a box")
	T.eq(knob.default, "", "an empty list")
	T.eq(EverySetting.Get(RECIPES), "7", "the game's list, not the CVar's text")
	T.eq(EverySetting.Get(TUTORIALS), "1 17 18", "in order")
	T.eq(EverySetting.Set(RECIPES, "9001, 2538 7", true), "7 2538 9001", "in order, whatever order it's typed in")
	T.eq(Calls(), "SetRecipeTracked 2538,true,false; SetRecipeTracked 9001,true,false", "only the two the game didn't have")
	T.eq(EverySetting.Before(RECIPES), "7")
	T.ok(EverySetting.IsStored(RECIPES))
	T.eq(EverySetting.Set(RECIPES, "2538 10", true), "10 2538")
	T.eq(Calls(), "SetRecipeTracked 7,false,false; SetRecipeTracked 9001,false,false; SetRecipeTracked 10,true,false")
	T.ok(EverySetting.Undo())
	T.eq(EverySetting.Get(RECIPES), "7 2538 9001", "Undo goes through the game's functions")
	T.ok(EverySetting.Redo())
	T.eq(EverySetting.Get(RECIPES), "10 2538")
	EverySetting.Reset(RECIPES)
	T.eq(EverySetting.Get(RECIPES), "7", "Reset: the list from before")
	T.ok(not EverySetting.IsStored(RECIPES))
	T.eq(EverySetting.Get(RECRAFTS), "", "the recrafts are a list of their own")
	T.eq(EverySetting.Set(RECRAFTS, "2538", true), "2538")
	T.eq(Calls():match("SetRecipeTracked 2538,true,true$") ~= nil, true)
	for _, cvar in ipairs(LISTS) do T.eq(W.SetCount(cvar), 0, cvar .. ": SetCVar isn't tried") end
end)

T.test("lists: the same entries in another order are the same list, and one the game doesn't take is left out", function()
	local EverySetting = Start(nil, function(g) g.recipes[false] = { 7, 6 } end)
	W.chat = {}
	T.eq(EverySetting.Set(RECIPES, "7 6", true), "6 7")
	T.eq(#calls, 0, "nothing to call")
	T.eq(#W.chat, 0, "and nothing said")
	T.eq(EverySetting.Set(RECIPES, "6 7 99", true), nil, "the game didn't take 99")
	T.eq(Calls(), "SetRecipeTracked 99,true,false")
	T.ok(W.chat[1]:find("didn't take", 1, true) and W.chat[1]:find("t.SetRecipeTracked(99,true,false)", 1, true), W.chat[1])
	T.eq(EverySetting.GetKept()[RECIPES], "6 7", "what was kept stays")
	T.eq(EverySetting.Set(RECIPES, "6 99", true), "6", "7 taken off, and 99 left out")
end)

T.test("lists: a kept list is put back at login, whatever was tracked since", function()
	local saved = { profiles = { Default = { [RECIPES] = "2538 9001", [TUTORIALS] = "1 17" } },
		before = { [RECIPES] = "", [TUTORIALS] = "1 17 18" } }
	local EverySetting = Start(saved, function(g) g.recipes[false] = { 9001, 4 } end)
	T.eq(EverySetting.Get(RECIPES), "2538 9001")
	T.eq(EverySetting.Get(TUTORIALS), "1 17")
	local text = table.concat(calls, "; ")
	T.ok(text:find("SetRecipeTracked 4,false,false; SetRecipeTracked 2538,true,false", 1, true), "4, tracked since, is taken off: " .. text)
	T.ok(text:find("ResetTutorials ; FlagTutorial 1; FlagTutorial 17", 1, true), "18, shown since, is taken off: " .. text)
	T.eq(EverySetting.Before(RECIPES), "4 9001", "what Reset puts back now")
	-- Nothing to do when the game has the list kept.
	Start({ profiles = { Default = { [RECIPES] = "2538" } }, before = { [RECIPES] = "" } }, function(g) g.recipes[false] = { 2538 } end)
	T.eq(#calls, 0)
end)

T.test("lists: the tutorials are added one at a time, and all taken off to take one off", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set(TUTORIALS, "1 2 17 18", true), "1 2 17 18")
	T.eq(Calls(), "FlagTutorial 2", "one added")
	T.eq(EverySetting.Set(TUTORIALS, "1 17 18", true), "1 17 18")
	T.eq(Calls(), "ResetTutorials ; FlagTutorial 1; FlagTutorial 17; FlagTutorial 18", "none takes one off")
	T.eq(EverySetting.Command(TUTORIALS, "1 17 18"), "/run local f=FlagTutorial ResetTutorials() f(1) f(17) f(18)")
end)

T.test("lists: the group finder's languages are saved whole, by name", function()
	local EverySetting = Start()
	T.eq(EverySetting.Get(LANGUAGES), "", "none ticked: the CVar's 0")
	T.eq(EverySetting.Set(LANGUAGES, "esMX ptBR", true), "esMX ptBR")
	T.eq(Calls(), "SaveLanguageSearchFilter esMX ptBR")
	T.eq(C_CVar.GetCVar(LANGUAGES), "128")
	EverySetting.Reset(LANGUAGES)
	T.eq(C_CVar.GetCVar(LANGUAGES), "0")
	T.eq(EverySetting.Command(LANGUAGES, "esMX ptBR"), "/run C_LFGList.SaveLanguageSearchFilter({esMX=true,ptBR=true})")
end)

T.test("lists: the advanced filter's dungeons left out are the CVar the game writes, changed through the filter", function()
	local EverySetting = Start()
	T.eq(EverySetting.Get(REMOVED), "", "v21, nothing left out")
	T.eq(EverySetting.Set(REMOVED, "285", true), "285")
	T.eq(Calls(), "SaveAdvancedFilter ", "285 unticked")
	T.eq(C_CVar.GetCVar(REMOVED), "v21##&)", "as the game writes it")
	T.eq(EverySetting.Command(REMOVED, ""), "/run local f=C_LFGList.GetAdvancedFilter() f.activities={285} C_LFGList.SaveAdvancedFilter(f)")
	EverySetting.Reset(REMOVED)
	T.eq(Calls(), "SaveAdvancedFilter 285", "ticked again")
	T.eq(C_CVar.GetCVar(REMOVED), "v21")
end)

T.test("lists: the dungeon finder's dungeons are a flag for each, set one at a time", function()
	local EverySetting = Start()
	T.eq(EverySetting.Set(DUNGEONS, "13 5", true), "5 13")
	T.eq(Calls(), "SetLFGDungeonEnabled 5,true; SetLFGDungeonEnabled 13,true")
	T.eq(C_CVar.GetCVar(DUNGEONS), "\002`@B", "dungeon 5 is flag 6, and 13 flag 14")
	T.eq(EverySetting.Set(DUNGEONS, "13", true), "13")
	T.eq(Calls(), "SetLFGDungeonEnabled 5,false")
	EverySetting.Reset(DUNGEONS)
	T.eq(C_CVar.GetCVar(DUNGEONS), "\002", "none, as the game writes it")
	T.eq(EverySetting.Get(DUNGEONS), "")
end)

T.test("lists: the quests watched by hand are watched and unwatched one at a time, and the game's own watches left alone", function()
	local EverySetting = Start(nil, function(g) g.watches = { { 783, 0 }, { 179, 1 } } end)
	T.eq(EverySetting.Get(QUESTS), "179", "783, which the game watches by itself, isn't one")
	T.eq(EverySetting.Set(QUESTS, "179 3361", true), "179 3361")
	T.eq(Calls(), "AddQuestWatch 3361")
	T.eq(EverySetting.Set(QUESTS, "3361 99", true), "3361", "99 isn't in the quest log")
	T.eq(Calls(), "RemoveQuestWatch 179; AddQuestWatch 99")
	EverySetting.Reset(QUESTS)
	T.eq(EverySetting.Get(QUESTS), "179")
	T.eq(game.watches[1][1], 783, "the game's own watch is still there")
	Type(EverySetting.Command(QUESTS, "3361"))
	T.eq(EverySetting.Get(QUESTS), "3361", "the command takes off the watches by hand only")
	T.eq(game.watches[1][1], 783)
end)

T.test("lists: each command is one line of chat that takes the list off and sets what it says", function()
	local EverySetting = Start(nil, function(g) g.recipes[false], g.recipes[true] = { 4 }, { 4 } end)
	EverySetting.Set(DUNGEONS, "7", true)
	local values = { [RECIPES] = "2538 9001", [RECRAFTS] = "2538", [TUTORIALS] = "1 2 17 18", [LANGUAGES] = "esMX",
		[REMOVED] = "285", [DUNGEONS] = "5 13", [QUESTS] = "179 783 3361" }
	for _, cvar in ipairs(LISTS) do
		for _, value in ipairs({ values[cvar], "" }) do
			Type(EverySetting.Command(cvar, value))
			T.eq(EverySetting.Get(cvar), value, cvar .. " after its command for " .. value)
		end
	end
end)

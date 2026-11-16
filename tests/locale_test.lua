-- The locale table (Locales/enUS.lua): Every Setting's own words are all in it, by key,
-- and nothing it shows in the window, its tooltips or in chat is written anywhere else.

local T = ...
local W = dofile("tests/wow.lua")

local function Read(path)
	local f = assert(io.open(path))
	local text = f:read("*a")
	f:close()
	return text
end

-- The addon's Lua files outside Locales/.
local CODE = {}
for _, path in ipairs(T.lines("find EverySetting -name '*.lua' | sort")) do
	if not path:find("/Locales/") then CODE[#CODE + 1] = path end
end

-- The string literals in Lua source, outside its comments: { line, text } each.
local function Literals(source)
	local out, i, line = {}, 1, 1
	local function Lines(s) for _ in s:gmatch("\n") do line = line + 1 end end
	while i <= #source do
		local c = source:sub(i, i)
		if source:sub(i, i + 1) == "--" then
			local eq = source:match("^%-%-%[(=*)%[", i)
			local stop = eq and select(2, source:find("]" .. eq .. "]", i, true)) or (source:find("\n", i, true) or #source + 1) - 1
			Lines(source:sub(i, stop))
			i = stop + 1
		elseif c == '"' or c == "'" then
			local j, text = i + 1, {}
			while source:sub(j, j) ~= c do
				if source:sub(j, j) == "\\" then j = j + 1 end
				text[#text + 1] = source:sub(j, j)
				j = j + 1
			end
			out[#out + 1] = { line, table.concat(text) }
			i = j + 1
		elseif source:match("^%[=*%[", i) then
			local eq = source:match("^%[(=*)%[", i)
			local s, e = source:find("]" .. eq .. "]", i, true)
			out[#out + 1] = { line, source:sub(i + #eq + 2, s - 1) }
			Lines(source:sub(i, e))
			i = e + 1
		else
			if c == "\n" then line = line + 1 end
			i = i + 1
		end
	end
	return out
end

-- What counts as words for people: a string literal in the addon's code that, with
-- its colour codes and its %s and %d taken out, has a word with a small letter in it
-- beside a space ("Reset all", "a /run line"), or is one capitalised word ("Reset").
-- Code doesn't count: a line the addon writes out for the player to type, which starts
-- with / ("/run SetCVar(...)"), or Lua, which has a call or an = straight after a name
-- ("local f=", "pairs(f)"). One word in small letters can't be told from a name the code
-- goes by ("toggle", "farclip"), so it doesn't count here: the test below puts up every
-- text with a marked locale, and finds those that reach the window, a tooltip or chat.
local function IsWords(text)
	text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("%%[-%d%.]*[sdf]", "")
	if text:find("^/") or text:find("^%)") or text:find("[%w_%]%)]=") or text:find("[%w_]%(") then return false end
	return text:find("%a*%l%a*%s") ~= nil or text:find("%s%a*%l") ~= nil or text:find("^%u%l+$") ~= nil
end

-- The capitalised words the code may have: names, not text. Each is what the game or
-- the saved variables know something by, and none is translated.
local NAMES = {
	Default = "the default profile's name, the key the saved variables keep it under",
	Frame = "a kind of frame, for CreateFrame", Button = "the same",
	Version = "the .toc field the Options page reads the version from",
	-- The item qualities: the settings' own names ("@color:Epic"), and Enum.ColorOverride's order.
	Poor = "", Common = "", Uncommon = "", Rare = "", Epic = "", Legendary = "",
	-- The minimap's tracking filters, by their names in Enum.MinimapTrackingFilter.
	Auctioneer = "", Banker = "", Barber = "", Battlemaster = "", Innkeeper = "", Mailbox = "", Repair = "",
	Stablemaster = "", Transmogrifier = "", Target = "", Focus = "", Digsites = "",
}

T.test("locale: no words for people are written outside the locale table", function()
	local found = {}
	for _, path in ipairs(CODE) do
		for _, literal in ipairs(Literals(Read(path))) do
			if IsWords(literal[2]) and not NAMES[literal[2]] then found[#found + 1] = ("%s:%d: %q"):format(path, literal[1], literal[2]) end
		end
	end
	T.eq(table.concat(found, "\n"), "", "words outside Locales/enUS.lua")
end)

T.test("locale: the test tells words for people from code", function()
	for _, words in ipairs({ "Reset", "Reset all", "a /run line or a macro", "Custom (%s)", "%s: no frame rate, %s.", "|cff888888heavy|r and" }) do
		T.ok(IsWords(words), words .. " is words")
	end
	for _, code in ipairs({ "farclip", "toggle", "GameFontNormal", "SetLFGRoles", "/console %s %s", "%s (%s)", "local f=",
		"for k,v in pairs(f) do f[k]=v~=true and v end", ") end", "SDL", "03:27 PM", "  " }) do
		T.ok(not IsWords(code), code .. " is code")
	end
end)

-- The English: key -> text, from the file itself, and how often each key is given.
local given = {}
for key in Read("EverySetting/Locales/enUS.lua"):gmatch('\nL%["([^"]+)"%] = ') do given[key] = (given[key] or 0) + 1 end
local english = {}
assert(loadfile("EverySetting/Locales/enUS.lua"))("EverySetting", english)
local EN = english.EN

T.test("locale: each key is given once, as a name in capitals, with a line of text", function()
	local count = 0
	for key, n in pairs(given) do
		count = count + 1
		T.eq(n, 1, key .. " is given more than once")
		T.ok(key:match("^[%u%d_]+$"), key .. " is in capitals")
		T.eq(type(EN[key]), "string", key)
		T.ok(EN[key] ~= "" and not EN[key]:find("^%s") and not EN[key]:find("%s$"), key .. " has no space at either end")
	end
	for key in pairs(EN) do T.ok(given[key], key .. " is set some other way") end
	T.ok(count > 900, "the table has the addon's words")
end)

-- The keys a line of CVars.lua names for its menu's labels, and the labels it shows as they are.
local function MenuLabels(spec)
	local labels = {}
	local parts = {}
	for part in (spec .. "|"):gmatch("(.-)|") do parts[#parts + 1] = part end
	if parts[2] == "c" or parts[2] == "f" then
		for i = 3, #parts do
			local label = parts[i]:match("^.-=(.*)$")
			if label then labels[#labels + 1] = label end
		end
	end
	return labels
end

T.test("locale: every key the code uses is in the table, and every key in the table is used", function()
	local used = {}
	for _, path in ipairs(CODE) do
		for key in Read(path):gmatch("L%.([%a%d_]+)") do
			used[key] = true
			T.ok(EN[key], path .. " uses L." .. key .. ", which the table doesn't have")
		end
	end
	local EverySetting = W.Load()
	local lines = {}
	for name, spec in pairs(EverySetting.CVARS) do lines[#lines + 1] = { name, spec } end
	for name, spec in pairs(EverySetting.RETAIL_CVARS) do lines[#lines + 1] = { name, spec } end -- retail's own
	for _, line in ipairs(lines) do
		local name, spec = line[1], line[2]
		for _, label in ipairs(MenuLabels(spec)) do
			-- A label the table doesn't have is shown as it is: capitals, digits and signs only.
			T.ok(EN[label] or not label:find("%l"), ("CVars.lua's %s has the label %s: words go in the table"):format(name, label))
			used[label] = true
		end
	end
	for key in pairs(EN) do T.ok(used[key], key .. " isn't used") end
end)

T.test("locale: the files that fill in another language are loaded after the English, and only in that client", function()
	local toc = {}
	for line in io.lines("EverySetting/EverySetting.toc") do
		local file = line:gsub("\r$", ""):match("^Locales\\(.+)%.lua$")
		if file then toc[#toc + 1] = file end
	end
	T.eq(toc[1], "enUS", "the English first")
	for i = 2, #toc do
		local source = Read("EverySetting/Locales/" .. toc[i] .. ".lua")
		T.ok(source:find('if GetLocale%(%) ~= "' .. toc[i] .. '" then return end'), toc[i] .. " starts by checking the client's language")
		T.ok(source:find('%-%-@localization%(locale="' .. toc[i] .. '", format="lua_additive_table", handle%-unlocalized="ignore"%)@'),
			toc[i] .. " has the packager's line for CurseForge's translations")
	end
	T.ok(#toc >= 2, "at least one other language")
end)

-------------------------------------------------------------------------------
-- Everything put up, in a marked locale
-------------------------------------------------------------------------------

-- A locale in which every word of the table is marked: each run of letters between \1
-- and \2, with the %s and %d, colour codes and new lines left as they are. Whatever the
-- addon puts up then has its own words marked, and anything else in it is either data (a
-- CVar's or a command's name, a value, a profile's name) or a word written outside the
-- table.
local function Mark(text)
	local out, i = {}, 1
	while i <= #text do
		local code = text:match("^|c%x%x%x%x%x%x%x%x", i) or text:match("^|r", i) or text:match("^%%%%", i)
			or text:match("^%%[-%d%.%$]*[sdf]", i)
		local word = not code and text:match("^%a+", i)
		local part = code or word or text:sub(i, i)
		out[#out + 1] = word and "\1" .. word .. "\2" or part
		i = i + #part
	end
	return table.concat(out)
end

T.test("locale: a marked locale marks every word, and leaves the rest as it is", function()
	T.eq(Mark("Lock %s"), "\1Lock\2 %s")
	T.eq(Mark("Every %sSetting|r"), "\1Every\2 %s\1Setting\2|r")
	T.eq(Mark("Click: back to |cffffffff%s|r.\n%d fps"), "\1Click\2: \1back\2 \1to\2 |cffffffff%s|r.\n%d \1fps\2")
	T.eq(Mark("Lock %s"):format("Shadows"), "\1Lock\2 Shadows", "what's filled in isn't marked")
end)

-- The English-looking words in `text` that aren't marked and aren't data: a word in small
-- letters, or capitalised, that isn't the name of anything in `data` (lower case). A
-- name with capitals inside it or an _ (SetCVar, test_cameraDynamicPitch) is code or data.
local function Unmarked(text, data)
	local found = {}
	text = text:gsub("\1%a+\2", ""):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
	for word in text:gmatch("[%w_]+") do
		if word:match("^%u?%l+$") and not data[word:lower()] then found[#found + 1] = word end
	end
	return found
end

T.test("locale: everything the window, its tooltips, chat and the game's own UI put up is the table's", function()
	local EverySetting, ns = W.Load(nil, nil, function(ns)
		for key, text in pairs(ns.EN) do ns.L[key] = Mark(text) end
	end)
	-- Every CVar of the client this was made for, each at 0: no value is a word. A
	-- few console commands, with no help.
	local data = { default = true } -- the default profile's name
	for _, cvar in ipairs(dofile("data/cvars.lua").cvars) do
		local flags = cvar[5] or ""
		W.AddCVar(cvar[1], "0", { locked = flags:find("l") and true, readOnly = flags:find("r") and true, secure = flags:find("s") and true })
		data[cvar[1]:lower()] = true
	end
	for _, command in ipairs({ "logout", "quit", "ver", "GxRestart", "reloadui", "pitchLimit", "physEnable", "fontsize", "fontcolor" }) do
		W.AddCommand(command)
		data[command:lower()] = true
	end

	-- Every text put up: on a frame (not in a box, where the values and lines to copy
	-- go), in a tooltip, in chat, in the game's menu.
	local shown = {}
	local function Put(where, text)
		if type(text) == "string" and text ~= "" then shown[#shown + 1] = { where, text } end
	end
	local widget = getmetatable(UIParent)
	local index = widget.__index
	widget.__index = function(self, key)
		if key == "SetText" and self.kind ~= "EditBox" then
			local set = index(self, key)
			return function(w, text, ...) Put(w.kind, text) return set(w, text, ...) end
		elseif key == "AddLine" then
			return function(_, text) Put("tooltip", text) end
		end
		return index(self, key)
	end

	-- Shows every tooltip there is to see now: the mouse over each frame that has one.
	local function Hover()
		for _, w in ipairs(W.widgets) do
			if w.scripts.OnEnter and w:IsVisible() then
				W.Run(w, "OnEnter")
				if w.scripts.OnLeave then W.Run(w, "OnLeave") end
			end
		end
	end
	-- The open menu's entry for `value`, which a click picks.
	local function MenuItem(value)
		for _, w in ipairs(W.widgets) do
			if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
		end
	end
	local function Pick(value)
		Hover()
		W.Run(assert(MenuItem(value), "the menu has no entry " .. tostring(value)), "OnClick")
	end

	W.Login()
	EverySetting.Set("farclip", "3000")
	EverySetting.Set("shadowTextureSize", "2048")
	EverySetting.Set("HDROutput", "1") -- waits for a graphics restart
	EverySetting.Set("@bar:2", "1") -- for a reload
	W.Console("cameraZoomSpeed", "20") -- not the default, and not kept: for Not default
	for _, msg in ipairs({ "apply", "putback", "putback on", "putback off", "putback maybe", "undo", "redo", "redo",
		"profile", "profile Nowhere", "situations", "warning", "warning on", "warning off", "warning maybe", "danger on",
		"danger off", "danger maybe", "probe", "probe nothingLikeIt 0 1", "probe farclip 1000 2000", "probe TurnSpeed 1 2",
		"dump", "check", "help" }) do
		W.Slash(msg)
	end

	-- The minimap entry's tooltip and menu, and the game's Options and key bindings.
	EverySetting_OnAddonCompartmentEnter(nil, UIParent)
	EverySetting_OnAddonCompartmentClick(nil, "RightButton")
	local function Walk(item)
		Put("menu", item.title)
		Put("menu", item.text)
		if item.tooltip then Put("menu", item.tooltip[1]) Put("menu", item.tooltip[2]) end
		for _, sub in ipairs(item.items) do Walk(sub) end
	end
	Walk(W.menu)
	for _, item in ipairs(W.menu.items) do
		if item.callback then item.callback(item.data) end
		for _, sub in ipairs(item.items) do sub.callback(sub.data) end
	end
	for _, category in ipairs(W.categories) do Put("category", category.name) end
	for _, name in ipairs({ "BINDING_HEADER_EVERYSETTING", "BINDING_NAME_EVERYSETTING_TOGGLE", "BINDING_NAME_EVERYSETTING_UNDO" }) do
		Put("binding", _G[name])
	end

	-- The window: every section, every row and every row's tooltip, in danger mode
	-- and out of it, with each section's other CVars unfolded.
	EverySetting_OpenOptions()
	local o = ns.Options
	Hover()
	local function EveryRow()
		W.Run(o.refs.list, "OnMouseWheel", 1e6)
		local last
		repeat
			last = o.view[1] and o.rows[1].item
			for _, row in ipairs(o.rows) do
				if row:IsShown() and row.item and row.item.more and not row.more.label:GetText():find("Hide") then W.Run(row.more, "OnClick") end
			end
			Hover()
			W.Run(o.refs.list, "OnMouseWheel", -1)
		until o.rows[1].item == last
	end
	EveryRow()
	o.refs.danger:SetChecked(true)
	W.Run(o.refs.danger, "OnClick")
	EveryRow()
	for _, b in ipairs(o.refs.side) do
		if b:IsShown() then W.Run(b, "OnClick") Hover() end
	end
	-- A danger setting's command, a console command's, and a refused change.
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.command:IsShown() then W.Run(row.command, "OnClick") Hover() break end
	end
	EverySetting.Set("TurnSpeed", "200")

	-- The filters, the menus of a row, and Not default's Keep these.
	o.refs.search:SetText("=0")
	Hover()
	o.refs.search:SetText("zzzzzz")
	o.refs.search:SetText("")
	W.Run(o.refs.kind, "OnClick")
	Pick("flags")
	W.Run(o.refs.kind, "OnClick")
	Pick("any")
	o.refs.notDefault:SetChecked(true)
	W.Run(o.refs.notDefault, "OnClick")
	W.Run(o.refs.keep, "OnClick")
	Pick("new")
	Hover()
	o.refs.dialog.name:SetText("P2")
	W.Run(o.refs.dialog.ok, "OnClick")
	o.refs.notDefault:SetChecked(false)
	W.Run(o.refs.notDefault, "OnClick")
	W.Run(o.refs.profile, "OnClick")
	Pick("Default")
	for _, cvar in ipairs({ "shadowTextureSize", "nameplateThreatDisplay" }) do
		o.refs.search:SetText(cvar)
		for _, row in ipairs(o.rows) do
			if row:IsShown() and row.dropdown:IsShown() then W.Run(row.dropdown, "OnClick") Hover() W.Run(row.dropdown, "OnClick") end
		end
	end

	-- A header's presets, and their dialogs.
	EverySetting.Set("farclip", "4000")
	o.refs.search:SetText("")
	W.Run(o.refs.side[1], "OnClick")
	local function Presets(choice, text)
		W.Run(o.rows[1].presets, "OnClick")
		Pick(choice)
		Hover()
		if text then
			o.refs.dialog.name:SetText("PRE")
			o.refs.dialog.body:SetText(text)
			W.Run(o.refs.dialog.ok, "OnClick")
			Hover()
		end
	end
	Presets("save", "")
	Presets("export")
	Presets("import", "/console farclip 5000\n/console nothingLikeIt 1\nfarclip\n/run print(1)\n/console TurnSpeed 1\n/console reloadui")
	Presets("delete")
	Pick("PRE")
	Hover()
	W.Run(o.refs.dialog.ok, "OnClick")
	Presets("tier:1")

	-- The Styles panel, its menus, and a style applied with the frame rate read around it.
	W.Run(o.refs.styles, "OnClick")
	Hover()
	W.Run(o.refs.stylesPanel.top, "OnClick")
	Pick(EverySetting.STYLES[1].name)
	W.Run(o.refs.stylesPanel.rows[1].pick, "OnClick")
	Hover()
	W.Run(o.refs.stylesPanel.rows[1].pick, "OnClick")
	W.Advance(5)
	W.Run(o.refs.stylesPanel.apply, "OnClick")
	for _ = 1, 30 do W.Advance(0.25) end
	EverySetting.Set("farclip", "5000")
	W.Speed = 0
	W.Advance(0.5)
	W.speed = 7
	for _ = 1, 30 do W.Advance(0.25) end
	W.speed = 0

	-- The footer's menus, and the profile's buttons and dialogs.
	W.Run(o.refs.situations, "OnClick")
	Pick("combat")
	for _, w in ipairs(W.widgets) do -- what you've changed since login, for the situation
		if w.kind == "Button" and type(w.value) == "table" and w:IsVisible() then Hover() W.Run(w, "OnClick") break end
	end
	W.Run(o.refs.resetAll, "OnClick")
	Pick("default")
	for _, button in ipairs({ "profileSave", "profileExport", "profileImport" }) do
		W.Run(o.refs[button], "OnClick")
		Hover()
	end
	o.refs.dialog.body:SetText("/console farclip 4000\n/console thatIsNotOne 2")
	W.Run(o.refs.dialog.ok, "OnClick")
	W.Run(o.refs.profile, "OnClick")
	Pick("P2")
	W.Run(o.refs.profileDelete, "OnClick")
	Hover()
	W.Run(o.refs.dialog.ok, "OnClick")
	W.Run(o.refs.restartGx, "OnClick")
	EverySetting.Set("@bar:3", "1")
	Hover()

	-- What the status line and chat say when something else changes a kept setting, in
	-- combat, and when another addon keeps changing one back.
	EverySetting.Set("farclip", "6000")
	W.Console("farclip", "7000")
	W.RunTimers()
	Hover()
	W.FromAddon("OtherAddon", function() C_CVar.SetCVar("shadowTextureSize", "512") end)
	EverySetting.SetPutBack(true)
	for _ = 1, 5 do
		W.FromAddon("OtherAddon", function() C_CVar.SetCVar("shadowTextureSize", "1024") end)
		W.Advance(1.5)
	end
	W.Combat(true)
	Hover()
	W.Slash("apply")
	W.Combat(false)

	widget.__index = index
	for i, line in ipairs(W.chat) do shown[#shown + 1] = { "chat " .. i, line } end
	local bad, seen = {}, {}
	for _, item in ipairs(shown) do
		local words = Unmarked(item[2], data)
		if #words > 0 and not seen[item[2]] then
			seen[item[2]] = true
			bad[#bad + 1] = ("%s: %s (%s)"):format(item[1], item[2]:gsub("[\1\2]", ""), table.concat(words, " "))
		end
	end
	T.ok(#shown > 1000, "it put up a great deal")
	T.eq(table.concat(bad, "\n"), "", "words not from the table")
end)

T.test("locale: search finds a setting by its name in the game's language, in English, and by its CVar", function()
	local EverySetting, ns = W.Load(nil, nil, function(ns)
		ns.L.SOFT_SHADOWS = "Weiche Schatten"
		ns.L.NAMEPLATE_DISTANCE = "Namensplakettenreichweite"
	end)
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("nameplateMaxDistance", "60")
	W.AddCVar("horizonStart", "1000")
	W.Login()
	EverySetting_OpenOptions()
	local o = ns.Options
	local function Found(text)
		o.refs.search:SetText(text)
		local cvars = {}
		for _, item in ipairs(o.view) do
			if item.knob then cvars[#cvars + 1] = item.knob.cvar end
		end
		return table.concat(cvars, " ")
	end
	T.eq(EverySetting.Knob("shadowSoft").label, "Weiche Schatten", "the row has the translation's name")
	T.eq(Found("weiche schatten"), "shadowSoft", "by the translation's name")
	T.eq(Found("soft shadows"), "shadowSoft", "by the English name, from a guide")
	T.eq(Found("shadowsoft"), "shadowSoft", "by the CVar")
	T.eq(Found("nameplate distance"), "nameplateMaxDistance", "a plain name from CVars.lua in English too")
	T.eq(Found("horizon start"), "horizonStart", "a name no translation changed")
end)

-- Open.lua and Bindings.xml: the entry under the game's Options > AddOns, the key
-- bindings, and the minimap entry with its menu, against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with two CVars, a knob for each and a style that sets one.
-- `saved` is last session's saved variables.
local function Start(saved)
	local EverySetting = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("shadowSoft", "0")
	EverySetting.GROUPS = { { title = "Knobs", items = {
		{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100 },
		{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
	} } }
	EverySetting.STYLES = { { name = "Soft", tip = "Soft shadows on.", set = { shadowSoft = 1 } } }
	W.Login()
	return EverySetting
end

local function Shown() return EverySettingOptions ~= nil and EverySettingOptions:IsShown() end

T.test("open: Every Setting is listed under the game's Options > AddOns", function()
	Start()
	T.eq(#W.categories, 1, "categories")
	T.eq(W.categories[1].name, "Every Setting")
	T.eq(W.categories[1].frame, EverySettingPanel, "the panel is the category's frame")
	T.ok(not EverySettingPanel:IsShown(), "the game shows the panel, not the addon")
end)

T.test("open: the panel's button opens the window, and leaves it open", function()
	Start()
	T.eq(EverySettingPanel.open:GetText(), "Open Every Setting")
	T.ok(not Shown(), "closed to begin with")
	W.Run(EverySettingPanel.open, "OnClick")
	T.ok(Shown(), "the button opens the window")
	W.Run(EverySettingPanel.open, "OnClick")
	T.ok(Shown(), "a second click doesn't close it")
end)

T.test("open: the panel shows the version the TOC gives", function()
	Start()
	local texts = {}
	for _, w in ipairs(W.widgets) do
		if w.parent == EverySettingPanel then texts[w:GetText()] = true end
	end
	T.ok(W.toc.Version, "the TOC has a version")
	T.ok(texts["v" .. W.toc.Version], "the version")
	T.ok(texts["Set once, kept forever. Even the hidden ones."], "the tagline")
end)

T.test("open: every binding has a name for the Keybindings list, under AddOns", function()
	Start()
	local xml = io.open("EverySetting/Bindings.xml"):read("*a")
	local count = 0
	for attributes in xml:gmatch("<Binding ([^>]+)>") do
		count = count + 1
		local name = attributes:match('name="([^"]+)"')
		T.eq(type(_G["BINDING_NAME_" .. name]), "string", "BINDING_NAME_" .. name)
		T.eq(attributes:match('category="([^"]+)"'), "ADDONS", name .. "'s category")
		local header = attributes:match('header="([^"]+)"')
		if header then T.eq(type(_G["BINDING_HEADER_" .. header]), "string", "BINDING_HEADER_" .. header) end
	end
	T.eq(count, 2, "bindings")
end)

T.test("open: the window's key opens it and closes it", function()
	Start()
	W.Press("EVERYSETTING_TOGGLE")
	T.ok(Shown(), "opens")
	W.Press("EVERYSETTING_TOGGLE")
	T.ok(not Shown(), "closes")
end)

T.test("open: the undo key takes back the last change, and says when there's none", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	W.Press("EVERYSETTING_UNDO")
	T.eq(C_CVar.GetCVar("farclip"), "1000")
	W.Press("EVERYSETTING_UNDO")
	T.ok(W.chat[#W.chat]:find("nothing to undo", 1, true), W.chat[#W.chat])
end)

T.test("open: hovering the minimap entry names the addon and says what each click does", function()
	Start()
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	EverySetting_OnAddonCompartmentEnter("EverySetting", CreateFrame("Frame"))
	T.eq(GameTooltip:GetText(), "Every Setting")
	T.eq(lines[#lines - 1], "Click to open the window.")
	T.eq(lines[#lines], "Right-click for styles and profiles.")
	EverySetting_OnAddonCompartmentEnter("EverySetting") -- nothing to anchor the tooltip to
	T.eq(#lines, 3, "and nothing more without a button")
end)

T.test("open: a click on the minimap entry opens the window, and a right click the menu", function()
	Start()
	EverySetting_OnAddonCompartmentClick("EverySetting", "LeftButton")
	T.ok(Shown(), "a left click opens the window")
	T.ok(not W.menu, "and no menu")
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	T.ok(W.menu, "a right click opens the menu")
	T.ok(Shown(), "and leaves the window as it is")
end)

T.test("open: the menu lists the styles, then the profiles with the one in use marked", function()
	Start({ profiles = { Default = {}, Raid = { farclip = "5000" } } })
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	local seen = {}
	for _, item in ipairs(W.menu.items) do
		seen[#seen + 1] = item.title and ("[" .. item.title .. "]") or item.divider and "-" or item.text
	end
	T.eq(table.concat(seen, ", "), "[Styles], Soft, [Profile], Default, Raid, -, Apply now, Reset all")
	T.eq(W.Find("Soft").tooltip[2], "Soft shadows on.", "a style's tooltip says what it's for")
	local default, raid = W.Find("Default"), W.Find("Raid")
	T.ok(default.radio and default.isSelected(default.data), "Default is marked")
	T.ok(not raid.isSelected(raid.data), "Raid isn't")
end)

T.test("open: picking a style sets it, as one change Undo takes back", function()
	local EverySetting = Start()
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	W.Pick("Soft")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	T.ok(EverySetting.IsStored("shadowSoft"), "kept in the profile")
	T.ok(W.chat[#W.chat]:find("the style Soft is set", 1, true), W.chat[#W.chat])
	T.ok(not W.menu, "the menu closes")
	EverySetting.Undo()
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
end)

T.test("open: a style picked in combat sets nothing, and says why", function()
	Start()
	W.Combat(true)
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	W.Pick("Soft")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
	T.ok(W.chat[#W.chat]:find("out of combat", 1, true), W.chat[#W.chat])
end)

T.test("open: picking a profile switches to it", function()
	local EverySetting = Start({ profiles = { Default = {}, Raid = { farclip = "5000" } } })
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	W.Pick("Raid")
	T.eq(EverySetting.GetProfile(), "Raid")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
	T.ok(W.chat[#W.chat]:find("now using the profile Raid", 1, true), W.chat[#W.chat])
	W.Combat(true)
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	W.Pick("Default")
	T.eq(EverySetting.GetProfile(), "Raid", "not in combat")
	T.ok(W.chat[#W.chat]:find("can't be changed in combat", 1, true), W.chat[#W.chat])
end)

T.test("open: Reset all asks what to reset to, as the window's button does", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("shadowSoft", true)
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	T.ok(not W.Find("Reset all").callback, "Reset all itself resets nothing")
	W.Pick("Reset all", "To how it was before Every Setting")
	T.eq(C_CVar.GetCVar("farclip"), "1000")
	T.ok(W.chat[#W.chat]:find("2 settings put back", 1, true), W.chat[#W.chat])
	C_CVar.SetCVar("farclip", "3000") -- as the game's own options would
	EverySetting.Set("farclip", 5000)
	EverySetting_OnAddonCompartmentClick("EverySetting", "RightButton")
	W.Pick("Reset all", "To the game's defaults")
	T.eq(C_CVar.GetCVar("farclip"), "1000", "the default, not the 3000 from before")
	T.ok(W.chat[#W.chat]:find("1 settings set to the game's defaults", 1, true), W.chat[#W.chat])
end)

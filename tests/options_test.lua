-- Options.lua: the window, driven the way a player would, against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with the window open, with last session's saved variables
-- if given. Returns the addon and the window's parts.
local function Open(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("groundEffectDist", "70", { min = 40, max = 800 })
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("ffxAntiAliasingMode", "0")
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	W.AddCVar("nameplateMaxDistance", "60.000000", { secure = true })
	local many = {}
	for i = 1, 30 do
		W.AddCVar("extra" .. i, "0")
		many[i] = { cvar = "extra" .. i, label = "Extra " .. i, type = "toggle" }
	end
	EverySetting.GROUPS = {
		{ title = "Graphics", items = {
			{ cvar = "groundEffectDist", label = "Ground clutter distance", tip = "How far away grass is drawn.",
			  type = "slider", min = 40, max = 800, step = 10 },
			{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
			{ cvar = "ffxAntiAliasingMode", label = "Anti-aliasing", type = "choice", restart = "gx",
			  options = { { 0, "None" }, { 1, "FXAA low" }, { 2, "FXAA high" } } },
			{ cvar = "gxMonitor", label = "Monitor", type = "slider", min = 0, max = 3, step = 1 },
			{ cvar = "notInThisClient", label = "Missing", type = "toggle" },
		} },
		{ title = "Nameplates", items = {
			{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
		} },
		{ title = "Extras", items = many },
	}
	-- A section for each group. The extras aren't listed, so they go in the last one.
	EverySetting.SECTIONS = { "Graphics", "Nameplates", "Extras" }
	EverySetting.CVARS = { groundEffectDist = "1", shadowSoft = "1", ffxAntiAliasingMode = "1", gxMonitor = "1",
		notInThisClient = "1", nameplateMaxDistance = "2" }
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

-- The row showing `cvar`, if it's scrolled into view.
local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

local function Titles(o)
	local titles = {}
	for _, item in ipairs(o.view) do
		titles[#titles + 1] = item.header and ("[" .. (item.group or item.section).title .. "]") or item.knob.label
	end
	return table.concat(titles, ", ")
end

T.test("options: the window lists every group and knob", function()
	local _, o = Open()
	T.ok(EverySettingOptions:IsShown(), "open")
	T.eq(#o.view, 3 + 4 + 1 + 30, "three headers and their knobs, but for the one the client lacks")
	T.eq(o.rows[1].title:GetText(), "Graphics")
	local row = RowFor(o, "groundEffectDist")
	T.eq(row.label:GetText(), "Ground clutter distance")
	T.eq(row.box:GetText(), "70")
	T.ok(row.slider:IsShown() and not row.dropdown:IsShown() and not row.check:IsShown(), "a slider row shows a slider")
	T.ok(not row.reset:IsShown(), "no reset at the default")
	T.eq(RowFor(o, "nameplateMaxDistance").box:GetText(), "60", "without the game's padding")
	T.eq(RowFor(o, "ffxAntiAliasingMode").dropdown.label:GetText(), "None")
	EverySetting_OpenOptions()
	T.ok(not EverySettingOptions:IsShown(), "the command toggles it")
end)

T.test("options: a checkbox sets a toggle, and Reset puts it back", function()
	local EverySetting, o = Open()
	local row = RowFor(o, "shadowSoft")
	row.check:SetChecked(true)
	W.Run(row.check, "OnClick")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	T.ok(row.reset:IsShown() and row.kept:IsShown(), "marked as kept, with a reset button")
	T.eq(row.state:GetText(), "On")
	W.Run(row.reset, "OnClick")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
	T.ok(not row.reset:IsShown() and not row.kept:IsShown())
	T.ok(not EverySetting.IsStored("shadowSoft"))
end)

T.test("options: typing a number clamps it, and Escape leaves it alone", function()
	local EverySetting, o = Open()
	local row = RowFor(o, "groundEffectDist")
	row.box:SetFocus()
	row.box:ClearFocus()
	T.ok(not EverySetting.IsStored("groundEffectDist"), "clicking in and out without typing sets nothing")
	T.eq(W.SetCount("groundEffectDist"), 0)
	row.box:SetFocus()
	row.box:SetText("123")
	W.Run(row.box, "OnEnterPressed")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "120")
	T.eq(row.box:GetText(), "120", "the box shows what was kept")
	row.box:SetFocus()
	row.box:SetText("99999")
	W.Run(row.box, "OnEscapePressed")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "120")
	T.eq(row.box:GetText(), "120")
	row.box:SetFocus()
	row.box:SetText("abc")
	W.Run(row.box, "OnEnterPressed")
	T.eq(row.box:GetText(), "120", "not a number")
end)

T.test("options: dragging a slider shows the value, and letting go sets it", function()
	local _, o = Open()
	local row = RowFor(o, "groundEffectDist")
	W.cursor = { 4 + 0.5 * (210 - 8), 0 } -- halfway along the track
	W.Run(row.slider, "OnMouseDown")
	T.eq(row.box:GetText(), "420", "the value under the thumb")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70", "not set while dragging")
	W.cursor = { 9999, 0 } -- past the end
	W.Run(row.slider, "OnUpdate")
	T.eq(row.box:GetText(), "800")
	W.Run(row.slider, "OnMouseUp")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "800")
	T.eq(row.slider.fraction, 1)
end)

T.test("options: a dropdown lists the options and sets the one picked", function()
	local EverySetting, o = Open()
	local row = RowFor(o, "ffxAntiAliasingMode")
	W.Run(row.dropdown, "OnClick")
	local menu = row.dropdown -- the menu is found through its option buttons
	local picked
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == 2 and w:IsVisible() then picked = w end
	end
	T.ok(picked, "the menu shows an option for each value")
	T.eq(picked.label:GetText(), "FXAA high")
	W.Run(picked, "OnClick")
	T.eq(C_CVar.GetCVar("ffxAntiAliasingMode"), "2")
	T.eq(menu.label:GetText(), "FXAA high")
	T.ok(not picked:IsVisible(), "picking closes the menu")
	-- It needs a graphics restart: the footer offers one.
	T.ok(o.refs.restartGx:IsShown())
	W.Run(o.refs.restartGx, "OnClick")
	T.eq(W.restarts.gx, 1)
	T.ok(not o.refs.restartGx:IsShown())
	T.eq(EverySetting.restart.gx, nil)
end)

T.test("options: a section with several groups shows a header for each", function()
	local EverySetting, ns = W.Load()
	W.AddCVar("farclip", "1000")
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("FootstepSounds", "1")
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100 },
		} },
		{ title = "Sound", items = { { cvar = "FootstepSounds", label = "Footsteps", type = "toggle" } } },
		{ title = "Shadows", items = { { cvar = "shadowSoft", label = "Soft shadows", type = "toggle" } } },
	}
	EverySetting.SECTIONS = { "Graphics", "Sound and voice" }
	EverySetting.CVARS = { farclip = "1", shadowSoft = "1", FootstepSounds = "2" }
	W.Login()
	EverySetting_OpenOptions()
	local o = ns.Options
	T.eq(Titles(o), "[Graphics], [Draw distance], View distance, [Shadows], Soft shadows, [Sound and voice], Footsteps",
		"a section's only group has no header of its own")
	T.ok(o.rows[1].rule:IsShown() and not o.rows[2].rule:IsShown(), "a section's title has a rule, a group's doesn't")
	o.refs.search:SetText("shadows")
	T.eq(Titles(o), "[Graphics], [Shadows], Soft shadows", "search covers a group's title")
	o.refs.search:SetText("voice")
	T.eq(Titles(o), "[Sound and voice], Footsteps", "and a section's")
end)

T.test("options: search filters by name, CVar, description and section", function()
	local _, o = Open()
	o.refs.search:SetText("shadow")
	T.eq(Titles(o), "[Graphics], Soft shadows")
	o.refs.search:SetText("GRASS")
	T.eq(Titles(o), "[Graphics], Ground clutter distance", "the description, any case")
	o.refs.search:SetText("nameplatemax")
	T.eq(Titles(o), "[Nameplates], Nameplate distance", "the CVar name")
	o.refs.search:SetText("graphics soft")
	T.eq(Titles(o), "[Graphics], Soft shadows", "every word must match")
	o.refs.search:SetText("zzz")
	T.eq(#o.view, 0)
	T.ok(o.refs.noMatch:IsShown())
	W.Run(o.refs.search, "OnEscapePressed")
	T.eq(#o.view, 38, "Escape clears the search")
end)

T.test("options: Changed only shows what Every Setting keeps", function()
	local EverySetting, o = Open()
	EverySetting.Set("shadowSoft", true)
	EverySetting.Set("extra7", true)
	C_CVar.SetCVar("extra9", "1") -- changed outside Every Setting
	o.refs.changed:SetChecked(true)
	W.Run(o.refs.changed, "OnClick")
	T.eq(Titles(o), "[Graphics], Soft shadows, [Extras], Extra 7")
end)

T.test("options: a knob the client lacks has no row, and a locked one is shown but can't be changed", function()
	local _, o = Open()
	o.refs.search:SetText("missing")
	T.eq(#o.view, 0, "not even by its name")
	o.refs.search:SetText("")
	local locked = RowFor(o, "gxMonitor")
	T.ok(locked.label:GetText():find("(read-only)", 1, true))
	W.Run(locked.slider, "OnMouseDown")
	T.ok(not locked.slider.dragging, "a locked slider doesn't drag")
	T.ok(not locked.reset:IsShown())
end)

T.test("options: the list scrolls, and the sidebar jumps to a section", function()
	local _, o = Open()
	T.ok(#o.view > #o.rows, "more knobs than rows")
	W.Run(o.refs.list, "OnMouseWheel", -1)
	T.eq(o.rows[1].item, o.view[4], "three rows per notch")
	W.Run(o.refs.list, "OnMouseWheel", -100)
	T.eq(o.rows[#o.rows].item, o.view[#o.view], "stops at the end")
	T.ok(o.refs.side[3].active, "the sidebar marks the section in view")
	W.Run(o.refs.side[2], "OnClick")
	T.eq(o.rows[1].title:GetText(), "Nameplates")
	-- A search that hides the section is cleared.
	o.refs.search:SetText("shadow")
	W.Run(o.refs.side[3], "OnClick")
	T.eq(o.refs.search:GetText(), "")
	T.eq(o.rows[1].title:GetText(), "Extras")
end)

T.test("options: the sidebar shows the groups of the section in view, and scrolls when they don't fit", function()
	local EverySetting, ns = W.Load()
	-- Graphics: 30 groups of a knob each, more than the sidebar has room for.
	-- Sound: one group, long enough to scroll to the top of the list.
	EverySetting.GROUPS, EverySetting.CVARS = {}, {}
	for i = 1, 30 do
		W.AddCVar("knob" .. i, "0")
		EverySetting.GROUPS[i] = { title = "Group " .. i, items = { { cvar = "knob" .. i, label = "Knob " .. i, type = "toggle" } } }
		EverySetting.CVARS["knob" .. i] = "1"
	end
	local sounds = {}
	for i = 1, 20 do
		W.AddCVar("sound" .. i, "0")
		sounds[i] = { cvar = "sound" .. i, label = "Sound " .. i, type = "toggle" }
		EverySetting.CVARS["sound" .. i] = "2"
	end
	EverySetting.GROUPS[31] = { title = "Sound", items = sounds }
	EverySetting.SECTIONS = { "Graphics", "Sound" }
	W.Login()
	EverySetting_OpenOptions()
	local o = ns.Options
	local graphics, sound = o.refs.side[1], o.refs.side[2]
	T.ok(graphics.active and graphics.groups[1]:IsShown(), "the groups of the section in view")
	T.ok(not graphics.groups[30]:IsShown() and not sound:IsShown(), "what doesn't fit is hidden")
	W.Run(o.refs.list, "OnMouseWheel", -3)
	T.ok(graphics.groups[5].active and not graphics.groups[1].active, "the group at the top of the list is marked")
	W.Run(o.refs.sidebar, "OnMouseWheel", -100)
	T.ok(graphics.groups[30]:IsShown() and sound:IsShown() and not graphics:IsShown(), "the wheel scrolls it to the end")
	W.Run(graphics.groups[20], "OnClick")
	T.eq(o.rows[1].title:GetText(), "Group 20", "a group's button goes to it")
	T.ok(graphics.groups[20].active, "and marks it")
	W.Run(sound, "OnClick")
	T.ok(sound.active and not graphics.groups[1]:IsShown(), "another section's groups go")
	T.ok(graphics:IsShown(), "and the sidebar scrolls back, now it all fits")
end)

-- The menu's button for `value`, if the menu is open.
local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

T.test("options: Reset all offers what to reset to, and Undo takes it back", function()
	local EverySetting, o = Open()
	EverySetting.Set("shadowSoft", true)
	EverySetting.Set("groundEffectDist", 300)
	T.eq(o.refs.side[1].count:GetText(), "2", "the sidebar counts what's kept")
	W.Run(o.refs.resetAll, "OnClick")
	T.ok(MenuItem("before") and MenuItem("default"), "a menu, not a reset")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	W.Run(MenuItem("before"), "OnClick")
	T.eq(C_CVar.GetCVar("shadowSoft"), "0")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70")
	T.ok(not MenuItem("before"), "picking closes the menu")
	T.ok(o.refs.undo:IsEnabled() and not o.refs.redo:IsEnabled())
	W.Run(o.refs.undo, "OnClick")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1", "one Undo for the whole reset")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.ok(o.refs.redo:IsEnabled())
	W.Run(o.refs.redo, "OnClick")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70")
end)

T.test("options: right-clicking Reset goes to the game's default", function()
	local EverySetting, o = Open()
	C_CVar.SetCVar("groundEffectDist", "320") -- a graphics preset's value
	EverySetting.Set("groundEffectDist", 500)
	local row = RowFor(o, "groundEffectDist")
	W.Run(row.reset, "OnEnter") -- the tooltip names both values
	W.Run(row.reset, "OnClick", "RightButton")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70", "the default, not the 320 from before")
	T.ok(not EverySetting.IsStored("groundEffectDist") and not row.reset:IsShown())
	W.Run(o.refs.undo, "OnClick")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "500")
	W.Run(row.reset, "OnClick", "LeftButton")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "320", "a plain click still goes back to before")
end)

T.test("options: profiles can be saved, switched and deleted from the header", function()
	local EverySetting, o = Open()
	EverySetting.Set("shadowSoft", true)
	T.eq(o.refs.profile.label:GetText(), "Default")
	T.ok(not o.refs.profileDelete:IsEnabled(), "Default can't be deleted")
	-- Save as: a name is asked for, and a bad one keeps the question open.
	W.Run(o.refs.profileSave, "OnClick")
	local dialog = o.refs.dialog
	T.ok(dialog:IsShown() and dialog.name:IsShown() and not dialog.scroll:IsShown(), "a name box, no big box")
	T.eq(dialog.ok.label:GetText(), "Save")
	W.Run(dialog.ok, "OnClick")
	T.ok(dialog:IsShown() and dialog.error:GetText() ~= "", "no name given")
	dialog.name:SetText("Raid night")
	T.eq(dialog.error:GetText(), "", "typing clears the complaint")
	W.Run(dialog.name, "OnEnterPressed")
	T.ok(not dialog:IsShown())
	T.eq(o.refs.profile.label:GetText(), "Raid night")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1", "the copy keeps the same values")
	EverySetting.Set("groundEffectDist", 100)
	-- Switch back with the dropdown.
	W.Run(o.refs.profile, "OnClick")
	T.ok(MenuItem("Raid night").active, "the profile in use is marked")
	W.Run(MenuItem("Default"), "OnClick")
	T.eq(o.refs.profile.label:GetText(), "Default")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "70", "what only Raid night keeps goes back")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	-- Reset all can copy from the other profile.
	W.Run(o.refs.resetAll, "OnClick")
	W.Run(MenuItem("profile:Raid night"), "OnClick")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "100")
	-- Delete asks first.
	EverySetting.SetProfile("Raid night")
	T.ok(o.refs.profileDelete:IsEnabled())
	W.Run(o.refs.profileDelete, "OnClick")
	T.ok(dialog:IsShown() and dialog.title:GetText():find("Delete Raid night", 1, true))
	W.Run(dialog.cancel, "OnClick")
	T.eq(EverySetting.GetProfile(), "Raid night", "Cancel leaves it")
	W.Run(o.refs.profileDelete, "OnClick")
	W.Run(dialog.ok, "OnClick")
	T.eq(EverySetting.GetProfile(), "Default")
	T.eq(#EverySetting.GetProfiles(), 1)
	T.ok(not dialog:IsShown())
	for _, b in ipairs({ o.refs.profile, o.refs.profileSave, o.refs.profileDelete, o.refs.profileExport, o.refs.profileImport,
		o.refs.styles, o.refs.foldAll, o.refs.resetAll, o.refs.undo, o.refs.redo }) do
		W.Run(b, "OnEnter")
	end
end)

T.test("options: a profile can be exported as text and imported under a new name", function()
	local EverySetting, o = Open()
	EverySetting.Set("shadowSoft", true)
	EverySetting.Set("groundEffectDist", 300)
	W.Run(o.refs.profileExport, "OnClick")
	local dialog = o.refs.dialog
	local text = dialog.body:GetText()
	T.eq(text, "EverySetting:1:groundEffectDist=300,shadowSoft=1")
	T.ok(dialog.scroll:IsShown() and not dialog.name:IsShown(), "just the text")
	T.eq(dialog.ok.label:GetText(), "As /console", "a button for the same as /console lines")
	T.eq(dialog.cancel.label:GetText(), "Close")
	-- The exported text can't be changed by typing in it.
	dialog.body.text = "oops"
	W.Run(dialog.body, "OnTextChanged", true)
	T.eq(dialog.body:GetText(), text)
	W.Run(dialog.cancel, "OnClick")
	EverySetting.ResetAll()
	-- Import: the string and a name.
	W.Run(o.refs.profileImport, "OnClick")
	T.ok(dialog.name:IsShown() and dialog.scroll:IsShown())
	T.eq(dialog.ok.label:GetText(), "Import")
	dialog.body:SetText("not a profile")
	dialog.name:SetText("Shared")
	W.Run(dialog.ok, "OnClick")
	T.ok(dialog:IsShown() and dialog.error:GetText():find("isn't an Every Setting profile", 1, true), "a bad string is explained")
	dialog.body:SetText(text)
	W.Run(dialog.ok, "OnClick")
	T.ok(not dialog:IsShown())
	T.eq(o.refs.profile.label:GetText(), "Shared")
	T.eq(C_CVar.GetCVar("groundEffectDist"), "300")
	T.eq(C_CVar.GetCVar("shadowSoft"), "1")
	-- Closing the window closes the dialog with it.
	W.Run(o.refs.profileExport, "OnClick")
	EverySetting_OpenOptions()
	T.ok(not dialog:IsShown())
end)

T.test("options: the window, its dialog, its menus and the Styles panel hide what's behind them", function()
	local _, o = Open()
	-- The texture that fills a frame's background.
	local function Background(frame)
		for _, w in ipairs(W.widgets) do
			if w.kind == "Texture" and w.parent == frame and w.layer == "BACKGROUND" then return w end
		end
	end
	local menu
	W.Run(o.refs.kind, "OnClick")
	for _, w in ipairs(W.widgets) do
		if w.parent == EverySettingOptions and w.catcher and w:IsShown() then menu = w end
	end
	W.Run(o.refs.profileExport, "OnClick")
	W.Run(o.refs.styles, "OnClick")
	for name, frame in pairs({ window = EverySettingOptions, dialog = o.refs.dialog, menu = menu, styles = o.refs.stylesPanel }) do
		T.eq(Background(frame).color[4], 1, "the " .. name .. "'s background is opaque")
	end
end)

T.test("options: a change made elsewhere shows up, and combat is explained", function()
	local EverySetting, o = Open()
	C_CVar.SetCVar("groundEffectDist", "250") -- the options menu, or another addon
	W.RunTimers()
	local row = RowFor(o, "groundEffectDist")
	T.eq(row.box:GetText(), "250")
	T.ok(not row.reset:IsShown() and not row.kept:IsShown(), "not Every Setting's to keep or reset")
	W.Combat(true)
	T.ok(o.refs.status:GetText():find("In combat", 1, true))
	EverySetting.Set("nameplateMaxDistance", 80)
	T.eq(RowFor(o, "nameplateMaxDistance").box:GetText(), "80", "shows the value that's waiting")
	W.Combat(false)
	T.eq(C_CVar.GetCVar("nameplateMaxDistance"), "80")
end)

T.test("options: every row's tooltip can be built", function()
	local EverySetting, o = Open()
	EverySetting.Set("shadowSoft", true)
	for _, row in ipairs(o.rows) do
		if row:IsShown() then
			W.Run(row.name, "OnEnter")
			W.Run(row.name, "OnLeave")
			if row.reset:IsShown() then W.Run(row.reset, "OnEnter") end
			if row.lock:IsShown() then W.Run(row.lock, "OnEnter") end
		end
	end
	for _, b in ipairs(o.refs.side) do W.Run(b, "OnEnter") end
end)

T.test("options: a tooltip with nothing more to say adds no line", function()
	local EverySetting, o = Open()
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(o.refs.side[1], "OnEnter") -- a section that keeps nothing
	T.eq(GameTooltip:GetText(), o.refs.side[1].label:GetText(), "its title")
	T.eq(#lines, 0, "and no body")
	EverySetting.Set("shadowSoft", true)
	W.Run(o.refs.side[1], "OnEnter")
	T.eq(type(lines[1]), "string", "a body once it keeps something")
end)

T.test("options: dragging the corner grip scales the window, and the size is kept", function()
	local _, o = Open()
	local grip = o.refs.grip
	T.eq(EverySettingOptions:GetScale(), 1, "100% at first")
	W.cursor = { 100, -100 }
	W.Run(grip, "OnMouseDown")
	W.cursor = { 120, -100 }
	W.Run(grip, "OnUpdate")
	T.eq(EverySettingOptions:GetScale(), 1.2, "the window follows the grip")
	W.cursor = { 50, -50 }
	W.Run(grip, "OnUpdate")
	T.eq(EverySettingOptions:GetScale(), 0.75, "down to 75%")
	W.cursor = { 1000, -100 }
	W.Run(grip, "OnUpdate")
	T.eq(EverySettingOptions:GetScale(), 1.5, "up to 150%")
	T.eq(EverySettingDB.scale, nil, "saved once it's let go")
	W.Run(grip, "OnMouseUp")
	T.eq(EverySettingDB.scale, 1.5, "for every character")
	T.eq(grip:GetScript("OnUpdate"), nil, "and the drag is over")

	_, o = Open(EverySettingDB)
	T.eq(EverySettingOptions:GetScale(), 1.5, "kept after a reload")
	W.Run(o.refs.grip, "OnDoubleClick")
	T.eq(EverySettingOptions:GetScale(), 1, "a double-click gives 100%")
	T.eq(EverySettingDB.scale, nil)
end)

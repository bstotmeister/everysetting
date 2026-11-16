-- Presets: Core.lua's functions for them, and the menu on the window's headers.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with two sections: Graphics, which has two groups with
-- built-in presets, and Camera, which has none. Of the styles, Film sets both
-- groups, Vista just Draw distance and Crisp just Shadows; none sets Camera.
local function Start(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("shadowMode", "1")
	W.AddCVar("ffxGlow", "1")
	W.AddCVar("cameraZoomSpeed", "20")
	W.AddCVar("cameraBobbing", "0")
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100,
			  raid = "RAIDfarclip", tiers = { 3000, 5000, 7000, 10000 } },
		} },
		{ title = "Shadows", items = {
			{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle", tiers = { 0, 0, 0, 1 } },
			{ cvar = "shadowMode", label = "Shadow type", type = "choice", tiers = { 2, 2, 3, 4 },
			  options = { { 0, "Blob" }, { 1, "One band" }, { 2, "Two" }, { 3, "Three" }, { 4, "Four" } } },
		} },
		{ title = "Camera", items = {
			{ cvar = "cameraZoomSpeed", label = "Zoom speed", type = "slider", min = 1, max = 50, step = 1 },
		} },
	}
	EverySetting.SECTIONS = { "Graphics", "Camera" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "1", shadowSoft = "1", shadowMode = "1", ffxGlow = "1|t", gxMonitor = "1",
		cameraZoomSpeed = "2", cameraBobbing = "2|t" }
	EverySetting.STYLES = {
		{ name = "Film", tier = 4, tip = "A test.", set = { shadowMode = 3 } },
		{ name = "Vista", tip = "Far.", set = { farclip = 9000 } },
		{ name = "Crisp", tip = "Sharp.", set = { shadowMode = 2 } },
	}
	W.Login()
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

T.test("presets: applying one keeps its values and leaves the rest of the profile alone", function()
	local EverySetting = Start()
	EverySetting.Set("cameraZoomSpeed", 30)
	EverySetting.ApplyPreset({ farclip = "5000", shadowSoft = "1", gxMonitor = "2", notInThisClient = "1" })
	T.eq(Get("farclip"), "5000")
	T.eq(Get("RAIDfarclip"), "5000", "the raid twin too")
	T.eq(Get("shadowSoft"), "1")
	T.ok(EverySetting.IsStored("farclip") and EverySetting.IsStored("shadowSoft"), "the profile keeps them")
	T.eq(Get("gxMonitor"), "0", "a locked CVar is skipped")
	T.eq(Get("cameraZoomSpeed"), "30")
	T.ok(EverySetting.IsStored("cameraZoomSpeed"), "what the preset doesn't list is still kept")
	T.ok(EverySetting.Undo(), "one Undo for the whole preset")
	T.eq(Get("farclip"), "1000")
	T.eq(Get("RAIDfarclip"), "1000")
	T.eq(Get("shadowSoft"), "0")
	T.ok(not EverySetting.IsStored("farclip") and not EverySetting.IsStored("shadowSoft"))
	T.eq(Get("cameraZoomSpeed"), "30")
	T.ok(EverySetting.Redo())
	T.eq(Get("farclip"), "5000")
	-- A CVar that isn't in Knobs.lua.
	EverySetting.ApplyPreset({ ffxGlow = "0" })
	T.eq(Get("ffxGlow"), "0")
	T.ok(EverySetting.IsStored("ffxGlow"))
	EverySetting.Reset("ffxGlow")
	T.eq(Get("ffxGlow"), "1", "Reset puts it back")
end)

T.test("presets: not in combat", function()
	local EverySetting = Start()
	W.Combat(true)
	EverySetting.ApplyPreset({ farclip = "5000" })
	T.eq(Get("farclip"), "1000")
	T.ok(W.chat[#W.chat]:find("out of combat", 1, true))
	T.eq(EverySetting.ImportPreset("Fight", "EverySetting:1:farclip=5000"), "A preset can't be applied in combat.")
	T.eq(EverySetting.GetPresets().Fight, nil)
	W.Combat(false)
	T.eq(EverySetting.ImportPreset("Fight", "EverySetting:1:farclip=5000"), nil)
	T.eq(Get("farclip"), "5000")
end)

T.test("presets: saved under a name that's free, and deleted", function()
	local EverySetting = Start()
	local kept = { farclip = "5000" }
	T.eq(EverySetting.SavePreset("", kept), "Type a name for the preset.")
	T.eq(EverySetting.SavePreset(("x"):rep(33), kept), "That name is too long.")
	T.eq(EverySetting.SavePreset("low", kept), "Low is the name of a built-in preset.")
	T.eq(EverySetting.SavePreset("Nothing", {}), "There's nothing changed here to save.")
	T.eq(EverySetting.SavePreset("  Far  ", kept), nil)
	kept.farclip = "9000"
	T.eq(EverySetting.GetPresets().Far.farclip, "5000", "a copy, under the name without its spaces")
	T.eq(EverySettingDB.presets.Far.farclip, "5000", "in the account's saved variables")
	T.eq(EverySetting.SavePreset("FAR", kept), "There's already a preset named Far.")
	T.eq(Get("farclip"), "1000", "saving sets nothing")
	EverySetting.DeletePreset("Far")
	T.eq(next(EverySetting.GetPresets()), nil)
	T.eq(EverySetting.NewProfile("Far"), nil, "a profile can have a preset's name")
end)

T.test("presets: a string is imported as a preset, or the part of it that fits", function()
	local EverySetting = Start()
	local text = "EverySetting:1:cameraZoomSpeed=40,farclip=9000,shadowSoft=1"
	local function Graphics(cvar) return cvar ~= "cameraZoomSpeed" end
	T.eq(EverySetting.ImportPreset("Theirs", "nonsense", Graphics), "That isn't an Every Setting profile string, or lines that set something, like /console farclip 5000.")
	T.eq(EverySetting.ImportPreset("Theirs", "EverySetting:1:cameraZoomSpeed=40", Graphics), "None of the settings in that string belong here.")
	T.eq(EverySetting.ImportPreset("Ultra", text, Graphics), "Ultra is the name of a built-in preset.")
	T.eq(next(EverySetting.GetPresets()), nil, "nothing saved by a refusal")
	T.eq(EverySetting.ImportPreset("Theirs", text, Graphics), nil)
	local preset = EverySetting.GetPresets().Theirs
	T.eq(preset.farclip, "9000")
	T.eq(preset.shadowSoft, "1")
	T.eq(preset.cameraZoomSpeed, nil, "only what fits")
	T.eq(Get("farclip"), "9000", "and it's applied")
	T.eq(Get("cameraZoomSpeed"), "20")
	T.ok(EverySetting.Undo())
	T.eq(Get("farclip"), "1000")
	T.ok(EverySetting.GetPresets().Theirs, "Undo takes back the values, not the preset")
	T.eq(EverySetting.ImportPreset("All of it", text), nil, "without a scope, everything is taken")
	T.eq(EverySetting.GetPresets()["All of it"].cameraZoomSpeed, "40")
end)

T.test("presets: part of a profile exports in the profile's format", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	EverySetting.Set("shadowSoft", true)
	T.eq(EverySetting.ExportProfile({ shadowSoft = "1" }), "EverySetting:1:shadowSoft=1")
	T.eq(EverySetting.ExportProfile(), "EverySetting:1:farclip=5000,shadowSoft=1", "the whole profile, as before")
end)

T.test("presets: they're saved with the account, and older saved variables have none", function()
	local EverySetting = Start({ profiles = { Default = {} } })
	T.eq(next(EverySetting.GetPresets()), nil)
	EverySetting = Start({ presets = { Far = { farclip = "5000" } } })
	T.eq(EverySetting.GetPresets().Far.farclip, "5000")
	T.eq(Get("farclip"), "1000", "a preset sets nothing until it's applied")
end)

T.test("presets: a locked setting is left alone, and its raid twin with it", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 9000)
	EverySetting.SetLocked("FARCLIP", true) -- CVar names ignore case
	T.ok(EverySetting.IsLocked("farclip"))
	T.eq(EverySettingDB.locked.farclip, true, "saved with the account, as the knob spells it")
	EverySetting.ApplyPreset({ farclip = "5000", shadowSoft = "1", cameraZoomSpeed = "40" })
	T.eq(Get("farclip"), "9000", "locked")
	T.eq(Get("RAIDfarclip"), "9000", "and its raid twin")
	T.eq(Get("shadowSoft"), "1", "the rest is set")
	T.eq(Get("cameraZoomSpeed"), "40")
	T.ok(EverySetting.Undo(), "one Undo for the preset")
	T.eq(Get("shadowSoft"), "0")
	T.eq(Get("cameraZoomSpeed"), "20")
	T.eq(Get("farclip"), "9000", "the change before it is still there")
	T.ok(EverySetting.Undo(), "Undo still takes back a locked setting's own change")
	T.eq(Get("farclip"), "1000")
	T.eq(EverySetting.Set("farclip", 3000), "3000", "and it can still be changed by hand")
	T.eq(EverySetting.ImportPreset("Far", "EverySetting:1:farclip=5000,shadowSoft=1"), nil)
	T.eq(Get("farclip"), "3000", "an imported preset leaves it alone too")
	T.eq(EverySetting.GetPresets().Far.farclip, "5000", "but saves its value")
	EverySetting.SetLocked("farclip", false)
	T.ok(not EverySetting.IsLocked("farclip"))
	T.eq(EverySettingDB.locked.farclip, nil)
	EverySetting.ApplyPreset(EverySetting.GetPresets().Far)
	T.eq(Get("farclip"), "5000", "unlocked, it's set again")
end)

T.test("presets: locks are the account's, not a profile's, and kept over a reload", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 9000)
	EverySetting.SetLocked("farclip", true)
	T.eq(EverySetting.ExportProfile(), "EverySetting:1:farclip=9000", "not in a profile string")
	EverySetting.NewProfile("Other")
	T.ok(EverySetting.IsLocked("farclip"), "whatever the profile")
	EverySetting = Start(EverySettingDB)
	T.ok(EverySetting.IsLocked("farclip"), "after a reload")
	EverySetting.ApplyPreset({ farclip = "5000" })
	T.eq(Get("farclip"), "9000")
	EverySetting = Start({ profiles = { Default = { farclip = "9000" } } }) -- from before there were locks
	T.ok(not EverySetting.IsLocked("farclip"))
	EverySetting.ApplyPreset({ farclip = "5000" })
	T.eq(Get("farclip"), "5000")
end)

-------------------------------------------------------------------------------
-- The window
-------------------------------------------------------------------------------

-- The list's rows, with the Presets buttons these tests press:
--   1 [Graphics]  2 [Draw distance]  3 farclip  4 [Shadows]  5 shadowSoft
--   6 shadowMode  7 (more)  8 [Camera]  9 cameraZoomSpeed  10 (more)
local GRAPHICS, DISTANCE, SHADOWS, CAMERA = 1, 2, 4, 8

local function Open()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	return EverySetting, o
end

-- The open menu's items and headings, in order.
local function Menu()
	local labels = {}
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and (w.value ~= nil or w.heading) and w:IsVisible() then labels[#labels + 1] = w.label:GetText() end
	end
	return table.concat(labels, ", ")
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

-- The open menu's heading `label`.
local function Heading(label)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.heading and w:IsVisible() and w.label:GetText() == label then return w end
	end
end

-- What the Presets menu of row `i` lists.
local function Look(o, i)
	W.Run(o.rows[i].presets, "OnClick")
	local menu = Menu()
	W.Run(o.rows[i].presets, "OnClick") -- closes it
	return menu
end

-- Picks `value` from the Presets menu of row `i`.
local function Pick(o, i, value)
	W.Run(o.rows[i].presets, "OnClick")
	W.Run(MenuItem(value), "OnClick")
end

T.test("presets: a header's menu has the built-in presets of its knobs", function()
	local EverySetting, o = Open()
	T.eq(o.rows[GRAPHICS].title:GetText(), "Graphics")
	T.eq(o.rows[SHADOWS].title:GetText(), "Shadows")
	T.eq(o.rows[CAMERA].title:GetText(), "Camera")
	T.ok(o.rows[GRAPHICS].presets:IsShown() and o.rows[SHADOWS].presets:IsShown(), "on a section's header and a group's")
	T.ok(not o.rows[3].presets:IsShown() and not o.rows[7].presets:IsShown(), "not on the other rows")
	T.eq(o.rows[SHADOWS].presets.label:GetText(), "Presets")
	W.Run(o.rows[SHADOWS].presets, "OnEnter")
	T.eq(Look(o, GRAPHICS), "Low, Medium, High, Ultra, Styles, Film, Vista, Crisp, Your presets, Import...")
	T.eq(Look(o, SHADOWS), "Low / Medium, High, Ultra, Styles, Film, Crisp, Your presets, Import...", "two that give the same values are one item")
	T.eq(Look(o, CAMERA), "Import...", "no built-in presets, and nothing changed to save")
	-- A group's preset sets its own knobs.
	Pick(o, SHADOWS, "tier:3")
	T.eq(Get("shadowMode"), "3")
	T.eq(Get("shadowSoft"), "0")
	T.ok(EverySetting.IsStored("shadowMode") and EverySetting.IsStored("shadowSoft"), "kept, even the one that didn't change")
	T.eq(Get("farclip"), "1000", "and nothing else")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	T.ok(MenuItem("tier:3").active and not MenuItem("tier:4").active, "the one that's set now is marked")
	T.eq(Menu(), "Low / Medium, High, Ultra, Styles, Film, Crisp, Your presets, Save as preset..., Export..., Import...", "and there's something to save")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	-- A section's preset sets every group's.
	Pick(o, GRAPHICS, "tier:4")
	T.eq(Get("farclip"), "10000")
	T.eq(Get("RAIDfarclip"), "10000")
	T.eq(Get("shadowMode"), "4")
	T.eq(Get("shadowSoft"), "1")
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("farclip"), "1000", "one Undo")
	T.eq(Get("shadowMode"), "3", "back to the preset before it")
	W.Run(o.rows[GRAPHICS].presets, "OnClick")
	T.ok(not MenuItem("tier:3").active, "High isn't set for the whole section")
end)

T.test("presets: what's changed under a header can be saved, exported and deleted", function()
	local EverySetting, o = Open()
	local dialog
	EverySetting.Set("cameraZoomSpeed", 30)
	EverySetting.Set("cameraBobbing", true) -- one of the section's other CVars
	EverySetting.Set("farclip", 5000)
	T.eq(Look(o, CAMERA), "Save as preset..., Export..., Import...")
	-- Export: only what's kept under this header.
	Pick(o, CAMERA, "export")
	dialog = o.refs.dialog
	T.eq(dialog.title:GetText(), "Export Camera")
	T.eq(dialog.body:GetText(), "EverySetting:1:cameraBobbing=1,cameraZoomSpeed=30")
	T.ok(not dialog.name:IsShown())
	T.eq(dialog.ok.label:GetText(), "As /console", "and a button for the same as /console lines")
	W.Run(dialog.cancel, "OnClick")
	-- Save: a name is asked for.
	Pick(o, CAMERA, "save")
	T.ok(dialog:IsShown() and dialog.name:IsShown() and not dialog.scroll:IsShown())
	T.ok(dialog.text:GetText():find("the 2 settings you've changed under Camera", 1, true))
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.error:GetText(), "Type a name for the preset.")
	dialog.name:SetText("My camera")
	W.Run(dialog.ok, "OnClick")
	T.ok(not dialog:IsShown())
	T.eq(EverySetting.GetPresets()["My camera"].cameraZoomSpeed, "30")
	T.eq(EverySetting.GetPresets()["My camera"].farclip, nil)
	T.eq(Look(o, CAMERA), "My camera, Save as preset..., Export..., Import..., Delete preset...")
	T.eq(Look(o, GRAPHICS), "Low, Medium, High, Ultra, Styles, Film, Vista, Crisp, Your presets, Save as preset..., Export..., Import...", "not listed where it doesn't belong")
	-- Applying it to a profile that doesn't have its values.
	EverySetting.Reset("cameraZoomSpeed")
	EverySetting.Reset("cameraBobbing")
	W.Run(o.rows[CAMERA].presets, "OnClick")
	T.ok(not MenuItem("preset:My camera").active)
	W.Run(MenuItem("preset:My camera"), "OnClick")
	T.eq(Get("cameraZoomSpeed"), "30")
	T.eq(Get("cameraBobbing"), "1")
	T.eq(Get("farclip"), "5000", "the rest of the profile is as it was")
	W.Run(o.rows[CAMERA].presets, "OnClick")
	T.ok(MenuItem("preset:My camera").active, "marked once it's set")
	W.Run(o.rows[CAMERA].presets, "OnClick")
	-- Delete: which one, then are you sure.
	Pick(o, CAMERA, "delete")
	T.eq(Menu(), "My camera", "a second menu, of the saved ones")
	W.Run(MenuItem("My camera"), "OnClick")
	T.eq(dialog.title:GetText(), "Delete the preset My camera?")
	W.Run(dialog.cancel, "OnClick")
	T.ok(EverySetting.GetPresets()["My camera"], "Cancel leaves it")
	Pick(o, CAMERA, "delete")
	W.Run(MenuItem("My camera"), "OnClick")
	W.Run(dialog.ok, "OnClick")
	T.eq(next(EverySetting.GetPresets()), nil)
	T.eq(Get("cameraZoomSpeed"), "30", "the profile keeps what the preset gave it")
	T.eq(Look(o, CAMERA), "Save as preset..., Export..., Import...")
end)

T.test("presets: a header imports the part of a string that belongs under it", function()
	local EverySetting, o = Open()
	EverySetting.Set("farclip", 5000)
	Pick(o, CAMERA, "import")
	local dialog = o.refs.dialog
	T.eq(dialog.title:GetText(), "Import a preset for Camera")
	T.ok(dialog.name:IsShown() and dialog.scroll:IsShown())
	dialog.name:SetText("Theirs")
	dialog.body:SetText("EverySetting:1:farclip=9000,shadowSoft=1")
	W.Run(dialog.ok, "OnClick")
	T.eq(dialog.error:GetText(), "None of the settings in that string belong here.")
	dialog.body:SetText("EverySetting:1:cameraZoomSpeed=40,farclip=9000,shadowSoft=1") -- a whole profile
	W.Run(dialog.ok, "OnClick")
	T.ok(not dialog:IsShown())
	T.eq(Get("cameraZoomSpeed"), "40")
	T.eq(Get("farclip"), "5000", "their view distance isn't taken")
	T.eq(Get("shadowSoft"), "0")
	T.eq(Look(o, CAMERA), "Theirs, Save as preset..., Export..., Import..., Delete preset...")
end)

T.test("presets: a saved one is listed under its group and its section", function()
	local EverySetting, o = Open()
	EverySetting.SavePreset("Soft", { shadowSoft = "1" })
	EverySetting.SavePreset("Far and soft", { farclip = "9000", shadowSoft = "1" })
	EverySetting.SavePreset("Zoom", { cameraZoomSpeed = "40" })
	T.eq(Look(o, SHADOWS), "Low / Medium, High, Ultra, Styles, Film, Crisp, Your presets, Soft, Import..., Delete preset...")
	T.eq(Look(o, DISTANCE), "Low, Medium, High, Ultra, Styles, Film, Vista, Your presets, Import...")
	T.eq(Look(o, GRAPHICS), "Low, Medium, High, Ultra, Styles, Film, Vista, Crisp, Your presets, Far and soft, Soft, Import..., Delete preset...", "in name order")
	T.eq(Look(o, CAMERA), "Zoom, Import..., Delete preset...")
end)

T.test("presets: a header's menu has the styles that set something under it, under a heading", function()
	local EverySetting, o = Open()
	T.eq(Look(o, DISTANCE), "Low, Medium, High, Ultra, Styles, Film, Vista, Your presets, Import...", "a group's: the styles that set it")
	T.eq(Look(o, SHADOWS), "Low / Medium, High, Ultra, Styles, Film, Crisp, Your presets, Import...")
	T.eq(Look(o, GRAPHICS), "Low, Medium, High, Ultra, Styles, Film, Vista, Crisp, Your presets, Import...", "a section's: those of all its groups")
	T.eq(Look(o, CAMERA), "Import...", "no heading where no style sets anything, nor over your own with nothing above")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	T.eq(MenuItem("style:Crisp").tip, "Sharp.", "hovering a style says what it's for")
	local heading = Heading("Styles")
	T.ok(heading and not heading.active, "the heading is shown, and not marked")
	GameTooltip:Hide()
	W.Run(heading, "OnEnter")
	T.ok(not GameTooltip:IsShown(), "it has no tooltip")
	W.Run(heading, "OnLeave")
	W.Run(heading, "OnClick")
	T.eq(Menu(), "Low / Medium, High, Ultra, Styles, Film, Crisp, Your presets, Import...", "clicking it leaves the menu open")
	T.eq(next(EverySetting.GetKept()), nil, "and sets nothing")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
end)

T.test("presets: a style from a header sets just that part, leaves locks alone, and is one Undo", function()
	local EverySetting, o = Open()
	EverySetting.Set("cameraZoomSpeed", 30)
	EverySetting.SetLocked("shadowSoft", true)
	Pick(o, SHADOWS, "style:Film")
	T.eq(Get("shadowMode"), "3", "the style's own value")
	T.eq(Get("shadowSoft"), "0", "a locked setting is left alone")
	T.ok(EverySetting.IsStored("shadowMode") and not EverySetting.IsStored("shadowSoft"))
	T.eq(Get("farclip"), "1000", "the rest of the style isn't set")
	T.eq(Get("cameraZoomSpeed"), "30")
	W.Run(o.refs.undo, "OnClick")
	T.eq(Get("shadowMode"), "1", "one Undo")
	T.ok(not EverySetting.IsStored("shadowMode"))
	T.eq(Get("cameraZoomSpeed"), "30", "the change before it is still there")
	-- A section's: the style's values for each of its groups.
	EverySetting.SetLocked("shadowSoft", false)
	Pick(o, GRAPHICS, "style:Film")
	T.eq(Get("farclip"), "10000", "from its built-in preset")
	T.eq(Get("RAIDfarclip"), "10000")
	T.eq(Get("shadowSoft"), "1")
	T.eq(Get("shadowMode"), "3")
	T.ok(EverySetting.IsStored("farclip") and EverySetting.IsStored("shadowSoft"), "kept")
	W.Run(o.rows[GRAPHICS].presets, "OnClick")
	T.ok(MenuItem("style:Film").active and not MenuItem("tier:4").active, "marked once it's set")
	W.Run(o.rows[GRAPHICS].presets, "OnClick")
	W.Run(o.rows[DISTANCE].presets, "OnClick")
	T.ok(MenuItem("tier:4").active and not MenuItem("style:Film").active, "where Ultra gives the same values, the first is marked")
	W.Run(o.rows[DISTANCE].presets, "OnClick")
end)

T.test("presets: a knob's lock box, and its group's on the group's header", function()
	local EverySetting, o = Open()
	T.ok(o.rows[DISTANCE].lock:IsShown() and o.rows[SHADOWS].lock:IsShown() and o.rows[5].lock:IsShown(), "on a group's header and a knob's row")
	T.ok(o.rows[CAMERA].lock:IsShown(), "and on the header of a section's only group")
	T.ok(o.rows[GRAPHICS].lock:IsShown(), "and on a section of several groups")
	T.ok(not o.rows[7].lock:IsShown(), "not on the button for the other CVars")
	-- A knob's box locks it, and the group's is checked once all its knobs are locked.
	local soft, mode, group = o.rows[5].lock, o.rows[6].lock, o.rows[SHADOWS].lock
	W.Run(soft, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock")
	soft:SetChecked(true)
	W.Run(soft, "OnClick")
	T.ok(EverySetting.IsLocked("shadowSoft"))
	T.ok(not group:GetChecked(), "not all of Shadows is locked")
	mode:SetChecked(true)
	W.Run(mode, "OnClick")
	T.ok(group:GetChecked(), "all of it is")
	Pick(o, SHADOWS, "tier:4")
	T.eq(Get("shadowSoft"), "0", "the group's preset leaves them alone")
	T.eq(Get("shadowMode"), "1")
	-- The group's box unlocks them all, and locks them all.
	group:SetChecked(false)
	W.Run(group, "OnClick")
	T.ok(not EverySetting.IsLocked("shadowSoft") and not EverySetting.IsLocked("shadowMode"))
	T.ok(not soft:GetChecked() and not mode:GetChecked())
	W.Run(o.rows[CAMERA].lock, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock Camera")
	o.rows[CAMERA].lock:SetChecked(true)
	W.Run(o.rows[CAMERA].lock, "OnClick")
	T.ok(EverySetting.IsLocked("cameraZoomSpeed") and o.rows[9].lock:GetChecked())
	T.ok(not EverySetting.IsLocked("cameraBobbing"), "the section's other CVars aren't the group's")
	-- One of the other CVars has a box of its own.
	W.Run(o.rows[10].more, "OnClick")
	T.eq(o.rows[11].item.knob.cvar, "cameraBobbing")
	T.ok(o.rows[11].lock:IsShown() and not o.rows[11].lock:GetChecked())
	-- A locked setting still changes by hand.
	o.rows[9].box:SetFocus()
	o.rows[9].box:SetText("33")
	W.Run(o.rows[9].box, "OnEnterPressed")
	T.eq(Get("cameraZoomSpeed"), "33")
end)

T.test("presets: a section's lock box is for all of its groups", function()
	local EverySetting, o = Open()
	local graphics, distance, shadows = o.rows[GRAPHICS].lock, o.rows[DISTANCE].lock, o.rows[SHADOWS].lock
	T.ok(graphics:IsShown() and not graphics:GetChecked())
	W.Run(graphics, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock Graphics")
	W.Run(graphics, "OnLeave")
	graphics:SetChecked(true)
	W.Run(graphics, "OnClick")
	T.ok(EverySetting.IsLocked("farclip") and EverySetting.IsLocked("shadowSoft") and EverySetting.IsLocked("shadowMode"), "every group's knobs")
	T.ok(not EverySetting.IsLocked("ffxGlow"), "not the section's other CVars")
	T.ok(not EverySetting.IsLocked("cameraZoomSpeed"), "nor another section's")
	T.ok(distance:GetChecked() and shadows:GetChecked() and o.rows[5].lock:GetChecked(), "the groups' boxes and the knobs'")
	-- Ticked only while every group in it is locked.
	shadows:SetChecked(false)
	W.Run(shadows, "OnClick")
	T.ok(not graphics:GetChecked() and distance:GetChecked() and EverySetting.IsLocked("farclip"), "just that group is unlocked")
	o.rows[5].lock:SetChecked(true)
	W.Run(o.rows[5].lock, "OnClick")
	T.ok(not graphics:GetChecked(), "one of its knobs isn't enough")
	o.rows[6].lock:SetChecked(true)
	W.Run(o.rows[6].lock, "OnClick")
	T.ok(graphics:GetChecked() and shadows:GetChecked())
	graphics:SetChecked(false)
	W.Run(graphics, "OnClick")
	T.ok(not EverySetting.IsLocked("farclip") and not EverySetting.IsLocked("shadowSoft") and not EverySetting.IsLocked("shadowMode"))
	T.ok(not distance:GetChecked() and not shadows:GetChecked())
	-- Other CVars, when a search lists them under the section's knobs, has no box.
	o.refs.search:SetText("camera")
	T.ok(o.rows[3].item.others and o.rows[3].title:IsShown())
	T.ok(not o.rows[3].lock:IsShown())
end)

T.test("presets: Lock all locks every tuned setting, and Unlock all unlocks them", function()
	local EverySetting, o = Open()
	local button, tuned = o.refs.lockAll, { "farclip", "shadowSoft", "shadowMode", "cameraZoomSpeed" }
	T.eq(button.label:GetText(), "Lock all")
	W.Run(button, "OnEnter")
	T.eq(GameTooltip:GetText(), "Lock all")
	W.Run(button, "OnLeave")
	W.Run(button, "OnClick")
	for _, cvar in ipairs(tuned) do T.ok(EverySetting.IsLocked(cvar), cvar .. " is locked") end
	T.ok(not EverySetting.IsLocked("ffxGlow") and not EverySetting.IsLocked("cameraBobbing"), "not the other CVars")
	T.eq(button.label:GetText(), "Unlock all")
	T.ok(o.rows[GRAPHICS].lock:GetChecked() and o.rows[SHADOWS].lock:GetChecked() and o.rows[CAMERA].lock:GetChecked())
	W.Run(button, "OnClick")
	for _, cvar in ipairs(tuned) do T.ok(not EverySetting.IsLocked(cvar), cvar .. " is unlocked") end
	T.eq(button.label:GetText(), "Lock all")
	T.ok(not o.rows[GRAPHICS].lock:GetChecked())
	-- Locking everything another way turns it into Unlock all too.
	o.rows[GRAPHICS].lock:SetChecked(true)
	W.Run(o.rows[GRAPHICS].lock, "OnClick")
	T.eq(button.label:GetText(), "Lock all")
	o.rows[CAMERA].lock:SetChecked(true)
	W.Run(o.rows[CAMERA].lock, "OnClick")
	T.eq(button.label:GetText(), "Unlock all")
end)

T.test("presets: a header's menu marks only what the profile keeps, not values that just match", function()
	local EverySetting, o = Open()
	C_CVar.SetCVar("shadowMode", "3") -- as High has it, set outside Every Setting
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	T.ok(not MenuItem("tier:3").active and not MenuItem("style:Crisp").active, "High matches, but nothing is kept")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	Pick(o, SHADOWS, "tier:3")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	T.ok(MenuItem("tier:3").active, "marked once it's kept")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	EverySetting.Reset("shadowMode")
	EverySetting.SetLocked("shadowMode", true)
	C_CVar.SetCVar("shadowMode", "3")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
	T.ok(MenuItem("tier:3").active, "a locked setting counts as kept, as in the Styles panel")
	W.Run(o.rows[SHADOWS].presets, "OnClick")
end)

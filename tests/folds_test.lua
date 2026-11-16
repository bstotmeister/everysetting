-- Options.lua: folding the list by section and by group, against a stand-in client.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with the window open: Graphics has two groups and an
-- other CVar, and Sound one group. `saved` is last session's saved variables.
local function Open(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("horizonStart", "400")
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("gxMonitor", "0")
	W.AddCVar("FootstepSounds", "1")
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100 },
			{ cvar = "horizonStart", label = "Far horizon", type = "slider", min = 400, max = 5000, step = 100 },
		} },
		{ title = "Shadows", items = { { cvar = "shadowSoft", label = "Soft shadows", type = "toggle" } } },
		{ title = "Sound", items = { { cvar = "FootstepSounds", label = "Footsteps", type = "toggle" } } },
	}
	EverySetting.SECTIONS = { "Graphics", "Sound" }
	EverySetting.CVARS = { farclip = "1", horizonStart = "1", shadowSoft = "1", gxMonitor = "1", FootstepSounds = "2" }
	W.Login()
	EverySetting_OpenOptions()
	return EverySetting, ns.Options
end

local ALL = "[Graphics] [Draw distance] farclip horizonStart [Shadows] shadowSoft ... [Sound] FootstepSounds"

-- What the list shows: [a header], a CVar, or ... for the button that unfolds a section's other CVars.
local function Shown(o)
	local out = {}
	for _, item in ipairs(o.view) do
		out[#out + 1] = item.others and "[others]" or item.header and ("[" .. (item.group or item.section).title .. "]")
			or item.more and "..." or item.knob.cvar
	end
	return table.concat(out, " ")
end

-- The row with the header `title`.
local function Header(o, title)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.header and (row.item.group or row.item.section).title == title then return row end
	end
end

local function Fold(o, title) W.Run(Header(o, title).fold, "OnClick") end

-- Ticks or unticks Changed or Tuned, as a click does.
local function Tick(box, on)
	box:SetChecked(on)
	W.Run(box, "OnClick")
end

-- Picks a type ("toggle", "slider"...) from the type menu.
local function PickKind(o, value)
	W.Run(o.refs.kind, "OnClick")
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then W.Run(w, "OnClick") return end
	end
end

T.test("folds: a section folds to its title, and a group to its own", function()
	local _, o = Open()
	T.eq(Shown(o), ALL, "everything unfolded at first")
	local graphics, draw = Header(o, "Graphics"), Header(o, "Draw distance")
	T.ok(graphics.fold:IsShown() and not graphics.fold.plus:IsShown(), "a minus by the title")
	T.ok(draw.fold:IsShown() and draw.lock:IsShown(), "a group's header keeps its lock box")
	T.ok(Header(o, "Sound").fold:IsShown() and Header(o, "Sound").lock:IsShown(), "and so does a section's only group's")
	for _, row in ipairs(o.rows) do
		if row:IsShown() and not row.item.header then T.ok(not row.fold:IsShown(), "a knob row has no fold mark") end
	end
	Fold(o, "Draw distance")
	T.eq(Shown(o), "[Graphics] [Draw distance] [Shadows] shadowSoft ... [Sound] FootstepSounds")
	T.ok(Header(o, "Draw distance").fold.plus:IsShown(), "a plus while it's folded")
	Fold(o, "Graphics")
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds", "the section's groups, knobs and other CVars go")
	Fold(o, "Sound")
	T.eq(Shown(o), "[Graphics] [Sound]")
	Fold(o, "Graphics")
	Fold(o, "Sound")
	T.eq(Shown(o), "[Graphics] [Draw distance] [Shadows] shadowSoft ... [Sound] FootstepSounds", "the group stays folded")
	Fold(o, "Draw distance")
	T.eq(Shown(o), ALL)
end)

T.test("folds: Collapse all folds every section, and Expand all opens everything", function()
	local _, o = Open()
	local button = o.refs.foldAll
	T.eq(button.label:GetText(), "Collapse all")
	Fold(o, "Shadows")
	W.Run(button, "OnClick")
	T.eq(Shown(o), "[Graphics] [Sound]")
	T.eq(button.label:GetText(), "Expand all")
	W.Run(button, "OnEnter")
	W.Run(button, "OnClick")
	T.eq(Shown(o), ALL, "every section and group")
	T.eq(button.label:GetText(), "Collapse all")
	-- Folding every section by hand turns it into Expand all too.
	Fold(o, "Sound")
	T.eq(button.label:GetText(), "Collapse all")
	Fold(o, "Graphics")
	T.eq(button.label:GetText(), "Expand all")
	Fold(o, "Graphics")
	T.eq(button.label:GetText(), "Collapse all")
end)

T.test("folds: a search shows what it finds inside folds, and the folds come back", function()
	local _, o = Open()
	Fold(o, "Draw distance")
	Fold(o, "Graphics")
	o.refs.search:SetText("view")
	T.eq(Shown(o), "[Graphics] [Draw distance] farclip", "inside a folded section and group")
	T.ok(not o.rows[1].fold:IsShown() and not o.rows[2].fold:IsShown(), "no fold marks while it's on")
	T.ok(not o.refs.foldAll:IsEnabled() and o.refs.foldAll:GetAlpha() < 1, "nor Collapse all")
	W.Run(o.refs.search, "OnEscapePressed")
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds")
	T.ok(o.refs.foldAll:IsEnabled() and o.refs.foldAll:GetAlpha() == 1 and o.rows[1].fold:IsShown())
end)

T.test("folds: hold with Changed, which shows a folded title only while something under it is changed", function()
	local EverySetting, o = Open()
	EverySetting.Set("horizonStart", 2000)
	Fold(o, "Draw distance")
	Fold(o, "Sound")
	Tick(o.refs.changed, true)
	T.eq(Shown(o), "[Graphics] [Draw distance]", "the folded group's title, and not the folded section with nothing changed")
	T.ok(Header(o, "Graphics").fold:IsShown() and Header(o, "Draw distance").fold.plus:IsShown(), "the fold marks show")
	T.ok(o.refs.foldAll:IsEnabled())
	Fold(o, "Draw distance")
	T.eq(Shown(o), "[Graphics] [Draw distance] horizonStart", "unfolded, what's changed in it")
	EverySetting.Set("FootstepSounds", false)
	T.eq(Shown(o), "[Graphics] [Draw distance] horizonStart [Sound]", "the folded section, once something in it is changed")
	Fold(o, "Graphics")
	T.eq(Shown(o), "[Graphics] [Sound]")
	EverySetting.Reset("horizonStart")
	T.eq(Shown(o), "[Sound]")
	EverySetting.Set("gxMonitor", "1", true)
	T.eq(Shown(o), "[Graphics] [Sound]", "or one of its other CVars")
	Tick(o.refs.changed, false)
	T.eq(Shown(o), "[Graphics] [Sound]")
end)

T.test("folds: hold with Tuned", function()
	local _, o = Open()
	Fold(o, "Draw distance")
	Tick(o.refs.tuned, true)
	T.eq(Shown(o), "[Graphics] [Draw distance] [Shadows] shadowSoft [Sound] FootstepSounds")
	T.ok(Header(o, "Draw distance").fold.plus:IsShown() and Header(o, "Sound").fold:IsShown(), "the fold marks show")
	Fold(o, "Graphics")
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds")
	Tick(o.refs.tuned, false)
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds")
end)

T.test("folds: hold with a type, which shows a folded title only while something under it is that type", function()
	local _, o = Open()
	Fold(o, "Draw distance")
	PickKind(o, "toggle")
	T.eq(Shown(o), "[Graphics] [Shadows] shadowSoft [Sound] FootstepSounds", "a folded group of sliders goes")
	T.ok(Header(o, "Graphics").fold:IsShown(), "the fold marks show")
	PickKind(o, "slider")
	T.eq(Shown(o), "[Graphics] [Draw distance]")
	Fold(o, "Graphics")
	PickKind(o, "text")
	T.eq(Shown(o), "[Graphics]", "a folded section, for one of its other CVars")
	PickKind(o, "any")
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds")
end)

T.test("folds: Collapse all and Expand all work with Changed or Tuned", function()
	local EverySetting, o = Open()
	local button = o.refs.foldAll
	EverySetting.Set("horizonStart", 2000)
	Tick(o.refs.changed, true)
	T.ok(button:IsEnabled() and button:GetAlpha() == 1)
	W.Run(button, "OnClick")
	T.eq(Shown(o), "[Graphics]", "Sound has nothing changed")
	T.eq(button.label:GetText(), "Expand all")
	W.Run(button, "OnClick")
	T.eq(Shown(o), "[Graphics] [Draw distance] horizonStart")
	T.eq(button.label:GetText(), "Collapse all")
	Tick(o.refs.changed, false)
	Tick(o.refs.tuned, true)
	W.Run(button, "OnClick")
	T.eq(Shown(o), "[Graphics] [Sound]")
	W.Run(button, "OnClick")
	T.eq(Shown(o), "[Graphics] [Draw distance] farclip horizonStart [Shadows] shadowSoft [Sound] FootstepSounds")
end)

T.test("folds: the sidebar unfolds the section it goes to", function()
	local _, o = Open()
	Fold(o, "Draw distance")
	W.Run(o.refs.foldAll, "OnClick")
	W.Run(o.refs.side[2], "OnClick")
	T.eq(Shown(o), "[Graphics] [Sound] FootstepSounds", "just that section")
	W.Run(o.refs.side[1], "OnClick")
	T.eq(Shown(o), "[Graphics] [Draw distance] [Shadows] shadowSoft ... [Sound] FootstepSounds", "its groups stay as they were")
	T.eq(o.rows[1].title:GetText(), "Graphics")
end)

T.test("folds: the sidebar's group buttons unfold the group they go to", function()
	local _, o = Open()
	local graphics, sound = o.refs.side[1], o.refs.side[2]
	T.eq(#graphics.groups, 2, "a button per group")
	T.eq(#sound.groups, 0, "none for a section's only group")
	T.ok(graphics.groups[1]:IsShown() and graphics.groups[2]:IsShown(), "under the section in view")
	Fold(o, "Shadows")
	W.Run(o.refs.foldAll, "OnClick")
	W.Run(graphics.groups[2], "OnClick")
	T.eq(Shown(o), "[Graphics] [Draw distance] farclip horizonStart [Shadows] shadowSoft ... [Sound]", "its section and itself")
end)

T.test("folds: are saved for the account, and an older save without them loads", function()
	local _, o = Open()
	Fold(o, "Draw distance")
	Fold(o, "Sound")
	local saved = EverySettingDB
	T.eq(saved.folded["Graphics/Draw distance"], true, "a group by its section and title")
	T.eq(saved.folded.Sound, true, "a section by its title")
	_, o = Open(saved)
	T.eq(Shown(o), "[Graphics] [Draw distance] [Shadows] shadowSoft ... [Sound]", "after a reload")
	_, o = Open({ profiles = { Default = {} }, applied = "Default", before = {} })
	T.eq(Shown(o), ALL)
	T.eq(type(EverySettingDB.folded), "table")
	Fold(o, "Graphics")
	T.eq(EverySettingDB.folded.Graphics, true)
end)

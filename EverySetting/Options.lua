-- Every Setting window: one row per knob, with a slider, dropdown or checkbox. One
-- list, by section: the knobs from Knobs.lua first, then the section's other
-- CVars, which stay folded away until they're asked for. Sections and groups
-- fold down to their titles. After the CVars, Console commands lists the
-- game's other console commands, to copy. In danger mode a last section,
-- Danger, gathers the settings the game locks or its server enforces.

local ADDON, ns = ...
local EverySetting = ns.EverySetting
local L = ns.L

local BG      = { 0.055, 0.055, 0.065 }
local CARD    = { 0.095, 0.095, 0.110 }
local LINE    = { 0.200, 0.200, 0.230 }
local BTN     = { 0.130, 0.130, 0.150 }
local BTN_HI  = { 0.190, 0.190, 0.220 }
local ACCENT  = { 1.000, 0.690, 0.000 }
local DANGER  = { 1.000, 0.439, 0.349 } -- WARN's red, for the Danger section's title and sidebar button
local MUTED   = { 0.560, 0.560, 0.600 }
-- The accent as a colour code, for part of a line of text.
local AMBER   = ("|cff%02x%02x%02x"):format(
	math.floor(ACCENT[1] * 255 + 0.5), math.floor(ACCENT[2] * 255 + 0.5), math.floor(ACCENT[3] * 255 + 0.5))
local WARN    = "|cffff7059" -- redder than the accent, so a warning doesn't read as a kept setting
local HELD    = "|cff66ccff" -- a setting a situation is holding

local WIDTH, HEIGHT = 940, 620
local PAD = 16
local SIDE_W = 170
local ROW_H = 28
local LABEL_W = 250
local CONTROL_X = LABEL_W + 12
local NAME_X = 30 -- a knob's name or a group's title, right of its lock box
local FOLD_W = 22 -- a header's fold mark, left of its title
local SLIDER_W, BOX_W, BOX_H = 210, 56, 20
local THUMB_W = 8
local PRESETS_W = 140

local win, dialog
local refs = {}   -- widgets the refresh needs
local rows = {}   -- the list's row frames, reused as it scrolls
local view = {}   -- what the list shows, a row each (see Filter)
local first = 1   -- index in `view` of the top row
local open = {}   -- section -> true while its other CVars are unfolded
local kind        -- the one type of knob to show ("toggle", "slider"...), or nil for all
local filtering   -- true while a search narrows the list, which sets the folds aside
ns.Options = { refs = refs, rows = rows, view = view } -- for the tests

-- The list's sections: { title, groups, more } for each of CVars.lua's sections
-- that has anything. `groups` are its groups from Knobs.lua and `more` its
-- other CVars, in name order. After them, Console commands has the client's
-- console commands that aren't CVars (`commands` is true), each with the button
-- that gives it to copy.
--
-- The last one is Danger. In danger mode the danger settings among a section's
-- other CVars (`all` has every one of them) are listed under Danger instead, in
-- a group for each kind (Kind). Outside it, Danger holds nothing.
local sections
local place = {} -- knob -> the section it's listed under
local arranged -- whether the sections are filled in for danger mode

-- A danger setting's kind, for its group under Danger and its tooltip: "server",
-- "setter" (locked, and set through the game's own function for it), "locked"
-- (locked, with none: the game offers no way to change it) or "readonly" (none either).
local function Kind(knob)
	if knob.danger ~= "server" and knob.setter then return "setter" end
	return knob.danger
end

-- Whether the game offers no way to change a danger setting, danger mode or not.
local function Refused(knob)
	local what = Kind(knob)
	return what == "locked" or what == "readonly"
end

local function Danger()
	local section = { title = L.DANGER, danger = true, groups = {}, all = {}, more = {} }
	for i, group in ipairs({ { "server", L.SERVER_ENFORCED }, { "setter", L.LOCKED_INDIRECT }, { "locked", L.LOCKED_NO_WAY },
		{ "readonly", L.READ_ONLY } }) do
		section.groups[i] = { kind = group[1], title = group[2], items = {} }
	end
	return section
end

-- Whether a section has anything to list: Danger has nothing outside danger
-- mode, and in it a section may have lost all it had to Danger.
local function Listed(section)
	for _, group in ipairs(section.groups) do
		if #group.items > 0 then return true end
	end
	return #section.more > 0
end

-- Fills in each section's `more`, and Danger's groups, for danger mode on or off.
local function Arrange(on)
	local danger = sections[#sections]
	local byKind = {}
	for _, group in ipairs(danger.groups) do
		wipe(group.items)
		byKind[group.kind] = group
	end
	for _, section in ipairs(sections) do
		wipe(section.more)
		section.holds = nil -- what its presets cover (see Holds)
		for _, knob in ipairs(section.all) do
			if on and knob.danger then
				local items = byKind[Kind(knob)].items
				items[#items + 1] = knob
				place[knob] = danger
			else
				section.more[#section.more + 1] = knob
				place[knob] = section
			end
		end
	end
	for _, group in ipairs(danger.groups) do
		table.sort(group.items, function(a, b) return a.cvar:lower() < b.cvar:lower() end)
	end
	arranged = on
end

-- Whether a tuned knob is listed: a CVar this client lacks gets no row, and a
-- group of only those no header (retail has no loot sparkles or HDR). A setting
-- that isn't a CVar, which the game can offer only to some characters (a
-- tracking filter), is listed, marked as not found.
local function InClient(knob) return knob.found or knob.calls ~= nil end

local function Sections()
	if not sections then
		local byTitle, tuned = {}, {}
		sections = {}
		for i, title in ipairs(EverySetting.SECTIONS) do
			sections[i] = { title = title, groups = {}, all = {}, more = {} }
			byTitle[title] = sections[i]
		end
		-- After the CVars, the console commands that aren't CVars: the ones that take
		-- a value, with a row of their own (EverySetting.Section gives them this
		-- section), and the rest to copy.
		local commands = { title = L.CONSOLE_COMMANDS, commands = true, groups = {}, all = {}, more = {} }
		sections[#sections + 1] = commands
		for _, group in ipairs(EverySetting.GROUPS) do
			local section, any = sections[EverySetting.Section(group.items[1].cvar)], false
			for _, knob in ipairs(group.items) do
				tuned[knob], place[knob] = true, section
				any = any or InClient(knob)
			end
			if any then section.groups[#section.groups + 1] = group end
		end
		for _, all in ipairs(EverySetting.AllGroups()) do
			local section = byTitle[all.title]
			for _, knob in ipairs(all.items) do
				if not tuned[knob] then section.all[#section.all + 1] = knob end
			end
		end
		for _, knob in ipairs(EverySetting.ConsoleCommands()) do commands.all[#commands.all + 1] = knob end
		sections[#sections + 1] = Danger()
		Arrange(false)
		-- A section with nothing at all goes. Danger stays, and so does one that only
		-- danger mode empties: the sidebar has a button for each, made once.
		for i = #sections - 1, 1, -1 do
			if not Listed(sections[i]) then table.remove(sections, i) end
		end
	end
	if EverySetting.GetDanger() ~= arranged then Arrange(EverySetting.GetDanger()) end
	return sections
end

-- A folded section or group shows just its header. Folds are saved by title,
-- a group's after its section's ("Camera/Action camera"), so a reload keeps them.
local function FoldKey(section, group)
	return group and section.title .. "/" .. group.title or section.title
end

local function Folded(section, group)
	return EverySetting.GetFolded()[FoldKey(section, group)] == true
end

local function SetFolded(section, group, on)
	EverySetting.GetFolded()[FoldKey(section, group)] = on or nil
end

local function AllFolded()
	for _, section in ipairs(Sections()) do
		if Listed(section) and not Folded(section) then return false end
	end
	return true
end

-------------------------------------------------------------------------------
-- Small widget kit (plain textures, no Blizzard templates)
-------------------------------------------------------------------------------

local function Fill(frame, layer, c, a)
	local t = frame:CreateTexture(nil, layer)
	t:SetAllPoints()
	t:SetColorTexture(c[1], c[2], c[3], a or 1)
	return t
end

local function Outline(frame, c)
	local function edge()
		local t = frame:CreateTexture(nil, "BORDER")
		t:SetColorTexture(c[1], c[2], c[3], 1)
		return t
	end
	local top, bottom, left, right = edge(), edge(), edge(), edge()
	top:SetPoint("TOPLEFT") top:SetPoint("TOPRIGHT") top:SetHeight(1)
	bottom:SetPoint("BOTTOMLEFT") bottom:SetPoint("BOTTOMRIGHT") bottom:SetHeight(1)
	left:SetPoint("TOPLEFT") left:SetPoint("BOTTOMLEFT") left:SetWidth(1)
	right:SetPoint("TOPRIGHT") right:SetPoint("BOTTOMRIGHT") right:SetWidth(1)
end

local function Text(parent, font, str, color)
	local fs = parent:CreateFontString(nil, "OVERLAY", font)
	fs:SetText(str or "")
	if color then fs:SetTextColor(color[1], color[2], color[3]) end
	return fs
end

-- `title` and `body` are strings, or functions of the owner that return one.
-- A tooltip for `owner`. `title` and `body` are text, or functions of `owner`
-- that return it: no title, no tooltip; no body, just the title.
local function Tooltip(owner, title, body)
	owner:HookScript("OnEnter", function(self)
		local t, b = title, body
		if type(t) == "function" then t = t(self) end
		if not t then return end
		GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
		GameTooltip:SetText(t, 1, 1, 1)
		if type(b) == "function" then b = b(self) end
		if b and b ~= "" then GameTooltip:AddLine(b, nil, nil, nil, true) end
		GameTooltip:Show()
	end)
	owner:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

-- Whether a line of text is cut short to fit, as a longer language's can be.
local function Cut(fs) return fs.IsTruncated ~= nil and fs:IsTruncated() end

-- A flat button. It's filled with the accent color while it is active, but for
-- a group's in the sidebar, whose title turns amber. A menu's heading is muted,
-- and the mouse doesn't light it up, and so is an option this computer can't use.
-- The sidebar's button for Danger is red: its label, or its fill while it's active.
local function Paint(b)
	local c
	local red = b.section and b.section.danger
	if b.heading or b.unsupported then
		c = BTN
		b.label:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
	elseif b.active and b.group then
		c = b.hover and BTN_HI or BTN
		b.label:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3])
	elseif b.active then
		c = red and DANGER or ACCENT
		b.label:SetTextColor(0.05, 0.05, 0.05)
	else
		c = b.hover and BTN_HI or BTN
		local shade = b.hover and 0.95 or 0.72
		if red then b.label:SetTextColor(DANGER[1], DANGER[2], DANGER[3]) else b.label:SetTextColor(shade, shade, shade) end
	end
	b.bg:SetColorTexture(c[1], c[2], c[3], 1)
end

local RUN_W = 44 -- a console command's Run button

local function Button(parent, label, w, h, onClick)
	local b = CreateFrame("Button", nil, parent)
	b:SetSize(w, h)
	b.bg = Fill(b, "BACKGROUND", BTN)
	Outline(b, LINE)
	b.label = Text(b, "GameFontHighlightSmall", label)
	-- Cut short with "..." where a language's words run wider than the button.
	b.label:SetPoint("LEFT", 4, 0)
	b.label:SetPoint("RIGHT", -4, 0)
	b.label:SetWordWrap(false)
	b:SetScript("OnEnter", function(self) self.hover = true Paint(self) end)
	b:SetScript("OnLeave", function(self) self.hover = false Paint(self) end)
	if onClick then b:SetScript("OnClick", onClick) end
	Paint(b)
	return b
end

local function SetActive(b, on)
	b.active = on and true or false
	Paint(b)
end

local function Checkbox(parent, label, onClick)
	local c = CreateFrame("CheckButton", nil, parent)
	c:SetSize(16, 16)
	Fill(c, "BACKGROUND", BTN)
	Outline(c, LINE)
	local mark = c:CreateTexture(nil, "ARTWORK")
	mark:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
	mark:SetPoint("TOPLEFT", 3, -3)
	mark:SetPoint("BOTTOMRIGHT", -3, 3)
	c:SetCheckedTexture(mark)
	c.text = Text(c, "GameFontHighlight", label)
	c.text:SetPoint("LEFT", c, "RIGHT", 8, 0)
	c:SetHitRectInsets(0, -(c.text:GetStringWidth() + 12), 0, 0)
	c:SetScript("OnClick", onClick)
	return c
end

-- A small box for a number. `onCommit` gets the text when Enter is pressed or
-- the box loses focus, or nil if nothing was typed or Escape was pressed.
local function NumberBox(parent, onCommit)
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(BOX_W, BOX_H)
	e:SetAutoFocus(false)
	e:SetFontObject("GameFontHighlightSmall")
	e:SetJustifyH("CENTER")
	e:SetTextInsets(4, 4, 0, 0)
	e:SetMaxLetters(10)
	Fill(e, "BACKGROUND", BTN)
	Outline(e, LINE)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	e:SetScript("OnEscapePressed", function(self)
		self.cancel = true
		self:ClearFocus()
	end)
	e:SetScript("OnEditFocusGained", function(self) self.was = self:GetText() end)
	e:SetScript("OnEditFocusLost", function(self)
		local cancel = self.cancel
		self.cancel = nil
		-- Clicking in and out without typing changes nothing.
		local text = self:GetText()
		onCommit(self, not cancel and text ~= self.was and text or nil)
	end)
	return e
end

-- A text box with a grey hint while it's empty. `onChange` gets the text.
local function SearchBox(parent, w, h, hint, onChange)
	local e = CreateFrame("EditBox", nil, parent)
	e:SetSize(w, h)
	e:SetAutoFocus(false)
	e:SetFontObject("GameFontHighlightSmall")
	e:SetTextInsets(6, 6, 0, 0)
	e:SetMaxLetters(40)
	Fill(e, "BACKGROUND", BTN)
	Outline(e, LINE)
	local placeholder = Text(e, "GameFontDisableSmall", hint)
	placeholder:SetPoint("LEFT", 6, 0)
	placeholder:SetPoint("RIGHT", -6, 0)
	placeholder:SetJustifyH("LEFT")
	placeholder:SetWordWrap(false)
	e:SetScript("OnEnterPressed", e.ClearFocus)
	e:SetScript("OnEscapePressed", function(self)
		self:SetText("")
		self:ClearFocus()
	end)
	e:SetScript("OnTextChanged", function(self)
		local text = self:GetText()
		placeholder:SetShown(text == "")
		onChange(text)
	end)
	return e
end

-- Where the mouse is along `frame`, from 0 (its left end) to 1, leaving `inset`
-- at each end.
local function CursorFraction(frame, inset)
	local x = GetCursorPosition() / frame:GetEffectiveScale()
	local f = (x - frame:GetLeft() - inset) / (frame:GetWidth() - 2 * inset)
	return math.min(1, math.max(0, f))
end

-- A slider: a track with a thumb. It works in fractions, 0 (left) to 1.
-- `onDrag(slider, fraction)` runs as the thumb moves and returns the fraction
-- to show (so it can snap to steps); `onRelease(slider, fraction)` when it's let go.
local function Slider(parent, w, onDrag, onRelease)
	local s = CreateFrame("Button", nil, parent)
	s:SetSize(w, 16)
	local track = s:CreateTexture(nil, "BACKGROUND")
	track:SetColorTexture(LINE[1], LINE[2], LINE[3], 1)
	track:SetPoint("LEFT") track:SetPoint("RIGHT")
	track:SetHeight(4)
	local fill = s:CreateTexture(nil, "ARTWORK")
	fill:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.9)
	fill:SetPoint("LEFT")
	fill:SetHeight(4)
	local thumb = s:CreateTexture(nil, "OVERLAY")
	thumb:SetColorTexture(0.92, 0.92, 0.92, 1)
	thumb:SetSize(THUMB_W, 14)

	function s:SetFraction(f)
		f = math.min(1, math.max(0, f))
		self.fraction = f
		local x = f * (w - THUMB_W)
		thumb:ClearAllPoints()
		thumb:SetPoint("LEFT", x, 0)
		fill:SetWidth(math.max(1, x))
		fill:SetShown(x >= 1)
	end

	local function Follow(self)
		self:SetFraction(onDrag(self, CursorFraction(self, THUMB_W / 2)))
	end
	s:SetScript("OnMouseDown", function(self)
		if self.off then return end
		self.dragging = true
		Follow(self)
		self:SetScript("OnUpdate", Follow)
	end)
	s:SetScript("OnMouseUp", function(self)
		if not self.dragging then return end
		self.dragging = false
		self:SetScript("OnUpdate", nil)
		onRelease(self, self.fraction)
	end)
	s:SetFraction(0)
	return s
end

-------------------------------------------------------------------------------
-- Dropdown
-------------------------------------------------------------------------------

local menu -- the one list of options, shown under whichever dropdown is open

local function CloseMenu()
	if menu then menu:Hide() end
end

-- Marks the menu's options: the one that's `current`, or each one that a
-- `current` that's a function says is ticked.
local function MarkMenu()
	local current = menu.current
	for i = 1, menu.count do
		local b = menu.items[i]
		local on
		if type(current) == "function" then on = current(b.value) else on = tostring(b.value) == tostring(current) end
		SetActive(b, not b.heading and on)
	end
end

-- Shows `options` ({ value, "Label" } each, or { value, "Label", "Tip" } for
-- one with a tooltip) under `owner`. A heading over the options after it is
-- { nil, "Label", heading = true }: muted, with no tooltip, and it can't be
-- picked. An option with `unsupported` (the game's words for why this computer
-- can't use it) is muted too, can't be picked, and says why in its tooltip. `current` is the value to mark, and `onPick(value)` runs for the one
-- that's clicked. The menu is as wide as `owner`, or `width`.
--
-- For a menu of ticks, `current` is a function of an option's value that
-- returns whether it's ticked. Clicking one leaves the menu open, to tick more.
local function OpenMenu(owner, options, current, onPick, width)
	if not menu then
		menu = CreateFrame("Frame", nil, win)
		menu:SetFrameStrata("FULLSCREEN_DIALOG")
		menu:EnableMouse(true)
		Fill(menu, "BACKGROUND", CARD)
		Outline(menu, ACCENT)
		menu.items = {}
		-- Clicking anywhere else closes it.
		menu.catcher = CreateFrame("Button", nil, menu)
		menu.catcher:SetFrameStrata("FULLSCREEN") -- over the window, under the menu
		menu.catcher:SetAllPoints(UIParent)
		menu.catcher:SetScript("OnClick", CloseMenu)
		menu:Hide()
	end
	if menu:IsShown() and menu.owner == owner then return CloseMenu() end
	menu.owner = owner
	local w = width or owner:GetWidth()
	for i, option in ipairs(options) do
		local b = menu.items[i]
		if not b then
			b = Button(menu, "", w - 2, BOX_H, function(self)
				if self.heading or self.unsupported then return end
				GameTooltip:Hide()
				if type(menu.current) == "function" then
					menu.onPick(self.value)
					return MarkMenu()
				end
				CloseMenu()
				menu.onPick(self.value)
			end)
			b:SetPoint("TOPLEFT", 1, -1 - (i - 1) * BOX_H)
			b.label:ClearAllPoints()
			b.label:SetPoint("LEFT", 8, 0)
			b.label:SetPoint("RIGHT", -8, 0)
			b.label:SetJustifyH("LEFT")
			-- An option with a tip shows it while the mouse is over it, and one cut short its whole label.
			-- One this computer can't use says why, in the game's red.
			Tooltip(b, function(self) return (self.tip or self.unsupported or Cut(self.label)) and self.label:GetText() end,
				function(self)
					local why = self.unsupported and ("|cffff2020" .. self.unsupported .. "|r")
					if why and self.tip then return self.tip .. "\n" .. why end
					return why or self.tip
				end)
			menu.items[i] = b
		end
		b:SetWidth(w - 2)
		-- Set on every open: the button may have been a heading last time, or not.
		b.value, b.tip, b.heading, b.unsupported = option[1], option[3], option.heading, option.unsupported
		b.label:SetText(option[2])
		b:Show()
	end
	for i = #options + 1, #menu.items do menu.items[i]:Hide() end
	menu.onPick, menu.current, menu.count = onPick, current, #options
	MarkMenu()
	local h = #options * BOX_H + 2
	menu:SetSize(w, h)
	menu:ClearAllPoints()
	-- Below the dropdown, or above it when there's no room below.
	local bottom = owner:GetBottom()
	if bottom and bottom * owner:GetEffectiveScale() < h + 8 then
		menu:SetPoint("BOTTOMLEFT", owner, "TOPLEFT", 0, 2)
	else
		menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
	end
	menu:Show()
end

local function Dropdown(parent, w, onClick)
	local d = Button(parent, "", w, BOX_H, onClick)
	d.label:ClearAllPoints()
	d.label:SetPoint("LEFT", 8, 0)
	d.label:SetPoint("RIGHT", -22, 0)
	d.label:SetJustifyH("LEFT")
	d.label:SetWordWrap(false)
	local arrow = d:CreateTexture(nil, "ARTWORK")
	arrow:SetTexture("Interface\\Buttons\\Arrow-Down-Up")
	arrow:SetSize(14, 14)
	arrow:SetPoint("RIGHT", -4, -3)
	return d
end

-------------------------------------------------------------------------------
-- Knobs as text
-------------------------------------------------------------------------------

-- A CVar value without the padding the game stores: "20.000000" is "20".
local function Short(value)
	local n = tonumber(value)
	if not n then return value or "" end
	return (("%.4f"):format(n):gsub("(%.%d-)0+$", "%1"):gsub("%.$", ""))
end

-- A choice's option for `value` ({ value, "Label" }), or nil if it has none. A
-- value in parts ("2,0": MSAAQuality's quality and coverage) goes by its first
-- part, as it does in Blizzard's menu.
local function Option(knob, value)
	value = tostring(Short(value))
	local part, found = value:match("^([^,]*),"), nil
	for _, option in ipairs(EverySetting.Options(knob)) do
		if tostring(option[1]) == value then return option end
		if tostring(option[1]) == part then found = option end
	end
	return found
end

-- A choice's label for `value`.
local function OptionLabel(knob, value)
	local option = Option(knob, value)
	return option and option[2] or L.CUSTOM_VALUE:format(Short(value))
end

-- A flags knob's value in words: the flags that are on.
local function FlagLabels(knob, value)
	local on = {}
	for _, flag in ipairs(knob.options) do
		if EverySetting.Flag(value, flag[1]) then on[#on + 1] = flag[2] end
	end
	return #on > 0 and table.concat(on, ", ") or L.NONE
end

-- A raw value as text the game's font can draw: the push-to-talk key's has a tab
-- between its keys, which shows as a space.
local function Spaced(value)
	return (value:gsub("\t", " "))
end

-- A knob's value as the tooltip shows it.
local function Describe(knob, value)
	if value == nil then return "?" end
	local n = tonumber(value)
	if knob.type == "toggle" and (n == 0 or n == 1) then return n == 1 and L.ON or L.OFF end
	if knob.type == "choice" then return OptionLabel(knob, value) end
	if knob.type == "flags" then return FlagLabels(knob, value) end
	if knob.raw then return value == "" and L.EMPTY or Spaced(value) end
	return Short(value)
end

-- What a tooltip says a change waits for, by the knob's `restart`: for any change,
-- and for a change to one value, where only that one waits (knob.restartTo).
local RESTART = {
	gx = { L.RESTART_GX, L.RESTART_GX_TO },
	window = { L.RESTART_WINDOW, L.RESTART_WINDOW_TO },
	reload = { L.RESTART_RELOAD, L.RESTART_RELOAD_TO },
	login = { L.RESTART_LOGIN, L.RESTART_LOGIN_TO },
	client = { L.RESTART_CLIENT, L.RESTART_CLIENT_TO },
}

-- Where the game saves a setting, by knob.storage.
local STORAGE = {
	account = L.STORAGE_ACCOUNT,
	character = L.STORAGE_CHARACTER,
	computer = L.STORAGE_COMPUTER,
	bindings = L.STORAGE_BINDINGS,
	server = L.STORAGE_SERVER,
	session = L.STORAGE_SESSION,
}

local function TipTitle(row)
	return row.item and row.item.knob and row.item.knob.label
end

-- What a row and its tooltip say of a value past the knob's range, by which
-- side (EverySetting.Past). The range is the game's own quality levels there.
local PAST = { [1] = L.PAST_TOP, [-1] = L.PAST_BOTTOM }
local THIS_PAST = { [1] = L.THIS_PAST_TOP, [-1] = L.THIS_PAST_BOTTOM }

-- What a row says under its name, and its tooltip, of what turning a knob up
-- costs (knob.cost), and where that comes from (knob.costSrc).
local COST_MARK = { heavy = WARN .. L.COST_MARK_HEAVY .. "|r", medium = "|cff888888" .. L.COST_MARK_MEDIUM .. "|r",
	light = "|cff888888" .. L.COST_MARK_LIGHT .. "|r" }
local COST = { heavy = L.COST_HEAVY, medium = L.COST_MEDIUM, light = L.COST_LIGHT }
local COST_SRC = { probe = L.COST_SRC_PROBE, guide = L.COST_SRC_GUIDE }

-- What a danger setting's tooltip starts with, by Kind: why it's left alone, and
-- the warning once danger mode lets it be changed. One the game offers no way to
-- change says so either way, and danger mode isn't offered for it.
local DANGER_TIP = {
	server = { L.DANGER_SERVER, L.DANGER_SERVER_ON },
	setter = { L.DANGER_LOCKED, L.DANGER_SETTER_ON },
	locked = { L.DANGER_LOCKED_NO_WAY, L.DANGER_LOCKED_NO_WAY },
	readonly = { L.DANGER_READONLY_NO_WAY, L.DANGER_READONLY_NO_WAY },
}

-- Not default: a CVar whose value isn't the game's default, whatever set it.
-- The CVars the game's graphics quality settings set, level by level
-- (data/presets.lua), are left out, and so are their raid twins: no level
-- keeps their engine default (view distance is 1000 by default and 10000 at
-- the top level), so the quality setting is the one that says what changed.
local QUALITY = {} -- lower-case CVar name -> true
for _, cvar in ipairs({ "wmoLodDist", "farclip", "horizonStart", "terrainLodDist", "horizonClip",
	"entityShadowFadeScale", "entityLodDist", "TerrainLodDiv", "lodObjectFadeScale", "lodObjectCullSize",
	"lodObjectMinSize", "doodadLodScale", "groundEffectDist", "groundEffectDensity", "shadowMode",
	"shadowNumCascades", "shadowTextureSize", "shadowSoft", "rippleDetail", "waterDetail", "reflectionMode",
	"particleMTDensity", "particleDensity", "weatherDensity", "SSAO", "refraction", "DepthBasedOpacity",
	"sunShafts", "volumeFogLevel", "OutlineEngineMode", "spellClutter", "spellVisualDensityFilterSetting",
	"projectedTextures", "terrainMipLevel", "worldBaseMip", "componentTextureLevel", "giQuality",
	"RenderFormat", "pbrLiquidDetail" }) do
	QUALITY[cvar:lower()], QUALITY[("RAID" .. cvar):lower()] = true, true
end
ns.Options.quality = QUALITY

-- The values the game writes for itself are left out too: no player chose them.
-- Kept, they'd be set again at every login, and an exported profile would take
-- them to another computer. Each with its source.
local OWN = {} -- lower-case CVar name -> true
for _, cvar in ipairs({
	-- The game's language, from the launcher. Their default is empty, so every
	-- client has one off it, and kept, a language picked in the launcher would be undone.
	"locale", "textLocale", "audioLocale",
	"agentUID", "portal", -- from Battle.net, their help says; empty by default too
	"hwDetect", -- the game's hardware detection: 1 runs it at the next start, and the game then sets 0
	-- The graphics API the game picked (auto by default). On a Mac the game's menu
	-- has no choice of it (Graphics.lua, IsMacClient), and on Windows Not default
	-- can't tell a pick from the game's. Set in its row, it's kept like any other.
	"GxApi",
	-- What the login screens have shown: the game's code sets each once it has
	-- (GlueParent.lua, GlueParentUtil.lua, CharacterCreate.lua). The movie and the
	-- warning go by expansion, so a kept one would show them again after the next.
	"playIntroMovie", "showPhotosensitivityWarning", "showScreenNarrationDialog", "showCreateCharacterRealmConfirmDialog",
}) do
	OWN[cvar:lower()] = true
end
ns.Options.own = OWN

-- And every ClientSettings_ CVar: the game's own record of what each graphics API
-- and card gets. Blizzard's interface code never reads one, and a mask's value
-- starts with the interface version (16001,0x0,...), so an old one would come
-- back after an update.
local function Own(cvar)
	cvar = cvar:lower()
	return OWN[cvar] or cvar:find("^clientsettings_") ~= nil
end

-- Whether the knob's `value` isn't the game's default: "1" and "1.000000" are the
-- same, and so are a flags knob's "0" and "\002".
local function OffDefault(knob, value)
	return knob.found and value ~= nil and not QUALITY[knob.cvar:lower()] and not Own(knob.cvar)
		and not EverySetting.SameAs(knob, value, knob.default)
end

local function TipBody(row)
	local knob = row.item and row.item.knob
	if not knob then return end
	if knob.type == "command" then
		return (knob.tip or "|cff888888" .. L.NO_DESCRIPTION .. "|r") .. "\n\n" .. (knob.runs and L.COMMAND_RUNS or L.COMMAND_COPY_ONLY)
			.. "\n\n|cff888888" .. L.CONSOLE_COMMAND_NAME:format(knob.cvar) .. "|r"
	end
	local lines = {}
	local danger = knob.danger and EverySetting.GetDanger()
	if not knob.found then
		lines[#lines + 1] = "|cffff6060" .. L.NOT_IN_CLIENT .. "|r"
	elseif danger then
		lines[#lines + 1] = WARN .. DANGER_TIP[Kind(knob)][2] .. "|r " .. L.DANGER_COMMAND_BUTTON
	elseif knob.danger then
		lines[#lines + 1] = "|cffff6060" .. DANGER_TIP[Kind(knob)][1] .. "|r" .. (Refused(knob) and "" or " " .. L.DANGER_MODE_HINT)
	end
	lines[#lines + 1] = knob.tip or (knob.raw and "|cff888888" .. L.NO_DESCRIPTION .. "|r") or nil
	if knob.cost then
		lines[#lines + 1] = COST[knob.cost] .. " " .. COST_SRC[knob.costSrc] .. " " .. L.COST_FRAMERATE
	end
	local heldValue, by = EverySetting.Held(knob.cvar)
	if by then
		lines[#lines + 1] = HELD .. L.HELD_BY:format(by, Describe(knob, heldValue)) .. "|r " .. L.HELD_AFTER
	end
	if knob.found then
		local now = L.NOW_AND_DEFAULT:format(Describe(knob, EverySetting.Get(knob.cvar)), Describe(knob, knob.default))
		local goesPast = EverySetting.GoesPast(knob)
		if knob.type == "slider" then
			local min, max = EverySetting.Bounds(knob)
			now = now .. "\n" .. ((knob.raw or goesPast) and L.USUAL_RANGE or L.RANGE):format(Short(min), Short(max))
		end
		lines[#lines + 1] = now
		if knob.unread then
			lines[#lines + 1] = L.UNREAD
		end
		if knob.raw and knob.type ~= "flags" and (danger or not knob.locked) and not (knob.danger and Refused(knob)) then
			lines[#lines + 1] = L.BOX_ANY_VALUE
		elseif goesPast then
			local past = EverySetting.Past(knob, EverySetting.Get(knob.cvar))
			lines[#lines + 1] = (past and WARN .. THIS_PAST[past] .. "|r " or "") .. L.PAST_RANGE
		end
		if EverySetting.IsPending(knob.cvar) then
			lines[#lines + 1] = WARN .. L.WAITING_FOR_COMBAT .. "|r"
		elseif knob.calls then
			lines[#lines + 1] = L.CALLS_OUT_OF_COMBAT
		elseif knob.secure then
			lines[#lines + 1] = L.SECURE_IN_COMBAT
		end
		if knob.restart then
			local says = RESTART[knob.restart]
			lines[#lines + 1] = WARN .. (knob.restartTo and says[2]:format(Describe(knob, knob.restartTo)) or says[1]) .. "|r"
		end
		if EverySetting.IsStored(knob.cvar) then
			local before = EverySetting.Before(knob.cvar)
			lines[#lines + 1] = AMBER .. L.KEPT_AT_LOGIN .. "|r "
				.. (before == nil and L.RESET_LEAVES or L.RESET_PUTS_BACK:format(Describe(knob, before)))
		elseif OffDefault(knob, EverySetting.Get(knob.cvar)) then
			lines[#lines + 1] = L.OFF_DEFAULT
		end
		local _, changedBy = EverySetting.ChangedBy(knob.cvar)
		if changedBy then lines[#lines + 1] = L.LAST_CHANGED_BY:format(changedBy) end
	end
	local where = ""
	if knob.found then
		where = " " .. STORAGE[knob.storage]
		if knob.storage == "character" and EverySetting.IsStored(knob.cvar) then
			where = where .. " " .. L.EVERY_CHARACTER_GETS
		end
	end
	-- A row that goes by its CVar's own name says so: it has no plain name yet.
	if knob.raw and knob.label == knob.cvar then
		lines[#lines + 1] = "|cff888888" .. L.NO_PLAIN_NAME .. "|r"
	end
	local name = knob.calls and L.NOT_A_CVAR:format(knob.calls)
		or knob.raid and L.CVAR_AND_RAID:format(knob.cvar, knob.raid) or L.CVAR_NAME:format(knob.cvar)
	lines[#lines + 1] = "|cff888888" .. name .. where .. "|r"
	return table.concat(lines, "\n\n")
end

-------------------------------------------------------------------------------
-- Rows
-------------------------------------------------------------------------------

local Refresh, PresetMenu, ShowDialog -- defined below

-- A color knob's value ("FF2B9305": alpha, red, green, blue, or the last three
-- alone) as red, green and blue from 0 to 1. Black for a value that isn't a color.
local function Color(value)
	value = value or ""
	local r, g, b = value:match("^%x%x(%x%x)(%x%x)(%x%x)$")
	if not r then r, g, b = value:match("^(%x%x)(%x%x)(%x%x)$") end
	if not r then return 0, 0, 0 end
	return tonumber(r, 16) / 255, tonumber(g, 16) / 255, tonumber(b, 16) / 255
end

-- Opens the game's color picker on a color knob's color. The knob is set once,
-- when the picker closes with its OK button: the picker reports every color
-- the mouse passes on the way, and each would be a change for Undo.
local picked -- while the picker is open for a knob: { cvar, hex = the color picked so far }

local function PickColor(knob)
	if picked == nil then
		ColorPickerFrame:HookScript("OnHide", function()
			local pick = picked
			picked = false
			-- Not if something else has opened the picker since: it's theirs to close.
			if pick and pick.hex and ColorPickerFrame.swatchFunc == pick.swatch then EverySetting.Set(pick.cvar, pick.hex) end
		end)
	end
	local pick = { cvar = knob.cvar }
	picked = pick
	local value = EverySetting.Get(knob.cvar) or ""
	local alpha = (value:match("^(%x%x)%x%x%x%x%x%x$") or "FF"):upper() -- the picker here is for the color alone
	local r, g, b = Color(value)
	pick.swatch = function()
		local red, green, blue = ColorPickerFrame:GetColorRGB()
		pick.hex = ("%s%02X%02X%02X"):format(alpha, math.floor(red * 255 + 0.5), math.floor(green * 255 + 0.5), math.floor(blue * 255 + 0.5))
	end
	ColorPickerFrame:SetupColorPickerAndShow({
		r = r, g = g, b = b,
		swatchFunc = pick.swatch,
		cancelFunc = function() pick.hex = nil end,
	})
end

-- Locks: styles and presets leave a locked setting alone. A knob's row has a
-- box for its lock, a group's header a box for all of the group's, and a
-- section's header one for all of its groups'.
local LOCK_TIP, GROUP_LOCK_TIP = L.LOCK_TIP, L.GROUP_LOCK_TIP

-- The groups a header's lock box is for, and what its tooltip calls them: a
-- group's own; a section's only group, whose header stands in for the
-- group's; or all of a section's groups. Its other CVars aren't in them, and
-- Danger's headers have no lock box.
local function HeaderGroups(item)
	if item.section.danger then return end
	if item.group then return { item.group }, item.group.title end
	local groups = item.section.groups
	if item.others or #groups == 0 then return end
	return groups, #groups == 1 and groups[1].title or item.section.title
end

-- Whether every knob in the group is locked.
local function GroupLocked(group)
	for _, knob in ipairs(group.items) do
		if not EverySetting.IsLocked(knob.cvar) then return false end
	end
	return true
end

local function AllLocked(groups)
	for _, group in ipairs(groups) do
		if not GroupLocked(group) then return false end
	end
	return true
end

-- Locks every knob in the groups, or unlocks them, and refreshes once.
local function LockGroups(groups, on)
	local cvars = {}
	for _, group in ipairs(groups) do
		for _, knob in ipairs(group.items) do cvars[#cvars + 1] = knob.cvar end
	end
	EverySetting.SetLockedList(cvars, on)
end

-- What the dialog of a knob's command says after COMMAND_TEXT: what typing it
-- does, and what Every Setting does after.
local function CommandNote(knob)
	if knob.danger then return Refused(knob) and L.COMMAND_REFUSED or L.COMMAND_NOT_KEPT end
	local note = EverySetting.PutsBack(knob.cvar) and L.COMMAND_PUT_BACK
		or EverySetting.IsStored(knob.cvar) and L.COMMAND_AT_LOGIN or L.COMMAND_SETS_NOW
	-- The game's word for a CVar. A setting that isn't one is marked secure by Every Setting alone.
	if knob.secure and not knob.calls then note = note .. " " .. L.COMMAND_NOT_IN_COMBAT end
	return note
end

-- A row shows a header, a knob or the button that unfolds a section's other
-- CVars, whichever part of the list scrolls under it. Everything it does goes
-- by row.item.
local function Row(parent)
	local row = CreateFrame("Frame", nil, parent)
	row:SetHeight(ROW_H)
	row:SetPoint("RIGHT")

	-- Header parts
	row.title = Text(row, "GameFontNormal", "", ACCENT)
	row.title:SetPoint("BOTTOMLEFT", 4, 6)
	row.rule = row:CreateTexture(nil, "ARTWORK")
	row.rule:SetColorTexture(LINE[1], LINE[2], LINE[3], 1)
	row.rule:SetHeight(1)
	row.rule:SetPoint("LEFT", row.title, "RIGHT", 10, 0)
	row.rule:SetPoint("RIGHT", row, "RIGHT", -PRESETS_W - 14, 0)
	-- Folds the section or group: a plus or minus left of the title, and
	-- clicking either one toggles it.
	row.fold = CreateFrame("Button", nil, row)
	row.fold:SetPoint("LEFT", row.title, "LEFT", -FOLD_W, 0)
	row.fold:SetPoint("RIGHT", row.title, "RIGHT")
	row.fold:SetHeight(ROW_H)
	row.fold:SetScript("OnClick", function()
		local item = row.item
		SetFolded(item.section, item.group, not Folded(item.section, item.group))
		Refresh()
	end)
	local function Stroke(w, h)
		local t = row.fold:CreateTexture(nil, "ARTWORK")
		t:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
		t:SetSize(w, h)
		t:SetPoint("CENTER", row.fold, "LEFT", 8, 0)
		return t
	end
	Stroke(10, 2)
	row.fold.plus = Stroke(2, 10) -- the stroke that makes the minus a plus, while it's folded
	-- The presets for the header's section or group.
	row.presets = Dropdown(row, PRESETS_W, function(self) PresetMenu(self, row.item.group or row.item.section) end)
	row.presets:SetPoint("RIGHT", -4, 0)
	row.presets.label:SetText(L.PRESETS)
	Tooltip(row.presets, L.PRESETS, function() return L.PRESETS_TIP:format((row.item.group or row.item.section).title) end)

	-- Unfolds the section's other CVars, or folds them away again.
	row.more = Button(row, "", 190, BOX_H, function()
		local section = row.item.section
		open[section] = not open[section] or nil
		Refresh()
	end)
	row.more:SetPoint("LEFT", 8, 0)
	Tooltip(row.more, function() return row.item.section.commands and L.CONSOLE_COMMANDS or L.OTHER_CVARS end, function()
		return row.item.section.commands and L.CONSOLE_COMMANDS_TIP or L.OTHER_CVARS_TIP
	end)

	-- Knob parts
	local hl = Fill(row, "BACKGROUND", { 1, 1, 1 }, 0.035)
	hl:Hide()
	-- A bar down the left edge of a knob Every Setting is keeping at your value.
	row.kept = row:CreateTexture(nil, "ARTWORK")
	row.kept:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
	row.kept:SetPoint("TOPLEFT", 0, -4)
	row.kept:SetPoint("BOTTOMLEFT", 0, 4)
	row.kept:SetWidth(2)
	-- A grey one where the value isn't the game's default and Every Setting doesn't keep it.
	row.off = row:CreateTexture(nil, "ARTWORK")
	row.off:SetColorTexture(MUTED[1], MUTED[2], MUTED[3], 1)
	row.off:SetAllPoints(row.kept)

	-- The lock box, left of a knob's name or a section's or group's title.
	row.lock = Checkbox(row, "", function(self)
		local item = row.item
		if item.knob then EverySetting.SetLocked(item.knob.cvar, self:GetChecked()) else LockGroups(HeaderGroups(item), self:GetChecked()) end
	end)
	row.lock:SetPoint("LEFT", 8, 0)
	row.lock:SetHitRectInsets(0, 0, 0, 0)
	Tooltip(row.lock, function()
		if row.item.knob then return L.LOCK end
		local _, name = HeaderGroups(row.item)
		return L.LOCK_NAME:format(name)
	end, function() return row.item.knob and LOCK_TIP or GROUP_LOCK_TIP end)

	-- The label area carries the tooltip; it's a button so it can take the mouse.
	row.name = CreateFrame("Button", nil, row)
	row.name:SetPoint("LEFT", NAME_X, 0)
	row.name:SetSize(LABEL_W - NAME_X, ROW_H)
	row.label = Text(row.name, "GameFontHighlight", "")
	row.label:SetPoint("LEFT")
	row.label:SetPoint("RIGHT")
	row.label:SetJustifyH("LEFT")
	row.label:SetWordWrap(false)
	-- Under the name, small: what turning it up costs (COST_MARK), and when the
	-- value is past the knob's range (PAST). Or the CVar, under the game's name for it.
	row.past = Text(row.name, "GameFontHighlightSmall", "")
	row.past:SetPoint("BOTTOMLEFT", 0, 1)
	row.past:SetPoint("BOTTOMRIGHT", 0, 1)
	row.past:SetJustifyH("LEFT")
	row.past:SetWordWrap(false)

	local function Knob() return row.item.knob end

	row.slider = Slider(row, SLIDER_W, function(_, fraction)
		-- Show the value under the thumb, snapped to the knob's step.
		local min, max = EverySetting.Bounds(Knob())
		local value = EverySetting.Normalize(Knob(), min + fraction * (max - min))
		row.box:SetText(value)
		return max > min and (tonumber(value) - min) / (max - min) or 0
	end, function(_, fraction)
		local min, max = EverySetting.Bounds(Knob())
		EverySetting.Set(Knob().cvar, min + fraction * (max - min))
	end)
	row.slider:SetPoint("LEFT", CONTROL_X, 0)

	row.box = NumberBox(row, function(_, text)
		-- A raw knob's box sets exactly what's typed, which can be nothing at all.
		-- A tuned slider's is held to its range, unless the engine isn't (GoesPast).
		if text and (text ~= "" or Knob().type == "text") then EverySetting.Set(Knob().cvar, text, true) end
		Refresh() -- shows the value the knob has now: clamped, or unchanged
	end)
	-- Pressing the row's / takes the focus from its box before the button is clicked.
	-- What's typed is then kept for the command, not set: setting it would refresh the
	-- row, which loses the click (seen in game).
	local lost = row.box:GetScript("OnEditFocusLost")
	row.box:SetScript("OnEditFocusLost", function(self)
		if row.command:IsShown() and row.command:IsMouseOver() and IsMouseButtonDown("LeftButton") then
			self.cancel, row.typed = nil, self:GetText()
			return
		end
		lost(self)
	end)

	row.dropdown = Dropdown(row, SLIDER_W + 8 + BOX_W, function(self)
		if self.off then return end
		local knob = Knob()
		if knob.type == "flags" then
			-- A menu of ticks, one for each flag: clicking a flag turns it on or off.
			local function On(index) return EverySetting.Flag(EverySetting.Get(knob.cvar), index) end
			return OpenMenu(self, knob.options, On, function(index) EverySetting.SetFlag(knob.cvar, index, not On(index)) end)
		end
		local option = Option(knob, EverySetting.Get(knob.cvar))
		OpenMenu(self, knob.options, option and option[1], function(value)
			EverySetting.Set(row.item.knob.cvar, value)
		end)
	end)
	row.dropdown:SetPoint("LEFT", CONTROL_X, 0)

	row.check = Checkbox(row, "", function(self) EverySetting.Set(Knob().cvar, self:GetChecked()) end)
	row.check:SetPoint("LEFT", CONTROL_X, 0)
	row.state = Text(row, "GameFontHighlightSmall", "", MUTED)
	row.state:SetPoint("LEFT", row.check, "RIGHT", 8, 0)
	-- What a console command does, where a setting's control would be.
	row.what = Text(row, "GameFontHighlightSmall", "", MUTED)
	row.what:SetPoint("LEFT", CONTROL_X, 0)
	row.what:SetPoint("RIGHT", -(28 + RUN_W + 4), 0)
	row.what:SetJustifyH("LEFT")
	row.what:SetWordWrap(false)

	-- A color's swatch, which opens the game's color picker.
	row.swatch = CreateFrame("Button", nil, row)
	row.swatch:SetSize(BOX_W, BOX_H)
	row.swatch:SetPoint("LEFT", CONTROL_X, 0)
	Outline(row.swatch, LINE)
	row.swatch.color = row.swatch:CreateTexture(nil, "ARTWORK")
	row.swatch.color:SetPoint("TOPLEFT", 1, -1)
	row.swatch.color:SetPoint("BOTTOMRIGHT", -1, 1)
	row.swatch:SetScript("OnClick", function(self)
		if not self.off then PickColor(Knob()) end
	end)

	row.reset = Button(row, L.RESET, 48, BOX_H, function(_, button)
		EverySetting.Reset(Knob().cvar, button == "RightButton")
	end)
	row.reset:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	row.reset:SetPoint("LEFT", CONTROL_X + SLIDER_W + 8 + BOX_W + 8, 0)
	Tooltip(row.reset, function() return L.RESET_NAME:format(Knob().label) end, function()
		if EverySetting.Before(Knob().cvar) == nil then return L.RESET_UNKNOWN end
		return L.RESET_TIP:format(Describe(Knob(), EverySetting.Before(Knob().cvar)), Describe(Knob(), Knob().default))
	end)

	-- The command that sets the row's setting to the value in its box (typed, or
	-- as it is now) or else the value it has. Showing it sets nothing: a value
	-- being typed is let go, as Escape does. A console command's row gives the command.
	row.command = Button(row, "/", 20, BOX_H, function()
		local knob, typed = Knob(), row.typed
		row.typed = nil
		if knob.type == "command" then
			local text = "/console " .. knob.cvar
			return ShowDialog({ title = L.CONSOLE_COMMAND_TITLE:format(knob.cvar), text = L.CONSOLE_COMMAND_TEXT,
				body = text, fixed = text })
		end
		local value = typed or row.box:IsShown() and row.box:GetText() or EverySetting.Get(knob.cvar)
		if row.box:HasFocus() then row.box:GetScript("OnEscapePressed")(row.box) end
		if typed then Refresh() end -- the box shows the value it has again
		local text = EverySetting.Command(knob.cvar, value or "")
		-- A setting that isn't a CVar goes by its name; a CVar by the one the command has.
		local name = knob.calls and knob.label or knob.cvar
		ShowDialog({ title = L.COMMAND_FOR:format(name), text = L.COMMAND_TEXT:format(name) .. " " .. CommandNote(knob),
			body = text, fixed = text })
	end)
	row.command:SetPoint("RIGHT")
	Tooltip(row.command, L.COMMAND, function()
		return Knob().type == "command" and L.COMMAND_SHOWS_CONSOLE or L.COMMAND_SHOWS
	end)

	-- A console command's row runs it, where EverySetting.RUNNABLE has it; for
	-- another the button is there, muted.
	row.run = Button(row, L.RUN, RUN_W, BOX_H, function() EverySetting.RunCommand(Knob().cvar) end)
	row.run:SetPoint("RIGHT", -24, 0)
	Tooltip(row.run, L.RUN, function() return Knob().runs and L.RUN_TIP or L.RUN_NOT end)

	row.controls = { row.lock, row.name, row.slider, row.box, row.dropdown, row.check, row.swatch, row.reset, row.command, row.run }
	local function over() if row.item and row.item.knob then hl:Show() end end
	local function out() hl:Hide() end
	for _, control in ipairs(row.controls) do
		if control ~= row.reset and control ~= row.lock and control ~= row.command and control ~= row.run then
			Tooltip(control, function() return TipTitle(row) end, function() return TipBody(row) end)
		end
		control:HookScript("OnEnter", over)
		control:HookScript("OnLeave", out)
	end
	return row
end

-- Fills in a row for the item scrolled under it (nil: nothing, past the end).
local function Bind(row, item)
	row.item, row.typed = item, nil
	row:SetShown(item ~= nil)
	if not item then return end

	local knob = item.knob
	row.title:SetShown(item.header == true)
	row.rule:SetShown(item.header == true and not (item.group or item.others))
	row.more:SetShown(item.more == true)
	row.presets:SetShown(item.header == true and not item.others and not item.section.danger and not item.section.commands)
	row.fold:SetShown(item.header == true and not item.others and not filtering)
	for _, control in ipairs(row.controls) do control:Hide() end
	row.kept:Hide()
	row.off:Hide()
	row.state:Hide()
	row.what:Hide()
	if item.header then
		-- A section's title is large, with a rule; a group's, inside it, is smaller.
		local inside = item.group or item.others
		local color = item.section.danger and DANGER or ACCENT
		row.title:SetFontObject(inside and "GameFontNormal" or "GameFontNormalLarge")
		row.title:SetTextColor(color[1], color[2], color[3])
		row.title:SetText(item.others and (item.section.commands and L.OTHER_COMMANDS or L.OTHER_CVARS) or (item.group or item.section).title)
		-- The fold mark goes in the lock box's place, or right of the box where there's one.
		local groups = HeaderGroups(item)
		row.title:SetPoint("BOTTOMLEFT", (groups and NAME_X or 8) + FOLD_W, 6)
		row.fold.plus:SetShown(Folded(item.section, item.group))
		if groups then
			row.lock:SetChecked(AllLocked(groups))
			row.lock:Show()
		end
		return
	elseif item.more then
		local section, n = item.section, #item.section.more
		-- "12 more CVars" where the section has knobs from Knobs.lua above them.
		local more = #section.groups > 0
		local count = section.commands and (more and (n == 1 and L.N_MORE_COMMAND or L.N_MORE_COMMANDS) or (n == 1 and L.N_COMMAND or L.N_COMMANDS))
			or (more and (n == 1 and L.N_MORE_CVAR or L.N_MORE_CVARS) or (n == 1 and L.N_CVAR or L.N_CVARS))
		row.more.label:SetText((open[section] and L.HIDE_N or L.SHOW_N):format(count:format(n)))
		return
	elseif knob.type == "command" then
		-- A console command: its name, what it does, and the button that gives it.
		row.name:Show()
		row.label:SetText(knob.label)
		row.label:SetTextColor(0.92, 0.92, 0.92)
		row.label:SetPoint("LEFT", 0, 0)
		row.label:SetPoint("RIGHT", 0, 0)
		row.past:SetText("")
		row.what:SetText(knob.tip or "")
		row.what:Show()
		row.command:Show()
		-- Muted rather than disabled, so its tooltip still says why: the game sends
		-- a disabled button no OnEnter. RunCommand runs nothing for it.
		row.run.unsupported = not knob.runs
		Paint(row.run)
		row.run:SetAlpha(knob.runs and 1 or 0.45)
		row.run:Show()
		return
	end

	-- A danger setting is off outside danger mode, and one the game offers no way
	-- to change (Refused) is in it too. In danger mode a danger setting's row has no
	-- lock box. A row that's on has the button for its command at its right end,
	-- where the setting has one, and so does a refused one in danger mode: the
	-- command is there to copy, though it changes nothing.
	local danger = knob.danger and EverySetting.GetDanger()
	local refused = danger and Refused(knob)
	local off = not knob.found or (knob.locked and not danger) or refused
	local value = EverySetting.Get(knob.cvar)
	row.name:Show()
	local _, by = EverySetting.Held(knob.cvar)
	row.label:SetText(knob.label
		.. (not knob.found and " |cff777777" .. L.NOT_FOUND .. "|r"
			or off and " |cff777777" .. (knob.danger == "server" and L.HANDS_OFF or knob.danger == "readonly" and L.READ_ONLY_MARK
				or L.LOCKED_MARK) .. "|r"
			or by and (" " .. HELD .. "(" .. by .. ")|r") or ""))
	if off then row.label:SetTextColor(0.5, 0.5, 0.5) else row.label:SetTextColor(0.92, 0.92, 0.92) end
	-- What turning it up costs, and a value past the range, are said under the
	-- name, which moves up to make room. So is the CVar of a row the game names.
	local past = EverySetting.Past(knob, value)
	local under = (knob.cost and COST_MARK[knob.cost] .. (past and ", " or "") or "") .. (past and WARN .. PAST[past] .. "|r" or "")
	if knob.named then under = "|cff888888" .. knob.cvar .. "|r" end
	row.past:SetText(under)
	row.label:SetPoint("LEFT", 0, under ~= "" and 6 or 0)
	row.label:SetPoint("RIGHT", 0, under ~= "" and 6 or 0)
	row.kept:SetShown(EverySetting.IsStored(knob.cvar))
	row.off:SetShown(not EverySetting.IsStored(knob.cvar) and OffDefault(knob, value))
	row.reset:SetShown(not off and EverySetting.IsStored(knob.cvar))
	local alpha = off and 0.45 or 1
	row.lock:SetChecked(EverySetting.IsLocked(knob.cvar))
	row.lock:SetShown(not danger)
	row.command:SetShown((not off or refused and knob.found) and EverySetting.HasCommand(knob.cvar))

	-- The box: beside a slider, and beside any raw knob's control. A raw knob
	-- with no control gets a wide one. It shows a raw knob's value as it's stored.
	-- A menu of flags has none: the packed value isn't text anyone could read or type.
	local boxed = knob.type == "slider" or (knob.raw and knob.type ~= "flags")
	if boxed then
		local wide = knob.type == "text"
		row.box:ClearAllPoints()
		row.box:SetPoint("LEFT", wide and CONTROL_X or CONTROL_X + SLIDER_W + 8, 0)
		row.box:SetWidth(wide and SLIDER_W + 8 + BOX_W or BOX_W)
		row.box:SetJustifyH(wide and "LEFT" or "CENTER")
		row.box:SetMaxLetters(knob.raw and 255 or 10)
		row.box:SetAlpha(alpha)
		row.box:SetEnabled(not off)
		row.box:Show()
		if not row.slider.dragging and not row.box:HasFocus() then
			row.box:SetText(knob.raw and Spaced(value or "") or Short(value))
			row.box:SetCursorPosition(0)
		end
	end

	if knob.type == "slider" then
		local min, max = EverySetting.Bounds(knob)
		row.slider.off = off
		row.slider:SetAlpha(alpha)
		row.slider:Show()
		if not row.slider.dragging then
			local n = tonumber(value)
			row.slider:SetFraction(n and max > min and (n - min) / (max - min) or 0)
		end
	elseif knob.type == "choice" or knob.type == "flags" then
		row.dropdown.off = off
		row.dropdown:SetWidth(boxed and SLIDER_W or SLIDER_W + 8 + BOX_W)
		row.dropdown:SetAlpha(alpha)
		row.dropdown.label:SetText(value and Describe(knob, value) or "")
		row.dropdown:Show()
	elseif knob.type == "toggle" then
		row.check:SetChecked(tonumber(value) == 1)
		row.check:SetEnabled(not off)
		row.check:SetAlpha(alpha)
		row.check:Show()
		row.state:SetText(value and Describe(knob, value) or "")
		row.state:Show()
	elseif knob.type == "color" then
		row.swatch.off = off
		row.swatch:SetAlpha(alpha)
		row.swatch.color:SetColorTexture(Color(value))
		row.swatch:Show()
	end
end

-------------------------------------------------------------------------------
-- The list: filtering and scrolling
-------------------------------------------------------------------------------

-- Every knob's value, read all at once while Not default or a search by value
-- needs it, and again after the game says a CVar changed: knob -> value.
local seen, stale = {}, true
local watch = CreateFrame("Frame")
watch:RegisterEvent("CVAR_UPDATE")
watch:SetScript("OnEvent", function() stale = true end)

local function Snapshot()
	if not stale then return end
	stale = false
	wipe(seen)
	for _, section in ipairs(Sections()) do
		for _, group in ipairs(section.danger and {} or section.groups) do
			for _, knob in ipairs(group.items) do seen[knob] = EverySetting.Get(knob.cvar) end
		end
		for _, knob in ipairs(section.all) do seen[knob] = EverySetting.Get(knob.cvar) end
	end
end

-- Not default leaves out the sections of what the game remembers and of
-- switches for its developers, until one is picked in the sidebar.
local STATE = { [L.DEBUG_AND_DEVELOPMENT] = true, [L.OTHER] = true }
local asked = {} -- section -> true once it's picked
local keepable = {} -- what Keep these keeps: the CVars Not default shows that the profile doesn't keep

local function LeftOut(section)
	return STATE[section.title] and not asked[section]
end

-- A name of Every Setting's own in the game's language -> the same in English, where a
-- translation has changed it: a player in another language may type the English one
-- from a guide. Made when a search first needs it.
local english
local function English(text)
	if not english then
		english = {}
		for key, words in pairs(ns.EN) do
			if L[key] ~= words and english[L[key]] == nil then english[L[key]] = words end
		end
	end
	return english[text]
end

-- Whether every word of `words` is in the knob's name (in the game's language or in
-- English), CVar or description, or in the title of its section or group. A word
-- that starts with = is a value ("=2048"), which the knob's must be.
local function Matches(knob, titles, words)
	if #words == 0 then return true end
	knob.search = knob.search or (knob.label .. " " .. (English(knob.label) or "") .. " " .. knob.cvar .. " " .. (knob.tip or "")):lower()
	for _, word in ipairs(words) do
		local value = word:match("^=(.+)")
		if value then
			if not (seen[knob] and EverySetting.Same(seen[knob]:lower(), value)) then return false end
		elseif not (knob.search:find(word, 1, true) or titles:find(word, 1, true)) then
			return false
		end
	end
	return true
end

-- Rebuilds `view`, a row each:
--   { section, header = true }          a section's title
--   { section, group, header = true }   a group's, where the section has several
--   { section, group, knob }            a knob from Knobs.lua
--   { section, more = true }            the button that unfolds the other CVars
--   { section, others = true, header = true }   "Other CVars", in its place when the list is narrowed
--   { section, knob }                   one of the other CVars
-- The search box, Changed, Not default and the type narrow it down, and then
-- they reach the other CVars whether those are unfolded or not. Tuned leaves
-- them out, and Danger's groups with them. A folded section or group shows
-- just its header, and with Changed, Tuned or a type only while something in it
-- would show. A search sets the folds aside: whatever matches shows, folded or
-- not. Not default also counts what each section shows (section.count), for
-- the sidebar, and leaves out the sections LeftOut says.
local SideCounts, ShowKeep -- defined below
local overwritten = false -- whether Apply now has something to do (see Refresh)
local function Filter()
	local words, byValue = {}, false
	for word in refs.search:GetText():lower():gmatch("%S+") do
		if word ~= "=" then words[#words + 1], byValue = word, byValue or word:sub(1, 1) == "=" end
	end
	local changedOnly, tunedOnly, notDefault = refs.changed:GetChecked(), refs.tuned:GetChecked(), refs.notDefault:GetChecked()
	local narrowed = #words > 0 or changedOnly or notDefault or kind ~= nil
	filtering = #words > 0
	if notDefault or byValue then Snapshot() end
	local function Shows(knob, titles)
		return InClient(knob) and (not kind or knob.type == kind) and (not changedOnly or EverySetting.IsStored(knob.cvar))
			and (not notDefault or OffDefault(knob, seen[knob])) and Matches(knob, titles, words)
	end
	wipe(keepable)
	for _, section in ipairs(Sections()) do
		section.count = nil
		if notDefault then
			local title, count = section.title:lower(), 0
			local function Count(knobs, titles)
				for _, knob in ipairs(knobs) do
					if Shows(knob, titles) then
						count = count + 1
						if not (LeftOut(section) or knob.locked or EverySetting.IsStored(knob.cvar)) then
							keepable[#keepable + 1] = knob.cvar
						end
					end
				end
			end
			for _, group in ipairs(tunedOnly and section.danger and {} or section.groups) do
				Count(group.items, title .. " " .. group.title:lower())
			end
			if not tunedOnly then Count(section.more, title) end
			section.count = count
		end
	end
	-- Whether any of `knobs` would show, for a folded header that hides them.
	local function Any(knobs, titles)
		for _, knob in ipairs(knobs) do
			if Shows(knob, titles) then return true end
		end
		return false
	end
	-- Headers go in with the first row under them, so one with nothing to show is
	-- left out. Put() with no row puts just the headers, for a fold.
	local head, sub
	local function Put(item)
		if head then view[#view + 1], head = head, nil end
		if sub then view[#view + 1], sub = sub, nil end
		view[#view + 1] = item
	end
	wipe(view)
	local listed = {}
	for _, section in ipairs(Sections()) do
		if not (notDefault and LeftOut(section)) then listed[#listed + 1] = section end
	end
	for _, section in ipairs(listed) do
		local title = section.title:lower()
		local groups = tunedOnly and section.danger and {} or section.groups
		-- No `sub`: the last section's "Other CVars" is left over when none of those showed.
		head, sub = { section = section, header = true }, nil
		if not filtering and Folded(section) then
			-- Its title, while anything in it would show: a knob, the button that
			-- unfolds its other CVars, or those a filter reaches.
			local any = #section.more > 0 and not tunedOnly and (not narrowed or Any(section.more, title))
			for _, group in ipairs(groups) do
				any = any or Any(group.items, title .. " " .. group.title:lower())
			end
			if any then Put() end
		else
			for _, group in ipairs(groups) do
				local titles = title .. " " .. group.title:lower()
				sub = #groups > 1 and { section = section, group = group, header = true } or nil
				if sub and not filtering and Folded(section, group) then
					if Any(group.items, titles) then Put() end
				else
					for _, knob in ipairs(group.items) do
						if Shows(knob, titles) then Put({ section = section, group = group, knob = knob }) end
					end
				end
			end
			-- Narrowed, the other CVars get a header if they follow knobs from Knobs.lua.
			sub = narrowed and not head and { section = section, others = true, header = true } or nil
			if #section.more > 0 and not tunedOnly then
				if not narrowed then Put({ section = section, more = true }) end
				if narrowed or open[section] then
					for _, knob in ipairs(section.more) do
						if Shows(knob, title) then Put({ section = section, knob = knob }) end
					end
				end
			end
		end
	end
	-- Collapse all, or Expand all once every section is folded. It has nothing
	-- to do while a search is on.
	refs.foldAll.label:SetText(AllFolded() and L.EXPAND_ALL or L.COLLAPSE_ALL)
	refs.foldAll:SetEnabled(not filtering)
	refs.foldAll:SetAlpha(filtering and 0.45 or 1)
	SideCounts()
	ShowKeep()
end

-- The sidebar's counts: with Not default, what each section shows (Filter);
-- otherwise how many of its settings Every Setting keeps (Refresh).
function SideCounts()
	for _, b in ipairs(refs.side) do
		local n = b.section.count or b.kept
		b.count:SetText(n > 0 and n or "")
	end
end

-- With Not default, out of combat, Keep these takes the status line's place,
-- and Apply now's.
function ShowKeep()
	local on = refs.notDefault:GetChecked() and not InCombatLockdown()
	refs.keep:SetShown(on)
	-- No wider than the room right of Lock all, which a longer language's filters take.
	local right, left = win:GetRight(), refs.lockAll:GetRight()
	if right and left and right > left then refs.keep:SetWidth(math.max(60, math.min(130, right - PAD - left - 16))) end
	refs.status:SetShown(not on)
	refs.applyNow:SetShown(not on and overwritten)
	refs.keep.label:SetText(L.KEEP_THESE_N:format(#keepable))
	refs.keep:SetEnabled(#keepable > 0)
	refs.keep:SetAlpha(#keepable > 0 and 1 or 0.45)
end

local function MaxFirst()
	return math.max(1, #view - #rows + 1)
end

-- The sidebar's buttons: a section's, and under it a group's, each with the gap
-- below it. A group's is indented.
local SECTION_STEP, GROUP_STEP, GROUP_IN = 25, 20, 12
local sideFirst = 1 -- index of the sidebar's top button, of those it could show
local sideTop       -- the section at the top of the list, whose groups the sidebar shows

-- Lays the sidebar out from its `index`th button: a button per section, and
-- under sideTop's a button per group. A section with nothing listed (Danger,
-- outside danger mode) gets none. What doesn't fit below is hidden. With
-- `follow`, it scrolls as little as it takes to show sideTop and its groups.
local function LayoutSide(index, follow)
	local buttons, from, to = {}, nil, nil
	for _, b in ipairs(refs.side) do
		local listed = Listed(b.section)
		local top = listed and b.section == sideTop
		b:Hide()
		if listed then buttons[#buttons + 1] = b end
		if top then from = #buttons end
		for _, g in ipairs(b.groups) do
			g:Hide()
			if top then buttons[#buttons + 1] = g end
		end
		if top then to = #buttons end
	end
	local room = refs.sidebar:GetHeight() + 2 -- the last button needs no gap below it
	local function Fits(i, j)
		local h = 0
		for k = i, j do h = h + (buttons[k].group and GROUP_STEP or SECTION_STEP) end
		return h <= room
	end
	if follow and from then
		index = math.min(index, from)
		while index < from and not Fits(index, to) do index = index + 1 end
	end
	local last = 1 -- the furthest down it scrolls: no further than leaves room unused
	while not Fits(last, #buttons) do last = last + 1 end
	sideFirst = math.max(1, math.min(last, math.floor(index)))
	local y, full = 0, false
	for i, b in ipairs(buttons) do
		local step = b.group and GROUP_STEP or SECTION_STEP
		full = full or (i >= sideFirst and y + step > room)
		local shown = i >= sideFirst and not full
		b:SetShown(shown)
		if shown then
			b:ClearAllPoints()
			b:SetPoint("TOPLEFT", b.group and GROUP_IN or 0, -y)
			y = y + step
		end
	end
end

-- Scrolls so `index` is the top row, and draws the rows.
local function ScrollTo(index)
	index = math.min(MaxFirst(), math.max(1, math.floor(index + 0.5)))
	if index ~= first then CloseMenu() end -- its dropdown has moved
	first = index
	for i, row in ipairs(rows) do Bind(row, view[first + i - 1]) end
	refs.noMatch:SetShown(#view == 0)

	-- The thumb's size is the share of the list in view; its place, how far down.
	local track = refs.track
	local shown = #view > #rows
	track:SetShown(shown)
	if shown then
		local h = track:GetHeight()
		local thumbH = math.max(24, h * #rows / #view)
		refs.thumb:SetHeight(thumbH)
		refs.thumb:ClearAllPoints()
		refs.thumb:SetPoint("TOP", 0, -(first - 1) / (MaxFirst() - 1) * (h - thumbH))
	end

	-- The sidebar marks the section at the top of the list, and shows its groups
	-- with the one at the top marked. A section's count is amber, or dark on the
	-- amber of the marked one.
	local top, group = view[first] and view[first].section, view[first] and view[first].group
	if top ~= sideTop then
		sideTop = top
		LayoutSide(sideFirst, true)
	end
	for _, b in ipairs(refs.side) do
		SetActive(b, b.section == top)
		if b.active then b.count:SetTextColor(0.05, 0.05, 0.05) else b.count:SetTextColor(ACCENT[1], ACCENT[2], ACCENT[3]) end
		for _, g in ipairs(b.groups) do SetActive(g, g.group == group) end
	end
end

-- Shows the knobs of one type ("toggle", "slider"...), or of every type (nil).
local KINDS = { { "any", L.ANY_TYPE }, { "toggle", L.CHECKBOXES }, { "slider", L.SLIDERS }, { "choice", L.MENUS },
	{ "flags", L.FLAG_MENUS }, { "color", L.COLORS }, { "text", L.TEXT_BOXES }, { "command", L.COMMANDS } }

local function SetKind(new)
	kind = new ~= "any" and new or nil
	for _, option in ipairs(KINDS) do
		if option[1] == (kind or "any") then refs.kind.label:SetText(option[2]) end
	end
end

-- Scrolls to a section's header, or to the header of its `group`, unfolding it
-- and clearing whatever hides it. A section with no knobs from Knobs.lua has its
-- CVars unfolded, so there's something to see.
local function ShowSection(section, group)
	local function Find()
		for i, item in ipairs(view) do
			if item.header and item.section == section and item.group == group then return i end
		end
	end
	SetFolded(section, nil, false)
	if group then SetFolded(section, group, false) end
	if #section.groups == 0 then open[section] = true end
	-- Not default shows a section it leaves out once it's picked.
	if refs.notDefault:GetChecked() and LeftOut(section) then
		asked[section] = true
		Filter()
	end
	if not Find() then
		refs.changed:SetChecked(false)
		refs.tuned:SetChecked(false)
		refs.notDefault:SetChecked(false)
		wipe(asked)
		SetKind(nil)
		refs.search:SetText("")
	end
	Filter()
	ScrollTo(Find() or 1)
end

-- Saving, deleting, exporting and importing profiles all use one dialog.
local DIALOG_W = 460

local function BuildDialog()
	dialog = CreateFrame("Frame", nil, win)
	dialog:SetWidth(DIALOG_W)
	dialog:SetPoint("TOP", 0, -120)
	dialog:SetFrameStrata("FULLSCREEN_DIALOG")
	dialog:EnableMouse(true) -- clicks don't go through to the window
	Fill(dialog, "BACKGROUND", BG)
	Outline(dialog, ACCENT)

	dialog.title = Text(dialog, "GameFontNormal", "", ACCENT)
	dialog.title:SetPoint("TOPLEFT", PAD, -14)
	dialog.text = Text(dialog, "GameFontHighlightSmall", "")
	dialog.text:SetPoint("TOPLEFT", dialog.title, "BOTTOMLEFT", 0, -8)
	dialog.text:SetWidth(DIALOG_W - 2 * PAD)
	dialog.text:SetJustifyH("LEFT")
	dialog.error = Text(dialog, "GameFontHighlightSmall", "")
	dialog.error:SetTextColor(1, 0.45, 0.45)
	dialog.error:SetPoint("LEFT", dialog, "BOTTOMLEFT", PAD, 23)
	dialog.error:SetWidth(DIALOG_W - 2 * PAD - 180)
	dialog.error:SetJustifyH("LEFT")
	local function Clear() dialog.error:SetText("") end

	-- onOK may show the dialog again, with something else in it. An import's
	-- report takes its place: a summary, and the rest in the big box.
	local function OK()
		local onOK = dialog.onOK
		local why, report = onOK(dialog.name:GetText(), dialog.body:GetText())
		if why then
			dialog.error:SetText(why)
		elseif report then
			local rest = #report > 1 and table.concat(report, "\n", 2) or nil
			ShowDialog({ title = L.IMPORTED, text = report[1], body = rest, fixed = rest })
		elseif dialog.onOK == onOK then
			dialog:Hide()
		end
	end
	dialog.cancel = Button(dialog, L.CANCEL, 80, 22, function() dialog:Hide() end)
	dialog.cancel:SetPoint("BOTTOMRIGHT", -PAD, 12)
	dialog.ok = Button(dialog, "", 80, 22, OK)
	dialog.ok:SetPoint("RIGHT", dialog.cancel, "LEFT", -6, 0)

	dialog.name = SearchBox(dialog, 220, BOX_H, L.NAME, Clear)
	dialog.name:SetMaxLetters(32)
	dialog.name:SetScript("OnEnterPressed", OK)
	dialog.name:SetScript("OnEscapePressed", function() dialog:Hide() end)

	-- The big box, for a profile string. It scrolls, since the string can be long.
	local scroll = CreateFrame("ScrollFrame", nil, dialog)
	scroll:SetSize(DIALOG_W - 2 * PAD, 120)
	Fill(scroll, "BACKGROUND", BTN)
	Outline(scroll, LINE)
	local body = CreateFrame("EditBox", nil, scroll)
	body:SetMultiLine(true)
	body:SetAutoFocus(false)
	body:SetFontObject("GameFontHighlightSmall")
	body:SetMaxLetters(0)
	body:SetTextInsets(6, 6, 6, 6)
	body:SetSize(DIALOG_W - 2 * PAD, 120)
	scroll:SetScrollChild(body)
	scroll:EnableMouse(true)
	scroll:SetScript("OnMouseDown", function() body:SetFocus() end)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), self:GetVerticalScroll() - delta * 20)))
	end)
	body:SetScript("OnEscapePressed", function() dialog:Hide() end)
	-- An export can't be changed: typing puts it back, selected for copying.
	body:SetScript("OnTextChanged", function(self, userInput)
		if not userInput then return end
		if dialog.fixed then
			self:SetText(dialog.fixed)
			self:HighlightText()
		end
		Clear()
	end)
	body:SetScript("OnEditFocusGained", function(self)
		if dialog.fixed then self:HighlightText() end
	end)
	dialog.scroll, dialog.body = scroll, body
	refs.dialog = dialog
end

-- Shows the dialog. `opts`:
--   title, text   what it's for
--   name          true for a box to type a name in
--   body          text for the big box (nil: no box); `fixed` (the same text) can't be changed
--   ok            the OK button's label (nil: just a Close button). Beside a
--                 `fixed` body there's nothing to cancel: the other one is Close
--   onOK(name, body)  returns why not, to keep the dialog open; or nil and an
--                 import's report, to show in its place
function ShowDialog(opts)
	if not dialog then BuildDialog() end
	CloseMenu()
	dialog.onOK, dialog.fixed = opts.onOK, opts.fixed
	dialog.title:SetText(opts.title)
	dialog.text:SetText(opts.text)
	dialog.error:SetText("")
	local below, h = dialog.text, 0
	dialog.name:SetText("")
	dialog.name:SetShown(opts.name and true or false)
	if opts.name then
		dialog.name:ClearAllPoints()
		dialog.name:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -10)
		below, h = dialog.name, h + BOX_H + 10
	end
	dialog.body:SetText(opts.body or "")
	dialog.scroll:SetShown(opts.body ~= nil)
	if opts.body then
		dialog.scroll:ClearAllPoints()
		dialog.scroll:SetPoint("TOPLEFT", below, "BOTTOMLEFT", 0, -10)
		dialog.scroll:SetVerticalScroll(0)
		h = h + 130
	end
	dialog.ok:SetShown(opts.ok ~= nil)
	dialog.ok.label:SetText(opts.ok or "")
	dialog.cancel.label:SetText(opts.ok and not opts.fixed and L.CANCEL or L.CLOSE)
	dialog:SetHeight(36 + dialog.text:GetStringHeight() + h + 56)
	dialog:Show()
	if opts.body then
		dialog.body:SetFocus()
	elseif opts.name then
		dialog.name:SetFocus()
	end
end

local function SaveAsDialog()
	ShowDialog({ title = L.SAVE_AS_TITLE, text = L.SAVE_AS_TEXT:format(EverySetting.GetProfile()),
		name = true, ok = L.SAVE, onOK = EverySetting.NewProfile })
end

local function DeleteDialog()
	local name = EverySetting.GetProfile()
	if name == EverySetting.DEFAULT_PROFILE then return end
	local default = EverySetting.DEFAULT_PROFILE
	ShowDialog({ title = L.DELETE_PROFILE_TITLE:format(name), text = L.DELETE_PROFILE_TEXT:format(default, name, name, default),
		ok = L.DELETE, onOK = EverySetting.DeleteProfile })
end


-- An export: a line of text for Import (`intro` says what it's for), or with
-- `lines` the same as /console lines. Its button switches between the two.
-- `part` is what to export, or nil for the profile in use.
local function ShowExport(title, intro, part, lines)
	local text = lines and EverySetting.ExportLines(part) or EverySetting.ExportProfile(part)
	ShowDialog({ title = title,
		text = lines and L.EXPORT_LINES_TEXT or intro .. " " .. L.AS_LINES,
		body = text, fixed = text,
		ok = lines and L.AS_A_STRING or L.AS_CONSOLE,
		onOK = function() ShowExport(title, intro, part, not lines) end })
end

local function ExportDialog()
	ShowExport(L.EXPORT_NAME:format(EverySetting.GetProfile()), L.EXPORT_PROFILE_INTRO)
end

local function ImportDialog()
	ShowDialog({ title = L.IMPORT, text = L.IMPORT_TEXT, name = true, body = "", ok = L.IMPORT, onOK = EverySetting.ImportProfile })
end

-- Keep these: what Not default shows, kept at its values in the profile in
-- use, or in a new copy of it. Nothing is set, and Undo takes it back.
local function KeepMenu(owner)
	if #keepable == 0 then return end
	local profile = EverySetting.GetProfile()
	OpenMenu(owner, { { "here", L.KEEP_IN:format(profile) }, { "new", L.KEEP_IN_NEW } }, nil, function(choice)
		if choice == "here" then return EverySetting.KeepAsIs(keepable) end
		local list = {}
		for i, cvar in ipairs(keepable) do list[i] = cvar end
		ShowDialog({ title = L.KEEP_NEW_TITLE, text = (#list == 1 and L.KEEP_NEW_TEXT_ONE or L.KEEP_NEW_TEXT):format(profile, #list),
			name = true, ok = L.KEEP, onOK = function(name)
				local why = EverySetting.NewProfile(name)
				if why then return why end
				EverySetting.KeepAsIs(list)
			end })
	end, 220)
end

-------------------------------------------------------------------------------
-- Presets
-------------------------------------------------------------------------------

-- A header's presets are for its scope: the section, or the group from
-- Knobs.lua. This is the knobs a scope holds: knob -> true.
local function Holds(scope)
	if not scope.holds then
		scope.holds = {}
		for _, group in ipairs(scope.groups or { scope }) do
			for _, knob in ipairs(group.items) do scope.holds[knob] = true end
		end
		for _, knob in ipairs(scope.more or {}) do scope.holds[knob] = true end
	end
	return scope.holds
end

local function Has(scope, cvar)
	local knob = EverySetting.RawKnob(cvar, "")
	return knob ~= nil and Holds(scope)[knob] == true
end

-- What the profile in use keeps in the scope: { cvar = value }, and how many.
local function Kept(scope)
	local kept, count = {}, 0
	for cvar, value in pairs(EverySetting.GetKept()) do
		if Has(scope, cvar) then kept[cvar], count = value, count + 1 end
	end
	return kept, count
end

-- The values the built-in preset `i` (of EverySetting.TIERS) gives the scope's
-- knobs, held to this client's range.
local function Tier(scope, i)
	local tier = {}
	for knob in pairs(Holds(scope)) do
		if knob.tiers and knob.found and not knob.locked then tier[knob.cvar] = EverySetting.Fit(knob, knob.tiers[i]) end
	end
	return tier
end

-- Whether `a` and `b` ({ cvar = value }, for the same CVars) have the same values.
local function Alike(a, b)
	for cvar, value in pairs(a) do
		if b[cvar] ~= value then return false end
	end
	return true
end

-- The presets for a scope, as two lists of { key, label, preset }: the
-- built-in ones its knobs have, where those that give it the same values are
-- one ("Low / Medium"), and the saved ones whose CVars are all in it, by name.
local function ScopePresets(scope)
	local tiers, saved, last = {}, {}, nil
	for i, name in ipairs(EverySetting.TIERS) do
		local tier = Tier(scope, i)
		if last and Alike(last, tier) then
			tiers[#tiers][2] = tiers[#tiers][2] .. " / " .. name
		elseif next(tier) then
			tiers[#tiers + 1] = { "tier:" .. i, name, tier }
			last = tier
		end
	end
	local presets, names = EverySetting.GetPresets(), {}
	for name, preset in pairs(presets) do
		local fits = true
		for cvar in pairs(preset) do fits = fits and Has(scope, cvar) end
		if fits then names[#names + 1] = name end
	end
	table.sort(names)
	for i, name in ipairs(names) do saved[i] = { "preset:" .. name, name, presets[name] } end
	return tiers, saved
end

-- Whether every CVar in the preset has the preset's value now.
local function IsSet(preset)
	for cvar, value in pairs(preset) do
		if Short(EverySetting.Get(cvar)) ~= Short(value) then return false end
	end
	return true
end

-- Whether the profile keeps the preset: each of its values is set now, and
-- kept, or locked (Apply leaves a locked one as it is). Values that only
-- happen to match, like a fresh profile's defaults, don't count. The Presets
-- menus and the Styles panel mark only what the profile keeps.
local function ProfileKeeps(preset)
	if not IsSet(preset) then return false end
	for cvar in pairs(preset) do
		if not (EverySetting.IsStored(cvar) or EverySetting.IsLocked(cvar)) then return false end
	end
	return true
end

local function SavePresetDialog(scope)
	local kept, count = Kept(scope)
	ShowDialog({ title = L.SAVE_PRESET_TITLE:format(scope.title),
		text = (count == 1 and L.SAVE_PRESET_TEXT_ONE or L.SAVE_PRESET_TEXT):format(count, scope.title),
		name = true, ok = L.SAVE, onOK = function(name) return EverySetting.SavePreset(name, kept) end })
end

local function ExportPresetDialog(scope)
	ShowExport(L.EXPORT_NAME:format(scope.title), L.EXPORT_PRESET_INTRO:format(scope.title), (Kept(scope)))
end

local function ImportPresetDialog(scope)
	ShowDialog({ title = L.IMPORT_PRESET_TITLE:format(scope.title), text = L.IMPORT_PRESET_TEXT:format(scope.title),
		name = true, body = "", ok = L.IMPORT,
		onOK = function(name, text) return EverySetting.ImportPreset(name, text, function(cvar) return Has(scope, cvar) end) end })
end

local function DeletePresetDialog(name)
	ShowDialog({ title = L.DELETE_PRESET_TITLE:format(name), text = L.DELETE_PRESET_TEXT,
		ok = L.DELETE, onOK = function() EverySetting.DeletePreset(name) end })
end

-- Opens the presets menu for a scope under `owner`: the built-in ones its
-- knobs have, the styles that set any of them, the saved ones whose CVars are
-- all in the scope, and what can be done with what the profile keeps there.
-- The first one the profile keeps is marked.
function PresetMenu(owner, scope)
	local options, presets, labels, current = {}, {}, {}, nil
	local function Add(key, label, preset, tip)
		options[#options + 1] = { key, label, tip }
		presets[key], labels[key] = preset, label
		if not current and ProfileKeeps(preset) then current = key end
	end
	local tiers, saved = ScopePresets(scope)
	for _, item in ipairs(tiers) do Add(item[1], item[2], item[3]) end
	-- Each style's values for the scope's groups, under a heading. The key keeps
	-- the style Ultra apart from the built-in one.
	local styled
	for _, style in ipairs(EverySetting.STYLES) do
		local preset = {}
		for _, group in ipairs(scope.groups or { scope }) do
			for cvar, value in pairs(EverySetting.StylePreset(style, group)) do preset[cvar] = value end
		end
		if next(preset) then
			if not styled then
				options[#options + 1] = { nil, L.STYLES, heading = true }
				styled = true
			end
			Add("style:" .. style.name, style.name, preset, style.tip)
		end
	end
	-- Your own, and what to do with them, under a heading when there's anything above.
	if #options > 0 then options[#options + 1] = { nil, L.YOUR_PRESETS, heading = true } end
	for _, item in ipairs(saved) do Add(item[1], item[2], item[3]) end
	if next((Kept(scope))) then
		options[#options + 1] = { "save", L.SAVE_AS_PRESET_MENU }
		options[#options + 1] = { "export", L.EXPORT_MENU }
	end
	options[#options + 1] = { "import", L.IMPORT_MENU }
	if #saved > 0 then options[#options + 1] = { "delete", L.DELETE_PRESET_MENU } end
	OpenMenu(owner, options, current, function(choice)
		if presets[choice] then
			EverySetting.ApplyPreset(presets[choice], L.PRESET_FOR:format(labels[choice], scope.title))
		elseif choice == "save" then
			SavePresetDialog(scope)
		elseif choice == "export" then
			ExportPresetDialog(scope)
		elseif choice == "import" then
			ImportPresetDialog(scope)
		else
			-- Which one to delete: a second menu, of the saved ones.
			local list = {}
			for i, item in ipairs(saved) do list[i] = { item[2], item[2] } end
			OpenMenu(owner, list, nil, DeletePresetDialog)
		end
	end)
end

local TAKE = {} -- the menu item that gives a situation what you've changed since login

-- The Situations menu: each situation and the preset it uses. Picking one
-- opens a second menu on the same button: what you've changed since login,
-- None, the situation's own preset, and the saved presets.
local function SituationMenu(owner)
	local options, labels, sets = {}, {}, {}
	for _, s in ipairs(EverySetting.SITUATIONS) do
		local name, on = EverySetting.GetSituation(s.key)
		options[#options + 1] = { s.key, (on and L.SITUATION_ON or L.SITUATION):format(s.label, name or L.NO_PRESET) }
		labels[s.key], sets[s.key] = s.label, s.sets
	end
	OpenMenu(owner, options, nil, function(key)
		local list = {}
		local changed = 0
		for _ in pairs(EverySetting.Changes()) do changed = changed + 1 end
		if changed > 0 then
			list[1] = { TAKE, L.USE_CHANGES:format(changed) }
		end
		list[#list + 1] = { "", L.NONE }
		if sets[key] then list[#list + 1] = { true, L.SITUATION_OWN_ITEM:format(sets[key]) } end
		local names = {}
		for name in pairs(EverySetting.GetPresets()) do names[#names + 1] = name end
		table.sort(names)
		for _, name in ipairs(names) do list[#list + 1] = { name, name } end
		local using, _, own = EverySetting.GetSituation(key)
		OpenMenu(owner, list, own or using or "", function(choice)
			if choice ~= TAKE then return EverySetting.SetSituation(key, choice ~= "" and choice or nil) end
			local count, name = EverySetting.TakeChanges(key)
			if not count then return EverySetting.Print(name) end
			EverySetting.Print(count == 1 and L.SITUATION_TAKEN_ONE or L.SITUATION_TAKEN, labels[key], count, name)
		end, 280)
	end, 280)
end

-- The sidebar: a button per section, which scrolls the list to it, and one per
-- group of a section with several, shown under the section at the top of the
-- list (LayoutSide). The mouse wheel scrolls it when they don't all fit.
local function BuildSide(y)
	local side = CreateFrame("Frame", nil, win)
	side:SetPoint("TOPLEFT", PAD, y)
	side:SetSize(SIDE_W, HEIGHT + y - 52) -- as tall as the list
	side:EnableMouseWheel(true)
	side:SetScript("OnMouseWheel", function(_, delta) LayoutSide(sideFirst - delta) end)
	refs.sidebar = side
	refs.side = {}
	for i, section in ipairs(Sections()) do
		local b = Button(side, section.title, SIDE_W, 23, function(self) ShowSection(self.section) end)
		b.groups = {}
		for j, group in ipairs(#section.groups > 1 and section.groups or {}) do
			local g = Button(side, group.title, SIDE_W - GROUP_IN, GROUP_STEP - 2,
				function(self) ShowSection(self.section, self.group) end)
			g.label:ClearAllPoints()
			g.label:SetPoint("LEFT", 10, 0)
			g.label:SetPoint("RIGHT", -6, 0)
			g.label:SetJustifyH("LEFT")
			Tooltip(g, function(self) return Cut(self.label) and self.label:GetText() end)
			g.section, g.group = section, group
			b.groups[j] = g
		end
		b.label:ClearAllPoints()
		b.label:SetPoint("LEFT", 10, 0)
		b.count = Text(b, "GameFontHighlightSmall", "")
		b.count:SetPoint("RIGHT", -8, 0)
		b.label:SetPoint("RIGHT", b.count, "LEFT", -4, 0)
		b.label:SetJustifyH("LEFT")
		b.section, b.kept, section.button = section, 0, b
		Tooltip(b, section.title, function(self)
			local count = self.section.count
			if count and LeftOut(self.section) then
				return L.SIDE_LEFT_OUT:format(count)
			elseif count then
				return L.SIDE_LISTS:format(count)
			end
			return self.kept > 0 and (self.kept == 1 and L.SIDE_KEPT_ONE or L.SIDE_KEPT):format(self.kept) or nil
		end)
		refs.side[i] = b
	end
	LayoutSide(1)
end

-------------------------------------------------------------------------------
-- Styles
-------------------------------------------------------------------------------

-- The Styles panel: a row for each part of the profile (a group from Knobs.lua)
-- that a style sets, each on a style, on one of the group's presets, or on
-- Keep mine. Apply sets them all as one preset. A row's lock box is its
-- group's, as in the list: a locked part is left as it is, and so is a locked
-- setting in a part.
local KEEP = L.KEEP_MINE
local STYLES_W, STYLE_PICK_W, STYLE_ROW_H = 364, 150, 24
local panel
-- The rows: { group, menu, options, choice }. `options` is key -> { label,
-- preset }, where the key is a style's name, "tier:<i>" or "preset:<name>";
-- `menu` lists them for the row's menu, and `choice` is a key, or nil for
-- Keep mine.
local parts = {}

-- The style the unlocked rows all agree with: each on it, or on Keep mine
-- where it sets nothing.
local function Agreed()
	for _, style in ipairs(EverySetting.STYLES) do
		local agree = true
		for _, part in ipairs(parts) do
			agree = agree and (GroupLocked(part.group) or part.choice == (part.options[style.name] and style.name or nil))
		end
		if agree then return style end
	end
end

local function ShowChoices()
	local any, all = false, true
	for i, part in ipairs(parts) do
		local row, locked = panel.rows[i], GroupLocked(part.group)
		row.lock:SetChecked(locked)
		row.pick:SetEnabled(not locked)
		row.pick:SetAlpha(locked and 0.45 or 1)
		row.pick.label:SetText(locked and L.LOCKED or part.choice and part.options[part.choice][1] or KEEP)
		any = any or (not locked and part.choice ~= nil)
		all = all and locked
	end
	panel.lock:SetChecked(all)
	local top = any and Agreed()
	panel.top.label:SetText(top and top.name or any and L.MIXED or KEEP)
	panel.apply:SetEnabled(any)
	panel.apply:SetAlpha(any and 1 or 0.45)
end

-- The status line calls what's applied by the style the rows agree on, or Styles.
local function Apply()
	local preset = {}
	for _, part in ipairs(parts) do
		for cvar, value in pairs(part.choice and part.options[part.choice][2] or {}) do preset[cvar] = value end
	end
	local style = Agreed()
	panel:Hide()
	EverySetting.ApplyPreset(preset, style and style.name or L.STYLES, style ~= nil)
end

-- A row's menu: the styles that set something in its part, the group's
-- built-in and saved presets, and Keep mine.
local function PartMenu(owner)
	local part = owner.part
	OpenMenu(owner, part.menu, part.choice or KEEP, function(key)
		part.choice = part.options[key] and key or nil
		ShowChoices()
	end)
end

-- The top menu: each style, which puts every unlocked row on it.
local function StyleMenu(owner)
	local options, top = {}, Agreed()
	for _, style in ipairs(EverySetting.STYLES) do
		local count = 0
		for _ in pairs(EverySetting.StylePreset(style)) do count = count + 1 end
		-- Hovering a style says what it's for, how much it sets and, once it's been
		-- applied whole, the frame rate it gave on this machine.
		local tip = style.tip .. "\n\n" .. L.STYLE_SETS:format(count)
		local before, after = EverySetting.StyleFramerate(style.name)
		if before then tip = tip .. "\n\n" .. L.STYLE_LAST_FPS:format(before, after) end
		options[#options + 1] = { style.name, style.name, tip }
	end
	OpenMenu(owner, options, top and top.name, function(name)
		for _, part in ipairs(parts) do
			if not GroupLocked(part.group) then part.choice = part.options[name] and name or nil end
		end
		ShowChoices()
	end)
end

local function BuildStylesPanel()
	panel = CreateFrame("Frame", nil, win)
	panel:SetWidth(STYLES_W)
	panel:SetFrameStrata("FULLSCREEN")
	panel:EnableMouse(true) -- clicks don't go through to the window
	Fill(panel, "BACKGROUND", CARD)
	Outline(panel, ACCENT)
	panel:SetScript("OnHide", CloseMenu) -- a row's menu goes with it
	panel.top = Dropdown(panel, STYLE_PICK_W, StyleMenu)
	panel.top:SetPoint("TOPRIGHT", -PAD, -12)
	Tooltip(panel.top, L.STYLE, L.STYLE_TOP_TIP)
	-- Locks every part, or unlocks them all. The refresh that follows shows it in the rows.
	panel.lock = Checkbox(panel, "", function(self)
		local groups = {}
		for i, part in ipairs(parts) do groups[i] = part.group end
		LockGroups(groups, self:GetChecked())
	end)
	panel.lock:SetPoint("LEFT", panel, "TOPLEFT", PAD, -12 - BOX_H / 2)
	panel.lock:SetHitRectInsets(0, 0, 0, 0)
	Tooltip(panel.lock, L.LOCK_EVERY_PART, L.LOCK_EVERY_PART_TIP)
	local label = Text(panel, "GameFontHighlight", L.STYLE)
	label:SetPoint("LEFT", panel.lock, "RIGHT", 8, 0)
	local rule = panel:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(LINE[1], LINE[2], LINE[3], 1)
	rule:SetHeight(1)
	rule:SetPoint("TOPLEFT", PAD, -42)
	rule:SetPoint("TOPRIGHT", -PAD, -42)
	panel.rows = {}
	panel.cancel = Button(panel, L.CANCEL, 80, 22, function() panel:Hide() end)
	panel.cancel:SetPoint("BOTTOMRIGHT", -PAD, 12)
	panel.apply = Button(panel, L.APPLY, 80, 22, Apply)
	panel.apply:SetPoint("RIGHT", panel.cancel, "LEFT", -6, 0)
	Tooltip(panel.apply, L.APPLY, L.APPLY_STYLES_TIP)
	refs.stylesPanel = panel
	panel:Hide() -- new frames start shown
end

-- Opens the Styles panel under `owner`, or closes it. Each row starts on what
-- the profile keeps for its part: the style it keeps everywhere, if there's
-- one, or else the first style, built-in preset or saved preset it keeps for
-- the part. Failing that, Keep mine.
local function StylesPanel(owner)
	if not panel then BuildStylesPanel() end
	if panel:IsShown() then return panel:Hide() end
	CloseMenu()
	wipe(parts)
	local whole
	for _, style in ipairs(EverySetting.STYLES) do
		if not whole and ProfileKeeps(EverySetting.StylePreset(style)) then whole = style end
	end
	for _, group in ipairs(EverySetting.GROUPS) do
		local part = { group = group, menu = {}, options = {} }
		local function Add(key, label, preset)
			part.menu[#part.menu + 1] = { key, label }
			part.options[key] = { label, preset }
		end
		for _, style in ipairs(EverySetting.STYLES) do
			local preset = EverySetting.StylePreset(style, group)
			if next(preset) then Add(style.name, style.name, preset) end
		end
		-- Only a part a style sets gets a row.
		if #part.menu > 0 then
			local tiers, saved = ScopePresets(group)
			if #tiers + #saved > 0 then part.menu[#part.menu + 1] = { nil, L.PRESETS, heading = true } end
			for _, item in ipairs(tiers) do Add(item[1], item[2], item[3]) end
			for _, item in ipairs(saved) do Add(item[1], item[2], item[3]) end
			part.menu[#part.menu + 1] = { KEEP, KEEP, L.KEEP_MINE_TIP }
			if whole and part.options[whole.name] then part.choice = whole.name end
			for _, option in ipairs(part.menu) do
				local key = option[1]
				if not part.choice and part.options[key] and ProfileKeeps(part.options[key][2]) then part.choice = key end
			end
			parts[#parts + 1] = part
		end
	end
	for i, part in ipairs(parts) do
		local row = panel.rows[i]
		if not row then
			local y = -52 - (i - 1) * STYLE_ROW_H
			row = { pick = Dropdown(panel, STYLE_PICK_W, PartMenu), title = Text(panel, "GameFontHighlightSmall", "") }
			row.pick:SetPoint("TOPRIGHT", -PAD, y)
			-- The part's lock box: the same as its group's in the list.
			row.lock = Checkbox(panel, "", function(self) LockGroups({ self.part.group }, self:GetChecked()) end)
			row.lock:SetPoint("LEFT", panel, "TOPLEFT", PAD, y - BOX_H / 2)
			row.lock:SetHitRectInsets(0, 0, 0, 0)
			Tooltip(row.lock, function(self) return L.LOCK_NAME:format(self.part.group.title) end, GROUP_LOCK_TIP)
			row.title:SetPoint("LEFT", row.lock, "RIGHT", 8, 0)
			row.title:SetPoint("RIGHT", row.pick, "LEFT", -8, 0)
			row.title:SetJustifyH("LEFT")
			row.title:SetWordWrap(false)
			panel.rows[i] = row
		end
		row.pick.part, row.lock.part = part, part
		row.title:SetText(part.group.title)
		row.pick:Show()
		row.lock:Show()
		row.title:Show()
	end
	for i = #parts + 1, #panel.rows do
		panel.rows[i].pick:Hide()
		panel.rows[i].lock:Hide()
		panel.rows[i].title:Hide()
	end
	panel:SetHeight(52 + #parts * STYLE_ROW_H + 12 + 22 + 12)
	panel:ClearAllPoints()
	panel:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2)
	ShowChoices()
	panel:Show()
end

-------------------------------------------------------------------------------
-- Window
-------------------------------------------------------------------------------

local function Build()
	win = CreateFrame("Frame", "EverySettingOptions", UIParent)
	win:SetSize(WIDTH, HEIGHT)
	win:SetScale(EverySetting.GetScale())
	win:SetPoint("CENTER")
	win:SetFrameStrata("DIALOG")
	win:SetToplevel(true)
	win:SetMovable(true)
	win:SetClampedToScreen(true)
	win:EnableMouse(true)
	win:EnableMouseWheel(true) -- so the wheel doesn't zoom the camera through it
	win:SetScript("OnMouseWheel", function() end)
	win:RegisterForDrag("LeftButton")
	win:SetScript("OnDragStart", win.StartMoving)
	win:SetScript("OnDragStop", win.StopMovingOrSizing)
	win:SetScript("OnShow", function()
		EverySetting.WatchFramerate(true)
		Refresh()
	end)
	win:SetScript("OnHide", function()
		EverySetting.WatchFramerate(false)
		CloseMenu()
		if dialog then dialog:Hide() end
		if panel then panel:Hide() end
	end)
	Fill(win, "BACKGROUND", BG)
	Outline(win, LINE)
	tinsert(UISpecialFrames, "EverySettingOptions") -- Escape closes it

	-- Header
	local head = CreateFrame("Frame", nil, win)
	head:SetPoint("TOPLEFT", 1, -1)
	head:SetPoint("TOPRIGHT", -1, -1)
	head:SetHeight(44)
	Fill(head, "BACKGROUND", CARD)
	local rule = head:CreateTexture(nil, "ARTWORK")
	rule:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 1)
	rule:SetHeight(2)
	rule:SetPoint("BOTTOMLEFT") rule:SetPoint("BOTTOMRIGHT")
	local icon = head:CreateTexture(nil, "ARTWORK")
	icon:SetTexture("Interface\\AddOns\\EverySetting\\Media\\logo")
	icon:SetSize(24, 24)
	icon:SetPoint("LEFT", PAD - 2, 0)
	local title = Text(head, "GameFontNormalLarge", L.WINDOW_TITLE:format(AMBER), { 1, 1, 1 })
	title:SetPoint("LEFT", icon, "RIGHT", 10, 1)
	local close = Button(head, "X", 24, 24, function() win:Hide() end)
	close:SetPoint("RIGHT", -10, 0)

	-- Profile: the settings this character uses, and saving, deleting and sharing them
	local prev = close
	for _, info in ipairs({
		{ "profileImport", L.IMPORT, ImportDialog, L.IMPORT, L.IMPORT_BUTTON_TIP },
		{ "profileExport", L.EXPORT, ExportDialog, L.EXPORT, L.EXPORT_BUTTON_TIP },
		{ "profileDelete", L.DELETE, DeleteDialog, L.DELETE_THIS_PROFILE,
		  L.DELETE_BUTTON_TIP:format(EverySetting.DEFAULT_PROFILE, EverySetting.DEFAULT_PROFILE) },
		{ "profileSave", L.SAVE_AS, SaveAsDialog, L.SAVE_AS_TITLE, L.SAVE_AS_BUTTON_TIP },
	}) do
		local b = Button(head, info[2], 60, BOX_H, info[3])
		b:SetPoint("RIGHT", prev, "LEFT", prev == close and -16 or -3, 0)
		Tooltip(b, info[4], info[5])
		refs[info[1]] = b
		prev = b
	end
	refs.profile = Dropdown(head, 170, function(self)
		local options = {}
		for i, name in ipairs(EverySetting.GetProfiles()) do options[i] = { name, name } end
		OpenMenu(self, options, EverySetting.GetProfile(), EverySetting.SetProfile)
	end)
	refs.profile:SetPoint("RIGHT", prev, "LEFT", -8, 0)
	Tooltip(refs.profile, L.PROFILE, L.PROFILE_TIP)
	local profileLabel = Text(head, "GameFontHighlight", L.PROFILE_LABEL)
	profileLabel:SetPoint("RIGHT", refs.profile, "LEFT", -8, 0)

	-- Styles: built-in presets that span sections, picked part by part.
	refs.styles = Dropdown(head, 110, StylesPanel)
	refs.styles:SetPoint("RIGHT", profileLabel, "LEFT", -16, 0)
	refs.styles.label:SetText(L.STYLES)
	Tooltip(refs.styles, L.STYLES, L.STYLES_TIP)

	-- Search and filters
	local y = -58
	-- An open menu belongs to a row, and the rows are about to show other settings.
	local function Narrow() CloseMenu() Filter() ScrollTo(1) end
	refs.search = SearchBox(win, SIDE_W, 22, L.SEARCH_HINT, function()
		if refs.noMatch then Narrow() end
	end)
	refs.search:SetPoint("TOPLEFT", PAD, y)
	Tooltip(refs.search, L.SEARCH, L.SEARCH_TIP)
	refs.changed = Checkbox(win, L.CHANGED, Narrow)
	refs.changed:SetPoint("LEFT", refs.search, "RIGHT", 16, 0)
	Tooltip(refs.changed, L.CHANGED_ONLY, L.CHANGED_TIP)
	refs.tuned = Checkbox(win, L.TUNED, Narrow)
	refs.tuned:SetPoint("LEFT", refs.changed.text, "RIGHT", 16, 0)
	Tooltip(refs.tuned, L.TUNED_ONLY, L.TUNED_TIP)
	refs.notDefault = Checkbox(win, L.NOT_DEFAULT, function(self)
		if not self:GetChecked() then wipe(asked) end
		Narrow()
	end)
	refs.notDefault:SetPoint("LEFT", refs.tuned.text, "RIGHT", 16, 0)
	Tooltip(refs.notDefault, L.NOT_DEFAULT_ONLY, L.NOT_DEFAULT_TIP)
	refs.kind = Dropdown(win, 104, function(self)
		OpenMenu(self, KINDS, kind or "any", function(value) SetKind(value) Narrow() end)
	end)
	refs.kind:SetPoint("LEFT", refs.notDefault.text, "RIGHT", 16, 0)
	Tooltip(refs.kind, L.TYPE, L.TYPE_TIP)
	SetKind(nil)
	-- Collapse all folds every section; Expand all unfolds every section and group.
	refs.foldAll = Button(win, L.COLLAPSE_ALL, 80, BOX_H, function()
		local folded = EverySetting.GetFolded()
		if AllFolded() then
			wipe(folded)
		else
			for _, section in ipairs(Sections()) do
				if Listed(section) then folded[FoldKey(section)] = true end
			end
		end
		Refresh()
	end)
	refs.foldAll:SetPoint("LEFT", refs.kind, "RIGHT", 16, 0)
	Tooltip(refs.foldAll, function(self) return self.label:GetText() end, L.FOLD_ALL_TIP)
	-- Lock all locks every tuned setting; Unlock all, once they all are, unlocks them.
	refs.lockAll = Button(win, L.LOCK_ALL, 60, BOX_H, function()
		LockGroups(EverySetting.GROUPS, not AllLocked(EverySetting.GROUPS))
	end)
	refs.lockAll:SetPoint("LEFT", refs.foldAll, "RIGHT", 6, 0)
	Tooltip(refs.lockAll, function(self) return self.label:GetText() end, L.LOCK_ALL_TIP)
	-- What's left of the row is about 170 wide, and the status lines run 220 to
	-- 250, so they wrap onto a second line.
	refs.status = Text(win, "GameFontHighlightSmall", "", MUTED)
	refs.status:SetPoint("RIGHT", win, "TOPRIGHT", -PAD, y - 11)
	refs.status:SetPoint("LEFT", refs.lockAll, "RIGHT", 16, 0)
	refs.status:SetJustifyH("RIGHT")
	refs.status:SetMaxLines(2)
	refs.keep = Dropdown(win, 130, KeepMenu)
	refs.keep:SetPoint("RIGHT", win, "TOPRIGHT", -PAD, y - 11)
	Tooltip(refs.keep, L.KEEP_THESE, L.KEEP_THESE_TIP)
	refs.keep:Hide()
	-- Apply now, right of the status line while it says something else has
	-- changed settings you keep (see Refresh).
	refs.applyNow = Button(win, L.APPLY_NOW, 56, BOX_H, function() EverySetting.ApplyNow() end)
	refs.applyNow:SetPoint("RIGHT", win, "TOPRIGHT", -PAD, y - 11)
	Tooltip(refs.applyNow, L.APPLY_NOW, L.APPLY_NOW_TIP)
	refs.applyNow:Hide()

	y = y - 36
	BuildSide(y)

	-- The list
	local list = CreateFrame("Frame", nil, win)
	list:SetPoint("TOPLEFT", PAD + SIDE_W + 12, y)
	list:SetPoint("BOTTOMRIGHT", -PAD - 12, 52)
	list:EnableMouseWheel(true)
	list:SetScript("OnMouseWheel", function(_, delta) ScrollTo(first - delta * 3) end)
	refs.list = list
	local visible = math.floor((HEIGHT + y - 52) / ROW_H)
	for i = 1, visible do
		local row = Row(list)
		row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_H)
		rows[i] = row
	end
	refs.noMatch = Text(list, "GameFontDisable", L.NO_MATCH)
	refs.noMatch:SetPoint("TOPLEFT", 8, -10)

	-- Scroll bar: a track with a thumb that can be dragged
	local track = CreateFrame("Button", nil, win)
	track:SetPoint("TOPLEFT", list, "TOPRIGHT", 4, 0)
	track:SetSize(8, visible * ROW_H)
	Fill(track, "BACKGROUND", LINE, 0.5)
	refs.thumb = track:CreateTexture(nil, "OVERLAY")
	refs.thumb:SetColorTexture(ACCENT[1], ACCENT[2], ACCENT[3], 0.8)
	refs.thumb:SetWidth(8)
	local function Follow(self)
		local _, cy = GetCursorPosition()
		local h = self:GetHeight()
		local f = (self:GetTop() - cy / self:GetEffectiveScale()) / h
		ScrollTo(1 + math.min(1, math.max(0, f)) * (MaxFirst() - 1))
	end
	track:SetScript("OnMouseDown", function(self) Follow(self) self:SetScript("OnUpdate", Follow) end)
	track:SetScript("OnMouseUp", function(self) self:SetScript("OnUpdate", nil) end)
	refs.track = track

	-- Footer
	local foot = CreateFrame("Frame", nil, win)
	foot:SetPoint("BOTTOMLEFT", 1, 1)
	foot:SetPoint("BOTTOMRIGHT", -1, 1)
	foot:SetHeight(40)
	Fill(foot, "BACKGROUND", CARD)
	-- Reset all: a menu of what to reset to. Undo takes any of them back.
	refs.resetAll = Button(foot, L.RESET_ALL_MENU, 110, 22, function(self)
		local options = {
			{ "before", L.TO_BEFORE },
			{ "default", L.TO_DEFAULTS },
		}
		for _, name in ipairs(EverySetting.GetProfiles()) do
			if name ~= EverySetting.GetProfile() then options[#options + 1] = { "profile:" .. name, L.TO_PROFILE:format(name) } end
		end
		OpenMenu(self, options, nil, function(choice)
			if choice == "before" then
				EverySetting.ResetAll()
			elseif choice == "default" then
				EverySetting.ResetAll(true)
			else
				EverySetting.CopyProfile(choice:sub(9))
			end
		end, 250)
	end)
	refs.resetAll:SetPoint("LEFT", PAD - 1, 0)
	Tooltip(refs.resetAll, L.RESET_ALL, L.RESET_ALL_TIP)
	-- Undo and redo: back and forth through this session's changes
	refs.undo = Button(foot, L.UNDO, 60, 22, function() EverySetting.Undo() end)
	refs.undo:SetPoint("LEFT", refs.resetAll, "RIGHT", 8, 0)
	Tooltip(refs.undo, L.UNDO, L.UNDO_TIP)
	refs.redo = Button(foot, L.REDO, 60, 22, function() EverySetting.Redo() end)
	refs.redo:SetPoint("LEFT", refs.undo, "RIGHT", 3, 0)
	Tooltip(refs.redo, L.REDO, L.REDO_TIP)
	refs.situations = Button(foot, L.SITUATIONS_MENU, 100, 22, SituationMenu)
	refs.situations:SetPoint("LEFT", refs.redo, "RIGHT", 8, 0)
	Tooltip(refs.situations, L.SITUATIONS, L.SITUATIONS_TIP)
	refs.cameraWarning = Checkbox(foot, L.HIDE_CAMERA_WARNING, function(self)
		EverySetting.SetHideCameraWarning(self:GetChecked())
	end)
	refs.cameraWarning:SetPoint("LEFT", refs.situations, "RIGHT", 16, 0)
	Tooltip(refs.cameraWarning, L.HIDE_CAMERA_WARNING, L.HIDE_CAMERA_WARNING_TIP)
	-- Danger mode. Turning it on goes to the Danger section, the list's last.
	refs.danger = Checkbox(foot, L.DANGER_MODE, function(self)
		EverySetting.SetDanger(self:GetChecked())
		if self:GetChecked() then ShowSection(sections[#sections]) end
	end)
	refs.danger:SetPoint("LEFT", refs.cameraWarning.text, "RIGHT", 16, 0)
	Tooltip(refs.danger, L.DANGER_MODE, L.DANGER_MODE_TIP)
	refs.restartGx = Button(foot, L.RESTART_GRAPHICS, 130, 22, function() EverySetting.RestartGraphics() end)
	refs.restartGx:SetPoint("LEFT", refs.danger.text, "RIGHT", 16, 0)
	Tooltip(refs.restartGx, function(self) return self.label:GetText() end, function()
		return EverySetting.restart.gx and L.RESTART_GRAPHICS_TIP or L.UPDATE_WINDOW_TIP
	end)
	-- The note has the room right of Danger mode, on two lines or three. Restart
	-- graphics takes that room while it's shown, and the note waits (see Refresh).
	refs.note = Text(foot, "GameFontHighlightSmall", "", MUTED)
	refs.note:SetPoint("RIGHT", -PAD, 0)
	refs.note:SetPoint("LEFT", refs.danger.text, "RIGHT", 16, 0)
	refs.note:SetJustifyH("RIGHT")
	refs.note:SetMaxLines(3)

	-- Size: the grip in the corner scales the whole window, keeping its top-left
	-- corner where it is. Drags are measured from where they start, so a click
	-- doesn't make it jump.
	local function ScaleTo(s, left, top)
		win:SetScale(s)
		win:ClearAllPoints()
		win:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", left / s, top / s)
	end
	local function Corner()
		local s = win:GetScale()
		return (win:GetLeft() or 0) * s, (win:GetTop() or 0) * s
	end
	local function Cursor()
		local cx, cy = GetCursorPosition()
		local u = UIParent:GetEffectiveScale()
		return cx / u, cy / u
	end
	local grip = CreateFrame("Button", nil, foot)
	grip:SetSize(14, 14)
	grip:SetPoint("BOTTOMRIGHT", -2, 2)
	grip:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
	grip:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
	grip:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
	local function Drag(self)
		local cx, cy = Cursor()
		local f = math.max((cx - self.left) / math.max(1, self.x0 - self.left),
			(self.top - cy) / math.max(1, self.top - self.y0))
		ScaleTo(math.min(EverySetting.MAX_SCALE, math.max(EverySetting.MIN_SCALE, self.s0 * f)), self.left, self.top)
	end
	grip:SetScript("OnMouseDown", function(self)
		self.s0 = win:GetScale()
		self.left, self.top = Corner()
		self.x0, self.y0 = Cursor()
		self:SetScript("OnUpdate", Drag)
	end)
	grip:SetScript("OnMouseUp", function(self)
		self:SetScript("OnUpdate", nil)
		EverySetting.SetScale(win:GetScale())
	end)
	grip:SetScript("OnDoubleClick", function()
		local left, top = Corner()
		ScaleTo(1, left, top)
		EverySetting.SetScale(1)
	end)
	Tooltip(grip, L.SIZE, L.SIZE_TIP)
	refs.grip = grip
end

-------------------------------------------------------------------------------
-- Refresh
-------------------------------------------------------------------------------

-- Why a reading of the frame rate was skipped (EverySetting.Reading).
local SKIPPED = { moving = L.SKIPPED_MOVING, camera = L.SKIPPED_CAMERA, combat = L.SKIPPED_COMBAT, soon = L.SKIPPED_SOON }

-- The status line for a reading of the frame rate around a change:
-- "Ground clutter density 48 to 256: 88 to 64 fps".
local function Framerate(r)
	local what = r.knob and L.FPS_CHANGE:format(r.knob.label, Describe(r.knob, r.from), Describe(r.knob, r.to)) or r.label
	if r.why then return L.FPS_SKIPPED:format(what, SKIPPED[r.why]) end
	if not r.after then return L.FPS_MEASURING:format(what) end
	return L.FPS_RESULT:format(what, math.floor(r.before + 0.5), math.floor(r.after + 0.5))
		.. (r.cap and WARN .. ", " .. L.FPS_CAPPED:format(math.floor(r.cap + 0.5)) .. "|r" or r.vsync and ", " .. L.FPS_VSYNC or "")
end

-- What changed the kept settings in `list` (EverySetting.Overwritten), for the
-- status line, which has room for two short lines: "The game" if it changed
-- them all, "An addon" if one addon did. nil if it was more than one thing, or
-- a /run line. Each setting's tooltip names what changed it.
local GAME = {} -- the game, or the console, as against an addon's folder name
local function Who(list)
	local who
	for _, knob in ipairs(list) do
		local addon, by = EverySetting.ChangedBy(knob.cvar)
		local this = addon or (by == L.BY_GAME or by == L.BY_CONSOLE) and GAME or nil
		if not this or this == ADDON or (who and this ~= who) then return nil end
		who = this
	end
	return who and (who == GAME and L.THE_GAME or L.AN_ADDON)
end

-- Shows the knobs as they are now, staying where the list is scrolled to.
function Refresh()
	-- A menu of ticks left open shows the flags as they are now: Reset or Undo may have changed them.
	if menu and menu:IsShown() and type(menu.current) == "function" then MarkMenu() end
	if not (win and win:IsShown()) then return end
	Filter()
	ScrollTo(first)

	-- Each section's count of knobs Every Setting is keeping, and the total.
	local total = 0
	for _, b in ipairs(refs.side) do b.kept = 0 end
	for cvar in pairs(EverySetting.GetKept()) do
		local knob = EverySetting.RawKnob(cvar, "")
		local section = knob and place[knob]
		if section then section.button.kept = section.button.kept + 1 end
		total = total + 1
	end
	SideCounts()
	LayoutSide(sideFirst) -- danger mode may have changed which sections have anything listed

	local status
	local reading = EverySetting.Reading()
	local list = EverySetting.Overwritten()
	if InCombatLockdown() then
		status = WARN .. L.IN_COMBAT .. "|r " .. L.IN_COMBAT_WAIT
	elseif #list > 0 then
		-- Ahead of a reading of the frame rate, which may be from long before.
		-- Two short lines, so a count of two digits still fits beside Apply now.
		status = (#list == 1 and L.STATUS_CHANGED_ONE or L.STATUS_CHANGED):format(Who(list) or L.SOMETHING, AMBER .. #list .. "|r")
	elseif reading then
		status = Framerate(reading)
	elseif total > 0 then
		status = (total == 1 and L.STATUS_KEPT_ONE or L.STATUS_KEPT):format(AMBER .. total .. "|r",
			EverySetting.GetPutBack() and L.STATUS_PUT_BACK or L.STATUS_AT_LOGIN)
	else
		status = L.STATUS_NONE
	end
	refs.status:SetText(status)
	-- Apply now takes the right end of the status line while it's shown.
	overwritten = #list > 0
	refs.applyNow:SetShown(overwritten and refs.status:IsShown())
	refs.status:SetPoint("RIGHT", refs.applyNow, overwritten and "LEFT" or "RIGHT", overwritten and -6 or 0, 0)
	refs.lockAll.label:SetText(AllLocked(EverySetting.GROUPS) and L.UNLOCK_ALL or L.LOCK_ALL)

	local profile = EverySetting.GetProfile()
	local isDefault = profile == EverySetting.DEFAULT_PROFILE
	refs.profile.label:SetText(profile)
	refs.profileDelete:SetEnabled(not isDefault)
	refs.profileDelete:SetAlpha(isDefault and 0.45 or 1)
	local undo, redo = EverySetting.HistorySize()
	refs.undo:SetEnabled(undo > 0)
	refs.undo:SetAlpha(undo > 0 and 1 or 0.45)
	refs.redo:SetEnabled(redo > 0)
	refs.redo:SetAlpha(redo > 0 and 1 or 0.45)
	refs.cameraWarning:SetChecked(EverySetting.GetHideCameraWarning())
	refs.danger:SetChecked(EverySetting.GetDanger())
	local restart = EverySetting.restart
	-- One button for a graphics restart and a window update: the first does both.
	local button = restart.gx and L.RESTART_GRAPHICS or restart.window and L.UPDATE_WINDOW
	refs.restartGx:SetShown(button and true or false)
	refs.restartGx.label:SetText(button or "")
	local note = restart.reload and L.NOTE_RELOAD or restart.login and L.NOTE_LOGIN or restart.client and L.NOTE_CLIENT
	refs.note:SetText(note and not button and (WARN .. note .. "|r") or "")
	if panel and panel:IsShown() then ShowChoices() end -- a lock box in the list may have changed a part
end
EverySetting.RefreshOptions = Refresh

function EverySetting_OpenOptions()
	if not win then
		Build()
		win:Hide() -- new frames start shown; start closed so the toggle below opens it
	end
	if win:IsShown() then
		win:Hide()
	else
		win:Show()
	end
end

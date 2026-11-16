-- A stand-in for the parts of the game's API that Every Setting uses, so its files can
-- be loaded and tested outside the game. W.Load() starts a fresh "client".

local W = {}

-------------------------------------------------------------------------------
-- Frames and other widgets
-------------------------------------------------------------------------------

-- A widget remembers what the tests look at (shown, text, checked, size,
-- scripts). Any other method the game has is accepted: a Create* makes a new
-- widget, a Get* returns 0, an Is* or Has* returns false, the rest do nothing.
-- Methods are told from the fields the addon keeps on its frames by their
-- capital first letter.
local Widget = {}

local function NewWidget(kind, parent, name)
	local w = setmetatable({ kind = kind, parent = parent, name = name, shown = true, scripts = {}, events = {} }, Widget)
	W.widgets[#W.widgets + 1] = w
	if name then _G[name] = w end
	return w
end

local methods = {}
function methods:Show() self:SetShown(true) end
function methods:Hide() self:SetShown(false) end
function methods:SetShown(shown)
	shown = shown and true or false
	if shown == self.shown then return end
	self.shown = shown
	local script = self.scripts[shown and "OnShow" or "OnHide"]
	if script then script(self) end
end
function methods:IsShown() return self.shown end
function methods:IsVisible()
	return self.shown and (self.parent == nil or self.parent.kind == nil or self.parent:IsVisible())
end
function methods:GetParent() return self.parent end
function methods:GetName() return self.name end
function methods:SetScript(what, fn) self.scripts[what] = fn end
function methods:GetScript(what) return self.scripts[what] end
function methods:HookScript(what, fn)
	local old = self.scripts[what]
	self.scripts[what] = old and function(...) old(...) fn(...) end or fn
end
function methods:RegisterEvent(event) self.events[event] = true end
function methods:UnregisterEvent(event) self.events[event] = nil end
function methods:SetText(text)
	self.text = tostring(text or "")
	local script = self.scripts.OnTextChanged
	if script then script(self, false) end
end
function methods:GetText() return self.text or "" end
function methods:GetStringWidth() return #(self.text or "") * 6 end
function methods:GetStringHeight() return 12 end
function methods:SetChecked(on) self.checked = on and true or false end
function methods:GetChecked() return self.checked or false end
function methods:SetEnabled(on) self.disabled = not on end
function methods:Enable() self.disabled = false end
function methods:Disable() self.disabled = true end
function methods:IsEnabled() return not self.disabled end
function methods:SetSize(w, h) self.width, self.height = w, h end
function methods:SetWidth(w) self.width = w end
function methods:SetHeight(h)
	self.height = h
	local script = self.scripts.OnSizeChanged
	if script then script(self, self.width or 0, h) end
end
function methods:GetWidth() return self.width or 0 end
function methods:GetHeight() return self.height or 0 end
function methods:GetSize() return self.width or 0, self.height or 0 end
function methods:SetColorTexture(r, g, b, a) self.color = { r, g, b, a or 1 } end
function methods:SetAlpha(a) self.alpha = a end
function methods:GetAlpha() return self.alpha or 1 end
function methods:SetVerticalScroll(y) self.scroll = y end
function methods:GetVerticalScroll() return self.scroll or 0 end
function methods:SetScrollChild(child) self.child = child end
function methods:SetFocus()
	self.focus = true
	local script = self.scripts.OnEditFocusGained
	if script then script(self) end
end
function methods:ClearFocus()
	local had = self.focus
	self.focus = false
	local script = self.scripts.OnEditFocusLost
	if had and script then script(self) end
end
function methods:HasFocus() return self.focus or false end
function methods:GetEffectiveScale() return 1 end
function methods:SetScale(s) self.scale = s end
function methods:GetScale() return self.scale or 1 end
function methods:GetLeft() return 0 end
function methods:GetFrameLevel() return self.level or 1 end
function methods:SetFrameLevel(level) self.level = level end

Widget.__index = function(_, key)
	local method = methods[key]
	if method then return method end
	if type(key) ~= "string" or not key:match("^%u") then return nil end
	if key:match("^Create") then
		return function(self, a, b)
			-- CreateTexture(name, layer) and CreateFontString(name, layer, font)
			local w = NewWidget(key:sub(7), self, type(a) == "string" and a or nil)
			w.layer = b
			return w
		end
	elseif key:match("^Get") then
		return function() return 0 end
	elseif key:match("^Is") or key:match("^Has") or key:match("^Can") then
		return function() return false end
	end
	return function() end
end

-- Runs a widget's script as the game would: W.Run(button, "OnClick").
function W.Run(widget, what, ...)
	local script = widget.scripts[what]
	assert(script, "the widget has no " .. what .. " script")
	return script(widget, ...)
end

-- Sends an event to every frame registered for it.
function W.Fire(event, ...)
	for _, w in ipairs(W.widgets) do
		if w.events[event] and w.scripts.OnEvent then w.scripts.OnEvent(w, event, ...) end
	end
end

-- Runs the functions queued with C_Timer.After, whatever their delay.
function W.RunTimers()
	local timers = W.timers
	W.timers = {}
	for _, timer in ipairs(timers) do timer.fn() end
end

-- Moves the clock on by `seconds`, running each timer as its time comes.
function W.Advance(seconds)
	local stop = W.now + seconds
	while true do
		local first
		for i, timer in ipairs(W.timers) do
			if timer.at <= stop and (not first or timer.at < W.timers[first].at) then first = i end
		end
		if not first then break end
		local timer = table.remove(W.timers, first)
		W.now = math.max(W.now, timer.at)
		timer.fn()
	end
	W.now = stop
end

-- Picks a color in the game's color picker, which is open: red, green and blue from 0 to 1.
function W.PickColor(r, g, b)
	W.picker.rgb = { r, g, b }
	W.picker.info.swatchFunc()
end

-- Closes the color picker: with its OK button, or else by cancelling.
function W.ClosePicker(ok)
	local picker = W.picker
	if ok then picker.info.swatchFunc() elseif picker.info.cancelFunc then picker.info.cancelFunc(picker.previous) end
	picker:Hide()
end

-- Presses the key bound to one of Bindings.xml's bindings: runs its body.
function W.Press(binding)
	local body = assert(W.bindings[binding], "Bindings.xml has no binding named " .. binding)
	assert((loadstring or load)(body))()
end

-- A description in the game's menu (MenuUtil): the open menu itself, or one of
-- its entries, which can hold a menu of its own. `items` has what was added, in order.
local Description = {}
Description.__index = Description
local function Add(to, item)
	item.items = {}
	to.items[#to.items + 1] = setmetatable(item, Description)
	return item
end
function Description:CreateTitle(text) return Add(self, { title = text }) end
function Description:CreateDivider() return Add(self, { divider = true }) end
function Description:CreateButton(text, callback, data) return Add(self, { text = text, callback = callback, data = data }) end
function Description:CreateRadio(text, isSelected, callback, data)
	return Add(self, { text = text, radio = true, isSelected = isSelected, callback = callback, data = data })
end
function Description:SetTitleAndTextTooltip(title, text) self.tooltip = { title, text } end

-- The entry of the open menu with that text: W.Find("Reset all", "To the game's defaults")
-- looks in an entry's own menu.
function W.Find(...)
	local at = assert(W.menu, "no menu is open")
	for _, text in ipairs({ ... }) do
		local found
		for _, item in ipairs(at.items) do
			if item.text == text then found = item end
		end
		at = assert(found, "the menu has no entry " .. text)
	end
	return at
end

-- Clicks that entry, which closes the menu.
function W.Pick(...)
	local item = W.Find(...)
	W.menu = nil
	item.callback(item.data)
end

-- Writes a line to the client's General.log, as the engine does: "[N][Console] <text>".
local LOG_START = os.time({ year = 2026, month = 11, day = 12, hour = 12 })
function W.Say(text)
	local stamp = os.date("%m/%d %H:%M:%S", LOG_START + math.floor(W.now)) .. (".%03d"):format(math.floor(W.now * 1000) % 1000)
	W.log[#W.log + 1] = stamp .. "  [N][Console] " .. text
end

-- A check for AddCVar's `validate`: a number outside min..max (either can be
-- nil, for a check on one end only) is turned down with `say`.
function W.Range(min, max, say)
	return function(value)
		local number = tonumber(value)
		if number and ((min and number < min) or (max and number > max)) then return false, say end
		return true
	end
end

-------------------------------------------------------------------------------
-- CVars
-------------------------------------------------------------------------------

-- Adds a CVar to the client. `opts` (optional):
--   min, max    the engine clamps a number to this range
--   validate    a function of the value, as the real engine checks it: true
--               keeps it, false turns it down and keeps the old value, a
--               string keeps that instead. A second result is written to the log.
--   float       a number is kept as "%f" ("1.000000")
--   secure      it can't be set in combat
--   locked, readOnly   it can't be set
--   takes       a locked or read-only one is set all the same
--   help, category     for ConsoleGetAllCommands
function W.AddCVar(name, default, opts)
	local cvar = { name = name, value = default, default = default }
	for k, v in pairs(opts or {}) do cvar[k] = v end
	W.cvars[name:lower()] = cvar
	W.cvarList[#W.cvarList + 1] = cvar
	return cvar
end

local function Find(name)
	return type(name) == "string" and W.cvars[name:lower()] or nil
end

local function SetCVar(name, value)
	local cvar = Find(name)
	W.sets[#W.sets + 1] = { name, tostring(value), at = W.now }
	if not cvar or ((cvar.locked or cvar.readOnly) and not cvar.takes) then return false end
	if cvar.secure and W.combat then return false end
	value = tostring(value)
	local number = tonumber(value)
	if number and cvar.min and number < cvar.min then value = tostring(cvar.min) end
	if number and cvar.max and number > cvar.max then value = tostring(cvar.max) end
	if cvar.validate then
		local result, say = cvar.validate(value)
		if say then W.Say(say) end
		if result == false then return true end -- turned down, but SetCVar says true
		if type(result) == "string" then value = result end
	end
	if cvar.float and tonumber(value) then value = ("%f"):format(tonumber(value)) end
	-- The game sends CVAR_UPDATE during the write, and only for a change.
	if value == cvar.value then return true end
	cvar.value = value
	W.Fire("CVAR_UPDATE", cvar.name, value)
	return true
end

-- A CVar that packs a set of on/off flags, as the engine keeps it: a byte for
-- the format's version (2), then a byte for every six flags, with bit 6 set
-- and a bit for each flag that's on. Bytes with no flag on are left off the end.
-- Flags are numbered from 1.
local function FlagsOn(value)
	local flags = {}
	for at = 2, #value do
		for bit = 0, 5 do
			if math.floor(value:byte(at) / 2 ^ bit) % 2 == 1 then flags[(at - 2) * 6 + bit + 1] = true end
		end
	end
	return flags
end

local function GetCVarBitfield(name, index)
	local cvar = Find(name)
	if not cvar then return nil end
	return FlagsOn(cvar.value)[index] or false
end

-- W.flagSets has each call: { name, index, on }.
local function SetCVarBitfield(name, index, on)
	local cvar = Find(name)
	W.flagSets[#W.flagSets + 1] = { name, index, on }
	if not cvar or ((cvar.locked or cvar.readOnly) and not cvar.takes) then return false end
	if cvar.secure and W.combat then return false end
	local flags, last = FlagsOn(cvar.value), 0
	flags[index] = on or nil
	for i in pairs(flags) do last = math.max(last, i) end
	local bytes = { cvar.value ~= "" and cvar.value:sub(1, 1) or "\002" }
	for at = 1, math.ceil(last / 6) do
		local byte = 64
		for bit = 0, 5 do
			if flags[(at - 1) * 6 + bit + 1] then byte = byte + 2 ^ bit end
		end
		bytes[#bytes + 1] = string.char(byte)
	end
	local value = table.concat(bytes)
	if value == cvar.value then return true end
	cvar.value = value
	W.Fire("CVAR_UPDATE", cvar.name, cvar.value)
	return true
end

-- Adds a console command that isn't a CVar, such as GxRestart, with the game's
-- help for it if given. A fresh client has none.
function W.AddCommand(name, help)
	W.commands[#W.commands + 1] = { name = name, help = help or "" }
end

-- How many times SetCVar was called for `name` since the client started.
function W.SetCount(name)
	local count = 0
	for _, set in ipairs(W.sets) do
		if set[1]:lower() == name:lower() then count = count + 1 end
	end
	return count
end

-------------------------------------------------------------------------------
-- A fresh client
-------------------------------------------------------------------------------

local function Globals(client)
	_G.C_CVar = {
		GetCVar = function(name) local c = Find(name) return c and c.value end,
		GetCVarDefault = function(name) local c = Find(name) return c and c.default end,
		GetCVarInfo = function(name)
			local c = Find(name)
			if not c then return nil end
			return c.value, c.default, c.account or false, c.character or false,
				c.locked or false, c.secure or false, c.readOnly or false
		end,
		SetCVar = SetCVar,
		GetCVarBitfield = GetCVarBitfield,
		SetCVarBitfield = SetCVarBitfield,
	}
	-- The game's SetCVar, from Blizzard's own code: it calls C_CVar.SetCVar.
	_G.SetCVar = (loadstring or load)("return function(name, value) local ok = C_CVar.SetCVar(name, value) return ok end",
		"@Interface/AddOns/Blizzard_SharedXMLBase/CvarUtil.lua")()
	_G.ConsoleGetAllCommands = function()
		local list = {}
		for _, c in ipairs(W.commands) do list[#list + 1] = { command = c.name, commandType = 1, category = 2, help = c.help } end
		for _, c in ipairs(W.cvarList) do
			list[#list + 1] = { command = c.name, commandType = 0, category = c.category or 5, help = c.help or "" }
		end
		return list
	end
	_G.Enum = { ConsoleCommandType = { Cvar = 0, Command = 1 },
		ConsoleColorType = { InputColor = 1, EchoColor = 2, WarningColor = 4, GlobalColor = 5, AdminColor = 6 } }
	-- The console: each line run is in W.consoled. Its text size and colors are
	-- set and read back as in the game, where 1.60.1 held the size to 10 to 50.
	W.consoled, W.fontHeight = {}, 14
	W.consoleColors = { [1] = { 128, 196, 255 }, [2] = { 128, 128, 128 }, [4] = { 255, 255, 0 }, [5] = { 255, 255, 255 }, [6] = { 255, 255, 255 } }
	_G.ConsoleExec = function(line)
		W.consoled[#W.consoled + 1] = line
		local size = line:match("^fontsize%s*(%S*)$")
		if size then W.fontHeight = math.max(10, math.min(50, tonumber(size) or 0)) end
		local class, r, g, b = line:match("^fontcolor (%a+) (%d+) (%d+) (%d+)$")
		local types = { input = 1, echo = 2, warning = 4, global = 5, admin = 6 }
		if types[class] then W.consoleColors[types[class]] = { tonumber(r), tonumber(g), tonumber(b) } end
		return true
	end
	_G.ConsoleGetFontHeight = function() return W.fontHeight end
	_G.ConsoleGetColorFromType = function(colorType)
		local c = W.consoleColors[colorType] or { 255, 255, 255 }
		return { GetRGB = function() return c[1] / 255, c[2] / 255, c[3] / 255 end }
	end
	-- Which game it is. Retail's project is the mainline's, and it has no
	-- WOW_PROJECT_CAMELOT (seen in 12.1.5). Forever's is its own: 18, as other
	-- addons take it to be.
	_G.WOW_PROJECT_MAINLINE = 1
	if client == "retail" then
		_G.GetBuildInfo = function() return "12.1.5", "70783", "Nov  3 2026", 120105 end
		_G.WOW_PROJECT_ID, _G.WOW_PROJECT_CAMELOT = 1, nil
	else
		_G.GetBuildInfo = function() return "1.60.1", "70938", "Nov 10 2026", 16001 end
		_G.WOW_PROJECT_ID, _G.WOW_PROJECT_CAMELOT = 18, 18
	end
	_G.GetLocale = function() return "enUS" end
	_G.InCombatLockdown = function() return W.combat end
	_G.IsMounted = function() return W.mounted end
	_G.IsResting = function() return W.resting end
	_G.IsInInstance = function() return W.instance, W.instance and "party" or "none" end
	_G.GetCursorPosition = function() return W.cursor[1], W.cursor[2] end
	_G.CreateFrame = function(kind, name, parent) return NewWidget(kind, parent, name) end
	_G.UIParent = NewWidget("Frame", nil, "UIParent")
	_G.UISpecialFrames = {}
	_G.GameTooltip = NewWidget("GameTooltip", nil, "GameTooltip")
	-- The game's color picker. It reports each color as it's picked (the one it
	-- opens on too), and again when OK is pressed. W.PickColor and W.ClosePicker work it.
	local picker = NewWidget("Frame", nil, "ColorPickerFrame")
	picker.shown = false
	function picker:SetupColorPickerAndShow(info)
		self.info, self.previous = info, { r = info.r, g = info.g, b = info.b }
		self.swatchFunc = info.swatchFunc -- as the game's keeps it
		self:Show()
		W.PickColor(info.r, info.g, info.b)
	end
	function picker:GetColorRGB() return self.rgb[1], self.rgb[2], self.rgb[3] end
	W.picker = picker
	_G.DEFAULT_CHAT_FRAME = { AddMessage = function(_, text) W.chat[#W.chat + 1] = text end }
	_G.C_Timer = { After = function(delay, fn) W.timers[#W.timers + 1] = { at = W.now + (delay or 0), fn = fn } end }
	_G.GetTime = function() return W.now end
	-- The frame rate, and what moves the scene: W.fps, W.speed, W.falling,
	-- W.mouselook, W.leftButton (held down), W.facing and W.zoom.
	_G.GetFramerate = function() return W.fps end
	_G.GetUnitSpeed = function() return W.speed end
	_G.IsFalling = function() return W.falling end
	_G.IsMouselooking = function() return W.mouselook end
	_G.IsMouseButtonDown = function(button) return button == "LeftButton" and W.leftButton end
	_G.GetPlayerFacing = function() return W.facing end
	_G.GetCameraZoom = function() return W.zoom end
	_G.UnitAffectingCombat = function() return W.combat end
	_G.debugprofilestop = function() return W.now * 1000 end
	_G.UnitName = function() return "Tester" end
	_G.GetRealmName = function() return "Realm" end
	-- W.addons: { name, loaded, enabled } for each addon in the AddOns folder.
	local function Addon(which)
		for i, addon in ipairs(W.addons) do
			if i == which or addon.name == which then return addon end
		end
	end
	_G.C_AddOns = {
		GetAddOnMetadata = function(_, field) return W.toc[field] end, -- Every Setting's own TOC
		GetNumAddOns = function() return #W.addons end,
		GetAddOnInfo = function(which) local a = Addon(which) return a and a.name end,
		IsAddOnLoaded = function(which) local a = Addon(which) return a and a.loaded or false end,
		DisableAddOn = function(which) local a = Addon(which) if a then a.enabled = false end end,
		EnableAddOn = function(which) local a = Addon(which) if a then a.enabled = true end end,
	}
	_G.RestartGx = function() W.restarts.gx = (W.restarts.gx or 0) + 1 end
	_G.UpdateWindow = function() W.restarts.window = (W.restarts.window or 0) + 1 end
	-- hooksecurefunc(name, hook) for a global, or (table, name, hook).
	_G.hooksecurefunc = function(t, name, hook)
		if type(t) ~= "table" then t, name, hook = _G, t, name end
		local original = t[name]
		t[name] = function(...)
			local results = { original(...) }
			hook(...)
			return (table.unpack or unpack)(results)
		end
	end
	_G.RunScript = function(code) assert((loadstring or load)(code, "=" .. code))() end
	-- The stack from `level` (1: the function that calls debugstack). The addon's
	-- files show as the game's do, by their path under Interface/AddOns.
	_G.debugstack = function(level) return debug.traceback("", (level or 1) + 1) end
	-- The Disable button on the game's warning about its experimental camera settings.
	_G.ResetTestCvars = function()
		for _, cvar in ipairs(W.cvarList) do
			if cvar.name:lower():find("^test_camera") then SetCVar(cvar.name, cvar.default) end
		end
	end
	-- The game's popups: W.popups has the one shown, by name.
	W.popups = {}
	_G.StaticPopup_Show = function(which) W.popups[which] = true end
	_G.StaticPopup_Hide = function(which) W.popups[which] = nil end
	-- The events the game's UI routes through GameEvent: W.gameEvents has each handler.
	local function ShowWarning() _G.StaticPopup_Show("EXPERIMENTAL_CVAR_WARNING") end
	W.gameEvents = { EXPERIMENTAL_CVAR_CONFIRMATION_NEEDED = ShowWarning }
	W.blizzardWarning = ShowWarning
	_G.GameEvent = {
		RegisterInternalEvent = function(event, handler) W.gameEvents[event] = handler end,
		UnregisterInternalEvent = function(event) W.gameEvents[event] = nil end,
		HandleExperimentalCVarConfirmationNeeded = ShowWarning,
	}
	-- The game's Options: W.categories has each category an addon registered, { name, frame }.
	-- SettingsPanel is their window, closed to begin with.
	_G.SettingsPanel = NewWidget("Frame", nil, "SettingsPanel")
	_G.SettingsPanel.shown = false
	_G.Settings = {
		RegisterCanvasLayoutCategory = function(frame, name) return { name = name, frame = frame } end,
		RegisterAddOnCategory = function(category) W.categories[#W.categories + 1] = category end,
	}
	-- The game's menu, opened at the pointer: W.menu is the one that's open.
	_G.MenuUtil = {
		CreateContextMenu = function(owner, generator)
			W.menu = setmetatable({ items = {} }, Description)
			generator(owner, W.menu)
		end,
	}
	-- The modified clicks, as the game keeps them with the key bindings: W.clicks has
	-- each one's value, and W.bindingSaves the binding set of each SaveBindings call.
	W.clicks, W.bindingSaves = {}, {}
	for action, value in pairs({ SELFCAST = "ALT", EXPANDTOOLTIP = "SHIFT", FOCUSCAST = "NONE", MOUSEOVERCAST = "NONE",
		AUTOLOOTTOGGLE = "SHIFT", MAILAUTOLOOTTOGGLE = "SHIFT", STICKYCAMERA = "CTRL", CHATLINK = "SHIFT-BUTTON1",
		DRESSUP = "CTRL-BUTTON1", EXPANDITEM = "SHIFT-BUTTON2", SPLITSTACK = "SHIFT", PICKUPACTION = "SHIFT",
		PICKUPITEM = "SHIFT", COMPAREITEMS = "SHIFT", OPENALLBAGS = "SHIFT", QUESTWATCHTOGGLE = "SHIFT",
		RECIPEWATCHTOGGLE = "SHIFT", TOKENWATCHTOGGLE = "SHIFT", SHOWITEMFLYOUT = "ALT", SHOWMULTICASTFLYOUT = "ALT" }) do
		W.clicks[action] = value
	end
	_G.GetModifiedClick = function(action) return W.clicks[action] end
	_G.SetModifiedClick = function(action, value) W.clicks[action] = value end
	-- The turn and strafe keys: W.strafe is 0 (Enhanced), 1 (Classic) or 2 (changed by hand).
	W.strafe = 0
	_G.Enum.TurnStrafeStyle = { Modern = 0, Legacy = 1, Custom = 2 }
	_G.C_KeyBindings = {
		GetTurnStrafeStyle = function() return W.strafe end,
		SetTurnStrafeStyle = function(style) if style == 0 or style == 1 then W.strafe = style end end,
	}
	_G.GetCurrentBindingSet = function() return 1 end -- the account's
	_G.SaveBindings = function(set) W.bindingSaves[#W.bindingSaves + 1] = set end
	-- The other settings that aren't CVars, as the 1.60.1 client has them:
	--   W.bars       action bars 2 to 8, on or off, which the game sets all at once
	--   W.overrides  item quality (0 to 5) -> the colour picked, as "ffrrggbb", or nil
	--   W.social     guildInvites, chat and allies. Guild invites and allies read back
	--                as they were for half a second, as the server answers (W.lag)
	--   W.tracking   the minimap's tracking: { filterID, active } each, in the game's order
	--   W.caa        the combat audio alerts of the specialisation in use, setting -> number
	W.bars = { false, false, false, false, false, false, false }
	_G.GetActionBarToggles = function() return (table.unpack or unpack)(W.bars, 1, 7) end
	_G.SetActionBarToggles = function(...) W.bars = { ... } end
	local DEFAULTS = { "ff9d9d9d", "ffffffff", "ff1eff00", "ff0070dd", "ffa335ee", "ffff8000" }
	local function Color(hex)
		return { hex = hex:lower(), GenerateHexColor = function(self) return self.hex end }
	end
	W.overrides = {}
	_G.CreateColorFromHexString = Color
	_G.C_ColorOverrides = {
		GetColorOverrideInfo = function(n)
			local hex = W.overrides[n]
			return hex and { overrideType = n, overrideColor = Color(hex), overrideColorString = hex } or nil
		end,
		GetDefaultColorForQuality = function(n) return Color(DEFAULTS[n + 1]) end,
		SetColorOverride = function(n, color) W.overrides[n] = color:GenerateHexColor() end,
		RemoveColorOverride = function(n) W.overrides[n] = nil end,
	}
	W.social, W.lag = { guildInvites = false, chat = false, allies = true }, {}
	local function Social(key, late)
		local function Get()
			local lag = W.lag[key]
			if lag and W.now < lag.ends then return lag.was end
			return W.social[key]
		end
		local function Set(on)
			if late then W.lag[key] = { was = Get(), ends = W.now + 0.5 } end
			W.social[key] = on
		end
		return Get, Set
	end
	_G.GetAutoDeclineGuildInvites, _G.SetAutoDeclineGuildInvites = Social("guildInvites", true)
	_G.GetAllowRecentAlliesSeeLocation, _G.SetAllowRecentAlliesSeeLocation = Social("allies", true)
	local isChatDisabled, setChatDisabled = Social("chat")
	_G.C_SocialRestrictions = { IsChatDisabled = isChatDisabled, SetChatDisabled = setChatDisabled }
	W.chatChanged = {} -- each call of the game's ChatConfigFrame_OnChatDisabledChanged
	_G.ChatConfigFrame_OnChatDisabledChanged = function(on) W.chatChanged[#W.chatChanged + 1] = on end
	_G.Enum.MinimapTrackingFilter = { Auctioneer = 1, Banker = 2, Battlemaster = 4, TaxiNode = 8, VenderFood = 16, Innkeeper = 32,
		Mailbox = 64, TrainerProfession = 128, VendorReagent = 256, Repair = 512, TrivialQuests = 1024, Stablemaster = 2048,
		Transmogrifier = 4096, POI = 8192, Target = 16384, Focus = 32768, QuestPOIs = 65536, Digsites = 131072, Barber = 262144,
		ItemUpgrade = 524288, VendorPoison = 1048576, AccountCompletedQuests = 2097152, AccountBanker = 4194304,
		TrainerClass = 8388608, VendorAmmo = 16777216 }
	W.tracking = {}
	for _, id in ipairs({ 1, 2, 4194304, 262144, 4, 8, 16, 16777216, 32, 524288, 64, 8388608, 128, 256, 512, 2048, 4096, 1024,
		2097152, 8192, 16384, 32768, 65536, 131072 }) do
		W.tracking[#W.tracking + 1] = { filterID = id, active = id == 8 or id == 32 or id == 65536 or id == 2097152 }
	end
	_G.C_Minimap = {
		GetNumTrackingTypes = function() return #W.tracking end,
		GetTrackingFilter = function(i) return W.tracking[i] and { filterID = W.tracking[i].filterID } end,
		GetTrackingInfo = function(i) return W.tracking[i] and { name = "Tracking " .. i, active = W.tracking[i].active } end,
		SetTracking = function(i, on) W.tracking[i].active = on end,
	}
	_G.Enum.CombatAudioAlertSpecSetting = { Resource1Percent = 0, Resource1Format = 1, Resource1Voice = 2, Resource1Volume = 3,
		Resource2Percent = 4, Resource2Format = 5, Resource2Voice = 6, Resource2Volume = 7, SayIfTargeted = 8 }
	W.caa = { [0] = 0, 1, 0, 100, 0, 1, 0, 100, 1 }
	_G.C_CombatAudioAlert = {
		GetSpecSetting = function(setting) return W.caa[setting] end,
		SetSpecSetting = function(setting, value) W.caa[setting] = value return true end,
	}
	_G.SlashCmdList = {}
	_G.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
	_G.strsplit = function(sep, s)
		local parts = {}
		for part in (s .. sep):gmatch("(.-)%" .. sep) do parts[#parts + 1] = part end
		return (table.unpack or unpack)(parts)
	end
	_G.unpack = _G.unpack or table.unpack
	_G.tinsert = table.insert
	_G.date = function(format, t) return os.date(format, t or LOG_START + math.floor(W.now)) end
	_G.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
	_G.EverySettingDB, _G.EverySettingCharDB = nil, nil
	_G.EverySettingOptions = nil -- the last client's window
end

-- Starts a fresh client and loads the addon's files in TOC order. `saved` is
-- the account's saved variables from the last session, if any, and `savedChar`
-- the character's. `onLocale(ns)`, if given, runs once the locale files are in and
-- before the files that use them, as a translation's would. `client` is "retail"
-- for the retail client, or else it's WoW Forever's. Returns the addon's table.
-- WoW Forever's CVars: its client's on a Mac (data/cvars.lua), then the ones only its
-- client on Windows has (W.WINDOWS), each as data/cvars.lua lists one.
W.WINDOWS = "data/ranges/70938/windows-d3d12/cvars.lua"
function W.ForeverCVars()
	local list, seen = {}, {}
	for _, path in ipairs({ "data/cvars.lua", W.WINDOWS }) do
		for _, cvar in ipairs(dofile(path).cvars) do
			if not seen[cvar[1]] then
				seen[cvar[1]] = true
				list[#list + 1] = cvar
			end
		end
	end
	return list
end

function W.Load(saved, savedChar, onLocale, client)
	W.widgets, W.cvars, W.cvarList, W.sets, W.flagSets, W.commands = {}, {}, {}, {}, {}, {}
	W.chat, W.timers, W.restarts, W.combat, W.cursor = {}, {}, {}, false, { 0, 0 }
	W.mounted, W.resting, W.instance = false, false, false
	W.now, W.log, W.addons = 0, {}, {}
	W.toc, W.bindings, W.categories, W.menu = {}, {}, {}, nil
	W.fps, W.speed, W.falling, W.mouselook, W.facing, W.zoom = 60, 0, false, false, 0, 15
	W.leftButton = false
	Globals(client)
	_G.EverySettingDB = saved
	_G.EverySettingCharDB = savedChar
	local files = {}
	for raw in io.lines("EverySetting/EverySetting.toc") do
		local line = raw:gsub("\r$", "")
		local field, value = line:match("^## (.-): (.*)$")
		if field then
			W.toc[field] = value
		elseif line ~= "" and not line:match("^#") then
			files[#files + 1] = line:gsub("\\", "/")
		end
	end
	local ns = {}
	for i, file in ipairs(files) do
		local f = assert(io.open("EverySetting/" .. file))
		local source = f:read("*a")
		f:close()
		-- Named by its path in the game, as debugstack shows it.
		assert((loadstring or load)(source, "@Interface/AddOns/EverySetting/" .. file))("EverySetting", ns)
		if onLocale and file:find("^Locales/") and not (files[i + 1] or ""):find("^Locales/") then onLocale(ns) end
	end
	-- The game loads an addon's Bindings.xml by its name. Each binding's body is Lua.
	local xml = assert(io.open("EverySetting/Bindings.xml"))
	for name, body in xml:read("*a"):gmatch('<Binding name="([^"]+)"[^>]*>(.-)</Binding>') do W.bindings[name] = body end
	xml:close()
	return ns.EverySetting, ns
end

-- Runs fn(...) as another addon's code, from its folder `name`: debugstack
-- shows that addon's file, as it would in the game.
function W.FromAddon(name, fn, ...)
	local chunk = (loadstring or load)("local fn = ... fn(select(2, ...))", "@Interface/AddOns/" .. name .. "/" .. name .. ".lua")
	chunk(fn, ...)
end

-- Runs a line of Lua as /run does in chat, or a macro: through the game's RunScript.
function W.FromChat(code)
	_G.RunScript(code)
end

-- Sets a CVar as /console does, which doesn't go through C_CVar.SetCVar.
function W.Console(name, value)
	SetCVar(name, value)
end

-- Logs in: the addon's saved variables load, then the CVars, then the world.
-- With `worldFirst` the world comes before the CVars: the game's own code
-- doesn't count on the order of the two.
function W.Login(worldFirst)
	W.Fire("ADDON_LOADED", "EverySetting")
	if not worldFirst then W.Fire("VARIABLES_LOADED") end
	W.Fire("PLAYER_ENTERING_WORLD", true, false)
	if worldFirst then W.Fire("VARIABLES_LOADED") end
end

-- Starts or ends combat.
function W.Combat(on)
	W.combat = on
	W.Fire(on and "PLAYER_REGEN_DISABLED" or "PLAYER_REGEN_ENABLED")
end

-- Mounts or dismounts.
function W.Mount(on)
	W.mounted = on
	W.Fire("PLAYER_MOUNT_DISPLAY_CHANGED")
end

-- Enters or leaves a city or an inn.
function W.Rest(on)
	W.resting = on
	W.Fire("PLAYER_UPDATE_RESTING")
end

-- Goes through a loading screen, into an instance or out of one.
function W.Zone(inInstance)
	W.instance = inInstance
	W.Fire("PLAYER_ENTERING_WORLD", false, false)
end

-- Types a slash command: W.Slash("probe farclip 0 99999").
function W.Slash(msg)
	_G.SlashCmdList.EVERYSETTING(msg)
end

return W

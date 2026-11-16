-- The settings the game locks but has a function of its own for: Every Setting
-- sets them through it. The voice chat devices, each from a menu of what the
-- game offers now, and the push-to-talk key, which the game takes as a list.

local T = ...
local W = dofile("tests/wow.lua")

local calls -- each call to one of the game's voice functions: { name, argument }
local quiet -- true: the game changes a device's CVar without a CVAR_UPDATE

-- The game's voice chat, as the 1.60.1 client has it:
--   a device's CVar changes a moment after its function is called, not during it;
--   the system's own device is listed with an ID like the rest, and while it's in
--   use the CVar is empty; an empty ID, or one that isn't offered, changes nothing;
--   the push-to-talk key's CVar changes at once, to the keys with a tab between them.
local function Voice()
	calls = {}
	local function Devices(first, name)
		return {
			{ deviceID = first, displayName = name, isActive = false, isSystemDefault = false, isCommsDefault = false },
			{ deviceID = "Default System Device", displayName = "Default System Device", isActive = true, isSystemDefault = true, isCommsDefault = false },
			{ deviceID = "Default Communication Device", displayName = "Default Communication Device", isActive = false,
			  isSystemDefault = false, isCommsDefault = true },
		}
	end
	local function SetDevice(name, cvar, devices)
		return function(id)
			calls[#calls + 1] = { name, id }
			for _, device in ipairs(devices) do
				if device.deviceID == id then
					C_Timer.After(0.3, function()
						local value = device.isSystemDefault and "" or id
						W.cvars[cvar:lower()].value = value
						if not quiet then W.Fire("CVAR_UPDATE", cvar, value) end
					end)
				end
			end
		end
	end
	local inputs, outputs = Devices("in-1", "Desk microphone"), Devices("out-1", "Headset")
	_G.C_VoiceChat = {
		GetAvailableInputDevices = function() return inputs end,
		GetAvailableOutputDevices = function() return outputs end,
		SetInputDevice = SetDevice("SetInputDevice", "VoiceInputDevice", inputs),
		SetOutputDevice = SetDevice("SetOutputDevice", "VoiceOutputDevice", outputs),
		SetPushToTalkBinding = function(keys)
			calls[#calls + 1] = { "SetPushToTalkBinding", keys }
			W.cvars.voicepushtotalkkeybind.value = table.concat(keys, "\t")
		end,
	}
	return inputs
end

-- A logged-in client in danger mode, with the three voice settings among the
-- CVars of Sound and voice. `saved` is last session's saved variables, `values`
-- what the CVars have as the client starts, and with `worldFirst` the world
-- loads before the variables do.
local function Start(saved, values, worldFirst)
	_G.C_VoiceChat, quiet = nil, false
	saved = saved or {}
	saved.danger = true
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("Sound_MusicVolume", "0.4")
	W.AddCVar("VoiceInputDevice", "", { locked = true })
	W.AddCVar("VoiceOutputDevice", "", { locked = true })
	W.AddCVar("VoicePushToTalkKeybind", "LMETA", { locked = true })
	for cvar, value in pairs(values or {}) do W.cvars[cvar:lower()].value = value end
	EverySetting.CVARS = { Sound_MusicVolume = "1|s|0|1|0.05", VoiceInputDevice = "1", VoiceOutputDevice = "1",
		VoicePushToTalkKeybind = "1" }
	EverySetting.GROUPS = {}
	EverySetting.SECTIONS = { "Sound and voice" }
	local inputs = Voice()
	W.Login(worldFirst)
	EverySetting.AllGroups()
	return EverySetting, ns.Options, inputs
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

-- The open menu's options, as "Label, Label".
local function Menu()
	local labels = {}
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value ~= nil and w.parent and w.parent.items and w:IsVisible() then
			labels[#labels + 1] = w.label:GetText()
		end
	end
	return table.concat(labels, ", ")
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

T.test("setters: a device is set through the game's function, by its ID", function()
	local EverySetting = Start()
	local knob = EverySetting.Knob("VoiceInputDevice")
	T.eq(knob.setter, true)
	T.eq(knob.type, "choice", "a menu")
	T.eq(EverySetting.Set("VoiceInputDevice", "in-1"), "in-1")
	T.eq(calls[1][1], "SetInputDevice")
	T.eq(calls[1][2], "in-1", "the ID as text")
	T.eq(W.SetCount("VoiceInputDevice"), 0, "SetCVar isn't tried")
	T.eq(Get("VoiceInputDevice"), "", "the game changes the CVar a moment later")
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-1", "and until then it's the device asked for")
	T.ok(EverySetting.IsStored("VoiceInputDevice"), "which is kept")
	T.eq(EverySetting.Before("VoiceInputDevice"), "")
	W.Advance(1)
	T.eq(Get("VoiceInputDevice"), "in-1")
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-1")
	T.eq(EverySetting.ChangedBy("VoiceInputDevice"), "EverySetting", "the game's change a moment later is Every Setting's")
	T.eq(EverySetting.Set("VoiceInputDevice", "no such device"), nil, "the menu takes only what the game offers")
	T.eq(#calls, 1)

	-- The system's own device is set by its ID, and the CVar is empty for it.
	T.eq(EverySetting.Set("VoiceInputDevice", ""), "")
	T.eq(calls[2][2], "Default System Device")
	T.eq(EverySetting.Undo(), true)
	T.eq(calls[3][2], "in-1", "Undo goes through the function")
	T.eq(EverySetting.Redo(), true)
	T.eq(calls[4][2], "Default System Device", "and Redo, before the game has answered")
	EverySetting.Undo()
	W.Advance(1)
	T.eq(Get("VoiceInputDevice"), "in-1")
	EverySetting.Reset("VoiceInputDevice")
	T.eq(calls[#calls][2], "Default System Device", "and Reset")
	T.ok(not EverySetting.IsStored("VoiceInputDevice"))
	W.Advance(1)
	T.eq(Get("VoiceInputDevice"), "")
	T.eq(EverySetting.Set("VoiceOutputDevice", "out-1"), "out-1")
	T.eq(calls[#calls][1], "SetOutputDevice")
end)

T.test("setters: a device the game doesn't take shows as the game has it, three seconds on", function()
	local EverySetting = Start()
	quiet = true
	T.eq(EverySetting.Set("VoiceInputDevice", "in-9", true), "in-9", "the box takes any ID")
	W.Advance(2.9)
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-9")
	W.Advance(0.2)
	T.eq(EverySetting.Get("VoiceInputDevice"), "", "the game changed nothing")
	T.ok(EverySetting.IsStored("VoiceInputDevice"), "it's still kept, and tried again at the next login")
	-- One it takes without saying so is the same by then.
	EverySetting.Set("VoiceInputDevice", "in-1")
	W.Advance(4)
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-1")
	-- A second change before the first's three seconds are up has three of its own.
	EverySetting.Set("VoiceInputDevice", "in-8", true)
	W.Advance(2)
	EverySetting.Set("VoiceInputDevice", "in-9", true)
	W.Advance(2)
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-9")
	W.Advance(1.1)
	T.eq(EverySetting.Get("VoiceInputDevice"), "in-1")
end)

T.test("setters: the push-to-talk key goes to the game as a list of keys", function()
	local EverySetting = Start()
	T.eq(EverySetting.Knob("VoicePushToTalkKeybind").type, "text", "a box")
	T.eq(EverySetting.Set("VoicePushToTalkKeybind", "LCTRL LSHIFT", true), "LCTRL\tLSHIFT", "kept as the game has it")
	T.eq(calls[1][1], "SetPushToTalkBinding")
	T.eq(table.concat(calls[1][2], "+"), "LCTRL+LSHIFT", "each key by its name")
	T.eq(EverySetting.Set("VoicePushToTalkKeybind", "  F13 ", true), "F13")
	T.eq(EverySetting.Undo(), true)
	T.eq(Get("VoicePushToTalkKeybind"), "LCTRL\tLSHIFT", "the game's own text goes back as the same keys")
	T.eq(#calls[#calls][2], 2)
	EverySetting.Reset("VoicePushToTalkKeybind")
	T.eq(Get("VoicePushToTalkKeybind"), "LMETA")
	T.eq(EverySetting.Set("VoicePushToTalkKeybind", "", true), "", "no key at all")
	T.eq(#calls[#calls][2], 0, "is an empty list")
end)

T.test("setters: the command is the game's function with the arguments it takes", function()
	local EverySetting = Start()
	T.eq(EverySetting.Command("VoiceInputDevice", "in-1"), '/run C_VoiceChat.SetInputDevice("in-1")')
	T.eq(EverySetting.Command("VoiceOutputDevice", ""), '/run C_VoiceChat.SetOutputDevice("Default System Device")', "the system's own")
	T.eq(EverySetting.Command("VoiceOutputDevice", 'a "b"'), '/run C_VoiceChat.SetOutputDevice("a \\"b\\"")')
	T.eq(EverySetting.Command("VoicePushToTalkKeybind", "LCTRL\tLSHIFT"), '/run C_VoiceChat.SetPushToTalkBinding({"LCTRL", "LSHIFT"})')
	T.eq(EverySetting.Command("VoicePushToTalkKeybind", "LMETA"), '/run C_VoiceChat.SetPushToTalkBinding({"LMETA"})')
	T.eq(EverySetting.Command("VoicePushToTalkKeybind", ""), "/run C_VoiceChat.SetPushToTalkBinding({})")
	_G.C_VoiceChat = nil
	T.eq(EverySetting.Command("VoiceInputDevice", "in-1"), '/run C_VoiceChat.SetInputDevice("in-1")', "on a client without it too")
	T.eq(EverySetting.Command("VoiceInputDevice", ""), '/run SetCVar("VoiceInputDevice", "")', "but not for a device nothing names")
end)

-- A test of the login, run once for each order its two events may come in.
local function EitherOrder(name, fn)
	T.test(name, function() fn(false) end)
	T.test(name .. " (the world loads first)", function() fn(true) end)
end

EitherOrder("setters: a kept value is set again at login, through the function", function(worldFirst)
	local kept = { profiles = { Default = { VoiceOutputDevice = "out-1", VoicePushToTalkKeybind = "LCTRL\tLSHIFT" } },
		before = { VoiceOutputDevice = "", VoicePushToTalkKeybind = "LMETA" } }
	local EverySetting = Start(kept, { VoiceOutputDevice = "Default Communication Device" }, worldFirst)
	T.eq(#calls, 2)
	T.eq(Get("VoicePushToTalkKeybind"), "LCTRL\tLSHIFT")
	W.Advance(1)
	T.eq(Get("VoiceOutputDevice"), "out-1", "the game had changed it")
	T.eq(W.SetCount("VoiceOutputDevice") + W.SetCount("VoicePushToTalkKeybind"), 0)
	T.eq(EverySetting.Before("VoiceOutputDevice"), "Default Communication Device", "what it was is what Reset puts back")
	-- One that's already there isn't set again.
	EverySetting = Start(EverySettingDB, { VoiceOutputDevice = "out-1", VoicePushToTalkKeybind = "LCTRL\tLSHIFT" }, worldFirst)
	T.eq(#calls, 0)
	-- Outside danger mode nothing is kept, or set.
	EverySetting.SetDanger(false)
	T.ok(not EverySetting.IsStored("VoiceOutputDevice"))
	T.eq(EverySetting.Set("VoiceOutputDevice", "out-1"), nil)
	T.eq(#calls, 0)
end)

T.test("setters: a device's row has a menu of the devices the game offers now", function()
	local EverySetting, o, inputs = Start()
	EverySetting_OpenOptions()
	local row = RowFor(o, "VoiceInputDevice")
	T.ok(row.dropdown:IsShown() and row.box:IsShown() and row.command:IsShown(), "a menu, a box and the command")
	T.eq(row.dropdown.label:GetText(), "Default System Device", "the system's own, with the CVar empty")
	W.Run(row.dropdown, "OnClick")
	T.eq(Menu(), "Desk microphone, Default System Device, Default Communication Device")
	W.Run(row.dropdown, "OnClick")
	table.insert(inputs, 1, { deviceID = "in-2", displayName = "Webcam" })
	W.Run(row.dropdown, "OnClick")
	T.eq(Menu(), "Webcam, Desk microphone, Default System Device, Default Communication Device", "built again each time it's opened")
	W.Run(MenuItem("in-2"), "OnClick")
	T.eq(row.dropdown.label:GetText(), "Webcam", "by its name, before the game has answered")
	T.eq(row.box:GetText(), "in-2", "and its ID in the box")
	T.ok(row.kept:IsShown() and row.reset:IsShown())
	W.Advance(1)
	T.eq(Get("VoiceInputDevice"), "in-2")
	T.eq(row.dropdown.label:GetText(), "Webcam")
	table.remove(inputs, 1)
	EverySetting.Changed()
	T.eq(row.dropdown.label:GetText(), "Custom (in-2)", "a device that's gone")
	W.Run(row.command, "OnClick")
	T.eq(o.refs.dialog.body:GetText(), '/run C_VoiceChat.SetInputDevice("in-2")')
	T.ok(o.refs.dialog.text:GetText():find("doesn't keep a value set this way", 1, true), "which the game takes")
	W.Run(o.refs.dialog.cancel, "OnClick")
	W.Run(row.reset, "OnClick")
	W.Advance(1)
	T.eq(Get("VoiceInputDevice"), "")
	T.eq(row.dropdown.label:GetText(), "Default System Device")
	-- The key's row is a box.
	local key = RowFor(o, "VoicePushToTalkKeybind")
	T.ok(key.box:IsShown() and not key.dropdown:IsShown())
	key.box:SetFocus()
	key.box:SetText("LALT")
	W.Run(key.box, "OnEnterPressed")
	T.eq(Get("VoicePushToTalkKeybind"), "LALT")
	W.Run(key.command, "OnClick")
	T.eq(o.refs.dialog.body:GetText(), '/run C_VoiceChat.SetPushToTalkBinding({"LALT"})')
	W.Run(o.refs.dialog.cancel, "OnClick")
	-- The game keeps two keys with a tab between them, which its font can't draw.
	key.box:SetFocus()
	key.box:SetText("LCTRL LSHIFT")
	W.Run(key.box, "OnEnterPressed")
	T.eq(Get("VoicePushToTalkKeybind"), "LCTRL\tLSHIFT")
	T.eq(key.box:GetText(), "LCTRL LSHIFT", "shown with a space")
	W.Run(key.command, "OnClick")
	T.eq(o.refs.dialog.body:GetText(), '/run C_VoiceChat.SetPushToTalkBinding({"LCTRL", "LSHIFT"})')
end)

T.test("setters: a client with no voice functions has an empty menu, and says the game didn't take it", function()
	local EverySetting, o = Start()
	_G.C_VoiceChat = nil
	EverySetting_OpenOptions()
	local row = RowFor(o, "VoiceInputDevice")
	T.eq(row.dropdown.label:GetText(), "Custom ()")
	W.Run(row.dropdown, "OnClick")
	T.eq(Menu(), "")
	W.chat = {}
	T.eq(EverySetting.Set("VoiceInputDevice", "in-1", true), nil)
	T.ok(W.chat[1]:find('/run C_VoiceChat.SetInputDevice("in-1")', 1, true), W.chat[1])
end)

-------------------------------------------------------------------------------
-- Settings the game's function takes whole: the group finder's roles and its
-- advanced filter, the wardrobe's checkboxes and the pet journal's sort.
-------------------------------------------------------------------------------

local ROLES, PVP, FILTER, RATING = "lfgSelectedRoles", "pvpSelectedRoles", "lfgListAdvancedFilters", "lfgListAdvancedFilterMinRating"

local FIELDS = { "needsTank", "needsHealer", "needsDamage", "needsMyClass", "hasTank", "hasHealer",
	"difficultyNormal", "difficultyHeroic", "difficultyMythic", "difficultyMythicPlus",
	"generalPlaystyle1", "generalPlaystyle2", "generalPlaystyle3", "generalPlaystyle4" }

-- Flags packed as the game packs them: "\002", then a byte for every six.
local function Pack(on)
	local bytes, last = { "\002" }, 0
	for i in pairs(on) do last = math.max(last, i) end
	for at = 1, math.ceil(last / 6) do
		local byte = 64
		for bit = 0, 5 do
			if on[(at - 1) * 6 + bit + 1] then byte = byte + 2 ^ bit end
		end
		bytes[#bytes + 1] = string.char(byte)
	end
	return table.concat(bytes)
end

-- The game's functions for them, as the 1.60.1 client has them: each changes its
-- CVar within the call, and nothing else will.
local filter -- the advanced filter as the game keeps it
local function Whole()
	calls = {}
	local function Bits(cvar, ...)
		local bits = { ... }
		return function(...)
			calls[#calls + 1] = { cvar, { ... } }
			local n = 0
			for i, on in ipairs({ ... }) do
				if on then n = n + bits[i] end
			end
			W.cvars[cvar:lower()].value = tostring(n)
		end
	end
	_G.SetLFGRoles = Bits(ROLES, 1, 2, 4, 8)
	_G.SetPVPRoles = Bits(PVP, 2, 4, 8)
	filter = { activities = { 285 }, minimumRating = 0 }
	for _, field in ipairs(FIELDS) do filter[field] = false end
	_G.C_LFGList = {
		GetAdvancedFilter = function()
			local copy = {}
			for k, v in pairs(filter) do copy[k] = v end
			return copy
		end,
		SaveAdvancedFilter = function(options)
			calls[#calls + 1] = { "SaveAdvancedFilter", options }
			filter = options
			local on = {}
			for i, field in ipairs(FIELDS) do on[i] = options[field] or nil end
			W.cvars[FILTER:lower()].value = Pack(on)
			W.cvars[RATING:lower()].value = tostring(options.minimumRating)
		end,
	}
	local function Shown(cvar)
		return function(shown)
			calls[#calls + 1] = { cvar, { shown } }
			W.cvars[cvar:lower()].value = shown and "1" or "0"
		end
	end
	_G.C_TransmogCollection = {
		SetCollectedShown = Shown("wardrobeShowCollected"),
		SetUncollectedShown = Shown("wardrobeShowUncollected"),
	}
	_G.C_PetJournal = {
		SetPetSortParameter = function(parameter)
			calls[#calls + 1] = { "petJournalSort", { parameter } }
			W.cvars.petjournalsort.value = tostring(parameter - 1)
		end,
	}
end

-- A logged-in client in danger mode with these CVars, each with its line from
-- CVars.lua. `saved` is last session's saved variables, and `values` what the
-- CVars have as the client starts.
local WHOLE = { ROLES, PVP, FILTER, RATING, "petJournalSort", "wardrobeShowCollected", "wardrobeShowUncollected" }
local function StartWhole(saved, values)
	_G.SetLFGRoles, _G.SetPVPRoles, _G.C_LFGList, _G.C_TransmogCollection, _G.C_PetJournal = nil, nil, nil, nil, nil
	saved = saved or {}
	saved.danger = true
	local EverySetting, ns = W.Load(saved)
	for _, cvar in ipairs(WHOLE) do W.AddCVar(cvar, "0", { locked = true }) end
	W.cvars.wardrobeshowcollected.value, W.cvars.wardrobeshowcollected.default = "1", "1"
	for cvar, value in pairs(values or {}) do W.cvars[cvar:lower()].value = value end
	EverySetting.GROUPS = {}
	Whole()
	W.Login()
	EverySetting.AllGroups()
	return EverySetting, ns.Options
end

-- The arguments of the last call to the game's function for `cvar`, as "a, b".
local function Args(cvar)
	for i = #calls, 1, -1 do
		if calls[i][1] == cvar then
			local args = {}
			for j, arg in ipairs(calls[i][2]) do args[j] = tostring(arg) end
			return table.concat(args, ", ")
		end
	end
end

-- Runs a command as the game's chat would: the Lua after /run.
local function Type(command)
	assert((loadstring or load)(assert(command:match("^/run (.*)$"), command)))()
end

T.test("setters: the roles are a menu of ticks, each one set through the game's function with the rest", function()
	local EverySetting = StartWhole()
	local knob = EverySetting.Knob(ROLES)
	T.eq(knob.type, "flags", "a menu of ticks")
	T.eq(knob.setter, true)
	T.eq(EverySetting.SetFlag(ROLES, 2, true), "2", "tank: kept as the game has it")
	T.eq(Args(ROLES), "false, true, false, false", "leader, tank, healer, damage")
	T.eq(EverySetting.SetFlag(ROLES, 3, true), "6")
	T.eq(Args(ROLES), "false, true, true, false", "the others as they are")
	T.eq(EverySetting.SetFlag(ROLES, 1, true), "7")
	T.eq(EverySetting.SetFlag(ROLES, 2, false), "5")
	T.eq(W.SetCount(ROLES) + #W.flagSets, 0, "neither SetCVar nor SetCVarBitfield is tried")
	T.ok(EverySetting.IsStored(ROLES))
	T.eq(EverySetting.Before(ROLES), "0")
	T.ok(EverySetting.Undo())
	T.eq(C_CVar.GetCVar(ROLES), "7", "Undo goes through the function")
	T.eq(Args(ROLES), "true, true, true, false")
	EverySetting.Reset(ROLES)
	T.eq(C_CVar.GetCVar(ROLES), "0", "and Reset")
	T.eq(Args(ROLES), "false, false, false, false")
	T.ok(not EverySetting.IsStored(ROLES))
	T.eq(EverySetting.Set(ROLES, "10"), "10", "the whole value, as an import or a profile has it")
	T.eq(Args(ROLES), "false, true, false, true")
	-- The battlegrounds' roles have no leader.
	T.eq(EverySetting.SetFlag(PVP, 3, true), "4", "healer")
	T.eq(Args(PVP), "false, true, false", "tank, healer, damage")
	T.eq(EverySetting.SetFlag(PVP, 4, true), "12")
	T.eq(Args(PVP), "false, true, true")
	T.eq(EverySetting.Command(ROLES, "6"), "/run SetLFGRoles(false, true, true, false)", "a global function, by its name")
	T.eq(EverySetting.Command(PVP, "12"), "/run SetPVPRoles(false, true, true)")
	T.eq(EverySetting.Command(PVP, "tank"), '/run SetCVar("pvpSelectedRoles", "tank")', "not a number: no roles")
end)

T.test("setters: a role's row shows the roles ticked, and its command", function()
	local EverySetting, o = StartWhole(nil, { [ROLES] = "6" })
	EverySetting_OpenOptions()
	o.refs.search:SetText(ROLES)
	local row = RowFor(o, ROLES)
	T.ok(row.dropdown:IsShown() and not row.box:IsShown() and row.command:IsShown(), "a menu of ticks and the command, no box")
	T.eq(row.dropdown.label:GetText(), "Tank, Healer")
	W.Run(row.dropdown, "OnClick")
	T.eq(Menu(), "Leader, Tank, Healer, Damage")
	T.ok(MenuItem(2).active and MenuItem(3).active and not MenuItem(1).active)
	W.Run(MenuItem(4), "OnClick")
	T.eq(C_CVar.GetCVar(ROLES), "14")
	T.ok(MenuItem(4).active, "ticked, and the menu stays open")
	T.eq(row.dropdown.label:GetText(), "Tank, Healer, Damage")
	T.ok(row.kept:IsShown() and row.reset:IsShown())
	W.Run(row.command, "OnClick")
	T.eq(o.refs.dialog.body:GetText(), "/run SetLFGRoles(false, true, true, true)")
	T.ok(o.refs.dialog.text:GetText():find("doesn't keep a value set this way", 1, true), "which the game takes")
	W.Run(o.refs.dialog.cancel, "OnClick")
	W.Run(row.reset, "OnClick")
	T.eq(C_CVar.GetCVar(ROLES), "6")
	T.eq(row.dropdown.label:GetText(), "Tank, Healer")
	Type(EverySetting.Command(ROLES, "9"))
	T.eq(C_CVar.GetCVar(ROLES), "9", "the command sets what it says")
end)

T.test("setters: the advanced filter goes to the game as its table, with only its flags changed", function()
	local EverySetting = StartWhole()
	T.eq(EverySetting.Knob(FILTER).type, "flags")
	filter.minimumRating, filter.activities = 1200, { 285, 301 }
	T.eq(EverySetting.SetFlag(FILTER, 1, true), "\002A", "needs a tank: packed, as the game has it")
	local options = calls[#calls][2]
	T.eq(options.needsTank, true)
	T.eq(options.hasTank, false)
	T.eq(options.minimumRating, 1200, "the rest of the table as the game had it")
	T.eq(table.concat(options.activities, " "), "285 301")
	T.eq(EverySetting.SetFlag(FILTER, 7, true), "\002AA", "normal difficulty, the seventh")
	T.eq(calls[#calls][2].difficultyNormal, true)
	T.eq(calls[#calls][2].needsTank, true)
	T.eq(EverySetting.SetFlag(FILTER, 1, false), "\002@A")
	T.eq(W.SetCount(FILTER) + #W.flagSets, 0)
	T.ok(EverySetting.Undo())
	T.eq(C_CVar.GetCVar(FILTER), "\002AA")
	EverySetting.Reset(FILTER)
	T.eq(C_CVar.GetCVar(FILTER), "\002", "Reset: none of them, as at first")
	T.eq(calls[#calls][2].needsTank, false)
	-- The minimum rating goes in the same table.
	T.eq(EverySetting.Set(RATING, "1500", true), "1500")
	T.eq(calls[#calls][2].minimumRating, 1500)
	T.eq(C_CVar.GetCVar(FILTER), "\002", "the flags as they were")
	T.eq(EverySetting.Set(RATING, "lots", true), nil, "a number only")
	-- The commands: the game's table, changed and saved.
	local command = EverySetting.Command(FILTER, "\002AA")
	T.eq(command, "/run local f=C_LFGList.GetAdvancedFilter() for k,v in pairs(f) do f[k]=v~=true and v end"
		.. " f.needsTank=true f.difficultyNormal=true C_LFGList.SaveAdvancedFilter(f)")
	filter.hasHealer = true
	Type(command)
	T.eq(C_CVar.GetCVar(FILTER), "\002AA", "every other flag off")
	T.eq(C_CVar.GetCVar(RATING), "1500", "and the rating as it was")
	T.eq(EverySetting.Command(RATING, "1800"), "/run local f=C_LFGList.GetAdvancedFilter() f.minimumRating=1800 C_LFGList.SaveAdvancedFilter(f)")
	Type(EverySetting.Command(RATING, "1800"))
	T.eq(C_CVar.GetCVar(RATING), "1800")
	T.eq(C_CVar.GetCVar(FILTER), "\002AA")
	_G.C_LFGList = nil
	T.eq(EverySetting.Command(FILTER, "\002A"), '/run SetCVar("lfgListAdvancedFilters", "\002A")', "a client without the function")
end)

T.test("setters: the wardrobe's checkboxes and the pet journal's sort go through the game's functions", function()
	local EverySetting = StartWhole()
	local knob = EverySetting.Knob("wardrobeShowUncollected")
	T.eq(knob.type, "toggle")
	T.eq(EverySetting.Set("wardrobeShowUncollected", true), "1")
	T.eq(Args("wardrobeShowUncollected"), "true")
	T.eq(EverySetting.Set("wardrobeShowCollected", false), "0")
	T.eq(Args("wardrobeShowCollected"), "false")
	T.eq(EverySetting.Command("wardrobeShowUncollected", "1"), "/run C_TransmogCollection.SetUncollectedShown(true)")
	EverySetting.Reset("wardrobeShowUncollected")
	T.eq(C_CVar.GetCVar("wardrobeShowUncollected"), "0")
	T.eq(EverySetting.Knob("petJournalSort").type, "choice")
	T.eq(EverySetting.Set("petJournalSort", "2"), "2", "rarity")
	T.eq(Args("petJournalSort"), "3", "the game counts its sorts from 1")
	T.eq(EverySetting.Command("petJournalSort", "2"), "/run C_PetJournal.SetPetSortParameter(3)")
	T.eq(W.SetCount("petJournalSort") + W.SetCount("wardrobeShowCollected") + W.SetCount("wardrobeShowUncollected"), 0)
end)

T.test("setters: a value kept for each is set again at login, through the game's function", function()
	local kept = { profiles = { Default = { [ROLES] = "6", [FILTER] = "\002A", wardrobeShowUncollected = "1" } },
		before = { [ROLES] = "0", [FILTER] = "\002", wardrobeShowUncollected = "0" } }
	StartWhole(kept, { [FILTER] = "\002" })
	T.eq(C_CVar.GetCVar(ROLES), "6")
	T.eq(C_CVar.GetCVar(FILTER), "\002A")
	T.eq(C_CVar.GetCVar("wardrobeShowUncollected"), "1")
	T.eq(#calls, 3, "a call each")
	T.eq(W.SetCount(ROLES) + W.SetCount(FILTER) + W.SetCount("wardrobeShowUncollected"), 0)
end)

-------------------------------------------------------------------------------
-- Flags the game sets one at a time: the journals' filters and guild news.
-------------------------------------------------------------------------------

local SOURCES, TOYS, GUILD, MOUNTS, PETS = "wardrobeSourceFilters", "toyBoxCollectedFilters", "guildNewsFilter",
	"mountJournalSourcesFilter", "petJournalSourceFilters"
local JOURNALS = { "guildNewsFilter", "heirloomCollectedFilters", "heirloomSourceFilters", "mountJournalGeneralFilters",
	"mountJournalSourcesFilter", "mountJournalTypeFilter", "petJournalFilters", "petJournalSourceFilters", "petJournalTypeFilters",
	"toyBoxCollectedFilters", "toyBoxExpansionFilters", "toyBoxSourceFilters", "transmogrifySetsFilters", "wardrobeSetsFilters",
	"wardrobeSourceFilters" }
-- How the 1.60.1 client keeps them, as it was seen to: the ones that keep their flags as the
-- bits of a number, with a bit for each filter that's ticked (the rest have a flag for each
-- one that's off), and what the game means by 0 where that isn't no flag on.
local NUMBERS = { guildNewsFilter = true, mountJournalGeneralFilters = true, mountJournalSourcesFilter = true,
	mountJournalTypeFilter = true, petJournalSourceFilters = true, petJournalTypeFilters = true }
local TICKED = { mountJournalGeneralFilters = true, mountJournalSourcesFilter = true, mountJournalTypeFilter = true,
	petJournalSourceFilters = true, petJournalTypeFilters = true }
local ZERO = { mountJournalGeneralFilters = "1", mountJournalSourcesFilter = "260", mountJournalTypeFilter = "31",
	petJournalSourceFilters = "4095", petJournalTypeFilters = "1023", petJournalFilters = "\002B" }
local ALL = { petJournalSourceFilters = 4095, petJournalTypeFilters = 1023 } -- written as 0

-- The flags on in a value as the game keeps it: packed, or the bits of a number.
local function FlagsOn(value)
	local on, n = {}, tonumber(value)
	if n then
		for i = 1, 30 do
			if math.floor(n / 2 ^ (i - 1)) % 2 == 1 then on[i] = true end
		end
		return on
	end
	for at = 2, #value do
		for bit = 0, 5 do
			if math.floor(value:byte(at) / 2 ^ bit) % 2 == 1 then on[(at - 2) * 6 + bit + 1] = true end
		end
	end
	return on
end

-- Sets flag `flag` of `cvar` as the game's functions do.
local function Put(cvar, flag, on)
	local value = W.cvars[cvar:lower()].value
	local flags = FlagsOn(value == "0" and ZERO[cvar] or value)
	flags[flag] = on or nil
	local n = 0
	for i in pairs(flags) do n = n + 2 ^ (i - 1) end
	if n == ALL[cvar] then n = 0 end
	W.cvars[cvar:lower()].value = NUMBERS[cvar] and ("%d"):format(n) or Pack(flags)
end

-- The game's function for a flag of `cvar`: it changes the CVar within the call. `flags`
-- maps the game's index to the flag, where they differ.
local function OneFlag(cvar, flags)
	return function(index, checked)
		calls[#calls + 1] = { cvar, { index, checked } }
		local on = checked == true or checked == 1
		if not TICKED[cvar] then on = not on end
		Put(cvar, flags and flags[index] or index, on)
	end
end
-- One of the toy box's or the heirlooms' functions, for flag `flag` alone.
local function Shown(cvar, flag, name)
	return function(shown)
		calls[#calls + 1] = { cvar, { shown }, name = name }
		Put(cvar, flag, not shown)
	end
end

local function Journals()
	calls = {}
	_G.C_MountJournal = { SetCollectedFilterSetting = OneFlag("mountJournalGeneralFilters"), SetSourceFilter = OneFlag(MOUNTS),
		SetTypeFilter = OneFlag("mountJournalTypeFilter") }
	_G.C_PetJournal = { SetFilterChecked = OneFlag("petJournalFilters"), SetPetSourceChecked = OneFlag(PETS),
		SetPetTypeFilter = OneFlag("petJournalTypeFilters") }
	_G.C_ToyBox = { SetCollectedShown = Shown(TOYS, 1, "SetCollectedShown"), SetUncollectedShown = Shown(TOYS, 2, "SetUncollectedShown"),
		SetUnusableShown = Shown(TOYS, 3, "SetUnusableShown"), SetSourceTypeFilter = OneFlag("toyBoxSourceFilters"),
		SetExpansionTypeFilter = OneFlag("toyBoxExpansionFilters") }
	_G.C_Heirloom = { SetCollectedHeirloomFilter = Shown("heirloomCollectedFilters", 1, "SetCollectedHeirloomFilter"),
		SetUncollectedHeirloomFilter = Shown("heirloomCollectedFilters", 2, "SetUncollectedHeirloomFilter"),
		SetHeirloomSourceFilter = OneFlag("heirloomSourceFilters") }
	_G.C_TransmogCollection = { SetSourceTypeFilter = OneFlag(SOURCES, { 2, 3, 4, 5, 8, 9 }) }
	_G.C_TransmogSets = { SetBaseSetsFilter = OneFlag("wardrobeSetsFilters"), SetSetsFilter = OneFlag("transmogrifySetsFilters") }
	_G.SetGuildNewsFilter = OneFlag(GUILD)
end

-- A logged-in client in danger mode with these CVars, each with its line from CVars.lua
-- and the default 0. `saved` is last session's saved variables, and `values` what the
-- CVars have as the client starts.
local function StartJournals(saved, values)
	saved = saved or {}
	saved.danger = true
	local EverySetting, ns = W.Load(saved)
	for _, cvar in ipairs(JOURNALS) do W.AddCVar(cvar, "0", { locked = true }) end
	for cvar, value in pairs(values or {}) do W.cvars[cvar:lower()].value = value end
	EverySetting.GROUPS = {}
	Journals()
	W.Login()
	EverySetting.AllGroups()
	return EverySetting, ns.Options
end

-- How many calls were made to the game's functions for `cvar`.
local function Calls(cvar)
	local count = 0
	for _, call in ipairs(calls) do
		if call[1] == cvar then count = count + 1 end
	end
	return count
end

T.test("setters: a journal's filter is a menu of the game's ticks, each set through the game's function for that flag", function()
	local EverySetting = StartJournals()
	local knob = EverySetting.Knob(SOURCES)
	T.eq(knob.type, "flags", "a menu of ticks")
	T.eq(knob.setter, true)
	T.eq(knob.options[1][2], "Boss Drop", "the game's own words")
	T.ok(EverySetting.Flag("0", knob.options[1][1]), "each source is ticked while it's shown, as in the game's menu")
	T.eq(EverySetting.SetFlag(SOURCES, -2, false), "\002B", "Boss Drop hidden: kept as the game has it")
	T.eq(Args(SOURCES), "1, false", "the game's first source is flag 2")
	T.eq(EverySetting.SetFlag(SOURCES, -9, false), "\002BD", "Profession, flag 9")
	T.eq(Args(SOURCES), "6, false", "the game's sixth")
	T.eq(EverySetting.SetFlag(SOURCES, -2, true), "\002@D")
	T.eq(Args(SOURCES), "1, true")
	T.eq(#calls, 3, "a call for each flag changed, and no other")
	T.eq(W.SetCount(SOURCES) + #W.flagSets, 0, "neither SetCVar nor SetCVarBitfield is tried")
	T.ok(EverySetting.IsStored(SOURCES))
	T.eq(EverySetting.Before(SOURCES), "0")
	T.ok(EverySetting.Undo())
	T.eq(C_CVar.GetCVar(SOURCES), "\002BD", "Undo goes through the function")
	T.eq(Args(SOURCES), "1, false")
	T.eq(#calls, 4)
	EverySetting.Reset(SOURCES)
	T.eq(C_CVar.GetCVar(SOURCES), "\002", "Reset: every source shown again, packed as the game packs it")
	T.eq(#calls, 6, "a call for each of the two flags on")
	T.ok(not EverySetting.IsStored(SOURCES))
	-- The whole value, as a profile has it: Boss Drop, Quest and Vendor hidden.
	T.eq(EverySetting.Set(SOURCES, "\002N"), "\002N")
	T.eq(#calls, 9)
end)

T.test("setters: the toy box and the heirlooms have a function for each of their flags", function()
	local EverySetting = StartJournals(nil, { [TOYS] = "\002B" })
	T.eq(EverySetting.SetFlag(TOYS, -2, true), "\002", "not collected shown")
	T.eq(calls[#calls].name, "SetUncollectedShown")
	T.eq(Args(TOYS), "true")
	T.eq(EverySetting.SetFlag(TOYS, -3, false), "\002D", "unusable hidden")
	T.eq(calls[#calls].name, "SetUnusableShown")
	T.eq(Args(TOYS), "false")
	T.eq(EverySetting.Set(TOYS, "\002A"), "\002A", "collected hidden, and unusable shown")
	T.eq(#calls, 4)
	T.eq(EverySetting.SetFlag("heirloomCollectedFilters", -1, false), "\002A")
	T.eq(calls[#calls].name, "SetCollectedHeirloomFilter")
	T.eq(EverySetting.Command(TOYS, "\002B"),
		"/run local t=C_ToyBox t.SetCollectedShown(true) t.SetUncollectedShown(false) t.SetUnusableShown(true)")
end)

T.test("setters: guild news keeps its filters that are off as the bits of a number, and takes 1 or 0", function()
	local EverySetting = StartJournals()
	T.eq(EverySetting.SetFlag(GUILD, -2, false), "2", "members' achievements off")
	T.eq(Args(GUILD), "2, 0")
	T.eq(EverySetting.SetFlag(GUILD, -9, false), "258", "legendary items looted, the ninth")
	T.eq(Args(GUILD), "9, 0")
	EverySetting.Reset(GUILD)
	T.eq(C_CVar.GetCVar(GUILD), "0")
	T.eq(Args(GUILD), "9, 1")
	T.eq(EverySetting.Command(GUILD, "2"), "/run local f=SetGuildNewsFilter f(1,1) f(2,0) f(3,1) f(4,1) f(5,1) f(6,1) f(9,1)")
end)

T.test("setters: the mount and pet journals' 0 is the game's defaults, read as the filters it ticks", function()
	local EverySetting = StartJournals()
	-- The mount journal's sources: a bit for each ticked, and 0 until one is changed.
	T.eq(EverySetting.Get(MOUNTS), "260", "Vendor and Trading Card Game, the two this client has")
	T.eq(EverySetting.Knob(MOUNTS).default, "260")
	T.eq(EverySetting.SetFlag(MOUNTS, 3, false), "256")
	T.eq(Args(MOUNTS), "3, false")
	T.eq(EverySetting.Before(MOUNTS), "260")
	EverySetting.Reset(MOUNTS)
	T.eq(C_CVar.GetCVar(MOUNTS), "260", "the game writes them out once one is changed")
	T.eq(EverySetting.Get(MOUNTS), "260")
	T.eq(EverySetting.Get("mountJournalGeneralFilters"), "1", "collected only")
	T.eq(EverySetting.Get("mountJournalTypeFilter"), "31")
	-- The pet journal's sources are 0 again whenever every one is ticked.
	T.eq(EverySetting.Get(PETS), "4095")
	T.eq(EverySetting.SetFlag(PETS, 1, false), "4094")
	T.eq(EverySetting.SetFlag(PETS, 1, true), "4095", "0 to the game, and all twelve ticked")
	T.eq(C_CVar.GetCVar(PETS), "0")
	T.eq(EverySetting.Get("petJournalFilters"), "\002B", "not collected hidden")
	-- A value kept for one is set again at login only where it differs from what 0 means.
	StartJournals({ profiles = { Default = { [MOUNTS] = "260", [PETS] = "4094" } }, before = { [MOUNTS] = "260", [PETS] = "4095" } })
	T.eq(Calls(MOUNTS), 0)
	T.eq(Calls(PETS), 1)
	T.eq(C_CVar.GetCVar(PETS), "4094")
end)

T.test("setters: 0, nothing and \\002 all have no flag on, and the game's own default isn't turned down", function()
	local EverySetting = StartJournals(nil, { [TOYS] = "\002" })
	W.chat = {}
	T.eq(EverySetting.Set(TOYS, "0"), "\002", "the same flags: kept as the game has it")
	T.eq(EverySetting.Set(SOURCES, "\002"), "0")
	T.eq(EverySetting.Set(SOURCES, ""), "0")
	T.eq(#calls, 0, "nothing to call")
	T.eq(#W.chat, 0, "and nothing said")
	-- From 0, one flag packs as the game packs it.
	T.eq(EverySetting.SetFlag(SOURCES, -3, false), "\002D")
	-- A flag the game doesn't change is turned down, with the command to try.
	_G.C_TransmogCollection.SetSourceTypeFilter = function() end
	T.eq(EverySetting.SetFlag(SOURCES, -4, false), nil)
	T.ok(W.chat[1]:find("didn't take", 1, true) and W.chat[1]:find("f(3,false)", 1, true), W.chat[1])
	T.eq(C_CVar.GetCVar(SOURCES), "\002D")
	T.eq(EverySetting.Get(SOURCES), "\002D", "kept as it was")
end)

T.test("setters: a value kept for a journal's filter is set again at login, a call for each flag that differs", function()
	local kept = { profiles = { Default = { [SOURCES] = "\002BD", [GUILD] = "5", [TOYS] = "\002" } },
		before = { [SOURCES] = "0", [GUILD] = "0", [TOYS] = "\002B" } }
	StartJournals(kept, { [SOURCES] = "\002B", [TOYS] = "0" })
	T.eq(C_CVar.GetCVar(SOURCES), "\002BD")
	T.eq(C_CVar.GetCVar(GUILD), "5")
	T.eq(Calls(SOURCES), 1, "Profession: Boss Drop was hidden already")
	T.eq(Calls(GUILD), 2)
	T.eq(Calls(TOYS), 0, "0 has no flag on either")
	T.eq(W.SetCount(SOURCES) + W.SetCount(GUILD) + W.SetCount(TOYS), 0)
end)

T.test("setters: each journal's command is one line of chat, and sets what it says", function()
	local EverySetting = StartJournals()
	T.eq(EverySetting.Command(SOURCES, "\002B"),
		"/run local f=C_TransmogCollection.SetSourceTypeFilter f(1,false) f(2,true) f(3,true) f(4,true) f(5,true) f(6,true)")
	T.eq(EverySetting.Command(MOUNTS, "4"), "/run local f=C_MountJournal.SetSourceFilter f(3,true) f(9,false)")
	for _, cvar in ipairs(JOURNALS) do
		local knob = EverySetting.Knob(cvar)
		T.eq(knob.type, "flags", cvar)
		-- Every box ticked, and none.
		local all, none = {}, {}
		for _, option in ipairs(knob.options) do
			if option[1] > 0 then all[option[1]] = true else none[-option[1]] = true end
		end
		for _, flags in ipairs({ all, none }) do
			local n = 0
			for i in pairs(flags) do n = n + 2 ^ (i - 1) end
			local value = NUMBERS[cvar] and ("%d"):format(n) or Pack(flags)
			local command = EverySetting.Command(cvar, value)
			T.ok(#command <= 255, cvar .. "'s command is longer than chat takes: " .. #command)
			Type(command)
			-- None of the mount journal's first three ticked is 0, which the game reads as its defaults.
			local want = C_CVar.GetCVar(cvar) == "0" and ZERO[cvar] or value
			for _, option in ipairs(knob.options) do
				T.eq(EverySetting.Flag(EverySetting.Get(cvar), option[1]), EverySetting.Flag(want, option[1]), cvar .. " " .. option[2])
			end
		end
	end
end)

T.test("setters: a journal's row ticks the filters that are on, and each click is one call", function()
	local _, o = StartJournals()
	EverySetting_OpenOptions()
	o.refs.search:SetText(SOURCES)
	local row = RowFor(o, SOURCES)
	T.ok(row.dropdown:IsShown() and not row.box:IsShown() and row.command:IsShown(), "a menu of ticks and the command, no box")
	T.eq(row.dropdown.label:GetText(), "Boss Drop, Quest, Vendor, World Drop, Achievement, Profession")
	W.Run(row.dropdown, "OnClick")
	T.eq(Menu(), "Boss Drop, Quest, Vendor, World Drop, Achievement, Profession")
	T.ok(MenuItem(-2).active and MenuItem(-9).active)
	W.Run(MenuItem(-3), "OnClick")
	T.eq(C_CVar.GetCVar(SOURCES), "\002D", "Quest hidden")
	T.eq(Args(SOURCES), "2, false")
	T.ok(not MenuItem(-3).active, "unticked, and the menu stays open")
	T.eq(row.dropdown.label:GetText(), "Boss Drop, Vendor, World Drop, Achievement, Profession")
	T.ok(row.kept:IsShown() and row.reset:IsShown())
	W.Run(row.command, "OnClick")
	T.eq(o.refs.dialog.body:GetText(),
		"/run local f=C_TransmogCollection.SetSourceTypeFilter f(1,true) f(2,false) f(3,true) f(4,true) f(5,true) f(6,true)")
	W.Run(o.refs.dialog.cancel, "OnClick")
	W.Run(row.reset, "OnClick")
	T.eq(C_CVar.GetCVar(SOURCES), "\002")
	T.eq(row.dropdown.label:GetText(), "Boss Drop, Quest, Vendor, World Drop, Achievement, Profession")
	T.ok(not row.off:IsShown(), "\\002 is no flag on, as the game's default 0 is: not off its default")
	T.eq(#calls, 2)
end)

-- Settings that aren't CVars: the modified clicks, which the game keeps with its key
-- bindings. Each has a name of its own ("@click:SELFCAST"), is read and written
-- through the game's functions, and is kept, set again at login, undone and reset
-- like a CVar.

local T = ...
local W = dofile("tests/wow.lua")

local SELF, STICKY, LINK = "@click:SELFCAST", "@click:STICKYCAMERA", "@click:CHATLINK"

-- The knob Knobs.lua has for a setting.
local function Tuned(EverySetting, name)
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			if knob.cvar == name then return knob end
		end
	end
end

-- A logged-in client with view distance and three of the modified clicks, as
-- Knobs.lua has them. `saved` is last session's saved variables, `before` runs
-- before login, and `lacks` takes the game's functions away.
local function Start(saved, before, lacks)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	local clicks = {}
	for i, name in ipairs({ SELF, STICKY, LINK }) do clicks[i] = Tuned(EverySetting, name) end
	EverySetting.GROUPS = {
		{ title = "Draw distance", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100, raid = "RAIDfarclip" },
		} },
		{ title = "Modified clicks", items = clicks },
	}
	if lacks then _G.GetModifiedClick, _G.SetModifiedClick = nil, nil end
	if before then before() end
	W.Login()
	return EverySetting, ns.Options
end

-- The body of the tooltip of the row showing `name`, in the open window.
local function Tip(o, name)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == name then
			local lines = {}
			rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
			W.Run(row.name, "OnEnter")
			rawset(GameTooltip, "AddLine", nil)
			return table.concat(lines, "\n")
		end
	end
end

T.test("not cvars: a modified click is set through the game's function, and saved with the bindings", function()
	local EverySetting = Start()
	local knob = EverySetting.Knob(SELF)
	T.eq(knob.found, true)
	T.eq(knob.default, "ALT", "Bindings_Camelot.xml's")
	T.eq(knob.calls, "GetModifiedClick and SetModifiedClick")
	T.eq(knob.setter, nil, "not a locked CVar's setter")
	T.eq(EverySetting.Section(SELF), 11, "under Mouse and keyboard")
	T.eq(EverySetting.Get(SELF), "ALT")
	T.eq(EverySetting.Set(SELF, "CTRL"), "CTRL")
	T.eq(W.clicks.SELFCAST, "CTRL")
	T.eq(#W.bindingSaves, 1, "saved as the game's options save it")
	T.eq(W.bindingSaves[1], 1, "in the binding set in use")
	T.eq(W.SetCount(SELF), 0, "SetCVar isn't tried")
	T.ok(EverySetting.IsStored(SELF))
	T.eq(EverySetting.Before(SELF), "ALT")
	T.eq(EverySetting.Command(SELF, "CTRL"), '/run SetModifiedClick("SELFCAST", "CTRL") SaveBindings(GetCurrentBindingSet())')
	T.eq(EverySetting.Set(SELF, "SHIFT-BUTTON9"), nil, "only what the menu has")
	T.eq(EverySetting.Set(LINK, "ALT-BUTTON2"), "ALT-BUTTON2", "a click with a button has those too")
	W.clicks.SELFCAST = "SHIFT" -- the game's own options
	T.eq(EverySetting.Get(SELF), "SHIFT", "read from the game each time")
end)

T.test("not cvars: kept, set again at login, undone, redone and reset", function()
	local EverySetting = Start()
	EverySetting.Set(STICKY, "ALT")
	T.ok(EverySetting.Undo())
	T.eq(W.clicks.STICKYCAMERA, "CTRL", "undone")
	T.ok(not EverySetting.IsStored(STICKY))
	T.ok(EverySetting.Redo())
	T.eq(W.clicks.STICKYCAMERA, "ALT", "and done again")
	local saved = EverySettingDB

	-- The next session: the bindings came back as something else.
	EverySetting = Start(saved, function() W.clicks.STICKYCAMERA = "SHIFT" end)
	T.eq(W.clicks.STICKYCAMERA, "ALT", "set again at login")
	T.eq(EverySetting.Before(STICKY), "SHIFT", "and what it was is what Reset puts back")
	EverySetting.Reset(STICKY)
	T.eq(W.clicks.STICKYCAMERA, "SHIFT")
	T.ok(not EverySetting.IsStored(STICKY))
	EverySetting.Set(STICKY, "NONE")
	EverySetting.Reset(STICKY, true)
	T.eq(W.clicks.STICKYCAMERA, "CTRL", "or the game's default")
	EverySetting.Set(STICKY, "NONE")
	T.eq(EverySetting.ResetAll(), 1)
	T.eq(W.clicks.STICKYCAMERA, "CTRL")
end)

T.test("not cvars: a change in combat waits for it to end, and situations leave them alone", function()
	local EverySetting = Start()
	W.Combat(true)
	T.eq(EverySetting.Set(SELF, "SHIFT"), "SHIFT")
	T.eq(W.clicks.SELFCAST, "ALT", "not in combat")
	T.ok(EverySetting.IsPending(SELF))
	W.Combat(false)
	T.eq(W.clicks.SELFCAST, "SHIFT", "once it's over")

	EverySettingDB.presets.Ride = { [STICKY] = "NONE", farclip = "3000" }
	EverySetting.SetSituation("mounted", "Ride")
	W.Mount(true)
	T.eq(C_CVar.GetCVar("farclip"), "3000", "a situation sets its CVars")
	T.eq(W.clicks.STICKYCAMERA, "CTRL", "and leaves a setting that isn't one alone")
	W.Mount(false)
end)

T.test("not cvars: styles leave them out, and a saved preset carries them", function()
	local EverySetting = Start()
	for _, style in ipairs(EverySetting.STYLES) do
		T.eq(EverySetting.StylePreset(style)[SELF], nil, style.name .. " leaves the modified clicks alone")
	end
	EverySetting.Set(SELF, "CTRL")
	T.eq(EverySetting.SavePreset("Casting", { [SELF] = "CTRL" }), nil)
	EverySetting.Reset(SELF)
	EverySetting.ApplyPreset(EverySetting.GetPresets().Casting)
	T.eq(W.clicks.SELFCAST, "CTRL", "applied")
	T.ok(EverySetting.IsStored(SELF))
	EverySetting.SetLocked(SELF, true)
	EverySetting.Reset(SELF)
	EverySetting.ApplyPreset(EverySetting.GetPresets().Casting)
	T.eq(W.clicks.SELFCAST, "ALT", "but not to one that's locked")
end)

T.test("not cvars: a shared string carries them, as version 2, older strings still import, and /console lines leave them out", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	T.eq(EverySetting.ExportProfile(), "EverySetting:1:farclip=5000", "CVars alone: version 1, which older versions read")
	EverySetting.Set(SELF, "CTRL")
	EverySetting.Set(LINK, "ALT-BUTTON1")
	local text = EverySetting.ExportProfile()
	T.eq(text, "EverySetting:2:%40click%3ACHATLINK=ALT-BUTTON1,%40click%3ASELFCAST=CTRL,farclip=5000")
	T.eq(EverySetting.ExportLines(), "/console farclip 5000", "/console can't set them, so the lines leave them out")
	EverySetting.ResetAll()
	T.eq(EverySetting.ImportProfile("Theirs", text), nil)
	T.eq(W.clicks.SELFCAST, "CTRL", "imported")
	T.eq(W.clicks.CHATLINK, "ALT-BUTTON1")
	T.eq(C_CVar.GetCVar("farclip"), "5000")
	T.eq(EverySetting.ImportProfile("Old", "EverySetting:1:farclip=7000"), nil, "a string from before")
	T.eq(C_CVar.GetCVar("farclip"), "7000")
	T.eq(EverySetting.ImportProfile("Newer", "EverySetting:3:farclip=7000"),
		"That profile is from a newer version of Every Setting. Update Every Setting to import it.")
	T.eq(EverySetting.ImportProfile("Bad", "EverySetting:2:%40click%3ASELFCAST=HYPER"), "That profile string is empty or damaged.",
		"a value the menu doesn't have is left out")
end)

T.test("not cvars: a client without the game's functions has none of them", function()
	local EverySetting = Start(nil, nil, true)
	local knob = EverySetting.Knob(SELF)
	T.eq(knob.found, false)
	T.eq(EverySetting.Get(SELF), nil)
	T.eq(EverySetting.Set(SELF, "CTRL"), nil)
	T.eq(EverySetting.ImportProfile("Theirs", "EverySetting:2:%40click%3ASELFCAST=CTRL,farclip=5000"), nil)
	T.ok(not EverySetting.IsStored(SELF), "an import leaves it out")
end)

T.test("not cvars: the window lists them under Mouse and keyboard, and says they aren't CVars", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	o.refs.search:SetText("sticky")
	local tip = Tip(o, STICKY)
	T.ok(tip, "found by the search")
	T.ok(tip:find("Not a CVar: the game's GetModifiedClick and SetModifiedClick. The game saves it with your key bindings", 1, true), tip)
	T.ok(not tip:find("CVar: @", 1, true), "no CVar's name")
	T.ok(tip:find("Now: |cffffffffCtrl|r    Game default: |cffffffffCtrl|r", 1, true), tip)
	T.ok(tip:find("a change made in combat waits until combat ends", 1, true), tip)
	local header
	for _, item in ipairs(o.view) do
		if item.knob and item.knob.cvar == STICKY then header = item.section.title end
	end
	T.eq(header, "Mouse and keyboard")
	W.clicks.STICKYCAMERA = "ALT" -- changed in the game's options, with no event
	EverySettingOptions:Hide()
	EverySetting_OpenOptions()
	T.ok(Tip(o, STICKY):find("Now: |cffffffffAlt|r", 1, true), "read again as the window opens")
end)

T.test("not cvars: /every check leaves them out", function()
	local EverySetting = Start()
	W.Slash("check")
	for _, r in ipairs(EverySettingDB.check) do T.ok(not r.cvar:find("^@"), r.cvar .. " was probed") end
	T.eq(W.SetCount(SELF), 0)
	T.eq(EverySetting.Get(SELF), "ALT")
end)

-- A logged-in client with the real Knobs.lua's settings that aren't CVars.
local function StartAll(saved, before)
	local EverySetting, ns = W.Load(saved)
	if before then before() end
	W.Login()
	return EverySetting, ns.Options
end

T.test("not cvars: an action bar is set with the other six as they are, and shows at the next reload", function()
	local EverySetting = StartAll()
	W.bars[4] = true -- bar 5, on already
	T.eq(EverySetting.Get("@bar:2"), "0")
	T.eq(EverySetting.Set("@bar:2", true), "1")
	T.eq(table.concat({ tostring(W.bars[1]), tostring(W.bars[2]), tostring(W.bars[4]) }, " "), "true false true", "bar 5 stays on")
	T.eq(EverySetting.restart.reload, true, "the window says a reload shows it")
	EverySetting.Set("@bar:3", true)
	T.eq(tostring(W.bars[1]) .. " " .. tostring(W.bars[2]), "true true", "one after another")
	T.ok(EverySetting.Undo())
	T.eq(W.bars[2], false)
	T.eq(W.bars[1], true)
end)

T.test("not cvars: an item quality colour is an override, and the game's own colour removes it", function()
	local EverySetting = StartAll()
	local knob = EverySetting.Knob("@color:Poor")
	T.eq(knob.type, "color")
	T.eq(knob.default, "FF9D9D9D", "the game's default, asked as it runs")
	T.eq(EverySetting.Get("@color:Poor"), "FF9D9D9D")
	T.eq(EverySetting.Set("@color:Poor", "ff00ff"), "FFFF00FF")
	T.eq(W.overrides[0], "ffff00ff")
	EverySetting.Reset("@color:Poor")
	T.eq(W.overrides[0], nil, "back to the game's: no override")
	EverySetting.Set("@color:Rare", "FF112233")
	EverySetting.Set("@color:Rare", "FF0070DD")
	T.eq(W.overrides[3], nil, "picking the game's own colour removes the override")
end)

T.test("not cvars: guild invites and location read back late, and are shown as set meanwhile", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.Set("@social:BlockGuildInvites", true), "1", "kept as set, though the game reads back the old value")
	T.eq(GetAutoDeclineGuildInvites(), false, "the server hasn't answered")
	T.eq(EverySetting.Get("@social:BlockGuildInvites"), "1")
	W.Advance(1)
	T.eq(GetAutoDeclineGuildInvites(), true)
	W.Advance(3)
	T.eq(EverySetting.Get("@social:BlockGuildInvites"), "1", "the game's answer")
	T.eq(EverySetting.Set("@social:RecentAlliesSeeLocation", "0"), "0")
	W.Advance(4)
	T.eq(W.social.allies, false)
	T.eq(EverySetting.Set("@social:RecentAlliesSeeLocation", "2"), nil, "only the menu's two")
end)

T.test("not cvars: chat is turned off as the game's options turn it off", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.Set("@social:DisableChat", true), "1")
	T.eq(W.social.chat, true)
	T.eq(W.chatChanged[1], true, "its chat settings and communities follow")
	EverySetting.Reset("@social:DisableChat")
	T.eq(W.social.chat, false)
	T.eq(W.chatChanged[2], false)
end)

T.test("not cvars: minimap tracking by its filter, wherever the game lists it", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.Get("@track:TrivialQuests"), "0")
	T.eq(EverySetting.Get("@track:Innkeeper"), "1")
	T.eq(EverySetting.Knob("@track:Innkeeper").default, "1", "the CVar minimapTrackedInfov4's default has it")
	T.eq(EverySetting.Set("@track:TrivialQuests", true), "1")
	T.eq(W.tracking[18].active, true, "the 18th the game lists")
	table.remove(W.tracking, 1)
	T.eq(EverySetting.Get("@track:TrivialQuests"), "1", "found again where it is now")
	local saved = EverySettingDB
	EverySetting = StartAll(saved, function() W.tracking[3] = nil end) -- a client without the account bank's banker
	T.eq(EverySetting.Knob("@track:AccountBanker").found, false)
end)

T.test("not cvars: combat audio alerts for the specialisation in use, a voice by its number", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.Get("@caa:Resource1Volume"), "100")
	T.eq(EverySetting.Set("@caa:Resource1Volume", 55), "55")
	T.eq(W.caa[3], 55, "a number")
	T.eq(EverySetting.Set("@caa:SayIfTargeted", 0), "0")
	T.eq(W.caa[8], 0)
	T.eq(EverySetting.Set("@caa:Resource2Voice", "12", true), "12", "a box, as typed")
	T.eq(W.caa[6], 12)
	T.eq(EverySetting.Set("@caa:Resource2Voice", "Zira", true), "12", "a number only: the box shows what's kept")
end)

T.test("not cvars: each group is under its section, and says where the game keeps it", function()
	local EverySetting, o = StartAll()
	local where = {}
	for _, name in ipairs({ "@bar:2", "@color:Epic", "@social:DisableChat", "@track:Mailbox", "@caa:Resource1Percent" }) do
		where[name] = EverySetting.SECTIONS[EverySetting.Section(name)]
	end
	T.eq(where["@bar:2"], "Action bars and spells")
	T.eq(where["@color:Epic"], "Accessibility")
	T.eq(where["@social:DisableChat"], "Chat and social")
	T.eq(where["@track:Mailbox"], "Interface")
	T.eq(where["@caa:Resource1Percent"], "Accessibility")
	EverySetting_OpenOptions()
	o.refs.search:SetText("guild invites")
	T.ok(Tip(o, "@social:BlockGuildInvites"):find("The game's server keeps it.", 1, true))
	o.refs.search:SetText("action bar 4")
	T.ok(Tip(o, "@bar:4"):find("A change shows after a reload", 1, true))
end)

T.test("not cvars: what the game lists only once the character is in the world is read again at login", function()
	local EverySetting = W.Load({ profiles = { Default = { ["@track:Mailbox"] = "1" } } })
	local tracking = W.tracking
	W.tracking = {} -- not listed yet as the CVars load
	W.Fire("ADDON_LOADED", "EverySetting")
	W.Fire("VARIABLES_LOADED")
	T.eq(EverySetting.Knob("@track:Mailbox").found, false)
	W.tracking = tracking
	W.Fire("PLAYER_ENTERING_WORLD", true, false)
	T.eq(EverySetting.Knob("@track:Mailbox").found, true)
	T.eq(W.tracking[11].active, true, "and the kept value is set")
end)

T.test("not cvars: the turn and strafe keys, left alone once they're changed by hand", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.Get("@keys:TurnStrafe"), "0")
	local saves = #W.bindingSaves
	T.eq(EverySetting.Set("@keys:TurnStrafe", "1"), "1")
	T.eq(W.strafe, 1)
	T.eq(#W.bindingSaves, saves + 1, "saved with the bindings")
	local saved = EverySettingDB
	StartAll(saved, function() W.strafe = 0 end)
	T.eq(W.strafe, 1, "set again at login")
	EverySetting = StartAll(saved, function() W.strafe = 2 end)
	T.eq(W.strafe, 2, "movement keys changed by hand are left alone at login")
	EverySetting.Set("@keys:TurnStrafe", "0")
	T.eq(W.strafe, 2, "and by hand here")
end)

T.test("not cvars: the / button gives a modified click's command, titled by its name", function()
	local _, o = StartAll()
	EverySetting_OpenOptions()
	local function Row(name)
		for _, row in ipairs(o.rows) do
			if row:IsShown() and row.item.knob and row.item.knob.cvar == name then return row end
		end
	end
	o.refs.search:SetText("sticky camera")
	local sticky = Row(STICKY)
	T.ok(sticky.lock:IsShown() and sticky.command:IsShown(), "a lock box and the command button")
	W.Run(sticky.command, "OnClick")
	local dialog = o.refs.dialog
	T.eq(dialog.title:GetText(), "Command for Sticky camera", "by its name: it has no CVar's")
	T.eq(dialog.body:GetText(), '/run SetModifiedClick("STICKYCAMERA", "CTRL") SaveBindings(GetCurrentBindingSet())')
	T.ok(dialog.text:GetText():find("set Sticky camera yourself", 1, true))
	T.ok(not dialog.text:GetText():find("combat", 1, true), "Every Setting's own word that it waits for combat isn't the game's")
	W.Run(dialog.cancel, "OnClick")
	o.refs.search:SetText("action bar 2")
	local bar = Row("@bar:2")
	T.ok(bar.lock:IsShown() and bar.check:IsShown() and bar.command:IsShown(), "an action bar has one too")
	W.Run(bar.command, "OnClick")
	T.eq(dialog.body:GetText(), "/run local t={GetActionBarToggles()} t[1]=false SetActionBarToggles(unpack(t,1,7))")
end)

-- Runs a command as typed in chat: a /run line, no longer than chat takes.
local function Type(command)
	assert(#command <= 255, "longer than chat takes: " .. command)
	assert((loadstring or load)(assert(command:match("^/run (.*)$"), command)))()
end

T.test("not cvars: each has a command, and typed it sets what Set would", function()
	local EverySetting = StartAll()
	T.eq(EverySetting.HasCommand("farclip"), true, "every CVar has")
	T.eq(EverySetting.HasCommand("@nothing"), false, "a name that isn't a CVar's, with no setter")
	for _, case in ipairs({
		{ "@click:SELFCAST", "CTRL" },
		{ "@keys:TurnStrafe", "1" },
		{ "@bar:3", "1" },
		{ "@bar:3", "0" },
		{ "@color:Rare", "FF112233" },
		{ "@track:Banker", "1" },
		{ "@track:TaxiNode", "0" },
		{ "@caa:Resource1Volume", "80" },
		{ "@caa:SayIfTargeted", "0" },
		{ "@social:DisableChat", "1" },
	}) do
		local name, value = case[1], case[2]
		T.eq(EverySetting.HasCommand(name), true, name)
		Type(EverySetting.Command(name, value))
		T.eq(EverySetting.Get(name), value, name .. " " .. value)
	end
	T.eq(W.bars[1], false, "the other bars as they were")
	T.eq(W.chatChanged[#W.chatChanged], true, "chat's own settings follow, as the game's options have them")
	T.eq(EverySetting.Command("@color:Rare", "0070dd"), "/run C_ColorOverrides.RemoveColorOverride(3)", "the game's own colour")
	Type(EverySetting.Command("@color:Rare", "0070dd"))
	T.eq(W.overrides[3], nil, "has no override")
	Type(EverySetting.Command("@social:BlockGuildInvites", "1"))
	Type(EverySetting.Command("@social:RecentAlliesSeeLocation", "0"))
	T.eq(W.social.guildInvites, true)
	T.eq(W.social.allies, false)
	-- Found wherever the game lists it, as Set finds it.
	table.insert(W.tracking, 1, table.remove(W.tracking, 2))
	Type(EverySetting.Command("@track:Banker", "0"))
	T.eq(EverySetting.Get("@track:Banker"), "0")
	-- Movement keys changed by hand are left alone, as Set leaves them.
	W.strafe = 2
	Type(EverySetting.Command("@keys:TurnStrafe", "0"))
	T.eq(W.strafe, 2)
	T.eq(EverySetting.Command("@caa:Resource1Voice", "x"), '/run C_CombatAudioAlert.SetSpecSetting(Enum.CombatAudioAlertSpecSetting.Resource1Voice, "x")',
		"what isn't a number is quoted")
end)

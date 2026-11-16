-- Situations: a saved preset used while something is true (in combat,
-- mounted, in a city or inn, in an instance), without changing the profile.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client. `saved` is last session's saved variables, and `before`
-- runs before login.
local function Start(saved, before)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000")
	W.AddCVar("RAIDfarclip", "1000")
	W.AddCVar("ffxAntiAliasingMode", "0")
	W.AddCVar("cameraZoomSpeed", "20")
	W.AddCVar("nameplateMaxDistance", "60", { secure = true })
	W.AddCVar("test_cameraOverShoulder", "0.000000", { float = true })
	W.AddCVar("gxMonitor", "0", { readOnly = true })
	EverySetting.GROUPS = {
		{ title = "Graphics", items = {
			{ cvar = "farclip", label = "View distance", type = "slider", min = 1000, max = 10000, step = 100, raid = "RAIDfarclip" },
			{ cvar = "ffxAntiAliasingMode", label = "Anti-aliasing", type = "choice", restart = "gx",
			  options = { { 0, "None" }, { 1, "FXAA" } } },
		} },
		{ title = "Camera", items = {
			{ cvar = "cameraZoomSpeed", label = "Zoom speed", type = "slider", min = 1, max = 50, step = 1 },
			{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
		} },
	}
	EverySetting.SECTIONS = { "Graphics", "Camera" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "1", ffxAntiAliasingMode = "1", gxMonitor = "1",
		cameraZoomSpeed = "2", nameplateMaxDistance = "2", test_cameraOverShoulder = "2" }
	if before then before() end
	W.Login()
	return EverySetting, ns.Options
end

local Get = function(cvar) return C_CVar.GetCVar(cvar) end

T.test("situations: a preset is used while its situation is on, and the profile doesn't change", function()
	local EverySetting = Start()
	EverySetting.Set("cameraZoomSpeed", 30)
	EverySetting.SavePreset("Ride", { cameraZoomSpeed = "45", test_cameraOverShoulder = "1" })
	local undo = EverySetting.HistorySize()
	EverySetting.SetSituation("mounted", "Ride")
	T.eq(Get("cameraZoomSpeed"), "30", "nothing until it's on")
	W.Mount(true)
	T.eq(Get("cameraZoomSpeed"), "45")
	T.eq(Get("test_cameraOverShoulder"), "1.000000", "a CVar that isn't a tuned knob too")
	T.eq(select(2, EverySetting.GetSituation("mounted")), true)
	T.eq(EverySetting.Get("cameraZoomSpeed"), "30", "the window shows your value")
	T.eq(EverySetting.GetKept().cameraZoomSpeed, "30", "the profile keeps it")
	T.ok(not EverySetting.IsStored("test_cameraOverShoulder"))
	T.eq(EverySettingDB.before.test_cameraOverShoulder, nil)
	T.eq(EverySetting.HistorySize(), undo, "nothing to undo")
	local value, by = EverySetting.Held("cameraZoomSpeed")
	T.eq(value, "45")
	T.eq(by, "Mounted")
	W.Mount(false)
	T.eq(Get("cameraZoomSpeed"), "30")
	T.eq(Get("test_cameraOverShoulder"), "0.000000")
	T.eq(EverySetting.Held("cameraZoomSpeed"), nil)
	T.eq(next(EverySettingDB.under), nil, "nothing left to put back")
end)

T.test("situations: the higher one wins a CVar, and they end in turn", function()
	local EverySetting = Start()
	EverySetting.SavePreset("City", { cameraZoomSpeed = "10", farclip = "3000" })
	EverySetting.SavePreset("Ride", { cameraZoomSpeed = "40" })
	EverySetting.SavePreset("Fight", { cameraZoomSpeed = "50" })
	EverySetting.SetSituation("resting", "City")
	EverySetting.SetSituation("mounted", "Ride")
	EverySetting.SetSituation("combat", "Fight")
	W.Rest(true)
	T.eq(Get("cameraZoomSpeed"), "10")
	T.eq(Get("farclip"), "3000")
	T.eq(Get("RAIDfarclip"), "3000", "the raid twin too")
	W.Mount(true)
	T.eq(Get("cameraZoomSpeed"), "40", "mounted is higher than resting")
	T.eq(Get("farclip"), "3000", "resting still holds what mounted doesn't set")
	W.Combat(true)
	T.eq(Get("cameraZoomSpeed"), "50")
	T.eq(select(2, EverySetting.Held("cameraZoomSpeed")), "In combat")
	W.Combat(false)
	T.eq(Get("cameraZoomSpeed"), "40")
	W.Mount(false)
	T.eq(Get("cameraZoomSpeed"), "10")
	W.Rest(false)
	T.eq(Get("cameraZoomSpeed"), "20")
	T.eq(Get("farclip"), "1000")
	T.eq(Get("RAIDfarclip"), "1000")
	-- An instance is checked at each loading screen.
	EverySetting.SetSituation("instance", "Ride")
	W.Zone(true)
	T.eq(Get("cameraZoomSpeed"), "40")
	W.Zone(false)
	T.eq(Get("cameraZoomSpeed"), "20")
end)

T.test("situations: a change made while one is on goes to the profile, underneath", function()
	local EverySetting = Start()
	EverySetting.SavePreset("Ride", { cameraZoomSpeed = "40", farclip = "5000" })
	EverySetting.SetSituation("mounted", "Ride")
	W.Mount(true)
	EverySetting.Set("cameraZoomSpeed", 25)
	EverySetting.Set("farclip", 2000)
	T.eq(Get("cameraZoomSpeed"), "40", "the situation still holds it")
	T.eq(Get("farclip"), "5000")
	T.eq(EverySetting.Get("cameraZoomSpeed"), "25")
	T.ok(EverySetting.IsStored("cameraZoomSpeed"))
	T.eq(EverySetting.Before("cameraZoomSpeed"), "20", "from before the situation")
	T.eq(EverySetting.ExportProfile(), "EverySetting:1:cameraZoomSpeed=25,farclip=2000", "export has your values")
	T.ok(EverySetting.Undo())
	T.eq(EverySetting.Get("farclip"), "1000")
	T.ok(EverySetting.Redo())
	W.Mount(false)
	T.eq(Get("cameraZoomSpeed"), "25", "yours, once it ends")
	T.eq(Get("farclip"), "2000")
	T.eq(Get("RAIDfarclip"), "2000")
	-- Reset all and a profile switch work underneath too.
	W.Mount(true)
	T.eq(EverySetting.ResetAll(), 2)
	T.eq(Get("cameraZoomSpeed"), "40", "still held")
	T.eq(EverySetting.Get("cameraZoomSpeed"), "20")
	EverySetting.NewProfile("Other")
	EverySetting.Set("cameraZoomSpeed", 33)
	EverySetting.SetProfile("Default")
	T.eq(EverySetting.Get("cameraZoomSpeed"), "20", "Default doesn't keep it")
	EverySetting.SetProfile("Other")
	T.eq(Get("cameraZoomSpeed"), "40")
	W.Mount(false)
	T.eq(Get("cameraZoomSpeed"), "33")
	T.eq(Get("farclip"), "1000")
	T.eq(Get("RAIDfarclip"), "1000")
end)

T.test("situations: secure, restart and locked CVars are left out", function()
	local EverySetting = Start()
	EverySetting.SavePreset("All", { nameplateMaxDistance = "80", ffxAntiAliasingMode = "1", gxMonitor = "2", cameraZoomSpeed = "40" })
	EverySetting.SetSituation("resting", "All")
	W.Rest(true)
	T.eq(Get("cameraZoomSpeed"), "40")
	T.eq(Get("nameplateMaxDistance"), "60", "secure")
	T.eq(Get("ffxAntiAliasingMode"), "0", "needs a restart")
	T.eq(Get("gxMonitor"), "0", "locked")
	T.eq(W.restarts.gx, nil)
end)

T.test("situations: a CVar something else changed is left as it is", function()
	local EverySetting = Start()
	EverySetting.SavePreset("City", { cameraZoomSpeed = "10" })
	EverySetting.SetSituation("resting", "City")
	W.Rest(true)
	C_CVar.SetCVar("cameraZoomSpeed", "35") -- the game's own options
	W.Mount(true)
	T.eq(Get("cameraZoomSpeed"), "35", "not set again")
	W.Rest(false)
	T.eq(Get("cameraZoomSpeed"), "35", "nor put back when the situation ends")
	T.eq(next(EverySettingDB.under), nil)
end)

T.test("situations: logout puts the values back, and a login after a crash does too", function()
	local EverySetting = Start()
	EverySetting.Set("cameraZoomSpeed", 30)
	EverySetting.SavePreset("City", { cameraZoomSpeed = "10" })
	EverySetting.SetSituation("resting", "City")
	W.Rest(true)
	W.Fire("PLAYER_LOGOUT")
	T.eq(Get("cameraZoomSpeed"), "30", "the game saves your value")
	T.eq(EverySettingDB.under.cameraZoomSpeed, "30", "and the record stays")
	-- The next session starts as a crash would leave it: at the situation's value.
	EverySetting = Start(EverySettingDB, function() W.cvars.camerazoomspeed.value = "10" end)
	T.eq(Get("cameraZoomSpeed"), "30", "back to the profile's value")
	T.eq(EverySettingDB.before.cameraZoomSpeed, "20", "not taken for a change the game made")
	T.eq(next(EverySettingDB.under), nil)
	T.eq(EverySetting.GetSituation("resting"), "City", "the assignment is saved")
	-- Logging in where a situation is on holds it again.
	Start(EverySettingDB, function() W.resting = true end)
	T.eq(Get("cameraZoomSpeed"), "10")
end)

T.test("situations: deleting a preset stops the situations that use it", function()
	local EverySetting = Start()
	EverySetting.SavePreset("City", { cameraZoomSpeed = "10" })
	EverySetting.SetSituation("resting", "City")
	W.Rest(true)
	EverySetting.DeletePreset("City")
	T.eq(Get("cameraZoomSpeed"), "20")
	T.eq(EverySetting.GetSituation("resting"), nil)
end)

T.test("situations: what you've changed since login is given to one in a single step", function()
	-- The profile kept a zoom speed of 30 from an earlier session.
	local EverySetting = Start({ profiles = { Default = { cameraZoomSpeed = "30" } }, before = { cameraZoomSpeed = "20" } })
	T.eq(Get("cameraZoomSpeed"), "30")
	T.eq(next(EverySetting.Changes()), nil, "nothing changed yet")
	EverySetting.Set("cameraZoomSpeed", 45)
	EverySetting.Set("farclip", 3000)
	EverySetting.RawKnob("test_cameraOverShoulder", "") -- as the window's list of every CVar makes it
	EverySetting.Set("test_cameraOverShoulder", 1)
	EverySetting.Set("nameplateMaxDistance", 80) -- secure
	EverySetting.Set("ffxAntiAliasingMode", 1) -- needs a restart
	local changes = EverySetting.Changes()
	T.eq(changes.cameraZoomSpeed, "45")
	T.eq(changes.farclip, "3000")
	T.eq(changes.test_cameraOverShoulder, "1.000000")
	T.eq(changes.RAIDfarclip, nil, "a raid twin goes along with its knob")
	T.eq(changes.nameplateMaxDistance, nil, "not what a situation can't use")
	T.eq(changes.ffxAntiAliasingMode, nil)
	W.Rest(true)
	local count, name = EverySetting.TakeChanges("resting")
	T.eq(count, 3)
	T.eq(name, "In a city or inn", "a new preset, named after the situation")
	T.eq(EverySetting.GetSituation("resting"), name)
	local preset = EverySetting.GetPresets()[name]
	T.eq(preset.cameraZoomSpeed, "45")
	T.eq(preset.farclip, "3000")
	T.eq(preset.test_cameraOverShoulder, "1.000000")
	-- In the city they look as they did...
	T.eq(Get("cameraZoomSpeed"), "45")
	T.eq(Get("RAIDfarclip"), "3000")
	-- ...but the profile is back how it was at login.
	T.eq(EverySetting.Get("cameraZoomSpeed"), "30")
	T.eq(EverySetting.Before("cameraZoomSpeed"), "20")
	T.ok(not EverySetting.IsStored("farclip") and not EverySetting.IsStored("test_cameraOverShoulder"))
	T.eq(EverySetting.Get("nameplateMaxDistance"), "80", "what a situation can't use stays in the profile")
	W.Rest(false)
	T.eq(Get("cameraZoomSpeed"), "30")
	T.eq(Get("farclip"), "1000")
	T.eq(Get("RAIDfarclip"), "1000")
	T.eq(Get("test_cameraOverShoulder"), "0.000000")
	-- Undo puts them back in the profile; the preset stays.
	T.ok(EverySetting.Undo())
	T.eq(Get("cameraZoomSpeed"), "45")
	T.eq(Get("RAIDfarclip"), "3000")
	T.ok(EverySetting.GetPresets()[name])
	T.ok(EverySetting.Redo())
	T.eq(Get("cameraZoomSpeed"), "30")
	local none, why = EverySetting.TakeChanges("resting")
	T.eq(none, nil)
	T.eq(why, "You haven't changed anything since you logged in that a situation can use.")
	-- More changes are added to the situation's preset.
	EverySetting.Set("cameraZoomSpeed", 12)
	T.eq(EverySetting.TakeChanges("resting"), 1)
	T.eq(preset.cameraZoomSpeed, "12")
	T.eq(preset.farclip, "3000", "what it had stays")
end)

T.test("situations: taking changes needs a free name, and not combat", function()
	local EverySetting = Start()
	EverySetting.SavePreset("Mounted", { farclip = "9000" })
	EverySetting.Set("cameraZoomSpeed", 45)
	local _, name = EverySetting.TakeChanges("mounted")
	T.eq(name, "Mounted 2", "the name was taken")
	T.eq(EverySetting.GetPresets().Mounted.farclip, "9000", "that preset is left alone")
	EverySetting.Set("cameraZoomSpeed", 40)
	W.Combat(true)
	T.eq(select(2, EverySetting.TakeChanges("combat")), "That has to wait until you're out of combat.")
	T.eq(EverySetting.GetSituation("combat"), nil)
	T.eq(select(2, EverySetting.TakeChanges("flying")), "There's no such situation.")
end)

-------------------------------------------------------------------------------
-- The window and the slash command
-------------------------------------------------------------------------------

-- The open menu's items, in order.
local function Menu()
	local labels = {}
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value ~= nil and w:IsVisible() then labels[#labels + 1] = w.label:GetText() end
	end
	return table.concat(labels, ", ")
end

local function MenuItem(value)
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w.value == value and w:IsVisible() then return w end
	end
end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

T.test("situations: the footer's menus, a held row, and /every situations", function()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	EverySetting.SavePreset("Ride", { farclip = "5000" })
	EverySetting.SavePreset("City", { cameraZoomSpeed = "10" })
	W.Run(o.refs.situations, "OnEnter")
	W.Run(o.refs.situations, "OnClick")
	T.eq(Menu(), "In combat: none, Mounted: none, In a city or inn: none, In an instance: none")
	W.Run(MenuItem("resting"), "OnClick")
	T.eq(Menu(), "None, Built in: fewer effects from the crowd, City, Ride", "a second menu: its own preset, then the saved ones")
	W.Run(MenuItem("City"), "OnClick")
	T.eq(EverySetting.GetSituation("resting"), "City")
	W.Rest(true)
	W.Run(o.refs.situations, "OnClick")
	T.ok(Menu():find("In a city or inn: City (on now)", 1, true), Menu())
	W.Run(MenuItem("resting"), "OnClick")
	T.ok(MenuItem("City").active, "the one in use is marked")
	W.Run(o.refs.situations, "OnClick") -- closes it
	local row = RowFor(o, "cameraZoomSpeed")
	T.ok(row.label:GetText():find("(In a city or inn)", 1, true), row.label:GetText())
	T.eq(row.box:GetText(), "20", "the row shows your value")
	W.Run(row.name, "OnEnter")
	T.ok(not RowFor(o, "farclip").label:GetText():find("(", 1, true), "a row nothing holds")
	W.Slash("situations")
	T.eq(W.chat[#W.chat], "|cffffb000Every Setting|r: situations: In combat: none, Mounted: none, In a city or inn: City (on now), In an instance: none.")
	-- None stops it.
	W.Run(o.refs.situations, "OnClick")
	W.Run(MenuItem("resting"), "OnClick")
	W.Run(MenuItem(""), "OnClick")
	T.eq(EverySetting.GetSituation("resting"), nil)
	T.eq(Get("cameraZoomSpeed"), "20")
	T.ok(not RowFor(o, "cameraZoomSpeed").label:GetText():find("(", 1, true))
end)

T.test("situations: the menu gives one what you've changed since login", function()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	W.Run(o.refs.situations, "OnClick")
	W.Run(MenuItem("mounted"), "OnClick")
	T.eq(Menu(), "None, Built in: see further, zoom out", "nothing changed yet, and no saved presets")
	W.Run(o.refs.situations, "OnClick") -- closes it
	EverySetting.Set("cameraZoomSpeed", 45)
	EverySetting.Set("farclip", 3000)
	W.Run(o.refs.situations, "OnClick")
	W.Run(MenuItem("mounted"), "OnClick")
	T.eq(Menu(), "Use what you've changed since login (2), None, Built in: see further, zoom out")
	local take
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w:IsVisible() and w.label and w.label:GetText():find("^Use what") then take = w end
	end
	W.Run(take, "OnClick")
	T.eq(EverySetting.GetSituation("mounted"), "Mounted")
	T.eq(Get("cameraZoomSpeed"), "20", "not mounted, so your profile's value")
	T.ok(W.chat[#W.chat]:find("Mounted now uses the 2 settings you changed (the preset Mounted)", 1, true), W.chat[#W.chat])
	W.Mount(true)
	T.eq(Get("cameraZoomSpeed"), "45")
	W.Run(o.refs.situations, "OnClick")
	T.ok(Menu():find("Mounted: Mounted (on now)", 1, true), Menu())
end)

-- A logged-in client with every CVar of `path` and the real knobs, retail's if `client` says so.
local RETAIL = "data/ranges/70783/retail/cvars.lua"
local function StartReal(path, client)
	local EverySetting, ns = W.Load(nil, nil, nil, client)
	for _, cvar in ipairs(dofile(path).cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	return EverySetting, ns.Options
end

T.test("situations: each one's own preset sets CVars both games have, inside their ranges, none secure", function()
	for _, game in ipairs({ { "data/cvars.lua" }, { RETAIL, "retail" } }) do
		local flags = {}
		for _, cvar in ipairs(dofile(game[1]).cvars) do flags[cvar[1]] = cvar[5] or "" end
		local EverySetting = StartReal(game[1], game[2])
		for _, s in ipairs(EverySetting.SITUATIONS) do
			local where = s.key .. " in " .. (game[2] or "forever")
			T.ok(type(s.sets) == "string" and s.sets ~= "", s.key .. " says what its own preset sets")
			T.ok(type(s.preset) == "table" and next(s.preset), s.key .. " has a preset of its own")
			for cvar, value in pairs(s.preset) do
				T.ok(flags[cvar], cvar .. " is a CVar, " .. where)
				T.ok(not (flags[cvar] or ""):find("[slr]"), cvar .. " can be set in combat and isn't locked, " .. where)
				local knob = EverySetting.RawKnob(cvar, "")
				T.ok(knob and knob.type ~= "text", cvar .. " has a control, " .. where)
				T.ok(knob and not knob.restart and not knob.locked, cvar .. " needs no restart, " .. where)
				if knob and not (game[2] == "retail" and cvar == "cameraDistanceMaxZoomFactor") then
					T.eq(EverySetting.Fit(knob, value), tostring(value), cvar .. " is inside its range, " .. where)
				end
			end
		end
	end
end)

T.test("situations: one's own preset is picked from its menu, used while it's on, and held to retail's range", function()
	local EverySetting, o = StartReal("data/cvars.lua")
	EverySetting_OpenOptions()
	W.Run(o.refs.situations, "OnClick")
	W.Run(MenuItem("combat"), "OnClick")
	local own
	for _, w in ipairs(W.widgets) do
		if w.kind == "Button" and w:IsVisible() and w.label and w.label:GetText() == "Built in: enemy nameplates, no weather, zoom out" then own = w end
	end
	T.ok(own, "its menu has it")
	W.Run(own, "OnClick")
	local name, on, isOwn = EverySetting.GetSituation("combat")
	T.eq(name, "built in")
	T.eq(on, false)
	T.eq(isOwn, true)
	T.eq(EverySettingDB.situations.combat, true, "saved as its own")
	T.eq(Get("nameplateShowEnemies"), "0", "nothing until it's on")
	W.Combat(true)
	T.eq(Get("nameplateShowEnemies"), "1")
	T.eq(Get("weatherDensity"), "0")
	T.eq(Get("RAIDweatherDensity"), "0", "the raid twin too")
	T.eq(tonumber(Get("cameraDistanceMaxZoomFactor")), 4)
	T.eq(EverySetting.GetKept().nameplateShowEnemies, nil, "the profile keeps none of it")
	W.Slash("situations")
	T.ok(W.chat[#W.chat]:find("In combat: built in (on now)", 1, true), W.chat[#W.chat])
	W.Run(o.refs.situations, "OnClick")
	W.Run(MenuItem("combat"), "OnClick")
	T.ok(MenuItem(true).active, "the one in use is marked")
	W.Run(o.refs.situations, "OnClick") -- closes it
	W.Combat(false)
	T.eq(Get("nameplateShowEnemies"), "0")
	T.eq(Get("weatherDensity"), "2")
	T.eq(tonumber(Get("cameraDistanceMaxZoomFactor")), 1)
	T.eq(next(EverySettingDB.under), nil, "nothing left to put back")

	EverySetting = StartReal(RETAIL, "retail")
	EverySetting.SetSituation("mounted", true)
	W.Mount(true)
	T.eq(tonumber(Get("cameraDistanceMaxZoomFactor")), 2.6, "retail's top")
	T.eq(Get("farclip"), "10000")
	W.Mount(false)
	T.eq(Get("farclip"), "1000")
end)

T.test("situations: what you've changed is added on top of one's own preset, in a preset of yours", function()
	local EverySetting = StartReal("data/cvars.lua")
	EverySetting.SetSituation("resting", true)
	EverySetting.Set("cameraZoomSpeed", 45)
	EverySetting.Set("particleDensity", 80)
	local count, name = EverySetting.TakeChanges("resting")
	T.eq(count, 2)
	T.eq(name, "In a city or inn")
	T.eq(EverySetting.GetSituation("resting"), "In a city or inn", "a saved preset now, not its own")
	local preset = EverySetting.GetPresets()[name]
	T.eq(preset.spellVisualDensityFilterSetting, "2", "its own preset's values")
	T.eq(preset.cameraZoomSpeed, "45", "and yours")
	T.eq(preset.particleDensity, "80", "yours over its own")
	W.Rest(true)
	T.eq(Get("particleDensity"), "80")
	T.eq(Get("spellVisualDensityFilterSetting"), "2")
end)

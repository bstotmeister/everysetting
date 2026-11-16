-- Restart markers: a line of CVars.lua can say a change shows only after a
-- graphics restart, a reload, a login or a game restart. The knob made from it warns,
-- the window offers the restart, and situations leave it out.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client whose CVars.lua has a marker of each kind.
local function Start()
	local EverySetting, ns = W.Load()
	W.AddCVar("GxApi", "auto")
	W.AddCVar("GxMaxFrameLatency", "3")
	W.AddCVar("physicsLevel", "1")
	W.AddCVar("uiFont", "0")
	W.AddCVar("NotchedDisplayMode", "1")
	W.AddCVar("lootSparkle", "0")
	W.AddCVar("cameraZoomSpeed", "20")
	W.AddCVar("TurnSpeed", "180", { min = 1 })
	W.AddCVar("statusText", "NONE")
	EverySetting.GROUPS = {}
	EverySetting.SECTIONS = { "Graphics", "Interface" }
	EverySetting.CVARS = {
		GxApi = "1|gx",
		GxMaxFrameLatency = "1|c|2=Triple buffering off|3=Triple buffering on|gx",
		physicsLevel = "1|s|0|2|1|client",
		uiFont = "2|t|reload",
		NotchedDisplayMode = "2|c|0=Overlap|1=Shift UI|2=Window below|window",
		lootSparkle = "1|t|login:0",
		cameraZoomSpeed = "1|s|1|50|1",
		TurnSpeed = "2|S|90|270|10|gx|x",
		statusText = "2|c|NONE=None|reload=Reload|client=Client",
	}
	W.Login()
	return EverySetting, ns.Options
end

local function RowFor(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then return row end
	end
end

-- A row's tooltip, as one text.
local function Tip(row)
	local lines = {}
	rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
	W.Run(row.name, "OnEnter")
	rawset(GameTooltip, "AddLine", nil)
	return table.concat(lines, "\n")
end

T.test("restart: a line's marker says what a change waits for, and the control is the rest of the line", function()
	local EverySetting = Start()
	local api = EverySetting.RawKnob("GxApi", "")
	T.eq(api.restart, "gx")
	T.eq(api.type, "text", "just a box, with a marker")
	local latency = EverySetting.RawKnob("GxMaxFrameLatency", "")
	T.eq(latency.restart, "gx")
	T.eq(latency.type, "choice")
	T.eq(#latency.options, 2, "the marker isn't an option")
	local physics = EverySetting.RawKnob("physicsLevel", "")
	T.eq(physics.restart, "client")
	T.eq(physics.max, 2) T.eq(physics.step, 1)
	T.eq(EverySetting.RawKnob("uiFont", "").restart, "reload")
	T.eq(EverySetting.RawKnob("NotchedDisplayMode", "").restart, "window")
	T.eq(EverySetting.RawKnob("uiFont", "").type, "toggle")
	local sparkle = EverySetting.RawKnob("lootSparkle", "")
	T.eq(sparkle.restart, "login")
	T.eq(sparkle.restartTo, "0", "only a change to 0")
	T.eq(physics.restartTo, nil, "any change")
	local turn = EverySetting.RawKnob("TurnSpeed", "")
	T.eq(turn.restart, "gx", "before the x")
	T.eq(turn.danger, "server")
	T.eq(turn.max, 270)
	local status = EverySetting.RawKnob("statusText", "")
	T.eq(status.restart, nil, "an option named like a marker is an option")
	T.eq(#status.options, 3)
	T.eq(EverySetting.RawKnob("cameraZoomSpeed", "").restart, nil)
end)

T.test("restart: a change to a marked CVar is noted, each kind by itself", function()
	local EverySetting = Start()
	for _, cvar in ipairs({ "GxApi", "physicsLevel", "uiFont", "NotchedDisplayMode", "cameraZoomSpeed" }) do EverySetting.RawKnob(cvar, "") end
	EverySetting.Set("cameraZoomSpeed", 30)
	T.eq(next(EverySetting.restart), nil, "nothing for a CVar with no marker")
	EverySetting.Set("GxApi", "auto", true)
	T.eq(EverySetting.restart.gx, nil, "nor for a value it has already")
	EverySetting.Set("GxApi", "metal", true)
	T.eq(EverySetting.restart.gx, true)
	T.eq(EverySetting.restart.client, nil)
	EverySetting.Set("physicsLevel", 2)
	T.eq(EverySetting.restart.client, true)
	T.eq(EverySetting.restart.reload, nil)
	EverySetting.Set("uiFont", 1)
	T.eq(EverySetting.restart.reload, true)
	T.eq(EverySetting.restart.window, nil)
	EverySetting.Set("NotchedDisplayMode", 2)
	T.eq(EverySetting.restart.window, true)
end)

T.test("restart: Restart graphics does what's owed, as the game's options do: the graphics, the window or both", function()
	local EverySetting = Start()
	for _, cvar in ipairs({ "GxMaxFrameLatency", "NotchedDisplayMode" }) do EverySetting.RawKnob(cvar, "") end
	EverySetting.Set("NotchedDisplayMode", 2)
	EverySetting.RestartGraphics()
	T.eq(W.restarts.window, 1, "the window is updated")
	T.eq(W.restarts.gx, nil, "with no graphics restart when none is owed")
	T.eq(EverySetting.restart.window, nil)
	EverySetting.Set("GxMaxFrameLatency", 2)
	EverySetting.Set("NotchedDisplayMode", 1)
	EverySetting.RestartGraphics()
	T.eq(W.restarts.gx, 1)
	T.eq(W.restarts.window, 2, "both when both are owed")
	T.eq(next(EverySetting.restart), nil)
	EverySetting.RestartGraphics()
	T.eq(W.restarts.gx, 2, "and the graphics when nothing is")
	T.eq(W.restarts.window, 2)
end)

T.test("restart: a marker for one value notes a change to it, and not one away from it", function()
	local EverySetting = Start()
	EverySetting.RawKnob("lootSparkle", "")
	EverySetting.Set("lootSparkle", 1)
	T.eq(EverySetting.restart.login, nil, "on shows at once")
	EverySetting.Set("lootSparkle", 0)
	T.eq(EverySetting.restart.login, true, "off waits")
	T.eq(EverySetting.restart.client, nil, "for a login, not a game restart")
	EverySetting.restart.login = nil
	EverySetting.Undo()
	T.eq(C_CVar.GetCVar("lootSparkle"), "1")
	T.eq(EverySetting.restart.login, nil, "Undo to on")
	EverySetting.Reset("lootSparkle")
	T.eq(C_CVar.GetCVar("lootSparkle"), "0")
	T.eq(EverySetting.restart.login, true, "Reset to off")
end)

T.test("restart: the window warns in a marked row's tooltip, and offers Restart graphics once it's changed", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	o.refs.search:SetText("GxApi")
	local row = RowFor(o, "GxApi")
	T.ok(Tip(row):find("A change shows after a graphics restart (the button at the bottom).", 1, true), "the tooltip warns")
	T.ok(not o.refs.restartGx:IsShown(), "no button until something has changed")
	row.box:SetFocus()
	row.box:SetText("metal")
	W.Run(row.box, "OnEnterPressed")
	T.eq(C_CVar.GetCVar("GxApi"), "metal")
	T.ok(o.refs.restartGx:IsShown(), "the footer offers the restart")
	T.eq(o.refs.restartGx.label:GetText(), "Restart graphics")
	W.Run(row.reset, "OnClick")
	T.eq(C_CVar.GetCVar("GxApi"), "auto")
	T.eq(W.restarts.gx, nil, "nothing restarts by itself")
	W.Run(o.refs.restartGx, "OnClick")
	T.eq(W.restarts.gx, 1)
	T.ok(not o.refs.restartGx:IsShown())

	-- A window update has the same button, under its own name.
	o.refs.search:SetText("NotchedDisplayMode")
	row = RowFor(o, "NotchedDisplayMode")
	T.ok(Tip(row):find("A change shows once the game's window is updated (the button at the bottom).", 1, true))
	row.box:SetFocus()
	row.box:SetText("2")
	W.Run(row.box, "OnEnterPressed")
	T.ok(o.refs.restartGx:IsShown())
	T.eq(o.refs.restartGx.label:GetText(), "Update window")
	W.Run(o.refs.restartGx, "OnClick")
	T.eq(W.restarts.window, 1)
	T.eq(W.restarts.gx, 1, "no graphics restart for it")
	T.ok(not o.refs.restartGx:IsShown())

	o.refs.search:SetText("lootSparkle")
	T.ok(Tip(RowFor(o, "lootSparkle")):find("A change to Off shows after you log out and in again.", 1, true), "a one-way marker names the value")
	o.refs.search:SetText("uiFont")
	row = RowFor(o, "uiFont")
	T.ok(Tip(row):find("A change shows after a reload (type /reload).", 1, true))
	T.eq(o.refs.note:GetText(), "")
	row.check:SetChecked(true)
	W.Run(row.check, "OnClick")
	T.ok(o.refs.note:GetText():find("after a reload: type /reload", 1, true), "the footer says a reload is owed")
	o.refs.search:SetText("cameraZoomSpeed")
	T.ok(not Tip(RowFor(o, "cameraZoomSpeed")):find("A change", 1, true), "no warning on a row with no marker")
end)

T.test("restart: a login owed is a line in the footer, with no button", function()
	local _, o = Start()
	EverySetting_OpenOptions()
	o.refs.search:SetText("lootSparkle")
	local row = RowFor(o, "lootSparkle")
	row.check:SetChecked(true)
	W.Run(row.check, "OnClick")
	T.eq(o.refs.note:GetText(), "", "on shows at once")
	row.check:SetChecked(false)
	W.Run(row.check, "OnClick")
	T.ok(o.refs.note:GetText():find("Some changes show after you log out and in again.", 1, true), "off waits for a login")
	T.ok(not o.refs.restartGx:IsShown(), "which no button does")
end)

T.test("restart: a situation leaves a marked CVar out, and so does what you've changed since login", function()
	local EverySetting = Start()
	EverySetting.SavePreset("City", { GxMaxFrameLatency = "2", NotchedDisplayMode = "2", physicsLevel = "2", uiFont = "1",
		lootSparkle = "1", cameraZoomSpeed = "40" })
	EverySetting.SetSituation("resting", "City")
	W.Rest(true)
	T.eq(C_CVar.GetCVar("cameraZoomSpeed"), "40")
	T.eq(C_CVar.GetCVar("GxMaxFrameLatency"), "3", "needs a graphics restart")
	T.eq(C_CVar.GetCVar("NotchedDisplayMode"), "1", "needs a window update")
	T.eq(C_CVar.GetCVar("physicsLevel"), "1", "needs a game restart")
	T.eq(C_CVar.GetCVar("uiFont"), "0", "needs a reload")
	T.eq(C_CVar.GetCVar("lootSparkle"), "0", "needs a login to go back")
	T.eq(next(EverySetting.restart), nil)
	W.Rest(false)
	for _, cvar in ipairs({ "GxMaxFrameLatency", "NotchedDisplayMode", "cameraZoomSpeed" }) do EverySetting.RawKnob(cvar, "") end
	EverySetting.Set("GxMaxFrameLatency", 2)
	EverySetting.Set("NotchedDisplayMode", 2)
	EverySetting.Set("cameraZoomSpeed", 45)
	local changes = EverySetting.Changes()
	T.eq(changes.cameraZoomSpeed, "45")
	T.eq(changes.GxMaxFrameLatency, nil)
	T.eq(changes.NotchedDisplayMode, nil)
end)

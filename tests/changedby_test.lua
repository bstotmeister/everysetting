-- Who changed a setting: what last changed each CVar this session (another
-- addon, Every Setting, a /run line, the game or the console), the line in chat
-- when another addon changes one the profile keeps, and where the game saves it.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with a few knobs: view distance (with its raid twin), soft
-- shadows, a CVar the game saves for the account and one it saves for each
-- character. `saved` is last session's saved variables. Returns the addon and
-- the window's parts.
local function Start(saved)
	local EverySetting, ns = W.Load(saved)
	W.AddCVar("farclip", "1000", { min = 185, max = 10000 })
	W.AddCVar("RAIDfarclip", "1000", { min = 185, max = 10000 })
	W.AddCVar("shadowSoft", "0")
	W.AddCVar("cameraDistanceMaxZoomFactor", "1.9", { account = true })
	W.AddCVar("nameplateMaxDistance", "60", { character = true })
	W.AddCVar("nameplateEnemyNpcAuraDisplay", "\002A")
	EverySetting.GROUPS = { { title = "Graphics", items = {
		{ cvar = "farclip", label = "View distance", type = "slider", min = 185, max = 10000, step = 5, raid = "RAIDfarclip" },
		{ cvar = "shadowSoft", label = "Soft shadows", type = "toggle" },
		{ cvar = "cameraDistanceMaxZoomFactor", label = "Max camera distance", type = "slider", min = 1, max = 4, step = 0.1 },
		{ cvar = "nameplateMaxDistance", label = "Nameplate distance", type = "slider", min = 20, max = 100, step = 1 },
	} } }
	EverySetting.SECTIONS = { "Graphics" }
	EverySetting.CVARS = { farclip = "1", RAIDfarclip = "1", shadowSoft = "1", cameraDistanceMaxZoomFactor = "1",
		nameplateMaxDistance = "1", nameplateEnemyNpcAuraDisplay = "1|f|1=Buffs|2=Debuffs" }
	W.Login()
	return EverySetting, ns.Options
end

-- Another addon's code: the game's SetCVar called from its folder.
local function Leatrix(cvar, value) W.FromAddon("Leatrix_Plus", SetCVar, cvar, value) end

-- The lines Every Setting printed that name `addon`.
local function Told(addon)
	local lines = {}
	for _, line in ipairs(W.chat) do
		if line:find(addon .. " changed", 1, true) then lines[#lines + 1] = line end
	end
	return lines
end

-- The body of the tooltip of the row showing `cvar`, in the open window.
local function Tip(o, cvar)
	for _, row in ipairs(o.rows) do
		if row:IsShown() and row.item and row.item.knob and row.item.knob.cvar == cvar then
			local lines = {}
			rawset(GameTooltip, "AddLine", function(_, text) lines[#lines + 1] = text end)
			W.Run(row.name, "OnEnter")
			rawset(GameTooltip, "AddLine", nil)
			return table.concat(lines, "\n")
		end
	end
end

T.test("changed by: another addon's change is put down to it, by its folder", function()
	local EverySetting = Start()
	T.eq(EverySetting.ChangedBy("farclip"), nil, "nothing seen yet")
	Leatrix("farclip", "3000")
	T.eq(C_CVar.GetCVar("farclip"), "3000")
	local addon, by = EverySetting.ChangedBy("farclip")
	T.eq(addon, "Leatrix_Plus", "through the game's SetCVar")
	T.eq(by, "Leatrix_Plus")
	T.eq(EverySetting.ChangedBy("FARCLIP"), "Leatrix_Plus", "in any letter case")
	W.FromAddon("DynamicCam", C_CVar.SetCVar, "cameraDistanceMaxZoomFactor", "2.6")
	T.eq(EverySetting.ChangedBy("cameraDistanceMaxZoomFactor"), "DynamicCam", "through C_CVar.SetCVar")
	W.FromAddon("Plater", C_CVar.SetCVarBitfield, "nameplateEnemyNpcAuraDisplay", 2, true)
	T.eq(EverySetting.ChangedBy("nameplateEnemyNpcAuraDisplay"), "Plater", "and C_CVar.SetCVarBitfield")
	-- Another addon calling a function of Blizzard's that sets a CVar is still that addon.
	W.FromAddon("Leatrix_Plus", W.FromAddon, "Blizzard_Settings_Shared", SetCVar, "shadowSoft", "1")
	T.eq(EverySetting.ChangedBy("shadowSoft"), "Leatrix_Plus", "through Blizzard's code")
end)

T.test("changed by: Every Setting's own change, the game's, the console's and a /run line's", function()
	local EverySetting = Start()
	EverySetting.Set("farclip", 5000)
	local addon, by = EverySetting.ChangedBy("farclip")
	T.eq(addon, "EverySetting", "its own folder")
	T.eq(by, "Every Setting")
	T.eq(EverySetting.ChangedBy("RAIDfarclip"), "EverySetting", "its raid twin too")

	W.FromAddon("Blizzard_Settings_Shared", SetCVar, "farclip", "4000")
	addon, by = EverySetting.ChangedBy("farclip")
	T.eq(addon, nil, "Blizzard's own options are no addon")
	T.eq(by, "the game")

	W.FromChat('SetCVar("farclip", 3000)')
	addon, by = EverySetting.ChangedBy("farclip")
	T.eq(addon, nil)
	T.eq(by, "a /run line or a macro")

	W.Console("farclip", "2000")
	T.eq(select(2, EverySetting.ChangedBy("farclip")), "a /run line or a macro", "until the game's CVAR_UPDATE is looked at")
	W.Advance(0.2)
	addon, by = EverySetting.ChangedBy("farclip")
	T.eq(addon, nil)
	T.eq(by, "the console or the game", "a change no hook saw")
	T.eq(#W.chat, 0, "none of them is told: only another addon is")
end)

T.test("changed by: a write that changes nothing leaves the last change as it was", function()
	local EverySetting = Start()
	W.FromAddon("Questie", SetCVar, "farclip", "1000")
	T.eq(EverySetting.ChangedBy("farclip"), nil, "the value it has already, with nothing noted before")
	Leatrix("farclip", "3000")
	W.FromAddon("DynamicCam", SetCVar, "farclip", "3000")
	T.eq(EverySetting.ChangedBy("farclip"), "Leatrix_Plus", "the same value again")
	W.Advance(0.2)
	T.eq(EverySetting.ChangedBy("farclip"), "Leatrix_Plus", "and CVAR_UPDATE agrees")
end)

T.test("changed by: a kept setting another addon changes is told once a session", function()
	local saved = {}
	local EverySetting = Start(saved)
	EverySetting.Set("farclip", 5000)
	Leatrix("farclip", "3000")
	local told = Told("Leatrix_Plus")
	T.eq(#told, 1)
	T.ok(told[1]:find("Leatrix_Plus changed View distance (farclip) to 3000, away from the 5000 you keep.", 1, true), told[1])
	EverySetting.Set("farclip", 5000)
	Leatrix("farclip", "2000")
	W.FromAddon("DynamicCam", SetCVar, "farclip", "2500")
	T.eq(#W.chat, 1, "once for the setting, whichever addon")
	T.eq(EverySetting.ChangedBy("farclip"), "DynamicCam", "though the tooltip has the last")

	Leatrix("shadowSoft", "1")
	T.eq(#W.chat, 1, "a setting the profile doesn't keep isn't told")
	EverySetting.Set("shadowSoft", 1)
	Leatrix("shadowSoft", "1")
	T.eq(#W.chat, 1, "nor one set to the value kept")
	Leatrix("shadowSoft", "0")
	T.eq(#Told("Leatrix_Plus"), 2, "another kept setting is told on its own")
	T.ok(W.chat[2]:find("Soft shadows (shadowSoft) to 0, away from the 1 you keep", 1, true), W.chat[2])
	EverySetting.AllGroups()
	EverySetting.SetFlag("nameplateEnemyNpcAuraDisplay", 1, false)
	W.FromAddon("Plater", C_CVar.SetCVarBitfield, "nameplateEnemyNpcAuraDisplay", 1, true)
	T.eq(W.chat[3], "|cffffb000Every Setting|r: Plater changed nameplateEnemyNpcAuraDisplay, away from what you keep."
		.. " Every Setting sets yours again at the next login, or now with |cffffff00/every apply|r.", "a packed set of flags shows no value")

	-- The next session tells it again, once its kept values are set.
	Start(saved)
	T.eq(C_CVar.GetCVar("farclip"), "5000", "set again at login")
	T.eq(#W.chat, 0)
	Leatrix("farclip", "3000")
	T.eq(#Told("Leatrix_Plus"), 1, "told again in a new session")
end)

T.test("changed by: another addon's change inside Every Setting's own is that addon's", function()
	-- One that sets a CVar back from CVAR_UPDATE, which the game sends during the write.
	local EverySetting = Start()
	local guard = CreateFrame("Frame")
	guard:RegisterEvent("CVAR_UPDATE")
	guard:SetScript("OnEvent", function(_, _, cvar)
		if cvar == "farclip" and C_CVar.GetCVar("farclip") ~= "3000" then Leatrix("farclip", "3000") end
	end)
	EverySetting.Set("farclip", 5000)
	T.eq(C_CVar.GetCVar("farclip"), "3000")
	T.eq(EverySetting.ChangedBy("farclip"), "Leatrix_Plus", "the last change is the other addon's")
	W.Advance(0.2)
	T.eq(EverySetting.ChangedBy("farclip"), "Leatrix_Plus")
end)

T.test("changed by: the tooltip names it, and says where the game saves the setting", function()
	local EverySetting, o = Start()
	EverySetting_OpenOptions()
	local tip = Tip(o, "farclip")
	T.ok(not tip:find("Last changed", 1, true), "nothing seen, nothing said")
	T.ok(tip:find("CVar: farclip, and RAIDfarclip in raids. The game saves it on this computer.", 1, true), tip)
	Leatrix("farclip", "3000")
	tip = Tip(o, "farclip")
	T.ok(tip:find("Last changed by |cffffffffLeatrix_Plus|r, since Every Setting loaded.", 1, true), tip)
	EverySetting.Set("farclip", 5000)
	T.ok(Tip(o, "farclip"):find("Last changed by |cffffffffEvery Setting|r", 1, true))

	T.ok(Tip(o, "cameraDistanceMaxZoomFactor"):find("The game saves it for your account.", 1, true))
	tip = Tip(o, "nameplateMaxDistance")
	T.ok(tip:find("The game saves it for each character.|r", 1, true), tip)
	EverySetting.Set("nameplateMaxDistance", 80)
	tip = Tip(o, "nameplateMaxDistance")
	T.ok(tip:find("The game saves it for each character. Every character on this profile gets the value you keep.", 1, true), tip)
	T.eq(EverySetting.Knob("farclip").storage, "computer")
	T.eq(EverySetting.Knob("cameraDistanceMaxZoomFactor").storage, "account")
	T.eq(EverySetting.Knob("nameplateMaxDistance").storage, "character")
end)

T.test("changed by: a locked setting set through the game's own function is Every Setting's", function()
	local EverySetting = W.Load({ danger = true })
	local cvar = W.AddCVar("VoiceOutputVolume", "100", { locked = true })
	EverySetting.GROUPS = {}
	EverySetting.CVARS = { VoiceOutputVolume = "1|s|0|100|1" }
	-- The game's function sets the CVar, and sends CVAR_UPDATE, without C_CVar.SetCVar.
	_G.C_VoiceChat = { SetOutputVolume = function(volume)
		cvar.value = tostring(volume)
		W.Fire("CVAR_UPDATE", "VoiceOutputVolume", cvar.value)
	end }
	W.Login()
	EverySetting.RawKnob("VoiceOutputVolume", "")
	T.eq(EverySetting.Set("VoiceOutputVolume", 60), "60")
	T.eq(EverySetting.ChangedBy("VoiceOutputVolume"), "EverySetting")
	W.Advance(0.2)
	T.eq(EverySetting.ChangedBy("VoiceOutputVolume"), "EverySetting", "not the console")
	_G.C_VoiceChat = nil
end)

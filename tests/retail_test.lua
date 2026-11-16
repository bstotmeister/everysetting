-- The two clients: WoW Forever, whose CVar list is data/cvars.lua, and retail, whose
-- list is data/ranges/70783/retail/cvars.lua. Each gets its own ranges, and retail
-- leaves out the tuned settings it has no CVar for.

local T = ...
local W = dofile("tests/wow.lua")

local RETAIL = "data/ranges/70783/retail/cvars.lua"
local SOURCES = { ui = true, help = true, api = true, probe = true, preset = true, command = true }

-- What #68 found retail has no CVar for.
local LACKS = { "outlineModeShowLootEffectWhenDisabled", "HDROutput", "useHDRBrightness", "useHDRPeakBrightness",
	"giQuality", "bloomEnable", "classicStyleWorldText" }

-- A logged-in client with every CVar of `path`, retail's if `client` says so.
local function Start(path, client)
	local EverySetting, ns = W.Load(nil, nil, nil, client)
	for _, cvar in ipairs(dofile(path).cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	return EverySetting, ns
end

local function StyleNamed(EverySetting, name)
	for _, style in ipairs(EverySetting.STYLES) do
		if style.name == name then return style end
	end
end

T.test("retail: Client says which game it is", function()
	T.eq(W.Load().Client(), "forever")
	T.eq(W.Load(nil, nil, nil, "retail").Client(), "retail")
end)

T.test("retail: a range of its own where retail's engine keeps another", function()
	local EverySetting = Start(RETAIL, "retail")
	local camera = EverySetting.Knob("cameraDistanceMaxZoomFactor")
	T.eq(select(2, EverySetting.Bounds(camera)), 2.6, "camera distance stops at 2.6")
	T.eq(EverySetting.Normalize(camera, 4), "2.6")
	T.ok(camera.tip:find("2.6", 1, true), "and its tip says so")
	local shadows = {}
	for _, option in ipairs(EverySetting.Knob("shadowTextureSize").options) do shadows[#shadows + 1] = option[1] end
	T.eq(table.concat(shadows, " "), "512 1024 2048", "the shadow sizes retail takes")
	local forever = Start("data/cvars.lua")
	T.eq(select(2, forever.Bounds(forever.Knob("cameraDistanceMaxZoomFactor"))), 4, "Forever keeps its own")
	T.eq(#forever.Knob("shadowTextureSize").options, 6)
end)

T.test("retail: each knob's retail range has a source, and holds retail's default", function()
	local EverySetting = Start(RETAIL, "retail")
	local default = {}
	for _, cvar in ipairs(dofile(RETAIL).cvars) do default[cvar[1]:lower()] = cvar[2] end
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			if knob.retail then T.ok(SOURCES[knob.retail.src], knob.cvar .. "'s retail range needs a source (src)") end
			local value = default[knob.cvar:lower()]
			if value and not knob.cvar:find("^@") then
				local shown = EverySetting.Normalize(knob, value)
				T.ok(shown and (tonumber(shown) == tonumber(value) or shown == value),
					knob.cvar .. ": retail's default " .. value .. " isn't in its range or options")
			end
		end
	end
end)

T.test("retail: the tuned settings it has no CVar for are left out of the window", function()
	local _, ns = Start(RETAIL, "retail")
	EverySetting_OpenOptions()
	local listed = {}
	for _, item in ipairs(ns.Options.view) do
		if item.knob then listed[item.knob.cvar] = true end
		T.ok(not (item.header and item.group and item.group.title == "HDR"), "HDR's group, which has nothing in retail")
	end
	for _, cvar in ipairs(LACKS) do T.ok(not listed[cvar], cvar .. " has a row") end
	T.ok(listed.cameraDistanceMaxZoomFactor and listed.shadowTextureSize, "the rest are there")
	-- The sidebar's group buttons, by title.
	local function Buttons(o)
		local titles = {}
		for _, b in ipairs(o.refs.side) do
			for _, g in ipairs(b.groups) do titles[g.group.title] = true end
		end
		return titles
	end
	T.ok(not Buttons(ns.Options).HDR, "nor a button in the sidebar")
	local _, forever = Start("data/cvars.lua")
	EverySetting_OpenOptions()
	listed = {}
	for _, item in ipairs(forever.Options.view) do
		if item.knob then listed[item.knob.cvar] = true end
	end
	for _, cvar in ipairs(LACKS) do T.ok(listed[cvar], cvar .. " has no row in Forever") end
	T.ok(Buttons(forever.Options).HDR, "Forever has HDR's button")
end)

T.test("retail: styles and the built-in presets stay inside retail's range", function()
	local EverySetting = Start(RETAIL, "retail")
	T.eq(EverySetting.StylePreset(StyleNamed(EverySetting, "Competitive")).cameraDistanceMaxZoomFactor, "2.6")
	local photo = EverySetting.StylePreset(StyleNamed(EverySetting, "Photo"))
	T.eq(photo.shadowTextureSize, "2048", "4096 is past retail's biggest")
	T.eq(photo.bloomEnable, nil, "nothing for a CVar retail lacks")
	T.eq(EverySetting.StylePreset(StyleNamed(EverySetting, "Immersive")).shadowTextureSize, "1024",
		"High's 1536, which retail turns down, is the size below it")
	for _, style in ipairs(EverySetting.STYLES) do
		for cvar, value in pairs(EverySetting.StylePreset(style)) do
			T.eq(EverySetting.Normalize(EverySetting.Knob(cvar), value), value, style.name .. ": " .. cvar)
		end
	end
	EverySetting.ApplyPreset(photo)
	T.eq(C_CVar.GetCVar("cameraDistanceMaxZoomFactor"), "2.6")
	T.eq(C_CVar.GetCVar("shadowTextureSize"), "2048")
	local forever = Start("data/cvars.lua")
	T.eq(forever.StylePreset(StyleNamed(forever, "Photo")).shadowTextureSize, "4096", "Forever keeps its own")
	T.eq(forever.StylePreset(StyleNamed(forever, "Competitive")).cameraDistanceMaxZoomFactor, "4")
end)

-- The options of a knob's menu, as "value=Label" each.
local function Menu(knob)
	local options = {}
	for _, option in ipairs(knob.options) do options[#options + 1] = option[1] .. "=" .. option[2] end
	return table.concat(options, " ")
end

T.test("retail: a CVar only it has sets, keeps over a login, resets and undoes", function()
	local EverySetting = Start(RETAIL, "retail")
	EverySetting.AllGroups()
	T.eq(EverySetting.Knob("volumeFogDisableNoise").type, "toggle")
	T.eq(EverySetting.Set("volumeFogDisableNoise", "1"), "1")
	T.eq(C_CVar.GetCVar("volumeFogDisableNoise"), "1")
	T.eq(EverySettingDB.profiles.Default.volumeFogDisableNoise, "1", "kept")
	-- The next login sets it again, over what the game had.
	local saved = EverySettingDB
	EverySetting = W.Load(saved, nil, nil, "retail")
	for _, cvar in ipairs(dofile(RETAIL).cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	T.eq(C_CVar.GetCVar("volumeFogDisableNoise"), "1", "set again at login")
	EverySetting.Reset("volumeFogDisableNoise")
	T.eq(C_CVar.GetCVar("volumeFogDisableNoise"), "0", "reset to how it was")
	T.eq(EverySettingDB.profiles.Default.volumeFogDisableNoise, nil)
	EverySetting.Undo()
	T.eq(C_CVar.GetCVar("volumeFogDisableNoise"), "1", "and undone")
	-- A menu of retail's own, for a CVar both games have.
	EverySetting.AllGroups()
	T.eq(EverySetting.Set("LowLatencyMode", "4"), "4")
	T.eq(EverySetting.Knob("LowLatencyMode").options[5][2], "Intel XeLL", "4 is retail's XeLL")
	EverySetting.Undo()
	T.eq(C_CVar.GetCVar("LowLatencyMode"), "0")
end)

T.test("retail: the window lists the CVars only retail has, each in its section", function()
	local EverySetting = Start(RETAIL, "retail")
	local sectionOf = {}
	for _, group in ipairs(EverySetting.AllGroups()) do
		for _, knob in ipairs(group.items) do sectionOf[knob.cvar] = group.title end
	end
	T.eq(sectionOf.SSAOType, "Graphics")
	T.eq(sectionOf.volumeFogUse16BitTexture, "Graphics")
	T.eq(sectionOf.KioskCharacterTemplateSet, "Debug and development")
	T.eq(sectionOf.activeCUFProfile, "Other", "what the game remembers")
	T.eq(sectionOf.LibOpenRaidTempCache, "Other", "an addon's")
	T.eq(sectionOf.advFlyPitchControlCameraChase, "Camera")
	local forever = Start("data/cvars.lua")
	sectionOf = {}
	for _, group in ipairs(forever.AllGroups()) do
		for _, knob in ipairs(group.items) do sectionOf[knob.cvar] = group.title end
	end
	T.eq(sectionOf.SSAOType, nil, "Forever has no such CVar")
	T.eq(sectionOf.advFlyPitchControlCameraChase, "Camera")
end)

T.test("retail: a plain name for a CVar only retail has is its row's name there", function()
	local EverySetting = Start(RETAIL, "retail")
	local retail, forever = {}, {}
	for _, cvar in ipairs(dofile(RETAIL).cvars) do retail[cvar[1]] = true end
	for _, cvar in ipairs(W.ForeverCVars()) do forever[cvar[1]] = true end
	for name, label in pairs(EverySetting.NAMES) do
		if not forever[name] then
			T.ok(retail[name] and EverySetting.RETAIL_CVARS[name], name .. " is a CVar, spelled as retail spells it")
			T.eq(EverySetting.RawKnob(name, "").label, label, name)
		end
	end
	T.eq(EverySetting.RawKnob("useShadowMapping", "").label, "Shadow mapping")
end)

T.test("retail: a control retail's menu gives another way is retail's there, and Forever keeps its own", function()
	local EverySetting = Start(RETAIL, "retail")
	EverySetting.AllGroups()
	T.eq(Menu(EverySetting.Knob("nameplateStyle")), "0=Modern 1=Thin 2=Block 3=Clean health 4=Cast focus 5=Legacy red")
	T.eq(Menu(EverySetting.Knob("graphicsComputeEffects")), "0=Disabled 1=Low 2=Medium 3=High 4=Ultra")
	T.eq(EverySetting.Knob("graphicsParticleDensity").type, "choice")
	T.eq(EverySetting.Knob("advFlyKeyboardMinPitchFactor").type, "slider")
	local forever = Start("data/cvars.lua")
	forever.AllGroups()
	T.eq(Menu(forever.Knob("nameplateStyle")), "1=Thin 0=Modern 2=Block 4=Cast focus")
	T.eq(Menu(forever.Knob("LowLatencyMode")), "0=Auto detect 1=Disabled 2=Built-in 3=NVIDIA Reflex 4=NVIDIA Reflex + Boost 5=Intel XeLL")
	T.eq(forever.Knob("graphicsParticleDensity").type, "text")
	T.eq(forever.Knob("advFlyKeyboardMinPitchFactor").type, "text")
end)

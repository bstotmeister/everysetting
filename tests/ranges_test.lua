-- RANGES.md and data/ranges/: the page is what scripts/gen-ranges.lua writes from the
-- addon's files, every tuned setting is on it with a source it explains, and what the
-- client kept is well formed and agrees with the ranges.

local T = ...
local W = dofile("tests/wow.lua")

-- A logged-in client with every CVar of `cvars`, a list as data/cvars.lua has it, retail's
-- if `client` says so.
local function Start(cvars, client)
	local game = W.Load(nil, nil, nil, client)
	for _, cvar in ipairs(cvars) do W.AddCVar(cvar[1], cvar[2] or "") end
	W.Login()
	return game
end

local EverySetting = Start(W.ForeverCVars())

-- The page as scripts/gen-ranges.lua writes it now.
local function Page()
	local page
	assert(loadfile("scripts/gen-ranges.lua"))(function(text) page = text end)
	return page
end

-- Whether two CVar values are the same: "1" and "1.000" are.
local function Same(a, b)
	local x, y = tonumber(a), tonumber(b)
	if x and y then return math.abs(x - y) < 1e-6 end
	return a == b
end

-- Whether a value is one the knob's slider, menu or checkbox offers.
local function Offered(knob, value)
	if knob.type == "slider" then
		local n = tonumber(value)
		return n ~= nil and n >= knob.min and n <= knob.max
	elseif knob.type == "toggle" then
		return Same(value, "0") or Same(value, "1")
	elseif knob.type == "choice" then
		for _, option in ipairs(knob.options) do
			if Same(tostring(option[1]), value) then return true end
		end
	end
	return false
end

T.test("ranges: RANGES.md is what scripts/gen-ranges.lua writes", function()
	local f = assert(io.open("RANGES.md"), "there's no RANGES.md")
	local kept = f:read("*a"):gsub("\r\n", "\n")
	f:close()
	T.ok(kept == Page(), "RANGES.md is out of date. Write it again: lua scripts/gen-ranges.lua > RANGES.md")
end)

T.test("ranges: every tuned setting is on the page, with a source the page explains", function()
	local page = Page()
	local sources = {} -- CVar -> the last cell of its row
	for cvar, source in page:gmatch("\n| [^|]* | [^|]* | `([^`|]+)` | [^|]* | `(%a+)` |") do sources[cvar] = source end
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			-- A setting that isn't a CVar ("@...") is only counted.
			T.eq(sources[knob.cvar], not knob.cvar:find("^@") and knob.src or nil, knob.cvar .. "'s source on the page")
			T.ok(page:find("\n| `" .. knob.src .. "` | ", 1, true), "the page doesn't explain " .. knob.src)
		end
	end
end)

T.test("ranges: what the client kept is well formed, and agrees with the ranges", function()
	local paths = T.lines("ls data/ranges/*/*/probes.lua")
	T.ok(#paths > 0, "data/ranges has no results")
	for _, path in ipairs(paths) do
		local build = path:match("^data/ranges/(%d+)/[%l%d-]+/probes%.lua$")
		T.ok(build, path .. ": the folders are <build>/<platform>, the platform in lower case")
		local run = dofile(path)
		T.eq(run.build, build, path .. ": the build is its folder's")
		T.ok(type(run.version) == "string" and type(run.platform) == "string", path .. " needs a version and a platform")
		T.ok(run.note == nil or type(run.note) == "string", path .. ": the note is text")
		T.ok(type(run.probes) == "table" and #run.probes > 0, path .. " has no probes")
		-- A retail run is checked against retail's CVars, with retail's controls: the list
		-- beside it, which a run on another platform than the Mac's has, or the Mac's.
		local retail = run.game == "WoW retail"
		T.ok(run.game == nil or retail, path .. ": the game is WoW retail, or none for WoW Forever")
		T.eq(retail, path:find("/retail[/-]") ~= nil, path .. ": a retail run's folder starts with retail")
		local list = path:gsub("probes%.lua$", "cvars.lua")
		if not T.lines("ls " .. list .. " 2>/dev/null")[1] then list = ("data/ranges/%s/retail/cvars.lua"):format(build) end
		local game = retail and Start(dofile(list).cvars, "retail") or EverySetting
		for i, probe in ipairs(run.probes) do
			local where = ("%s, probe %d"):format(path, i)
			for j = 1, 5 do
				T.ok(type(probe[j]) == "string", where .. " needs five strings: the CVar, the two values set and the two kept")
			end
			T.ok(probe.note == nil or type(probe.note) == "string", where .. ": the note is text")
			local knob = game.RawKnob(probe[1], "")
			T.ok(knob, where .. ": the client has no CVar named " .. probe[1])
			T.eq(probe[1], knob.cvar, where .. ": spelled as the client spells it")
			-- A value the control offers that the engine didn't keep: the range is wrong
			-- there, or there's a reason, which the probe's note gives.
			for j = 2, 3 do
				T.ok(not Offered(knob, probe[j]) or Same(probe[j], probe[j + 2]) or probe.note,
					("%s: %s offers %s, and the engine didn't keep it. Fix the range, or say why in a note"):format(where, knob.cvar, probe[j]))
			end
		end
		if game ~= EverySetting then EverySetting = Start(W.ForeverCVars()) end
	end
end)

T.test("ranges: the frame rates measured are well formed, for tuned settings, at values they offer", function()
	for _, path in ipairs(T.lines("ls data/ranges/*/*/costs.lua 2>/dev/null")) do
		local build = path:match("^data/ranges/(%d+)/[%l%d-]+/costs%.lua$")
		T.ok(build, path .. ": the folders are <build>/<platform>, the platform in lower case")
		local run = dofile(path)
		T.eq(run.build, build, path .. ": the build is its folder's")
		T.ok(type(run.version) == "string" and type(run.platform) == "string", path .. " needs a version and a platform")
		T.ok(run.note == nil or type(run.note) == "string", path .. ": the note is text")
		T.ok(type(run.costs) == "table" and #run.costs > 0, path .. " has no frame rates")
		for i, line in ipairs(run.costs) do
			local where = ("%s, line %d"):format(path, i)
			T.ok(type(line[1]) == "string" and type(line[2]) == "string" and type(line[3]) == "string",
				where .. " needs the CVar and the two values set, as text")
			T.ok(type(line[4]) == "number" and line[4] > 0 and type(line[5]) == "number" and line[5] > 0,
				where .. " needs the frame rate at each, as a number")
			T.ok(line.note == nil or type(line.note) == "string", where .. ": the note is text")
			local knob = EverySetting.Knob(line[1])
			T.ok(knob and knob.cvar == line[1], where .. ": " .. line[1] .. " isn't a tuned setting, spelled as Knobs.lua spells it")
			T.ok(Offered(knob, line[2]) and Offered(knob, line[3]), where .. ": a value the setting doesn't offer")
		end
	end
end)

T.test("ranges: what a console command printed is well formed, and each command with a row was tried", function()
	local tried = {} -- command -> true
	for _, path in ipairs(T.lines("ls data/ranges/*/*/probes.lua")) do
		for i, command in ipairs(dofile(path).commands or {}) do
			local where = ("%s, command %d"):format(path, i)
			for j = 1, 3 do
				T.ok(type(command[j]) == "string", where .. " needs three strings: the command, the value and what it printed")
			end
			T.ok(command.note == nil or type(command.note) == "string", where .. ": the note is text")
			T.ok(EverySetting.RawKnob(command[1], "") == nil, where .. ": " .. command[1] .. " is a CVar")
			tried[command[1]] = true
		end
	end
	for _, group in ipairs(EverySetting.GROUPS) do
		for _, knob in ipairs(group.items) do
			local command = knob.cvar:match("^@console:(%a+)")
			if command then T.ok(tried[command], command .. " has a row, and nothing says what it took") end
		end
	end
end)

T.test("ranges: scripts/gen-probes.lua turns a saved check into probes", function()
	local path = os.tmpname()
	local f = assert(io.open(path, "w"))
	f:write([[EverySettingDB = { dump = { version = "1.60.1", build = "70938", cvars = {} }, check = {
		{ cvar = "groundEffectDensity", ok = true, min = "16", max = "256", below = "48", above = "48" },
		{ cvar = "cameraDistanceMaxZoomFactor", ok = true, min = "1", max = "4", below = "2", above = "2" },
		{ cvar = "screenshotFormat", ok = true, kept = { "jpeg", "png", "tga" } },
		{ cvar = "volumeFog", ok = false, kept = { "0", "0" } },
	} }]])
	f:close()
	local file
	assert(loadfile("scripts/gen-probes.lua"))(path, "Windows, Direct3D 12", function(text) file = text end)
	os.remove(path)
	local run = assert((loadstring or load)(file))()
	T.eq(run.version, "1.60.1")
	T.eq(run.build, "70938")
	T.eq(run.platform, "Windows, Direct3D 12")
	local lines = {}
	for i, probe in ipairs(run.probes) do lines[i] = table.concat(probe, " ") end
	T.eq(table.concat(lines, "\n"), table.concat({
		"groundEffectDensity 16 256 16 256", -- a slider's ends,
		"groundEffectDensity 8 264 48 48", -- and one step past each
		"cameraDistanceMaxZoomFactor 1 4 1 4",
		"cameraDistanceMaxZoomFactor 0.9 4.1 2 2",
		"screenshotFormat jpeg jpeg jpeg jpeg", -- each of a menu's options
		"screenshotFormat png png png png",
		"screenshotFormat tga tga tga tga",
		"volumeFog 0 0 0 0", -- a checkbox's 0 and 1
		"volumeFog 1 1 0 0",
	}, "\n"))
end)

T.test("ranges: scripts/gen-probes.lua reads a check from retail by retail's ranges", function()
	local path = os.tmpname()
	local f = assert(io.open(path, "w"))
	-- An older dump, which doesn't name its game: retail's version says it.
	f:write([[EverySettingDB = { dump = { version = "12.1.5", build = "70783", cvars = {} }, check = {
		{ cvar = "cameraDistanceMaxZoomFactor", ok = true, min = "1", max = "2.6", below = "1", above = "2.6" },
		{ cvar = "shadowTextureSize", ok = true, kept = { "512", "1024", "2048" } },
	} }]])
	f:close()
	local file
	assert(loadfile("scripts/gen-probes.lua"))(path, "Windows, Direct3D 12", function(text) file = text end)
	os.remove(path)
	T.ok(file:find("^%-%- What the engine kept on WoW retail 12.1.5"), "the comment names the game")
	local run = assert((loadstring or load)(file))()
	T.eq(run.game, "WoW retail")
	local lines = {}
	for i, probe in ipairs(run.probes) do lines[i] = table.concat(probe, " ") end
	T.eq(table.concat(lines, "\n"), table.concat({
		"cameraDistanceMaxZoomFactor 1 2.6 1 2.6", -- retail's end, not Forever's 4
		"cameraDistanceMaxZoomFactor 0.9 2.7 1 2.6",
		"shadowTextureSize 512 512 512 512", -- retail's three sizes
		"shadowTextureSize 1024 1024 1024 1024",
		"shadowTextureSize 2048 2048 2048 2048",
	}, "\n"))
end)

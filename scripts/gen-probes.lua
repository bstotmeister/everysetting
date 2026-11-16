-- Writes a probes.lua for data/ranges/ from what /every check saved: a client's results
-- for every tuned setting, as one line for each probe. Runs on plain Lua (5.1 to 5.5).
--
-- In game, type /every dump, /every check and then /reload: that writes both to
-- WTF/Account/<account>/SavedVariables/EverySetting.lua. Copy the file before the next
-- reload or logout, which writes it again without them. Then, from the repo root:
--
--   lua scripts/gen-probes.lua <path to that EverySetting.lua> "<platform>" > probes.new
--   mv probes.new data/ranges/<build>/<folder>/probes.lua
--
-- <platform> is the client in words ("Windows, Direct3D 12"). data/ranges/README.md says
-- how the folders are named. The check saves what the engine kept and not what was set, so
-- the values set are read from EverySetting/Knobs.lua: run this at the commit that client's
-- addon was built from.

local savedPath, platform, take = ... -- the tests pass a function that takes the file
if not savedPath or not platform then
	io.stderr:write('usage: lua scripts/gen-probes.lua <path to SavedVariables/EverySetting.lua> "<platform>"\n')
	os.exit(1)
end

-- The saved variables file sets globals. They're read into a table of their own.
local function Globals(path)
	local env = {}
	local chunk
	if setfenv then -- Lua 5.1
		chunk = assert(loadfile(path))
		setfenv(chunk, env)
	else
		chunk = assert(loadfile(path, "t", env))
	end
	chunk()
	return env
end

local db = Globals(savedPath).EverySettingDB or {}
if type(db.check) ~= "table" or type(db.dump) ~= "table" then
	io.stderr:write(savedPath .. " needs both a check and a dump. Type /every dump, /every check and then /reload in game first.\n")
	os.exit(1)
end

-- The game the check was in, which the dump names. A dump from before it did goes by
-- its version: Forever's is 1.x, retail's 12.x.
local client = db.dump.client or (tostring(db.dump.version):match("^1%.") and "forever" or "retail")
local game = client == "retail" and "WoW retail" or "WoW Forever"

local EverySetting = {}
local ns = { EverySetting = EverySetting }
for _, file in ipairs({ "Locales/enUS.lua", "Knobs.lua" }) do assert(loadfile("EverySetting/" .. file))("EverySetting", ns) end
local knobOf = {}
for _, group in ipairs(EverySetting.GROUPS) do
	for _, knob in ipairs(group.items) do
		for field, value in pairs(knob[client] or {}) do knob[field] = value end -- the range that client checked
		knobOf[knob.cvar] = knob
	end
end

-- A value as it's written here: 0.05, 10000. The same on every Lua.
local function Text(value)
	if type(value) ~= "number" then return tostring(value) end
	return (("%.4f"):format(value):gsub("(%.%d-)0+$", "%1"):gsub("%.$", ""))
end

local function Quote(s)
	return '"' .. tostring(s):gsub('[\\"]', "\\%0") .. '"'
end

local out = {
	("-- What the engine kept on %s %s (build %s), %s: /every check, as"):format(game, tostring(db.dump.version), tostring(db.dump.build), platform),
	"-- scripts/gen-probes.lua wrote it. data/ranges/README.md describes a line.",
	"return {",
	("\t%sversion = %s, build = %s, platform = %s,"):format(client == "retail" and "game = " .. Quote(game) .. ", " or "",
		Quote(db.dump.version), Quote(db.dump.build), Quote(platform)),
	"\tprobes = {",
}
local function Probe(cvar, low, high, keptLow, keptHigh)
	out[#out + 1] = ("\t\t{ %s, %s, %s, %s, %s },"):format(Quote(cvar), Quote(Text(low)), Quote(Text(high)), Quote(keptLow), Quote(keptHigh))
end

-- As Check in Core.lua tries them: a slider's ends and one step past each, a checkbox's
-- 0 and 1, and each of a menu's options.
for _, result in ipairs(db.check) do
	local knob = knobOf[result.cvar]
	if not knob then
		io.stderr:write(result.cvar .. " was checked, and Knobs.lua here has no such setting. Is this the commit that client's addon was built from?\n")
		os.exit(1)
	end
	if knob.type == "slider" then
		local step = knob.step or 1
		Probe(knob.cvar, knob.min, knob.max, result.min, result.max)
		Probe(knob.cvar, knob.min - step, knob.max + step, result.below, result.above)
	else
		local tries = { "0", "1" }
		if knob.type == "choice" then
			tries = {}
			for i, option in ipairs(knob.options) do tries[i] = option[1] end
		end
		for i, value in ipairs(tries) do Probe(knob.cvar, value, value, result.kept[i], result.kept[i]) end
	end
end
out[#out + 1] = "\t},"
out[#out + 1] = "}"

local file = table.concat(out, "\n") .. "\n"
if type(take) == "function" then take(file) else io.write(file) end

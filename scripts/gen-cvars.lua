-- Writes data/cvars.lua from what /every dump saved. Runs on plain Lua (5.1 to 5.5).
--
-- In game, type /every dump and then /reload: that writes the client's CVar list
-- to WTF/Account/<account>/SavedVariables/EverySetting.lua. Then, from the repo root:
--
--   lua scripts/gen-cvars.lua <path to SavedVariables/EverySetting.lua> data/cvars.lua > cvars.new
--   mv cvars.new data/cvars.lua
--
-- The second path is the list as it is now, and can be left out. With it, the
-- CVars added and removed since are printed (to stderr), and a CVar that was set
-- in the dumping client's Config.wtf keeps the category and help it had: the game
-- gives those back with category 5 and no help text.

local dumpPath, oldPath = ...
if not dumpPath then
	io.stderr:write("usage: lua scripts/gen-cvars.lua <path to SavedVariables/EverySetting.lua> [old data/cvars.lua]\n")
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

local dump = (Globals(dumpPath).EverySettingDB or {}).dump
if type(dump) ~= "table" or type(dump.cvars) ~= "table" then
	io.stderr:write(dumpPath .. " has no dump. Type /every dump and then /reload in game first.\n")
	os.exit(1)
end

local old = {} -- name -> its entry in the old list
if oldPath then
	for _, cvar in ipairs(dofile(oldPath).cvars) do old[cvar[1]] = cvar end
end

-- A string as Lua source, the way the list has always been written.
local function Quote(s)
	return '"' .. s:gsub('[\\"]', "\\%0"):gsub("\n", "\\n"):gsub("\r", "\\r") .. '"'
end

-- The dump's flags as letters, in this order.
local FLAGS = { { "account", "a" }, { "character", "c" }, { "secure", "s" }, { "locked", "l" }, { "readOnly", "r" } }

local cvars = {}
for i, cvar in ipairs(dump.cvars) do cvars[i] = cvar end
table.sort(cvars, function(a, b)
	local x, y = a.name:lower(), b.name:lower()
	if x ~= y then return x < y end
	return a.name < b.name
end)

local out = { [[
-- Every CVar in the WoW Forever client, as /every dump saved it: the game has no
-- public list. Used by the tests (a knob's CVar must exist) and by
-- scripts/gen-cvars.lua. Not shipped with the addon.
--
-- Each entry: { name, default, category, help, flags }. The category is the
-- game's Enum.ConsoleCategory (0 debug, 1 graphics, 2 console, 4 game,
-- 5 default, 6 net, 7 sound, 10 none). Flags: a = stored per account on the
-- server, c = stored per character, s = secure (can't be set in combat),
-- l = locked, r = read-only.
--
-- A CVar that was set in the dumping client's Config.wtf comes back from the
-- game with category 5 and no help text, whatever it really has.
return {]],
	("\tversion = %s, build = %s,"):format(Quote(tostring(dump.version)), Quote(tostring(dump.build))),
	"\tcvars = {",
}
local seen, added, removed = {}, {}, {}
for _, cvar in ipairs(cvars) do
	local category, help = cvar.category, cvar.help or ""
	local was = old[cvar.name]
	if was and category == 5 and help == "" then category, help = was[3], was[4] end
	local flags = ""
	for _, flag in ipairs(FLAGS) do
		if cvar[flag[1]] then flags = flags .. flag[2] end
	end
	out[#out + 1] = ("\t\t{ %s, %s, %s, %s, %s },"):format(Quote(cvar.name),
		cvar.default ~= nil and Quote(tostring(cvar.default)) or "nil", tostring(category), Quote(help), Quote(flags))
	seen[cvar.name] = true
	if oldPath and not was then added[#added + 1] = cvar.name end
end
out[#out + 1] = "\t},"
out[#out + 1] = "}"
io.write(table.concat(out, "\n"), "\n")

if oldPath then
	for name in pairs(old) do
		if not seen[name] then removed[#removed + 1] = name end
	end
	table.sort(removed, function(a, b) return a:lower() < b:lower() end)
	for _, name in ipairs(added) do io.stderr:write("added: " .. name .. "\n") end
	for _, name in ipairs(removed) do io.stderr:write("removed: " .. name .. "\n") end
	io.stderr:write(("%d CVars: %d added, %d removed\n"):format(#cvars, #added, #removed))
end

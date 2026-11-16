-- Runs every tests/*_test.lua outside the game, on plain Lua (5.1 to 5.5).
-- Usage, from the repo root: lua tests/run.lua

local T = { passed = 0, failed = {} }

-- Runs `fn` as a test named `name`. A failed check raises an error, which ends it.
function T.test(name, fn)
	local ok, err = pcall(fn)
	if ok then
		T.passed = T.passed + 1
	else
		T.failed[#T.failed + 1] = name .. "\n      " .. tostring(err)
	end
end

function T.ok(value, what)
	if not value then error(what or "expected a true value", 2) end
end

function T.eq(got, want, what)
	if got ~= want then
		error(("%s: got %s, want %s"):format(what or "values differ", tostring(got), tostring(want)), 2)
	end
end

-- The lines `command` prints.
function T.lines(command)
	local out = {}
	local p = assert(io.popen(command))
	for line in p:lines() do out[#out + 1] = line end
	p:close()
	return out
end

for _, path in ipairs(T.lines("ls tests/*_test.lua")) do
	assert(loadfile(path))(T)
end

for _, failure in ipairs(T.failed) do print("FAIL  " .. failure) end
print(("%d passed, %d failed"):format(T.passed, #T.failed))
os.exit(#T.failed == 0 and 0 or 1)

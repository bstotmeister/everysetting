-- The TOC lists the files the game loads: each must exist, and none can be left out.

local T = ...

local listed, interface = {}, nil
for raw in io.lines("EverySetting/EverySetting.toc") do
	local line = raw:gsub("\r$", "")
	interface = interface or line:match("^## Interface:%s*(.-)%s*$")
	if line ~= "" and not line:match("^#") then listed[#listed + 1] = (line:gsub("\\", "/")) end
end

-- One .toc for both clients: each loads an addon that names its interface number.
T.test("toc: targets WoW Forever and retail", function()
	T.eq(interface, "16001, 120105", "Interface")
end)

T.test("toc: every listed file exists", function()
	T.ok(#listed > 0, "the TOC lists no files")
	for _, file in ipairs(listed) do
		local f = io.open("EverySetting/" .. file)
		T.ok(f, file .. " is listed in the TOC but doesn't exist")
		f:close()
	end
end)

T.test("toc: every Lua file is listed", function()
	local inToc = {}
	for _, file in ipairs(listed) do inToc[file] = true end
	for _, path in ipairs(T.lines("find EverySetting -name '*.lua'")) do
		local file = path:gsub("^EverySetting/", "")
		T.ok(inToc[file], file .. " isn't listed in the TOC, so the game won't load it")
	end
end)

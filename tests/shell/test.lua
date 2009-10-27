function Test()
	local pattern = [[
**test.lua
** **Jamfile.jam
**
]]

	TestPattern(pattern, RunJam{})
end


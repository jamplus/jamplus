function Test()
	local pattern = [[
**test.lua
** **Jamfile.jam
**
*** found 1 target(s)...
]]

	TestPattern(pattern, RunJam{})
end


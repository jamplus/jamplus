function Test()
	local pattern = [[
**I** **like** **peas.**
No splits here
*** found 1 target(s)...
]]

	TestPattern(pattern, RunJam{})
end


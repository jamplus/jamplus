function Test()
	local pattern = [[
10 + 2 = 12
10 - 2 = 8
10 * 2 = 20
10 / 2 = 5
10 % 3 = 1
jam: rule Math: Unknown operator [^].
]]

	TestPattern(pattern, RunJam{ '-fmath.jam' })
end


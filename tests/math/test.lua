function Test()
	local pattern = [[
10 + 2 = 12
10 - 2 = 8
10 * 2 = 20
10 / 2 = 5
10 % 3 = 1
10 > 2 = 1
1 > 2 = 0
10 >= 2 = 1
1 >= 2 = 0
10 >= 10 = 1
2 < 10 = 1
1 <= 2 = 1
2 <= 2 = 1
3 <= 2 = 0
2 = 2 = 1
2 == 3 = 0
jam: rule Math: Unknown operator [^].
]]

	TestPattern(pattern, RunJam{ '-fmath.jam' })
end


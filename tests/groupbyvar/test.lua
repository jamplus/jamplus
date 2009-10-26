function Test()
	local pattern = [[
Together - targeta targetc targete targetf
Together - targetb
Together - targetd
(2 max) - targeta targetc
(2 max) - targetb
(2 max) - targetd
(2 max) - targete targetf
*** found 1 target(s)...
]]

	TestPattern(pattern, RunJam())
end


function Test()
	local pattern = [[
Unsorted - AB aa ZZ zx bd bf
Sorted case sensitive - AB ZZ aa bd bf zx
Sorted case insensitive - aa AB bd bf zx ZZ
*** found 1 target(s)...
]]

	TestPattern(pattern, RunJam{})
end


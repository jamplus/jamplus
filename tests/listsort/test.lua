function Test()
	local pattern = [[
Unsorted - AB aa ZZ zx bd bf
Sorted case sensitive - AB ZZ aa bd bf zx
Sorted case insensitive - aa AB bd bf zx ZZ
]]

	TestPattern(pattern, RunJam{})
end


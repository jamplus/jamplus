function Test()
	local pattern = [[
SOME_DIR (should be empty) =
SOME_DIR (should equal c:/some/dir) = c:/some/dir
SOME_DIR (should be empty) =
*** found 1 target(s)...
]]
	return TestPattern(pattern, RunJam())
end


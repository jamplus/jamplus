function Test()
	do
		local pattern = [[
The string with $(ARGS).all-the-args--{And even more { string literal } stuff}
In quotes "does not expand $(ARGS)" but does here "all-the-args".
*** found 1 target(s)...
]]

		TestPattern(pattern, RunJam{})
	end
end


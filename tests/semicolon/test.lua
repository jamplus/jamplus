function Test()
	do
		local pattern = [[
This has a : in it.
This is missing a space:
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

		TestPattern(pattern, RunJam{ '-fcolon.jam' })
	end

	do
		local pattern = [[
semicolon.jam: line 2: found semicolon at the beginning or end of a token.
        Surround semicolons with whitespace. at keyword =
semicolon.jam: line 2: syntax error at EOF
don't know how to make all
*** found 1 target(s)...
*** can't find 1 target(s)...
]]

		TestPattern(pattern, RunJam{ '-fsemicolon.jam' })
	end
end


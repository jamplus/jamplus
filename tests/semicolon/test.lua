function Test()
	do
		local pattern = [[
This has a : in it.
This is missing a space:
]]

		TestPattern(pattern, RunJam{ '-fcolon.jam' })
	end

	do
		local pattern = [[
semicolon.jam: line 2: found semicolon at the beginning or end of a token.
        Surround semicolons with whitespace. at keyword =
semicolon.jam: line 2: syntax error at EOF
]]

		TestPattern(pattern, RunJam{ '-fsemicolon.jam' })
	end
end


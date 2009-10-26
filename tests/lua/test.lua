function Test()
	local lines = RunJam{ '-ftestluaparser.jam' }
	local numTestsPassed, totalTests = lines[1]:match('Tests passed: (%d+)/(%d+)')
	TestExpression(numTestsPassed == totalTests, "One of the Lua parser tests failed")
	
	local start = os.clock()
	local pattern = [[
*** found 4 target(s)...
*** updating 3 target(s)...
warning: using independent target xit.h
hello
@ RunLuaScript MyTarget.out
warning: using independent target xit2.h
hi
@ RunLuaScript MyTarget.out2
warning: using independent target xit3.h
together
@ RunLuaScript MyTarget.out3
*** updated 3 target(s)...
]]
	TestPattern(pattern, RunJam{ '-ftestluaaction.jam' })
	TestExpression(os.clock() - start >= 8, "testluaaction.jam did not take 8 seconds")
end


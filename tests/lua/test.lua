function Test()
	local lines = RunJam{ '-ftestluaparser.jam' }
	local ranTest = false
	for index = 1, #lines do
		local numTestsPassed, totalTests = lines[index]:match('Tests passed: (%d+)/(%d+)')
		if numTestsPassed then
			TestExpression(numTestsPassed == totalTests, "One of the Lua parser tests failed")
			TestNumberUpdate(totalTests - 1)
			TestSucceeded(numTestsPassed - 1)
			ranTest = true
			break
		end
	end

	TestExpression(ranTest, "One of the Lua parser tests failed")

	local start = os.time()
	local pattern = [[
*** found 4 target(s)...
*** updating 3 target(s)...
warning: using independent target xit.h
!OOO!hello
@ RunLuaScript MyTarget.out
warning: using independent target xit2.h
!OOO!hi
@ RunLuaScript MyTarget.out2
warning: using independent target xit3.h
!OOO!together
@ RunLuaScript MyTarget.out3
*** updated 3 target(s)...
]]
	TestPattern(pattern, RunJam{ '-ftestluaaction.jam' })
	TestExpression(os.time() - start >= 8, "testluaaction.jam did not take 8 seconds")
end


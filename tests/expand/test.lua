function Test()
	local lines = RunJam{ '-fexpandtests.jam' }
	local ranTest = false
	for index = 1, #lines do
		local numTestsPassed, totalTests = lines[index]:match('Tests passed: (%d+)/(%d+)')
		if numTestsPassed then
			TestExpression(numTestsPassed == totalTests, "One of the expansion tests failed")
			TestNumberUpdate(totalTests - 1)
			TestSucceeded(numTestsPassed - 1)
			ranTest = true
			break
		end
	end

	TestExpression(ranTest, "One of the expansion tests failed")
end


function Test()
	local lines = RunJam{ '-fexpandtests.jam' }
	local numTestsPassed, totalTests = lines[1]:match('Tests passed: (%d+)/(%d+)')
	TestExpression(numTestsPassed == totalTests, "One of the expansion tests failed")
end


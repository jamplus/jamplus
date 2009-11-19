function Test()
	local lines = RunJam()

	local pattern =
	{
		'*** found 17 target(s)...',
		'*** updating 8 target(s)...',
		'@ BatchIt hello.out',
		'hello hi more',
		'@ BatchIt hello.out',
		'less somewhere over',
		'@ BatchIt hello.out',
		'the rainbow',
		'*** updated 8 target(s)...',
	}

	return TestPattern(pattern, lines)
end


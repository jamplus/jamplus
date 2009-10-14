function Test()
	local lines = RunJam()

	local pattern =
	{
		'*** found 17 target(s)...',
		'*** updating 8 target(s)...',
		'@ BatchIt rainbow.out',
		'hello hi more',
		'@ BatchIt rainbow.out',
		'less somewhere over',
		'@ BatchIt rainbow.out',
		'the rainbow',
		'*** updated 8 target(s)...',
	}

	return TestPattern(pattern, lines)
end


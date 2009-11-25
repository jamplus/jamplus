function Test()
	local pattern =
	{
		'*** found 3 target(s)...',
		'*** updating 3 target(s)...',
		'@ DoEcho all2',
		'echo @@@@@@@@@@@ hello everyone',
		'@ DoEcho all3',
		'&=====%s+hello everyone',
		'@ DoEcho all',
		'&echo%s+hello everyone',
		'*** updated 3 target(s)...',
	}

	return TestPattern(pattern, RunJam())
end


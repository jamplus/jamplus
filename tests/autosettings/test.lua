function Test()
	local lines = RunJam{ '-j1' }

	local pattern =
	{
		'*** found 3 target(s)...',
		'*** updating 3 target(s)...',
		'@ DoEcho all2',
		'echo *********** hello everyone',
		'@ DoEcho all3',
		'=====  hello everyone',
		'@ DoEcho all',
		'echo  hello everyone',
		'*** updated 3 target(s)...',
	}

	return TestPattern(pattern, lines)
end


function Test()
	local lines = RunJam{ '-f', 'testbindingname.jam' }

	local pattern =
	{
		'*** found 2 target(s)...',
		'*** updating 1 target(s)...',
		'@ EchoIt all/that/stuff',
		's:/somethingelse.txt',
		'*** updated 1 target(s)...',
	}

	return TestPattern(pattern, lines)
end


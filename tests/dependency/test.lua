function Test()
	local pattern =
	{
		'*** found 6 target(s)...',
		'*** updating 3 target(s)...',
		'@ Update b_tmp',
		'Updating b_tmp : b_src',
		'@ Update a',
		'Updating a b : a_src b_tmp',
		'*** updated 3 target(s)...',
	}

	TestPattern(pattern, RunJam{ '-fmore_than_one_target.jam' })
end


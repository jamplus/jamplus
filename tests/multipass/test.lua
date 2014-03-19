function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'Pass2.jam',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
Pass 1
*** found 1 target(s)...
*** executing pass 2...
Pass 2
*** found 2 target(s)...
*** updating 1 target(s)...
@ WriteFile Pass3.jam
*** updated 1 target(s)...
*** executing pass 3...
Pass 3 written
*** found 2 target(s)...
*** updating 1 target(s)...
*** updated 1 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Jamfile.jam',
		'Pass2.jam',
		'Pass3.jam',
	}

	TestFiles(pass1Files)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 1
*** found 1 target(s)...
*** executing pass 2...
Pass 2
*** found 2 target(s)...
*** updating 1 target(s)...
@ WriteFile Pass3.jam
*** updated 1 target(s)...
*** executing pass 3...
Pass 3 written
*** found 1 target(s)...
*** updated 1 target(s)...
]]
	TestPattern(pattern2, RunJam())
	TestFiles(pass1Files)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local pattern3 = [[
Pass 1
*** found 2 target(s)...
*** executing pass 2...
Pass 2
*** found 1 target(s)...
*** executing pass 3...
Pass 3 written
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(pattern3, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end


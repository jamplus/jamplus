function Test()
	local originalFiles =
	{
		'Jamfile.jam',
	}

	local originalDirs =
	{
	}

	do
		-- Test for a clean directory.
		ospath.remove('.depcache')
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs =
	{
	}
	
	local files =
	{
		'.depcache',
		'Jamfile.jam',
		'1'
	}

	do
		local pattern = [[
*** found 2 target(s)...
*** updating 1 target(s)...
@ TestAction 1
Executing test action for 1
*** updated 1 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 2 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 2 target(s)...
*** updating 1 target(s)...
@ TestAction 1
Executing test action for 1
*** updated 1 target(s)...
]]

		TestPattern(pattern, RunJam{ '-sCOMMAND_LINE_VERSION=3' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 2 target(s)...
]]
		TestPattern(pattern, RunJam{ '-sCOMMAND_LINE_VERSION=3' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	ospath.remove('.depcache')
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

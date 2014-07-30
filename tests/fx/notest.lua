function Test()
	if Platform ~= 'win32' then
		return
	end

	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'simple.fx',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	-- First build
	local pattern = [[
*** found 4 target(s)...
*** updating 1 target(s)...
@ CompileEffect simple.fxo
!NEXT!*** updated 1 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Jamfile.jam',
		'simple.fx',
		'simple.fxo',
	}

	TestFiles(pass1Files)
	TestDirectories(originalDirs)

	local pattern2 = [[
*** found 4 target(s)...
]]
	TestPattern(pattern2, RunJam())
	
	osprocess.sleep(1.0)
	ospath.touch('simple.fx')
	TestPattern(pattern, RunJam())

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


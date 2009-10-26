function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
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
*** found 9 target(s)...
*** updating 5 target(s)...
@ C.C++ <test>foo.obj
foo.cpp
*** updated 2 target(s)...
Pass 2
*** found 19 target(s)...
*** updating 10 target(s)...
*** updated 1 target(s)...
Pass 3
*** found 28 target(s)...
*** updating 13 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Jamfile.jam',
		'foo.cpp',
		'foo.h',
		'foo.obj',
		'vc.pdb',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local cleanpattern_allpasses = [[
Pass 1
*** found 3 target(s)...
*** updating 1 target(s)...
@ Clean clean:test
*** updated 1 target(s)...
Pass 2
*** found 4 target(s)...
*** updating 1 target(s)...
@ Clean clean:test
*** updated 1 target(s)...
Pass 3
*** found 5 target(s)...
*** updating 2 target(s)...
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_allpasses, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 2
*** found 1 target(s)...
Pass 3
*** found 2 target(s)...
]]
	TestPattern(pattern2, RunJam{ '-sPASS_NUM=2' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_pass2on = [[
Pass 2
*** found 2 target(s)...
Pass 3
*** found 3 target(s)...
*** updating 1 target(s)...
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_pass2on, RunJam{ '-sPASS_NUM=2', 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end


function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'README',
		'circularA.h',
		'circularB.h',
		'sourceA.c',
		'sourceB.c',
		'sourceB.h',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	-- First build
	local pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ SleepThenTouch <foo>generated.h
@ C.CC <foo>sourceB.obj
sourceA.c
sourceB.c
Generating Code...
@ C.Archive <foo>foo.lib
*** updated 4 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Jamfile.jam',
		'README',
		'circularA.h',
		'circularB.h',
		'foo.release.lib',
		'generated.h',
		'sourceA.c',
		'sourceA.obj',
		'sourceB.c',
		'sourceB.h',
		'sourceB.obj',
		'vc.pdb',
	}

	TestFiles(pass1Files)
	TestDirectories(originalDirs)

	local pattern2 = [[
*** found 17 target(s)...
]]
	TestPattern(pattern2, RunJam())
	
	os.sleep(1.0)
	os.touch('generated.h')

	local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <foo>sourceB.obj
sourceA.c
sourceB.c
Generating Code...
@ C.Archive <foo>foo.lib
*** updated 3 target(s)...
]]
	TestPattern(pattern3, RunJam())

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


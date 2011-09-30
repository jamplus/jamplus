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

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 11 target(s)...
@ SleepThenTouch <win32!release:foo>generated.h
!NEXT!@ C.vc.CC <win32!release:foo>sourceA.obj
!NEXT!@ C.vc.Archive <win32!release:foo>foo.lib
!NEXT!*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{'foo'})

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
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })
	
		os.sleep(1.0)
		os.touch('generated.h')

		local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
!NEXT!@ C.vc.CC <win32!release:foo>sourceA.obj
!NEXT!@ C.vc.Archive <win32!release:foo>foo.lib
!NEXT!*** updated 3 target(s)...
]]
		TestPattern(pattern3, RunJam{ 'foo' })
	
	else
		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ SleepThenTouch <macosx32!release:foo>generated.h 
@ C.gcc.CC <macosx32!release:foo>sourceA.o 
@ C.gcc.CC <macosx32!release:foo>sourceB.o 
@ C.gcc.Archive <macosx32!release:foo>foo.a 
!NEXT!@ C.gcc.Ranlib <macosx32!release:foo>foo.a 
!NEXT!*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{ 'foo' })

		local pass1Files =
		{
			'Jamfile.jam',
			'README',
			'circularA.h',
			'circularB.h',
			'foo.release.a',
			'generated.h',
			'sourceA.c',
			'sourceA.o',
			'sourceB.c',
			'sourceB.h',
			'sourceB.o',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })

		os.sleep(1.0)
		os.touch('generated.h')

		local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <foo>sourceA.o 
@ C.CC <foo>sourceB.o 
@ C.Archive <foo>foo.a 
@ C.Ranlib <foo>foo.a 
!NEXT!*** updated 3 target(s)...
]]
		TestPattern(pattern3, RunJam{ 'foo' })

	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


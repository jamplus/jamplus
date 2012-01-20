function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'main.c',
		'test.c',
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
*** found 18 target(s)...
*** updating 6 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
*** updated 6 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'win32!release/',
			'win32!release/test/',
		}
		
		local pass1Files =
		{
			'Jamfile.jam',
			'main.c',
			'test.c',
			'test.h',
			'win32!release/test/main.obj',
			'win32!release/test/test.obj',
			'win32!release/test/test.release.exe',
			'win32!release/test/test.release.exe.intermediate.manifest',
			'win32!release/test/test.release.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 18 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		os.sleep(1.0)
		os.touch('test.h')

		local pattern3 = [[
*** found 18 target(s)...
*** updating 2 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
	
	else

		-- First build
		local pattern = [[
*** found 10 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.o 
@ C.CC <test>test.o 
@ C.Link <test>test.release 
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'main.c',
			'main.o',
			'test.c',
			'test.h',
			'test.o',
			'test.release',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 10 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('test.h')

		local pattern3 = [[
*** found 10 target(s)...
*** updating 2 target(s)...
@ C.CC <test>main.o 
@ C.Link <test>test.release 
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())

	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


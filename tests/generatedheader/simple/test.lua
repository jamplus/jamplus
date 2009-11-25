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
*** found 16 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.obj
main.c
test.c
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'main.c',
			'main.obj',
			'test.c',
			'test.h',
			'test.obj',
			'test.release.exe',
			'test.release.exe.intermediate.manifest',
			'test.release.pdb',
			'vc.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 16 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		os.sleep(1.0)
		os.touch('test.h')

		local pattern3 = [[
*** found 16 target(s)...
*** updating 2 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 2 target(s)...
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


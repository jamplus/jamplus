function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'file.txt',
		'main.c',
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
*** found 20 target(s)...
*** updating 6 target(s)...
@ GenerateCFile <win32!release:helloworld>file.c
!NEXT!@ C.vc.CC <win32!release:helloworld>main.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 6 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'win32-release/',
			'win32-release/helloworld/',
		}

		local pass1Files = {
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'win32-release/helloworld/file.obj',
			'win32-release/helloworld/helloworld.release.exe',
			'?win32-release/helloworld/helloworld.release.exe.intermediate.manifest',
			'win32-release/helloworld/helloworld.release.pdb',
			'win32-release/helloworld/main.obj',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 20 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('file.c')

		local pattern3 = [[
*** found 20 target(s)...
*** updating 2 target(s)...
@ C.vc.CC <win32!release:helloworld>file.obj
file.c
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

	else
		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
@ C.gcc.CC <macosx32!release:helloworld>main.o 
@ GenerateCFile <macosx32!release:helloworld>file.c 
@ C.gcc.CC <macosx32!release:helloworld>file.o 
@ C.gcc.Link <macosx32!release:helloworld>helloworld 
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'macosx32-release/',
			'macosx32-release/helloworld/',
		}

		local pass1Files =
		{
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'macosx32-release/helloworld/file.o',
			'macosx32-release/helloworld/helloworld.release',
			'macosx32-release/helloworld/main.o',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('file.c')

		local pattern3 = [[
*** found 11 target(s)...
*** updating 2 target(s)...
@ C.gcc.CC <macosx32!release:helloworld>file.o
@ C.gcc.Link <macosx32!release:helloworld>helloworld
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)
	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


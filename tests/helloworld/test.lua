function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'file.c',
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
*** updating 5 target(s)...
@ C.vc.CC <win32!release:helloworld>main.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Directories = {
			'win32-release/',
			'win32-release/helloworld/',
		}

		local pass1Files =
		{
			'file.c',
			'Jamfile.jam',
			'main.c',
			'win32-release/helloworld/file.obj',
			'win32-release/helloworld/helloworld.release.exe',
			'?win32-release/helloworld/helloworld.release.exe.intermediate.manifest',
			'win32-release/helloworld/helloworld.release.pdb',
			'win32-release/helloworld/main.obj',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 20 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		osprocess.sleep(1.0)
		ospath.touch('file.c')

		local pattern3 = [[
*** found 20 target(s)...
*** updating 2 target(s)...
@ C.vc.CC <win32!release:helloworld>file.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

	else

		-- First build
		local pattern = [[
*** found 10 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>main.o 
@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>file.o 
@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):helloworld>helloworld 
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'macosx32-release/',
			'macosx32-release/helloworld/',
		}

		local pass1Files = {
			'file.c',
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
*** found 10 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('file.c')

		local pattern3 = [[
*** found 10 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>file.o 
@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):helloworld>helloworld 
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


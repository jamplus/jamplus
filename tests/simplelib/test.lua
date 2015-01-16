function Test()
	local originalFiles =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/main.c',
		'lib-a/Jamfile.jam',
		'lib-a/add.c',
		'lib-a/add.h',
	}

	local originalDirs =
	{
		'app/',
		'lib-a/',
	}

	do
		-- Test for a clean directory.
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs
	local files
	local patternA
	local patternB
	local patternC
	local patternD
	
	if Platform == 'win32' then
		dirs =
		{
			'app/',
			'lib-a/',
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/app/app/',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/',
		}

		files = {
			'Jamfile.jam',
			'test.lua',
			'app/Jamfile.jam',
			'app/main.c',
			'$(TOOLCHAIN_PATH)/app/app/app.release.exe',
			'?$(TOOLCHAIN_PATH)/app/app/app.release.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/app/app/app.release.pdb',
			'$(TOOLCHAIN_PATH)/app/app/main.obj',
			'lib-a/add.c',
			'lib-a/add.h',
			'lib-a/Jamfile.jam',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.obj',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.release.lib',
		}
	
		patternA = [[
*** found 12 target(s)...
*** updating 6 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-a>add.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-a>lib-a.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 6 target(s)...
]]

		patternB = [[
*** found 12 target(s)...
]]

		patternC = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 2 target(s)...
]]

		patternD = [[
*** found 12 target(s)...
]]

	else
		dirs =
		{
			'app/',
			'lib-a/',
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/app/app/',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/',
		}

		files = {
			'Jamfile.jam',
			'test.lua',
			'app/Jamfile.jam',
			'app/main.c',
			'$(TOOLCHAIN_PATH)/app/app/app.release',
			'$(TOOLCHAIN_PATH)/app/app/main.o',
			'lib-a/add.c',
			'lib-a/add.h',
			'lib-a/Jamfile.jam',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.o',
			'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.release.a',
		}
	
		patternA = [[
*** found 12 target(s)...
*** updating 6 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-a>add.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-a>lib-a.a 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 6 target(s)...
]]

		patternB = [[
*** found 12 target(s)...
]]

		patternC = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 2 target(s)...
]]

		patternD = [[
*** found 12 target(s)...
]]

	end

	do
		TestPattern(patternA, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('lib-a/add.h')

		TestPattern(patternC, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternD, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

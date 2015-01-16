function Test()
	local originalFiles =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/main.c',
		'lib-c/Jamfile.jam',
		'lib-c/add.c',
		'lib-c/add.h',
		'slib-a/Jamfile.jam',
		'slib-a/slib-a.c',
		'slib-b/Jamfile.jam',
		'slib-b/slib-b.c',
	}

	local originalDirs =
	{
		'app/',
		'lib-c/',
		'slib-a/',
		'slib-b/',
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
	
	if Platform == 'win32' then
		dirs = {
			'app/',
			'image/',
			'lib-c/',
			'slib-a/',
			'slib-b/',
			'image/$(PLATFORM_CONFIG)/TOP/',
			'image/$(PLATFORM_CONFIG)/TOP/app/app/',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/',
			'image/$(PLATFORM_CONFIG)/TOP/app/app/',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/',
		}

		files = {
			'Jamfile.jam',
			'test.lua',
			'app/Jamfile.jam',
			'app/main.c',
			'image/.depcache',
			'image/app.release.exe',
			'image/app.release.pdb',
			'image/slib-a.release.dll',
			'image/slib-a.release.exp',
			'image/slib-a.release.lib',
			'image/slib-a.release.pdb',
			'image/slib-b.release.dll',
			'image/slib-b.release.exp',
			'image/slib-b.release.lib',
			'image/slib-b.release.pdb',
			'?image/win32-release/TOP/app/app/app.release.exe.intermediate.manifest',
			'image/win32-release/TOP/app/app/main.obj',
			'image/win32-release/TOP/lib-c/lib-c/add.obj',
			'image/win32-release/TOP/lib-c/lib-c/lib-c.release.lib',
			'image/win32-release/TOP/slib-a/slib-a/slib-a.obj',
			'?image/win32-release/TOP/slib-a/slib-a/slib-a.release.dll.intermediate.manifest',
			'image/win32-release/TOP/slib-b/slib-b/slib-b.obj',
			'?image/win32-release/TOP/slib-b/slib-b/slib-b.release.dll.intermediate.manifest',
			'lib-c/add.c',
			'lib-c/add.h',
			'lib-c/Jamfile.jam',
			'slib-a/Jamfile.jam',
			'slib-a/slib-a.c',
			'slib-b/Jamfile.jam',
			'slib-b/slib-b.c',
		}
	else
		dirs = {
			'app/',
			'image/',
			'lib-c/',
			'slib-a/',
			'slib-b/',
			'image/$(PLATFORM_CONFIG)/TOP/',
			'image/$(PLATFORM_CONFIG)/TOP/app/app/',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/',
			'image/$(PLATFORM_CONFIG)/TOP/app/app/',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/',
			'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/',
		}

		files = {
			'Jamfile.jam',
			'test.lua',
			'app/Jamfile.jam',
			'app/main.c',
			'image/.depcache',
			'image/app.release',
			'image/slib-a.release.so',
			'image/slib-b.release.so',
			'image/$(PLATFORM_CONFIG)/TOP/app/app/main.o',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/add.o',
			'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/lib-c.release.a',
			'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/slib-a.o',
			'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/slib-b.o',
			'lib-c/add.c',
			'lib-c/add.h',
			'lib-c/Jamfile.jam',
			'slib-a/Jamfile.jam',
			'slib-a/slib-a.c',
			'slib-b/Jamfile.jam',
			'slib-b/slib-b.c',
		}
	end

	local pattern
	do
		if Platform == 'win32' then
		 	pattern = [[
*** found 42 target(s)...
*** updating 15 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.obj
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.lib
@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
*** updated 15 target(s)...
]]
		else
			pattern = [[
*** found 26 target(s)...
*** updating 15 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.a 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 15 target(s)...
]]
		end

		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('lib-c/add.h')

		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
				*** updating 7 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
				*** updated 7 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('lib-c/add.c')

		if Platform == 'win32' then
			pattern = [[
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
				*** updating 7 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.o 
				@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.a 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
				*** updated 7 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('slib-a/slib-a.c')

		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!*** updated 3 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
				*** updating 4 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
				*** updated 4 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
*** found 42 target(s)...
]]
		else
			pattern = [[
				*** found 26 target(s)...
]]
		end
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

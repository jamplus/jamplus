function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'common/common.jam',
		'common/print.cpp',
		'common/print.h',
		'libA/libA.cpp',
		'libA/libA.jam',
		'project1/project1.cpp',
		'project1/project1.jam',
	}

	local originalDirs =
	{
		'common/',
		'libA/',
		'project1/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 26 target(s)...
*** updating 9 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.obj
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):common>print.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):common>common.lib
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 9 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'$(TOOLCHAIN_PATH)/common/common/common.release.lib',
			'$(TOOLCHAIN_PATH)/common/common/print.obj',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.obj',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.release.lib',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.obj',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.release.exe',
			'?$(TOOLCHAIN_PATH)/project1/project1/project1.release.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.release.pdb',
		}

		local pass1Directories = {
			'common/',
			'libA/',
			'project1/',
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/common/common/',
			'$(TOOLCHAIN_PATH)/libA/libA/',
			'$(TOOLCHAIN_PATH)/project1/project1/',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 26 target(s)...
]]
		TestPattern(pattern2, RunJam())
	else
		-- First build
		local pattern = [[
*** found 18 target(s)...
*** updating 9 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):common>print.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):common>common.a 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.a 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 9 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Directories = {
			'common/',
			'libA/',
			'project1/',
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/common/common/',
			'$(TOOLCHAIN_PATH)/libA/libA/',
			'$(TOOLCHAIN_PATH)/project1/project1/',
		}

		local pass1Files =
		{
			'Jamfile.jam',
			'test.lua',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'$(TOOLCHAIN_PATH)/common/common/common.release.a',
			'$(TOOLCHAIN_PATH)/common/common/print.o',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.o',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.release.a',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.o',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.release',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 18 target(s)...
]]
		TestPattern(pattern2, RunJam())
	end
	
	osprocess.sleep(1.0)
	ospath.touch('common/print.h')

	if Platform == 'win32' then
		local pattern3 = [[
*** found 26 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.obj
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	else
		local pattern3 = [[
*** found 18 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.a 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	end

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


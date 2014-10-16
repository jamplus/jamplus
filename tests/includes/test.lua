function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'common/common.jam',
		'common/print.cpp',
		'common/print.h',
		'project1/adefine.cpp',
		'project1/project1.cpp',
		'project1/project1.jam',
		'shared/adefine.h',
	}

	local originalDirs =
	{
		'common/',
		'project1/',
		'shared/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 33 target(s)...
*** updating 7 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.obj
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>adefine.obj
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):common>print.obj
!NEXT!@ C.$(COMPILER).Archive <$(TOOLCHAIN_GRIST):common>common.lib
!NEXT!@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 7 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Directories = {
			'common/',
			'project1/',
			'shared/',
			'common/$(TOOLCHAIN_PATH)/',
			'common/$(TOOLCHAIN_PATH)/common/',
			'project1/$(TOOLCHAIN_PATH)/',
			'project1/$(TOOLCHAIN_PATH)/project1/',
		}

		local pass1Files =
		{
			'Jamfile.jam',
			'test.lua',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'common/$(TOOLCHAIN_PATH)/common/common.release.lib',
			'common/$(TOOLCHAIN_PATH)/common/print.obj',
			'project1/adefine.cpp',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/$(TOOLCHAIN_PATH)/project1/adefine.obj',
			'project1/$(TOOLCHAIN_PATH)/project1/project1.obj',
			'project1/$(TOOLCHAIN_PATH)/project1/project1.release.exe',
			'?project1/$(TOOLCHAIN_PATH)/project1/project1.release.exe.intermediate.manifest',
			'project1/$(TOOLCHAIN_PATH)/project1/project1.release.pdb',
			'shared/adefine.h',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 33 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		osprocess.sleep(1.0)
		ospath.touch('common/print.h')

		local pattern3 = [[
*** found 33 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.obj
!NEXT!@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		osprocess.sleep(1.0)
		ospath.touch('shared/adefine.h')

		local pattern4 = [[
*** found 33 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>adefine.obj
!NEXT!@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern4, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)
	
	else

		-- First build
		local pattern = [[
*** updating 7 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>adefine.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):common>print.o 
@ C.$(COMPILER).Archive2 <$(TOOLCHAIN_GRIST):common>common.a 
@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1 
*** updated 7 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'common/',
			'project1/',
			'shared/',
			'common/$(TOOLCHAIN_PATH)/',
			'common/$(TOOLCHAIN_PATH)/common/',
			'project1/$(TOOLCHAIN_PATH)/',
			'project1/$(TOOLCHAIN_PATH)/project1/',
		}

		local pass1Files = {
			'Jamfile.jam',
			'test.lua',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'common/$(TOOLCHAIN_PATH)/common/common.release.a',
			'common/$(TOOLCHAIN_PATH)/common/print.o',
			'project1/adefine.cpp',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/$(TOOLCHAIN_PATH)/project1/adefine.o',
			'project1/$(TOOLCHAIN_PATH)/project1/project1.o',
			'project1/$(TOOLCHAIN_PATH)/project1/project1.release',
			'shared/adefine.h',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 17 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('common/print.h')

		local pattern3 = [[
*** found 17 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1 
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		osprocess.sleep(1.0)
		ospath.touch('shared/adefine.h')

		local pattern4 = [[
*** found 17 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>adefine.o 
@ C.$(COMPILER).Link <$(TOOLCHAIN_GRIST):project1>project1 
*** updated 2 target(s)...
]]
		TestPattern(pattern4, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


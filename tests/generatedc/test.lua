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
*** found 19 target(s)...
*** updating 5 target(s)...
@ GenerateCFile <$(TOOLCHAIN_GRIST):helloworld>file.c
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/helloworld/',
		}

		local pass1Files = {
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/helloworld/file.obj',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld.exe',
			'?$(TOOLCHAIN_PATH)/helloworld/helloworld.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld.pdb',
			'$(TOOLCHAIN_PATH)/helloworld/main.obj',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 19 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('file.c')

		local pattern3 = [[
*** found 19 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.obj
file.c
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
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
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.o 
@ GenerateCFile <$(TOOLCHAIN_GRIST):helloworld>file.c 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>file.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/helloworld/',
		}

		local pass1Files =
		{
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/helloworld/file.o',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld',
			'$(TOOLCHAIN_PATH)/helloworld/main.o',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('file.c')

		local pattern3 = [[
*** found 11 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>file.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld
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


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function TestChecksum()
	local function WriteOriginalFiles()
		ospath.copy_file('file.txt', 'file.c')
		ospath.touch('file.c')
	end

	local function WriteModifiedFiles()
		ospath.write_file('file.c', [[
#include <stdio.h>

void Print()
{
        printf("Something else.\n");
}
]])
	end

	-- Test for a clean directory.
	local originalFiles = {
		'Jamfile.jam',
		'file.txt',
		'main.c',
	}

	local originalDirs = {
	}

	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 19 target(s)...
*** updating 5 target(s)...
@ GenerateCFile <$(TOOLCHAIN_GRIST):helloworld>file.c
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
*** finished in 0.01 sec
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/helloworld/',
		}

		local pass1Files = {
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/helloworld/file.obj',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld.exe',
			'?$(TOOLCHAIN_PATH)/helloworld/helloworld.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld.pdb',
			'$(TOOLCHAIN_PATH)/helloworld/main.obj',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 19 target(s)...
*** finished in 0.01 sec
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('file.c')
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		WriteModifiedFiles()

		local pattern3 = [[
*** found 19 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.obj
file.c
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 2 target(s)...
*** finished in 0.01 sec
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

	else
		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>main.o 
@ GenerateCFile <$(TOOLCHAIN_GRIST):helloworld>file.c 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>file.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
*** updated 5 target(s)...
*** finished in 0.01 sec
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/helloworld/',
		}

		local pass1Files =
		{
			'file.c',
			'file.txt',
			'Jamfile.jam',
			'main.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/helloworld/file.o',
			'$(TOOLCHAIN_PATH)/helloworld/helloworld',
			'$(TOOLCHAIN_PATH)/helloworld/main.o',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 11 target(s)...
*** finished in 0.01 sec
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('file.c')
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		WriteModifiedFiles()

		local pattern3 = [[
*** found 11 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>file.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld
*** updated 2 target(s)...
*** finished in 0.01 sec
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)
	end

	WriteOriginalFiles()
	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


function Test()
	local function WriteOriginalFiles()
		ospath.write_file('src/precomp.h', [[
#ifndef PRECOMP_H
#define PRECOMP_H

#include <stdio.h>

#endif // PRECOMP_H
]])

		ospath.write_file('src/createprecomp.c', [[
#include "precomp.h"
]])
	end

	local function WriteModifiedFileA()
		ospath.write_file('src/precomp.h', [[
// Modified
#ifndef PRECOMP_H
#define PRECOMP_H

#include <stdio.h>

#endif // PRECOMP_H
]])

	end

	local function WriteModifiedFileB()
		ospath.write_file('src/createprecomp.c', [[
// Modified
#include "precomp.h"
]])
	end

	local originalFiles =
	{
		'jam/Jamfile.jam',
		'src/createprecomp.c',
		'src/file.c',
		'src/main.c',
		'src/precomp.h',
	}

	local originalDirs =
	{
		'jam/',
		'src/',
	}

	do
		-- Test for a clean directory.
		WriteOriginalFiles()
		RunJam{ '-Cjam', 'clean' }
		ospath.remove('jam/.jamchecksums')
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs
	local files
	local pattern
	
	if Platform == 'win32' then
		dirs =
		{
			'jam/',
			'src/',
			'jam/$(TOOLCHAIN_PATH)/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/',
		}
	
		files =
		{
			'jam/Jamfile.jam',
			'jam/.build/.depcache',
			'?jam/.build/.jamchecksums',
			'jam/$(TOOLCHAIN_PATH)/helloworld/createprecomp.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/file.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.exe',
			'?jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.exe.intermediate.manifest',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.pdb',
			'jam/$(TOOLCHAIN_PATH)/helloworld/main.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp.h.pch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}

		pattern = [[
*** found 22 target(s)...
*** updating 6 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 6 target(s)...
]]
	else
		dirs = {
			'jam/',
			'src/',
			'jam/$(TOOLCHAIN_PATH)/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp%-%x+/',
		}

		files = {
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
			'jam/Jamfile.jam',
			'jam/.build/.depcache',
			'?jam/.build/.jamchecksums',
			'jam/$(TOOLCHAIN_PATH)/helloworld/createprecomp.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/file.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld',
			'jam/$(TOOLCHAIN_PATH)/helloworld/main.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp%-%x+/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 17 target(s)...
			*** updating 7 target(s)...
			&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):helloworld%-%x+>precomp.h.gch 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.o 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/main.o 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
			@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
			*** updated 7 target(s)...
]]
	
	end

	do
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	local noopPattern
	if Platform == 'win32' then
		noopPattern = [[
			*** found 22 target(s)...
]]
	else
		noopPattern = [[
			*** found 17 target(s)...
]]
	end

	do
		TestPattern(noopPattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('src/precomp.h')

		if useChecksums then
			local noopPattern2 = [[
		*** found 22 target(s)...
		*** updating 5 target(s)...
		*** updated 0 target(s)...
]]
			TestPattern(noopPattern2, RunJam{ '-Cjam' })

			osprocess.sleep(1.0)
			WriteModifiedFileA()
		end

		if Platform == 'win32' then
			if useChecksums then
				pattern = [[
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 3 target(s)...
]]
			else
				pattern = [[
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
			end
		else
			if useChecksums then
				pattern = [[
				*** found 17 target(s)...
				*** updating 5 target(s)...
				&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):helloworld%-%x+>precomp.h.gch 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/main.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				*** updated 4 target(s)...
]]
			else
				pattern = [[
				*** found 17 target(s)...
				*** updating 5 target(s)...
				&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):helloworld%-%x+>precomp.h.gch 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/main.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
				*** updated 5 target(s)...
]]
			end
		end

		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(noopPattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('src/createprecomp.c')

		if useChecksums then
			local noopPattern2
			if Platform == 'win32' then
				noopPattern2 = [[
*** found 17 target(s)...
*** updating 5 target(s)...
*** updated 0 target(s)...
]]
			else
				noopPattern2 = [[
*** found 17 target(s)...
*** updating 2 target(s)...
*** updated 0 target(s)...
]]
			end
			osprocess.sleep(1.0)
			TestPattern(noopPattern2, RunJam{ '-Cjam' })

			osprocess.sleep(1.0)
			WriteModifiedFileB()
		end

		if Platform == 'win32' then
			if useChecksums then
				pattern = [[
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 3 target(s)...
]]
			else
				pattern = [[
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
			end
		else
			if useChecksums then
				pattern = [[
				*** found 17 target(s)...
				*** updating 2 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				*** updated 1 target(s)...
]]
			else
				pattern = [[
				*** found 17 target(s)...
				*** updating 2 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
				*** updated 2 target(s)...
]]
			end
		end
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	WriteOriginalFiles()
	RunJam{ '-Cjam', 'clean' }
	ospath.remove('jam/.jamchecksums')
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

TestChecksum = Test

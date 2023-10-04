local originalFiles = {
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

local originalDirs = {
	'app/',
	'lib-c/',
	'slib-a/',
	'slib-b/',
}

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
		'image/.jamdepcache',
		'?image/.jamchecksums',
		'image/app.exe',
		'image/app.pdb',
		'image/slib-a.dll',
		'image/slib-a.exp',
		'image/slib-a.lib',
		'image/slib-a.pdb',
		'image/slib-b.dll',
		'image/slib-b.exp',
		'image/slib-b.lib',
		'image/slib-b.pdb',
		'?image/$(PLATFORM_CONFIG)/TOP/app/app/app.exe.intermediate.manifest',
		'image/$(PLATFORM_CONFIG)/TOP/app/app/main.obj',
		'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/add.obj',
		'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/lib-c.lib',
		'image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/slib-a.obj',
		'?image/$(PLATFORM_CONFIG)/TOP/slib-a/slib-a/slib-a.dll.intermediate.manifest',
		'image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/slib-b.obj',
		'?image/$(PLATFORM_CONFIG)/TOP/slib-b/slib-b/slib-b.dll.intermediate.manifest',
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
		'image/.jamdepcache',
		'?image/.jamchecksums',
		'image/app',
		'image/slib-a.so',
		'image/slib-b.so',
		'image/$(PLATFORM_CONFIG)/TOP/app/app/main.o',
		'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/add.o',
		'image/$(PLATFORM_CONFIG)/TOP/lib-c/lib-c/lib-c.a',
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

local pass1Pattern
local pass2Pattern
local pass3Pattern
local pass3Pattern_useChecksums
local pass4Pattern
local pass4Pattern_useChecksums
local pass5Pattern
local pass5Pattern_useChecksums
local pass6Pattern
local pass6Pattern_useChecksums
local pass7Pattern
local pass7Pattern_useChecksums
local pass8Pattern
local pass8Pattern_useChecksums
if Platform == 'win32' then
	pass1Pattern = [[
*** found 42 target(s)...
*** updating 15 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.lib
@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 15 target(s)...
]]

	pass2Pattern = [[
*** found 42 target(s)...
]]

	pass3Pattern = [[
*** found 42 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 4 target(s)...
]]

	pass3Pattern_useChecksums = [[
*** found 42 target(s)...
*** updating 4 target(s)...
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 4 target(s)...
]]

	pass4Pattern = [[
*** found 42 target(s)...
]]

	pass4Pattern_useChecksums = [[
*** found 42 target(s)...
]]

	pass5Pattern = [[
!NEXT!*** updating 4 target(s)...
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 4 target(s)...
]]

	pass5Pattern_useChecksums = [[
!NEXT!*** updating 4 target(s)...
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.dll
!NEXT!*** updated 4 target(s)...
]]

	pass6Pattern = [[
*** found 42 target(s)...
]]

	pass6Pattern_useChecksums = [[
*** found 42 target(s)...
]]

	pass7Pattern = [[
*** found 42 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!*** updated 2 target(s)...
]]

	pass7Pattern_useChecksums = [[
*** found 42 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.dll
!NEXT!*** updated 2 target(s)...
]]

	pass8Pattern = [[
*** found 42 target(s)...
]]

	pass8Pattern_useChecksums = [[
*** found 42 target(s)...
]]

else

	pass1Pattern = [[
*** found 26 target(s)...
*** updating 15 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 15 target(s)...
]]

	pass2Pattern = [[
		*** found 26 target(s)...
]]

	pass3Pattern = [[
		*** found 26 target(s)...
		*** updating 7 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
		*** updated 7 target(s)...
]]

	if Platform == 'linux' then
		if Compiler == 'clang' then
			pass3Pattern_useChecksums = [[
				*** found 26 target(s)...
				*** updating 7 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so
				*** updated 4 target(s)...
]]
		else
			pass3Pattern_useChecksums = [[
				*** found 26 target(s)...
				*** updating 7 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so
				*** updated 4 target(s)...
]]
		end
	else
		pass3Pattern_useChecksums = [[
		*** found 26 target(s)...
		*** updating 7 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-b>slib-b.o
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so
		*** updated 4 target(s)...
]]
	end

	pass4Pattern = [[
		*** found 26 target(s)...
]]

	pass4Pattern_useChecksums = [[
		*** found 26 target(s)...
]]

	pass5Pattern = [[
		*** found 26 target(s)...
		*** updating 7 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.o 
		@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
		*** updated 7 target(s)...
]]

	pass5Pattern_useChecksums = [[
		*** found 26 target(s)...
		*** updating 7 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-c>add.o 
		@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-c>lib-c.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-b>slib-b.so 
		*** updated 4 target(s)...
]]

	pass6Pattern = [[
		*** found 26 target(s)...
]]

	pass7Pattern = [[
		*** found 26 target(s)...
		*** updating 4 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
		*** updated 4 target(s)...
]]

	pass7Pattern_useChecksums = [[
		*** found 26 target(s)...
		*** updating 4 target(s)...
		@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):slib-a>slib-a.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):slib-a>slib-a.so 
		*** updated 2 target(s)...
]]

	pass8Pattern = [[
		*** found 26 target(s)...
]]
end

function Test()
	local function WriteOriginalFiles()
		ospath.write_file('lib-c/add.h', [[
int Add(int a, int b);
]])

		ospath.write_file('lib-c/add.c', [[
int Add(int a, int b)
{
    return a + b;
}
]])

		ospath.write_file('slib-a/slib-a.c', [[
#include <stdio.h>
#include "../lib-c/add.h"

#if _MSC_VER
__declspec(dllexport)
#endif
void ExportA()
{
    printf("ExportA: 2 + 5 = %d\n", Add(2, 5));
}



#if _MSC_VER
__declspec(dllexport)
#endif
void ExportA2()
{
    printf("ExportA2: 3 + 9 = %d\n", Add(3, 9));
}
]])
	end

	local function WriteModifiedFileA()
		ospath.write_file('lib-c/add.h', [[
// Modified
int Add(int a, int b);
]])
	end

	local function WriteModifiedFileB()
		ospath.write_file('lib-c/add.c', [[
// Modified
int Add(int a, int b)
{
    return a + b;
}
]])
	end

	local function WriteModifiedFileC()
		ospath.write_file('slib-a/slib-a.c', [[
// Modified
#include <stdio.h>
#include "../lib-c/add.h"

#if _MSC_VER
__declspec(dllexport)
#endif
void ExportA()
{
    printf("ExportA: 2 + 5 = %d\n", Add(2, 5));
}



#if _MSC_VER
__declspec(dllexport)
#endif
void ExportA2()
{
    printf("ExportA2: 3 + 9 = %d\n", Add(3, 9));
}
]])
	end

	do
		-- Test for a clean directory.
		WriteOriginalFiles()
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(pass1Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(pass2Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('lib-c/add.h')
		osprocess.sleep(1.0)

		if useChecksums then
			local noopPattern
			if Platform == 'win32' then
				noopPattern = [[
*** found 26 target(s)...
*** updating 4 target(s)...
*** updated 0 target(s)...
]]
			else
				noopPattern = [[
*** found 28 target(s)...
*** updating 7 target(s)...
*** updated 0 target(s)...
]]
			end

			TestPattern(noopPattern, RunJam{})

			TestPattern(pass2Pattern, RunJam{})
			TestDirectories(dirs)
			TestFiles(files)

			osprocess.sleep(1.0)
			WriteModifiedFileA()
			osprocess.sleep(1.0)
		end

		TestPattern(useChecksums  and  pass3Pattern_useChecksums  or  pass3Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		TestPattern(useChecksums  and  pass4Pattern_useChecksums  or  pass4Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('lib-c/add.c')
		osprocess.sleep(1.0)

		if useChecksums then
			local noopPattern
			if Platform == 'win32' then
				noopPattern = [[
*** found 26 target(s)...
*** updating 4 target(s)...
*** updated 0 target(s)...
]]
			else
				noopPattern = [[
*** found 28 target(s)...
*** updating 7 target(s)...
*** updated 0 target(s)...
]]
			end

			TestPattern(noopPattern, RunJam{})

			osprocess.sleep(1.0)
			WriteModifiedFileB()
			osprocess.sleep(1.0)
		end

		TestPattern(useChecksums  and  pass5Pattern_useChecksums  or  pass5Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(useChecksums  and  pass6Pattern_useChecksums  or  pass6Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		ospath.touch('slib-a/slib-a.c')

		if useChecksums then
			local noopPattern
			if Platform == 'win32' then
				noopPattern = [[
*** found 26 target(s)...
*** updating 2 target(s)...
*** updated 0 target(s)...
]]
			else
				noopPattern = [[
*** found 28 target(s)...
*** updating 4 target(s)...
*** updated 0 target(s)...
]]
			end

			TestPattern(noopPattern, RunJam{})

			osprocess.sleep(1.0)
			WriteModifiedFileC()
			osprocess.sleep(1.0)
		end

		TestPattern(useChecksums  and  pass7Pattern_useChecksums  or  pass7Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(useChecksums  and  pass8Pattern_useChecksums  or  pass8Pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

TestChecksum = Test

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
			'$(TOOLCHAIN_PATH)/common/common/common.lib',
			'$(TOOLCHAIN_PATH)/common/common/print.obj',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.obj',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.lib',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.obj',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.exe',
			'?$(TOOLCHAIN_PATH)/project1/project1/project1.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.pdb',
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
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
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
			'$(TOOLCHAIN_PATH)/common/common/common.a',
			'$(TOOLCHAIN_PATH)/common/common/print.o',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.o',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.a',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.o',
			'$(TOOLCHAIN_PATH)/project1/project1/project1',
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
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	end

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
---------------------------------------------------------------------------------
function TestChecksum()
	local function WriteOriginalFiles()
		ospath.write_file('common/print.h', [[
extern void Print(const char* str);
]])

		ospath.write_file('libA/libA.cpp', [[
void LibA()
{
    Print("test libA\n");
}
]])
	end

	local function WriteModifiedFileA()
		ospath.write_file('common/print.h', [[
// Modified file
extern void Print(const char* str);
]])
	end

	local function WriteModifiedFileB()
		ospath.write_file('libA/libA.cpp', [[
void LibA()
{
    Print("test libA modified\n");
}
]])
	end

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
	WriteOriginalFiles()
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
			'$(TOOLCHAIN_PATH)/common/common/common.lib',
			'$(TOOLCHAIN_PATH)/common/common/print.obj',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.obj',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.lib',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.obj',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.exe',
			'?$(TOOLCHAIN_PATH)/project1/project1/project1.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.pdb',
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
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
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
			'$(TOOLCHAIN_PATH)/common/common/common.a',
			'$(TOOLCHAIN_PATH)/common/common/print.o',
			'libA/libA.cpp',
			'libA/libA.jam',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.o',
			'$(TOOLCHAIN_PATH)/libA/libA/libA.a',
			'project1/project1.cpp',
			'project1/project1.jam',
			'$(TOOLCHAIN_PATH)/project1/project1/project1.o',
			'$(TOOLCHAIN_PATH)/project1/project1/project1',
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

	local pattern3 = [[
*** found 18 target(s)...
*** updating 4 target(s)...
*** updated 4 target(s)...
]]
	TestPattern(pattern3, RunJam())

	osprocess.sleep(1.0)
	WriteModifiedFileA()

	if Platform == 'win32' then
		local pattern4 = [[
*** found 26 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.obj
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 4 target(s)...
]]
		TestPattern(pattern4, RunJam())
	elseif Platform == 'linux' then
		local pattern4 = [[
*** found 18 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
*** updated 4 target(s)...
]]
		TestPattern(pattern4, RunJam())
	else
		local pattern4 = [[
*** found 18 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>project1.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
*** updated 4 target(s)...
]]
		TestPattern(pattern4, RunJam())
	end

	local noopPattern = [[
*** found 18 target(s)...
]]
	TestPattern(noopPattern, RunJam())

	osprocess.sleep(1.0)
    WriteModifiedFileB()

	if Platform == 'win32' then
		local pattern5 = [[
*** found 26 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.lib
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
!NEXT!*** updated 3 target(s)...
]]
		TestPattern(pattern5, RunJam())
	else
		local pattern5 = [[
*** found 18 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libA>libA.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libA>libA.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 3 target(s)...
]]
		TestPattern(pattern5, RunJam())
	end

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
	WriteOriginalFiles()
end


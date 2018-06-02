local originalFiles = {
	'Jamfile.jam',
	'test.lua',
	'app/Jamfile.jam',
	'app/main.c',
	'lib-a/Jamfile.jam',
	'lib-a/add.c',
	'lib-a/add.h',
}

local originalDirs = {
	'app/',
	'lib-a/',
}

local dirs
local files
local patternA
local patternB
local patternC
local patternC_useChecksums
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
		'$(TOOLCHAIN_PATH)/app/app/app.exe',
		'?$(TOOLCHAIN_PATH)/app/app/app.exe.intermediate.manifest',
		'$(TOOLCHAIN_PATH)/app/app/app.pdb',
		'$(TOOLCHAIN_PATH)/app/app/main.obj',
		'lib-a/add.c',
		'lib-a/add.h',
		'lib-a/Jamfile.jam',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.obj',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.lib',
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

	patternB_useChecksums = [[
*** found 12 target(s)...
*** updating 2 target(s)...
*** updated 2 target(s)...
]]

	patternC = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 2 target(s)...
]]

	patternC_useChecksums = patternC

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
		'$(TOOLCHAIN_PATH)/app/app/app',
		'$(TOOLCHAIN_PATH)/app/app/main.o',
		'lib-a/add.c',
		'lib-a/add.h',
		'lib-a/Jamfile.jam',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.o',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.a',
	}

	patternA = [[
*** found 12 target(s)...
*** updating 6 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-a>add.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-a>lib-a.a 
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 6 target(s)...
]]

	patternB = [[
*** found 12 target(s)...
]]

	patternB_useChecksums = [[
*** found 12 target(s)...
*** updating 2 target(s)...
*** updated 2 target(s)...
]]

	patternC = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app
*** updated 2 target(s)...
]]

if Platform == 'linux' then
	patternC_useChecksums = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
*** updated 2 target(s)...
]]
else
	patternC_useChecksums = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
*** updated 2 target(s)...
]]
end

	patternD = [[
*** found 12 target(s)...
]]

end


function Test()
	local function WriteOriginalFiles()
		ospath.write_file('lib-a/add.h', [[
int Add(int a, int b);
]])
	end

	local function WriteModifiedFileA()
		ospath.write_file('lib-a/add.h', [[
// Modified
int Add(int a, int b);
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

		if useChecksums then
			TestPattern(patternB_useChecksums, RunJam{})

			osprocess.sleep(1.0)
			WriteModifiedFileA()
		end

		TestPattern(useChecksums  and  patternC_useChecksums  or  patternC, RunJam{})
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
	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

TestChecksum = Test

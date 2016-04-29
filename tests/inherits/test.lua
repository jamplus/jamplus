local originalFiles =
{
	'app/Jamfile.jam',
	'app/main.c',
	'Jamfile.jam',
	'lib-a/add.c',
	'lib-a/add.h',
	'lib-a/Jamfile.jam',
	'nested-lib-b/Jamfile.jam',
	'nested-lib-b/sub.c',
	'nested-lib-b/sub.h',
	'nested-lib-c/Jamfile.jam',
	'nested-lib-c/mul.c',
	'nested-lib-c/mul.h',
}

local originalDirs =
{
	'app/',
	'lib-a/',
	'nested-lib-b/',
	'nested-lib-c/',
}


local dirs
local files
local patternA
local patternB
local patternC
local patternC_checksums
local patternD

if Platform == 'win32' then
	dirs =
	{
		'app/',
		'$(TOOLCHAIN_PATH)/',
		'$(TOOLCHAIN_PATH)/app/app/',
		'lib-a/',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/',
		'nested-lib-b/',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/',
		'nested-lib-c/',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/',
	}

	files = {
		'app/Jamfile.jam',
		'app/main.c',
		'$(TOOLCHAIN_PATH)/app/app/app.exe',
		'$(TOOLCHAIN_PATH)/app/app/app.pdb',
		'$(TOOLCHAIN_PATH)/app/app/main.obj',
		'Jamfile.jam',
		'lib-a/add.c',
		'lib-a/add.h',
		'lib-a/Jamfile.jam',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.obj',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.lib',
		'nested-lib-b/Jamfile.jam',
		'nested-lib-b/sub.c',
		'nested-lib-b/sub.h',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/nested-lib-b.lib',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/sub.obj',
		'nested-lib-c/Jamfile.jam',
		'nested-lib-c/mul.c',
		'nested-lib-c/mul.h',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/mul.obj',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/nested-lib-c.lib',
	}

	patternA = [[
*** found 22 target(s)...
*** updating 12 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-a>add.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):nested-lib-b>sub.obj
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):nested-lib-c>mul.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):nested-lib-c>nested-lib-c.lib
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):nested-lib-b>nested-lib-b.lib
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-a>lib-a.lib
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 12 target(s)...
]]

	patternB = [[
*** found 22 target(s)...
]]

	patternC = [[
*** found 22 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 2 target(s)...
]]

	patternC_checksums = [[
*** found 22 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app.exe
!NEXT!*** updated 2 target(s)...
]]

	patternD = [[
*** found 22 target(s)...
]]

else
	dirs =
	{
		'app/',
		'$(TOOLCHAIN_PATH)/',
		'$(TOOLCHAIN_PATH)/app/app/',
		'lib-a/',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/',
		'nested-lib-b/',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/',
		'nested-lib-c/',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/',
	}

	files = {
		'app/Jamfile.jam',
		'app/main.c',
		'$(TOOLCHAIN_PATH)/app/app/app',
		'$(TOOLCHAIN_PATH)/app/app/main.o',
		'Jamfile.jam',
		'lib-a/add.c',
		'lib-a/add.h',
		'lib-a/Jamfile.jam',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/add.o',
		'$(TOOLCHAIN_PATH)/lib-a/lib-a/lib-a.a',
		'nested-lib-b/Jamfile.jam',
		'nested-lib-b/sub.c',
		'nested-lib-b/sub.h',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/nested-lib-b.a',
		'$(TOOLCHAIN_PATH)/nested-lib-b/nested-lib-b/sub.o',
		'nested-lib-c/Jamfile.jam',
		'nested-lib-c/mul.c',
		'nested-lib-c/mul.h',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/mul.o',
		'$(TOOLCHAIN_PATH)/nested-lib-c/nested-lib-c/nested-lib-c.a',
	}

	patternA = [[
*** found 22 target(s)...
*** updating 12 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):lib-a>add.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):nested-lib-b>sub.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):nested-lib-c>mul.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):nested-lib-c>nested-lib-c.a 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):nested-lib-b>nested-lib-b.a 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):lib-a>lib-a.a 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app 
*** updated 12 target(s)...
]]

	patternB = [[
*** found 22 target(s)...
]]

	patternC = [[
*** found 22 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):app>app 
*** updated 2 target(s)...
]]

	patternC_checksums = [[
*** found 22 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):app>main.o
*** updated 1 target(s)...
]]

	patternD = [[
*** found 22 target(s)...
]]


end


function Test()
	do
		-- Test for a clean directory.
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


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function TestChecksum()
	local function WriteOriginalFiles()
		ospath.write_file('lib-a/add.h', [[
int Add(int a, int b);
]])
	end

	local function WriteModifiedFiles()
		ospath.write_file('lib-a/add.h', [[
// I am modified!
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
		if useChecksums then
			patternB = [[
*** found 35 target(s)...
*** updating 2 target(s)...
*** updated 2 target(s)...
]]
		end
		osprocess.sleep(1.0)
		ospath.touch('lib-a/add.h')
		TestPattern(patternB, RunJam{})

		osprocess.sleep(1.0)
		WriteModifiedFiles()

		TestPattern(patternC_checksums, RunJam{})
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

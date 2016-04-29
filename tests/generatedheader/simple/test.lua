function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'main.c',
		'test.c',
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
@ WriteFile <$(TOOLCHAIN_GRIST):test>test.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}
		
		local pass1Files =
		{
			'Jamfile.jam',
			'main.c',
			'test.c',
			'test.h',
			'$(TOOLCHAIN_PATH)/test/main.obj',
			'$(TOOLCHAIN_PATH)/test/test.obj',
			'$(TOOLCHAIN_PATH)/test/test.exe',
			'?$(TOOLCHAIN_PATH)/test/test.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/test/test.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 19 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		osprocess.sleep(1.0)
		ospath.touch('test.h')

		local pattern3 = [[
*** found 19 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
	
	else

		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>test.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>test.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test 
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = { 
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}

		local pass1Files = { 
			'Jamfile.jam',
			'main.c',
			'test.c',
			'test.h',
			'test.lua',
			'$(TOOLCHAIN_PATH)/test/main.o',
			'$(TOOLCHAIN_PATH)/test/test.o',
			'$(TOOLCHAIN_PATH)/test/test',
		}	

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('test.h')

		local pattern3 = [[
*** found 11 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test 
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())

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
		ospath.write_file('test.h', [[
extern void Print(const char* str);
]])
	end

	local function WriteModifiedFile()
		ospath.write_file('test.h', [[
// Modified file
extern void Print(const char* str);
]])
	end

	-- Test for a clean directory.
	local originalFiles = {
		'Jamfile.jam',
		'main.c',
		'test.c',
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
@ WriteFile <$(TOOLCHAIN_GRIST):test>test.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}
		
		local pass1Files =
		{
			'Jamfile.jam',
			'main.c',
			'test.c',
			'test.h',
			'$(TOOLCHAIN_PATH)/test/main.obj',
			'$(TOOLCHAIN_PATH)/test/test.obj',
			'$(TOOLCHAIN_PATH)/test/test.exe',
			'?$(TOOLCHAIN_PATH)/test/test.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/test/test.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 19 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		if useChecksums then
			pattern2 = [[
*** found 21 target(s)...
*** updating 2 target(s)...
*** updated 2 target(s)...
]]
		else
			pattern2 = [[
*** found 21 target(s)...
]]
		end
		osprocess.sleep(1.0)
		ospath.touch('test.h')
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		WriteModifiedFile()

		local pattern3 = [[
*** found 19 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
	
	else

		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>test.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>test.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test 
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = { 
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}

		local pass1Files = { 
			'Jamfile.jam',
			'main.c',
			'test.c',
			'test.h',
			'test.lua',
			'$(TOOLCHAIN_PATH)/test/main.o',
			'$(TOOLCHAIN_PATH)/test/test.o',
			'$(TOOLCHAIN_PATH)/test/test',
		}	

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('test.h')
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		WriteModifiedFile()

		local pattern3 = [[
*** found 11 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
*** updated 1 target(s)...
]]
		TestPattern(pattern3, RunJam())

	end

	WriteOriginalFiles()
	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'main.c',
		'main.h',
		'test.c',
	}

	local originalDirs =
	{
	}

	ospath.remove('.jamcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local patternA
	local patternB
	local patternC
	local noDepCacheFiles
	local dirs
	
	if Platform == 'win32' then
		dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}

		noDepCacheFiles =
		{
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'$(TOOLCHAIN_PATH)/test/main.obj',
			'$(TOOLCHAIN_PATH)/test/test.obj',
			'$(TOOLCHAIN_PATH)/test/test.exe',
			'?$(TOOLCHAIN_PATH)/test/test.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/test/test.pdb',
		}
		
		patternA = [[
*** found 21 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
]]

		patternB = [[
*** found 21 target(s)...
]]

		patternC = [[
*** found 21 target(s)...
]]
	else
		dirs = {
			'$(TOOLCHAIN_PATH)/',
			'$(TOOLCHAIN_PATH)/test/',
		}

		noDepCacheFiles = {
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/test/main.o',
			'$(TOOLCHAIN_PATH)/test/test.o',
			'$(TOOLCHAIN_PATH)/test/test',
		}
		
		patternA = [[
*** found 13 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>test.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 5 target(s)...
]]

		if useChecksums then
			patternB = [[
*** found 23 target(s)...
]]

			patternC = [[
*** found 23 target(s)...
]]
		else
			patternB = [[
*** found 13 target(s)...
]]

			patternC = [[
*** found 13 target(s)...
]]
		end

	end

	do
		TestPattern(patternA, RunJam{ 'JAM_NO_DEPCACHE=1' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{ 'JAM_NO_DEPCACHE=1' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{ 'JAM_NO_DEPCACHE=1' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		TestPattern(patternB, RunJam{ 'JAM_NO_DEPCACHE=1', 'GENERATED_VERSION=v3' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local depCacheFiles
	local patternA
	local patternB
	local patternC
	local patternD
	local patternE
	
	if Platform == 'win32' then
		depCacheFiles = {
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'$(TOOLCHAIN_PATH)/test/main.obj',
			'$(TOOLCHAIN_PATH)/test/test.obj',
			'$(TOOLCHAIN_PATH)/test/test.exe',
			'?$(TOOLCHAIN_PATH)/test/test.exe.intermediate.manifest',
			'$(TOOLCHAIN_PATH)/test/test.pdb',
		}
		
		patternA = [[
*** found 21 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
]]

		if useChecksums then
			patternB = [[
*** found 13 target(s)...
]]
		else
			patternB = [[
*** found 23 target(s)...
]]
		end

		patternC = [[
*** found 21 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 3 target(s)...
]]

		if useChecksums then
			patternD = [[
*** found 21 target(s)...
]]
		else
			patternD = [[
*** found 21 target(s)...
]]
		end

		patternE = [[
*** found 21 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 3 target(s)...
]]

	else
		depCacheFiles = {
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'test.lua',
			'$(TOOLCHAIN_PATH)/test/main.o',
			'$(TOOLCHAIN_PATH)/test/test.o',
			'$(TOOLCHAIN_PATH)/test/test',
		}
		
		patternA = [[
*** found 13 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>test.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 5 target(s)...
]]

		if useChecksums then
			patternB = [[
*** found 13 target(s)...
]]

			patternC = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
*** updated 2 target(s)...
]]
		else
			patternB = [[
*** found 13 target(s)...
]]

			patternC = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 3 target(s)...
]]
		end

		if useChecksums then
			patternD = [[
*** found 13 target(s)...
]]

			patternE = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
*** updated 1 target(s)...
]]
		else
			patternD = [[
*** found 13 target(s)...
]]

			patternE = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>generated.h
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 3 target(s)...
]]
		end
	end

	do
		TestPattern(patternA, RunJam{})
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{})
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		TestPattern(patternC, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternD, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		osprocess.sleep(1.0)
		TestPattern(patternE, RunJam{})
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

TestChecksum = Test

function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateVS2008JamWorkspace.bat',
		'Jamfile.jam',
		'filedebug.c',
		'filerelease.c',
		'linux.c',
		'macosx.c',
		'platform.c',
		'win32.c',
	}

	local originalDirs =
	{
	}

	ospath.remove('.jamcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pass1Directories
	local pass1Files
	do
		local pattern
	    if Platform == 'win32' then
			pattern = [[
*** found 20 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>platform.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):platform>platform.exe
!NEXT!*** updated 5 target(s)...
]]
			pass1Directories = {
				'$(TOOLCHAIN_PATH)/',
				'$(TOOLCHAIN_PATH)/platform/',
			}

			pass1Files =
			{
				'.jamcache',
				'CreateVS2008JamWorkspace.bat',
				'Jamfile.jam',
				'filedebug.c',
				'filerelease.c',
				'linux.c',
				'macosx.c',
				'platform.c',
				'win32.c',
				'$(TOOLCHAIN_PATH)/platform/filerelease.obj',
				'$(TOOLCHAIN_PATH)/platform/platform.obj',
				'$(TOOLCHAIN_PATH)/platform/platform.release.exe',
				'?$(TOOLCHAIN_PATH)/platform/platform.release.exe.intermediate.manifest',
				'$(TOOLCHAIN_PATH)/platform/platform.release.pdb',
				'$(TOOLCHAIN_PATH)/platform/win32.obj',
			}

		else
			if Platform == 'macosx' then
				pattern = [[
*** found 12 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>platform.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>macosx.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>filerelease.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):platform>platform
*** updated 5 target(s)...
]]
			elseif Platform == 'linux' then
				pattern = [[
*** found 12 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>platform.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>linux.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>filerelease.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):platform>platform
*** updated 5 target(s)...
]]
			else
				pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>platform.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>linux.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):platform>filerelease.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):platform>platform
*** updated 4 target(s)...
]]
			end

			pass1Directories = {
				'$(TOOLCHAIN_PATH)/',
				'$(TOOLCHAIN_PATH)/platform/',
			}

			pass1Files = {
				'.jamcache',
				'CreateVS2008JamWorkspace.bat',
				'filedebug.c',
				'filerelease.c',
				'Jamfile.jam',
				'linux.c',
				'macosx.c',
				'platform.c',
				'test.lua',
				'win32.c',
				'$(TOOLCHAIN_PATH)/platform/filerelease.o',
				'$(TOOLCHAIN_PATH)/platform/platform.o',
				'$(TOOLCHAIN_PATH)/platform/platform.release',
			}

			if Platform == 'macosx' then
				pass1Files[#pass1Files + 1] = '$(TOOLCHAIN_PATH)/platform/macosx.o'
			else
				pass1Files[#pass1Files + 1] = '$(TOOLCHAIN_PATH)/platform/linux.o'
			end

		end

		TestPattern(pattern, RunJam())

		TestDirectories(pass1Directories)
		TestFiles(pass1Files)
	end

	---------------------------------------------------------------------------
	local pattern3
	if Platform == 'win32' then
		local pattern2 = [[
Using win32
This is a Win32 build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, osprocess.collectlines{'.build\\win32-release\\TOP\\platform\\platform.release.exe'})

		pattern3 = [[
*** found 20 target(s)...
]]

	elseif Platform == 'macosx' then
		local pattern2 = [[
Using macosx
This is a Mac OS X build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, osprocess.collectlines{'./.build/macosx32-release/TOP/platform/platform.release'})

		pattern3 = [[
*** found 12 target(s)...
]]

	else
		local pattern2 = [[
Using linux
This is a Linux build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, osprocess.collectlines{'./.build/linux32-release/TOP/platform/platform.release'})

		pattern3 = [[
*** found 12 target(s)...
]]

	end
	
	---------------------------------------------------------------------------
	TestPattern(pattern3, RunJam())
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	ospath.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

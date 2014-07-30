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
*** found 22 target(s)...
*** updating 6 target(s)...
@ C.vc.CC <win32!release:platform>platform.obj
!NEXT!@ C.vc.Link <win32!release:platform>platform.exe
!NEXT!*** updated 6 target(s)...
]]
			pass1Directories = {
				'win32-release/',
				'win32-release/platform/',
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
				'win32-release/platform/filerelease.obj',
				'win32-release/platform/platform.obj',
				'win32-release/platform/platform.release.exe',
				'?win32-release/platform/platform.release.exe.intermediate.manifest',
				'win32-release/platform/platform.release.pdb',
				'win32-release/platform/win32.obj',
			}

		else
			if Platform == 'macosx' then
				pattern = [[
*** found 12 target(s)...
*** updating 5 target(s)...
@ C.gcc.CC <macosx32!release:platform>platform.o 
@ C.gcc.CC <macosx32!release:platform>macosx.o 
@ C.gcc.CC <macosx32!release:platform>filerelease.o 
@ C.gcc.Link <macosx32!release:platform>platform
*** updated 5 target(s)...
]]
			else
				pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.CC <platform>platform.o
@ C.CC <platform>linux.o
@ C.CC <platform>filerelease.o
@ C.Link <platform>platform.release
*** updated 4 target(s)...
]]
			end

			pass1Directories = {
				'macosx32-release/',
				'macosx32-release/platform/',
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
				'macosx32-release/platform/filerelease.o',
				'macosx32-release/platform/macosx.o',
				'macosx32-release/platform/platform.o',
				'macosx32-release/platform/platform.release',
			}

			if Platform == 'macosx' then
				pass1Files[#pass1Files + 1] = 'macosx32-release/platform/macosx.o'
			else
				pass1Files[#pass1Files + 1] = 'linux.o'
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
		TestPattern(pattern2, osprocess.collectlines{'win32-release\\platform\\platform.release.exe'})

		pattern3 = [[
*** found 22 target(s)...
]]

	elseif Platform == 'macosx' then
		local pattern2 = [[
Using macosx
This is a Mac OS X build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, osprocess.collectlines{'./macosx32-release/platform/platform.release'})

		pattern3 = [[
*** found 12 target(s)...
]]

	else
		local pattern2 = [[
Using linux
This is a Linux build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, osprocess.collectlines{'./platform.release'})

		pattern3 = [[
*** found 11 target(s)...
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

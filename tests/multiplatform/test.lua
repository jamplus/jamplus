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

	os.remove('.jamcache')
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
*** found 19 target(s)...
*** updating 6 target(s)...
@ C.vc.CC <win32!release:platform>platform.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:platform>platform.exe
!NEXT!*** updated 6 target(s)...
]]
			pass1Directories = {
				'win32!release/',
				'win32!release/platform/',
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
				'win32!release/platform/filerelease.obj',
				'win32!release/platform/platform.obj',
				'win32!release/platform/platform.release.exe',
				'win32!release/platform/platform.release.exe.intermediate.manifest',
				'win32!release/platform/platform.release.pdb',
				'win32!release/platform/win32.obj',
			}

		else
			if Platform == 'macosx' then
				pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.CC <platform>platform.o 
@ C.CC <platform>macosx.o 
@ C.CC <platform>filerelease.o 
@ C.Link <platform>platform.release 
*** updated 4 target(s)...
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

			pass1Files = {
				'.jamcache',
				'CreateVS2008JamWorkspace.bat',
				'filedebug.c',
				'filerelease.c',
				'filerelease.o',
				'Jamfile.jam',
				'linux.c',
				'macosx.c',
				'platform.c',
				'platform.o',
				'platform.release',
				'win32.c',
			}

			if Platform == 'macosx' then
				pass1Files[#pass1Files + 1] = 'macosx.o'
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
		TestPattern(pattern2, ex.collectlines{'win32!release\\platform\\platform.release.exe'})

		pattern3 = [[
*** found 19 target(s)...
]]

	elseif Platform == 'macosx' then
		local pattern2 = [[
Using macosx
This is a Mac OS X build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, ex.collectlines{'./platform.release'})

		pattern3 = [[
*** found 11 target(s)...
]]

	else
		local pattern2 = [[
Using linux
This is a Linux build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, ex.collectlines{'./platform.release'})

		pattern3 = [[
*** found 11 target(s)...
]]

	end
	
	---------------------------------------------------------------------------
	TestPattern(pattern3, RunJam())
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

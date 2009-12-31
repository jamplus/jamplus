function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateVS2008JamWorkspace.bat',
		'Jamfile.jam',
		'filedebug.c',
		'filerelease.c',
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
	local pass1Files
	do
		local pattern
	    if Platform == 'win32' then
			pattern = [[
*** found 17 target(s)...
*** updating 4 target(s)...
@ C.CC <platform>platform.obj
platform.c
win32.c
filerelease.c
Generating Code...
@ C.LinkWithManifest <platform>platform.release.exe
*** updated 4 target(s)...
]]

			pass1Files =
			{
				'.jamcache',
				'CreateVS2008JamWorkspace.bat',
				'Jamfile.jam',
				'filedebug.c',
				'filerelease.c',
				'filerelease.obj',
				'macosx.c',
				'platform.c',
				'platform.obj',
				'platform.release.exe',
				'platform.release.exe.intermediate.manifest',
				'platform.release.pdb',
				'test.lua',
				'vc.pdb',
				'win32.c',
				'win32.obj',
			}

		else
			pattern = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.CC <platform>platform.o 
@ C.CC <platform>macosx.o 
@ C.CC <platform>filerelease.o 
@ C.Link <platform>platform.release 
*** updated 4 target(s)...
]]

			pass1Files = {
				'.jamcache',
				'CreateVS2008JamWorkspace.bat',
				'filedebug.c',
				'filerelease.c',
				'filerelease.o',
				'Jamfile.jam',
				'macosx.c',
				'macosx.o',
				'platform.c',
				'platform.o',
				'platform.release',
				'win32.c',
			}

		end

		TestPattern(pattern, RunJam())

		TestDirectories(originalDirs)
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
		TestPattern(pattern2, ex.collectlines{'platform.release.exe'})

		pattern3 = [[
*** found 17 target(s)...
]]

	else
		local pattern2 = [[
Using macosx
This is a Mac OS X build.
RELEASE: What's up?!
]]
		TestPattern(pattern2, ex.collectlines{'platform.release.exe'})

		pattern3 = [[
*** found 11 target(s)...
]]

	end
	
	---------------------------------------------------------------------------
	TestPattern(pattern3, RunJam())
	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

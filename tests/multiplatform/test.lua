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
	local pattern = [[
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

	TestPattern(pattern, RunJam())

	local pass1Files =
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

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2 = [[
Using win32
This is a Win32 build.
RELEASE: What's up?!
]]
	TestPattern(pattern2, ex.collectlines{'platform.release.exe'})
	
	---------------------------------------------------------------------------
	local pattern3 = [[
*** found 17 target(s)...
]]

	TestPattern(pattern3, RunJam())
	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

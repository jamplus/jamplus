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

	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local noDepCacheFiles =
	{
		'Jamfile.jam',
		'generated.h',
		'main.c',
		'main.h',
		'main.obj',
		'test.c',
		'test.lua',
		'test.obj',
		'test.release.exe',
		'test.release.exe.intermediate.manifest',
		'test.release.pdb',
		'vc.pdb',
	}

	do
		local pattern = [[
*** found 17 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.obj
main.c
test.c
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{ 'NO_DEP_CACHE=1' })

		TestDirectories(originalDirs)
		TestFiles(noDepCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]
		TestPattern(pattern, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(originalDirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]
		TestPattern(pattern, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(originalDirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local depCacheFiles =
	{
		'.jamcache',
		'Jamfile.jam',
		'generated.h',
		'main.c',
		'main.h',
		'main.obj',
		'test.c',
		'test.lua',
		'test.obj',
		'test.release.exe',
		'test.release.exe.intermediate.manifest',
		'test.release.pdb',
		'vc.pdb',
	}

	do
		local pattern = [[
*** found 17 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.obj
main.c
test.c
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{})

		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		TestPattern(pattern, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 17 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

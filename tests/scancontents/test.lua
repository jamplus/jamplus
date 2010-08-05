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
	local patternA
	local patternB
	local patternC
	local noDepCacheFiles
	
	if Platform == 'win32' then
		noDepCacheFiles =
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
		
		patternA = [[
*** found 16 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.obj
main.c
test.c
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 4 target(s)...
]]

		patternB = [[
*** found 16 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]

		patternC = [[
*** found 16 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]
	else
		noDepCacheFiles = {
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'main.o',
			'test.c',
			'test.lua',
			'test.o',
			'test.release',
		}
		
		patternA = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.o 
@ C.CC <test>test.o 
@ C.Link <test>test.release 
*** updated 4 target(s)...
]]

		patternB = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.o 
@ C.Link <test>test.release 
*** updated 3 target(s)...
]]

		patternC = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.o 
@ C.Link <test>test.release 
*** updated 3 target(s)...
]]
	end

	do
		TestPattern(patternA, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(originalDirs)
		TestFiles(noDepCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(originalDirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	do
		TestPattern(patternC, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(originalDirs)
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
		
		patternA = [[
*** found 16 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.obj
main.c
test.c
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 4 target(s)...
]]

		patternB = [[
*** found 16 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternC = [[
*** found 16 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]

		patternD = [[
*** found 16 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternE = [[
*** found 16 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.obj
main.c
@ C.LinkWithManifest <test>test.release.exe
*** updated 3 target(s)...
]]

	else
		depCacheFiles = {
			'.jamcache',
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'main.o',
			'test.c',
			'test.lua',
			'test.o',
			'test.release',
		}
		
		patternA = [[
*** found 11 target(s)...
*** updating 4 target(s)...
@ C.CC <test>main.o 
@ C.CC <test>test.o 
@ C.Link <test>test.release 
*** updated 4 target(s)...
]]

		patternB = [[
*** found 11 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternC = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.o 
@ C.Link <test>test.release 
*** updated 3 target(s)...
]]

		patternD = [[
*** found 11 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternE = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.CC <test>main.o 
@ C.Link <test>test.release 
*** updated 3 target(s)...
]]
	end

	do
		TestPattern(patternA, RunJam{})
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{})
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternC, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternD, RunJam{ 'GENERATED_VERSION=v3' })
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternE, RunJam{})
		TestDirectories(originalDirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

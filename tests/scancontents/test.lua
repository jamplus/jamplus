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
	local dirs
	
	if Platform == 'win32' then
		dirs = {
			'win32!release/',
			'win32!release/test/',
		}

		noDepCacheFiles =
		{
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'win32!release/test/main.obj',
			'win32!release/test/test.obj',
			'win32!release/test/test.release.exe',
			'win32!release/test/test.release.exe.intermediate.manifest',
			'win32!release/test/test.release.pdb',
		}
		
		patternA = [[
*** found 19 target(s)...
*** updating 6 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 6 target(s)...
]]

		patternB = [[
*** found 19 target(s)...
*** updating 3 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 3 target(s)...
]]

		patternC = [[
*** found 19 target(s)...
*** updating 3 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 3 target(s)...
]]
	else
		dirs = {
			'macosx32!release/',
			'macosx32!release/test/',
		}

		noDepCacheFiles = {
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'test.lua',
			'macosx32!release/test/main.o',
			'macosx32!release/test/test.o',
			'macosx32!release/test/test.release',
		}
		
		patternA = [[
*** found 13 target(s)...
*** updating 5 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.CC <macosx32!release:test>test.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 5 target(s)...
]]

		patternB = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 3 target(s)...
]]

		patternC = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 3 target(s)...
]]
	end

	do
		TestPattern(patternA, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{ 'NO_DEP_CACHE=1' })
		TestDirectories(dirs)
		TestFiles(noDepCacheFiles)
	end
	
	---------------------------------------------------------------------------
	do
		TestPattern(patternC, RunJam{ 'NO_DEP_CACHE=1' })
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
			'.jamcache',
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'win32!release/test/main.obj',
			'win32!release/test/test.obj',
			'win32!release/test/test.release.exe',
			'win32!release/test/test.release.exe.intermediate.manifest',
			'win32!release/test/test.release.pdb',
		}
		
		patternA = [[
*** found 19 target(s)...
*** updating 6 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 6 target(s)...
]]

		patternB = [[
*** found 19 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternC = [[
*** found 19 target(s)...
*** updating 3 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 3 target(s)...
]]

		patternD = [[
*** found 19 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternE = [[
*** found 19 target(s)...
*** updating 3 target(s)...
@ C.vc.CC <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 3 target(s)...
]]

	else
		depCacheFiles = {
			'.jamcache',
			'generated.h',
			'Jamfile.jam',
			'main.c',
			'main.h',
			'test.c',
			'test.lua',
			'macosx32!release/test/main.o',
			'macosx32!release/test/test.o',
			'macosx32!release/test/test.release',
		}
		
		patternA = [[
*** found 13 target(s)...
*** updating 5 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.CC <macosx32!release:test>test.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 5 target(s)...
]]

		patternB = [[
*** found 13 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternC = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 3 target(s)...
]]

		patternD = [[
*** found 13 target(s)...
*** updating 3 target(s)...
*** updated 1 target(s)...
]]

		patternE = [[
*** found 13 target(s)...
*** updating 3 target(s)...
@ C.gcc.CC <macosx32!release:test>main.o 
@ C.gcc.Link <macosx32!release:test>test
*** updated 3 target(s)...
]]
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
		TestPattern(patternE, RunJam{})
		TestDirectories(dirs)
		TestFiles(depCacheFiles)
	end

	---------------------------------------------------------------------------
	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

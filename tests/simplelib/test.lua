function Test()
	local originalFiles =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/main.c',
		'lib-a/Jamfile.jam',
		'lib-a/add.c',
		'lib-a/add.h',
	}

	local originalDirs =
	{
		'app/',
		'lib-a/',
	}

	do
		-- Test for a clean directory.
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs =
	{
		'app/',
		'lib-a/',
		'app/win32!release/',
		'app/win32!release/app/',
		'lib-a/win32!release/',
		'lib-a/win32!release/lib-a/',
	}
	
	local files
	local patternA
	local patternB
	local patternC
	local patternD
	
	if Platform == 'win32' then
		files = {
			'Jamfile.jam',
			'test.lua',
			'app/Jamfile.jam',
			'app/main.c',
			'app/win32!release/app/app.release.exe',
			'app/win32!release/app/app.release.exe.intermediate.manifest',
			'app/win32!release/app/app.release.pdb',
			'app/win32!release/app/main.obj',
			'lib-a/add.c',
			'lib-a/add.h',
			'lib-a/Jamfile.jam',
			'lib-a/win32!release/lib-a/add.obj',
			'lib-a/win32!release/lib-a/lib-a.release.lib',
		}
	
		patternA = [[
*** found 16 target(s)...
*** updating 8 target(s)...
@ C.vc.CC <win32!release:app>main.obj
!NEXT!@ C.vc.CC <win32!release:lib-a>add.obj
!NEXT!@ C.vc.Archive <win32!release:lib-a>lib-a.lib
!NEXT!@ C.vc.LinkWithManifest <win32!release:app>app.exe
!NEXT!*** updated 8 target(s)...
]]

		patternB = [[
*** found 16 target(s)...
]]

		patternC = [[
*** found 16 target(s)...
*** updating 2 target(s)...
@ C.vc.CC <win32!release:app>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:app>app.exe
!NEXT!*** updated 2 target(s)...
]]

		patternD = [[
*** found 16 target(s)...
]]

	else
		files = {
			'Jamfile.jam',
			'app/app.release',
			'app/Jamfile.jam',
			'app/main.c',
			'app/main.o',
			'lib-a/add.c',
			'lib-a/add.h',
			'lib-a/add.o',
			'lib-a/Jamfile.jam',
			'lib-a/lib-a.release.a',
		}

		patternA = [[
*** found 12 target(s)...
*** updating 4 target(s)...
@ C.CC <lib-a>add.o 
@ C.Archive <lib-a>lib-a.a 
!NEXT!@ C.Ranlib <lib-a>lib-a.a 
@ C.CC <app>main.o 
@ C.Link <app>app.release 
*** updated 4 target(s)...
]]

		patternB = [[
*** found 12 target(s)...
]]

		patternC = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.CC <app>main.o 
@ C.Link <app>app.release 
*** updated 2 target(s)...
]]

		patternD = [[
*** found 12 target(s)...
]]

	end

	do
		TestPattern(patternA, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternB, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('lib-a/add.h')

		TestPattern(patternC, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		TestPattern(patternD, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

function Test()
	local originalFiles =
	{
        'app/Jamfile.jam',
        'app/main.c',
        'Jamfile.jam',
        'lib-a/add.c',
        'lib-a/add.h',
        'lib-a/Jamfile.jam',
        'nested-lib-b/Jamfile.jam',
        'nested-lib-b/sub.c',
        'nested-lib-b/sub.h',
        'nested-lib-c/Jamfile.jam',
        'nested-lib-c/mul.c',
        'nested-lib-c/mul.h',
}

	local originalDirs =
	{
		'app/',
		'lib-a/',
		'nested-lib-b/',
		'nested-lib-c/',
	}

	do
		-- Test for a clean directory.
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs
	local files
	local patternA
	local patternB
	local patternC
	local patternD
	
	if Platform == 'win32' then
		dirs =
		{
			'app/',
			'app/win32-release/',
			'app/win32-release/app/',
			'lib-a/',
			'lib-a/win32-release/',
			'lib-a/win32-release/lib-a/',
			'nested-lib-b/',
			'nested-lib-b/win32-release/',
			'nested-lib-b/win32-release/nested-lib-b/',
			'nested-lib-c/',
			'nested-lib-c/win32-release/',
			'nested-lib-c/win32-release/nested-lib-c/',
		}

		files = {
			'app/Jamfile.jam',
			'app/main.c',
			'app/win32-release/app/app.release.exe',
			'app/win32-release/app/app.release.pdb',
			'app/win32-release/app/main.obj',
			'Jamfile.jam',
			'lib-a/add.c',
			'lib-a/add.h',
			'lib-a/Jamfile.jam',
			'lib-a/win32-release/lib-a/add.obj',
			'lib-a/win32-release/lib-a/lib-a.release.lib',
			'nested-lib-b/Jamfile.jam',
			'nested-lib-b/sub.c',
			'nested-lib-b/sub.h',
			'nested-lib-b/win32-release/nested-lib-b/nested-lib-b.release.lib',
			'nested-lib-b/win32-release/nested-lib-b/sub.obj',
			'nested-lib-c/Jamfile.jam',
			'nested-lib-c/mul.c',
			'nested-lib-c/mul.h',
			'nested-lib-c/win32-release/nested-lib-c/mul.obj',
			'nested-lib-c/win32-release/nested-lib-c/nested-lib-c.release.lib',
		}
	
		patternA = [[
*** found 30 target(s)...
*** updating 16 target(s)...
@ C.vc.CC <win32!release:app>main.obj
!NEXT!@ C.vc.CC <win32!release:lib-a>add.obj
!NEXT!@ C.vc.CC <win32!release:nested-lib-b>sub.obj
!NEXT!@ C.vc.CC <win32!release:nested-lib-c>mul.obj
!NEXT!@ C.vc.Archive <win32!release:nested-lib-c>nested-lib-c.lib
@ C.vc.Archive <win32!release:nested-lib-b>nested-lib-b.lib
@ C.vc.Archive <win32!release:lib-a>lib-a.lib
@ C.vc.Link <win32!release:app>app.exe
*** updated 16 target(s)...
]]

		patternB = [[
*** found 30 target(s)...
]]

		patternC = [[
*** found 30 target(s)...
*** updating 2 target(s)...
@ C.vc.CC <win32!release:app>main.obj
!NEXT!@ C.vc.Link <win32!release:app>app.exe
!NEXT!*** updated 2 target(s)...
]]

		patternD = [[
*** found 30 target(s)...
]]

	else

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
		osprocess.sleep(1.0)
		ospath.touch('lib-a/add.h')

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

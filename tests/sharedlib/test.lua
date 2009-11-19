function Test()
	local originalFiles =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/main.c',
		'lib-c/Jamfile.jam',
		'lib-c/add.c',
		'lib-c/add.h',
		'slib-a/Jamfile.jam',
		'slib-a/slib-a.c',
		'slib-b/Jamfile.jam',
		'slib-b/slib-b.c',
	}

	local originalDirs =
	{
		'app/',
		'lib-c/',
		'slib-a/',
		'slib-b/',
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
		'image/',
		'lib-c/',
		'slib-a/',
		'slib-b/',
		'app/image/',
		'image/TOP/',
		'image/TOP/app/',
		'image/TOP/lib-c/',
		'image/TOP/slib-a/',
		'image/TOP/slib-b/',
	}
	
	local files =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/main.c',
		'app/image/app.release.exe',
		'app/image/app.release.pdb',
		'image/slib-a.release.dll',
		'image/slib-a.release.exp',
		'image/slib-a.release.lib',
		'image/slib-a.release.pdb',
		'image/slib-b.release.dll',
		'image/slib-b.release.exp',
		'image/slib-b.release.lib',
		'image/slib-b.release.pdb',
		'image/TOP/app/app.release.exe.intermediate.manifest',
		'image/TOP/app/main.obj',
		'image/TOP/app/vc.pdb',
		'image/TOP/lib-c/add.obj',
		'image/TOP/lib-c/lib-c.release.lib',
		'image/TOP/lib-c/vc.pdb',
		'image/TOP/slib-a/slib-a.obj',
		'image/TOP/slib-a/slib-a.release.dll.intermediate.manifest',
		'image/TOP/slib-a/vc.pdb',
		'image/TOP/slib-b/slib-b.obj',
		'image/TOP/slib-b/slib-b.release.dll.intermediate.manifest',
		'image/TOP/slib-b/vc.pdb',
		'lib-c/Jamfile.jam',
		'lib-c/add.c',
		'lib-c/add.h',
		'slib-a/Jamfile.jam',
		'slib-a/slib-a.c',
		'slib-b/Jamfile.jam',
		'slib-b/slib-b.c',
	}

	do
		local pattern = [[
*** found 46 target(s)...
*** updating 17 target(s)...
@ C.CC <lib-c>add.obj
add.c
@ C.Archive <lib-c>lib-c.lib
@ C.CC <slib-a>slib-a.obj
slib-a.c
@ C.LinkWithManifest <slib-a>slib-a.release.dll
!NEXT!@ C.CC <slib-b>slib-b.obj
slib-b.c
@ C.LinkWithManifest <slib-b>slib-b.release.dll
!NEXT!@ C.CC <app>main.obj
main.c
@ C.LinkWithManifest <app>app.release.exe
*** updated 17 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 46 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('lib-c/add.h')

		local pattern = [[
*** found 46 target(s)...
*** updating 4 target(s)...
@ C.CC <slib-a>slib-a.obj
slib-a.c
@ C.LinkWithManifest <slib-a>slib-a.release.dll
!NEXT!@ C.CC <slib-b>slib-b.obj
slib-b.c
@ C.LinkWithManifest <slib-b>slib-b.release.dll
!NEXT!@ C.LinkWithManifest <app>app.release.exe
*** updated 5 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 46 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('lib-c/add.c')

		local pattern = [[
*** found 46 target(s)...
*** updating 4 target(s)...
@ C.CC <lib-c>add.obj
add.c
@ C.Archive <lib-c>lib-c.lib
@ C.LinkWithManifest <slib-a>slib-a.release.dll
!NEXT!@ C.LinkWithManifest <slib-b>slib-b.release.dll
!NEXT!@ C.LinkWithManifest <app>app.release.exe
*** updated 5 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 46 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('slib-a/slib-a.c')

		local pattern = [[
*** found 46 target(s)...
*** updating 2 target(s)...
@ C.CC <slib-a>slib-a.obj
slib-a.c
@ C.LinkWithManifest <slib-a>slib-a.release.dll
!NEXT!@ C.LinkWithManifest <app>app.release.exe
*** updated 3 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 46 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

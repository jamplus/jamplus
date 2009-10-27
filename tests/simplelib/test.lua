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
	}
	
	local files =
	{
		'Jamfile.jam',
		'test.lua',
		'app/Jamfile.jam',
		'app/app.release.exe',
		'app/app.release.exe.intermediate.manifest',
		'app/app.release.pdb',
		'app/main.c',
		'app/main.obj',
		'app/vc.pdb',
		'lib-a/Jamfile.jam',
		'lib-a/add.c',
		'lib-a/add.h',
		'lib-a/add.obj',
		'lib-a/lib-a.release.lib',
		'lib-a/vc.pdb',
	}

	do
		local pattern = [[
*** found 12 target(s)...
*** updating 4 target(s)...
@ C.CC <lib-a>add.obj
add.c
@ C.Archive <lib-a>lib-a.lib
@ C.CC <app>main.obj
main.c
@ C.LinkWithManifest <app>app.release.exe
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 12 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('lib-a/add.h')

		local pattern = [[
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.CC <app>main.obj
main.c
@ C.LinkWithManifest <app>app.release.exe
*** updated 2 target(s)...
]]
		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 12 target(s)...
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

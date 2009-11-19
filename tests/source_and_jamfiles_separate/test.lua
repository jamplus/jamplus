function Test()
	local originalFiles =
	{
		'jam/Jamfile.jam',
		'src/createprecomp.c',
		'src/file.c',
		'src/main.c',
		'src/precomp.h',
	}

	local originalDirs =
	{
		'jam/',
		'src/',
	}

	do
		-- Test for a clean directory.
		RunJam{ '-Cjam', 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	---------------------------------------------------------------------------
	local dirs =
	{
		'jam/',
		'src/',
	}
	
	local files =
	{
		'jam/Jamfile.jam',
		'jam/createprecomp.obj',
		'jam/file.obj',
		'jam/helloworld.release.exe',
		'jam/helloworld.release.exe.intermediate.manifest',
		'jam/helloworld.release.pdb',
		'jam/main.obj',
		'jam/precomp.h.pch',
		'jam/vc.pdb',
		'src/createprecomp.c',
		'src/file.c',
		'src/main.c',
		'src/precomp.h',
	}

	do
		local pattern = [[
*** found 20 target(s)...
*** updating 5 target(s)...
@ C.CC <helloworld>precomp.h.pch
createprecomp.c
@ C.CC <helloworld>file.obj
file.c
main.c
Generating Code...
@ C.LinkWithManifest <helloworld>helloworld.release.exe
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 20 target(s)...
]]
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('src/precomp.h')

		local pattern = [[
*** found 20 target(s)...
*** updating 5 target(s)...
@ C.CC <helloworld>precomp.h.pch
createprecomp.c
@ C.CC <helloworld>file.obj
file.c
main.c
Generating Code...
@ C.LinkWithManifest <helloworld>helloworld.release.exe
*** updated 5 target(s)...
]]
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 20 target(s)...
]]
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('src/createprecomp.c')

		local pattern = [[
*** found 20 target(s)...
*** updating 5 target(s)...
@ C.CC <helloworld>precomp.h.pch
createprecomp.c
@ C.CC <helloworld>file.obj
file.c
main.c
Generating Code...
@ C.LinkWithManifest <helloworld>helloworld.release.exe
*** updated 5 target(s)...
]]
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ '-Cjam', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

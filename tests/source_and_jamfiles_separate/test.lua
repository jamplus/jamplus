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
	local dirs
	local files
	local pattern
	
	if Platform == 'win32' then
		dirs =
		{
			'jam/',
			'src/',
		}
	
		files =
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

		pattern = [[
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
	else
		dirs = {
			'jam/',
			'src/',
			'jam/precomp-10708b2c9f7dbac75f1ba74e0c9b6cf6/',
		}

		files = {
			'jam/createprecomp.o',
			'jam/file.o',
			'jam/helloworld.release',
			'jam/Jamfile.jam',
			'jam/main.o',
			'jam/precomp-10708b2c9f7dbac75f1ba74e0c9b6cf6/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 15 target(s)...
			*** updating 6 target(s)...
			@ C.PCH <helloworld-10708b2c9f7dbac75f1ba74e0c9b6cf6>precomp.h.gch 
			@ C.CC <helloworld>file.o 
			@ C.CC <helloworld>main.o 
			@ C.CC <helloworld>createprecomp.o 
			@ C.Link <helloworld>helloworld.release 
			*** updated 6 target(s)...
]]
	
	end

	do
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
				*** found 20 target(s)...
]]
		else
			pattern = [[
				*** found 15 target(s)...
]]
		end
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('src/precomp.h')

		if Platform == 'win32' then
			pattern = [[
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
		else
			pattern = [[
				*** found 15 target(s)...
				*** updating 5 target(s)...
				@ C.PCH <helloworld-10708b2c9f7dbac75f1ba74e0c9b6cf6>precomp.h.gch 
				@ C.CC <helloworld>file.o 
				@ C.CC <helloworld>main.o 
				@ C.CC <helloworld>createprecomp.o 
				@ C.Link <helloworld>helloworld.release 
				*** updated 5 target(s)...
]]
		end

		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		if Platform == 'win32' then
			pattern = [[
				*** found 20 target(s)...
]]
		else
			pattern = [[
				*** found 15 target(s)...
]]
		end
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		os.sleep(1.0)
		os.touch('src/createprecomp.c')

		if Platform == 'win32' then
			pattern = [[
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
		else
			pattern = [[
				*** found 15 target(s)...
				*** updating 2 target(s)...
				@ C.CC <helloworld>createprecomp.o 
				@ C.Link <helloworld>helloworld.release 
				*** updated 2 target(s)...
]]
		end
		TestPattern(pattern, RunJam{ '-Cjam' })
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	RunJam{ '-Cjam', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

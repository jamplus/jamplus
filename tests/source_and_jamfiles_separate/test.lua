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
			'jam/win32!release/',
			'jam/win32!release/helloworld/',
		}
	
		files =
		{
			'jam/Jamfile.jam',
			'jam/win32!release/helloworld/createprecomp.obj',
			'jam/win32!release/helloworld/file.obj',
			'jam/win32!release/helloworld/helloworld.release.exe',
			'jam/win32!release/helloworld/helloworld.release.exe.intermediate.manifest',
			'jam/win32!release/helloworld/helloworld.release.pdb',
			'jam/win32!release/helloworld/main.obj',
			'jam/win32!release/helloworld/precomp.h.pch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}

		pattern = [[
*** found 21 target(s)...
*** updating 7 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 7 target(s)...
]]
	else
		dirs = {
			'jam/',
			'src/',
			'jam/precomp%-%x+/',
		}

		files = {
			'jam/createprecomp.o',
			'jam/file.o',
			'jam/helloworld.release',
			'jam/Jamfile.jam',
			'jam/main.o',
			'jam/precomp%-%x+/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 16 target(s)...
			*** updating 6 target(s)...
			&@ C.PCH <helloworld%-%x+>precomp.h.gch 
			@ C.CC <helloworld>../src/file.o 
			@ C.CC <helloworld>../src/main.o 
			@ C.CC <helloworld>../src/createprecomp.o 
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
				*** found 21 target(s)...
]]
		else
			pattern = [[
				*** found 16 target(s)...
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
*** found 21 target(s)...
*** updating 5 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 16 target(s)...
				*** updating 5 target(s)...
				&@ C.PCH <helloworld%-%x+>precomp.h.gch 
				@ C.CC <helloworld>../src/file.o 
				@ C.CC <helloworld>../src/main.o 
				@ C.CC <helloworld>../src/createprecomp.o 
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
				*** found 21 target(s)...
]]
		else
			pattern = [[
				*** found 16 target(s)...
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
*** found 21 target(s)...
*** updating 5 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 16 target(s)...
				*** updating 2 target(s)...
				@ C.CC <helloworld>../src/createprecomp.o 
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

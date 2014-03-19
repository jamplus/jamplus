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
			'jam/win32-release/',
			'jam/win32-release/helloworld/',
		}
	
		files =
		{
			'jam/Jamfile.jam',
			'jam/win32-release/helloworld/createprecomp.obj',
			'jam/win32-release/helloworld/file.obj',
			'jam/win32-release/helloworld/helloworld.release.exe',
			'?jam/win32-release/helloworld/helloworld.release.exe.intermediate.manifest',
			'jam/win32-release/helloworld/helloworld.release.pdb',
			'jam/win32-release/helloworld/main.obj',
			'jam/win32-release/helloworld/precomp.h.pch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}

		pattern = [[
*** found 24 target(s)...
*** updating 7 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 7 target(s)...
]]
	else
		dirs = {
			'jam/',
			'src/',
			'jam/macosx32-release/',
			'jam/macosx32-release/helloworld/',
			'jam/macosx32%-release/helloworld/precomp%-%x+/',
		}

		files = {
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
			'jam/Jamfile.jam',
			'jam/macosx32-release/helloworld/createprecomp.o',
			'jam/macosx32-release/helloworld/file.o',
			'jam/macosx32-release/helloworld/helloworld.release',
			'jam/macosx32-release/helloworld/main.o',
			'jam/macosx32%-release/helloworld/precomp%-%x+/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 17 target(s)...
			*** updating 7 target(s)...
			&@ C.gcc.PCH <macosx32!release:helloworld%-%x+>precomp.h.gch 
			@ C.gcc.CC <macosx32!release:helloworld>../src/file.o 
			@ C.gcc.CC <macosx32!release:helloworld>../src/main.o 
			@ C.gcc.CC <macosx32!release:helloworld>../src/createprecomp.o 
			@ C.gcc.Link <macosx32!release:helloworld>helloworld 
			*** updated 7 target(s)...
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
				*** found 24 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
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
*** found 24 target(s)...
*** updating 5 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
				*** updating 5 target(s)...
				&@ C.gcc.PCH <macosx32!release:helloworld%-%x+>precomp.h.gch 
				@ C.gcc.CC <macosx32!release:helloworld>../src/file.o 
				@ C.gcc.CC <macosx32!release:helloworld>../src/main.o 
				@ C.gcc.CC <macosx32!release:helloworld>../src/createprecomp.o 
				@ C.gcc.Link <macosx32!release:helloworld>helloworld
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
				*** found 24 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
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
*** found 24 target(s)...
*** updating 5 target(s)...
@ C.vc.CC <win32!release:helloworld>precomp.h.pch
!NEXT!@ C.vc.CC <win32!release:helloworld>../src/file.obj
!NEXT!@ C.vc.Link <win32!release:helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
				*** updating 2 target(s)...
				@ C.gcc.CC <macosx32!release:helloworld>../src/createprecomp.o 
				@ C.gcc.Link <macosx32!release:helloworld>helloworld
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

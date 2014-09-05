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
			'jam/$(PLATFORM_CONFIG)/',
			'jam/$(PLATFORM_CONFIG)/helloworld/',
			'jam/macosx32%-release/helloworld/precomp%-%x+/',
		}

		files = {
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
			'jam/Jamfile.jam',
			'jam/$(PLATFORM_CONFIG)/helloworld/createprecomp.o',
			'jam/$(PLATFORM_CONFIG)/helloworld/file.o',
			'jam/$(PLATFORM_CONFIG)/helloworld/helloworld.release',
			'jam/$(PLATFORM_CONFIG)/helloworld/main.o',
			'jam/macosx32%-release/helloworld/precomp%-%x+/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 17 target(s)...
			*** updating 7 target(s)...
			&@ C.$(COMPILER).PCH <$(PLATFORM_CONFIG):helloworld%-%x+>precomp.h.gch 
			@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/file.o 
			@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/main.o 
			@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/createprecomp.o 
			@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):helloworld>helloworld 
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
		osprocess.sleep(1.0)
		ospath.touch('src/precomp.h')

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
				&@ C.$(COMPILER).PCH <$(PLATFORM_CONFIG):helloworld%-%x+>precomp.h.gch 
				@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/file.o 
				@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/main.o 
				@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/createprecomp.o 
				@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):helloworld>helloworld
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
		osprocess.sleep(1.0)
		ospath.touch('src/createprecomp.c')

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
				@ C.$(COMPILER).CC <$(PLATFORM_CONFIG):helloworld>../src/createprecomp.o 
				@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):helloworld>helloworld
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

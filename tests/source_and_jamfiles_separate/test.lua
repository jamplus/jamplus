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
			'jam/$(TOOLCHAIN_PATH)/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/',
		}
	
		files =
		{
			'jam/Jamfile.jam',
			'jam/.build/.depcache',
			'jam/$(TOOLCHAIN_PATH)/helloworld/createprecomp.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/file.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.release.exe',
			'?jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.release.exe.intermediate.manifest',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.release.pdb',
			'jam/$(TOOLCHAIN_PATH)/helloworld/main.obj',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp.h.pch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}

		pattern = [[
*** found 22 target(s)...
*** updating 6 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>precomp.h.pch
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 6 target(s)...
]]
	else
		dirs = {
			'jam/',
			'src/',
			'jam/$(TOOLCHAIN_PATH)/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp%-%x+/',
		}

		files = {
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
			'jam/Jamfile.jam',
			'jam/.build/.depcache',
			'jam/$(TOOLCHAIN_PATH)/helloworld/createprecomp.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/file.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/helloworld.release',
			'jam/$(TOOLCHAIN_PATH)/helloworld/main.o',
			'jam/$(TOOLCHAIN_PATH)/helloworld/precomp%-%x+/precomp.h.gch',
			'src/createprecomp.c',
			'src/file.c',
			'src/main.c',
			'src/precomp.h',
		}
		
		pattern = [[
			*** found 17 target(s)...
			*** updating 7 target(s)...
			&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):helloworld%-%x+>precomp.h.gch 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.o 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/main.o 
			@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
			@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld 
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
				*** found 22 target(s)...
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
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>precomp.h.pch
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
				*** updating 5 target(s)...
				&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):helloworld%-%x+>precomp.h.gch 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/main.o 
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld
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
				*** found 22 target(s)...
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
*** found 22 target(s)...
*** updating 5 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>precomp.h.pch
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/file.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld.exe
!NEXT!*** updated 5 target(s)...
]]
		else
			pattern = [[
				*** found 17 target(s)...
				*** updating 2 target(s)...
				@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):helloworld>../src/createprecomp.o 
				@ $(C_LINK) <$(TOOLCHAIN_GRIST):helloworld>helloworld
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

function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'test.lua',
		'source/Jamfile.jam',
		'source/project1/Jamfile.jam',
		'source/project1/project1.cpp',
	}

	local originalDirs =
	{
		'source/',
		'source/project1/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	-- First build
	local cwd = ospath.getcwd():gsub(':', '--'):gsub('\\', '/')
	local cwdNoDashes = ospath.getcwd():gsub('\\', '/')
	
	if Platform == 'win32' then
		local pattern = [[
*** found 8 target(s)...
*** updating 4 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>]] .. cwdNoDashes .. [[/source/project1/project1.obj
project1.cpp
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'.build/.depcache',
			'Jamfile.jam',
			'source/Jamfile.jam',
			'source/project1/Jamfile.jam',
			'source/project1/project1.cpp',
			'source/project1/lib/win32/release/project1.exe',
			'source/project1/lib/win32/release/project1.pdb',
			'?source/project1/obj/win32/release/project1.exe.intermediate.manifest',
			'source/project1/obj/win32/release/vc.pdb',
			'source/project1/obj/win32/release/' .. cwd .. '/source/project1/project1.obj',
		}
		
		local pass1Directories =
		{
			'.build/',
			'source/',
			'source/project1/',
			'source/project1/lib/',
			'source/project1/lib/win32/',
			'source/project1/lib/win32/release/',
			'source/project1/obj/',
			'source/project1/obj/win32/',
			'source/project1/obj/win32/release/',
		}
	
		for component in (cwd .. [[/source/project1/project1.obj]]):gmatch('(.-/)') do
			pass1Directories[#pass1Directories + 1] = pass1Directories[#pass1Directories] .. component
		end

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 8 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		osprocess.sleep(1.0)
		ospath.touch('source/project1/project1.cpp')

		local pattern3 = [[
*** found 8 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>]] .. cwdNoDashes .. [[/source/project1/project1.obj
project1.cpp
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1.exe
*** updated 2 target(s)...
]]

		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)
	
	else
		local pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>]] .. cwd .. [[/source/project1/project1.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'.build/.depcache',
			'Jamfile.jam',
			'test.lua',
			'source/Jamfile.jam',
			'source/project1/Jamfile.jam',
			'source/project1/project1.cpp',
			'source/project1/project1.o',
			'source/project1/lib/$PlatformDir/release/project1',
		}

		local pass1Directories =
		{
			'.build/',
			'source/',
			'source/project1/',
			'source/project1/lib/',
			'source/project1/lib/$PlatformDir/',
			'source/project1/lib/$PlatformDir/release/',
		}

--		for component in (cwd .. [[/source/project1/project1.o]]):gmatch('(.-/)') do
--			pass1Directories[#pass1Directories + 1] = pass1Directories[#pass1Directories] .. component
--		end

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 8 target(s)...
]]
		TestPattern(pattern2, RunJam())

		osprocess.sleep(1.0)
		ospath.touch('source/project1/project1.cpp')

		local pattern3 = [[
*** found 8 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):project1>]] .. cwd .. [[/source/project1/project1.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):project1>project1
*** updated 2 target(s)...
]]

		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)
	
	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


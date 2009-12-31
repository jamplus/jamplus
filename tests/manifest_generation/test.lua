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
	local cwd = os.getcwd():gsub(':', '--'):gsub('\\', '/')
	
	if Platform == 'win32' then
		local pattern = [[
*** found 19 target(s)...
*** updating 11 target(s)...
@ C.C++ <project1>]] .. cwd .. [[/source/project1/project1.obj
project1.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 11 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'source/Jamfile.jam',
			'source/project1/Jamfile.jam',
			'source/project1/project1.cpp',
			'source/project1/obj/win32/release/project1.release.exe',
			'source/project1/obj/win32/release/project1.release.exe.intermediate.manifest',
			'source/project1/obj/win32/release/project1.release.pdb',
			'source/project1/obj/win32/release/vc.pdb',
			'source/project1/obj/win32/release/' .. cwd .. '/source/project1/project1.obj',
		}
	
		local pass1Directories =
		{
			'source/',
			'source/project1/',
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
*** found 19 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		os.sleep(1.0)
		os.touch('source/project1/project1.cpp')

		local pattern3 = [[
*** found 19 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>]] .. cwd .. [[/source/project1/project1.obj
project1.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 2 target(s)...
]]

		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(pass1Directories)
	
	else
		local pattern = [[
*** found 7 target(s)...
*** updating 3 target(s)...
@ C.C++ <project1>]] .. cwd .. [[/source/project1/project1.o
@ C.Link <project1>project1.release
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'test.lua',
			'source/Jamfile.jam',
			'source/project1/Jamfile.jam',
			'source/project1/project1.cpp',
			'source/project1/project1.o',
			'source/project1/obj/macosx32/release/project1.release',
		}

		local pass1Directories =
		{
			'source/',
			'source/project1/',
			'source/project1/obj/',
			'source/project1/obj/macosx32/',
			'source/project1/obj/macosx32/release/',
		}

--		for component in (cwd .. [[/source/project1/project1.o]]):gmatch('(.-/)') do
--			pass1Directories[#pass1Directories + 1] = pass1Directories[#pass1Directories] .. component
--		end

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 7 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('source/project1/project1.cpp')

		local pattern3 = [[
*** found 7 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>]] .. cwd .. [[/source/project1/project1.o
@ C.Link <project1>project1.release
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


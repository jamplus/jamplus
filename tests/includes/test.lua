function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'common/common.jam',
		'common/print.cpp',
		'common/print.h',
		'project1/adefine.cpp',
		'project1/project1.cpp',
		'project1/project1.jam',
		'shared/adefine.h',
	}

	local originalDirs =
	{
		'common/',
		'project1/',
		'shared/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 29 target(s)...
*** updating 5 target(s)...
@ C.C++ <common>print.obj
print.cpp
@ C.Archive <common>common.lib
@ C.C++ <project1>project1.obj
project1.cpp
@ C.C++ <project1>adefine.obj
adefine.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'common/common.jam',
			'common/common.release.lib',
			'common/print.cpp',
			'common/print.h',
			'common/print.obj',
			'common/vc.pdb',
			'project1/adefine.cpp',
			'project1/adefine.obj',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/project1.obj',
			'project1/project1.release.exe',
			'project1/project1.release.exe.intermediate.manifest',
			'project1/project1.release.pdb',
			'project1/vc.pdb',
			'shared/adefine.h',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 29 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		os.sleep(1.0)
		os.touch('common/print.h')

		local pattern3 = [[
*** found 29 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>project1.obj
project1.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		os.sleep(1.0)
		os.touch('shared/adefine.h')

		local pattern4 = [[
*** found 29 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>adefine.obj
adefine.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 2 target(s)...	
]]
		TestPattern(pattern4, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)
	
	else

		-- First build
		local pattern = [[
*** found 17 target(s)...
*** updating 5 target(s)...
@ C.C++ <common>print.o 
@ C.Archive <common>common.a 
!NEXT!@ C.Ranlib <common>common.a 
@ C.C++ <project1>project1.o 
@ C.C++ <project1>adefine.o 
@ C.Link <project1>project1.release 
*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'common/common.jam',
			'common/common.release.a',
			'common/print.cpp',
			'common/print.h',
			'common/print.o',
			'project1/adefine.cpp',
			'project1/adefine.o',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/project1.o',
			'project1/project1.release',
			'shared/adefine.h',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 17 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('common/print.h')

		local pattern3 = [[
*** found 17 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>project1.o 
@ C.Link <project1>project1.release 
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		os.sleep(1.0)
		os.touch('shared/adefine.h')

		local pattern4 = [[
*** found 17 target(s)...
*** updating 2 target(s)...
@ C.C++ <project1>adefine.o 
@ C.Link <project1>project1.release 
*** updated 2 target(s)...
]]
		TestPattern(pattern4, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)

	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


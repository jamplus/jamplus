function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'common/common.jam',
		'common/print.cpp',
		'common/print.h',
		'libA/libA.cpp',
		'libA/libA.jam',
		'project1/project1.cpp',
		'project1/project1.jam',
	}

	local originalDirs =
	{
		'common/',
		'libA/',
		'project1/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 23 target(s)...
*** updating 6 target(s)...
@ C.C++ <common>print.obj
print.cpp
@ C.Archive <common>common.lib
@ C.C++ <libA>libA.obj
libA.cpp
@ C.Archive <libA>libA.lib
@ C.C++ <project1>project1.obj
project1.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 6 target(s)...
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
			'libA/libA.cpp',
			'libA/libA.jam',
			'libA/libA.obj',
			'libA/libA.release.lib',
			'libA/vc.pdb',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/project1.obj',
			'project1/project1.release.exe',
			'project1/project1.release.exe.intermediate.manifest',
			'project1/project1.release.pdb',
			'project1/vc.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 23 target(s)...
]]
		TestPattern(pattern2, RunJam())
	else
		-- First build
		local pattern = [[
*** found 19 target(s)...
*** updating 6 target(s)...
@ C.C++ <common>print.o 
@ C.Archive <common>common.a 
ar: creating archive common/common.release.a
@ C.Ranlib <common>common.a 
@ C.C++ <libA>libA.o 
@ C.Archive <libA>libA.a 
ar: creating archive libA/libA.release.a
@ C.Ranlib <libA>libA.a 
@ C.C++ <project1>project1.o 
@ C.Link <project1>project1.release 
*** updated 6 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'test.lua',
			'common/common.jam',
			'common/common.release.a',
			'common/print.cpp',
			'common/print.h',
			'common/print.o',
			'libA/libA.cpp',
			'libA/libA.jam',
			'libA/libA.o',
			'libA/libA.release.a',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/project1.o',
			'project1/project1.release',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 19 target(s)...
]]
		TestPattern(pattern2, RunJam())
	end
	
	os.sleep(1.0)
	os.touch('common/print.h')

	if Platform == 'win32' then
		local pattern3 = [[
*** found 23 target(s)...
*** updating 6 target(s)...
@ C.C++ <common>print.obj
print.cpp
@ C.Archive <common>common.lib
@ C.C++ <libA>libA.obj
libA.cpp
@ C.Archive <libA>libA.lib
@ C.C++ <project1>project1.obj
project1.cpp
@ C.LinkWithManifest <project1>project1.release.exe
*** updated 6 target(s)...
]]
		TestPattern(pattern3, RunJam())
	else
		local pattern3 = [[
*** found 19 target(s)...
*** updating 4 target(s)...
@ C.C++ <libA>libA.o 
@ C.Archive <libA>libA.a 
@ C.Ranlib <libA>libA.a 
@ C.C++ <project1>project1.o 
@ C.Link <project1>project1.release 
*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	end

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


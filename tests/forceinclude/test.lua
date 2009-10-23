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

	-- First build
	local pattern = [[
*** found 17 target(s)...
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
*** found 17 target(s)...
]]
	TestPattern(pattern2, RunJam())
	
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	os.sleep(1.0)
	os.touch('common/print.h')

	local pattern3 = [[
*** found 17 target(s)...
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

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


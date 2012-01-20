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
*** found 29 target(s)...
*** updating 12 target(s)...
@ C.vc.C++ <win32!release:project1>project1.obj
!NEXT!@ C.vc.C++ <win32!release:common>print.obj
!NEXT!@ C.vc.Archive <win32!release:common>common.lib
!NEXT!@ C.vc.C++ <win32!release:libA>libA.obj
!NEXT!@ C.vc.Archive <win32!release:libA>libA.lib
!NEXT!@ C.vc.LinkWithManifest <win32!release:project1>project1.exe
!NEXT!*** updated 12 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'common/win32!release/common/common.release.lib',
			'common/win32!release/common/print.obj',
			'libA/libA.cpp',
			'libA/libA.jam',
			'libA/win32!release/libA/libA.obj',
			'libA/win32!release/libA/libA.release.lib',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/win32!release/project1/project1.obj',
			'project1/win32!release/project1/project1.release.exe',
			'project1/win32!release/project1/project1.release.exe.intermediate.manifest',
			'project1/win32!release/project1/project1.release.pdb',
		}

		local pass1Directories = {
			'common/',
			'libA/',
			'project1/',
			'common/win32!release/',
			'common/win32!release/common/',
			'libA/win32!release/',
			'libA/win32!release/libA/',
			'project1/win32!release/',
			'project1/win32!release/project1/',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 29 target(s)...
]]
		TestPattern(pattern2, RunJam())
	else
		-- First build
		local pattern = [[
*** found 19 target(s)...
*** updating 6 target(s)...
@ C.C++ <common>print.o 
@ C.Archive <common>common.a 
!NEXT!@ C.Ranlib <common>common.a 
@ C.C++ <libA>libA.o 
@ C.Archive <libA>libA.a 
!NEXT!@ C.Ranlib <libA>libA.a
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
*** found 29 target(s)...
*** updating 4 target(s)...
@ C.vc.C++ <win32!release:project1>project1.obj
!NEXT!@ C.vc.C++ <win32!release:libA>libA.obj
!NEXT!@ C.vc.Archive <win32!release:libA>libA.lib
!NEXT!@ C.vc.LinkWithManifest <win32!release:project1>project1.exe
!NEXT!*** updated 4 target(s)...
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


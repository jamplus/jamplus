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
*** found 31 target(s)...
*** updating 12 target(s)...
@ C.vc.C++ <win32!release:project1>project1.obj
!NEXT!@ C.vc.C++ <win32!release:common>print.obj
!NEXT!@ C.vc.Archive <win32!release:common>common.lib
!NEXT!@ C.vc.C++ <win32!release:libA>libA.obj
!NEXT!@ C.vc.Archive <win32!release:libA>libA.lib
!NEXT!@ C.vc.Link <win32!release:project1>project1.exe
!NEXT!*** updated 12 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'common/win32-release/common/common.release.lib',
			'common/win32-release/common/print.obj',
			'libA/libA.cpp',
			'libA/libA.jam',
			'libA/win32-release/libA/libA.obj',
			'libA/win32-release/libA/libA.release.lib',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/win32-release/project1/project1.obj',
			'project1/win32-release/project1/project1.release.exe',
			'?project1/win32-release/project1/project1.release.exe.intermediate.manifest',
			'project1/win32-release/project1/project1.release.pdb',
		}

		local pass1Directories = {
			'common/',
			'libA/',
			'project1/',
			'common/win32-release/',
			'common/win32-release/common/',
			'libA/win32-release/',
			'libA/win32-release/libA/',
			'project1/win32-release/',
			'project1/win32-release/project1/',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 31 target(s)...
]]
		TestPattern(pattern2, RunJam())
	else
		-- First build
		local pattern = [[
*** found 18 target(s)...
*** updating 9 target(s)...
@ C.gcc.C++ <macosx32!release:project1>project1.o 
@ C.gcc.C++ <macosx32!release:common>print.o 
@ C.gcc.Archive <macosx32!release:common>common.a 
!NEXT!@ C.gcc.Ranlib <macosx32!release:common>common.a 
@ C.gcc.C++ <macosx32!release:libA>libA.o 
@ C.gcc.Archive <macosx32!release:libA>libA.a 
!NEXT!@ C.gcc.Ranlib <macosx32!release:libA>libA.a
@ C.gcc.Link <macosx32!release:project1>project1
*** updated 9 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Dirs = {
			'common/',
			'libA/',
			'project1/',
			'common/macosx32-release/',
			'common/macosx32-release/common/',
			'libA/macosx32-release/',
			'libA/macosx32-release/libA/',
			'project1/macosx32-release/',
			'project1/macosx32-release/project1/',
		}

		local pass1Files =
		{
			'Jamfile.jam',
			'test.lua',
			'common/common.jam',
			'common/print.cpp',
			'common/print.h',
			'common/macosx32-release/common/common.release.a',
			'common/macosx32-release/common/print.o',
			'libA/libA.cpp',
			'libA/libA.jam',
			'libA/macosx32-release/libA/libA.o',
			'libA/macosx32-release/libA/libA.release.a',
			'project1/project1.cpp',
			'project1/project1.jam',
			'project1/macosx32-release/project1/project1.o',
			'project1/macosx32-release/project1/project1.release',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Dirs)

		local pattern2 = [[
*** found 18 target(s)...
]]
		TestPattern(pattern2, RunJam())
	end
	
	os.sleep(1.0)
	os.touch('common/print.h')

	if Platform == 'win32' then
		local pattern3 = [[
*** found 31 target(s)...
*** updating 4 target(s)...
@ C.vc.C++ <win32!release:project1>project1.obj
!NEXT!@ C.vc.C++ <win32!release:libA>libA.obj
!NEXT!@ C.vc.Archive <win32!release:libA>libA.lib
!NEXT!@ C.vc.Link <win32!release:project1>project1.exe
!NEXT!*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	else
		local pattern3 = [[
*** found 18 target(s)...
*** updating 4 target(s)...
@ C.gcc.C++ <macosx32!release:project1>project1.o 
@ C.gcc.C++ <macosx32!release:libA>libA.o 
@ C.gcc.Archive <macosx32!release:libA>libA.a 
!NEXT!@ C.gcc.Ranlib <macosx32!release:libA>libA.a
@ C.gcc.Link <macosx32!release:project1>project1
*** updated 4 target(s)...
]]
		TestPattern(pattern3, RunJam())
	end

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	do
		local pattern
		local pass1Dirs
		local pass1Files
		if Platform == 'win32' then
			pattern = [[
Pass 1
*** found 12 target(s)...
*** updating 7 target(s)...
@ WriteFile <win32!release:test>foo.cpp
*** updated 4 target(s)...
Pass 2
*** found 30 target(s)...
*** updating 12 target(s)...
@ WriteFile <win32!release:test>foo.h
@ WriteFile <win32!release:test>main.cpp
@ C.vc.C++ <win32!release:test>main.obj
!NEXT!@ C.vc.LinkWithManifest <win32!release:test>test.exe
!NEXT!*** updated 5 target(s)...
Pass 3
*** found 41 target(s)...
*** updating 12 target(s)...
]]

			pass1Dirs = {
				'win32!release/',
				'win32!release/test/',
			}

			pass1Files =
			{
				'foo.h',
				'Jamfile.jam',
				'win32!release/test/foo.cpp',
				'win32!release/test/foo.obj',
				'win32!release/test/main.cpp',
				'win32!release/test/main.obj',
				'win32!release/test/test.release.exe',
				'win32!release/test/test.release.exe.intermediate.manifest',
				'win32!release/test/test.release.pdb',
			}

		else
			pattern = [[
Pass 1 
*** found 9 target(s)...
*** updating 5 target(s)...
@ WriteFile <test>foo.cpp 
@ C.C++ <test>foo.o 
*** updated 2 target(s)...
Pass 2 
*** found 19 target(s)...
*** updating 10 target(s)...
@ WriteFile <test>foo.h 
@ WriteFile <test>main.cpp 
@ C.C++ <test>main.o 
@ C.Link <test>test.release 
*** updated 5 target(s)...
Pass 3 
*** found 28 target(s)...
]]

			pass1Files = {
				'foo.cpp',
				'foo.h',
				'foo.o',
				'Jamfile.jam',
				'main.cpp',
				'main.o',
				'test.lua',
				'test.release',
			}
		end

		TestPattern(pattern, RunJam())

		TestDirectories(pass1Dirs)
		TestFiles(pass1Files)
	end

	---------------------------------------------------------------------------
	local cleanpattern_allpasses = [[
Pass 1
*** found 4 target(s)...
*** updating 1 target(s)...
@ Clean <win32!release>clean:test
*** updated 1 target(s)...
Pass 2
*** found 6 target(s)...
*** updating 1 target(s)...
@ Clean <win32!release>clean:test
*** updated 1 target(s)...
Pass 3
*** found 8 target(s)...
*** updating 1 target(s)...
]]
	TestPattern(cleanpattern_allpasses, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 2
*** found 1 target(s)...
Pass 3
*** found 2 target(s)...
]]
	TestPattern(pattern2, RunJam{ '-sPASS_NUM=2' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_pass2on = [[
Pass 2
*** found 2 target(s)...
Pass 3
*** found 3 target(s)...
]]
	TestPattern(cleanpattern_pass2on, RunJam{ '-sPASS_NUM=2', 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end


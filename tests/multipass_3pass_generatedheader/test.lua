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
		local pass1Files
		if Platform == 'win32' then
			pattern = [[
Pass 1
*** found 9 target(s)...
*** updating 5 target(s)...
@ WriteFile <test>foo.cpp
*** updated 2 target(s)...
Pass 2
*** found 25 target(s)...
*** updating 10 target(s)...
@ WriteFile <test>foo.h
@ WriteFile <test>main.cpp
@ C.C++ <test>main.obj
main.cpp
foo.cpp
Generating Code...
@ C.LinkWithManifest <test>test.release.exe
*** updated 5 target(s)...
Pass 3
*** found 33 target(s)...
*** updating 10 target(s)...
]]

			pass1Files =
			{
				'Jamfile.jam',
				'foo.cpp',
				'foo.h',
				'foo.obj',
				'main.cpp',
				'main.obj',
				'test.release.exe',
				'test.release.exe.intermediate.manifest',
				'test.release.pdb',
				'vc.pdb',
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

		TestDirectories(originalDirs)
		TestFiles(pass1Files)
	end

	---------------------------------------------------------------------------
	local cleanpattern_allpasses = [[
Pass 1
*** found 3 target(s)...
*** updating 1 target(s)...
@ Clean clean:test
*** updated 1 target(s)...
Pass 2
*** found 4 target(s)...
*** updating 1 target(s)...
@ Clean clean:test
*** updated 1 target(s)...
Pass 3
*** found 5 target(s)...
*** updating 2 target(s)...
*** updated 1 target(s)...
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
*** updating 1 target(s)...
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_pass2on, RunJam{ '-sPASS_NUM=2', 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end


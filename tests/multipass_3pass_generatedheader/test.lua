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
*** executing pass 2...
Pass 2
*** found 21 target(s)...
*** updating 5 target(s)...
@ WriteFile <win32!release:test>foo.h
@ WriteFile <win32!release:test>main.cpp
@ C.vc.C++ <win32!release:test>main.obj
!NEXT!@ C.vc.Link <win32!release:test>test.exe
!NEXT!*** updated 5 target(s)...
*** executing pass 3...
Pass 3
*** found 12 target(s)...
]]

			pass1Dirs = {
				'win32-release/',
				'win32-release/test/',
			}

			pass1Files =
			{
				'foo.h',
				'Jamfile.jam',
				'win32-release/test/foo.cpp',
				'win32-release/test/foo.obj',
				'win32-release/test/main.cpp',
				'win32-release/test/main.obj',
				'win32-release/test/test.release.exe',
				'?win32-release/test/test.release.exe.intermediate.manifest',
				'win32-release/test/test.release.pdb',
			}

		else
			pattern = [[
Pass 1 
*** found 10 target(s)...
*** updating 6 target(s)...
@ WriteFile <$(PLATFORM_CONFIG):test>foo.cpp 
@ C.$(COMPILER).C++ <$(PLATFORM_CONFIG):test>foo.o 
*** updated 3 target(s)...
Pass 2 
*** found 11 target(s)...
*** updating 4 target(s)...
@ WriteFile <$(PLATFORM_CONFIG):test>foo.h 
@ WriteFile <$(PLATFORM_CONFIG):test>main.cpp 
@ C.$(COMPILER).C++ <$(PLATFORM_CONFIG):test>main.o 
@ C.$(COMPILER).Link <$(PLATFORM_CONFIG):test>test
*** updated 4 target(s)...
Pass 3 
*** found 8 target(s)...
]]

			pass1Dirs = {
				'$(PLATFORM_CONFIG)/',
				'$(PLATFORM_CONFIG)/test/',
			}

			pass1Files = {
				'foo.h',
				'Jamfile.jam',
				'test.lua',
				'$(PLATFORM_CONFIG)/test/foo.cpp',
				'$(PLATFORM_CONFIG)/test/foo.o',
				'$(PLATFORM_CONFIG)/test/main.cpp',
				'$(PLATFORM_CONFIG)/test/main.o',
				'$(PLATFORM_CONFIG)/test/test.release',
			}
		end

		TestPattern(pattern, RunJam())

		TestDirectories(pass1Dirs)
		TestFiles(pass1Files)
	end

	---------------------------------------------------------------------------
	local cleanpattern_allpasses
	if Platform == 'win32' then
		cleanpattern_allpasses = [[
Pass 1
*** found 4 target(s)...
*** updating 1 target(s)...
@ Clean <win32!release>clean:test
*** updated 1 target(s)...
*** executing pass 2...
Pass 2
*** found 2 target(s)...
@ Clean <win32!release>clean:test
*** updated 1 target(s)...
*** executing pass 3...
Pass 3
*** found 2 target(s)...
]]
	else
		cleanpattern_allpasses = [[
Pass 1
*** found 4 target(s)...
*** updating 1 target(s)...
@ Clean <$(PLATFORM_CONFIG)>clean:test
*** updated 1 target(s)...
Pass 2
*** found 2 target(s)...
@ Clean <$(PLATFORM_CONFIG)>clean:test
*** updated 1 target(s)...
Pass 3
*** found 2 target(s)...
]]
	end
	TestPattern(cleanpattern_allpasses, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 2
*** found 1 target(s)...
*** executing pass 2...
Pass 3
*** found 1 target(s)...
]]
	TestPattern(pattern2, RunJam{ '-sPASS_NUM=2' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_pass2on = [[
Pass 2
*** found 2 target(s)...
Pass 3
*** found 1 target(s)...
]]
	TestPattern(cleanpattern_pass2on, RunJam{ '-sPASS_NUM=2', 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end


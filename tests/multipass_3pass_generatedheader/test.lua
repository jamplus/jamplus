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
*** found 10 target(s)...
*** updating 6 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>foo.cpp
*** updated 3 target(s)...
*** executing pass 2...
Pass 2
*** found 19 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>foo.h
@ WriteFile <$(TOOLCHAIN_GRIST):test>main.cpp
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):test>main.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test.exe
!NEXT!*** updated 5 target(s)...
*** executing pass 3...
Pass 3
*** found 10 target(s)...
]]

			pass1Dirs = {
				'$(TOOLCHAIN_PATH)/',
				'$(TOOLCHAIN_PATH)/test/',
			}

			pass1Files =
			{
				'foo.h',
				'Jamfile.jam',
				'$(TOOLCHAIN_PATH)/test/foo.cpp',
				'$(TOOLCHAIN_PATH)/test/foo.obj',
				'$(TOOLCHAIN_PATH)/test/main.cpp',
				'$(TOOLCHAIN_PATH)/test/main.obj',
				'$(TOOLCHAIN_PATH)/test/test.release.exe',
				'?$(TOOLCHAIN_PATH)/test/test.release.exe.intermediate.manifest',
				'$(TOOLCHAIN_PATH)/test/test.release.pdb',
			}

		else
			pattern = [[
Pass 1
*** found 10 target(s)...
*** updating 6 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>foo.cpp
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):test>foo.o
*** updated 3 target(s)...
Pass 2
*** found 11 target(s)...
*** updating 5 target(s)...
@ WriteFile <$(TOOLCHAIN_GRIST):test>foo.h
@ WriteFile <$(TOOLCHAIN_GRIST):test>main.cpp
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):test>main.o
@ $(C_LINK) <$(TOOLCHAIN_GRIST):test>test
*** updated 5 target(s)...
Pass 3
*** found 11 target(s)...
]]

			pass1Dirs = {
				'$(TOOLCHAIN_PATH)/',
				'$(TOOLCHAIN_PATH)/test/',
			}

			pass1Files = {
				'foo.h',
				'Jamfile.jam',
				'test.lua',
				'$(TOOLCHAIN_PATH)/test/foo.cpp',
				'$(TOOLCHAIN_PATH)/test/foo.o',
				'$(TOOLCHAIN_PATH)/test/main.cpp',
				'$(TOOLCHAIN_PATH)/test/main.o',
				'$(TOOLCHAIN_PATH)/test/test.release',
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
*** updating 2 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:test
@ Clean clean
*** updated 2 target(s)...
*** executing pass 2...
Pass 2
*** found 2 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:test
*** updated 2 target(s)...
*** executing pass 3...
Pass 3
*** found 2 target(s)...
*** updating 1 target(s)...
]]
	else
		cleanpattern_allpasses = [[
Pass 1
*** found 4 target(s)...
*** updating 2 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:test
*** updated 2 target(s)...
*** executing pass 2...
Pass 2
*** found 2 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:test
*** updated 2 target(s)...
*** executing pass 3...
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


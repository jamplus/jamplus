function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'README',
		'circularA.h',
		'circularB.h',
		'sourceA.c',
		'sourceB.c',
		'sourceB.h',
	}

	local originalDirs =
	{
	}

	os.remove('.jamcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 12 target(s)...
*** updating 5 target(s)...
Writing generated.h
@ SleepThenTouch <$(TOOLCHAIN_GRIST):foo>generated.h
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.lib
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam{'foo'})

		local pass1Directories = {
			'$(TOOLCHAIN_PATH)/foo/',
		}

		local pass1Files =
		{
			'?.jamcache',
			'Jamfile.jam',
			'README',
			'circularA.h',
			'circularB.h',
			'generated.h',
			'sourceA.c',
			'sourceB.c',
			'sourceB.h',
			'$(TOOLCHAIN_PATH)/foo/foo.lib',
			'$(TOOLCHAIN_PATH)/foo/sourceA.obj',
			'$(TOOLCHAIN_PATH)/foo/sourceB.obj',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })
	
		osprocess.sleep(1.0)
		ospath.touch('generated.h')

		if useChecksums then
			pattern2 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
*** updated 3 target(s)...
]]
			TestPattern(pattern2, RunJam{ 'foo' })

			osprocess.sleep(1.0)
			ospath.write_file('generated.h', '//')
		end

		local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.lib
!NEXT!*** updated 3 target(s)...
]]
		TestPattern(pattern3, RunJam{ 'foo' })
	
	else
		-- First build
		local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
Writing generated.h
@ SleepThenTouch <$(TOOLCHAIN_GRIST):foo>generated.h 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceB.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.a 
!NEXT!*** updated 5 target(s)...
]]

		TestPattern(pattern, RunJam{ 'foo' })

		local pass1Directories = {
			'$(TOOLCHAIN_PATH)/foo/',
		}

		local pass1Files =
		{
			'?.jamcache',
			'Jamfile.jam',
			'README',
			'circularA.h',
			'circularB.h',
			'generated.h',
			'sourceA.c',
			'sourceB.c',
			'sourceB.h',
			'$(TOOLCHAIN_PATH)/foo/foo.a',
			'$(TOOLCHAIN_PATH)/foo/sourceA.o',
			'$(TOOLCHAIN_PATH)/foo/sourceB.o',
		}

		TestFiles(pass1Files)
		TestDirectories(pass1Directories)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })

		osprocess.sleep(1.0)
		ospath.touch('generated.h')

		if useChecksums then
		local pattern2 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
*** updated 3 target(s)...
]]
			TestPattern(pattern2, RunJam{ 'foo' })

			osprocess.sleep(1.0)
			ospath.write_file('generated.h', '//')

			local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceB.o 
!NEXT!*** updated 3 target(s)...
]]
			TestPattern(pattern3, RunJam{ 'foo' })

		local pattern2 = [[
*** found 11 target(s)...
]]
			TestPattern(pattern2, RunJam{ 'foo' })

			osprocess.sleep(1.0)
			ospath.write_file('generated.h', 'int GENERATED_H;')
		end

		local pattern4 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceB.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.a 
!NEXT!*** updated 3 target(s)...
]]
		TestPattern(pattern4, RunJam{ 'foo' })

	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

TestChecksum = Test

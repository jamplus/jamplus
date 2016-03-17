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

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 12 target(s)...
*** updating 4 target(s)...
Writing generated.h
@ SleepThenTouch <$(TOOLCHAIN_GRIST):foo>generated.h
!NEXT!@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.lib
!NEXT!*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{'foo'})

		local pass1Files =
		{
			'?.jamcache',
			'Jamfile.jam',
			'README',
			'circularA.h',
			'circularB.h',
			'foo.lib',
			'generated.h',
			'sourceA.c',
			'sourceA.obj',
			'sourceB.c',
			'sourceB.h',
			'sourceB.obj',
			'vc.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })
	
		osprocess.sleep(1.0)
		ospath.touch('generated.h')

		if useChecksums then
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
*** updating 4 target(s)...
Writing generated.h
@ SleepThenTouch <$(TOOLCHAIN_GRIST):foo>generated.h 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceB.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):foo>foo.a 
!NEXT!*** updated 4 target(s)...
]]

		TestPattern(pattern, RunJam{ 'foo' })

		local pass1Files =
		{
			'?.jamcache',
			'Jamfile.jam',
			'README',
			'circularA.h',
			'circularB.h',
			'foo.a',
			'generated.h',
			'sourceA.c',
			'sourceA.o',
			'sourceB.c',
			'sourceB.h',
			'sourceB.o',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 11 target(s)...
]]
		TestPattern(pattern2, RunJam{ 'foo' })

		osprocess.sleep(1.0)
		ospath.touch('generated.h')

		if useChecksums then
			TestPattern(pattern2, RunJam{ 'foo' })

			osprocess.sleep(1.0)
			ospath.write_file('generated.h', '//')

			local pattern3 = [[
*** found 11 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceA.o 
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):foo>sourceB.o 
!NEXT!*** updated 2 target(s)...
]]
			TestPattern(pattern3, RunJam{ 'foo' })

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

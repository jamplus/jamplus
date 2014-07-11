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

	io.writeall('Care.cpp', '// Care.cpp')
	io.writeall('Care.h', '// Care.h')
	io.writeall('NoCare.cpp', '// NoCare.cpp')
	
	---------------------------------------------------------------------------
	local pattern = [[
Pass 1
*** found 1 target(s)...
Pass 2
*** found 7 target(s)...
*** updating 2 target(s)...
@ CopyAction NoCare.o
!NEXT!@ CopyAction Care.o
!NEXT!*** updated 2 target(s)...
Pass 3
*** found 3 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Care.cpp',
		'Care.h',
		'Care.o',
		'Jamfile.jam',
		'NoCare.cpp',
		'NoCare.o',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local cleanpattern_allpasses = [[
Pass 1
*** found 2 target(s)...
Pass 2
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
Pass 3
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_allpasses, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	io.writeall('Care.cpp', '// Care.cpp')
	io.writeall('Care.h', '// Care.h')
	io.writeall('NoCare.cpp', '// NoCare.cpp')
	
	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 1
*** found 1 target(s)...
Pass 2
*** found 7 target(s)...
*** updating 2 target(s)...
@ CopyAction NoCare.o
!NEXT!@ CopyAction Care.o
!NEXT!*** updated 2 target(s)...
]]
	TestPattern(pattern2, RunJam{ '-s', 'IGNORE_PASS_3=true' })
	TestFiles(pass1Files)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_test2 = [[
Pass 1
*** found 2 target(s)...
Pass 2
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_test2, RunJam{ '-sIGNORE_PASS_3=2', 'clean' })
	
	local test2Files =
	{
		'Care.cpp',
		'Care.h',
		'Jamfile.jam',
		'NoCare.cpp',
	}
	
	TestFiles(test2Files)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
Pass 2
*** found 7 target(s)...
*** updating 2 target(s)...
@ CopyAction NoCare.o
!NEXT!@ CopyAction Care.o
!NEXT!*** updated 2 target(s)...
Pass 3
*** found 3 target(s)...
]]
	TestPattern(pattern3, RunJam{ '-s', 'PASS_NUM=2' })
	TestFiles(pass1Files)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_test3 = [[
Pass 2
*** found 2 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
Pass 3
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_test3, RunJam{ '-sPASS_NUM=2', 'clean' })
	
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

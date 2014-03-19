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

	-- Write them out in this order so Foo.h has a greater timestamp than Foo.cpp.
	io.writeall('Foo.cpp', '// Foo.cpp')
	io.writeall('Foo.h', '// Foo.h')
	
	---------------------------------------------------------------------------
	local pattern = [[
Pass 1
*** found 1 target(s)...
*** executing pass 2...
Pass 2
*** found 1 target(s)...
*** executing pass 3...
Pass 3
*** found 4 target(s)...
*** updating 1 target(s)...
@ CopyAction Foo.o
!NEXT!*** updated 1 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'Foo.cpp',
		'Foo.h',
		'Foo.o',
		'Jamfile.jam',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local cleanpattern_allpasses = [[
Pass 1
*** found 2 target(s)...
Pass 2
*** found 1 target(s)...
Pass 3
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_allpasses, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	-- Write them out in this order so Foo.h has a greater timestamp than Foo.cpp.
	io.writeall('Foo.cpp', '// Foo.cpp')
	io.writeall('Foo.h', '// Foo.h')
	
	---------------------------------------------------------------------------
	local pattern2 = [[
Pass 2
*** found 1 target(s)...
*** executing pass 2...
Pass 3
*** found 4 target(s)...
*** updating 1 target(s)...
@ CopyAction Foo.o
!NEXT!*** updated 1 target(s)...
]]
	TestPattern(pattern2, RunJam{ '-sPASS_NUM=2' })
	TestFiles(pass1Files)
	TestDirectories(originalDirs)
	
	---------------------------------------------------------------------------
	local cleanpattern_pass2on = [[
Pass 2
*** found 2 target(s)...
*** executing pass 2...
Pass 3
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern_pass2on, RunJam{ '-sPASS_NUM=2', 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

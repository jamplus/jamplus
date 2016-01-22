function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'Pass2.jam',
		'file.txt',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 3 target(s)...
*** updating 1 target(s)...
@ Copy file.dat
!NEXT!*** failed Copy file.dat ...
*** failed updating 1 target(s)...
*** executing pass 2...
*** found 3 target(s)...
*** updating 2 target(s)...
*** skipped test.zip for lack of file.dat...
*** failed updating 1 target(s)...
*** skipped 1 target(s)...
]]

	TestPattern(pattern, RunJam{ '-sFORCE_ERROR=1' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 3 target(s)...
*** updating 1 target(s)...
@ Copy file.dat
!NEXT!*** updated 1 target(s)...
*** executing pass 2...
*** found 3 target(s)...
*** updating 1 target(s)...
@ Anyway test.zip
!NEXT!*** updated 1 target(s)...
]]

	TestPattern(pattern2, RunJam{})

	local pass1Files =
	{
		'Jamfile.jam',
		'Pass2.jam',
		'file.dat',
		'file.txt',
		'test.lua',
		'test.zip',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern3 = [[
*** found 3 target(s)...
*** executing pass 2...
*** found 4 target(s)...
]]

	TestPattern(pattern3, RunJam{})
	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local cleanpattern = [[
*** found 2 target(s)...
*** executing pass 2...
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	TestPattern(cleanpattern, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end





-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function Test()
	-- Test for a clean directory.
	local originalFiles = {
		'Jamfile.jam',
		'Pass2.jam',
		'file.txt',
	}

	local originalDirs = {
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pass1Directories = {
		'?.build/',
	}

	local pattern = [[
*** found 3 target(s)...
*** updating 1 target(s)...
@ Copy file.dat
!NEXT!*** failed Copy file.dat ...
*** failed updating 1 target(s)...
*** executing pass 2...
*** found 3 target(s)...
*** updating 2 target(s)...
*** skipped test.zip for lack of file.dat...
*** failed updating 1 target(s)...
*** skipped 1 target(s)...
]]

	TestPattern(pattern, RunJam{ '-sFORCE_ERROR=1' })
	TestDirectories(pass1Directories)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 3 target(s)...
*** updating 1 target(s)...
@ Copy file.dat
!NEXT!*** updated 1 target(s)...
*** executing pass 2...
*** found 3 target(s)...
*** updating 1 target(s)...
@ Anyway test.zip
!NEXT!*** updated 1 target(s)...
]]

	TestPattern(pattern2, RunJam{})

	local pass1Files = {
		'Jamfile.jam',
		'Pass2.jam',
		'file.dat',
		'file.txt',
		'test.lua',
		'test.zip',
	}

	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern3 = [[
*** found 3 target(s)...
*** executing pass 2...
*** found 4 target(s)...
]]

	TestPattern(pattern3, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local cleanpattern
	if useChecksums then
		cleanpattern = [[
*** found 2 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
*** executing pass 2...
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	else
		cleanpattern = [[
*** found 2 target(s)...
*** executing pass 2...
*** found 1 target(s)...
*** updating 1 target(s)...
@ Clean clean
*** updated 1 target(s)...
]]
	end
	TestPattern(cleanpattern, RunJam{ 'clean' })
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

TestChecksum = Test

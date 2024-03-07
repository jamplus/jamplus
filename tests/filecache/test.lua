function Test()
	local originalFiles =
	{
		"file1.tga",
		"file2.tga",
		"Jamfile.jam",
	}

	local originalDirs =
	{
	}

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	local pattern = [[
*** found 5 target(s)...
*** updating 2 target(s)...
@ ConvertImageHelper file1.image
!NEXT!Caching file1.image
@ ConvertImageHelper file2.image
!NEXT!Caching file2.image
*** updated 2 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.image',
		'file1.tga',
		'file2.image',
		'file2.tga',
		'cache/68a/68a3ba7c0b59a09ef08a142938e06333.blob',
		'cache/703/7030d7ab84c047dcb88c7ef237ec747f-68a3ba7c0b59a09ef08a142938e06333.link',
		'cache/ef0/ef04c3d244dfe6f6847848cab47bc08b-f9cf672fdacd1a0612bb39eb173967cf.link',
		'cache/f9c/f9cf672fdacd1a0612bb39eb173967cf.blob',
	}

	local newDirectories =
	{
		'cache/',
		'cache/68a/',
		'cache/703/',
		'cache/ef0/',
		'cache/f9c/',
	}

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean' }

	local pass2Files =
	{
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.tga',
		'file2.tga',
		'cache/68a/68a3ba7c0b59a09ef08a142938e06333.blob',
		'cache/703/7030d7ab84c047dcb88c7ef237ec747f-68a3ba7c0b59a09ef08a142938e06333.link',
		'cache/ef0/ef04c3d244dfe6f6847848cab47bc08b-f9cf672fdacd1a0612bb39eb173967cf.link',
		'cache/f9c/f9cf672fdacd1a0612bb39eb173967cf.blob',
	}

	TestFiles(pass2Files)
	TestDirectories(newDirectories)

	local pattern2 = [[
*** found 5 target(s)...
*** updating 2 target(s)...
Using cached file1.image
Using cached file2.image
*** updated 2 target(s)...
]]
	TestPattern(pattern2, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	osprocess.sleep(1.0)
	ospath.touch('file1.tga')

	local pattern3 = [[
*** found 5 target(s)...
*** updating 1 target(s)...
file1.image is already the proper cached target.
*** updated 1 target(s)...
]]
	TestPattern(pattern3, RunJam())

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function TestChecksum()
	local originalFiles = {
		"file1.tga",
		"file2.tga",
		"Jamfile.jam",
	}

	local originalDirs = {
	}

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')
	ospath.write_file('file1.tga', '////abcd\n')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	local pattern = [[
*** found 5 target(s)...
*** updating 2 target(s)...
@ ConvertImageHelper file1.image
!NEXT!Caching file1.image
@ ConvertImageHelper file2.image
!NEXT!Caching file2.image
*** updated 2 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.image',
		'file1.tga',
		'file2.image',
		'file2.tga',
		'cache/68a/68a3ba7c0b59a09ef08a142938e06333.blob',
		'cache/703/7030d7ab84c047dcb88c7ef237ec747f-68a3ba7c0b59a09ef08a142938e06333.link',
		'cache/ef0/ef04c3d244dfe6f6847848cab47bc08b-f9cf672fdacd1a0612bb39eb173967cf.link',
		'cache/f9c/f9cf672fdacd1a0612bb39eb173967cf.blob',
	}

	local pass1Directories = {
		'cache/',
		'cache/68a/',
		'cache/703/',
		'cache/ef0/',
		'cache/f9c/',
	}

	TestFiles(pass1Files)
	TestDirectories(pass1Directories)

	RunJam{ 'clean' }

	local pass2Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.tga',
		'file2.tga',
		'cache/68a/68a3ba7c0b59a09ef08a142938e06333.blob',
		'cache/703/7030d7ab84c047dcb88c7ef237ec747f-68a3ba7c0b59a09ef08a142938e06333.link',
		'cache/ef0/ef04c3d244dfe6f6847848cab47bc08b-f9cf672fdacd1a0612bb39eb173967cf.link',
		'cache/f9c/f9cf672fdacd1a0612bb39eb173967cf.blob',
	}

	TestFiles(pass2Files)
	TestDirectories(pass1Directories)

	local pattern2 = [[
*** found 5 target(s)...
*** updating 2 target(s)...
Using cached file1.image
Using cached file2.image
*** updated 2 target(s)...
]]
	TestPattern(pattern2, RunJam())

	TestFiles(pass1Files)
	TestDirectories(pass1Directories)

	osprocess.sleep(1.0)
	ospath.touch('file1.tga')

	local pattern3 = [[
*** found 5 target(s)...
*** updating 1 target(s)...
*** updated 0 target(s)...
]]
	TestPattern(pattern3, RunJam())

	osprocess.sleep(1.0)
	ospath.write_file('file1.tga', '////abcde\n')

	local pattern4 = [[
*** found 5 target(s)...
*** updating 1 target(s)...
@ ConvertImageHelper file1.image
!NEXT!Caching file1.image
*** updated 1 target(s)...
]]

	TestPattern(pattern4, RunJam())

	local pass3Directories = {
		'cache/',
		'cache/68a/',
		'cache/703/',
		'cache/718/',
		'cache/910/',
		'cache/ef0/',
		'cache/f9c/',
	}

	local pass3Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.image',
		'file1.tga',
		'file2.image',
		'file2.tga',
		'cache/68a/68a3ba7c0b59a09ef08a142938e06333.blob',
		'cache/703/7030d7ab84c047dcb88c7ef237ec747f-68a3ba7c0b59a09ef08a142938e06333.link',
		'cache/718/718dbd8f4e4ca8964409bf8e64820397.blob',
		'cache/910/9101634ed11e9c897e9b8630955e0b5d-718dbd8f4e4ca8964409bf8e64820397.link',
		'cache/ef0/ef04c3d244dfe6f6847848cab47bc08b-f9cf672fdacd1a0612bb39eb173967cf.link',
		'cache/f9c/f9cf672fdacd1a0612bb39eb173967cf.blob',
	}

	TestFiles(pass3Files)
	TestDirectories(pass3Directories)

	local pattern5 = [[
*** found 5 target(s)...
]]

	TestPattern(pattern5, RunJam())

	osprocess.sleep(1.0)
	ospath.write_file('file1.tga', '////abcd\n')

	local pattern6 = [[
*** found 5 target(s)...
*** updating 1 target(s)...
Using cached file1.image
*** updated 1 target(s)...
]]

	TestPattern(pattern6, RunJam())

	TestFiles(pass3Files)
	TestDirectories(pass3Directories)

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')

	RunJam{ 'clean' }

	ospath.remove('cache/')

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


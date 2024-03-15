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
		'cache/336/3363e03829148af09ea0590b7cbaa368.blob',
		'cache/7f7/7f74ec37f27e8cb8dc47c084abd73070-3363e03829148af09ea0590b7cbaa368.link',
		'cache/8bc/8bc07bb4ca487884f6e6df44d2c304ef-cf673917eb39bb12061acdda2f67cff9.link',
		'cache/cf6/cf673917eb39bb12061acdda2f67cff9.blob',
	}

	local newDirectories =
	{
		'cache/',
		'cache/336/',
		'cache/7f7/',
		'cache/8bc/',
		'cache/cf6/',
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
		'cache/336/3363e03829148af09ea0590b7cbaa368.blob',
		'cache/7f7/7f74ec37f27e8cb8dc47c084abd73070-3363e03829148af09ea0590b7cbaa368.link',
		'cache/8bc/8bc07bb4ca487884f6e6df44d2c304ef-cf673917eb39bb12061acdda2f67cff9.link',
		'cache/cf6/cf673917eb39bb12061acdda2f67cff9.blob',
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
		'cache/336/3363e03829148af09ea0590b7cbaa368.blob',
		'cache/7f7/7f74ec37f27e8cb8dc47c084abd73070-3363e03829148af09ea0590b7cbaa368.link',
		'cache/8bc/8bc07bb4ca487884f6e6df44d2c304ef-cf673917eb39bb12061acdda2f67cff9.link',
		'cache/cf6/cf673917eb39bb12061acdda2f67cff9.blob',
	}

	local pass1Directories = {
		'cache/',
		'cache/336/',
		'cache/7f7/',
		'cache/8bc/',
		'cache/cf6/',
	}

	TestFiles(pass1Files)
	TestDirectories(pass1Directories)

	RunJam{ 'clean' }

	local pass2Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.tga',
		'file2.tga',
		'cache/336/3363e03829148af09ea0590b7cbaa368.blob',
		'cache/7f7/7f74ec37f27e8cb8dc47c084abd73070-3363e03829148af09ea0590b7cbaa368.link',
		'cache/8bc/8bc07bb4ca487884f6e6df44d2c304ef-cf673917eb39bb12061acdda2f67cff9.link',
		'cache/cf6/cf673917eb39bb12061acdda2f67cff9.blob',
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
		'cache/336/',
		'cache/5d0/',
		'cache/7f7/',
		'cache/8bc/',
		'cache/970/',
		'cache/cf6/',
	}

	local pass3Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.image',
		'file1.tga',
		'file2.image',
		'file2.tga',
		'cache/336/3363e03829148af09ea0590b7cbaa368.blob',
		'cache/5d0/5d0b5e9530869b7e899c1ed14e630191-970382648ebf094496a84c4e8fbd8d71.link',
		'cache/7f7/7f74ec37f27e8cb8dc47c084abd73070-3363e03829148af09ea0590b7cbaa368.link',
		'cache/8bc/8bc07bb4ca487884f6e6df44d2c304ef-cf673917eb39bb12061acdda2f67cff9.link',
		'cache/970/970382648ebf094496a84c4e8fbd8d71.blob',
		'cache/cf6/cf673917eb39bb12061acdda2f67cff9.blob',
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


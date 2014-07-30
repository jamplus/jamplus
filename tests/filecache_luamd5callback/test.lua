function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'file1.png',
		'file2.png',
		'file3.png',
		'file4.zip',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
	}

	local originalDirs =
	{
	}

	ospath.remove('cache/')
	ospath.remove('.depcache')
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	-- First build
	local pattern = [[
*** found 11 target(s)...
*** updating 5 target(s)...
md5png: Calculating file1.png...
@ ConvertImageHelper file1.image
!NEXT!Caching file1.image
@ ConvertImageHelper file2.image
!NEXT!@ ConvertImageHelper file3.image
md5zip: Calculating file4.zip...
!NEXT!@ ConvertImageHelper file4.image
!NEXT!Caching file4.image
@ ConvertImageHelper file5.image
!NEXT!*** updated 5 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'.depcache',
		'Jamfile.jam',
		'file1.image',
		'file1.png',
		'file2.image',
		'file2.png',
		'file3.image',
		'file3.png',
		'file4.image',
		'file4.zip',
		'file5.image',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
		'test.lua',
		'cache/0bc/0bc7b9e962cc568e2cfce97548a5dda3.blob',
		'cache/152/152d400ae1cca7812f209752c68c2431-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/174/1741db7ac6770248495984b8ea8fa8eb-7daedef0992cb6be9a30e0cc36742148.link',
		'cache/368/368d4220e4b0e4ebba8569b61095ed2b-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/3a2/3a21947a7ac8198e306adeb15630c62f-7daedef0992cb6be9a30e0cc36742148.link',
		'cache/61c/61c764b9d60f08674009c5830d1686c9-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/7da/7daedef0992cb6be9a30e0cc36742148.blob',
	}

	local newDirectories =
	{
		'cache/',
		'cache/0bc/',
		'cache/152/',
		'cache/174/',
		'cache/368/',
		'cache/3a2/',
		'cache/61c/',
		'cache/7da/',
	}

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean' }

	local pass2Files =
	{
		'.depcache',
		'Jamfile.jam',
		'file1.png',
		'file2.png',
		'file3.png',
		'file4.zip',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
		'cache/0bc/0bc7b9e962cc568e2cfce97548a5dda3.blob',
		'cache/152/152d400ae1cca7812f209752c68c2431-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/174/1741db7ac6770248495984b8ea8fa8eb-7daedef0992cb6be9a30e0cc36742148.link',
		'cache/368/368d4220e4b0e4ebba8569b61095ed2b-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/3a2/3a21947a7ac8198e306adeb15630c62f-7daedef0992cb6be9a30e0cc36742148.link',
		'cache/61c/61c764b9d60f08674009c5830d1686c9-0bc7b9e962cc568e2cfce97548a5dda3.link',
		'cache/7da/7daedef0992cb6be9a30e0cc36742148.blob',
	}

	TestFiles(pass2Files)
	TestDirectories(newDirectories)

	local pattern2 = [[
*** found 11 target(s)...
*** updating 5 target(s)...
Using cached file1.image
Using cached file2.image
Using cached file3.image
Using cached file4.image
Using cached file5.image
*** updated 5 target(s)...
]]
	TestPattern(pattern2, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	osprocess.sleep(1.0)
	ospath.touch('file3.png')

	local pattern3 = [[
*** found 11 target(s)...
*** updating 1 target(s)...
file3.image is already the proper cached target.
*** updated 1 target(s)...
]]
	TestPattern(pattern3, RunJam())

	ospath.remove('cache/')
	ospath.remove('.depcache')
	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


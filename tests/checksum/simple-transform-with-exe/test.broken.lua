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
		'cache/c51/c518ad13579d451d4c0b2b69178a5095-ead1e43de665f2a38d9f939274cf079c.link',
		'cache/e80/e803da4ab5571e583e755f963d4b37fd-faa1fdb2548701eb77fc77cfa18d8e47.link',
		'cache/ead/ead1e43de665f2a38d9f939274cf079c.blob',
		'cache/faa/faa1fdb2548701eb77fc77cfa18d8e47.blob',
	}

	local newDirectories =
	{
		'cache/',
		'cache/c51/',
		'cache/e80/',
		'cache/ead/',
		'cache/faa/',
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
		'cache/c51/c518ad13579d451d4c0b2b69178a5095-ead1e43de665f2a38d9f939274cf079c.link',
		'cache/e80/e803da4ab5571e583e755f963d4b37fd-faa1fdb2548701eb77fc77cfa18d8e47.link',
		'cache/ead/ead1e43de665f2a38d9f939274cf079c.blob',
		'cache/faa/faa1fdb2548701eb77fc77cfa18d8e47.blob',
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
		'cache/c51/c518ad13579d451d4c0b2b69178a5095-ead1e43de665f2a38d9f939274cf079c.link',
		'cache/e80/e803da4ab5571e583e755f963d4b37fd-faa1fdb2548701eb77fc77cfa18d8e47.link',
		'cache/ead/ead1e43de665f2a38d9f939274cf079c.blob',
		'cache/faa/faa1fdb2548701eb77fc77cfa18d8e47.blob',
	}

	local pass1Directories = {
		'cache/',
		'cache/c51/',
		'cache/e80/',
		'cache/ead/',
		'cache/faa/',
	}

	TestFiles(pass1Files)
	TestDirectories(pass1Directories)

	RunJam{ 'clean' }

	local pass2Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.tga',
		'file2.tga',
		'cache/c51/c518ad13579d451d4c0b2b69178a5095-ead1e43de665f2a38d9f939274cf079c.link',
		'cache/e80/e803da4ab5571e583e755f963d4b37fd-faa1fdb2548701eb77fc77cfa18d8e47.link',
		'cache/ead/ead1e43de665f2a38d9f939274cf079c.blob',
		'cache/faa/faa1fdb2548701eb77fc77cfa18d8e47.blob',
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
file1.image is already the proper cached target.
*** updated 1 target(s)...
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
		'cache/33d/',
		'cache/ba3/',
		'cache/c51/',
		'cache/e80/',
		'cache/ead/',
		'cache/faa/',
	}

	local pass3Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'file1.image',
		'file1.tga',
		'file2.image',
		'file2.tga',
		'cache/33d/33d6f96e9d66b65c9d4036f777187316-ba30b5bbf846278b094d76c1c7a3aaf9.link',
		'cache/ba3/ba30b5bbf846278b094d76c1c7a3aaf9.blob',
		'cache/c51/c518ad13579d451d4c0b2b69178a5095-ead1e43de665f2a38d9f939274cf079c.link',
		'cache/e80/e803da4ab5571e583e755f963d4b37fd-faa1fdb2548701eb77fc77cfa18d8e47.link',
		'cache/ead/ead1e43de665f2a38d9f939274cf079c.blob',
		'cache/faa/faa1fdb2548701eb77fc77cfa18d8e47.blob',
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

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


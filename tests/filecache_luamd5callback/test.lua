function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'extra.png',
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
	ospath.remove('.jamchecksums')
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
!NEXT!md5zip: Calculating file4.zip...
!NEXT!@ ConvertImageHelper file4.image
!NEXT!Caching file4.image
@ ConvertImageHelper file5.image
!NEXT!*** updated 5 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files =
	{
		'?.jamchecksums',
		'Jamfile.jam',
		'extra.png',
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
		'cache/886/886160b610ddb485591ee4148ff4a125-cadea65306fd1485dfc720a42894d02b.link',
		'cache/a50/a50161b39b1d9dd3c0ccc71b99eea835-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/c72/c725fc57ac830ff20dc121a89e8e2750-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/cad/cadea65306fd1485dfc720a42894d02b.blob',
		'cache/d6e/d6ebe7c0fc970729e3e76bba600f9dcf.blob',
		'cache/f4f/f4f45e85b0ac7838cfc3ec71031f5871-cadea65306fd1485dfc720a42894d02b.link',
		'cache/fe0/fe079e9f8dd0cd55cb3d4b4d3c87764a-cadea65306fd1485dfc720a42894d02b.link',
	}

	local newDirectories =
	{
		'cache/',
		'cache/886/',
		'cache/a50/',
		'cache/c72/',
		'cache/cad/',
		'cache/d6e/',
		'cache/f4f/',
		'cache/fe0/',
	}

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean' }

	local pass2Files =
	{
		'?.jamdepcache',
		'Jamfile.jam',
		'extra.png',
		'file1.png',
		'file2.png',
		'file3.png',
		'file4.zip',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
		'cache/886/886160b610ddb485591ee4148ff4a125-cadea65306fd1485dfc720a42894d02b.link',
		'cache/a50/a50161b39b1d9dd3c0ccc71b99eea835-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/c72/c725fc57ac830ff20dc121a89e8e2750-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/cad/cadea65306fd1485dfc720a42894d02b.blob',
		'cache/d6e/d6ebe7c0fc970729e3e76bba600f9dcf.blob',
		'cache/f4f/f4f45e85b0ac7838cfc3ec71031f5871-cadea65306fd1485dfc720a42894d02b.link',
		'cache/fe0/fe079e9f8dd0cd55cb3d4b4d3c87764a-cadea65306fd1485dfc720a42894d02b.link',
	}

	TestFiles(pass2Files)
	TestDirectories(newDirectories)

	local pattern2 = [[
*** found 11 target(s)...
*** updating 5 target(s)...
md5png: Calculating file1.png...
Using cached file1.image
Using cached file2.image
Using cached file3.image
md5zip: Calculating file4.zip...
Using cached file4.image
Using cached file5.image
*** updated 5 target(s)...
]]
	TestPattern(pattern2, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean', 'JAM_CHECKSUMS_KEEPCACHE=1' }

	local pattern3 = [[
*** found 11 target(s)...
*** updating 5 target(s)...
Using cached file1.image
Using cached file2.image
Using cached file3.image
Using cached file4.image
Using cached file5.image
*** updated 5 target(s)...
]]
	TestPattern(pattern3, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	osprocess.sleep(1.0)
	ospath.touch('file3.png')

	local pattern4 = [[
*** found 11 target(s)...
*** updating 1 target(s)...
file3.image is already the proper cached target.
*** updated 1 target(s)...
]]
	TestPattern(pattern4, RunJam())

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
	ospath.copy_file('file2.png', 'file3.png')

	-- Test for a clean directory.
	local originalFiles = {
		'Jamfile.jam',
		'extra.png',
		'file1.png',
		'file2.png',
		'file3.png',
		'file4.zip',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
	}

	local originalDirs = {
	}

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')
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
!NEXT!Caching link file2.image
!NEXT!@ ConvertImageHelper file3.image
!NEXT!Caching link file3.image
md5zip: Calculating file4.zip...
!NEXT!@ ConvertImageHelper file4.image
!NEXT!Caching file4.image
@ ConvertImageHelper file5.image
!NEXT!Caching link file5.image
!NEXT!*** updated 5 target(s)...
]]

	TestPattern(pattern, RunJam())

	local pass1Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'extra.png',
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
		'cache/886/886160b610ddb485591ee4148ff4a125-cadea65306fd1485dfc720a42894d02b.link',
		'cache/a50/a50161b39b1d9dd3c0ccc71b99eea835-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/c72/c725fc57ac830ff20dc121a89e8e2750-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/cad/cadea65306fd1485dfc720a42894d02b.blob',
		'cache/d6e/d6ebe7c0fc970729e3e76bba600f9dcf.blob',
		'cache/f4f/f4f45e85b0ac7838cfc3ec71031f5871-cadea65306fd1485dfc720a42894d02b.link',
		'cache/fe0/fe079e9f8dd0cd55cb3d4b4d3c87764a-cadea65306fd1485dfc720a42894d02b.link',
	}

	local newDirectories = {
		'cache/',
		'cache/886/',
		'cache/a50/',
		'cache/c72/',
		'cache/cad/',
		'cache/d6e/',
		'cache/f4f/',
		'cache/fe0/',
	}

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean' }

	local pass2Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'extra.png',
		'file1.png',
		'file2.png',
		'file3.png',
		'file4.zip',
		'file5.zip',
		'md5file.lua',
		'md5png.lua',
		'md5zip.lua',
		'cache/886/886160b610ddb485591ee4148ff4a125-cadea65306fd1485dfc720a42894d02b.link',
		'cache/a50/a50161b39b1d9dd3c0ccc71b99eea835-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/c72/c725fc57ac830ff20dc121a89e8e2750-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/cad/cadea65306fd1485dfc720a42894d02b.blob',
		'cache/d6e/d6ebe7c0fc970729e3e76bba600f9dcf.blob',
		'cache/f4f/f4f45e85b0ac7838cfc3ec71031f5871-cadea65306fd1485dfc720a42894d02b.link',
		'cache/fe0/fe079e9f8dd0cd55cb3d4b4d3c87764a-cadea65306fd1485dfc720a42894d02b.link',
	}

	TestFiles(pass2Files)
	TestDirectories(newDirectories)

	local pattern2 = [[
*** found 11 target(s)...
*** updating 5 target(s)...
md5png: Calculating file1.png...
Using cached file1.image
Using cached file2.image
Using cached file3.image
md5zip: Calculating file4.zip...
Using cached file4.image
Using cached file5.image
*** updated 5 target(s)...
]]
	TestPattern(pattern2, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	RunJam{ 'clean', 'JAM_CHECKSUMS_KEEPCACHE=1' }

	local pattern3 = [[
*** found 11 target(s)...
*** updating 5 target(s)...
Using cached file1.image
Using cached file2.image
Using cached file3.image
Using cached file4.image
Using cached file5.image
*** updated 5 target(s)...
]]
	TestPattern(pattern3, RunJam())

	TestFiles(pass1Files)
	TestDirectories(newDirectories)

	osprocess.sleep(1.0)
	ospath.touch('file3.png')

	local pattern4 = [[
*** found 11 target(s)...
*** updating 1 target(s)...
*** updated 0 target(s)...
]]
	TestPattern(pattern4, RunJam())

	osprocess.sleep(1.0)
	ospath.copy_file('extra.png', 'file3.png')
	ospath.touch('file3.png')

	local pattern5 = [[
*** found 11 target(s)...
*** updating 1 target(s)...
@ ConvertImageHelper file3.image
!NEXT!Caching file3.image
*** updated 1 target(s)...
]]
	TestPattern(pattern5, RunJam())

	local pass3Directories = {
		'cache/',
		'cache/527/',
		'cache/886/',
		'cache/a50/',
		'cache/b57/',
		'cache/c72/',
		'cache/cad/',
		'cache/d6e/',
		'cache/f4f/',
		'cache/fe0/',
	}

	local pass3Files = {
		'?.jamdepcache',
		'Jamfile.jam',
		'extra.png',
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
		'cache/527/527c94471f41c1e70e628bb2704c6669-b579c4857bdb320f1c41021f5b5c9f9e.link',
		'cache/886/886160b610ddb485591ee4148ff4a125-cadea65306fd1485dfc720a42894d02b.link',
		'cache/a50/a50161b39b1d9dd3c0ccc71b99eea835-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/b57/b579c4857bdb320f1c41021f5b5c9f9e.blob',
		'cache/c72/c725fc57ac830ff20dc121a89e8e2750-d6ebe7c0fc970729e3e76bba600f9dcf.link',
		'cache/cad/cadea65306fd1485dfc720a42894d02b.blob',
		'cache/d6e/d6ebe7c0fc970729e3e76bba600f9dcf.blob',
		'cache/f4f/f4f45e85b0ac7838cfc3ec71031f5871-cadea65306fd1485dfc720a42894d02b.link',
		'cache/fe0/fe079e9f8dd0cd55cb3d4b4d3c87764a-cadea65306fd1485dfc720a42894d02b.link',
	}

	TestFiles(pass3Files)
	TestDirectories(pass3Directories)

	local pattern6 = [[
*** found 11 target(s)...
]]
	TestPattern(pattern6, RunJam())

	ospath.remove('cache/')
	ospath.remove('.jamdepcache')
	RunJam{ 'clean' }
	ospath.copy_file('file2.png', 'file3.png')

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


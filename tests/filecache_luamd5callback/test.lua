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
		'cache/25a/25a1f48f14e41e5985b4dd10b6606188-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/2bd/2bd09428a420c7df8514fd0653a6deca.blob',
		'cache/35a/35a8ee991bc7ccc0d39d1d9bb36101a5-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/4a7/4a76873c4d4b3dcb55cdd08d9f9e07fe-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/502/50278e9ea821c10df20f83ac57fc25c7-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/715/71581f0371ecc3cf3878acb0855ef4f4-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/cf9/cf9d0f60ba6be7e3290797fcc0e7ebd6.blob',
	}

	local newDirectories =
	{
		'cache/',
		'cache/25a/',
		'cache/2bd/',
		'cache/35a/',
		'cache/4a7/',
		'cache/502/',
		'cache/715/',
		'cache/cf9/',
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
		'cache/25a/25a1f48f14e41e5985b4dd10b6606188-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/2bd/2bd09428a420c7df8514fd0653a6deca.blob',
		'cache/35a/35a8ee991bc7ccc0d39d1d9bb36101a5-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/4a7/4a76873c4d4b3dcb55cdd08d9f9e07fe-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/502/50278e9ea821c10df20f83ac57fc25c7-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/715/71581f0371ecc3cf3878acb0855ef4f4-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/cf9/cf9d0f60ba6be7e3290797fcc0e7ebd6.blob',
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
		'cache/25a/25a1f48f14e41e5985b4dd10b6606188-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/2bd/2bd09428a420c7df8514fd0653a6deca.blob',
		'cache/35a/35a8ee991bc7ccc0d39d1d9bb36101a5-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/4a7/4a76873c4d4b3dcb55cdd08d9f9e07fe-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/502/50278e9ea821c10df20f83ac57fc25c7-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/715/71581f0371ecc3cf3878acb0855ef4f4-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/cf9/cf9d0f60ba6be7e3290797fcc0e7ebd6.blob',
	}

	local newDirectories = {
		'cache/',
		'cache/25a/',
		'cache/2bd/',
		'cache/35a/',
		'cache/4a7/',
		'cache/502/',
		'cache/715/',
		'cache/cf9/',
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
		'cache/25a/25a1f48f14e41e5985b4dd10b6606188-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/2bd/2bd09428a420c7df8514fd0653a6deca.blob',
		'cache/35a/35a8ee991bc7ccc0d39d1d9bb36101a5-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/4a7/4a76873c4d4b3dcb55cdd08d9f9e07fe-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/502/50278e9ea821c10df20f83ac57fc25c7-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/715/71581f0371ecc3cf3878acb0855ef4f4-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/cf9/cf9d0f60ba6be7e3290797fcc0e7ebd6.blob',
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
		'cache/25a/',
		'cache/2bd/',
		'cache/35a/',
		'cache/4a7/',
		'cache/502/',
		'cache/696/',
		'cache/715/',
		'cache/9e9/',
		'cache/cf9/',
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
		'cache/25a/25a1f48f14e41e5985b4dd10b6606188-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/2bd/2bd09428a420c7df8514fd0653a6deca.blob',
		'cache/35a/35a8ee991bc7ccc0d39d1d9bb36101a5-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/4a7/4a76873c4d4b3dcb55cdd08d9f9e07fe-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/502/50278e9ea821c10df20f83ac57fc25c7-cf9d0f60ba6be7e3290797fcc0e7ebd6.link',
		'cache/696/69664c70b28b620ee7c1411f47947c52-9e9f5c5b1f02411c0f32db7b85c479b5.link',
		'cache/715/71581f0371ecc3cf3878acb0855ef4f4-2bd09428a420c7df8514fd0653a6deca.link',
		'cache/9e9/9e9f5c5b1f02411c0f32db7b85c479b5.blob',
		'cache/cf9/cf9d0f60ba6be7e3290797fcc0e7ebd6.blob',
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


function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'Jamfile.jam',
		'helloworld.c',
		'test.lua',
		'c-compilers/c-groovycompiler.jam',
		'c-compilers/groovyplatform-autodetect.jam',
		'c-compilers/configs/groovyplatform-debug.jam',
		'c-compilers/configs/groovyplatform-release.jam',
	}

	local originalDirs =
	{
		'c-compilers/',
		'c-compilers/configs/',
	}

	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=release', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern
	local pattern2
	if Platform == 'win32' then
		pattern = [[
*** found 10 target(s)...
*** updating 4 target(s)...
@ C.groovycompiler.CC <groovyplatform!release:helloworld>helloworld.o
@ C.groovycompiler.Link <groovyplatform!release:helloworld>helloworld.exe
*** updated 4 target(s)...
]]
		pattern2 = [[
*** found 10 target(s)...
]]
	else
		pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.groovycompiler.CC <groovyplatform!release:helloworld>helloworld.o
!NEXT!@ C.groovycompiler.Link <groovyplatform!release:helloworld>helloworld.exe
!NEXT!*** updated 3 target(s)...
]]
		pattern2 = [[
*** found 8 target(s)...
]]
	end

	TestPattern(pattern, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=release' })

	local pass1Dirs =
	{
		'c-compilers/',
		'c-compilers/configs/',
		'groovyplatform-release/',
		'groovyplatform-release/helloworld/',
	}

	local pass1Files =
	{
		'c-compilers/c-groovycompiler.jam',
		'c-compilers/configs/groovyplatform-debug.jam',
		'c-compilers/configs/groovyplatform-release.jam',
		'c-compilers/groovyplatform-autodetect.jam',
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'groovyplatform-release/helloworld/helloworld.o',
		'groovyplatform-release/helloworld/helloworld.release.exe',
		'helloworld.c',
		'Jamfile.jam',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=release' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=release', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
!NEXT!c-compilers/configs/badplatform-release.jam: No such file or directory
]]
	TestPattern(pattern3, RunJam{ 'PLATFORM=badplatform' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

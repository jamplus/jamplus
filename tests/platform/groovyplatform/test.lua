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
		'c-compilers/groovyplatform-groovycompiler-debug.jam',
		'c-compilers/groovyplatform-groovycompiler-retail.jam',
	}

	local originalDirs =
	{
		'c-compilers/',
	}

	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 7 target(s)...
*** updating 2 target(s)...
@ C.CC <helloworld>helloworld.o
@ C.Link <helloworld>helloworld.retail.exe
*** updated 2 target(s)...
]]

	TestPattern(pattern, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail' })

	local pass1Files =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'Jamfile.jam',
		'helloworld.c',
		'helloworld.o',
		'helloworld.retail.exe',
		'test.lua',
		'c-compilers/c-groovycompiler.jam',
		'c-compilers/groovyplatform-autodetect.jam',
		'c-compilers/groovyplatform-groovycompiler-debug.jam',
		'c-compilers/groovyplatform-groovycompiler-retail.jam',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 7 target(s)...
]]
	TestPattern(pattern2, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail' })
	TestDirectories(originalDirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
!NEXT!* No supported build platform found on this computer.
]]
	TestPattern(pattern3, RunJam{ 'PLATFORM=badplatform' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'CreateJamVS2010Workspace.bat',
		'CreateJamVS2010Workspace.config',
		'CreateJamVS2012Workspace.bat',
		'CreateJamVS2012Workspace.config',
		'Jamfile.jam',
		'helloworld.c',
		'test.lua',
		'c-compilers/c-groovycompiler.jam',
		'c-compilers/groovyplatform-autodetect.jam',
		'c-compilers/configs/groovyplatform-debug.jam',
		'c-compilers/configs/groovyplatform-retail.jam',
	}

	local originalDirs =
	{
		'c-compilers/',
		'c-compilers/configs/',
	}

	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 10 target(s)...
*** updating 4 target(s)...
@ C.groovycompiler.CC <groovyplatform!retail:helloworld>helloworld.o
@ C.groovycompiler.Link <groovyplatform!retail:helloworld>helloworld.exe
*** updated 4 target(s)...
]]

	TestPattern(pattern, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail' })

	local pass1Dirs =
	{
		'c-compilers/',
		'c-compilers/configs/',
		'groovyplatform-retail/',
		'groovyplatform-retail/helloworld/',
	}

	local pass1Files =
	{
		'c-compilers/c-groovycompiler.jam',
		'c-compilers/configs/groovyplatform-debug.jam',
		'c-compilers/configs/groovyplatform-retail.jam',
		'c-compilers/groovyplatform-autodetect.jam',
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'CreateJamVS2010Workspace.bat',
		'CreateJamVS2010Workspace.config',
		'CreateJamVS2012Workspace.bat',
		'CreateJamVS2012Workspace.config',
		'groovyplatform-retail/helloworld/helloworld.o',
		'groovyplatform-retail/helloworld/helloworld.retail.exe',
		'helloworld.c',
		'Jamfile.jam',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 10 target(s)...
]]
	TestPattern(pattern2, RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'PLATFORM=groovyplatform', 'CONFIG=retail', 'clean' }
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

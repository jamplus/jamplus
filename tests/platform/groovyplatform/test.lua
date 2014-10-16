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
		'toolchains/c/_helpers/groovycompiler.jam',
		'toolchains/c/_helpers/groovyplatform-autodetect.jam',
		'toolchains/c/groovyplatform-debug.jam',
		'toolchains/c/groovyplatform-retail.jam',
	}

	local originalDirs =
	{
		'toolchains/',
		'toolchains/c/',
		'toolchains/c/_helpers/',
	}

	RunJam{ 'TOOLCHAIN=c/groovyplatform/retail', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern
	local pattern2
	pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.groovycompiler.CC <c/groovyplatform/retail:helloworld>helloworld.o
!NEXT!@ C.groovycompiler.Link <c/groovyplatform/retail:helloworld>helloworld.exe
*** updated 3 target(s)...
]]
	pattern2 = [[
!NEXT!*** found 8 target(s)...
]]

	TestPattern(pattern, RunJam{ 'TOOLCHAIN=c/groovyplatform/retail' })

	local pass1Dirs =
	{
		'groovyplatform-retail/',
		'groovyplatform-retail/helloworld/',
		'toolchains/',
		'toolchains/c/',
		'toolchains/c/_helpers/',
	}

	local pass1Files =
	{
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
		'toolchains/c/_helpers/groovycompiler.jam',
		'toolchains/c/_helpers/groovyplatform-autodetect.jam',
		'toolchains/c/groovyplatform-debug.jam',
		'toolchains/c/groovyplatform-retail.jam',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{ 'TOOLCHAIN=c/groovyplatform/retail' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'TOOLCHAIN=c/groovyplatform/retail', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
!NEXT!* Unable to find [toolchains/c/_helpers/badplatform].
]]
	TestPattern(pattern3, RunJam{ 'TOOLCHAIN=c/badplatform' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

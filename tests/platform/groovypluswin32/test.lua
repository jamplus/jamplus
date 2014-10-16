function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'Jamfile.jam',
		'helloworld.c',
		'test.lua',
		'toolchains/c/_helpers/groovycompiler.jam',
		'toolchains/c/_helpers/groovyplatform-autodetect.jam',
		'toolchains/c/groovyplatform-debug.jam',
		'toolchains/c/groovyplatform-release.jam',
	}

	local originalDirs =
	{
		'toolchains/',
		'toolchains/c/',
		'toolchains/c/_helpers/',
	}

	RunJam{ 'TOOLCHAIN=c/groovyplatform/release', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.groovycompiler.CC <c/groovyplatform/release:helloworld>helloworld.o
!NEXT!@ C.groovycompiler.Link <c/groovyplatform/release:helloworld>helloworld.exe
*** updated 3 target(s)...
]]
	local pattern2 = [[
!NEXT!*** found 8 target(s)...
]]

	TestPattern(pattern, RunJam{ 'TOOLCHAIN=c/groovyplatform/release' })

	local pass1Dirs =
	{
		'groovyplatform-release/',
		'groovyplatform-release/helloworld/',
		'toolchains/',
		'toolchains/c/',
		'toolchains/c/_helpers/',
	}

	local pass1Files =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'groovyplatform-release/helloworld/helloworld.o',
		'groovyplatform-release/helloworld/helloworld.release.exe',
		'helloworld.c',
		'Jamfile.jam',
		'toolchains/c/_helpers/groovycompiler.jam',
		'toolchains/c/_helpers/groovyplatform-autodetect.jam',
		'toolchains/c/groovyplatform-debug.jam',
		'toolchains/c/groovyplatform-release.jam',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{ 'TOOLCHAIN=c/groovyplatform/release' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'TOOLCHAIN=c/groovyplatform/release', 'clean' }
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

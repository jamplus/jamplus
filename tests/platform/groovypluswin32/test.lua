function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'helloworld.c',
		'jam/c/toolchain/groovyplatform.jam',
		'Jamfile.jam',
		'test.lua',
	}

	local originalDirs =
	{
		'jam/',
		'jam/c/',
		'jam/c/toolchain/',
	}

	RunJam{ 'C.TOOLCHAIN=groovyplatform/release', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.groovycompiler.CC <c/groovyplatform/release:helloworld>helloworld.o
!NEXT!@ C.groovycompiler.Link <c/groovyplatform/release:helloworld>helloworld$(SUFEXE)
*** updated 3 target(s)...
]]
	local pattern2 = [[
!NEXT!*** found 8 target(s)...
]]

	TestPattern(pattern, RunJam{ 'C.TOOLCHAIN=groovyplatform/release' })

	local pass1Dirs =
	{
		'.build/groovyplatform-release/TOP/',
		'.build/groovyplatform-release/TOP/helloworld/',
		'jam/',
		'jam/c/',
		'jam/c/toolchain/',
	}

	local pass1Files =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'helloworld.c',
		'.build/groovyplatform-release/TOP/helloworld/helloworld.o',
		'.build/groovyplatform-release/TOP/helloworld/helloworld.release$(SUFEXE)',
		'jam/c/toolchain/groovyplatform.jam',
		'Jamfile.jam',
		'test.lua',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{ 'C.TOOLCHAIN=groovyplatform/release' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'C.TOOLCHAIN=groovyplatform/release', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
!NEXT!* Toolchain [ badplatform ] not found!

  Could not match any of the following rules:
    -> C.Toolchain.badplatform
    -> C.Toolchain.badplatform.*
]]
	TestPattern(pattern3, RunJam{ 'C.TOOLCHAIN=badplatform' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

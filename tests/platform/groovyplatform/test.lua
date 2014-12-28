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
		'helloworld.c',
		'jam/c/toolchain/groovycompiler/groovyplatform.jam',
		'jam/c/toolchain/groovycompiler/shared.jam',
		'jam/c/toolchain/groovyplatform/debug.jam',
		'jam/c/toolchain/groovyplatform/retail.jam',
		'Jamfile.jam',
		'test.lua',
	}

	local originalDirs =
	{
		'jam/',
		'jam/c/',
		'jam/c/toolchain/',
		'jam/c/toolchain/groovycompiler/',
		'jam/c/toolchain/groovyplatform/',
	}

	RunJam{ 'C.TOOLCHAIN=groovyplatform/retail', 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern
	local pattern2
	pattern = [[
*** found 8 target(s)...
*** updating 3 target(s)...
@ C.groovycompiler.CC <c/groovyplatform/retail:helloworld>helloworld.o
!NEXT!@ C.groovycompiler.Link <c/groovyplatform/retail:helloworld>helloworld$(SUFEXE)
*** updated 3 target(s)...
]]
	pattern2 = [[
!NEXT!*** found 8 target(s)...
]]

	TestPattern(pattern, RunJam{ 'C.TOOLCHAIN=groovyplatform/retail' })

	local pass1Dirs =
	{
		'.build/groovyplatform-retail/TOP/',
		'.build/groovyplatform-retail/TOP/helloworld/',
		'jam/',
		'jam/c/',
		'jam/c/toolchain/',
		'jam/c/toolchain/groovycompiler/',
		'jam/c/toolchain/groovyplatform/',
	}

	local pass1Files =
	{
		'CreateJamVS2008Workspace.bat',
		'CreateJamVS2008Workspace.config',
		'CreateJamVS2010Workspace.bat',
		'CreateJamVS2010Workspace.config',
		'CreateJamVS2012Workspace.bat',
		'CreateJamVS2012Workspace.config',
		'helloworld.c',
		'.build/groovyplatform-retail/TOP/helloworld/helloworld.o',
		'.build/groovyplatform-retail/TOP/helloworld/helloworld.retail$(SUFEXE)',
		'jam/c/toolchain/groovycompiler/groovyplatform.jam',
		'jam/c/toolchain/groovycompiler/shared.jam',
		'jam/c/toolchain/groovyplatform/debug.jam',
		'jam/c/toolchain/groovyplatform/retail.jam',
		'Jamfile.jam',
		'test.lua',
	}

	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{ 'C.TOOLCHAIN=groovyplatform/retail' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'C.TOOLCHAIN=groovyplatform/retail', 'clean' }
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

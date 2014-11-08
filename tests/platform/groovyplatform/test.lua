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
		'groovyplatform-retail/helloworld/helloworld.o',
		'groovyplatform-retail/helloworld/helloworld.retail.exe',
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
	TestPattern(pattern2, RunJam{ 'TOOLCHAIN=c/groovyplatform/retail' })
	TestDirectories(pass1Dirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'TOOLCHAIN=c/groovyplatform/retail', 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)

	---------------------------------------------------------------------------
	local pattern3 = [[
!NEXT!* Toolchain [ c/badplatform ] not found!

  Could not find any of the following matching rules:
    -> C.Toolchain.badplatform
    -> C.Toolchain.badplatform.*
]]
	TestPattern(pattern3, RunJam{ 'TOOLCHAIN=c/badplatform' })
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end

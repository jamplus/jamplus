function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'file.c',
		'main.c',
	}

	local originalDirs =
	{
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	if Platform == 'win32' then
		-- First build
		local pattern = [[
*** found 15 target(s)...
*** updating 3 target(s)...
@ C.CC <helloworld>main.obj
main.c
file.c
Generating Code...
@ C.LinkWithManifest <helloworld>helloworld.release.exe
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'file.c',
			'file.obj',
			'helloworld.release.exe',
			'helloworld.release.exe.intermediate.manifest',
			'helloworld.release.pdb',
			'main.c',
			'main.obj',
			'vc.pdb',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 15 target(s)...
]]
		TestPattern(pattern2, RunJam())
	
		os.sleep(1.0)
		os.touch('file.c')

		local pattern3 = [[
*** found 15 target(s)...
*** updating 2 target(s)...
@ C.CC <helloworld>file.obj
file.c
@ C.LinkWithManifest <helloworld>helloworld.release.exe
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)

	else

		-- First build
		local pattern = [[
*** found 9 target(s)...
*** updating 3 target(s)...
@ C.CC <helloworld>main.o 
@ C.CC <helloworld>file.o 
@ C.Link <helloworld>helloworld.release 
*** updated 3 target(s)...
]]

		TestPattern(pattern, RunJam())

		local pass1Files =
		{
			'Jamfile.jam',
			'file.c',
			'file.o',
			'helloworld.release',
			'main.c',
			'main.o',
		}

		TestFiles(pass1Files)
		TestDirectories(originalDirs)

		local pattern2 = [[
*** found 9 target(s)...
]]
		TestPattern(pattern2, RunJam())

		os.sleep(1.0)
		os.touch('file.c')

		local pattern3 = [[
*** found 9 target(s)...
*** updating 2 target(s)...
@ C.CC <helloworld>file.o 
@ C.Link <helloworld>helloworld.release 
*** updated 2 target(s)...
]]
		TestPattern(pattern3, RunJam())
		TestFiles(pass1Files)
		TestDirectories(originalDirs)
	end

	RunJam{ 'clean' }

	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


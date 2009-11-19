function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'main.cpp',
		'mypch.cpp',
		'includes/mypch.h',
	}

	local originalDirs =
	{
		'includes/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pattern = [[
*** found 17 target(s)...
*** updating 4 target(s)...
@ C.C++ <main>mypch.h.pch
mypch.cpp
@ C.C++ <main>main.obj
main.cpp
@ C.LinkWithManifest <main>main.release.exe
*** updated 4 target(s)...
]]

	TestPattern(pattern, RunJam{})

	local pass1Files =
	{
		'Jamfile.jam',
		'main.cpp',
		'main.obj',
		'main.release.exe',
		'main.release.exe.intermediate.manifest',
		'main.release.pdb',
		'mypch.cpp',
		'mypch.h.pch',
		'mypch.obj',
		'test.lua',
		'vc.pdb',
		'includes/mypch.h',
	}

	TestDirectories(originalDirs)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2 = [[
*** found 17 target(s)...
]]
	TestPattern(pattern2, RunJam{})
	TestDirectories(originalDirs)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

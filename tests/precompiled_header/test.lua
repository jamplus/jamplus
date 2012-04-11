function Test()
	-- Test for a clean directory.
	local originalFiles =
	{
		'Jamfile.jam',
		'main.cpp',
		'mypch.cpp',
		'includes/mypch.h',
		'includes/usefuldefine.h',
	}

	local originalDirs =
	{
		'includes/',
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	local pass1Directories
	local pass1Files
	local pattern

	if Platform == 'win32' and not Compiler then
		pass1Directories = {
			'includes/',
			'win32-release/',
			'win32-release/main/',
		}

		pass1Files = {
			'Jamfile.jam',
			'main.cpp',
			'mypch.cpp',
			'includes/mypch.h',
			'includes/usefuldefine.h',
			'win32-release/main/main.obj',
			'win32-release/main/main.release.exe',
			'win32-release/main/main.release.exe.intermediate.manifest',
			'win32-release/main/main.release.pdb',
			'win32-release/main/mypch.h.pch',
			'win32-release/main/mypch.obj',
		}

		pass1Pattern = [[
			*** found 20 target(s)...
			*** updating 6 target(s)...
			@ C.vc.C++ <win32!release:main>mypch.h.pch
			mypch.cpp
			@ C.vc.C++ <win32!release:main>main.obj
			main.cpp
			@ C.vc.LinkWithManifest <win32!release:main>main.exe
			*** updated 6 target(s)...
]]

		pass2Pattern = [[
			*** found 20 target(s)...
			*** updating 4 target(s)...
			@ C.vc.C++ <win32!release:main>mypch.h.pch
			mypch.cpp
			@ C.vc.C++ <win32!release:main>main.obj
			main.cpp
			@ C.vc.LinkWithManifest <win32!release:main>main.exe
			*** updated 4 target(s)...
]]
	elseif Compiler == 'mingw' then
		pass1Directories = {
			'includes/',
			'mypch%-%x+/',
		}

		pass1Files = {
			'Jamfile.jam',
			'main.cpp',
			'main.o',
			'main.release.exe',
			'mypch.cpp',
			'mypch.o',
			'test.lua',
			'includes/mypch.h',
			'includes/usefuldefine.h',
			'mypch%-%x+/mypch.h.gch',
		}

		pass1Pattern = [[
			*** found 14 target(s)...
			*** updating 5 target(s)...
			&@ C.PCH <main%-%x+>mypch.h.gch
			@ C.C++ <main>main.o 
			@ C.C++ <main>mypch.o 
			@ C.Link <main>main.release.exe
			*** updated 5 target(s)...
]]

		pass2Pattern = [[
			*** found 14 target(s)...
			*** updating 5 target(s)...
			&@ C.PCH <main%-%x+>mypch.h.gch
			@ C.C++ <main>main.o 
			@ C.C++ <main>mypch.o 
			@ C.Link <main>main.release.exe
			*** updated 5 target(s)...
]]
	else
		pass1Directories = {
			'includes/',
			'macosx32-release/',
			'macosx32-release/main/',
			'macosx32%-release/main/mypch%-%x+/',
		}

		pass1Files = {
			'Jamfile.jam',
			'main.cpp',
			'mypch.cpp',
			'test.lua',
			'includes/mypch.h',
			'includes/usefuldefine.h',
			'macosx32-release/main/main.o',
			'macosx32-release/main/main.release',
			'macosx32-release/main/mypch.o',
			'macosx32%-release/main/mypch%-%x+/mypch.h.gch',
		}

		pass1Pattern = [[
			*** found 15 target(s)...
			*** updating 6 target(s)...
			&@ C.gcc.PCH <macosx32!release:main%-%x+>mypch.h.gch
			@ C.gcc.C++ <macosx32!release:main>main.o 
			@ C.gcc.C++ <macosx32!release:main>mypch.o 
			@ C.gcc.Link <macosx32!release:main>main
			*** updated 6 target(s)...
]]

		pass2Pattern = [[
			*** found 15 target(s)...
			*** updating 4 target(s)...
			&@ C.gcc.PCH <macosx32!release:main%-%x+>mypch.h.gch
			@ C.gcc.C++ <macosx32!release:main>main.o 
			@ C.gcc.C++ <macosx32!release:main>mypch.o 
			@ C.gcc.Link <macosx32!release:main>main
			*** updated 4 target(s)...
]]
	end

	TestPattern(pass1Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2
	if Platform == 'win32' and Compiler ~= 'mingw' then
		pattern2 = [[
*** found 20 target(s)...
]]
	else
		pattern2 = [[
*** found 15 target(s)...
]]
	end
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	os.sleep(1)
	os.touch('includes/usefuldefine.h')
	TestPattern(pass2Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

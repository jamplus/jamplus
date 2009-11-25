function Test()
	RunJam{ 'clean' }
	
	local cleanFiles =
	{
		'appA.cpp',
		'appB.cpp',
		'Jamfile.jam',
	}
	TestFiles(cleanFiles)

	if Platform == 'win32' then
		local run1pattern =
		{
			'Building appA...',
			'Building appB...',
			'*** found 24 target(s)...',
			'*** updating 4 target(s)...',
			'@ C.C++ <appA>appA.obj',
			'appA.cpp',
			'@ C.LinkWithManifest <appA>appA.release.exe',
			'@ C.C++ <appB>appB.obj',
			'appB.cpp',
			'@ C.LinkWithManifest <appB>appB.release.exe',
			'*** updated 4 target(s)...',
		}

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'appA.obj', 'appA.release.exe', 'appA.release.exe.intermediate.manifest', 'appA.release.pdb',
			'appB.obj', 'appB.release.exe', 'appB.release.exe.intermediate.manifest', 'appB.release.pdb',
			'?vc.pdb'
		}

		local appAPattern = [[
Building appA...
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.C++ <appA>appA.obj
appA.cpp
@ C.LinkWithManifest <appA>appA.release.exe
*** updated 2 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'appA.obj', 'appA.release.exe', 'appA.release.exe.intermediate.manifest', 'appA.release.pdb',
			'?vc.pdb'
		}

		local appBPattern = [[
Building appB...
*** found 12 target(s)...
*** updating 2 target(s)...
@ C.C++ <appB>appB.obj
appB.cpp
@ C.LinkWithManifest <appB>appB.release.exe
*** updated 2 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'appA.obj', 'appA.release.exe', 'appA.release.exe.intermediate.manifest', 'appA.release.pdb',
			'appB.obj', 'appB.release.exe', 'appB.release.exe.intermediate.manifest', 'appB.release.pdb',
			'?vc.pdb'
		}

		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'appB.obj', 'appB.release.exe', 'appB.release.exe.intermediate.manifest', 'appB.release.pdb',
			'?vc.pdb'
		}

		RunJam{ 'clean:appB' }
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
		}

	else
		---------------------------------------------------------------------------
		local run1pattern = [[
Building appA... 
Building appB... 
*** found 12 target(s)...
*** updating 4 target(s)...
@ C.C++ <appA>appA.o 
@ C.Link <appA>appA.release 
@ C.C++ <appB>appB.o 
@ C.Link <appB>appB.release 
*** updated 4 target(s)...
]]

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release',
			'appB.cpp', 'appB.o', 'appB.release',
		}

		---------------------------------------------------------------------------
		local cleanPattern = [[
Building appA... 
Building appB... 
*** found 4 target(s)...
*** updating 2 target(s)...
@ Clean clean:appA 
@ Clean clean:appB 
*** updated 2 target(s)...
]]
		TestPattern(cleanPattern, RunJam{ 'clean' })
		TestFiles(cleanFiles)

		---------------------------------------------------------------------------
		local appAPattern = [[
Building appA... 
*** found 6 target(s)...
*** updating 2 target(s)...
@ C.C++ <appA>appA.o 
@ C.Link <appA>appA.release 
*** updated 2 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release',
			'appB.cpp',
		}

		---------------------------------------------------------------------------
		local appBPattern = [[
Building appB... 
*** found 6 target(s)...
*** updating 2 target(s)...
@ C.C++ <appB>appB.o 
@ C.Link <appB>appB.release 
*** updated 2 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release',
			'appB.cpp', 'appB.o', 'appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appA' }
		TestFiles{
			'Jamfile.jam',
			'appA.cpp',
			'appB.cpp', 'appB.o', 'appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appB' }
		TestFiles(cleanFiles)

	end

end


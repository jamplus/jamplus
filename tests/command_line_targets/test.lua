function Test()
	RunJam{ 'clean' }
	
	local cleanFiles =
	{
		'appA.cpp',
		'appB.cpp',
		'Jamfile.jam',
	}
	TestFiles(cleanFiles)

	if Platform == 'win32'  and  Compiler ~= 'mingw' then
		local run1pattern =
		{
			'Building appA...',
			'Building appB...',
			'*** found 27 target(s)...',
			'*** updating 7 target(s)...',
			'@ C.vc.C++ <win32!release:appA>appA.obj',
			'appA.cpp',
			'@ C.vc.LinkWithManifest <win32!release:appA>appA.exe',
			'@ C.vc.C++ <win32!release:appB>appB.obj',
			'appB.cpp',
			'@ C.vc.LinkWithManifest <win32!release:appB>appB.exe',
			'*** updated 7 target(s)...',
		}

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32!release/appA/appA.obj',
			'win32!release/appA/appA.release.exe',
			'win32!release/appA/appA.release.exe.intermediate.manifest',
			'win32!release/appA/appA.release.pdb',
			'win32!release/appB/appB.obj',
			'win32!release/appB/appB.release.exe',
			'win32!release/appB/appB.release.exe.intermediate.manifest',
			'win32!release/appB/appB.release.pdb',
			'?vc.pdb'
		}

		---------------------------------------------------------------------------
		local cleanPattern = [[
Building appA... 
Building appB... 
*** found 6 target(s)...
*** updating 2 target(s)...
@ Clean <win32!release>clean:appA 
@ Clean <win32!release>clean:appB 
*** updated 2 target(s)...
]]
		TestPattern(cleanPattern, RunJam{ 'clean' })
		TestFiles(cleanFiles)

		---------------------------------------------------------------------------
		local appAPattern = [[
Building appA...
*** found 14 target(s)...
*** updating 4 target(s)...
@ C.vc.C++ <win32!release:appA>appA.obj
appA.cpp
@ C.vc.LinkWithManifest <win32!release:appA>appA.exe
*** updated 4 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32!release/appA/appA.obj',
			'win32!release/appA/appA.release.exe',
			'win32!release/appA/appA.release.exe.intermediate.manifest',
			'win32!release/appA/appA.release.pdb',
--			'?vc.pdb'
		}

		local appBPattern = [[
Building appB...
*** found 14 target(s)...
*** updating 3 target(s)...
@ C.vc.C++ <win32!release:appB>appB.obj
appB.cpp
@ C.vc.LinkWithManifest <win32!release:appB>appB.exe
*** updated 3 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32!release/appA/appA.obj',
			'win32!release/appA/appA.release.exe',
			'win32!release/appA/appA.release.exe.intermediate.manifest',
			'win32!release/appA/appA.release.pdb',
			'win32!release/appB/appB.obj',
			'win32!release/appB/appB.release.exe',
			'win32!release/appB/appB.release.exe.intermediate.manifest',
			'win32!release/appB/appB.release.pdb',
			'?vc.pdb'
		}

		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32!release/appB/appB.obj',
			'win32!release/appB/appB.release.exe',
			'win32!release/appB/appB.release.exe.intermediate.manifest',
			'win32!release/appB/appB.release.pdb',
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
@ C.Link <appA>appA.release$(SUFEXE) 
@ C.C++ <appB>appB.o 
@ C.Link <appB>appB.release$(SUFEXE) 
*** updated 4 target(s)...
]]

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release$(SUFEXE)',
			'appB.cpp', 'appB.o', 'appB.release$(SUFEXE)',
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
@ C.Link <appA>appA.release$(SUFEXE) 
*** updated 2 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release$(SUFEXE)',
			'appB.cpp',
		}

		---------------------------------------------------------------------------
		local appBPattern = [[
Building appB... 
*** found 6 target(s)...
*** updating 2 target(s)...
@ C.C++ <appB>appB.o 
@ C.Link <appB>appB.release$(SUFEXE)
*** updated 2 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'Jamfile.jam',
			'appA.cpp', 'appA.o', 'appA.release$(SUFEXE)',
			'appB.cpp', 'appB.o', 'appB.release$(SUFEXE)',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appA' }
		TestFiles{
			'Jamfile.jam',
			'appA.cpp',
			'appB.cpp', 'appB.o', 'appB.release$(SUFEXE)',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appB' }
		TestFiles(cleanFiles)

	end

end


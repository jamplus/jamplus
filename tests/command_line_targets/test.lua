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
			'*** found 33 target(s)...',
			'*** updating 7 target(s)...',
			'@ C.vc.C++ <win32!release:appA>appA.obj',
			'!NEXT!@ C.vc.Link <win32!release:appA>appA.exe',
			'!NEXT!@ C.vc.C++ <win32!release:appB>appB.obj',
			'!NEXT!@ C.vc.Link <win32!release:appB>appB.exe',
			'*** updated 7 target(s)...',
		}

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32-release/appA/appA.obj',
			'win32-release/appA/appA.release.exe',
			'win32-release/appA/appA.release.pdb',
			'win32-release/appB/appB.obj',
			'win32-release/appB/appB.release.exe',
			'win32-release/appB/appB.release.pdb',
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
*** found 17 target(s)...
*** updating 4 target(s)...
@ C.vc.C++ <win32!release:appA>appA.obj
!NEXT!@ C.vc.Link <win32!release:appA>appA.exe
*** updated 4 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32-release/appA/appA.obj',
			'win32-release/appA/appA.release.exe',
			'win32-release/appA/appA.release.pdb',
--			'?vc.pdb'
		}

		local appBPattern = [[
Building appB...
*** found 17 target(s)...
*** updating 3 target(s)...
@ C.vc.C++ <win32!release:appB>appB.obj
!NEXT!@ C.vc.Link <win32!release:appB>appB.exe
*** updated 3 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32-release/appA/appA.obj',
			'win32-release/appA/appA.release.exe',
			'win32-release/appA/appA.release.pdb',
			'win32-release/appB/appB.obj',
			'win32-release/appB/appB.release.exe',
			'win32-release/appB/appB.release.pdb',
			'?vc.pdb'
		}

		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'win32-release/appB/appB.obj',
			'win32-release/appB/appB.release.exe',
			'win32-release/appB/appB.release.pdb',
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
*** found 15 target(s)...
*** updating 6 target(s)...
@ C.gcc.C++ <$(PLATFORM_CONFIG):appA>appA.o 
@ C.gcc.Link <$(PLATFORM_CONFIG):appA>appA$(SUFEXE) 
@ C.gcc.C++ <$(PLATFORM_CONFIG):appB>appB.o 
@ C.gcc.Link <$(PLATFORM_CONFIG):appB>appB$(SUFEXE) 
*** updated 6 target(s)...
]]

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(PLATFORM_CONFIG)/appA/appA.o',
			'$(PLATFORM_CONFIG)/appA/appA.release',
			'$(PLATFORM_CONFIG)/appB/appB.o',
			'$(PLATFORM_CONFIG)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		local cleanPattern = [[
Building appA... 
Building appB... 
*** found 6 target(s)...
*** updating 2 target(s)...
@ Clean <$(PLATFORM_CONFIG)>clean:appA 
@ Clean <$(PLATFORM_CONFIG)>clean:appB 
*** updated 2 target(s)...
]]
		TestPattern(cleanPattern, RunJam{ 'clean' })
		TestFiles(cleanFiles)

		---------------------------------------------------------------------------
		local appAPattern = [[
Building appA... 
*** found 7 target(s)...
*** updating 3 target(s)...
@ C.gcc.C++ <$(PLATFORM_CONFIG):appA>appA.o 
@ C.gcc.Link <$(PLATFORM_CONFIG):appA>appA$(SUFEXE) 
*** updated 3 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(PLATFORM_CONFIG)/appA/appA.o',
			'$(PLATFORM_CONFIG)/appA/appA.release',
		}

		---------------------------------------------------------------------------
		local appBPattern = [[
Building appB... 
*** found 7 target(s)...
*** updating 3 target(s)...
@ C.gcc.C++ <$(PLATFORM_CONFIG):appB>appB.o 
@ C.gcc.Link <$(PLATFORM_CONFIG):appB>appB$(SUFEXE)
*** updated 3 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(PLATFORM_CONFIG)/appA/appA.o',
			'$(PLATFORM_CONFIG)/appA/appA.release',
			'$(PLATFORM_CONFIG)/appB/appB.o',
			'$(PLATFORM_CONFIG)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(PLATFORM_CONFIG)/appB/appB.o',
			'$(PLATFORM_CONFIG)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appB' }
		TestFiles(cleanFiles)

	end

end


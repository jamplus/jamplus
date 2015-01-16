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
			'*** found 31 target(s)...',
			'*** updating 6 target(s)...',
			'@ C.vc.C++ <$(TOOLCHAIN_GRIST):appA>appA.obj',
			'!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):appA>appA.exe',
			'!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):appB>appB.obj',
			'!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):appB>appB.exe',
			'*** updated 6 target(s)...',
		}

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'$(TOOLCHAIN_PATH)/appA/appA.obj',
			'$(TOOLCHAIN_PATH)/appA/appA.release.exe',
			'$(TOOLCHAIN_PATH)/appA/appA.release.pdb',
			'$(TOOLCHAIN_PATH)/appB/appB.obj',
			'$(TOOLCHAIN_PATH)/appB/appB.release.exe',
			'$(TOOLCHAIN_PATH)/appB/appB.release.pdb',
			'?vc.pdb',
		}

		---------------------------------------------------------------------------
		local cleanPattern = [[
Building appA... 
Building appB... 
*** found 6 target(s)...
*** updating 3 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:appA 
@ Clean <$(TOOLCHAIN_GRIST)>clean:appB 
@ Clean clean
*** updated 3 target(s)...
]]
		TestPattern(cleanPattern, RunJam{ 'clean' })
		TestFiles(cleanFiles)

		---------------------------------------------------------------------------
		local appAPattern = [[
Building appA...
*** found 15 target(s)...
*** updating 3 target(s)...
@ C.vc.C++ <$(TOOLCHAIN_GRIST):appA>appA.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):appA>appA.exe
*** updated 3 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'$(TOOLCHAIN_PATH)/appA/appA.obj',
			'$(TOOLCHAIN_PATH)/appA/appA.release.exe',
			'$(TOOLCHAIN_PATH)/appA/appA.release.pdb',
--			'?vc.pdb'
		}

		local appBPattern = [[
Building appB...
*** found 15 target(s)...
*** updating 3 target(s)...
@ C.vc.C++ <$(TOOLCHAIN_GRIST):appB>appB.obj
!NEXT!@ $(C_LINK) <$(TOOLCHAIN_GRIST):appB>appB.exe
*** updated 3 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'$(TOOLCHAIN_PATH)/appA/appA.obj',
			'$(TOOLCHAIN_PATH)/appA/appA.release.exe',
			'$(TOOLCHAIN_PATH)/appA/appA.release.pdb',
			'$(TOOLCHAIN_PATH)/appB/appB.obj',
			'$(TOOLCHAIN_PATH)/appB/appB.release.exe',
			'$(TOOLCHAIN_PATH)/appB/appB.release.pdb',
			'?vc.pdb'
		}

		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp', 'appB.cpp', 'Jamfile.jam',
			'$(TOOLCHAIN_PATH)/appB/appB.obj',
			'$(TOOLCHAIN_PATH)/appB/appB.release.exe',
			'$(TOOLCHAIN_PATH)/appB/appB.release.pdb',
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
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):appA>appA.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):appA>appA$(SUFEXE) 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):appB>appB.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):appB>appB$(SUFEXE) 
*** updated 6 target(s)...
]]

		TestPattern(run1pattern, RunJam())

		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(TOOLCHAIN_PATH)/appA/appA.o',
			'$(TOOLCHAIN_PATH)/appA/appA.release',
			'$(TOOLCHAIN_PATH)/appB/appB.o',
			'$(TOOLCHAIN_PATH)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		local cleanPattern = [[
Building appA... 
Building appB... 
*** found 6 target(s)...
*** updating 3 target(s)...
@ Clean <$(TOOLCHAIN_GRIST)>clean:appA 
@ Clean <$(TOOLCHAIN_GRIST)>clean:appB 
*** updated 3 target(s)...
]]
		TestPattern(cleanPattern, RunJam{ 'clean' })
		TestFiles(cleanFiles)

		---------------------------------------------------------------------------
		local appAPattern = [[
Building appA... 
*** found 7 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):appA>appA.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):appA>appA$(SUFEXE) 
*** updated 3 target(s)...
]]

		TestPattern(appAPattern, RunJam{ 'appA' })
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(TOOLCHAIN_PATH)/appA/appA.o',
			'$(TOOLCHAIN_PATH)/appA/appA.release',
		}

		---------------------------------------------------------------------------
		local appBPattern = [[
Building appB... 
*** found 7 target(s)...
*** updating 3 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):appB>appB.o 
@ $(C_LINK) <$(TOOLCHAIN_GRIST):appB>appB$(SUFEXE)
*** updated 3 target(s)...
]]

		TestPattern(appBPattern, RunJam{ 'appB' })
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(TOOLCHAIN_PATH)/appA/appA.o',
			'$(TOOLCHAIN_PATH)/appA/appA.release',
			'$(TOOLCHAIN_PATH)/appB/appB.o',
			'$(TOOLCHAIN_PATH)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appA' }
		TestFiles{
			'appA.cpp',
			'appB.cpp',
			'Jamfile.jam',
			'test.lua',
			'$(TOOLCHAIN_PATH)/appB/appB.o',
			'$(TOOLCHAIN_PATH)/appB/appB.release',
		}

		---------------------------------------------------------------------------
		RunJam{ 'clean:appB' }
		TestFiles(cleanFiles)

	end

end


function Test()
	RunJam{ 'clean' }
	TestFiles{ 'appA.cpp', 'appB.cpp', 'Jamfile.jam' }

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

	RunJam{ 'clean' }
	TestFiles{ 'appA.cpp', 'appB.cpp', 'Jamfile.jam' }

	TestPattern(appAPattern, RunJam{ 'appA' })
	TestFiles{
		'appA.cpp', 'appB.cpp', 'Jamfile.jam',
		'appA.obj', 'appA.release.exe', 'appA.release.exe.intermediate.manifest', 'appA.release.pdb',
		'?vc.pdb'
	}


	appBPattern = [[
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

end


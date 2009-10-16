function Test()
	PostErrorMessage = '* This test needs more work.'

	local originalFiles =
	{
		"Jamfile.jam",
		"Jamrules.jam",
		"test.lua",
		"liba/Jamfile.jam",
		"liba/rootfile.cpp",
		"liba/treea/treeb/deepfile.cpp",
		"libb/Jamfile.jam",
		"libb/filea.cpp",
		"libb/fileb.cpp",
		"libb/filec.cpp",
		"libb/onelevel/oneleveldeeper.cpp",
		"libc/Jamfile.jam",
		"libc/src/Loading/Loading.cpp",
		"libc/src/Saving/Saving1.cpp",
		"libc/src/Saving/Saving3.cpp",
		"libc/src/Saving/SavingB.cpp",
		"libc/src/integral/integral1.cpp",
		"libc/src/integral/integral2.cpp",
		"libc/src/memory/memorya.cpp",
		"libc/src/memory/memoryb.cpp",
		"libc/src/win32/Loading/Loading.cpp",
		"libc/src/win32/Saving/Saving1.cpp",
		"libc/src/win32/Saving/Saving3.cpp",
		"libc/src/win32/Saving/SavingB.cpp",
		"outer/outer.cpp",
		"outerb/outer.cpp",
	}
	
	local originalDirs =
	{
		"liba/",
		"libb/",
		"libc/",
		"outer/",
		"outerb/",
		"liba/treea/",
		"liba/treea/treeb/",
		"libb/onelevel/",
		"libc/src/",
		"libc/src/Loading/",
		"libc/src/Saving/",
		"libc/src/integral/",
		"libc/src/memory/",
		"libc/src/win32/",
		"libc/src/win32/Loading/",
		"libc/src/win32/Saving/",
	}

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	RunJam()

	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)
end


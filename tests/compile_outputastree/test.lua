function Test()
--	PostErrorMessage = '* This test needs more work.'

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

	do
		RunJam{ 'clean' }
		TestDirectories(originalDirs)
		TestFiles(originalFiles)
	end

	if Platform == 'win32'  and  Compiler ~= 'mingw' then
		local dirs =
		{
			'liba/',
			'libb/',
			'libc/',
			'outer/',
			'outerb/',
			'liba/lib/',
			'liba/obj/',
			'liba/treea/',
			'liba/lib/win32/',
			'liba/lib/win32/release/',
			'liba/obj/win32/',
			'liba/obj/win32/release/',
			'liba/obj/win32/release/__/',
			'liba/obj/win32/release/treea/',
			'liba/obj/win32/release/__/outer/',
			'liba/obj/win32/release/treea/treeb/',
			'liba/treea/treeb/',
			'libb/lib/',
			'libb/obj/',
			'libb/onelevel/',
			'libb/lib/win32/',
			'libb/lib/win32/release/',
			'libb/obj/win32/',
			'libb/obj/win32/release/',
			'libb/obj/win32/release/__/',
			'libb/obj/win32/release/onelevel/',
			'libb/obj/win32/release/__/outerb/',
			'libc/lib/',
			'libc/obj/',
			'libc/src/',
			'libc/lib/win32/',
			'libc/lib/win32/release/',
			'libc/obj/win32/',
			'libc/obj/win32/release/',
			'libc/obj/win32/release/src/',
			'libc/obj/win32/release/src/Loading/',
			'libc/obj/win32/release/src/Saving/',
			'libc/obj/win32/release/src/integral/',
			'libc/obj/win32/release/src/memory/',
			'libc/obj/win32/release/src/win32/',
			'libc/obj/win32/release/src/win32/Loading/',
			'libc/obj/win32/release/src/win32/Saving/',
			'libc/src/Loading/',
			'libc/src/Saving/',
			'libc/src/integral/',
			'libc/src/memory/',
			'libc/src/win32/',
			'libc/src/win32/Loading/',
			'libc/src/win32/Saving/',
		}
	
		local files =
		{
			'Jamfile.jam',
			'Jamrules.jam',
			'liba/Jamfile.jam',
			'liba/rootfile.cpp',
			'liba/lib/win32/release/liba.lib',
			'liba/obj/win32/release/rootfile.obj',
			'liba/obj/win32/release/vc.pdb',
			'liba/obj/win32/release/__/outer/outer.obj',
			'liba/obj/win32/release/treea/treeb/deepfile.obj',
			'liba/treea/treeb/deepfile.cpp',
			'libb/Jamfile.jam',
			'libb/filea.cpp',
			'libb/fileb.cpp',
			'libb/filec.cpp',
			'libb/lib/win32/release/libb.lib',
			'libb/obj/win32/release/filea.obj',
			'libb/obj/win32/release/fileb.obj',
			'libb/obj/win32/release/filec.obj',
			'libb/obj/win32/release/vc.pdb',
			'libb/obj/win32/release/__/outerb/outer.obj',
			'libb/obj/win32/release/onelevel/oneleveldeeper.obj',
			'libb/onelevel/oneleveldeeper.cpp',
			'libc/Jamfile.jam',
			'libc/lib/win32/release/libc.lib',
			'libc/obj/win32/release/vc.pdb',
			'libc/obj/win32/release/src/Loading/Loading.obj',
			'libc/obj/win32/release/src/Saving/Saving1.obj',
			'libc/obj/win32/release/src/Saving/Saving3.obj',
			'libc/obj/win32/release/src/Saving/SavingB.obj',
			'libc/obj/win32/release/src/integral/integral1.obj',
			'libc/obj/win32/release/src/integral/integral2.obj',
			'libc/obj/win32/release/src/memory/memorya.obj',
			'libc/obj/win32/release/src/memory/memoryb.obj',
			'libc/obj/win32/release/src/win32/Loading/Loading.obj',
			'libc/obj/win32/release/src/win32/Saving/Saving1.obj',
			'libc/obj/win32/release/src/win32/Saving/Saving3.obj',
			'libc/obj/win32/release/src/win32/Saving/SavingB.obj',
			'libc/src/Loading/Loading.cpp',
			'libc/src/Saving/Saving1.cpp',
			'libc/src/Saving/Saving3.cpp',
			'libc/src/Saving/SavingB.cpp',
			'libc/src/integral/integral1.cpp',
			'libc/src/integral/integral2.cpp',
			'libc/src/memory/memorya.cpp',
			'libc/src/memory/memoryb.cpp',
			'libc/src/win32/Loading/Loading.cpp',
			'libc/src/win32/Saving/Saving1.cpp',
			'libc/src/win32/Saving/Saving3.cpp',
			'libc/src/win32/Saving/SavingB.cpp',
			'outer/outer.cpp',
			'outerb/outer.cpp',
		}

		do
			local pattern = [[
*** found 88 target(s)...
*** updating 56 target(s)...
@ C.vc.C++ <win32!release:liba>rootfile.obj
!NEXT!@ C.vc.C++ <win32!release:liba>treea/treeb/deepfile.obj
!NEXT!@ C.vc.C++ <win32!release:liba>../outer/outer.obj
!NEXT!@ C.vc.Archive <win32!release:liba>liba.lib
!NEXT!@ C.vc.C++ <win32!release:libb>filea.obj
!NEXT!@ C.vc.C++ <win32!release:libb>onelevel/oneleveldeeper.obj
!NEXT!@ C.vc.C++ <win32!release:libb>../outerb/outer.obj
!NEXT!@ C.vc.Archive <win32!release:libb>libb.lib
!NEXT!@ C.vc.C++ <win32!release:libc>src/Loading/Loading.obj
!NEXT!@ C.vc.C++ <win32!release:libc>src/Saving/Saving1.obj
!NEXT!@ C.vc.C++ <win32!release:libc>src/memory/memorya.obj
!NEXT!@ C.vc.C++ <win32!release:libc>src/integral/integral1.obj
!NEXT!@ C.vc.C++ <win32!release:libc>src/win32/Loading/Loading.obj
!NEXT!@ C.vc.C++ <win32!release:libc>src/win32/Saving/Saving1.obj
!NEXT!@ C.vc.Archive <win32!release:libc>libc.lib
*** updated 27 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 88 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			RunJam{ 'clean' }
			TestDirectories(originalDirs)
			TestFiles(originalFiles)
		end
	else
		local dirs =
		{
			'liba/',
			'libb/',
			'libc/',
			'outer/',
			'outerb/',
			'liba/lib/',
			'liba/obj/',
			'liba/treea/',
			'liba/lib/$PlatformDir/',
			'liba/lib/$PlatformDir/release/',
			'liba/obj/$PlatformDir/',
			'liba/obj/$PlatformDir/release/',
			'liba/obj/$PlatformDir/release/__/',
			'liba/obj/$PlatformDir/release/treea/',
			'liba/obj/$PlatformDir/release/__/outer/',
			'liba/obj/$PlatformDir/release/treea/treeb/',
			'liba/treea/treeb/',
			'libb/lib/',
			'libb/obj/',
			'libb/onelevel/',
			'libb/lib/$PlatformDir/',
			'libb/lib/$PlatformDir/release/',
			'libb/obj/$PlatformDir/',
			'libb/obj/$PlatformDir/release/',
			'libb/obj/$PlatformDir/release/__/',
			'libb/obj/$PlatformDir/release/onelevel/',
			'libb/obj/$PlatformDir/release/__/outerb/',
			'libc/lib/',
			'libc/obj/',
			'libc/src/',
			'libc/lib/$PlatformDir/',
			'libc/lib/$PlatformDir/release/',
			'libc/obj/$PlatformDir/',
			'libc/obj/$PlatformDir/release/',
			'libc/obj/$PlatformDir/release/src/',
			'libc/obj/$PlatformDir/release/src/Loading/',
			'libc/obj/$PlatformDir/release/src/Saving/',
			'libc/obj/$PlatformDir/release/src/integral/',
			'libc/obj/$PlatformDir/release/src/memory/',
			'libc/src/Loading/',
			'libc/src/Saving/',
			'libc/src/integral/',
			'libc/src/memory/',
			'libc/src/win32/',
			'libc/src/win32/Loading/',
			'libc/src/win32/Saving/',
		}
	
		local files =
		{
			'Jamfile.jam',
			'Jamrules.jam',
			'test.lua',
			'liba/Jamfile.jam',
			'liba/rootfile.cpp',
			'liba/lib/$PlatformDir/release/liba.a',
			'liba/obj/$PlatformDir/release/rootfile.o',
			'liba/obj/$PlatformDir/release/__/outer/outer.o',
			'liba/obj/$PlatformDir/release/treea/treeb/deepfile.o',
			'liba/treea/treeb/deepfile.cpp',
			'libb/Jamfile.jam',
			'libb/filea.cpp',
			'libb/fileb.cpp',
			'libb/filec.cpp',
			'libb/lib/$PlatformDir/release/libb.a',
			'libb/obj/$PlatformDir/release/filea.o',
			'libb/obj/$PlatformDir/release/fileb.o',
			'libb/obj/$PlatformDir/release/filec.o',
			'libb/obj/$PlatformDir/release/__/outerb/outer.o',
			'libb/obj/$PlatformDir/release/onelevel/oneleveldeeper.o',
			'libb/onelevel/oneleveldeeper.cpp',
			'libc/Jamfile.jam',
			'libc/lib/$PlatformDir/release/libc.a',
			'libc/obj/$PlatformDir/release/src/Loading/Loading.o',
			'libc/obj/$PlatformDir/release/src/Saving/Saving1.o',
			'libc/obj/$PlatformDir/release/src/Saving/Saving3.o',
			'libc/obj/$PlatformDir/release/src/Saving/SavingB.o',
			'libc/obj/$PlatformDir/release/src/integral/integral1.o',
			'libc/obj/$PlatformDir/release/src/integral/integral2.o',
			'libc/obj/$PlatformDir/release/src/memory/memorya.o',
			'libc/obj/$PlatformDir/release/src/memory/memoryb.o',
			'libc/src/Loading/Loading.cpp',
			'libc/src/Saving/Saving1.cpp',
			'libc/src/Saving/Saving3.cpp',
			'libc/src/Saving/SavingB.cpp',
			'libc/src/integral/integral1.cpp',
			'libc/src/integral/integral2.cpp',
			'libc/src/memory/memorya.cpp',
			'libc/src/memory/memoryb.cpp',
			'libc/src/win32/Loading/Loading.cpp',
			'libc/src/win32/Saving/Saving1.cpp',
			'libc/src/win32/Saving/Saving3.cpp',
			'libc/src/win32/Saving/SavingB.cpp',
			'outer/outer.cpp',
			'outerb/outer.cpp',
		}

		do
			local pattern = [[
*** found 52 target(s)...
*** updating 32 target(s)...
@ C.C++ <liba>rootfile.o 
@ C.C++ <liba>treea/treeb/deepfile.o 
@ C.C++ <liba>../outer/outer.o 
@ C.Archive <liba>liba.a 
!NEXT!@ C.Ranlib <liba>liba.a 
!OOOGROUP!@ C.C++ <libb>filea.o 
!OOOGROUP!@ C.C++ <libb>fileb.o 
!OOOGROUP!@ C.C++ <libb>filec.o 
@ C.C++ <libb>onelevel/oneleveldeeper.o 
@ C.C++ <libb>../outerb/outer.o 
@ C.Archive <libb>libb.a 
!NEXT!@ C.Ranlib <libb>libb.a 
!OOOGROUP!@ C.C++ <libc>src/Saving/Saving1.o 
!OOOGROUP!@ C.C++ <libc>src/Saving/Saving3.o 
!OOOGROUP!@ C.C++ <libc>src/Saving/SavingB.o 
!OOOGROUP!@ C.C++ <libc>src/memory/memorya.o 
!OOOGROUP!@ C.C++ <libc>src/memory/memoryb.o 
!OOOGROUP!@ C.C++ <libc>src/integral/integral2.o 
!OOOGROUP!@ C.C++ <libc>src/integral/integral1.o 
!OOOGROUP!@ C.C++ <libc>src/Loading/Loading.o 
@ C.Archive <libc>libc.a 
!NEXT!@ C.Ranlib <libc>libc.a 
*** updated 32 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 52 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			RunJam{ 'clean' }
			TestDirectories(originalDirs)
			TestFiles(originalFiles)
		end
	end
end


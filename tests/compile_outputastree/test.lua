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
			'.build/',
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
			'libc/obj/$PlatformDir/release/src/win32/',
			'libc/obj/$PlatformDir/release/src/win32/Loading/',
			'libc/obj/$PlatformDir/release/src/win32/Saving/',
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
			'.build/.jamdepcache',
			'liba/Jamfile.jam',
			'liba/rootfile.cpp',
			'liba/lib/$PlatformDir/release/liba.lib',
			'liba/obj/$PlatformDir/release/rootfile.obj',
			'liba/obj/$PlatformDir/release/vc.pdb',
			'liba/obj/$PlatformDir/release/__/outer/outer.obj',
			'liba/obj/$PlatformDir/release/treea/treeb/deepfile.obj',
			'liba/treea/treeb/deepfile.cpp',
			'libb/Jamfile.jam',
			'libb/filea.cpp',
			'libb/fileb.cpp',
			'libb/filec.cpp',
			'libb/lib/$PlatformDir/release/libb.lib',
			'libb/obj/$PlatformDir/release/filea.obj',
			'libb/obj/$PlatformDir/release/fileb.obj',
			'libb/obj/$PlatformDir/release/filec.obj',
			'libb/obj/$PlatformDir/release/vc.pdb',
			'libb/obj/$PlatformDir/release/__/outerb/outer.obj',
			'libb/obj/$PlatformDir/release/onelevel/oneleveldeeper.obj',
			'libb/onelevel/oneleveldeeper.cpp',
			'libc/Jamfile.jam',
			'libc/lib/$PlatformDir/release/libc.lib',
			'libc/obj/$PlatformDir/release/vc.pdb',
			'libc/obj/$PlatformDir/release/src/Loading/Loading.obj',
			'libc/obj/$PlatformDir/release/src/Saving/Saving1.obj',
			'libc/obj/$PlatformDir/release/src/Saving/Saving3.obj',
			'libc/obj/$PlatformDir/release/src/Saving/SavingB.obj',
			'libc/obj/$PlatformDir/release/src/integral/integral1.obj',
			'libc/obj/$PlatformDir/release/src/integral/integral2.obj',
			'libc/obj/$PlatformDir/release/src/memory/memorya.obj',
			'libc/obj/$PlatformDir/release/src/memory/memoryb.obj',
			'libc/obj/$PlatformDir/release/src/win32/Loading/Loading.obj',
			'libc/obj/$PlatformDir/release/src/win32/Saving/Saving1.obj',
			'libc/obj/$PlatformDir/release/src/win32/Saving/Saving3.obj',
			'libc/obj/$PlatformDir/release/src/win32/Saving/SavingB.obj',
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
*** found 64 target(s)...
*** updating 38 target(s)...
@ C.vc.C++ <$(TOOLCHAIN_GRIST):liba>rootfile.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):liba>treea/treeb/deepfile.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):liba>../outer/outer.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):liba>liba.lib
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libb>filea.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libb>onelevel/oneleveldeeper.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libb>../outerb/outer.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libb>libb.lib
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/Loading/Loading.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/Saving/Saving1.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/integral/integral1.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/memory/memorya.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/win32/Loading/Loading.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/win32/Saving/Saving1.obj
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libc>libc.lib
*** updated 20 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 64 target(s)...
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
			'.build/',
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
*** found 54 target(s)...
*** updating 32 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):liba>rootfile.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):liba>treea/treeb/deepfile.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):liba>../outer/outer.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):liba>liba.a 
!NEXT!*** updated 8 target(s)...
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libb>filea.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libb>fileb.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libb>filec.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libb>onelevel/oneleveldeeper.o 
@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libb>../outerb/outer.o 
@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libb>libb.a 
!NEXT!*** updated 10 target(s)...
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/Loading/Loading.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/Saving/Saving1.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/Saving/Saving3.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/Saving/SavingB.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/integral/integral1.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/integral/integral2.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/memory/memorya.o 
!NEXT!@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):libc>src/memory/memoryb.o 
!NEXT!@ $(C_ARCHIVE) <$(TOOLCHAIN_GRIST):libc>libc.a 
!NEXT!*** updated 14 target(s)...
]]

			TestPattern(pattern, RunJam{ 'liba', 'libb', 'libc' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 54 target(s)...
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

TestChecksum = Test

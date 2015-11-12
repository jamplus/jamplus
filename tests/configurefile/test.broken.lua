function Test()
	local originalFiles =
	{
		"Jamfile.jam",
		"config.h.in",
		"main.c",
	}
	
	local originalDirs =
	{
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
			'.build/.depcache',
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
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/memory/memorya.obj
!NEXT!@ C.vc.C++ <$(TOOLCHAIN_GRIST):libc>src/integral/integral1.obj
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
			'$(TOOLCHAIN_PATH)/test/',
		}
	
		local files =
		{
			'Jamfile.jam',
			'config.h.in',
			'main.c',
			'$(TOOLCHAIN_PATH)/test/config.h',
			'$(TOOLCHAIN_PATH)/test/main.o',
			'$(TOOLCHAIN_PATH)/test/test.release',
		}

		do
			local pattern = [[
*** found 9 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o
@ $(C.LINK) <$(TOOLCHAIN_GRIST):test>test
@ RunExecutable <$(TOOLCHAIN_GRIST):test>test
Built for platform $(PLATFORM)
*** updated 2 target(s)...
]]

			TestPattern(pattern, RunJam{})
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
]]

			TestPattern(pattern, RunJam{})
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o
@ $(C.LINK) <$(TOOLCHAIN_GRIST):test>test
@ RunExecutable <$(TOOLCHAIN_GRIST):test>test
Built for platform $(PLATFORM)
This is awesome!
*** updated 2 target(s)...
]]

			osprocess.sleep(1)
			TestPattern(pattern, RunJam{ 'IS_AWESOME=1' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
]]

			TestPattern(pattern, RunJam{ 'IS_AWESOME=1' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o
@ $(C.LINK) <$(TOOLCHAIN_GRIST):test>test
@ RunExecutable <$(TOOLCHAIN_GRIST):test>test
Built for platform $(PLATFORM)
This is not awesome... :(
*** updated 2 target(s)...
]]

			osprocess.sleep(1)
			TestPattern(pattern, RunJam{ 'IS_NOT_AWESOME=1' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
]]

			TestPattern(pattern, RunJam{ 'IS_NOT_AWESOME=1' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
*** updating 2 target(s)...
@ C.$(COMPILER).CC <$(TOOLCHAIN_GRIST):test>main.o
@ $(C.LINK) <$(TOOLCHAIN_GRIST):test>test
@ RunExecutable <$(TOOLCHAIN_GRIST):test>test
Built for platform $(PLATFORM)
This is awesome!
This is not awesome... :(
*** updated 2 target(s)...
]]

			osprocess.sleep(1)
			TestPattern(pattern, RunJam{ 'IS_AWESOME=1', 'IS_NOT_AWESOME=1' })
			TestDirectories(dirs)
			TestFiles(files)
		end

		---------------------------------------------------------------------------
		do
			local pattern = [[
*** found 9 target(s)...
]]

			TestPattern(pattern, RunJam{ 'IS_AWESOME=1', 'IS_NOT_AWESOME=1' })
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


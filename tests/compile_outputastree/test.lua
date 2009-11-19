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
*** found 86 target(s)...
*** updating 56 target(s)...
@ C.C++ <liba>rootfile.obj
rootfile.cpp
@ C.C++ <liba>treea/treeb/deepfile.obj
deepfile.cpp
@ C.C++ <liba>__/outer/outer.obj
outer.cpp
@ C.Archive <liba>liba.lib
@ C.C++ <libb>filea.obj
filea.cpp
fileb.cpp
filec.cpp
Generating Code...
@ C.C++ <libb>onelevel/oneleveldeeper.obj
oneleveldeeper.cpp
@ C.C++ <libb>__/outerb/outer.obj
outer.cpp
@ C.Archive <libb>libb.lib
@ C.C++ <libc>src/Loading/Loading.obj
Loading.cpp
@ C.C++ <libc>src/Saving/Saving1.obj
Saving1.cpp
Saving3.cpp
SavingB.cpp
Generating Code...
@ C.C++ <libc>src/memory/memorya.obj
memorya.cpp
memoryb.cpp
Generating Code...
@ C.C++ <libc>src/integral/integral1.obj
integral1.cpp
integral2.cpp
Generating Code...
@ C.C++ <libc>src/win32/Loading/Loading.obj
Loading.cpp
@ C.C++ <libc>src/win32/Saving/Saving1.obj
Saving1.cpp
Saving3.cpp
SavingB.cpp
Generating Code...
@ C.Archive <libc>libc.lib
*** updated 56 target(s)...
]]

		TestPattern(pattern, RunJam{})
		TestDirectories(dirs)
		TestFiles(files)
	end

	---------------------------------------------------------------------------
	do
		local pattern = [[
*** found 86 target(s)...
]]

		TestPattern(pattern, RunJam{})
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


local originalFiles = {
	'Jamfile.jam',
	'main.cpp',
	'mypch.cpp',
	'includes/mypch.h',
	'includes/usefuldefine.h',
}

local originalDirs = {
	'includes/',
}

local pass1Directories
local pass1Files
if Platform == 'win32' and not Compiler then
	pass1Directories = {
		'includes/',
		'$(TOOLCHAIN_PATH)/',
		'$(TOOLCHAIN_PATH)/main/',
	}

	pass1Files = {
		'Jamfile.jam',
		'main.cpp',
		'mypch.cpp',
		'includes/mypch.h',
		'includes/usefuldefine.h',
		'$(TOOLCHAIN_PATH)/main/main.obj',
		'$(TOOLCHAIN_PATH)/main/main.exe',
		'?$(TOOLCHAIN_PATH)/main/main.exe.intermediate.manifest',
		'$(TOOLCHAIN_PATH)/main/main.pdb',
		'$(TOOLCHAIN_PATH)/main/mypch.h.pch',
		'$(TOOLCHAIN_PATH)/main/mypch.obj',
	}

	pass1Pattern = [[
		*** found 21 target(s)...
		*** updating 5 target(s)...
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.obj
		mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.obj
		main.cpp
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main.exe
		!NEXT!*** updated 5 target(s)...
]]

	pass2Pattern = [[
		*** found 21 target(s)...
		*** updating 4 target(s)...
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.obj
		mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.obj
		main.cpp
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main.exe
		!NEXT!*** updated 4 target(s)...
]]

	pass2Pattern_useChecksums = [[
		*** found 21 target(s)...
		*** updating 4 target(s)...
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.obj
		mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.obj
		main.cpp
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main.exe
		!NEXT!*** updated 3 target(s)...
]]
elseif Compiler == 'mingw' then
	pass1Directories = {
		'includes/',
		'mypch%-%x+/',
	}

	pass1Files = {
		'Jamfile.jam',
		'main.cpp',
		'main.o',
		'main.exe',
		'mypch.cpp',
		'mypch.o',
		'test.lua',
		'includes/mypch.h',
		'includes/usefuldefine.h',
		'mypch%-%x+/mypch.h.gch',
	}

	pass1Pattern = [[
		*** found 14 target(s)...
		*** updating 5 target(s)...
		&@ C.PCH <main%-%x+>mypch.h.gch
		@ C.C++ <main>main.o 
		@ C.C++ <main>mypch.o 
		@ C.Link <main>main.exe
		*** updated 5 target(s)...
]]

	pass2Pattern = [[
		*** found 14 target(s)...
		*** updating 5 target(s)...
		&@ C.PCH <main%-%x+>mypch.h.gch
		@ C.C++ <main>main.o 
		@ C.C++ <main>mypch.o 
		@ C.Link <main>main.exe
		*** updated 5 target(s)...
]]
else
	pass1Directories = {
		'includes/',
		'$(TOOLCHAIN_PATH)/',
		'$(TOOLCHAIN_PATH)/main/',
		'$(TOOLCHAIN_PATH)/main/mypch%-%x+/',
	}

	pass1Files = {
		'Jamfile.jam',
		'main.cpp',
		'mypch.cpp',
		'test.lua',
		'includes/mypch.h',
		'includes/usefuldefine.h',
		'$(TOOLCHAIN_PATH)/main/main.o',
		'$(TOOLCHAIN_PATH)/main/main',
		'$(TOOLCHAIN_PATH)/main/mypch.o',
		'$(TOOLCHAIN_PATH)/main/mypch%-%x+/mypch.h.gch',
	}

	pass1Pattern = [[
		*** found 15 target(s)...
		*** updating 6 target(s)...
		&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):main%-%x+>mypch.h.gch
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.o 
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main
		*** updated 6 target(s)...
]]

	pass2Pattern = [[
		*** found 15 target(s)...
		*** updating 4 target(s)...
		&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):main%-%x+>mypch.h.gch
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.o 
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main
		*** updated 4 target(s)...
]]
end


function Test()
	-- Test for a clean directory.
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	TestPattern(pass1Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2
	if Platform == 'win32' and Compiler ~= 'mingw' then
		pattern2 = [[
*** found 21 target(s)...
]]
	else
		pattern2 = [[
*** found 15 target(s)...
]]
	end
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	osprocess.sleep(1)
	ospath.touch('includes/usefuldefine.h')
	TestPattern(pass2Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function TestChecksum()
	local function WriteOriginalFiles()
		ospath.write_file('includes/usefuldefine.h', [[
#ifndef USEFULDEFINE_H
#define USEFULDEFINE_H

#define USEFUL_DEFINE 10

#endif
]])
	end

	local function WriteModifiedFiles()
		ospath.write_file('includes/usefuldefine.h', [[
#ifndef USEFULDEFINE_H
#define USEFULDEFINE_H

#define USEFUL_DEFINE 20

#endif
]])
	end

	-- Test for a clean directory.
	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestDirectories(originalDirs)
	TestFiles(originalFiles)

	---------------------------------------------------------------------------
	TestPattern(pass1Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	local pattern2
	if Platform == 'win32' and Compiler ~= 'mingw' then
		pattern2 = [[
*** found 23 target(s)...
]]
	else
		pattern2 = [[
*** found 15 target(s)...
]]
	end
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	if useChecksums then
		pattern2 = [[
*** found 22 target(s)...
*** updating 4 target(s)...
*** updated 0 target(s)...
]]
	end
	osprocess.sleep(1)
	ospath.touch('includes/usefuldefine.h')
	TestPattern(pattern2, RunJam{})

	osprocess.sleep(1)
	WriteModifiedFiles()
	TestPattern(useChecksums  and  pass2Pattern_useChecksums  or  pass2Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
		pattern2 = [[
*** found 22 target(s)...
]]
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

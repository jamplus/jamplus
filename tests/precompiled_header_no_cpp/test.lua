local originalFiles = {
	'Jamfile.jam',
	'main.cpp',
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
		'includes/mypch.h',
		'includes/usefuldefine.h',
		'$(TOOLCHAIN_PATH)/main/main.obj',
		'$(TOOLCHAIN_PATH)/main/main.release.exe',
		'?$(TOOLCHAIN_PATH)/main/main.release.exe.intermediate.manifest',
		'$(TOOLCHAIN_PATH)/main/main.release.pdb',
		'$(TOOLCHAIN_PATH)/main/mypch.cpp',
		'$(TOOLCHAIN_PATH)/main/mypch.h.pch',
		'$(TOOLCHAIN_PATH)/main/mypch.obj',
	}

	pass1Pattern = [[
		*** found 21 target(s)...
		*** updating 6 target(s)...
		@ WriteFile <$(TOOLCHAIN_GRIST):main>includes/mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.h.pch
		mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.obj
		main.cpp
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main.exe
		!NEXT!*** updated 6 target(s)...
]]

	pass2Pattern = [[
		*** found 21 target(s)...
		*** updating 4 target(s)...
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>mypch.h.pch
		mypch.cpp
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.obj
		main.cpp
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main.exe
		!NEXT!*** updated 4 target(s)...
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
		'main.release.exe',
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
		@ C.Link <main>main.release.exe
		*** updated 5 target(s)...
]]

	pass2Pattern = [[
		*** found 14 target(s)...
		*** updating 5 target(s)...
		&@ C.PCH <main%-%x+>mypch.h.gch
		@ C.C++ <main>main.o 
		@ C.C++ <main>mypch.o 
		@ C.Link <main>main.release.exe
		*** updated 5 target(s)...
]]
else
	pass1Directories = {
		'includes/',
		'$(TOOLCHAIN_PATH)/',
		'$(TOOLCHAIN_PATH)/main/',
		'.build/$(PLATFORM_CONFIG)/TOP/main/mypch%-%x+/',
	}

	pass1Files = {
		'Jamfile.jam',
		'main.cpp',
		'test.lua',
		'includes/mypch.h',
		'includes/usefuldefine.h',
		'$(TOOLCHAIN_PATH)/main/main.o',
		'$(TOOLCHAIN_PATH)/main/main.release',
		'.build/$(PLATFORM_CONFIG)/TOP/main/mypch%-%x+/mypch.h.gch',
	}

	pass1Pattern = [[
		*** found 13 target(s)...
		*** updating 5 target(s)...
		&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):main%-%x+>mypch.h.gch
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main
		*** updated 5 target(s)...
]]

	pass2Pattern = [[
		*** found 13 target(s)...
		*** updating 3 target(s)...
		&@ C.$(COMPILER).PCH <$(TOOLCHAIN_GRIST):main%-%x+>mypch.h.gch
		@ C.$(COMPILER).C++ <$(TOOLCHAIN_GRIST):main>main.o 
		@ $(C_LINK) <$(TOOLCHAIN_GRIST):main>main
		*** updated 3 target(s)...
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
*** found 13 target(s)...
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
*** found 21 target(s)...
]]
	else
		pattern2 = [[
*** found 13 target(s)...
]]
	end
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)
	
	---------------------------------------------------------------------------
	osprocess.sleep(1)
	ospath.touch('includes/usefuldefine.h')
	TestPattern(pattern2, RunJam{})

	osprocess.sleep(1)
	WriteModifiedFiles()
	TestPattern(pass2Pattern, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	TestPattern(pattern2, RunJam{})
	TestDirectories(pass1Directories)
	TestFiles(pass1Files)

	---------------------------------------------------------------------------
	WriteOriginalFiles()
	RunJam{ 'clean' }
	TestFiles(originalFiles)
	TestDirectories(originalDirs)
end

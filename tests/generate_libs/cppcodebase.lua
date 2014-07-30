local ospath = require 'ospath'

module('cppcodebase', package.seeall)

function SetDir(dir)
    if not ospath.exists(dir) then
        ospath.mkdir(dir .. '/')
	end
    ospath.chdir(dir)
end


function lib_name(i)
    return "lib_" .. i
end

function CreateHeader(lib, name)
    local filename = name .. ".h"
    local handle = io.open(filename, "w")

    local guard = lib .. '_' .. name .. '_h_'
    handle:write ('#ifndef ' .. guard .. '\n')
    handle:write ('#define ' .. guard .. '\n\n')
    
	local class = lib .. '_' .. name
    handle:write ('class ' .. class .. ' {\n')
    handle:write ('public:\n')
    handle:write ('    ' .. class .. '();\n')
    handle:write ('    ~' .. class .. '();\n')
    handle:write ('};\n\n')
    
    handle:write ('#endif\n')
end

function lotto(count, range)
	function PositiveIntegers() return setmetatable({}, { __index = function(self, k) return k end }) end

	function permute(tab, n, count)
		n = n or #tab
		for i = 1, count or n do
			local j = math.random(i, n)
			tab[i], tab[j] = tab[j], tab[i]
		end
		return tab
	end

	return {unpack(
				permute(PositiveIntegers(), range, count),
				1, count)
			}
end


function CreateCPP(lib, name, lib_number, classes_per_lib, internal_includes, external_includes)
    local filename = name .. ".cpp"
    local handle = io.open(filename, "w" )
    
    local header= name .. ".h"
    handle:write ('#include "' .. header .. '"\n')
    
    local includes = lotto(internal_includes, classes_per_lib - 1)
    for _, i in ipairs(includes) do
        handle:write ('#include "class_' .. i .. '.h"\n')
	end

    if lib_number > 0 then
        includes = lotto(external_includes, classes_per_lib - 1)
        for _, i in ipairs(includes) do
            libname = 'lib_' .. math.random(0, lib_number)
            handle:write ('#include <' .. libname .. '/' .. 'class_' .. i .. '.h>\n')
		end
	end
    
    handle:write ('\n')
	local class = lib .. '_' .. name
    handle:write (class .. '::' .. class .. '() {}\n')
    handle:write (class .. '::~' .. class  .. '() {}\n')
end


function CreateLibrary(lib_number, classes, internal_includes, external_includes)
	local lib = lib_name(lib_number)
    SetDir(lib) 
	print('-> Writing ' .. lib .. '...')
    for i = 0, classes - 1 do
        classname = "class_" .. i
        CreateHeader(lib, classname)
        CreateCPP(lib, classname, lib_number, classes, internal_includes, external_includes)
	end
    ospath.chdir("..")
end


function CreateSetOfLibraries(libs, classes, internal_includes, external_includes, myfunction)
    math.randomseed(12345)
    for i = 0, libs - 1 do
        CreateLibrary(i, classes, internal_includes, external_includes)
        myfunction(i, classes)
	end
end

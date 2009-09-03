require 'cppcodebase'
require 'jam'
require 'jamplus'


HELP_USAGE = [[Usage: generate_libs.lua root libs classes internal external.
    root     - Root directory where to create libs.
    libs     - Number of libraries (libraries only depend on those with smaller numbers)
    classes  - Number of classes per library
    internal - Number of includes per file referring to that same library
    external - Number of includes per file pointing to other libraries
]]


if #arg ~= 5 then
	print(HELP_USAGE)
	return
end

root_dir = arg[1]
libs = tonumber(arg[2])
classes = tonumber(arg[3])
internal_includes = tonumber(arg[4])
external_includes = tonumber(arg[5])

cppcodebase.SetDir(root_dir)
jam.CreateCodebase(libs, classes, internal_includes, external_includes)
jamplus.CreateCodebase(libs, classes, internal_includes, external_includes, false)
jamplus.CreateCodebase(libs, classes, internal_includes, external_includes, true)

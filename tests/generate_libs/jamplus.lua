module('jamplus', package.seeall)

function CreateLibJamfileHelper(lib_number, classes, lump)
    os.chdir(cppcodebase.lib_name(lib_number))
    local handle = io.open("Jamfile.jam", "w")
    handle:write("SubDir TOP lib_" .. lib_number .. " ;\n\n")
	handle:write("SRCS =\n")
    for i = 0, classes - 1 do
        handle:write('        class_' .. i .. '.cpp\n')
	end
	handle:write(';\n\n')

	if lump then
		handle:write("C.Lump lib_" .. lib_number .. " : SRCS : lib_" .. lib_number .. " ;\n")
	end

    handle:write("C.Library lib_" .. lib_number .. " : $(SRCS) ;\n")
    handle:write("Depends all : lib_" .. lib_number .. " ;\n")
    os.chdir('..')
end


function CreateLibJamfileNoLump(lib_number, classes)
	CreateLibJamfileHelper(lib_number, classes, false)
end


function CreateLibJamfileLump(lib_number, classes)
	CreateLibJamfileHelper(lib_number, classes, true)
end


function CreateFullJamfile(libs)
    local handle = io.open("Jamfile.jam", "w")
    handle:write ("SubDir TOP ;\n\n")

    for i = 0, libs - 1 do
        handle:write('SubInclude TOP ' .. cppcodebase.lib_name(i) .. ' ;\n')
	end

    handle:write('\nWorkspace GeneratedLibs :\n')
    for i = 0, libs - 1 do
        handle:write('\t\t' .. cppcodebase.lib_name(i) .. '\n')
	end
    handle:write(';\n')

    handle = io.open("Jamrules.jam", "w")
	handle:write('DEPCACHE.standard = .jamcache ;\n')
	handle:write('DEPCACHE = standard ;\n')
    handle:write ('INCLUDES = $(TOP) ;\n')
    handle:write ('C.IncludeDirectories * : $(TOP) ;\n')
end


function CreateCodebase(libs, classes, internal_includes, external_includes, lump)
    cppcodebase.SetDir(lump and 'jamplus-lump' or 'jamplus')
    cppcodebase.CreateSetOfLibraries(libs, classes, internal_includes, external_includes, lump and CreateLibJamfileLump or CreateLibJamfileNoLump)
    CreateFullJamfile(libs, lump)
    os.chdir('..')
end



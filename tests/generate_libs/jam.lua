module('jam', package.seeall)

function CreateLibJamfile(lib_number, classes)
    os.chdir(cppcodebase.lib_name(lib_number)) 
    local handle = io.open("Jamfile", "w")
    handle:write ("SubDir TOP lib_" .. lib_number .. " ;\n\n")
    handle:write ("SubDirHdrs $(INCLUDES) ;\n\n")
    handle:write ("Library lib_" .. lib_number .. " :\n")
    for i = 0, classes - 1 do
        handle:write('    class_' .. i .. '.cpp\n')
	end
    handle:write ('    ;\n')
    os.chdir('..')
end


function CreateFullJamfile(libs)
    local handle = io.open("Jamfile", "w")
    handle:write ("SubDir TOP ;\n\n")
    
    for i = 0, libs - 1 do
        handle:write('SubInclude TOP ' .. cppcodebase.lib_name(i) .. ' ;\n')
	end
        
    handle = io.open("Jamrules", "w")
    handle:write ('INCLUDES = $(TOP) ;\n')
end
    
    
function CreateCodebase(libs, classes, internal_includes, external_includes)
    cppcodebase.SetDir('jam')
    cppcodebase.CreateSetOfLibraries(libs, classes, internal_includes, external_includes, CreateLibJamfile)
    CreateFullJamfile(libs)
	
	local handle = io.open('jam.bat', 'wt');
	handle:write('jam.exe -f ../../Jambase')
    os.chdir('..')
end

local osprocess = require 'osprocess'
local ospath = require 'ospath'
local miniz = require 'miniz'
local filefind = require 'filefind'

local argIndex = 1
local outputDirectory = arg[argIndex]
argIndex = argIndex + 1

if not outputDirectory then
    outputDirectory = '.' --JAM_EXECUTABLE_PATH
end

function MirrorExtractZip(archive, outputDirectory)
    local outputDirectoryEntries = {}
    for entry in filefind.glob(ospath.join(outputDirectory, '**@*')) do
        outputDirectoryEntries[entry.filename] = entry.write_time
    end

    for index = 1, archive:get_num_files() do
        local entry = archive:stat(index)
        local entryFilename = entry.filename
        if entry.filename:sub(-1) ~= '/' then
            local fullOutputFilename = ospath.join(outputDirectory, entry.filename)
            if outputDirectoryEntries[fullOutputFilename] then
                print('Refusing to overwrite ' .. entry.filename)
                error()
            end
        end
    end

    for index = 1, archive:get_num_files() do
        local entry = archive:stat(index)
        local entryFilename = entry.filename
        if entry.filename:sub(-1) ~= '/' then
            local fullOutputFilename = ospath.join(outputDirectory, entry.filename)
            if outputDirectoryEntries[fullOutputFilename] ~= entry.time then
                --print('Extracting ' .. entry.filename)
                ospath.mkdir(fullOutputFilename)
                archive:extract_to_file(entry.filename, fullOutputFilename)
                ospath.touch(fullOutputFilename, entry.time)
            end
            outputDirectoryEntries[fullOutputFilename] = nil
            local components = {}
            for component in fullOutputFilename:gmatch('[^/]+') do
                components[#components + 1] = component
                outputDirectoryEntries[table.concat(components, '/') .. '/'] = nil
            end
        end
    end
    archive:close()

    for filename in pairs(outputDirectoryEntries) do
        print('Removing ' .. filename)
        --ospath.remove(filename)
    end
end

MirrorExtractZip(jam_zip_attemptopen(), outputDirectory)


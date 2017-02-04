local filefind = require 'filefind'
local ospath = require 'ospath'

local jamfileJamFilename = 'Jamfile.jam'
if ospath.exists(jamfileJamFilename) then
    print('The file Jamfile.jam is already present and will not be overwritten.')
    return
end

local jamfileLuaFilename = 'Jamfile.lua'
if ospath.exists(jamfileLuaFilename) then
    print('The file Jamfile.lua is already present and will not be overwritten.')
    return
end

print('Writing ' .. jamfileJamFilename .. '...')
local file = io.open(jamfileJamFilename, 'wb')
file:write('C.Application app : *.c *.cpp ;\n')
file:close()

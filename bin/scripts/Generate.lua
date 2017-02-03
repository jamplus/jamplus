local filefind = require 'filefind'
local ospath = require 'ospath'

local jamfileFilename = 'Jamfile.jam'
if ospath.exists(jamfileFilename) then
    return
end

local file = io.open(jamfileFilename, 'wb')
file:write('C.Application app : *.c *.cpp ;\n')
file:close()
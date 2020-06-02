local miniz = require "miniz"
local fs = require "path.fs"

local za = miniz.zip_write_file "lua-miniz.zip"
za:add_file "lminiz.c"
za:add_file "miniz.c"
za:add_file "lua.exe"
za:add_file "lua53.dll"
za:add_file "miniz.dll"
za:add_file "zlib.dll"
za:add_file "path.dll"
za:add_file "test.lua"
za:add_file "xlsx.lua"
za:add_file "test_flate.lua"
za:add_file "test_xlsx.lua"
for file in fs.dir("xlsxwriter") do
   za:add_file("xlsxwriter/"..file)
end
za:finalize()
za:close()

local za = assert(miniz.zip_read_file "lua-miniz.zip")
print(#za)
for _, file in ipairs(za) do
   print(file)
end
print(za:extract "test.lua")
za:close()


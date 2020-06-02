local miniz = require "miniz"
local zlib = require "zlib"

local fh = assert(io.open "miniz.c")
local content = fh:read "*a"
fh:close()


print(#content)

print("test zlib")
local data1 = zlib.deflate()(content, "finish")
print(#data1)
local out1 = zlib.inflate()(data1)
assert(out1 == content)

print("test miniz-zlib-header")
local data2 = miniz.deflate(content)
print(#data2)
local out2 = miniz.inflate(data1)
assert(out2 == content)

print("test miniz-without-zlib-header")
local data3 = miniz.compress(content)
print(#data3)
local out3 = miniz.decompress(data3)
assert(out3 == content)

print("test miniz->zlib")
local data4 = miniz.deflate(content)
print(#data4)
local out4 = zlib.inflate()(data4)
assert(out4 == content)

print("test zlib->miniz")
local data5 = zlib.deflate()(content, "finish")
print(#data5)
local out5 = miniz.inflate(data5)
assert(out5 == content)




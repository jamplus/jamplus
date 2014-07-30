local md5 = require 'md5'
local struct = require 'struct'

function md5png(filename)
	jam_print("md5png: Calculating " .. filename .. "...")
	local file = io.open(filename, 'rb')
	if not file then return nil end

	file:seek('cur', 8)

	local md5sum = md5.new()
	local offset
	while true do
		local length = struct.unpack('>I', file:read(4))
		local chunkType = file:read(4)
		if chunkType == 'IEND' then break end
		file:seek('cur', length)
		local crc = file:read(4)
		md5sum:update(crc)
	end

	return md5sum:digest(true)
end


if arg and arg[1] then
	md5png(arg[1])
end

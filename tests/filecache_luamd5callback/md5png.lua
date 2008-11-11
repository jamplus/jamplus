require 'md5'

function md5png(filename)
	print("md5png: Calculating " .. filename .. "...")
	local file = io.open(filename, 'rb')
	if not file then return nil end

	file:seek('cur', 8)

	local md5sum = md5.new()
	local offset
	while true do
		local length = select(2, string.unpack(file:read(4), '>I'))
		local chunkType = file:read(4)
		if chunkType == 'IEND' then break end
		file:seek('cur', length)
		local crc = file:read(4)
		md5sum:update(crc)
	end

	return md5sum:digest(true)
end


if arg then
	md5png(arg[1])
end

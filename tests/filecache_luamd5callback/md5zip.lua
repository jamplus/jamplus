function md5zip(filename)
	jam_print("md5zip: Calculating " .. filename .. "...")

	local md5 = require 'md5'
	local struct = require 'struct'
	local ziparchive = require 'ziparchive'

	local archive = ziparchive.open(filename)
	if not archive then
		return nil
	end

	local md5sum = md5.new()
	for index = 1, archive:fileentrycount() do
		local fileEntry = archive:fileentry(index)
		md5sum:update(struct.pack('c' .. tostring(fileEntry.filename:len()), fileEntry.filename))
		md5sum:update(struct.pack('I4', fileEntry.crc))
	end

	archive:close()

	return md5sum:digest(true)
end

if arg and arg[1] then
	md5zip(arg[1])
end

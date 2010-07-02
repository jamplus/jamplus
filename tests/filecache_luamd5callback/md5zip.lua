function md5zip(filename)
	print("md5zip: Calculating " .. filename .. "...")

	require 'md5'
	require 'ziparchive'

	local archive = ziparchive.open(filename)
	if not archive then
		return nil
	end

	local md5sum = md5.new()
	for index = 1, archive:fileentrycount() do
		local fileEntry = archive:fileentry(index)
		md5sum:update(string.pack('A', fileEntry.filename))
		md5sum:update(string.pack('I', fileEntry.crc))
	end

	archive:close()

	return md5sum:digest(true)
end

if arg and arg[1] then
	md5zip(arg[1])
end

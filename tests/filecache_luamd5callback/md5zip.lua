function md5zip(filename)
	require 'md5'
	require 'vdrive'

	local drive = vdrive.VirtualDrive()
	if not drive:Open(filename) then
		return nil
	end

	local md5sum = md5.new()
	for index = 1, drive:GetFileEntryCount() do
		local fileEntry = drive:GetFileEntry(index)
		md5sum:update(string.pack('A', fileEntry.FileName))
		md5sum:update(string.pack('I', fileEntry.CRC))
	end

	drive:Close()

	return md5sum:digest(true)
end

if arg then
	md5zip(arg[1])
end

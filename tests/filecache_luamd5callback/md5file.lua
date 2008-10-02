require 'md5'

function md5file(filename)
	local md5sum = md5.new()
	md5sum:updatefile(filename)
	return md5sum:digest(true)
end

if arg then
	md5file(arg[1])
end

local md5 = require 'md5'

function md5file(filename)
	local md5sum = md5.new()
	md5sum:updatefile(filename)
	return md5sum:digest(true)
end

if arg and arg[1] then
	md5file(arg[1])
end

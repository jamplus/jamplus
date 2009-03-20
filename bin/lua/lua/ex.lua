module(..., package.seeall)

require 'ex.core'

-- ex.popen
function ex.popen(args)
	local out_rd, out_wr = io.pipe()
	args.stdout = out_wr
	local proc, err = os.spawn(args)
	out_wr:close()
	if not proc then
		out_rd:close()
		return proc, err
	end
	return proc, out_rd
end

-- ex.lines
function ex.lines(args)
	local proc, input = popen(args)
	return function()
		local line = input:read("*l")
		if line then return line end
		input:close()
		proc:wait()
	end
end

-- ex.popen2()
function ex.popen2(args)
	local in_rd, in_wr = io.pipe()
	local out_rd, out_wr = io.pipe()
	args.stdin = in_rd
	args.stdout = out_wr
	local proc, err = os.spawn(args)
	in_rd:close(); out_wr:close()
	if not proc then
		in_wr:close(); out_rd:close()
		return proc, err
	end
	return proc, out_rd, in_wr
end



local osprocess = require 'osprocess'

print("Beginning tests...")

logfile = io.open('output/test.log', 'wb')
if not logfile then
	print("* Unable to open output/test.log.")
	error()
end

print("Test A")
for line in osprocess.lines{ ADD_EXE, 4 } do
	if line:sub(1, 6) ~= 'Usage:' then
		logfile:write("Test A failed.\n")
		logfile:close()
		return 1
	end
	break
end
logfile:write("Test A succeeded.\n")

print("Test B")
for line in osprocess.lines{ ADD_EXE, 4, 6 } do
	if line ~= '100' then
		print("Failed test Add 4 + 6 = 10")
		logfile:write("Test B failed.\n")
		logfile:close()
		return 1
	end
	break
end
logfile:write("Test A succeeded.\n")
logfile:close()

return 0

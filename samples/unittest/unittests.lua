require 'ex'

print("Test A")
for line in ex.lines{ ADD_EXE, 4 } do
	if line:sub(1, 6) ~= 'Usage:' then return 1 end
	break
end

print("Test B")
for line in ex.lines{ ADD_EXE, 4, 6 } do
	if line ~= '100' then
		print("Failed test Add 4 + 6 = 10")
		return 1
	end
	break
end

return 0

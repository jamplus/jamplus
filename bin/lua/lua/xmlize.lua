-- Loosely based on a PHP implementation.
local lom = require "lxp.lom"

function string.split(s, sep)
	local ret = {}
	if s == '' then return ret end
	s = s..sep
	for cap in string.gmatch(s, '(.-)'..sep) do
		table.insert(ret, cap)
	end
	return ret
end

local function xml_depth(vals)
	local valCount = #vals
	if valCount == 1  and  type(vals[1]) ~= 'table' then
		return vals[1]
	end

	local children = {}

	for i = 1, #vals do
		local val = vals[i]
		if type(val) == "table" then
			children[#children + 1] = val.tag
			local tagEntry = children[val.tag]
			if not tagEntry then
				tagEntry = {}
				children[val.tag] = tagEntry
			end

			entry = {}
			tagEntry[#tagEntry + 1] = entry

			entry['@'] = val.attr
			entry['#'] = xml_depth(val)
		else
			children[#children + 1] = val
		end
	end

	return children
end


function xmlize(data)
	data = data:gsub('<%?xml.-%?>(.+)', "%1")
	data = '<root>' .. data .. '</root>'

	local vals, err = lom.parse(data)

    array = xml_depth(vals);

	return array
end



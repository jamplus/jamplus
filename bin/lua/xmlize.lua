local M = {}

------------------------------------------------------------
-- xmlize (from lminiz)

local function parseargs(s, arg)
   arg = arg or {}
   string.gsub(s, "([%-%w]+)=([\"'])(.-)%2", function (w, _, a)
      arg[w] = a
   end)
   return arg
end

local function collect(s)
   local stack = {}
   local top = {}
   table.insert(stack, top)
   local i = 1
   while true do
      local ni,j,c,label,xarg, empty = string.find(s, "<(%/?)([%w:]+)(.-)(%/?)>", i)
      if not ni then break end
      local text = string.sub(s, i, ni-1)
      if not string.find(text, "^%s*$") then
         table.insert(top, text)
      end
      if empty == "/" then  -- empty element tag
         table.insert(top, parseargs(xarg, {tag=label}))
      elseif c == "" then   -- start tag
         top = parseargs(xarg, {tag=label})
         table.insert(stack, top)   -- new level
      else  -- endtag
         local toclose = table.remove(stack)  -- remove top
         top = stack[#stack]
         if #stack < 1 then
            error("nothing to close with "..label)
         end
         if toclose.tag ~= label then
            error("trying to close "..toclose.tag.." with "..label)
         end
         table.insert(top, toclose)
      end
      i = j+1
   end
   local text = string.sub(s, i)
   if not string.find(text, "^%s*$") then
      table.insert(stack[#stack], text)
   end
   if #stack > 1 then
      error("unclosed "..stack[#stack].label)
   end
   if type(stack[1][1]) == "string" then
      table.remove(stack[1], 1)
   end
   return stack[1][1]
end

local function xmlparse(t)
   local count = #t
   if count == 1 and type(t[1]) ~= 'table' then
      return t[1]
   end

   local order = {}
   local children = { ['*'] = order }
   for i = 1, count do local v = t[i]
      if type(v) == "table" then
         children[#children + 1] = v.tag
         local et = children[v.tag]
         if not et then et = {}; children[v.tag] = et end

         local attr = {}
         for k, vv in pairs(v) do
            if type(k) == "string" then
               attr[k] = vv
            end
         end

         local entry = {}
         et[#et+1] = entry
         order[#order+1] = { v.tag, v }

         entry['@'] = attr
         entry['#'] = xmlparse(v)
      else
         children[#children + 1] = v
      end
   end

   return children
end

function M.luaize(buffer)
    if not buffer then return xmlparse {} end
    return xmlparse {
        tag = "root",
        collect(buffer),
    }
end


---------------------------------------------------------------------------------
-- Encoding routines stolen from Lua Element Tree.
local mapping = { ['&']  = "&amp;"  ,
                  ['<']  = "&lt;"   ,
                  ['>']  = "&gt;"   ,
                  ['"']  = "&quot;" ,
                  ["'"]  = "&apos;" , -- not used
                  ["\t"] = "&#9;"    ,
                  ["\r"] = "&#13;"   ,
                  ["\n"] = "&#10;"   }

local function map(symbols)
  local array = {}
  for _, symbol in ipairs(symbols) do
    table.insert(array, {symbol, mapping[symbol]})
  end
  return array
end

encoding = {}

encoding[1] = { map{'&', '<'}      ,
                map{'&', '<', '"'} }

encoding[2] = { map{'&', '<', '>'}      ,
                map{'&', '<', '>', '"'} }

encoding[3] = { map{'&', '\r', '<', '>'}                  ,
                map{'&', '\r', '\n', '\t', '<', '>', '"'} }

encoding[4] = { map{'&', '\r', '\n', '\t', '<', '>', '"'} ,
                map{'&', '\r', '\n', '\t', '<', '>', '"'} }

encoding["minimal"]   = encoding[1]
encoding["standard"]  = encoding[2]
encoding["strict"]    = encoding[3]
encoding["most"]      = encoding[4]

local _encode = function(text, encoding)
	for _, key_value in pairs(encoding) do
		text = text:gsub(key_value[1], key_value[2])
	end
	return text
end
---------------------------------------------------------------------------------

local srep = string.rep

local function xmlsave_recurse(indent, luaTable, xmlTable, maxIndentLevel)
	local tabs = ''
	if indent then
		if not maxIndentLevel  or indent <= maxIndentLevel then
			tabs = srep('\t', indent)
		end
	end
	local keys = {}
	local entryOrder
	if luaTable[1] then
		for _, key in ipairs(luaTable) do
			local whichIndex = keys[key]
			if not whichIndex then
				keys[key] = 0
				whichIndex = 0
			end
			whichIndex = whichIndex + 1
			keys[key] = whichIndex

			local section = luaTable[key]
			if not section then
				if not indent then
					-- Generally whitespace.
					xmlTable[#xmlTable + 1] = key
				end
			else
				local entry = section[whichIndex]
				if not entry then
					error('xmlsave: syntax bad')
				end

				xmlTable[#xmlTable + 1] = tabs .. '<' .. key

				local attributes = entry['@']
				if attributes then
					if not indent then
						for _, attrKey in ipairs(attributes) do
							xmlTable[#xmlTable + 1] = ' ' .. attrKey .. '="' .. attributes[attrKey] .. '"'
						end
					else
						for attrKey, attrValue in pairs(attributes) do
							if type(attrKey) == 'string' then
								xmlTable[#xmlTable + 1] = ' ' .. attrKey .. '="' .. attrValue .. '"'
							end
						end
					end
				end

				xmlTable[#xmlTable + 1] = '>'

				local elements = entry['#']
				if type(elements) == 'table' then
					if indent then
						xmlTable[#xmlTable + 1] = '\n'
					end
					xmlsave_recurse(indent and (indent + 1) or nil, elements, xmlTable, maxIndentLevel)
				else
					xmlTable[#xmlTable + 1] = _encode(elements, encoding[4][1])
				end

				if indent and type(elements) == 'table' then
					xmlTable[#xmlTable + 1] = tabs
				end
				xmlTable[#xmlTable + 1] = '</' .. key .. '>'
				if indent then
					xmlTable[#xmlTable + 1] = '\n'
				end
			end
		end
	else
		for key, value in pairs(luaTable) do
			if type(value) == 'table' then
				for _, entry in ipairs(value) do
					xmlTable[#xmlTable + 1] = tabs .. '<' .. key

					local attributes = entry['@']
					if attributes then
						if not indent then
							for _, attrKey in ipairs(attributes) do
								xmlTable[#xmlTable + 1] = ' ' .. attrKey .. '="' .. attributes[attrKey] .. '"'
							end
						else
							for attrKey, attrValue in pairs(attributes) do
								if type(attrKey) == 'string' then
									xmlTable[#xmlTable + 1] = ' ' .. attrKey .. '="' .. attrValue .. '"'
								end
							end
						end
					end

					xmlTable[#xmlTable + 1] = '>'

					local elements = entry['#']
					if type(elements) == 'table' then
						if indent then
							xmlTable[#xmlTable + 1] = '\n'
						end
						xmlsave_recurse(indent and (indent + 1) or nil, elements, xmlTable, maxIndentLevel)
					else
						xmlTable[#xmlTable + 1] = _encode(elements, encoding[4][1]) 
					end

					if indent and type(elements) == 'table' then
						xmlTable[#xmlTable + 1] = tabs
					end
					xmlTable[#xmlTable + 1] = '</' .. key .. '>'
					if indent then
						xmlTable[#xmlTable + 1] = '\n'
					end
				end
			end
		end
	end
end


function M.xmlize(outFilename, luaTable, indent, maxIndentLevel)
	local xmlTable = {}
	xmlsave_recurse(indent, luaTable, xmlTable, maxIndentLevel)
	local outText = table.concat(xmlTable)
	if outFilename == ':string' then
		return outText
	else
		local file = io.open(outFilename, "wt")
		file:write(table.concat(xmlTable))
		file:close()
	end
end

return M


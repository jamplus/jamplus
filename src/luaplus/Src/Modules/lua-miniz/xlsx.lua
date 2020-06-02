local miniz = require 'miniz'

local M = {}

------------------------------------------------------------
-- xmlize

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

local function xmlize(t)
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
         entry['#'] = xmlize(v)
      else
         children[#children + 1] = v
      end
   end

   return children
end

local function _xlsx_readdocument(xlsx, documentName)
   local buffer = xlsx.archive:extract(documentName)
   if not buffer then return xmlize {} end
   return xmlize {
      tag = "root",
      collect(buffer),
   }
end

------------------------------------------------------------
-- Utils

local char_A = string.byte("A")
local col_names = {}

local function col_to_name(col_num, col_abs)
   local col_str      = col_names[col_num]
   local col_num_orig = col_num
   if not col_str then
      col_str = ""
      col_num = col_num + 1
      while col_num > 0 do
         -- Set remainder from 1 .. 26
         local remainder = col_num % 26
         if remainder == 0 then remainder = 26 end
         -- Convert the remainder to a character.
         local col_letter = string.char(char_A + remainder - 1)
         -- Accumulate the column letters, right to left.
         col_str = col_letter .. col_str
         -- Get the next order of magnitude.
         col_num = math.floor((col_num - 1) / 26)
      end
      col_names[col_num_orig] = col_str
   end
   if col_abs then col_str = '$' .. col_str end
   return col_str
end

local function rowcol_to_cell(row, col)
   row = math.floor(row) + 1
   local col_str = col_to_name(col, false)
   return col_str .. row
end

------------------------------------------------------------

local colRowPattern = "([a-zA-Z]*)(%d*)"

local __cellMetatable = {
   UNDEFINED = "undefined",
   INT = "int",
   DOUBLE = "double",
   STRING = "string",
   WSTRING = "wstring",
   FORMULA = "formula",
   BOOLEAN = "boolean",

   Get = function(self)
      return self.value
   end,

   GetBoolean = function(self)
      return self.value
   end,

   GetInteger = function(self)
      return self.value
   end,

   GetDouble = function(self)
      return self.value
   end,

   GetString = function(self)
      return self.value
   end,
}

__cellMetatable.__index = __cellMetatable

function __cellMetatable:Type()
   return self.type
end

local function Cell(rowNum, colNum, value, type, formula)
   return setmetatable({
                       row = tonumber(rowNum),
                       column = colNum,
                       value = value,
                       type = type  or  __cellMetatable.UNDEFINED,
                       formula = formula,
                    }, __cellMetatable)
end

local __colTypeTranslator = {
   b = __cellMetatable.BOOLEAN,
   s = __cellMetatable.STRING,
}

local __sheetMetatable = {
   __load = function(self)
      local sheetDoc = _xlsx_readdocument(self.workbook, ("xl/worksheets/sheet%d.xml"):format(self.id))
      local sheetData = sheetDoc.worksheet[1]['#'].sheetData
      local rows = {}
      local columns = {}
      if sheetData[1]['#'].row then
         for _, rowNode in ipairs(sheetData[1]['#'].row) do
            local rowNum = tonumber(rowNode['@'].r)
            if not rows[rowNum] then
               rows[rowNum] = {}
            end
            if rowNode['#'].c then
               for _, columnNode in ipairs(rowNode['#'].c) do
                  -- Generate the proper column index.
                  local cellId = columnNode['@'].r
                  local colLetters = cellId:match(colRowPattern)
                  local colNum = 0
                  if colLetters then
                     local index = 1
                     repeat
                        colNum = colNum * 26
                        colNum = colNum + colLetters:byte(index) - ('A'):byte(1) + 1
                        index = index + 1
                     until index > #colLetters
                  end

                  local colType = columnNode['@'].t

                  local data
                  if columnNode['#'].v then
                     data = columnNode['#'].v[1]['#']
                     if colType == 's' then
                        colType = __cellMetatable.STRING
                        data = self.workbook.sharedStrings[tonumber(data) + 1]
                        data = data:gsub("%&%#(%d+)", string.char)
                     elseif colType == 'str' then
                        colType = __cellMetatable.STRING
                        data = data:gsub("%&%#(%d+)", string.char)
                     elseif colType == 'b' then
                        colType = __cellMetatable.BOOLEAN
                        data = data == '1'
                     else
                        local numberStyle = 0
                        local cellS = tonumber(columnNode['@'].s)
                        if cellS then
                           local xfs = self.workbook.styles.cellXfs[cellS - 1]
                           if xfs then 
                              numberStyle = xfs.numFmtId
                           end
                           if not numberStyle then
                              numberStyle = 0
                           end
                        end
                        if numberStyle == 0  or  numberStyle == 1 then
                           colType = __cellMetatable.INT
                        else
                           colType = __cellMetatable.DOUBLE
                        end
                        data = tonumber(data)
                     end

                     --local formula
                     --if columnNode['#'].f then
                     --assert()
                     --end

                  else
                     colType = __colTypeTranslator[colType]
                  end

                  if not columns[colNum] then
                     columns[colNum] = {}
                  end
                  local cell = Cell(rowNum, colNum, data, colType--[[, formula]])
                  table.insert(rows[rowNum], cell)
                  table.insert(columns[colNum], cell)
                  self.__cells[cellId] = cell
               end
            end
         end
      end
      self.__rows = rows
      self.__cols = columns
      self.loaded = true
   end,

   rows = function(self)
      if not self.loaded then
         self.__load()
      end
      return self.__rows
   end,

   cols = function(self)
      if not self.loaded then
         self.__load()
      end
      return self.__cols
   end,

   GetAnsiSheetName = function(self)
      return self.name
   end,

   GetUnicodeSheetName = function(self)
      return self.name
   end,

   GetSheetName = function(self)
      return self.name
   end,

   GetTotalRows = function(self)
      return #self.__rows
   end,

   GetTotalCols = function(self)
      return #self.__cols
   end,

   Cell = function(self, row, col)
      return self.__cells[rowcol_to_cell(row, col)]
   end,

   __tostring = function(self)
      return "xlsx.Sheet " .. self.name
   end
}

__sheetMetatable.__index = function(self, key)
   local value = __sheetMetatable[key]
   if value then return value end
   return self.__cells[key]
end

local function Sheet(workbook, id, name)
   local self = {}
   self.workbook = workbook
   self.id = id
   self.name = name
   self.loaded = false
   self.__cells = {}
   self.__cols = {}
   self.__rows = {}
   setmetatable(self, __sheetMetatable)
   return self
end

local __workbookMetatableMembers = {
   GetTotalWorksheets = function(self)
      return #self.__sheets
   end,

   GetWorksheet = function(self, key)
      return self.__sheets[key]
   end,

   GetAnsiSheetName = function(self, key)
      return self:GetWorksheet(key).name
   end,

   GetUnicodeSheetName = function(self, key)
      return self:GetWorksheet(key).name
   end,

   GetSheetName = function(self, key)
      return self:GetWorksheet(key).name
   end,

   Sheets = function(self)
      local i = 0
      return function()
         i = i + 1
         return self.__sheets[i]
      end
   end,

   Close = function(self)
      self.archive:close()
   end
}

local __workbookMetatable = {
   __len = function(self)
      return #self.__sheets
   end,

   __index = function(self, key)
      local value = __workbookMetatableMembers[key]
      if value then return value end
      return self.__sheets[key]
   end,
}

function M.Workbook(filename)
   local self = {}
   self.archive = assert(miniz.zip_read_file(filename))

   local sharedStringsXml = _xlsx_readdocument(self, 'xl/sharedstrings.xml')
   self.sharedStrings = {}
   if sharedStringsXml and sharedStringsXml.sst then
      local function unescape(s)
         if type(s) ~= "string" then
            print(require "serpent".block(s))
         end
         return (s
                 :gsub("&#(%d+);", function(d) return utf8.char(tonumber(d)) end)
                 :gsub("&(%w+);", { amp = "&", lt = "<", gt = ">", quot = '"', apos = "'" }))
      end
      local function getstring(t)
         if type(t['#']) == 'table' then
            return t['@'].space == "preserve" and ' ' or ''
         end
         return unescape(t['#'])
      end
      for _, str in ipairs(sharedStringsXml.sst[1]['#'].si) do
         if str['#'].r then
            local concatenatedString = {}
            for _, rstr in ipairs(str['#'].r) do
               local t = getstring(rstr['#'].t[1])
               if type(t) == 'string' then
                  concatenatedString[#concatenatedString + 1] = t
               end
            end
            concatenatedString = table.concat(concatenatedString)
            self.sharedStrings[#self.sharedStrings + 1] = concatenatedString
         else
            local t = getstring(str['#'].t[1])
            self.sharedStrings[#self.sharedStrings + 1] = t
         end
      end
   end

   local stylesXml = _xlsx_readdocument(self, 'xl/styles.xml')
   self.styles = {}
   local cellXfs = {}
   self.styles.cellXfs = cellXfs
   if stylesXml then
      for _, xfXml in ipairs(stylesXml.styleSheet[1]['#'].cellXfs[1]['#'].xf) do
         local xf = {}
         local numFmtId = xfXml['@'].numFmtId
         if numFmtId then
            xf.numFmtId = tonumber(numFmtId)
         end
         cellXfs[#cellXfs + 1] = xf
      end
   end

   self.workbookDoc = _xlsx_readdocument(self, 'xl/workbook.xml')
   local sheets = self.workbookDoc.workbook[1]['#'].sheets
   self.__sheets = {}
   local id = 1
   for _, sheetNode in ipairs(sheets[1]['#'].sheet) do
      local name = sheetNode['@'].name
      local sheet = Sheet(self, id, name)
      sheet:__load()
      self.__sheets[id] = sheet
      self.__sheets[name] = sheet
      id = id + 1
   end
   setmetatable(self, __workbookMetatable)
   return self
end

return M

--[[
xlsx = M

local workbook = xlsx.Workbook('Book1.xlsx')
print("Book")
local sheet = workbook[1]
print(sheet:Cell(0, 52))
cell = sheet:Cell(0, 52)
print(cell.value)
print(cell:Get())
print(workbook:GetTotalWorksheets())
print(sheet:rows())
print(sheet:cols())
print(sheet.B1)


--]]

-- vim: set tabstop=4 expandtab:

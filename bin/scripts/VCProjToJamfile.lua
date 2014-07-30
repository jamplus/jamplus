local getopt = require 'getopt'
local xmlize = require 'xmlize'
local ospath = require 'ospath'

local options = getopt.makeOptions{}
local nonOpts, opts, errors = getopt.getOpt(arg, options)
if #errors > 0  or  #nonOpts ~= 2 then
	print(table.concat (errors, "\n") .. "\n" ..
			getopt.usageInfo ("Usage: jam --vcprojtojamfile [options] <source-vcproj> <destination-jamfile>",
			options))
	os.exit(-1)
end

package.path = (debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. "/?.lua;" .. package.path
require 'WriteJamfileHelper'

local vcproj = path.read_file(nonOpts[1])
if not vcproj then
	print('VCProjToJamfile: * Error: Unable to read ' .. nonOpts[1] .. '.')
	os.exit(-1)
end

local xml = xmlize.luaize(vcproj)

local function RecurseFilters(filters, folderPath)
	if not filters then return end

	local groups = {}
	for _, filter in ipairs(filters) do
		local files = {}
		if filter['#'].File then
			for _, file in ipairs(filter['#'].File) do
				files[#files + 1] = file['@'].RelativePath:gsub('\\', '/'):gsub('^%./', '')
			end
		end

		local fullFolderPath = folderPath
		if filter['@'].Name then
			fullFolderPath = fullFolderPath .. filter['@'].Name .. '\\'
		end

		groups[#groups + 1] =
		{
			FolderPath = fullFolderPath:sub(1, fullFolderPath:len() - 1),
			SrcsName = fullFolderPath:upper():gsub('[ \\]', '_') .. 'SRCS',
			Files = files,
			Groups = RecurseFilters(filter['#'].Filter, fullFolderPath),
		}
	end

	table.sort(groups, function(a, b) return a.FolderPath:lower() < b.FolderPath:lower() end)
	return groups
end

local visualStudioProject = xml.VisualStudioProject[1]
local target = visualStudioProject['@'].Name
local filters = visualStudioProject['#'].Files
SourceGroups = RecurseFilters(filters, '')

if not WriteJamfileHelper.Write(nonOpts[2], target) then
	print('VCProjToJamfile: * Error: Unable to write ' .. nonOpts[2] .. '.')
	os.exit(-1)
end

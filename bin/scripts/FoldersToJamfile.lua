local getopt = require 'getopt'
local filefind = require 'filefind'
local ospath = require 'ospath'

package.path = (debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. "/?.lua;" .. package.path
local foldertree = require 'FolderTree'
local WriteJamfileHelper = require 'WriteJamfileHelper'

local options = getopt.makeOptions{}
local nonOpts, opts, errors = getopt.getOpt(arg, options)
if #errors > 0  or  #nonOpts ~= 2 then
	print(table.concat (errors, "\n") .. "\n" ..
			getopt.usageInfo ("Usage: jam --folderstojamfile [options] <start-path> <destination-jamfile>",
			options))
	os.exit(-1)
end

local files = {}

local rootPath = ospath.add_slash(nonOpts[1])
for entry in filefind.glob(ospath.join(rootPath, '**')) do
	local relativePath = entry.filename:sub(#rootPath + 1)
	local path, filename = relativePath:match('(.+)/(.*)')
	if not path then
		path, filename = '', relativePath
	end
	foldertree.InsertName(files, path:gsub('/', '\\'), filename)
end

foldertree.Sort(files)


local function RecurseFilters(filters, folderPath)
	local groups = {}
	for _, filter in ipairs(filters) do
		if type(filter) == 'table' then
			local fullFolderPath = folderPath
			if filter.folder ~= '' then
				fullFolderPath = fullFolderPath .. filter.folder .. '\\'
			end

			local files = {}
			for _, file in ipairs(filter) do
				if type(file) ~= 'table' then
					files[#files + 1] = fullFolderPath:gsub('\\', '/') .. file
				end
			end

			groups[#groups + 1] =
			{
				FolderPath = fullFolderPath:sub(1, fullFolderPath:len() - 1),
				SrcsName = fullFolderPath:upper():gsub('[ \\]', '_') .. 'SRCS',
				Files = files,
				Groups = RecurseFilters(filter, fullFolderPath),
			}
		end
	end

	table.sort(groups, function(a, b) return a.FolderPath:lower() < b.FolderPath:lower() end)
	return groups
end

files.folder = ''
SourceGroups = RecurseFilters({ files } , '')

local target = "***FILL_ME_IN***"

if not WriteJamfileHelper.Write(nonOpts[2], target, SourceGroups) then
	print('VCProjToJamfile: * Error: Unable to write ' .. nonOpts[1] .. '.')
	os.exit(-1)
end

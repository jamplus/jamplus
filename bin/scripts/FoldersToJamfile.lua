require 'getopt'
require 'glob'

package.path = (debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. "/?.lua;" .. package.path
require 'FolderTree'
require 'WriteJamfileHelper'

local options = Options {}
local nonOpts, opts, errors = getopt.getOpt(arg, options)
if #errors > 0  or  #nonOpts ~= 1 then
	print(table.concat (errors, "\n") .. "\n" ..
			getopt.usageInfo ("Usage: FoldersToJam [options] <destination-jamfile>",
			options))
	os.exit(-1)
end

local files = {}

local sources = glob.match('**')
for _, source in ipairs(sources) do
	local path, filename = source:match('(.+)/(.*)')
	if not path then
		path, filename = '', source
	end
	FolderTree.InsertName(files, path:gsub('/', '\\'), filename)
end

FolderTree.Sort(files)


local function RecurseFilters(filters, folderPath)
	local groups = {}
	for _, filter in ipairs(filters) do
		if type(filter) == 'table' then
			local files = {}
			for _, file in ipairs(filter) do
				if type(file) ~= 'table' then
					files[#files + 1] = folderPath:gsub('\\', '/') .. file
				end
			end

			local fullFolderPath = folderPath
			if filter.folder ~= '' then
				fullFolderPath = fullFolderPath .. filter.folder .. '\\'
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

if not WriteJamfileHelper.Write(nonOpts[1], target) then
	print('VCProjToJamfile: * Error: Unable to write ' .. nonOpts[2] .. '.')
	os.exit(-1)
end

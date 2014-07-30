local getopt = require 'getopt'
local xmlize = require 'xmlize'
local ospath = require 'ospath'

local options = getopt.makeOptions {}
local nonOpts, opts, errors = getopt.getOpt(arg, options)
if #errors > 0  or  #nonOpts ~= 2 then
	print(table.concat (errors, "\n") .. "\n" ..
			getopt.usageInfo ("Usage: jam --vcxprojtojamfile [options] <source-vcxproj> <destination-jamfile>",
			options))
	os.exit(-1)
end

package.path = (debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. "/?.lua;" .. package.path
local foldertree = require 'FolderTree'
local WriteJamfileHelper = require 'WriteJamfileHelper'

local vcxproj = ospath.read_file(nonOpts[1])
if not vcxproj then
	print('VCXProjToJamfile: * Error: Unable to read ' .. nonOpts[1] .. '.')
	os.exit(-1)
end

local xml = xmlize.luaize(vcxproj)

local function RecurseItemGroup(files, itemGroupRoot)
	for _, entry in ipairs(itemGroupRoot) do
		entry = entry['#']
		for _, orderTable in ipairs(entry['*']) do
			local key = orderTable[1]
			if key ~= 'Filter' then
				local value = entry[key][orderTable[2]]
				local attr = value['@']
				local filename = ospath.make_slash(attr.Include)

				local filter = value['#'].Filter
				if filter then
					local relativePath = filter[1]['#']
					if type(relativePath) ~= 'string' then
						relativePath = ''
					end
					foldertree.InsertName(files, relativePath, filename)
				else
					foldertree.InsertName(files, '', filename)
				end
			end
		end
	end
	return files
end

local files = {}

local project = xml.Project[1]['#']
files = RecurseItemGroup(files, project.ItemGroup, '')

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
					files[#files + 1] = file
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

local target = ospath.remove_directory(ospath.remove_extension(nonOpts[1]))

if not WriteJamfileHelper.Write(nonOpts[2], target, SourceGroups) then
	print('VCProjToJamfile: * Error: Unable to write ' .. nonOpts[2] .. '.')
	os.exit(-1)
end

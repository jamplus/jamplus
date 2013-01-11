--[[
	files =
	{
	    'hi',
		{
			folder = 'Stuff',
			'stuff',
			{
				folder = 'nested',
			}
		}
	}
]]

local M = {}

function M.FindFolder(currentFolder, fullFolderPath)
	if fullFolderPath == '' then
		return currentFolder
	end

	-- Split each component.
	for folderName in fullFolderPath:gmatch('[^\\]+') do
		local foundFolder
		for _, entry in ipairs(currentFolder) do
			if type(entry) == 'table'  and entry.folder:lower() == folderName:lower() then
				foundFolder = entry
				break
			end
		end

		-- If the folder wasn't found, then make it.
		if not foundFolder then
			foundFolder = {  folder = folderName  }
			currentFolder[#currentFolder + 1] = foundFolder
		end

		currentFolder = foundFolder
	end

	return currentFolder
end


function M.InsertName(rootFolder, fullFolderPath, name)
	local folder = M.FindFolder(rootFolder, fullFolderPath)

	local foundEntry
	for _, entry in ipairs(folder) do
		if type(entry) == 'string'  and  entry:lower() == name:lower() then
			foundEntry = entry
			break
		end
	end

	if not foundEntry then
		folder[#folder + 1] = name
	end
end


local function SortEntry(left, right)
	if type(left) == 'table'  and  type(right) == 'table' then
		return left.folder:lower() < right.folder:lower()
	elseif type(left) == 'table'  and  type(right) ~= 'table' then
		return true
	elseif type(left) ~= 'table'  and  type(right) == 'table' then
		return false
	end

	return left:lower() < right:lower()
end


function M.Sort(currentFolder)
	table.sort(currentFolder, SortEntry)
	for _, entry in ipairs(currentFolder) do
		if type(entry) == 'table' then
			M.Sort(entry)
		end
	end
end

return M


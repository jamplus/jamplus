local M = {}

local function Quote(textToQuote)
	textToQuote = textToQuote:gsub('"', '\\"'):gsub('\\', '\\\\')
	return textToQuote:find('[ \\]') and ('"' .. textToQuote .. '"') or textToQuote
end

function M.Write(filename, target, SourceGroups)
	local text = {}
	text[#text + 1] = [[
{

Exit This file was exported and needs to be fixed up. ;
SubDir TOP *** ;

]]

	local filesText = {}
	local sourceGroupsText = {}

	function RecurseSourceGroups(sourceGroups)
		for _, sourceGroup in ipairs(sourceGroups) do
			if sourceGroup.Groups then
				RecurseSourceGroups(sourceGroup.Groups)
			end
			filesText[#filesText + 1] = 'local ' .. sourceGroup.SrcsName .. ' =\n'
			for _, fileName in ipairs(sourceGroup.Files) do
				filesText[#filesText + 1] = '\t\t' .. Quote(fileName) .. '\n'
			end
			if sourceGroup.Groups then
				for _, childSourceGroup in ipairs(sourceGroup.Groups) do
					filesText[#filesText + 1] = '\t\t$(' .. childSourceGroup.SrcsName .. ')\n'
					sourceGroupsText[#sourceGroupsText + 1] =
							"SourceGroup " .. Quote(target) .. " : " .. Quote(childSourceGroup.FolderPath:gsub('/', '\\\\')) ..
									" : $(" .. childSourceGroup.SrcsName .. ") ;\n"
				end
			end
			filesText[#filesText + 1] = ";\n\n"
		end
	end

	RecurseSourceGroups(SourceGroups)

	text[#text + 1] = table.concat(filesText)
	text[#text + 1] = table.concat(sourceGroupsText)

	text[#text + 1] = '\nC.Library ' .. target .. ' : $(SRCS) ;\n'
	text[#text + 1] = '\n}\n'

	local file = io.open(filename, 'wb')
	if not file then
		return false
	end
	file:write(table.concat(text))
	file:close()

	return true
end

return M


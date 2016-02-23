-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local uuid = require 'uuid'

MapPlatformToCodeBlocksPlatform =
{
	['win32'] = 'Win32',
}

MapConfigToCodeBlocksConfig =
{
	['debug'] = 'Debug',
	['release'] = 'Release',
}

MapCompilerToCodeBlocksCompiler =
{
	['vs2003'] = 'msvc7',
	['vs2005'] = 'msvc8',
	['vs2008'] = 'msvc9',
	['vs2010'] = 'msvc10',
	['mingw'] = 'gcc',
}

local CodeBlocksProjectMetaTable = {  __index = CodeBlocksProjectMetaTable  }

function CodeBlocksProjectMetaTable:_GatherSourceFolders(folder, folderList, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local sourceFolderName
			if fullPath ~= '' then
				sourceFolderName = fullPath .. '\\' .. entry.folder
			else
				sourceFolderName = entry.folder
			end
			table.insert(folderList, sourceFolderName)
			self:_GatherSourceFolders(entry, folderList, sourceFolderName)
		end
	end
end


function CodeBlocksProjectMetaTable:Write(outputPath)
	local filename = outputPath .. self.ProjectName .. '.cbp'

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
		ProjectExportInfo[self.ProjectName] = info
	end

	local project = Projects[self.ProjectName]

	local cbCompiler = MapCompilerToCodeBlocksCompiler[self.Options.compiler]

	-- Write header.
	table.insert(self.Contents, expand([[
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<CodeBlocks_project_file>
	<FileVersion major="1" minor="6" />
	<Project>
		<Option title="$(ProjectName)" />
		<Option makefile_is_custom="1" />
		<Option compiler="$(Compiler)" />
]], self, { Compiler = cbCompiler } ))
--		<Option pch_mode="2" />

	local platformName = Platform
	do
		local configName = 'debug'
		local jamCommandLine = os.path.escape(jamScript) .. ' ' ..
				os.path.escape('-C' .. destinationRootPath) .. ' -g ' ..
				'C.TOOLCHAIN=' .. platformName .. '/' .. configName

		local configInfo =
		{
			Platform = platformName,
			Config = configName,
			CBPlatform = MapPlatformToCodeBlocksPlatform[platformName],
			CBConfig = MapConfigToCodeBlocksConfig[configName],
			Defines = '',
			Includes = '',
			Output = '',
		}

		if project and project.Name and project.Name ~= '!BuildWorkspace' and project.Name ~= '!UpdateWorkspace' then
			if project.Defines then
				configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
			end
			if project.IncludePaths then
				configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
			end
			if project.OutputPaths then
				configInfo.Output = project.OutputPaths[platformName][configName] .. project.OutputNames[platformName][configName]
			end
			configInfo.BuildCommandLine = jamCommandLine .. ' ' .. self.ProjectName
			configInfo.RebuildCommandLine = jamCommandLine .. ' -a ' .. self.ProjectName
			configInfo.CleanCommandLine = jamCommandLine .. ' clean:' .. self.ProjectName
		else
			configInfo.BuildCommandLine = project.BuildCommandLine and project.BuildCommandLine[1] or jamCommandLine
			configInfo.RebuildCommandLine = project.RebuildCommandLine and project.RebuildCommandLine[1] or (jamCommandLine .. ' -a')
			configInfo.CleanCommandLine = project.CleanCommandLine and project.CleanCommandLine[1] or (jamCommandLine .. ' clean')
		end

		table.insert(self.Contents, expand([==[
		<MakeCommands>
			<Build command="$(BuildCommandLine)" />
			<CompileFile command="$(BuildCommandLine)" />
			<Clean command="$(CleanCommandLine)" />
			<DistClean command="$(CleanCommandLine)" />
		</MakeCommands>
]==], configInfo, info, _G))

	end

	local virtualFolderInfo = { sourceFolderList = { '!Sources' } }
	if project then
		self:_GatherSourceFolders(project.SourcesTree, virtualFolderInfo.sourceFolderList, '')
	end

	table.insert(self.Contents, expand([[
		<Option virtualFolders="$(table.concat(sourceFolderList, ';'))" />
]], virtualFolderInfo, _G))

	-- Start Build section
	table.insert(self.Contents, [[
		<Build>
]])

	for configName in ivalues(Config.Configurations) do
		local jamCommandLine = os.path.escape(jamScript) .. ' ' ..
				os.path.escape('-C' .. destinationRootPath) .. ' ' ..
				'-sPLATFORM=' .. platformName .. ' ' ..
				'-sCONFIG=' .. configName

		local configInfo =
		{
			Platform = platformName,
			Config = configName,
			CBPlatform = MapPlatformToCodeBlocksPlatform[platformName],
			CBConfig = MapConfigToCodeBlocksConfig[configName],
			Defines = '',
			Includes = '',
			Output = '',
		}

		if project and project.Name then
			if project.Defines then
				configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
			end
			if project.IncludePaths then
				configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
			end
			if project.OutputPaths then
				configInfo.Output = project.OutputPaths[platformName][configName] .. project.OutputNames[platformName][configName]
			end
			configInfo.BuildCommandLine = jamCommandLine .. ' ' .. self.ProjectName
			configInfo.RebuildCommandLine = jamCommandLine .. ' -a ' .. self.ProjectName
			configInfo.CleanCommandLine = jamCommandLine .. ' clean:' .. self.ProjectName
		elseif not commandLines then
			configInfo.BuildCommandLine = jamCommandLine
			configInfo.RebuildCommandLine = jamCommandLine .. ' -a'
			configInfo.CleanCommandLine = jamCommandLine .. ' clean'
		else
			configInfo.BuildCommandLine = commandLines[1] or ''
			configInfo.RebuildCommandLine = commandLines[2] or ''
			configInfo.CleanCommandLine = commandLines[3] or ''
		end

		table.insert(self.Contents, expand([==[
			<Target title="$(CBConfig)">
				<Option output="$(Output)" prefix_auto="0" extension_auto="0" />
				<Option type="1" />
				<MakeCommands>
					<Build command="$(BuildCommandLine)" />
					<CompileFile command="$(BuildCommandLine)" />
					<Clean command="$(CleanCommandLine)" />
					<DistClean command="$(CleanCommandLine)" />
				</MakeCommands>
			</Target>
]==], configInfo, info, _G))
	end

	-- Write Build footer.
	table.insert(self.Contents, [[
		</Build>
]])

	if project then
		self:_WriteFiles(project.SourcesTree, '')
	end

	table.insert(self.Contents, [[
	</Project>
</CodeBlocks_project_file>
]])

	self.Contents = table.concat(self.Contents)

	local file = io.open(filename, 'wt')
	file:write(self.Contents)
	file:close()
end


function CodeBlocksProjectMetaTable:_WriteFiles(folder, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local sourceFolderName
			if fullPath ~= '' then
				sourceFolderName = fullPath .. '\\' .. entry.folder
			else
				sourceFolderName = entry.folder
			end
			self:_WriteFiles(entry, sourceFolderName)
		else
			if fullPath ~= '' then
				table.insert(self.Contents, '\t\t<Unit filename="' .. entry:gsub('/', '\\') .. '">\n')
				table.insert(self.Contents, '\t\t\t<Option virtualFolder="' .. fullPath .. '\\" />\n')
				table.insert(self.Contents, '\t\t</Unit>\n')
			else
				table.insert(self.Contents, '\t\t<Unit filename="' .. entry:gsub('/', '\\') .. '">\n')
				table.insert(self.Contents, '\t\t\t<Option virtualFolder="!Sources\\" />\n')
				table.insert(self.Contents, '\t\t</Unit>\n')
--				table.insert(self.Contents, '\t\t<Unit filename="' .. entry:gsub('/', '\\') .. '" />\n')
			end
		end
	end
end


function CodeBlocksProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = CodeBlocksProjectMetaTable }
	)
end





local CodeBlocksWorkspaceMetaTable = {  __index = CodeBlocksWorkspaceMetaTable  }

function CodeBlocksWorkspaceMetaTable:Write(outputPath)
	local filename = outputPath .. self.Name .. '.workspace'

	local workspace = Workspaces[self.Name]

	-- Write header.
	table.insert(self.Contents, expand([[
<?xml version="1.0" encoding="UTF-8" standalone="yes" ?>
<CodeBlocks_workspace_file>
	<Workspace title="$(Name)">
]], self))

	-- Write projects.
	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		table.insert(self.Contents, expand([[
		<Project filename="$(Filename)" active="1" />
]], info))
	end

	-- Write footer.
	table.insert(self.Contents, [[
	</Workspace>
</CodeBlocks_workspace_file>
]])

	self.Contents = table.concat(self.Contents)

	local file = io.open(filename, 'wt')
	file:write(self.Contents)
	file:close()
end

function CodeBlocksWorkspace(workspaceName, options)
	return setmetatable(
		{
			Contents = {},
			Name = workspaceName,
			Options = options,
		}, { __index = CodeBlocksWorkspaceMetaTable }
	)
end



function CodeBlocksInitialize()
	ProjectExportInfo = {}
end


function CodeBlocksShutdown()
end








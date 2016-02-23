-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local uuid = require 'uuid'

local VisualStudio200xProjectMetaTable = {  __index = VisualStudio200xProjectMetaTable  }

local function GetMapPlatformToVSPlatform(platformName)
	return MapPlatformToVSPlatform and MapPlatformToVSPlatform[platformName] or platformName
end

local function GetMapConfigToVSConfig(configName)
	return MapConfigToVSConfig and MapConfigToVSConfig[configName] or configName
end

local function RealVSPlatform(platform)
	if VSNativePlatforms  and  VSNativePlatforms[platform] then
		return MapPlatformToVSPlatform[platform]
	end

	return "Win32"
end

local function RealVSConfig(platform, config)
	local realConfig = GetMapConfigToVSConfig(config)
	if VSNativePlatforms  and  VSNativePlatforms[platform] then
		return realConfig
	end

	return GetMapPlatformToVSPlatform(platform) .. ' ' .. realConfig
end

function VisualStudio200xProjectMetaTable:Write(outputPath)
	local filename = ospath.join(outputPath, self.ProjectName .. '.vcproj')

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
		ProjectExportInfo[self.ProjectName] = info
	else
		info.Filename = filename
	end

	local project = Projects[self.ProjectName]

	-- Write header.
	table.insert(self.Contents, expand([[
<?xml version="1.0" encoding="Windows-1252"?>
<VisualStudioProject
	ProjectType="Visual C++"
]]))

	if self.Options.vs2003 then
		table.insert(self.Contents, expand([[
	Version="7.10"
	Name="$(Name)"
	ProjectGUID="$(Uuid:upper())"
	Keyword="MakeFileProj">
]], info))
	elseif self.Options.vs2005 then
		table.insert(self.Contents, expand([[
	Version="8.00"
	Name="$(Name)"
	ProjectGUID="$(Uuid:upper())"
	RootNamespace="$(Name)"
	>
]], info))
	elseif self.Options.vs2008 then
		table.insert(self.Contents, expand([[
	Version="9.00"
	Name="$(Name)"
	ProjectGUID="$(Uuid:upper())"
	RootNamespace="$(Name)"
	>
]], info))
	end

	-- Write Platforms section.
	table.insert(self.Contents, [[
	<Platforms>
]])

	local processedPlatform = {}
	if self.Options.vs2003 then
		for platformName in ivalues(Config.Platforms) do
			local realPlatform = RealVSPlatform(platformName)
			if not processedPlatform[realPlatform] then
				processedPlatform[realPlatform] = true
				table.insert(self.Contents, [[
		<Platform
			Name="]] .. realPlatform .. [["/>
]])
			end
		end
	elseif self.Options.vs2005 or self.Options.vs2008 then
		for platformName in ivalues(Config.Platforms) do
			local realPlatform = RealVSPlatform(platformName)
			if not processedPlatform[realPlatform] then
				processedPlatform[realPlatform] = true
				table.insert(self.Contents, [[
		<Platform
			Name="]] .. realPlatform .. [["
		/>
]])
		end
	end
	table.insert(self.Contents, [[
	</Platforms>
]])

	-- Write ToolFiles section.
		table.insert(self.Contents, [[
	<ToolFiles>
	</ToolFiles>
]])
	end

	-- Write Configurations header.
	table.insert(self.Contents, [[
	<Configurations>
]])

	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local jamCommandLine = ospath.escape(jamScript) .. ' ' ..
					ospath.escape('-C' .. destinationRootPath) .. ' -g ' ..
					'C.TOOLCHAIN=' .. platformName .. '/' .. configName

			local configInfo =
			{
				Platform = platformName,
				Config = configName,
				VSPlatform = RealVSPlatform(platformName),
				VSConfig = RealVSConfig(platformName, configName),
				Defines = '',
				Includes = '',
				Output = '',
			}

			if project and project.Name and project.Name ~= '!BuildWorkspace' and project.Name ~= '!UpdateWorkspace' then
				if project.Defines and project.Defines[platformName] and project.Defines[platformName][configName] then
					configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
				end
				if project.IncludePaths and project.IncludePaths[platformName] and project.IncludePaths[platformName][configName] then
					configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
				end
				if project.DebuggerOutputNames  and  project.DebuggerOutputNames[platformName]  and  project.DebuggerOutputNames[platformName][configName] then
					configInfo.Output = project.DebuggerOutputNames[platformName][configName]
				end
				if configInfo.Output == ''  and  project.OutputPaths and project.OutputPaths[platformName] and project.OutputPaths[platformName][configName] then
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

			configInfo.BuildCommandLine = configInfo.BuildCommandLine:gsub('"', '&quot;')
			configInfo.RebuildCommandLine = configInfo.RebuildCommandLine:gsub('"', '&quot;')
			configInfo.CleanCommandLine = configInfo.CleanCommandLine:gsub('"', '&quot;')

			table.insert(self.Contents, [==[
		<Configuration
]==])

			if self.Options.vs2003 then
				table.insert(self.Contents, expand([==[
			Name="$(VSConfig)|$(VSPlatform)"
			OutputDirectory="$$(ConfigurationName)"
			IntermediateDirectory="$$(ConfigurationName)"
			ConfigurationType="0"
			BuildLogFile="$(destinationRootPath:gsub('/', '\\'))$(Platform)-$(Config)/BuildLog.htm">
			<Tool
				Name="VCNMakeTool"
				BuildCommandLine="$(BuildCommandLine)"
				ReBuildCommandLine="$(RebuildCommandLine)"
				CleanCommandLine="$(CleanCommandLine)"
				Output="$(Output)"
			/>
]==], configInfo, info, _G))

			elseif self.Options.vs2005 or self.Options.vs2008 then
				table.insert(self.Contents, expand([==[
			Name="$(VSConfig)|$(VSPlatform)"
			OutputDirectory="$$(ConfigurationName)"
			IntermediateDirectory="$$(ConfigurationName)"
			ConfigurationType="0"
			BuildLogFile="$(destinationRootPath:gsub('/', '\\'))$(Platform)-$(Config)/BuildLog.htm"
			>
			<Tool
				Name="VCNMakeTool"
				BuildCommandLine="$(BuildCommandLine)"
				ReBuildCommandLine="$(RebuildCommandLine)"
				CleanCommandLine="$(CleanCommandLine)"
				Output="$(Output)"
				PreprocessorDefinitions="$(Defines)"
				IncludeSearchPath="$(Includes)"
				ForcedIncludes=""
				AssemblySearchPath=""
				ForcedUsingAssemblies=""
				CompileAsManaged=""
			/>
]==], configInfo, info, _G))
			end

			-- Write out custom tools.
			if project.MakefileTool then
				local sortedTools = {}
				for toolKey in pairs(project.MakefileTool) do
					sortedTools[#sortedTools + 1] = toolKey
				end
				table.sort(sortedTools)
				
				for _, toolKey in ipairs(sortedTools) do
					local tool = project.MakefileTool[toolKey]

					table.insert(self.Contents, [==[
			<Tool
				Name="]==] .. toolKey .. [==["
]==])

					local sortedKeys = {}
					for key in pairs(tool) do
						sortedKeys[#sortedKeys + 1] = key
					end
					table.sort(sortedKeys)

					for _, key in ipairs(sortedKeys) do
						local value = tool[key]
						table.insert(self.Contents, '\t\t\t\t' .. key .. '="' .. value .. '"' .. '\n')
					end
					
					table.insert(self.Contents, [==[
			/>
]==])
				end
			end
			
			table.insert(self.Contents, [==[
		</Configuration>
]==])
		end
	end

	-- Write Configurations footer.
	table.insert(self.Contents, [[
	</Configurations>
]])

	-- Write References.
	table.insert(self.Contents, [[
	<References>
	</References>
]])

	-- Write Files.
	table.insert(self.Contents, [[
	<Files>
]])

	if project then
		self:_WriteFiles(project.SourcesTree, '\t\t')
	end

	table.insert(self.Contents, [[
	</Files>
]])

	-- Write Globals.
	table.insert(self.Contents, [[
	<Globals>
	</Globals>
]])

	-- Write footer.
	table.insert(self.Contents, [[
</VisualStudioProject>
]])

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)
end

function VisualStudio200xProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = VisualStudio200xProjectMetaTable }
	)
end


function VisualStudio200xProjectMetaTable:_WriteFiles(folder, tabs)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			table.insert(self.Contents, tabs .. '<Filter\n')
			table.insert(self.Contents, tabs .. '\tName="' .. entry.folder .. '"\n')
			table.insert(self.Contents, tabs .. '\t>\n')
			self:_WriteFiles(entry, tabs .. '\t')
			table.insert(self.Contents, tabs .. '</Filter>\n')
		else
			table.insert(self.Contents, tabs .. '<File\n')
			table.insert(self.Contents, tabs .. '\tRelativePath="' .. ospath.make_backslash(entry) .. '"\n')
			table.insert(self.Contents, tabs .. '\t>\n')
			table.insert(self.Contents, tabs .. '</File>\n')
		end
	end
end





local VisualStudio200xSolutionMetaTable = {  __index = VisualStudio200xSolutionMetaTable  }

function VisualStudio200xSolutionMetaTable:_GatherSolutionFolders(folder, folderList, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local solutionFolder = fullPath .. '\\' .. entry.folder
			table.insert(folderList, solutionFolder)
			self:_GatherSolutionFolders(entry, folderList, solutionFolder)
		end
	end
end


function VisualStudio200xSolutionMetaTable:_WriteNestedProjects(folder, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local solutionFolder = fullPath .. '\\' .. entry.folder
			if folder.folder then
				table.insert(self.Contents, expand([[
		$(Child) = $(Parent)
]], {  Child = ProjectExportInfo[solutionFolder].Uuid, Parent = ProjectExportInfo[fullPath].Uuid  }))
			end
			self:_WriteNestedProjects(entry, solutionFolder)
		else
			if folder.folder then
				table.insert(self.Contents, expand([[
		$(Child) = $(Parent)
]], {  Child = ProjectExportInfo[entry].Uuid, Parent = ProjectExportInfo[fullPath].Uuid  }))
			end
		end
	end
end


function VisualStudio200xSolutionMetaTable:Write(outputPath)
	local filename = ospath.join(outputPath, self.Name .. '.sln')

	local workspace = Workspaces[self.Name]

	-- Write header.
	table.insert(self.Contents, '\xef\xbb\xbf\n')

	if self.Options.vs2003 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 8.00
]])
	elseif self.Options.vs2005 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 9.00
# Visual Studio 2005
]])
	elseif self.Options.vs2008 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 10.00
# Visual Studio 2008
]])
	end

	-- Write projects.
	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		if info then
			if self.Options.vs2003 then
				table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename:gsub('/', '\\'))", "$(Uuid)"
	ProjectSection(ProjectDependencies) = postProject
	EndProjectSection
EndProject
]], info))
			elseif self.Options.vs2005 or self.Options.vs2008 then
				table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename:gsub('/', '\\'))", "$(Uuid)"
EndProject
]], info))
			end
		end
	end

	-- Write the folders we use.
	local folderList = {}
	self:_GatherSolutionFolders(workspace.ProjectTree, folderList, '')

	for solutionFolderName in ivalues(folderList) do
		local info = ProjectExportInfo[solutionFolderName]
		if not info then
			info =
			{
				Name = solutionFolderName:match('.*\\(.+)'),
				Filename = solutionFolderName,
				Uuid = '{' .. uuid.new():upper() .. '}'
			}
			ProjectExportInfo[solutionFolderName] = info
		end

		table.insert(self.Contents, expand([[
Project("{2150E333-8FDC-42A3-9474-1A3956D46DE8}") = "$(Name)", "$(Name)", "$(Uuid)"
EndProject
]], info))
	end

	-- Begin writing the Global section.
	table.insert(self.Contents, [[
Global
]])

	table.insert(self.Contents, [[
	GlobalSection(SolutionConfigurationPlatforms) = preSolution
]])

	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = GetMapPlatformToVSPlatform(platformName),
				VSConfig = GetMapConfigToVSConfig(configName),
			}
			table.insert(self.Contents, expand([[
		$(VSConfig)|$(VSPlatform) = $(VSConfig)|$(VSPlatform)
]], configInfo))
		end
	end

	table.insert(self.Contents, [[
	EndGlobalSection
]])

	-------------------
	table.insert(self.Contents, [[
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
]])

	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local info = ProjectExportInfo[buildWorkspaceName]
			local configInfo =
			{
				VSPlatform = GetMapPlatformToVSPlatform(platformName),
				VSConfig = GetMapConfigToVSConfig(configName),
				RealVSPlatform = RealVSPlatform(platformName),
				RealVSConfig = RealVSConfig(platformName, configName),
			}
			table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(RealVSConfig)|$(RealVSPlatform)
]], configInfo, info))

			table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).Build.0 = $(RealVSConfig)|$(RealVSPlatform)
]], configInfo, info))
		end
	end

	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local info = ProjectExportInfo[updateWorkspaceName]
			local configInfo =
			{
				VSPlatform = GetMapPlatformToVSPlatform(platformName),
				VSConfig = GetMapConfigToVSConfig(configName),
				RealVSPlatform = RealVSPlatform(platformName),
				RealVSConfig = RealVSConfig(platformName, configName),
			}
			table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(RealVSConfig)|$(RealVSPlatform)
]], configInfo, info))
		end
	end

	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		if info then
			for platformName in ivalues(Config.Platforms) do
				for configName in ivalues(Config.Configurations) do
					local configInfo =
					{
						VSPlatform = GetMapPlatformToVSPlatform(platformName),
						VSConfig = GetMapConfigToVSConfig(configName),
						RealVSPlatform = RealVSPlatform(platformName),
						RealVSConfig = RealVSConfig(platformName, configName),
					}
					table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(RealVSConfig)|$(RealVSPlatform)
]], configInfo, info))
				end
			end
		end
	end

	table.insert(self.Contents, [[
	EndGlobalSection
]])

	table.insert(self.Contents, [[
	GlobalSection(SolutionProperties) = preSolution
		HideSolutionNode = FALSE
	EndGlobalSection
]])

	table.insert(self.Contents, [[
	GlobalSection(NestedProjects) = preSolution
]])

	self:_WriteNestedProjects(workspace.ProjectTree, '')

	table.insert(self.Contents, [[
	EndGlobalSection
]])

	-- Write EndGlobal section.
	table.insert(self.Contents, [[
EndGlobal
]])

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)
end

function VisualStudio200xSolution(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = VisualStudio200xSolutionMetaTable }
	)
end



function VisualStudio200xInitialize()
	local chunk = loadfile(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'))
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function VisualStudio200xShutdown()
	prettydump.dumpascii(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'), 'ProjectExportInfo', ProjectExportInfo)
end





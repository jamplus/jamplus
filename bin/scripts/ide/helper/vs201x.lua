-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local uuid = require 'uuid'

local solutionProjectTypes = {
	[".csproj"] = "{FAE04EC0-301F-11D3-BF4B-00C04F79EFBC}",
	[".vcxproj"] = "{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}",
}

local VisualStudio201xProjectMetaTable = {  __index = VisualStudio201xProjectMetaTable  }

local function GetWorkspaceConfigList(workspace)
	if not workspace.Configs then
		return Config.Configurations
	end

	local workspaceConfigs = {}
	for configName in pairs(workspace.Configs) do
		workspaceConfigs[#workspaceConfigs + 1] = configName
	end
	table.sort(workspaceConfigs)
	return workspaceConfigs
end

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

local function RealVSConfig(platform, config, forceNativePlatform)
	local realConfig = GetMapConfigToVSConfig(config)
	if forceNativePlatform  or  (VSNativePlatforms  and  VSNativePlatforms[platform]) then
		return realConfig
	end

	return GetMapPlatformToVSPlatform(platform) .. ' ' .. realConfig
end

-- For a source group, find the depth to which all files (excluding jam files) share the same absolute path.
local function FindCommonPathDepth(sourceGroup)
	-- Files have nothing to be common with; call that depth 0.
	if type(sourceGroup) ~= 'table' then
		return 0
	end

	local children = {}

	-- Count children, excluding jamfiles.
	-- The jamfile exclusing only seems to work because they are always on their own in the source group;
	-- if they were contained within their directory we would have to prune this from the source group.
	for child in ivalues(sourceGroup) do
		if type(child) == 'table' or not child:match("%w+%.jam") then
			table.insert(children, child)
		end
	end

	if # children == 1 then
		-- If there's exactly one entry (excluding jamfiles) under this one, carry on to the next level, as all children share this part of the path.
		return 1 + FindCommonPathDepth(children[1])
	else
		-- If there is more than one item under this one, that's because they don't share the next directory.
		return 0
	end
end

function VisualStudio201xProjectMetaTable:WriteHelper(outputPath, commandLines, androidApplication)
    local fileTitle = self.ProjectName .. (androidApplication  and  '-android'  or '')
	local filename = ospath.join(outputPath, fileTitle .. '.vcxproj')
	local userContents = {}

	local project = Projects[self.ProjectName]

	if project.ExternalProject then
		local filename = project.RelativePath
		local info = { Name = self.ProjectName, Filename = filename }
		local extension = ospath.get_extension(filename)
		if extension == '.csproj' then
			local buffer = ospath.read_file(filename)
			if buffer then
				local xml = require 'xmlize'.luaize(buffer)
				if xml.Project  and  xml.Project[1] then
					if xml.Project[1]['#'].PropertyGroup then
						for _, propertyGroup in ipairs(xml.Project[1]['#'].PropertyGroup) do
							if propertyGroup['#'].ProjectGuid then
								info.Uuid = '{' .. propertyGroup['#'].ProjectGuid[1]['#']:upper() .. '}'
							end
							if propertyGroup['@'].Condition then
								local condition = propertyGroup['@'].Condition
								local config, platform = condition:match("'%$%(Configuration%)|%$%(Platform%)' == '([^|]*)|(.*)'")
								if config then
									if not info.FoundConfigs then
										info.FoundConfigs = {}
									end
									info.FoundConfigs[config] = true
									if not info.FoundPlatforms then
										info.FoundPlatforms = {}
									end
									info.FoundPlatforms[platform] = true
								end
							end
						end
					end
				end
			end
		end
		if not info.Uuid then
			info.Uuid = '{' .. uuid.new():upper() .. '}'
		end
		ProjectExportInfo[self.ProjectName] = info
		return
	end

	local info = ProjectExportInfo[self.ProjectName .. (androidApplication  and  '-android'  or  '')]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
		ProjectExportInfo[self.ProjectName .. (androidApplication  and  '-android'  or  '')] = info
	else
		info.Filename = filename
	end

	-- Write header.
    if self.Options.vs2015 then
        table.insert(self.Contents, expand([[
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="14.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
]]))
    else
        table.insert(self.Contents, expand([[
<?xml version="1.0" encoding="utf-8"?>
<Project DefaultTargets="Build" ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
]]))
    end

	-- Write Configurations header
	table.insert(self.Contents, [[
  <ItemGroup Label="ProjectConfigurations">
]])

    local projectPlatforms = Config.Platforms
    if androidApplication then
        projectPlatforms = { 'ARM', 'ARM64', 'x86' }
    end
	local workspaceConfigs = GetWorkspaceConfigList(self.Workspace)
	for platformName in ivalues(projectPlatforms) do
		for configName in ivalues(workspaceConfigs) do
			local configInfo = {}
			if androidApplication then
				configInfo.VSPlatform = platformName
				configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  RealVSConfig(platformName, configName, true)  or  configName
			else
				configInfo.VSPlatform = RealVSPlatform(platformName)
				configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  RealVSConfig(platformName, configName)  or  configName
			end
			table.insert(self.Contents, expand([==[
    <ProjectConfiguration Include="$(VSConfig)|$(VSPlatform)">
      <Configuration>$(VSConfig)</Configuration>
      <Platform>$(VSPlatform)</Platform>
    </ProjectConfiguration>
]==], configInfo, info, _G))
		end
	end

	table.insert(self.Contents, [[
  </ItemGroup>
]])

	-- Write Globals
	do
		local extraInfo = {}
		if self.Options.vs2010 then
			extraInfo.TargetFrameworkVersion = "v4.0"
		elseif self.Options.vs2012 then
			extraInfo.TargetFrameworkVersion = "v4.5"
		elseif self.Options.vs2013 then
			extraInfo.TargetFrameworkVersion = "v4.5"
		elseif self.Options.vs2015 then
			extraInfo.TargetFrameworkVersion = "v4.5.2"
		end
		table.insert(self.Contents, expand([[
  <PropertyGroup Label="Globals">
    <ProjectGUID>$(Uuid)</ProjectGUID>
    <TargetFrameworkVersion>$(TargetFrameworkVersion)</TargetFrameworkVersion>
    <Keyword>MakeFileProj</Keyword>
    <ProjectName>$(Name)</ProjectName>
]], extraInfo, info))

        if androidApplication then
            table.insert(self.Contents, expand([[
    <ApplicationType>Android</ApplicationType>
    <ApplicationTypeRevision>2.0</ApplicationTypeRevision>
]], extraInfo, info))
        end

		table.insert(self.Contents, expand([[
  </PropertyGroup>
]], extraInfo, info))
	end

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
]])

	-- Write Configurations.
	for platformName in ivalues(projectPlatforms) do
		local toolchainPlatform = platformName
		for workspaceConfigName in ivalues(workspaceConfigs) do
			local jamCommandLine = ospath.escape(ospath.make_backslash(jamScript)) .. ' ' ..
					ospath.escape('-C' .. destinationRootPath) ..
					' -g'

			local configName = workspaceConfigName
			local customWorkspaceConfig = self.Workspace  and  self.Workspace.Configs  and  self.Workspace.Configs[workspaceConfigName]
			if customWorkspaceConfig then
				jamCommandLine = jamCommandLine .. ' ' .. table.concat(customWorkspaceConfig.CommandLineOptions, ' ')
				configName = customWorkspaceConfig.ActualConfigName
			elseif androidApplication then
				platformName = 'android'
				jamCommandLine = jamCommandLine .. ' C.TOOLCHAIN=' .. platformName .. '/' .. configName .. '@C.ARCHITECTURE=' .. toolchainPlatform
			else
				jamCommandLine = jamCommandLine .. ' C.TOOLCHAIN=' .. platformName .. '/' .. configName
			end

			local configInfo =
			{
				Platform = platformName,
				PLATFORM = platformName,
				Config = configName,
				WorkspaceConfigName = workspaceConfigName,
				Defines = '',
				Includes = '',
				Output = '',
				OutputPath = '',
				ForceIncludes = '',
			}

			if androidApplication then
				configInfo.VSPlatform = toolchainPlatform
				configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  RealVSConfig(platformName, configName, true)  or  workspaceConfigName
			else
				configInfo.VSPlatform = RealVSPlatform(platformName)
				configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  RealVSConfig(platformName, configName)  or  workspaceConfigName
			end

			if project and project.Name and project.Name ~= '!BuildWorkspace' and project.Name ~= '!UpdateWorkspace' then
				if project.Defines and project.Defines[platformName] and project.Defines[platformName][configName] then
					configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
				end
				if project.IncludePaths and project.IncludePaths[platformName] and project.IncludePaths[platformName][configName] then
					configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
				end
				if project.OutputPaths and project.OutputPaths[platformName] and project.OutputPaths[platformName][configName] 
					and project.OutputNames and project.OutputNames[platformName] and project.OutputNames[platformName][configName] then
					configInfo.OutputPath = project.OutputPaths[platformName][configName]
					configInfo.Output = project.OutputPaths[platformName][configName] .. project.OutputNames[platformName][configName]
				end
				if project.DebuggerOutputNames  and  project.DebuggerOutputNames[platformName]  and  project.DebuggerOutputNames[platformName][configName] then
					configInfo.Output = project.DebuggerOutputNames[platformName][configName]
				end
				configInfo.BuildCommandLine = jamCommandLine .. ' ' .. self.ProjectName
				configInfo.RebuildCommandLine = jamCommandLine .. ' -a ' .. self.ProjectName
				configInfo.CleanCommandLine = jamCommandLine .. ' clean:' .. self.ProjectName
				if project.ForceIncludes  and  project.ForceIncludes[platformName]  and  project.ForceIncludes[platformName][configName] then
					configInfo.ForceIncludes = table.concat(project.ForceIncludes[platformName][configName], ';')
				end
			else
				configInfo.BuildCommandLine = project.BuildCommandLine and project.BuildCommandLine[1] or jamCommandLine
				configInfo.RebuildCommandLine = project.RebuildCommandLine and project.RebuildCommandLine[1] or (jamCommandLine .. ' -a')
				configInfo.CleanCommandLine = project.CleanCommandLine and project.CleanCommandLine[1] or (jamCommandLine .. ' clean')
			end

			configInfo.BuildCommandLine = configInfo.BuildCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')
			configInfo.RebuildCommandLine = configInfo.RebuildCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')
			configInfo.CleanCommandLine = configInfo.CleanCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')

			table.insert(self.Contents, expand([==[
  <PropertyGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'" Label="Configuration">
    <ConfigurationType>Makefile</ConfigurationType>
    <BuildLogFile>$(ospath.join(_getWorkspacePath(), '_logs_'))/$(Platform)-$(Config)/$$(MSBuildProjectName).log</BuildLogFile>
    <NMakeBuildCommandLine>$(BuildCommandLine)</NMakeBuildCommandLine>
    <NMakeOutput>$(Output)</NMakeOutput>
    <NMakeCleanCommandLine>$(CleanCommandLine)</NMakeCleanCommandLine>
    <NMakeReBuildCommandLine>$(RebuildCommandLine)</NMakeReBuildCommandLine>
    <NMakePreprocessorDefinitions>$(Defines)</NMakePreprocessorDefinitions>
    <NMakeIncludeSearchPath>$(Includes)</NMakeIncludeSearchPath>
    <OutDir>$(OutputPath)</OutDir>
    <IntDir>$$(SolutionDir)/_intermediates_/$(Platform)-$(Config)/$$(MSBuildProjectName)</IntDir>
]==], configInfo, info, _G))

			if configInfo.ForceIncludes ~= '' then
				self.Contents[#self.Contents + 1] = expand([==[
    <NMakeForcedIncludes>$(ForceIncludes)</NMakeForcedIncludes>
]==], configInfo, info, _G)
			end

            if androidApplication then
                if project.PackagePath  and  project.PackagePath[platformName]  and  project.PackagePath[platformName][configName]
                        and  project.AdditionalSymbolSearchPaths  and  project.AdditionalSymbolSearchPaths[platformName]  and  project.AdditionalSymbolSearchPaths[platformName][configName] then
                    configInfo.PackagePath = project.PackagePath[platformName][configName]
                    configInfo.AdditionalSymbolSearchPaths = project.AdditionalSymbolSearchPaths[platformName][configName]
                    userContents[#userContents + 1] = expand([==[
  <PropertyGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'">
    <LocalDebuggerWorkingDirectory>$(OutputPath)</LocalDebuggerWorkingDirectory>
    <DebuggerFlavor>AndroidDebugger</DebuggerFlavor>
    <PackagePath>$(PackagePath)</PackagePath>
    <AdditionalSymbolSearchPaths>$(AdditionalSymbolSearchPaths)</AdditionalSymbolSearchPaths>
  </PropertyGroup>
]==], configInfo, info, _G)
                end
            else
                userContents[#userContents + 1] = expand([==[
  <PropertyGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'">
    <LocalDebuggerWorkingDirectory>$(OutputPath)</LocalDebuggerWorkingDirectory>
    <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
  </PropertyGroup>
]==], configInfo, info, _G)
            end

			if self.Options.vs2012 then
				self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v110</PlatformToolset>
]]
			elseif self.Options.vs2013 then
				self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v120</PlatformToolset>
]]
			elseif self.Options.vs2015 then
				if androidApplication then
					self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>Clang_3_8</PlatformToolset>
]]
				else
					self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v140</PlatformToolset>
]]
				end
			end
			self.Contents[#self.Contents + 1] = [[
  </PropertyGroup>
]]

			self.Contents[#self.Contents + 1] = expand([==[
  <ItemDefinitionGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'">
    <Link>
]==], configInfo, info, _G)
			if project.Options then
				if project.Options.windows then
					self.Contents[#self.Contents + 1] = [==[
      <SubSystem>Windows</SubSystem>
]==]
				else
					self.Contents[#self.Contents + 1] = [==[
      <SubSystem>Console</SubSystem>
]==]
				end
			end

			self.Contents[#self.Contents + 1] = expand([==[
    </Link>
    <BuildLog>
      <Path>$(ospath.join(_getWorkspacePath(), '_logs_'))/$(Platform)-$(Config)/$$(MSBuildProjectName).log</Path>
    </BuildLog>
  </ItemDefinitionGroup>
]==], configInfo, info, _G)
		end
	end

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />
]])

	-- Write Files.
	table.insert(self.Contents, [[
  <ItemGroup>
]])
	self:_WriteFilesFlat(project.SourcesTree)
	table.insert(self.Contents, [[
  </ItemGroup>
]])

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.targets" />
]])

	-- Write footer.
	table.insert(self.Contents, [[
</Project>
]])
	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)

	if userContents[1] then
		local userFilename = ospath.join(outputPath, fileTitle .. '.vcxproj.user')
		userContents = [[
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="12.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
]] .. table.concat(userContents) .. [[
</Project>
]]
		userContents = userContents:gsub('\r\n', '\n'):gsub('\n', '\r\n')
		WriteFileIfModified(userFilename, userContents)
	end

	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	-- Write the .vcxproj.filters file.
	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	local filename = ospath.join(outputPath, fileTitle .. '.vcxproj.filters')
	self.Contents = {}

	-- Write header.
	table.insert(self.Contents, [[
<?xml version="1.0" encoding="utf-8"?>
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
]])

	-- Write folders.
	table.insert(self.Contents, [[
  <ItemGroup>
]])

	local commonPathDepth = 0

	if project then
		commonPathDepth = FindCommonPathDepth(project.SourcesTree)
	end

	if project then
		self:_WriteFolders(project.SourcesTree, '', 0, commonPathDepth)
	end

	table.insert(self.Contents, [[
  </ItemGroup>
]])

	-- Write Files.
	table.insert(self.Contents, [[
  <ItemGroup>
]])

	if project then
		self:_WriteFiles(project.SourcesTree, '', 0, commonPathDepth)
	end

	table.insert(self.Contents, [[
  </ItemGroup>
]])

	-- Write footer.
	table.insert(self.Contents, [[
</Project>
]])

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)
end


function VisualStudio201xProjectMetaTable:Write(outputPath, commandLines)
    for platformName in ivalues(Config.Platforms) do
        if platformName == 'android' then
            local project = Projects[self.ProjectName]
            if project.Options  and  project.Options.app then
                self:WriteHelper(outputPath, commandLines, true)
                self.Contents = {}
            end
            break
        end
    end
    self:WriteHelper(outputPath, commandLines)
end


function VisualStudio201xProject(projectName, options, workspace, project)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
			Workspace = workspace,
			Project = project,
		}, { __index = VisualStudio201xProjectMetaTable }
	)
end


function VisualStudio201xProjectMetaTable:_WriteFolders(folder, inFilter, depth, rootDepth)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local filter = inFilter

			-- Ignore the first 'rootDepth' segments of the path when naming a filter, to avoid the unnecessary shared parts of absolute paths being generated as filters.
			if depth >= rootDepth then
				if filter ~= '' then filter = filter .. '\\' end
				filter = filter .. entry.folder
			end

			self:_WriteFolders(entry, filter, depth + 1, rootDepth)

			if depth >= rootDepth then
				table.insert(self.Contents, "    <Filter Include=\"" .. filter .. "\"/>\n")
			end
		end
	end
end


function VisualStudio201xProjectMetaTable:_WriteFiles(folder, inFilter, depth, rootDepth)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local filter = inFilter

			-- Ignore the first 'rootDepth' segments of the path when naming a filter, to avoid the unnecessary shared parts of absolute paths being generated as filters.
			if depth >= rootDepth then
				if filter ~= '' then filter = filter .. '\\' end
				filter = filter .. entry.folder
			end

			self:_WriteFiles(entry, filter, depth + 1, rootDepth)
		else
			table.insert(self.Contents, '    <None Include="' .. ospath.make_backslash(entry) .. '">\n')
			table.insert(self.Contents, '      <Filter>' .. inFilter .. '</Filter>\n')
			table.insert(self.Contents, '    </None>\n')
		end
	end
end


function VisualStudio201xProjectMetaTable:_WriteFilesFlat(folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self:_WriteFilesFlat(entry)
		else
			table.insert(self.Contents, '    <None Include="' .. ospath.make_backslash(entry) .. '" />\n')
		end
	end
end






local VisualStudio201xSolutionMetaTable = {  __index = VisualStudio201xSolutionMetaTable  }

function VisualStudio201xSolutionMetaTable:_GatherSolutionFolders(folder, folderList, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local solutionFolder = fullPath .. '\\' .. entry.folder
			table.insert(folderList, solutionFolder)
			self:_GatherSolutionFolders(entry, folderList, solutionFolder)
		end
	end
end


function VisualStudio201xSolutionMetaTable:_WriteNestedProjects(folder, fullPath)
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


function VisualStudio201xSolutionMetaTable:Write(outputPath)
	local filename = ospath.join(outputPath, self.Name .. '.sln')

	local workspace = Workspaces[self.Name]

	-- Write header.
	table.insert(self.Contents, '\xef\xbb\xbf\n')

	if self.Options.vs2010 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 2010
]])
	elseif self.Options.vs2012 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 2012
]])
	elseif self.Options.vs2013 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 2013
VisualStudioVersion = 12.0.21005.1
MinimumVisualStudioVersion = 10.0.40219.1
]])
	elseif self.Options.vs2015 then
		table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 12.00
# Visual Studio 14
VisualStudioVersion = 14.0.22310.1
MinimumVisualStudioVersion = 10.0.40219.1
]])
	end

	-- Write projects.
	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		if info then
			local extension = ospath.get_extension(info.Filename)
			info.ProjectType = solutionProjectTypes[extension]
			if not info.ProjectType then
				print('Error: Unknown project type for external project [' .. info.Filename .. '].')
			else
				table.insert(self.Contents, expand([[
Project("$(ProjectType)") = "$(Name)", "$(Filename:gsub('/', '\\'))", "$(Uuid)"
EndProject
]], info))
			end
		end

		-- As a hack, test also for Android projects.
		local info = ProjectExportInfo[projectName .. '-android']
		if info then
			local extension = ospath.get_extension(info.Filename)
			info.ProjectType = solutionProjectTypes[extension]
			if not info.ProjectType then
				print('Error: Unknown project type for external project [' .. info.Filename .. '].')
			else
				table.insert(self.Contents, expand([[
Project("$(ProjectType)") = "$(Name)", "$(Filename:gsub('/', '\\'))", "$(Uuid)"
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

	local workspaceConfigs = GetWorkspaceConfigList(workspace)
	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(workspaceConfigs) do
			local configInfo = {}
			configInfo.VSPlatform = GetMapPlatformToVSPlatform(platformName)
			configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  GetMapConfigToVSConfig(configName)  or  configName
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

	function WriteSolutionConfigInfo(projectName)
		local info = ProjectExportInfo[projectName]
		if not info then return end

		for platformName in ivalues(Config.Platforms) do
			for configName in ivalues(workspaceConfigs) do
				local configInfo = {}
				configInfo.VSPlatform = GetMapPlatformToVSPlatform(platformName)
				configInfo.VSConfig = workspaceConfigs == Config.Configurations  and  GetMapConfigToVSConfig(configName)  or  configName

				if info.FoundPlatforms then
					for foundPlatformName in pairs(info.FoundPlatforms) do
						if platformName:lower() == foundPlatformName:lower() then
							configInfo.RealVSPlatform = foundPlatformName
							break
						end
					end
					if not configInfo.RealVSPlatform then
						if info.FoundPlatforms['AnyCPU'] then
							configInfo.RealVSPlatform = 'Any CPU'
						end
					end
				end

				if not configInfo.RealVSPlatform then
					configInfo.RealVSPlatform = RealVSPlatform(platformName)
				end

				if info.FoundConfigs then
					for foundConfigName in pairs(info.FoundConfigs) do
						if configName:lower() == foundConfigName:lower() then
							configInfo.RealVSConfig = foundConfigName
							break
						end
					end

					if not configInfo.RealVSConfig then
						for foundConfigName in pairs(info.FoundConfigs) do
							if ('^' .. configName:lower()):match(foundConfigName:lower()) then
								configInfo.RealVSConfig = foundConfigName
								break
							end
						end
					end
				end

				if not configInfo.RealVSConfig then
					configInfo.RealVSConfig = RealVSConfig(platformName, configName)
				end

				table.insert(self.Contents, expand([[
			$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(RealVSConfig)|$(RealVSPlatform)
	]], configInfo, info))

				if projectName == buildWorkspaceName then
					table.insert(self.Contents, expand([[
			$(Uuid).$(VSConfig)|$(VSPlatform).Build.0 = $(RealVSConfig)|$(RealVSPlatform)
	]], configInfo, info))
				end
			end
		end
	end

	WriteSolutionConfigInfo(buildWorkspaceName)
	WriteSolutionConfigInfo(updateWorkspaceName)

	for projectName in ivalues(workspace.Projects) do
		WriteSolutionConfigInfo(projectName)
		WriteSolutionConfigInfo(projectName .. '-android')
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

function VisualStudio201xSolution(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = VisualStudio201xSolutionMetaTable }
	)
end



function VisualStudio201xInitialize()
	local chunk = loadfile(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'))
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function VisualStudio201xShutdown()
	prettydump.dumpascii(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'), 'ProjectExportInfo', ProjectExportInfo)
end





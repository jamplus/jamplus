-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local uuid = require 'uuid'

local VisualStudio201xProjectMetaTable = {  __index = VisualStudio201xProjectMetaTable  }

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

function VisualStudio201xProjectMetaTable:Write(outputPath, commandLines)
	local filename = ospath.join(outputPath, self.ProjectName .. '.vcxproj')
	local userContents = {}

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
		ProjectExportInfo[self.ProjectName] = info
	else
		info.Filename = filename
	end

	local project = Projects[self.ProjectName]

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

	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = RealVSPlatform(platformName),
				VSConfig = RealVSConfig(platformName, configName),
			}
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
			extraInfo.TargetFrameworkVersion = "v4.5"
		end
		table.insert(self.Contents, expand([[
  <PropertyGroup Label="Globals">
    <ProjectGUID>$(Uuid)</ProjectGUID>
    <TargetFrameworkVersion>$(TargetFrameworkVersion)</TargetFrameworkVersion>
    <Keyword>MakeFileProj</Keyword>
    <ProjectName>$(Name)</ProjectName>
  </PropertyGroup>
]], extraInfo, info))
	end

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
]])

	-- Write Configurations.
	for platformName in ivalues(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local jamCommandLine = ospath.escape(ospath.make_backslash(jamScript)) .. ' ' ..
					ospath.escape('-C' .. destinationRootPath) .. ' ' ..
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
				OutputPath = '',
			}

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
    <BuildLogFile>$(ospath.make_backslash(destinationRootPath))$(Platform)-$(Config)/$$(MSBuildProjectName).log</BuildLogFile>
    <NMakeBuildCommandLine>$(BuildCommandLine)</NMakeBuildCommandLine>
    <NMakeOutput>$(Output)</NMakeOutput>
    <NMakeCleanCommandLine>$(CleanCommandLine)</NMakeCleanCommandLine>
    <NMakeReBuildCommandLine>$(RebuildCommandLine)</NMakeReBuildCommandLine>
    <NMakePreprocessorDefinitions>$(Defines)</NMakePreprocessorDefinitions>
    <NMakeIncludeSearchPath>$(Includes)</NMakeIncludeSearchPath>
]==], configInfo, info, _G))

			userContents[#userContents + 1] = expand([==[
  <PropertyGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'">
    <LocalDebuggerWorkingDirectory>$(OutputPath)</LocalDebuggerWorkingDirectory>
    <DebuggerFlavor>WindowsLocalDebugger</DebuggerFlavor>
  </PropertyGroup>
]==], configInfo, info, _G)

			if self.Options.vs2012 then
				self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v110</PlatformToolset>
]]
			elseif self.Options.vs2013 then
				self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v120</PlatformToolset>
]]
			elseif self.Options.vs2015 then
				self.Contents[#self.Contents + 1] = [[
    <PlatformToolset>v140</PlatformToolset>
]]
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
  </ItemDefinitionGroup>
]==])
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
		local userFilename = ospath.join(outputPath, self.ProjectName .. '.vcxproj.user')
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
	local filename = ospath.join(outputPath, self.ProjectName .. '.vcxproj.filters')
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

function VisualStudio201xProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
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
			table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename:gsub('/', '\\'))", "$(Uuid)"
EndProject
]], info))
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





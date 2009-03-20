-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
require 'std'
require 'ex'
require 'iox'
require 'md5'
require 'uuid'
local expand = require 'expand'

scriptPath = ((debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. '\\'):gsub('\\', '/'):lower()
package.path = scriptPath .. "?.lua;" .. package.path
require 'FolderTree'

jamPath = iox.PathMakeAbsolute(scriptPath .. '../'):gsub('\\', '/')
jamExePath = iox.PathMakeAbsolute(jamPath .. 'jam.exe')

Config =
{
	Configurations = { 'debug', 'release' }
}

Compilers =
{
	{ 'vs2008', 'Visual Studio 2008' },
	{ 'vs2005', 'Visual Studio 2005' },
	{ 'vs2003', 'Visual Studio 2003' },
	{ 'vs2002', 'Visual Studio 2002' },
	{ 'vc6',	'Visual C++ 6' },
	{ 'mingw',	'MinGW' },
}

local buildWorkspaceName = '!BuildWorkspace'
local updateWorkspaceName = '!UpdateWorkspace'

function ivalues(t)
	if not t then return function() return nil end end
	local n = 0
	return function()
		n = n + 1
		return t[n]
	end
end

function list.find(searchList, value)
	for index = 1, #searchList do
		if searchList[index] == value then
			return index
		end
	end
end

-- popen2()
function popen2(...)
	local in_rd, in_wr = io.pipe()
	local out_rd, out_wr = io.pipe()
	local proc, err = os.spawn{stdin = in_rd, stdout = out_wr, ...}
	in_rd:close(); out_wr:close()
	if not proc then
		in_wr:close(); out_rd:close()
		return proc, err
	end
	return proc, out_rd, in_wr
end


function ErrorHandler(inMessage)
	message = {}
	table.insert(message, [[

-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
]])
	if inMessage then
		table.insert(message, '-- ')
		table.insert(message, inMessage)
		table.insert(message, ':\n')
	end
	if ErrorInfo then
		for key, value in pairs(ErrorInfo) do
			table.insert(message,
					string.format('--       %s(%s): %s',
							key, type(value), tostring(value)))
		end
	end
	table.insert(message, [[
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
]])

	table.insert(message, debug.traceback())
	return table.concat(message)
end


function WriteFileIfModified(filename, contents)
	local writeFile = iox.access(filename) == -1
	if not writeFile then
		local md5Contents = md5.digest(contents)
		local md5File = md5.new()
		md5File:updatefile(filename .. '.cache')
		writeFile = md5Contents ~= md5File:digest()
	end
	if writeFile then
		iox.PathCreate(filename)
		io.writeall(filename, contents)
		io.writeall(filename .. '.cache', contents)
	end
end


function ProcessCommandLine()
	local options = Options {
		Option {{"gen"}, "Set a project generator", "Req", 'GENERATOR'},
		Option {{"compiler"}, "Set the default compiler used to build with", "Req", 'COMPILER'},
		Option {{"postfix"}, "Extra text for the IDE project name"},
		Option {{"config"}, "Filename of additional configuration file", "Req", 'CONFIG'},
	}

	nonOpts, opts, errors = getopt.getOpt (arg, options)
	if #errors > 0  or
		(#nonOpts ~= 1  and  #nonOpts ~= 2) or
		not opts.gen or
		not Exporters[opts.gen]
	then
		print (table.concat (errors, "\n") .. "\n" ..
				getopt.usageInfo ("Usage: JamToWorkspace [options] <source-jamfile> <path-to-destination>",
				options))

		local sortedExporters = {}
		for exporterName in pairs(Exporters) do
			sortedExporters[#sortedExporters + 1] = exporterName
		end
		table.sort(sortedExporters)

		local genOptions = {}
		for exporterName in ivalues(sortedExporters) do
			genOptions[#genOptions + 1] =
				Option{ { exporterName }, Exporters[exporterName].Description }
		end
		genOptions = Options(genOptions)

		print(getopt.usageInfo("\nAvailable workspace generators:", genOptions))

		local compilerOptions = {}
		for compilerInfo in ivalues(Compilers) do
			compilerOptions[#compilerOptions + 1] =
				Option{ { compilerInfo[1] }, compilerInfo[2] }
		end
		compilerOptions = Options(compilerOptions)

		print(getopt.usageInfo("\nAvailable compilers:", compilerOptions))

		os.exit(-1)
	end
end

function CreateTargetInfoFiles()
	function DumpConfig(platform, config)
		local collectConfigurationArgs =
		{
			'"-C' .. destinationRootPath .. '"',
			'"-sJAMFILE=' .. destinationRootPath .. 'DumpJamTargetInfo.jam"',
			'-sTARGETINFO_LOCATE=' .. destinationRootPath .. 'TargetInfo/',
			'-sPLATFORM=' .. platform,
			'-sCONFIG=' .. config,
			'-d0',
		}

		print('Writing platform [' .. platform .. '] and config [' .. config .. ']...')
		local p, i, o = popen2('"' .. jamExePath .. '"', unpack(collectConfigurationArgs))
--		print(jamExePath .. ' ' .. table.concat(collectConfigurationArgs, ' '))
--		print(p, i, o)
		io.write(i:read("*a"))
		p:wait()
	end

	DumpConfig('*', '*')
	DumpConfig('win32', '*')
	for config in ivalues(Config.Configurations) do
		DumpConfig('win32', config)
	end
end

function ReadTargetInfoFiles()
	function ReadTargetInfo(platform, config)
		local targetInfoFilename = destinationRootPath .. 'TargetInfo/TargetInfo.' ..
				(platform == '*' and '[all]' or platform) .. '.' ..
				(config == '*' and '[all]' or config) .. '.lua'
		local chunk, message = loadfile(targetInfoFilename)
		if not chunk then
			error('* Error parsing ' .. targetInfoFilename .. '.\n\n' .. message)
		end
		chunk()
	end

	ReadTargetInfo('*', '*')
	ReadTargetInfo('win32', '*')
	for config in ivalues(Config.Configurations) do
		ReadTargetInfo('win32', config)
	end

	AutoWriteMetaTable.active = false
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
MapPlatformToVSPlatform =
{
	['win32'] = 'Win32',
}

MapConfigToVSConfig =
{
	['debug'] = 'Debug',
	['release'] = 'Release',
}

local VisualStudioProjectMetaTable = {  __index = VisualStudioProjectMetaTable  }

function VisualStudioProjectMetaTable:Write(outputPath, commandLines)
	local filename = outputPath .. self.ProjectName .. '.vcproj'

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = uuid.new():upper() }
		ProjectExportInfo[self.ProjectName] = info
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
	if self.Options.vs2003 then
		table.insert(self.Contents, [[
	<Platforms>
		<Platform
			Name="Win32"/>
	</Platforms>
]])
	elseif self.Options.vs2005 or self.Options.vs2008 then
		table.insert(self.Contents, [[
	<Platforms>
		<Platform
			Name="Win32"
		/>
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

	local platformName = 'win32'
	for configName in ivalues(Config.Configurations) do
		local jamCommandLine = jamExePath ..
				' -C' .. destinationRootPath ..
				' -sPLATFORM=' .. platformName ..
				' -sCONFIG=' .. configName

		local configInfo =
		{
			Platform = platformName,
			Config = configName,
			VSPlatform = MapPlatformToVSPlatform[platformName],
			VSConfig = MapConfigToVSConfig[configName],
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

		if self.Options.vs2003 then
			table.insert(self.Contents, expand([==[
		<Configuration
			Name="$(VSConfig)|$(VSPlatform)"
			OutputDirectory="$$(ConfigurationName)"
			IntermediateDirectory="$$(ConfigurationName)"
			ConfigurationType="0"
			BuildLogFile="$(destinationRootPath:gsub('\\', '/'))temp-$(Platform)-$(Config)/BuildLog.htm">
			<Tool
				Name="VCNMakeTool"
				BuildCommandLine="$(BuildCommandLine)"
				ReBuildCommandLine="$(RebuildCommandLine)"
				CleanCommandLine="$(CleanCommandLine)"
				Output="$(Output)"
			/>
		</Configuration>
]==], configInfo, info, _G))

		elseif self.Options.vs2005 or self.Options.vs2008 then
			table.insert(self.Contents, expand([==[
		<Configuration
			Name="$(VSConfig)|$(VSPlatform)"
			OutputDirectory="$$(ConfigurationName)"
			IntermediateDirectory="$$(ConfigurationName)"
			ConfigurationType="0"
			BuildLogFile="$(destinationRootPath:gsub('\\', '/'))temp-$(Platform)-$(Config)/BuildLog.htm"
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
		</Configuration>
]==], configInfo, info, _G))
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

function VisualStudioProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = VisualStudioProjectMetaTable }
	)
end


function VisualStudioProjectMetaTable:_WriteFiles(folder, tabs)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			table.insert(self.Contents, tabs .. '<Filter\n')
			table.insert(self.Contents, tabs .. '\tName="' .. entry.folder .. '"\n')
			table.insert(self.Contents, tabs .. '\t>\n')
			self:_WriteFiles(entry, tabs .. '\t')
			table.insert(self.Contents, tabs .. '</Filter>\n')
		else
			table.insert(self.Contents, tabs .. '<File\n')
			table.insert(self.Contents, tabs .. '\tRelativePath="' .. entry:gsub('/', '\\') .. '"\n')
			table.insert(self.Contents, tabs .. '\t>\n')
			table.insert(self.Contents, tabs .. '</File>\n')
		end
	end
end





local VisualStudioSolutionMetaTable = {  __index = VisualStudioSolutionMetaTable  }

function VisualStudioSolutionMetaTable:_GatherSolutionFolders(folder, folderList, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local solutionFolder = fullPath .. '\\' .. entry.folder
			table.insert(folderList, solutionFolder)
			self:_GatherSolutionFolders(entry, folderList, solutionFolder)
		end
	end
end


function VisualStudioSolutionMetaTable:_WriteNestedProjects(folder, fullPath)
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


function VisualStudioSolutionMetaTable:Write(outputPath)
	local filename = outputPath .. self.Name .. '.sln'

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
		if self.Options.vs2003 then
			table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename)", "$(Uuid)"
	ProjectSection(ProjectDependencies) = postProject
	EndProjectSection
EndProject
]], info))
		elseif self.Options.vs2005 or self.Options.vs2008 then
			table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename)", "$(Uuid)"
EndProject
]], info))
		end
	end

	-- Write the folders we use.
	local folderList = {}
	self:_GatherSolutionFolders(workspace.ProjectTree, folderList, '')

	-- !BuildWorkspace
	local info = ProjectExportInfo[buildWorkspaceName]
	table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename)", "$(Uuid)"
EndProject
]], info))

	-- !UpdateWorkspace
	local info = ProjectExportInfo[updateWorkspaceName]
	table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename)", "$(Uuid)"
EndProject
]], info))

	for solutionFolderName in ivalues(folderList) do
		local info = ProjectExportInfo[solutionFolderName]
		if not info then
			info =
			{
				Name = solutionFolderName:match('.*\\(.+)'),
				Filename = solutionFolderName,
				Uuid = uuid.new():upper()
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

	local platformName = 'win32'
	for configName in ivalues(Config.Configurations) do
		local configInfo =
		{
			VSPlatform = MapPlatformToVSPlatform[platformName],
			VSConfig = MapConfigToVSConfig[configName],
		}
		table.insert(self.Contents, expand([[
		$(VSConfig)|$(VSPlatform) = $(VSConfig)|$(VSPlatform)
]], configInfo))
	end

	table.insert(self.Contents, [[
	EndGlobalSection
]])

	-------------------
	table.insert(self.Contents, [[
	GlobalSection(ProjectConfigurationPlatforms) = postSolution
]])

	for configName in ivalues(Config.Configurations) do
		local info = ProjectExportInfo[buildWorkspaceName]
		local configInfo =
		{
			VSPlatform = MapPlatformToVSPlatform[platformName],
			VSConfig = MapConfigToVSConfig[configName],
		}
		table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(VSConfig)|$(VSPlatform)
]], configInfo, info))

			table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).Build.0 = $(VSConfig)|$(VSPlatform)
]], configInfo, info))
	end

	for configName in ivalues(Config.Configurations) do
		local info = ProjectExportInfo[updateWorkspaceName]
		local configInfo =
		{
			VSPlatform = MapPlatformToVSPlatform[platformName],
			VSConfig = MapConfigToVSConfig[configName],
		}
		table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(VSConfig)|$(VSPlatform)
]], configInfo, info))
	end

	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		for configName in ivalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = MapPlatformToVSPlatform[platformName],
				VSConfig = MapConfigToVSConfig[configName],
			}
			table.insert(self.Contents, expand([[
		$(Uuid).$(VSConfig)|$(VSPlatform).ActiveCfg = $(VSConfig)|$(VSPlatform)
]], configInfo, info))
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

function VisualStudioSolution(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = VisualStudioSolutionMetaTable }
	)
end



function VisualStudioInitialize()
	local chunk = loadfile(destinationRootPath .. 'VSProjectExportInfo.lua')
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function VisualStudioShutdown()
	LuaDumpObject(destinationRootPath .. 'VSProjectExportInfo.lua', 'ProjectExportInfo', ProjectExportInfo)
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
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
		info = { Name = self.ProjectName, Filename = filename, Uuid = uuid.new():upper() }
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

	local platformName = 'win32'
	do
		local configName = 'debug'
		local jamCommandLine = jamExePath ..
				' -C' .. destinationRootPath ..
				' -sPLATFORM=' .. platformName ..
				' -sCONFIG=' .. configName

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
		local jamCommandLine = jamExePath ..
				' -C' .. destinationRootPath ..
				' -sPLATFORM=' .. platformName ..
				' -sCONFIG=' .. configName

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







Exporters =
{
	vs2003 =
	{
		Initialize = VisualStudioInitialize,
		ProjectExporter = VisualStudioProject,
		WorkspaceExporter = VisualStudioSolution,
		Shutdown = VisualStudioShutdown,
		Description = 'Generate Visual Studio 2003 solutions and projects.',
		Options =
		{
			vs2003 = true,
		}
	},

	vs2005 =
	{
		Initialize = VisualStudioInitialize,
		ProjectExporter = VisualStudioProject,
		WorkspaceExporter = VisualStudioSolution,
		Shutdown = VisualStudioShutdown,
		Description = 'Generate Visual Studio 2005 solutions and projects.',
		Options =
		{
			vs2005 = true,
		}
	},

	vs2008 =
	{
		Initialize = VisualStudioInitialize,
		ProjectExporter = VisualStudioProject,
		WorkspaceExporter = VisualStudioSolution,
		Shutdown = VisualStudioShutdown,
		Description = 'Generate Visual Studio 2008 solutions and projects.',
		Options =
		{
			vs2008 = true,
		}
	},

	codeblocks =
	{
		Initialize = CodeBlocksInitialize,
		ProjectExporter = CodeBlocksProject,
		WorkspaceExporter = CodeBlocksWorkspace,
		Shutdown = CodeBlocksShutdown,
		Description = 'Generate CodeBlocks workspaces and projects.',
		Options =
		{
		}
	}
}





function BuildSourceTree(project)
	-- Filter files.
	local files = {}
	local sourcesMap = {}
	for _, source in ipairs(project.Sources) do
		sourcesMap[source:lower()] = source
	end

	-- Add Jamfile.jam.
	sourcesMap[project.Jamfile:lower()] = project.Jamfile

	if project.SourceGroups then
		for sourceGroupName, sourceGroup in pairs(project.SourceGroups) do
			for filename in ivalues(sourceGroup) do
				local lowerFilename = filename:lower()
				if sourcesMap[lowerFilename] then
					FolderTree.InsertName(files, sourceGroupName, filename)
					sourcesMap[lowerFilename] = nil
				end
			end
		end
	end

	for _, filename in pairs(sourcesMap) do
		FolderTree.InsertName(files, '', filename)
	end

	FolderTree.Sort(files)

	project.SourcesTree = files
--	project.SourceGroups = nil
end


function DumpProject(project)
	local outPath = iox.PathCombine(destinationRootPath, project.RelativePath) .. '/'
	iox.PathCreate(outPath)

	BuildSourceTree(project)

	local exporter = Exporters[opts.gen]
	local projectExporter = exporter.ProjectExporter(project.Name, exporter.Options)
	projectExporter:Write(outPath)
end


function BuildProjectTree(workspace)
	-- Filter projects.
	local projects = {}
	local projectsMap = {}
	for project in ivalues(workspace.Projects) do
		projectsMap[project:lower()] = true
	end

	projectsMap[buildWorkspaceName:lower()] = true
	projectsMap[updateWorkspaceName:lower()] = true

	for projectGroupName, projectGroup in pairs(workspace.ProjectGroups) do
		for projectName in ivalues(projectGroup) do
			local lowerProjectName = projectName:lower()
			if projectsMap[lowerProjectName] then
				FolderTree.InsertName(projects, projectGroupName, projectName)
				projectsMap[lowerProjectName] = nil
			end
		end
	end

	for projectName in pairs(projectsMap) do
		FolderTree.InsertName(projects, '', projectName)
	end

	FolderTree.Sort(projects)

	workspace.ProjectTree = projects
	workspace.ProjectGroups = nil
end


function DumpWorkspace(workspace)
	-- Write the !BuildWorkspace project
	local exporter = Exporters[opts.gen]
	Projects[buildWorkspaceName] = {}
	Projects[buildWorkspaceName].Sources =
	{
		jamPath:gsub('\\', '/') .. '/Jambase.jam'
	}
	Projects[buildWorkspaceName].SourcesTree = Projects[buildWorkspaceName].Sources
	local projectExporter = exporter.ProjectExporter(buildWorkspaceName, exporter.Options)
	projectExporter:Write(destinationRootPath)

	-- Write the !UpdateWorkspace project
	local projectExporter = exporter.ProjectExporter(updateWorkspaceName, exporter.Options)
	projectExporter:Write(destinationRootPath,
		{
			destinationRootPath .. 'UpdateWorkspace.bat',
			destinationRootPath .. 'UpdateWorkspace.bat',
		}
	)

	if exporter.Options.vs2005 or exporter.Options.vs2008 then
		local jamSupport = workspace.ProjectGroups['!JamSupport']
		if not jamSupport then
			jamSupport = {}
			workspace.ProjectGroups['!JamSupport'] = jamSupport
		end
		table.insert(jamSupport, buildWorkspaceName)
		table.insert(jamSupport, updateWorkspaceName)
	end

	BuildProjectTree(workspace)

	for projectName in ivalues(workspace.Projects) do
		local project = Projects[projectName]
		DumpProject(project)
	end
end


function BuildProject()
	local exporter = Exporters[opts.gen]
	exporter.Options.compiler = opts.compiler or opts.gen

	iox.PathCreate(destinationRootPath)

	locateTargetText =
	{
		locateTargetText = [[
ALL_LOCATE_TARGET = $(destinationRootPath:gsub('\\', '/'))temp-$$(PLATFORM)-$$(CONFIG) ;
]]
	}

	---------------------------------------------------------------------------
	-- Write the generated DumpJamTargetInfo.jam.
	---------------------------------------------------------------------------
	io.writeall(destinationRootPath .. 'DumpJamTargetInfo.jam', expand([[
$(locateTargetText)
include $(scriptPath)DumpJamTargetInfo.jam ;
]], locateTargetText, _G))

	---------------------------------------------------------------------------
	-- Write the generated Jamfile.jam.
	---------------------------------------------------------------------------
	local jamfileText = { expand([[
# Generated file
$(locateTargetText)
DEPCACHE.standard = $$(ALL_LOCATE_TARGET)/.depcache ;
DEPCACHE = standard ;

]], locateTargetText, _G) }

	-- Write the Jamfile variables out.
	if Config.JamfileVariables then
		for _, variable in ipairs(Config.JamfileVariables) do
			jamfileText[#jamfileText + 1] = variable[1] .. ' = "' .. expand(tostring(variable[2])) .. '" ;\n'
		end
		jamfileText[#jamfileText + 1] = '\n'
	end

	-- Write all the SubDir roots.
	for _, subInclude in ipairs(Config.SubIncludes) do
		local expandTable =
		{
			rootNameText = subInclude[1],
			sourceRootPathText = subInclude[2],
			sourceJamfileText = subInclude[3] or 'Jamfile.jam',
		}
		expandTable.sourceJamfile = expandTable.sourceJamfile or 'Jamfile.jam' ;
		jamfileText[#jamfileText + 1] = expand('$(rootNameText) = $(sourceRootPathText) ;\n', expandTable, _G)
		if subInclude[4] ~= false then
			jamfileText[#jamfileText + 1] = expand('SubInclude $(rootNameText) : $(sourceJamfileText) ;\n', expandTable, _G)
		end
	end

	io.writeall(destinationRootPath .. 'Jamfile.jam', table.concat(jamfileText))

	---------------------------------------------------------------------------
	-- Write the generated Jambase.jam.
	---------------------------------------------------------------------------
	local jambaseText = { '# Generated file\n' }

	-- Write the Jambase variables out.
	if Config.JambaseVariables then
		for _, variable in ipairs(Config.JambaseVariables) do
			jambaseText[#jambaseText + 1] = variable[1] .. ' = "' .. expand(tostring(variable[2])) .. '" ;\n'
		end
		jambaseText[#jambaseText + 1] = '\n'
	end

	jambaseText[#jambaseText + 1] = expand([[
COMPILER = $(compiler) ;
include $(jamPath)Jambase.jam ;
]], exporter.Options, _G)
	io.writeall(destinationRootPath .. 'Jambase.jam', table.concat(jambaseText))

	-- Read the target information.
	CreateTargetInfoFiles()
	ReadTargetInfoFiles()

	-- Write jam.bat.
	io.writeall(destinationRootPath .. 'jam.bat',
			'@"' .. jamExePath .. '" "-C' .. destinationRootPath .. '" %*\n')

	-- Write UpdateWorkspace.bat.
	local contents = '@"' .. scriptPath .. 'JamToWorkspace.bat" --gen=' ..
			opts.gen .. ' --compiler=' .. exporter.Options.compiler .. ' '
	contents = contents .. '"--config=' .. destinationRootPath .. '\\UpdateWorkspace.config" '
	contents = contents .. '"' .. sourceJamfilePath .. '"\n'
	io.writeall(destinationRootPath .. 'UpdateWorkspace.bat', contents)

	-- Write UpdateWorkspace.config.
	LuaDumpObject(destinationRootPath .. 'UpdateWorkspace.config', 'Config', Config)

	-- Export everything.
	exporter.Initialize()

	-- Iterate all the workspaces.
	for _, workspace in pairs(Workspaces) do
		if workspace.Export == nil  or  workspace.Export == true then
			local index = 1

			-- Rid ourselves of duplicates.
			local usedProjects = {}
			while index <= #workspace.Projects do
				local projectName = workspace.Projects[index]
				if usedProjects[projectName] then
					table.remove(workspace.Projects, index)
				else
					usedProjects[projectName] = true
					index = index + 1
				end
			end

			-- Add any of the listed projects' libraries.
			for index = 1, #workspace.Projects do
				local projectName = workspace.Projects[index]
				local project = Projects[projectName]
				if not project then
					print('* Project [' .. projectName .. '] is in workspace [' .. workspace.Name .. '] but not defined.')
					error()
				end
				for projectName in ivalues(project.Libraries) do
					if not usedProjects[projectName] then
						workspace.Projects[#workspace.Projects + 1] = projectName
						usedProjects[projectName] = true
					end
				end
			end

			DumpWorkspace(workspace)

			local workspaceExporter = exporter.WorkspaceExporter(workspace.Name, exporter.Options)
			workspaceExporter:Write(destinationRootPath)
		end
	end

	exporter.Shutdown()
end


ProcessCommandLine()

-- Turn the source code root into an absolute path based on the current working directory.
sourceJamfilePath = iox.PathMakeAbsolute(nonOpts[1]):gsub('\\', '/')
sourceRootPath, sourceJamfile = sourceJamfilePath:match('(.+/)(.*)')
if not sourceRootPath or not sourceJamfile then
	sourceRootPath = sourceJamfilePath
	sourceJamfile = 'Jamfile.jam'
	sourceJamfilePath = sourceRootPath .. '/' .. sourceJamfile
end

Config.SubIncludes =
{
	{ 'AppRoot', '$(sourceRootPath)', sourceJamfile },
}

-- Do the same with the destination.
destinationRootPath = iox.PathAddBackslash(iox.PathMakeAbsolute(nonOpts[2] or '.')):gsub('\\', '/')

-- Load the config file.
if opts.config then
	local chunk, err = loadfile(opts.config)
	if not chunk then
		print('JamToWorkspace: Unable to load config file [' .. opts.config .. '].')
		print(err)
		os.exit(-1)
	end

	local configFile = {}
	setfenv(chunk, configFile)

	local ret, err = pcall(chunk)
	if not ret then
		print('JamToWorkspace: Unable to execute config file [' .. opts.config .. '].')
		print(err)
		os.exit(-1)
	end

	Config = table.merge(Config, configFile.Config)
end

local result, message = xpcall(BuildProject, ErrorHandler)
if not result then
	print(message)
end

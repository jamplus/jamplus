-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
require 'getopt'
require 'ex'
require 'md5'
require 'uuid'
local expand = require 'expand'

scriptPath = os.path.simplify(os.path.make_absolute(((debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. '\\'):gsub('\\', '/'):lower()))
package.path = scriptPath .. "?.lua;" .. package.path
require 'FolderTree'

jamPath = os.path.simplify(os.path.make_absolute(scriptPath .. '../'))

local OS = os.getenv("OS")
local OSPLAT = os.getenv("OSPLAT")
if not OS  or  not OSPLAT then
	print('*** JamToWorkspace must be called directly from Jam.')
	print('\njam --jamtoworkspace ...')
end
jamExePathNoQuotes = os.path.combine(jamPath, OS:lower() .. OSPLAT:lower(), 'jam')
jamExePath = os.path.escape(jamExePathNoQuotes)

Config =
{
	Configurations = { 'debug', 'release', 'releaseltcg' }
}

Compilers =
{
	{ 'vs2010', 'Visual Studio 2010' },
	{ 'vs2008', 'Visual Studio 2008' },
	{ 'vs2005', 'Visual Studio 2005' },
	{ 'vs2003', 'Visual Studio 2003' },
	{ 'vs2002', 'Visual Studio 2002' },
	{ 'vc6',	'Visual C++ 6' },
	{ 'mingw',	'MinGW' },
	{ 'gcc',	'gcc' },
}

if OS == "NT" then
	Platform = 'win32'
	uname = 'windows'
	Config.Platforms = { 'win32' }
else
	local f = io.popen('uname')
	uname = f:read('*a'):lower():gsub('\n', '')
	f:close()
	
	if OS == "MACOSX" then
		Platform = 'macosx'
		
		Config.Platforms = { 'macosx' } -- , 'iphone', 'iphonesimulator' }
	end
end

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

function irvalues(t)
	if not t then return function() return nil end end
	local n = #t + 1
	return function()
		n = n - 1
		return t[n]
	end
end

function list_find(searchList, value)
	for index = 1, #searchList do
		if searchList[index] == value then
			return index
		end
	end
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
	local writeFile = not os.path.exists(filename)
	if not writeFile then
		local md5Contents = md5.digest(contents)
		local md5File = md5.new()
		md5File:updatefile(filename .. '.cache')
		writeFile = md5Contents ~= md5File:digest()
	end
	if writeFile then
		os.mkdir(filename)
		io.writeall(filename, contents)
		io.writeall(filename .. '.cache', contents)
	end
end


function ProcessCommandLine()
	JamFlags = { }

	function ProcessJamFlags(newarg, oldarg)
		local key, value = newarg:match('(.+)=(.+)')
		if not key then
			errors = { 'Invalid --jamflags ' .. newarg .. '.  Must be in KEY=VALUE form.' }
			Usage()
		end
		JamFlags[#JamFlags + 1] = { Key = key, Value = value }
	end

	local options = Options {
		Option {{"gen"}, "Set a project generator", "Req", 'GENERATOR'},
		Option {{"compiler"}, "Set the default compiler used to build with", "Req", 'COMPILER'},
		Option {{"postfix"}, "Extra text for the IDE project name"},
		Option {{"config"}, "Filename of additional configuration file", "Req", 'CONFIG'},
		Option {{"jamflags"}, "Extra flags to make available for each invocation of Jam.  Specify in KEY=VALUE form.", "Req", 'JAMBASE_FLAGS', ProcessJamFlags },
	}

	function Usage()
		print (table.concat (errors, "\n") .. "\n" ..
				getopt.usageInfo ("Usage: jam --workspace [options] <source-jamfile> <path-to-destination>",
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
	
	nonOpts, opts, errors = getopt.getOpt (arg, options)
	opts.gen = opts.gen or 'none'
	if #errors > 0  or
		(#nonOpts ~= 1  and  #nonOpts ~= 2) or
		not Exporters[opts.gen]
	then
		Usage()
	end
end

function CreateTargetInfoFiles()
	function DumpConfig(platform, config)
		local collectConfigurationArgs =
		{
			os.path.escape('-C' .. destinationRootPath),
			os.path.escape('-sJAMFILE=' .. destinationRootPath .. 'DumpJamTargetInfo.jam'),
			os.path.escape('-sTARGETINFO_LOCATE=' .. destinationRootPath .. 'TargetInfo/'),
			'-sPLATFORM=' .. platform,
			'-sCONFIG=' .. config,
			'-d0',
		}

		print('Reading platform [' .. platform .. '] and config [' .. config .. ']...')
		for line in ex.lines{jamExePath, unpack(collectConfigurationArgs)} do
			print(line)
		end
--		print(jamExePath .. ' ' .. table.concat(collectConfigurationArgs, ' '))
--		print(p, i, o)
	end

	DumpConfig('*', '*')
	for platformName in ivalues(Config.Platforms) do
		DumpConfig(platformName, '*')
		for configName in ivalues(Config.Configurations) do
			DumpConfig(platformName, configName)
		end
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
	for platformName in ivalues(Config.Platforms) do
		ReadTargetInfo(platformName, '*')
		for configName in ivalues(Config.Configurations) do
			ReadTargetInfo(platformName, configName)
		end
	end

	AutoWriteMetaTable.active = false
end


-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
VisualC6MapJamPlatformToVC6Platform =
{
	['win32'] = 'Win32',
	['macosx'] = 'Mac OS X',
}

VisualC6MapJamConfigToVC6Config =
{
	['debug'] = 'Debug',
	['release'] = 'Release',
	['releaseltcg'] = 'Release LTCG'
}

local VisualC6ProjectMetaTable = {  __index = VisualC6ProjectMetaTable  }

function VisualC6ProjectMetaTable:Write(outputPath, commandLines)
	local filename = outputPath .. self.ProjectName .. '.dsp'

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename }
		ProjectExportInfo[self.ProjectName] = info
	end

	local project = Projects[self.ProjectName]

	-- Write header.
	table.insert(self.Contents, expand([[
# Microsoft Developer Studio Project File - Name="$(Name)" - Package Owner=<4>
# Microsoft Developer Studio Generated Build File, Format Version 6.00
# ** DO NOT EDIT **

# TARGTYPE "Win32 (x86) External Target" 0x0106

]], info))

	local defaultConfigName = info.Name .. ' - ' ..
			VisualC6MapJamPlatformToVC6Platform[Config.Platforms[1]] .. ' ' ..
			VisualC6MapJamConfigToVC6Config[Config.Configurations[1]]
	table.insert(self.Contents, 'CFG=' .. defaultConfigName .. '\n')

	table.insert(self.Contents, expand([[
!MESSAGE This is not a valid makefile. To build this project using NMAKE,
!MESSAGE use the Export Makefile command and run
!MESSAGE
!MESSAGE NMAKE /f "$(Name).mak".
!MESSAGE
!MESSAGE You can specify a configuration when running NMAKE
!MESSAGE by defining the macro CFG on the command line. For example:
!MESSAGE
!MESSAGE NMAKE /f "$(Name).mak" CFG="]] .. defaultConfigName .. [["
!MESSAGE
!MESSAGE Possible choices for configuration are:
!MESSAGE
]], info))

	for platformName in irvalues(Config.Platforms) do
		for configName in irvalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = VisualC6MapJamPlatformToVC6Platform[platformName],
				VSConfig = VisualC6MapJamConfigToVC6Config[configName],
			}
			table.insert(self.Contents, expand([[
!MESSAGE "$(Name) - $(VSPlatform) $(VSConfig)" (based on "Win32 (x86) External Target")
]], configInfo, info))
		end
	end

	table.insert(self.Contents, [[
!MESSAGE

# Begin Project
# PROP AllowPerConfigDependencies 0
# PROP Scc_ProjName ""
# PROP Scc_LocalPath ""

]])

	-- Write Configurations.
	local first = true
	for platformName in irvalues(Config.Platforms) do
		for configName in irvalues(Config.Configurations) do
			local jamCommandLine = os.path.make_backslash(jamExePathNoQuotes) .. ' ' ..
					os.path.escape('-C' .. destinationRootPath) .. ' ' ..
					'-sPLATFORM=' .. platformName .. ' ' ..
					'-sCONFIG=' .. configName

			local configInfo =
			{
				Platform = platformName,
				Config = configName,
				VSPlatform = VisualC6MapJamPlatformToVC6Platform[platformName],
				VSConfig = VisualC6MapJamConfigToVC6Config[configName],
				Output = '',
				OutputName = '',
				OutputPath = '',
			}

			if project and project.Name then
				if project.OutputPaths then
					configInfo.Output = project.OutputPaths[platformName][configName] .. project.OutputNames[platformName][configName]
					configInfo.OutputName = project.OutputNames[platformName][configName]
					configInfo.OutputPath = project.OutputPaths[platformName][configName]:gsub('/', '\\')
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

			if first then
				table.insert(self.Contents, expand([==[
!IF  "$$(CFG)" == "$(Name) - $(VSPlatform) $(VSConfig)"

]==], configInfo, info))
				first = false
			else
				table.insert(self.Contents, expand([==[
!ELSEIF  "$$(CFG)" == "$(Name) - $(VSPlatform) $(VSConfig)"

]==], configInfo, info))
			end

			table.insert(self.Contents, expand([==[
# PROP BASE Use_MFC
# PROP BASE Use_Debug_Libraries 0
# PROP BASE Output_Dir "$(OutputPath)"
# PROP BASE Intermediate_Dir "$(destinationRootPath:gsub('/', '\\'))temp-$(Platform)-$(Config)"
# PROP BASE Cmd_Line "$(BuildCommandLine)"
# PROP BASE Rebuild_Opt "-a"
# PROP BASE Target_File "$(OutputName)"
# PROP BASE Bsc_Name ""
# PROP BASE Target_Dir "$(OutputPath)"
# PROP Use_MFC
# PROP Use_Debug_Libraries 0
# PROP Output_Dir "$(OutputPath)"
# PROP Intermediate_Dir "$(destinationRootPath:gsub('/', '\\'))temp-$(Platform)-$(Config)"
# PROP Cmd_Line "$(BuildCommandLine)"
# PROP Rebuild_Opt "-a"
# PROP Target_File "$(OutputName)"
# PROP Bsc_Name ""
# PROP Target_Dir ""

]==], configInfo, info, _G))
		end
	end

	-- Write Configurations footer.
	table.insert(self.Contents, [[
!ENDIF

]])

	-- Write Targets.
	table.insert(self.Contents, [[
# Begin Target

]])

	for platformName in irvalues(Config.Platforms) do
		for configName in irvalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = VisualC6MapJamPlatformToVC6Platform[platformName],
				VSConfig = VisualC6MapJamConfigToVC6Config[configName],
			}

			table.insert(self.Contents, expand([==[
# Name "$(Name) - $(VSPlatform) $(VSConfig)"
]==], configInfo, info))
		end
	end

	table.insert(self.Contents, [[

]])

	first = true
	for platformName in irvalues(Config.Platforms) do
		for configName in irvalues(Config.Configurations) do
			local configInfo =
			{
				VSPlatform = VisualC6MapJamPlatformToVC6Platform[platformName],
				VSConfig = VisualC6MapJamConfigToVC6Config[configName],
			}

			if first then
				table.insert(self.Contents, expand([==[
!IF  "$$(CFG)" == "$(Name) - $(VSPlatform) $(VSConfig)"

]==], configInfo, info))
				first = false
			else
				table.insert(self.Contents, expand([==[
!ELSEIF  "$$(CFG)" == "$(Name) - $(VSPlatform) $(VSConfig)"

]==], configInfo, info))
			end
		end
	end

	table.insert(self.Contents, [[
!ENDIF

]])

	-- Write Files.
	if project then
		self:_WriteFiles(project.SourcesTree)
	end

	table.insert(self.Contents, [[
# End Target
# End Project
]])

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)
end

function VisualC6Project(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = VisualC6ProjectMetaTable }
	)
end


function VisualC6ProjectMetaTable:_WriteFiles(folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			table.insert(self.Contents, '# Begin Group "' .. entry.folder .. '"\n\n')
			self:_WriteFiles(entry)
			table.insert(self.Contents, '# End Group\n')
		else
			table.insert(self.Contents, '# Begin Source File\n\n')
			table.insert(self.Contents, 'SOURCE=' .. entry:gsub('/', '\\') .. '\n')
			table.insert(self.Contents, '# End Source File\n')
		end
	end
end





local VisualC6SolutionMetaTable = {  __index = VisualC6SolutionMetaTable  }

function VisualC6SolutionMetaTable:Write(outputPath)
	local filename = outputPath .. self.Name .. '.dsw'

	local workspace = Workspaces[self.Name]

	-- Write header.
	table.insert(self.Contents, [[
Microsoft Developer Studio Workspace File, Format Version 6.00
# WARNING: DO NOT EDIT OR DELETE THIS WORKSPACE FILE!

]])

	-- Write projects.
	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		if info then
			table.insert(self.Contents, expand([[
###############################################################################

Project: "$(Name)"=$(Filename) - Package Owner=<4>

Package=<5>
{{{
}}}

Package=<4>
{{{
}}}

]], info))
		end
	end

	table.insert(self.Contents, [[
###############################################################################

Global:

Package=<5>
{{{
}}}

Package=<3>
{{{
}}}

###############################################################################

]])
	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n'):gsub('\n', '\r\n')

	WriteFileIfModified(filename, self.Contents)
end

function VisualC6Solution(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = VisualC6SolutionMetaTable }
	)
end



function VisualC6Initialize()
	ProjectExportInfo = {}
end


function VisualC6Shutdown()
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
MapPlatformToVSPlatform =
{
	['win32'] = 'Win32',
	['macosx'] = 'Mac OS X',
}

MapConfigToVSConfig =
{
	['debug'] = 'Debug',
	['release'] = 'Release',
	['releaseltcg'] = 'Release LTCG'
}

local VisualStudio200xProjectMetaTable = {  __index = VisualStudio200xProjectMetaTable  }

function VisualStudio200xProjectMetaTable:Write(outputPath, commandLines)
	local filename = outputPath .. self.ProjectName .. '.vcproj'

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
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
]])
		for platformName in ivalues(Config.Platforms) do
			table.insert(self.Content, [[
		<Platform
			Name="]] .. platformName .. [["/>
]])
		end
		table.insert(self.Contents, [[
	</Platforms>
]])
	elseif self.Options.vs2005 or self.Options.vs2008 then
		table.insert(self.Contents, [[
	<Platforms>
]])
		for platformName in ivalues(Config.Platforms) do
			table.insert(self.Contents, [[
		<Platform
			Name="]] .. platformName .. [["
		/>
]])
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
			local jamCommandLine = jamExePath .. ' ' ..
					os.path.escape('-C' .. destinationRootPath) .. ' ' ..
					'-sPLATFORM=' .. platformName .. ' ' ..
					'-sCONFIG=' .. configName

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
			
			configInfo.BuildCommandLine = configInfo.BuildCommandLine:gsub('"', '&quot;')
			configInfo.RebuildCommandLine = configInfo.RebuildCommandLine:gsub('"', '&quot;')
			configInfo.CleanCommandLine = configInfo.CleanCommandLine:gsub('"', '&quot;')

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
			table.insert(self.Contents, tabs .. '\tRelativePath="' .. entry:gsub('/', '\\') .. '"\n')
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
		if info then
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
				VSPlatform = MapPlatformToVSPlatform[platformName],
				VSConfig = MapConfigToVSConfig[configName],
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
	end

	for platformName in ivalues(Config.Platforms) do
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
	end

	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		if info then
			for platformName in ivalues(Config.Platforms) do
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
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	local chunk = loadfile(outPath .. 'VSProjectExportInfo.lua')
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function VisualStudio200xShutdown()
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	LuaDumpObject(outPath .. 'VSProjectExportInfo.lua', 'ProjectExportInfo', ProjectExportInfo)
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local VisualStudio201xProjectMetaTable = {  __index = VisualStudio201xProjectMetaTable  }

function VisualStudio201xProjectMetaTable:Write(outputPath, commandLines)
	local filename = outputPath .. self.ProjectName .. '.vcxproj'

	local info = ProjectExportInfo[self.ProjectName]
	if not info then
		info = { Name = self.ProjectName, Filename = filename, Uuid = '{' .. uuid.new():upper() .. '}' }
		ProjectExportInfo[self.ProjectName] = info
	end

	local project = Projects[self.ProjectName]

	-- Write header.
	table.insert(self.Contents, expand([[
<Project DefaultTargets="Build" ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
]]))

	-- Write Configurations header
	table.insert(self.Contents, [[
  <ItemGroup Label="ProjectConfigurations">
]])

	local platformName = Platform
	for configName in ivalues(Config.Configurations) do
		local configInfo =
		{
			VSPlatform = MapPlatformToVSPlatform[platformName],
			VSConfig = MapConfigToVSConfig[configName],
		}
		table.insert(self.Contents, expand([==[
    <ProjectConfiguration Include="$(VSConfig)|$(VSPlatform)">
      <Configuration>$(VSConfig)</Configuration>
      <Platform>$(VSPlatform)</Platform>
    </ProjectConfiguration>
]==], configInfo, info, _G))
	end

	table.insert(self.Contents, [[
  </ItemGroup>
]])

	-- Write Globals
	table.insert(self.Contents, expand([[
  <PropertyGroup Label="Globals">
    <ProjectGUID>$(Uuid)</ProjectGUID>
    <TargetFrameworkVersion>v4.0</TargetFrameworkVersion>
    <Keyword>MakeFileProj</Keyword>
    <ProjectName>$(Name)</ProjectName>
  </PropertyGroup>
]], info))

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.Default.props" />
]])

	table.insert(self.Contents, [[
  <Import Project="$(VCTargetsPath)\Microsoft.Cpp.props" />
]])

	-- Write Configurations.
	local platformName = Platform
	for configName in ivalues(Config.Configurations) do
		local jamCommandLine = jamExePath .. ' ' ..
				os.path.escape('-C' .. destinationRootPath) .. ' ' ..
				'-sPLATFORM=' .. platformName .. ' ' ..
				'-sCONFIG=' .. configName

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
		
		configInfo.BuildCommandLine = configInfo.BuildCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')
		configInfo.RebuildCommandLine = configInfo.RebuildCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')
		configInfo.CleanCommandLine = configInfo.CleanCommandLine:gsub('<', '&lt;'):gsub('>', '&gt;')

		table.insert(self.Contents, expand([==[
  <PropertyGroup Condition="'$$(Configuration)|$$(Platform)'=='$(VSConfig)|$(VSPlatform)'" Label="Configuration">
    <ConfigurationType>Makefile</ConfigurationType>
    <BuildLogFile>$(destinationRootPath:gsub('/', '\\'))temp-$(Platform)-$(Config)/$$(MSBuildProjectName).log</BuildLogFile>
    <NMakeBuildCommandLine>$(BuildCommandLine)</NMakeBuildCommandLine>
    <NMakeOutput>$(Output)</NMakeOutput>
    <NMakeCleanCommandLine>$(CleanCommandLine)</NMakeCleanCommandLine>
    <NMakeReBuildCommandLine>$(RebuildCommandLine)</NMakeReBuildCommandLine>
    <NMakePreprocessorDefinitions>$(Defines)</NMakePreprocessorDefinitions>
    <NMakeIncludeSearchPath>$(Includes)</NMakeIncludeSearchPath>
  </PropertyGroup>
]==], configInfo, info, _G))
	end

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

	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	-- Write the .vcxproj.filters file.
	---------------------------------------------------------------------------
	---------------------------------------------------------------------------
	local filename = outputPath .. self.ProjectName .. '.vcxproj.filters'
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

	if project then
		self:_WriteFolders(project.SourcesTree, '')
	end

	table.insert(self.Contents, [[
  </ItemGroup>
]])	

	-- Write Files.
	table.insert(self.Contents, [[
  <ItemGroup>
]])

	if project then
		self:_WriteFiles(project.SourcesTree, '')
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


function VisualStudio201xProjectMetaTable:_WriteFolders(folder, filter)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			if filter ~= '' then filter = filter .. '\\' end
			filter = filter .. entry.folder
			self:_WriteFolders(entry, filter)
			table.insert(self.Contents, [[
    <Filter Include="]] .. filter .. [[">
    </Filter>
]])
		end
	end
end


function VisualStudio201xProjectMetaTable:_WriteFiles(folder, filter)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			if filter ~= '' then filter = filter .. '\\' end
			filter = filter .. entry.folder
			self:_WriteFiles(entry, filter)
		else
			table.insert(self.Contents, '    <None Include="' .. entry:gsub('/', '\\') .. '">\n')
			table.insert(self.Contents, '      <Filter>' .. filter .. '</Filter>\n')
			table.insert(self.Contents, '    </None>\n')
		end
	end
end


function VisualStudio201xProjectMetaTable:_WriteFilesFlat(folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self:_WriteFilesFlat(entry)
		else
			table.insert(self.Contents, '    <None Include="' .. entry:gsub('/', '\\') .. '" />\n')
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
	local filename = outputPath .. self.Name .. '.sln'

	local workspace = Workspaces[self.Name]

	-- Write header.
	table.insert(self.Contents, '\xef\xbb\xbf\n')

	table.insert(self.Contents, [[
Microsoft Visual Studio Solution File, Format Version 11.00
# Visual Studio 10
]])

	-- Write projects.
	for projectName in ivalues(workspace.Projects) do
		local info = ProjectExportInfo[projectName]
		table.insert(self.Contents, expand([[
Project("{8BC9CEB8-8B4A-11D0-8D11-00A0C91BC942}") = "$(Name)", "$(Filename)", "$(Uuid)"
EndProject
]], info))
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

	local platformName = Platform
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
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	local chunk = loadfile(outPath .. 'VSProjectExportInfo.lua')
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function VisualStudio201xShutdown()
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	LuaDumpObject(outPath .. 'VSProjectExportInfo.lua', 'ProjectExportInfo', ProjectExportInfo)
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

	local platformName = Platform
	do
		local configName = 'debug'
		local jamCommandLine = jamExePath .. ' ' ..
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
		local jamCommandLine = jamExePath .. ' ' ..
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







-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
function XcodeUuid()
	return uuid.new():gsub('%-', ''):upper():sub(1, 24)
end


function XcodeHelper_AssignEntryUuids(entryUuids, folder, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local fullFolderName = fullPath .. entry.folder .. '/'
			if not entryUuids[fullFolderName] then
				entryUuids[fullFolderName] = XcodeUuid()
			end
			XcodeHelper_AssignEntryUuids(entryUuids, entry, fullFolderName)
		else
			if not entryUuids[entry] then
				entryUuids[entry] = XcodeUuid()
			end
		end
	end
end


function XcodeHelper_WritePBXGroup(contents, entryUuids, uuid, name, children, fullPath)
	table.insert(contents, ('\t\t%s /* %s */ = {\n'):format(uuid, name))
	table.insert(contents, '\t\t\tisa = PBXGroup;\n')
	table.insert(contents, '\t\t\tchildren = (\n')
	for entry in ivalues(children) do
		if type(entry) == 'table' then
			local fullFolderName = fullPath .. entry.folder .. '/'
			table.insert(contents, '\t\t\t\t' .. entryUuids[fullFolderName] .. ' /* ' .. entry.folder .. ' */,\n')
		else
			table.insert(contents, '\t\t\t\t' .. entryUuids[entry] .. ' /* ' .. entry .. ' */,\n')
		end
	end
	table.insert(contents, '\t\t\t);\n')
	table.insert(contents, '\t\t\tname = "' .. name .. '";\n')
	table.insert(contents, '\t\t\tsourceTree = "<group>";\n')
	table.insert(contents, '\t\t};\n')
end
	

function XcodeHelper_WritePBXGroups(contents, entryUuids, folder, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local fullFolderName = fullPath .. entry.folder .. '/'
			XcodeHelper_WritePBXGroup(contents, entryUuids, entryUuids[fullFolderName], entry.folder, entry, fullFolderName)
			XcodeHelper_WritePBXGroups(contents, entryUuids, entry, fullFolderName)
		end
	end
end



local XcodeProjectMetaTable = {  __index = XcodeProjectMetaTable  }

function XcodeProjectMetaTable:Write(outputPath, commandLines)
	local projectsPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'

	local filename = outputPath .. self.ProjectName .. '.xcodeproj/project.pbxproj'
	os.mkdir(filename)

	local jamCommandLine = jamExePath .. ' ' ..
			os.path.escape('-C' .. destinationRootPath)

	local info = ProjectExportInfo[self.ProjectName:lower()]
	if not info then
		info = {
			Name = self.ProjectName,
			Filename = filename,
		}
		ProjectExportInfo[self.ProjectName:lower()] = info
	end

	local project = Projects[self.ProjectName]

	-- Write header.
	table.insert(self.Contents, [[
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 45;
	objects = {

]])

	if not info.EntryUuids then
		info.EntryUuids = { }
	end
	self.EntryUuids = info.EntryUuids
	
	project.SourcesTree.folder = self.ProjectName
	local sourcesTree = { project.SourcesTree }
	XcodeHelper_AssignEntryUuids(info.EntryUuids, sourcesTree, '')

	-- Write PBXFileReferences.
	table.insert(self.Contents, [[
/* Begin PBXFileReference section */
]])
	self:_WritePBXFileReferences(sourcesTree)
	table.insert(self.Contents, [[
/* End PBXFileReference section */

]])

	-- Write PBXGroups.
	table.insert(self.Contents, '/* Begin PBXGroup section */\n')
	XcodeHelper_WritePBXGroups(self.Contents, self.EntryUuids, sourcesTree, '')
	table.insert(self.Contents, '/* End PBXGroup section */\n\n')

	if type(info.LegacyTargetUuid) ~= 'string' then
		info.LegacyTargetUuid = XcodeUuid()
	end
	if type(info.LegacyTargetBuildConfigurationListUuid) ~= 'string' then
		info.LegacyTargetBuildConfigurationListUuid = XcodeUuid()
	end
	if type(info.ProjectUuid) ~= 'string' then
		info.ProjectUuid = XcodeUuid()
	end
	if type(info.ProjectBuildConfigurationListUuid) ~= 'string' then
		info.ProjectBuildConfigurationListUuid = XcodeUuid()
	end

	info.GroupUuid = info.EntryUuids[sourcesTree[1].folder .. '/']

	-- Write PBXLegacyTarget.
	table.insert(self.Contents, '/* Begin PBXLegacyTarget section */\n')
	table.insert(self.Contents, ("\t\t%s /* %s */ = {\n"):format(info.LegacyTargetUuid, info.Name))
	table.insert(self.Contents, '\t\t\tisa = PBXLegacyTarget;\n')
	if commandLines and commandLines[1] then
		table.insert(self.Contents, '\t\t\tbuildArgumentsString = "";\n')
	else
		table.insert(self.Contents, '\t\t\tbuildArgumentsString = "\\\"-sPLATFORM=$(PLATFORM) -sCONFIG=$(CONFIG)\\\" $(ACTION) $(TARGET_NAME)";\n')
	end
	table.insert(self.Contents, '\t\t\tbuildConfigurationList = ' .. info.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. info.Name .. '" */;\n')
	table.insert(self.Contents, '\t\t\tbuildPhases = (\n')
	table.insert(self.Contents, '\t\t\t);\n')
	if commandLines and commandLines[1] then
		table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. commandLines[1] .. '";\n')
	else
		table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. os.path.combine(projectsPath, 'xcodejam') .. '";\n')
	end
	table.insert(self.Contents, '\t\t\tdependencies = (\n')
	table.insert(self.Contents, '\t\t\t);\n')
	table.insert(self.Contents, '\t\t\tname = "' .. info.Name .. '";\n')
	table.insert(self.Contents, '\t\t\tpassBuildSettingsInEnvironment = 1;\n')
	table.insert(self.Contents, '\t\t\tproductName = "' .. self.ProjectName .. '";\n')
	table.insert(self.Contents, '\t\t};\n')
	table.insert(self.Contents, '/* End PBXLegacyTarget section */\n\n')

	-- Write PBXProject.
	table.insert(self.Contents, '/* Begin PBXProject section */\n')
	table.insert(self.Contents, ("\t\t%s /* Project object */ = {\n"):format(info.ProjectUuid))
	table.insert(self.Contents, expand([[
			isa = PBXProject;
			buildConfigurationList = $(ProjectBuildConfigurationListUuid) /* Build configuration list for PBXProject "$(Name)" */;
			compatibilityVersion = "Xcode 3.1";
			hasScannedForEncodings = 1;
			mainGroup = $(GroupUuid) /* $(Name) */;
			projectDirPath = "";
			projectRoot = "";
			targets = (
				$(LegacyTargetUuid) /* $(Name) */,
			);
		};
]], info))
	table.insert(self.Contents, '/* End PBXProject section */\n\n')

	for _, platformName in ipairs(Config.Platforms) do
		-- Write XCBuildConfigurations.
		table.insert(self.Contents, '/* Begin XCBuildConfiguration section */\n')

		-- Write legacy target configurations.
		if type(info.LegacyTargetConfigUuids) ~= 'table' then
			info.LegacyTargetConfigUuids = {}
		end
		
		if type(info.LegacyTargetConfigUuids[platformName]) ~= 'table' then
			info.LegacyTargetConfigUuids[platformName] = {}
			for _, config in ipairs(Config.Configurations) do
				info.LegacyTargetConfigUuids[platformName][config] = XcodeUuid()
			end
		end

		for _, config in ipairs(Config.Configurations) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t" .. info.LegacyTargetConfigUuids[platformName][config] .. ' /* ' .. platformAndConfigText .. ' */ = {\n')
			table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
			table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
			table.insert(self.Contents, "\t\t\t\tPRODUCT_NAME = \"" .. self.ProjectName .. "\";\n")
			table.insert(self.Contents, "\t\t\t\tTARGET_NAME = \"" .. self.ProjectName .. "\";\n")
			table.insert(self.Contents, "\t\t\t\tPLATFORM = " .. platformName .. ";\n")
			table.insert(self.Contents, "\t\t\t\tCONFIG = " .. config .. ";\n")
			table.insert(self.Contents, "\t\t\t};\n")
			table.insert(self.Contents, '\t\t\tname = "' .. platformAndConfigText .. '";\n')
			table.insert(self.Contents, "\t\t};\n")
		end
	
		-- Write project configurations.
		if type(info.ProjectConfigUuids) ~= 'table' then
			info.ProjectConfigUuids = {}
		end
		
		if type(info.ProjectConfigUuids[platformName]) ~= 'table' then
			info.ProjectConfigUuids[platformName] = {}
			for _, config in ipairs(Config.Configurations) do
				info.ProjectConfigUuids[platformName][config] = XcodeUuid()
			end
		end

		for _, config in ipairs(Config.Configurations) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t" .. info.ProjectConfigUuids[platformName][config] .. ' /* ' .. platformAndConfigText .. ' */ = {\n')
			table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
			table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
			table.insert(self.Contents, "\t\t\t\tOS = MACOSX;\n")
			table.insert(self.Contents, "\t\t\t\tSDKROOT = macosx10.5;\n")
			table.insert(self.Contents, "\t\t\t};\n")
			table.insert(self.Contents, '\t\t\tname = "' .. platformAndConfigText .. '";\n')
			table.insert(self.Contents, "\t\t};\n")
		end

		table.insert(self.Contents, '/* End XCBuildConfiguration section */\n\n')
	end


	-- Write XCConfigurationLists.
	table.insert(self.Contents, "/* Begin XCConfigurationList section */\n")

	table.insert(self.Contents, "\t\t" .. info.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. info.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, platformName in ipairs(Config.Platforms) do
		for _, config in ipairs(Config.Configurations) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t\t\t" .. info.LegacyTargetConfigUuids[platformName][config] .. " /* " .. platformAndConfigText .. " */,\n")
		end
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = release;\n")
	table.insert(self.Contents, "\t\t};\n\n")

	table.insert(self.Contents, "\t\t" .. info.ProjectBuildConfigurationListUuid .. ' /* Build configuration list for PBXProject "' .. info.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, platformName in ipairs(Config.Platforms) do
		for _, config in ipairs(Config.Configurations) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t\t\t" .. info.ProjectConfigUuids[platformName][config] .. " /* " .. platformAndConfigText .. " */,\n")
		end
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = release;\n")
	table.insert(self.Contents, "\t\t};\n")

	table.insert(self.Contents, "/* End XCConfigurationList section */\n\n")
	
	table.insert(self.Contents, "\t};\n")
	table.insert(self.Contents, "\trootObject = " .. info.ProjectUuid .. " /* Project object */;\n")
	table.insert(self.Contents, "}\n")
	
	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')

	WriteFileIfModified(filename, self.Contents)

	---------------------------------------------------------------------------
	-- Write username.pbxuser with the executable settings
	---------------------------------------------------------------------------
	if type(info.ExecutableInfo) ~= 'table' then
		info.ExecutableInfo = {}
	end

	local ConfigInfo = {}
	for _, platformName in ipairs(Config.Platforms) do
		ConfigInfo[platformName] = {}
		for configName in ivalues(Config.Configurations) do
			local configInfo =
			{
				Platform = platformName,
				Config = configName,
				VSPlatform = MapPlatformToVSPlatform[platformName],
				VSConfig = MapConfigToVSConfig[configName],
				Defines = '',
				Includes = '',
				OutputPath = '',
				OutputName = '',
			}
			ConfigInfo[platformName][configName] = configInfo

			if project and project.Name then
				if project.Defines then
					configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
				end
				if project.IncludePaths then
					configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
				end
				if project.OutputPaths then
					configInfo.OutputPath = project.OutputPaths[platformName][configName]
					configInfo.OutputName = project.OutputNames[platformName][configName]
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
		end
	
		if type(info.ExecutableInfo[platformName]) ~= 'table' then
			info.ExecutableInfo[platformName] = {}
		end
	
		for configName in ivalues(Config.Configurations) do
			local configInfo = ConfigInfo[platformName][configName]
		
			local executableConfig = info.ExecutableInfo[platformName][configName]
			if not executableConfig then
				executableConfig = {}
				info.ExecutableInfo[platformName][configName] = executableConfig
			end
		
			if not executableConfig.Uuid then
				executableConfig.Uuid = XcodeUuid()
			end
		
			if not executableConfig.FileReferenceUuid then
				executableConfig.FileReferenceUuid = XcodeUuid()
			end
		end
	end
	
	local extraData = {}
	extraData.activePlatform = Config.Platforms[1]
	extraData.activeConfig = Config.Configurations[1]
	extraData.activeExecutable = info.ExecutableInfo[extraData.activePlatform][extraData.activeConfig].Uuid

	local filename = outputPath .. self.ProjectName .. '.xcodeproj/' .. os.getenv('USER') .. '.pbxuser'

	self.Contents = {}
	table.insert(self.Contents, [[
// !$*UTF8*$!
{
]])

	for _, platformName in ipairs(Config.Platforms) do
		table.insert(self.Contents, expand([[
	$(ProjectUuid) /* Project object */ = {
		activeBuildConfigurationName = $(activeConfig);
		activeExecutable = $(activeExecutable) /* $(Name) */;
		activeTarget = $(LegacyTargetUuid) /* $(Name) */;
		executables = (
]], extraData, info))

		for configName in ivalues(Config.Configurations) do
			local configInfo = ConfigInfo[platformName][configName]
			local executableConfig = info.ExecutableInfo[platformName][configName]
		
			table.insert(self.Contents, '\t\t\t' .. executableConfig.Uuid .. ' /* ' .. configInfo.OutputName .. ' */,\n')
		end
	
		table.insert(self.Contents, [[
		);
		userBuildSettings = {
		};
	};
]])

		table.insert(self.Contents, ("\t%s /* %s */ = {\n"):format(info.LegacyTargetUuid, self.ProjectName))
		table.insert(self.Contents, '\t\tactiveExec = 0;\n')
		table.insert(self.Contents, '\t};\n')

		for configName in ivalues(Config.Configurations) do
			local configInfo = ConfigInfo[platformName][configName]
			local executableConfig = info.ExecutableInfo[platformName][configName]
		
			if not executableConfig.Uuid then
				executableConfig.Uuid = XcodeUuid()
			end
		
			if not executableConfig.FileReferenceUuid then
				executableConfig.FileReferenceUuid = XcodeUuid()
			end
			extraData.OutputName = configInfo.OutputName

			if configInfo.OutputName ~= '' then
				table.insert(self.Contents, ("\t%s /* %s */ = {\n"):format(executableConfig.FileReferenceUuid, configInfo.OutputName))
				table.insert(self.Contents, [[
		isa = PBXFileReference;
		lastKnownFileType = text;
]])
				table.insert(self.Contents, '\t\tname = ' .. configInfo.OutputName .. ';\n')
				table.insert(self.Contents, '\t\tpath = "' .. configInfo.OutputPath .. configInfo.OutputName .. '";\n')
				table.insert(self.Contents, [[
		sourceTree = "<absolute>";
	};
]])

				table.insert(self.Contents, ("\t%s /* %s */ = {\n"):format(executableConfig.Uuid, configInfo.OutputName))
				table.insert(self.Contents, expand([[
		isa = PBXExecutable;
		activeArgIndices = (
		);
		argumentStrings = (
		);
		autoAttachOnCrash = 1;
		breakpointsEnabled = 1;
		configStateDict = {
			"PBXLSLaunchAction-0" = {
				PBXLSLaunchAction = 0;
				PBXLSLaunchStartAction = 1;
				PBXLSLaunchStdioStyle = 2;
				PBXLSLaunchStyle = 0;
				class = PBXLSRunLaunchConfig;
				commandLineArgs = (
				);
				displayName = "Executable Runner";
				environment = {
				};
				identifier = com.apple.Xcode.launch.runConfig;
				remoteHostInfo = "";
				startActionInfo = "";
			};
		};
		customDataFormattersEnabled = 1;
		debuggerPlugin = GDBDebugging;
		disassemblyDisplayState = 0;
		dylibVariantSuffix = "";
		enableDebugStr = 1;
		environmentEntries = (
		);
		executableSystemSymbolLevel = 0;
		executableUserSymbolLevel = 0;
		launchableReference = $(FileReferenceUuid) /* $(OutputName) */;
		libgmallocEnabled = 0;
		name = $(OutputName);
		sourceDirectories = (
		);
	};
]], executableConfig, info, extraData))
			end
		end
	end
		
	table.insert(self.Contents, '}\n')

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')

	WriteFileIfModified(filename, self.Contents)
end

function XcodeProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = XcodeProjectMetaTable }
	)
end


function XcodeProjectMetaTable:_WritePBXFileReferences(folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self:_WritePBXFileReferences(entry)
		else
			table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode%s; name = "%s"; path = "%s"; sourceTree = "<group>"; };\n'):format(
					self.EntryUuids[entry], entry, os.path.get_extension(entry), os.path.remove_directory(entry), entry))
		end
	end
end



local XcodeWorkspaceMetaTable = {  __index = XcodeWorkspaceMetaTable  }

local function _XcodeProjectSortFunction(left, right)
	local leftType = type(left)
	local rightType = type(right)
	if leftType == 'table'  and  rightType == 'table' then
		return left.folder:lower() < right.folder:lower()
	end
	if leftType == 'table' then
		return true
	end
	if rightType == 'table' then
		return false
	end
	return left:lower() < right:lower()
end


function XcodeWorkspaceMetaTable:_WritePBXFileReferences(folder)
	table.sort(folder, _XcodeProjectSortFunction)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self:_WritePBXFileReferences(entry)
		else
			table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode%s; name = "%s"; path = "%s"; sourceTree = "<group>"; };\n'):format(
					self.EntryUuids[entry], entry, os.path.get_extension(entry), os.path.remove_directory(entry), entry))
		end
	end
end



function XcodeWorkspaceMetaTable:_WritePBXProjectFileReferences(folder, workspace)
	table.sort(folder, _XcodeProjectSortFunction)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self:_WritePBXProjectFileReferences(entry, workspace)
		else
			if os.path.get_extension(entry) == '.xcodeproj' then
				local projectName = os.path.remove_extension(entry)
				local projectInfo = ProjectExportInfo[projectName:lower()]
				if projectInfo then
					table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; lastKnownFileType = "wrapper.pb-project"; name = "%s"; path = "%s"; sourceTree = SOURCE_ROOT; };\n'):format(
							self.EntryUuids[entry], entry, projectName, os.path.simplify(os.path.remove_slash(os.path.remove_filename(projectInfo.Filename)))))
				end

				self:_WritePBXFileReferences({ Projects[projectName].SourcesTree })
			else
				table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode%s; name = "%s"; path = "%s"; sourceTree = "<group>"; };\n'):format(
						self.EntryUuids[entry], entry, os.path.get_extension(entry), os.path.remove_directory(entry), entry))
			end
		end
	end
end


function XcodeWorkspaceMetaTable:_WriteProjectReferences(folder, fullPath)
	for _, entry in ipairs(folder) do
		if type(entry) == 'table' then
			local fullFolderName = fullPath .. entry.folder .. '/'
			self:_WriteProjectReferences(entry, fullFolderName)
		else
			table.insert(self.Contents, '\t\t\t\t{\n')
			table.insert(self.Contents, '\t\t\t\t\tProductGroup = ' .. self.EntryUuids[fullPath] .. ' /* ' .. ' */;\n')
			table.insert(self.Contents, '\t\t\t\t\tProjectRef = ' .. self.EntryUuids[entry] .. ' /* ' .. entry .. '.xcodeproj */;\n')
			table.insert(self.Contents, '\t\t\t\t},\n')
		end
	end
end


function XcodeWorkspaceMetaTable:_AppendXcodeproj(folder)
	for index = 1, #folder do
		local entry = folder[index]
		if type(entry) == 'table' then
			self:_AppendXcodeproj(entry)
		else
			folder[index] = entry .. '.xcodeproj'
			folder[#folder + 1] = Projects[entry].SourcesTree 
		end
	end
end


function XcodeWorkspaceMetaTable:Write(outputPath)
	local projectsPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'

	local filename = outputPath .. self.Name .. '.workspace.xcodeproj/project.pbxproj'
	os.mkdir(filename)

	local workspace = Workspaces[self.Name]
	local workspaceName = self.Name .. '.workspace'

	local info = ProjectExportInfo[workspaceName:lower()]
	if not info then
		info = {
			Name = workspaceName,
			Filename = filename,
		}
		ProjectExportInfo[workspaceName:lower()] = info
	end
	if not info.LegacyTargetUuid then
		info.LegacyTargetUuid = XcodeUuid()
	end
	if not info.LegacyTargetBuildConfigurationListUuid then
		info.LegacyTargetBuildConfigurationListUuid = XcodeUuid()
	end
	if not info.ProjectUuid then
		info.ProjectUuid = XcodeUuid()
	end
	if not info.ProjectBuildConfigurationListUuid then
		info.ProjectBuildConfigurationListUuid = XcodeUuid()
	end

	-- Write header.
	table.insert(self.Contents, [[
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 45;
	objects = {

]])

	if not info.EntryUuids then
		info.EntryUuids = { }
	end
	self.EntryUuids = info.EntryUuids
	
	self:_AppendXcodeproj(workspace.ProjectTree)
	workspace.ProjectTree.folder = self.Name .. '.workspace'
	local workspaceTree = { workspace.ProjectTree }
	XcodeHelper_AssignEntryUuids(info.EntryUuids, workspaceTree, '')

	-- Write PBXFileReferences.
	table.insert(self.Contents, [[
/* Begin PBXFileReference section */
]])
	self:_WritePBXProjectFileReferences(workspaceTree, workspace)
	table.insert(self.Contents, [[
/* End PBXFileReference section */

]])

	-- Write PBXGroups.
	table.insert(self.Contents, '/* Begin PBXGroup section */\n')
	XcodeHelper_WritePBXGroups(self.Contents, info.EntryUuids, workspaceTree, '')
	table.insert(self.Contents, '/* End PBXGroup section */\n\n')

	-- Write PBXLegacyTarget.
	table.insert(self.Contents, '/* Begin PBXLegacyTarget section */\n')
	table.insert(self.Contents, ("\t\t%s /* %s */ = {\n"):format(info.LegacyTargetUuid, info.Name))
	table.insert(self.Contents, '\t\t\tisa = PBXLegacyTarget;\n')
	table.insert(self.Contents, '\t\t\tbuildArgumentsString = "\\\"-sPLATFORM=$(PLATFORM) -sCONFIG=$(CONFIG)\\\" $(ACTION) $(TARGET_NAME)";\n')
	table.insert(self.Contents, '\t\t\tbuildConfigurationList = ' .. info.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. info.Name .. '" */;\n')
	table.insert(self.Contents, '\t\t\tbuildPhases = (\n')
	table.insert(self.Contents, '\t\t\t);\n')
	table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. os.path.combine(projectsPath, 'xcodejam') .. '";\n')
	table.insert(self.Contents, '\t\t\tdependencies = (\n')
	table.insert(self.Contents, '\t\t\t);\n')
	table.insert(self.Contents, '\t\t\tname = "' .. info.Name .. '";\n')
	table.insert(self.Contents, '\t\t\tpassBuildSettingsInEnvironment = 1;\n')
	table.insert(self.Contents, '\t\t\tproductName = "' .. self.Name .. '";\n')
	table.insert(self.Contents, '\t\t};\n')
	table.insert(self.Contents, '/* End PBXLegacyTarget section */\n\n')

	-- Write PBXProject.
	table.insert(self.Contents, '/* Begin PBXProject section */\n')
	table.insert(self.Contents, ("\t\t%s /* Project object */ = {\n"):format(info.ProjectUuid))
	info.GroupUuid = info.EntryUuids[workspaceTree[1].folder .. '/']
	table.insert(self.Contents, expand([[
			isa = PBXProject;
			buildConfigurationList = $(ProjectBuildConfigurationListUuid) /* Build configuration list for PBXProject "$(Name)" */;
			compatibilityVersion = "Xcode 3.1";
			hasScannedForEncodings = 1;
			mainGroup = $(GroupUuid);
			projectDirPath = "";
]], info))
--projectReferences = (
--	self:_WriteProjectReferences(workspaceTree, '')
--);
	table.insert(self.Contents, expand([[
			projectRoot = "";
			targets = (
				$(LegacyTargetUuid) /* $(Name) */,
			);
		};
]], info))
	table.insert(self.Contents, '/* End PBXProject section */\n\n')

	-- Write XCBuildConfigurations.
	if not info.LegacyTargetConfigUuids then
		info.LegacyTargetConfigUuids = {}

		for _, config in ipairs(Config.Configurations) do
			info.LegacyTargetConfigUuids[config] = XcodeUuid()
		end
	end

	if not info.ProjectConfigUuids then
		info.ProjectConfigUuids = {}

		for _, config in ipairs(Config.Configurations) do
			info.ProjectConfigUuids[config] = XcodeUuid()
		end
	end

	table.insert(self.Contents, '/* Begin XCBuildConfiguration section */\n')

	-- Write legacy target configurations.
	for _, platform in ipairs(Config.Platforms) do
		for _, config in ipairs(Config.Configurations) do
			table.insert(self.Contents, "\t\t" .. info.LegacyTargetConfigUuids[config] .. ' /* ' .. config .. ' */ = {\n')
			table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
			table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
			table.insert(self.Contents, "\t\t\t\tPRODUCT_NAME = " .. 'all' .. ";\n")
			table.insert(self.Contents, "\t\t\t\tTARGET_NAME = " .. 'all' .. ";\n")
			table.insert(self.Contents, "\t\t\t\tPLATFORM = " .. platform .. ";\n")
			table.insert(self.Contents, "\t\t\t\tCONFIG = " .. config .. ";\n")
			table.insert(self.Contents, "\t\t\t};\n")
			table.insert(self.Contents, "\t\t\tname = " .. config .. ";\n")
			table.insert(self.Contents, "\t\t};\n")
		end
	end
	
	-- Write project configurations.
	for _, config in ipairs(Config.Configurations) do
		table.insert(self.Contents, "\t\t" .. info.ProjectConfigUuids[config] .. ' /* ' .. config .. ' */ = {\n')
		table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
		table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
		table.insert(self.Contents, "\t\t\t\tOS = MACOSX;\n")
		table.insert(self.Contents, "\t\t\t\tSDKROOT = macosx10.5;\n")
		table.insert(self.Contents, "\t\t\t};\n")
		table.insert(self.Contents, "\t\t\tname = " .. config .. ";\n")
		table.insert(self.Contents, "\t\t};\n")
	end

	table.insert(self.Contents, '/* End XCBuildConfiguration section */\n\n')


	-- Write XCConfigurationLists.
	table.insert(self.Contents, "/* Begin XCConfigurationList section */\n")

	table.insert(self.Contents, "\t\t" .. info.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. self.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, config in ipairs(Config.Configurations) do
		table.insert(self.Contents, "\t\t\t\t" .. info.LegacyTargetConfigUuids[config] .. " /* " .. config .. " */,\n")
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = release;\n")
	table.insert(self.Contents, "\t\t};\n\n")
	
	table.insert(self.Contents, "\t\t" .. info.ProjectBuildConfigurationListUuid .. ' /* Build configuration list for PBXProject "' .. self.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, config in ipairs(Config.Configurations) do
		table.insert(self.Contents, "\t\t\t\t" .. info.ProjectConfigUuids[config] .. " /* " .. config .. " */,\n")
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = release;\n")
	table.insert(self.Contents, "\t\t};\n")
	
	table.insert(self.Contents, "/* End XCConfigurationList section */\n\n")
	
	table.insert(self.Contents, "\t};\n")

	table.insert(self.Contents, "\trootObject = " .. info.ProjectUuid .. " /* Project object */;\n")
	table.insert(self.Contents, "}\n")
	
	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')
	WriteFileIfModified(filename, self.Contents)

end

function XcodeWorkspace(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = XcodeWorkspaceMetaTable }
	)
end



function XcodeInitialize()
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	local chunk = loadfile(outPath .. 'XcodeProjectExportInfo.lua')
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end

	io.writeall(outPath .. 'xcodejam', [[
#!/bin/sh
TARGET_NAME=
if [ "$3" = "" ]; then
	TARGET_NAME=$2
elif [ "$2" = build ]; then
	TARGET_NAME=$3
elif [ "$2" = clean ]; then
	TARGET_NAME=clean:$3
fi
]] .. os.path.escape(os.path.combine(destinationRootPath, 'jam')) .. [[ $1 $TARGET_NAME
]])
	os.chmod(outPath .. 'xcodejam', 777)
end


function XcodeShutdown()
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	LuaDumpObject(outPath .. 'XcodeProjectExportInfo.lua', 'ProjectExportInfo', ProjectExportInfo)
end




-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local NoneProjectMetaTable = {  __index = VisualStudio200xProjectMetaTable  }

function NoneProjectMetaTable:Write(outputPath, commandLines)
end

function NoneProject(projectName, options)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
		}, { __index = NoneProjectMetaTable }
	)
end


local NoneWorkspaceMetaTable = {  __index = NoneWorkspaceMetaTable  }

function NoneWorkspaceMetaTable:Write(outputPath)
end

function NoneWorkspace(solutionName, options)
	return setmetatable(
		{
			Contents = {},
			Name = solutionName,
			Options = options,
		}, { __index = NoneWorkspaceMetaTable }
	)
end



function NoneInitialize()
end


function NoneShutdown()
end





Exporters =
{
	none =
	{
		Initialize = NoneInitialize,
		ProjectExporter = NoneProject,
		WorkspaceExporter = NoneWorkspace,
		Shutdown = NoneShutdown,
		Description = 'Do not generate a workspace.',
		Options = {},
	},

	vc6 =
	{
		Initialize = VisualC6Initialize,
		ProjectExporter = VisualC6Project,
		WorkspaceExporter = VisualC6Solution,
		Shutdown = VisualC6Shutdown,
		Description = 'Generate Visual C++ 6.0 workspaces and projects.',
		Options =
		{
		}
	},

	vs2003 =
	{
		Initialize = VisualStudio200xInitialize,
		ProjectExporter = VisualStudio200xProject,
		WorkspaceExporter = VisualStudio200xSolution,
		Shutdown = VisualStudio200xShutdown,
		Description = 'Generate Visual Studio 2003 solutions and projects.',
		Options =
		{
			vs2003 = true,
		}
	},

	vs2005 =
	{
		Initialize = VisualStudio200xInitialize,
		ProjectExporter = VisualStudio200xProject,
		WorkspaceExporter = VisualStudio200xSolution,
		Shutdown = VisualStudio200xShutdown,
		Description = 'Generate Visual Studio 2005 solutions and projects.',
		Options =
		{
			vs2005 = true,
		}
	},

	vs2008 =
	{
		Initialize = VisualStudio200xInitialize,
		ProjectExporter = VisualStudio200xProject,
		WorkspaceExporter = VisualStudio200xSolution,
		Shutdown = VisualStudio200xShutdown,
		Description = 'Generate Visual Studio 2008 solutions and projects.',
		Options =
		{
			vs2008 = true,
		}
	},

	vs2010 =
	{
		Initialize = VisualStudio201xInitialize,
		ProjectExporter = VisualStudio201xProject,
		WorkspaceExporter = VisualStudio201xSolution,
		Shutdown = VisualStudio201xShutdown,
		Description = 'Generate Visual Studio 2010 solutions and projects.',
		Options =
		{
			vs2010 = true,
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
	},

	xcode =
	{
		Initialize = XcodeInitialize,
		ProjectExporter = XcodeProject,
		WorkspaceExporter = XcodeWorkspace,
		Shutdown = XcodeShutdown,
		Description = 'Generate Xcode project',
		Options =
		{
		}
	},

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
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects', project.RelativePath) .. '/'
	os.mkdir(outPath)

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
		projectsMap[project:lower()] = project
	end

	projectsMap[buildWorkspaceName:lower()] = buildWorkspaceName
	projectsMap[updateWorkspaceName:lower()] = updateWorkspaceName

	if workspace.ProjectGroups then
		for projectGroupName, projectGroup in pairs(workspace.ProjectGroups) do
			for projectName in ivalues(projectGroup) do
				local lowerProjectName = projectName:lower()
				if projectsMap[lowerProjectName] then
					FolderTree.InsertName(projects, projectGroupName, projectName)
					projectsMap[lowerProjectName] = nil
				end
			end
		end
	end

	for lowerProjectName, projectName in pairs(projectsMap) do
		FolderTree.InsertName(projects, '', projectName)
	end

	FolderTree.Sort(projects)

	workspace.ProjectTree = projects
	workspace.ProjectGroups = nil
end


function DumpWorkspace(workspace)
	local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
	
	-- Write the !BuildWorkspace project
	local exporter = Exporters[opts.gen]
	Projects[buildWorkspaceName] = {}
	Projects[buildWorkspaceName].Sources =
	{
		jamPath:gsub('\\', '/') .. '/Jambase.jam'
	}
	Projects[buildWorkspaceName].SourcesTree = Projects[buildWorkspaceName].Sources
	local projectExporter = exporter.ProjectExporter(buildWorkspaceName, exporter.Options)
	projectExporter:Write(outPath)

	-- Write the !UpdateWorkspace project
	Projects[updateWorkspaceName] = {}
	Projects[updateWorkspaceName].Sources =
	{
		jamPath:gsub('\\', '/') .. '/Jambase.jam'
	}
	Projects[updateWorkspaceName].SourcesTree = Projects[updateWorkspaceName].Sources
	local projectExporter = exporter.ProjectExporter(updateWorkspaceName, exporter.Options)

	local updateWorkspaceCommandLines
	if uname == 'windows' then
		updateWorkspaceCommandLines =
		{
			outPath .. 'updateprojects.bat',
			outPath .. 'updateprojects.bat',
		}
	else
		updateWorkspaceCommandLines =
		{
			outPath .. 'updateprojects',
			outPath .. 'updateprojects',
		}
	end

	projectExporter:Write(outPath, updateWorkspaceCommandLines)

	if not workspace.ProjectGroups then
		workspace.ProjectGroups = {}
	end
	local jamSupport = workspace.ProjectGroups['!JamSupport']
	if not jamSupport then
		jamSupport = {}
		workspace.ProjectGroups['!JamSupport'] = jamSupport
	end
	table.insert(jamSupport, buildWorkspaceName)
	table.insert(jamSupport, updateWorkspaceName)

	BuildProjectTree(workspace)

	for projectName in ivalues(workspace.Projects) do
		local project = Projects[projectName]
		if project then
			DumpProject(project)
		else
			print('* Attempting to write unknown project [' .. projectName .. '].')
		end
	end

	workspace.Projects[#workspace.Projects + 1] = buildWorkspaceName
	workspace.Projects[#workspace.Projects + 1] = updateWorkspaceName
end


function BuildProject()
	print('Creating workspace...')
	os.mkdir(destinationRootPath)

	local exporter = Exporters[opts.gen]
	exporter.Options.compiler = opts.compiler or opts.gen

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
	
	local hasCOMPILER = false
	for _, info in ipairs(Config.JamFlags) do
		if info.Key == 'COMPILER' then
			hasCOMPILER = true
			break
		end
	end
	
	if not hasCOMPILER then
		table.insert(Config.JamFlags, 1, { Key = 'COMPILER', Value = exporter.Options.compiler })
	end
	
	for _, info in ipairs(Config.JamFlags) do
		jambaseText[#jambaseText + 1] = expand(info.Key .. ' = ' .. info.Value .. ' ;\n', exporter.Options, _G)
	end
	jambaseText[#jambaseText + 1] = expand([[

include $(jamPath)Jambase.jam ;
]], exporter.Options, _G)
	io.writeall(destinationRootPath .. 'Jambase.jam', table.concat(jambaseText))

	local jamScript
	if uname == 'windows' then
		-- Write jam.bat.
		jamScript = os.path.combine(destinationRootPath, 'jam.bat')
		io.writeall(jamScript,
			'@' .. jamExePath .. ' ' .. os.path.escape("-C" .. destinationRootPath) .. ' %*\n')

		-- Write updateworkspace.bat.
		io.writeall(os.path.combine(destinationRootPath, 'updateworkspace.bat'),
				("@%s --workspace --config=%s %s %s\n"):format(
				os.path.escape(jamScript),
				os.path.escape(destinationRootPath .. '/workspace.config'),
				os.path.escape(sourceJamfilePath),
				os.path.escape(destinationRootPath)))
	else
		-- Write jam shell script.
		jamScript = os.path.combine(destinationRootPath, 'jam')
		io.writeall(jamScript,
				'#!/bin/sh\n' ..
				jamExePath .. ' ' .. os.path.escape("-C" .. destinationRootPath) .. ' $*\n')
		os.chmod(jamScript, 777)

		-- Write updateworkspace.sh.
		local updateworkspace = os.path.combine(destinationRootPath, 'updateworkspace')
		io.writeall(updateworkspace,
				("#!/bin/sh\n%s --workspace --config=%s %s %s\n"):format(
				os.path.escape(jamScript), opts.gen,
				os.path.escape(destinationRootPath .. '/workspace.config'),
				os.path.escape(sourceJamfilePath),
				os.path.escape(destinationRootPath)))
		os.chmod(updateworkspace, 777)
	end

	-- Write workspace.config.
	LuaDumpObject(destinationRootPath .. 'workspace.config', 'Config', Config)

	if opts.gen ~= 'none' then
		local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
		os.mkdir(outPath)

		-- Read the target information.
		CreateTargetInfoFiles()
		ReadTargetInfoFiles()

		print('Writing generated projects...')

		if uname == 'windows' then
			-- Write updateprojects.bat.
			io.writeall(outPath .. 'updateprojects.bat',
					("@%s --workspace --gen=%s --config=%s %s ..\n"):format(
					os.path.escape(jamScript), opts.gen,
					os.path.escape(destinationRootPath .. '/workspace.config'),
					os.path.escape(sourceJamfilePath)))
		else
			-- Write updateprojects.sh.
			io.writeall(outPath .. 'updateprojects',
					("#!/bin/sh\n%s --workspace --gen=%s --config=%s %s ..\n"):format(
					os.path.escape(jamScript), opts.gen,
					os.path.escape(destinationRootPath .. '/workspace.config'),
					os.path.escape(sourceJamfilePath)))
			os.chmod(outPath .. 'updateprojects', 777)
		end

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

				local outPath = os.path.combine(destinationRootPath, opts.gen .. '.projects') .. '/'
				local workspaceExporter = exporter.WorkspaceExporter(workspace.Name, exporter.Options)
				workspaceExporter:Write(outPath)
			end
		end

		exporter.Shutdown()
	end
end


ProcessCommandLine()

-- Turn the source code root into an absolute path based on the current working directory.
sourceJamfilePath = os.path.simplify(os.path.make_absolute(nonOpts[1]))
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

Config.JamFlags = JamFlags

-- Do the same with the destination.
destinationRootPath = os.path.simplify(os.path.add_slash(os.path.make_absolute(nonOpts[2] or '.')))

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

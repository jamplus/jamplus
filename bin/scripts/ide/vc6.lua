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
			local jamCommandLine = os.path.make_backslash(jamScript) .. ' ' ..
					os.path.escape('-C' .. destinationRootPath) .. ' -g ' ..
					'C.TOOLCHAIN=' .. platformName .. '/' .. configName

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

			if project and project.Name and project.Name ~= '!BuildWorkspace' and project.Name ~= '!UpdateWorkspace' then
				if project.OutputPaths then
					configInfo.Output = project.OutputPaths[platformName][configName] .. project.OutputNames[platformName][configName]
					configInfo.OutputName = project.OutputNames[platformName][configName]
					configInfo.OutputPath = project.OutputPaths[platformName][configName]:gsub('/', '\\')
				end
				configInfo.BuildCommandLine = jamCommandLine .. ' ' .. self.ProjectName
				configInfo.RebuildCommandLine = jamCommandLine .. ' -a ' .. self.ProjectName
				configInfo.CleanCommandLine = jamCommandLine .. ' clean:' .. self.ProjectName
			else
				configInfo.BuildCommandLine = project.BuildCommandLine and project.BuildCommandLine[1] or jamCommandLine
				configInfo.RebuildCommandLine = project.RebuildCommandLine and project.RebuildCommandLine[1] or (jamCommandLine .. ' -a')
				configInfo.CleanCommandLine = project.CleanCommandLine and project.CleanCommandLine[1] or (jamCommandLine .. ' clean')
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





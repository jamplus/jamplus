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
	local projectsPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'

	local filename = outputPath .. self.ProjectName .. '.xcodeproj/project.pbxproj'
	os.mkdir(filename)

	local jamCommandLine = jamScript .. ' ' ..
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
	local projectsPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'

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
	local outPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'
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
	local outPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'
	LuaDumpObject(outPath .. 'XcodeProjectExportInfo.lua', 'ProjectExportInfo', ProjectExportInfo)
end





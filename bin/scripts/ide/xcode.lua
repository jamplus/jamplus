------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local uuid = require 'uuid'

function deepcopy(t)
    if type(t) ~= 'table' then return t end
    local res = {}
    for k,v in pairs(t) do
        if type(v) == 'table' then
            v = deepcopy(v)
        end
        res[k] = v
    end
    return res
end


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


-- Use the upper 24 characters of a UUID as the Xcode UUID.
function XcodeUuid()
	return uuid.new():gsub('%-', ''):upper():sub(1, 24)
end


-- Assign UUIDs to every entry in the folder tree.
function XcodeHelper_AssignEntryUuids(entryUuids, folder, fullPath, prefix)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local fullFolderName = prefix .. fullPath .. entry.folder .. '/'
			if not entryUuids[fullFolderName] then
				entryUuids[fullFolderName] = XcodeUuid()
			end
			XcodeHelper_AssignEntryUuids(entryUuids, entry, fullFolderName, prefix)
		else
			if not entryUuids[prefix .. entry] then
				entryUuids[prefix .. entry] = XcodeUuid()
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
			local strippedEntry = entry:match('^app>(.+)')
			table.insert(contents, '\t\t\t\t' .. entryUuids[entry] .. ' /* ' .. (strippedEntry or entry ) .. ' */,\n')
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
			local fullFolderName = fullPath
			if entry.folder ~= '' then
				fullFolderName = fullFolderName .. entry.folder .. '/'
			end
			XcodeHelper_WritePBXGroup(contents, entryUuids, entryUuids[fullFolderName], entry.folder, entry, fullFolderName)
			XcodeHelper_WritePBXGroups(contents, entryUuids, entry, fullFolderName)
		end
	end
end



local function GetJamConfigName(workspaceConfigName, workspace)
	local customWorkspaceConfig = workspace  and  workspace.Configs  and  workspace.Configs[workspaceConfigName]
	return customWorkspaceConfig  and  customWorkspaceConfig.ActualConfigName  or  workspaceConfigName
end


local function XcodeHelper_GetProjectExportInfo(projectName, workspace)
	local project = Projects[projectName]
	local info = ProjectExportInfo[projectName:lower()]
	if not info then
		info = {
			Name = projectName,
			Filename = filename,
		}
		ProjectExportInfo[projectName:lower()] = info
	end

	-- Build up all the UUIDs.
	if not info.EntryUuids then
		info.EntryUuids = { }
	end
	
	-- Make executable Products files available.
	if not info.ExecutablePath  and  project.Options  and  project.Options.app then
		local executablePath = projectName
		if project.Options.bundle then
			executablePath = executablePath .. '.app'
		end
		info.ExecutablePath = executablePath
	end

	if type(info.ExecutableInfo) ~= 'table' then
		info.ExecutableInfo = {}
	end

	if type(info.LegacyTargetUuid) ~= 'string' then
		info.LegacyTargetUuid = XcodeUuid()
	end
	if type(info.PBXBuildRuleUuid) ~= 'string' then
		info.PBXBuildRuleUuid = XcodeUuid()
	end
	if type(info.ShellScriptUuid) ~= 'string' then
		info.ShellScriptUuid = XcodeUuid()
	end
	if type(info.SourcesUuid) ~= 'string' then
		info.SourcesUuid = XcodeUuid()
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

	if type(info.LegacyTargetConfigUuids) ~= 'table' then
		info.LegacyTargetConfigUuids = {}
	end

	local workspaceConfigs = GetWorkspaceConfigList(workspace)
	for _, platformName in ipairs(Config.Platforms) do
		if type(info.ExecutableInfo[platformName]) ~= 'table' then
			info.ExecutableInfo[platformName] = {}
		end

		for configName in ivalues(workspaceConfigs) do
			local executableConfig = info.ExecutableInfo[platformName][configName]
			if not executableConfig then
				executableConfig = {}
				info.ExecutableInfo[platformName][configName] = executableConfig
			end

			if not executableConfig.Uuid then
				executableConfig.Uuid = XcodeUuid()
			end
		end
		
		if type(info.LegacyTargetConfigUuids[platformName]) ~= 'table' then
			info.LegacyTargetConfigUuids[platformName] = {}
			for configName in ivalues(workspaceConfigs) do
				info.LegacyTargetConfigUuids[platformName][configName] = XcodeUuid()
			end
		end
		
		if type(info.ProjectConfigUuids) ~= 'table' then
			info.ProjectConfigUuids = {}
		end

		if type(info.ProjectConfigUuids[platformName]) ~= 'table' then
			info.ProjectConfigUuids[platformName] = {}
			for configName in ivalues(workspaceConfigs) do
				info.ProjectConfigUuids[platformName][configName] = XcodeUuid()
			end
		end
	end

	if not project.ConfigInfo then project.ConfigInfo = {} end
	for _, platformName in ipairs(Config.Platforms) do
		if not project.ConfigInfo[platformName] then project.ConfigInfo[platformName] = {} end
		for workspaceConfigName in ivalues(workspaceConfigs) do
			local configName = GetJamConfigName(workspaceConfigName, workspace)

			local configInfo = project.ConfigInfo[platformName][workspaceConfigName]
			if not configInfo then
				configInfo = {
					Platform = platformName,
					PLATFORM = platformName,
					Config = configName,
					WorkspaceConfigName = workspaceConfigName,
					Defines = '',
					Includes = '',
					OutputPath = '',
					OutputName = '',
				}
				project.ConfigInfo[platformName][workspaceConfigName] = configInfo
			end

			if configInfo.Defines == ''  and  project.Defines  and  project.Defines[platformName]  and  project.Defines[platformName][configName] then
				configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
			end
			if configInfo.Includes == ''  and  project.IncludePaths  and  project.IncludePaths[platformName]  and  project.IncludePaths[platformName][configName]  then
				configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ' ')
			end
			if configInfo.OutputPath == ''  and  project.OutputPaths  and project.OutputPaths[platformName]  and  project.OutputPaths[platformName][configName]  then
				configInfo.OutputPath = project.OutputPaths[platformName][configName]
			end
			if configInfo.OutputName == ''  and  project.OutputNames  and project.OutputNames[platformName]  and project.OutputNames[platformName][configName]  then
				configInfo.OutputName = project.OutputNames[platformName][configName]
			end
		end
	end

	if project.Options  and  project.Options.app  and  not project._insertedapp then
		FolderTree.InsertName(project.SourcesTree, "Products", 'app>' .. info.ExecutablePath)
		project._insertedapp = true
	end

	return info
end


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


function XcodeHelper_SortFoldersAndFiles(self, folder)
	table.sort(folder, _XcodeProjectSortFunction)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			XcodeHelper_SortFoldersAndFiles(self, entry)
		end
	end
end


local buildExtensions = {
	['.cpp'] = true,
	['.c'] = true,
	['.m'] = true,
	['.mm'] = true,
}

function XcodeHelper_WritePBXBuildFiles(self, folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			XcodeHelper_WritePBXBuildFiles(self, entry)
		else
			local ext = ospath.get_extension(entry)
			if buildExtensions[ext] then
				table.insert(self.Contents, ('\t\t%s /* %s in Sources */ = {isa = PBXBuildFile; fileRef = %s /* %s */; };\n'):format(
						self.EntryUuids['PBXBuildFile*' .. entry], ospath.remove_directory(entry), self.EntryUuids[entry], ospath.remove_directory(entry)))
			end
		end
	end
end


function XcodeHelper_WritePBXBuildFileReferences(self, folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			XcodeHelper_WritePBXBuildFileReferences(self, entry)
		else
			local ext = ospath.get_extension(entry)
			if buildExtensions[ext] then
				table.insert(self.Contents, ('\t\t\t\t%s /* %s in Sources */,\n'):format(
						self.EntryUuids['PBXBuildFile*' .. entry], ospath.remove_directory(entry)))
			end
		end
	end
end


local sourcecodeType = {
	['.cpp'] = '.cpp.cpp',
	['.c'] = '.c.c',
	['.h'] = '.c.h',
	['.m'] = '.c.objc',
	['.mm'] = '.cpp.objcpp',
}

function XcodeHelper_WritePBXFileReferences(self, folder)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			XcodeHelper_WritePBXFileReferences(self, entry)
		else
			local ext = ospath.get_extension(entry)
			local strippedEntry = entry:match('^app>(.+)')
			if strippedEntry then
				table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; explicitFileType = wrapper.application; includeInIndex = 0; name = "%s"; path = "%s"; sourceTree = BUILT_PRODUCTS_DIR; };\n'):format(
						self.EntryUuids[entry], strippedEntry, ospath.remove_directory(strippedEntry), strippedEntry))
			else
				table.insert(self.Contents, ('\t\t%s /* %s */ = {isa = PBXFileReference; fileEncoding = 4; lastKnownFileType = sourcecode%s; name = "%s"; path = "%s"; sourceTree = "<group>"; };\n'):format(
						self.EntryUuids[entry], entry, sourcecodeType[ext]  or  ext, ospath.remove_directory(entry), entry))
			end
		end
	end
end


local function XcodeHelper_WritePBXLegacyTarget(self, info, allTargets, projectsPath)
	for curProject in ivalues(allTargets) do
		if not curProject.XcodeProjectType then
			if curProject.Name == buildWorkspaceName  or  curProject.Name == updateWorkspaceName  or  curProject.Options.project then
				curProject.XcodeProjectType = 'legacy'
			else
				curProject.XcodeProjectType = 'native'
			end
		end
	end

	for _, projectType in ipairs{ 'native', 'legacy' } do	
		if projectType == 'native' then
			-- Write PBXNativeTarget.
			table.insert(self.Contents, '/* Begin PBXNativeTarget section */\n')
		elseif projectType == 'legacy' then
			-- Write PBXLegacyTarget.
			table.insert(self.Contents, '/* Begin PBXLegacyTarget section */\n')
		end

		for curProject in ivalues(allTargets) do
			if curProject.XcodeProjectType == projectType then
				local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name, self.Workspace)
				local subProject = Projects[curProject.Name]

				table.insert(self.Contents, ("\t\t%s /* %s */ = {\n"):format(subProjectInfo.LegacyTargetUuid, subProjectInfo.Name))
				if projectType == 'native' then
					table.insert(self.Contents, '\t\t\tisa = PBXNativeTarget;\n')
				else
					table.insert(self.Contents, '\t\t\tisa = PBXLegacyTarget;\n')

					if subProject.BuildCommandLine then
						table.insert(self.Contents, '\t\t\tbuildArgumentsString = "";\n')
					else
						table.insert(self.Contents, '\t\t\tbuildArgumentsString = "$(COMMANDLINE)";\n')
					end
				end
				table.insert(self.Contents, '\t\t\tbuildConfigurationList = ' .. subProjectInfo.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. subProjectInfo.Name .. '" */;\n')
				table.insert(self.Contents, '\t\t\tbuildPhases = (\n')
				table.insert(self.Contents, '\t\t\t\t' .. subProjectInfo.ShellScriptUuid .. ' /* ShellScript */,\n')
				table.insert(self.Contents, '\t\t\t\t' .. subProjectInfo.SourcesUuid .. ' /* Sources */,\n')
				table.insert(self.Contents, '\t\t\t);\n')
				if projectType == 'legacy' then
					if subProject.BuildCommandLine then
						table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. subProject.BuildCommandLine[1] .. '";\n')
					else
						table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. ospath.join(destinationRootPath, 'jam') .. '";\n')
					end
				end
				table.insert(self.Contents, '\t\t\tbuildRules = (\n')
				table.insert(self.Contents, '\t\t\t\t' .. info.PBXBuildRuleUuid .. ' /* PBXBuildRule */,\n')
				table.insert(self.Contents, '\t\t\t);\n');
				table.insert(self.Contents, '\t\t\tdependencies = (\n')
				table.insert(self.Contents, '\t\t\t);\n')
				table.insert(self.Contents, '\t\t\tname = "' .. subProjectInfo.Name .. '";\n')
				table.insert(self.Contents, '\t\t\tpassBuildSettingsInEnvironment = 1;\n')
				table.insert(self.Contents, '\t\t\tproductName = "' .. subProjectInfo.Name .. '";\n')

				if subProjectInfo.ExecutablePath then
					local entryUuid = info.EntryUuids['app>' .. subProjectInfo.ExecutablePath]
					if entryUuid then
						table.insert(self.Contents, '\t\t\tproductReference = ' .. entryUuid .. '; /* ' .. subProjectInfo.ExecutablePath .. ' */\n')
					end
				end
				if subProject.Options then
					if subProject.Options.bundle then
						table.insert(self.Contents, '\t\t\tproductType = "com.apple.product-type.application";\n');
					elseif subProject.Options.app then
						table.insert(self.Contents, '\t\t\tproductType = "com.apple.product-type.tool";\n');
					elseif subProject.Options.lib then
						table.insert(self.Contents, '\t\t\tproductType = "com.apple.product-type.library.static";\n');
					end
				end

				table.insert(self.Contents, '\t\t};\n')
			end
		end
		if projectType == 'native' then
			table.insert(self.Contents, '/* End PBXNativeTarget section */\n\n')
		elseif projectType == 'legacy' then
			table.insert(self.Contents, '/* End PBXLegacyTarget section */\n\n')
		end
	end

	table.insert(self.Contents, "/* Begin PBXShellScriptBuildPhase section */\n")
	for curProject in ivalues(allTargets) do
		if curProject.XcodeProjectType == 'native' then
			local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name, self.Workspace)
			local subProject = Projects[curProject.Name]
			table.insert(self.Contents, expand([[
		$(ShellScriptUuid) /* ShellScript */ = {
			isa = PBXShellScriptBuildPhase;
			buildActionMask = 2147483647;
			files = (
			);
			inputPaths = (
			);
			outputPaths = (
			);
			runOnlyForDeploymentPostprocessing = 0;
			shellPath = /bin/sh;
			shellScript = "]], subProjectInfo))
			if subProject.BuildCommandLine then
				table.insert(self.Contents, subProject.BuildCommandLine[1] .. '";\n')
			else
				table.insert(self.Contents, ospath.join(destinationRootPath, 'jam') .. [[ $COMMANDLINE";]] .. '\n')
			end
			table.insert(self.Contents, "\t\t};\n")
		end
	end
	table.insert(self.Contents, expand("/* End PBXShellScriptBuildPhase section */\n\n"))

	table.insert(self.Contents, "/* Begin PBXSourcesBuildPhase section */\n")
	for curProject in ivalues(allTargets) do
		if curProject.XcodeProjectType == 'native' then
            local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name, self.Workspace)
            local subProject = Projects[curProject.Name]
            table.insert(self.Contents, expand([[
		$(SourcesUuid) /* Sources */ = {
			isa = PBXSourcesBuildPhase;
			buildActionMask = 2147483647;
			files = (
]], subProjectInfo))

            XcodeHelper_WritePBXBuildFileReferences(self, subProject.SourcesTree)

            table.insert(self.Contents,[[
			);
			runOnlyForDeploymentPostprocessing = 0;
		};
]])
        end
	end
	table.insert(self.Contents, "\n/* End PBXSourcesBuildPhase section */\n\n")
end

local function XcodeHelper_WritePBXProject(self, info, allTargets)
	-- Write PBXProject.
	table.insert(self.Contents, '/* Begin PBXProject section */\n')
	table.insert(self.Contents, ("\t\t%s /* Project object */ = {\n"):format(info.ProjectUuid))
	table.insert(self.Contents, expand([[
			isa = PBXProject;
			buildConfigurationList = $(ProjectBuildConfigurationListUuid) /* Build configuration list for PBXProject "$(Name)" */;
			compatibilityVersion = "Xcode 3.2";
			hasScannedForEncodings = 0;
			mainGroup = $(GroupUuid) /* $(Name) */;
]], info))
	local productsEntryUuid = self.EntryUuids[self.ProjectName .. '/Products/']
	if productsEntryUuid then
		table.insert(self.Contents, ("\t\t\tproductRefGroup = %s /* Products */;\n"):format(self.EntryUuids[self.ProjectName .. '/Products/']))
	end
	table.insert(self.Contents, expand([[
			projectDirPath = "";
			projectRoot = "";
			targets = (
]], info))
	for curProject in ivalues(allTargets) do
		local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name, self.Workspace)
		table.insert(self.Contents, ("\t\t\t\t\t%s /* %s */,\n"):format(subProjectInfo.LegacyTargetUuid, subProjectInfo.Name))
	end
	table.insert(self.Contents, [[
			);
		};
]])
	table.insert(self.Contents, '/* End PBXProject section */\n\n')
end

local function XcodeHelper_WriteProjectXCBuildConfiguration(self, info, projectName, workspaceConfigs)
	local subProject = Projects[projectName]

	-- Write project configurations.
	for _, platformName in ipairs(Config.Platforms) do
		for _, configName in ipairs(workspaceConfigs) do
			local configInfo = subProject.ConfigInfo[platformName][configName]

			local platformAndConfigText = platformName .. ' - ' .. configName
			table.insert(self.Contents, "\t\t" .. info.ProjectConfigUuids[platformName][configName] .. ' /* ' .. platformAndConfigText .. ' */ = {\n')
			table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
			table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
	--			table.insert(self.Contents, "\t\t\t\tOS = MACOSX;\n")
			local productName = configInfo.OutputName
--[[			if subProject.Options  and  subProject.Options.app then
				if subProject.Options.bundle then
					productName = productName .. '.app'
				end
			end
]]
			table.insert(self.Contents, "\t\t\t\tPRODUCT_NAME = \"" .. ((productName and productName ~= '') and productName or projectName) .. "\";\n")
			table.insert(self.Contents, "\t\t\t};\n")
			table.insert(self.Contents, '\t\t\tname = "' .. platformAndConfigText .. '";\n')
			table.insert(self.Contents, "\t\t};\n")
		end
	end
end

local function XcodeHelper_WriteXCBuildConfigurations(self, info, projectName, workspaceConfigs)
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName, self.Workspace)
	local subProject = Projects[projectName]

	-- Write XCBuildConfigurations.
	table.insert(self.Contents, '/* Begin XCBuildConfiguration section */\n')

	for _, platformName in ipairs(Config.Platforms) do
		for _, workspaceConfigName in ipairs(workspaceConfigs) do
			local configName = GetJamConfigName(workspaceConfigName, self.Workspace)

			local configInfo = subProject.ConfigInfo[platformName][workspaceConfigName]

			local platformAndConfigText = platformName .. ' - ' .. workspaceConfigName
			table.insert(self.Contents, "\t\t" .. subProjectInfo.LegacyTargetConfigUuids[platformName][workspaceConfigName] .. ' /* ' .. platformAndConfigText .. ' */ = {\n')
			table.insert(self.Contents, "\t\t\tisa = XCBuildConfiguration;\n")
			table.insert(self.Contents, "\t\t\tbuildSettings = {\n")
			table.insert(self.Contents, "\t\t\t\tTARGET_NAME = \"" .. (subProject.TargetName or projectName) .. "\";\n")

			-- Deployment target (iOS).
			local iosSdkVersionMin
			if subProject.IOS_SDK_VERSION_MIN and  subProject.IOS_SDK_VERSION_MIN[platformName]  and  subProject.IOS_SDK_VERSION_MIN[platformName][configName] then
				iosSdkVersionMin = subProject.IOS_SDK_VERSION_MIN[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].IOS_SDK_VERSION_MIN  and  Projects['C.*'].IOS_SDK_VERSION_MIN[platformName]  and  Projects['C.*'].IOS_SDK_VERSION_MIN[platformName][configName] then
				iosSdkVersionMin = Projects['C.*'].IOS_SDK_VERSION_MIN[platformName][configName]			
		   	end

			if iosSdkVersionMin then
				table.insert(self.Contents, "\t\t\t\tIPHONEOS_DEPLOYMENT_TARGET = \"" .. iosSdkVersionMin .. "\";\n")
			end

			-- Deployment target (OSX).
			local osxSdkVersionMin
			if subProject.OSX_SDK_VERSION_MIN  and  subProject.OSX_SDK_VERSION_MIN[platformName]  and  subProject.OSX_SDK_VERSION_MIN[platformName][configName] then
				osxSdkVersionMin = subProject.OSX_SDK_VERSION_MIN[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].OSX_SDK_VERSION_MIN  and  Projects['C.*'].OSX_SDK_VERSION_MIN[platformName]  and  Projects['C.*'].OSX_SDK_VERSION_MIN[platformName][configName] then
				osxSdkVersionMin = Projects['C.*'].OSX_SDK_VERSION_MIN[platformName][configName]			
		   	end

			if osxSdkVersionMin then
				table.insert(self.Contents, "\t\t\t\tMACOSX_DEPLOYMENT_TARGET = \"" .. osxSdkVersionMin .. "\";\n")
			end

			local jamCommandLine = '-g'

			local customWorkspaceConfig = self.Workspace  and  self.Workspace.Configs  and  self.Workspace.Configs[workspaceConfigName]
			if customWorkspaceConfig then
				jamCommandLine = jamCommandLine .. ' ' .. expand(table.concat(customWorkspaceConfig.CommandLineOptions, ' '), configInfo, info, _G)
			else
				jamCommandLine = jamCommandLine .. ' C.TOOLCHAIN=' .. platformName .. '/' .. configName
			end
			table.insert(self.Contents, '\t\t\t\tCOMMANDLINE = "' .. jamCommandLine .. '";\n')

			table.insert(self.Contents, "\t\t\t\tPLATFORM = " .. platformName .. ";\n")
			table.insert(self.Contents, "\t\t\t\tCONFIG = " .. configName .. ";\n")
			if subProject.BUNDLE_PATH  and subProject.BUNDLE_PATH[platformName]  and  subProject.BUNDLE_PATH[platformName][configName]  then
				table.insert(self.Contents, "\t\t\t\tCONFIGURATION_BUILD_DIR = \"" .. ospath.remove_slash(ospath.remove_filename(subProject.BUNDLE_PATH[platformName][configName])) .. "\";\n")
			elseif configInfo.OutputPath ~= '' then
				table.insert(self.Contents, "\t\t\t\tCONFIGURATION_BUILD_DIR = \"" .. ospath.remove_slash(configInfo.OutputPath) .. "\";\n")
			end

			if configInfo.Includes ~= '' then
				self.Contents[#self.Contents + 1] = '\t\t\t\tUSER_HEADER_SEARCH_PATHS = "' .. configInfo.Includes .. '";\n'
			end

			local productName = configInfo.OutputName
--[[			if subProject.Options  and  subProject.Options.app then
				if subProject.Options.bundle then
					productName = productName .. '.app'
				end
			end
]]			
			table.insert(self.Contents, "\t\t\t\tPRODUCT_NAME = \"" .. ((productName and productName ~= '') and productName or projectName) .. "\";\n")
--			table.insert(self.Contents, '\t\t\t\tINFOPLIST_FILE = "myopengl-Info.plist";\n');

			-- Write SDKROOT.
			if true then
				local sdkRoot
				if subProject.XCODE_SDKROOT  and  subProject.XCODE_SDKROOT[platformName]  and  subProject.XCODE_SDKROOT[platformName][configName] then
					sdkRoot = subProject.XCODE_SDKROOT[platformName][configName]
				elseif Projects['C.*']  and  Projects['C.*'].XCODE_SDKROOT  and  Projects['C.*'].XCODE_SDKROOT[platformName]  and  Projects['C.*'].XCODE_SDKROOT[platformName][configName] then
					sdkRoot = Projects['C.*'].XCODE_SDKROOT[platformName][configName]			
				end
				if sdkRoot then
					table.insert(self.Contents, "\t\t\t\tSDKROOT = " .. sdkRoot .. ";\n")
				end
			end

			-- Write PRODUCT_BUNDLE_IDENTIFIER.
			local productBundleIdentifier
			if subProject.PRODUCT_BUNDLE_IDENTIFIER  and  subProject.PRODUCT_BUNDLE_IDENTIFIER[platformName]  and  subProject.PRODUCT_BUNDLE_IDENTIFIER[platformName][configName] then
				productBundleIdentifier = subProject.PRODUCT_BUNDLE_IDENTIFIER[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].PRODUCT_BUNDLE_IDENTIFIER  and  Projects['C.*'].PRODUCT_BUNDLE_IDENTIFIER[platformName]  and  Projects['C.*'].PRODUCT_BUNDLE_IDENTIFIER[platformName][configName] then
				productBundleIdentifier = Projects['C.*'].PRODUCT_BUNDLE_IDENTIFIER[platformName][configName]			
			end
			if productBundleIdentifier then
				table.insert(self.Contents, "\t\t\t\tPRODUCT_BUNDLE_IDENTIFIER = \"" .. productBundleIdentifier .. "\";\n")
			end

			-- Write PROVISIONING_PROFILE_SPECIFIER.
			local provisioningProfileSpecifier
			if subProject.PROVISIONING_PROFILE_SPECIFIER  and  subProject.PROVISIONING_PROFILE_SPECIFIER[platformName]  and  subProject.PROVISIONING_PROFILE_SPECIFIER[platformName][configName] then
				provisioningProfileSpecifier = subProject.PROVISIONING_PROFILE_SPECIFIER[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].PROVISIONING_PROFILE_SPECIFIER  and  Projects['C.*'].PROVISIONING_PROFILE_SPECIFIER[platformName]  and  Projects['C.*'].PROVISIONING_PROFILE_SPECIFIER[platformName][configName] then
				provisioningProfileSpecifier = Projects['C.*'].PROVISIONING_PROFILE_SPECIFIER[platformName][configName]			
			end
			if provisioningProfileSpecifier then
				table.insert(self.Contents, "\t\t\t\tPROVISIONING_PROFILE_SPECIFIER = \"" .. provisioningProfileSpecifier .. "\";\n")
			end

			-- Write CODE_SIGN_ENTITLEMENTS.
			local codeSignEntitlements
			if subProject.XCODE_ENTITLEMENTS  and  subProject.XCODE_ENTITLEMENTS[platformName]  and  subProject.XCODE_ENTITLEMENTS[platformName][configName] then
				codeSignEntitlements = subProject.XCODE_ENTITLEMENTS[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].XCODE_ENTITLEMENTS  and  Projects['C.*'].XCODE_ENTITLEMENTS[platformName]  and  Projects['C.*'].XCODE_ENTITLEMENTS[platformName][configName] then
				codeSignEntitlements = Projects['C.*'].XCODE_ENTITLEMENTS[platformName][configName]			
		   	end
			if codeSignEntitlements then
				table.insert(self.Contents, "\t\t\t\tCODE_SIGN_ENTITLEMENTS = \"" .. codeSignEntitlements .. "\";\n")
			end

			-- Write CODE_SIGN_IDENTITY.
			local codeSignIdentity = "iPhone Developer"
			if subProject.IOS_SIGNING_IDENTITY  and  subProject.IOS_SIGNING_IDENTITY[platformName]  and  subProject.IOS_SIGNING_IDENTITY[platformName][configName] then
				codeSignIdentity = subProject.IOS_SIGNING_IDENTITY[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].IOS_SIGNING_IDENTITY  and  Projects['C.*'].IOS_SIGNING_IDENTITY[platformName]  and  Projects['C.*'].IOS_SIGNING_IDENTITY[platformName][configName] then
				codeSignIdentity = Projects['C.*'].IOS_SIGNING_IDENTITY[platformName][configName]			
		   	end

			local archs
			if subProject.XCODE_ARCHITECTURE  and  subProject.XCODE_ARCHITECTURE[platformName]  and  subProject.XCODE_ARCHITECTURE[platformName][configName] then
				archs = table.concat(subProject.XCODE_ARCHITECTURE[platformName][configName], ' ')
			elseif Projects['C.*'].XCODE_ARCHITECTURE  and  Projects['C.*'].XCODE_ARCHITECTURE[platformName]  and  Projects['C.*'].XCODE_ARCHITECTURE[platformName][configName] then
				archs = table.concat(Projects['C.*'].XCODE_ARCHITECTURE[platformName][configName], ' ')
			elseif platformName == 'macosx32'  or  platformName == 'macosx64' then
				archs = "$(ARCHS_STANDARD_32_64_BIT)"
			elseif platformName == 'ios'  or  platformName == 'iossimulator' then
				archs = "$(ARCHS_UNIVERSAL_IPHONE_OS)"
			end
			self.Contents[#self.Contents + 1] = "\t\t\t\tARCHS = \"" .. archs .. "\";\n"

			if platformName == 'ios'  or  platformName == 'iossimulator' then
				table.insert(self.Contents, '\t\t\t\tARCHS = "$(ARCHS_UNIVERSAL_IPHONE_OS)";\n')
				table.insert(self.Contents, '\t\t\t\t"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "' .. codeSignIdentity .. '";\n')
				local targetedDeviceFamily = "1,2"
				if subProject.TARGETED_DEVICE_FAMILY  and  subProject.TARGETED_DEVICE_FAMILY[platformName]  and  subProject.TARGETED_DEVICE_FAMILY[platformName][configName] then
					targetedDeviceFamily = subProject.TARGETED_DEVICE_FAMILY[platformName][configName]
				elseif Projects['C.*']  and  Projects['C.*'].TARGETED_DEVICE_FAMILY  and  Projects['C.*'].TARGETED_DEVICE_FAMILY[platformName]  and  Projects['C.*'].TARGETED_DEVICE_FAMILY[platformName][configName] then
					targetedDeviceFamily = Projects['C.*'].TARGETED_DEVICE_FAMILY[platformName][configName]
				end
				table.insert(self.Contents, "\t\t\t\tTARGETED_DEVICE_FAMILY = \"" .. targetedDeviceFamily .. "\";\n")
			end
			table.insert(self.Contents, "\t\t\t};\n")
			table.insert(self.Contents, '\t\t\tname = "' .. platformAndConfigText .. '";\n')
			table.insert(self.Contents, "\t\t};\n")
		end
	end

	-- Write project configurations.
	XcodeHelper_WriteProjectXCBuildConfiguration(self, info, projectName, workspaceConfigs)
	
	table.insert(self.Contents, '/* End XCBuildConfiguration section */\n\n')
end

local function XcodeHelper_WriteProjectXCConfigurationList(self, info, workspaceConfigs)
	table.insert(self.Contents, "\t\t" .. info.ProjectBuildConfigurationListUuid .. ' /* Build configuration list for PBXProject "' .. info.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, platformName in ipairs(Config.Platforms) do
		for _, config in ipairs(workspaceConfigs) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t\t\t" .. info.ProjectConfigUuids[platformName][config] .. " /* " .. platformAndConfigText .. " */,\n")
		end
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = \"" .. Config.Platforms[1] .. ' - ' .. workspaceConfigs[1] .. "\";\n")
	table.insert(self.Contents, "\t\t};\n")
end

local function XcodeHelper_WriteXCConfigurationLists(self, info, projectName, workspaceConfigs)
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName, self.Workspace)

	-- Write XCConfigurationLists.
	table.insert(self.Contents, "/* Begin XCConfigurationList section */\n")

	table.insert(self.Contents, "\t\t" .. subProjectInfo.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXNativeTarget "' .. subProjectInfo.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, platformName in ipairs(Config.Platforms) do
		for _, config in ipairs(workspaceConfigs) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t\t\t" .. subProjectInfo.LegacyTargetConfigUuids[platformName][config] .. " /* " .. platformAndConfigText .. " */,\n")
		end
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	table.insert(self.Contents, "\t\t};\n\n")

	XcodeHelper_WriteProjectXCConfigurationList(self, info, workspaceConfigs)

	table.insert(self.Contents, "/* End XCConfigurationList section */\n\n")
end

local XcodeProjectMetaTable = {  __index = XcodeProjectMetaTable  }

function XcodeProjectMetaTable:Write(outputPath)
	local projectName = self.ProjectName
	local projectPath = ospath.join(outputPath, self.ProjectName .. '.xcodeproj')
	local filename = ospath.join(outputPath, projectPath, 'project.pbxproj')

	local info = XcodeHelper_GetProjectExportInfo(self.ProjectName, self.Workspace)
	info.Filename = filename

	local project = Projects[self.ProjectName]

	local workspaceConfigs = GetWorkspaceConfigList(self.Workspace)

	--project._insertedapp = nil

	-- Write header.
	table.insert(self.Contents, [[
// !$*UTF8*$!
{
	archiveVersion = 1;
	classes = {
	};
	objectVersion = 46;
	objects = {

]])

	-- Build all targets
	local allTargets = { project }
	if false  and  project.Name ~= buildWorkspaceName  and  project.Name ~= updateWorkspaceName then
		local jamProject = deepcopy(project)
		jamProject.Name = '!clean:' .. project.Name
		Projects[jamProject.Name] = project
		jamProject.TargetName = 'clean:' .. project.Name
		jamProject.Options = nil
		jamProject.SourcesTree = nil
		jamProject.XcodeProjectType = 'legacy'
		allTargets[#allTargets + 1] = jamProject
	end

	table.sort(allTargets, function(left, right) return left.Name:lower() < right.Name:lower() end)

	project.SourcesTree.folder = project.Name
	local projectTree = { project.SourcesTree }
	XcodeHelper_AssignEntryUuids(info.EntryUuids, projectTree, '', '')
	XcodeHelper_AssignEntryUuids(info.EntryUuids, projectTree, '', 'PBXBuildFile*')
	info.GroupUuid = info.EntryUuids[project.Name .. '/']
	self.EntryUuids = info.EntryUuids

	-- Sort the folders and files.
	XcodeHelper_SortFoldersAndFiles(self, projectTree)

	-- Write PBXBuildFile section.
	table.insert(self.Contents, [[
/* Begin PBXBuildFile section */
]])
	XcodeHelper_WritePBXBuildFiles(self, projectTree)
	table.insert(self.Contents, [[
/* End PBXBuildFile section */

]])

	table.insert(self.Contents, [[
/* Begin PBXBuildRule section */
		]] .. info.PBXBuildRuleUuid .. [[ /* PBXBuildRule */ = {
			isa = PBXBuildRule;
			compilerSpec = com.apple.compilers.proxy.script;
			filePatterns = "*.cpp *.c *.mm *.m";
			fileType = pattern.proxy;
			isEditable = 1;
			outputFiles = (
			);
			script = "";
		};
/* End PBXBuildRule section */

]])

	-- Write PBXFileReferences.
	table.insert(self.Contents, [[
/* Begin PBXFileReference section */
]])
	XcodeHelper_WritePBXFileReferences(self, project.SourcesTree)
	table.insert(self.Contents, [[
/* End PBXFileReference section */

]])

	-- Write PBXGroups.
	table.insert(self.Contents, '/* Begin PBXGroup section */\n')
	XcodeHelper_WritePBXGroups(self.Contents, self.EntryUuids, projectTree, '')
	table.insert(self.Contents, '/* End PBXGroup section */\n\n')

	-- Write PBXLegacyTarget.
	local projectsPath = _getWorkspaceProjectsPath()
	XcodeHelper_WritePBXLegacyTarget(self, info, allTargets, projectsPath)

	-- Write PBXProject.
	XcodeHelper_WritePBXProject(self, info, allTargets)

	for curProject in ivalues(allTargets) do
		XcodeHelper_WriteXCBuildConfigurations(self, info, curProject.Name, workspaceConfigs)
		XcodeHelper_WriteXCConfigurationLists(self, info, curProject.Name, workspaceConfigs)
	end

	table.insert(self.Contents, "\t};\n")
	table.insert(self.Contents, "\trootObject = " .. info.ProjectUuid .. " /* Project object */;\n")
	table.insert(self.Contents, "}\n")

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')
	WriteFileIfModified(filename, self.Contents)

	---------------------------------------------------------------------------
	-- Write the schemes
	---------------------------------------------------------------------------
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName, self.Workspace)
	local subProject = Projects[projectName]

	for _, platformName in ipairs(Config.Platforms) do
		for _, configName in ipairs(workspaceConfigs) do
			local configInfo = subProject.ConfigInfo[platformName][configName]
			local filename = ospath.join(projectPath, 'xcshareddata', 'xcschemes', projectName .. '-' .. platformName .. '-' .. configName .. '.xcscheme')

			local contents = {}

			local expandData = {
				BuildConfiguration = platformName .. ' - ' .. configName,
				ProductIdentifier = subProjectInfo.LegacyTargetUuid,
				ExecutableName = configInfo.OutputName,
				ProjectName = self.ProjectName,
				XcodeProjName = self.ProjectName .. '.xcodeproj',
			}
			contents[#contents + 1] = expand([[
<?xml version="1.0" encoding="UTF-8"?>
<Scheme
   LastUpgradeVersion = "0630"
   version = "1.3">
   <BuildAction
      parallelizeBuildables = "YES"
      buildImplicitDependencies = "YES">
      <BuildActionEntries>
         <BuildActionEntry
            buildForTesting = "YES"
            buildForRunning = "YES"
            buildForProfiling = "YES"
            buildForArchiving = "YES"
            buildForAnalyzing = "YES">
            <BuildableReference
               BuildableIdentifier = "primary"
               BlueprintIdentifier = "$(ProductIdentifier)"
               BuildableName = "$(ExecutableName)"
               BlueprintName = "$(ProjectName)"
               ReferencedContainer = "container:$(XcodeProjName)">
            </BuildableReference>
         </BuildActionEntry>
      </BuildActionEntries>
   </BuildAction>
   <TestAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      shouldUseLaunchSchemeArgsEnv = "YES"
      buildConfiguration = "$(BuildConfiguration)">
      <Testables>
      </Testables>
      <MacroExpansion>
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$(ProductIdentifier)"
            BuildableName = "$(ExecutableName)"
            BlueprintName = "$(ProjectName)"
            ReferencedContainer = "container:$(XcodeProjName)">
         </BuildableReference>
      </MacroExpansion>
   </TestAction>
   <LaunchAction
      selectedDebuggerIdentifier = "Xcode.DebuggerFoundation.Debugger.LLDB"
      selectedLauncherIdentifier = "Xcode.DebuggerFoundation.Launcher.LLDB"
      launchStyle = "0"
      useCustomWorkingDirectory = "NO"
      buildConfiguration = "$(BuildConfiguration)"
      ignoresPersistentStateOnLaunch = "NO"
      debugDocumentVersioning = "YES"
      allowLocationSimulation = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$(ProductIdentifier)"
            BuildableName = "$(ExecutableName)"
            BlueprintName = "$(ProjectName)"
            ReferencedContainer = "container:$(XcodeProjName)">
         </BuildableReference>
      </BuildableProductRunnable>
      <AdditionalOptions>
      </AdditionalOptions>
   </LaunchAction>
   <ProfileAction
      shouldUseLaunchSchemeArgsEnv = "YES"
      savedToolIdentifier = ""
      useCustomWorkingDirectory = "NO"
      buildConfiguration = "$(BuildConfiguration)"
      debugDocumentVersioning = "YES">
      <BuildableProductRunnable
         runnableDebuggingMode = "0">
         <BuildableReference
            BuildableIdentifier = "primary"
            BlueprintIdentifier = "$(ProductIdentifier)"
            BuildableName = "$(ExecutableName)"
            BlueprintName = "$(ProjectName)"
            ReferencedContainer = "container:$(XcodeProjName)">
         </BuildableReference>
      </BuildableProductRunnable>
   </ProfileAction>
   <AnalyzeAction
      buildConfiguration = "$(BuildConfiguration)">
   </AnalyzeAction>
   <ArchiveAction
      buildConfiguration = "$(BuildConfiguration)"
      revealArchiveInOrganizer = "YES">
   </ArchiveAction>
</Scheme>
]], expandData, _G)

			contents = table.concat(contents):gsub('\r\n', '\n')
			WriteFileIfModified(filename, contents)
		end
	end
end

function XcodeProject(projectName, options, workspace)
	return setmetatable(
		{
			Contents = {},
			ProjectName = projectName,
			Options = options,
			Workspace = workspace,
		}, { __index = XcodeProjectMetaTable }
	)
end


local XcodeWorkspaceMetaTable = {  __index = XcodeWorkspaceMetaTable  }

function XcodeWorkspaceMetaTable:_GatherWorkspaceFolders(folder, folderList, fullPath)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			local workspaceFolder = fullPath .. '\\' .. entry.folder
			folderList[#folderList + 1] = workspaceFolder
			self:_GatherWorkspaceFolders(entry, folderList, workspaceFolder)
		end
	end
end


function XcodeWorkspaceMetaTable:_WriteNestedProjects(folder, tabs)
	for entry in ivalues(folder) do
		if type(entry) == 'table' then
			self.Contents[#self.Contents + 1] = tabs .. '<Group\n'
			self.Contents[#self.Contents + 1] = tabs .. '   location = "container:"\n'
			self.Contents[#self.Contents + 1] = tabs .. '   name = "' .. entry.folder .. '">\n'
			self:_WriteNestedProjects(entry, tabs .. '   ')
			self.Contents[#self.Contents + 1] = tabs .. '</Group>\n'
		else
			local info = ProjectExportInfo[entry:lower()]
			if info then
				self.Contents[#self.Contents + 1] = tabs .. '<FileRef\n'
				self.Contents[#self.Contents + 1] = tabs .. '   location = "absolute:' .. info.Filename:gsub('/project.pbxproj', '') .. '">\n'
				self.Contents[#self.Contents + 1] = tabs .. '</FileRef>\n'
			end
		end
	end
end


function XcodeWorkspaceMetaTable:Write(outputPath)
	local filename = ospath.join(outputPath, self.Name .. '.xcworkspace', 'contents.xcworkspacedata')

	local workspace = Workspaces[self.Name]

	--ospath.mkdir(filename)

	self.Contents[#self.Contents + 1] = [[
<?xml version="1.0" encoding="UTF-8"?>
<Workspace
   version = "1.0">
]]

	-- Write the folders we use.
	local folderList = {}
	self:_GatherWorkspaceFolders(workspace.ProjectTree, folderList, '')
	self:_WriteNestedProjects(workspace.ProjectTree, '   ')

	self.Contents[#self.Contents + 1] = [[
</Workspace>
]]

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
	local chunk = loadfile(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'))
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end
end


function XcodeShutdown()
	prettydump.dumpascii(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'), 'ProjectExportInfo', ProjectExportInfo)
end





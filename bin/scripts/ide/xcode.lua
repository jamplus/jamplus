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

-- Use the upper 24 characters of a UUID as the Xcode UUID.
function XcodeUuid()
	return uuid.new():gsub('%-', ''):upper():sub(1, 24)
end


-- Assign UUIDs to every entry in the folder tree.
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



local function XcodeHelper_GetProjectExportInfo(projectName)
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
	if type(info.ShellScriptUuid) ~= 'string' then
		info.ShellScriptUuid = XcodeUuid()
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

	for _, platformName in ipairs(Config.Platforms) do
		if type(info.ExecutableInfo[platformName]) ~= 'table' then
			info.ExecutableInfo[platformName] = {}
		end

		for configName in ivalues(Config.Configurations) do
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
			for configName in ivalues(Config.Configurations) do
				info.LegacyTargetConfigUuids[platformName][configName] = XcodeUuid()
			end
		end
		
		if type(info.ProjectConfigUuids) ~= 'table' then
			info.ProjectConfigUuids = {}
		end

		if type(info.ProjectConfigUuids[platformName]) ~= 'table' then
			info.ProjectConfigUuids[platformName] = {}
			for configName in ivalues(Config.Configurations) do
				info.ProjectConfigUuids[platformName][configName] = XcodeUuid()
			end
		end
	end

	if not project.ConfigInfo then project.ConfigInfo = {} end
	for _, platformName in ipairs(Config.Platforms) do
		if not project.ConfigInfo[platformName] then project.ConfigInfo[platformName] = {} end
		for configName in ivalues(Config.Configurations) do
			local configInfo = project.ConfigInfo[platformName][configName]
			if not configInfo then
				configInfo = {
					Platform = platformName,
					Config = configName,
					Defines = '',
					Includes = '',
					OutputPath = '',
					OutputName = '',
				}
				project.ConfigInfo[platformName][configName] = configInfo
			end

			if configInfo.Defines == ''  and  project.Defines  and  project.Defines[platformName]  and  project.Defines[platformName][configName] then
				configInfo.Defines = table.concat(project.Defines[platformName][configName], ';'):gsub('"', '\\&quot;')
			end
			if configInfo.IncludePaths == ''  and  project.IncludePaths  and project.IncludePaths[platformName]  and  project.IncludePaths[platformName][configName]  then
				configInfo.Includes = table.concat(project.IncludePaths[platformName][configName], ';')
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


function XcodeHelper_WritePBXFileReferences(self, folder)
	table.sort(folder, _XcodeProjectSortFunction)
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
						self.EntryUuids[entry], entry, ext, ospath.remove_directory(entry), entry))
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
				local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name)
				local subProject = Projects[curProject.Name]

				table.insert(self.Contents, ("\t\t%s /* %s */ = {\n"):format(subProjectInfo.LegacyTargetUuid, subProjectInfo.Name))
				if projectType == 'native' then
					table.insert(self.Contents, '\t\t\tisa = PBXNativeTarget;\n')
				else
					table.insert(self.Contents, '\t\t\tisa = PBXLegacyTarget;\n')

					if subProject.BuildCommandLine then
						table.insert(self.Contents, '\t\t\tbuildArgumentsString = "";\n')
					else
						table.insert(self.Contents, '\t\t\tbuildArgumentsString = "$(PLATFORM) $(CONFIG) $(ACTION) $(TARGET_NAME)";\n')
					end
				end
				table.insert(self.Contents, '\t\t\tbuildConfigurationList = ' .. subProjectInfo.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXLegacyTarget "' .. subProjectInfo.Name .. '" */;\n')
				table.insert(self.Contents, '\t\t\tbuildPhases = (\n')
				table.insert(self.Contents, '\t\t\t\t' .. subProjectInfo.ShellScriptUuid .. ' /* ShellScript */,\n')
				table.insert(self.Contents, '\t\t\t);\n')
				if projectType == 'legacy' then
					if subProject.BuildCommandLine then
						table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. subProject.BuildCommandLine[1] .. '";\n')
					else
						table.insert(self.Contents, '\t\t\tbuildToolPath = "' .. ospath.join(_getWorkspacePath(), 'xcodejam') .. '";\n')
					end
				end
				table.insert(self.Contents, '\t\t\tbuildRules = (\n')
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
			local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name)
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
				table.insert(self.Contents, ospath.join(_getWorkspacePath(), 'xcodejam') .. [[ $PLATFORM $CONFIG $ACTION $TARGET_NAME";]] .. '\n')
			end
			table.insert(self.Contents, "\t\t};\n")
		end
	end
	table.insert(self.Contents, expand("/* End PBXShellScriptBuildPhase section */\n\n"))
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
		local subProjectInfo = XcodeHelper_GetProjectExportInfo(curProject.Name)
		table.insert(self.Contents, ("\t\t\t\t\t%s /* %s */,\n"):format(subProjectInfo.LegacyTargetUuid, subProjectInfo.Name))
	end
	table.insert(self.Contents, [[
			);
		};
]])
	table.insert(self.Contents, '/* End PBXProject section */\n\n')
end

local function XcodeHelper_WriteProjectXCBuildConfiguration(self, info, projectName)
	local subProject = Projects[projectName]

	-- Write project configurations.
	for _, platformName in ipairs(Config.Platforms) do
		for _, configName in ipairs(Config.Configurations) do
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

local function XcodeHelper_WriteXCBuildConfigurations(self, info, projectName)
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName)
	local subProject = Projects[projectName]

	-- Write XCBuildConfigurations.
	table.insert(self.Contents, '/* Begin XCBuildConfiguration section */\n')

	for _, platformName in ipairs(Config.Platforms) do
		for _, configName in ipairs(Config.Configurations) do
			local configInfo = subProject.ConfigInfo[platformName][configName]

			local platformAndConfigText = platformName .. ' - ' .. configName
			table.insert(self.Contents, "\t\t" .. subProjectInfo.LegacyTargetConfigUuids[platformName][configName] .. ' /* ' .. platformAndConfigText .. ' */ = {\n')
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
				print( "MACOSX_DEPLOYMENT_TARGET found for " .. platformName .. " - " .. configName )
			end

			table.insert(self.Contents, "\t\t\t\tPLATFORM = " .. platformName .. ";\n")
			table.insert(self.Contents, "\t\t\t\tCONFIG = " .. configName .. ";\n")
			if configInfo.OutputPath ~= '' then
				table.insert(self.Contents, "\t\t\t\tCONFIGURATION_BUILD_DIR = \"" .. ospath.remove_slash(configInfo.OutputPath) .. "\";\n")
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
			local sdkRoot
			if subProject.XCODE_SDKROOT  and  subProject.XCODE_SDKROOT[platformName]  and  subProject.XCODE_SDKROOT[platformName][configName] then
				sdkRoot = subProject.XCODE_SDKROOT[platformName][configName]
			elseif Projects['C.*']  and  Projects['C.*'].XCODE_SDKROOT  and  Projects['C.*'].XCODE_SDKROOT[platformName]  and  Projects['C.*'].XCODE_SDKROOT[platformName][configName] then
				sdkRoot = Projects['C.*'].XCODE_SDKROOT[platformName][configName]			
		   	end
			if sdkRoot then
				table.insert(self.Contents, "\t\t\t\tSDKROOT = " .. sdkRoot .. ";\n")
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


			if platformName == 'macosx32'  or  platformName == 'macosx64' then
				table.insert(self.Contents, "\t\t\t\tARCHS = \"$(ARCHS_STANDARD_32_64_BIT)\";\n");
			elseif platformName == 'ios'  or  platformName == 'iossimulator' then
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
	XcodeHelper_WriteProjectXCBuildConfiguration(self, info, projectName)
	
	table.insert(self.Contents, '/* End XCBuildConfiguration section */\n\n')
end

local function XcodeHelper_WriteProjectXCConfigurationList(self, info)
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
	table.insert(self.Contents, "\t\t\tdefaultConfigurationName = \"" .. Config.Platforms[1] .. ' - ' .. Config.Configurations[1] .. "\";\n")
	table.insert(self.Contents, "\t\t};\n")
end

local function XcodeHelper_WriteXCConfigurationLists(self, info, projectName)
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName)

	-- Write XCConfigurationLists.
	table.insert(self.Contents, "/* Begin XCConfigurationList section */\n")

	table.insert(self.Contents, "\t\t" .. subProjectInfo.LegacyTargetBuildConfigurationListUuid .. ' /* Build configuration list for PBXNativeTarget "' .. subProjectInfo.Name .. '" */ = {\n')
	table.insert(self.Contents, "\t\t\tisa = XCConfigurationList;\n")
	table.insert(self.Contents, "\t\t\tbuildConfigurations = (\n")
	for _, platformName in ipairs(Config.Platforms) do
		for _, config in ipairs(Config.Configurations) do
			local platformAndConfigText = platformName .. ' - ' .. config
			table.insert(self.Contents, "\t\t\t\t" .. subProjectInfo.LegacyTargetConfigUuids[platformName][config] .. " /* " .. platformAndConfigText .. " */,\n")
		end
	end
	table.insert(self.Contents, "\t\t\t);\n")
	table.insert(self.Contents, "\t\t\tdefaultConfigurationIsVisible = 0;\n")
	--table.insert(self.Contents, "\t\t\tdefaultConfigurationName = \"" .. Config.Platforms[1] .. ' - ' .. Config.Configurations[1] .. "\";\n")
	table.insert(self.Contents, "\t\t};\n\n")

	XcodeHelper_WriteProjectXCConfigurationList(self, info)

	table.insert(self.Contents, "/* End XCConfigurationList section */\n\n")
end

local XcodeProjectMetaTable = {  __index = XcodeProjectMetaTable  }

function XcodeProjectMetaTable:Write(outputPath)
	local projectName = self.ProjectName
	local projectPath = ospath.join(outputPath, self.ProjectName .. '.xcodeproj')
	local filename = ospath.join(outputPath, projectPath, 'project.pbxproj')

	local info = XcodeHelper_GetProjectExportInfo(self.ProjectName)
	info.Filename = filename

	local project = Projects[self.ProjectName]

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

	--self:_AppendXcodeproj(workspace.ProjectTree)
	--workspace.ProjectTree.folder = self.Name .. '.workspace'
	--local workspaceTree = { workspace.ProjectTree }
	--XcodeHelper_AssignEntryUuids(info.EntryUuids, workspaceTree, '')
	project.SourcesTree.folder = project.Name
	local projectTree = { project.SourcesTree }
	XcodeHelper_AssignEntryUuids(info.EntryUuids, projectTree, '')
	info.GroupUuid = info.EntryUuids[project.Name .. '/']
	self.EntryUuids = info.EntryUuids

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
		XcodeHelper_WriteXCBuildConfigurations(self, info, curProject.Name)
		XcodeHelper_WriteXCConfigurationLists(self, info, curProject.Name)
	end

	table.insert(self.Contents, "\t};\n")
	table.insert(self.Contents, "\trootObject = " .. info.ProjectUuid .. " /* Project object */;\n")
	table.insert(self.Contents, "}\n")

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')
	WriteFileIfModified(filename, self.Contents)

	---------------------------------------------------------------------------
	-- Write the schemes
	---------------------------------------------------------------------------
	local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName)
	local subProject = Projects[projectName]

	for _, platformName in ipairs(Config.Platforms) do
		for _, configName in ipairs(Config.Configurations) do
			local configInfo = subProject.ConfigInfo[platformName][configName]
			local filename = ospath.join(projectPath, 'xcshareddata', 'xcschemes', projectName .. '-' .. platformName .. '-' .. configName .. '.xcscheme')
			local subProjectInfo = XcodeHelper_GetProjectExportInfo(projectName)

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
	return
	---------------------------------------------------------------------------
	-- Write username.pbxuser with the executable settings
	---------------------------------------------------------------------------
--[=========[]
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

	table.insert(self.Contents, expand([[
	$(ProjectUuid) /* Project object */ = {
		activeBuildConfigurationName = "$(activePlatform) - $(activeConfig)";
		activeExecutable = $(activeExecutable) /* $(Name) */;
		activeTarget = $(LegacyTargetUuid) /* $(Name) */;
		executables = (
]], extraData, info))

	for _, platformName in ipairs(Config.Platforms) do
		for configName in ivalues(Config.Configurations) do
			local configInfo = ConfigInfo[platformName][configName]
			local executableConfig = info.ExecutableInfo[platformName][configName]

			table.insert(self.Contents, '\t\t\t' .. executableConfig.Uuid .. ' /* ' .. platformName .. ' - ' .. configInfo.OutputName .. ' */,\n')
		end
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

	for _, platformName in ipairs(Config.Platforms) do
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
			extraData.OutputPath = configInfo.OutputPath

			local platformOutputName = platformName .. ' - ' .. configName .. ' - ' .. configInfo.OutputName
			extraData.PlatformOutputName = platformOutputName			

			if configInfo.OutputName ~= '' then
				table.insert(self.Contents, ("\t%s /* %s */ = {\n"):format(executableConfig.FileReferenceUuid, platformOutputName))
				table.insert(self.Contents, [[
		isa = PBXFileReference;
		lastKnownFileType = text;
]])
				table.insert(self.Contents, '\t\tname = "' .. platformOutputName .. '";\n')
				table.insert(self.Contents, '\t\tpath = "' .. configInfo.OutputPath .. configInfo.OutputName .. '";\n')
				table.insert(self.Contents, [[
		sourceTree = "<absolute>";
	};
]])

				table.insert(self.Contents, ("\t%s /* %s */ = {\n"):format(executableConfig.Uuid, platformOutputName))
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
		launchableReference = $(FileReferenceUuid) /* $(PlatformOutputName) */;
		libgmallocEnabled = 0;
		name = "$(PlatformOutputName)";
		sourceDirectories = (
		);
		startupPath = "$(OutputPath)";
	};
]], executableConfig, info, extraData))
			end
		end
	end

	table.insert(self.Contents, '}\n')

	self.Contents = table.concat(self.Contents):gsub('\r\n', '\n')

	WriteFileIfModified(filename, self.Contents)
--]=========]
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


function XcodeWorkspaceMetaTable:_AppendXcodeproj(folder)
	for index = 1, #folder do
		local entry = folder[index]
		if type(entry) == 'table' then
			self:_AppendXcodeproj(entry)
		else
			-- Build up the source tree list
			local info = XcodeHelper_GetProjectExportInfo(entry)
			local sourcesTree = Projects[entry].SourcesTree
			if sourcesTree then
				sourcesTree.folder = entry
				folder[index] = sourcesTree
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
	if true then return end
--[==[
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
--]==]
	contents[#contents + 1] = [[
</Workspace>
]]

	local filename = ospath.join(outputPath, self.Name .. '.workspace.xcodeproj/project.pbxproj')
	ospath.mkdir(filename)

	local workspaceName = self.Name .. '.workspace'

	for projectName, project in pairs(Projects) do
		project._insertedapp = nil
	end

	Projects[self.Name .. '.workspace'] = {}

	local info = XcodeHelper_GetProjectExportInfo(workspaceName)

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

	self:_AppendXcodeproj(workspace.ProjectTree)
	workspace.ProjectTree.folder = self.Name .. '.workspace'
	local workspaceTree = { workspace.ProjectTree }
	XcodeHelper_AssignEntryUuids(info.EntryUuids, workspaceTree, '')
	info.GroupUuid = info.EntryUuids[workspaceTree[1].folder .. '/']
	self.EntryUuids = info.EntryUuids

	-- Build all targets
	local allTargets = {}
	for projectName in ivalues(workspace.Projects) do
		local curProject = Projects[projectName]
		allTargets[#allTargets + 1] = curProject

		if false  and  projectName ~= buildWorkspaceName  and  projectName ~= updateWorkspaceName then
			local jamProject = deepcopy(curProject)
			jamProject.Name = '!clean:' .. jamProject.Name
			Projects[jamProject.Name] = jamProject
			jamProject.TargetName = 'clean:' .. curProject.Name
			jamProject.SourcesTree = nil
			jamProject.Options = nil
			jamProject.XcodeProjectType = 'legacy'
			allTargets[jamProject.Name] = true
			allTargets[#allTargets + 1] = jamProject
		end
	end

	table.sort(allTargets, function(left, right) return left.Name:lower() < right.Name:lower() end)

	-- Write PBXFileReferences.
	table.insert(self.Contents, [[
/* Begin PBXFileReference section */
]])
	XcodeHelper_WritePBXFileReferences(self, workspaceTree)
	table.insert(self.Contents, [[
/* End PBXFileReference section */

]])

	-- Write PBXGroups.
	table.insert(self.Contents, '/* Begin PBXGroup section */\n')
	XcodeHelper_WritePBXGroups(self.Contents, self.EntryUuids, workspaceTree, '')
	table.insert(self.Contents, '/* End PBXGroup section */\n\n')

	-- Write PBXLegacyTarget.
	XcodeHelper_WritePBXLegacyTarget(self, info, allTargets, projectsPath)

	-- Write PBXProject.
	XcodeHelper_WritePBXProject(self, info, allTargets)

	for curProject in ivalues(allTargets) do
		XcodeHelper_WriteXCBuildConfigurations(self, info, curProject.Name)
		XcodeHelper_WriteXCConfigurationLists(self, info, curProject.Name)
	end

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
	local chunk = loadfile(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'))
	if chunk then chunk() end
	if not ProjectExportInfo then
		ProjectExportInfo = {}
	end

	local xcodejamFilename = ospath.join(_getWorkspacePath(), 'xcodejam')
	ospath.write_file(xcodejamFilename, [[
#!/bin/sh
TARGET_NAME=
if [ "$4" = "" ]; then
	TARGET_NAME=$3
elif [ "$3" = build ]; then
	TARGET_NAME=$4
elif [ "$3" = clean ]; then
	TARGET_NAME=$4
fi
]] .. ospath.escape(ospath.join(destinationRootPath, 'jam')) .. [[ C.TOOLCHAIN=$1/$2 $TARGET_NAME
]])
	ospath.chmod(xcodejamFilename, 777)
end


function XcodeShutdown()
	prettydump.dumpascii(ospath.join(_getTargetInfoPath(), 'ProjectExportInfo.lua'), 'ProjectExportInfo', ProjectExportInfo)
end





-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
OS = os.getenv("OS")
OSPLAT = os.getenv("OSPLAT")
if not OS  or  not OSPLAT then
	print('*** JamToWorkspace must be called directly from Jam.')
	print('\njam --jamtoworkspace ...')
	os.exit(-1)
end

require 'getopt'
require 'ex'
require 'md5'
require 'uuid'
expand = require 'expand'

scriptPath = os.path.simplify(os.path.make_absolute(((debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. '\\'):gsub('\\', '/'):lower()))
package.path = scriptPath .. "?.lua;" .. package.path
require 'FolderTree'

jamPath = os.path.simplify(os.path.make_absolute(scriptPath .. '../'))

jamExePathNoQuotes = os.path.combine(jamPath, OS:lower() .. OSPLAT:lower(), 'jam')
jamExePath = os.path.escape(jamExePathNoQuotes)

Compilers =
{
	{ 'vs2010', 'Visual Studio 2010' },
	{ 'vs2008', 'Visual Studio 2008' },
	{ 'vs2005', 'Visual Studio 2005' },
	{ 'vs2003', 'Visual Studio 2003' },
	{ 'vc6',	'Visual C++ 6' },
	{ 'mingw',	'MinGW' },
	{ 'gcc',	'gcc' },
}

Config = {}

if OS == "NT" then
	uname = 'windows'
else
	local f = io.popen('uname')
	uname = f:read('*a'):lower():gsub('\n', '')
	f:close()
end

buildWorkspaceName = '!BuildWorkspace'
updateWorkspaceName = '!UpdateWorkspace'

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
		Option {{"gui"}, "Pop up a GUI to set options"},
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

function ReadTargetInfo(outPath, platform, config)
	local targetInfoFilename = outPath .. '_targetinfo_/targetinfo.' ..
			(platform == '*' and '!all!' or platform) .. '.' ..
			(config == '*' and '!all!' or config) .. '.lua'
	local chunk, message = loadfile(targetInfoFilename)
	if not chunk then
		error('* Error parsing ' .. targetInfoFilename .. '.\n\n' .. message)
	end
	chunk()
end

function CreateTargetInfoFiles(outPath)
	function DumpConfig(platform, config)
		local collectConfigurationArgs =
		{
			jamExePath,
			os.path.escape('-C' .. destinationRootPath),
			os.path.escape('-sJAMFILE_ROOT=' .. sourceRootPath),
			os.path.escape('-sJAMFILE=' .. outPath .. 'DumpJamTargetInfo.jam'),
			os.path.escape('-sTARGETINFO_LOCATE=' .. outPath .. '_targetinfo_/'),
			'-sPLATFORM=' .. platform,
			'-sCONFIG=' .. config,
			'-d0',
			'-S'
		}

		print('Reading platform [' .. platform .. '] and config [' .. config .. ']...')
--		print(table.concat(collectConfigurationArgs, ' '))
		for line in ex.lines(collectConfigurationArgs) do
			print(line)
		end
--		print(p, i, o)
	end

	DumpConfig('*', '*')
	ReadTargetInfo(outPath, '*', '*')

	if not Config.Platforms then
		Config.Platforms = VALID_PLATFORMS
	end

	local workspacePlatforms = {}
	for _, platform in ipairs(list.concat(Config.Platforms, Config.WorkspacePlatforms)) do
		if not workspacePlatforms[platform] then
			workspacePlatforms[platform] = true
			workspacePlatforms[#workspacePlatforms + 1] = platform
		end
	end

	if not Config.Configurations then
		Config.Configurations = VALID_CONFIGS
	end

	local workspaceConfigurations = {}
	for _, config in ipairs(list.concat(Config.Configurations, Config.WorkspaceConfigurations)) do
		if not workspaceConfigurations[config] then
			workspaceConfigurations[config] = true
			workspaceConfigurations[#workspaceConfigurations + 1] = config
		end
	end

	for platformName in ivalues(workspacePlatforms) do
		DumpConfig(platformName, '*')
		for configName in ivalues(workspaceConfigurations) do
			DumpConfig(platformName, configName)
		end
	end
end

function ReadTargetInfoFiles(outPath)
	for platformName in ivalues(Config.Platforms) do
		ReadTargetInfo(outPath, platformName, '*')
		for configName in ivalues(Config.Configurations) do
			ReadTargetInfo(outPath, platformName, configName)
		end
	end

	AutoWriteMetaTable.active = false
end


-- Ugly, but suitable for now until the autodetection process is in place.
require 'ide/none'
require 'ide/vc6'
require 'ide/vs2003'
require 'ide/vs2005'
require 'ide/vs2008'
require 'ide/vs2010'
require 'ide/codeblocks'
require 'ide/xcode'

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
	local newSources = {}
	for _, source in ipairs(project.Sources) do
		local lowerSource = source:lower()
		if not sourcesMap[lowerSource] then
			newSources[#newSources + 1] = source
			sourcesMap[lowerSource] = source
		end
	end
	project.Sources = newSources

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
	local outPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_', project.RelativePath) .. '/'
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
	local outPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'

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
			outPath .. 'updateworkspace.bat',
			outPath .. 'updateworkspace.bat',
		}
	else
		updateWorkspaceCommandLines =
		{
			outPath .. 'updateworkspace',
			outPath .. 'updateworkspace',
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
	print('Creating build environment...')
	os.mkdir(destinationRootPath)

	local exporter = Exporters[opts.gen]
	exporter.Options.compiler = opts.compiler or opts.gen

	locateTargetText =
	{
		locateTargetText = [[
ALL_LOCATE_TARGET = $(destinationRootPath:gsub('\\', '/'))$$(PLATFORM)-$$(CONFIG) ;
]]
	}

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
	function WriteJambase()
		local jambaseText = { '# Generated file\n' }

		if VALID_PLATFORMS then
			jambaseText[#jambaseText + 1] = "VALID_PLATFORMS ="
			for platform in ivalues(VALID_PLATFORMS) do
				jambaseText[#jambaseText + 1] = ' "' .. platform .. '"'
			end
			jambaseText[#jambaseText + 1] = ' ;\n'
		elseif Config.Platforms then
			jambaseText[#jambaseText + 1] = "VALID_PLATFORMS ="
			for platform in ivalues(Config.Platforms) do
				jambaseText[#jambaseText + 1] = ' "' .. platform .. '"'
			end
			jambaseText[#jambaseText + 1] = ' ;\n'
		end

		if VALID_CONFIGS then
			jambaseText[#jambaseText + 1] = "VALID_CONFIGS ="
			for config in ivalues(VALID_CONFIGS) do
				jambaseText[#jambaseText + 1] = ' "' .. config .. '"'
			end
			jambaseText[#jambaseText + 1] = ' ;\n'
		elseif Config.Configurations then
			jambaseText[#jambaseText + 1] = "VALID_CONFIGS ="
			for config in ivalues(Config.Configurations) do
				jambaseText[#jambaseText + 1] = ' "' .. config .. '"'
			end
			jambaseText[#jambaseText + 1] = ' ;\n'
		end

		jambaseText[#jambaseText + 1] = "JAM_MODULES_USER_PATH += \"" .. sourceRootPath .. "\" ;\n"

		-- Write the Jambase variables out.
		if Config.JambaseVariables then
			for _, variable in ipairs(Config.JambaseVariables) do
				jambaseText[#jambaseText + 1] = variable[1] .. ' = "' .. expand(tostring(variable[2])) .. '" ;\n'
			end
			jambaseText[#jambaseText + 1] = '\n'
		end

		for _, info in ipairs(Config.JamFlags) do
			jambaseText[#jambaseText + 1] = expand(info.Key .. ' = ' .. info.Value .. ' ;\n', exporter.Options, _G)
		end
		jambaseText[#jambaseText + 1] = expand([[

include $(jamPath)Jambase.jam ;
]], exporter.Options, _G)
		io.writeall(destinationRootPath .. 'Jambase.jam', table.concat(jambaseText))
	end

	WriteJambase()

	local jamScript
	if uname == 'windows' then
		-- Write jam.bat.
		jamScript = os.path.combine(destinationRootPath, 'jam.bat')
		io.writeall(jamScript,
			'@' .. jamExePath .. ' ' .. os.path.escape("-C" .. destinationRootPath) .. ' %*\n')

		-- Write updatebuildenvironment.bat.
		io.writeall(os.path.combine(destinationRootPath, 'updatebuildenvironment.bat'),
				("@%s --workspace --config=%s %s %s\n"):format(
				os.path.escape(jamScript),
				os.path.escape(destinationRootPath .. '/buildenvironment.config'),
				os.path.escape(sourceJamfilePath),
				os.path.escape(destinationRootPath)))
	else
		-- Write jam shell script.
		jamScript = os.path.combine(destinationRootPath, 'jam')
		io.writeall(jamScript,
				'#!/bin/sh\n' ..
				jamExePath .. ' ' .. os.path.escape("-C" .. destinationRootPath) .. ' $*\n')
		os.chmod(jamScript, 777)

		-- Write updatebuildenvironment.sh.
		local updatebuildenvironment = os.path.combine(destinationRootPath, 'updatebuildenvironment')
		io.writeall(updatebuildenvironment,
				("#!/bin/sh\n%s --workspace --config=%s %s %s\n"):format(
				os.path.escape(jamScript),
				os.path.escape(destinationRootPath .. '/buildenvironment.config'),
				os.path.escape(sourceJamfilePath),
				os.path.escape(destinationRootPath)))
		os.chmod(updatebuildenvironment, 777)
	end

	-- Write buildenvironment.config.
	LuaDumpObject(destinationRootPath .. 'buildenvironment.config', 'Config', Config)

	if opts.gen ~= 'none' then
		local outPath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'
		os.mkdir(outPath)

		---------------------------------------------------------------------------
		-- Write the generated DumpJamTargetInfo.jam.
		---------------------------------------------------------------------------
		io.writeall(outPath .. 'DumpJamTargetInfo.jam', expand([[
$(locateTargetText)
__JAM_SCRIPTS_PATH = "$(scriptPath)" ;
include $(scriptPath)ide/$(gen).jam ;
include $(scriptPath)DumpJamTargetInfo.jam ;
]], locateTargetText, opts, _G))

		-- Read the target information.
		CreateTargetInfoFiles(outPath)
		VALID_PLATFORMS = Config.Platforms
		VALID_CONFIGS = Config.Configurations
		WriteJambase()			-- Write it out with the new VALID_PLATFORMS and VALID_CONFIGS variables.
		ReadTargetInfoFiles(outPath)

		print('Writing generated projects...')

		if uname == 'windows' then
			-- Write updateworkspace.bat.
			io.writeall(outPath .. 'updateworkspace.bat',
					("@%s --workspace --gen=%s --config=%s %s %s\n"):format(
					os.path.escape(jamScript), opts.gen,
					os.path.escape(destinationRootPath .. '/buildenvironment.config'),
					os.path.escape(sourceJamfilePath),
					os.path.escape(destinationRootPath)))
		else
			-- Write updateworkspace.sh.
			io.writeall(outPath .. 'updateworkspace',
					("#!/bin/sh\n%s --workspace --gen=%s --config=%s %s %s\n"):format(
					os.path.escape(jamScript), opts.gen,
					os.path.escape(destinationRootPath .. '/buildenvironment.config'),
					os.path.escape(sourceJamfilePath),
					os.path.escape(destinationRootPath)))
			os.chmod(outPath .. 'updateworkspace', 777)
		end

		-- Export everything.
		exporter.Initialize()

		-- Iterate all the workspaces.
		local outWorkspacePath = os.path.combine(destinationRootPath, '_workspace.' .. opts.gen .. '_') .. '/'
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
				workspaceExporter:Write(outWorkspacePath)
			end
		end

		exporter.Shutdown()

		if opts.gui then
			if OS == "NT" then
				os.execute('explorer "' .. os.path.make_backslash(outWorkspacePath) .. '"')
			end
		end
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

-------------------------------------------------------------------------------
--
-------------------------------------------------------------------------------
OS = os.getenv("OS")
OSPLAT = os.getenv("OSPLAT")
JAM_EXECUTABLE = os.getenv("JAM_EXECUTABLE")
if not OS  or  not OSPLAT  or  not JAM_EXECUTABLE then
	print('*** JamToWorkspace must be called directly from Jam.')
	print('\nUsage: jam --workspace ...')
	os.exit(-1)
end

local getopt = require 'getopt'
ospath = require 'ospath'
osprocess = require 'osprocess'
prettydump = require 'prettydump'
local md5 = require 'md5'
expand = require 'expand'

scriptPath = ospath.simplify(ospath.make_absolute(((debug.getinfo(1, "S").source:match("@(.+)[\\/]") or '.') .. '\\'):gsub('\\', '/')))
package.path = scriptPath .. "?.lua;" .. package.path
FolderTree = require 'FolderTree'

jamPath = ospath.simplify(ospath.make_absolute(scriptPath .. '../'))

Compilers =
{
	{ 'vs2015', 'Visual Studio 2015' },
	{ 'vs2013', 'Visual Studio 2013' },
	{ 'vs2012', 'Visual Studio 2012' },
	{ 'vs2010', 'Visual Studio 2010' },
	{ 'vs2008', 'Visual Studio 2008' },
	{ 'vs2005', 'Visual Studio 2005' },
	{ 'vs2003', 'Visual Studio 2003' },
	{ 'vc6',	'Visual C++ 6' },
	{ 'mingw',	'MinGW' },
	{ 'clang',	'Clang' },
	{ 'gcc',	'GCC' },
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

function list_concat (...)
	local r = {}
	for _, l in ipairs ({...}) do
		for _, v in ipairs (l) do
			table.insert (r, v)
		end
	end
	return r
end

function list_find(searchList, value)
	for index = 1, #searchList do
		if searchList[index] == value then
			return index
		end
	end
end

--- Merge one table into another. <code>u</code> is merged into <code>t</code>.
-- @param t first table
-- @param u second table
-- @return first table
function table_merge (t, u)
  for i, v in pairs (u) do
    t[i] = v
  end
  return t
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
	local md5Contents = md5.digest(contents)
	local writeFile = not ospath.exists(filename)
	if not writeFile then
		local md5File = io.open(filename .. '.md5', 'rb')
		if md5File then
			local md5FileDigest = md5File:read(32)
			md5File:close()
			writeFile = md5Contents ~= md5FileDigest
		else
			writeFile = true
		end
	end
	if writeFile then
		ospath.mkdir(filename)
		ospath.write_file(filename, contents)
		ospath.write_file(filename .. '.md5', md5Contents)
	end
end


function ProcessCommandLine()
	JambaseFlags = { }

	function ProcessJambaseFlags(newarg, oldarg)
		local key, value = newarg:match('(.+)=(.+)')
		if not key then
			errors = { 'Invalid --jambaseflags ' .. newarg .. '.  Must be in KEY=VALUE form.' }
			Usage()
		end
		JambaseFlags[#JambaseFlags + 1] = { Key = key, Value = value }
	end

	JamfileFlags = { }

	function ProcessJamfileFlags(newarg, oldarg)
		local key, value = newarg:match('(.+)=(.+)')
		if not key then
			errors = { 'Invalid --jamfileflags ' .. newarg .. '.  Must be in KEY=VALUE form.' }
			Usage()
		end
		JamfileFlags[#JamfileFlags + 1] = { Key = key, Value = value }
	end

	local options = getopt.makeOptions{
		getopt.Option {{"help"}, "Show this help listing"},
		getopt.Option {{"gen"}, "Set a project generator", "Req", 'GENERATOR'},
		getopt.Option {{"gui"}, "Pop up a GUI to set options"},
		getopt.Option {{"platform"}, "Set the default platform used to build with", "Req", 'PLATFORM'},
		getopt.Option {{"config"}, "Filename of additional configuration file", "Req", 'CONFIG'},
		getopt.Option {{"compiler"}, "Set the default compiler used to build with", "Req", 'COMPILER'},
		getopt.Option {{"jambaseflags"}, "Extra flags to make available for each invocation of Jam.  Specify in KEY=VALUE form.", "Req", 'JAMBASE_FLAGS', ProcessJambaseFlags },
		getopt.Option {{"jamfileflags"}, "Extra flags to make available for each invocation of Jam.  Specify in KEY=VALUE form.", "Req", 'JAMFILE_FLAGS', ProcessJamfileFlags },
		getopt.Option {{"jamexepath"}, "The full path to the Jam executable when the default location won't suffice.", "Req", 'JAMEXEPATH' },
		getopt.Option {{"jambase"}, "The full path to the Jambase.jam", "Req", 'JAMBASEFULLPATH' },
	}

	function Usage()
		print (table.concat (errors, "\n") .. "\n" ..
				getopt.usageInfo ("Usage: jam --workspace [options] [[<source-jamfile>] <path-to-destination>]",
				options))

		local sortedExporters = {}
		for exporterName in pairs(Exporters) do
			sortedExporters[#sortedExporters + 1] = exporterName
		end
		table.sort(sortedExporters)

		local genOptions = {}
		for exporterName in ivalues(sortedExporters) do
			genOptions[#genOptions + 1] =
				getopt.Option{ { exporterName }, Exporters[exporterName].Description }
		end

		print(getopt.usageInfo("\nAvailable workspace generators:", getopt.makeOptions(genOptions)))

		local compilerOptions = {}
		for compilerInfo in ivalues(Compilers) do
			compilerOptions[#compilerOptions + 1] =
				getopt.Option{ { compilerInfo[1] }, compilerInfo[2] }
		end

		print(getopt.usageInfo("\nAvailable compilers:", getopt.makeOptions(compilerOptions)))

		os.exit(-1)
	end

	nonOpts, opts, errors = getopt.getOpt (arg, options)

	opts.gen = opts.gen or { DefaultExporter }
	local ides = {}
	local usedIdes = {}
	for _, str in ipairs(opts.gen) do
		for ide in str:gmatch('([^,]+)') do
			if not usedIdes[ide] then
				if not Exporters[ide] then
					Usage()
				end
				ides[#ides + 1] = ide
				usedIdes[ide] = true
			end
		end
	end
	table.sort(ides)
	opts.gen = ides

	opts.compiler = opts.compiler and opts.compiler[#opts.compiler]
	opts.config = opts.config and opts.config[#opts.config]
	opts.jambaseflags = opts.jambaseflags and opts.jambaseflags[#opts.jambaseflags]
	if opts.jambaseflags then
		ProcessJambaseFlags(opts.jambaseflags)
	end
	opts.jamfileflags = opts.jamfileflags and opts.jamfileflags[#opts.jamfileflags]
	if opts.jamfileflags then
		ProcessJamfileFlags(opts.jamfileflags)
	end
	opts.jamexepath = opts.jamexepath and opts.jamexepath[#opts.jamexepath]
	opts.jambase = opts.jambase and opts.jambase[#opts.jambase]

	if nonOpts[1] == nil then
		nonOpts = { 'Jamfile.jam', '.build' }
	elseif nonOpts[2] == nil then
		nonOpts[#nonOpts + 1] = '.build'
	end

	if #errors > 0  or  opts.help  or  (#nonOpts ~= 1  and  #nonOpts ~= 2) then
		Usage()
	end
end

function _getTargetInfoPath()
	return ospath.join(_getWorkspacePath(), '_targetinfo_')
end

function _getTargetInfoFilename(platform, config)
	return ospath.join(_getTargetInfoPath(), 'targetinfo.' ..
			(platform == '*' and '_all_' or platform) .. '.' ..
			(config == '*' and '_all_' or config) .. '.lua')
end

function _getWorkspacesPath()
	return ospath.join(destinationRootPath, '_workspaces_')
end

function _getWorkspacePath()
	return ospath.join(_getWorkspacesPath(), ide)
end

function _getWorkspaceProjectsPath()
	return ospath.join(_getWorkspacePath(), '_projects_')
end

function ReadTargetInfo(platform, config)
	local targetInfoFilename = _getTargetInfoFilename(platform, config)
	if ospath.exists(targetInfoFilename) then
		local chunk, message = loadfile(targetInfoFilename)
		if not chunk then
			error('* Error parsing ' .. targetInfoFilename .. '.\n\n' .. message)
		end
		chunk()
	else
		print('* Unable to find ' .. targetInfoFilename .. '.')
	end
end

function CreateTargetInfoFiles(outPath)
	function DumpConfig(platform, config)
		local targetInfoFilename = _getTargetInfoFilename(platform, config)
		ospath.remove(targetInfoFilename)

		local collectConfigurationArgs =
		{
			jamExePath,
			ospath.escape('-C' .. destinationRootPath),
			ospath.escape('JAMFILE_ROOT=' .. sourceRootPath),
			ospath.escape('JAMFILE=' .. ospath.join(_getTargetInfoPath(), 'DumpJamTargetInfo.jam')),
			ospath.escape('TARGETINFO_LOCATE=' .. ospath.add_slash(_getTargetInfoPath())),
			'C.TOOLCHAIN=' .. platform .. '/' .. config,
			'-d0',
			'-S'
		}

		print('    Parsing toolchain ' .. platform .. '/' .. config .. '...')
		--print(table.concat(collectConfigurationArgs, ' '))
		for line in osprocess.lines(collectConfigurationArgs) do
			print(line)
		end
--		print(p, i, o)
	end

	Workspaces = nil
	Projects = nil
	AutoWriteMetaTable = nil

	DumpConfig('*', '*')
	ReadTargetInfo('*', '*')

	if not Config.Platforms then
		if opts.platform then
			Config.Platforms = opts.platform
		else
			Config.Platforms = VALID_PLATFORMS
		end
	end

	local workspacePlatforms = {}
	for _, platform in ipairs(list_concat(Config.Platforms, Config.WorkspacePlatforms)) do
		if not workspacePlatforms[platform] then
			workspacePlatforms[platform] = true
			workspacePlatforms[#workspacePlatforms + 1] = platform
		end
	end

	if not Config.Configurations then
		Config.Configurations = VALID_CONFIGS
	end

	local workspaceConfigurations = {}
	for _, config in ipairs(list_concat(Config.Configurations, Config.WorkspaceConfigurations)) do
		if not workspaceConfigurations[config] then
			workspaceConfigurations[config] = true
			workspaceConfigurations[#workspaceConfigurations + 1] = config
		end
	end

--	for configName in ivalues(workspaceConfigurations) do
--		DumpConfig('*', configName)
--	end

	for platformName in ivalues(workspacePlatforms) do
--		DumpConfig(platformName, '*')
		for configName in ivalues(workspaceConfigurations) do
			DumpConfig(platformName, configName)
		end
	end
end

function ReadTargetInfoFiles()
	for platformName in ivalues(Config.Platforms) do
--		ReadTargetInfo(platformName, '*')
		for configName in ivalues(Config.Configurations) do
			ReadTargetInfo(platformName, configName)
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
require 'ide/vs2012'
require 'ide/vs2013'
require 'ide/vs2015'
require 'ide/codeblocks'
require 'ide/xcode'

if uname == 'windows' then
	DefaultExporter = 'vs2015'
elseif uname == 'darwin' then
	DefaultExporter = 'xcode'
else
	DefaultExporter = 'none'
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

	vs2012 =
	{
		Initialize = VisualStudio201xInitialize,
		ProjectExporter = VisualStudio201xProject,
		WorkspaceExporter = VisualStudio201xSolution,
		Shutdown = VisualStudio201xShutdown,
		Description = 'Generate Visual Studio 2012 solutions and projects.',
		Options =
		{
			vs2012 = true,
		}
	},

	vs2013 =
	{
		Initialize = VisualStudio201xInitialize,
		ProjectExporter = VisualStudio201xProject,
		WorkspaceExporter = VisualStudio201xSolution,
		Shutdown = VisualStudio201xShutdown,
		Description = 'Generate Visual Studio 2013 solutions and projects.',
		Options =
		{
			vs2013 = true,
		}
	},

	vs2015 =
	{
		Initialize = VisualStudio201xInitialize,
		ProjectExporter = VisualStudio201xProject,
		WorkspaceExporter = VisualStudio201xSolution,
		Shutdown = VisualStudio201xShutdown,
		Description = 'Generate Visual Studio 2015 solutions and projects.',
		Options =
		{
			vs2015 = true,
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
	if project.Sources then
		for _, source in ipairs(project.Sources) do
			local lowerSource = source:lower()
			if not sourcesMap[lowerSource] then
				newSources[#newSources + 1] = source
				sourcesMap[lowerSource] = source
			end
		end
	end
	project.Sources = newSources

	-- Add Jamfile.jam.
	if project.Jamfile then
		sourcesMap[project.Jamfile:lower()] = project.Jamfile
	end

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


function DumpProject(project, workspace)
	local outPath = ospath.join(_getWorkspaceProjectsPath(), project.RelativePath)
	ospath.mkdir(ospath.add_slash(outPath))

	local exporter = Exporters[ide]
	local projectExporter = exporter.ProjectExporter(project.Name, exporter.Options, workspace)
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
	local outPath = _getWorkspacePath()
	local projectsOutPath = _getWorkspaceProjectsPath()

	-- Write the !BuildWorkspace project
	local exporter = Exporters[ide]
	Projects[buildWorkspaceName] = {}
	Projects[buildWorkspaceName].Sources =
	{
		mainJambase,
	}
	Projects[buildWorkspaceName].SourcesTree = Projects[buildWorkspaceName].Sources
	Projects[buildWorkspaceName].Name = buildWorkspaceName
	Projects[buildWorkspaceName].TargetName = ''
	local projectExporter = exporter.ProjectExporter(buildWorkspaceName, exporter.Options, workspace)
	projectExporter:Write(projectsOutPath)

	-- Write the !UpdateWorkspace project
	Projects[updateWorkspaceName] = {}
	Projects[updateWorkspaceName].Sources =
	{
		mainJambase,
		ospath.join(destinationRootPath, 'customsettings.jam'),
	}
	Projects[updateWorkspaceName].SourcesTree = Projects[updateWorkspaceName].Sources
	Projects[updateWorkspaceName].Name = updateWorkspaceName
	local projectExporter = exporter.ProjectExporter(updateWorkspaceName, exporter.Options, workspace)

	local updateWorkspaceCommandLines
	if uname == 'windows' then
		updateWorkspaceCommandLines =
		{
			ospath.make_backslash( '"' .. ospath.join(_getWorkspacesPath(), 'updateworkspaces.bat') .. '"' ),
			ospath.make_backslash( '"' .. ospath.join(_getWorkspacesPath(), 'updateworkspaces.bat') .. '"' ),
			ospath.make_backslash( '"' .. ospath.join(_getWorkspacesPath(), 'updateworkspaces.bat') .. '"' ),
		}
	else
		updateWorkspaceCommandLines =
		{
			ospath.join(_getWorkspacesPath(), 'updateworkspaces'),
			ospath.join(_getWorkspacesPath(), 'updateworkspaces'),
			ospath.join(_getWorkspacesPath(), 'updateworkspaces'),
		}
	end

	Projects[updateWorkspaceName].BuildCommandLine = { updateWorkspaceCommandLines[1] }
	Projects[updateWorkspaceName].RebuildCommandLine = { updateWorkspaceCommandLines[2] }
	Projects[updateWorkspaceName].CleanCommandLine = { updateWorkspaceCommandLines[3] }
	projectExporter:Write(projectsOutPath)

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
			BuildSourceTree(project)
		end
	end

	for projectName in ivalues(workspace.Projects) do
		local project = Projects[projectName]
		if project and project.RelativePath then
			DumpProject(project, workspace)
		else
			print('* Attempting to write unknown project [' .. projectName .. '].')
		end
	end

	workspace.Projects[#workspace.Projects + 1] = buildWorkspaceName
	workspace.Projects[#workspace.Projects + 1] = updateWorkspaceName
end


---------------------------------------------------------------------------
-- Write the generated Jambase.jam.
---------------------------------------------------------------------------
function WriteJambase(exporter)
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

	if opts.compiler or Config.Compiler then
		Config.Compiler = Config.Compiler or opts.compiler
		jambaseText[#jambaseText + 1] = "C.COMPILER ?= \"" .. Config.Compiler .. "\" ;\n"
	end

	local variablesTable = {
		sourceRootPath = sourceRootPath,
		destinationRootPath = destinationRootPath,
	}

	-- Write the Jambase variables out.
	if type(Config.JambaseVariables) == 'table' then
		for _, variable in ipairs(Config.JambaseVariables) do
			GetUserInput(variable)
			jambaseText[#jambaseText + 1] = variable[1] .. ' = "' .. expand(tostring(variable[2]), userVariables, variablesTable) .. '" ;\n'
		end
		jambaseText[#jambaseText + 1] = '\n'
	end

	if type(Config.JambaseText) == 'string' then
		jambaseText[#jambaseText + 1] = '{\n'
		for key, value in pairs(variablesTable) do
			jambaseText[#jambaseText + 1] = '\tlocal ' .. key .. ' = "' .. value .. '" ;\n'
		end
		jambaseText[#jambaseText + 1] = Config.JambaseText
		jambaseText[#jambaseText + 1] = '\n}\n'
	end

	for _, info in ipairs(Config.JambaseFlags) do
		jambaseText[#jambaseText + 1] = expand(info.Key .. ' = "' .. info.Value .. '" ;\n', exporter.Options, _G)
	end

	-- Write the Jambase variables out.
	if type(Config.JamModulesUserPath) == 'table' then
		for _, path in ipairs(Config.JamModulesUserPath) do
			jambaseText[#jambaseText + 1] = 'JAM_MODULES_USER_PATH += "' .. expand(path, userVariables, variablesTable) .. '" ;\n'
		end
	elseif type(Config.JamModulesUserPath) == 'string' then
		jambaseText[#jambaseText + 1] = 'JAM_MODULES_USER_PATH += "' .. expand(Config.JamModulesUserPath, userVariables, variablesTable) .. '" ;\n'
	end

	jambaseText[#jambaseText + 1] = "JAM_MODULES_USER_PATH += \"" .. sourceRootPath .. "\" ;\n"
	jambaseText[#jambaseText + 1] = "JAM_MODULES_USER_PATH += \"" .. sourceRootPath .. "jam\" ;\n"

	jambaseText[#jambaseText + 1] = expand([[

include "$(mainJambase)" ;
]], exporter.Options, _G)
	ospath.write_file(ospath.join(destinationRootPath, 'Jambase.jam'), table.concat(jambaseText))
end


function GetUserInput(variable)
    if type(variable[2]) == 'table' then
        local values = {}
        for _, nonExpandedValue in ipairs(variable[2]) do
            values[#values + 1] = expand(tostring(nonExpandedValue), expandTable, _G)
        end

        local userChoice
        while true do
            io.write('Choose setting for ' .. variable[1] .. ':\n')
            for index, value in ipairs(values) do
                io.write('    ' .. index .. ') ' .. value .. '\n')
            end
            io.write('Your choice? ');  io.stdout:flush()
            userChoice = tonumber(io.read('*l'))
            if userChoice >= 1  and  userChoice <= #values then
                break
            end

            io.write('Invalid choice.  Try again.\n\n')
        end

        variable[2] = values[userChoice]
    end
end


function BuildWorkspace(exporter, ide)
	if ide ~= 'none' then
		local outPath = _getWorkspacePath()
		ospath.mkdir(ospath.add_slash(outPath))

		---------------------------------------------------------------------------
		-- Write the generated DumpJamTargetInfo.jam.
		---------------------------------------------------------------------------
		local dumpJamTargetInfoFilename = ospath.join(_getTargetInfoPath(), 'DumpJamTargetInfo.jam')
		ospath.mkdir(dumpJamTargetInfoFilename)
		ospath.write_file(dumpJamTargetInfoFilename, expand([[
$(locateTargetText)
__JAM_SCRIPTS_PATH = "$(scriptPath)" ;
include "$(scriptPath)ide/]] .. ide .. [[.jam" ;
include "$(scriptPath)DumpJamTargetInfo.jam" ;
]], locateTargetText, opts, _G))

		-- Read the target information.
		CreateTargetInfoFiles(outPath)
		VALID_PLATFORMS = Config.Platforms
		VALID_CONFIGS = Config.Configurations
		WriteJambase(exporter)			-- Write it out with the new VALID_PLATFORMS and VALID_CONFIGS variables.
		ReadTargetInfoFiles()

		-- Export everything.
		exporter.Initialize()

		-- Iterate all the workspaces.
		local outWorkspacePath = _getWorkspacePath()
		for _, workspace in pairs(Workspaces) do
			if workspace.Export == nil  or  workspace.Export == true then
				-- Rid ourselves of duplicates.
				local usedProjects = {}
				if workspace.Projects then
					local index = 1
					while index <= #workspace.Projects do
						local projectName = workspace.Projects[index]
						if usedProjects[projectName] then
							table.remove(workspace.Projects, index)
						else
							usedProjects[projectName] = true
							index = index + 1
						end
					end
				end

				-- Add any of the listed projects' libraries.
				if workspace.Projects then
					for index = 1, #workspace.Projects do
						local projectName = workspace.Projects[index]
						local project = Projects[projectName]
						if not project then
							print('* Project [' .. projectName .. '] is in workspace [' .. workspace.Name .. '] but not defined.')
						else
							for projectName in ivalues(project.Libraries) do
								if Projects[projectName]  and  not usedProjects[projectName] then
									workspace.Projects[#workspace.Projects + 1] = projectName
									usedProjects[projectName] = true
								end
							end
							if Projects['C.*'] then
								for projectName in ivalues(Projects['C.*'].Libraries) do
									if Projects[projectName]  and  not usedProjects[projectName] then
										workspace.Projects[#workspace.Projects + 1] = projectName
										usedProjects[projectName] = true
									end
								end
							end
						end
					end

					DumpWorkspace(workspace)

					local workspaceExporter = exporter.WorkspaceExporter(workspace.Name, exporter.Options)
					workspaceExporter:Write(outWorkspacePath)
				end
			end
		end

		exporter.Shutdown()
	end
end


function BuildWorkspaces()
	-- Fill in User Variables
	local userVariables = {}
	if type(Config.UserVariables) == 'table' then
		for _, variable in ipairs(Config.UserVariables) do
		    GetUserInput(variable)
		end
	end

	print('Creating build environment...')
	ospath.mkdir(destinationRootPath)

	opts.compiler = opts.compiler  or  ide

	locateTargetText =
	{
		locateTargetText = [[
ALL_LOCATE_TARGET = "$(destinationRootPath)$$(C.PLATFORM)/_intermediates_" ;
]],
		settingsFile = ospath.join(destinationRootPath, 'customsettings.jam'),
	}

	---------------------------------------------------------------------------
	-- Write the generated Jamfile.jam.
	---------------------------------------------------------------------------
	local jamfileText = { expand([[
# Generated file
$(locateTargetText)
DEPCACHE.standard = "$$(ALL_LOCATE_TARGET)/$$(C.PLATFORM)-$$(C.CONFIG)/.depcache" ;
DEPCACHE = standard ;

CUSTOMSETTINGS ?= "$(settingsFile)" ;
NoCare $$(CUSTOMSETTINGS) ;
include $$(CUSTOMSETTINGS) ;

]], locateTargetText, _G) }

	---------------------------------------------------------------------------
	-- Write the customsettings.jam.
	---------------------------------------------------------------------------
	if not ospath.exists(locateTargetText.settingsFile) then
		ospath.write_file(locateTargetText.settingsFile, [[
# This file is included before any other Jamfiles.
#
# Enter your own settings here.
]])
	end
	
	-- Write the Jamfile variables out.
	if Config.JamfileVariables then
		for _, variable in ipairs(Config.JamfileVariables) do
		    GetUserInput(variable)
            jamfileText[#jamfileText + 1] = variable[1] .. ' = "' .. expand(tostring(variable[2]), userVariables, _G) .. '" ;\n'
        end
		jamfileText[#jamfileText + 1] = '\n'
	end

	for _, info in ipairs(Config.JamfileFlags) do
		jamfileText[#jamfileText + 1] = expand(info.Key .. ' = "' .. info.Value .. '" ;\n', exporter.Options, userVariables, _G)
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
			jamfileText[#jamfileText + 1] = expand('if [ RuleExists SubInclude ] { SubInclude $(rootNameText) : $(sourceJamfileText) ; } else { include $$($(rootNameText))$(sourceJamfileText) ; }\n', expandTable, _G)
		end
	end

	ospath.write_file(ospath.join(destinationRootPath, 'Jamfile.jam'), table.concat(jamfileText))

	if uname == 'windows' then
		-- Write jam.bat.
		jamScript = ospath.make_backslash(ospath.join(destinationRootPath, 'jam.bat'))
		ospath.write_file(jamScript,
			'@' .. (opts.jamexepath or jamExePath) .. ' ' .. ospath.escape("-C" .. destinationRootPath) .. ' %*\n')

		-- Write updatebuildenvironment.bat.
		ospath.write_file(ospath.join(destinationRootPath, 'updatebuildenvironment.bat'),
				("@%s --workspace --config=%s %s %s\n"):format(
				ospath.escape(jamScript),
				ospath.escape(ospath.join(destinationRootPath, 'buildenvironment.config')),
				ospath.escape(sourceJamfilePath),
				ospath.escape(destinationRootPath)))
	else
		-- Write jam shell script.
		jamScript = ospath.join(destinationRootPath, 'jam')
		ospath.write_file(jamScript,
				'#!/bin/sh\n' ..
				(opts.jamexepath or jamExePath) .. ' ' .. ospath.escape("-C" .. destinationRootPath) .. ' $*\n')
		ospath.chmod(jamScript, 777)

		-- Write updatebuildenvironment.sh.
		local updatebuildenvironment = ospath.join(destinationRootPath, 'updatebuildenvironment')
		ospath.write_file(updatebuildenvironment,
				("#!/bin/sh\n%s --workspace --config=%s %s %s\n"):format(
				ospath.escape(jamScript),
				ospath.escape(ospath.join(destinationRootPath, 'buildenvironment.config')),
				ospath.escape(sourceJamfilePath),
				ospath.escape(destinationRootPath)))
		ospath.chmod(updatebuildenvironment, 777)
	end

	ospath.mkdir(ospath.add_slash(_getWorkspacesPath()))
	if uname == 'windows' then
		-- Write updateworkspace.bat.
		ospath.write_file(ospath.join(_getWorkspacesPath(), 'updateworkspaces.bat'),
				("@%s --workspace --gen=%s --config=%s %s %s\n"):format(
				ospath.escape(jamScript), table.concat(opts.gen, ','),
				ospath.escape(ospath.join(destinationRootPath, 'buildenvironment.config')),
				ospath.escape(sourceJamfilePath),
				ospath.escape(destinationRootPath)))
	else
		-- Write updateworkspace.sh.
		ospath.write_file(ospath.join(_getWorkspacesPath(), 'updateworkspaces'),
				("#!/bin/sh\n%s --workspace --gen=%s --config=%s %s %s\n"):format(
				ospath.escape(jamScript), table.concat(opts.gen, ','),
				ospath.escape(ospath.join(destinationRootPath, 'buildenvironment.config')),
				ospath.escape(sourceJamfilePath),
				ospath.escape(destinationRootPath)))
		ospath.chmod(ospath.join(_getWorkspacesPath(), 'updateworkspaces'), 777)
	end

	for _, _ide in ipairs(opts.gen) do
		ide = _ide
		print('Generating the ' .. ide .. ' workspace...')

		local exporter = Exporters[ide]
		exporter.Options.compiler = opts.compiler
		WriteJambase(exporter)

		BuildWorkspace(exporter, ide)
	end

	-- Write buildenvironment.config.
	prettydump.dumpascii(ospath.join(destinationRootPath, 'buildenvironment.config'), 'Config', Config)

	if opts.gen[1] ~= 'none' then
		-- This can fail on Windows 7 with TCC 10.00.76.  Put it at the end, so the rest of
		-- the process finishes.
		if opts.gui then
			if OS == "NT" then
				os.execute('explorer "' .. ospath.make_backslash(_getWorkspacePath()) .. '"')
			end
		end
	end
end


ProcessCommandLine()

if opts.jamexepath then
	jamExePathNoQuotes = ospath.join(opts.jamexepath)
else
	jamExePathNoQuotes = JAM_EXECUTABLE
end
jamExePath = ospath.escape(jamExePathNoQuotes)

-- Turn the source code root into an absolute path based on the current working directory.
sourceJamfilePath = ospath.simplify(ospath.make_absolute(nonOpts[1]))
sourceRootPath, sourceJamfile = sourceJamfilePath:match('(.+/)(.*)')
if not sourceRootPath or not sourceJamfile then
	sourceRootPath = sourceJamfilePath
	sourceJamfile = 'Jamfile.jam'
	sourceJamfilePath = sourceRootPath .. '/' .. sourceJamfile
end
if sourceJamfile == '' then
	sourceJamfile = 'Jamfile.jam'
end

Config.SubIncludes =
{
	{ 'AppRoot', '"$(sourceRootPath)"', sourceJamfile },
}

Config.JambaseFlags = JambaseFlags
Config.JamfileFlags = JamfileFlags

-- Do the same with the destination.
destinationRootPath = ospath.simplify(ospath.add_slash(ospath.make_absolute(nonOpts[2] or '.')))

-- Load the config file.
if opts.config then
	local configFile = {}
	local chunk, err = loadfile(opts.config, 'bt', configFile)
	if not chunk then
		print('JamToWorkspace: Unable to load config file [' .. opts.config .. '].')
		print(err)
		os.exit(-1)
	end

	if setfenv then
		setfenv(chunk, configFile)
	end

	local ret, err = pcall(chunk)
	if not ret then
		print('JamToWorkspace: Unable to execute config file [' .. opts.config .. '].')
		print(err)
		os.exit(-1)
	end

	Config = table_merge(Config, configFile.Config)
end

-- Set the paths to the Jambase.jam files.
if opts.jambase then
	mainJambase = ospath.join(sourceRootPath, opts.jambase  or  Config.Jambase)
	Config.Jambase = mainJambase
else
	mainJambase = Config.Jambase  or  ospath.join(jamPath, 'Jambase.jam')
end

local result, message = xpcall(BuildWorkspaces, ErrorHandler)
if not result then
	print(message)
end

var index =
[
    [ "Quick Start Guide", "quick_start.html", [
      [ "Overview", "quick_start.html#quick_start_overview", null ],
      [ "Tutorial 0: Use Jam to Build Simple Applications", "quick_start.html#quick_start_00", [
        [ "Building helloworld", "quick_start.html#quick_start_00_simple_helloworld", null ]
      ] ],
      [ "Tutorial 1: Hello World!", "quick_start.html#quick_start_01", [
        [ "Initial Setup", "quick_start.html#quick_start_01_setup", null ],
        [ "Compiling the Tutorial", "quick_start.html#quick_start_01_compiling", null ],
        [ "Cleaning Up the Tutorial Files", "quick_start.html#quick_start_01_clean", null ],
        [ "Building an IDE Workspace", "quick_start.html#quick_start_01_workspace", null ]
      ] ]
    ] ],
    [ "Examples", "examples.html", [
      [ "Overview", "examples.html#examples_overview", null ],
      [ "Examples: Building Lua", "examples_building_lua.html", [
        [ "Building Lua (5.4)", "examples_building_lua.html#examples_building_lua_setup", [
          [ "Building without a Jamfile", "examples_building_lua.html#examples_building_lua_quick", null ],
          [ "Building a statically-linked Lua with a Jamfile", "examples_building_lua.html#examples_building_lua_jamfile_static", null ]
        ] ]
      ] ],
      [ "Examples Write File", "examples_write_file.html", [
        [ "Writing a file", "examples_write_file.html#examples_write_file_overview", null ],
        [ "Write a file with a custom action", "examples_write_file.html#examples_write_file_1", null ],
        [ "Write a file with changing content", "examples_write_file.html#examples_write_file_2", null ],
        [ "Writing larger text files", "examples_write_file.html#examples_write_file_3", null ],
        [ "Refactoring the build script", "examples_write_file.html#examples_write_file_5", null ],
        [ "Writing the target file to a directory", "examples_write_file.html#examples_write_file_6", null ]
      ] ],
      [ "Examples: Simple Transform", "examples_simple_transform.html", [
        [ "Simple Transform Overview", "examples_simple_transform.html#examples_simple_transform_overview", null ],
        [ "Setup", "examples_simple_transform.html#examples_simple_transform_setup", null ],
        [ "Transform source to destination", "examples_simple_transform.html#examples_simple_transform_step_1", null ],
        [ "Build behaviors", "examples_simple_transform.html#examples_simple_transform_step_2", null ],
        [ "Applying UseCommandLine", "examples_simple_transform.html#examples_simple_transform_step_3", null ]
      ] ]
    ] ],
    [ "Bootstrapping/Building", "building.html", [
      [ "Prerequisites", "building.html#building_prerequisites", null ],
      [ "Quick Bootstrapping of JamPlus", "building.html#building_bootstrapping", null ],
      [ "Embed Build Modules", "building.html#embedbuildmodules", null ],
      [ "Extract Build Modules", "building.html#extractbuildmodules", null ],
      [ "Run the JamPlus Test Suite", "building.html#building_testing", null ]
    ] ],
    [ "Jam Workspace Generator", "jamtoworkspace.html", [
      [ "Overview", "jamtoworkspace.html#jamtoworkspace_overview", null ],
      [ "Usage", "jamtoworkspace.html#jamtoworkspace_usage", null ],
      [ "Generated Files", "jamtoworkspace.html#jamtoworkspace_generatedfiles", null ]
    ] ],
    [ "Usage", "usage.html", null ],
    [ "Jam Language", "jam_language.html", [
      [ "Introduction", "jam_language.html#cmd_intro", null ],
      [ "Operation", "jam_language.html#operation_main", [
        [ "Start-up Phase", "jam_language.html#operation_start-up", null ],
        [ "Parsing Phase", "jam_language.html#operation_parsing", null ],
        [ "Binding Phase", "jam_language.html#operation_binding", [
          [ "Binding", "jam_language.html#operation_binding_binding", null ],
          [ "Targets", "jam_language.html#operation_binding_targets", null ],
          [ "Update Determination", "jam_language.html#operation_binding_update_determination", null ],
          [ "Header File Scanning", "jam_language.html#operation_binding_header_file_scanning", null ]
        ] ],
        [ "Updating Phase", "jam_language.html#operation_updating", null ]
      ] ],
      [ "Language", "jam_language.html#language_main", [
        [ "Overview", "jam_language.html#language_overview", null ],
        [ "Lexical Features", "jam_language.html#language_lexical_features", null ],
        [ "Datatype", "jam_language.html#language_datatype", null ],
        [ "Rules", "jam_language.html#language_rules", null ],
        [ "Updating Actions", "jam_language.html#language_updating_actions", null ],
        [ "Statements", "jam_language.html#language_statements", null ]
      ] ]
    ] ],
    [ "Variables", "language_variables.html", [
      [ "Basics", "language_variables.html#language_variable_basics", null ],
      [ "Variable Expansion", "language_variables.html#language_variable_expansion", null ],
      [ "Patterns and Wildcards", "language_variables.html#patterns_and_wildcards", null ],
      [ "Variable Expansion Examples", "language_variables.html#variable_expansion_examples", null ]
    ] ],
    [ "Built-in Rules", "builtin_rules.html", [
      [ "Introduction", "builtin_rules.html#builtin_rules_intro", null ],
      [ "Dependency Building", "builtin_rules.html#language_built_in_rules_dependency_building", null ],
      [ "rule Depends targets1 : targets2 [ : target3 ... targets9 ] ;", "builtin_rules.html#rule_Depends", null ],
      [ "rule Includes <i>targets1</i> : <i>targets2</i> [ : <i>target3</i> ... <i>targets9</i> ] ;", "builtin_rules.html#rule_Includes", null ],
      [ "rule Needs <i>targets1</i> : <i>targets2</i> [ : <i>target3</i> ... <i>targets9</i> ] ;", "builtin_rules.html#rule_Needs", null ],
      [ "Modifying Binding", "builtin_rules.html#language_built_in_rules_modifying_binding", null ],
      [ "rule Always targets ;", "builtin_rules.html#rule_Always", null ],
      [ "rule ForceCare targets ;", "builtin_rules.html#rule_ForceCare", null ],
      [ "rule ForceContentsOnly targets ;", "builtin_rules.html#rule_ForceContentsOnly", null ],
      [ "rule IgnoreContents targets ;", "builtin_rules.html#rule_IgnoreContents", null ],
      [ "rule Leaves targets ;", "builtin_rules.html#rule_Leaves", null ],
      [ "rule MightNotUpdate targets ;", "builtin_rules.html#rule_MightNotUpdate", null ],
      [ "rule NoCare targets ;", "builtin_rules.html#rule_NoCare", null ],
      [ "rule NotFile targets ;", "builtin_rules.html#rule_NotFile", null ],
      [ "rule NoUpdate targets ;", "builtin_rules.html#rule_NoUpdate", null ],
      [ "rule ScanContents targets ;", "builtin_rules.html#rule_ScanContents", null ],
      [ "rule Temporary targets ;", "builtin_rules.html#rule_Temporary", null ],
      [ "Utility Rules", "builtin_rules.html#language_built_in_rules_utility_rules", null ],
      [ "rule ConfigureFileHelper TARGET : SOURCE [ : OPTIONS ] ;", "builtin_rules.html#rule_ConfigureFileHelper", null ],
      [ "rule DebugSuppressMakeText ;", "builtin_rules.html#rule_DebugSuppressMakeText", null ],
      [ "rule DependsList PARENT_TARGETS ;", "builtin_rules.html#rule_DependsList", null ],
      [ "rule Echo ARGS ;", "builtin_rules.html#rule_Echo", null ],
      [ "rule Exit ARGS ;", "builtin_rules.html#rule_Exit", null ],
      [ "rule ExpandFileList WILDCARDS : ABSOLUTE : SEARCH_SOURCE", "builtin_rules.html#rule_ExpandFileList", null ],
      [ "rule Glob DIRECTORIES : PATTERNS [ : PREPEND ] ;", "builtin_rules.html#rule_Glob", null ],
      [ "rule GroupByVar TARGETLIST_VARIABLE_NAME : COMPARISON_SETTINGS_NAME [ : MAX_PER_GROUP ] ;", "builtin_rules.html#rule_GroupByVar", null ],
      [ "rule ListSort LIST : CASE_INSENSITVE ;", "builtin_rules.html#rule_ListSort", null ],
      [ "rule MakeRelativePath INPUT_PATHS : START_PATH ;", "builtin_rules.html#rule_MakeRelativePath", null ],
      [ "rule Match REGEXPS : LIST ;", "builtin_rules.html#rule_Match", null ],
      [ "rule Math LEFT OPERATOR RIGHT ;", "builtin_rules.html#rule_Math", null ],
      [ "rule MD5 LIST [ : LIST2 ... ] ;", "builtin_rules.html#rule_MD5", null ],
      [ "rule MD5File FILENAME_LIST [ : FILENAME_LIST2 ... ] ;", "builtin_rules.html#rule_MD5File", null ],
      [ "rule OptionalFileCache TARGETS [ : CACHE_NAME ] ;", "builtin_rules.html#rule_OptionalFileCache", null ],
      [ "rule QuickSettingsLookup TARGET : SYMBOL ;", "builtin_rules.html#rule_QuickSettingsLookup", null ],
      [ "rule QueueJamfile JAMFILE_LIST [ : PRIORITY ] ;", "builtin_rules.html#rule_QueueJamfile", null ],
      [ "rule RuleExists RULE_NAME ;", "builtin_rules.html#rule_RuleExists", null ],
      [ "rule Search TARGET ;", "builtin_rules.html#rule_Search", null ],
      [ "rule Shell COMMANDS ;", "builtin_rules.html#rule_Shell", null ],
      [ "rule Split STRINGS : SPLIT_CHARACTERS", "builtin_rules.html#rule_Split", null ],
      [ "rule Subst LIST : PATTERN [ : REPL [ : MAXN ] ] ;", "builtin_rules.html#rule_Subst", [
        [ "Patterns", "builtin_rules.html#rule_Subst_Patterns", null ]
      ] ],
      [ "rule SubstLiteralize LITERAL_PATTERN ;", "builtin_rules.html#rule_SubstLiteralize", null ],
      [ "rule UseCommandLine TARGETS : COMMANDLINE;", "builtin_rules.html#rule_UseCommandLine", null ],
      [ "rule UseDepCache TARGETS [ : CACHE_NAME ] ;", "builtin_rules.html#rule_UseDepCache", null ],
      [ "rule UseFileCache TARGETS [ : CACHE_NAME ] ;", "builtin_rules.html#rule_UseFileCache", null ],
      [ "rule UseMD5Callback TARGETS [ : MD5_CALLBACK ] ;", "builtin_rules.html#rule_UseMD5Callback", null ],
      [ "rule W32_GETREG KEYS ;", "builtin_rules.html#rule_W32_GETREG", null ],
      [ "rule Wildcard WILDCARDS : ABSOLUTE : SEARCH_SOURCE", "builtin_rules.html#rule_Wildcard", null ],
      [ "Building with Checksums", "checksum_builds.html", [
        [ "Overview", "checksum_builds.html#checksum_builds_overview", null ],
        [ "Usage", "checksum_builds.html#checksum_builds_usage", null ]
      ] ]
    ] ],
    [ "Built-in Variables", "builtin_variables.html", [
      [ "Introduction", "builtin_variables.html#builtin_variables_intro", null ],
      [ "BINDING, SEARCH, and LOCATE Variables", "builtin_variables.html#built_in_variables_binding_binding_search_locate", null ],
      [ "Header Scanning Variables", "builtin_variables.html#built_in_variables_hdrscan", [
        [ "Filtering Unwanted Dependencies", "builtin_variables.html#built_in_variables_hdrfilter", null ],
        [ "Shelling Processes for Dependencies", "builtin_variables.html#built_in_variables_hdrpipe", null ]
      ] ],
      [ "Semaphores", "builtin_variables.html#built_in_variables_semaphore", null ],
      [ "Platform Identifier Variables", "builtin_variables.html#built_in_variables_platform", null ],
      [ "Jam Version Variables", "builtin_variables.html#language_built_in_variables_version", null ],
      [ "Miscellaneous Variables", "builtin_variables.html#language_built_in_variables_misc", null ],
      [ "JAMSHELL Variable", "builtin_variables.html#built_in_variables_jamshell", null ],
      [ "Clean up of extra files and directories", "builtin_variables.html#language_built_in_variables_clean_globs", null ]
    ] ],
    [ "Dependency Cache", "dependency_cache.html", [
      [ "Introduction", "dependency_cache.html#dependency_cache_intro", null ],
      [ "Dependency Cache Usage", "dependency_cache.html#dependency_cache_usage", null ],
      [ "Technical Details", "dependency_cache.html#dependency_cache_technical_details", null ]
    ] ],
    [ "Jambase Rules", "jambase_rules.html", [
      [ "Introduction", "jambase_rules.html#jambase_intro", null ],
      [ "Missing rules", "jambase_rules.html#jambase_missing_rules", null ],
      [ "rule ActiveTarget TARGET", "jambase_rules.html#rule_ActiveTarget", null ],
      [ "rule AutoSourceGroup [ TARGET ] [ : SOURCES ]", "jambase_rules.html#rule_AutoSourceGroup", null ],
      [ "rule Clean TARGETS : FILES", "jambase_rules.html#rule_Clean", null ],
      [ "rule CleanTree TARGETS : DIRECTORIES", "jambase_rules.html#rule_CleanTree", null ],
      [ "rule ExternalProject PROJECT_NAME : PROJECT_PATH", "jambase_rules.html#rule_ExternalProject", null ],
      [ "rule FGristDirectories DIRECTORIES", "jambase_rules.html#rule_FGristDirectories", null ],
      [ "rule IncludeModule MODULE_NAME", "jambase_rules.html#rule_IncludeModule", null ],
      [ "rule MakeLocate TARGETS : DIRECTORY : OPTIONS", "jambase_rules.html#rule_MakeLocate", null ],
      [ "rule MkDir DIRECTORY", "jambase_rules.html#rule_MkDir", null ],
      [ "rule NoWorkspace WORKSPACE_NAME", "jambase_rules.html#rule_NoWorkspace", null ],
      [ "rule Project PROJECT_NAME : SOURCES", "jambase_rules.html#rule_Project", null ],
      [ "rule ProjectGroup TARGET : FOLDERNAME : PROJECTS", "jambase_rules.html#rule_ProjectGroup", null ],
      [ "rule RmTemps TARGETS : SOURCES", "jambase_rules.html#rule_RmTemps", null ],
      [ "rule SearchSource SOURCES", "jambase_rules.html#rule_SearchSource", null ],
      [ "rule SourceGroup TARGET : FOLDERNAME : SOURCES", "jambase_rules.html#rule_SourceGroup", null ],
      [ "rule SubDir TOP d1...dn : SUBNAME", "jambase_rules.html#rule_SubDir", null ],
      [ "rule SubInclude VAR d1...dn : FILETITLE : OPTIONS", "jambase_rules.html#rule_SubInclude", null ],
      [ "rule SubIncludeRelative RELATIVE_PATH : FILETITLE : OPTIONS", "jambase_rules.html#rule_SubIncludeRelative", null ],
      [ "rule Workspace WORKSPACE_NAME : TARGETS", "jambase_rules.html#rule_Workspace", null ],
      [ "rule WorkspaceConfig WORKSPACE_NAME : CONFIG_NAME : JAM_CONFIG_NAME : COMMAND_LINE", "jambase_rules.html#rule_WorkspaceConfig", null ],
      [ "actions WriteFile TARGETS", "jambase_rules.html#actions_WriteFile", null ],
      [ "rule WriteFileContents TARGETS : CONTENTS", "jambase_rules.html#rule_WriteFileContents", null ]
    ] ],
    [ "JamPlus Modules", "modules.html", [
      [ "Introduction", "modules.html#modules_intro", null ],
      [ "List of Jam Modules", "modules.html#modules_list", [
        [ "General Modules", "modules.html#modules_general_list", null ],
        [ "C/C++ Support Modules", "modules.html#modules_c_support_list", null ],
        [ "C# Support Modules", "modules.html#modules_csharp_support_list", null ],
        [ "Platform Support Modules", "modules.html#modules_platform_support_list", null ]
      ] ],
      [ "Directory Copy Rules", "module_copydirectory.html", [
        [ "List of Rules", "module_copydirectory.html#module_copydirectory_ruleslist", null ],
        [ "Rules", "module_copydirectory.html#module_copydirectory_rules", null ],
        [ "rule CopyDirectory PARENTS : DESTINATION_PATH : SOURCE_PATH [ : SEARCH_STRING ]", "module_copydirectory.html#rule_CopyDirectory", null ]
      ] ],
      [ "File Copy Rules", "module_copyfile.html", [
        [ "List of Rules", "module_copyfile.html#module_copyfile_ruleslist", null ],
        [ "Rules", "module_copyfile.html#module_copyfile_rules", null ],
        [ "rule CopyFile PARENTS : TARGET : SOURCE", "module_copyfile.html#rule_CopyFile", null ]
      ] ],
      [ "C++/CLI Rules", "module_hardsoftlink.html", [
        [ "List of Rules", "module_hardsoftlink.html#module_hardsoftlink_ruleslist", null ],
        [ "Rules", "module_hardsoftlink.html#module_hardsoftlink_rules", null ],
        [ "rule HardLink PARENT : TARGET : SOURCE", "module_hardsoftlink.html#rule_HardLink", null ],
        [ "rule SoftLink PARENT : TARGET : SOURCE", "module_hardsoftlink.html#rule_SoftLink", null ]
      ] ],
      [ "C/C++ Rules", "module_c.html", [
        [ "List of Rules", "module_c.html#module_c_ruleslist", null ],
        [ "Rules", "module_c.html#module_c_rules", null ],
        [ "rule C.ActiveTarget TARGET", "module_c.html#rule_C_ActiveTarget", null ],
        [ "rule C.AddBuildExtensions TYPE : EXTS : RULE : SUFOBJ : ADD_TO_EXTENSIONS : ADD_TO_LINK", "module_c.html#rule_C_AddBuildExtensions", null ],
        [ "rule C.AddFlags TARGET : FLAGS", "module_c.html#rule_C_AddFlags", null ],
        [ "rule C.Application TARGET : SOURCES [ : OPTIONS ]", "module_c.html#rule_C_Application", null ],
        [ "rule C.BatchCompileGroupSize TARGET [ : SIZE ]", "module_c.html#rule_C_BatchCompileGroupSize", null ],
        [ "rule C.CFlags TARGET : FLAGS", "module_c.html#rule_C_CFlags", null ],
        [ "rule C.Clean TARGET : FILES", "module_c.html#rule_C_Clean", null ],
        [ "rule C.C++Exceptions TARGET : TYPE", "module_c.html#rule_C_CppExceptions", null ],
        [ "rule C.C++Flags TARGET : FLAGS", "module_c.html#rule_C_CppFlags", null ],
        [ "rule C.CompileOptions OPTIONS", "module_c.html#rule_C_CompileOptions", null ],
        [ "rule C.ConfigureFile TARGET : DESTINATION : SOURCE : OPTIONS", "module_c.html#rule_C_ConfigureFile", null ],
        [ "rule C.DefFile TARGET : SOURCES", "module_c.html#rule_C_DefFile", null ],
        [ "rule C.Defines TARGET : DEFINES [ : OPTIONS ]", "module_c.html#rule_C_Defines", null ],
        [ "rule C.ExcludeFromBuild TARGET : SOURCES", "module_c.html#rule_C_ExcludeFromBuild", null ],
        [ "rule C.ExcludeFromWorkspace TARGET : SOURCES", "module_c.html#rule_C_ExcludeFromWorkspace", null ],
        [ "rule C.ExcludePatternsFromBuild TARGET : PATTERNS", "module_c.html#rule_C_ExcludePatternsFromBuild", null ],
        [ "rule C.Flags TYPE : TARGET : FLAGS", "module_c.html#rule_C_Flags", null ],
        [ "rule C.ForceFileType TARGET : SOURCES : FILE_TYPE", "module_c.html#rule_C_ForceFileType", null ],
        [ "rule C.ForceInclude TARGET : INCLUDES", "module_c.html#rule_C_ForceInclude", null ],
        [ "rule C.ForcePublic TARGET", "module_c.html#rule_C_ForcePublic", null ],
        [ "rule C.GetArchitecture TOOLCHAIN_SPEC", "module_c.html#rule_C_GetArchitecture", null ],
        [ "rule C.GetLinkTargets TARGET : TOOLCHAIN_SPEC", "module_c.html#rule_C_GetLinkTargets", null ],
        [ "rule C.GetActiveToolchain", "module_c.html#rule_C_GetActiveToolchain", null ],
        [ "rule C.GristFiles TARGET : FILES", "module_c.html#rule_C_GristFiles", null ],
        [ "rule C.GristTarget TARGET", "module_c.html#rule_C_GristTarget", null ],
        [ "rule C.IncludeDirectories TARGET : INCLUDEPATHS [ : OPTIONS ]", "module_c.html#rule_C_IncludeDirectories", null ],
        [ "rule C.IncludeInBuild TARGET : SOURCES", "module_c.html#rule_C_IncludeInBuild", null ],
        [ "rule C.Inherits TARGET : INHERITS_TARGETS [ : OPTIONS ]", "module_c.html#rule_C_Inherits", null ],
        [ "rule C.InstallNamePath TARGET : INSTALL_NAME_PATH", "module_c.html#rule_C_InstallNamePath", null ],
        [ "rule C.LibFlags TARGET : FLAGS", "module_c.html#rule_C_LibFlags", null ],
        [ "rule C.Library TARGET : SOURCES [ : OPTIONS ]", "module_c.html#rule_C_Library", null ],
        [ "rule C.LinkDirectories TARGET : DIRECTORIES [ : OPTIONS ]", "module_c.html#rule_C_LinkDirectories", null ],
        [ "rule C.LinkFlags TARGET : FLAGS", "module_c.html#rule_C_LinkFlags", null ],
        [ "rule C.LinkLibraries TARGET : LIBRARIES [ : OPTIONS ]", "module_c.html#rule_C_LinkLibraries", null ],
        [ "rule C.LinkPrebuiltLibraries TARGET : LIBRARIES [ : OPTIONS ]", "module_c.html#rule_C_LinkPrebuiltLibraries", null ],
        [ "rule C.Lump PARENT : SOURCES_VARIABLE_NAME : LUMP_NAME [ : PCH_FILENAMES : EXTRA_INCLUDE_PATHS ]", "module_c.html#rule_C_Lump", null ],
        [ "rule C.NoPrecompiledHeader TARGET : FILES", "module_c.html#rule_C_NoPrecompiledHeader", null ],
        [ "rule C.ObjectAddFlags TARGET : SOURCES : FLAGS", "module_c.html#rule_C_ObjectAddFlags", null ],
        [ "rule C.ObjectCFlags TARGET : SOURCES : FLAGS", "module_c.html#rule_C_ObjectCFlags", null ],
        [ "rule C.ObjectC++Flags TARGET : SOURCES : FLAGS", "module_c.html#rule_C_ObjectCppFlags", null ],
        [ "rule C.ObjectDefines TARGET : SOURCES : DEFINES", "module_c.html#rule_C_ObjectDefines", null ],
        [ "rule C.ObjectForceInclude TARGET : SOURCES : INCLUDES", "module_c.html#rule_C_ObjectForceInclude", null ],
        [ "rule C.ObjectIncludeDirectories TARGET : SOURCE : INCLUDEPATHS [ : OPTIONS ]", "module_c.html#rule_C_ObjectIncludeDirectories", null ],
        [ "rule C.ObjectRemoveFlags TARGET : SOURCES : FLAGS", "module_c.html#rule_C_ObjectRemoveFlags", null ],
        [ "rule C.OutputName TARGET : NAME", "module_c.html#rule_C_OutputName", null ],
        [ "rule C.OutputPath TARGET : OUTPUTPATH", "module_c.html#rule_C_OutputPath", null ],
        [ "rule C.OutputPostfix TARGET : POSTFIX", "module_c.html#rule_C_OutputPostfix", null ],
        [ "rule C.OutputPostfixClear TARGET", "module_c.html#rule_C_OutputPostfixClear", null ],
        [ "rule C.OutputSuffix TARGET : SUFFIX", "module_c.html#rule_C_OutputSuffix", null ],
        [ "rule C.OverrideToolchainSpec TOOLCHAIN_SPEC_OPTIONS : OPTIONS", "module_c.html#rule_C_OverrideToolchainSpec", null ],
        [ "rule C.PrecompiledHeader TARGET : NAME : FILES", "module_c.html#rule_C_PrecompiledHeader", null ],
        [ "rule C.RemoveFlags TARGET : FLAGS", "module_c.html#rule_C_RemoveFlags", null ],
        [ "rule C.RuntimeType TARGET : TYPE [ : THE_PLATFORM ]", "module_c.html#rule_C_RuntimeType", null ],
        [ "rule C.SearchSource TARGET : SOURCES : SEARCH_PATHS", "module_c.html#rule_C_SearchSource", null ],
        [ "rule C.Toolchain TOOLCHAIN_SPEC", "module_c.html#rule_C_Toolchain", null ],
        [ "rule LocateSource TARGET : DIRECTORY", "module_c.html#rule_LocateSource", null ],
        [ "rule LocateTarget TARGET : DIRECTORY", "module_c.html#rule_LocateTarget", null ],
        [ "C Module Multiple Toolchain Support", "module_c_multiple_toolchain_support.html", [
          [ "Overview", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_overview", null ],
          [ "Usage", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_usage", null ],
          [ "Example", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_example", null ],
          [ "Technical Details", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_technical_details", null ]
        ] ]
      ] ],
      [ "c/directx - C/C++ DirectX Rules", "module_c_directx.html", [
        [ "List of Rules", "module_c_directx.html#module_c_directx_ruleslist", null ],
        [ "Rules", "module_c_directx.html#module_c_directx_rules", null ],
        [ "rule C.UseDirectX TARGET [ : OPTIONS ]", "module_c_directx.html#rule_C_UseDirectX", null ]
      ] ],
      [ "c/dotnet - C++/CLI Rules", "module_c_dotnet.html", [
        [ "List of Rules", "module_c_dotnet.html#module_c_dotnet_ruleslist", null ],
        [ "Rules", "module_c_dotnet.html#module_c_dotnet_rules", null ],
        [ "rule C.ReferenceDirectories TARGET : DIRECTORIES : THE_CONFIG : THE_PLATFORM", "module_c_dotnet.html#rule_C_ReferenceDirectories", null ],
        [ "rule C.StrongName TARGET : SNK_NAME", "module_c_dotnet.html#rule_C_StrongName", null ],
        [ "rule C.UseDotNet TARGET [ : OPTIONS ]", "module_c_dotnet.html#rule_C_UseDotNet", null ]
      ] ],
      [ "c/mfc - C++ MFC Rules", "module_c_mfc.html", [
        [ "List of Rules", "module_c_mfc.html#module_c_mfc_ruleslist", null ],
        [ "Rules", "module_c_mfc.html#module_c_mfc_rules", null ],
        [ "rule C.UseMFC TARGET [ : OPTIONS ]", "module_c_mfc.html#rule_C_UseMFC", null ]
      ] ],
      [ "c/midl - IDL Rules", "module_c_midl.html", [
        [ "List of Rules", "module_c_midl.html#module_c_midl_ruleslist", null ],
        [ "Rules", "module_c_midl.html#module_c_midl_rules", null ],
        [ "rule C.MidlCompiler PARENT : SOURCE", "module_c_midl.html#rule_C_MidlCompiler", null ],
        [ "rule C.MidlFlags PARENT : BASE_NAME [ : OPTIONS ]", "module_c_midl.html#rule_C_MidlFlags", null ]
      ] ],
      [ "Win32 Resource Support", "module_c_win32resource.html", [
        [ "List of Rules", "module_c_win32resource.html#module_c_win32resource_ruleslist", null ],
        [ "Rules", "module_c_win32resource.html#module_c_win32resource_rules", null ],
        [ "rule C.RcDefines TARGET [ : RESOURCE_NAME ] : DEFINES", "module_c_win32resource.html#rule_C_RcDefines", null ],
        [ "rule C.RcFlags TARGET [ : RESOURCE_NAME ] : FLAGS", "module_c_win32resource.html#rule_C_RcFlags", null ],
        [ "rule C.RcIncludeDirectories TARGET [ : RESOURCE_NAME ] : HDRS", "module_c_win32resource.html#rule_C_RcIncludeDirectories", null ],
        [ "rule C.ResourceCompiler PARENT : SOURCES [ : OPTIONS ]", "module_c_win32resource.html#rule_C_ResourceCompiler", null ]
      ] ],
      [ "c/wxwidgets - C++ wxWidgets Rules", "module_c_wxwidgets.html", [
        [ "List of Rules", "module_c_wxwidgets.html#module_c_wxwidgets_ruleslist", null ],
        [ "Rules", "module_c_wxwidgets.html#module_c_wxwidgets_rules", null ],
        [ "rule C.UseWxWidgets TARGETS : COMPONENTS [ : OPTIONS ]", "module_c_wxwidgets.html#rule_C_UseWxWidgets", null ]
      ] ],
      [ "C# Rules", "module_csharp.html", [
        [ "List of Rules", "module_csharp.html#module_csharp_ruleslist", null ],
        [ "Rules", "module_csharp.html#module_csharp_rules", null ],
        [ "rule CSharp.CscDefines TARGET : DEFINES [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_CscDefines", null ],
        [ "rule CSharp.CscFlags TARGET : FLAGS [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_CscFlags", null ],
        [ "rule CSharp.Application TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Application", null ],
        [ "rule CSharp.Assembly TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Assembly", null ],
        [ "rule CSharp.Library TARGET : SOURCES [ : OPTIONS ]", "module_csharp.html#rule_CSharp_Library", null ],
        [ "rule CSharp.ReferenceAssemblies TARGET : ASSEMBLIES [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_ReferenceAssemblies", null ],
        [ "rule CSharp.ReferencePaths TARGET : PATHS [ : THE_CONFIG ]", "module_csharp.html#rule_CSharp_ReferencePaths", null ]
      ] ],
      [ "Android Rules", "module_android.html", [
        [ "List of Rules", "module_android.html#module_android_ruleslist", null ],
        [ "Rules", "module_android.html#module_android_rules", null ],
        [ "rule android.Application TARGET : SOURCES", "module_android.html#rule_android_Application", null ],
        [ "rule android.Assets TARGET : DIRECTORY", "module_android.html#rule_android_Assets", null ],
        [ "rule android.JarDirectories TARGET : DIRECTORIES", "module_android.html#rule_android_JarDirectories", null ],
        [ "rule android.Library TARGET : SOURCES : OPTIONS", "module_android.html#rule_android_Library", null ],
        [ "rule android.LinkJars TARGET : LIBRARIES", "module_android.html#rule_android_LinkJars", null ],
        [ "rule android.Manifest TARGET : MANIFEST", "module_android.html#rule_android_Manifest", null ],
        [ "rule android.NativeLibraries TARGET : NATIVE_LIBRARIES", "module_android.html#rule_android_NativeLibraries", null ],
        [ "rule android.NativePrebuiltLibraries TARGET : NATIVE_PREBUILT_LIBRARIES", "module_android.html#rule_android_NativePrebuiltLibraries", null ],
        [ "rule android.NativePrebuiltLibraryDirectories TARGET : DIRECTORIES", "module_android.html#rule_android_NativePrebuiltLibraryDirectories", null ],
        [ "rule android.Package TARGET [ : TOOLCHAINS [ : OPTIONS ] ]", "module_android.html#rule_android_Package", null ],
        [ "rule android.PackageName TARGET : PACKAGE_NAME", "module_android.html#rule_android_PackageName", null ],
        [ "rule android.PackageOutputPath TARGET : PACKAGE_OUTPUT_PATH", "module_android.html#rule_android_PackageOutputPath", null ],
        [ "rule android.PrebuiltAars TARGET : LIBRARIES", "module_android.html#rule_android_PrebuiltAars", null ],
        [ "rule android.PrebuiltJars TARGET : LIBRARIES", "module_android.html#rule_android_PrebuiltJars", null ],
        [ "rule android.ProductVersion TARGET : VERSION_NAME : VERSION_CODE", "module_android.html#rule_android_ProductVersion", null ],
        [ "rule android.Resources TARGET : DIRECTORIES", "module_android.html#rule_android_Resources", null ],
        [ "rule android.SDK SDK_VERSION : ARCHITECTURE", "module_android.html#rule_android_SDK", null ],
        [ "rule android.SDKCompileVersion TARGET : SDK_COMPILE_VERSION", "module_android.html#rule_android_SDKCompileVersion", null ],
        [ "rule android.SDKMinimumVersion TARGET : SDK_MINIMUM_VERSION", "module_android.html#rule_android_SDKMinimumVersion", null ],
        [ "rule android.Sign TARGET : KEYSTORE_PATH_PASSWORD_KEY", "module_android.html#rule_android_Sign", null ],
        [ "rule android.SourcePaths TARGET : DIRECTORIES", "module_android.html#rule_android_SourcePaths", null ],
        [ "rule android.UncompressedAssetExtensions TARGET : UNCOMPRESSED_ASSET_EXTENSIONS", "module_android.html#rule_android_UncompressedAssetExtensions", null ]
      ] ],
      [ "iOS Rules", "module_ios.html", [
        [ "List of Rules", "module_ios.html#module_ios_ruleslist", null ],
        [ "Rules", "module_ios.html#module_ios_rules", null ],
        [ "rule C.ios.FrameworkDirectories TARGET : DIRECTORIES", "module_ios.html#rule_C_ios_FrameworkDirectories", null ],
        [ "rule C.ios.LinkFrameworks TARGET : FRAMEWORKS", "module_ios.html#rule_C_ios_LinkFrameworks", null ],
        [ "rule C.ios.WeakLinkFrameworks TARGET : FRAMEWORKS", "module_ios.html#rule_C_ios_WeakLinkFrameworks", null ],
        [ "rule ios.Archive TARGET : OUTPUT_PATH : ITUNES_ARTWORK : OPTIONS", "module_ios.html#rule_ios_Archive", null ],
        [ "rule ios.AssetCatalog TARGET : ASSET_CATALOG_PATH ;", "module_ios.html#rule_ios_AssetCatalog", null ],
        [ "rule ios.Bundle TARGET [ : TOOLCHAINS ]", "module_ios.html#rule_ios_Bundle", null ],
        [ "rule ios.BundleInfoArrayBegin TARGET : KEY", "module_ios.html#rule_ios_BundleInfoArrayBegin", null ],
        [ "rule ios.BundleInfoArrayBoolean TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayBoolean", null ],
        [ "rule ios.BundleInfoArrayDictBegin TARGET", "module_ios.html#rule_ios_BundleInfoArrayDictBegin", null ],
        [ "rule C.ios.BundleInfoArrayDictEnd TARGET", "module_ios.html#rule_ios_BundleInfoArrayDictEnd", null ],
        [ "rule ios.BundleInfoArrayEnd TARGET", "module_ios.html#rule_ios_BundleInfoArrayEnd", null ],
        [ "rule ios.BundleInfoArrayInteger TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayInteger", null ],
        [ "rule ios.BundleInfoArrayString TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoArrayString", null ],
        [ "rule ios.BundleInfoBoolean TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoBoolean", null ],
        [ "rule ios.BundleInfoDictBegin TARGET : KEY", "module_ios.html#rule_ios_BundleInfoDictBegin", null ],
        [ "rule ios.BundleInfoDictEnd TARGET", "module_ios.html#rule_ios_BundleInfoDictEnd", null ],
        [ "rule ios.BundleInfoInteger TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoInteger", null ],
        [ "rule ios.BundleInfoString TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfoString", null ],
        [ "rule ios.BundleInfo TARGET : KEY : VALUE : NO_OVERRIDE", "module_ios.html#rule_ios_BundleInfo", null ],
        [ "rule ios.BundlePath TARGET : BUNDLE_PATH", "module_ios.html#rule_ios_BundlePath", null ],
        [ "rule ios.CodeSign TARGET : SIGNING_IDENTITY : CERTIFICATE_CHAIN", "module_ios.html#rule_ios_CodeSign", null ],
        [ "rule ios.GetBundlePath TARGET", "module_ios.html#rule_ios_GetBundlePath", null ],
        [ "rule ios.GetBundleTarget TARGET", "module_ios.html#rule_ios_GetBundleTarget", null ],
        [ "rule ios.InfoPListFile TARGET : SOURCE", "module_ios.html#rule_ios_InfoPListFile", null ],
        [ "rule C.ios.Lipo TARGET : LINK_TARGETS : OUTPUT_PATH", "module_ios.html#rule_C_ios_Lipo", null ],
        [ "rule ios.MergeInfoPList TARGET : SOURCE", "module_ios.html#rule_ios_MergeInfoPList", null ],
        [ "rule ios.MinimumOSVersion TARGET : SDK_VERSION_MIN", "module_ios.html#rule_ios_MinimumOSVersion", null ],
        [ "rule ios.ProvisionFile TARGET : FILENAME", "module_ios.html#rule_ios_ProvisionFile", null ],
        [ "rule ios.Provision TARGET : PROFILE_ID", "module_ios.html#rule_ios_Provision", null ],
        [ "rule ios.SDK SDK_VERSION", "module_ios.html#rule_ios_SDK", null ],
        [ "rule ios.Storyboards TARGET : LANGUAGE_DIRECTORY [ : STORYBOARD_FILES ]", "module_ios.html#rule_ios_Storyboards", null ],
        [ "rule ios.WebServer TARGET", "module_ios.html#rule_ios_WebServer", null ]
      ] ]
    ] ],
    [ "Multiple Passes", "multiple_passes.html", [
      [ "Overview", "multiple_passes.html#multiple_passes_overview", null ],
      [ "Usage", "multiple_passes.html#multiple_passes_usage", null ],
      [ "Example 1", "multiple_passes.html#multiple_passes_example1", null ],
      [ "Gotchas", "multiple_passes.html#multiple_passes_gotchas", null ]
    ] ],
    [ "C Module Multiple Toolchain Support", "module_c_multiple_toolchain_support.html", [
      [ "Overview", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_overview", null ],
      [ "Usage", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_usage", null ],
      [ "Example", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_example", null ],
      [ "Technical Details", "module_c_multiple_toolchain_support.html#module_c_multiple_toolchain_support_technical_details", null ]
    ] ],
    [ "Lua Support", "lua_support.html", [
      [ "Overview", "lua_support.html#lua_support_overview", null ],
      [ "Using Lua during the Parsing Phase", "lua_support.html#lua_support_rules", [
        [ "rule LuaString LUA_SCRIPT", "lua_support.html#rule_LuaString", null ],
        [ "rule LuaFile LUA_FILENAME", "lua_support.html#rule_LuaFile", null ]
      ] ],
      [ "Using Lua in Actions", "lua_support.html#lua_support_actions", null ],
      [ "Lua Line Filters", "lua_support.html#lua_support_line_filters", null ],
      [ "Accessing Jam from Lua", "lua_support.html#lua_support_module_jam", null ],
      [ "Lua to Jam API", "lua_support.html#lua_support_jam", [
        [ "function jam_action(ACTION_NAME, ACTION_TEXT [, FLAGS])", "lua_support.html#lua_jam_action", null ],
        [ "function jam_evaluaterule(RULE_NAME [, PARAMETERS])", "lua_support.html#lua_jam_evaluaterule", null ],
        [ "function jam_expand(TEXT_TO_EXPAND)", "lua_support.html#lua_jam_expand", null ],
        [ "function jam_getvar([ TARGET_NAME, ] VARIABLE_NAME)", "lua_support.html#lua_jam_getvar", null ],
        [ "function jam_parse(TEXT_TO_PARSE)", "lua_support.html#lua_jam_parse", null ],
        [ "function jam_print(TEXT_TO_PRINT)", "lua_support.html#lua_jam_print", null ],
        [ "function jam_setvar([ TARGET_NAME, ] VARIABLE_NAME, VALUE)", "lua_support.html#lua_jam_setvar", null ]
      ] ],
      [ "Examples", "lua_support.html#lua_support_examples", null ]
    ] ],
    [ "File Cache", "file_cache.html", [
      [ "Introduction", "file_cache.html#file_cache_intro", null ],
      [ "Creating and Using File Caches", "file_cache.html#file_cache_usage", [
        [ "Creation of a File Cache", "file_cache.html#file_cache_usage_creating", null ],
        [ "Using the File Cache", "file_cache.html#file_cache_usage_using", null ]
      ] ],
      [ "Technical Details", "file_cache.html#file_cache_technical", null ],
      [ "Content MD5sums", "file_cache.html#file_cache_content_md5sums", null ]
    ] ],
    [ "Building with Checksums", "checksum_builds.html", [
      [ "Overview", "checksum_builds.html#checksum_builds_overview", null ],
      [ "Usage", "checksum_builds.html#checksum_builds_usage", null ]
    ] ],
    [ "Warnings and Errors", "warnings_and_errors.html", null ],
    [ "Bugs, Limitations", "bugs.html", null ],
    [ "Miscellaneous Improvements", "improvements.html", null ],
    [ "Scripts", "scripts.html", [
      [ "Overview", "scripts.html#scripts_overview", null ],
      [ "FoldersToJamfile", "scripts.html#folderstojamfile", null ],
      [ "Generate", "scripts.html#generate", null ],
      [ "VCProjToJamfile", "scripts.html#vcprojtojamfile", null ],
      [ "VCXProjToJamfile", "scripts.html#vcxprojtojamfile", null ]
    ] ],
    [ "Changelog", "changelog.html", [
      [ "Version 1.0", "changelog.html#version1_0", null ]
    ] ]
];
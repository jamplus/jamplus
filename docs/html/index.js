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
    [ "Examples", "examples.html", "examples" ],
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
    [ "Built-in Rules", "builtin_rules.html", "builtin_rules" ],
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
    [ "JamPlus Modules", "modules.html", "modules" ],
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
      [ "Content checksums", "file_cache.html#file_cache_content_checksums", null ]
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
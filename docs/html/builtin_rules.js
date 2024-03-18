var builtin_rules =
[
    [ "Introduction", "builtin_rules.html#builtin_rules_intro", null ],
    [ "Dependency Building", "builtin_rules.html#language_built_in_rules_dependency_building", null ],
    [ "rule Depends targets1 : targets2 [ : target3 ... targets9 ] ;", "builtin_rules.html#rule_Depends", null ],
    [ "rule Includes targets1 : targets2 [ : target3 ... targets9 ] ;", "builtin_rules.html#rule_Includes", null ],
    [ "rule Needs targets1 : targets2 [ : target3 ... targets9 ] ;", "builtin_rules.html#rule_Needs", null ],
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
    [ "rule xxh3_128bits LIST [ : LIST2 ... ] ;", "builtin_rules.html#rule_xxh3_128bits", null ],
    [ "rule xxh3_128bits_file FILENAME_LIST [ : FILENAME_LIST2 ... ] ;", "builtin_rules.html#rule_xxh3_128bits_file", null ],
    [ "Building with Checksums", "checksum_builds.html", [
      [ "Overview", "checksum_builds.html#checksum_builds_overview", null ],
      [ "Usage", "checksum_builds.html#checksum_builds_usage", null ]
    ] ]
];
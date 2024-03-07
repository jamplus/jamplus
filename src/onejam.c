#ifdef _WIN32
#define NT
#pragma comment(lib, "advapi32.lib")
#pragma comment(lib, "Winmm.lib")
#elif defined(__linux__)
#define _GNU_SOURCE
#endif /* _WIN32 */

#define OPT_ACTION_MAXTARGETS_EXT
#define OPT_ACTIONS_DUMP_TEXT_EXT
#define OPT_ACTIONS_WAIT_FIX
#define OPT_BUILTIN_GROUPBYVAR_EXT
#define OPT_BUILTIN_MATH_EXT
#define OPT_BUILTIN_MD5CACHE_EXT
#define OPT_BUILTIN_MD5_EXT
#define OPT_BUILTIN_NEEDS_EXT
#define OPT_BUILTIN_PUTENV_EXT
#define OPT_BUILTIN_SPLIT_EXT
#define OPT_BUILTIN_SUBST_EXT
#define OPT_CIRCULAR_GENERATED_HEADER_FIX
#define OPT_CLEAN_GLOBS_EXT
#ifdef NT
#define OPT_BUILTIN_W32_GETREG_EXT
#define OPT_BUILTIN_W32_GETREG64_EXT
#define OPT_BUILTIN_W32_SHORTNAME_EXT
#endif /* NT */
#define OPT_DEBUG_MAKE1_LOG_EXT
#define OPT_DEBUG_MAKE_PRINT_TARGET_NAME
#define OPT_DEBUG_MEM_TOTALS_EXT
#define OPT_EXPAND_BINDING_EXT
#define OPT_EXPAND_ESCAPE_PATH_EXT
#define OPT_EXPAND_FILEGLOB_EXT
#define OPT_EXPAND_INCLUDES_EXCLUDES_EXT
#define OPT_EXPAND_LITERALS_EXT
#define OPT_EXPAND_RULE_NAMES_EXT
#define OPT_EXPORT_JOBNUM_EXT
#define OPT_FIND_BAD_SEMICOLON_USAGE_EXT
#define OPT_FIX_NOTFILE_NEWESTFIRST
#define OPT_FIX_NT_ARSCAN_LEAK
#define OPT_FIX_TEMPFILE_CRASH
#define OPT_FIX_UPDATED
#define OPT_GRAPH_DEBUG_EXT
#define OPT_HDRPIPE_EXT
#define OPT_HDRRULE_BOUNDNAME_ARG_EXT
#define OPT_HEADER_CACHE_EXT
#define OPT_IMPROVED_MEMUSE_EXT
#define OPT_IMPROVED_PATIENCE_EXT
#define OPT_IMPROVED_PROGRESS_EXT
#define OPT_IMPROVED_WARNINGS_EXT
#define OPT_IMPROVE_DEBUG_COMPILE_EXT
#define OPT_IMPROVE_DEBUG_LEVEL_HELP_EXT
#define OPT_IMPROVE_JOBS_SETTING_EXT
#define OPT_INTERRUPT_FIX
#define OPT_JAMFILE_BOUNDNAME_EXT
#define OPT_JOB_SLOT_EXT
#define OPT_LINE_FILTER_SUPPORT
#define OPT_LOAD_MISSING_RULE_EXT
#define OPT_MINUS_EQUALS_EXT
#define OPT_MULTIPASS_EXT
#define OPT_NOCARE_NODES_EXT
#define OPT_NODELETE_READONLY
#define OPT_PATCHED_VERSION_VAR_EXT
#define OPT_PATH_BINDING_EXT
//#define OPT_PERCENT_DONE_EXT
#define OPT_PIECEMEAL_PUNT_EXT
#define OPT_PRINT_TOTAL_TIME_EXT
#define OPT_REMOVE_EMPTY_DIRS_EXT
#define OPT_RESPONSE_FILES
#define OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
#define OPT_SCAN_SUBDIR_NOTIFY_EXT
#define OPT_SCRIPTS_PASSTHROUGH_EXT
#define OPT_SEMAPHORE
#define OPT_SERIAL_OUTPUT_EXT
#define OPT_SETCWD_SETTING_EXT
#define OPT_SET_JAMCOMMANDLINETARGETS_EXT
#define OPT_SET_JAMPROCESSPATH_EXT
#define OPT_SLASH_MODIFIERS_EXT
#define OPT_TIMESTAMP_IMMEDIATE_PARENT_CHECK_EXT
#define OPT_TIMESTAMP_EXTENDED_PARENT_CHECK_EXT2
#define OPT_UPDATED_CHILD_FIX
#define OPT_USE_CHECKSUMS_EXT
#define OPT_VAR_CWD_EXT
#define OPT_BUILTIN_LUA_SUPPORT_EXT
#define FILEGLOB_BUILD_IMPLEMENTATION
#include "fileglob.c"
#include "buffer.c"
//#define MINIZ_NO_ZLIB_APIS
#include "miniz.c"
//#include "jamzipbuffer.c"
#include "builtins.c"
#include "command.c"
#include "compile.c"
#include "execmac.c"
#include "execunix.c"
#include "execvms.c"
#include "expand.c"
#include "filemac.c"
#include "filent.c"
#include "fileos2.c"
#include "fileunix.c"
#include "filevms.c"
#include "glob.c"
#include "hash.c"
#include "hcache.c"
#include "headers.c"
#include "jam.c"
#include "jambase-j.c"
#include "jamgram.c"
#include "lists.c"
#include "luasupport.c"
#include "luagsub.c"
#include "make.c"
#include "make1.c"
#include "md5c.c"
#include "mempool.c"
#include "newstr.c"
#include "option.c"
#include "parse.c"
#include "pathmac.c"
#include "pathunix.c"
#include "pathvms.c"
#include "progress.c"
#include "regexp.c"
#include "rules.c"
#include "scan.c"
#include "search.c"
#include "timestamp.c"
#include "tmpunix.c"
#include "variable.c"
#include "w32_getreg.c"
#include "w32_shortname.c"
#include "xxhash.c"

#undef LoadString
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lua.h"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lualib.h"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lauxlib.h"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lapi.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lauxlib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lbaselib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lbitlib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lcode.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lcorolib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lctype.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ldblib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ldebug.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ldo.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ldump.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lfunc.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lgc.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/linit.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/liolib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/llex.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lmathlib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lmem.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/loadlib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lobject.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lopcodes.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/loslib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lparser.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lstate.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lstring.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lstrlib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ltable.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ltablib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/ltm.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lundump.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lutf8lib.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lvm.c"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lzio.c"

// Lanes
#include "luaplus/Src/Modules/lanes/src/cancel.c"
#include "luaplus/Src/Modules/lanes/src/compat.c"
#include "luaplus/Src/Modules/lanes/src/deep.c"
#include "luaplus/Src/Modules/lanes/src/keeper.c"
#include "luaplus/Src/Modules/lanes/src/lanes.c"
#include "luaplus/Src/Modules/lanes/src/linda.c"
#include "luaplus/Src/Modules/lanes/src/threading.c"
#include "luaplus/Src/Modules/lanes/src/tools.c"
#include "luaplus/Src/Modules/lanes/src/universe.c"

// filefind
#include "luaplus/Src/Modules/filefind/src/filefind.c"

// md5
#include "luaplus/Src/Modules/md5/lmd5.c"

// miniz
#include "luaplus/Src/Modules/lua-miniz/lminiz.c"

// ospath
#include "luaplus/Src/Modules/ospath/src/ospath.c"
#include "luaplus/Src/Modules/ospath/src/pusherror.c"

// osprocess
#ifdef _WIN32
#include "luaplus/Src/Modules/osprocess/w32api/ex.c"
#include "luaplus/Src/Modules/osprocess/w32api/spawn.c"
#include "luaplus/Src/Modules/osprocess/w32api/windows_pusherror.c"
#else
#include "luaplus/Src/Modules/osprocess/posix/ex.c"
#include "luaplus/Src/Modules/osprocess/posix/posix_spawn.c"
#include "luaplus/Src/Modules/osprocess/posix/spawn.c"
#endif

// struct
#include "luaplus/Src/Modules/struct/struct.c"

// uuid
#include "luaplus/Src/Modules/uuid/luuid.c"
#ifdef _WIN32
#include "luaplus/Src/Modules/uuid/wuuid.c"
#endif





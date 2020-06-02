#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

#if !defined(_MSC_VER)
#include <inttypes.h>
#endif /* _MSC_VER */

#ifdef __cplusplus
extern "C" {
#endif

LIST *
builtin_luastring(
	PARSE	*parse,
	LOL		*args,
	int		*jmp );

LIST *
builtin_luafile(
	PARSE	*parse,
	LOL		*args,
	int		*jmp );

int luahelper_taskadd(const char* taskscript, LOL* args);
int luahelper_taskisrunning(intptr_t taskid, int* returnValue);
void luahelper_taskcancel(intptr_t taskid);

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback);
#endif

int luahelper_push_linefilter(const char* actionName);
void luahelper_pop_linefilter();
const char* luahelper_linefilter(const char* line, size_t lineSize);

LIST* luahelper_call_script(const char* filename, LIST* args);

#ifdef __cplusplus
}
#endif

#endif

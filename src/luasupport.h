#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

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

int luahelper_taskadd(const char* taskscript);
int luahelper_taskisrunning(int taskid, int* returnValue);
void luahelper_taskcancel(int taskid);

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback);
#endif

int luahelper_push_linefilter(const char* actionName);
void luahelper_pop_linefilter();
const char* luahelper_linefilter(const char* line, size_t lineSize);

#ifdef __cplusplus
}
#endif

#endif

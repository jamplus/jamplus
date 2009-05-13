#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

#include "jam.h"
#include "lists.h"
#include "parse.h"
#include "compile.h"
#include "rules.h"
#include "variable.h"
#include "filesys.h"

#ifdef OS_NT
#include <windows.h>
#undef LoadString
#else
#include <dlfcn.h>
#endif

/* Declarations from lua.h. */
/*
** pseudo-indices
*/
#define LUA_REGISTRYINDEX	(-10000)
#define LUA_GLOBALSINDEX	(-10002)

typedef struct lua_State lua_State;

typedef int (*lua_CFunction) (lua_State *L);

/* type of numbers in Lua */
#define LUA_NUMBER double
typedef LUA_NUMBER lua_Number;

/* type for integer functions */
#define LUA_INTEGER int
typedef LUA_INTEGER lua_Integer;

/*
** basic types
*/
#define LUA_TNONE		(-1)

#define LUA_TNIL		0
#define LUA_TBOOLEAN		1
#define LUA_TLIGHTUSERDATA	2
#define LUA_TNUMBER		3
#define LUA_TSTRING		4
#define LUA_TTABLE		5
#define LUA_TFUNCTION		6
#define LUA_TUSERDATA		7
#define LUA_TTHREAD		8

void (*lua_close) (lua_State *L);

int   (*lua_gettop) (lua_State *L);
void  (*lua_settop) (lua_State *L, int idx);
void (*lua_pushvalue) (lua_State *L, int idx);

#define lua_isfunction(L,n)	(lua_type(L, (n)) == LUA_TFUNCTION)
#define lua_istable(L,n)	(lua_type(L, (n)) == LUA_TTABLE)
#define lua_isnil(L,n)		(lua_type(L, (n)) == LUA_TNIL)
#define lua_isboolean(L,n)	(lua_type(L, (n)) == LUA_TBOOLEAN)
int             (*lua_isnumber) (lua_State *L, int idx);
int             (*lua_isstring) (lua_State *L, int idx);
int             (*lua_type) (lua_State *L, int idx);

lua_Number      (*lua_tonumber) (lua_State *L, int idx);
int             (*lua_toboolean) (lua_State *L, int idx);
#define lua_tostring(L,i)	lua_tolstring(L, (i), NULL)
const char     *(*lua_tolstring) (lua_State *L, int idx, size_t *len);
size_t          (*lua_objlen) (lua_State *L, int idx);

void  (*lua_pushnil) (lua_State *L);
void  (*lua_pushnumber) (lua_State *L, lua_Number n);
void  (*lua_pushinteger) (lua_State *L, lua_Integer n);
void  (*lua_pushstring) (lua_State *L, const char *s);
void  (*lua_pushcclosure) (lua_State *L, lua_CFunction fn, int n);
void  (*lua_pushboolean) (lua_State *L, int b);

void  (*lua_gettable) (lua_State *L, int idx);
void  (*lua_getfield) (lua_State *L, int idx, const char *k);
void  (*lua_rawgeti) (lua_State *L, int idx, int n);
void  (*lua_createtable) (lua_State *L, int narr, int nrec);

void  (*lua_settable) (lua_State *L, int idx);
void  (*lua_setfield) (lua_State *L, int idx, const char *k);
void  (*lua_rawseti) (lua_State *L, int idx, int n);

int   (*lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (*lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);

int   (*lua_next) (lua_State *L, int idx);

#define lua_pop(L,n)		lua_settop(L, -(n)-1)

#define lua_newtable(L)		lua_createtable(L, 0, 0)

void (*luaL_openlibs) (lua_State *L);
int (*luaL_loadstring) (lua_State *L, const char *s);
int (*luaL_loadfile) (lua_State *L, const char *filename);
lua_State *(*luaL_newstate) (void);
int (*luaL_ref) (lua_State *L, int t);
void (*luaL_unref) (lua_State *L, int t, int ref);



/*****************************************************************************/
static lua_State *L;

static LIST *luahelper_addtolist(lua_State *L, LIST *list, int index)
{
	if (lua_isboolean(L, index))
		return list_new(list, lua_toboolean(L, index) ? "true" : "false", 0);

	if (lua_isnumber(L, index))
		return list_new(list, lua_tostring(L, index), 0);

	if (lua_isstring(L, index))
		return list_new(list, lua_tostring(L, index), 0);

	else if (lua_istable(L, index))
	{
		lua_pushnil(L);
		while (lua_next(L, index) != 0)
		{
			list = luahelper_addtolist(L, list, index + 2);
			lua_pop(L, 1);
		}
	}

	return list;
}


int LS_jam_setvar(lua_State *L)
{
	int numParams = lua_gettop(L);
	if (numParams < 2  ||  numParams > 3)
		return 0;

	if (!lua_isstring(L, 1))
		return 0;

	if (numParams == 2)
	{
		var_set(lua_tostring(L, 1), luahelper_addtolist(L, L0, 2), VAR_SET);
	}
	else
	{
		TARGET *t;

		if (!lua_isstring(L, 2))
			return 0;

		t = bindtarget(lua_tostring(L, 1));
		pushsettings(t->settings);
		var_set(lua_tostring(L, 2), luahelper_addtolist(L, L0, 3), VAR_SET);
		popsettings(t->settings);
	}

	return 0;
}


int LS_jam_getvar(lua_State *L)
{
	LIST *list;
	int index;

	int numParams = lua_gettop(L);
	if (numParams < 1  ||  numParams > 2)
		return 0;

	if (!lua_isstring(L, 1))
		return 0;

	if (numParams == 1)
	{
		list = var_get(lua_tostring(L, 1));
	}
	else
	{
		TARGET *t;

		if (!lua_isstring(L, 2))
			return 0;

		t = bindtarget(lua_tostring(L, 1));
		pushsettings(t->settings);
		list = var_get(lua_tostring(L, 2));
		popsettings(t->settings);
	}

	lua_newtable(L);
	index = 1;
	for (; list; list = list_next(list), ++index)
	{
		lua_pushnumber(L, index);
		lua_pushstring(L, list->string);
		lua_settable(L, -3);
	}

	return 1;
}


int LS_jam_evaluaterule(lua_State *L)
{
	LOL lol;
	int i;
	LIST *list;
	int index;

	int numParams = lua_gettop(L);
	if (numParams < 1)
		return 0;

	if (!lua_isstring(L, 1))
		return 0;

	lol_init(&lol);

	for (i = 0; i < numParams - 1; ++i)
	{
		lol_add(&lol, luahelper_addtolist(L, L0, 2 + i));
	}
	list = evaluate_rule(lua_tostring(L, 1), &lol, L0);
	lol_free(&lol);

	lua_newtable(L);
	index = 1;
	for (; list; list = list_next(list), ++index)
	{
		lua_pushnumber(L, index);
		lua_pushstring(L, list->string);
		lua_settable(L, -3);
	}

	return 1;
}


/*
*/

static LIST *lua_callhelper(int top, int ret)
{
	LIST *retList;
	int numParams;
	int i;

	if (ret != 0)
	{
		if (lua_isstring(L, -1))
		{
			printf("jam: Error compiling Lua code\n%s\n", lua_tostring(L, -1));
			exit(EXITBAD);
		}
		lua_pop(L, 1);
		return L0;
	}

	ret = lua_pcall(L, 0, -1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
		{
			printf("jam: Error running Lua code\n%s\n", lua_tostring(L, -1));
			exit(EXITBAD);
		}
		lua_pop(L, 1);
		return L0;
	}

	retList = L0;

	numParams = lua_gettop(L) - top;
	for (i = 1; i <= numParams; ++i)
	{
		retList = luahelper_addtolist(L, retList, top + i);
	}

	return retList;
}


static int pmain (lua_State *L)
{
	int top;
	int ret;

	luaL_openlibs(L);

	lua_pushcclosure(L, LS_jam_getvar, 0);
	lua_setfield(L, LUA_GLOBALSINDEX, "jam_getvar");
	lua_pushcclosure(L, LS_jam_setvar, 0);
	lua_setfield(L, LUA_GLOBALSINDEX, "jam_setvar");
	lua_pushcclosure(L, LS_jam_evaluaterule, 0);
	lua_setfield(L, LUA_GLOBALSINDEX, "jam_evaluaterule");

	top = lua_gettop(L);
	ret = luaL_loadstring(L, "require 'lanes'");
	lua_callhelper(top, ret);
	return 0;
}


static void* lua_loadsymbol(void* handle, const char* symbol)
{
#ifdef OS_NT
	return GetProcAddress(handle, symbol);
#else
	return dlsym(handle, symbol);
#endif
}


void lua_init()
{
	LIST *luaSharedLibrary;
#ifdef OS_NT
	HINSTANCE handle = NULL;
#else
	void* handle = NULL;
#endif

	if (L)
		return;

#ifdef _DEBUG
	luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.DEBUG");
#else
	luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.RELEASE");
#endif
	if (luaSharedLibrary)
	{
#ifdef OS_NT
		handle = LoadLibrary(luaSharedLibrary->string);
#else
		handle = dlopen(luaSharedLibrary->string, RTLD_LAZY);
#endif
	}
	if (!handle)
	{
		char fileName[4096];
		getprocesspath(fileName, 4096);

#ifdef OS_NT
#ifdef _DEBUG
		strcat(fileName, "lua/luaplus_1100.debug.dll");
#else
		strcat(fileName, "lua/luaplus_1100.dll");
#endif
		handle = LoadLibrary(fileName);
#else
#ifdef _DEBUG
		strcat(fileName, "/lua/luaplus_1100.debug.so");
#else
		strcat(fileName, "/lua/luaplus_1100.so");
#endif
		handle = dlopen(fileName, RTLD_LAZY);
#endif
		if (!handle)
		{
			printf("jam: Unable to find the LuaPlus shared library.\n");
			exit(EXITBAD);
		}
	}

	lua_close = (void (*)(lua_State *))lua_loadsymbol(handle, "lua_close");

	lua_gettop = (int (*)(lua_State *))lua_loadsymbol(handle, "lua_gettop");
	lua_settop = (void (*)(lua_State *, int))lua_loadsymbol(handle, "lua_settop");
	lua_pushvalue = (void (*)(lua_State *, int))lua_loadsymbol(handle, "lua_pushvalue");

	lua_isnumber = (int (*)(lua_State *, int))lua_loadsymbol(handle, "lua_isnumber");
	lua_isstring = (int (*)(lua_State *, int))lua_loadsymbol(handle, "lua_isstring");
	lua_type = (int (*)(lua_State *, int))lua_loadsymbol(handle, "lua_type");

	lua_tonumber = (lua_Number (*)(lua_State *, int))lua_loadsymbol(handle, "lua_tonumber");
	lua_toboolean = (int (*)(lua_State *, int))lua_loadsymbol(handle, "lua_toboolean");
	lua_tolstring = (const char *(*)(lua_State *, int, size_t *))lua_loadsymbol(handle, "lua_tolstring");
	lua_objlen = (size_t (*)(lua_State *, int))lua_loadsymbol(handle, "lua_objlen");

	lua_pushnil = (void (*) (lua_State *))lua_loadsymbol(handle, "lua_pushnil");
	lua_pushnumber = (void (*) (lua_State *, lua_Number))lua_loadsymbol(handle, "lua_pushnumber");
	lua_pushinteger = (void (*) (lua_State *, lua_Integer))lua_loadsymbol(handle, "lua_pushinteger");
	lua_pushstring = (void (*) (lua_State *, const char *))lua_loadsymbol(handle, "lua_pushstring");
	lua_pushcclosure = (void (*) (lua_State *, lua_CFunction, int))lua_loadsymbol(handle, "lua_pushcclosure");
	lua_pushboolean = (void (*)(lua_State *, int))lua_loadsymbol(handle, "lua_pushboolean");

	lua_gettable = (void (*) (lua_State *, int id))lua_loadsymbol(handle, "lua_gettable");
	lua_getfield = (void (*)(lua_State *, int, const char *))lua_loadsymbol(handle, "lua_getfield");
	lua_rawgeti = (void  (*) (lua_State *, int, int))lua_loadsymbol(handle, "lua_rawgeti");
	lua_createtable = (void (*)(lua_State *, int, int))lua_loadsymbol(handle, "lua_createtable");

	lua_settable = (void (*)(lua_State *, int))lua_loadsymbol(handle, "lua_settable");
	lua_setfield = (void (*)(lua_State *, int, const char *))lua_loadsymbol(handle, "lua_setfield");
	lua_rawseti = (void (*)(lua_State *, int, int))lua_loadsymbol(handle, "lua_rawseti");

	lua_pcall = (int (*)(lua_State *, int, int, int))lua_loadsymbol(handle, "lua_pcall");
	lua_cpcall = (int (*)(lua_State *, lua_CFunction, void *))lua_loadsymbol(handle, "lua_cpcall");

	lua_next = (int (*)(lua_State *, int))lua_loadsymbol(handle, "lua_next");

	luaL_openlibs = (void (*)(lua_State *))lua_loadsymbol(handle, "luaL_openlibs");
	luaL_loadstring = (int (*)(lua_State *, const char *))lua_loadsymbol(handle, "luaL_loadstring");
	luaL_loadfile = (int (*)(lua_State *, const char *))lua_loadsymbol(handle, "luaL_loadfile");
	luaL_newstate = (lua_State *(*)(void))lua_loadsymbol(handle, "luaL_newstate");
	luaL_ref = (int (*)(lua_State *, int))lua_loadsymbol(handle, "luaL_ref");
	luaL_unref = (void (*)(lua_State *, int, int))lua_loadsymbol(handle, "luaL_unref");

	L = luaL_newstate();
	lua_cpcall(L, &pmain, 0);
}


int luahelper_taskadd(const char* taskscript)
{
	int ret;
	int ref;
	size_t taskscriptlen = strlen(taskscript);
	char* newTaskScript;

	lua_init();

	lua_getfield(L, LUA_GLOBALSINDEX, "lanes");			/* lanes */
	lua_getfield(L, -1, "gen");							/* lanes gen */
	lua_pushstring(L, "*");								/* lanes gen * */

	newTaskScript = malloc( taskscriptlen + 1 );
	strncpy(newTaskScript, taskscript, taskscriptlen);
	newTaskScript[taskscriptlen] = 0;
	ret = luaL_loadstring(L, newTaskScript);			/* lanes gen * script */
	free(newTaskScript);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error compiling Lua lane\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return -1;
	}

	ret = lua_pcall(L, 2, 1, 0);						/* lanes lane_h */
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error creating Lua lane\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return -1;
	}

	if (!lua_isfunction(L, -1))							/* lanes lane_h */
	{
		lua_pop(L, 2);
		return -1;
	}

	ret = lua_pcall(L, 0, 1, 0);						/* lanes ret */
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error calling Lua lane\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return -1;
	}

	ref = luaL_ref(L, LUA_REGISTRYINDEX);
	lua_pop(L, 1);
	return ref;
}


int luahelper_taskisrunning(int taskid)
{
	const char* status;
	lua_init();

	lua_rawgeti(L, LUA_REGISTRYINDEX, taskid);		/* lane_h */
	lua_getfield(L, -1, "status");					/* lane_h status */

	status = lua_tostring(L, -1);
	if (strcmp(status, "done") == 0)
	{
		lua_pop(L, 2);
		luaL_unref(L, LUA_REGISTRYINDEX, taskid);
		return 0;
	}
	else if (strcmp(status, "error") == 0  ||  strcmp(status, "cancelled") == 0)
	{
		int ret;

		lua_pop(L, 1);								/* lane_h */
		lua_getfield(L, -1, "join");				/* lane_h join(function) */
		lua_pushvalue(L, -2);						/* lane_h join(function) lane_h */
		ret = lua_pcall(L, 1, 3, 0);				/* lane_h nil err stack_tbl */
		if (ret != 0)
		{
			if (lua_isstring(L, -1))
				printf("jam: Error in Lua lane\n%s\n");
			lua_pop(L, 2);
			return 1;
		}

		lua_pop(L, 4);								/* */

		luaL_unref(L, LUA_REGISTRYINDEX, taskid);
		return 1;
	}

	lua_pop(L, 2);
	return 1;
}


void luahelper_taskcancel(int taskid)
{
	int ret;

	lua_init();

	lua_rawgeti(L, LUA_REGISTRYINDEX, taskid);
	lua_pushvalue(L, -1);
	lua_getfield(L, -1, "cancel");
	lua_pushvalue(L, -2);
	lua_pushnumber(L, 0);
	lua_pushboolean(L, 1);

	ret = lua_pcall(L, 3, -1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error running Lua task.cancel\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return;
	}

	lua_pop(L, 1);
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT

int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback)
{
	int ret;

	lua_init();

	lua_getfield(L, LUA_GLOBALSINDEX, callback);
	if (!lua_isfunction(L, -1))
	{
		lua_pop(L, 1);
		printf("jam: Error calling Lua md5 callback '%s'.\n", callback);
		memset(sum, 0, sizeof(MD5SUM));
		return 0;
	}

	lua_pushstring(L, filename);
	ret = lua_pcall(L, 1, 1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error running Lua md5 callback\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 1);
		memset(sum, 0, sizeof(MD5SUM));
		return 0;
	}

	if (lua_isnil(L, -1))
	{
		memset(sum, 0, sizeof(MD5SUM));
		lua_pop(L, 1);
		return 0;
	}

	if (!lua_isstring(L, -1)  ||  lua_objlen(L, -1) != sizeof(MD5SUM))
	{
		printf("jam: Error running Lua md5 callback '%s'.\n", callback);
		memset(sum, 0, sizeof(MD5SUM));
		lua_pop(L, 1);
		return 0;
	}

	memcpy(sum, lua_tostring(L, -1), sizeof(MD5SUM));
	lua_pop(L, 1);
	return 1;
}

#endif


LIST *
builtin_luastring(
		  PARSE	*parse,
		  LOL		*args,
		  int		*jmp)
{
    int top;
    int ret;

    LIST *l = lol_get(args, 0);
    if (!l)
    {
	printf("jam: No argument passed to LuaString\n");
	exit(EXITBAD);
    }
    lua_init();
    top = lua_gettop(L);
    ret = luaL_loadstring(L, l->string);
    return lua_callhelper(top, ret);
}


LIST *
builtin_luafile(
		PARSE	*parse,
		LOL		*args,
		int		*jmp)
{
    int top;
    int ret;
    LIST *l2;
    int index = 0;

    LIST *l = lol_get(args, 0);
    if (!l) {
	printf("jam: No argument passed to LuaFile\n");
	exit(EXITBAD);
    }
    lua_init();
    top = lua_gettop(L);
    lua_newtable(L);
    for (l2 = lol_get(args, 1); l2; l2 = l2->next) {
	lua_pushstring(L, l2->string);
	lua_rawseti(L, -2, ++index);
    }
    lua_setfield(L, LUA_GLOBALSINDEX, "arg");
    ret = luaL_loadfile(L, l->string);
    return lua_callhelper(top, ret);
}


void lua_shutdown()
{
    if (L)
    {
	lua_close(L);
	L = NULL;
    }
}

#endif

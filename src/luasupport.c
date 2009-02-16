#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

#include "jam.h"
#include "lists.h"
#include "parse.h"
#include "compile.h"
#include "rules.h"
#include "variable.h"

#include <windows.h>
#undef LoadString

/* Declarations from lua.h. */
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

void  (*lua_getfield) (lua_State *L, int idx, const char *k);
void  (*lua_createtable) (lua_State *L, int narr, int nrec);

void  (*lua_settable) (lua_State *L, int idx);
void  (*lua_setfield) (lua_State *L, int idx, const char *k);

int   (*lua_pcall) (lua_State *L, int nargs, int nresults, int errfunc);
int   (*lua_cpcall) (lua_State *L, lua_CFunction func, void *ud);

int   (*lua_next) (lua_State *L, int idx);

#define lua_pop(L,n)		lua_settop(L, -(n)-1)

#define lua_newtable(L)		lua_createtable(L, 0, 0)

void (*luaL_openlibs) (lua_State *L);
int (*luaL_loadstring) (lua_State *L, const char *s);
int (*luaL_loadfile) (lua_State *L, const char *filename);
lua_State *(*luaL_newstate) (void);



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
	ret = luaL_loadstring(L, "require 'task'");
	lua_callhelper(top, ret);
	return 0;
}


void lua_init()
{
	LIST *luaSharedLibrary;
	HINSTANCE hInstance = NULL;
	char *ptr;

	if (L)
		return;

#ifdef _DEBUG
	luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.DEBUG");
#else
	luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.RELEASE");
#endif
	if (luaSharedLibrary)
	{
		hInstance = LoadLibrary(luaSharedLibrary->string);
	}
	if (!hInstance)
	{
		char fileName[_MAX_PATH];
		GetModuleFileName(NULL, fileName, _MAX_PATH);

		ptr = strrchr(fileName, '\\');
		if (!ptr)
			ptr = strrchr(fileName, '/');
		if (!ptr)
		{
			printf("jam: Error loading Lua shared library: %s\n", fileName);
			exit(EXITBAD);
		}
		ptr++;
#ifdef _DEBUG
		strcpy(ptr, "lua\\LuaPlus_1100.debug.dll");
#else
		strcpy(ptr, "lua\\LuaPlus_1100.dll");
#endif
		hInstance = LoadLibrary(fileName);
		if (!hInstance)
		{
			printf("jam: Unable to find the LuaPlus DLL.\n");
			exit(EXITBAD);
		}
	}

	lua_close = (void (*)(lua_State *))GetProcAddress(hInstance, "lua_close");

	lua_gettop = (int (*)(lua_State *))GetProcAddress(hInstance, "lua_gettop");
	lua_settop = (void (*)(lua_State *, int))GetProcAddress(hInstance, "lua_settop");

	lua_isnumber = (int (*)(lua_State *, int))GetProcAddress(hInstance, "lua_isnumber");
	lua_isstring = (int (*)(lua_State *, int))GetProcAddress(hInstance, "lua_isstring");
	lua_type = (int (*)(lua_State *, int))GetProcAddress(hInstance, "lua_type");

	lua_tonumber = (lua_Number (*)(lua_State *, int))GetProcAddress(hInstance, "lua_tonumber");
	lua_toboolean = (int (*)(lua_State *, int))GetProcAddress(hInstance, "lua_toboolean");
	lua_tolstring = (const char *(*)(lua_State *, int, size_t *))GetProcAddress(hInstance, "lua_tolstring");
	lua_objlen = (size_t (*)(lua_State *, int))GetProcAddress(hInstance, "lua_objlen");

	lua_pushnil = (void (*) (lua_State *))GetProcAddress(hInstance, "lua_pushnil");
	lua_pushnumber = (void (*) (lua_State *, lua_Number))GetProcAddress(hInstance, "lua_pushnumber");
	lua_pushinteger = (void (*) (lua_State *, lua_Integer))GetProcAddress(hInstance, "lua_pushinteger");
	lua_pushstring = (void (*) (lua_State *, const char *))GetProcAddress(hInstance, "lua_pushstring");
	lua_pushcclosure = (void (*) (lua_State *, lua_CFunction, int))GetProcAddress(hInstance, "lua_pushcclosure");

	lua_getfield = (void (*)(lua_State *, int, const char *))GetProcAddress(hInstance, "lua_getfield");
	lua_createtable = (void (*)(lua_State *, int, int))GetProcAddress(hInstance, "lua_createtable");

	lua_settable = (void (*)(lua_State *, int))GetProcAddress(hInstance, "lua_settable");
	lua_setfield = (void (*)(lua_State *, int, const char *))GetProcAddress(hInstance, "lua_setfield");

	lua_pcall = (int (*)(lua_State *, int, int, int))GetProcAddress(hInstance, "lua_pcall");
	lua_cpcall = (int (*)(lua_State *, lua_CFunction, void *))GetProcAddress(hInstance, "lua_cpcall");

	lua_next = (int (*)(lua_State *, int))GetProcAddress(hInstance, "lua_next");

	luaL_openlibs = (void (*)(lua_State *))GetProcAddress(hInstance, "luaL_openlibs");
	luaL_loadstring = (int (*)(lua_State *, const char *))GetProcAddress(hInstance, "luaL_loadstring");
	luaL_loadfile = (int (*)(lua_State *, const char *))GetProcAddress(hInstance, "luaL_loadfile");
	luaL_newstate = (lua_State *(*)(void))GetProcAddress(hInstance, "luaL_newstate");

	L = luaL_newstate();
	lua_cpcall(L, &pmain, 0);
}


int luahelper_taskadd(const char* taskscript)
{
	int ret;

	lua_init();

	lua_getfield(L, LUA_GLOBALSINDEX, "task");
	lua_getfield(L, -1, "create");
	lua_pushstring(L, taskscript);

	ret = lua_pcall(L, 1, -1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error creating Lua task\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return -1;
	}

	if (lua_isnumber(L, -1))
	{
		lua_Number ret = lua_tonumber(L, -1);
		lua_pop(L, 2);
		return (int)ret;
	}

	lua_pop(L, 2);
	return -1;
}


int luahelper_taskisrunning(int taskid)
{
	int ret;

	lua_init();

	lua_getfield(L, LUA_GLOBALSINDEX, "task");
	lua_getfield(L, -1, "isrunning");
	lua_pushinteger(L, taskid);

	ret = lua_pcall(L, 1, -1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error testing Lua task.isrunning\n%s\n", lua_tostring(L, -1));
		lua_pop(L, 2);
		return -1;
	}

	if (lua_isboolean(L, -1))
	{
		int ret = lua_toboolean(L, -1);
		lua_pop(L, 2);
		return ret;
	}

	lua_pop(L, 2);
	return 0;
}


void luahelper_taskcancel(int taskid)
{
	int ret;

	lua_init();

	lua_getfield(L, LUA_GLOBALSINDEX, "task");
	lua_getfield(L, -1, "cancel");
	lua_pushinteger(L, taskid);

	ret = lua_pcall(L, 1, -1, 0);
	if (ret != 0)
	{
		if (lua_isstring(L, -1))
			printf("jam: Error testing Lua task.cancel\n%s\n", lua_tostring(L, -1));
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

	LIST *l = lol_get(args, 0);
	if (!l)
	{
		printf("jam: No argument passed to LuaFile\n");
		exit(EXITBAD);
	}
	lua_init();
	top = lua_gettop(L);
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

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

#include "jam.h"
#include "lists.h"
#include "parse.h"
#include "scan.h"
#include "compile.h"
#include "rules.h"
#include "variable.h"
#include "filesys.h"
#include "expand.h"

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
#define LUA_REGISTRYINDEX    (-10000)
#define LUA_GLOBALSINDEX    (-10002)

typedef struct ls_lua_State ls_lua_State;

typedef int (*ls_lua_CFunction) (ls_lua_State *L);

/* type of numbers in Lua */
#define LUA_NUMBER double
typedef LUA_NUMBER ls_lua_Number;

/* type for integer functions */
#define LUA_INTEGER int
typedef LUA_INTEGER ls_lua_Integer;

/*
** basic types
*/
#define LUA_TNONE        (-1)

#define LUA_TNIL        0
#define LUA_TBOOLEAN        1
#define LUA_TLIGHTUSERDATA    2
#define LUA_TNUMBER        3
#define LUA_TSTRING        4
#define LUA_TTABLE        5
#define LUA_TFUNCTION        6
#define LUA_TUSERDATA        7
#define LUA_TTHREAD        8

void (*ls_lua_close) (ls_lua_State *L);

int   (*ls_lua_gettop) (ls_lua_State *L);
void  (*ls_lua_settop) (ls_lua_State *L, int idx);
void (*ls_lua_pushvalue) (ls_lua_State *L, int idx);
void (*ls_lua_remove) (ls_lua_State *L, int idx);

#define ls_lua_isfunction(L,n)    (ls_lua_type(L, (n)) == LUA_TFUNCTION)
#define ls_lua_istable(L,n)    (ls_lua_type(L, (n)) == LUA_TTABLE)
#define ls_lua_isnil(L,n)        (ls_lua_type(L, (n)) == LUA_TNIL)
#define ls_lua_isboolean(L,n)    (ls_lua_type(L, (n)) == LUA_TBOOLEAN)
int             (*ls_lua_isnumber) (ls_lua_State *L, int idx);
int             (*ls_lua_isstring) (ls_lua_State *L, int idx);
int             (*ls_lua_isuserdata) (ls_lua_State *L, int idx);
int             (*ls_lua_type) (ls_lua_State *L, int idx);

ls_lua_Number      (*ls_lua_tonumber) (ls_lua_State *L, int idx);
int             (*ls_lua_toboolean) (ls_lua_State *L, int idx);
#define ls_lua_tostring(L,i)    ls_lua_tolstring(L, (i), NULL)
const char     *(*ls_lua_tolstring) (ls_lua_State *L, int idx, size_t *len);
size_t          (*ls_lua_objlen) (ls_lua_State *L, int idx);

void  (*ls_lua_pushnil) (ls_lua_State *L);
void  (*ls_lua_pushnumber) (ls_lua_State *L, ls_lua_Number n);
void  (*ls_lua_pushinteger) (ls_lua_State *L, ls_lua_Integer n);
void  (*ls_lua_pushstring) (ls_lua_State *L, const char *s);
void  (*ls_lua_pushlstring) (ls_lua_State *L, const char *s, size_t l);
void  (*ls_lua_pushcclosure) (ls_lua_State *L, ls_lua_CFunction fn, int n);
void  (*ls_lua_pushboolean) (ls_lua_State *L, int b);

void  (*ls_lua_gettable) (ls_lua_State *L, int idx);
void  (*ls_lua_getfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_rawgeti) (ls_lua_State *L, int idx, int n);
void  (*ls_lua_createtable) (ls_lua_State *L, int narr, int nrec);

void  (*ls_lua_settable) (ls_lua_State *L, int idx);
void  (*ls_lua_setfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_rawseti) (ls_lua_State *L, int idx, int n);

int   (*ls_lua_pcall) (ls_lua_State *L, int nargs, int nresults, int errfunc);
int   (*ls_lua_cpcall) (ls_lua_State *L, ls_lua_CFunction func, void *ud);

int   (*ls_lua_next) (ls_lua_State *L, int idx);

#define ls_lua_pop(L,n)        ls_lua_settop(L, -(n)-1)

#define ls_lua_newtable(L)        ls_lua_createtable(L, 0, 0)

void (*ls_luaL_openlibs) (ls_lua_State *L);
int (*ls_luaL_loadstring) (ls_lua_State *L, const char *s);
int (*ls_luaL_loadfile) (ls_lua_State *L, const char *filename);
ls_lua_State *(*ls_luaL_newstate) (void);
int (*ls_luaL_ref) (ls_lua_State *L, int t);
void (*ls_luaL_unref) (ls_lua_State *L, int t, int ref);



/*****************************************************************************/
static ls_lua_State *L;

static LIST *luahelper_addtolist(ls_lua_State *L, LIST *list, int index)
{
    if (ls_lua_isboolean(L, index))
        return list_append(list, ls_lua_toboolean(L, index) ? "true" : "false", 0);

    if (ls_lua_isnumber(L, index))
        return list_append(list, ls_lua_tostring(L, index), 0);

    if (ls_lua_isstring(L, index))
        return list_append(list, ls_lua_tostring(L, index), 0);

    else if (ls_lua_istable(L, index))
    {
        ls_lua_pushnil(L);
        while (ls_lua_next(L, index) != 0)
        {
            list = luahelper_addtolist(L, list, index + 2);
            ls_lua_pop(L, 1);
        }
    }

    return list;
}


int LS_jam_setvar(ls_lua_State *L)
{
    int numParams = ls_lua_gettop(L);
    if (numParams < 2  ||  numParams > 3)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    if (numParams == 2)
    {
        var_set(ls_lua_tostring(L, 1), luahelper_addtolist(L, L0, 2), VAR_SET);
    }
    else
    {
        TARGET *t;

        if (!ls_lua_isstring(L, 2))
            return 0;

        t = bindtarget(ls_lua_tostring(L, 1));
        pushsettings(t->settings);
        var_set(ls_lua_tostring(L, 2), luahelper_addtolist(L, L0, 3), VAR_SET);
        popsettings(t->settings);
    }

    return 0;
}


int LS_jam_getvar(ls_lua_State *L)
{
    LIST *list;
    LISTITEM* item;
    int index;

    int numParams = ls_lua_gettop(L);
    if (numParams < 1  ||  numParams > 2)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    if (numParams == 1)
    {
        list = var_get(ls_lua_tostring(L, 1));
    }
    else
    {
        TARGET *t;

        if (!ls_lua_isstring(L, 2))
            return 0;

        t = bindtarget(ls_lua_tostring(L, 1));
        pushsettings(t->settings);
        list = var_get(ls_lua_tostring(L, 2));
        popsettings(t->settings);
    }

    ls_lua_newtable(L);
    index = 1;
    for (item = list_first(list); item; item = list_next(item), ++index)
    {
        ls_lua_pushnumber(L, index);
        ls_lua_pushstring(L, list_value(item));
        ls_lua_settable(L, -3);
    }

    return 1;
}


int LS_jam_evaluaterule(ls_lua_State *L)
{
    LOL lol;
    int i;
    LIST *list;
    LISTITEM* item;
    int index;

    int numParams = ls_lua_gettop(L);
    if (numParams < 1)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    lol_init(&lol);

    for (i = 0; i < numParams - 1; ++i)
    {
        lol_add(&lol, luahelper_addtolist(L, L0, 2 + i));
    }
    list = evaluate_rule(ls_lua_tostring(L, 1), &lol, L0);
    lol_free(&lol);

    ls_lua_newtable(L);
    index = 1;
    for (item = list_first(list); item; item = list_next(item), ++index)
    {
        ls_lua_pushnumber(L, index);
        ls_lua_pushstring(L, list_value(item));
        ls_lua_settable(L, -3);
    }

    return 1;
}


int LS_jam_expand(ls_lua_State *L)
{
    LIST *list = L0;
    LISTITEM* item;
    int index;

    int numParams = ls_lua_gettop(L);
    if (numParams < 1  ||  numParams > 1)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    {
        LOL lol;
        const char* src = ls_lua_tostring(L, 1);
        lol_init(&lol);
        list = var_expand(L0, src, src + strlen(src), &lol, 0);
    }

    ls_lua_newtable(L);
    index = 1;
    for (item = list_first(list); item; item = list_next(item), ++index)
    {
        ls_lua_pushnumber(L, index);
        ls_lua_pushstring(L, list_value(item));
        ls_lua_settable(L, -3);
    }

    return 1;
}


int LS_jam_parse(ls_lua_State *L)
{
    int numParams = ls_lua_gettop(L);
    if (numParams < 1  ||  numParams > 1)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    {
        const char* src = ls_lua_tostring(L, 1);
        const char* ptr = src;
        const char* startPtr;
        char** lines;
        int numberOfLines = 1;
        int status;

        while (*ptr) {
            if (*ptr == '\n') {
                ++numberOfLines;
            }
            ++ptr;
        }
        lines = malloc(sizeof(char*) * (numberOfLines + 1));
        numberOfLines = 0;
        startPtr = ptr = src;
        while (1) {
            if (*ptr == '\n'  ||  *ptr == 0) {
                char* line;
                if (*ptr == '\n')
                    ++ptr;
                line = malloc(ptr - startPtr + 1);
                memcpy(line, startPtr, ptr - startPtr);
                line[ptr - startPtr] = 0;
                startPtr = ptr;
                lines[numberOfLines++] = line;
                if (*ptr == 0)
                    break;
            } else {
                ++ptr;
            }
        }
        lines[numberOfLines] = 0;
        parse_lines(lines[0], lines);

        status = yyanyerrors();

        while (numberOfLines > 0) {
            free(lines[--numberOfLines]);
        }
        free(lines);

        if (status) {
            struct ls_lua_Debug ar;
            if (ls_lua_getstack(L, 1, &ar)) {
                ls_lua_getinfo(L, "nSl", &ar);
                int hi = 5;
            }

            printf("jam: Error parsing Jam code near %s[%d].\n", ar.short_src, ar.currentline);
            exit(EXITBAD);
        }
    }

    return 0;
}


int LS_jam_print(ls_lua_State *L)
{
    int numParams = ls_lua_gettop(L);
    if (numParams < 1  ||  numParams > 1)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    puts(ls_lua_tostring(L, 1));

    return 0;
}


/*
*/

static LIST *ls_lua_callhelper(int top, int ret)
{
    LIST *retList;
    int numParams;
    int i;

    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
        {
            printf("jam: Error compiling Lua code\n%s\n", ls_lua_tostring(L, -1));
            exit(EXITBAD);
        }
        ls_lua_pop(L, 1);
        return L0;
    }

    ret = ls_lua_pcall(L, 0, -1, 0);
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
        {
            printf("jam: Error running Lua code\n%s\n", ls_lua_tostring(L, -1));
            exit(EXITBAD);
        }
        ls_lua_pop(L, 1);
        return L0;
    }

    retList = L0;

    numParams = ls_lua_gettop(L) - top;
    for (i = 1; i <= numParams; ++i)
    {
        retList = luahelper_addtolist(L, retList, top + i);
    }

    return retList;
}


static int pmain (ls_lua_State *L)
{
    int top;
    int ret;

    ls_luaL_openlibs(L);

    ls_lua_pushcclosure(L, LS_jam_getvar, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_getvar");
    ls_lua_pushcclosure(L, LS_jam_setvar, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_setvar");
    ls_lua_pushcclosure(L, LS_jam_evaluaterule, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_evaluaterule");
    ls_lua_pushcclosure(L, LS_jam_expand, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_expand");
    ls_lua_pushcclosure(L, LS_jam_parse, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_parse");
    ls_lua_pushcclosure(L, LS_jam_print, 0);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "jam_print");

    top = ls_lua_gettop(L);
    ret = ls_luaL_loadstring(L, "lanes = require 'lanes'");
    ls_lua_callhelper(top, ret);
    ret = ls_luaL_loadstring(L, "lanes.configure()");
    ls_lua_callhelper(top, ret);

    ls_lua_newtable(L);
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "LineFilters");

    return 0;
}


static void* ls_lua_loadsymbol(void* handle, const char* symbol)
{
#ifdef OS_NT
    return GetProcAddress(handle, symbol);
#else
    return dlsym(handle, symbol);
#endif
}


void ls_lua_init()
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
    if (list_first(luaSharedLibrary))
    {
#ifdef OS_NT
        handle = LoadLibrary(list_value(list_first(luaSharedLibrary)));
#else
        handle = dlopen(list_value(list_first(luaSharedLibrary)), RTLD_LAZY | RTLD_GLOBAL);
#endif
    }
    if (!handle)
    {
        char fileName[4096];
        getprocesspath(fileName, 4096);

#ifdef OS_NT
#ifdef _DEBUG
        strcat(fileName, "/lua/lua51_debug.dll");
#else
        strcat(fileName, "/lua/lua51.dll");
#endif
        handle = LoadLibrary(fileName);
#else
#ifdef _DEBUG
        strcat(fileName, "/lua/lua51_debug.so");
#else
        strcat(fileName, "/lua/lua51.so");
#endif
        handle = dlopen(fileName, RTLD_LAZY | RTLD_GLOBAL);
#endif
        if (!handle)
        {
            printf("jam: Unable to find the LuaPlus shared library.\n");
            exit(EXITBAD);
        }
    }

    ls_lua_close = (void (*)(ls_lua_State *))ls_lua_loadsymbol(handle, "lua_close");

    ls_lua_gettop = (int (*)(ls_lua_State *))ls_lua_loadsymbol(handle, "lua_gettop");
    ls_lua_settop = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_settop");
    ls_lua_pushvalue = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_pushvalue");
    ls_lua_remove = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_remove");

    ls_lua_isnumber = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isnumber");
    ls_lua_isstring = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isstring");
    ls_lua_isuserdata = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isuserdata");
    ls_lua_type = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_type");

    ls_lua_tonumber = (ls_lua_Number (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_tonumber");
    ls_lua_toboolean = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_toboolean");
    ls_lua_tolstring = (const char *(*)(ls_lua_State *, int, size_t *))ls_lua_loadsymbol(handle, "lua_tolstring");
    ls_lua_objlen = (size_t (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_objlen");

    ls_lua_pushnil = (void (*) (ls_lua_State *))ls_lua_loadsymbol(handle, "lua_pushnil");
    ls_lua_pushnumber = (void (*) (ls_lua_State *, ls_lua_Number))ls_lua_loadsymbol(handle, "lua_pushnumber");
    ls_lua_pushinteger = (void (*) (ls_lua_State *, ls_lua_Integer))ls_lua_loadsymbol(handle, "lua_pushinteger");
    ls_lua_pushstring = (void (*) (ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "lua_pushstring");
    ls_lua_pushlstring = (void (*) (ls_lua_State *, const char *, size_t))ls_lua_loadsymbol(handle, "lua_pushlstring");
    ls_lua_pushcclosure = (void (*) (ls_lua_State *, ls_lua_CFunction, int))ls_lua_loadsymbol(handle, "lua_pushcclosure");
    ls_lua_pushboolean = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_pushboolean");

    ls_lua_gettable = (void (*) (ls_lua_State *, int id))ls_lua_loadsymbol(handle, "lua_gettable");
    ls_lua_getfield = (void (*)(ls_lua_State *, int, const char *))ls_lua_loadsymbol(handle, "lua_getfield");
    ls_lua_rawgeti = (void  (*) (ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_rawgeti");
    ls_lua_createtable = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_createtable");

    ls_lua_settable = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_settable");
    ls_lua_setfield = (void (*)(ls_lua_State *, int, const char *))ls_lua_loadsymbol(handle, "lua_setfield");
    ls_lua_rawseti = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_rawseti");

    ls_lua_pcall = (int (*)(ls_lua_State *, int, int, int))ls_lua_loadsymbol(handle, "lua_pcall");
    ls_lua_cpcall = (int (*)(ls_lua_State *, ls_lua_CFunction, void *))ls_lua_loadsymbol(handle, "lua_cpcall");

    ls_lua_next = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_next");

    ls_luaL_openlibs = (void (*)(ls_lua_State *))ls_lua_loadsymbol(handle, "luaL_openlibs");
    ls_luaL_loadstring = (int (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "luaL_loadstring");
    ls_luaL_loadfile = (int (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "luaL_loadfile");
    ls_luaL_newstate = (ls_lua_State *(*)(void))ls_lua_loadsymbol(handle, "luaL_newstate");
    ls_luaL_ref = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "luaL_ref");
    ls_luaL_unref = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "luaL_unref");

    L = ls_luaL_newstate();
    ls_lua_cpcall(L, &pmain, 0);
}


int luahelper_taskadd(const char* taskscript)
{
    int ret;
    int ref;
    size_t taskscriptlen = strlen(taskscript);
    char* newTaskScript;

    ls_lua_init();

    ls_lua_getfield(L, LUA_GLOBALSINDEX, "lanes");            /* lanes */
    ls_lua_getfield(L, -1, "gen");                            /* lanes gen */
    ls_lua_pushstring(L, "*");                                /* lanes gen * */

    newTaskScript = malloc( taskscriptlen + 1 );
    strncpy(newTaskScript, taskscript, taskscriptlen);
    newTaskScript[taskscriptlen] = 0;
    ret = ls_luaL_loadstring(L, newTaskScript);            /* lanes gen * script */
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            printf("jam: Error compiling Lua lane\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_pop(L, 2);
        printf("%s\n", newTaskScript);
        free(newTaskScript);
        return -1;
    }

    free(newTaskScript);
    ret = ls_lua_pcall(L, 2, 1, 0);                        /* lanes lane_h */
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            printf("jam: Error creating Lua lane\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_pop(L, 2);
        return -1;
    }

    if (!ls_lua_isfunction(L, -1))                            /* lanes lane_h */
    {
        ls_lua_pop(L, 2);
        return -1;
    }

    ret = ls_lua_pcall(L, 0, 1, 0);                        /* lanes ret */
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            printf("jam: Error calling Lua lane\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_pop(L, 2);
        return -1;
    }

    ref = ls_luaL_ref(L, LUA_REGISTRYINDEX);
    ls_lua_pop(L, 1);
    return ref;
}


int luahelper_taskisrunning(int taskid, int* returnValue)
{
    const char* status;
    ls_lua_init();

    ls_lua_rawgeti(L, LUA_REGISTRYINDEX, taskid);        /* lane_h */
    if (!ls_lua_isuserdata(L, -1))
    {
        *returnValue = 1;
        ls_lua_pop(L, 1);
        return 0;
    }
    ls_lua_getfield(L, -1, "status");                    /* lane_h status */

    status = ls_lua_tostring(L, -1);
    if (strcmp(status, "done") == 0)
    {
        int ret;

        ls_lua_pop(L, 1);                                /* lane_h */
        ls_lua_getfield(L, -1, "join");                    /* lane_h join(function) */
        ls_lua_pushvalue(L, -2);                        /* lane_h join(function) lane_h */
        ret = ls_lua_pcall(L, 1, 1, 0);                    /* lane_h ret */
        if (ret != 0)
        {
            if (ls_lua_isstring(L, -1))
                printf("jam: Error in Lua lane\n%s\n", ls_lua_tostring(L, -1));
            *returnValue = 1;
        }
        if (ls_lua_isnumber(L, -1))
            *returnValue = (int)ls_lua_tonumber(L, -1);
        else
            *returnValue = 0;
        ls_lua_pop(L, 2);
        ls_luaL_unref(L, LUA_REGISTRYINDEX, taskid);
        return 0;
    }
    else if (strcmp(status, "error") == 0  ||  strcmp(status, "cancelled") == 0)
    {
        int ret;

        *returnValue = 1;

        ls_lua_pop(L, 1);                                /* lane_h */
        ls_lua_getfield(L, -1, "join");                    /* lane_h join(function) */
        ls_lua_pushvalue(L, -2);                        /* lane_h join(function) lane_h */
        ret = ls_lua_pcall(L, 1, 3, 0);                    /* lane_h nil err stack_tbl */
        if (ret != 0)
        {
            if (ls_lua_isstring(L, -1))
                printf("jam: Error in Lua lane\n%s\n", ls_lua_tostring(L, -1));
            ls_lua_pop(L, 2);
            return 0;
        }

        if (ls_lua_isstring(L, -2))
        {
            printf("jam: Error in Lua lane\n%s\n", ls_lua_tostring(L, -2));
        }

        ls_lua_pop(L, 4);                                /* */

        ls_luaL_unref(L, LUA_REGISTRYINDEX, taskid);
        return 0;
    }

    ls_lua_pop(L, 2);
    return 1;
}


void luahelper_taskcancel(int taskid)
{
    int ret;

    ls_lua_init();

    ls_lua_rawgeti(L, LUA_REGISTRYINDEX, taskid);
    ls_lua_pushvalue(L, -1);
    ls_lua_getfield(L, -1, "cancel");
    ls_lua_pushvalue(L, -2);
    ls_lua_pushnumber(L, 0);
    ls_lua_pushboolean(L, 1);

    ret = ls_lua_pcall(L, 3, -1, 0);
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            printf("jam: Error running Lua task.cancel\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_pop(L, 2);
        return;
    }

    ls_lua_pop(L, 1);
}


static int linefilter_stack_position = -1;

int luahelper_push_linefilter(const char* actionName) {
    ls_lua_init();

    ls_lua_getfield(L, LUA_GLOBALSINDEX, "LineFilters");    /* LineFilters */
    ls_lua_getfield(L, -1, actionName);                        /* LineFilters function */
    if (!ls_lua_isfunction(L, -1)) {
        ls_lua_pop(L, 2);
        return 0;
    }
    ls_lua_remove(L, -2);
    linefilter_stack_position = ls_lua_gettop(L);
    return 1;
}


void luahelper_pop_linefilter() {
    if (linefilter_stack_position == -1)
        return;

    ls_lua_remove(L, linefilter_stack_position);
    linefilter_stack_position = -1;
}


const char* luahelper_linefilter(const char* line, size_t lineSize) {
    int ret;
    int top;
    char* out;

    if (linefilter_stack_position == -1) {
        fprintf(stderr, "jam: Line filter access not enabled.\n");
        exit(1);
    }

    ls_lua_init();

    top = ls_lua_gettop(L);
    ls_lua_pushvalue(L, linefilter_stack_position);
    ls_lua_pushlstring(L, line, lineSize);                    /* function line */
    ret = ls_lua_pcall(L, 1, 1, 0);
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            fprintf(stderr, "jam: Error running line filter.\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_settop(L, top);
        return NULL;
    }

    out = malloc(ls_lua_objlen(L, -1) + 1);
    strcpy(out, ls_lua_tostring(L, -1));
    ls_lua_settop(L, top);

    return out;
}


#ifdef OPT_BUILTIN_MD5CACHE_EXT

int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback)
{
    int ret;

    ls_lua_init();

    ls_lua_getfield(L, LUA_GLOBALSINDEX, callback);
    if (!ls_lua_isfunction(L, -1))
    {
        ls_lua_pop(L, 1);
        printf("jam: Error calling Lua md5 callback '%s'.\n", callback);
        memset(sum, 0, sizeof(MD5SUM));
        return 0;
    }

    ls_lua_pushstring(L, filename);
    ret = ls_lua_pcall(L, 1, 1, 0);
    if (ret != 0)
    {
        if (ls_lua_isstring(L, -1))
            printf("jam: Error running Lua md5 callback\n%s\n", ls_lua_tostring(L, -1));
        ls_lua_pop(L, 1);
        memset(sum, 0, sizeof(MD5SUM));
        return 0;
    }

    if (ls_lua_isnil(L, -1))
    {
        memset(sum, 0, sizeof(MD5SUM));
        ls_lua_pop(L, 1);
        return 0;
    }

    if (!ls_lua_isstring(L, -1)  ||  ls_lua_objlen(L, -1) != sizeof(MD5SUM))
    {
        printf("jam: Error running Lua md5 callback '%s'.\n", callback);
        memset(sum, 0, sizeof(MD5SUM));
        ls_lua_pop(L, 1);
        return 0;
    }

    memcpy(sum, ls_lua_tostring(L, -1), sizeof(MD5SUM));
    ls_lua_pop(L, 1);
    return 1;
}

#endif


LIST *
builtin_luastring(
          PARSE    *parse,
          LOL        *args,
          int        *jmp)
{
    int top;
    int ret;

    LIST *l = lol_get(args, 0);
    if (!list_first(l))
    {
        printf("jam: No argument passed to LuaString\n");
        exit(EXITBAD);
    }
    ls_lua_init();
    top = ls_lua_gettop(L);
    ret = ls_luaL_loadstring(L, list_value(list_first(l)));
    return ls_lua_callhelper(top, ret);
}


LIST *
builtin_luafile(
        PARSE    *parse,
        LOL        *args,
        int        *jmp)
{
    int top;
    int ret;
    LISTITEM *l2;
    int index = 0;

    LIST *l = lol_get(args, 0);
    if (!list_first(l)) {
        printf("jam: No argument passed to LuaFile\n");
        exit(EXITBAD);
    }
    ls_lua_init();
    top = ls_lua_gettop(L);
    ls_lua_newtable(L);
    for (l2 = list_first(lol_get(args, 1)); l2; l2 = list_next(l2)) {
        ls_lua_pushstring(L, list_value(l2));
        ls_lua_rawseti(L, -2, ++index);
    }
    ls_lua_setfield(L, LUA_GLOBALSINDEX, "arg");
    ret = ls_luaL_loadfile(L, list_value(list_first(l)));
    return ls_lua_callhelper(top, ret);
}


void ls_lua_shutdown()
{
    if (L)
    {
        ls_lua_close(L);
        L = NULL;
    }
}

#endif

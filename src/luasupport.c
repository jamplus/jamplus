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
#include "newstr.h"

#ifdef OS_NT
#include <windows.h>
#undef LoadString
#else
#include <dlfcn.h>
#endif
#include <stddef.h>

/*
@@ LUAI_BITSINT defines the number of bits in an int.
** CHANGE here if Lua cannot automatically detect the number of bits of
** your machine. Probably you do not need to change this.
*/
/* avoid overflows in comparison */
#if INT_MAX-20 < 32760		/* { */
#define LUAI_BITSINT	16
#elif INT_MAX > 2147483640L	/* }{ */
/* int has at least 32 bits */
#define LUAI_BITSINT	32
#else				/* }{ */
#error "you must define LUA_BITSINT with number of bits in an integer"
#endif				/* } */


/*
@@ LUAI_MAXSTACK limits the size of the Lua stack.
** CHANGE it if you need a different limit. This limit is arbitrary;
** its only purpose is to stop Lua to consume unlimited stack
** space (and to reserve some numbers for pseudo-indices).
*/
#if LUAI_BITSINT >= 32
#define LUAI_MAXSTACK		1000000
#else
#define LUAI_MAXSTACK		15000
#endif

/* reserve some space for error handling */
#define LUAI_FIRSTPSEUDOIDX	(-LUAI_MAXSTACK - 1000)

/* Declarations from lua.h. */
/*
** pseudo-indices
*/
#define LUA_REGISTRYINDEX	LUAI_FIRSTPSEUDOIDX

typedef struct ls_lua_State ls_lua_State;

typedef int (*ls_lua_CFunction) (ls_lua_State *L);

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
#define LUA_TNONE        (-1)

/* type of numbers in Lua */
#define LUA_NUMBER	double
typedef LUA_NUMBER ls_lua_Number;

/* type for integer functions */
#define LUA_INTEGER	ptrdiff_t
typedef LUA_INTEGER ls_lua_Integer;

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

ls_lua_Number      (*ls_lua_tonumberx) (ls_lua_State *L, int idx, int *isnum);
int             (*ls_lua_toboolean) (ls_lua_State *L, int idx);
#define ls_lua_tostring(L,i)    ls_lua_tolstring(L, (i), NULL)
const char     *(*ls_lua_tolstring) (ls_lua_State *L, int idx, size_t *len);
size_t          (*ls_lua_rawlen) (ls_lua_State *L, int idx);

void  (*ls_lua_pushnil) (ls_lua_State *L);
void  (*ls_lua_pushnumber) (ls_lua_State *L, ls_lua_Number n);
void  (*ls_lua_pushinteger) (ls_lua_State *L, ls_lua_Integer n);
const char *(*ls_lua_pushlstring) (ls_lua_State *L, const char *s, size_t l);
const char *(*ls_lua_pushstring) (ls_lua_State *L, const char *s);
void  (*ls_lua_pushcclosure) (ls_lua_State *L, ls_lua_CFunction fn, int n);
void  (*ls_lua_pushboolean) (ls_lua_State *L, int b);

void  (*ls_lua_getglobal) (ls_lua_State *L, const char *var);
void  (*ls_lua_gettable) (ls_lua_State *L, int idx);
void  (*ls_lua_getfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_rawgeti) (ls_lua_State *L, int idx, int n);
void  (*ls_lua_createtable) (ls_lua_State *L, int narr, int nrec);

void  (*ls_lua_setglobal) (ls_lua_State *L, const char *var);
void  (*ls_lua_settable) (ls_lua_State *L, int idx);
void  (*ls_lua_setfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_rawseti) (ls_lua_State *L, int idx, int n);

int   (*ls_lua_pcallk) (ls_lua_State *L, int nargs, int nresults, int errfunc,
                            int ctx, ls_lua_CFunction k);
#define ls_lua_pcall(L,n,r,f)	ls_lua_pcallk(L, (n), (r), (f), 0, NULL)

int   (*ls_lua_next) (ls_lua_State *L, int idx);

#define ls_lua_pop(L,n)        ls_lua_settop(L, -(n)-1)

#define ls_lua_newtable(L)        ls_lua_createtable(L, 0, 0)

typedef struct ls_lua_Debug ls_lua_Debug;  /* activation record */
int (*ls_lua_getstack)(ls_lua_State *L, int level, ls_lua_Debug *ar);
int (*ls_lua_getinfo)(ls_lua_State *L, const char *what, ls_lua_Debug *ar);

/*
@@ LUA_IDSIZE gives the maximum size for the description of the source
@* of a function in debug information.
** CHANGE it if you want a different size.
*/
#define LUA_IDSIZE    60

struct ls_lua_Debug {
  int event;
  const char *name;	/* (n) */
  const char *namewhat;	/* (n) 'global', 'local', 'field', 'method' */
  const char *what;	/* (S) 'Lua', 'C', 'main', 'tail' */
  const char *source;	/* (S) */
  int currentline;	/* (l) */
  int linedefined;	/* (S) */
  int lastlinedefined;	/* (S) */
  unsigned char nups;	/* (u) number of upvalues */
  unsigned char nparams;/* (u) number of parameters */
  char isvararg;        /* (u) */
  char istailcall;	/* (t) */
  char short_src[LUA_IDSIZE]; /* (S) */
  /* private part */
  struct CallInfo *i_ci;  /* active function */
};

void (*ls_luaL_openlibs) (ls_lua_State *L);
int (*ls_luaL_loadstring) (ls_lua_State *L, const char *s);
int (*ls_luaL_loadfilex) (ls_lua_State *L, const char *filename, const char *mode);
#define ls_luaL_loadfile(L,f)	ls_luaL_loadfilex(L,f,NULL)

ls_lua_State *(*ls_luaL_newstate) (void);
int (*ls_luaL_ref) (ls_lua_State *L, int t);
void (*ls_luaL_unref) (ls_lua_State *L, int t, int ref);

#define ls_lua_tonumber(L,i)	ls_lua_tonumberx(L,i,NULL)

/*****************************************************************************/
static ls_lua_State *L;

static LIST *luahelper_addtolist(ls_lua_State *L, LIST *list, int index)
{
    if (ls_lua_isboolean(L, index))
        return list_append(list, ls_lua_toboolean(L, index) ? "true" : "false", 0);

    if (ls_lua_isnumber(L, index)) {
        LIST* newList;
        ls_lua_pushvalue(L, index);
        newList = list_append(list, ls_lua_tostring(L, -1), 0);
        ls_lua_pop(L, 1);
        return newList;
    }

    if (ls_lua_isstring(L, index)) {
        const char* value = ls_lua_tostring(L, index);
        return list_append(list, value, 0);
    }

    else if (ls_lua_istable(L, index))
    {
        ls_lua_pushnil(L);
        while (ls_lua_next(L, index) != 0)
        {
            list = luahelper_addtolist(L, list, ls_lua_gettop(L));
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
        t->settings = addsettings(t->settings, VAR_SET, ls_lua_tostring(L, 2), luahelper_addtolist(L, L0, 3));
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
    const char* rule;

    int numParams = ls_lua_gettop(L);
    if (numParams < 1)
        return 0;

    if (!ls_lua_isstring(L, 1))
        return 0;

    lol_init(&lol);

    rule = ls_lua_tostring(L, 1);
    for (i = 0; i < numParams - 1; ++i)
    {
        lol_add(&lol, luahelper_addtolist(L, L0, 2 + i));
    }
    list = evaluate_rule(rule, &lol, L0);
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


// jam_action(name, function, {options})
int LS_jam_action(ls_lua_State *L)
{
    RULE* rule;
    const char* name;
    int paramIndex = 2;

    int numParams = ls_lua_gettop(L);
    if (numParams < 2) {
        //ls_luaL_error
        return 0;
    }

    if (!ls_lua_isstring(L, 1))
        return 0;
    name = ls_lua_tostring(L, 1);
    rule = bindrule(name);

    if (rule->actions) {
        freestr(rule->actions);
        rule->actions = NULL;
    }

    if (rule->bindlist) {
        list_free(rule->bindlist);
        rule->bindlist = L0;
    }

    if (ls_lua_isstring(L, 2))
        paramIndex = 2;
    else if (ls_lua_isstring(L, 3))
        paramIndex = 3;
    else {
        return 0;
    }

    rule->actions = copystr(ls_lua_tostring(L, paramIndex));
    rule->flags = 0;

    paramIndex = paramIndex == 2 ? 3 : 2;

    if (ls_lua_istable(L, paramIndex)) {
        ls_lua_getfield(L, paramIndex, "bind");
        if (ls_lua_istable(L, -1)) {
            ls_lua_pushnil(L);
            while (ls_lua_next(L, -2) != 0) {
                if (!ls_lua_tostring(L, -1)) {
                    printf("!!\n");
                    exit(1);
                }
                rule->bindlist = list_append(rule->bindlist, ls_lua_tostring(L, -1), 0);
                ls_lua_pop(L, 1);
            }
            ls_lua_pop(L, 1);
        }
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "updated");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_UPDATED : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "together");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_TOGETHER : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "ignore");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_IGNORE : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "quietly");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_QUIETLY : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "piecemeal");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_PIECEMEAL : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "existing");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_EXISTING : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "response");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_RESPONSE : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "lua");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_LUA : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "screenoutput");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_SCREENOUTPUT : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "removeemptydirs");
        rule->flags |= ls_lua_toboolean(L, -1) ? RULE_REMOVEEMPTYDIRS : 0;
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "maxtargets");
        if (ls_lua_isnumber(L, -1)) {
            rule->flags |= RULE_MAXTARGETS;
            rule->maxtargets = (int)ls_lua_tonumber(L, -1);
        }
        ls_lua_pop(L, 1);

        ls_lua_getfield(L, paramIndex, "maxline");
        if (ls_lua_isnumber(L, -1)) {
            rule->flags |= RULE_MAXLINE;
            rule->maxline = (int)ls_lua_tonumber(L, -1);
        }
        ls_lua_pop(L, 1);
    }

    return 0;
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
            int ret;
            printf("jam: Error running Lua code\n%s\n", ls_lua_tostring(L, -1));
            ls_lua_getglobal(L, "debug");
            ls_lua_getfield(L, -1, "traceback");
            ret = ls_lua_pcall(L, 0, 1, 0);
            if (ret == 0) {
                if (ls_lua_isstring(L, -1)) {
                    puts(ls_lua_tostring(L, -1));
                }
            }
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


static int lanes_on_state_create(ls_lua_State *L) {
    ls_lua_pushcclosure(L, LS_jam_getvar, 0);
    ls_lua_setglobal(L, "jam_getvar");
    ls_lua_pushcclosure(L, LS_jam_setvar, 0);
    ls_lua_setglobal(L, "jam_setvar");
    ls_lua_pushcclosure(L, LS_jam_expand, 0);
    ls_lua_setglobal(L, "jam_expand");
    ls_lua_pushcclosure(L, LS_jam_print, 0);
    ls_lua_setglobal(L, "jam_print");
    return 0;
}


static int pmain (ls_lua_State *L)
{
    int top;
    int ret;

    ls_luaL_openlibs(L);

    ls_lua_pushcclosure(L, LS_jam_getvar, 0);
    ls_lua_setglobal(L, "jam_getvar");
    ls_lua_pushcclosure(L, LS_jam_setvar, 0);
    ls_lua_setglobal(L, "jam_setvar");
    ls_lua_pushcclosure(L, LS_jam_action, 0);
    ls_lua_setglobal(L, "jam_action");
    ls_lua_pushcclosure(L, LS_jam_evaluaterule, 0);
    ls_lua_setglobal(L, "jam_evaluaterule");
    ls_lua_pushcclosure(L, LS_jam_expand, 0);
    ls_lua_setglobal(L, "jam_expand");
    ls_lua_pushcclosure(L, LS_jam_parse, 0);
    ls_lua_setglobal(L, "jam_parse");
    ls_lua_pushcclosure(L, LS_jam_print, 0);
    ls_lua_setglobal(L, "jam_print");

    top = ls_lua_gettop(L);
    ret = ls_luaL_loadstring(L, "lanes = require 'lanes'");
    ls_lua_callhelper(top, ret);

    ls_lua_getglobal(L, "lanes");                       /* lanes */
    ls_lua_getfield(L, -1, "configure");                /* lanes configure */
    ls_lua_newtable(L);                                 /* lanes configure table */
    ls_lua_pushcclosure(L, lanes_on_state_create, 0);   /* lanes configure table lanes_on_state_create */
    ls_lua_setfield(L, -2, "on_state_create");          /* lanes configure table */
    ret = ls_lua_pcall(L, 1, 0, 0);                     /* lanes */
    if (ret != 0) {
        const char* err = ls_lua_tostring(L, -1);  (void)err;
	}
    ls_lua_pop(L, 2);

    ls_lua_newtable(L);
    ls_lua_setglobal(L, "LineFilters");

    return 0;
}


#ifdef OS_NT
static HMODULE ls_lua_loadlibrary(const char* filename)
#else
static void* ls_lua_loadlibrary(const char* filename)
#endif
{
#ifdef OS_NT
    return LoadLibrary(filename);
#else
    return dlopen(filename, RTLD_LAZY | RTLD_GLOBAL);
#endif
}


static void* ls_lua_loadsymbol(void* handle, const char* symbol)
{
#ifdef OS_NT
    return GetProcAddress(handle, symbol);
#else
    return dlsym(handle, symbol);
#endif
}


#ifdef OS_NT
HMODULE luaTildeModule;
#else
void* luaTildeModule;
#endif
typedef void* LuaTildeHost;
LuaTildeHost* (*LuaTilde_Command)(LuaTildeHost*, const char*, void*, void*);


void ls_lua_init()
{
    char fileName[4096];
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
        strcpy(fileName, list_value(list_first(luaSharedLibrary)));
        handle = ls_lua_loadlibrary(fileName);
    }
    if (!handle)
    {
        getprocesspath(fileName, 4096);

#ifdef OS_NT
#ifdef _DEBUG
        strcat(fileName, "/lua/lua52_debug.dll");
#else
        strcat(fileName, "/lua/lua52.dll");
#endif
#else
#ifdef _DEBUG
        strcat(fileName, "/lua/liblua52_debug.so");
#else
        strcat(fileName, "/lua/liblua52.so");
#endif
#endif
        handle = ls_lua_loadlibrary(fileName);
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

    ls_lua_tonumberx = (ls_lua_Number (*)(ls_lua_State *, int, int *))ls_lua_loadsymbol(handle, "lua_tonumberx");
    ls_lua_toboolean = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_toboolean");
    ls_lua_tolstring = (const char *(*)(ls_lua_State *, int, size_t *))ls_lua_loadsymbol(handle, "lua_tolstring");
    ls_lua_rawlen = (size_t (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_rawlen");

    ls_lua_pushnil = (void (*) (ls_lua_State *))ls_lua_loadsymbol(handle, "lua_pushnil");
    ls_lua_pushnumber = (void (*) (ls_lua_State *, ls_lua_Number))ls_lua_loadsymbol(handle, "lua_pushnumber");
    ls_lua_pushinteger = (void (*) (ls_lua_State *, ls_lua_Integer))ls_lua_loadsymbol(handle, "lua_pushinteger");
    ls_lua_pushstring = (const char *(*) (ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "lua_pushstring");
    ls_lua_pushlstring = (const char *(*) (ls_lua_State *, const char *, size_t))ls_lua_loadsymbol(handle, "lua_pushlstring");
    ls_lua_pushcclosure = (void (*) (ls_lua_State *, ls_lua_CFunction, int))ls_lua_loadsymbol(handle, "lua_pushcclosure");
    ls_lua_pushboolean = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_pushboolean");

    ls_lua_getglobal = (void (*) (ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "lua_getglobal");
    ls_lua_gettable = (void (*) (ls_lua_State *, int id))ls_lua_loadsymbol(handle, "lua_gettable");
    ls_lua_getfield = (void (*)(ls_lua_State *, int, const char *))ls_lua_loadsymbol(handle, "lua_getfield");
    ls_lua_rawgeti = (void  (*) (ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_rawgeti");
    ls_lua_createtable = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_createtable");

    ls_lua_setglobal = (void (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "lua_setglobal");
    ls_lua_settable = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_settable");
    ls_lua_setfield = (void (*)(ls_lua_State *, int, const char *))ls_lua_loadsymbol(handle, "lua_setfield");
    ls_lua_rawseti = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_rawseti");

    ls_lua_pcallk = (int (*)(ls_lua_State *, int, int, int, int, ls_lua_CFunction))ls_lua_loadsymbol(handle, "lua_pcallk");

    ls_lua_next = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_next");

    ls_lua_getstack = (int(*)(ls_lua_State *, int, ls_lua_Debug *))ls_lua_loadsymbol(handle, "lua_getstack");
    ls_lua_getinfo = (int(*)(ls_lua_State *, const char *, ls_lua_Debug *))ls_lua_loadsymbol(handle, "lua_getinfo");

    ls_luaL_openlibs = (void (*)(ls_lua_State *))ls_lua_loadsymbol(handle, "luaL_openlibs");
    ls_luaL_loadstring = (int (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "luaL_loadstring");
    ls_luaL_loadfilex = (int (*)(ls_lua_State *, const char *, const char *))ls_lua_loadsymbol(handle, "luaL_loadfilex");
    ls_luaL_newstate = (ls_lua_State *(*)(void))ls_lua_loadsymbol(handle, "luaL_newstate");
    ls_luaL_ref = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "luaL_ref");
    ls_luaL_unref = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "luaL_unref");

    L = ls_luaL_newstate();
    ls_lua_pushcclosure(L, &pmain, 0);
    ls_lua_pcall(L, 0, 0, 0);

    if (globs.lua_debugger) {
        char* slashPtr;
        char* backslashPtr;
        slashPtr = strrchr(fileName, '/');
        backslashPtr = strrchr(fileName, '\\');
        slashPtr = slashPtr > backslashPtr ? slashPtr : backslashPtr;
        if (slashPtr) {
            ++slashPtr;
        } else {
            slashPtr = fileName;
        }
#ifdef OS_NT
#ifdef _DEBUG
        strcpy(slashPtr, "lua-tilde.debug.dll");
#else
        strcpy(slashPtr, "lua-tilde.dll");
#endif
#else
#ifdef _DEBUG
        strcpy(slashPtr, "lua-tilde.debug.so");
#else
        strcpy(slashPtr, "lua-tilde.so");
#endif
#endif
        luaTildeModule = ls_lua_loadlibrary(fileName);
        if (luaTildeModule) {
            LuaTildeHost* host;
            LuaTilde_Command = (LuaTildeHost* (*)(LuaTildeHost*, const char*, void*, void*))ls_lua_loadsymbol(luaTildeModule, "LuaTilde_Command");
            host = LuaTilde_Command(NULL, "create", (void*)10000, NULL);
            LuaTilde_Command(host, "registerstate", "State", L);
            LuaTilde_Command(host, "waitfordebuggerconnection", NULL, NULL);
        }
    }
}


int luahelper_taskadd(const char* taskscript)
{
    int ret;
    int ref;
    size_t taskscriptlen = strlen(taskscript);
    char* newTaskScript;

    ls_lua_init();

    ls_lua_getglobal(L, "lanes");                             /* lanes */
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

    ls_lua_getglobal(L, "LineFilters");                        /* LineFilters */
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

    out = malloc(ls_lua_rawlen(L, -1) + 1);
    strcpy(out, ls_lua_tostring(L, -1));
    ls_lua_settop(L, top);

    return out;
}


#ifdef OPT_BUILTIN_MD5CACHE_EXT

int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback)
{
    int ret;

    ls_lua_init();

    ls_lua_getglobal(L, callback);
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

    if (!ls_lua_isstring(L, -1)  ||  ls_lua_rawlen(L, -1) != sizeof(MD5SUM))
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
    ls_lua_setglobal(L, "arg");
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

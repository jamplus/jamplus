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
#include "miniz.h"

extern mz_zip_archive *zip_attemptopen();
extern int zip_findfile(const char *filename);

//#define OPT_BUILTIN_LUA_DLL_SUPPORT_EXT
#ifdef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

#ifdef OS_NT
#include <windows.h>
#undef LoadString
#else
#include <dlfcn.h>
#endif

#else /* OPT_BUILTIN_LUA_DLL_SUPPORT_EXT */

#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lua.h"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lualib.h"
#include "luaplus/Src/LuaPlus/lua53-luaplus/src/lauxlib.h"
#include "luaplus/Src/Modules/lanes/src/threading.h"
#include "luaplus/Src/Modules/lanes/src/lanes.h"

#endif /* OPT_BUILTIN_LUA_DLL_SUPPORT_EXT */

#include <stddef.h>

/*
@@ LUAI_BITSINT defines the (minimum) number of bits in an 'int'.
*/
/* avoid undefined shifts */
#if ((INT_MAX >> 15) >> 15) >= 1
#define LUAI_BITSINT	32
#else
/* 'int' always must have at least 16 bits */
#define LUAI_BITSINT	16
#endif


/*
@@ LUA_INT_TYPE defines the type for Lua integers.
@@ LUA_FLOAT_TYPE defines the type for Lua floats.
** Lua should work fine with any mix of these options (if supported
** by your C compiler). The usual configurations are 64-bit integers
** and 'double' (the default), 32-bit integers and 'float' (for
** restricted platforms), and 'long'/'double' (for C compilers not
** compliant with C99, which may not have support for 'long long').
*/

/* predefined options for LUA_INT_TYPE */
#define LUA_INT_INT		1
#define LUA_INT_LONG		2
#define LUA_INT_LONGLONG	3

/* predefined options for LUA_FLOAT_TYPE */
#define LUA_FLOAT_FLOAT		1
#define LUA_FLOAT_DOUBLE	2
#define LUA_FLOAT_LONGDOUBLE	3

#if defined(LUA_32BITS)		/* { */
/*
** 32-bit integers and 'float'
*/
#if LUAI_BITSINT >= 32  /* use 'int' if big enough */
#define LUA_INT_TYPE	LUA_INT_INT
#else  /* otherwise use 'long' */
#define LUA_INT_TYPE	LUA_INT_LONG
#endif
#define LUA_FLOAT_TYPE	LUA_FLOAT_FLOAT

#elif defined(LUA_C89_NUMBERS)	/* }{ */
/*
** largest types available for C89 ('long' and 'double')
*/
#define LUA_INT_TYPE	LUA_INT_LONG
#define LUA_FLOAT_TYPE	LUA_FLOAT_DOUBLE

#endif				/* } */


/*
** default configuration for 64-bit Lua ('long long' and 'double')
*/
#if !defined(LUA_INT_TYPE)
#define LUA_INT_TYPE	LUA_INT_LONGLONG
#endif

#if !defined(LUA_FLOAT_TYPE)
#define LUA_FLOAT_TYPE	LUA_FLOAT_DOUBLE
#endif								/* } */

/* }================================================================== */


/*
@@ LUA_NUMBER is the floating-point type used by Lua.
*/

#if LUA_FLOAT_TYPE == LUA_FLOAT_FLOAT		/* { single float */

#define LUA_NUMBER	float


#elif LUA_FLOAT_TYPE == LUA_FLOAT_LONGDOUBLE	/* }{ long double */

#define LUA_NUMBER	long double


#elif LUA_FLOAT_TYPE == LUA_FLOAT_DOUBLE	/* }{ double */

#define LUA_NUMBER	double

#else						/* }{ */

#error "numeric float type not defined"

#endif					/* } */


/*
@@ LUA_INTEGER is the integer type used by Lua.
**
@@ LUA_UNSIGNED is the unsigned version of LUA_INTEGER.
*/


#define LUAI_UACINT		LUA_INTEGER

/*
** use LUAI_UACINT here to avoid problems with promotions (which
** can turn a comparison between unsigneds into a signed comparison)
*/
#define LUA_UNSIGNED		unsigned LUAI_UACINT


/* now the variable definitions */

#if LUA_INT_TYPE == LUA_INT_INT		/* { int */

#define LUA_INTEGER		int

#define LUA_MAXINTEGER		INT_MAX
#define LUA_MININTEGER		INT_MIN

#elif LUA_INT_TYPE == LUA_INT_LONG	/* }{ long */

#define LUA_INTEGER		long

#define LUA_MAXINTEGER		LONG_MAX
#define LUA_MININTEGER		LONG_MIN

#elif LUA_INT_TYPE == LUA_INT_LONGLONG	/* }{ long long */

#if defined(LLONG_MAX)		/* { */
/* use ISO C99 stuff */

#define LUA_INTEGER		long long

#define LUA_MAXINTEGER		LLONG_MAX
#define LUA_MININTEGER		LLONG_MIN

#elif defined(LUA_USE_WINDOWS) /* }{ */
/* in Windows, can use specific Windows types */

#define LUA_INTEGER		__int64

#define LUA_MAXINTEGER		_I64_MAX
#define LUA_MININTEGER		_I64_MIN

#else				/* }{ */

#error "Compiler does not support 'long long'. Use option '-DLUA_32BITS' \
  or '-DLUA_C89_NUMBERS' (see file 'luaconf.h' for details)"

#endif				/* } */

#else				/* }{ */

#error "numeric integer type not defined"

#endif				/* } */

/* }================================================================== */

#define LUA_PATH_SEP            ";"
#define LUA_PATH_MARK           "?"

/*
@@ LUA_DIRSEP is the directory separator (for submodules).
** CHANGE it if your machine does not use "/" as the directory separator
** and is not Windows. (On Windows Lua automatically uses "\".)
*/
#if defined(_WIN32)
#define LUA_DIRSEP	"\\"
#else
#define LUA_DIRSEP	"/"
#endif

/*
@@ LS_LUA_KCONTEXT is the type of the context ('ctx') for continuation
** functions.  It must be a numerical type; Lua will use 'intptr_t' if
** available, otherwise it will use 'ptrdiff_t' (the nearest thing to
** 'intptr_t' in C89)
*/
#define LS_LUA_KCONTEXT	ptrdiff_t

#if !defined(LUA_USE_C89) && defined(__STDC_VERSION__) && \
    __STDC_VERSION__ >= 199901L
#include <stdint.h>
#if defined(INTPTR_MAX)  /* even in C99 this type is optional */
#undef LS_LUA_KCONTEXT
#define LS_LUA_KCONTEXT	intptr_t
#endif
#endif




/*
@@ LUAI_MAXSTACK limits the size of the Lua stack.
** CHANGE it if you need a different limit. This limit is arbitrary;
** its only purpose is to stop Lua from consuming unlimited stack
** space (and to reserve some numbers for pseudo-indices).
*/
#if LUAI_BITSINT >= 32
#define LUAI_MAXSTACK		1000000
#else
#define LUAI_MAXSTACK		15000
#endif

/* Declarations from lua.h. */
/*
** pseudo-indices
** (-LUAI_MAXSTACK is the minimum valid index; we keep some free empty
** space after that to help overflow detection)
*/
#define LUA_REGISTRYINDEX	(-LUAI_MAXSTACK - 1000)
#define ls_lua_upvalueindex(i)	(LUA_REGISTRYINDEX - (i))

typedef struct ls_lua_State ls_lua_State;

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

#define LUA_NUMTAGS		9

/* type of numbers in Lua */
typedef LUA_NUMBER ls_lua_Number;

/* type for integer functions */
typedef LUA_INTEGER ls_lua_Integer;

/* unsigned integer type */
typedef LUA_UNSIGNED ls_lua_Unsigned;

/* type for continuation-function contexts */
typedef LS_LUA_KCONTEXT ls_lua_KContext;

typedef int (*ls_lua_CFunction) (ls_lua_State *L);

ls_lua_State *(*ls_luaL_newstate) (void);
void (*ls_lua_close) (ls_lua_State *L);

int   (*ls_lua_gettop) (ls_lua_State *L);
void  (*ls_lua_settop) (ls_lua_State *L, int idx);
void (*ls_lua_pushvalue) (ls_lua_State *L, int idx);
void (*ls_lua_rotate) (ls_lua_State *L, int idx, int n);

#define ls_lua_remove(L,idx)	(ls_lua_rotate(L, (idx), -1), ls_lua_pop(L, 1))

#define ls_lua_isfunction(L,n)    (ls_lua_type(L, (n)) == LUA_TFUNCTION)
#define ls_lua_istable(L,n)    (ls_lua_type(L, (n)) == LUA_TTABLE)
#define ls_lua_isnil(L,n)        (ls_lua_type(L, (n)) == LUA_TNIL)
#define ls_lua_isboolean(L,n)    (ls_lua_type(L, (n)) == LUA_TBOOLEAN)
int             (*ls_lua_isnumber) (ls_lua_State *L, int idx);
int             (*ls_lua_isstring) (ls_lua_State *L, int idx);
int             (*ls_lua_isuserdata) (ls_lua_State *L, int idx);
int             (*ls_lua_type) (ls_lua_State *L, int idx);

ls_lua_Number   (*ls_lua_tonumberx) (ls_lua_State *L, int idx, int *isnum);
ls_lua_Integer  (*ls_lua_tointegerx) (ls_lua_State *L, int idx, int *isnum);
int             (*ls_lua_toboolean) (ls_lua_State *L, int idx);
#define ls_lua_tostring(L,i)    ls_lua_tolstring(L, (i), NULL)
const char     *(*ls_lua_tolstring) (ls_lua_State *L, int idx, size_t *len);
size_t          (*ls_lua_rawlen) (ls_lua_State *L, int idx);

void  (*ls_lua_pushnil) (ls_lua_State *L);
void  (*ls_lua_pushnumber) (ls_lua_State *L, ls_lua_Number n);
void  (*ls_lua_pushinteger) (ls_lua_State *L, ls_lua_Integer n);
const char *(*ls_lua_pushlstring) (ls_lua_State *L, const char *s, size_t len);
const char *(*ls_lua_pushstring) (ls_lua_State *L, const char *s);
void  (*ls_lua_pushcclosure) (ls_lua_State *L, ls_lua_CFunction fn, int n);
void  (*ls_lua_pushboolean) (ls_lua_State *L, int b);

void  (*ls_lua_getglobal) (ls_lua_State *L, const char *var);
void  (*ls_lua_gettable) (ls_lua_State *L, int idx);
void  (*ls_lua_getfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_rawgeti) (ls_lua_State *L, int idx, ls_lua_Integer n);
void  (*ls_lua_createtable) (ls_lua_State *L, int narr, int nrec);

void  (*ls_lua_setglobal) (ls_lua_State *L, const char *name);
void  (*ls_lua_settable) (ls_lua_State *L, int idx);
void  (*ls_lua_setfield) (ls_lua_State *L, int idx, const char *k);
void  (*ls_lua_seti) (ls_lua_State *L, int idx, ls_lua_Integer n);
void  (*ls_lua_rawseti) (ls_lua_State *L, int idx, ls_lua_Integer n);

int   (*ls_lua_pcallk) (ls_lua_State *L, int nargs, int nresults, int errfunc,
                            ls_lua_KContext ctx, ls_lua_CFunction k);
#define ls_lua_pcall(L,n,r,f)	ls_lua_pcallk(L, (n), (r), (f), 0, NULL)

void  (*ls_lua_len) (ls_lua_State *L, int idx);

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

/*
** {======================================================
** Generic Buffer manipulation
** =======================================================
*/

void (*ls_luaL_openlibs) (ls_lua_State *L);
int (*ls_luaL_loadbufferx) (ls_lua_State *L, const char *buff, size_t sz,
                                   const char *name, const char *mode);
int (*ls_luaL_loadstring) (ls_lua_State *L, const char *s);
int (*ls_luaL_loadfilex) (ls_lua_State *L, const char *filename, const char *mode);
#define ls_luaL_loadfile(L,f)	ls_luaL_loadfilex(L,f,NULL)

#define ls_luaL_dostring(L, s) \
	(ls_luaL_loadstring(L, s) || ls_lua_pcall(L, 0, -1, 0))

const char *(*ls_luaL_gsub) (ls_lua_State *L, const char *s, const char *p, const char *r);

int (*ls_luaL_ref) (ls_lua_State *L, int t);
void (*ls_luaL_unref) (ls_lua_State *L, int t, int ref);

#define ls_lua_tonumber(L,i)	ls_lua_tonumberx(L,i,NULL)

int (*ls_luaL_error) (ls_lua_State *L, const char *fmt, ...);

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
        lines = (char**)malloc(sizeof(char*) * (numberOfLines + 1));
        numberOfLines = 0;
        startPtr = ptr = src;
        while (1) {
            if (*ptr == '\n'  ||  *ptr == 0) {
                char* line;
                if (*ptr == '\n')
                    ++ptr;
                line = (char*)malloc(ptr - startPtr + 1);
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


static const char *jluapushnexttemplate (ls_lua_State *L, const char *path) {
  const char *l;
  while (*path == *LUA_PATH_SEP) path++;  /* skip separators */
  if (*path == '\0') return NULL;  /* no more templates */
  l = strchr(path, *LUA_PATH_SEP);  /* find next separator */
  if (l == NULL) l = path + strlen(path);
  ls_lua_pushlstring(L, path, l - path);  /* template */
  return l;
}

static int jluasearchpath(ls_lua_State *L, const char *name,
									const char *path,
									const char *sep,
									const char *dirsep) {
	int index = -1;
	if (*sep != '\0')  /* non-empty separator? */
		name = ls_luaL_gsub(L, name, sep, dirsep);  /* replace it by 'dirsep' */
	while ((path = jluapushnexttemplate(L, path)) != NULL) {
		const char *filename = ls_luaL_gsub(L, ls_lua_tostring(L, -1),
			LUA_PATH_MARK, name);
		ls_lua_remove(L, -2);  /* remove path template */
		index = zip_findfile(filename);
		if (index != -1)
		{
			return index;  /* return that file name */
		}
		ls_lua_remove(L, -2);  /* remove file name */
	}
	return -1;  /* not found */
}


static int jluafindfile(ls_lua_State *L, const char *name,
                                           const char *pname,
                                           const char *dirsep) {
    const char *path;
    ls_lua_getfield(L, ls_lua_upvalueindex(1), pname);
    path = ls_lua_tostring(L, -1);
    if (path == NULL)
        return -1;
    return jluasearchpath(L, name, path, ".", dirsep);
}


static int jluacheckload (ls_lua_State *L, int stat, const char *filename) {
  if (stat) {  /* module loaded successfully? */
    ls_lua_pushstring(L, filename);  /* will be 2nd argument to module */
    return 2;  /* return open function and file name */
  }
  else
    return ls_luaL_error(L, "error loading module '%s' from file '%s':\n\t%s",
                          ls_lua_tostring(L, 1), filename, ls_lua_tostring(L, -1));
}


/*
** LUA_LSUBSEP is the character that replaces dots in submodule names
** when searching for a Lua loader.
*/
#if !defined(LUA_LSUBSEP)
#define LUA_LSUBSEP		LUA_DIRSEP
#endif


static int jluasearcher_Lua (ls_lua_State *L) {
	int top;
	size_t len;
	const char *name = ls_lua_tolstring(L, 1, &len);
	int index = jluafindfile(L, name, "path", LUA_LSUBSEP);
	if (index == -1)
		return 0;  /* module not found in this path */
    char filename[512];
    mz_zip_archive *pZipArchive = zip_attemptopen();
	mz_uint filenameLength = mz_zip_reader_get_filename(pZipArchive, index, filename, sizeof(filename));
	size_t bufferSize;
	unsigned char* buffer = (unsigned char*)mz_zip_reader_extract_to_heap(pZipArchive, index, &bufferSize, 0);
    top = ls_lua_gettop(L);
    int ret = jluacheckload(L, (ls_luaL_loadbufferx(L, (const char*)buffer, bufferSize, filename, NULL) == 0), filename);
	pZipArchive->m_pFree(pZipArchive->m_pAlloc_opaque, buffer);
    return ret;
}

#ifndef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

extern int luaopen_filefind(lua_State *L);
extern int luaopen_lxp(lua_State *L);
extern int luaopen_md5(lua_State *L);
extern int luaopen_miniz(lua_State *L);
extern int luaopen_ospath_core(lua_State *L);
extern int luaopen_osprocess_core(lua_State *L);
extern int luaopen_prettydump(lua_State *L);
extern int luaopen_rapidjson(lua_State *L);
extern int luaopen_struct(lua_State *L);
extern int luaopen_uuid(lua_State *L);
extern int luaopen_ziparchive(lua_State *L);

#endif /* OPT_BUILTIN_LUA_DLL_SUPPORT_EXT */

static void ls_register_custom_libs(ls_lua_State* L)
{
#ifndef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT
    luaL_requiref((lua_State*)L, "filefind", luaopen_filefind, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "lxp", luaopen_lxp, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "md5", luaopen_md5, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "miniz", luaopen_miniz, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "ospath.core", luaopen_ospath_core, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "osprocess.core", luaopen_osprocess_core, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "prettydump", luaopen_prettydump, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "rapidjson", luaopen_rapidjson, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "struct", luaopen_struct, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "uuid", luaopen_uuid, 1);
    ls_lua_pop(L, 1);
    luaL_requiref((lua_State*)L, "ziparchive", luaopen_ziparchive, 1);
    ls_lua_pop(L, 1);
#endif /* OPT_BUILTIN_LUA_DLL_SUPPORT_EXT */
}

static int lanes_on_state_create(ls_lua_State *L) {
	{
        char exeName[4096];
        getexecutablepath(exeName, sizeof(exeName));
        ls_lua_pushlstring(L, exeName, strlen(exeName));
        ls_lua_setglobal(L, "JAM_EXECUTABLE");

        getprocesspath(exeName, sizeof(exeName));
        ls_lua_pushlstring(L, exeName, strlen(exeName));
        ls_lua_setglobal(L, "JAM_EXECUTABLE_PATH");
    }

    ls_luaL_dostring(L,
        "package.path = JAM_EXECUTABLE_PATH .. '/lua/?.lua;' .. JAM_EXECUTABLE_PATH .. '/../lua/?.lua;' .. package.path\n"
        "package.path = JAM_EXECUTABLE_PATH .. '/lua/?/init.lua;' .. JAM_EXECUTABLE_PATH .. '/../lua/?/init.lua;'  .. package.path\n"
    );

    ls_lua_pushcclosure(L, LS_jam_getvar, 0);
    ls_lua_setglobal(L, "jam_getvar");
    ls_lua_pushcclosure(L, LS_jam_setvar, 0);
    ls_lua_setglobal(L, "jam_setvar");
    ls_lua_pushcclosure(L, LS_jam_expand, 0);
    ls_lua_setglobal(L, "jam_expand");
    ls_lua_pushcclosure(L, LS_jam_print, 0);
    ls_lua_setglobal(L, "jam_print");

    ls_lua_getglobal(L, "package");                     /* package */
    ls_lua_getfield(L, -1, "searchers");                /* package searchers */
    ls_lua_len(L, -1);                                  /* package searchers searchersLen */
    int isnum;
    int l = (int)ls_lua_tointegerx(L, -1, &isnum);      /* package searchers searchersLen */
    ls_lua_pop(L, 1);                                   /* package searchers */
    ls_lua_pushvalue(L, -2);                            /* package searchers package */
    ls_lua_pushcclosure(L, jluasearcher_Lua, 1);        /* package searchers package jluasearcher_Lua */
    ls_lua_seti(L, -2, l + 1);                          /* package searchers package */
    ls_lua_pop(L, 3);

    ls_register_custom_libs(L);
    return 0;
}


static int pmain (ls_lua_State *L)
{
    int top;
    int ret;

    ls_luaL_openlibs(L);

    ls_luaL_dostring(L,
        "package.path = JAM_EXECUTABLE_PATH .. '/lua/?.lua;' .. JAM_EXECUTABLE_PATH .. '/../lua/?.lua;' .. package.path\n"
        "package.path = JAM_EXECUTABLE_PATH .. '/lua/?/init.lua;' .. JAM_EXECUTABLE_PATH .. '/../lua/?/init.lua;'  .. package.path\n"
    );

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
    ls_lua_getglobal(L, "package");                     /* package */
    ls_lua_getfield(L, -1, "searchers");                /* package searchers */
    ls_lua_len(L, -1);                                  /* package searchers searchersLen */
    int isnum;
    int l = (int)ls_lua_tointegerx(L, -1, &isnum);      /* package searchers searchersLen */
    ls_lua_pop(L, 1);                                   /* package searchers */
    ls_lua_pushvalue(L, -2);                            /* package searchers package */
    ls_lua_pushcclosure(L, jluasearcher_Lua, 1);        /* package searchers package jluasearcher_Lua */
    ls_lua_seti(L, -2, l + 1);                          /* package searchers package */
    ls_lua_pop(L, 3);

#ifndef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT
	luaL_requiref((lua_State*)L, "lanes.core", luaopen_lanes_core, 1);
	ls_lua_pop(L, 1);
#endif /* OPT_BUILTIN_LUA_DLL_SUPPORT_EXT */

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

    ls_register_custom_libs(L);
    return 0;
}


#ifdef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

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

#endif // OPT_BUILTIN_LUA_DLL_SUPPORT_EXT


void ls_lua_init()
{
#ifdef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT
    char fileName[4096];
    LIST *luaSharedLibrary;
#ifdef OS_NT
    HINSTANCE handle = NULL;
#else
    void* handle = NULL;
#endif
#endif // OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

    if (L)
        return;

#ifdef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

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
        strcat(fileName, "/lua/lua53.dll");
#else
        strcat(fileName, "/lua/lua53.dll");
#endif
#else
#ifdef _DEBUG
        strcat(fileName, "/lua/liblua53_debug.so");
#else
        strcat(fileName, "/lua/liblua53.so");
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
    ls_lua_rotate = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_rotate");

    ls_lua_isnumber = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isnumber");
    ls_lua_isstring = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isstring");
    ls_lua_isuserdata = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_isuserdata");
    ls_lua_type = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_type");

    ls_lua_tonumberx = (ls_lua_Number (*)(ls_lua_State *, int, int *))ls_lua_loadsymbol(handle, "lua_tonumberx");
    ls_lua_tointegerx = (ls_lua_Integer (*)(ls_lua_State *L, int idx, int *isnum))ls_lua_loadsymbol(handle, "lua_tointegerx");
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
    ls_lua_rawgeti = (void  (*) (ls_lua_State *, int, ls_lua_Integer))ls_lua_loadsymbol(handle, "lua_rawgeti");
    ls_lua_createtable = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "lua_createtable");

    ls_lua_setglobal = (void (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "lua_setglobal");
    ls_lua_settable = (void (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_settable");
    ls_lua_setfield = (void (*)(ls_lua_State *, int, const char *))ls_lua_loadsymbol(handle, "lua_setfield");
    ls_lua_seti = (void (*)(ls_lua_State *, int, ls_lua_Integer))ls_lua_loadsymbol(handle, "lua_seti");
    ls_lua_rawseti = (void (*)(ls_lua_State *, int, ls_lua_Integer))ls_lua_loadsymbol(handle, "lua_rawseti");

    ls_lua_pcallk = (int (*)(ls_lua_State *, int, int, int, ls_lua_KContext, ls_lua_CFunction))ls_lua_loadsymbol(handle, "lua_pcallk");

    ls_lua_len = (void (*) (ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_len");

    ls_lua_next = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "lua_next");

    ls_lua_getstack = (int(*)(ls_lua_State *, int, ls_lua_Debug *))ls_lua_loadsymbol(handle, "lua_getstack");
    ls_lua_getinfo = (int(*)(ls_lua_State *, const char *, ls_lua_Debug *))ls_lua_loadsymbol(handle, "lua_getinfo");

    ls_luaL_openlibs = (void (*)(ls_lua_State *))ls_lua_loadsymbol(handle, "luaL_openlibs");
    ls_luaL_loadstring = (int (*)(ls_lua_State *, const char *))ls_lua_loadsymbol(handle, "luaL_loadstring");
    ls_luaL_loadfilex = (int (*)(ls_lua_State *, const char *, const char *))ls_lua_loadsymbol(handle, "luaL_loadfilex");
    ls_luaL_gsub = (const char *(*)(ls_lua_State *, const char *, const char *, const char *))ls_lua_loadsymbol(handle, "luaL_gsub");
    ls_luaL_newstate = (ls_lua_State *(*)(void))ls_lua_loadsymbol(handle, "luaL_newstate");
    ls_luaL_ref = (int (*)(ls_lua_State *, int))ls_lua_loadsymbol(handle, "luaL_ref");
    ls_luaL_unref = (void (*)(ls_lua_State *, int, int))ls_lua_loadsymbol(handle, "luaL_unref");

    ls_luaL_error = (int (*)(ls_lua_State *L, const char *fmt, ...))ls_lua_loadsymbol(handle, "luaL_error");

#else

    ls_lua_close = (void (*)(ls_lua_State *))lua_close;

    ls_lua_gettop = (int (*)(ls_lua_State *))lua_gettop;
    ls_lua_settop = (void (*)(ls_lua_State *, int))lua_settop;
    ls_lua_pushvalue = (void (*)(ls_lua_State *, int))lua_pushvalue;
    ls_lua_rotate = (void (*)(ls_lua_State *, int, int))lua_rotate;

    ls_lua_isnumber = (int (*)(ls_lua_State *, int))lua_isnumber;
    ls_lua_isstring = (int (*)(ls_lua_State *, int))lua_isstring;
    ls_lua_isuserdata = (int (*)(ls_lua_State *, int))lua_isuserdata;
    ls_lua_type = (int (*)(ls_lua_State *, int))lua_type;

    ls_lua_tonumberx = (ls_lua_Number (*)(ls_lua_State *, int, int *))lua_tonumberx;
    ls_lua_tointegerx = (ls_lua_Integer (*)(ls_lua_State *L, int idx, int *isnum))lua_tointegerx;
    ls_lua_toboolean = (int (*)(ls_lua_State *, int))lua_toboolean;
    ls_lua_tolstring = (const char *(*)(ls_lua_State *, int, size_t *))lua_tolstring;
    ls_lua_rawlen = (size_t (*)(ls_lua_State *, int))lua_rawlen;

    ls_lua_pushnil = (void (*) (ls_lua_State *))lua_pushnil;
    ls_lua_pushnumber = (void (*) (ls_lua_State *, ls_lua_Number))lua_pushnumber;
    ls_lua_pushinteger = (void (*) (ls_lua_State *, ls_lua_Integer))lua_pushinteger;
    ls_lua_pushstring = (const char *(*) (ls_lua_State *, const char *))lua_pushstring;
    ls_lua_pushlstring = (const char *(*) (ls_lua_State *, const char *, size_t))lua_pushlstring;
    ls_lua_pushcclosure = (void (*) (ls_lua_State *, ls_lua_CFunction, int))lua_pushcclosure;
    ls_lua_pushboolean = (void (*)(ls_lua_State *, int))lua_pushboolean;

    ls_lua_getglobal = (void (*) (ls_lua_State *, const char *))lua_getglobal;
    ls_lua_gettable = (void (*) (ls_lua_State *, int id))lua_gettable;
    ls_lua_getfield = (void (*)(ls_lua_State *, int, const char *))lua_getfield;
    ls_lua_rawgeti = (void  (*) (ls_lua_State *, int, ls_lua_Integer))lua_rawgeti;
    ls_lua_createtable = (void (*)(ls_lua_State *, int, int))lua_createtable;

    ls_lua_setglobal = (void (*)(ls_lua_State *, const char *))lua_setglobal;
    ls_lua_settable = (void (*)(ls_lua_State *, int))lua_settable;
    ls_lua_setfield = (void (*)(ls_lua_State *, int, const char *))lua_setfield;
    ls_lua_seti = (void (*)(ls_lua_State *, int, ls_lua_Integer))lua_seti;
    ls_lua_rawseti = (void (*)(ls_lua_State *, int, ls_lua_Integer))lua_rawseti;

    ls_lua_pcallk = (int (*)(ls_lua_State *, int, int, int, ls_lua_KContext, ls_lua_CFunction))lua_pcallk;

    ls_lua_len = (void (*)(ls_lua_State *L, int idx))lua_len;

    ls_lua_next = (int (*)(ls_lua_State *, int))lua_next;

    ls_lua_getstack = (int(*)(ls_lua_State *, int, ls_lua_Debug *))lua_getstack;
    ls_lua_getinfo = (int(*)(ls_lua_State *, const char *, ls_lua_Debug *))lua_getinfo;

    ls_luaL_openlibs = (void (*)(ls_lua_State *))luaL_openlibs;
    ls_luaL_loadbufferx = (int (*)(ls_lua_State *L, const char *, size_t, const char *, const char *))luaL_loadbufferx;
    ls_luaL_loadstring = (int (*)(ls_lua_State *, const char *))luaL_loadstring;
    ls_luaL_loadfilex = (int (*)(ls_lua_State *, const char *, const char *))luaL_loadfilex;
    ls_luaL_newstate = (ls_lua_State *(*)(void))luaL_newstate;
    ls_luaL_gsub = (const char *(*)(ls_lua_State *, const char *, const char *, const char *))luaL_gsub;
    ls_luaL_ref = (int (*)(ls_lua_State *, int))luaL_ref;
    ls_luaL_unref = (void (*)(ls_lua_State *, int, int))luaL_unref;

    ls_luaL_error = (int (*)(ls_lua_State *L, const char *fmt, ...))luaL_error;

#endif // OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

    L = ls_luaL_newstate();

	{
        char exeName[4096];
        getexecutablepath(exeName, sizeof(exeName));
        ls_lua_pushlstring(L, exeName, strlen(exeName));
        ls_lua_setglobal(L, "JAM_EXECUTABLE");

        getprocesspath(exeName, sizeof(exeName));
        ls_lua_pushlstring(L, exeName, strlen(exeName));
        ls_lua_setglobal(L, "JAM_EXECUTABLE_PATH");
    }

    ls_lua_pushcclosure(L, &pmain, 0);
    ls_lua_pcall(L, 0, 0, 0);

#ifdef OPT_BUILTIN_LUA_DLL_SUPPORT_EXT
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
#endif // OPT_BUILTIN_LUA_DLL_SUPPORT_EXT

    if (ruleexists("LuaSupport"))
    {
        LOL lol;
        LIST *result;
        lol_init(&lol);
        result = evaluate_rule("LuaSupport", &lol, L0);
        lol_free(&lol);
        list_free(result);
    }
}


int luahelper_taskadd(const char* taskscript, LOL* args)
{
    int ret;
    int ref;
    size_t taskscriptlen = strlen(taskscript);
    char* newTaskScript;
	int i;

    ls_lua_init();

    ls_lua_getglobal(L, "lanes");                             /* lanes */
    ls_lua_getfield(L, -1, "gen");                            /* lanes gen */
    ls_lua_pushstring(L, "*");                                /* lanes gen * */

    newTaskScript = (char*)malloc( taskscriptlen + 1 );
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

    for (i = 0; i < args->count; ++i)
    {
        LIST* list = lol_get(args, i);
        LISTITEM *l2;
        int index = 0;
        ls_lua_newtable(L);
		for (l2 = list_first(list); l2; l2 = list_next(l2))
		{
			ls_lua_pushstring(L, list_value(l2));
			ls_lua_rawseti(L, -2, ++index);
		}
    }

    ret = ls_lua_pcall(L, args->count, 1, 0);                        /* lanes ret */
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


int luahelper_taskisrunning(intptr_t taskid, int* returnValue)
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


void luahelper_taskcancel(intptr_t taskid)
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

    out = (char*)malloc(ls_lua_rawlen(L, -1) + 1);
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
    if (ret != 0) {
        int entryIndex = zip_findfile(list_value(list_first(l)));
        if (entryIndex != -1)
        {
            char filename[512];
            mz_zip_archive *pZipArchive = zip_attemptopen();
            mz_uint filenameLength = mz_zip_reader_get_filename(pZipArchive, entryIndex, filename, sizeof(filename));
            size_t bufferSize;
            unsigned char* buffer = (unsigned char*)mz_zip_reader_extract_to_heap(pZipArchive, entryIndex, &bufferSize, 0);
            ret = ls_luaL_loadbufferx(L, (const char*)buffer, bufferSize, filename, NULL);
            pZipArchive->m_pFree(pZipArchive->m_pAlloc_opaque, buffer);
        }
    }
    return ls_lua_callhelper(top, ret);
}


LIST* luahelper_call_script(const char* filename, LIST* args)
{
    int top;
    int ret;
    LISTITEM *l2;
    int index = 0;

    ls_lua_init();
    top = ls_lua_gettop(L);
    ls_lua_newtable(L);
    for (l2 = list_first(args); l2; l2 = list_next(l2)) {
        ls_lua_pushstring(L, list_value(l2));
        ls_lua_rawseti(L, -2, ++index);
    }
    ls_lua_setglobal(L, "arg");
    ret = ls_luaL_loadfile(L, filename);
    if (ret != 0) {
        int entryIndex = zip_findfile(filename);
        if (entryIndex != -1)
        {
            char filename[512];
            mz_zip_archive *pZipArchive = zip_attemptopen();
            mz_uint filenameLength = mz_zip_reader_get_filename(pZipArchive, entryIndex, filename, sizeof(filename));
            size_t bufferSize;
            unsigned char* buffer = (unsigned char*)mz_zip_reader_extract_to_heap(pZipArchive, entryIndex, &bufferSize, 0);
            ret = ls_luaL_loadbufferx(L, (const char*)buffer, bufferSize, filename, NULL);
            pZipArchive->m_pFree(pZipArchive->m_pAlloc_opaque, buffer);
        }
    }
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

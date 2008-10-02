#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

extern "C"
{
#include "jam.h"
#include "lists.h"
#include "parse.h"
#include "compile.h"
#include "rules.h"
#include "variable.h"
}

#include <windows.h>
#undef LoadString
#include "LuaPlus/LuaPlus.h"

using namespace LuaPlus;

LuaState* state;


static LIST *luahelper_addtolist(LIST *list, LuaObject& obj)
{
    if (obj.IsBoolean())
	return list_new(list, obj.GetBoolean() ? "true" : "false", 0);

    if (obj.IsNumber())
	return list_new(list, obj.ToString(), 0);

    if (obj.IsString())
	return list_new(list, obj.GetString(), 0);

    else if (obj.IsTable())
    {
	for (LuaTableIterator it(obj); it; ++it)
	{
	    list = luahelper_addtolist(list, it.GetValue());
	}
    }

    return list;
}


int LS_jam_setvar(LuaState* state)
{
    int numParams = state->GetTop();
    if (numParams < 2  ||  numParams > 3)
	return 0;

    LuaObject param1Obj(state, 1);
    if (!param1Obj.IsString())
	return 0;
    LuaObject param2Obj(state, 2);

    if (numParams == 2)
    {
	var_set(param1Obj.GetString(), luahelper_addtolist(L0, param2Obj), VAR_SET);
    }
    else
    {
	if (!param2Obj.IsString())
	    return 0;
	LuaObject param3(state, 3);

	TARGET *t = bindtarget(param1Obj.GetString());
	pushsettings(t->settings);
	var_set(param2Obj.GetString(), luahelper_addtolist(L0, param3), VAR_SET);
	popsettings(t->settings);
    }

    return 0;
}


int LS_jam_getvar(LuaState* state)
{
    int numParams = state->GetTop();
    if (numParams < 1  ||  numParams > 2)
	return 0;

    LuaObject param1Obj(state, 1);
    if (!param1Obj.IsString())
	return 0;

    LIST *list;
    if (numParams == 1)
    {
	list = var_get(param1Obj.GetString());
    }
    else
    {
	LuaObject param2Obj(state, 2);
	if (!param2Obj.IsString())
	    return 0;

	TARGET *t = bindtarget(param1Obj.GetString());
	pushsettings(t->settings);
	list = var_get(param2Obj.GetString());
	popsettings(t->settings);
    }

    LuaObject tableObj;
    tableObj.AssignNewTable(state);
    int index = 1;
    for (; list; list = list_next(list), ++index)
    {
	tableObj.SetString(index, list->string);
    }
    tableObj.Push();

    return 1;
}


int LS_jam_evaluaterule(LuaState* state)
{
    int numParams = state->GetTop();
    if (numParams < 1)
	return 0;

    LuaObject ruleNameObj(state, 1);
    if (!ruleNameObj.IsString())
	return 0;

    LOL lol;
    lol_init(&lol);

    for (int i = 0; i < numParams - 1; ++i)
    {
	LuaObject paramObj(state, 2 + i);
	lol_add(&lol, luahelper_addtolist(L0, paramObj));
    }
    LIST *list = evaluate_rule(ruleNameObj.GetString(), &lol, L0);
    lol_free(&lol);

    LuaObject tableObj;
    tableObj.AssignNewTable(state);
    int index = 1;
    for (; list; list = list_next(list), ++index)
    {
	tableObj.SetString(index, list->string);
    }
    tableObj.Push();

    return 1;
}


void lua_init()
{
    if (state)
	return;

    LIST *luaSharedLibrary;
#ifdef _DEBUG
    luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.DEBUG");
#else
    luaSharedLibrary = var_get("LUA_SHARED_LIBRARY.RELEASE");
#endif
    HINSTANCE hInstance = NULL;
    if (luaSharedLibrary)
    {
	hInstance = LoadLibrary(luaSharedLibrary->string);
    }
    if (!hInstance)
    {
	char fileName[_MAX_PATH];
	GetModuleFileName(NULL, fileName, _MAX_PATH);

	char *ptr = strrchr(fileName, '\\');
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
	HINSTANCE hInstance = LoadLibrary(fileName);
	if (!hInstance)
	{
	    printf("jam: Unable to find the LuaPlus DLL.\n");
	    exit(EXITBAD);
	}
    }

    state = LuaState::Create(true);
    state->GetGlobals().Register("jam_getvar", LS_jam_getvar);
    state->GetGlobals().Register("jam_setvar", LS_jam_setvar);
    state->GetGlobals().Register("jam_evaluaterule", LS_jam_evaluaterule);
    state->DoString("require 'task'");
}


/*
*/

static LIST *lua_callhelper(int top, int ret)
{
    LuaAutoBlock autoBlock(state);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error compiling Lua code\n");
	    printf(errObj.GetString());
	    printf("\n");
	    exit(EXITBAD);
	}
	state->Pop();
	return L0;
    }

    ret = state->PCall(0, -1, 0);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error running Lua code\n");
	    printf(errObj.GetString());
	    printf("\n");
	    exit(EXITBAD);
	}
	state->Pop();
	return L0;
    }

    LIST *retList = L0;

    int numParams = state->GetTop() - top;
    for (int i = 0; i < numParams; ++i)
    {
	LuaObject retObj(state, top + i + 1);
	retList = luahelper_addtolist(retList, retObj);
    }

    return retList;
}


extern "C" int luahelper_taskadd(const char* taskCode)
{
    lua_init();
    LuaAutoBlock autoBlock(state);
    /*
    int ret = state->LoadString(taskCode);
    if (ret != 0)
    {
    LuaStackObject errObj(state, -1);
    if (errObj.IsString())
    {
    printf("jam: Error compiling Lua task code\n");
    printf(errObj.GetString());
    printf("\n");
    //			exit(EXITBAD);
    }
    state->Pop();
    return -1;
    }

    LuaObject chunkObj(state, -1);
    */
    LuaObject taskObj = state->GetGlobal("task");
    LuaObject createObj = taskObj["create"];
    createObj.Push();
    //	chunkObj.Push();
    state->PushString(taskCode);

    int ret = state->PCall(1, -1, 0);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error creating Lua task\n");
	    printf(errObj.GetString());
	    printf("\n");
	}
	state->Pop();
	return -1;
    }

    LuaObject taskIdObj(state, -1);
    if (taskIdObj.IsNumber())
	return taskIdObj.GetInteger();

    return -1;
}


extern "C" int luahelper_taskisrunning(int taskId)
{
    lua_init();
    LuaAutoBlock autoBlock(state);
    LuaObject taskObj = state->GetGlobal("task");
    LuaObject isrunningObj = taskObj["isrunning"];
    isrunningObj.Push();
    state->PushInteger(taskId);

    int ret = state->PCall(1, -1, 0);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error testing Lua task.isrunning\n");
	    printf(errObj.GetString());
	    printf("\n");
	}
	state->Pop();
	return -1;
    }

    LuaObject retObj(state, -1);
    if (retObj.IsBoolean())
	return retObj.GetBoolean() ? 1 : 0;

    return 0;
}


extern "C" void luahelper_taskcancel(int taskId)
{
    lua_init();
    LuaAutoBlock autoBlock(state);
    LuaObject taskObj = state->GetGlobal("task");
    LuaObject functionObj = taskObj["cancel"];
    functionObj.Push();
    state->PushInteger(taskId);

    int ret = state->PCall(1, -1, 0);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error running Lua task.cancel\n");
	    printf(errObj.GetString());
	    printf("\n");
	}
	state->Pop();
	return;
    }
}


#ifdef OPT_BUILTIN_MD5CACHE_EXT

extern "C" int luahelper_md5callback(const char *filename, MD5SUM sum, const char* callback)
{
    lua_init();
    LuaAutoBlock autoBlock(state);
    LuaObject callbackObj = state->GetGlobal(callback);
    if (!callbackObj.IsFunction())
    {
	printf("jam: Error calling Lua md5 callback '%s'.\n", callback);
	memset(sum, 0, sizeof(MD5SUM));
	return 0;
    }
    callbackObj.Push();
    state->PushString(filename);
    int ret = state->PCall(1, 1, 0);
    if (ret != 0)
    {
	LuaStackObject errObj(state, -1);
	if (errObj.IsString())
	{
	    printf("jam: Error running Lua md5 callback '%s'.\n", callback);
	    printf(errObj.GetString());
	    printf("\n");
	}
	state->Pop();
	memset(sum, 0, sizeof(MD5SUM));
	return 0;
    }

    LuaStackObject md5Obj(state, -1);
    if (md5Obj.IsNil())
    {
	memset(sum, 0, sizeof(MD5SUM));
	return 0;
    }

    if (!md5Obj.IsString()  ||  md5Obj.StrLen() != sizeof(MD5SUM))
    {
	printf("jam: Error running Lua md5 callback '%s'.\n", callback);
	memset(sum, 0, sizeof(MD5SUM));
	return 0;
    }

    memcpy(sum, md5Obj.GetString(), sizeof(MD5SUM));
    return 1;
}

#endif

	    
extern "C" LIST *
builtin_luastring(
		  PARSE	*parse,
		  LOL		*args,
		  int		*jmp)
{
    LIST *l = lol_get(args, 0);
    if (!l)
    {
	printf("jam: No argument passed to LuaString\n");
	exit(EXITBAD);
    }
    lua_init();
    LuaAutoBlock autoBlock(state);
    int top = state->GetTop();
    int ret = state->LoadString(l->string);
    return lua_callhelper(top, ret);
}


extern "C" LIST *
builtin_luafile(
		PARSE	*parse,
		LOL		*args,
		int		*jmp)
{
    LIST *l = lol_get(args, 0);
    if (!l)
    {
	printf("jam: No argument passed to LuaFile\n");
	exit(EXITBAD);
    }
    lua_init();
    LuaAutoBlock autoBlock(state);
    int top = state->GetTop();
    int ret = state->LoadFile(l->string);
    return lua_callhelper(top, ret);
}


void lua_shutdown()
{
    if (state)
    {
	LuaState::Destroy(state);
	state = NULL;
    }
}

#endif

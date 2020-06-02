/*
 * "ex" API implementation
 * http://lua-users.org/wiki/ExtensionProposal
 * Copyright 2007 Mark Edgar < medgar at student gc maricopa edu >
 */
#ifndef osprocess_pusherror_h
#define osprocess_pusherror_h

#include <windows.h>
#include "lua.h"

int osprocess_windows_pusherror(lua_State *L, DWORD error, int nresults);
#define osprocess_windows_pushlasterror(L) osprocess_windows_pusherror(L, GetLastError(), -2)

#endif/*osprocess_pusherror_h*/

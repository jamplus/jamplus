// luaexpat
#define XML_STATIC
#ifndef _WIN32
#define HAVE_MEMMOVE
//#define HAVE_GETRANDOM
#endif
#ifdef __APPLE__
#define HAVE_ARC4RANDOM_BUF
#elif defined(__linux__)
#define HAVE_GETRANDOM
#elif defined(__FreeBSD__)
#define HAVE_ARC4RANDOM_BUF
#endif
#include "luaplus/Src/Modules/libexpat/expat/lib/xmlparse.c"
#include "luaplus/Src/Modules/libexpat/expat/lib/xmlrole.c"
#include "luaplus/Src/Modules/libexpat/expat/lib/xmltok.c"
#include "luaplus/Src/Modules/libexpat/expat/lib/xmltok_impl.c"
#include "luaplus/Src/Modules/libexpat/expat/lib/xmltok_ns.c"
#include "luaplus/Src/Modules/luaexpat/src/lxplib.c"
#include "luaplus/Src/Modules/libexpat/expat/lib/loadlibrary.c"


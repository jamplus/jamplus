#ifdef NT
#ifdef OPT_BUILTIN_W32_GETREG_EXT

#include "jam.h"
#include "lists.h"
#include "w32_getreg.h"
#include "newstr.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

struct keydef
{
    const char* keyname;
    HKEY keyval;
};

static struct keydef keynames[] = {
    { "HKEY_LOCAL_MACHINE", HKEY_LOCAL_MACHINE },
    { "HKEY_CURRENT_USER", HKEY_CURRENT_USER },
    { "HKEY_LOCAL_MACHINE", HKEY_LOCAL_MACHINE },
    { "HKEY_CLASSES_ROOT", HKEY_CLASSES_ROOT },
    { 0, 0 }
};


/*
 * Get a value from the Windows registry and return it as a string.
 */
const char*
w32_getreg(LIST* pathlist)
{
    HKEY key = HKEY_LOCAL_MACHINE;
    const char* valueName = 0;
    struct keydef *keydefs = keynames;
    DWORD dataType  = 0;
    DWORD dataSize  = 0;
    char* dataValue = 0;
    const char* retval = 0;
	    
    if (!pathlist) return 0;

    while (keydefs->keyname) {
	if (!strcmp(pathlist->string, keydefs->keyname)) {
	    key = keydefs->keyval;
	    pathlist = list_next(pathlist);
	    break;
	}
	++keydefs;
    }

    if (!keydefs->keyname) return 0;

    for ( ; pathlist ; pathlist = list_next(pathlist)) {
        const char* text = pathlist->string;
        if (valueName) {            
            DWORD retCode = RegOpenKeyEx(key, valueName, 0,
                                         KEY_EXECUTE |
                                         KEY_QUERY_VALUE |
                                         KEY_ENUMERATE_SUB_KEYS, &key);
            if (retCode != ERROR_SUCCESS) {
		return 0;
	    }
        }
        valueName = text;
    }

    if (!valueName) {
	return 0;
    }
    
    {
        DWORD retCode = RegQueryValueEx(key,
                                        valueName,
                                        0,
                                        &dataType,
                                        0,
                                        &dataSize);

        if (retCode != ERROR_SUCCESS) {
	    return 0;
	}

        switch (dataType) {
	case REG_SZ:
	case REG_EXPAND_SZ:
	    break;
	default:
	    return 0;
        }

        if (dataSize < 1) {
	    return 0;
	}

        dataSize += 5;
        dataValue = malloc(dataSize);

        retCode = RegQueryValueEx(key,
                                  valueName,
                                  0,
                                  &dataType,
                                  (LPBYTE)dataValue,
                                  &dataSize);

        if (retCode != ERROR_SUCCESS) {
	    free(dataValue);
            return 0;
        }
	retval = newstr(dataValue);
	free(dataValue);
	return retval;
    }
}

#endif
#endif

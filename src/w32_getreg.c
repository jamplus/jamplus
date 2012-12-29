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
w32_getreg_internal(LIST* pathlist, INT is64Bit)
{
    HKEY key = HKEY_LOCAL_MACHINE;
    const char* valueName = 0;
    struct keydef *keydefs = keynames;
    DWORD dataType  = 0;
    DWORD dataSize  = 0;
    char* dataValue = 0;
	const char* retval = 0;
	LISTITEM* curEl = list_first(pathlist);
	    
    if (!curEl) return 0;

    while (keydefs->keyname) {
	if (!strcmp(list_value(curEl), keydefs->keyname)) {
	    key = keydefs->keyval;
	    curEl = list_next(curEl);
	    break;
	}
	++keydefs;
    }

    if (!keydefs->keyname) return 0;

    for ( ; curEl ; curEl = list_next(curEl)) {
        const char* text = list_value(curEl);
        if (valueName) {            
            DWORD retCode = RegOpenKeyEx(key, valueName, 0,
                                         KEY_EXECUTE |
                                         KEY_QUERY_VALUE |
										 ( is64Bit ? KEY_WOW64_64KEY : 0 ) |
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
	case REG_DWORD:
	    break;
	default:
	    return 0;
        }

        if (dataSize < 1) {
	    return 0;
	}

		if ( dataType == REG_DWORD )
		{
			dataSize = sizeof( DWORD );
		}
		else
		{
			dataSize += 5;
		}
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

	if ( dataType == REG_DWORD )
	{
		char buffer[ 128 ];
		itoa( ( ( DWORD *)dataValue )[ 0 ], buffer, 10 );
		retval = newstr( buffer );
	}
	else
	{
		retval = newstr(dataValue);
	}
	free(dataValue);
	return retval;
    }
}

const char*
w32_getreg(LIST* pathlist)
{
	const char* ret = w32_getreg_internal( pathlist, 0); 
	if (ret == 0) ret = w32_getreg_internal( pathlist, 1);
	return ret;
}

#ifdef OPT_BUILTIN_W32_GETREG64_EXT
const char*
w32_getreg64(LIST* pathlist)
{
	return w32_getreg_internal( pathlist, 1 );
}
#endif

#endif
#endif

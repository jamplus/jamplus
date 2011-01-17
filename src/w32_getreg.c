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

typedef BOOL (WINAPI *LPFN_ISWOW64PROCESS) (HANDLE, PBOOL);

LPFN_ISWOW64PROCESS fnIsWow64Process;

BOOL Is64BitWindows()
{
#if defined(_WIN64)
	return TRUE;  // 64-bit programs run only on Win64
#elif defined(_WIN32)
	BOOL bIsWow64 = FALSE;

	//IsWow64Process is not available on all supported versions of Windows.
	//Use GetModuleHandle to get a handle to the DLL that contains the function
	//and GetProcAddress to get a pointer to the function if available.

	fnIsWow64Process = (LPFN_ISWOW64PROCESS) GetProcAddress(
		GetModuleHandle(TEXT("kernel32")),"IsWow64Process");

	if (NULL != fnIsWow64Process)
	{
		if (!fnIsWow64Process(GetCurrentProcess(),&bIsWow64))
		{
			//handle error
			return FALSE;
		}
	}
	return bIsWow64;

#else
	return FALSE; // Win64 does not support Win16
#endif
}


const char*
w32_getreg(LIST* pathlist)
{
	return w32_getreg_internal( pathlist, Is64BitWindows() == TRUE ? 1 : 0 );
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

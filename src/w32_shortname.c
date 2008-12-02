#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT

#include "jam.h"
#include "lists.h"
#include "w32_shortname.h"
#include "newstr.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

const char*
w32_shortname(LIST* pathlist)
{
    LIST* savepathlist = pathlist;
    size_t buffer_size = 0;
    char* temp;
    const char* retval = 0;
    for ( ; pathlist ; pathlist = list_next(pathlist)) {
	const char* text = pathlist->string;
	buffer_size += strlen(text) + 1;
    }
    buffer_size++;
    {
	size_t retlen;
	size_t length;

	temp = malloc(buffer_size);
	temp[0] = 0;
	pathlist = savepathlist;

	for ( ; pathlist ; pathlist = list_next(pathlist)) {
	    strcat(temp, pathlist->string);
	    if (list_next(pathlist))
		strcat(temp, " ");
	}
	length = strlen(temp);
	retlen = GetShortPathName(temp, temp, (DWORD)length);
	if (retlen != 0 && retlen != length)
	    retval = newstr(temp);
	free(temp);
    }
    return retval;
}

#endif

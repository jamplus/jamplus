#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT

#include "jam.h"
#include "lists.h"
#include "w32_shortname.h"
#include "newstr.h"

#define WIN32_LEAN_AND_MEAN
#include <windows.h>

const char*
w32_shortname(NewList* pathlist)
{
    size_t buffer_size = 0;
    char* temp;
    const char* retval = 0;
    NewListItem* item;
    for (item = newlist_first(pathlist) ; item ; item = newlist_next(item)) {
	const char* text = newlist_value(item);
	buffer_size += strlen(text) + 1;
    }
    buffer_size++;
    {
	size_t retlen;
	size_t length;

	temp = malloc(buffer_size);
	temp[0] = 0;

	for (item = newlist_first(pathlist); item ; item = newlist_next(item)) {
	    strcat(temp, newlist_value(item));
	    if (newlist_next(item))
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

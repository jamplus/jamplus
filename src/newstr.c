/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * newstr.c - string manipulation routines
 *
 * To minimize string copying, string creation, copying, and freeing
 * is done through newstr.
 *
 * External functions:
 *
 *    newstr() - return a malloc'ed copy of a string
 *    copystr() - return a copy of a string previously returned by newstr()
 *    freestr() - free a string returned by newstr() or copystr()
 *    donestr() - free string tables
 *
 * Once a string is passed to newstr(), the returned string is readonly.
 *
 * This implementation builds a hash table of all strings, so that multiple 
 * calls of newstr() on the same string allocate memory for the string once.
 * Strings are never actually freed.
 *
 * 11/04/02 (seiwald) - const-ing for string literals
 */

# include "jam.h"
# include "newstr.h"
# include "hash.h"

typedef const char *STRING;

static struct hash *strhash = 0;
static size_t strtotal = 0;
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
static long str_allocs = 0;
#endif
#ifdef OPT_IMPROVED_MEMUSE_EXT
static char* str_allocbuf = NULL;
static char* str_allocend = NULL;
#define STR_ALLOCSIZE (1024 * 128)
#endif

/*
 * newstr() - return a malloc'ed copy of a string
 */

const char *
newstr( const char *string )
{
	STRING str, *s = &str;

	if( !strhash )
	    strhash = hashinit( sizeof( STRING ), "strings" );

	*s = string;

	if( hashenter( strhash, (HASHDATA **)&s ) )
	{
	    size_t l = strlen( string );
#ifdef OPT_IMPROVED_MEMUSE_EXT
	    char *m;

	    if (!str_allocbuf || (str_allocbuf + l + 1) >= str_allocend) {
		str_allocbuf = malloc( l + 1 );
		str_allocend = str_allocbuf + l + 1;
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
		++str_allocs;
#endif
	    }
	    m = str_allocbuf;
	    str_allocbuf += (l + 1);
#else
	    char *m = (char *)malloc( l + 1 );

	    if (DEBUG_MEM)
		    printf("newstr: allocating %d bytes\n", l + 1 );
#endif

	    strtotal += l + 1;
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
#ifndef OPT_IMPROVED_MEMUSE_EXT
	    ++str_allocs;
#endif
#endif
	    memcpy( m, string, l + 1 );
	    *s = m;
	}

	return *s;
}

/*
 * copystr() - return a copy of a string previously returned by newstr()
 */

const char *
copystr( const char *s )
{
	return s;
}

/*
 * freestr() - free a string returned by newstr() or copystr()
 */

void
freestr( const char *s )
{
}

/*
 * donestr() - free string tables
 */

void
donestr()
{
	hashdone( strhash );

#ifdef OPT_DEBUG_MEM_TOTALS_EXT
	if (!DEBUG_MEM && DEBUG_MEM_TOTALS) {
	    printf("%dK in strings (%ld allocs)\n",
		   (int)(strtotal / 1024), str_allocs);
	}
#else
	if( DEBUG_MEM )
	    printf( "%dK in strings\n", strtotal / 1024 );
#endif
}

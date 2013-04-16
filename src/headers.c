/*
 * Copyright 1993, 2000 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * headers.c - handle #includes in source files
 *
 * Using regular expressions provided as the variable $(HDRSCAN),
 * headers() searches a file for #include files and phonies up a
 * rule invocation:
 *
 *	$(HDRRULE) <target> : <include files> ;
 *
 * External routines:
 *    headers() - scan a target for include files and call HDRRULE
 *
 * Internal routines:
 *    headers1() - using regexp, scan a file and build include LIST
 *
 * 04/13/94 (seiwald) - added shorthand L0 for null list pointer
 * 09/10/00 (seiwald) - replaced call to compile_rule with evaluate_rule,
 *		so that headers() doesn't have to mock up a parse structure
 *		just to invoke a rule.
 * 03/02/02 (seiwald) - rules can be invoked via variable names
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/09/02 (seiwald) - push regexp creation down to headers1().
 */

# include "jam.h"
# include "lists.h"
# include "parse.h"
# include "compile.h"
# include "rules.h"
# include "variable.h"
# include "regexp.h"
# include "headers.h"
# include "newstr.h"
# include "hash.h"

#ifdef OPT_HEADER_CACHE_EXT
# include "hcache.h"
#endif

#ifndef OPT_HEADER_CACHE_EXT
static LIST *headers1( const char *file, LIST *hdrscan );
#endif

#ifdef OPT_HDRPIPE_EXT
# include "buffer.h"
# include "filesys.h"
#endif


/*
 * headers() - scan a target for include files and call HDRRULE
 */

# define MAXINC 10

void
headers( TARGET *t )
{
	LIST	*hdrscan;
	LIST	*hdrrule;
	LOL	lol;

	if( !list_first( hdrscan = var_get( "HDRSCAN" ) ) ||
	    !list_first( hdrrule = var_get( "HDRRULE" ) ) )
	        return;

	/* Doctor up call to HDRRULE rule */
	/* Call headers1() to get LIST of included files. */

	if( DEBUG_HEADER )
	    printf( "header scan %s\n", t->name );

	lol_init( &lol );

	lol_add( &lol, list_append( L0, t->name, 1 ) );
#ifdef OPT_HEADER_CACHE_EXT
	lol_add( &lol, hcache( t, hdrscan ) );
#else
	lol_add( &lol, headers1( t->boundname, hdrscan ) );
#endif

	if( list_first(lol_get( &lol, 1 )) )
	{
#ifdef OPT_HDRRULE_BOUNDNAME_ARG_EXT
	    /* The third argument to HDRRULE is the bound name of
	     * $(<) */
	    lol_add( &lol, list_append( L0, t->boundname, 0 ) );
#endif
	    list_free( evaluate_rule( list_value(list_first(hdrrule)), &lol, L0 ) );
	}

	/* Clean up */

	lol_free( &lol );
}

#ifdef OPT_HDRPIPE_EXT

extern struct hash *regexhash;

typedef struct
{
    const char *name;
    regexp *re;
} regexdata;

/* OPT_HDRPIPE_EXT -- http://maillist.perforce.com/pipermail/jamming/2002-June/001717.html */

/*
 * headers1() - using regexp, scan a file and build include LIST
 */

static LIST *headers1helper(
	FILE *f,
	LIST *hdrscan )
{
	int	i;
	int	rec = 0;
	LIST	*result = 0;
	regexp	*re[ MAXINC ];
	char	buf[ 1024 ];
	LIST	*hdrdownshift;
	int	dodownshift = 1;
	LISTITEM* pattern;

#ifdef OPT_IMPROVED_PATIENCE_EXT
	static int count = 0;
	++count;
	if ( ((count == 100) || !( count % 1000 )) && DEBUG_MAKE )
	    printf("*** patience...\n");
#endif

	hdrdownshift = var_get( "HDRDOWNSHIFT" );
	if ( list_first(hdrdownshift) )
	{
		char const* str = list_value(list_first(hdrdownshift));
	    dodownshift = strcmp( str, "false" ) != 0  &&
		    strcmp( str, "0" ) != 0;
	}

	if ( !regexhash )
	    regexhash = hashinit( sizeof(regexdata), "regex" );

	pattern = list_first(hdrscan);
	while( rec < MAXINC && pattern )
	{
	    regexdata data, *d = &data;
	    data.name = list_value(pattern);
	    if( !hashcheck( regexhash, (HASHDATA **)&d ) )
	    {
		d->re = jam_regcomp( list_value(pattern) );
		(void)hashenter( regexhash, (HASHDATA **)&d );
	    }
	    re[rec++] = d->re;
	    pattern = list_next( pattern );
	}

	while( fgets( buf, sizeof( buf ), f ) )
	{
	    for( i = 0; i < rec; i++ )
		if( jam_regexec( re[i], buf ) && re[i]->startp[1] )
	    {
		/* Copy and terminate extracted string. */

		char buf2[ MAXSYM ];
		int l = (int)(re[i]->endp[1] - re[i]->startp[1]);
# ifdef DOWNSHIFT_PATHS
		if ( dodownshift )
		{
		    const char *target = re[i]->startp[1];
		    char *p = buf2;

		    if ( l > 0 )
		    {
			do *p++ = (char)tolower( *target++ );
			while( --l );
		    }

		    *p = 0;
		}
		else
# endif
		{
		memcpy( buf2, re[i]->startp[1], l );
		buf2[ l ] = 0;
		}

		result = list_append( result, buf2, 0 );

		if( DEBUG_HEADER )
		    printf( "header found: %s\n", buf2 );
	    }
	}

	return result;
}

LIST *
headers1(
	const char *file,
	LIST *hdrscan )
{
	FILE	*f;
	LIST	*result = 0;
	LIST    *hdrpipe;
	LIST	*hdrpipefile;

	if ( list_first(hdrpipe = var_get( "HDRPIPE" )) )
	{
		LOL args;
		BUFFER buff;
		lol_init( &args );
		lol_add( &args, list_append( L0, file, 0 ) );
		buffer_init( &buff );
		if ( var_string( list_value(list_first(hdrpipe)), &buff, 0, &args, ' ') < 0 )  {
		    printf( "Cannot expand HDRPIPE '%s' !\n", list_value(list_first(hdrpipe)) );
		    exit( EXITBAD );
		}
		buffer_addchar( &buff, 0 );
		if ( !( f = file_popen( (const char*)buffer_ptr( &buff ), "r" ) ) ) {
		    buffer_free( &buff );
		    return result;
		}
		buffer_free( &buff );
		lol_free( &args );
	}
	else
	{
		if( !( f = fopen( file, "r" ) ) )
		    return result;
	}

	result = headers1helper( f, hdrscan );

	if ( list_first(hdrpipe) )
		file_pclose( f );
	else
		fclose( f );

	if ( list_first(hdrpipefile = var_get( "HDRPIPEFILE" )) )
	{
		if( !( f = fopen( list_value(list_first(hdrpipefile)), "r" ) ) )
		    return result;
		result = headers1helper( f, hdrscan );
		fclose( f );
	}

	return result;
}

#else

struct hash *regexhash;

typedef struct
{
    const char *name;
    regexp *re;
} regexdata;

#ifndef OPT_HEADER_CACHE_EXT
static	/* Needs to be global if header caching is on */
#endif
LIST *
headers1(
	const char *file,
	LIST *hdrscan )
{
	FILE	*f;
	int	i;
	int	rec = 0;
	LIST	*result = 0;
	LISTITEM* pattern;
	regexp	*re[ MAXINC ];
	char	buf[ 1024 ];

#ifdef OPT_IMPROVED_PATIENCE_EXT
	static int count = 0;
	++count;
	if ( ((count == 100) || !( count % 1000 )) && DEBUG_MAKE )
	    printf("*** patience...\n");
#endif

	if( !( f = fopen( file, "r" ) ) )
	    return result;

	if ( !regexhash )
	    regexhash = hashinit( sizeof(regexdata), "regex" );

	pattern = list_first(hdrscan);
	while( rec < MAXINC && pattern )
	{
	    regexdata data, *d = &data;
	    data.name = list_value(pattern);
	    if( !hashcheck( regexhash, (HASHDATA **)&d ) )
	    {
		d->re = jam_regcomp( hdrscan->string );
		(void)hashenter( regexhash, (HASHDATA **)&d );
	    }
	    re[rec++] = d->re;
		pattern = list_next(pattern);
	}

	while( fgets( buf, sizeof( buf ), f ) )
	{
	    for( i = 0; i < rec; i++ )
		if( jam_regexec( re[i], buf ) && re[i]->startp[1] )
	    {
		/* Copy and terminate extracted string. */

		char buf2[ MAXSYM ];
		int l = re[i]->endp[1] - re[i]->startp[1];
# ifdef DOWNSHIFT_PATHS
		const char *target = re[i]->startp[1];
		char *p = buf2;

		do *p++ = tolower( *target++ );
		while( --l );

		*p = 0;
#else
		memcpy( buf2, re[i]->startp[1], l );
		buf2[ l ] = 0;
# endif
		result = list_append( result, buf2, 0 );

		if( DEBUG_HEADER )
		    printf( "header found: %s\n", buf2 );
	    }
	}

/*	while( rec )
	    free( (char *)re[--rec] );
*/
	fclose( f );

	return result;
}

#endif

/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * builtins.c - builtin jam rules
 *
 * External routines:
 *
 * 	load_builtin() - define builtin rules
 *
 * Internal routines:
 *
 *	builtin_depends() - DEPENDS/INCLUDES/NEEDS rule
 *	builtin_echo() - ECHO rule
 *	builtin_exit() - EXIT rule
 *	builtin_flags() - NOCARE, NOTFILE, TEMPORARY rule
 *	builtin_glob() - GLOB rule
 *	builtin_match() - MATCH rule
 *
 * 01/10/01 (seiwald) - split from compile.c
 * 01/08/01 (seiwald) - new 'Glob' (file expansion) builtin
 * 03/02/02 (seiwald) - new 'Match' (regexp match) builtin
 * 04/03/02 (seiwald) - Glob matches only filename, not directory
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 10/22/02 (seiwald) - working return/break/continue statements
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/03/02 (seiwald) - fix odd includes support by grafting them onto depends
 * 01/14/03 (seiwald) - fix includes fix with new internal includes TARGET
 */

# include "jam.h"

# include "lists.h"
# include "parse.h"
# include "builtins.h"
# include "rules.h"
# include "filesys.h"
# include "newstr.h"
# include "regexp.h"
# include "pathsys.h"

# include "buffer.h"
# include "variable.h"
# include "search.h"

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
# include "luasupport.h"
#endif

#ifdef OPT_SERIAL_OUTPUT_EXT
# include "execcmd.h"
#endif

/*
 * compile_builtin() - define builtin rules
 */

# define P0 (PARSE *)0
# define C0 (char *)0

LIST *builtin_depends( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_echo( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_exit( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_flags( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_glob( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_match( PARSE *parse, LOL *args, int *jmp );
#ifdef OPT_BUILTIN_SUBST_EXT
LIST *builtin_subst( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_MULTIPASS_EXT
LIST *builtin_queuejamfile( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_HEADER_CACHE_EXT
LIST *builtin_usedepcache( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_BUILTIN_MD5_EXT
LIST *builtin_usefilecache( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_usecommandline( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_md5( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_md5file( PARSE *parse, LOL *args, int *jmp );
#endif /* OPT_BUILTIN_MD5_EXT */
#ifdef OPT_BUILTIN_MATH_EXT
static LIST* builtin_math( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef NT
#ifdef OPT_BUILTIN_W32_GETREG_EXT
static LIST* builtin_w32_getreg( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT
static LIST* builtin_w32_shortname( PARSE *parse, LOL *args, int *jmp );
#endif
#endif
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
LIST *builtin_usemd5callback( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_SERIAL_OUTPUT_EXT
LIST *builtin_shell( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_GROUPBYVAR_EXT
LIST *builtin_groupbyvar( PARSE *parse, LOL *args, int *jmp );
#endif

int glob( const char *s, const char *c );

void
load_builtins()
{
    bindrule( "Always" )->procedure =
    bindrule( "ALWAYS" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_TOUCHED );

    bindrule( "Depends" )->procedure =
    bindrule( "DEPENDS" )->procedure =
	parse_make( builtin_depends, P0, P0, P0, C0, C0, 0 );

    bindrule( "echo" )->procedure =
    bindrule( "Echo" )->procedure =
    bindrule( "ECHO" )->procedure =
	parse_make( builtin_echo, P0, P0, P0, C0, C0, 0 );

    bindrule( "exit" )->procedure =
    bindrule( "Exit" )->procedure =
    bindrule( "EXIT" )->procedure =
	parse_make( builtin_exit, P0, P0, P0, C0, C0, 0 );

    bindrule( "Glob" )->procedure =
    bindrule( "GLOB" )->procedure =
	parse_make( builtin_glob, P0, P0, P0, C0, C0, 0 );

    bindrule( "Includes" )->procedure =
    bindrule( "INCLUDES" )->procedure =
	parse_make( builtin_depends, P0, P0, P0, C0, C0, 1 );

    bindrule( "Leaves" )->procedure =
    bindrule( "LEAVES" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_LEAVES );

    bindrule( "Match" )->procedure =
    bindrule( "MATCH" )->procedure =
	parse_make( builtin_match, P0, P0, P0, C0, C0, 0 );

    bindrule( "NoCare" )->procedure =
    bindrule( "NOCARE" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_NOCARE );

    bindrule( "NOTIME" )->procedure =
    bindrule( "NotFile" )->procedure =
    bindrule( "NOTFILE" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_NOTFILE );

    bindrule( "NoUpdate" )->procedure =
    bindrule( "NOUPDATE" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_NOUPDATE );

#ifdef OPT_BUILTIN_SUBST_EXT
	bindrule( "Subst" )->procedure =
	parse_make( builtin_subst, P0, P0, P0, C0, C0, 0 );
#endif

    bindrule( "Temporary" )->procedure =
    bindrule( "TEMPORARY" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_TEMP );

#ifdef OPT_MULTIPASS_EXT
    bindrule( "QueueJamfile" )->procedure =
	parse_make( builtin_queuejamfile, P0, P0, P0, C0, C0, 0 );
#endif

#ifdef OPT_BUILTIN_MD5_EXT
    bindrule( "MD5" )->procedure =
	parse_make( builtin_md5, P0, P0, P0, C0, C0, 0 );
    bindrule( "MD5File" )->procedure =
	parse_make( builtin_md5file, P0, P0, P0, C0, C0, 0 );
#endif /* OPT_BUILTIN_MD5_EXT */
#ifdef OPT_BUILTIN_MATH_EXT
    bindrule( "Math" )->procedure =
	parse_make( builtin_math, P0, P0, P0, C0, C0, 0 );
#endif
#ifdef NT
#ifdef OPT_BUILTIN_W32_GETREG_EXT
	bindrule( "W32_GETREG" )->procedure =
		parse_make( builtin_w32_getreg, P0, P0, P0, C0, C0, 0 );
#endif
#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT
	bindrule( "W32_SHORTNAME" )->procedure =
		parse_make( builtin_w32_shortname, P0, P0, P0, C0, C0, 0 );
#endif
#endif

#ifdef OPT_HEADER_CACHE_EXT
    bindrule( "UseDepCache" )->procedure =
 parse_make( builtin_usedepcache, P0, P0, P0, C0, C0, T_FLAG_USEDEPCACHE );
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
    bindrule( "UseFileCache" )->procedure =
 parse_make( builtin_usefilecache, P0, P0, P0, C0, C0, T_FLAG_USEFILECACHE );

    bindrule( "OptionalFileCache" )->procedure =
 parse_make( builtin_usefilecache, P0, P0, P0, C0, C0, T_FLAG_USEFILECACHE | T_FLAG_OPTIONALFILECACHE );

    bindrule( "UseCommandLine" )->procedure =
	parse_make( builtin_usecommandline, P0, P0, P0, C0, C0, T_FLAG_USECOMMANDLINE );

    bindrule( "ScanContents" )->procedure =
    bindrule( "SCANCONTENTS" )->procedure =
	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_SCANCONTENTS );
#endif

#ifdef OPT_BUILTIN_NEEDS_EXT
    bindrule( "MightNotUpdate" )->procedure =
    	parse_make( builtin_flags, P0, P0, P0, C0, C0, T_FLAG_MIGHTNOTUPDATE );

    bindrule( "Needs" )->procedure =
    bindrule( "NEEDS" )->procedure =
	parse_make( builtin_depends, P0, P0, P0, C0, C0, 2 );
#endif

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
    bindrule( "LuaString" )->procedure =
	parse_make( builtin_luastring, P0, P0, P0, C0, C0, 0 );

    bindrule( "LuaFile" )->procedure =
	parse_make( builtin_luafile, P0, P0, P0, C0, C0, 0 );

    bindrule( "UseMD5Callback" )->procedure =
	parse_make( builtin_usemd5callback, P0, P0, P0, C0, C0, 0 );
#endif
#ifdef OPT_SERIAL_OUTPUT_EXT
    bindrule( "Shell" )->procedure =
	parse_make( builtin_shell, P0, P0, P0, C0, C0, 0 );
#endif

#ifdef OPT_BUILTIN_GROUPBYVAR_EXT
	bindrule( "GroupByVar" )->procedure =
		parse_make( builtin_groupbyvar, P0, P0, P0, C0, C0, 0 );
#endif
}

/*
 * builtin_depends() - DEPENDS/INCLUDES/NEEDS rule
 *
 * The DEPENDS builtin rule appends each of the listed sources on the
 * dependency list of each of the listed targets.  It binds both the
 * targets and sources as TARGETs.
 */

LIST *
builtin_depends(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    int curindex = 0;
    while ( 1 )
    {
	LIST *targets = lol_get( args, curindex );
	LIST *sources = lol_get( args, curindex + 1 );
	LIST *l;

	if ( !sources )
	    break;

	for( l = targets; l; l = list_next( l ) )
	{
	    TARGET *t = bindtarget( l->string );

	    /* If doing INCLUDES, switch to the TARGET's include */
	    /* TARGET, creating it if needed.  The internal include */
	    /* TARGET shares the name of its parent. */

#ifdef OPT_BUILTIN_NEEDS_EXT
	    if( parse->num==1 )
#else
	    if( parse->num )
#endif
	    {
		if( !t->includes )
		    t->includes = copytarget( t );
		t = t->includes;
	    }

#ifdef OPT_BUILTIN_NEEDS_EXT
	    t->depends = targetlist( t->depends, sources, (char)(parse->num==2) );
#else
	    t->depends = targetlist( t->depends, sources );
#endif
	}

	++curindex;
    }

    return L0;
}

/*
 * builtin_echo() - ECHO rule
 *
 * The ECHO builtin rule echoes the targets to the user.  No other
 * actions are taken.
 */

LIST *
builtin_echo(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	list_print( lol_get( args, 0 ) );
	printf( "\n" );
	return L0;
}

/*
 * builtin_exit() - EXIT rule
 *
 * The EXIT builtin rule echoes the targets to the user and exits
 * the program with a failure status.
 */

LIST *
builtin_exit(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	list_print( lol_get( args, 0 ) );
	printf( "\n" );
	exit( EXITBAD ); /* yeech */
	return L0;
}

/*
 * builtin_flags() - NOCARE, NOTFILE, TEMPORARY rule
 *
 * Builtin_flags() marks the target with the appropriate flag, for use
 * by make0().  It binds each target as a TARGET.
 */

LIST *
builtin_flags(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );

	for( ; l; l = list_next( l ) )
	    bindtarget( l->string )->flags |= parse->num;

	return L0;
}

/*
 * builtin_globbing() - GLOB rule
 */

struct globbing {
	LIST	*patterns;
	LIST	*results;
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	const char *dirname;
	size_t	dirnamelen;
	int	prependdir;
#endif
} ;

#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
static void
builtin_glob_back(
	void	*closure,
	const char *file,
	int	status,
	time_t	time,
	int	dir )
{
	struct globbing *globbing = (struct globbing *)closure;
	LIST		*l;

	char buffer[ MAXJPATH ];
	if ( dir )
	{
	    strcpy( buffer, file );
	    strcat( buffer, "/" );
	    file = buffer;
	}

	for( l = globbing->patterns; l; l = l->next )
	{
	    if( !glob( l->string, file + globbing->dirnamelen ) )
	    {
		globbing->results = list_new( globbing->results, file + ( ( 1 - globbing->prependdir ) * globbing->dirnamelen ), 0 );
		break;
	    }
	}
}
#else
static void
builtin_glob_back(
	void	*closure,
	const char *file,
	int	status,
	time_t	time )
{
	struct globbing *globbing = (struct globbing *)closure;
	LIST		*l;
	PATHNAME	f;
	char		buf[ MAXJPATH ];

	/* Null out directory for matching. */
	/* We wish we had file_dirscan() pass up a PATHNAME. */

	path_parse( file, &f );
	f.f_dir.len = 0;
	path_build( &f, buf, 0 );

	for( l = globbing->patterns; l; l = l->next )
	    if( !glob( l->string, buf ) )
	{
	    globbing->results = list_new( globbing->results, file, 0 );
	    break;
	}
}
#endif

LIST *
builtin_glob(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *r = lol_get( args, 1 );
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	LIST *prepend = lol_get( args, 2 );
#endif

	struct globbing globbing;

	globbing.results = L0;
	globbing.patterns = r;
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	globbing.prependdir = 1;
	if ( prepend )
	{
	    if ( strcmp( prepend->string, "1" ) == 0  ||  strcmp( prepend->string, "true" ) == 0 )
		globbing.prependdir = 1;
	    else
		globbing.prependdir = 0;
	}

	for( ; l; l = list_next( l ) )
	{
	    globbing.dirname = l->string;
	    globbing.dirnamelen = strlen( l->string );
	    if ( globbing.dirname[ globbing.dirnamelen - 1 ] != '/'  &&  globbing.dirname[ globbing.dirnamelen - 1 ] != '\\' )
		globbing.dirnamelen++;
	    file_dirscan( l->string, builtin_glob_back, &globbing );
	}
#else
	for( ; l; l = list_next( l ) )
	    file_dirscan( l->string, builtin_glob_back, &globbing );
#endif

	return globbing.results;
}

/*
 * builtin_match() - MATCH rule, regexp matching
 */

LIST *
builtin_match(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l, *r;
	LIST *result = 0;

	/* For each pattern */

	for( l = lol_get( args, 0 ); l; l = l->next )
	{
	    regexp *re = jam_regcomp( l->string );

	    /* For each string to match against */

	    for( r = lol_get( args, 1 ); r; r = r->next )
		if( jam_regexec( re, r->string ) )
	    {
		int i, top;

		/* Find highest parameter */

		for( top = NSUBEXP; top-- > 1; )
		    if( re->startp[top] )
			break;

		/* And add all parameters up to highest onto list. */
		/* Must have parameters to have results! */

		for( i = 1; i <= top; i++ )
		{
		    BUFFER buff;
		    int l;
		    buffer_init( &buff );
		    l = re->endp[i] - re->startp[i];
		    buffer_addstring( &buff, re->startp[i], l );
		    buffer_addchar( &buff, 0 );
		    result = list_new( result, buffer_ptr( &buff ), 0 );
		    buffer_free( &buff );
		}
	    }

	    free( (char *)re );
	}

	return result;
}


#ifdef OPT_BUILTIN_SUBST_EXT
/*
 * builtin_subst() - Lua-like gsub rule, regexp substitution
 */

extern int str_gsub (BUFFER *buff, const char *src, const char *p, const char *repl, int max_s);

LIST *
builtin_subst(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *liststring;
	LIST *result = 0;
	LIST *pattern = lol_get( args, 1 );
	LIST *repl = lol_get( args, 2 );
	LIST *nstr = lol_get( args, 3 );
	int n = nstr ? atoi( nstr->string ) : -1;

	/* For each string */

	for( liststring = lol_get( args, 0 ); liststring; liststring = liststring->next )
	{
		BUFFER buff;
		buffer_init( &buff );
		str_gsub (&buff, liststring->string, pattern->string, repl ? repl->string : "", n);
		result = list_new( result, buffer_ptr( &buff ), 0 );
		buffer_free( &buff );
	}

	return result;
}
#endif /* OPT_BUILTIN_SUBST_EXT */



#ifdef OPT_MULTIPASS_EXT

/*
 * builtin_queuejamfile()
 *
 * Queue a Jamfile to run in the next Jam pass.
 */

extern LIST *queuedjamfiles;

LIST *
builtin_queuejamfile(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );
	char priority[ 100 ];
	size_t priorityLen;

	if ( l2 ) {
		sprintf( priority, ":%d", atoi( l2->string ) );
		priorityLen = strlen( priority );
	} else {
		strcpy( priority, ":0" );
		priorityLen = 2;
	}

	for( ; l; l = list_next( l ) ) {
		size_t stringLen = strlen( l->string );
		char *filename = malloc( stringLen + priorityLen + 1 );
		strncpy( filename, l->string, stringLen );
		strcpy( filename + stringLen, priority );
		queuedjamfiles = list_new( queuedjamfiles, filename, 0 );
		free( filename );
	}

	return L0;
}

#endif

#ifdef OPT_HEADER_CACHE_EXT

/*
 * builtin_usedepcache() -
 *
 *
 *
 */

LIST *
builtin_usedepcache(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );

	for( ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( l->string );
	    if ( l2 )
		t->settings = addsettings( t->settings, VAR_SET, "DEPCACHE", list_copy( L0, l2 ) );
	    else
		t->settings = addsettings( t->settings, VAR_SET, "DEPCACHE", L0 );
	    t->flags |= parse->num;
	}

	return L0;
}

#endif

#ifdef OPT_BUILTIN_MD5_EXT
/*
 * builtin_usefilecache() - Use file cache rule
 *
 * Builtin_usefilecache() marks the target with the T_FLAG_USEFILECACHE
 * flag.
 */

LIST *
builtin_usefilecache(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );
	const char* cachevar = l2 ? l2->string : "generic";
	BUFFER buff;
	buffer_init( &buff );
	buffer_addstring( &buff, "FILECACHE.", 10 );
	buffer_addstring( &buff, cachevar, strlen( cachevar ) );
	buffer_addchar( &buff, 0 );

	for( ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( l->string );
	    t->settings = addsettings( t->settings, VAR_SET, "FILECACHE", list_new( L0, buffer_ptr( &buff ), 0 ) );
	    t->flags |= parse->num;
	}

	buffer_free( &buff );

	return L0;
}

/*
 * builtin_usecommandline() -
 *
 *
 *
 */

LIST *
builtin_usecommandline(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );

	for( ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( l->string );
	    t->settings = addsettings( t->settings, VAR_SET, "COMMANDLINE", list_copy( L0, l2 ) );
	    t->flags |= parse->num;
	}

	return L0;
}

/*
 * builtin_md5() - Return the MD5 sum of the supplied lists
 */
#include "global.h"
#include "md5.h"

LIST *
builtin_md5(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	static const unsigned char list_sep[] = { 0, 0 };
	static const unsigned char item_sep[] = { 0 };

	MD5_CTX context;
	unsigned char digest[16];
	unsigned char digest_string[33];
	unsigned char* p;
	int i;
	LIST *l;
	LIST *result;

	MD5Init(&context);

	/* For each argument */
	for (i = 0; i < args->count; ++i) {
	    if (i > 0) {
		/* separate lists with 2 NUL characters.  This
		 * guarantees that [ MD5 a b ] is different from [ MD5
		 * a : b ] */
		MD5Update(&context, list_sep, sizeof(list_sep));
	    }
	    l = lol_get(args, i);
	    if (l) {
		MD5Update(&context, (unsigned char*)l->string, strlen(l->string));
		for (l = list_next(l); l; l = list_next(l)) {
		    /* separate list items with 1 NUL character.  This
		     * guarantees that [ MD5 a b ] is different from [
		     * MD5 ab ] */
		    MD5Update(&context, item_sep, sizeof(item_sep));
		    MD5Update(&context, (unsigned char*)l->string, strlen(l->string));
		}
	    }
	}

	MD5Final(digest, &context);
	p = digest_string;
	for (i = 0, p = digest_string; i < 16; i++, p += 2) {
	    sprintf((char*)p, "%02x", digest[i]);
	}
	*p = 0;

	result = list_new(L0, (const char*)digest_string, 0);

	return result;
}

LIST *
builtin_md5file(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	static const unsigned char list_sep[] = { 0, 0 };
	static const unsigned char item_sep[] = { 0 };

	MD5_CTX context;
	unsigned char digest[16];
	unsigned char digest_string[33];
	unsigned char* p;
	int i;
	LIST *l;
	LIST *result;

	const int BUFFER_SIZE = 100 * 1024;
	unsigned char* buffer = (unsigned char*)malloc(BUFFER_SIZE);

	MD5Init(&context);

	/* For each argument */
	for (i = 0; i < args->count; ++i) {
	    l = lol_get(args, i);
	    if (l) {
		do {
			FILE* file;
			TARGET *t = bindtarget(l->string);
			pushsettings( t->settings );
			t->boundname = search( t->name, &t->time );
			popsettings( t->settings );
		    file = fopen(t->boundname, "rb");
		    if (file) {
			int readSize;

			do
			{
			    readSize = fread(buffer, 1, BUFFER_SIZE, file);
			    MD5Update(&context, buffer, readSize);
			} while (readSize != 0);

			fclose(file);
		    }

		    l = list_next(l);
		} while (l);
	    }
	}

	free(buffer);

	MD5Final(digest, &context);
	p = digest_string;
	for (i = 0, p = digest_string; i < 16; i++, p += 2) {
	    sprintf((char*)p, "%02x", digest[i]);
	}
	*p = 0;

	result = list_new(L0, (const char*)digest_string, 0);

	return result;
}
#endif /* OPT_BUILTIN_MD5_EXT */

#ifdef OPT_BUILTIN_MATH_EXT
LIST *
builtin_math(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    char buffer[100];
    int num1;
    int num2;
    int result;

    LIST *expression = lol_get( args, 0 );
    if ( !expression  ||  !expression->next  ||  !expression->next->next )
	return NULL;

    num1 = atoi( expression->string );
    num2 = atoi( expression->next->next->string );
    result = 0;

    switch ( expression->next->string[0] )
    {
	case '+':   result = num1 + num2;    break;
	case '-':   result = num1 - num2;    break;
	case '*':   result = num1 * num2;    break;
	case '/':   result = num1 / num2;    break;
	case '%':   result = num1 % num2;    break;
	default:
	    printf( "jam: rule Math: Unknown operator [%s].\n", expression->next->string );
	    exit( EXITBAD );
    }

	sprintf(buffer, "%d", result);

    return list_new(L0, buffer, 0);
}
#endif

#ifdef NT
#ifdef OPT_BUILTIN_W32_GETREG_EXT
#include "w32_getreg.h"

/*
* builtin_w32_getreg() - W32_GETREG rule, returns a registry entry
* 			given a list of keys.
*
* Usage: result = [ W32_GETREG list ] ;
*/
static LIST*
builtin_w32_getreg( PARSE *parse, LOL *args, int *jmp )
{
	const char* result = w32_getreg(lol_get(args, 0));
	if (result)
		return list_new(L0, result, 0);
	return L0;
}
#endif

#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT
#include "w32_shortname.h"

/*
* builtin_w32_shortname() - W32_SHORTNAME rule, returns the short path
*			(no spaces) of the given path
*
* Usage: result = [ W32_SHORTNAME list ] ;
*/
static LIST*
builtin_w32_shortname( PARSE *parse, LOL *args, int *jmp )
{
	LIST* arg = lol_get(args, 0);
	if (arg)
		return list_new(L0, w32_shortname(arg), 0);
	return L0;
}
#endif
#endif

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
/*
 * builtin_usemd5callback() -
 *
 *
 *
 */

LIST *
builtin_usemd5callback(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *l = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );

	for( ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( l->string );
	    t->settings = addsettings( t->settings, VAR_SET, "MD5CALLBACK", list_copy( L0, l2 ) );
	}

	return L0;
}
#endif



#ifdef OPT_SERIAL_OUTPUT_EXT

/*
 * builtin_shell() -
 *
 *
 *
 */

static void shell_done( const char* outputname, void *closure, int status )
{
    char* buffer;
    long size;
    LIST **list = (LIST**)closure;
    FILE *file = fopen(outputname, "rb");
    if (!file)
	return;
    if (fseek(file, 0, SEEK_END) != 0) {
	fclose(file);
	return;
    }
    size = ftell(file);

    fseek(file, 0, SEEK_SET);

    buffer = malloc(size + 1);
    if (fread(buffer, 1, size, file) != size) {
	free(buffer);
	fclose(file);
	return;
    }
    buffer[size] = 0;

    *list = list_new(*list, buffer, 0);

    free(buffer);
    fclose(file);
}


LIST *
builtin_shell(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    LIST *l = lol_get( args, 0 );
    LIST *shell = var_get( "JAMSHELL" );	/* shell is per-target */

    LIST *output = L0;

    exec_init();
    for( ; l; l = list_next( l ) ) {
        execcmd( l->string, shell_done, &output, shell, 1 );
	execwait();
    }
    exec_done();

    return output;
}

#endif


#ifdef OPT_BUILTIN_GROUPBYVAR_EXT

SETTINGS* quicklookup( TARGET* t, const char* symbol )
{
	SETTINGS *vars;
	if ( !t  ||  !symbol )
		return NULL;

	for ( vars = t->settings; vars; vars = vars->next )
	    if ( vars->symbol[0] == symbol[0]  &&  strcmp( vars->symbol, symbol ) == 0 )
			return vars;

	return NULL;
}


LIST *
builtin_groupbyvar(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST* group1 = L0;
	LIST* rest = L0;
	LIST* f = L0;

	LIST* filelist;
	LIST* varname;
	LIST* maxPerGroupList;
	int numInGroup = 0;
	int maxPerGroup = INT_MAX;

	LIST* all;
	SETTINGS* vars;
	LIST* var1;

	filelist = lol_get( args, 0 );
	if ( !filelist )
		return L0;
    varname = lol_get( args, 1 );
	if ( !varname )
		return L0;
    maxPerGroupList = lol_get( args, 2 );
	if ( maxPerGroupList ) {
		maxPerGroup = atoi( maxPerGroupList->string );
		if ( maxPerGroup == 0 )
			maxPerGroup = INT_MAX;
	}

	/* get the actual filelist */
	all = var_get( filelist->string );

	/* */
	vars = quicklookup( bindtarget( all->string ), varname->string );
	if ( !vars )
		return L0;
	var1 = vars->value;

	for ( f = all; f; f = list_next( f ) ) {
		LIST* it;
		LIST* it1;
		LIST* var;
		vars = quicklookup( bindtarget( f->string ), varname->string );
		if ( !vars )
			continue;
		var = vars->value;

		for ( it = var, it1 = var1; it  &&  it1;  it = list_next( it ), it1 = list_next( it1 ) )
		{
			if ( it->string != it1->string )
				break;
		}

		if ( numInGroup < maxPerGroup  &&  !it  &&  !it1 ) {
			group1 = list_new( group1, f->string, 1 );
			++numInGroup;
		} else
			rest = list_new( rest, f->string, 1 );
	}

	var_set( filelist->string, rest, VAR_SET );

    return group1;
}

#endif
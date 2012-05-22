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

#include "fileglob.h"

/*
 * compile_builtin() - define builtin rules
 */

# define P0 (PARSE *)0
# define C0 (char *)0

NewList *builtin_depends( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_echo( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_exit( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_flags( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_flags_forcecare( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_flags_nocare( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_glob( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_match( PARSE *parse, LOL *args, int *jmp );
#ifdef OPT_BUILTIN_SUBST_EXT
NewList *builtin_subst( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_subst_literalize( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_MULTIPASS_EXT
NewList *builtin_queuejamfile( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_HEADER_CACHE_EXT
NewList *builtin_usedepcache( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef OPT_BUILTIN_MD5_EXT
NewList *builtin_usefilecache( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_usecommandline( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_md5( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_md5file( PARSE *parse, LOL *args, int *jmp );
#endif /* OPT_BUILTIN_MD5_EXT */
#ifdef OPT_BUILTIN_MATH_EXT
static NewList* builtin_math( PARSE *parse, LOL *args, int *jmp );
#endif
#ifdef NT
#ifdef OPT_BUILTIN_W32_GETREG_EXT
static NewList* builtin_w32_getreg( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_W32_GETREG64_EXT
static NewList* builtin_w32_getreg64( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT
static NewList* builtin_w32_shortname( PARSE *parse, LOL *args, int *jmp );
#endif
#endif
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
NewList *builtin_usemd5callback( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_SERIAL_OUTPUT_EXT
NewList *builtin_shell( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_GROUPBYVAR_EXT
NewList *builtin_groupbyvar( PARSE *parse, LOL *args, int *jmp );
#endif

#ifdef OPT_BUILTIN_SPLIT_EXT
NewList *builtin_split( PARSE *parse, LOL *args, int *jmp );
#endif

NewList *builtin_expandfilelist( PARSE *parse, LOL *args, int *jmp );
NewList* builtin_listsort( PARSE *parse, LOL *args, int *jmp );

NewList *builtin_dependslist( PARSE *parse, LOL *args, int *jmp );
NewList *builtin_quicksettingslookup(PARSE *parse, LOL *args, int *jmp);
NewList *builtin_ruleexists(PARSE *parse, LOL *args, int *jmp);

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

    bindrule( "ForceCare" )->procedure =
	parse_make( builtin_flags_forcecare, P0, P0, P0, C0, C0, T_FLAG_FORCECARE );

    bindrule( "NoCare" )->procedure =
    bindrule( "NOCARE" )->procedure =
	parse_make( builtin_flags_nocare, P0, P0, P0, C0, C0, T_FLAG_NOCARE );

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
	bindrule( "SubstLiteralize" )->procedure =
		parse_make( builtin_subst_literalize, P0, P0, P0, C0, C0, 0 );
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
#ifdef OPT_BUILTIN_W32_GETREG64_EXT
	bindrule( "W32_GETREG64" )->procedure =
		parse_make( builtin_w32_getreg64, P0, P0, P0, C0, C0, 0 );
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

#ifdef OPT_BUILTIN_SPLIT_EXT
	bindrule( "Split" )->procedure =
		parse_make( builtin_split, P0, P0, P0, C0, C0, 0 );
#endif

	bindrule( "ExpandFileList" )->procedure =
		parse_make( builtin_expandfilelist, P0, P0, P0, C0, C0, 0 );
	bindrule( "ListSort" )->procedure =
		parse_make( builtin_listsort, P0, P0, P0, C0, C0, 0 );

	bindrule( "DependsList" )->procedure =
		parse_make( builtin_dependslist, P0, P0, P0, C0, C0, 0 );

	bindrule( "QuickSettingsLookup" )->procedure =
		parse_make( builtin_quicksettingslookup, P0, P0, P0, C0, C0, 0 );

	bindrule( "RuleExists" )->procedure =
		parse_make( builtin_ruleexists, P0, P0, P0, C0, C0, 0 );
}

/*
 * builtin_depends() - DEPENDS/INCLUDES/NEEDS rule
 *
 * The DEPENDS builtin rule appends each of the listed sources on the
 * dependency list of each of the listed targets.  It binds both the
 * targets and sources as TARGETs.
 */

NewList *
builtin_depends(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    int curindex = 0;
    while ( 1 )
    {
	NewList *targets = lol_get( args, curindex );
	NewList *sources = lol_get( args, curindex + 1 );
	NewListItem *l;

	if ( !sources )
	    break;

	for( l = newlist_first(targets); l; l = newlist_next( l ) )
	{
	    TARGET *t = bindtarget( newlist_value(l) );

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

    return NULL;
}

/*
 * builtin_echo() - ECHO rule
 *
 * The ECHO builtin rule echoes the targets to the user.  No other
 * actions are taken.
 */

NewList *
builtin_echo(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	newlist_print( lol_get( args, 0 ) );
	printf( "\n" );
	return NULL;
}

/*
 * builtin_exit() - EXIT rule
 *
 * The EXIT builtin rule echoes the targets to the user and exits
 * the program with a failure status.
 */

NewList *
builtin_exit(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	newlist_print( lol_get( args, 0 ) );
	printf( "\n" );
	exit( EXITBAD ); /* yeech */
	return NULL;
}

/*
 * builtin_flags() - NOCARE, NOTFILE, TEMPORARY rule
 *
 * Builtin_flags() marks the target with the appropriate flag, for use
 * by make0().  It binds each target as a TARGET.
 */

NewList *
builtin_flags(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* flag;
	NewList *flags = lol_get( args, 0 );

	for(flag = newlist_first(flags) ; flag; flag = newlist_next( flag ) )
	    bindtarget( newlist_value(flag) )->flags |= parse->num;

	return NULL;
}

/*
 * builtin_flags_forcecare() - ForceCare rule
 */

NewList *
builtin_flags_forcecare(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* target;
	NewList *targets = lol_get( args, 0 );

	for(target = newlist_first(targets) ; target; target = newlist_next( target ) ) {
		TARGET* t = bindtarget(newlist_value(target));
		t->flags |= T_FLAG_FORCECARE;
		t->flags &= ~T_FLAG_NOCARE;
	}

	return NULL;
}

/*
 * builtin_flags_nocare() - NOCARE rule
 */

NewList *
builtin_flags_nocare(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* l;
	for(l = newlist_first(lol_get(args, 0)) ; l; l = newlist_next( l ) ) {
		TARGET* t = bindtarget(newlist_value(l));
		if ( ! ( t->flags & T_FLAG_FORCECARE ) )
			t->flags |= T_FLAG_NOCARE;
	}

	return NULL;
}

/*
 * builtin_globbing() - GLOB rule
 */

struct globbing {
	NewList	*patterns;
	NewList	*results;
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
	NewListItem* l;

	char buffer[ MAXJPATH ];
	if ( dir )
	{
	    strcpy( buffer, file );
	    strcat( buffer, "/" );
	    file = buffer;
	}

	for( l = newlist_first(globbing->patterns); l; l = newlist_next(l) )
	{
	    if( !glob( newlist_value(l), file + globbing->dirnamelen ) )
	    {
		globbing->results = newlist_append( globbing->results, file + ( ( 1 - globbing->prependdir ) * globbing->dirnamelen ), 0 );
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
	NewListItem* l;
	PATHNAME	f;
	char		buf[ MAXJPATH ];

	/* Null out directory for matching. */
	/* We wish we had file_dirscan() pass up a PATHNAME. */

	path_parse( file, &f );
	f.f_dir.len = 0;
	path_build( &f, buf, 0 );

	for( l = newlist_first(globbing->patterns); l; l = newlist_next(l) )
	    if( !glob( newlist_value(l), buf ) )
	{
	    globbing->results = newlist_append( globbing->results, file, 0 );
	    break;
	}
}
#endif

NewList *
builtin_glob(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList *dirs = lol_get( args, 0 );
	NewListItem* l;
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	NewList *prepend = lol_get( args, 2 );
#endif

	struct globbing globbing;

	globbing.results = NULL;
	globbing.patterns = lol_get(args, 1);
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	globbing.prependdir = 1;
	if ( newlist_first(prepend) )
	{
		char const* str = newlist_value(newlist_first(prepend));
	    if ( strcmp( str, "1" ) == 0  ||  strcmp( str, "true" ) == 0 )
		globbing.prependdir = 1;
	    else
		globbing.prependdir = 0;
	}

	for(l = newlist_first(dirs) ; l; l = newlist_next( l ) )
	{
	    globbing.dirname = newlist_value(l);
	    globbing.dirnamelen = strlen(newlist_value(l));
	    if ( globbing.dirname[ globbing.dirnamelen - 1 ] != '/'  &&  globbing.dirname[ globbing.dirnamelen - 1 ] != '\\' )
		globbing.dirnamelen++;
	    file_dirscan( newlist_value(l), builtin_glob_back, &globbing );
	}
#else
	for(l = newlist_furst(dirs) ; l; l = newlist_next( l ) )
	    file_dirscan( newlist_value(l), builtin_glob_back, &globbing );
#endif

	return globbing.results;
}

/*
 * builtin_match() - MATCH rule, regexp matching
 */

NewList *
builtin_match(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList *result = 0;

	/* For each pattern */

	NewListItem* pattern;
	for(pattern = newlist_first(lol_get( args, 0 )); pattern; pattern = newlist_next(pattern) )
	{
	    regexp *re = jam_regcomp( newlist_value(pattern) );

	    /* For each string to match against */

		NewListItem* r;
	    for(r = newlist_first(lol_get( args, 1 )); r; r = newlist_next(r) )
		if( jam_regexec( re, newlist_value(r) ) )
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
		    size_t l;
		    buffer_init( &buff );
		    l = re->endp[i] - re->startp[i];
		    buffer_addstring( &buff, re->startp[i], l );
		    buffer_addchar( &buff, 0 );
		    result = newlist_append( result, buffer_ptr( &buff ), 0 );
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

NewList *
builtin_subst(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* liststring;
	NewList *result = 0;
	NewList *pattern = lol_get( args, 1 );
	NewList *repl = lol_get( args, 2 );
	NewList *nstr = lol_get( args, 3 );
	char const* patternStr = "";
	char const* replStr = "";
	int n = newlist_first(nstr) ? atoi( newlist_value(newlist_first(nstr)) ) : -1;

	if(newlist_first(pattern)) { patternStr = newlist_value(newlist_first(pattern)); }
	if(newlist_first(repl)) { replStr = newlist_value(newlist_first(repl)); }

	/* For each string */

	for(liststring = newlist_first(lol_get( args, 0 )); liststring; liststring = newlist_next(liststring) )
	{
		BUFFER buff;
		buffer_init( &buff );
		str_gsub (&buff, newlist_value(liststring), patternStr, replStr, n);
		result = newlist_append( result, buffer_ptr( &buff ), 0 );
		buffer_free( &buff );
	}

	return result;
}



NewList *builtin_subst_literalize( PARSE	*parse, LOL	*args, int	*jmp )
{
	NewList *result = NULL;

	NewListItem* pattern;
	for(pattern = newlist_first(lol_get( args, 0 )); pattern; pattern = newlist_next(pattern) )
	{
		const char* patternString;
		BUFFER patternBuff;
		buffer_init( &patternBuff );

		for ( patternString = newlist_value(pattern); *patternString; ++patternString )
		{
			if ( *patternString == '('  ||  *patternString == ')'  ||  *patternString == '.'  ||
					*patternString == '%'  ||  *patternString == '+'  ||  *patternString == '-'  ||  
					*patternString == '*'  ||  *patternString == '?'  ||  *patternString == '['  ||  
					*patternString == ']'  ||  *patternString == '^'  ||  *patternString == '$' )
			{
				buffer_addchar( &patternBuff, '%' );
			}
			buffer_addchar( &patternBuff, *patternString );
		}
		buffer_addchar( &patternBuff, 0 );
		result = newlist_append( result, buffer_ptr( &patternBuff ), 0 );
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

extern NewList *queuedjamfiles;

NewList *
builtin_queuejamfile(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* l;
	NewList *files = lol_get( args, 0 );
	NewList *l2 = lol_get( args, 1 );
	char priority[ 100 ];
	size_t priorityLen;

	if ( newlist_first(l2) ) {
		sprintf( priority, ":%d", atoi( newlist_value(newlist_first(l2)) ) );
		priorityLen = strlen( priority );
	} else {
		strcpy( priority, ":0" );
		priorityLen = 2;
	}

	for(l = newlist_first(files) ; l; l = newlist_next( l ) ) {
		size_t stringLen = strlen( newlist_value(l) );
		char *filename = malloc( stringLen + priorityLen + 1 );
		strncpy( filename, newlist_value(l), stringLen );
		strcpy( filename + stringLen, priority );
		queuedjamfiles = newlist_append( queuedjamfiles, filename, 0 );
		free( filename );
	}

	return NULL;
}

#endif

#ifdef OPT_HEADER_CACHE_EXT

/*
 * builtin_usedepcache() -
 *
 *
 *
 */

NewList *
builtin_usedepcache(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* l;
	NewList *targets = lol_get( args, 0 );
	NewList *l2 = lol_get( args, 1 );

	for(l = newlist_first(targets) ; l; l = newlist_next( l ) ) {
	    TARGET *t = bindtarget( newlist_value(l) );
	    if ( newlist_first(l2) )
		t->settings = addsettings( t->settings, VAR_SET, "DEPCACHE", newlist_copy( NULL, l2 ) );
	    else
		t->settings = addsettings( t->settings, VAR_SET, "DEPCACHE", NULL );
	    t->flags |= parse->num;
	}

	return NULL;
}

#endif

#ifdef OPT_BUILTIN_MD5_EXT
/*
 * builtin_usefilecache() - Use file cache rule
 *
 * Builtin_usefilecache() marks the target with the T_FLAG_USEFILECACHE
 * flag.
 */

NewList *
builtin_usefilecache(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* l;
	NewList *targets = lol_get( args, 0 );
	NewList *l2 = lol_get( args, 1 );
	const char* cachevar = newlist_first(l2) ? newlist_value(newlist_first(l2)) : "generic";
	BUFFER buff;
	buffer_init( &buff );
	buffer_addstring( &buff, "FILECACHE.", 10 );
	buffer_addstring( &buff, cachevar, strlen( cachevar ) );
	buffer_addchar( &buff, 0 );

	for(l = newlist_first(targets) ; l; l = newlist_next( l ) ) {
	    TARGET *t = bindtarget(newlist_value(l));
	    t->settings = addsettings( t->settings, VAR_SET, "FILECACHE", newlist_append( NULL, buffer_ptr( &buff ), 0 ) );
	    t->flags |= parse->num;
	}

	buffer_free( &buff );

	return NULL;
}

/*
 * builtin_usecommandline() -
 *
 *
 *
 */

NewList *
builtin_usecommandline(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList *targets = lol_get( args, 0 );
	NewList *cmdLine = lol_get( args, 1 );
	NewListItem* l;

	for(l = newlist_first(targets) ; l; l = newlist_next( l ) ) {
	    TARGET *t = bindtarget( newlist_value(l) );
	    t->settings = addsettings( t->settings, VAR_SET, "COMMANDLINE", newlist_copy( NULL, cmdLine ) );
	    t->flags |= parse->num;
	}

	return NULL;
}

/*
 * builtin_md5() - Return the MD5 sum of the supplied lists
 */
#include "global.h"
#include "md5.h"

NewList *
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
	NewList *l;

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
	    if (newlist_first(l)) {
			NewListItem* item = newlist_first(l);
		MD5Update(&context, (unsigned char*)newlist_value(item), (unsigned int)strlen(newlist_value(item)));
		for (item = newlist_next(item); item; item = newlist_next(item)) {
		    /* separate list items with 1 NUL character.  This
		     * guarantees that [ MD5 a b ] is different from [
		     * MD5 ab ] */
		    MD5Update(&context, item_sep, sizeof(item_sep));
		    MD5Update(&context, (unsigned char*)newlist_value(item), (unsigned int)strlen(newlist_value(item)));
		}
	    }
	}

	MD5Final(digest, &context);
	p = digest_string;
	for (i = 0, p = digest_string; i < 16; i++, p += 2) {
	    sprintf((char*)p, "%02x", digest[i]);
	}
	*p = 0;

	return newlist_append(NULL, (char const*)digest_string, 0);
}

NewList *
builtin_md5file(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	MD5_CTX context;
	unsigned char digest[16];
	unsigned char digest_string[33];
	unsigned char* p;
	int i;

	const size_t BUFFER_SIZE = 100 * 1024;
	unsigned char* buffer = (unsigned char*)malloc(BUFFER_SIZE);

	MD5Init(&context);

	/* For each argument */
	for (i = 0; i < args->count; ++i) {
	    NewListItem* target = newlist_first(lol_get(args, i));
	    if (target) {
		do {
			FILE* file;
			TARGET *t = bindtarget(newlist_value(target));
			pushsettings( t->settings );
			t->boundname = search( t->name, &t->time );
			popsettings( t->settings );
		    file = fopen(t->boundname, "rb");
		    if (file) {
			size_t readSize;

			do
			{
			    readSize = fread(buffer, 1, BUFFER_SIZE, file);
			    MD5Update(&context, buffer, readSize);
			} while (readSize != 0);

			fclose(file);
		    }

			target = newlist_next(target);
		} while (target);
	    }
	}

	free(buffer);

	MD5Final(digest, &context);
	p = digest_string;
	for (i = 0, p = digest_string; i < 16; i++, p += 2) {
	    sprintf((char*)p, "%02x", digest[i]);
	}
	*p = 0;

	return newlist_append(NULL, (char const*)digest_string, 0);
}
#endif /* OPT_BUILTIN_MD5_EXT */

#ifdef OPT_BUILTIN_MATH_EXT
NewList *
builtin_math(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    char buffer[100];
    int num1;
	char const* op;
    int num2;
    int result;

	NewListItem* exprEl;
    NewList *expression = lol_get( args, 0 );
	if(newlist_length(expression) != 3) {
		return NULL;
	}

	exprEl = newlist_first(expression);
	num1 = atoi(newlist_value(exprEl));

	exprEl = newlist_next(exprEl);
	op = newlist_value(exprEl);

	exprEl = newlist_next(exprEl);
	num2 = atoi(newlist_value(exprEl));

    result = 0;

    switch (op[0])
    {
	case '+':   result = num1 + num2;    break;
	case '-':   result = num1 - num2;    break;
	case '*':   result = num1 * num2;    break;
	case '/':   result = num1 / num2;    break;
	case '%':   result = num1 % num2;    break;
	default:
	    printf( "jam: rule Math: Unknown operator [%s].\n", op );
	    exit( EXITBAD );
    }

	sprintf(buffer, "%d", result);

    return newlist_append(NULL, buffer, 0);
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
static NewList*
builtin_w32_getreg( PARSE *parse, LOL *args, int *jmp )
{
	const char* result = w32_getreg(lol_get(args, 0));
	if (result)
		return newlist_append(NULL, result, 0);
	return NULL;
}

#ifdef OPT_BUILTIN_W32_GETREG64_EXT
/*
* builtin_w32_getreg64() - W32_GETREG64 rule, returns a 64bit registry entry
* 			given a list of keys.
*
* Usage: result = [ W32_GETREG64 list ] ;
*/
static NewList*
builtin_w32_getreg64( PARSE *parse, LOL *args, int *jmp )
{
	const char* result = w32_getreg64(lol_get(args, 0));
	if (result)
		return newlist_append(NULL, result, 0);
	return NULL;
}
#endif

#endif

#ifdef OPT_BUILTIN_W32_SHORTNAME_EXT
#include "w32_shortname.h"

/*
* builtin_w32_shortname() - W32_SHORTNAME rule, returns the short path
*			(no spaces) of the given path
*
* Usage: result = [ W32_SHORTNAME list ] ;
*/
static NewList*
builtin_w32_shortname( PARSE *parse, LOL *args, int *jmp )
{
	NewList* arg = lol_get(args, 0);
	if (newlist_first(arg))
		return newlist_append(NULL, w32_shortname(arg), 0);
	return NULL;
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

NewList *
builtin_usemd5callback(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList *targets = lol_get( args, 0 );
	NewList *l2 = lol_get( args, 1 );
	NewListItem* l;

	for(l = newlist_first(targets) ; l; l = newlist_next( l ) ) {
	    TARGET *t = bindtarget( newlist_value(l) );
	    t->settings = addsettings( t->settings, VAR_SET, "MD5CALLBACK", newlist_copy( NULL, l2 ) );
	}

	return NULL;
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
    NewList **list = (NewList**)closure;
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

    *list = newlist_append(*list, buffer, 0);

    free(buffer);
    fclose(file);
}


NewList *
builtin_shell(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewListItem* l;
    NewList *cmds = lol_get( args, 0 );
    NewList *shell = var_get( "JAMSHELL" );	/* shell is per-target */

	NewList *output = NULL;

    exec_init();
    for(l = newlist_first(cmds) ; l; l = newlist_next( l ) ) {
        execcmd( newlist_value(l), shell_done, &output, shell, 1 );
	execwait();
    }
    exec_done();

    return output;
}

#endif


#ifdef OPT_BUILTIN_GROUPBYVAR_EXT

NewList *
builtin_groupbyvar(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList* group1 = NULL;
	NewList* rest = NULL;
	NewListItem* f;

	NewList* filelist;
	NewList* varnameList;
	char const* varname;
	NewList* maxPerGroupList;
	int numInGroup = 0;
	int maxPerGroup = INT_MAX;

	NewList* all;
	SETTINGS* vars;
	NewList* matchVars;

	filelist = lol_get( args, 0 );
	if ( !newlist_first(filelist) )
		return NULL;

	varnameList = lol_get( args, 1 );
	if ( !newlist_first(varnameList) )
		return NULL;
	varname = newlist_value(newlist_first(varnameList));

    maxPerGroupList = lol_get( args, 2 );
	if ( newlist_first(maxPerGroupList) ) {
		maxPerGroup = atoi( newlist_value(newlist_first(maxPerGroupList)) );
		if ( maxPerGroup == 0 )
			maxPerGroup = INT_MAX;
	}

	/* get the actual filelist */
	all = var_get( newlist_value(newlist_first(filelist)) );

	/* */
	vars = quicksettingslookup( bindtarget( newlist_value(newlist_first(all)) ), varname );
	if ( !vars )
		return NULL;
	matchVars = vars->value;

	for (f = newlist_first(all); f; f = newlist_next( f ) ) {
		NewList* testVars;
		int equal;
		
		vars = quicksettingslookup( bindtarget( newlist_value(f) ), varname );
		if ( !vars )
			continue;
		testVars = vars->value;

		equal = newlist_equal(matchVars, testVars);

		if ( numInGroup < maxPerGroup && equal ) {
			group1 = newlist_append( group1, newlist_value(f), 1 );
			++numInGroup;
		} else
			rest = newlist_append( rest, newlist_value(f), 1 );
	}

	var_set( newlist_value(newlist_first(filelist)), rest, VAR_SET );

    return group1;
}

#endif


#ifdef OPT_BUILTIN_SPLIT_EXT
/* Based on code from ftjam by David Turner */
NewList *
builtin_split(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    NewList* inputList = lol_get( args, 0 );
    NewList* result = NULL;
    NewListItem* input;

	char	token[256];
	BUFFER buff;

	buffer_init( &buff );

	/* Build split token lookup table */
	{
		NewListItem* tok;
		NewList* tokens = lol_get(args, 1);
		memset( token, 0, sizeof( token ) );
		for(tok = newlist_first(tokens); tok; tok = newlist_next(tok)) {
			char const* s = newlist_value(tok);
			for(; *s; s += 1) {
				token[(unsigned char)*s] = 1;
			}
		}
	}

    /* now parse the input and split it */
    for (input = newlist_first(inputList) ; input; input = newlist_next(input) ) {
		const char* ptr = newlist_value(input);
		const char* lastPtr = newlist_value(input);

		while ( *ptr ) {
            if ( token[(unsigned char) *ptr] ) {
                size_t count = ptr - lastPtr;
                if ( count > 0 ) {
					buffer_reset( &buff );
					buffer_addstring( &buff, lastPtr, count );
					buffer_addchar( &buff, 0 );

                    result = newlist_append( result, buffer_ptr( &buff ), 0 );
                }
				lastPtr = ptr + 1;
            }
			++ptr;
        }
        if ( ptr > lastPtr )
            result = newlist_append( result, lastPtr, 0 );
    }

	buffer_free( &buff );
    return  result;
}
#endif



NewList *
builtin_expandfilelist(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	NewList* files = lol_get( args, 0 );
	NewListItem* file;
	NewList* result = NULL;
	NewList* searchSource = var_get( "SEARCH_SOURCE" );
	size_t searchSourceLen;
	int searchSourceExtraLen = 0;
	char const* searchSourceStr = "";

	if ( newlist_first(searchSource) ) {
		searchSourceStr = newlist_value(newlist_first(searchSource));
		searchSourceLen = strlen(searchSourceStr);
		if ( searchSourceStr[ searchSourceLen - 1 ] != '/'  &&  searchSourceStr[ searchSourceLen - 1 ] != '\\' )
			searchSourceExtraLen = 1;
	}

    for (file = newlist_first(files) ; file; file = newlist_next(file) ) {
		int wildcard = 0;
		const char* ptr = newlist_value(file);
		while ( *ptr ) {
			if ( *ptr == '*'  ||  *ptr == '?' ) {
				wildcard = 1;
				break;
			}
			++ptr;
		}

		if ( !wildcard ) {
			result = newlist_append( result, newlist_value(file), 1 );
		} else {
			PATHNAME	f;
			char		buf[ MAXJPATH ];
			size_t testIndex = 0;
			fileglob* glob;
			int matches = 1;

			path_parse( newlist_value(file), &f );
			f.f_root.len = searchSourceLen;
			f.f_root.ptr = searchSourceStr;
			path_build( &f, buf, 0 );

			while ( testIndex < searchSourceLen ) {
				if ( buf[ testIndex ] != searchSourceStr[ testIndex ] ) {
					matches = 0;
					break;
				}
				++testIndex;
			}

			glob = fileglob_Create( buf );
			while ( fileglob_Next( glob ) ) {
	            result = newlist_append( result, fileglob_FileName( glob ) + ( matches ? searchSourceLen : 0 ) + searchSourceExtraLen, 0 );
			}
			fileglob_Destroy( glob );
		}
	}

    return result;
}



NewList *builtin_listsort( PARSE *parse, LOL *args, int *jmp )
{
	NewList *l = newlist_copy( NULL, lol_get( args, 0 ) );
    NewList *caseSensitiveList = lol_get( args, 1 );
	int caseSensitive = 1;
	if ( newlist_first(caseSensitiveList) )
		caseSensitive = atoi(newlist_value(newlist_first(caseSensitiveList)));

	return newlist_sort(l, caseSensitive);
}



NewList *builtin_dependslist(PARSE *parse, LOL *args, int *jmp)
{
	NewList *result = NULL;
	NewList *parents = lol_get(args, 0);
	NewListItem* parent;
	
    for (parent = newlist_first(parents); parent; parent = newlist_next(parent)) {
		TARGET *t = bindtarget(newlist_value(parent));
		TARGETS *child;

		for (child = t->depends; child; child = child->next)
		{
			result = newlist_append(result, child->target->name, 1);
	    }
	}
	
	return result;
}


NewList *builtin_quicksettingslookup(PARSE *parse, LOL *args, int *jmp)
{
	TARGET* t;
	NewList* symbol;
	SETTINGS* settings;

	NewList *target = lol_get(args, 0);
	if (!newlist_first(target))
		return NULL;

	symbol = lol_get(args, 1);
	if (!newlist_first(symbol))
		return NULL;

	t = bindtarget(newlist_value(newlist_first(target)));
	settings = quicksettingslookup(t, newlist_value(newlist_first(symbol)));
	if (settings)
		return newlist_copy(NULL, settings->value);

	return NULL;
}


NewList *builtin_ruleexists(PARSE *parse, LOL *args, int *jmp)
{
	NewList* symbol;

	symbol = lol_get(args, 0);
	if (!newlist_first(symbol))
		return NULL;

	if ( ruleexists(newlist_value(newlist_first(symbol))) )
		return newlist_append( NULL, "true", 0 );
	return NULL;
}

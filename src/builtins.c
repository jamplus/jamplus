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

# include "expand.h"

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
# include "luasupport.h"
#endif

#ifdef OPT_SERIAL_OUTPUT_EXT
# include "execcmd.h"
#endif

#ifdef OPT_LOAD_MISSING_RULE_EXT
# include "compile.h"
#endif

#include "timestamp.h"
#include "fileglob.h"

/*
 * compile_builtin() - define builtin rules
 */

# define P0 (PARSE *)0
# define C0 (char *)0

LIST *builtin_depends( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_echo( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_exit( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_flags( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_flags_forcecare( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_flags_nocare( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_glob( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_match( PARSE *parse, LOL *args, int *jmp );
#ifdef OPT_BUILTIN_SUBST_EXT
LIST *builtin_subst( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_subst_literalize( PARSE *parse, LOL *args, int *jmp );
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

#ifdef OPT_BUILTIN_W32_GETREG64_EXT
static LIST* builtin_w32_getreg64( PARSE *parse, LOL *args, int *jmp );
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

#ifdef OPT_BUILTIN_SPLIT_EXT
LIST *builtin_split( PARSE *parse, LOL *args, int *jmp );
#endif

LIST *builtin_expandfilelist( PARSE *parse, LOL *args, int *jmp );
LIST* builtin_listsort( PARSE *parse, LOL *args, int *jmp );

LIST *builtin_dependslist( PARSE *parse, LOL *args, int *jmp );
LIST *builtin_quicksettingslookup(PARSE *parse, LOL *args, int *jmp);
LIST *builtin_ruleexists(PARSE *parse, LOL *args, int *jmp);
LIST *builtin_configurefilehelper(PARSE *parse, LOL *args, int *jmp);
LIST *builtin_search(PARSE *parse, LOL *args, int *jmp);

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
	bindrule( "Wildcard" )->procedure =
		parse_make( builtin_expandfilelist, P0, P0, P0, C0, C0, 0 );
	bindrule( "ListSort" )->procedure =
		parse_make( builtin_listsort, P0, P0, P0, C0, C0, 0 );

	bindrule( "DependsList" )->procedure =
		parse_make( builtin_dependslist, P0, P0, P0, C0, C0, 0 );

	bindrule( "QuickSettingsLookup" )->procedure =
		parse_make( builtin_quicksettingslookup, P0, P0, P0, C0, C0, 0 );

	bindrule( "RuleExists" )->procedure =
		parse_make( builtin_ruleexists, P0, P0, P0, C0, C0, 0 );

	bindrule( "ConfigureFileHelper" )->procedure =
		parse_make( builtin_configurefilehelper, P0, P0, P0, C0, C0, 0 );

	bindrule( "Search" )->procedure =
		parse_make( builtin_search, P0, P0, P0, C0, C0, 0 );
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
	LISTITEM *l;

	if ( !sources )
	    break;

	for( l = list_first(targets); l; l = list_next( l ) )
	{
	    TARGET *t = bindtarget( list_value(l) );

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
	LISTITEM* flag;
	LIST *flags = lol_get( args, 0 );

	for(flag = list_first(flags) ; flag; flag = list_next( flag ) )
	    bindtarget( list_value(flag) )->flags |= parse->num;

	return L0;
}

/*
 * builtin_flags_forcecare() - ForceCare rule
 */

LIST *
builtin_flags_forcecare(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LISTITEM* target;
	LIST *targets = lol_get( args, 0 );

	for(target = list_first(targets) ; target; target = list_next( target ) ) {
		TARGET* t = bindtarget(list_value(target));
		t->flags |= T_FLAG_FORCECARE;
		t->flags &= ~T_FLAG_NOCARE;
	}

	return L0;
}

/*
 * builtin_flags_nocare() - NOCARE rule
 */

LIST *
builtin_flags_nocare(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LISTITEM* l;
	for(l = list_first(lol_get(args, 0)) ; l; l = list_next( l ) ) {
		TARGET* t = bindtarget(list_value(l));
		if ( ! ( t->flags & T_FLAG_FORCECARE ) )
			t->flags |= T_FLAG_NOCARE;
	}

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
	LISTITEM* l;

	char buffer[ MAXJPATH ];
	if ( dir )
	{
	    strcpy( buffer, file );
	    strcat( buffer, "/" );
	    file = buffer;
	}

	for( l = list_first(globbing->patterns); l; l = list_next(l) )
	{
	    if( !glob( list_value(l), file + globbing->dirnamelen ) )
	    {
		globbing->results = list_append( globbing->results, file + ( ( 1 - globbing->prependdir ) * globbing->dirnamelen ), 0 );
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
	LISTITEM* l;
	PATHNAME	f;
	char		buf[ MAXJPATH ];

	/* Null out directory for matching. */
	/* We wish we had file_dirscan() pass up a PATHNAME. */

	path_parse( file, &f );
	f.f_dir.len = 0;
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	path_build( &f, buf, 0, 1 );
#else
	path_build( &f, buf, 0 );
#endif

	for( l = list_first(globbing->patterns); l; l = list_next(l) )
	    if( !glob( list_value(l), buf ) )
	{
	    globbing->results = list_append( globbing->results, file, 0 );
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
	LIST *dirs = lol_get( args, 0 );
	LISTITEM* l;
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	LIST *prepend = lol_get( args, 2 );
#endif

	struct globbing globbing;

	globbing.results = L0;
	globbing.patterns = lol_get(args, 1);
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	globbing.prependdir = 1;
	if ( list_first(prepend) )
	{
		char const* str = list_value(list_first(prepend));
	    if ( strcmp( str, "1" ) == 0  ||  strcmp( str, "true" ) == 0 )
		globbing.prependdir = 1;
	    else
		globbing.prependdir = 0;
	}

	for(l = list_first(dirs) ; l; l = list_next( l ) )
	{
	    globbing.dirname = list_value(l);
	    globbing.dirnamelen = strlen(list_value(l));
	    if ( globbing.dirname[ globbing.dirnamelen - 1 ] != '/'  &&  globbing.dirname[ globbing.dirnamelen - 1 ] != '\\' )
		globbing.dirnamelen++;
	    file_dirscan( list_value(l), builtin_glob_back, &globbing );
	}
#else
	for(l = list_furst(dirs) ; l; l = list_next( l ) )
	    file_dirscan( list_value(l), builtin_glob_back, &globbing );
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
	LIST *result = 0;

	/* For each pattern */

	LISTITEM* pattern;
	for(pattern = list_first(lol_get( args, 0 )); pattern; pattern = list_next(pattern) )
	{
	    regexp *re = jam_regcomp( list_value(pattern) );

	    /* For each string to match against */

		LISTITEM* r;
	    for(r = list_first(lol_get( args, 1 )); r; r = list_next(r) )
		if( jam_regexec( re, list_value(r) ) )
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
		    result = list_append( result, buffer_ptr( &buff ), 0 );
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
	LISTITEM* liststring;
	LIST *result = 0;
	LIST *pattern = lol_get( args, 1 );
	LIST *repl = lol_get( args, 2 );
	LIST *nstr = lol_get( args, 3 );
	char const* patternStr = "";
	char const* replStr = "";
	int n = list_first(nstr) ? atoi( list_value(list_first(nstr)) ) : -1;

	if(list_first(pattern)) { patternStr = list_value(list_first(pattern)); }
	if(list_first(repl)) { replStr = list_value(list_first(repl)); }

	/* For each string */

	for(liststring = list_first(lol_get( args, 0 )); liststring; liststring = list_next(liststring) )
	{
		BUFFER buff;
		buffer_init( &buff );
		str_gsub (&buff, list_value(liststring), patternStr, replStr, n);
		result = list_append( result, buffer_ptr( &buff ), 0 );
		buffer_free( &buff );
	}

	return result;
}



LIST *builtin_subst_literalize( PARSE	*parse, LOL	*args, int	*jmp )
{
	LIST *result = L0;

	LISTITEM* pattern;
	for(pattern = list_first(lol_get( args, 0 )); pattern; pattern = list_next(pattern) )
	{
		const char* patternString;
		BUFFER patternBuff;
		buffer_init( &patternBuff );

		for ( patternString = list_value(pattern); *patternString; ++patternString )
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
		result = list_append( result, buffer_ptr( &patternBuff ), 0 );
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
	LISTITEM* l;
	LIST *files = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );
	char priority[ 100 ];
	size_t priorityLen;

	if ( list_first(l2) ) {
		sprintf( priority, "%c%d", '\xff', atoi( list_value(list_first(l2)) ) );
		priorityLen = strlen( priority );
	} else {
		sprintf( priority, "%c0", '\xff' );
		priorityLen = 2;
	}

	for(l = list_first(files) ; l; l = list_next( l ) ) {
		size_t stringLen = strlen( list_value(l) );
		char *filename = malloc( stringLen + priorityLen + 1 );
		strncpy( filename, list_value(l), stringLen );
		strcpy( filename + stringLen, priority );
		queuedjamfiles = list_append( queuedjamfiles, filename, 0 );
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
	LISTITEM* l;
	LIST *targets = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );

	for(l = list_first(targets) ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( list_value(l) );
	    if ( list_first(l2) )
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
	LISTITEM* l;
	LIST *targets = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );
	const char* cachevar = list_first(l2) ? list_value(list_first(l2)) : "generic";
	BUFFER buff;
	buffer_init( &buff );
	buffer_addstring( &buff, "FILECACHE.", 10 );
	buffer_addstring( &buff, cachevar, strlen( cachevar ) );
	buffer_addchar( &buff, 0 );

	for(l = list_first(targets) ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget(list_value(l));
	    t->settings = addsettings( t->settings, VAR_SET, "FILECACHE", list_append( L0, buffer_ptr( &buff ), 0 ) );
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
	LIST *targets = lol_get( args, 0 );
	LIST *cmdLine = lol_get( args, 1 );
	LISTITEM* l;

	for(l = list_first(targets) ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( list_value(l) );
	    t->settings = addsettings( t->settings, VAR_SET, "COMMANDLINE", list_copy( L0, cmdLine ) );
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
	    if (list_first(l)) {
			LISTITEM* item = list_first(l);
		MD5Update(&context, (unsigned char*)list_value(item), (unsigned int)strlen(list_value(item)));
		for (item = list_next(item); item; item = list_next(item)) {
		    /* separate list items with 1 NUL character.  This
		     * guarantees that [ MD5 a b ] is different from [
		     * MD5 ab ] */
		    MD5Update(&context, item_sep, sizeof(item_sep));
		    MD5Update(&context, (unsigned char*)list_value(item), (unsigned int)strlen(list_value(item)));
		}
	    }
	}

	MD5Final(digest, &context);
	p = digest_string;
	for (i = 0, p = digest_string; i < 16; i++, p += 2) {
	    sprintf((char*)p, "%02x", digest[i]);
	}
	*p = 0;

	return list_append(L0, (char const*)digest_string, 0);
}

LIST *
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
	    LISTITEM* target = list_first(lol_get(args, i));
	    if (target) {
		do {
			FILE* file;
			TARGET *t = bindtarget(list_value(target));
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

			target = list_next(target);
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

	return list_append(L0, (char const*)digest_string, 0);
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
	char const* op;
    int num2;
    int result;

	LISTITEM* exprEl;
    LIST *expression = lol_get( args, 0 );
	if(list_length(expression) != 3) {
		return NULL;
	}

	exprEl = list_first(expression);
	num1 = atoi(list_value(exprEl));

	exprEl = list_next(exprEl);
	op = list_value(exprEl);

	exprEl = list_next(exprEl);
	num2 = atoi(list_value(exprEl));

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

    return list_append(L0, buffer, 0);
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
		return list_append(L0, result, 0);
	return L0;
}

#ifdef OPT_BUILTIN_W32_GETREG64_EXT
/*
* builtin_w32_getreg64() - W32_GETREG64 rule, returns a 64bit registry entry
* 			given a list of keys.
*
* Usage: result = [ W32_GETREG64 list ] ;
*/
static LIST*
builtin_w32_getreg64( PARSE *parse, LOL *args, int *jmp )
{
	const char* result = w32_getreg64(lol_get(args, 0));
	if (result)
		return list_append(L0, result, 0);
	return L0;
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
static LIST*
builtin_w32_shortname( PARSE *parse, LOL *args, int *jmp )
{
	LIST* arg = lol_get(args, 0);
	if (list_first(arg))
		return list_append(L0, w32_shortname(arg), 0);
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
	LIST *targets = lol_get( args, 0 );
	LIST *l2 = lol_get( args, 1 );
	LISTITEM* l;

	for(l = list_first(targets) ; l; l = list_next( l ) ) {
	    TARGET *t = bindtarget( list_value(l) );
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

    *list = list_append(*list, buffer, 0);

    free(buffer);
    fclose(file);
}


LIST *
builtin_shell(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    LIST *cmds = lol_get( args, 0 );
    LISTITEM* l;
    LIST *shell = var_get( "JAMSHELL" );	/* shell is per-target */

    LIST *output = L0;

    exec_init();
    for( l = list_first(cmds); l; l = list_next( l ) ) {
        execcmd( list_value(l), shell_done, &output, shell, 1 );
	execwait();
    }
    exec_done();

    return output;
}

#endif


#ifdef OPT_BUILTIN_GROUPBYVAR_EXT

LIST *
builtin_groupbyvar(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST* group1 = L0;
	LIST* rest = L0;
	LISTITEM* f;

	LIST* filelist;
	LIST* varnameList;
	char const* varname;
	LIST* maxPerGroupList;
	int numInGroup = 0;
	int maxPerGroup = INT_MAX;

	LIST* all;
	SETTINGS* vars;
	LIST* matchVars;

	filelist = lol_get( args, 0 );
	if ( !list_first(filelist) )
		return L0;

	varnameList = lol_get( args, 1 );
	if ( !list_first(varnameList) )
		return NULL;
	varname = list_value(list_first(varnameList));

    maxPerGroupList = lol_get( args, 2 );
	if ( list_first(maxPerGroupList) ) {
		maxPerGroup = atoi( list_value(list_first(maxPerGroupList)) );
		if ( maxPerGroup == 0 )
			maxPerGroup = INT_MAX;
	}

	/* get the actual filelist */
	all = var_get( list_value(list_first(filelist)) );

	/* */
	vars = quicksettingslookup( bindtarget( list_value(list_first(all)) ), varname );
	if ( !vars )
		return L0;
	matchVars = vars->value;

	for (f = list_first(all); f; f = list_next( f ) ) {
		LIST* testVars;
		int equal;
		
		vars = quicksettingslookup( bindtarget( list_value(f) ), varname );
		if ( !vars )
			continue;
		testVars = vars->value;

		equal = list_equal(matchVars, testVars);

		if ( numInGroup < maxPerGroup && equal ) {
			group1 = list_append( group1, list_value(f), 1 );
			++numInGroup;
		} else
			rest = list_append( rest, list_value(f), 1 );
	}

	var_set( list_value(list_first(filelist)), rest, VAR_SET );

    return group1;
}

#endif


#ifdef OPT_BUILTIN_SPLIT_EXT
/* Based on code from ftjam by David Turner */
LIST *
builtin_split(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
    LIST* inputList = lol_get( args, 0 );
    LIST* result = L0;
    LISTITEM* input;

	char	token[256];
	BUFFER buff;

	buffer_init( &buff );

	/* Build split token lookup table */
	{
		LISTITEM* tok;
		LIST* tokens = lol_get(args, 1);
		memset( token, 0, sizeof( token ) );
		for(tok = list_first(tokens); tok; tok = list_next(tok)) {
			char const* s = list_value(tok);
			for(; *s; s += 1) {
				token[(unsigned char)*s] = 1;
			}
		}
	}

    /* now parse the input and split it */
    for (input = list_first(inputList) ; input; input = list_next(input) ) {
		const char* ptr = list_value(input);
		const char* lastPtr = list_value(input);

		while ( *ptr ) {
            if ( token[(unsigned char) *ptr] ) {
                size_t count = ptr - lastPtr;
                if ( count > 0 ) {
					buffer_reset( &buff );
					buffer_addstring( &buff, lastPtr, count );
					buffer_addchar( &buff, 0 );

                    result = list_append( result, buffer_ptr( &buff ), 0 );
                }
				lastPtr = ptr + 1;
            }
			++ptr;
        }
        if ( ptr > lastPtr )
            result = list_append( result, lastPtr, 0 );
    }

	buffer_free( &buff );
    return  result;
}
#endif



LIST *
builtin_expandfilelist(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST* files = lol_get( args, 0 );
	LISTITEM* file;
	LIST* result = L0;
	LIST* searchSource = var_get( "SEARCH_SOURCE" );
	size_t searchSourceLen = 0;
	int searchSourceExtraLen = 0;
	char const* searchSourceStr = "";
	LIST* absoluteList = lol_get( args, 1 );
	int absolute = 1;
	if ( list_first( absoluteList ) )
	{
		char const* str = list_value( list_first( absoluteList ) );
		absolute = strcmp( str, "1" ) == 0  ||  strcmp( str, "true" ) == 0;
	}

	if ( list_first(searchSource) ) {
		searchSourceStr = list_value(list_first(searchSource));
		searchSourceLen = strlen(searchSourceStr);
		if ( searchSourceStr[ searchSourceLen - 1 ] != '/'  &&  searchSourceStr[ searchSourceLen - 1 ] != '\\' )
			searchSourceExtraLen = 1;
	}

    for (file = list_first(files) ; file; file = list_next(file) ) {
		int wildcard = 0;
		const char* ptr = list_value(file);
		while ( *ptr ) {
			if ( *ptr == '*'  ||  *ptr == '?' ) {
				wildcard = 1;
				break;
			}
			++ptr;
		}

		if ( !wildcard ) {
			result = list_append( result, list_value(file), 1 );
		} else {
			PATHNAME	f;
			char		buf[ MAXJPATH ];
			size_t testIndex = 0;
			fileglob* glob;
			int matches = 1;

			path_parse( list_value(file), &f );
			f.f_root.len = searchSourceLen;
			f.f_root.ptr = searchSourceStr;
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
			path_build( &f, buf, 0, absolute );
#else
			path_build( &f, buf, 0 );
#endif

			while ( testIndex < searchSourceLen ) {
				if ( buf[ testIndex ] != searchSourceStr[ testIndex ] ) {
					matches = 0;
					break;
				}
				++testIndex;
			}
			if ( buf[ testIndex ] != '/' ) {
				matches = 0;
			}

			glob = fileglob_Create( buf );
			while ( fileglob_Next( glob ) ) {
				result = list_append(result,fileglob_FileName(glob) + (matches ? (searchSourceLen + searchSourceExtraLen) : 0),0);
			}
			fileglob_Destroy( glob );
		}
	}

    return result;
}



LIST *builtin_listsort( PARSE *parse, LOL *args, int *jmp )
{
	LIST *l = list_copy( L0, lol_get( args, 0 ) );
    LIST *caseSensitiveList = lol_get( args, 1 );
	int caseSensitive = 1;
	if ( list_first(caseSensitiveList) )
		caseSensitive = atoi(list_value(list_first(caseSensitiveList)));

	return list_sort(l, caseSensitive);
}



LIST *builtin_dependslist(PARSE *parse, LOL *args, int *jmp)
{
	LIST *result = L0;
	LIST *parents = lol_get(args, 0);
	LISTITEM* parent;
	
    for (parent = list_first(parents); parent; parent = list_next(parent)) {
		TARGET *t = bindtarget(list_value(parent));
		TARGETS *child;

		for (child = t->depends; child; child = child->next)
		{
			result = list_append(result, child->target->name, 1);
	    }
	}
	
	return result;
}


LIST *builtin_quicksettingslookup(PARSE *parse, LOL *args, int *jmp)
{
	TARGET* t;
	LIST* symbol;
	SETTINGS* settings;

	LIST *target = lol_get(args, 0);
	if (!list_first(target))
		return L0;

	symbol = lol_get(args, 1);
	if (!list_first(symbol))
		return L0;

	t = bindtarget(list_value(list_first(target)));
	settings = quicksettingslookup(t, list_value(list_first(symbol)));
	if (settings)
		return list_copy(L0, settings->value);

	return L0;
}


LIST *builtin_ruleexists(PARSE *parse, LOL *args, int *jmp)
{
	LIST* symbol;
	const char* rulename;

	symbol = lol_get(args, 0);
	if (!list_first(symbol))
		return L0;

	rulename = list_value( list_first( symbol ) );
	if ( ruleexists( rulename ) )
		return list_append( L0, "true", 0 );

	if ( !lol_get( args, 1 ) )
		return L0;

#ifdef OPT_LOAD_MISSING_RULE_EXT
	if( ruleexists( "FindMissingRule" ) ) {
		LOL lol;
		LIST *args = list_append( L0, rulename, 0 );
		LIST *result;

		lol_init( &lol );
		lol_add( &lol, args );
		result = evaluate_rule( "FindMissingRule", &lol, L0 );
		lol_free( &lol );

		if( list_first( result ) ) {
			list_free( result );
			return list_append( L0, "true", 0 );
		}

		list_free( result );
	}
#endif /* OPT_LOAD_MISSING_RULE_EXT */

	return L0;
}


extern char leftParen;
extern char rightParen;
LIST *builtin_configurefilehelper(PARSE *parse, LOL *args, int *jmp)
{
	TARGET* target;
	TARGET* source;
	LIST* targetName;
	LIST* sourceName;
	LIST* options;
	LISTITEM* item;
	FILE* file;
	const char* sourceFilename;
	LIST* newLines = L0;
	int mustWrite;
	int expand;
	time_t time;

	targetName = lol_get(args, 0);
	if (!list_first(targetName))
		return L0;

	sourceName = lol_get(args, 1);
	if (!list_first(sourceName))
		return L0;

	options = lol_get(args, 2);

	expand = 1;
	if (options) {
		for (item = list_first(options); item; item = list_next(item)) {
			const char* option = list_value(item);
			if (strcmp(option, "noexpand") == 0) {
				expand = 0;
			}
		}
	}

	source = bindtarget(list_value(list_first(sourceName)));
	sourceFilename = search_using_target_settings(source, source->name, &time);
	file = fopen(sourceFilename, "rt");
	if (!file)
		return L0;

	if (file) {
		while (!feof(file)) {
			LIST *list = L0;
			LOL lol;
			char* cmakeDefine;
			char line[10000];

			if (!fgets(line, 10000, file))
				break;

			if (expand) {
				lol_init(&lol);
				leftParen = '{';
				rightParen = '}';
				list = var_expand(L0, line, line + strlen(line), &lol, 0);
				leftParen = '(';
				rightParen = ')';
				strcpy(line, list_value(list_first(list)));
				cmakeDefine = strstr(line, "#cmakedefine ");
				if (cmakeDefine) {
					char newLine[10000];
					char saveCh;
					char* key = cmakeDefine + 13;
					LIST* value;
					char* rest;
					while ((*key == ' '  ||  * key == '\t')  &&  *key != 0) {
						++key;
					}
					if (*key == 0) {
						/* invalid */
					}
					rest = key;
					while (*rest != 0  &&  *rest != ' '  &&  *rest != '\t'  &&  *rest != '\n') {
						++rest;
					}

					saveCh = *rest;
					*rest = 0;
					value = var_get(key);

					if (value) {
						*rest = saveCh;
						sprintf(newLine, "#define %s", key);
						newLines = list_append(newLines, newLine, 0);
					} else {
						sprintf(newLine, "/* #undef %s */\n", key);
						newLines = list_append(newLines, newLine, 0);
					}
				} else {
					char* undef = strstr(line, "#undef ");
					if (undef) {
						char newLine[10000];
						char saveCh;
						char* key = undef + 7;
						LIST* value;
						char* rest;
						while ((*key == ' '  ||  * key == '\t')  &&  *key != 0) {
							++key;
						}
						if (*key == 0) {
							/* invalid */
						}
						rest = key;
						while (*rest != 0  &&  *rest != ' '  &&  *rest != '\t'  &&  *rest != '\n') {
							++rest;
						}

						saveCh = *rest;
						*rest = 0;
						value = var_get(key);

						if (value) {
							sprintf(newLine, "#define %s ", key);
							strcat(newLine, list_value(list_first(value)));
							*rest = saveCh;
							strcat(newLine, rest);
							newLines = list_append(newLines, newLine, 0);
						} else {
							sprintf(newLine, "/* #undef %s */\n", key);
							*rest = saveCh;
							newLines = list_append(newLines, newLine, 0);
						}
					} else {
						newLines = list_append(newLines, line, 0);
					}
				}

				list_free(list);
				lol_free(&lol);
			} else {
				newLines = list_append(newLines, line, 0);
			}
		}
		fclose(file);
	}

	target = bindtarget(list_value(list_first(targetName)));
	mustWrite = 1;
	if (target) {
		LISTITEM* newLine = list_first(newLines);
		const char* destinationFilename = search_using_target_settings(target, target->name, &time);
		file_mkdir(destinationFilename);
		file = fopen(destinationFilename, "rt");
		if (file) {
			mustWrite = 0;
			while (!mustWrite  &&  !feof(file)) {
				char line[10000];
				if (!fgets(line, 10000, file)) {
					break;
				}
				mustWrite = strcmp(list_value(newLine), line) != 0;
				newLine = list_next(newLine);
			}
			fclose(file);
		}
	}

	if (mustWrite) {
		LISTITEM* newLine = list_first(newLines);
		const char* destinationFilename = search_using_target_settings(target, target->name, &time);
		file = fopen(destinationFilename, "wb");
		while (newLine) {
			fputs(list_value(newLine), file);
			//fputc('\n', file);
			newLine = list_next(newLine);
		}
		fclose(file);
		timestamp( destinationFilename, &time, 1 );
		target->binding = T_BIND_UNBOUND;
	}

	return L0;
}


LIST *builtin_search(PARSE *parse, LOL *args, int *jmp)
{
	LIST* targetName;
	TARGET* target;
	const char* filename;
	time_t time;

	targetName = lol_get(args, 0);
	if (!list_first(targetName))
		return L0;

	target = bindtarget(list_value(list_first(targetName)));
	filename = search_using_target_settings(target, target->name, &time);
	if (time == 0)
		return L0;
	return list_append( L0, filename, 0 );
}


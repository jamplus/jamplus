/*
 * /+\
 * +\	Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 * \+/
 *
 * This file is part of jam.
 *
 * License is hereby granted to use this software and distribute it
 * freely, as long as this copyright notice is retained and modifications
 * are clearly marked.
 *
 * ALL WARRANTIES ARE HEREBY DISCLAIMED.
 */
/*
 * jam.c - make redux
 *
 * See Jam.html for usage information.
 *
 * These comments document the code.
 *
 * The top half of the code is structured such:
 *
 *                       jam
 *                      / | \
 *                 +---+  |  \
 *                /       |   \
 *         jamgram     option  \
 *        /  |   \              \
 *       /   |    \              \
 *      /    |     \             |
 *  scan     |     compile      make
 *   |       |    /  | \       / |  \
 *   |       |   /   |  \     /  |   \
 *   |       |  /    |   \   /   |    \
 * jambase parse     |   rules  search make1
 *                   |           |      |   \
 *                   |           |      |    \
 *                   |           |      |     \
 *               builtins    timestamp command execute
 *                               |
 *                               |
 *                               |
 *                             filesys
 *
 *
 * The support routines are called by all of the above, but themselves
 * are layered thus:
 *
 *                     variable|expand
 *                      /  |   |   |
 *                     /   |   |   |
 *                    /    |   |   |
 *                 lists   |   |   pathsys
 *                    \    |   |
 *                     \   |   |
 *                      \  |   |
 *                     newstr  |
 *                        \    |
 *                         \   |
 *                          \  |
 *                          hash
 *
 * Roughly, the modules are:
 *
 *	builtins.c - jam's built-in rules
 *	command.c - maintain lists of commands
 *	compile.c - compile parsed jam statements
 *	execunix.c - execute a shell script on UNIX
 *	execvms.c - execute a shell script, ala VMS
 *	expand.c - expand a buffer, given variable values
 *	file*.c - scan directories and archives on *
 *	hash.c - simple in-memory hashing routines
 *	hcache.c - handle caching of #includes in source files
 *	headers.c - handle #includes in source files
 *	jambase.c - compilable copy of Jambase
 *	jamgram.y - jam grammar
 *	lists.c - maintain lists of strings
 *	make.c - bring a target up to date, once rules are in place
 *	make1.c - execute command to bring targets up to date
 *	newstr.c - string manipulation routines
 *	option.c - command line option processing
 *	parse.c - make and destroy parse trees as driven by the parser
 *	path*.c - manipulate file names on *
 *	hash.c - simple in-memory hashing routines
 *	regexp.c - Henry Spencer's regexp
 *	rules.c - access to RULEs, TARGETs, and ACTIONs
 *	scan.c - the jam yacc scanner
 *	search.c - find a target along $(SEARCH) or $(LOCATE)
 *	timestamp.c - get the timestamp of a file or archive member
 *	variable.c - handle jam multi-element variables
 *
 * 05/04/94 (seiwald) - async multiprocess (-j) support
 * 02/08/95 (seiwald) - -n implies -d2.
 * 02/22/95 (seiwald) - -v for version info.
 * 09/11/00 (seiwald) - PATCHLEVEL folded into VERSION.
 * 01/10/01 (seiwald) - pathsys.h split from filesys.h
 * 01/21/02 (seiwald) - new -q to quit quickly on build failure
 * 03/16/02 (seiwald) - support for -g (reorder builds by source time)
 * 09/19/02 (seiwald) - new -d displays
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 11/04/02 (seiwald) - const-ing for string literals
 */

# include "jam.h"
# include "option.h"
# include "patchlevel.h"

/* These get various function declarations. */

# include "lists.h"
# include "parse.h"
# include "variable.h"
# include "compile.h"
# include "builtins.h"
# include "rules.h"
# include "newstr.h"
# include "scan.h"
# include "timestamp.h"
# include "make.h"

# include "buffer.h"
# include "expand.h"

# include "filesys.h"

# include "hcache.h"

#ifdef OPT_BUILTIN_MD5CACHE_EXT
# include "md5.h"
#endif

#ifdef OPT_VAR_CWD_EXT
#if _MSC_VER
#include <direct.h>
#else
#include <unistd.h>
#endif
#endif

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
# include "luasupport.h"
#endif

#ifdef OPT_SCRIPTS_PASSTHROUGH_EXT
#include <stdlib.h>
#include "execcmd.h"
#endif

#include "fileglob.h"
#include "miniz.h"

#ifdef NT
#include <io.h>
#endif

/* Macintosh is "special" */

# ifdef OS_MAC
# include <QuickDraw.h>
# endif

# ifdef OS_MACOSX
#include <sys/types.h>
#include <sys/sysctl.h>
# endif

/* And UNIX for this */

# ifdef unix
# include <sys/utsname.h>
# endif
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
static int malloc_bytes = 0;
static int realloc_bytes = 0;
#endif /* OPT_DEBUG_MEM_TOTALS_EXT */

struct globs globs = {
#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
	1,			/* printtarget */
#endif
#ifdef OPT_IMPROVED_PROGRESS_EXT
	0,			/* updating */
	0,			/* start */
#endif
	0,			/* noexec */
	1,			/* jobs */
	0,			/* quitquick */
	0,			/* newestfirst */
# ifdef OS_MAC
	{ 0 },			/* display - suppress actions output */
# else
	{ 0, 1 }, 		/* display actions  */
# endif
	0,			/* output commands, not run them */
	0,                      /* silence */
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	0,          /* lua debugger */
#endif
} ;

/* Symbols to be defined as true for use in Jambase */

static const char *othersyms[] = { OSMAJOR, OSMINOR, OSPLAT, JAMVERSYM,
                                   DPG_JAMVERSION, 0 } ;

/* Known for sure:
 *	mac needs arg_enviro
 *	OS2 needs extern environ
 */

# ifdef OS_MAC
# define use_environ arg_environ
# ifdef MPW
QDGlobals qd;
# endif
# endif

# ifndef use_environ
# define use_environ environ
# if !defined( __WATCOM__ ) && !defined( OS_OS2 ) && !defined( OS_NT )
extern char **environ;
# endif
# endif

extern int nodepcache;
#ifdef OPT_USE_CHECKSUMS_EXT
extern int usechecksums;
#endif /* OPT_USE_CHECKSUMS_EXT */

int embedbuildmodules(const char *rootDirectory);
int extractbuildmodules(const char *rootDirectory);

int main( int argc, char **argv, char **arg_environ )
{
	int		n, num_targets;
	const char	*s;
	struct option	optv[N_OPTS];
	char*       targets[N_TARGETS];
	const char	*all = "all";
	int		anyhow = 0;
	int		status;
#ifdef OPT_PRINT_TOTAL_TIME_EXT
#if _MSC_VER  &&  _MSC_VER < 1300
	unsigned __int64 start;
#else
	unsigned long long	start;
#endif
	start = getmilliseconds();
//	time_t		start;
//	time(&start);
#endif

# ifdef OS_MAC
	InitGraf(&qd.thePort);
# endif

	argc--, argv++;
#ifdef OPT_SCRIPTS_PASSTHROUGH_EXT
    {
        int argstartindex;
        for ( argstartindex = 0; argstartindex < argc; ++argstartindex ) {
            if ( argv[argstartindex][0] == '-'  &&  argv[argstartindex][1] == '-' ) {
                char processPath[4096];
                int i;
                const char* name = argv[argstartindex] + 2;

				if (strcmp(name, "embedbuildmodules") == 0  ||  strcmp(name, "embed") == 0) {
					++argstartindex;
					embedbuildmodules(argc == argstartindex + 1 ? argv[argstartindex] : NULL);
					return EXITOK;
				}

				if (strcmp(name, "extractbuildmodules") == 0  ||  strcmp(name, "extract") == 0) {
					++argstartindex;
					extractbuildmodules(argc == argstartindex + 1 ? argv[argstartindex] : NULL);
					return EXITOK;
				}

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
				BUFFER buff;
				const char* appsPath = "apps/";

                getprocesspath( processPath, sizeof( processPath ) );

                putenv( OSMINOR );
                putenv( OSPLAT );

				{
					char exeName[ 4096 ];
#if defined(_MSC_VER) || defined(__MINGW32__) || defined(__MINGW64__)
					strcpy( exeName, "JAM_EXECUTABLE=" );

					getexecutablepath( exeName + strlen( exeName ), 4096 - strlen( exeName ) );
					putenv( exeName );
#else
					getexecutablepath( exeName, 4096 );
					setenv( "JAM_EXECUTABLE", exeName, 1 );
#endif
				}

				buffer_init(&buff);
				buffer_addstring(&buff, processPath, strlen(processPath));
				buffer_addstring(&buff, "/../", 4);
				buffer_addstring(&buff, appsPath, strlen(appsPath));
				buffer_addstring(&buff, name, strlen(name));
				buffer_addstring(&buff, ".lua", 4);
				buffer_addchar(&buff, 0);

				LIST* args = L0;
                for ( i = argstartindex + 1; i < argc; ++i ) {
					args = list_append(args, argv[i], 0);
                }
				luahelper_call_script(buffer_ptr(&buff), args);
				buffer_free(&buff);
#else
                char* scriptPath;
                char* ptr;
                int size;
                char* commandLine;

                scriptPath = malloc( strlen( processPath ) + 1 + strlen( name ) + 4 + 1 );
                strcpy( scriptPath, processPath );
                strcat( scriptPath, "/" );
                strcat( scriptPath, name );

# ifdef NT
                ptr = scriptPath + strlen( scriptPath );
                strcpy( ptr, ".bat" );
                if ( access( scriptPath, 0 ) == -1 ) {
                    strcpy( ptr, ".cmd" );
                    if ( access( scriptPath, 0 ) == -1 ) {
                        strcpy( ptr, ".exe" );
                        if ( access( scriptPath, 0 ) == -1 ) {
                            printf("* Unable to access script %s.\n", name);
                            exit(-1);
                        }
                    }
                }
# else
                ptr = scriptPath + strlen( scriptPath );
                if ( access( scriptPath, 0 ) == -1 ) {
                    strcpy( ptr, ".sh" );
                    if ( access( scriptPath, 0 ) == -1 ) {
                        printf("* Unable to access script %s.\n", name);
                        exit(-1);
                    }
                }
# endif

                size = 4;
                for ( i = argstartindex; i < argc; ++i ) {
                    int needsEscape = 0;
                    const char* argvptr = i == argstartindex ? scriptPath : argv[i];
                    while ( *argvptr ) {
                        if ( *argvptr == ' ' )
                            needsEscape++;
                        ++size;
                        ++argvptr;
                    }
                    size += needsEscape + 1;
                }

                commandLine = malloc( size + 1 );
                ptr = commandLine;

                for ( i = argstartindex; i < argc; ++i ) {
                    int needsEscape = i == 0 ? 1 : 0;
                    const char* argvptr = i == argstartindex ? scriptPath : argv[i];
                    if ( !needsEscape ) {
                        while ( *argvptr ) {
                            if ( *argvptr == ' ' ) {
                                needsEscape = 1;
                                break;
                            }
                            ++argvptr;
                        }
                    }
#ifdef NT
                    if ( needsEscape )
                        *ptr++ = '"';
#endif

                    argvptr = i == argstartindex ? scriptPath : argv[i];
                    while ( *argvptr ) {
#ifndef NT
                        if ( *argvptr == ' ' )
                            *ptr++ = '\\';
#endif
                        *ptr++ = *argvptr++;
                    }

#ifdef NT
                    if ( needsEscape )
                        *ptr++ = '"';
#endif
                    *ptr++ = ' ';
                }

                *ptr = 0;

                putenv( OSMINOR );
                putenv( OSPLAT );

				{
					char exeName[ 4096 ];
#if defined(_MSC_VER)
					strcpy( exeName, "JAM_EXECUTABLE=" );

					getexecutablepath( exeName + strlen( exeName ), 4096 - strlen( exeName ) );
					putenv( exeName );
#else
					getexecutablepath( exeName, 4096 );
					setenv( "JAM_EXECUTABLE", exeName, 1 );
#endif
				}

                exec_init();
                execcmd( commandLine, NULL, NULL, NULL, 0 );
                execwait();
                exec_done();

                free( commandLine );
                free( scriptPath );
#endif

                return EXITOK;
            }
        }
    }
#endif

#if 0
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
#ifndef OS_NT
    if ( !getenv( "JAM_DYLD_FALLBACK_LIBRARY_PATH_SET" ) )
    {
	char fileName[4096];
		char exeName[4096];
	getprocesspath(fileName, 4096);
	strcat(fileName, "/lua");

	setenv("DYLD_FALLBACK_LIBRARY_PATH", fileName, 1);
	setenv("JAM_DYLD_FALLBACK_LIBRARY_PATH_SET", "true", 1);

	getexecutablepath(exeName, 4096);

	argc++, argv--;
	argv[0] = exeName;
	execve(exeName, argv, environ);
	perror("execve");

	return 0;
    }
#endif
#endif
#endif

#ifdef OPT_SETCWD_SETTING_EXT
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	if( ( num_targets = getoptions( argc, argv, "d:C:j:f:gs:t:Tabno:qvS", optv, targets ) ) < 0 )
#else
	if( ( num_targets = getoptions( argc, argv, "d:C:j:f:gs:t:Tano:qvS", optv, targets ) ) < 0 )
#endif
#else
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	if( ( num_targets = getoptions( argc, argv, "d:j:f:gs:t:abno:qv", optv, targets ) ) < 0 )
#else
	if( ( num_targets = getoptions( argc, argv, "d:j:f:gs:t:ano:qv", optv, targets ) ) < 0 )
#endif
#endif
	{
	    printf( "\nusage: jam [ options ] targets...\n\n" );

            printf( "-a      Build all targets, even if they are current.\n" );
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
            printf( "-b      Enable Lua debugger.\n" );
#endif
#ifdef OPT_SETCWD_SETTING_EXT
            printf( "-Cx     Set working directory to x.\n" );
#endif
            printf( "-dx     Display (a)actions (c)causes (d)dependencies\n" );
	    printf( "        (m)make tree (x)commands (0-9) debug levels.\n" );
#ifdef OPT_GRAPH_DEBUG_EXT
	    printf( "        (g)graph (f)fate changes.\n");
#endif /* OPT_GRAPH_DEBUG_EXT */
            printf( "-fx     Read x instead of Jambase.\n" );
	    printf( "-g      Build from newest sources first.\n" );
            printf( "-jx     Run up to x shell commands concurrently.\n" );
            printf( "-n      Don't actually execute the updating actions.\n" );
            printf( "-ox     Write the updating actions to file x.\n" );
            printf( "-q      Quit quickly as soon as a target fails.\n" );
            printf( "-S      Silence on missing rules.\n" );
	    printf( "-sx=y   Set variable x=y, overriding environment.\n" );
            printf( "-tx     Rebuild x, even if it is up-to-date.\n" );
#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
	    printf( "-T      Toggle printing of target's name.\n");
#endif /* OPT_DEBUG_MAKE_PRINT_TARGET_NAME */
            printf( "-v      Print the version of jam and exit.\n\n" );


#ifdef OPT_IMPROVE_DEBUG_LEVEL_HELP_EXT
	    printf( "\n" );

	    /* CWM - Added help on debug levels */
	    printf( "The debug levels are:\n" );
	    printf( "  1 - show make actions when executed\n" );
	    printf( "  2 - show text of actions\n" );
	    printf( "  3 - show progress of make.  Show files when bound\n" );
	    printf( "  4 - show execcmds()'s work\n" );
	    printf( "  5 - show rule invocations\n" );
	    printf( "  6 - show header scan, dir scan, attempts at binding\n" );
	    printf( "  7 - show variable setting\n" );
	    printf( "  8 - show variable fetches and expansions.  "
		    "show 'if' calculations\n" );
	    printf( "  9 - show scanner tokens.  Show memory use\n" );
	    printf( "\n" );
	    printf( "  To select individual debug levels, try:  -d+n -d+n...\n" );

#endif
	    exit( EXITBAD );
	}

	/* Version info. */

	if( ( s = getoptval( optv, 'v', 0 ) ) )
	{
	    printf( "JamPlus %s (based on Jam %s). %s.\n", JAMPLUS_VERSION, JAM_VERSION, OSMINOR );
	    printf( "    Jam is Copyright 1993-2002 Christopher Seiwald.\n" );
#ifdef OPT_PATCHED_VERSION_VAR_EXT
	    printf( "PATCHED_VERSION %s.%s\n",
		    PATCHED_VERSION_MAJOR, PATCHED_VERSION_MINOR);
#ifdef DEBUG_J
	    printf( "This is a DEBUG version.\n");
#endif
#endif

	    return EXITOK;
	}

	/* Pick up interesting options */

#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
	if( ( s = getoptval( optv, 'T', 0 ) ) )
	    globs.printtarget = !globs.printtarget;
#endif /* OPT_DEBUG_MAKE_PRINT_TARGET_NAME */
	if( ( s = getoptval( optv, 'n', 0 ) ) )
	    globs.noexec++, DEBUG_MAKE = DEBUG_MAKEQ = DEBUG_EXEC = 1;

	if( ( s = getoptval( optv, 'q', 0 ) ) )
	    globs.quitquick = 1;

	if( ( s = getoptval( optv, 'a', 0 ) ) )
	    anyhow++;

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	if( ( s = getoptval( optv, 'b', 0 ) ) )
	    globs.lua_debugger = 1;
#endif

	if( ( s = getoptval( optv, 'S', 0 ) ) )
	    globs.silence = 1;

#ifdef OPT_SETCWD_SETTING_EXT
	if( ( s = getoptval( optv, 'C', 0 ) ) )
		chdir(s);
#endif /* OPT_IMPROVE_JOBS_SETTING_EXT */

#ifdef OPT_IMPROVE_JOBS_SETTING_EXT
#ifdef OS_NT
{
    const char *jobs = getenv("NUMBER_OF_PROCESSORS");
    if (jobs)
        globs.jobs = atoi( jobs );
	if (globs.jobs == 0)
		globs.jobs = 1;
}
#elif defined(OS_MACOSX)
{
	int mib[2];
	size_t len;
	int numProcessors;
	mib[0] = CTL_HW;
	mib[1] = HW_NCPU;
	len = sizeof(numProcessors);
	int result = sysctl(mib, 2, &numProcessors, &len, NULL, 0);
	if (result == -1)
	{
		globs.jobs = 1;
	}
	else
	{
		globs.jobs = numProcessors;
	}
}
#endif /* OS_NT */
#endif /* OPT_IMPROVE_JOBS_SETTING_EXT */

	if( ( s = getoptval( optv, 'j', 0 ) ) )
	    globs.jobs = atoi( s );

	if( ( s = getoptval( optv, 'g', 0 ) ) )
	    globs.newestfirst = 1;

	/* Turn on/off debugging */

	for( n = 0; (s = getoptval( optv, 'd', n )); n++ )
	{
	    int i = atoi( s );

	    /* First -d, turn off defaults. */

	    if( !n )
		DEBUG_MAKE = DEBUG_MAKEQ = DEBUG_EXEC = 0;

	    /* n turns on levels 1-n */
	    /* +n turns on level n */
	    /* c turns on named display c */

	    if( i < 0 || i >= DEBUG_MAX )
	    {
		printf( "Invalid debug level '%s'.\n", s );
	    }
	    else if( *s == '+' )
	    {
		globs.debug[i] = 1;
	    }
	    else if( i ) while( i )
	    {
		globs.debug[i--] = 1;
	    }
	    else while( *s ) switch( *s++ )
	    {
	    case 'a': DEBUG_MAKE = DEBUG_MAKEQ = 1; break;
	    case 'c': DEBUG_CAUSES = 1; break;
#ifdef OPT_BUILTIN_MD5CACHE_EXT
		case 'h': DEBUG_MD5HASH = 1; break;
#endif
	    case 'd': DEBUG_DEPENDS = 1; break;
#ifdef OPT_GRAPH_DEBUG_EXT
	    case 'f': DEBUG_FATE = 1; break;
	    case 'g': DEBUG_GRAPH = 1; break;
#endif /* OPT_GRAPH_DEBUG_EXT */
	    case 'm': DEBUG_MAKEPROG = 1; break;
	    case 'x': DEBUG_EXEC = 1; break;
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
	    case 'T': DEBUG_MEM_TOTALS = 1; break;
#endif
#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    case 'M' : DEBUG_MAKE1 = 1; break;
#endif
	    case '0': break;
	    default: printf( "Invalid debug flag '%c'.\n", s[-1] );
	    }
	}

	var_set( "CRLF", list_append(L0, "\r\n", 0), VAR_SET );

	/* Set JAMDATE first */

	{
	    char buf[ 128 ];
	    time_t clock;
	    time( &clock );
	    strcpy( buf, ctime( &clock ) );

	    /* Trim newline from date */

	    if( strlen( buf ) == 25 )
		buf[ 24 ] = 0;

	    var_set( "JAMDATE", list_append( L0, buf, 0 ), VAR_SET );
	}

	/* And JAMUNAME */
# ifdef unix
	{
	    struct utsname u;

	    if( uname( &u ) >= 0 )
	    {
		LIST *l = L0;
		l = list_append( l, u.machine, 0 );
		l = list_append( l, u.version, 0 );
		l = list_append( l, u.release, 0 );
		l = list_append( l, u.nodename, 0 );
		l = list_append( l, u.sysname, 0 );
		var_set( "JAMUNAME", l, VAR_SET );
	    }
	}
# endif /* unix */

#ifdef OPT_VAR_CWD_EXT
        /* And CWD */
        {
            char filebuf[4096];
            if (getcwd(filebuf, sizeof(filebuf))) {
#ifdef NT
                /*
                    Under the Visual Studio debugger, the drive letter is capitalized. At the Command Prompt,
                    the drive letter is lowercase. This causes issues with the command-line MD5sums, so make
                    the drive letter lowercase all of the time.
                */
                if (filebuf[1] == ':') {
                    filebuf[0] = tolower(filebuf[0]);
                }
#endif /* NT */
                var_set( "CWD", list_append( L0, filebuf, 0 ), VAR_SET );
            }
        }
#endif

#ifdef OPT_SET_JAMPROCESSPATH_EXT
	{
	    char fileName[4096];
	    getprocesspath(fileName, 4096);
	    var_set( "JAM_PROCESS_PATH", list_append( L0, fileName, 0 ), VAR_SET );
	}
	{
		char exeName[ 4096 ];
		getexecutablepath( exeName, 4096 );
		var_set( "JAM_EXECUTABLE_PATH", list_append( L0, exeName, 0 ), VAR_SET );
	}

#endif

	/*
	 * Jam defined variables OS, OSPLAT
	 */

	var_defines( othersyms );
#ifdef OPT_PATCHED_VERSION_VAR_EXT
#define QUOTE2(x) #x
#define QUOTE(x) QUOTE2(x)
	{
	    char *s;
	    char options[sizeof(QUOTE(JAM_OPTIONS)) + 1];
	    strcpy(options, QUOTE(JAM_OPTIONS));

	    var_set("PATCHED_JAM_VERSION",
		    list_append(list_append(L0, PATCHED_VERSION_MAJOR, 0),
			     PATCHED_VERSION_MINOR, 0),
		    VAR_SET);

	    for (s = strtok(options, ":"); s; s = strtok(NULL, ":")) {
		var_set("PATCHED_JAM_VERSION", list_append(L0, s, 0),
			VAR_APPEND);
	    }
	}
#endif

	/* load up environment variables */

	var_defines( (const char **)use_environ );

	/* Load up variables set on command line. */

	for( n = 0; (s = getoptval( optv, 's', n )); n++ )
	{
	    const char *symv[2];
	    symv[0] = s;
	    symv[1] = 0;
	    var_defines( symv );
	}

	/* Initialize built-in rules */

	load_builtins();

#ifdef OPT_JOB_SLOT_EXT
	/* Silently enforce maximum to be two digits */
	/* Test against 99 rather than MAXJOBS, as the intent of */
	/* this is to protect the fixed size buffers. MAXJOBS is */
	/* enforced elsewhere. */
	if( globs.jobs > 99 )
	    globs.jobs = 99;
#endif

#ifdef OPT_EXPORT_JOBNUM_EXT
	{
	    LIST *l = 0;
	    int i;
	    char num[20];

	    /* The number could be negative if the user is trying to be nasty */
	    if( globs.jobs < 1 )
		globs.jobs = 1;

	    /* How many jobs are we allowed to spawn? */
	    sprintf( num, "%d", globs.jobs );
	    var_set( "JAM_NUM_JOBS", list_append( 0, newstr( num ), 0 ), VAR_SET );

	    /* An easy test to see if there are multiple jobs */
	    if( globs.jobs > 1 )
		var_set( "JAM_MULTI_JOBS", list_append( 0, newstr( num ), 0 ),
			VAR_SET );

	    /* Create a list of the job nums. ie, -j4 -> 0 1 2 3 */
	    for( i = 0; i < globs.jobs; ++i )
	    {
		sprintf( num, "%d", i );
		l = list_append( l, newstr( num ), 0 );
	    }
	    var_set( "JAM_JOB_LIST", l, VAR_SET );
	}
#endif

    var_set( "DEPCACHE", list_append( L0, "standard", 0 ), VAR_SET );

#ifdef OPT_SET_JAMCOMMANDLINETARGETS_EXT
	{
		/* Go through the list of targets specified on the command line, */
		/* and add them to a variable called JAM_COMMAND_LINE_TARGETS. */
		LIST* l = L0;
		int n_targets = num_targets ? num_targets : 1;
		const char** actual_targets = num_targets ? (const char**)targets : &all;
		int i;

		for ( i = 0; i < n_targets; ++i )
		{
			l = list_append( l, actual_targets[ i ], 0 );
		}

		var_set( "JAM_COMMAND_LINE_TARGETS", l, VAR_SET );
	}
#endif

	/* Parse ruleset */

	for( n = 0; (s = getoptval( optv, 'f', n )); n++ )
	    parse_file( s );

	if( !n )
	    parse_file( "+" );

	status = yyanyerrors();

	/* Manually touch -t targets */

	for( n = 0; (s = getoptval( optv, 't', n )); n++ )
	    touchtarget( s );

	/* If an output file is specified, set globs.cmdout to that */

	if( (s = getoptval( optv, 'o', 0 )) )
	{
	    if( !( globs.cmdout = fopen( s, "w" ) ) )
	    {
		printf( "Failed to write to '%s'\n", s );
		exit( EXITBAD );
	    }
	    globs.noexec++;
	}

#ifdef OPT_SET_JAMCOMMANDLINETARGETS_EXT
	{
		LIST *jamCommandLineTargets = var_get("JAM_COMMAND_LINE_TARGETS");
		num_targets = 0;
		if ( jamCommandLineTargets )
		{
			LISTITEM *item;
			for ( item = list_first(jamCommandLineTargets); item; item = list_next(item) )
			{
				targets[num_targets++] = (char*)list_value(item);
			}
		}
	}
#endif

#ifdef OPT_USE_CHECKSUMS_EXT
	LIST *nodepcachelist = var_get("JAM_NO_DEPCACHE");
	if (nodepcachelist  &&  list_first(nodepcachelist)  &&  strcmp(list_value(list_first(nodepcachelist)), "1") == 0)
	{
		nodepcache = 1;
		var_set( "DEPCACHE.standard", NULL, VAR_REMOVE );
	}
	else
	{
		LIST *depcache = var_get("DEPCACHE.standard");
		if (!depcache)
		{
			const char* depcache_builtinfilename = hcache_get_builtinfilename();
			var_set( "DEPCACHE.standard", list_append( L0, depcache_builtinfilename, 0 ), VAR_SET );
#if 0
			if (ruleexists("Clean"))
			{
				LOL lol;
				LIST *result;
				lol_init(&lol);
				lol_add(&lol, list_append(L0, "clean", 0));
				lol_add(&lol, list_append(L0, depcache_builtinfilename, 0));
				result = evaluate_rule("Clean", &lol, L0);
				lol_free(&lol);
				list_free(result);
			}
#endif
		}
	}

	if (!nodepcache)
	{
		LIST *usechecksumslist = var_get("JAM_CHECKSUMS");
		if (!usechecksumslist)
		{
			usechecksumslist = var_get("JAM_USE_CHECKSUMS");
		}
		if (usechecksumslist  &&  list_first(usechecksumslist)  &&  strcmp(list_value(list_first(usechecksumslist)), "1") == 0)
		{
			usechecksums = 1;
		}
	}
#endif /* OPT_USE_CHECKSUMS_EXT */

	/* Now make target */

	if( !num_targets )
	    status |= make( 1, &all, anyhow );
	else
	    status |= make( num_targets, (const char**)targets, anyhow );

	/* Widely scattered cleanup */

	var_done();
	donerules();
	donestamps();
	donestr();
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
	list_done();
	parse_done();
	if (DEBUG_MEM || DEBUG_MEM_TOTALS) {
	    printf("%dK total malloc()\n", malloc_bytes / 1024);
	    printf("%dK total realloc()\n", realloc_bytes / 1024);
	}
#endif

	/* close cmdout */

	if( globs.cmdout )
	    fclose( globs.cmdout );

#ifdef OPT_PRINT_TOTAL_TIME_EXT
	{
#if _MSC_VER  &&  _MSC_VER < 1300
	    unsigned __int64 now;
#else
	    unsigned long long now;
#endif
//	    time_t now;
	    long elapsed;
	    const char* elapsed_logfile_name;

	    now = getmilliseconds();
	    elapsed = (long)(now - start);
//	    time( &now );
//	    elapsed = (long)difftime(now, start);

//	    if (elapsed > 10)
	    {
		long hundredths = elapsed / 10 % 100;
		long seconds = (elapsed / 1000) % 60;
		long minutes = (elapsed / 1000) / 60;

		if ( DEBUG_MAKE )
		{
		printf("*** finished in ");
		if (minutes > 0)
		    printf("%ld min %ld sec\n", minutes, seconds);
		else
		    printf("%ld.%02d sec\n", seconds, (int)hundredths);
//		printf("*** finished in %d\n", elapsed);
		}
	    }

	    elapsed_logfile_name = getenv("JAM_ELAPSED_LOGFILE");
	    if (elapsed_logfile_name)
	    {
		FILE* file = fopen(elapsed_logfile_name, "a");
		if (!file) {
		    printf("could not open elapsed log file \"%s\"\n",
			   elapsed_logfile_name);
		    printf("check the JAM_ELAPSED_LOGFILE "
			   "environment variable.\n");
		} else {
		    fprintf(file, "when %ld elapsed %ld\n",
			    (long)now, elapsed);
		    fclose(file);
		}
	    }
	}
#endif
	return status ? EXITBAD : EXITOK;
}

#if defined(PURE) && !defined(NT)
int check_leaks(void)
{
    if (purify_new_leaks()) {
	/* Dereference a NULL pointer in such a way that Purify can
	 * bring up the debugger */
	char* null_pointer = 0;
	*null_pointer = 'Z';
	return 1;
    }
    return 0;
}
#endif

#ifdef OPT_DEBUG_MEM_TOTALS_EXT
void*
track_malloc(size_t mem)
{
    malloc_bytes += (int)mem;
#undef malloc
    return malloc(mem);
//#define malloc(x) do_not_call_malloc_after_this(x)
}

void*
track_realloc(void *ptr, size_t size)
{
    realloc_bytes += (int)size;
#undef realloc
    return realloc(ptr, size);
//#define realloc(a,b) do_not_call_realloc_after_this(a,b)
}
#endif

#define ZIPBUFFERHEADER_SIGNATUREA "JamZipBu"
#define ZIPBUFFERHEADER_SIGNATUREB "fferInfo"

typedef struct _JamZipBufferInfo
{
	uint8_t signatureA[8];
	uint64_t startOffset;
	uint64_t size;
	uint8_t signatureB[8];
} JamZipBufferInfo;


int zipArchiveOpenedSuccessfully = -1;
mz_zip_archive *pZipArchive = NULL;

/*
const unsigned char *zip_get_jamZipBuffer() {
	return jamZipBuffer;
}

size_t zip_get_jamZipBuffer_size() {
	return sizeof(jamZipBuffer);
}
*/

mz_zip_archive *zip_attemptopen() {
	if (pZipArchive == NULL  &&  zipArchiveOpenedSuccessfully == -1)
	{
		JamZipBufferInfo jamZipBufferInfo;
		uint64_t executableSize = 0;
		char executablePath[1000];

		pZipArchive = malloc(sizeof(mz_zip_archive));
		mz_zip_zero_struct(pZipArchive);

		getexecutablepath(executablePath, sizeof(executablePath));

		memcpy(&jamZipBufferInfo.signatureA, ZIPBUFFERHEADER_SIGNATUREA, 8);
		jamZipBufferInfo.startOffset = 0;
		jamZipBufferInfo.size = 0;
		memcpy(&jamZipBufferInfo.signatureB, ZIPBUFFERHEADER_SIGNATUREB, 8);

		{
			FILE *file = NULL;
#if defined(_MSC_VER)
			fopen_s(&file, executablePath, "rb");
#else
			file = fopen(executablePath, "rb");
#endif
			if (file != NULL)
			{
				JamZipBufferInfo testJamZipBufferInfo;
				fseek(file, -(int)sizeof(JamZipBufferInfo), SEEK_END);
				fread(&testJamZipBufferInfo, sizeof(JamZipBufferInfo), 1, file);
				executableSize = ftell(file);
				fclose(file);

				if (memcmp(&testJamZipBufferInfo.signatureA, ZIPBUFFERHEADER_SIGNATUREA, 8) == 0
						&& memcmp(&testJamZipBufferInfo.signatureB, ZIPBUFFERHEADER_SIGNATUREB, 8) == 0
						&& testJamZipBufferInfo.startOffset + testJamZipBufferInfo.size == executableSize - sizeof(JamZipBufferInfo)
					)
				{
					jamZipBufferInfo.startOffset = testJamZipBufferInfo.startOffset;
					jamZipBufferInfo.size = testJamZipBufferInfo.size;
					executableSize = jamZipBufferInfo.startOffset;


					if (!mz_zip_reader_init_file_v2(pZipArchive, executablePath, 0, jamZipBufferInfo.startOffset, jamZipBufferInfo.size))
					{
						zipArchiveOpenedSuccessfully = 0;
						mz_zip_end(pZipArchive);
						free(pZipArchive);
					}
					else
					{
						zipArchiveOpenedSuccessfully = 1;
						return pZipArchive;
					}
				}
			}
		}
	}
	return pZipArchive;
}

int zip_findfile(const char *filename) {
	//printf("zip_findfile: %s\n", filename);
	zip_attemptopen();
	if (pZipArchive == NULL)
	{
	//printf("zip_findfile: no zip\n", filename);
		return -1;
	}

	// Search for the file.
	const char* srcPtr = filename;
	BUFFER buff;
	buffer_init(&buff);
	while (*srcPtr != 0)
	{
		if (*srcPtr == '\\')
		{
			buffer_addchar(&buff, '/');
		}
		else
		{
			buffer_addchar(&buff, *srcPtr);
		}
		++srcPtr;
	}
	buffer_addchar(&buff, 0);

	const char* filenamePtr = buffer_ptr(&buff);
	//printf("zip_findfile: filenamePtr: %s\n", filenamePtr);
	int index = mz_zip_reader_locate_file(pZipArchive, filenamePtr, NULL, 0);
	//printf("zip_findfile: index: %d\n", index);
	if (index == -1)
	{
		while (*filenamePtr != 0)
		{
			if (*filenamePtr == '/')
			{
	//printf("zip_findfile: filenamePtr-again: %s\n", filenamePtr + 1);
				index = mz_zip_reader_locate_file(pZipArchive, filenamePtr + 1, NULL, 0);
				if (index != -1)
				{
					break;
				}
			}
			++filenamePtr;
		}
	}

	buffer_free(&buff);
	return index;
}


int copyfilemaxbytes(const char *dst, const char *src, size_t maxBytesToCopy)
{
	size_t size = 0, sizeout = 0;
	size_t bytesCopied = 0;
	FILE *fsrc = NULL, *fdst = NULL;
	unsigned char block[1 << 16];

#if defined(_MSC_VER)
	fopen_s(&fsrc, src, "rb");
#else
	fsrc = fopen(src, "rb");
#endif
	if (fsrc == NULL) {
		return 0;
	}

	file_mkdir(dst);

#if defined(_MSC_VER)
	fopen_s(&fdst, dst, "wb");
#else
	fdst = fopen(dst, "wb");
#endif
	if (fdst == NULL) {
		fclose(fsrc);
		return 0;
	}

	while (!feof(fsrc) && bytesCopied < maxBytesToCopy) {
		size_t bytesToCopy = sizeof(block);
		if (bytesCopied + bytesToCopy > maxBytesToCopy) {
			bytesToCopy = maxBytesToCopy - bytesCopied;
		}
		size = fread(block, 1, (size_t)bytesToCopy, fsrc);
		if (size == 0) {
			break;
		}

		sizeout = fwrite(block, 1, size, fdst);
		if (sizeout != size) {
			fclose(fsrc);
			fclose(fdst);
			return 0;
		}

		bytesCopied += bytesToCopy;
	}

	fclose(fsrc);
	fclose(fdst);
	return 1;
}

int appenddatatoexecutable(void* buffer, size_t bufferSize)
{
	JamZipBufferInfo jamZipBufferInfo;
	uint64_t executableSize = 0;
	char newExecutablePath[1000];
	char executablePath[1000];
	getexecutablepath(executablePath, sizeof(executablePath));

	memcpy(&jamZipBufferInfo.signatureA, ZIPBUFFERHEADER_SIGNATUREA, 8);
	jamZipBufferInfo.startOffset = 0;
	jamZipBufferInfo.size = 0;
	memcpy(&jamZipBufferInfo.signatureB, ZIPBUFFERHEADER_SIGNATUREB, 8);

	{
		FILE *file = NULL;
#if defined(_MSC_VER)
		fopen_s(&file, executablePath, "rb");
#else
		file = fopen(executablePath, "rb");
#endif
		//FILE* file = fopen(executablePath, "rb");
		if (file != NULL)
		{
			JamZipBufferInfo testJamZipBufferInfo;
			fseek(file, -(int)sizeof(JamZipBufferInfo), SEEK_END);
			fread(&testJamZipBufferInfo, sizeof(JamZipBufferInfo), 1, file);
			executableSize = ftell(file);
			fclose(file);

			if (memcmp(&testJamZipBufferInfo.signatureA, ZIPBUFFERHEADER_SIGNATUREA, 8) == 0
					&& memcmp(&testJamZipBufferInfo.signatureB, ZIPBUFFERHEADER_SIGNATUREB, 8) == 0
					&& testJamZipBufferInfo.startOffset + testJamZipBufferInfo.size == executableSize - sizeof(JamZipBufferInfo)
				)
			{
				jamZipBufferInfo.startOffset = testJamZipBufferInfo.startOffset;
				jamZipBufferInfo.size = testJamZipBufferInfo.size;
				executableSize = jamZipBufferInfo.startOffset;
			}
		}
	}

	if (executableSize == 0)
	{
		FILE *file = NULL;
#if defined(_MSC_VER)
		fopen_s(&file, executablePath, "rb");
#else
		file = fopen(executablePath, "rb");
#endif
		if (file != NULL)
		{
			fseek(file, 0, SEEK_END);
			executableSize = ftell(file);
			fclose(file);
		}
	}

	strcpy(newExecutablePath, executablePath);
	strcat(newExecutablePath, ".embed");
	copyfilemaxbytes(newExecutablePath, executablePath, executableSize);

	FILE* file = NULL;
#if defined(_MSC_VER)
	fopen_s(&file, newExecutablePath, "ab");
#else
	file = fopen(newExecutablePath, "ab");
#endif
	jamZipBufferInfo.startOffset = executableSize;
	jamZipBufferInfo.size = bufferSize;
	fwrite(buffer, bufferSize, 1, file);
	fwrite(&jamZipBufferInfo, sizeof(JamZipBufferInfo), 1, file);
	fclose(file);

	printf("embedbuildmodules: Created [%s] with new build modules.\n", newExecutablePath);
	printf("embedbuildmodules: Rename to [%s] to use.\n", executablePath);
	return 0;
}

int embedbuildmodules(const char *rootDirectory)
{
	FILE *fin;
	char cwdbuf[4096];
	char buf[ 1024 ];
	BUFFER pathBuffer;
	size_t pathLength = 0;
	const char* ptr;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	const char* jambuildmodulesFilename = "jambuildmodules.txt";
#else
	const char* jambuildmodulesFilename = "jambuildmodules-nolua.txt";
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */

	mz_zip_archive zip;
	memset(&zip, 0, sizeof(zip));
	mz_bool ret = mz_zip_writer_init_heap(&zip, 0, 512 * 1024);

	buffer_init(&pathBuffer);
	if (rootDirectory == NULL)
	{
		if (getcwd(cwdbuf, sizeof(cwdbuf)))
		{
			rootDirectory = cwdbuf;
		}
	}
	if (rootDirectory != NULL)
	{
		ptr = rootDirectory;
		while (*ptr != 0)
		{
			if (*ptr == '\\')
			{
				buffer_addchar(&pathBuffer, '/');
			}
			else
			{
				buffer_addchar(&pathBuffer, *ptr);
			}
			++ptr;
		}
		if (buffer_pos(&pathBuffer) != 0 && buffer_posptr(&pathBuffer)[-1] != '/')
		{
			buffer_addchar(&pathBuffer, '/');
		}
	}
	pathLength = buffer_pos(&pathBuffer);

	buffer_addstring(&pathBuffer, jambuildmodulesFilename, strlen(jambuildmodulesFilename));
	buffer_addchar(&pathBuffer, 0);
	fin = fopen(buffer_ptr(&pathBuffer), "r");
	if (fin == NULL)
	{
		printf("embedbuildmodules: Unable to access %s.\n", buffer_ptr(&pathBuffer));
		exit(EXITBAD);
		return 0;
	}
	buffer_setpos(&pathBuffer, pathLength);

	while (fgets(buf, sizeof(buf), fin))
	{
		char *p = buf;

		/* Strip leading whitespace. */
		while (*p == ' ' || *p == '\t' || *p == '\n')
			p++;

		/* Drop comments and empty lines. */
		if (*p == '#' || !*p)
			continue;

		unsigned char* srcPtr = (unsigned char*)p;
		buffer_setpos(&pathBuffer, pathLength);
		char* destPtr = buffer_posptr(&pathBuffer);
		while (*srcPtr && *srcPtr != '\n' && *srcPtr != '$')
		{
			if (*srcPtr == '\\')
			{
				buffer_addchar(&pathBuffer, '/');
			}
			else
			{
				buffer_addchar(&pathBuffer, *srcPtr);
			}
			++srcPtr;
			++destPtr;
		}
		if (*srcPtr == '$')
		{
			++srcPtr;
		}
		if (buffer_pos(&pathBuffer) != pathLength && buffer_posptr(&pathBuffer)[-1] != '/')
		{
			buffer_addchar(&pathBuffer, '/');
		}
		size_t pathLength = buffer_pos(&pathBuffer);
		buffer_addchar(&pathBuffer, 0);

		BUFFER wildcardBuf;
		buffer_init(&wildcardBuf);
		buffer_addstring(&wildcardBuf, buffer_ptr(&pathBuffer), pathLength);

		while (*srcPtr && *srcPtr != '\n' && *srcPtr != '$')
		{
			if (*srcPtr == '\\')
			{
				buffer_addchar(&wildcardBuf, '/');
			}
			else
			{
				buffer_addchar(&wildcardBuf, *srcPtr);
			}
			++srcPtr;
		}
		buffer_addchar(&wildcardBuf, 0);

		if (*srcPtr == '$')
		{
			++srcPtr;
		}

		unsigned char* entryFilename = srcPtr;
		while (*srcPtr && *srcPtr != '\n')
		{
			++srcPtr;
		}
		*srcPtr = 0;
		if (*entryFilename == 0)
		{
			entryFilename = NULL;
		}

		//printf("Searching wildcard %s\n", wildcard);
		fileglob* glob = fileglob_Create(buffer_ptr(&wildcardBuf));
		while (fileglob_Next(glob))
		{
			const char* filename = fileglob_FileName(glob);
			//printf("%s\n", filename);
			mz_zip_writer_add_file(&zip, entryFilename != NULL ? (const char*)entryFilename : filename + pathLength, filename, NULL, 0, MZ_BEST_COMPRESSION);
		}
	}
	fclose(fin);

	void* buffer;
	size_t bufferSize;
	mz_zip_writer_finalize_heap_archive(&zip, &buffer, &bufferSize);
	appenddatatoexecutable(buffer, bufferSize);

	zip.m_pFree(zip.m_pAlloc_opaque, buffer);

	mz_zip_writer_end(&zip);
	return 0;
}


int extractbuildmodules(const char *rootDirectory)
{
	char cwdbuf[4096];
	BUFFER pathBuffer;
	size_t pathLength = 0;
	int index;
	const char* ptr;

	mz_zip_archive *archive = zip_attemptopen();
	if (archive == NULL)
	{
		printf("extractbuildmodules: No embedded archive to extract.\n");
		exit(EXITBAD);
	}

	buffer_init(&pathBuffer);
	if (rootDirectory == NULL)
	{
		if (getcwd(cwdbuf, sizeof(cwdbuf)))
		{
			rootDirectory = cwdbuf;
		}
	}
	if (rootDirectory != NULL)
	{
		ptr = rootDirectory;
		while (*ptr != 0)
		{
			if (*ptr == '\\')
			{
				buffer_addchar(&pathBuffer, '/');
			}
			else
			{
				buffer_addchar(&pathBuffer, *ptr);
			}
			++ptr;
		}
		if (buffer_pos(&pathBuffer) != 0 && buffer_posptr(&pathBuffer)[-1] != '/')
		{
			buffer_addchar(&pathBuffer, '/');
		}
	}
	pathLength = buffer_pos(&pathBuffer);
	buffer_addchar(&pathBuffer, 0);

	printf("extractbuildmodules: Extracting files to [%s].\n", buffer_ptr(&pathBuffer));
	for (index = 0; index < (int)mz_zip_reader_get_num_files(archive); ++index)
	{
		mz_zip_archive_file_stat fileEntry;
		if (mz_zip_reader_file_stat(archive, index, &fileEntry))
		{
			if (!fileEntry.m_is_directory)
			{
				time_t fileTime;

				buffer_setpos(&pathBuffer, pathLength);
				buffer_addstring(&pathBuffer, fileEntry.m_filename, strlen(fileEntry.m_filename));
				buffer_addchar(&pathBuffer, 0);

				if (file_time(buffer_ptr(&pathBuffer), &fileTime) == 0)
				{
					printf("extractbuildmodules: Refusing to overwrite [%s].\n", buffer_ptr(&pathBuffer));
					exit(EXITBAD);
				}
			}
		}
	}

	for (index = 0; index < (int)mz_zip_reader_get_num_files(archive); ++index)
	{
		mz_zip_archive_file_stat fileEntry;
		if (mz_zip_reader_file_stat(archive, index, &fileEntry))
		{
			if (!fileEntry.m_is_directory)
			{
				buffer_setpos(&pathBuffer, pathLength);
				buffer_addstring(&pathBuffer, fileEntry.m_filename, strlen(fileEntry.m_filename));
				buffer_addchar(&pathBuffer, 0);

				file_mkdir(buffer_ptr(&pathBuffer));
				mz_zip_reader_extract_to_file(archive, index, buffer_ptr(&pathBuffer), 0);
			}
		}
	}
	return 0;
}

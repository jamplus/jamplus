/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * execunix.c - execute a shell script on UNIX/WinNT/OS2/AmigaOS
 *
 * If $(JAMSHELL) is defined, uses that to formulate execvp()/spawnvp().
 * The default is:
 *
 *	/bin/sh -c %		[ on UNIX/AmigaOS ]
 *	cmd.exe /c %		[ on OS2/WinNT ]
 *
 * Each word must be an individual element in a jam variable value.
 *
 * In $(JAMSHELL), % expands to the command string and ! expands to
 * the slot number (starting at 1) for multiprocess (-j) invocations.
 * If $(JAMSHELL) doesn't include a %, it is tacked on as the last
 * argument.
 *
 * Don't just set JAMSHELL to /bin/sh or cmd.exe - it won't work!
 *
 * External routines:
 *	execcmd() - launch an async command execution
 * 	execwait() - wait and drive at most one execution completion
 *
 * Internal routines:
 *	onintr() - bump intr to note command interruption
 *
 * 04/08/94 (seiwald) - Coherent/386 support added.
 * 05/04/94 (seiwald) - async multiprocess interface
 * 01/22/95 (seiwald) - $(JAMSHELL) support
 * 06/02/97 (gsar)    - full async multiprocess support for Win32
 * 01/20/00 (seiwald) - Upgraded from K&R to ANSI C
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/27/02 (seiwald) - grist .bat file with pid for system uniqueness
 */

# include "jam.h"
# include "lists.h"
# include "execcmd.h"
# include <errno.h>

# include "parse.h"
# ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
# include "luasupport.h"
# endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */
#include "variable.h"

# ifdef USE_EXECUNIX

# ifdef OS_OS2
# define USE_EXECNT
# include <process.h>
# endif

# ifdef OS_NT
# define USE_EXECNT
# include <process.h>
# define WIN32_LEAN_AND_MEAN
# include <windows.h>		/* do the ugly deed */
# include <io.h>
# else
# include <unistd.h>
# include <sys/types.h>
# include <sys/wait.h>
# endif

static int my_wait( int *status );

#include <stdlib.h>
#include <errno.h>

#ifdef OPT_INTERRUPT_FIX
int intr = 0;
#else
static int intr = 0;
#endif
static int cmdsrunning = 0;
static void (*istat)( int );

static struct
{
	intptr_t pid; /* on win32, a real process handle */
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	int lua;
#endif
#ifdef OPT_SERIAL_OUTPUT_EXT
	void	(*func)( const char* outputname, void *closure, int status );
#else
    	void	(*func)( void *closure, int status );
#endif
	void 	*closure;

/* # ifdef USE_EXECNT *//* CWM - need on unix too */
	char	*tempfile;
/* # endif *//* CWM */

# ifdef OPT_SERIAL_OUTPUT_EXT
	char	*outputFilename;
	int	outputFilenameUsed;
# endif

} cmdtab[ MAXJOBS ] = {{0}};

/*
 * onintr() - bump intr to note command interruption
 */

void
onintr( int disp )
{
	intr++;
	printf( "*** interrupted\n" );
}

#ifdef OPT_SERIAL_OUTPUT_EXT
void
exec_init()
{
	char 	*tempdir;
	int		i;

# ifdef USE_EXECNT
	tempdir = "\\temp";
# else
	tempdir = "/tmp";
# endif

	if( getenv( "TMPDIR" ) )
		tempdir = getenv( "TMPDIR" );
	else if( getenv( "TEMP" ) )
		tempdir = getenv( "TEMP" );
	else if( getenv( "TMP" ) )
		tempdir = getenv( "TMP" );

	{
		LIST *jobsList = var_get( "JAM_NUM_JOBS" );
		if ( list_first(jobsList) )
		{
			int jobs = atoi(list_value(list_first(jobsList)));
			if ( jobs > 0 )
				globs.jobs = jobs;
		}
	}

	for( i = 0; i < globs.jobs; ++i )
	{
		cmdtab[ i ].outputFilename = malloc( strlen( tempdir ) + 32 );
		sprintf( cmdtab[ i ].outputFilename, "%s%cjam%dout%d",
			tempdir, PATH_DELIM, getpid(), i );
	}
}

void
exec_done()
{
    int		i;

    for( i = 0; i < globs.jobs; ++i)
    {
		if ( cmdtab[ i ].outputFilenameUsed )
			unlink( cmdtab[ i ].outputFilename );

/* # ifdef USE_EXECNT *//* CWM - need on unix too */
		if ( cmdtab[ i ].tempfile )
			unlink( cmdtab[ i ].tempfile );
/* # endif *//* CWM */
    }
}
#endif

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT

/*
 * execlua() - launch an async command execution
 */

void
execlua(
	char *string,
#ifdef OPT_SERIAL_OUTPUT_EXT
	void (*func)( const char* outputname, void *closure, int status ),
#else
	void (*func)( void *closure, int status ),
#endif
	void *closure )
{
	int pid;
	int slot;

	/* Find a slot in the running commands table for this one. */

	for( slot = 0; slot < MAXJOBS; slot++ )
		if( !cmdtab[ slot ].pid )
			break;

	if( slot == MAXJOBS )
	{
		printf( "no slots for child!\n" );
		exit( EXITBAD );
	}

# ifdef OPT_JOB_SLOT_EXT
	/* Now that we know the slot we are going to run in, replace any */
	/* occurrences of '!!' with the slot number.  */
	{
		char *c = strchr( string, '!' );

		while( c )
		{
			if( c[1] == '!' )
			{
				char num[3];

				sprintf( num, "%02d", slot );
				c[0] = num[0];
				c[1] = num[1];

				c += 2;
			}
			else
				++c;

			c = strchr( c, '!' );
		}
	}
# endif

	/* Catch interrupts whenever commands are running. */

	if( !cmdsrunning++ )
		istat = signal( SIGINT, onintr );

	/* Start the command */

	pid = luahelper_taskadd( string );
	if( pid < 0 )
	{
		printf( "jam: Unable to add a new task\n" );
		exit( EXITBAD );
	}

	/* Save the operation for execwait() to find. */

	cmdtab[ slot ].pid = pid;
	cmdtab[ slot ].func = func;
	cmdtab[ slot ].closure = closure;
	cmdtab[ slot ].lua = 1;

	/* Wait until we're under the limit of concurrent commands. */
	/* Don't trust globs.jobs alone. */

	while( cmdsrunning >= MAXJOBS || cmdsrunning >= globs.jobs )
		if( !execwait() )
			break;
}

#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */


/*
 * execcmd() - launch an async command execution
 */

void
execcmd(
	const char *string,
#ifdef OPT_SERIAL_OUTPUT_EXT
	void (*func)( const char* outputname, void *closure, int status ),
#else
	void (*func)( void *closure, int status ),
#endif
	void *closure,
	LIST *shell,
#ifdef OPT_SERIAL_OUTPUT_EXT
    int serialOutput
#endif
    )
{
	intptr_t pid;
	int slot;
	const char *argv[ MAXARGC + 1 ];	/* +1 for NULL */
# ifdef USE_EXECNT
	int quote = 0;
#endif

# ifdef USE_EXECNT
	char *p;
# endif

	/* Find a slot in the running commands table for this one. */

	for( slot = 0; slot < MAXJOBS; slot++ )
		if( !cmdtab[ slot ].pid )
			break;

	if( slot == MAXJOBS )
	{
		printf( "no slots for child!\n" );
		exit( EXITBAD );
	}

# ifdef OPT_JOB_SLOT_EXT
	/* Now that we know the slot we are going to run in, replace any */
	/* occurrences of '!!' with the slot number.  */
	{
		char *c = strchr( string, '!' );

		while( c )
		{
			if( c[1] == '!' )
			{
				char num[3];

				sprintf( num, "%02d", slot );
				c[0] = num[0];
				c[1] = num[1];

				c += 2;
			}
			else
				++c;

			c = strchr( c, '!' );
		}
	}
# endif

/* # ifdef USE_EXECNT *//* CWM */
	if( !cmdtab[ slot ].tempfile )
	{
		char *tempdir;

		if( !( tempdir = getenv( "TMPDIR" ) ) &&
			!( tempdir = getenv( "TEMP" ) ) &&
			!( tempdir = getenv( "TMP" ) ) )
# ifdef USE_EXECNT /* CWM */
			tempdir = "\\temp";
# else
		    tempdir = "/tmp";
# endif

		/* +32 is room for \jamXXXXXcmdSS.bat (at least) */

		cmdtab[ slot ].tempfile = malloc( strlen( tempdir ) + 32 );

		sprintf( cmdtab[ slot ].tempfile, "%s%cjam%dcmd%d.bat",
			tempdir, PATH_DELIM, getpid(), slot );
	}

# ifdef USE_EXECNT
	/* Trim leading, ending white space */

	while( isspace( *string ) )
		++string;

	p = strchr( string, '\n' );

	while( p && isspace( *p ) )
		++p;

	if ( !p  ||  !*p )
	{
		const char* p2 = string;
		while ( *p2 != '"'  &&  *p2 != 0 )
			p2++;
		if ( *p2 == '"' )
			quote = 1;
	}


	/* If multi line, or too long, or JAMSHELL is set, write to bat file. */
	/* Otherwise, exec directly. */
	/* Frankly, if it is a single long line I don't think the */
	/* command interpreter will do any better -- it will fail. */

	if( p && *p || strlen( string ) > MAXLINE || list_first(shell) || quote )
# else
	if( list_first(shell) )
# endif
	{
		FILE *f;

		/* Write command to bat file. */

		f = fopen( cmdtab[ slot ].tempfile, "w" );
#ifdef OPT_FIX_TEMPFILE_CRASH
		if (!f) {
			perror( "fopen" );
			printf( "could not open tempfile %s, is TEMP set correctly?\n",
				cmdtab[ slot ].tempfile );
			exit( EXITBAD );
		}
#endif
		fputs( string, f );
		fclose( f );

		string = cmdtab[ slot ].tempfile;
	}

/* # endif *//* CWM */

	/* Forumulate argv */
	/* If shell was defined, be prepared for % and ! subs. */
	/* Otherwise, use stock /bin/sh (on unix) or cmd.exe (on NT). */

	if(list_first(shell))
	{
		int i;
		char jobno[4];
		int gotpercent = 0;
		LISTITEM* item = list_first(shell);

		sprintf( jobno, "%d", slot + 1 );

		for( i = 0; item && i < MAXARGC; i++, item = list_next( item ) )
		{
			switch( list_value(item)[0] )
			{
			case '%':	argv[i] = string; gotpercent++; break;
			case '!':	argv[i] = jobno; break;
			default:	argv[i] = list_value(item);
			}
			if( DEBUG_EXECCMD )
				printf( "argv[%d] = '%s'\n", i, argv[i] );
		}

		if( !gotpercent )
			argv[i++] = string;

		argv[i] = 0;
	}
	else
	{
# ifdef USE_EXECNT
		argv[0] = "cmd.exe";
		argv[1] = "/Q/C";		/* anything more is non-portable */
# else
		argv[0] = "/bin/sh";
		argv[1] = "-c";
# endif
		argv[2] = string;
		argv[3] = 0;
	}

	/* Catch interrupts whenever commands are running. */

	if( !cmdsrunning++ )
		istat = signal( SIGINT, onintr );

	/* Start the command */

# ifdef USE_EXECNT
#ifdef OPT_SERIAL_OUTPUT_EXT
	if ( serialOutput )
	{
		int	out, err, fd, bad_spawn = 0, spawn_err = -1;

		out = _dup (1);
		err = _dup (2);
		cmdtab[ slot ].outputFilenameUsed = 1;
		fd = open( cmdtab[ slot ].outputFilename,
			O_WRONLY | O_TRUNC | O_CREAT, 0644 );
		_dup2 (fd, 1);
		_dup2 (fd, 2);
		close (fd);

		if( ( pid = spawnvp( P_NOWAIT, argv[0], argv ) ) == -1 )
		{
			bad_spawn = 1;
			spawn_err = errno;
		}

		_dup2 (out, 1);
		_dup2 (err, 2);
		close (out);
		close (err);

		if( bad_spawn )
		{
			errno = spawn_err;
			printf( "Jam: Error invoking spawn() for %s\n", argv[0] );
			perror( "spawn" );
			exit( EXITBAD );
		}
	}
	else

#endif
	{

		if( ( pid = spawnvp( P_NOWAIT, argv[0], argv ) ) == -1 )
		{
			perror( "spawn" );
			exit( EXITBAD );
		}

	}
# else
# ifdef NO_VFORK
	if ((pid = fork()) == 0)
	{
# ifdef OPT_SERIAL_OUTPUT_EXT
		int fd;

		close( 1 );
		close( 2 );
		cmdtab[ slot ].outputFilenameUsed = 1;
		fd = open( cmdtab[ slot ].outputFilename,
					O_WRONLY | O_TRUNC | O_CREAT, 0644 );
		dup( fd );
		dup( fd );
# endif
		execvp( argv[0], argv );
		_exit(127);
	}
# else
	if ((pid = vfork()) == 0)
	{
# ifdef OPT_SERIAL_OUTPUT_EXT
		if ( serialOutput )
		{
			int fd;

			close( 1 );
			close( 2 );
			cmdtab[ slot ].outputFilenameUsed = 1;
			fd = open( cmdtab[ slot ].outputFilename,
				O_WRONLY | O_TRUNC | O_CREAT, 0644 );
			dup( fd );
			dup( fd );
		}
# endif
		execvp( argv[0], argv );
		exit(127);
	}
# endif

	if( pid == -1 )
	{
	    perror( "vfork" );
	    exit( EXITBAD );
	}
# endif
	/* Save the operation for execwait() to find. */

	cmdtab[ slot ].pid = pid;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	cmdtab[ slot ].lua = 0;
#endif
	cmdtab[ slot ].func = func;
	cmdtab[ slot ].closure = closure;

	/* Wait until we're under the limit of concurrent commands. */
	/* Don't trust globs.jobs alone. */

	while( cmdsrunning >= MAXJOBS || cmdsrunning >= globs.jobs )
		if( !execwait() )
			break;
}

/*
 * execwait() - wait and drive at most one execution completion
 */

int
execwait()
{
	int i;
	int status, w;
	int rstat;

	/* Handle naive make1() which doesn't know if cmds are running. */

	if( !cmdsrunning )
		return 0;

	/* Pick up process pid and status */

	while( ( w = my_wait( &status ) ) == -1 && errno == EINTR )
		;

	if( w == -1 )
	{
		printf( "child process(es) lost!\n" );
		perror("wait");
		exit( EXITBAD );
	}

	/* Find the process in the cmdtab. */

	for( i = 0; i < MAXJOBS; i++ )
		if( w == cmdtab[ i ].pid )
			break;

	if( i == MAXJOBS )
	{
		printf( "waif child found!\n" );
		exit( EXITBAD );
	}

# ifdef USE_EXECNT
	/* Clear the temp file */

	unlink( cmdtab[ i ].tempfile );
# endif

	/* Drive the completion */

	if( !--cmdsrunning )
		signal( SIGINT, istat );

	if( intr )
		rstat = EXEC_CMD_INTR;
	else if( w == -1 || status != 0 )
		rstat = EXEC_CMD_FAIL;
	else
		rstat = EXEC_CMD_OK;

	cmdtab[ i ].pid = 0;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	cmdtab[ i ].lua = 0;
#endif

	if (cmdtab[ i ].func)
#ifdef OPT_SERIAL_OUTPUT_EXT
		(*cmdtab[ i ].func)(cmdtab[ i ].outputFilename,
		cmdtab[ i ].closure, rstat);
#else
		(*cmdtab[ i ].func)( cmdtab[ i ].closure, rstat );
#endif

	return 1;
}

static int
my_wait( int *status )
{
	int i, num_active = 0;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	int num_lua_active = 0;
#endif
#ifdef USE_EXECNT
	DWORD exitcode, waitcode;
	static HANDLE *active_handles = 0;

	if (!active_handles)
		active_handles = (HANDLE *)malloc(globs.jobs * sizeof(HANDLE) );
#endif

	/* first see if any non-waited-for processes are dead,
	* and return if so.
	*/
	for ( i = 0; i < globs.jobs; i++ ) {
		if ( cmdtab[i].pid ) {
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
			if ( cmdtab[i].lua ) {
				int ret = luahelper_taskisrunning( cmdtab[i].pid, status );
				if ( ret == 0 ) {
					return cmdtab[i].pid;
				}
				++num_lua_active;
				continue;
			}
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */
#ifdef USE_EXECNT
			if ( GetExitCodeProcess((HANDLE)cmdtab[i].pid, &exitcode) ) {
				if ( exitcode == STILL_ACTIVE )
					active_handles[num_active++] = (HANDLE)cmdtab[i].pid;
				else {
					CloseHandle((HANDLE)cmdtab[i].pid);
					*status = (int)((exitcode & 0xff) << 8);
					return cmdtab[i].pid;
				}
			}
			else
				goto FAILED;
#else
			if ( waitpid( cmdtab[i].pid, status, WNOHANG ) != 0 ) {
				return cmdtab[i].pid;
			} else {
				++num_active;
			}
#endif
		}
	}

	/* if a child exists, wait for it to die */
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	if ( !num_active && !num_lua_active ) {
#else
	if ( !num_active ) {
#endif
		errno = ECHILD;
		return -1;
	}

	if ( intr ) {
		for ( i = 0; i < globs.jobs; i++ ) {
			if ( cmdtab[i].pid ) {
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
				if ( cmdtab[i].lua ) {
					luahelper_taskcancel( cmdtab[i].pid );
					continue;
				}
#endif
#ifdef USE_EXECNT
				TerminateProcess( (HANDLE)cmdtab[i].pid, (UINT)-1 );
#else
				kill( cmdtab[i].pid, SIGKILL );
#endif
			}
		}
	}

#ifdef USE_EXECNT
	waitcode = WAIT_TIMEOUT;
	if ( num_active > 0 ) {
		waitcode = WaitForMultipleObjects( num_active,
				active_handles,
				FALSE,
				1000 );
	}
	if ( waitcode != WAIT_FAILED  &&  waitcode == WAIT_TIMEOUT ) {
		/* try the Lua ones */
		for ( i = 0; i < globs.jobs; i++ ) {
			if ( cmdtab[i].pid ) {
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
				if ( cmdtab[i].lua ) {
					int ret = luahelper_taskisrunning( cmdtab[i].pid, status );
					if ( ret == 0 ) {
						return cmdtab[i].pid;
					}
				}
#endif
			}
		}
	}
	if ( waitcode == WAIT_TIMEOUT ) {
		errno = EINTR;
		return -1;
	}
	else if ( waitcode != WAIT_FAILED ) {
		if ( waitcode >= WAIT_ABANDONED_0
			&& waitcode < WAIT_ABANDONED_0 + num_active )
			i = waitcode - WAIT_ABANDONED_0;
		else
			i = waitcode - WAIT_OBJECT_0;
		if ( GetExitCodeProcess(active_handles[i], &exitcode) ) {
			CloseHandle(active_handles[i]);
			*status = (int)((exitcode & 0xff) << 8);
			return (int)active_handles[i];
		}
	}
#else
	for ( i = 0; i < globs.jobs; i++ ) {
		if ( cmdtab[i].pid ) {
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
			if ( cmdtab[i].lua ) {
				if ( !luahelper_taskisrunning( cmdtab[i].pid, status ) ) {
					*status = 0;
					return cmdtab[i].pid;
				}
			} else
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */
				if ( waitpid( cmdtab[i].pid, status, WNOHANG ) != 0 ) {
					return cmdtab[i].pid;
				}
		}
	}

	usleep( 1000 );

	errno = EINTR;
	return -1;
#endif

FAILED:
#ifdef USE_EXECNT
	errno = GetLastError();
#endif
	return -1;

}

# endif /* USE_EXECUNIX */

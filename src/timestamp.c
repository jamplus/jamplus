/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * timestamp.c - get the timestamp of a file or archive member
 *
 * 09/22/00 (seiwald) - downshift names on OS2, too
 * 01/08/01 (seiwald) - closure param for file_dirscan/file_archscan
 * 11/04/02 (seiwald) - const-ing for string literals
 */

# include "jam.h"
# include "hash.h"
# include "filesys.h"
# include "pathsys.h"
# include "timestamp.h"
# include "newstr.h"

/*
 * BINDING - all known files
 */

typedef struct _binding BINDING;

struct _binding {
	const char	*name;
	short		flags;

# define BIND_SCANNED	0x01	/* if directory or arch, has been scanned */

	short		progress;

# define BIND_INIT	0	/* never seen */
# define BIND_NOENTRY	1	/* timestamp requested but file never found */
# define BIND_SPOTTED	2	/* file found but not timed yet */
# define BIND_MISSING	3	/* file found but can't get timestamp */
# define BIND_FOUND	4	/* file found and time stamped */

	time_t		time;	/* update time - 0 if not exist */
} ;

static struct hash *bindhash = 0;
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
static void time_enter( void *, const char *, int , time_t, int  );
#else
static void time_enter( void *, const char *, int , time_t  );
#endif

static const char *time_progress[] =
{
	"INIT",
	"NOENTRY",
	"SPOTTED",
	"MISSING",
	"FOUND"
} ;


/*
 * timestamp() - return timestamp on a file, if present
 */

void
timestamp( 
	const char	*target,
	time_t	*time,
	int      force )
{
	PATHNAME f1, f2;
	BINDING	binding, *b = &binding;
	char buf[ MAXJPATH ];

# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p = path;

	do *p++ = tolower( *target );
	while( *target++ );

	target = path;
# endif 

	if( !bindhash )
	    bindhash = hashinit( sizeof( BINDING ), "bindings" );

	/* Quick path - is it there? */

	b->name = target;
	b->time = b->flags = 0;
	b->progress = BIND_INIT;

	if( hashenter( bindhash, (HASHDATA **)&b ) )
	    b->name = newstr( target );		/* never freed */

	if ( force )
	{
		b->progress = BIND_INIT;
		b->time = b->flags = 0;
	}

	if( b->progress != BIND_INIT )
	    goto afterscanning;

	b->progress = BIND_NOENTRY;

	/* Not found - have to scan for it */

	path_parse( target, &f1 );

	/* Scan directory if not already done so */

	{
	    BINDING binding, *b = &binding;

	    f2 = f1;
	    f2.f_grist.len = 0;
	    path_parent( &f2 );
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f2, buf, 0, 1 );
#else
	    path_build( &f2, buf, 0 );
#endif

	    b->name = buf;
	    b->time = b->flags = 0;
	    b->progress = BIND_INIT;

#if !defined(OPT_TIMESTAMP_IMMEDIATE_PARENT_CHECK_EXT)  &&  !defined(OPT_TIMESTAMP_EXTENDED_PARENT_CHECK_EXT)
	    if( hashenter( bindhash, (HASHDATA **)&b ) )
		b->name = newstr( buf );	/* never freed */

		if ( force )
		{
			b->progress = BIND_INIT;
			b->time = b->flags = 0;
		}

	    if( !( b->flags & BIND_SCANNED ) )
	    {
		file_dirscan( buf, time_enter, bindhash );
		b->flags |= BIND_SCANNED;
	    }
#endif

#ifdef OPT_TIMESTAMP_IMMEDIATE_PARENT_CHECK_EXT
		if( hashenter( bindhash, (HASHDATA **)&b ) )
			b->name = newstr( buf );	/* never freed */

		if ( force )
		{
			b->progress = BIND_INIT;
			b->time = b->flags = 0;
		}

		if( !( b->flags & BIND_SCANNED ) )
		{
			/* verify the need to scan it by checking if the parent directory has been read */
			BINDING	binding2, *b2 = &binding2;

			if ( buf[0]  &&  buf[0] != '.'  &&  buf[1] != '.' )
			{
				int absolute = 0;
				char buf2[ MAXJPATH ];
				path_parse( buf, &f2 );
				f2.f_grist.len = 0;
				path_parent( &f2 );
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
				path_build( &f2, buf2, 0, 1 );
#else
				path_build( &f2, buf2, 0 );
#endif

				b2->name = buf2;
				b2->flags = 0;

#ifdef OS_NT
				absolute =
					( ( ( buf[0] >= 'a'  &&  buf[0] <= 'z' )  ||  ( buf[0] >= 'A'  &&  buf[0] <= 'Z' ) )  &&
					buf[1] == ':' )  ||  ( buf[0] == '/'  ||  buf[0] == '\\' );
#else
				absolute = buf[0] == '/';
#endif

				if( ( buf2[0]  ||  !absolute )  &&  hashcheck( bindhash, (HASHDATA **)&b2 ) )
				{
					if ( !( b2->flags & BIND_SCANNED )  ||  b->progress == BIND_FOUND  ||  b->progress == BIND_SPOTTED )
					{
						file_dirscan( buf, time_enter, bindhash );
					}
					else
					{
						int hi = 5;  (void)hi;
					}
				}
				else
				{
					file_dirscan( buf, time_enter, bindhash );
				}
			}
			else
			{
				file_dirscan( buf, time_enter, bindhash );
			}

			b->flags |= BIND_SCANNED;
		}
#endif

#ifdef OPT_TIMESTAMP_EXTENDED_PARENT_CHECK_EXT
		{
			/* See if the directory has already been entered into the hash table. */
			int found = hashcheck( bindhash, (HASHDATA **)&b );

			if ( force )
			{
				b->progress = BIND_INIT;
				b->time = b->flags = 0;
			}

			/* If it wasn't there or hasn't been scanned yet... */
			if( !found  ||  !( b->flags & BIND_SCANNED ) )
			{
				/* Verify the need to scan it by checking if the parent directory has been read. */
				BINDING	binding2, *b2 = &binding2;

				/* There is no point in looking for a parent for an empty directory (the current */
				/* working directory or a ".." directory.  Neither have a parent. */
				if ( buf[0]  &&  buf[0] != '.'  &&  buf[1] != '.' )
				{
					char* ptr = buf + strlen( buf ) - 1;
					char* prevPtr = ptr + 1;
					char prevCh = 0;
					char prevPtrCh = 0;
					int done = 0;
					int possible = 1;

					/* We need to know if this is an absolute path.  If it is absolute, then the */
					/* topmost parent is different than if it is relative. */
#ifdef OS_NT
					int absolute =
						( ( ( buf[0] >= 'a'  &&  buf[0] <= 'z' )  ||  ( buf[0] >= 'A'  &&  buf[0] <= 'Z' ) )  &&
						buf[1] == ':' )  ||  ( buf[0] == '/'  ||  buf[0] == '\\' );
#else
					int absolute = buf[0] == '/';
#endif

					/* Go until we've reached the topmost parent directory. */
					while ( !done )
					{
						/* Search for the previous directory */
						while ( ptr > buf )
						{
							if ( *ptr == '/' )
								break;
							ptr--;
						}

						/* When we reach the beginning, we are done at the end of this pass. */
						if ( ptr == buf )
						{
							done = 1;

							/* Because we put back some saved off characters when we're done, */
							/* handle the absolute path case. */
							if ( absolute )
								ptr = prevPtr;
						}

						/* Save off the characters for the parent directory and the current directory. */
						prevCh = *ptr;
						*ptr = 0;
						prevPtrCh = *prevPtr;
						*prevPtr = 0;

						/* Look up the parent directory. */
						b2 = &binding2;
						b2->name = buf;

						if( hashcheck( bindhash, (HASHDATA **)&b2 ) )
						{
							/* The parent directory is in our hash table.  Compare the subdirectory */
							/* to see if there is even the remote possibility of the file being on the disk. */

							/* If the parent directory has been scanned, we can check to see if the */
							/* child directory was in the list. */
							if ( !( b2->flags & BIND_SCANNED ) )
							{
								file_dirscan( buf, time_enter, bindhash );
								b2->flags |= BIND_SCANNED;
							}
							if ( b2->flags & BIND_SCANNED )
							{
								*prevPtr = 0;
								*ptr = prevCh;

								/* Look up the child directory. */
								b2 = &binding2;
								b2->name = buf;

								if( !hashcheck( bindhash, (HASHDATA **)&b2 ) )
								{
									/* The child directory was not part of the scanned directory, */
									/* so there isn't a point in proceeding with the directory scan */
									/* for the target that was passed in. */
									possible = 0;
								}

								/* Restore the saved off characters. */
								*ptr = prevCh;
								if ( ptr != prevPtr )
									*prevPtr = prevPtrCh;
								break;	/* Break out of the loop. */
							}
						}

						/* Restore the saved off characters. */
						*ptr = prevCh;
						if ( ptr != prevPtr )
							*prevPtr = prevPtrCh;
						prevPtr = ptr;
						--ptr;
					}

					/* Prepare to enter the requested directory into the hash table. */
					b2 = &binding2;
					b2->name = buf;

					if( !found  &&  hashenter( bindhash, (HASHDATA **)&b ) )
						b->name = newstr( buf );	/* never freed */

					/* Is it even possible the requested target directory exists on disk? */
					/* We calculated this above. */
					if( possible )
					{
						if( ( buf[0]  ||  !absolute )  &&  hashcheck( bindhash, (HASHDATA **)&b2 ) )
						{
							if ( !( b2->flags & BIND_SCANNED )  ||  b->progress == BIND_FOUND )
							{
								file_dirscan( buf, time_enter, bindhash );
							}
						}
						else
						{
							file_dirscan( buf, time_enter, bindhash );
						}
					}
				}
				else
				{
					/* We got here because either the current working directory or .. directory */
					/* needs to be scanned. */
					if ( hashenter( bindhash, (HASHDATA **)&b ) )
						b->name = newstr( buf );	/* never freed */
					file_dirscan( buf, time_enter, bindhash );
				}

				/* Mark the directory as now having been scanned. */
				b->flags |= BIND_SCANNED;
			}
		}
#endif
	}

	/* Scan archive if not already done so */

	if( f1.f_member.len )
	{
	    BINDING binding, *b = &binding;

	    f2 = f1;
	    f2.f_grist.len = 0;
	    f2.f_member.len = 0;
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f2, buf, 0, 1 );
#else
	    path_build( &f2, buf, 0 );
#endif

	    b->name = buf;
	    b->time = b->flags = 0;
	    b->progress = BIND_INIT;

	    if( hashenter( bindhash, (HASHDATA **)&b ) )
		b->name = newstr( buf );	/* never freed */

	    if( !( b->flags & BIND_SCANNED ) )
	    {
		file_archscan( buf, time_enter, bindhash );
		b->flags |= BIND_SCANNED;
	    }
	}

    afterscanning:

	if( b->progress == BIND_SPOTTED )
	{
	    if( file_time( b->name, &b->time ) < 0 )
		b->progress = BIND_MISSING;
	    else
		b->progress = BIND_FOUND;
	}

	*time = b->progress == BIND_FOUND ? b->time : 0;
}

static void
time_enter( 
	void		*closure,
	const char	*target,
	int		found,
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	time_t		time,
	int		dir )
#else
	time_t		time )
#endif
{
	BINDING	binding, *b = &binding;
	struct hash *bindhash = (struct hash *)closure;

# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p = path;

	do *p++ = tolower( *target );
	while( *target++ );

	target = path;
# endif

	b->name = target;
	b->flags = 0;

	if( hashenter( bindhash, (HASHDATA **)&b ) )
	    b->name = newstr( target );		/* never freed */

	b->time = time;
	b->progress = found ? BIND_FOUND : BIND_SPOTTED;

	if( DEBUG_BINDSCAN )
	    printf( "time ( %s ) : %s\n", target, time_progress[b->progress] );
}

/*
 * donestamps() - free timestamp tables
 */

void
donestamps()
{
	hashdone( bindhash );
#ifdef OPT_MULTIPASS_EXT
	bindhash = NULL;
#endif
}

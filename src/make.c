/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * make.c - bring a target up to date, once rules are in place
 *
 * This modules controls the execution of rules to bring a target and
 * its dependencies up to date.  It is invoked after the targets, rules,
 * et. al. described in rules.h are created by the interpreting of the
 * jam files.
 *
 * This file contains the main make() entry point and the first pass
 * make0().  The second pass, make1(), which actually does the command
 * execution, is in make1.c.
 *
 * External routines:
 *	make() - make a target, given its name
 *
 * Internal routines:
 * 	make0() - bind and scan everything to make a TARGET
 * 	make0sort() - reorder TARGETS chain by their time (newest to oldest)
 *
 * 12/26/93 (seiwald) - allow NOTIME targets to be expanded via $(<), $(>)
 * 01/04/94 (seiwald) - print all targets, bounded, when tracing commands
 * 04/08/94 (seiwald) - progress report now reflects only targets with actions
 * 04/11/94 (seiwald) - Combined deps & headers into deps[2] in TARGET.
 * 12/20/94 (seiwald) - NOTIME renamed NOTFILE.
 * 12/20/94 (seiwald) - make0() headers after determining fate of target, so
 *			that headers aren't seen as dependents on themselves.
 * 01/19/95 (seiwald) - distinguish between CANTFIND/CANTMAKE targets.
 * 02/02/95 (seiwald) - propagate leaf source time for new LEAVES rule.
 * 02/14/95 (seiwald) - NOUPDATE rule means don't update existing target.
 * 08/22/95 (seiwald) - NOUPDATE targets immune to anyhow (-a) flag.
 * 09/06/00 (seiwald) - NOCARE affects targets with sources/actions.
 * 03/02/01 (seiwald) - reverse NOCARE change.
 * 03/14/02 (seiwald) - TEMPORARY targets no longer take on parents age
 * 03/16/02 (seiwald) - support for -g (reorder builds by source time)
 * 07/17/02 (seiwald) - TEMPORARY sources for headers now get built
 * 09/19/02 (seiwald) - new -d displays
 * 09/23/02 (seiwald) - suppress "...using temp..." in default output
 * 09/28/02 (seiwald) - make0() takes parent pointer; new -dc display
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/03/02 (seiwald) - fix odd includes support by grafting them onto depends
 * 12/17/02 (seiwald) - new copysettings() to protect target-specific vars
 * 01/03/03 (seiwald) - T_FATE_NEWER once again gets set with missing parent
 * 01/14/03 (seiwald) - fix includes fix with new internal includes TARGET
 * 04/04/03 (seiwald) - fix INTERNAL node binding to avoid T_BIND_PARENTS
 * 04/14/06 (kaib) - fix targets to show in 'updated' when their includes are newer
 */

# include "jam.h"

#ifdef OPT_REMOVE_EMPTY_DIRS_EXT
#ifdef NT
#include <direct.h>
#else
#include <unistd.h>
#endif
#include <errno.h>
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
#include "md5.h"
#endif
# include "lists.h"
# include "parse.h"
# include "variable.h"
# include "rules.h"

# include "search.h"
# include "newstr.h"
# include "make.h"
# include "headers.h"
# include "command.h"

# ifdef OPT_HEADER_CACHE_EXT
# include "hcache.h"
# endif

# ifdef OPT_IMPROVED_PROGRESS_EXT
# include "progress.h"
# endif

# ifdef OPT_MULTIPASS_EXT
# include "timestamp.h"
# endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
# include "filesys.h"
#endif

#include "hash.h"
# include "fileglob.h"

# ifndef max
# define max( a,b ) ((a)>(b)?(a):(b))
# endif

int hadupdating;

typedef struct {
	int	temp;
	int	updating;
	int	cantfind;
	int	cantmake;
	int	targets;
	int	made;
} COUNTS ;

#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
static void make0( TARGET *t, TARGET *p, int epoch, int depth,
		COUNTS *counts, int anyhow );
#else
static void make0( TARGET *t, TARGET *p, int depth,
		COUNTS *counts, int anyhow );
#endif

static TARGETS *make0sort( TARGETS *c );
#ifdef OPT_BUILTIN_MD5CACHE_EXT
void make0calcmd5sum( TARGET *t, int source, int depth, int force );
#endif
#ifdef OPT_GRAPH_DEBUG_EXT
static void dependGraphOutput( TARGET *t, int depth );
#endif

void make1buildchecksum( const char* makestage, TARGET* t, XXH128_hash_t* buildmd5sum, int force );

static const char *target_fate[] =
{
	"init",		/* T_FATE_INIT */
	"making", 	/* T_FATE_MAKING */
	"stable", 	/* T_FATE_STABLE */
	"newer",	/* T_FATE_NEWER */
	"temp", 	/* T_FATE_ISTMP */
	"touched", 	/* T_FATE_TOUCHED */
	"missing", 	/* T_FATE_MISSING */
	"needtmp", 	/* T_FATE_NEEDTMP */
	"old", 		/* T_FATE_OUTDATED */
	"update", 	/* T_FATE_UPDATE */
	"nofind", 	/* T_FATE_CANTFIND */
	"nomake" 	/* T_FATE_CANTMAKE */
} ;

static const char *target_bind[] =
{
	"unbound",
	"missing",
	"parents",
	"exists",
} ;

# define spaces(x) ( "                " + 16 - ( x > 16 ? 16 : x ) )

#ifdef OPT_INTERRUPT_FIX
void onintr( int disp );
#endif

/*
 * make() - make a target, given its name
 */

int nodepcache = 0;
#ifdef OPT_USE_CHECKSUMS_EXT
int usechecksums = 0;
#endif /* OPT_USE_CHECKSUMS_EXT */
extern int make0calcmd5sum_epoch;
extern int make0calcmd5sum_timestamp_epoch;
extern int make0calcmd5sum_dependssorted_stage;

#ifdef OPT_MULTIPASS_EXT
int actionpass = 0;

void
make_fixparents(
	TARGETS *targets )
{
	for ( ; targets; targets = targets->next )
	{
		if ( targets->target->flags & T_FLAG_FIXPROGRESS_VISITED )
			continue;
		if ( targets->target->fate != T_FATE_TOUCHED )
			targets->target->fate = T_FATE_INIT;
		targets->target->progress = T_MAKE_INIT;
		make_fixparents( targets->target->parents );
	}
}

void
make_fixprogress(
	TARGET	*t )
{
	TARGETS *c;
	ACTIONS *actions;

	if ( t->flags & T_FLAG_FIXPROGRESS_VISITED )
		return;
	t->flags |= T_FLAG_FIXPROGRESS_VISITED;

	if ( t->fate == T_FATE_INIT  ||  t->fate == T_FATE_TOUCHED  ||  t->fate == T_FATE_MISSING  ||
		t->fate == T_FATE_STABLE  ||
		t->fate == T_FATE_UPDATE  ||  t->fate == T_FATE_CANTMAKE  ||  t->status == 3 /*EXEC_CMD_NEXTPASS*/ )
	{
		if ( t->fate != T_FATE_TOUCHED )
			t->fate = T_FATE_INIT;
		t->progress = T_MAKE_INIT;
		make_fixparents( t->parents );
	}

	if ( t->binding != T_BIND_EXISTS )
	{
		t->binding = T_BIND_UNBOUND;
		t->time = 0;
	}
	if ( t->parents )
		targetlist_free( t->parents );
	t->parents = NULL;
	t->flags &= ~T_FLAG_VISITED;
	t->status = 0;

	for ( actions = t->actions; actions; actions = actions->next )
	{
		if ( actions->action->pass == actionpass )
		{
			if ( actions->action->status == 3 /*EXEC_CMD_NEXTPASS*/ )
			{
				for (c = actions->action->sources; c; c = c->next)
				{
					if ( !c->target->actions )
					{
						actions->action->status = 0;
						actions->action->pass++;
					}
				}
			}

			if (actions->action->pass == actionpass)
			{
				actions->action->running = 0;
			}
		}
	}

	for( c = t->depends; c; c = c->next )
	{
		make_fixprogress( c->target );
	}
}

LIST *queuedjamfiles = NULL;

typedef struct _queuedfileinfo QUEUEDFILEINFO;

struct _queuedfileinfo {
	int priority;
	const char *filename;
} ;

int compare_queuedfileinfo( const void *_left, const void *_right ) {
	QUEUEDFILEINFO *left = (QUEUEDFILEINFO*)_left;
	QUEUEDFILEINFO *right = (QUEUEDFILEINFO*)_right;
	return left->priority < right->priority;
}

#endif

#ifdef OPT_REMOVE_EMPTY_DIRS_EXT

LIST* emptydirtargets = L0;

struct dirlistdata {
	const char	*name;
} ;

typedef struct dirlistdata DIRLISTDATA;


typedef struct _sortedtargets SORTEDTARGETS;

struct _sortedtargets {
	const char *filename;
	size_t filenamelen;
} ;

int compare_sortedtargets( const void *_left, const void *_right ) {
	SORTEDTARGETS *left = (SORTEDTARGETS*)_left;
	SORTEDTARGETS *right = (SORTEDTARGETS*)_right;
	if ( right->filenamelen > left->filenamelen )
		return 1;
	if ( right->filenamelen < left->filenamelen )
		return -1;
	return strcmp( right->filename, left->filename );
}


void remove_empty_dirs()
{
	BUFFER lastdirbuff;
	LISTITEM *l;
	int i;
	int count;
	SORTEDTARGETS* sortedfiles;

	struct hash *dirlisthash;
	DIRLISTDATA dirlistdata, *c = &dirlistdata;


	if ( !list_first(emptydirtargets) )
		return;

	l = list_first(emptydirtargets);
	i = 0;
	count = 0;

	for( ; l; l = list_next( l ) ) {
		++count;
	}

	dirlisthash = hashinit( sizeof(DIRLISTDATA), "dirlisthash" );

	sortedfiles = malloc( sizeof( SORTEDTARGETS ) * count );
	i = 0;
	for( l = list_first(emptydirtargets); l; l = list_next( l ) ) {
		TARGET *t;
		t = bindtarget( list_value(l) );
		pushsettings( t->settings );
		t->boundname = search( t->name, &t->time );
		popsettings( t->settings );

		char* slashptr = strrchr( t->boundname, '/' );
		if (slashptr == NULL)
			continue;
		char path[MAXJPATH];
		strncpy( path, t->boundname, slashptr - t->boundname + 1 );
		path[ slashptr - t->boundname + 1 ] = 0;

		c = &dirlistdata;
		c->name = path;
		if ( hashenter( dirlisthash, (HASHDATA **)&c ) ) {
			c->name = newstr( path );

			sortedfiles[ i ].filename = c->name;
			sortedfiles[ i ].filenamelen = slashptr - t->boundname;
			++i;
		}
	}
	count = i;

	qsort( sortedfiles,	count, sizeof( SORTEDTARGETS ), compare_sortedtargets );

	hashdone( dirlisthash );
	dirlisthash = hashinit( sizeof(DIRLISTDATA), "dirlisthash" );

	buffer_init( &lastdirbuff );
	buffer_addchar( &lastdirbuff, 0 );
	for ( i = 0; i < count; ++i ) {
		char* slashptr = strrchr( sortedfiles[ i ].filename, '/' );
		if ( slashptr )
			*slashptr = 0;
		if ( strcmp( buffer_ptr( &lastdirbuff ), sortedfiles[ i ].filename ) != 0 ) {
			buffer_reset( &lastdirbuff );
			buffer_addstring( &lastdirbuff, sortedfiles[ i ].filename, strlen( sortedfiles[ i ].filename ) );
			buffer_addchar( &lastdirbuff, 0 );
			buffer_addchar( &lastdirbuff, 0 );

			buffer_deltapos( &lastdirbuff, -2 );

			{
				char* lastdirptr = buffer_ptr( &lastdirbuff );
				char* dirslashptr = buffer_posptr( &lastdirbuff );
				while ( 1 ) {
					char* olddirslashptr = dirslashptr;

					int dirret = dir_isempty( lastdirptr );
					if (dirret == ENOTEMPTY) {
						*olddirslashptr = '/';
						break;
					}

					if ( dirret == 0 ) {
						/* walk up directories removing any empty ones */
						c = &dirlistdata;
						c->name = lastdirptr;
						if ( hashenter( dirlisthash, (HASHDATA **)&c ) ) {
							c->name = newstr( lastdirptr );
							int MAX_RETRIES = 5;
							int retries = 0;
							while ( retries < MAX_RETRIES ) {
								int ret = rmdir( lastdirptr );
								if ( ret == -1 ) {
									int err = errno;
									if ( err == EACCES ) {
										printf("remove %s - %d - %d\n", lastdirptr, ret, err);
#if defined(_WIN32)
										_sleep(1);
#else
										usleep(1000);
#endif
										++retries;
										continue;
									}
									if ( err != ENOENT ) {
										*olddirslashptr = '/';
										retries = MAX_RETRIES;
										break;
									}
								} else {
									break;
								}
							}
						}
					}

					dirslashptr = strrchr( lastdirptr, '/' );
					*olddirslashptr = '/';
					if ( !dirslashptr )
						break;
					*dirslashptr = 0;
				}

				buffer_addchar( &lastdirbuff, 0 );
			}
		}
		if ( slashptr )
			*slashptr = '/';
	}
	buffer_free( &lastdirbuff );

	free( sortedfiles );

	list_free( emptydirtargets );

	hashdone( dirlisthash );
}

#endif /* OPT_REMOVE_EMPTY_DIRS_EXT */


#ifdef OPT_CLEAN_GLOBS_EXT

struct usedtargetsdata {
	const char	*name;
} ;

typedef struct usedtargetsdata USEDTARGETSDATA ;
static struct hash *usedtargetshash;


void add_used_target_to_hash(TARGET *t) {
	USEDTARGETSDATA usedtargetsdata, *c = &usedtargetsdata;
	if (!usedtargetshash) {
		usedtargetshash = hashinit(sizeof(USEDTARGETSDATA), "usedtargets");
	}
	c->name = t->name;
	if (hashenter(usedtargetshash, (HASHDATA **)&c)) {
		c->name = newstr(t->name);
	}
}


static void add_files_to_keepfileshash( void *userdata, HASHDATA *hashdata ) {
	struct hash *keepfileshash = (struct hash *)userdata;
	USEDTARGETSDATA usedfilesdata, *c = &usedfilesdata;
	USEDTARGETSDATA *data = (USEDTARGETSDATA *)hashdata;
	const char *target;
# ifdef DOWNSHIFT_PATHS
	char path[MAXJPATH], *p;
# endif

	TARGET *t = bindtarget( data->name );
	if( t->binding == T_BIND_UNBOUND && !( t->flags & T_FLAG_NOTFILE ) )
	{
		pushsettings( t->settings );
		t->boundname = search( t->name, &t->time );
		t->binding = t->time ? T_BIND_EXISTS : T_BIND_MISSING;
		popsettings( t->settings );
	}

	target = t->boundname;

# ifdef DOWNSHIFT_PATHS
	p = path;
	do *p++ = (char)tolower(*target); while (*target++);
	target = path;
# endif

	c->name = target;
	if (hashenter(keepfileshash, (HASHDATA **)&c)) {
		c->name = newstr(target);
	}
}

int clean_unused_files(int usealltargets) {
	LISTITEM *l;
	LIST* clean_verbose;
	LIST* clean_noop;
	LIST* clean_roots;
	struct hash *keepfileshash;
	int verbose = 0;
	int noop = 0;

	keepfileshash = hashinit(sizeof(USEDTARGETSDATA), "usedfiles");

	for (l = list_first(var_get("CLEAN.KEEP_TARGETS")); l; l = list_next(l)) {
		USEDTARGETSDATA keepfilesdata;
		keepfilesdata.name = list_value(l);
		add_files_to_keepfileshash(keepfileshash, (HASHDATA *)&keepfilesdata);
	}

	if (usedtargetshash && (usealltargets || var_get("CLEAN.KEEP_USED_TARGETS"))) {
		hashiterate(usedtargetshash, add_files_to_keepfileshash, keepfileshash);
	}

	for (l = list_first(var_get("CLEAN.KEEP_WILDCARDS")); l; l = list_next(l)) {
		fileglob *glob = fileglob_Create(list_value(l));
		while (fileglob_Next(glob)) {
			USEDTARGETSDATA usedfilesdata, *c = &usedfilesdata;
			const char *target = fileglob_FileName(glob);
# ifdef DOWNSHIFT_PATHS
			char path[MAXJPATH];
			char *p = path;

			do *p++ = (char)tolower(*target);
			while (*target++);

			target = path;
# endif

			c->name = target;
			if (hashenter(keepfileshash, (HASHDATA **)&c)) {
				c->name = newstr(target);
			}
		}
		fileglob_Destroy(glob);
	}

	clean_verbose = var_get("CLEAN.VERBOSE");
	if (clean_verbose  &&  list_first(clean_verbose)  &&  strcmp(list_value(list_first(clean_verbose)), "1") == 0) {
		verbose = 1;
	}

	clean_noop = var_get("CLEAN.NOOP");
	if (clean_noop  &&  list_first(clean_noop)  &&  strcmp(list_value(list_first(clean_noop)), "1") == 0) {
		noop = 1;
	}

	int filesremoved = 0;
	for (l = list_first(var_get("CLEAN.REMOVE_WILDCARDS")); l; l = list_next(l)) {
		fileglob *glob = fileglob_Create(list_value(l));
		while (fileglob_Next(glob)) {
			USEDTARGETSDATA usedfilesdata, *c = &usedfilesdata;
			const char *target = fileglob_FileName(glob);
			if (verbose) {
				printf("* Removing %s...\n", target);
			}
			if (!noop) {
				unlink(target);
				filesremoved = 1;
			}
		}
		fileglob_Destroy(glob);
	}

	for (l = list_first(var_get("CLEAN.REMOVE_TARGETS")); l; l = list_next(l)) {
		TARGET *t = bindtarget( list_value(l) );
		if (t->boundname != NULL) {
			time_t time;
			if (file_time( t->boundname, &time ) != -1) {
				if (verbose) {
					printf("* Removing %s...\n", t->boundname);
				}
				if (!noop) {
					unlink(t->boundname);
					filesremoved = 1;
				}
			}
		}
	}

	clean_roots = var_get("CLEAN.ROOTS");
	for (l = list_first(clean_roots); l; l = list_next(l)) {
		fileglob* glob;

		glob = fileglob_Create(list_value(l));
		while (fileglob_Next(glob)) {
			const char *target = fileglob_FileName(glob);
			USEDTARGETSDATA usedtargetsdata, *c = &usedtargetsdata;
			char path[MAXJPATH];
			char *p = path;

# ifdef DOWNSHIFT_PATHS
			do *p++ = (char)tolower(*target);
			while (*target++);
# else
			strcpy(path, target);
# endif
			target = path;

			c->name = target;

			if (fileglob_IsDirectory(glob)) {
				strcat(path, "\x01");
			} else {
				if (!hashcheck(keepfileshash, (HASHDATA **)&c)) {
					if (verbose) {
						printf("* Removing %s...\n", target);
					}
					if (!noop) {
						unlink(target);
						filesremoved = 1;
					}
				}
			}
			emptydirtargets = list_append(emptydirtargets, target, 0);
		}
		fileglob_Destroy(glob);
	}

	hashdone(keepfileshash);
	hashdone(usedtargetshash);
	usedtargetshash = NULL;

	return filesremoved;
}

#endif /* OPT_CLEAN_GLOBS_EXT */


int
make(
	int		n_targets,
	const char	**targets,
	int		anyhow )
{
	int i;
	COUNTS counts[1];
	int status = 0;		/* 1 if anything fails */

#ifdef OPT_INTERRUPT_FIX
	signal( SIGINT, onintr );
#endif

#ifdef OPT_MULTIPASS_EXT
pass:
#endif
	++make0calcmd5sum_dependssorted_stage;

	memset( (char *)counts, 0, sizeof( *counts ) );

	for( i = 0; i < n_targets; i++ )
	{
	    TARGET *t = bindtarget( targets[i] );

#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
	    make0( t, 0, i, 0, counts, anyhow );
#else
	    make0( t, 0, 0, counts, anyhow );
#endif
	}
#ifdef OPT_GRAPH_DEBUG_EXT
	if( DEBUG_GRAPH )
	{
		for( i = 0; i < n_targets; i++ )
		{
			TARGET *t = bindtarget( targets[i] );
			dependGraphOutput( t, 0 );
		}
	}
#endif

	if( DEBUG_MAKE )
	{
		if( counts->targets )
			printf( "*** found %d target(s)...\n", counts->targets );
		if( counts->temp )
			printf( "*** using %d temp target(s)...\n", counts->temp );
		if( counts->updating )
		{
			printf( "*** updating %d target(s)...\n", counts->updating );
			hadupdating = 1;
		}
		if( counts->cantfind )
			printf( "*** can't find %d target(s)...\n", counts->cantfind );
		if( counts->cantmake )
			printf( "*** can't make %d target(s)...\n", counts->cantmake );
	}

#ifdef OPT_IMPROVED_PROGRESS_EXT
	globs.updating = counts->updating;
	globs.progress = progress_start(counts->updating);
#endif
#ifdef OPT_MULTIPASS_EXT
	status |= counts->cantfind || counts->cantmake;
#else
	status = counts->cantfind || counts->cantmake;
#endif

	++make0calcmd5sum_dependssorted_stage;

	for( i = 0; i < n_targets; i++ )
	    status |= make1( bindtarget( targets[i] ) );

#ifdef OPT_MULTIPASS_EXT
	if ( list_first(queuedjamfiles) )
	{
		LIST *origqueuedjamfiles = queuedjamfiles;
		LISTITEM *l = list_first(queuedjamfiles);
		int i = 0;
		int count = 0;
		QUEUEDFILEINFO* sortedfiles;

		queuedjamfiles = L0;

		for( i = 0; i < n_targets; i++ )
			make_fixprogress( bindtarget( targets[i] ) );

#ifdef OPT_BUILTIN_MD5CACHE_EXT
		checksums_nextpass();
#endif /* OPT_BUILTIN_MD5CACHE_EXT */
		donestamps();
		++actionpass;

		printf( "*** executing pass %d...\n", actionpass + 1 );

		for( ; l; l = list_next( l ) ) {
			++count;
		}

		sortedfiles = (QUEUEDFILEINFO*)malloc( sizeof( QUEUEDFILEINFO ) * count );
		i = 0;
		for( l = list_first( origqueuedjamfiles ); l; l = list_next( l ) ) {
			char *separator = strchr( list_value(l), '\xff' );
			TARGET *t;
			*separator = 0;
			t = bindtarget(list_value(l));
			*separator = '\xff';
			pushsettings( t->settings );
			t->boundname = search( t->name, &t->time );
			popsettings( t->settings );
			sortedfiles[i].priority = atoi( separator + 1 );
			sortedfiles[i].filename = t->boundname;
			++i;
		}

		qsort( sortedfiles,	count, sizeof( QUEUEDFILEINFO ), compare_queuedfileinfo );

		for ( i = 0; i < count; ++i ) {
			parse_file( sortedfiles[ i ].filename );
		}

		free( sortedfiles );

		list_free( origqueuedjamfiles );

		goto pass;
	}
#endif

#ifdef OPT_HEADER_CACHE_EXT
	if ( globs.noexec == 0 )
		hcache_done();
#endif

    donestamps();

#ifdef OPT_BUILTIN_MD5CACHE_EXT
	for ( i = 0; i < n_targets; i++ )
	{
		if ( strcmp( targets[i], "clean" ) == 0 ) {
			LIST *var = var_get( "JAM_CHECKSUMS_KEEPCACHE" );
			if ( !var  ||  !list_first( var )  ||  strcmp( list_value( list_first( var ) ), "1" ) != 0 ) {
				emptydirtargets = list_append(emptydirtargets, checksums_filename(), 0);
				unlink( checksums_filename() );
			}
			var = var_get( "JAM_KEEPDEPCACHE" );
			if ( !var  ||  !list_first( var )  ||  strcmp( list_value( list_first( var ) ), "1" ) != 0 ) {
				if ( hcache_get_builtinfilename() ) {
					emptydirtargets = list_append(emptydirtargets, hcache_get_builtinfilename(), 0);
					unlink( hcache_get_builtinfilename() );
				}
			}
			break;
		}
	}
#endif /* OPT_BUILTIN_MD5CACHE_EXT */

#ifdef OPT_CLEAN_GLOBS_EXT
	if ( var_get( "TARGETINFO_LOCATE" ) == NULL ) {
		clean_unused_files(1);
	}
#endif /* OPT_CLEAN_GLOBS_EXT */

#ifdef OPT_REMOVE_EMPTY_DIRS_EXT
	remove_empty_dirs();
#endif

	return status;
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int  md5matchescommandline( TARGET *t )
{
	SETTINGS *vars;

	if ( t->rulemd5sumchecked )
		return t->rulemd5sumclean;

	t->rulemd5sumchecked = 1;

	if ( ! ( t->flags & T_FLAG_USECOMMANDLINE ) )
	{
		// Not a source file.
		t->rulemd5sumclean = 1;
		return 1;
	}

	for ( vars = t->settings; vars; vars = vars->next )
	{
		if ( vars->symbol[0] == 'C'  &&  strcmp( vars->symbol, "COMMANDLINE" ) == 0 )
		{
			LISTITEM *item;
			XXH3_state_t* state = XXH3_createState();
			XXH3_128bits_reset(state);

			for ( item = list_first(vars->value); item; item = list_next(item) ) {
				char const* str = list_value(item);
				XXH3_128bits_update(state, (unsigned char*)str, (unsigned int)strlen( str ) );
			}

			t->rulemd5sum = XXH3_128bits_digest(state);
			XXH3_freeState(state);
			t->rulemd5sumclean = (char)hcache_getrulemd5sum( t );
			return t->rulemd5sumclean;
		}
	}

	t->rulemd5sumclean = 1;
	return 1;
}
#endif

/*
 * make0() - bind and scan everything to make a TARGET
 *
 * Make0() recursively binds a target, searches for #included headers,
 * calls itself on those headers, and calls itself on any dependents.
 */

static void
make0(
	TARGET	*t,
	TARGET  *p,		/* parent */
#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
	int epoch,      /* top level invocation number for make0 */
#endif
	int	depth,		/* for display purposes */
	COUNTS	*counts,/* for reporting */
	int	anyhow      /* forcibly touch all (real) targets */
	)
{
	TARGETS	*c, *incs;
	TARGET 	*ptime = t;
	time_t	last, leaf, hlast;
	int	fate;
	const char *flag = "";
	SETTINGS *s;
#ifdef OPT_GRAPH_DEBUG_EXT
	int	savedFate, oldTimeStamp;
#endif
	LIST* hdrextra;

	/*
	 * Step 1: initialize
	 */

	if( DEBUG_MAKEPROG )
		printf( "make\t--\t%s%s\n", spaces( depth ), t->name );

#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
	if ( t->fate == T_FATE_INIT ) {
		t->epoch = epoch;
		t->depth = depth;
		t->recurseincludesepoch = INT_MIN;
	}
#endif
#ifdef OPT_USE_CHECKSUMS_EXT
	if ( t->fate == T_FATE_INIT ) {
		t->timestamp_epoch = -1000000001;
		t->calcchecksum_epoch = -1000000001;
	}
#endif /* OPT_USE_CHECKSUMS_EXT */
#ifdef OPT_MULTIPASS_EXT
	if ( t->fate == T_FATE_INIT )
		t->fate = T_FATE_MAKING;
	t->flags &= ~T_FLAG_FIXPROGRESS_VISITED;
#else
	t->fate = T_FATE_MAKING;
#endif

	/*
	 * Step 2: under the influence of "on target" variables,
	 * bind the target and search for headers.
	 */

	/* Step 2a: set "on target" variables. */

	s = copysettings( t->settings );
	pushsettings( s );

	/* Step 2b: find and timestamp the target file (if it's a file). */

	if( t->binding == T_BIND_UNBOUND && !( t->flags & T_FLAG_NOTFILE ) )
	{
		t->boundname = search( t->name, &t->time );
		t->binding = t->time ? T_BIND_EXISTS : T_BIND_MISSING;
#if 0
		if (usechecksums)
		{
			if (t->binding == T_BIND_EXISTS)
			{
				getcachedmd5sum(t, 0);
				if (t->contentchecksum)
				{
					t->time = t->contentchecksum->originalmtime;
				}
			}
		}
#endif
	}

	/* INTERNAL, NOTFILE header nodes have the time of their parents */

	if( p && t->flags & T_FLAG_INTERNAL )
		ptime = p;

	/* If temp file doesn't exist but parent does, use parent */

	if( p && t->flags & T_FLAG_TEMP &&
		t->binding == T_BIND_MISSING &&
		p->binding != T_BIND_MISSING )
	{
		t->binding = T_BIND_PARENTS;
		ptime = p;
	}

	hdrextra = var_get("HDREXTRA");

	/* Step 2c: If its a file, search for headers. */
	if( t->binding == T_BIND_EXISTS || hdrextra )
		headers( t );

#ifdef OPT_SEMAPHORE
	{
		LIST *var = var_get( "SEMAPHORE" );
		if( list_first(var) )
		{
			TARGET *semaphore = bindtarget(list_value(list_first(var)));

			semaphore->progress = T_MAKE_SEMAPHORE;
			t->semaphore = semaphore;
		}
	}
#endif

	/* Step 2d: reset "on target" variables */

	popsettings( s );
	freesettings( s );

	/*
	 * Pause for a little progress reporting
	 */

	if( DEBUG_MAKEPROG )
	{
		if( strcmp( t->name, t->boundname ) )
		{
			printf( "bind\t--\t%s%s: %s\n",
				spaces( depth ), t->name, t->boundname );
		}

		switch( t->binding )
		{
			case T_BIND_UNBOUND:
			case T_BIND_MISSING:
			case T_BIND_PARENTS:
				printf( "time\t--\t%s%s: %s\n",
					spaces( depth ), t->name, target_bind[ t->binding ] );
				break;

			case T_BIND_EXISTS:
				printf( "time\t--\t%s%s: %s",
					spaces( depth ), t->name, ctime( &t->time ) );
				break;
		}
	}

	/*
	 * Step 3: recursively make0() dependents & headers
	 */

	/* Step 3a: recursively make0() dependents */

	for( c = t->depends; c; c = c->next )
	{
		int internal = t->flags & T_FLAG_INTERNAL;

		if( DEBUG_DEPENDS )
#ifdef OPT_BUILTIN_NEEDS_EXT
			printf( "%s \"%s\" : \"%s\" ;\n",
					(internal ? "Includes" : (c->needs ? "Needs" : "Depends")),
					t->name, c->target->name );
#else
			printf( "%s \"%s\" : \"%s\" ;\n",
					(internal ? "Includes" : "Depends"),
					t->name, c->target->name );
#endif

		/* Warn about circular deps, except for includes, */
		/* which include each other alot. */

		if( c->target->fate == T_FATE_INIT )
#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
			make0( c->target, ptime, epoch, depth + 1, counts, anyhow );
#else
			make0( c->target, ptime, depth + 1, counts, anyhow );
#endif
		else if( c->target->fate == T_FATE_MAKING && !internal )
			printf( "warning: %s depends on itself\n", c->target->name );
#ifdef OPT_FIX_UPDATED
		else if( ptime && ptime->binding != T_BIND_UNBOUND &&
			c->target->time > ptime->time &&
			c->target->fate < T_FATE_NEWER )
		{
			/*
			 * BUG FIX:
			 *
			 * If you have a rule with flag RULE_UPDATED, then any
			 * dependents must have fate greater than
			 * T_FATE_STABLE to be included.
			 *
			 * However, make.c can get confused for dependency
			 * trees like this:
			 *
			 * a --> b --> d
			 *   \-> c --> d
			 *
			 * In this case, make.c can set the fate of "d" before
			 * it ever gets to "c".  So you will end up with a
			 * T_FATE_MISSING target "c" with dependents with
			 * T_FATE_STABLE.
			 *
			 * If "c" happens to have a RULE_UPDATED action,
			 * RULE_UPDATED, make1list() will refrain from
			 * including it in the list of targets.
			 *
			 * We hack around this here by explicitly checking for
			 * this case and manually tweaking the dependents fate
			 * to at least T_FATE_NEWER.
			 *
			 * An alternate fix is to modify make1cmds() to take a
			 * TARGET* instead of an ACTIONS* and, when the target
			 * is T_FATE_MISSING, have it mask off the
			 * RULE_UPDATED flag when calling make1list().
			 */
#ifdef OPT_GRAPH_DEBUG_EXT
			if( DEBUG_FATE ) {
				if( c->target->fate == T_FATE_STABLE ) {
					printf("fate change  %s set to %s (parent %s)\n",
						c->target->name,
						target_fate[T_FATE_NEWER],
						ptime->name);
				} else {
					printf("fate change  %s adjusted from %s to %s\n",
						c->target->name,
						target_fate[c->target->fate],
						target_fate[T_FATE_NEWER]);
				}
			}
#endif
//			c->target->fate = T_FATE_NEWER;
	    }
#endif
	}

	/* Step 3b: recursively make0() internal includes node */

	if( t->includes )
#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
	    make0( t->includes, p, epoch, depth + 1, counts, anyhow );
#else
	    make0( t->includes, p, depth + 1, counts, anyhow );
#endif

	/* Step 3c: add dependents' includes to our direct dependencies */

	incs = 0;

	for( c = t->depends; c; c = c->next ) {
#ifdef OPT_BUILTIN_NEEDS_EXT
		/* If this is a "Needs" dependency, don't care about its timestamp. */
		if (c->needs  ||  (t->flags & T_FLAG_MIGHTNOTUPDATE)) {
			continue;
		}
#endif
		if( c->target->includes ) {
#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
			if ( c->target->includes->epoch == epoch  &&  c->target->includes->depth <= depth ) {
				/* See http://maillist.perforce.com/pipermail/jamming/2003-December/002252.html and
					  http://maillist.perforce.com/pipermail/jamming/2003-December/002253.html */
				/*
				 * Found a loop in the graph, break it by flattening the dependencies
				 */
				TARGETS *n;
				for ( n = c->target->includes->depends; n; n = n->next )
				{
					if( t != n->target )
					{
#ifdef OPT_BUILTIN_NEEDS_EXT
						incs = targetentry( incs, n->target, 0 );
#else /* !OPT_BUILTIN_NEEDS_EXT */
						incs = targetentry( incs, n->target );
#endif /* OPT_BUILTIN_NEEDS_EXT */
						if( n->target->fate == T_FATE_INIT )
						{
							/*
							 * Found never visited dependent node, visit it before picking up fate and time.
							 */
							make0( n->target, c->target, epoch, c->target->includes->depth + 1, counts, anyhow );
						}
					}
				}
			}
			else
			{
				incs = targetentry( incs, c->target->includes, 0 );
			}

#else /* !OPT_CIRCULAR_GENERATED_HEADER_FIX */
#ifdef OPT_BUILTIN_NEEDS_EXT
			incs = targetentry( incs, c->target->includes, 0 );
#else
			incs = targetentry( incs, c->target->includes );
#endif /* OPT_BUILTIN_NEEDS_EXT */
#endif /* OPT_CIRCULAR_GENERATED_HEADER_FIX */
#ifdef OPT_UPDATED_CHILD_FIX
			/* See http://maillist.perforce.com/pipermail/jamming/2006-May/002676.html */
			/* If the includes are newer than we are their original target
				also needs to be marked newer. This is needed so that 'updated'
				correctly will include the original target in the $(<) variable. */
			if(c->target->includes->time > ptime->time || c->target->includes->fate > T_FATE_STABLE) {
				c->target->fate = max( T_FATE_NEWER, c->target->fate );
			}
#endif
	    }
	}

	t->depends = targetchain( t->depends, incs );

	/*
	 * Step 4: compute time & fate
	 */

	/* Step 4a: pick up dependents' time and fate */

	last = 0;
	leaf = 0;
	fate = T_FATE_STABLE;

	for( c = t->depends; c; c = c->next )
	{
#ifdef OPT_BUILTIN_NEEDS_EXT
		/* If this is a "Needs" dependency, don't care about its timestamp. */
		if (c->needs  ||  (t->flags & T_FLAG_MIGHTNOTUPDATE)) {
			continue;
		}
#endif

		/* If LEAVES has been applied, we only heed the timestamps of */
		/* the leaf source nodes. */

		leaf = max( leaf, c->target->leaf );

		if( t->flags & T_FLAG_LEAVES )
		{
			last = leaf;
			continue;
		}

		last = max( last, c->target->time );
#ifdef OPT_GRAPH_DEBUG_EXT
		if( DEBUG_FATE && fate < c->target->fate ) {
			printf( "fate change  %s from %s to %s by dependency %s\n",
				t->name,
				target_fate[fate], target_fate[c->target->fate],
				c->target->name);
		}
#endif
		fate = max( fate, c->target->fate );
	}

	/* Step 4b: pick up included headers time */

	/*
	 * If a header is newer than a temp source that includes it,
	 * the temp source will need building.
	 */

	hlast = t->includes ? t->includes->time : 0;

	/* Step 4c: handle NOUPDATE oddity */

	/*
	 * If a NOUPDATE file exists, make dependents eternally old.
	 * Don't inherit our fate from our dependents.  Decide fate
	 * based only upon other flags and our binding (done later).
	 */

	if( t->flags & T_FLAG_NOUPDATE )
	{
#ifdef OPT_GRAPH_DEBUG_EXT
		if( DEBUG_FATE && fate != T_FATE_STABLE ) {
			printf("fate change  %s back to stable by NOUPDATE.\n",
				t->name);
		}
#endif
		last = 0;
		t->time = 0;
		fate = T_FATE_STABLE;
	}

	/* Step 4d: determine fate: rebuild target or what? */

	/*
	    In English:
		If can't find or make child, can't make target.
		If children changed, make target.
		If target missing, make it.
		If children newer, make target.
		If temp's children newer than parent, make temp.
		If temp's headers newer than parent, make temp.
		If deliberately touched, make it.
		If up-to-date temp file present, use it.
		If target newer than non-notfile parent, mark target newer.
		Otherwise, stable!

		Note this block runs from least to most stable:
		as we make it further down the list, the target's
		fate is getting stabler.
	*/
#ifdef OPT_GRAPH_DEBUG_EXT
	savedFate = fate;
	oldTimeStamp = 0;
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
	if ( !md5matchescommandline( t ) )
	{
		ACTIONS *actions;
		for ( actions = t->actions; actions; actions = actions->next )
		{
			TARGETS *targets;
			for ( targets = actions->action->targets; targets; targets = targets->next )
			{
				if ( targets->target == t )
				{
					targets->parentcommandlineoutofdate = 1;
					break;
				}
			}
			for ( targets = actions->action->sources; targets; targets = targets->next )
			{
				for( c = t->depends; c; c = c->next )
				{
					if ( targets->target == c->target )
					{
						targets->parentcommandlineoutofdate = 1;
						break;
					}
				}
				//if ( targets->parentcommandlineoutofdate )
				//{
					//break;
				//}
			}
		}

		fate = T_FATE_UPDATE;
	}
#endif

	if (usechecksums && fate == T_FATE_STABLE)
	{
		if (t->binding == T_BIND_EXISTS && !(t->flags & (T_FLAG_NOTFILE | T_FLAG_NOUPDATE)) /* && t->actions*/)
		{
			if (t->actions) {
				//if (t->contentchecksum != NULL && t->contentchecksum->currentmtime != t->contentchecksum->originalmtime)
				{
					XXH128_hash_t buildmd5sum;

					/* find its final md5sum */
					++make0calcmd5sum_epoch;
					++make0calcmd5sum_timestamp_epoch;
					//make0calcmd5sum(t, 1, 1);
					make1buildchecksum("make0", t, &buildmd5sum, 0);

					if (checksum_retrieve(t, buildmd5sum, 0) == 0)
					{
						t->flags |= T_FLAG_WRONGCHECKSUM;
						fate = T_FATE_UPDATE;
					}
				}
			}
			else {
				/*
				if (t->binding == T_BIND_EXISTS)
				{
					//getcachedmd5sum(t, 0);
					if (t->contentchecksum && t->contentchecksum->contentmd5sum_changed)
					{
						fate = T_FATE_NEWER;
					}
				}
				*/
			}
		}
	}

	if( fate >= T_FATE_BROKEN )
	{
		fate = T_FATE_CANTMAKE;
	}
	else if( fate >= T_FATE_SPOIL )
	{
		fate = T_FATE_UPDATE;
	}
	else if( t->binding == T_BIND_MISSING )
	{
		fate = T_FATE_MISSING;
	}
	else if( t->binding == T_BIND_EXISTS && last > t->time )
	{
#ifdef OPT_GRAPH_DEBUG_EXT
		oldTimeStamp = 1;
#endif
		fate = T_FATE_OUTDATED;
	}
	else if( t->binding == T_BIND_PARENTS && last > p->time )
	{
		fate = T_FATE_NEEDTMP;
	}
	else if( t->binding == T_BIND_PARENTS && hlast > p->time )
	{
#ifdef OPT_GRAPH_DEBUG_EXT
		oldTimeStamp = 1;
#endif
		fate = T_FATE_NEEDTMP;
	}
	else if( t->flags & T_FLAG_TOUCHED )
	{
		fate = T_FATE_TOUCHED;
	}
	else if( anyhow && !( t->flags & T_FLAG_NOUPDATE ) )
	{
		fate = T_FATE_TOUCHED;
	}
	else if( t->binding == T_BIND_EXISTS && t->flags & T_FLAG_TEMP )
	{
		fate = T_FATE_ISTMP;
	}
	// See http://maillist.perforce.com/pipermail/jamming/2003-January/001853.html.
	else if( t->binding == T_BIND_EXISTS && p &&
		p->binding != T_BIND_UNBOUND && t->time > p->time )
	{
#ifdef OPT_BUILTIN_NEEDS_EXT
		if (!(p->flags & T_FLAG_MIGHTNOTUPDATE))
		{
#endif
		fate = T_FATE_NEWER;
#ifdef OPT_BUILTIN_NEEDS_EXT
		}
#endif
	}
	else
	{
		fate = T_FATE_STABLE;
	}
#ifdef OPT_GRAPH_DEBUG_EXT
	if( DEBUG_FATE && fate != savedFate )
	{
		if( savedFate == T_FATE_STABLE )
		{
			printf( "fate change  %s set to %s%s\n",
				t->name, target_fate[fate],
				oldTimeStamp ? " (by timestamp)" : "" );
		}
		else
		{
			printf( "fate change  %s adjusted from %s to %s%s\n",
				t->name, target_fate[savedFate], target_fate[fate],
				oldTimeStamp ? " (by timestamp)" : "" );
		}
	}
#endif

	/* Step 4e: handle missing files */
	/* If it's missing and there are no actions to create it, boom. */
	/* If we can't make a target we don't care about, 'sokay */
	/* We could insist that there are updating actions for all missing */
	/* files, but if they have dependents we just pretend it's NOTFILE. */

	if( fate == T_FATE_MISSING && !t->actions && !t->depends )
	{
#ifdef OPT_MULTIPASS_EXT
		if ( queuedjamfiles )
		{
			if( ( t->flags & T_FLAG_NOCARE ) )
			{
				if( !( t->flags & T_FLAG_FORCECARE ) )
				{
#ifdef OPT_GRAPH_DEBUG_EXT
					if( DEBUG_FATE )
						printf( "fate change  %s to STABLE from %s, "
							"no actions, no dependents and don't care\n",
							t->name, target_fate[fate]);
#endif
					fate = T_FATE_STABLE;
				}
			}
			else if( !( t->flags & T_FLAG_FORCECARE ) )
			{
				printf( "don't know how to make %s\n", t->name );

				fate = T_FATE_CANTFIND;
			}
		}
		else
		{
#endif
		if( t->flags & T_FLAG_NOCARE )
		{
#ifdef OPT_GRAPH_DEBUG_EXT
			if( DEBUG_FATE )
				printf( "fate change  %s to STABLE from %s, "
						"no actions, no dependents and don't care\n",
						t->name, target_fate[fate]);
#endif
			fate = T_FATE_STABLE;
		}
		else
		{
			printf( "don't know how to make %s\n", t->name );

			fate = T_FATE_CANTFIND;
		}
#ifdef OPT_MULTIPASS_EXT
		}
#endif
	}

	/* Step 4f: propagate dependents' time & fate. */
	/* Set leaf time to be our time only if this is a leaf. */

	t->time = max( t->time, last );
	t->leaf = leaf ? leaf : t->time ;
	t->fate = (char)fate;

	/*
	 * Step 5: sort dependents by their update time.
	 */

#ifdef OPT_FIX_NOTFILE_NEWESTFIRST
	if( globs.newestfirst && !( t->flags & T_FLAG_NOTFILE ) )
		t->depends = make0sort( t->depends );
#else
	if( globs.newestfirst )
		t->depends = make0sort( t->depends );
#endif

	/*
	 * Step 6: a little harmless tabulating for tracing purposes
	 */

	/* Don't count or report interal includes nodes. */

	if( t->flags & T_FLAG_INTERNAL )
		return;


#ifdef OPT_IMPROVED_PATIENCE_EXT
	++counts->targets;
#else
	if( !( ++counts->targets % 1000 ) && DEBUG_MAKE )
		printf( "*** patience...\n" );
#endif

	if( fate == T_FATE_ISTMP )
		counts->temp++;
	else if( fate == T_FATE_CANTFIND )
		counts->cantfind++;
	else if( fate == T_FATE_CANTMAKE && t->actions )
		counts->cantmake++;
	else if( fate >= T_FATE_BUILD && fate < T_FATE_BROKEN && t->actions )
		counts->updating++;

	if( !( t->flags & T_FLAG_NOTFILE ) && fate >= T_FATE_SPOIL )
		flag = "+";
	else if( t->binding == T_BIND_EXISTS && p && t->time > p->time )
		flag = "*";

	if( DEBUG_MAKEPROG )
		printf( "made%s\t%s\t%s%s\n",
			flag, target_fate[ t->fate ],
			spaces( depth ), t->name );

	if( DEBUG_CAUSES &&
		t->fate >= T_FATE_NEWER &&
		t->fate <= T_FATE_MISSING )
			printf( "%s %s\n", target_fate[ t->fate ], t->name );
}

/*
 * make0sort() - reorder TARGETS chain by their time (newest to oldest)
 */

static TARGETS *
make0sort( TARGETS *chain )
{
	TARGETS *result = 0;

	/* We walk chain, taking each item and inserting it on the */
	/* sorted result, with newest items at the front.  This involves */
	/* updating each TARGETS' c->next and c->tail.  Note that we */
	/* make c->tail a valid prev pointer for every entry.  Normally, */
	/* it is only valid at the head, where prev == tail.  Note also */
	/* that while tail is a loop, next ends at the end of the chain. */

	/* Walk current target list */

	while( chain )
	{
		TARGETS *c = chain;
		TARGETS *s = result;

		chain = chain->next;

	    /* Find point s in result for c */

		while( s && s->target->time > c->target->time )
			s = s->next;

	    /* Insert c in front of s (might be 0). */
	    /* Don't even think of deciphering this. */

		c->next = s;			/* good even if s = 0 */
		if( result == s ) result = c;	/* new head of chain? */
		if( !s ) s = result;		/* wrap to ensure a next */
		if( result != c ) s->tail->next = c; /* not head? be prev's next */
		c->tail = s->tail;			/* take on next's prev */
		s->tail = c;			/* make next's prev us */
	}

	return result;
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT
/*
 * make0sortbyname() - reorder TARGETS chain by their filenames - used to make reliable md5sums
 */

TARGETS *
make0sortbyname( TARGETS *chain )
{
	TARGETS *result = 0;

	/* We walk chain, taking each item and inserting it on the */
	/* sorted result, with newest items at the front.  This involves */
	/* updating each TARGETS' c->next and c->tail.  Note that we */
	/* make c->tail a valid prev pointer for every entry.  Normally, */
	/* it is only valid at the head, where prev == tail.  Note also */
	/* that while tail is a loop, next ends at the end of the chain. */

	/* Walk current target list */

	while( chain )
	{
		TARGETS *c = chain;
		TARGETS *s = result;

		chain = chain->next;

		/* Find point s in result for c */

		while( s && ( strcmp( s->target->name, c->target->name ) < 0 ) )
			s = s->next;

		/* Insert c in front of s (might be 0). */
		/* Don't even think of deciphering this. */

		c->next = s;   /* good even if s = 0 */
		if( result == s ) result = c; /* new head of chain? */
		if( !s ) s = result;  /* wrap to ensure a next */
		if( result != c ) s->tail->next = c; /* not head? be prev's next */
		c->tail = s->tail;   /* take on next's prev */
		s->tail = c;   /* make next's prev us */
	}

	return result;
}

int make0calcmd5sum_epoch = -1000000000;
int make0calcmd5sum_timestamp_epoch = -1000000000;
int make0calcmd5sum_dependssorted_stage = 0;

int make0recurseincludes_epoch = -1000000000;

static void make0recurseincludesmd5sum( XXH3_state_t *state, TARGET *t, int depth )
{
	TARGETS *c;

	if ( t->dependssorted != make0calcmd5sum_dependssorted_stage )
	{
		//t->depends = make0sortbyname( t->depends );
		//t->dependssorted = make0calcmd5sum_dependssorted_stage;
	}

	for( c = t->depends; c; c = c->next )
	{
		if ( c->target->recurseincludesepoch == make0recurseincludes_epoch)
		{
			continue;
		}

		//c->target->epoch = make0calcmd5sum_epoch;
		c->target->recurseincludesepoch = make0recurseincludes_epoch;

		if( ( c->target->binding == T_BIND_UNBOUND /*|| c->target->time == 0*/ ) && !( c->target->flags & T_FLAG_NOTFILE )
				&& c->target->timestamp_epoch != make0calcmd5sum_timestamp_epoch )
		{
			c->target->timestamp_epoch = make0calcmd5sum_timestamp_epoch;
			pushsettings( c->target->settings );
			c->target->boundname = search( c->target->name, &c->target->time );
			popsettings( c->target->settings );
			c->target->binding = c->target->time ? T_BIND_EXISTS : T_BIND_MISSING;
		}
		if ( !( c->target->flags & T_FLAG_NOTFILE ) && !( c->target->flags & T_FLAG_INTERNAL ) && !( c->target->flags & T_FLAG_NOUPDATE ) )
		{
			getcachedmd5sum( c->target, 0 );
			if ( !( c->target->flags & T_FLAG_IGNORECONTENTS )  &&  c->target->contentchecksum  &&  !ismd5empty( c->target->contentchecksum->contentmd5sum ) )
			{
				XXH3_128bits_update( state, &c->target->contentchecksum->contentmd5sum, sizeof( c->target->contentchecksum->contentmd5sum ) );
				if( DEBUG_MD5HASH )
					printf( "\t\t%s%s: md5 %s\n", spaces( depth ), c->target->name, md5tostring( c->target->contentchecksum->contentmd5sum ) );
			}
		}

		/* add sum of your includes */
		if ( !c->target->includes && !( c->target->flags & T_FLAG_NOTFILE ) )
		{
			SETTINGS *s = copysettings( c->target->settings );
			pushsettings( s );
			headers( c->target );
			popsettings( s );
			freesettings( s );
		}

		if ( c->target->includes )
		{
			make0recurseincludesmd5sum( state, c->target->includes, depth + 1 );
		}
	}
}


/*
 * make0calcmd5sum() - calculate md5sum for a buildable target
 */
void make0calcmd5sum( TARGET *t, int source, int depth, int force )
{
	XXH3_state_t *state;
	TARGETS *c;

	if ( t->buildmd5sum_calculated && !force )
		return;

	if (t->calcchecksum_epoch == make0calcmd5sum_epoch)
	{
		return;
	}

	t->calcchecksum_epoch = make0calcmd5sum_epoch;

	if ( ( t->flags & T_FLAG_NOUPDATE ) || ( t->flags & T_FLAG_INTERNAL ) )
	{
		//memset( &t->buildmd5sum, 0, sizeof( t->buildmd5sum ) );
		//t->buildmd5sum_calculated = 1;
		return;
	}
	if ( ( t->flags & T_FLAG_NOTFILE ) )
	{
		//memset( &t->buildmd5sum, 0, sizeof( t->buildmd5sum ) );
		//return;
	}
	if ( !source )
	{
		//memset( &t->buildmd5sum, 0, sizeof( t->buildmd5sum ) );
		//t->buildmd5sum_calculated = 1;
		return;
	}

	getcachedmd5sum( t, 0 );

	//if ( !t->contentchecksum  ||  ismd5empty( t->contentchecksum->contentmd5sum ) )
	//{
		//memset( &t->buildmd5sum, 0, sizeof( t->buildmd5sum ) );
		//t->buildmd5sum_calculated = 0;
		//return;
	//}

	/* sort all dependents by name, so we can make reliable md5sums */
	if ( t->dependssorted != make0calcmd5sum_dependssorted_stage )
	{
		targetlist_free(t->dependssortedbyname);
		if (t->depends)
		{
			t->dependssortedbyname = copytargets((TARGETS *)0, t->depends);
			t->dependssortedbyname = make0sortbyname(t->dependssortedbyname);
		}
		t->dependssorted = make0calcmd5sum_dependssorted_stage;
	}

	state = XXH3_createState();
	XXH3_128bits_reset(state);

	/* add the path of the file to the sum - it is significant because one command can create more than one file */
	XXH3_128bits_update(state, (unsigned char*)t->name, (unsigned int)strlen( t->name ) );

	if( DEBUG_MD5HASH )
		printf( "\t\t%starget: %s\n", spaces( depth ), t->name );

    /* if this is a source */
	if (source  &&  !(t->flags & T_FLAG_IGNORECONTENTS))
	{
		/* start by adding your own content */
		if (t->contentchecksum  &&  !ismd5empty(t->contentchecksum->contentmd5sum))
		{
			XXH3_128bits_update(state, &t->contentchecksum->contentmd5sum, sizeof( t->contentchecksum->contentmd5sum ) );
			if( DEBUG_MD5HASH )
				printf( "\t\t%scontent: %s\n", spaces( depth ), md5tostring( t->contentchecksum->contentmd5sum ) );
		}
	}

    /* add in the COMMANDLINE */
	if ( t->flags & T_FLAG_USECOMMANDLINE )
	{
		SETTINGS *vars;
		for ( vars = t->settings; vars; vars = vars->next )
		{
			if ( vars->symbol[0] == 'C'  &&  strcmp( vars->symbol, "COMMANDLINE" ) == 0 )
			{
				LISTITEM *item;
				for ( item = list_first(vars->value); item; item = list_next(item) )
				{
					char const* str = list_value(item);
					XXH3_128bits_update(state, (unsigned char*)str, (unsigned int)strlen(str) );
					if( DEBUG_MD5HASH )
						printf( "\t\t%sCOMMANDLINE: %s\n", spaces( depth ), str );
				}

				break;
			}
		}
	}

	/* add sum of your includes */
	//if ( t->flags & T_FLAG_INTERNAL )
	//if (0)
	if ( !t->includes )
	{
		SETTINGS *s = copysettings( t->settings );
		pushsettings( s );
		headers( t );
		popsettings( s );
		freesettings( s );
	}

	if ( t->includes )
	{
		const char* includesStr = "#includes";
		XXH3_128bits_update(state, (unsigned char*)includesStr, (unsigned int)strlen( includesStr ) );

		if( DEBUG_MD5HASH )
			printf( "\t\t%s#includes:\n", spaces( depth ) );
		++make0recurseincludes_epoch;
		make0recurseincludesmd5sum( state, t->includes, depth + 1 );
	}

    /* for each of your dependencies */
	for( c = t->dependssortedbyname; c; c = c->next )
	{
		/* If this is a "Needs" dependency, don't care about its contents. */
		if (c->needs) //  ||  (t->flags & T_FLAG_MIGHTNOTUPDATE))
		{
			continue;
		}

		if (c->target->epoch == make0calcmd5sum_epoch)
		{
			continue;
		}
		make0calcmd5sum( c->target, 1, depth + 1, force );

		/* add name of the dependency and its contents */
		if ( c->target->buildmd5sum_calculated )
		{
			XXH3_128bits_update(state, (unsigned char*)c->target->name, (unsigned int)strlen( c->target->name ) );
			if ( !( c->target->flags & T_FLAG_FORCECONTENTSONLY ) )
			{
				XXH3_128bits_update(state, &c->target->buildmd5sum, sizeof( c->target->buildmd5sum ) );
				if( DEBUG_MD5HASH )
					printf( "\t\t%sdepends: %s %s\n", spaces( depth ), c->target->name, md5tostring( c->target->buildmd5sum ) );
			}
			else if ( !( c->target->flags & T_FLAG_IGNORECONTENTS )  &&  c->target->contentchecksum  &&  !ismd5empty( c->target->contentchecksum->contentmd5sum ) )
			{
				if( DEBUG_MD5HASH )
					printf( "\t\t%sdepends: %s %s\n", spaces( depth ), c->target->name, md5tostring( c->target->buildmd5sum ) );
				XXH3_128bits_update(state, &c->target->contentchecksum->contentmd5sum, sizeof( c->target->contentchecksum->contentmd5sum ) );
				if( DEBUG_MD5HASH )
					printf( "\t\t  %s%s: md5 %s\n", spaces( depth ), c->target->name, md5tostring( c->target->contentchecksum->contentmd5sum ) );
			}
		}
	}
	t->buildmd5sum = XXH3_128bits_digest(state);
	XXH3_freeState(state);
	if( DEBUG_MD5HASH ) {
		printf( "\t\t%sbuildmd5sum: %s (%s)\n", spaces( depth ), t->name, md5tostring(t->buildmd5sum));
	}

	t->buildmd5sum_calculated = 1;
}
#endif

#ifdef OPT_GRAPH_DEBUG_EXT

/*
 * dependGraphOutput() - output the DG after make0 has run
 */

static void
dependGraphOutputTimes( time_t time )
{
    printf( "(time:%d)\n", (int)time );
}

static void
dependGraphOutput( TARGET *t, int depth )
{
	TARGETS	*c;
	TARGET	*include;

	int internal = t->flags & T_FLAG_INTERNAL;

	if (   (t->flags & T_FLAG_VISITED) != 0
		|| !t->name
		|| !t->boundname)
		return;

	t->flags |= T_FLAG_VISITED;

	switch (t->fate)
	{
	case T_FATE_TOUCHED:
	case T_FATE_MISSING:
	case T_FATE_OUTDATED:
	case T_FATE_UPDATE:
		printf( "->" );
		break;
	default:
		printf( "  " );
		break;
	}

	if( internal )
		printf( "%s%2d Name: (internal) %s\n", spaces(depth), depth, t->name );
	else
		printf( "%s%2d Name: %s\n", spaces(depth), depth, t->name );

	if( strcmp (t->name, t->boundname) )
	{
		printf( "  %s    Loc: %s\n", spaces(depth), t->boundname );
	}

	switch( t->fate )
	{
		case T_FATE_STABLE:
			printf( "  %s   Fate: Stable\n", spaces(depth) );
			break;
		case T_FATE_NEWER:
			printf( "  %s   Fate: Newer\n", spaces(depth) );
			break;
		case T_FATE_ISTMP:
			printf( "  %s   Fate: Up to date temp file\n", spaces(depth) );
			break;
		case T_FATE_TOUCHED:
			printf( "  %s   Fate: Been touched, updating it\n", spaces(depth) );
			break;
		case T_FATE_MISSING:
			printf( "  %s   Fate: Missing, creating it\n", spaces(depth) );
			break;
		case T_FATE_OUTDATED:
			printf( "  %s   Fate: Outdated, updating it\n", spaces(depth) );
			break;
		case T_FATE_UPDATE:
			printf( "  %s   Fate: Updating it\n", spaces(depth) );
			break;
		case T_FATE_CANTFIND:
			printf( "  %s   Fate: Can't find it\n", spaces(depth) );
			break;
		case T_FATE_CANTMAKE:
			printf( "  %s   Fate: Can't make it\n", spaces(depth) );
			break;
	}

	printf( "  %s   Time: ", spaces(depth) );
	dependGraphOutputTimes( t->time );

	if( t->flags & ~T_FLAG_VISITED )
	{
		printf( "  %s  Flags: ", spaces(depth) );
		if( t->flags & T_FLAG_TEMP ) printf ("TEMPORARY ");
		if( t->flags & T_FLAG_NOCARE ) printf ("NOCARE ");
		if( t->flags & T_FLAG_FORCECARE ) printf ("FORCECARE ");
		if( t->flags & T_FLAG_NOTFILE ) printf ("NOTFILE ");
		if( t->flags & T_FLAG_TOUCHED ) printf ("TOUCHED ");
		if( t->flags & T_FLAG_LEAVES ) printf ("LEAVES ");
		if( t->flags & T_FLAG_NOUPDATE ) printf ("NOUPDATE ");
		if( t->flags & T_FLAG_INTERNAL ) printf ("INTERNAL ");
#ifdef OPT_BUILTIN_NEEDS_EXT
		if( t->flags & T_FLAG_MIGHTNOTUPDATE ) printf ("MIGHTNOTUPDATE ");
		if( t->flags & T_FLAG_SCANCONTENTS ) printf ("SCANCONTENTS ");
		if( t->flags & T_FLAG_IGNORECONTENTS ) printf ("IGNORECONTENTS ");
		if( t->flags & T_FLAG_FORCECONTENTSONLY ) printf ("FORCECONTENTSONLY ");
#endif
		printf( "\n" );
	}

	for( c = t->depends; c; c = c->next )
	{
		printf( "  %s       : %s %s%s (%s) ", spaces(depth),
           c->needs ? "Needs" : "Depends on", (c->target->flags & T_FLAG_INTERNAL) ? "(internal) " : "", c->target->name, target_fate[ c->target->fate ] );
		dependGraphOutputTimes( c->target->time );
	}

	include = t->includes;
	if( include )
	{
		printf( "  %s       : Includes %s (%s) ", spaces(depth),
			include->name, target_fate[ include->fate ] );
		dependGraphOutputTimes( include->time );
	}

	for( c = t->depends; c; c = c->next )
	{
		dependGraphOutput( c->target, depth + 1 );
	}

	if( include )
		dependGraphOutput( include, depth + 1 );
}

#endif

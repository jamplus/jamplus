/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * make1.c - execute command to bring targets up to date
 *
 * This module contains make1(), the entry point called by make() to
 * recursively decend the dependency graph executing update actions as
 * marked by make0().
 *
 * External routines:
 *
 *	make1() - execute commands to update a TARGET and all its dependents
 *
 * Internal routines, the recursive/asynchronous command executors:
 *
 *	make1a() - recursively traverse target tree, calling make1b()
 *	make1b() - dependents of target built, now build target with make1c()
 *	make1c() - launch target's next command, call make1b() when done
 *	make1d() - handle command execution completion and call back make1c()
 *
 * Internal support routines:
 *
 *	make1cmds() - turn ACTIONS into CMDs, grouping, splitting, etc
 *	make1list() - turn a list of targets into a LIST, for $(<) and $(>)
 * 	make1settings() - for vars that get bound, build up replacement lists
 * 	make1bind() - bind targets that weren't bound in dependency analysis
 *
 * 04/16/94 (seiwald) - Split from make.c.
 * 04/21/94 (seiwald) - Handle empty "updated" actions.
 * 05/04/94 (seiwald) - async multiprocess (-j) support
 * 06/01/94 (seiwald) - new 'actions existing' does existing sources
 * 12/20/94 (seiwald) - NOTIME renamed NOTFILE.
 * 01/19/95 (seiwald) - distinguish between CANTFIND/CANTMAKE targets.
 * 01/22/94 (seiwald) - pass per-target JAMSHELL down to execcmd().
 * 02/28/95 (seiwald) - Handle empty "existing" actions.
 * 03/10/95 (seiwald) - Fancy counts.
 * 02/07/01 (seiwald) - Fix jam -d0 return status.
 * 01/21/02 (seiwald) - new -q to quit quickly on build failure
 * 02/28/02 (seiwald) - don't delete 'actions updated' targets on failure
 * 02/28/02 (seiwald) - merge EXEC_xxx flags in with RULE_xxx
 * 07/17/02 (seiwald) - TEMPORARY sources for headers now get built
 * 09/23/02 (seiwald) - "...using temp..." only displayed on -da now.
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/03/02 (seiwald) - fix odd includes support by grafting them onto depends
 */

# include "jam.h"

# include "lists.h"
# include "parse.h"
# include "variable.h"
# include "rules.h"

# include "search.h"
# include "newstr.h"
# include "make.h"
# include "command.h"
# include "execcmd.h"
# include "filesys.h"
#ifdef OPT_IMPROVED_PROGRESS_EXT
#include "progress.h"
#endif
#ifdef OPT_BUILTIN_MD5CACHE_EXT
#ifndef NT
#include <unistd.h>
#endif
# include "md5.h"
# include "hcache.h"
# include "buffer.h"
#endif
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
# include "luasupport.h"
#endif

static void make1a( TARGET *t, TARGET *parent );
static void make1b( TARGET *t );
static void make1c( TARGET *t );
#ifdef OPT_SERIAL_OUTPUT_EXT
static void make1d( const char* outputname, void *closure, int status );
#else
static void make1d( void *closure, int status );
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
static CMD *make1cmds( TARGET *t, ACTIONS *a0 );
#else
static CMD *make1cmds( ACTIONS *a0 );
#endif
static LIST *make1list( LIST *l, TARGETS *targets, int flags );
#ifdef OPT_BUILTIN_MD5CACHE_EXT
static LIST *make1list_unbound( LIST *l, TARGETS *targets, int flags );
#endif
static SETTINGS *make1settings( LIST *vars );
static void make1bind( TARGET *t, int warn );
#ifdef OPT_ACTIONS_WAIT_FIX
static void make1wait( TARGET *t );
#endif
#ifdef OPT_SERIAL_OUTPUT_EXT
static int verifyIsRealOutput (char *input, int len);
#endif
#ifdef OPT_RESPONSE_FILES
static void printResponseFiles(CMD *cmd);
#endif

#ifdef OPT_MULTIPASS_EXT
extern LIST *queuedjamfiles;
#endif

/* Ugly static - it's too hard to carry it through the callbacks. */

static struct {
	int	failed;
	int	skipped;
	int	total;
	int	made;
} counts[1] ;

#ifdef OPT_BUILTIN_MD5CACHE_EXT

void read_md5sum( FILE *f, MD5SUM sum);
void write_md5sum( FILE *f, MD5SUM sum);
void write_string( FILE *f, const char *s );

#endif

#ifdef OPT_MULTIPASS_EXT
extern int actionpass;
#endif

/*
 * make1() - execute commands to update a TARGET and all its dependents
 */

#ifdef OPT_INTERRUPT_FIX
extern int intr;
#else
static int intr = 0;
#endif

int
make1( TARGET *t )
{
	memset( (char *)counts, 0, sizeof( *counts ) );

#ifdef OPT_SERIAL_OUTPUT_EXT
	exec_init();
#endif
	/* Recursively make the target and its dependents */

	make1a( t, (TARGET *)0 );

	/* Wait for any outstanding commands to finish running. */

	while( execwait() )
	    ;

#ifdef OPT_SERIAL_OUTPUT_EXT
	exec_done();
#endif
	/* Talk about it */

	if( DEBUG_MAKE && counts->failed )
	    printf( "*** failed updating %d target(s)...\n", counts->failed );

	if( DEBUG_MAKE && counts->skipped )
	    printf( "*** skipped %d target(s)...\n", counts->skipped );

	if( DEBUG_MAKE && counts->made )
	    printf( "*** updated %d target(s)...\n", counts->made );

	return counts->total != counts->made;
}

/*
 * make1a() - recursively traverse target tree, calling make1b()
 */

static void
make1a(
	TARGET	*t,
	TARGET	*parent )
{
	TARGETS	*c;

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	if (DEBUG_MAKE1) {
	    printf("make1\t--\t%s (parent %s)\n",
		   t->name, parent ? parent->name : "<nil>");
	}
#endif
	/* If the parent is the first to try to build this target */
	/* or this target is in the make1c() quagmire, arrange for the */
	/* parent to be notified when this target is built. */

	if( parent )
	    switch( t->progress )
	{
	case T_MAKE_INIT:
	case T_MAKE_ACTIVE:
	case T_MAKE_RUNNING:
#ifdef OPT_BUILTIN_NEEDS_EXT
	    t->parents = targetentry( t->parents, parent, 0 );
#else
	    t->parents = targetentry( t->parents, parent );
#endif
	    parent->asynccnt++;
	}

	if( t->progress != T_MAKE_INIT )
	    return;

	/* Asynccnt counts the dependents preventing this target from */
	/* proceeding to make1b() for actual building.  We start off with */
	/* a count of 1 to prevent anything from happening until we can */
	/* call all dependents.  This 1 is accounted for when we call */
	/* make1b() ourselves, below. */

	t->asynccnt = 1;

	/* Recurse on our dependents, manipulating progress to guard */
	/* against circular dependency. */

	t->progress = T_MAKE_ONSTACK;

	/* Recurse on "real" dependents. */
	for( c = t->depends; c && !intr; c = c->next )
	    make1a( c->target, t );

#ifdef OPT_UPDATED_CHILD_FIX
	{
	    ACTIONS *actions;
	    for( actions = t->actions; actions; actions = actions->next )
	    {
			TARGETS *targets;

#ifdef OPT_MULTIPASS_EXT
			if ( actions->action->pass != actionpass )
				continue;
#endif
			for( targets = actions->action->targets; targets; targets = targets->next )
			{
				if (targets->target != t)// && targets->target->progress<T_MAKE_ONSTACK)
				{
//					make1a( targets->target, t );
					for( c = targets->target->depends; c && !intr; c = c->next )
						make1a( c->target, t );
				}
			}
	    }
	}
#endif

	t->progress = T_MAKE_ACTIVE;

	/* Now that all dependents have bumped asynccnt, we now allow */
	/* decrement our reference to asynccnt. */

	make1b( t );
}

/*
 * make1b() - dependents of target built, now build target with make1c()
 */

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int  md5matchescommandline( TARGET *t );
#endif

static void
make1b( TARGET *t )
{
	TARGETS	*c;
	const char *failed;
#ifdef OPT_MULTIPASS_EXT
	int missing;
#endif
#ifdef OPT_BUILTIN_NEEDS_EXT
	int childmightnotupdate;
	int childscancontents;
	int childupdated;
#endif

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	if (DEBUG_MAKE1) {
	    printf( "make1b\t--\t%s (asynccnt %d)\n" ,
		    t->name, t->asynccnt);
	}
#endif
	/* If any dependents are still outstanding, wait until they */
	/* call make1b() to signal their completion. */

	if( --t->asynccnt )
	    return;

#ifdef OPT_INTERRUPT_FIX
	if( intr )
	    return;
#endif

	failed = "dependents";
#ifdef OPT_MULTIPASS_EXT
	missing = 0;
#endif
#ifdef OPT_BUILTIN_NEEDS_EXT
	childmightnotupdate = 0;
	childscancontents = 0;
	childupdated = 0;
#endif

#ifdef OPT_SEMAPHORE
	if( t->semaphore && t->semaphore->asynccnt )
	{
	    /* We can't launch yet.  Try again when the semaphore is free */
#ifdef OPT_BUILTIN_NEEDS_EXT
	    t->semaphore->parents = targetentry( t->semaphore->parents, t, 0 );
#else
	    t->semaphore->parents = targetentry( t->semaphore->parents, t );
#endif
	    t->asynccnt++;

	    if( DEBUG_EXECCMD )
		printf( "SEM: %s is busy, delaying launch of %s\n",
			t->semaphore->name, t->name);
	    return;
	}
#endif
	/* Now ready to build target 't'... if dependents built ok. */

	/* Collect status from dependents */

	for( c = t->depends; c; c = c->next ) {
	    if ( !(t->flags & T_FLAG_INTERNAL) && c->target->asynccnt ) {
//			printf("warning: Trying to build '%s' before dependent '%s' is done!\n", t->name, c->target->name);
		}
#ifdef OPT_BUILTIN_NEEDS_EXT
	    /* Only test a target's MightNotUpdate flag if the target's build was successful. */
	    if( c->target->status == EXEC_CMD_OK ) {
		/* Skip checking MightNotUpdate children if the target is bound to a missing file, */
		/* as in this case it should be built anyway */
		if ( c->target->flags & T_FLAG_MIGHTNOTUPDATE && t->binding != T_BIND_MISSING ) {
		    time_t timestamp;

		    /* Mark that we've seen a MightNotUpdate flag in this set of children. */
		    childmightnotupdate = 1;

		    /* Grab the generated target's timestamp. */
		    if ( file_time( c->target->boundname, &timestamp ) == 0 ) {
			/* If the child's timestamp is greater that the target's timestamp, then it updated. */
				if ( timestamp > t->time ) {
					if ( c->target->flags & T_FLAG_SCANCONTENTS ) {
						childscancontents = 1;
						if ( getcachedmd5sum( c->target, 1 ) )
							childupdated = 1;
					} else
						childupdated = 1;
				} else {
					childscancontents = 1;
				}
		    }
		}
		/* If it didn't have the MightNotUpdate flag but did update, mark it. */
		else if ( c->target->fate > T_FATE_STABLE  &&  !c->needs ) {
			if ( c->target->flags & T_FLAG_SCANCONTENTS ) {
				childscancontents = 1;
				if ( getcachedmd5sum( c->target, 1 ) )
					childupdated = 1;
			} else
				childupdated = 1;
		}
	    }
#endif

	    if( c->target->status > t->status )
	{
	    failed = c->target->name;
	    t->status = c->target->status;
#ifdef OPT_MULTIPASS_EXT
		if ( ( c->target->fate == T_FATE_MISSING  &&  ! ( c->target->flags & T_FLAG_NOCARE )  &&  !c->target->actions ) || t->status == EXEC_CMD_NEXTPASS )
		{
			missing = 1;
			if ( queuedjamfiles )
			{
				ACTIONS *actions;

				t->status = EXEC_CMD_NEXTPASS;

				for( actions = t->actions; actions; actions = actions->next )
				{
					actions->action->pass++;
				}
			}
		}
#endif
	}

#ifdef OPT_NOCARE_NODES_EXT
	/* CWM */
	/* If actions on deps have failed, but if this is a 'nocare' target */
	/* then continue anyway. */

	if( ( t->flags & T_FLAG_NOCARE ) && t->status == EXEC_CMD_FAIL )
	{
		printf( "...dependency on %s failed, but don't care...\n", t->name );
		t->status = EXEC_CMD_OK;
	}
#endif
	}

#ifdef OPT_BUILTIN_NEEDS_EXT
	/* If we found a MightNotUpdate flag and there was an update, mark the fate as updated. */
	if ( childmightnotupdate  &&  childupdated  &&  t->fate == T_FATE_STABLE )
	      t->fate = T_FATE_UPDATE;
	if ( childscancontents ) {
		if ( !childupdated ) {
			if ( t->includes ) {
				for( c = t->includes->depends; c; c = c->next ) {
					if ( c->target->fate > T_FATE_STABLE  &&  !c->needs ) {
						if ( c->target->flags & T_FLAG_SCANCONTENTS ) {
							if ( getcachedmd5sum( c->target, 1 )  ||  !md5matchescommandline( c->target ) ) {
								childupdated = 1;
								break;
							}
						} else {
							childupdated = 1;
							break;
						}
					}
				}
			}

			if ( !childupdated )
				t->fate = T_FATE_STABLE;
		} else if ( t->fate == T_FATE_STABLE )
			t->fate = T_FATE_UPDATE;
	}
	if ( t->fate == T_FATE_UPDATE  &&  !childupdated  &&  t->status != EXEC_CMD_NEXTPASS )
		if ( md5matchescommandline( t ) )
		    t->fate = T_FATE_STABLE;
	if ( t->flags & ( T_FLAG_MIGHTNOTUPDATE | T_FLAG_SCANCONTENTS )  &&  t->actions ) {
#ifdef OPT_ACTIONS_WAIT_FIX
	    /* See http://maillist.perforce.com/pipermail/jamming/2003-December/002252.html */
	    /* Determine if an action is already running on behalf of another target, and if so, */
	    /* bail out of make1b() prior to calling make1cmds() by adding more parents to the */
	    /* in-progress target and incrementing the asynccnt of the new target. */
	    make1wait( t );
	    if ( t->asynccnt != 0 )
		return;
#endif
	}
#endif

	/* If actions on deps have failed, bail. */
	/* Otherwise, execute all actions to make target */

#ifdef OPT_MULTIPASS_EXT
	if( t->status == EXEC_CMD_FAIL && t->actions && !missing )
#else
	if( t->status == EXEC_CMD_FAIL && t->actions )
#endif
	{
	    ++counts->skipped;
	    printf( "*** skipped %s for lack of %s...\n", t->name, failed );
	}

	if( t->status == EXEC_CMD_OK )
	    switch( t->fate )
	{
	case T_FATE_INIT:
	case T_FATE_MAKING:
	    /* shouldn't happen */

	case T_FATE_STABLE:
	case T_FATE_NEWER:
	    break;

	case T_FATE_CANTFIND:
	case T_FATE_CANTMAKE:
	    t->status = EXEC_CMD_FAIL;
	    break;

	case T_FATE_ISTMP:
	    if( DEBUG_MAKEQ )
		printf( "*** using %s...\n", t->name );
	    break;

	case T_FATE_TOUCHED:
	case T_FATE_MISSING:
	case T_FATE_NEEDTMP:
	case T_FATE_OUTDATED:
	case T_FATE_UPDATE:
	    /* Set "on target" vars, build actions, unset vars */
	    /* Set "progress" so that make1c() counts this target among */
	    /* the successes/failures. */

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    if (DEBUG_MAKE1) {
		printf( "make1b\t--\t%s (has actions)\n" , t->name );
	    }
#endif
	    if( t->actions )
	    {
#ifdef OPT_ACTIONS_WAIT_FIX
		/* See http://maillist.perforce.com/pipermail/jamming/2003-December/002252.html */
		/* Determine if an action is already running on behalf of another target, and if so, */
		/* bail out of make1b() prior to calling make1cmds() by adding more parents to the */
		/* in-progress target and incrementing the asynccnt of the new target. */
		make1wait( t );
		if ( t->asynccnt != 0 )
		    return;
#endif
		++counts->total;

#ifndef OPT_IMPROVED_PROGRESS_EXT
		if( DEBUG_MAKE && !( counts->total % 100 ) )
		    printf( "*** on %dth target...\n", counts->total );
#else
		{
		    double est_remaining;

		    est_remaining =
			progress_update(globs.progress, counts->total);

		    if (est_remaining > 0) {
			int minutes = (int)est_remaining / 60;
			int seconds = (int)est_remaining % 60;

			if (minutes > 0 || seconds > 0) {
			    printf("*** completed %.0f%% (",
				   ((double)counts->total * 100 /
				    globs.updating));
			    if (minutes > 0)
				printf("%d min ", minutes);
			    if (seconds >= 0)
				printf("%d sec ", seconds);
			    printf("remaining)...\n");
			}
		    }
		}
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
		pushsettings( t->settings );
		filecache_fillvalues( t );
		popsettings( t->settings );
		t->cmds = (char *)make1cmds( t, t->actions );
#else
		pushsettings( t->settings );
		t->cmds = (char *)make1cmds( t->actions );
		popsettings( t->settings );
#endif

		t->progress = T_MAKE_RUNNING;
	    }

	    break;
	}

#ifdef OPT_SEMAPHORE
	/* If there is a semaphore, indicate that its in use */
	if( t->semaphore )
	{
	    ++(t->semaphore->asynccnt);

	    if( DEBUG_EXECCMD )
		printf( "SEM: %s now used by %s\n", t->semaphore->name,
		       t->name );
	}
#endif
	/* Call make1c() to begin the execution of the chain of commands */
	/* needed to build target.  If we're not going to build target */
	/* (because of dependency failures or because no commands need to */
	/* be run) the chain will be empty and make1c() will directly */
	/* signal the completion of target. */

	make1c( t );
}

/*
 * make1c() - launch target's next command, call make1b() when done
 */

static void
make1c( TARGET *t )
{
	CMD	*cmd = (CMD *)t->cmds;

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	if (DEBUG_MAKE1) {
	    printf( "make1c\t--\t%s (status %d)\n" ,
		    t->name, t->status );
	}
#endif
	/* If there are (more) commands to run to build this target */
	/* (and we haven't hit an error running earlier comands) we */
	/* launch the command with execcmd(). */

	/* If there are no more commands to run, we collect the status */
	/* from all the actions then report our completion to all the */
	/* parents. */

	if( cmd && t->status == EXEC_CMD_OK )
	{
#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    if (DEBUG_MAKE1) {
		printf( "make1c\t--\t%s (more to do)\n" ,
			t->name );
	    }
#endif
#ifndef OPT_SERIAL_OUTPUT_EXT
	    if( DEBUG_MAKE )
		if( DEBUG_MAKEQ || ! ( cmd->rule->flags & RULE_QUIETLY ) )
	    {
#ifdef OPT_PERCENT_DONE_EXT
		/* CWM - added '@' and %done to front of output */
		int done = counts->skipped + counts->failed + counts->made;
		float percent = (done * 99.0f) / globs.updating;
		printf( "@ %2.0f%% %s ", percent, cmd->rule->name );
#else
		/* CWM - added '@' to front of output */
		printf( "@ %s ", cmd->rule->name );
#endif
#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
		if (globs.printtarget) {
		    printf("%s ", t->name);
		} else {
		    list_print( lol_get( &cmd->args, 0 ) );
		}
#else
		list_print( lol_get( &cmd->args, 0 ) );
#endif
		printf( "\n" );
	    }

	    if( DEBUG_EXEC )
		printf( "%s\n", buffer_ptr( &cmd->commandbuff ) );
#endif /* !OPT_SERIAL_OUTPUT_EXT */
#ifdef OPT_RESPONSE_FILES
	    if (DEBUG_EXEC)
	    {
		printResponseFiles(cmd);
	    }
#endif

	    if( globs.cmdout )
		fprintf( globs.cmdout, "%s", buffer_ptr(&cmd->commandbuff) );

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	    if ( cmd->rule->flags & RULE_LUA )
	    {
		execlua( cmd->luastring, make1d, t );
	    }
	    else
#endif
#ifdef OPT_ACTIONS_DUMP_TEXT_EXT
	    if (cmd->rule->flags & RULE_WRITEFILE)
	    {
#ifdef OPT_SERIAL_OUTPUT_EXT
		make1d( 0, t, EXEC_CMD_OK );
#else
		make1d( t, EXEC_CMD_OK );
#endif
	    }
	    else
#endif
	    if( globs.noexec )
	    {
#ifdef OPT_SERIAL_OUTPUT_EXT
		make1d( 0, t, EXEC_CMD_OK );
#else
		make1d( t, EXEC_CMD_OK );
#endif
	    }
	    else
	    {
		fflush( stdout );
		execcmd( buffer_ptr(&cmd->commandbuff), make1d, t, cmd->shell, (cmd->rule->flags & RULE_SCREENOUTPUT) == 0 );
	    }
	}
	else
	{
	    TARGETS	*c;
	    ACTIONS	*actions;

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    if (DEBUG_MAKE1) {
		printf( "make1c\t--\t%s (no more to do)\n" ,
			t->name );
	    }
#endif
	    /* Collect status from actions, and distribute it as well */

#ifdef OPT_MULTIPASS_EXT
		{
			int previousPassStatus = -1;
			int currentPassStatus = -1;
			for( actions = t->actions; actions; actions = actions->next )
				if( actions->action->pass < actionpass  &&  actions->action->status > previousPassStatus )
					previousPassStatus = actions->action->status;

			for( actions = t->actions; actions; actions = actions->next )
				if( actions->action->pass == actionpass  &&  actions->action->status > currentPassStatus )
					currentPassStatus = actions->action->status;

			if (currentPassStatus == -1  &&  previousPassStatus != -1)
				t->status = previousPassStatus;
			else if (currentPassStatus != -1  &&  currentPassStatus > t->status)
				t->status = currentPassStatus;

		    for( actions = t->actions; actions; actions = actions->next )
				if( actions->action->pass == actionpass  &&  t->status > actions->action->status )
				    actions->action->status = t->status;
		}
#else
	    for( actions = t->actions; actions; actions = actions->next )
		if( actions->action->status > t->status )
		    t->status = actions->action->status;

	    for( actions = t->actions; actions; actions = actions->next )
		if( t->status > actions->action->status )
		    actions->action->status = t->status;

#endif

#ifdef OPT_MULTIPASS_EXT
		if ( t->fate == T_FATE_MISSING  &&  !( t->flags & T_FLAG_NOCARE )  &&  !t->actions  &&  queuedjamfiles )
		{
			t->status = EXEC_CMD_NEXTPASS;
		}
#endif

	    /* Tally success/failure for those we tried to update. */

	    if( t->progress == T_MAKE_RUNNING )
		switch( t->status )
	    {
	    case EXEC_CMD_OK:
		++counts->made;
		break;
	    case EXEC_CMD_FAIL:
		++counts->failed;
		break;
	    }

	    /* Tell parents dependent has been built */

	    t->progress = T_MAKE_DONE;

#ifdef OPT_BUILTIN_MD5CACHE_EXT
	    /* Update the file cache. */
	    if ( t->flags & T_FLAG_USECOMMANDLINE )
		hcache_finalizerulemd5sum( t );
#endif

#ifdef OPT_SEMAPHORE
	    /* If there is a semaphore, its now free */
	    if( t->semaphore )
	    {
		--(t->semaphore->asynccnt);

		if( DEBUG_EXECCMD )
		    printf( "SEM: %s is now free\n", t->semaphore->name);

		/* If anything is waiting, notify the next target */
		if( t->semaphore->parents )
		{
		    TARGETS *first = t->semaphore->parents;
		    if( first->next )
			first->next->tail = first->tail;
		    t->semaphore->parents = first->next;

		    if( DEBUG_EXECCMD )
			printf( "SEM: now launching %s\n", first->target->name);
		    make1b( first->target );
#ifndef OPT_IMPROVED_MEMUSE_EXT
		    free( first );
#endif
		}
	    }
#endif
	    for( c = t->parents; c; c = c->next )
		make1b( c->target );
	}
}

/*
 * make1d() - handle command execution completion and call back make1c()
 */

#ifdef OPT_LINE_FILTER_SUPPORT
int lineBufferInitialized = 0;
BUFFER lineBuffer;
#endif /* OPT_LINE_FILTER_SUPPORT */

static void
make1d(
#ifdef OPT_SERIAL_OUTPUT_EXT
	const char*	outputname,
#endif
	void	*closure,
	int	status )
{
	TARGET	*t = (TARGET *)closure;
	CMD	*cmd = (CMD *)t->cmds;

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	if (DEBUG_MAKE1) {
	    printf( "make1d\t--\t%s\n" ,
		    t->name );
	}
#endif
	/* Execcmd() has completed.  All we need to do is fiddle with the */
	/* status and signal our completion so make1c() can run the next */
	/* command.  On interrupts, we bail heavily. */

	if( status == EXEC_CMD_FAIL && ( cmd->rule->flags & RULE_IGNORE ) )
	    status = EXEC_CMD_OK;

	/* On interrupt, set intr so _everything_ fails */

	if( status == EXEC_CMD_INTR )
	    ++intr;

#ifndef OPT_SERIAL_OUTPUT_EXT
	if( status == EXEC_CMD_FAIL && DEBUG_MAKE )
	{
	    /* Print command text on failure */

	    if( !DEBUG_EXEC )
		printf( "%s\n", buffer_ptr( &cmd->commandbuff ) );
#ifdef OPT_RESPONSE_FILES
	    if (!DEBUG_EXEC)
	    {
		printResponseFiles(cmd);
	    }
#endif

	    printf( "*** failed %s ", cmd->rule->name );
	    list_print( lol_get( &cmd->args, 0 ) );
	    printf( "...\n" );

	    if( globs.quitquick ) ++intr;
	}
#else
	if( DEBUG_MAKE )
	{
	    if( DEBUG_MAKEQ || ! ( cmd->rule->flags & RULE_QUIETLY ) )
	    {
#ifdef OPT_PERCENT_DONE_EXT
		    /* CWM - added '@' and %done to front of output */
		    int done = counts->skipped + counts->failed + counts->made;
		    float percent = (done * 99.0f) / globs.updating;
		    printf( "@ %2.0f%% %s ", percent, cmd->rule->name );
#else
		    /* CWM - Added '@' to front of output */
			printf( "@ %s ", cmd->rule->name );
#endif
#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
		if (globs.printtarget) {
		    printf("%s ", t->name);
		} else {
		    list_print( lol_get( &cmd->args, 0 ) );
		}
#else
		list_print( lol_get( &cmd->args, 0 ) );
#endif
		printf( "\n" );
	    }
	}

	if( DEBUG_EXEC || (status == EXEC_CMD_FAIL && DEBUG_MAKE) )
	{
	    printf( "%s\n", buffer_ptr(&cmd->commandbuff) );
#ifdef OPT_RESPONSE_FILES
	    printResponseFiles(cmd);
#endif
	}

	/* Print the output now, if there was any */
	if( outputname )
	{
		FILE		*fp;
#ifdef OPT_LINE_FILTER_SUPPORT
		size_t		n = 1;

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		LIST*		useLuaLineFilters;

		useLuaLineFilters = var_get( "USE_LUA_LINE_FILTERS" );
		if ( list_first(useLuaLineFilters) )
		{
			if ( ( strcmp( list_value(list_first(useLuaLineFilters)), "1" ) != 0  &&  strcmp( list_value(list_first(useLuaLineFilters)), "true" ) != 0)
					||  !luahelper_push_linefilter( cmd->rule->name ) )
			{
				useLuaLineFilters = NULL;
			}
		}
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */

		if ( !lineBufferInitialized )
		{
			buffer_init( &lineBuffer );
			lineBufferInitialized = 1;
		}
		buffer_reset( &lineBuffer );

		fp = fopen( outputname, "r" );
		if ( fp )
		{
			while ( n > 0 )
			{
				char* startPtr;
				char* ptr;
				n = fread( buffer_posptr( &lineBuffer ), sizeof(char), buffer_size( &lineBuffer ) - buffer_pos( &lineBuffer ), fp);
				buffer_deltapos( &lineBuffer, n );
				startPtr = ptr = buffer_ptr( &lineBuffer );
				while ( 1 )
				{
					int count;
					while ( ptr != buffer_posptr( &lineBuffer )  &&  *ptr != '\n' )
					{
						++ptr;
					}
					count = ptr - startPtr;
					if ( count == 0 )
					{
						buffer_reset( &lineBuffer );
						break;
					}
					if ( *ptr != '\n' )
					{
						memcpy( buffer_ptr( &lineBuffer ), startPtr, count );
						buffer_setpos( &lineBuffer, count );
						break;
					}
					else
					{
						++ptr;
						++count;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
						if ( useLuaLineFilters )
						{
							const char* line = luahelper_linefilter( startPtr, count );
							if ( line )
							{
								fwrite( line, sizeof( char ), strlen( line ), stdout );
								free( (void*)line );
							}
						}
						else
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */
						{
							fwrite( startPtr, sizeof(char), count, stdout );
						}
						startPtr = ptr;
					}
				}
				if ( buffer_pos( &lineBuffer ) == buffer_size( &lineBuffer ) )
				{
					buffer_openspace( &lineBuffer, buffer_size( &lineBuffer ) + BUFFER_STATIC_SIZE );
				}
			}
			if ( buffer_pos( &lineBuffer ) > 0 )
			{
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
				if ( useLuaLineFilters )
				{
					const char* line = luahelper_linefilter( buffer_ptr( &lineBuffer ), buffer_pos( &lineBuffer ) );
					if ( line )
					{
						fwrite( line, sizeof( char ), strlen( line ), stdout );
						free( (void*)line );
					}
				}
				else
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */
				{
					fwrite( buffer_ptr( &lineBuffer ), sizeof(char), buffer_pos( &lineBuffer ), stdout );
				}
			}

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
			if ( useLuaLineFilters )
			{
				luahelper_pop_linefilter();
			}
#endif /* OPT_BUILTIN_LUA_SUPPORT_EXT */

			fclose(fp);
		}
#else
		size_t		n;
		char		buf[4096];

		fp = fopen( outputname, "r" );
		if (fp)
		{
			n = fread(buf, sizeof(char), sizeof buf, fp);
//			if (verifyIsRealOutput (buf, n))
			{
				fwrite(buf, sizeof(char), n, stdout);
				n = fread(buf, sizeof(char), sizeof buf, fp);
				while (n > 0)
				{
					fwrite(buf, sizeof(char), n, stdout);
					n = fread(buf, sizeof(char), sizeof buf, fp);
				}
			}
			fclose(fp);
		}
#endif /* OPT_LINE_FILTER_SUPPORT */
	}

	if( status == EXEC_CMD_FAIL && DEBUG_MAKE )
	{
	    printf( "*** failed %s ", cmd->rule->name );
#ifdef OPT_DEBUG_MAKE_PRINT_TARGET_NAME
	    if (globs.printtarget) {
		printf("%s ", t->name);
	    } else {
		list_print( lol_get( &cmd->args, 0 ) );
	    }
#else
	    list_print( lol_get( &cmd->args, 0 ) );
#endif
	    printf( "...\n" );

	    if (globs.quitquick)
	    {
		++intr;
	    }
	}
#endif /* OPT_SERIAL_OUTPUT_EXT */

	/* If the command was interrupted or failed and the target */
	/* is not "precious", remove the targets. */
	/* Precious == 'actions updated' -- the target maintains state. */

	if( status != EXEC_CMD_OK )
	{
		if ( !( cmd->rule->flags & RULE_UPDATED ) ) {
	    LIST *targets = lol_get( &cmd->args, 0 );
	    LISTITEM* target;

#ifdef OPT_NODELETE_READONLY
	    for(target = list_first(targets) ; target; target = list_next(target) )
		if( file_writeable(list_value(target)) &&
		    !unlink(list_value(target)) )
		    printf( "*** removing %s\n", list_value(target) );
#else
	    for(target = list_first(targets) ; target; target = list_next( target ) )
		if( !unlink( list_value(target) ) )
		    printf( "*** removing %s\n", list_value(target) );
#endif
	}
	}
#ifdef OPT_BUILTIN_MD5CACHE_EXT
	else
	{
		LISTITEM* target;
	    LIST *targets = lol_get( &cmd->args, 0 );

	    for(target = list_first(targets) ; target; target = list_next( target ) )
	    {
		TARGET *t = bindtarget( list_value(target) );
		filecache_update( t );
	    }
	}
#endif

	/* Free this command and call make1c() to move onto next command. */

	t->status = (char)status;
	t->cmds = (char *)cmd_next( cmd );

	cmd_free( cmd );

	make1c( t );
}

/*
 * make1cmds() - turn ACTIONS into CMDs, grouping, splitting, etc
 *
 * Essentially copies a chain of ACTIONs to a chain of CMDs,
 * grouping RULE_TOGETHER actions, splitting RULE_PIECEMEAL actions,
 * and handling RULE_UPDATED actions.  The result is a chain of
 * CMDs which can be expanded by var_string() and executed with
 * execcmd().
 */

#ifdef OPT_BUILTIN_MD5CACHE_EXT
TARGETS *
make0sortbyname( TARGETS *chain );

void make0calcmd5sum( TARGET *t, int source );
#endif


#ifdef OPT_REMOVE_EMPTY_DIRS_EXT
extern LIST* emptydirtargets;
#endif


#ifdef OPT_BUILTIN_MD5CACHE_EXT
static CMD *
make1cmds( TARGET *t, ACTIONS *a0 )
#else
static CMD *
make1cmds( ACTIONS *a0 )
#endif
{
	CMD *cmds = 0;
	LIST *shell = var_get( "JAMSHELL" );	/* shell is per-target */

	/* Step through actions */
	/* Actions may be shared with other targets or grouped with */
	/* RULE_TOGETHER, so actions already seen are skipped. */

	for( ; a0; a0 = a0->next )
	{
	    RULE    *rule = a0->action->rule;
	    SETTINGS *boundvars;
	    LIST    *nt, *ns;
	    ACTIONS *a1;
	    int	    start, chunk, length, maxline;
		TARGETS *autosettingsreverse = 0;
		TARGETS *autot;

#ifdef OPT_MULTIPASS_EXT
	    if ( a0->action->pass != actionpass )
		continue;
#endif

	    /* Only do rules with commands to execute. */
	    /* If this action has already been executed, use saved status */

#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    if (DEBUG_MAKE1) {
		printf( "make1cmds\t--\t%s (actions %s, running %s)\n" ,
			rule->name,
			rule->actions ? "yes" : "no",
			a0->action->running ? "yes" : "no" );
	    }
#endif
	    if( !rule->actions || a0->action->running )
		continue;

#ifdef OPT_REMOVE_EMPTY_DIRS_EXT
		if ( rule->flags & RULE_REMOVEEMPTYDIRS ) {
			for( a1 = a0; a1; a1 = a1->next ) {
				TARGETS* sources;
				for ( sources = a1->action->sources; sources; sources = sources->next ) {
					emptydirtargets = list_append( emptydirtargets, sources->target->name, 1 );
				}
			}
		}
#endif

		for ( autot = a0->action->autosettings; autot; autot = autot->next ) {
			if ( autot->target != t )
				pushsettings( autot->target->settings );
			autosettingsreverse = targetentryhead( autosettingsreverse, autot->target, 0 );
		}
		pushsettings( t->settings );
	    a0->action->running = 1;
#ifdef OPT_ACTIONS_WAIT_FIX
	    a0->action->run_tgt = t;
#endif

	    /* Make LISTS of targets and sources */
	    /* If `execute together` has been specified for this rule, tack */
	    /* on sources from each instance of this rule for this target. */
#ifdef OPT_DEBUG_MAKE1_LOG_EXT
	    if (DEBUG_MAKE1) {
		LIST *list = make1list(L0, a0->action->targets, 0);
		printf("make1cmds\t--\ttargets: ");
		list_print(list);
		list_free(list);
		printf("\n");
		list = make1list(L0, a0->action->sources, 0);
		printf("make1cmds\t--\tsources: ");
		list_print(list);
		list_free(list);
		printf("\n");
	    }
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
	    if (t->filecache_generate  ||  t->filecache_use)
	    {
		LIST* targets = make1list_unbound( L0, a0->action->targets, 0 );
		LIST* sources = make1list_unbound( L0, a0->action->sources, rule->flags );

		nt = L0;
		ns = L0;

		if ( strncmp( rule->name, "batched_", 8 ) == 0 )
		{
		    int anycacheable = 0;
			LISTITEM* target = list_first(targets);
			LISTITEM* source = list_first(sources);
		    for( ; target; target = list_next(target), source = ( source == NULL ? source : list_next(source) ) )
		    {
			TARGET *t = bindtarget(list_value(target));
			TARGET *s = source!=NULL ? bindtarget(list_value(source)) : NULL;

			/* if this target could be cacheable */
			if ( (t->flags & T_FLAG_USEFILECACHE) && (t->filecache_generate  ||  t->filecache_use) ) {
			    /* find its final md5sum */
			    MD5_CTX context;
			    MD5SUM buildsumorg;
			    anycacheable = 1;
			    memcpy(&buildsumorg, &t->buildmd5sum, sizeof(t->buildmd5sum));
			    MD5Init( &context );
			    MD5Update( &context, t->buildmd5sum, sizeof( t->buildmd5sum ) );
			    {
				TARGET *outt = bindtarget( t->boundname );
				outt->flags |= T_FLAG_USEFILECACHE;
				MD5Final( outt->buildmd5sum, &context );
				memcpy(&t->buildmd5sum, &outt->buildmd5sum, sizeof(t->buildmd5sum));
			    }
			    if (DEBUG_MD5HASH) {
				printf( "Cacheable: %s buildmd5: %s org: %s\n",
				    t->boundname, md5tostring(t->buildmd5sum), md5tostring(buildsumorg) );
			    }

			    /* if using cache is allowed */
			    if (t->filecache_use) {
				const char *cachedname;

				/* if the target is available in the cache */
				cachedname = filecache_getfilename(t, t->buildmd5sum, ".doesntwork");
				if (cachedname!=NULL) {
				    time_t cachedtime;
				    if ( file_time( cachedname, &cachedtime ) == 0 )
				    {
					/* try to get it from the cache */
					if (copyfile(t->boundname, cachedname, NULL)) {
					    printf( "Using cached %s\n", t->name );
					    continue;
					} else {
					    printf( "Cannot retrieve %s from cache (will build normally)\n", t->name );
					}
				    } else {
					if( DEBUG_MD5HASH) {
					    printf( "Cannot find %s in cache as %s\n", t->name, cachedname );
					}
				    }
				}
			    }
			    /* Build new lists */

			    nt = list_append( nt, t->boundname, 1 );
			    if (s)
				ns = list_append( ns, s->boundname, 1 );
			}
		    }

		    if ( !anycacheable ) {
			nt = make1list( L0, a0->action->targets, 0 );
			ns = make1list( L0, a0->action->sources, rule->flags );
		    }
		}
		else
		{
		    int allcached = 1;
		    LISTITEM* target;
		    popsettings( t->settings );
		    for(target = list_first(targets) ; target; target = list_next(target) )
		    {
			TARGET *t = bindtarget(list_value(target));
//			TARGET *s = sources!=NULL ? bindtarget(sources->string) : NULL;
			TARGETS *c;
			TARGET *outt;
			LIST *filecache = 0;

			if ( t->flags & T_FLAG_USEFILECACHE )
			{
			    pushsettings( t->settings );
			    filecache = filecache_fillvalues( t );
			    popsettings( t->settings );
			}

			/* if this target could be cacheable */
			if ( (t->flags & T_FLAG_USEFILECACHE) && (t->filecache_generate  ||  t->filecache_use) ) {
			    /* find its final md5sum */
			    MD5_CTX context;

			    if( DEBUG_MD5HASH ) {
				printf( "------------------------------------------------\n" );
				printf( "------------------------------------------------\n" );
				printf( "------------------------------------------------\n" );
			    }

			    /* sort all dependents by name, so we can make reliable md5sums */
			    t->depends = make0sortbyname( t->depends );

			    MD5Init( &context );

			    /* add the path of the file to the sum - it is significant because one command can create more than one file */
			    MD5Update( &context, (unsigned char*)t->name, (unsigned int)strlen( t->name ) );

			    /* add in the COMMANDLINE */
			    if ( t->flags & T_FLAG_USECOMMANDLINE )
			    {
				SETTINGS *vars;
				for ( vars = t->settings; vars; vars = vars->next )
				{
				    if ( vars->symbol[0] == 'C'  &&  strcmp( vars->symbol, "COMMANDLINE" ) == 0 )
				    {
					LISTITEM *list;
					for ( list = list_first(vars->value); list; list = list_next(list) )
					{
					    MD5Update( &context, (unsigned char*)list_value(list), (unsigned int)strlen( list_value(list) ) );
					    if( DEBUG_MD5HASH )
						printf( "\t\tCOMMANDLINE: %s\n", list_value(list) );
					}

					break;
				    }
				}
			    }

			    /* for each dependencies */
			    for( c = t->depends; c; c = c->next )
			    {
				/* If this is a "Needs" dependency, don't care about its contents. */
				if (c->needs)
				{
				    continue;
				}

				/* add name of the dependency and its contents */
				make0calcmd5sum( c->target, 1 );
				if ( c->target->buildmd5sum_calculated )
				{
				    MD5Update( &context, (unsigned char*)c->target->name, (unsigned int)strlen( c->target->name ) );
				    MD5Update( &context, c->target->buildmd5sum, sizeof( c->target->buildmd5sum ) );
				}
			    }

			    outt = bindtarget( t->boundname );
			    outt->flags |= T_FLAG_USEFILECACHE;
			    outt->filecache_generate = t->filecache_generate;
			    outt->filecache_use = t->filecache_use;
			    outt->settings = addsettings( outt->settings, VAR_SET, "FILECACHE", list_append( L0, list_value(list_first(filecache)), 1 ) );
			    MD5Final( outt->buildmd5sum, &context );
			    if (DEBUG_MD5HASH)
			    {
				printf( "Cacheable: %s buildmd5: %s\n", t->boundname, md5tostring(outt->buildmd5sum) );
			    }

			    /* if using cache is allowed */
			    if ( t->filecache_use  &&  allcached )
			    {
				allcached = filecache_retrieve( t, outt->buildmd5sum );
			    }
			    else
			    {
				allcached = 0;
			    }
			}
			else
			{
			    allcached = 0;
			}
		    }
		    pushsettings( t->settings );

		    if ( !allcached ) {
			nt = make1list( L0, a0->action->targets, 0 );
			ns = make1list( L0, a0->action->sources, rule->flags );
		    }
		}
		list_free( targets );
		list_free( sources );

		/* if no targets survived (all were retrieved from the cache)
		or no sources survived (all are up to date) */
		if (nt==NULL) { // || ns==NULL) {
		    /* skip this action */
		    list_free(ns);
			popsettings( t->settings );
			for ( autot = autosettingsreverse; autot; autot = autot->next ) {
				if ( autot->target != t )
					pushsettings( autot->target->settings );
			}
		    continue;
		}
	    }
	    else
	    {
#if 0
		if ( strncmp( rule->name, "batched_", 8 ) == 0 )
		{
			TARGETS* targets = a0->action->targets;
			TARGETS* sources = a0->action->sources;
		    int anycacheable = 0;

			nt = L0;
			ns = L0;

			/* walk sources and targets simultaneously */
			for( ; targets; targets = targets->next, sources = (sources==NULL?sources:sources->next) )
			{
				TARGET *t = targets->target;
				TARGET *s = sources!=NULL ? sources->target : NULL;

				/* Sources to 'actions existing' are never in the dependency */
				/* graph (if they were, they'd get built and 'existing' would */
				/* be superfluous, so throttle warning message about independent */
				/* targets. */

				if( t->binding == T_BIND_UNBOUND )
					make1bind( t, 0 );
				if( s!=NULL) {
					if ( s->binding == T_BIND_UNBOUND )
						make1bind( s, !( rule->flags & RULE_EXISTING ) );
					if ( s->binding == T_BIND_UNBOUND )
						printf("Warning using unbound source %s for batched action.\n", s->name);
				}


				if( ( rule->flags & RULE_EXISTING ) && s!=NULL && s->binding != T_BIND_EXISTS )
					continue;

				if( t->fate < T_FATE_BUILD )
					continue;

				/* Build new lists */

				nt = list_new( nt, t->boundname, 1 );
				if (s!=NULL) {
					ns = list_new( ns, s->boundname, 1 );
				}
			}

			if (sources!=NULL) {
				printf("warning: more sources than targets in a batched action!\n");
			}

		} else {
#endif
			nt = make1list( L0, a0->action->targets, 0 );
			ns = make1list( L0, a0->action->sources, rule->flags );
#if 0
	    }
#endif
		}
#else
	    nt = make1list( L0, a0->action->targets, 0 );
	    ns = make1list( L0, a0->action->sources, rule->flags );
#endif

	    if( rule->flags & RULE_TOGETHER )
		for( a1 = a0->next; a1; a1 = a1->next )
#ifdef OPT_MULTIPASS_EXT
		    if( a1->action->pass == actionpass && a1->action->rule == rule && !a1->action->running )
#else
		    if( a1->action->rule == rule && !a1->action->running )
#endif
	    {
		ns = make1list( ns, a1->action->sources, rule->flags );
		a1->action->running = 1;
#ifdef OPT_ACTIONS_WAIT_FIX
		a1->action->run_tgt = t;
#endif
	    }

	    /* If doing only updated (or existing) sources, but none have */
	    /* been updated (or exist), skip this action. */

	    if( !ns && ( rule->flags & ( RULE_UPDATED | RULE_EXISTING ) ) )
	    {
		list_free( nt );
#ifdef OPT_DEBUG_MAKE1_LOG_EXT
		if (DEBUG_MAKE1) {
		    const char* desc = 0;
		    if ((rule->flags & (RULE_UPDATED | RULE_EXISTING))
			== (RULE_UPDATED | RULE_EXISTING)) {
			desc = "updated/existing";
		    } else if (rule->flags & RULE_UPDATED) {
			desc = "updated";
		    } else if (rule->flags & RULE_EXISTING) {
			desc = "existing";
		    }
		    printf( "make1cmds\t--\t%s (skipping actions by %s)\n" ,
			    rule->name, desc );
		}
#endif /* OPT_DEBUG_MAKE1_LOG_EXT */
			popsettings( t->settings );
			for ( autot = autosettingsreverse; autot; autot = autot->next ) {
				if ( autot->target != t )
					pushsettings( autot->target->settings );
			}
		continue;
	    }

	    /* If we had 'actions xxx bind vars' we bind the vars now */

	    boundvars = make1settings( rule->bindlist );
	    pushsettings( boundvars );

	    /*
	     * Build command, starting with all source args.
	     *
	     * If cmd_new returns 0, it's because the resulting command
	     * length is > MAXLINE.  In this case, we'll slowly reduce
	     * the number of source arguments presented until it does
	     * fit.  This only applies to actions that allow PIECEMEAL
	     * commands.
	     *
	     * While reducing slowly takes a bit of compute time to get
	     * things just right, it's worth it to get as close to MAXLINE
	     * as possible, because launching the commands we're executing
	     * is likely to be much more compute intensive!
	     *
	     * Note we loop through at least once, for sourceless actions.
	     *
	     * Max line length is the action specific maxline or, if not
	     * given or bigger than MAXLINE, MAXLINE.
	     */

	    start = 0;
	    chunk = length = list_length( ns );
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
	    maxline = rule->maxline;
/* commented so jamgram.y can compile #else
	    maxline = rule->flags / RULE_MAXLINE;
#endif */
#ifdef OPT_PIECEMEAL_PUNT_EXT
	    maxline = maxline && maxline < CMDBUF ? maxline : CMDBUF;
#else
	    maxline = maxline && maxline < MAXLINE ? maxline : MAXLINE;
#endif

	    do
	    {
		/* Build cmd: cmd_new consumes its lists. */
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
		int thischunk = rule->maxtargets != 0 ? (chunk < rule->maxtargets ? chunk : rule->maxtargets) : chunk;

		CMD *cmd = cmd_new( rule,
			list_copy( L0, nt ),
			list_sublist( ns, start, thischunk ),
			list_copy( L0, shell ),
			maxline );
/* commented so jamgram.y can compile #else
		CMD *cmd = cmd_new( rule,
			list_copy( L0, nt ),
			list_sublist( ns, start, chunk ),
			list_copy( L0, shell ),
			maxline );
#endif */

		if( cmd )
		{
		    /* It fit: chain it up. */

		    if( !cmds ) cmds = cmd;
		    else cmds->tail->next = cmd;
		    cmds->tail = cmd;
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
		    start += thischunk;
/* commented out so jamgram.y can compile #else
		    start += chunk;
#endif */
		}
		else if( ( rule->flags & RULE_PIECEMEAL ) && chunk > 1 )
		{
		    /* Reduce chunk size slowly. */

		    chunk = chunk * 9 / 10;
		}
		else
		{
		    /* Too long and not splittable. */

#ifdef OPT_PIECEMEAL_PUNT_EXT
		    if (maxline < CMDBUF) {
			maxline = CMDBUF;
			continue;
		    }
#endif
		    printf( "%s actions too long (max %d)!\n",
			rule->name, maxline );
		    exit( EXITBAD );
		}
	    }
	    while( start < length );

	    /* These were always copied when used. */

	    list_free( nt );
	    list_free( ns );

	    /* Free the variables whose values were bound by */
	    /* 'actions xxx bind vars' */

	    popsettings( boundvars );
	    freesettings( boundvars );

		popsettings( t->settings );
		for ( autot = autosettingsreverse; autot; autot = autot->next ) {
			if ( autot->target != t )
				pushsettings( autot->target->settings );
		}
	}

	return cmds;
}

/*
 * make1list() - turn a list of targets into a LIST, for $(<) and $(>)
 */

static LIST *
make1list(
	LIST	*l,
	TARGETS	*targets,
	int	flags )
{
    for( ; targets; targets = targets->next )
    {
	TARGET *t = targets->target;

	/* Sources to 'actions existing' are never in the dependency */
	/* graph (if they were, they'd get built and 'existing' would */
	/* be superfluous, so throttle warning message about independent */
	/* targets. */

	if( t->binding == T_BIND_UNBOUND )
	    make1bind( t, !( flags & RULE_EXISTING ) );

	if( ( flags & RULE_EXISTING ) && t->binding != T_BIND_EXISTS )
	    continue;

#ifdef OPT_BUILTIN_MD5CACHE_EXT
	if( ( flags & RULE_UPDATED ) && t->fate <= T_FATE_STABLE && !targets->parentcommandlineoutofdate )
#else
	if( ( flags & RULE_UPDATED ) && t->fate <= T_FATE_STABLE )
#endif
	    continue;

	/* Prohibit duplicates for RULE_TOGETHER */

	if( flags & RULE_TOGETHER )
	{
	    LISTITEM *m;

	    for( m = list_first(l); m; m = list_next(m) )
		if( !strcmp( list_value(m), t->boundname ) )
		    break;

	    if( m )
		continue;
	}

	/* Build new list */

	l = list_append( l, t->boundname, 1 );
    }

    return l;
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT

/*
 * make1list_unbound() - turn a list of targets into a LIST, for $(<) and $(>)
 */

static LIST *
make1list_unbound(
	LIST	*l,
	TARGETS	*targets,
	int	flags )
{
    for( ; targets; targets = targets->next )
    {
	TARGET *t = targets->target;

	/* Sources to 'actions existing' are never in the dependency */
	/* graph (if they were, they'd get built and 'existing' would */
	/* be superfluous, so throttle warning message about independent */
	/* targets. */

	if( t->binding == T_BIND_UNBOUND )
	    make1bind( t, !( flags & RULE_EXISTING ) );

	if( ( flags & RULE_EXISTING ) && t->binding != T_BIND_EXISTS )
	    continue;

	if( ( flags & RULE_UPDATED ) && t->fate <= T_FATE_STABLE && !targets->parentcommandlineoutofdate )
	    continue;

	/* Prohibit duplicates for RULE_TOGETHER */

	if( flags & RULE_TOGETHER )
	{
	    LISTITEM *m;

	    for( m = list_first(l); m; m = list_next(m) )
		if( !strcmp( list_value(m), t->boundname ) )
		    break;

	    if( m )
		continue;
	}

	/* Build new list */

	l = list_append( l, t->name, 1 );
    }

    return l;
}


#if 0
/*
 * make1list_batched() - turn a list of targets and sources into two LISTs, for $(<) and $(>)
 * Takes only targets that need updating and their respective sources, matching one-to-one by list indices.
 * Extra targets are appended if count(targets) > count(sources).
 */

static void
make1list_batched(
				  LIST**plt,
				  LIST**pls,
				  TARGETS *targets,
				  TARGETS *sources,
				  int     flags )
{
	/* walk sources and targets simultaneously */
	for( ; targets; targets = targets->next, sources = (sources==NULL?sources:sources->next) )
	{
		TARGET *t = targets->target;
		TARGET *s = sources!=NULL ? sources->target : NULL;

		/* Sources to 'actions existing' are never in the dependency */
		/* graph (if they were, they'd get built and 'existing' would */
		/* be superfluous, so throttle warning message about independent */
		/* targets. */

		if( t->binding == T_BIND_UNBOUND )
			make1bind( t, 0 );
		if( s!=NULL) {
			if ( s->binding == T_BIND_UNBOUND )
				make1bind( s, !( flags & RULE_EXISTING ) );
			if ( s->binding == T_BIND_UNBOUND )
				printf("Warning using unbound source %s for batched action.\n", s->name);
		}


		if( ( flags & RULE_EXISTING ) && s!=NULL && s->binding != T_BIND_EXISTS )
			continue;

		if( t->fate < T_FATE_BUILD )
			continue;

		/* Build new lists */

		*plt = list_new( *plt, t->boundname, 1 );
		if (s!=NULL) {
			*pls = list_new( *pls, s->boundname, 1 );
		}
	}

	if (sources!=NULL) {
		printf("warning: more sources than targets in a batched action!\n");
	}
}
#endif

#if 0

/*
 * make1list_batched() - turn a list of targets and sources into two LISTs, for $(<) and $(>)
 * Takes only targets that need updating and their respective sources, matching one-to-one by list indices.
 * Extra targets are appended if count(targets) > count(sources).
 */

static void
make1list_batched(
        MD5SUM *md5forcmd,
        LIST**plt,
        LIST**pls,
        TARGETS *targets,
        TARGETS *sources,
        int     flags )
{
    /* walk sources and targets simultaneously */
    for( ; targets; targets = targets->next, sources = (sources==NULL?sources:sources->next) )
    {
	TARGET *t = targets->target;
	TARGET *s = sources!=NULL ? sources->target : NULL;

	if ( t->flags & T_FLAG_USEFILECACHE )
	{
	    LIST *filecache;
	    pushsettings( t->settings );
	    filecache = var_get( "FILECACHE" );
	    if ( filecache ) {
		LIST *l;
		char *ptr;
		strcpy( filecache_buffer, "FILECACHE." );
		strcat( filecache_buffer, filecache->string );
		ptr = filecache_buffer + strlen( filecache_buffer );
		strcat( ptr, ".USE" );
		l = var_get( filecache_buffer );
		if ( l  &&  atoi( l->string ) != 0) {
		    t->filecache_use = 1;
		}
		strcat( ptr, ".GENERATE" );
		l = var_get( filecache_buffer );
		if ( l  &&  atoi( l->string ) != 0) {
		    t->filecache_generate = 1;
		}
	    }
	    popsettings( t->settings );
	}

	/* Sources to 'actions existing' are never in the dependency */
	/* graph (if they were, they'd get built and 'existing' would */
	/* be superfluous, so throttle warning message about independent */
	/* targets. */

	if( t->binding == T_BIND_UNBOUND )
	    make1bind( t, 0 );
	if( s!=NULL) {
	    if ( s->binding == T_BIND_UNBOUND )
		make1bind( s, !( flags & RULE_EXISTING ) );
	    if ( s->binding == T_BIND_UNBOUND )
		printf("Warning using unbound source %s for batched action.\n", s->name);
	}


	if( ( flags & RULE_EXISTING ) && s!=NULL && s->binding != T_BIND_EXISTS )
	    continue;

	if( t->fate < T_FATE_BUILD )
	    continue;

	/* if this target could be cacheable */
	if ( (t->flags & T_FLAG_USEFILECACHE) && (t->filecache_generate || t->filecache_use) ) {
	    /* find its final md5sum */
	    MD5_CTX context;
	    MD5SUM buildsumorg;
	    memcpy(&buildsumorg, &t->buildmd5sum, sizeof(t->buildmd5sum));
	    MD5Init( &context );

	    /* add the path of the file to the sum - it is significant because one command can create more than one file */
	    MD5Update( &context, t->name, strlen( t->name ) );
	    MD5Final( t->buildmd5sum, &context );
	    if (DEBUG_MD5HASH) {
		printf( "Cacheable: %s buildmd5: %s org: %s\n",
		    t->boundname, md5tostring(t->buildmd5sum), md5tostring(buildsumorg) );
	    }
	}

	/* if this target could be cacheable */
	if ( (t->flags & T_FLAG_USEFILECACHE) && (t->filecache_generate || t->filecache_use) ) {
	    const char *cachedname;
	    time_t cachedtime;

	    /* if using cache is allowed */
	    if (t->filecache_use) {
		/* if the target is available in the cache */
		cachedname = filecache_getfilename(t, t->buildmd5sum, "");
		if (cachedname!=NULL) {
		    if ( file_time( cachedname, &cachedtime ) == 0 ) {
			/* try to get it from the cache */
			if (copyfile(t->boundname, cachedname, NULL)) {
			    printf( "Using cached %s\n", t->boundname );
			    continue;
			} else {
			    printf( "Cannot retrieve %s from cache (will build normally)\n", t->boundname );
			}
		    } else {
			if( DEBUG_MD5HASH) {
			    printf( "Cannot find %s in cache as %s\n", t->boundname, cachedname );
			}
		    }
		}
	    }
	}

	/* Build new lists */

	*plt = list_new( *plt, t->boundname, 1 );
	if (s!=NULL) {
	    *pls = list_new( *pls, s->boundname, 1 );
	}
    }

    if (sources!=NULL) {
	printf("warning: more sources than targets in a batched action!\n");
    }
}

#endif

#endif

/*
 * make1settings() - for vars that get bound values, build up replacement lists
 */

static SETTINGS *
make1settings( LIST *vars )
{
	SETTINGS *settings = 0;
	LISTITEM* var;

	for(var = list_first(vars) ; var; var = list_next( var ) )
	{
	    LISTITEM *l = list_first(var_get(list_value(var)));
	    LIST *nl = 0;

	    for( ; l; l = list_next( l ) )
	    {
		TARGET *t = bindtarget(list_value(l));

		/* Make sure the target is bound, warning if it is not in the */
		/* dependency graph. */

		if( t->binding == T_BIND_UNBOUND )
		    make1bind( t, 1 );

		/* Build new list */

		nl = list_append( nl, t->boundname, 1 );
	    }

	    /* Add to settings chain */

	    settings = addsettings( settings, 0, list_value(var), nl );
	}

	return settings;
}

/*
 * make1bind() - bind targets that weren't bound in dependency analysis
 *
 * Spot the kludge!  If a target is not in the dependency tree, it didn't
 * get bound by make0(), so we have to do it here.  Ugly.
 */

static void
make1bind(
	TARGET	*t,
	int	warn )
{
	if( t->flags & T_FLAG_NOTFILE )
	    return;

	/* Sources to 'actions existing' are never in the dependency */
	/* graph (if they were, they'd get built and 'existing' would */
	/* be superfluous, so throttle warning message about independent */
	/* targets. */

	if( warn )
	    printf( "warning: using independent target %s\n", t->name );

	pushsettings( t->settings );
	t->boundname = search( t->name, &t->time );
	t->binding = t->time ? T_BIND_EXISTS : T_BIND_MISSING;
	popsettings( t->settings );
}

#ifdef OPT_ACTIONS_WAIT_FIX
static void
make1wait( TARGET *t )
{
    ACTIONS *a0;

    for( a0 = t->actions; a0; a0 = a0->next )
    {
        if( a0->action->running && a0->action->run_tgt->progress != T_MAKE_DONE )
        {
            a0->action->run_tgt->parents = targetentry( a0->action->run_tgt->parents, t, 0 );
            t->asynccnt++;
        }
    }
}
#endif


#if defined(OPT_SERIAL_OUTPUT_EXT)
/* Ignore common noise from NT tools */
static int
verifyIsRealOutput(char *input, int len)
{
    int	 n = 0, d = 0, i;

    /* Test for compiler output.  A single word with 1 dot */
    for (i = 0; i < len; ++i)
    {
	switch (input[i])
	{
	  case ' ': return 1;
	  case '\t': return 1;
	  case '\n':
	      if (++n > 1)
		  return 1;
	      break;
	  case '.':
	      if (++d > 1)
		  return 1;
	      break;
	}
    }

    /* There must be exactly one newline and one dot. */
    if (n == 1 && d == 1)
	return 0;

    /* Assume its real.  */
    return 1;
}
#endif /* OPT_SERIAL_OUTPUT_EXT */
#ifdef OPT_RESPONSE_FILES
static void
printResponseFiles(CMD* cmd)
{
    TMPLIST* r;
    for (r = cmd->response_files; r; r = r->next) {
	FILE* f;
	printf("==================================="
	       "===================================\n");
	printf("contents of response file %s\n", r->file->name);
	f = fopen(r->file->name, "r");
	if (!f) {
	    printf("error: could not open temp file\n");
	} else {
	    char buffer[10240];
	    size_t bytes;

	    while (1) {
		bytes = fread(buffer, 1, sizeof(buffer), f);
		if (bytes > 0) {
		    fwrite(buffer, bytes, 1, stdout);
		} else if (bytes == 0) {
		    if (ferror(f)) {
			printf("error: problem reading"
			       " temp file\n");
		    }
		    break;
		}
	    }
	    fclose(f);
	    printf("\n");
	}
	printf("-----------------------------------"
	       "-----------------------------------\n");
    }
}
#endif /* OPT_RESPONSE_FILES */

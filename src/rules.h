/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * rules.h -  targets, rules, and related information
 *
 * This file describes the structures holding the targets, rules, and
 * related information accumulated by interpreting the statements
 * of the jam files.
 *
 * The following are defined:
 *
 *	RULE - a generic jam rule, the product of RULE and ACTIONS 
 *	ACTIONS - a chain of ACTIONs 
 *	ACTION - a RULE instance with targets and sources 
 *	SETTINGS - variables to set when executing a TARGET's ACTIONS 
 *	TARGETS - a chain of TARGETs 
 *	TARGET - a file or "thing" that can be built 
 *
 * 04/11/94 (seiwald) - Combined deps & headers into deps[2] in TARGET.
 * 04/12/94 (seiwald) - actionlist() now just appends a single action.
 * 06/01/94 (seiwald) - new 'actions existing' does existing sources
 * 12/20/94 (seiwald) - NOTIME renamed NOTFILE.
 * 01/19/95 (seiwald) - split DONTKNOW into CANTFIND/CANTMAKE.
 * 02/02/95 (seiwald) - new LEAVES modifier on targets.
 * 02/14/95 (seiwald) - new NOUPDATE modifier on targets.
 * 02/28/02 (seiwald) - merge EXEC_xxx flags in with RULE_xxx 
 * 06/21/02 (seiwald) - support for named parameters
 * 07/17/02 (seiwald) - TEMPORARY sources for headers now get built
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/03/02 (seiwald) - fix odd includes support by grafting them onto depends
 * 12/17/02 (seiwald) - new copysettings() to protect target-specific vars
 * 01/14/03 (seiwald) - fix includes fix with new internal includes TARGET
 */

typedef struct _rule RULE;
typedef struct _target TARGET;
typedef struct _targets TARGETS;
typedef struct _action ACTION;
typedef struct _actions ACTIONS;
typedef struct _settings SETTINGS ;

/* RULE - a generic jam rule, the product of RULE and ACTIONS */

struct _rule {
	const char	*name;
	PARSE		*procedure;	/* parse tree from RULE */
	const char	*actions;	/* command string from ACTIONS */
	LIST		*bindlist;	/* variable to bind for actions */
	LIST		*params;	/* bind args to local vars */
	int		flags;		/* modifiers on ACTIONS */

# define	RULE_UPDATED	0x01	/* $(>) is updated sources only */
# define	RULE_TOGETHER	0x02	/* combine actions on single target */
# define	RULE_IGNORE	0x04	/* ignore return status of executes */
# define	RULE_QUIETLY	0x08	/* don't mention it unless verbose */
# define	RULE_PIECEMEAL	0x10	/* split exec so each $(>) is small */
# define	RULE_EXISTING	0x20	/* $(>) is pre-exisitng sources only */
/* commented out so jamgram.y can compile #ifdef OPT_RESPONSE_FILES */
# define	RULE_RESPONSE	0x40	/* enable response file syntax */
/* commented out so jamgram.y can compile #endif */
# define	RULE_MAXLINE	0x80	/* cmd specific maxline (last) */
/* commented out for the parser -- #ifdef OPT_BUILTIN_LUA_SUPPORT_EXT */
# define	RULE_LUA	    0x100	/* this action is lua script */
/*#endif*/
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
# define	RULE_MAXTARGETS	0x200	/* cmd specific maxtargets */
/* commented out so jamgram.y can compile #endif */
#ifdef OPT_ACTIONS_DUMP_TEXT_EXT
# define	RULE_WRITEFILE	0x400	/* this action writes a file and is done */
#endif
/* commented out so jamgram.y can compile #ifdef OPT_REMOVE_EMPTY_DIRS_EXT */
# define	RULE_SCREENOUTPUT   0x800	/* screen the output from the action */
/* commented out so jamgram.y can compile #ifdef OPT_REMOVE_EMPTY_DIRS_EXT */
# define	RULE_REMOVEEMPTYDIRS 0x1000	/* screen the output from the action */

	int		maxline;
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
	int		maxtargets;
/* commented out so jamgram.y can compile #endif */

} ;

/* ACTIONS - a chain of ACTIONs */

struct _actions {
	ACTIONS		*next;
	ACTIONS		*tail;		/* valid only for head */
	ACTION		*action;
} ;

/* ACTION - a RULE instance with targets and sources */

struct _action {
	RULE		*rule;
	TARGETS		*targets;
	TARGETS		*sources;	/* aka $(>) */
#ifdef OPT_ACTIONS_WAIT_FIX
	TARGET		*run_tgt;
#endif
	char		running;	/* has been started */
	char		status;		/* see TARGET status */
#ifdef OPT_MULTIPASS_EXT
	int		pass;
#endif
	TARGETS		*autosettings;
#ifdef OPT_USE_CHECKSUMS_EXT
	TARGETS		*extratargets;
#endif /* OPT_USE_CHECKSUMS_EXT */
} ;

/* SETTINGS - variables to set when executing a TARGET's ACTIONS */

struct _settings {
	SETTINGS 	*next;
	const char	*symbol;	/* symbol name for var_set() */
	LIST		*value;		/* symbol value for var_set() */
} ;

/* TARGETS - a chain of TARGETs */

struct _targets {
	TARGETS		*next;
	TARGETS		*tail;		/* valid only for head */
	TARGET		*target;
#ifdef OPT_BUILTIN_NEEDS_EXT	
	char		needs;		/* set if this target was depended via the Needs rule */
#endif
#ifdef OPT_BUILTIN_MD5CACHE_EXT
	char		parentcommandlineoutofdate;
#endif
} ;

/* TARGET - a file or "thing" that can be built */

struct _target {
	const char	*name;
	const char	*boundname;	/* if search() relocates target */
	ACTIONS		*actions;	/* rules to execute, if any */
	SETTINGS 	*settings;	/* variables to define */

	unsigned int flags;		/* status info */

# define 	T_FLAG_TEMP 	0x01	/* TEMPORARY applied */
# define 	T_FLAG_NOCARE 	0x02	/* NOCARE applied */
# define 	T_FLAG_NOTFILE 	0x04	/* NOTFILE applied */
# define	T_FLAG_TOUCHED	0x08	/* ALWAYS applied or -t target */
# define	T_FLAG_LEAVES	0x10	/* LEAVES applied */
# define	T_FLAG_NOUPDATE	0x20	/* NOUPDATE applied */
# define	T_FLAG_INTERNAL	0x40	/* internal INCLUDES node */
#ifdef OPT_BUILTIN_MD5CACHE_EXT
# define	T_FLAG_USEFILECACHE	    0x80  /* attempt retrieval of the target from the file cache */
# define	T_FLAG_OPTIONALFILECACHE    0x100 /*  */
# define	T_FLAG_USECOMMANDLINE	    0x200 /* use md5sum command line */
# define	T_FLAG_SCANCONTENTS	    0x400 /* use md5sum instead of timestamp for this target */
#endif
#ifdef OPT_GRAPH_DEBUG_EXT
# define	T_FLAG_VISITED	0x800	/* used in debugging */
#endif /* OPT_GRAPH_DEBUG_EXT */
# ifdef OPT_MULTIPASS_EXT
# define	T_FLAG_FIXPROGRESS_VISITED	0x1000	/*  */
#endif
#ifdef OPT_HEADER_CACHE_EXT
# define	T_FLAG_USEDEPCACHE    0x2000   /* a target-specificdep cache has been set */
#endif
#ifdef OPT_BUILTIN_NEEDS_EXT
# define 	T_FLAG_MIGHTNOTUPDATE    0x4000	/* MightNotUpdate applied */
#endif
# define 	T_FLAG_FORCECARE 	0x8000	/* ForceCare applied */
#ifdef OPT_USE_CHECKSUMS_EXT
# define	T_FLAG_CHECKSUM_VISITED	0x10000	/*  */
#endif /* OPT_USE_CHECKSUMS_EXT */

	char		binding;	/* how target relates to real file */

# define 	T_BIND_UNBOUND	0	/* a disembodied name */
# define 	T_BIND_MISSING	1	/* couldn't find real file */
# define 	T_BIND_PARENTS	2	/* using parent's timestamp */
# define 	T_BIND_EXISTS	3	/* real file, timestamp valid */

	TARGETS		*depends;	/* dependencies */
	TARGET		*includes;	/* includes */

	time_t		time;		/* update time */
	time_t		leaf;		/* update time of leaf sources */
#ifdef OPT_BUILTIN_MD5CACHE_EXT
	MD5SUM		contentmd5sum; 	/* existing md5sum - either direct (for sources) or indirect (for those that have actions) */
	MD5SUM		buildmd5sum;	/* new indirect md5sum calculated from actions */
	MD5SUM		rulemd5sum;	/*  */
	char		rulemd5sumchecked;
	char		rulemd5sumclean;
	char		contentmd5sum_calculated;
	char		contentmd5sum_changed;
	char		buildmd5sum_calculated;
	char		filecache_use;
	char		filecache_generate;
#ifdef OPT_USE_CHECKSUMS_EXT
	char		contentmd5sum_file_dirty;
	char		leafmd5filedirty;
#endif /* OPT_USE_CHECKSUMS_EXT */
#endif	
#ifdef OPT_CIRCULAR_GENERATED_HEADER_FIX
	int			epoch;
	int			depth;
#endif
	char		fate;		/* make0()'s diagnosis */

# define 	T_FATE_INIT	0	/* nothing done to target */
# define 	T_FATE_MAKING	1	/* make0(target) on stack */

# define 	T_FATE_STABLE	2	/* target didn't need updating */
# define	T_FATE_NEWER	3	/* target newer than parent */

# define	T_FATE_SPOIL	4	/* >= SPOIL rebuilds parents */
# define 	T_FATE_ISTMP	4	/* unneeded temp target oddly present */

# define	T_FATE_BUILD	5	/* >= BUILD rebuilds target */
# define	T_FATE_TOUCHED	5	/* manually touched with -t */
# define	T_FATE_MISSING	6	/* is missing, needs updating */
# define	T_FATE_NEEDTMP	7	/* missing temp that must be rebuild */
# define 	T_FATE_OUTDATED	8	/* is out of date, needs updating */
# define 	T_FATE_UPDATE	9	/* deps updated, needs updating */

# define 	T_FATE_BROKEN	10	/* >= BROKEN ruins parents */
# define 	T_FATE_CANTFIND	10	/* no rules to make missing target */
# define 	T_FATE_CANTMAKE	11	/* can't find dependents */

	char		progress;	/* tracks make1() progress */

# define	T_MAKE_INIT	0	/* make1(target) not yet called */
# define	T_MAKE_ONSTACK	1	/* make1(target) on stack */
# define	T_MAKE_ACTIVE	2	/* make1(target) in make1b() */
# define	T_MAKE_RUNNING	3	/* make1(target) running commands */
# define	T_MAKE_DONE	4	/* make1(target) done */
#ifdef OPT_SEMAPHORE
# define 	T_MAKE_SEMAPHORE 5 /* Special target type for semaphores */
#endif

	char		status;		/* execcmd() result */

	int		asynccnt;	/* child deps outstanding */
	TARGETS		*parents;	/* used by make1() for completion */
	char		*cmds;		/* type-punned command list */
#ifdef OPT_SEMAPHORE
	TARGET  	*semaphore;	/* used in serialization */
#endif
} ;

RULE 	*bindrule( const char *rulename );
int ruleexists( const char *rulename );
TARGET *bindtarget( const char *targetname );
TARGET *copytarget( const TARGET *t );
void 	touchtarget( const char *t );
#ifdef OPT_BUILTIN_NEEDS_EXT
TARGETS *targetlist( TARGETS *chain, LIST  *targets, char needs );
TARGETS *targetentry( TARGETS *chain, TARGET *target, char needs );
TARGETS *targetentryhead( TARGETS *chain, TARGET *target, char needs );
#else
TARGETS *targetlist( TARGETS *chain, LIST  *targets );
TARGETS *targetentry( TARGETS *chain, TARGET *target );
#endif
#ifdef OPT_MULTIPASS_EXT
void	targetlist_free( TARGETS *targets );
#endif
TARGETS *targetchain( TARGETS *chain, TARGETS *targets );
ACTIONS *actionlist( ACTIONS *chain, ACTION *action );
SETTINGS *addsettings( SETTINGS *v, int setflag, const char *sym, LIST *val );
SETTINGS *copysettings( SETTINGS *v );
void 	pushsettings( SETTINGS *v );
void 	popsettings( SETTINGS *v );
void 	freesettings( SETTINGS *v );
void	donerules();
SETTINGS* quicksettingslookup( TARGET* t, const char* symbol );

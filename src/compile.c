/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * compile.c - compile parsed jam statements
 *
 * External routines:
 *
 *	compile_append() - append list results of two statements
 *	compile_break() - compile 'break/continue/return' rule
 *	compile_eval() - evaluate if to determine which leg to compile
 *	compile_foreach() - compile the "for x in y" statement
 *	compile_if() - compile 'if' rule
 *	compile_include() - support for 'include' - call include() on file
 *	compile_list() - expand and return a list 
 *	compile_local() - declare (and set) local variables
 *	compile_null() - do nothing -- a stub for parsing
 *	compile_on() - run rule under influence of on-target variables
 *	compile_rule() - compile a single user defined rule
 *	compile_rules() - compile a chain of rules
 *	compile_set() - compile the "set variable" statement
 *	compile_setcomp() - support for `rule` - save parse tree 
 *	compile_setexec() - support for `actions` - save execution string 
 *	compile_settings() - compile the "on =" (set variable on exec) statement
 *	compile_switch() - compile 'switch' rule
 *
 * Internal routines:
 *
 *	debug_compile() - printf with indent to show rule expansion.
 *	evaluate_rule() - execute a rule invocation
 *
 * 02/03/94 (seiwald) -	Changed trace output to read "setting" instead of 
 *			the awkward sounding "settings".
 * 04/12/94 (seiwald) - Combined build_depends() with build_includes().
 * 04/12/94 (seiwald) - actionlist() now just appends a single action.
 * 04/13/94 (seiwald) - added shorthand L0 for null list pointer
 * 05/13/94 (seiwald) - include files are now bound as targets, and thus
 *			can make use of $(SEARCH)
 * 06/01/94 (seiwald) - new 'actions existing' does existing sources
 * 08/23/94 (seiwald) - Support for '+=' (append to variable)
 * 12/20/94 (seiwald) - NOTIME renamed NOTFILE.
 * 01/22/95 (seiwald) - Exit rule.
 * 02/02/95 (seiwald) - Always rule; LEAVES rule.
 * 02/14/95 (seiwald) - NoUpdate rule.
 * 01/20/00 (seiwald) - Upgraded from K&R to ANSI C
 * 09/07/00 (seiwald) - stop crashing when a rule redefines itself
 * 09/11/00 (seiwald) - new evaluate_rule() for headers().
 * 09/11/00 (seiwald) - rules now return values, accessed via [ rule arg ... ]
 * 09/12/00 (seiwald) - don't complain about rules invoked without targets
 * 01/13/01 (seiwald) - fix case where rule is defined within another
 * 01/10/01 (seiwald) - built-ins split out to builtin.c.
 * 01/11/01 (seiwald) - optimize compile_rules() for tail recursion
 * 01/21/01 (seiwald) - replace evaluate_if() with compile_eval()
 * 01/24/01 (seiwald) - 'while' statement
 * 03/23/01 (seiwald) - "[ on target rule ]" support
 * 02/28/02 (seiwald) - merge EXEC_xxx flags in with RULE_xxx 
 * 03/02/02 (seiwald) - rules can be invoked via variable names
 * 03/12/02 (seiwald) - &&,&,||,|,in now short-circuit again
 * 03/25/02 (seiwald) - if ( "" a b ) one again returns true
 * 06/21/02 (seiwald) - support for named parameters
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 10/22/02 (seiwald) - working return/break/continue statements
 * 11/04/02 (seiwald) - const-ing for string literals
 * 11/18/02 (seiwald) - remove bogus search() in 'on' statement.
 * 12/17/02 (seiwald) - new copysettings() to protect target-specific vars
 */

# include "jam.h"

# include "lists.h"
# include "parse.h"
# include "compile.h"
# include "variable.h"
# include "expand.h"
# include "rules.h"
# include "newstr.h"
# include "search.h"
# include "buffer.h"

#ifdef OPT_MULTIPASS_EXT
extern int actionpass;
#endif

#ifdef OPT_MINUS_EQUALS_EXT
static const char *set_names[] = { "=", "+=", "?=", "-=" };
#else
static const char *set_names[] = { "=", "+=", "?=" };
#endif
static void debug_compile( int which, const char *s );
int glob( const char *s, const char *c );



/*
 * compile_append() - append list results of two statements
 *
 *	parse->left	more compile_append() by left-recursion
 *	parse->right	single rule
 */

LIST *
compile_append(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	/* Append right to left. */

	return list_appendList( 
		(*parse->left->func)( parse->left, args, jmp ),
		(*parse->right->func)( parse->right, args, jmp ) );
}

/*
 * compile_break() - compile 'break/continue/return' rule
 *
 *	parse->left	results
 *	parse->num	JMP_BREAK/CONTINUE/RETURN
 */

LIST *
compile_break(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *lv = (*parse->left->func)( parse->left, args, jmp );
	*jmp = parse->num;
	return lv;
}

/*
 * compile_eval() - evaluate if to determine which leg to compile
 *
 * Returns:
 *	list 	if expression true - compile 'then' clause
 *	L0	if expression false - compile 'else' clause
 */

static int
lcmp( LIST *t, LIST *s )
{
	int status = 0;

	LISTITEM* ti = list_first(t);
	LISTITEM* si = list_first(s);

	while( !status && ( ti || si ) )
	{
	    const char *st = ti ? list_value(ti) : "";
	    const char *ss = si ? list_value(si) : "";

	    status = strcmp( st, ss );

	    ti = ti ? list_next( ti ) : ti;
	    si = si ? list_next( si ) : si;
	}

	return status;
}

LIST *
compile_eval(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST *ll, *lr, *t;
	int status = 0;

	/* Short circuit lr eval for &&, ||, and 'in' */

	ll = (*parse->left->func)( parse->left, args, jmp );
	lr = 0;

	switch( parse->num )
	{
	case EXPR_AND: 
	case EXPR_IN: 	if( ll ) goto eval; break;
	case EXPR_OR: 	if( !ll ) goto eval; break;
	default: eval: 	lr = (*parse->right->func)( parse->right, args, jmp );
	}

	/* Now eval */

	switch( parse->num )
	{
	case EXPR_NOT:	
		if( !ll ) status = 1;
		break;

	case EXPR_AND:
		if( ll && lr ) status = 1;
		break;

	case EXPR_OR:
		if( ll || lr ) status = 1;
		break;

	case EXPR_IN:
		/* "a in b": make sure each of */
		/* ll is equal to something in lr. */
		status = list_in(ll, lr);

		break;

	case EXPR_EXISTS:       if( lcmp( ll, L0 ) != 0 ) status = 1; break;
	case EXPR_EQUALS:	if( lcmp( ll, lr ) == 0 ) status = 1; break;
	case EXPR_NOTEQ:	if( lcmp( ll, lr ) != 0 ) status = 1; break;
	case EXPR_LESS:		if( lcmp( ll, lr ) < 0  ) status = 1; break;
	case EXPR_LESSEQ:	if( lcmp( ll, lr ) <= 0 ) status = 1; break;
	case EXPR_MORE:		if( lcmp( ll, lr ) > 0  ) status = 1; break;
	case EXPR_MOREEQ:	if( lcmp( ll, lr ) >= 0 ) status = 1; break;

	}

	if( DEBUG_IF )
	{
	    debug_compile( 0, "if" );
	    list_print( ll );
	    printf( "(%d) ", status );
	    list_print( lr );
	    printf( "\n" );
	}

	/* Find something to return. */
	/* In odd circumstances (like "" = "") */
	/* we'll have to return a new string. */

	if( !status ) t = 0;
	else if( ll ) t = ll, ll = 0;
	else if( lr ) t = lr, lr = 0;
	else t = list_append( L0, "1", 0 );

	if( ll ) list_free( ll );
	if( lr ) list_free( lr );
	return t;
}

/*
 * compile_foreach() - compile the "for x in y" statement
 *
 * Compile_foreach() resets the given variable name to each specified
 * value, executing the commands enclosed in braces for each iteration.
 *
 *	parse->string	index variable
 *	parse->left	variable values
 *	parse->right	rule to compile
 */

LIST *
compile_foreach(
	PARSE	*p,
	LOL	*args,
	int	*jmp )
{
	LIST	*nv = (*p->left->func)( p->left, args, jmp );
	LIST	*result = 0;
	LISTITEM *l;

	/* TODO: Efficiency: nv could be split apart and reused during the traversal */

	/* for each value for var */

	for( l = list_first(nv); l && *jmp == JMP_NONE; l = list_next( l ) )
	{
	    /* Reset $(p->string) for each val. */

	    var_set( p->string, list_append( L0, list_value(l), 1 ), VAR_SET );

	    /* Keep only last result. */

	    list_free( result );
	    result = (*p->right->func)( p->right, args, jmp );

	    /* continue loop? */

	    if( *jmp == JMP_CONTINUE )
		*jmp = JMP_NONE;
	}

	/* Here by break/continue? */

	if( *jmp == JMP_BREAK || *jmp == JMP_CONTINUE )
	    *jmp = JMP_NONE;

	list_free( nv );

	/* Returns result of last loop */

	return result;
}

/*
 * compile_if() - compile 'if' rule
 *
 *	parse->left		condition tree
 *	parse->right		then tree
 *	parse->third		else tree
 */

LIST *
compile_if(
	PARSE	*p,
	LOL	*args,
	int	*jmp )
{
	LIST *l = (*p->left->func)( p->left, args, jmp );

	p = l ? p->right : p->third;

	list_free( l );

	return (*p->func)( p, args, jmp );
}

/*
 * compile_include() - support for 'include' - call include() on file
 *
 * 	parse->left	list of files to include (can only do 1)
 */

LIST *
compile_include(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "include" );
	    list_print( nt );
	    printf( "\n" );
	}

	if( nt && list_first(nt) )
	{
	    TARGET *t = bindtarget( list_value(list_first(nt)) );

	    /* Bind the include file under the influence of */
	    /* "on-target" variables.  Though they are targets, */
	    /* include files are not built with make(). */
	    /* Needn't copysettings(), as search sets no vars. */

	    pushsettings( t->settings );
	    t->boundname = search( t->name, &t->time );
	    popsettings( t->settings );

	    /* Don't parse missing file if NOCARE set */

	    if( t->time || !( t->flags & T_FLAG_NOCARE ) )
		parse_file( t->boundname );
	}

	list_free( nt );

	return L0;
}

/*
 * compile_list() - expand and return a list 
 *
 * 	parse->string - character string to expand
 */

LIST *
compile_list(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	/* voodoo 1 means: s is a copyable string */
	const char *s = parse->string;
	return var_expand( L0, s, s + strlen( s ), args, 1 );
}

/*
 * compile_local() - declare (and set) local variables
 *
 *	parse->left	list of variables
 *	parse->right	list of values
 *	parse->third	rules to execute
 */

LIST *
compile_local(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LISTITEM *l;
	SETTINGS *s = 0;
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );
	LIST	*ns = (*parse->right->func)( parse->right, args, jmp );
	LIST	*result;

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "local" );
	    list_print( nt );
	    printf( " = " );
	    list_print( ns );
	    printf( "\n" );
	}

	/* Initial value is ns */

	for( l = list_first(nt); l; l = list_next( l ) )
	    s = addsettings( s, 0, list_value(l), list_copy( NULL, ns ) );

	list_free( ns );
	list_free( nt );

	/* Note that callees of the current context get this "local" */
	/* variable, making it not so much local as layered. */

	pushsettings( s );
	result = (*parse->third->func)( parse->third, args, jmp );
	popsettings( s );
	freesettings( s );

	return result;
}

/*
 * compile_null() - do nothing -- a stub for parsing
 */

LIST *
compile_null(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	return L0;
}

/*
 * compile_on() - run rule under influence of on-target variables
 *
 * 	parse->left	target list; only first used
 *	parse->right	rule to run
 */

LIST *
compile_on(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );
	LIST	*result = 0;

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "on" );
	    list_print( nt );
	    printf( "\n" );
	}

	/* 
	 * Copy settings, so that 'on target var on target = val' 
	 * doesn't set var globally.
	 */

	if( nt && list_first(nt) )
	{
	    TARGET *t = bindtarget( list_value(list_first(nt)) );
	    SETTINGS *s = copysettings( t->settings );

	    pushsettings( s );
	    result = (*parse->right->func)( parse->right, args, jmp );
	    popsettings( s );
	    freesettings( s );
	}

	list_free( nt );

	return result;
}

/*
 * compile_rule() - compile a single user defined rule
 *
 *	parse->left	list of rules to run
 *	parse->right	parameters (list of lists) to rule, recursing left
 *
 * Wrapped around evaluate_rule() so that headers() can share it.
 */

LIST *
compile_rule(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LOL	nargs[1];
	LIST	*result = 0;
	LIST	*ll;
	LISTITEM *l;
	PARSE	*p;

	/* list of rules to run -- normally 1! */

	ll = (*parse->left->func)( parse->left, args, jmp );

	/* Build up the list of arg lists */

	lol_init( nargs );

	for( p = parse->right; p; p = p->left )
	    lol_add( nargs, (*p->right->func)( p->right, args, jmp ) );

	/* Run rules, appending results from each */

	for( l = list_first(ll); l; l = list_next( l ) ) {
	    list_free(result); /* Keep only last result */
	    result = evaluate_rule( list_value(l), nargs, result );
	}

	list_free( ll );
	lol_free( nargs );

	return result;
}

/*
 * evaluate_rule() - execute a rule invocation
 */

#ifdef OPT_CLEAN_GLOBS_EXT
extern void add_used_target_to_hash(TARGET *t);
#endif /* OPT_CLEAN_GLOBS_EXT */

LIST *
evaluate_rule(
	const char *rulename,
	LOL	*args, 
	LIST	*result )
{
#ifdef OPT_EXPAND_RULE_NAMES_EXT
	RULE	*rule;
	char	*expanded;
	char	*c;
	int i;
	BUFFER	buff;

	buffer_init( &buff );

	if( (i = var_string( rulename, &buff, 0, args, ' ' )) < 0 )
	{
	    printf( "Failed to expand rule %s -- expansion too long\n", rulename );
	    exit( EXITBAD );
	}
	expanded = buffer_ptr( &buff );
	while ( expanded[0] == ' ' )
	    expanded++;
	while ( (c = strrchr(expanded, ' ')) )
	    *c = '\0';

	if( DEBUG_COMPILE )
	{
	    debug_compile( 1, rulename );
	    if ( strcmp(rulename, expanded) )
		printf( "-> %s  ", expanded );
	    lol_print( args );
	    printf( "\n" );
	}

	rule = bindrule( expanded );
#else	
	RULE	*rule = bindrule( rulename );

	if( DEBUG_COMPILE )
	{
	    debug_compile( 1, rulename );
	    lol_print( args );
	    printf( "\n" );
	}
#endif

#ifdef OPT_LOAD_MISSING_RULE_EXT
	if( !rule->actions && !rule->procedure )
	{
		if( ruleexists( "FindMissingRule" ) )
		{
			LOL lol;
			LIST *args = list_append( L0, expanded, 0 );
			LIST *result;

			lol_init( &lol );
			lol_add( &lol, args );
			result = evaluate_rule( "FindMissingRule", &lol, L0 );
			lol_free( &lol );

			if( list_first( result ) ) {
				rule = bindrule( list_value( list_first( result ) ) );
			}

			list_free( result );
		}
	}
#endif /* OPT_LOAD_MISSING_RULE_EXT */

	/* Check traditional targets $(<) and sources $(>) */

#ifdef OPT_IMPROVED_WARNINGS_EXT
	if( !rule->actions && !rule->procedure && !globs.silence )
	    printf( "warning: unknown rule %s %s\n", rule->name,
		   file_and_line());
#else
	if( !rule->actions && !rule->procedure )
	    printf( "warning: unknown rule %s\n", rule->name );
#endif

	/* If this rule will be executed for updating the targets */
	/* then construct the action for make(). */

	if( rule->actions )
	{
	    TARGETS	*t;
	    ACTION	*action;

	    /* The action is associated with this instance of this rule */

	    action = (ACTION *)malloc( sizeof( ACTION ) );
	    memset( (char *)action, '\0', sizeof( *action ) );

	    action->rule = rule;
#ifdef OPT_BUILTIN_NEEDS_EXT
	    action->targets = targetlist( (TARGETS *)0, lol_get( args, 0 ), 0 );
	    action->sources = targetlist( (TARGETS *)0, lol_get( args, 1 ), 0 );
	    action->autosettings = targetlist( (TARGETS *)0, lol_get( args, 2 ), 0 );
#else
	    action->targets = targetlist( (TARGETS *)0, lol_get( args, 0 ) );
	    action->sources = targetlist( (TARGETS *)0, lol_get( args, 1 ) );
#endif

#ifdef OPT_CLEAN_GLOBS_EXT
		{
			TARGETS* targets;
			for ( targets = action->targets; targets; targets = targets->next ) {
				if ( !( targets->target->flags & T_FLAG_NOTFILE ) )
					add_used_target_to_hash( targets->target );
			}
		}
#endif /* OPT_CLEAN_GLOBS_EXT */

	    /* Append this action to the actions of each target */

#ifdef OPT_MULTIPASS_EXT
	    action->pass = actionpass;
	    for( t = action->targets; t; t = t->next ) {
		t->target->progress = T_MAKE_INIT;
		t->target->actions = actionlist( t->target->actions, action );
	    }
#else
	    for( t = action->targets; t; t = t->next )
		t->target->actions = actionlist( t->target->actions, action );
#endif
	}

	/* Now recursively compile any parse tree associated with this rule */

	if( rule->procedure )
	{
	    PARSE *parse = rule->procedure;
	    SETTINGS *s = 0;
	    int jmp = JMP_NONE;
	    LISTITEM *l;
	    int i;

	    /* build parameters as local vars */
	    for( l = list_first(rule->params), i = 0; l; l = list_next(l), i++ )
		s = addsettings( s, 0, list_value(l), 
		    list_copy( L0, lol_get( args, i ) ) );

	    /* Run rule. */
	    /* Bring in local params. */
	    /* refer/free to ensure rule not freed during use. */

	    parse_refer( parse );

	    pushsettings( s );
	    result = list_appendList( result, (*parse->func)( parse, args, &jmp ) );
	    popsettings( s );
	    freesettings( s );

	    parse_free( parse );
	}

	if( DEBUG_COMPILE )
	    debug_compile( -1, 0 );

#ifdef OPT_EXPAND_RULE_NAMES_EXT
	buffer_free( &buff );
#endif

	return result;
}

/*
 * compile_rules() - compile a chain of rules
 *
 *	parse->left	single rule
 *	parse->right	more compile_rules() by right-recursion
 */

LIST *
compile_rules(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	/* Ignore result from first statement; return the 2nd. */
	/* Optimize recursion on the right by looping. */

	LIST 	*result = 0;

	while( *jmp == JMP_NONE && parse->func == compile_rules )
	{
	    list_free( result );
	    result = (*parse->left->func)( parse->left, args, jmp );
	    parse = parse->right;
	}

	if( *jmp == JMP_NONE )
	{
	    list_free( result );
	    result = (*parse->func)( parse, args, jmp );
	}

	return result;
}

/*
 * compile_set() - compile the "set variable" statement
 *
 *	parse->left	variable names
 *	parse->right	variable values 
 *	parse->num	VAR_SET/APPEND/DEFAULT
 */

LIST *
compile_set(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );
	LIST	*ns = (*parse->right->func)( parse->right, args, jmp );
	LISTITEM	*l;

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "set" );
	    list_print( nt );
	    printf( " %s ", set_names[ parse->num ] );
	    list_print( ns );
	    printf( "\n" );
	}

	/* Call var_set to set variable */
	/* var_set keeps ns, so need to copy it */

	for( l = list_first(nt); l; l = list_next( l ) )
	    var_set( list_value(l), list_copy( L0, ns ), parse->num );

	list_free( nt );

	return ns;
}

/*
 * compile_setcomp() - support for `rule` - save parse tree 
 *
 *	parse->string	rule name
 *	parse->left	list of argument names
 *	parse->right	rules for rule
 */

LIST *
compile_setcomp(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	RULE	*rule = bindrule( parse->string );
	LIST	*params = 0;
	PARSE	*p;

	/* Build param list */

	for( p = parse->left; p; p = p->left )
	    params = list_append( params, p->string, 1 );

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "rule" );
	    printf( "%s ", parse->string );
	    list_print( params );
	    printf( "\n" );
	}

	/* Free old one, if present */

	if( rule->procedure )
	    parse_free( rule->procedure );

	if( rule->params )
	    list_free( rule->params );

	rule->procedure = parse->right;
	rule->params = params;

	/* we now own this parse tree */
	/* don't let parse_free() release it */

	parse_refer( parse->right );

	return L0;
}

/*
 * compile_setexec() - support for `actions` - save execution string 
 *
 *	parse->string	rule name
 *	parse->string1	OS command string
 *	parse->num	flags
 *	parse->left	`bind` variables
 *
 * Note that the parse flags (as defined in compile.h) are transfered
 * directly to the rule flags (as defined in rules.h).
 */

LIST *
compile_setexec(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	RULE	*rule = bindrule( parse->string );
	LIST	*bindlist = (*parse->left->func)( parse->left, args, jmp );
	
	/* Free old one, if present */

	if( rule->actions )
	{
	    freestr( rule->actions );
	    list_free( rule->bindlist );
	}

	rule->actions = copystr( parse->string1 );
	rule->bindlist = bindlist;
	rule->flags = parse->num;
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
	rule->maxline = parse->num2;
	rule->maxtargets = parse->num3;
/* commented out so jamgram.y can compile #endif */

	return L0;
}

/*
 * compile_settings() - compile the "on =" (set variable on exec) statement
 *
 *	parse->left	variable names
 *	parse->right	target name 
 *	parse->third	variable value 
 *	parse->num	VAR_SET/APPEND/DEFAULT
 */

LIST *
compile_settings(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );
	LIST	*ns = (*parse->third->func)( parse->third, args, jmp );
	LIST	*targets = (*parse->right->func)( parse->right, args, jmp );
	LISTITEM	*ts;

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "set" );
	    list_print( nt );
	    printf( "on " );
	    list_print( targets );
	    printf( " %s ", set_names[ parse->num ] );
	    list_print( ns );
	    printf( "\n" );
	}

	/* Call addsettings to save variable setting */
	/* addsettings keeps ns, so need to copy it */
	/* Pass append flag to addsettings() */

	for( ts = list_first(targets); ts; ts = list_next( ts ) )
	{
	    TARGET 	*t = bindtarget( list_value(ts) );
	    LISTITEM	*l;

	    for( l = list_first(nt); l; l = list_next( l ) )
		t->settings = addsettings( t->settings, parse->num,
				list_value(l), list_copy( NULL, ns ) );
	}

	list_free( nt );
	list_free( targets );

	return ns;
}

/*
 * compile_switch() - compile 'switch' rule
 *
 *	parse->left	switch value (only 1st used)
 *	parse->right	cases
 *
 *	cases->left	1st case
 *	cases->right	next cases
 *
 *	case->string	argument to match
 *	case->left	parse tree to execute
 */

LIST *
compile_switch(
	PARSE	*parse,
	LOL	*args,
	int	*jmp )
{
	LIST	*nt = (*parse->left->func)( parse->left, args, jmp );
	LIST	*result = 0;

	if( DEBUG_COMPILE )
	{
	    debug_compile( 0, "switch" );
	    list_print( nt );
	    printf( "\n" );
	}

	/* Step through cases */

	for( parse = parse->right; parse; parse = parse->right )
	{
	    if( !glob( parse->left->string, list_first(nt) ? list_value(list_first(nt)) : "" ) )
	    {
		/* Get & exec parse tree for this case */
		parse = parse->left->left;
		result = (*parse->func)( parse, args, jmp );
		break;
	    }
	}

	list_free( nt );

	return result;
}

/*
 * compile_while() - compile 'while' rule
 *
 *	parse->left		condition tree
 *	parse->right		execution tree
 */

LIST *
compile_while(
	PARSE	*p,
	LOL	*args,
	int	*jmp )
{
	LIST *result = 0;
	LIST *l;

	/* Returns the value from the last execution of the block */

	while( ( *jmp == JMP_NONE ) && 
	       ( l = (*p->left->func)( p->left, args, jmp ) ) )
	{
	    /* Always toss while's expression */

	    list_free( l );

	    /* Keep only last result. */

	    list_free( result );
	    result = (*p->right->func)( p->right, args, jmp );

	    /* continue loop? */

	    if( *jmp == JMP_CONTINUE )
		*jmp = JMP_NONE;
	}

	/* Here by break/continue? */

	if( *jmp == JMP_BREAK || *jmp == JMP_CONTINUE )
	    *jmp = JMP_NONE;

	/* Returns result of last loop */

	return result;
}

/*
 * debug_compile() - printf with indent to show rule expansion.
 */

static void
debug_compile( int which, const char *s )
{
	static int level = 0;
	static char indent[36] = ">>>>|>>>>|>>>>|>>>>|>>>>|>>>>|>>>>|";
	int i = ((1+level) * 2) % 35;

	if( which >= 0 )
	    printf( "%*.*s ", i, i, indent );

	if( s )
	    printf( "%s ", s );

	level += which;
}

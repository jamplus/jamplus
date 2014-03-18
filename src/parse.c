/*
 * Copyright 1993, 2000 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * parse.c - make and destroy parse trees as driven by the parser
 *
 * 09/07/00 (seiwald) - ref count on PARSE to avoid freeing when used,
 *		as per Matt Armstrong.
 * 09/11/00 (seiwald) - structure reworked to reflect that (*func)()
 *		returns a LIST *.
 * 10/22/02 (seiwald) - working return/break/continue statements
 * 11/04/02 (seiwald) - const-ing for string literals
 */

# include "jam.h"
# include "lists.h"
# include "parse.h"
# include "scan.h"
# include "newstr.h"

static PARSE *yypsave;
#ifdef OPT_IMPROVED_MEMUSE_EXT
#include "mempool.h"
static MEMPOOL* parse_pool = NULL;
#endif

void
parse_file( const char *f )
{
	/* Suspend scan of current file */
	/* and push this new file in the stream */

	yyfparse(f);

	/* Now parse each block of rules and execute it. */
	/* Execute it outside of the parser so that recursive */
	/* calls to yyrun() work (no recursive yyparse's). */

	for(;;)
	{
	    LOL l;
	    PARSE *p;
	    int jmp = 0; /* JMP_NONE */

	    /* $(<) and $(>) empty in outer scope. */

	    lol_init( &l );

	    /* Filled by yyparse() calling parse_save() */

	    yypsave = 0;

	    /* If parse error or empty parse, outta here */

	    if( yyparse() || !( p = yypsave ) )
		break;

	    /* Run the parse tree. */

	    list_free( (*(p->func))( p, &l, &jmp ) );


	    parse_free( p );
	}
}

void
parse_lines( const char *s, char** lines )
{
	/* Suspend scan of current file */
	/* and push this new file in the stream */

	yyfparselines(s, lines);

	/* Now parse each block of rules and execute it. */
	/* Execute it outside of the parser so that recursive */
	/* calls to yyrun() work (no recursive yyparse's). */

	for(;;)
	{
	    LOL l;
	    PARSE *p;
	    int jmp = 0; /* JMP_NONE */

	    /* $(<) and $(>) empty in outer scope. */

	    lol_init( &l );

	    /* Filled by yyparse() calling parse_save() */

	    yypsave = 0;

	    /* If parse error or empty parse, outta here */

	    if( yyparse() || !( p = yypsave ) )
		break;

	    /* Run the parse tree. */

	    list_free( (*(p->func))( p, &l, &jmp ) );


	    parse_free( p );
	}
}

void
parse_save( PARSE *p )
{
	yypsave = p;
}

PARSE *
parse_make( 
	LIST		*(*func)( PARSE *p, LOL *args, int *jmp ),
	PARSE		*left,
	PARSE		*right,
	PARSE		*third,
	const char 	*string,
	const char 	*string1,
	int		num )
{
#ifdef OPT_IMPROVED_MEMUSE_EXT
	PARSE	*p;

	if (!parse_pool) {
	    parse_pool = mempool_create("PARSE", sizeof(PARSE));
	}
	p = mempool_alloc(parse_pool);
#else
	PARSE	*p = (PARSE *)malloc( sizeof( PARSE ) );
#endif

	p->func = func;
	p->left = left;
	p->right = right;
	p->third = third;
	p->string = string;
	p->string1 = string1;
	p->num = num;
/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */
	p->num2 = p->num3 = 0;
/* commented out so jamgram.y can compile #endif */
	p->refs = 1;

	return p;
}

/* commented out so jamgram.y can compile #ifdef OPT_ACTION_MAXTARGETS_EXT */

PARSE *
parse_make3( 
	LIST		*(*func)( PARSE *p, LOL *args, int *jmp ),
	PARSE		*left,
	PARSE		*right,
	PARSE		*third,
	const char 	*string,
	const char 	*string1,
	int		num,
	int		num2,
	int		num3 )
{
#ifdef OPT_IMPROVED_MEMUSE_EXT
	PARSE	*p;

	if (!parse_pool) {
	    parse_pool = mempool_create("PARSE", sizeof(PARSE));
	}
	p = mempool_alloc(parse_pool);
#else
	PARSE	*p = (PARSE *)malloc( sizeof( PARSE ) );
#endif

	p->func = func;
	p->left = left;
	p->right = right;
	p->third = third;
	p->string = string;
	p->string1 = string1;
	p->num = num;
	p->num2 = num2;
	p->num3 = num3;
	p->refs = 1;

	return p;
}

/* commented out so jamgram.y can compile #endif */

void
parse_refer( PARSE *p )
{
	++p->refs;
}

void
parse_free( PARSE *p )
{
	if( --p->refs )
	    return;

	if( p->string )
	    freestr( p->string );
	if( p->string1 )
	    freestr( p->string1 );
	if( p->left )
	    parse_free( p->left );
	if( p->right )
	    parse_free( p->right );
	if( p->third )
	    parse_free( p->third );
	
#ifdef OPT_IMPROVED_MEMUSE_EXT
	mempool_free(parse_pool, p);
#else
	free( (char *)p );
#endif
}

#ifdef OPT_DEBUG_MEM_TOTALS_EXT
void
parse_done(void)
{
#ifdef OPT_IMPROVED_MEMUSE_EXT
    mempool_done(parse_pool);
#endif
}
#endif /* OPT_DEBUG_MEM_TOTALS_EXT */

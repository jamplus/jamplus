/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * lists.c - maintain lists of strings
 *
 * This implementation essentially uses a singly linked list, but
 * guarantees that the head element of every list has a valid pointer
 * to the tail of the list, so the new elements can efficiently and 
 * properly be appended to the end of a list.
 *
 * To avoid massive allocation, list_free() just tacks the whole freed
 * chain onto freelist and list_new() looks on freelist first for an
 * available list struct.  list_free() does not free the strings in the 
 * chain: it lazily lets list_new() do so.
 *
 * 08/23/94 (seiwald) - new list_append()
 * 09/07/00 (seiwald) - documented lol_*() functions
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/09/02 (seiwald) - new list_printq() for writing lists to Jambase
 */

# include "jam.h"
# include "newstr.h"
# include "lists.h"

static LIST *freelist = 0;	/* junkpile for list_free() */
#ifdef OPT_IMPROVED_MEMUSE_EXT
#include "mempool.h"
static MEMPOOL* list_pool = NULL;
#endif

/*
 * list_append() - append a list onto another one, returning total
 */

LIST *
list_append( 
	LIST	*l,
	LIST	*nl )
{
	if( !nl )
	{
	    /* Just return l */
	}
	else if( !l )
	{
	    l = nl;
	}
	else
	{
	    /* Graft two non-empty lists. */
	    l->tail->next = nl;
	    l->tail = nl->tail;
	}

	return l;
}

#ifdef OPT_MINUS_EQUALS_EXT

/*
 * list_remove() - remove items from a list
 */

LIST *
list_remove( 
	LIST	*l,
	LIST	*nl )
{
    LIST *newlist = L0;
    LIST *list;
    /* Remove values */
    for ( list = l; list; list = list->next )
    {
	LIST *variable;
	int found = 0;
	for ( variable = nl; variable; variable = variable->next )
	{
	    if ( list->string == variable->string )
	    {
		found = 1;
		break;
	    }
	}
	if ( !found )
	    newlist = list_new( newlist, list->string, 0 );
    }

    list_free( l );
    return newlist;
}

#endif

/*
 * list_new() - tack a string onto the end of a list of strings
 */

LIST *
list_new( 
	LIST	*head,
	const char *string,
	int	copy )
{
	LIST *l;

	if( DEBUG_LISTS )
	    printf( "list > %s <\n", string );

	/* Copy/newstr as needed */

	string = copy ? copystr( string ) : newstr( string );

	/* Get list struct from freelist, if one available.  */
	/* Otherwise allocate. */
	/* If from freelist, must free string first */

	if( freelist )
	{
	    l = freelist;
	    freestr( l->string );
	    freelist = freelist->next;
	}
	else
	{
#ifdef OPT_IMPROVED_MEMUSE_EXT
	    if (!list_pool) {
		list_pool = mempool_create("LIST", sizeof(LIST));
	    }
	    l = mempool_alloc(list_pool);
#else
	    l = (LIST *)malloc( sizeof( *l ) );
#endif
	}

	/* If first on chain, head points here. */
	/* If adding to chain, tack us on. */
	/* Tail must point to this new, last element. */

	if( !head ) head = l;
	else head->tail->next = l;
	head->tail = l;
	l->next = 0;

	l->string = string;

	return head;
}

/*
 * list_copy() - copy a whole list of strings (nl) onto end of another (l)
 */

LIST *
list_copy( 
	LIST	*l,
	LIST 	*nl )
{
	for( ; nl; nl = list_next( nl ) )
	    l = list_new( l, nl->string, 1 );

	return l;
}

/*
 * list_sublist() - copy a subset of a list of strings
 */

LIST *
list_sublist( 
	LIST	*l,
	int	start,
	int	count )
{
	LIST	*nl = 0;

	for( ; l && start--; l = list_next( l ) )
	    ;

	for( ; l && count--; l = list_next( l ) )
	    nl = list_new( nl, l->string, 1 );

	return nl;
}

/*
 * list_free() - free a list of strings
 */

void
list_free( LIST	*head )
{
	/* Just tack onto freelist. */

	if( head )
	{
	    head->tail->next = freelist;
	    freelist = head;
	}
}

/*
 * list_print() - print a list of strings to stdout
 */

void
list_print( LIST *l )
{
	for( ; l; l = list_next( l ) )
	    printf( "%s ", l->string );
}

/*
 * list_printq() - print a list of safely quoted strings to a file
 */

void
list_printq( FILE *out, LIST *l )
{
	/* Dump each word, enclosed in "s */
	/* Suitable for Jambase use. */

	for( ; l; l = list_next( l ) )
	{
	    const char *p = l->string;
	    const char *ep = p + strlen( p );
	    const char *op = p;

	    fputc( '\n', out );
	    fputc( '\t', out );
	    fputc( '"', out );

	    /* Any embedded "'s?  Escape them */

	    while( (p = (char *)memchr( op, '"',  ep - op )) )
	    {
		fwrite( op, p - op, 1, out );
		fputc( '\\', out );
		fputc( '"', out );
		op = p + 1;
	    }

	    /* Write remainder */

	    fwrite( op, ep - op, 1, out );
	    fputc( '"', out );
	    fputc( ' ', out );
	}
}

/*
 * list_length() - return the number of items in the list
 */

int
list_length( LIST *l )
{
	int n = 0;

	for( ; l; l = list_next( l ), ++n )
	    ;

	return n;
}

/*
 * Borrowed from https://alumnus.alumni.caltech.edu/~pje/llmsort.html.
 */
static void *list_sort_helper(void *p, unsigned index,
	int (*compare)(void *, void *, void *), void *pointer, unsigned long *pcount)
{
	unsigned base;
	unsigned long block_size;

	struct record
	{
		struct record *next[1];
		/* other members not directly accessed by this function */
	};

	struct tape
	{
		struct record *first, *last;
		unsigned long count;
	} tape[4];

	/* Distribute the records alternately to tape[0] and tape[1]. */

	tape[0].count = tape[1].count = 0L;
	tape[0].first = NULL;
	base = 0;
	while (p != NULL)
	{
		struct record *next = ((struct record *)p)->next[index];
		((struct record *)p)->next[index] = tape[base].first;
		tape[base].first = ((struct record *)p);
		tape[base].count++;
		p = next;
		base ^= 1;
	}

	/* If the list is empty or contains only a single record, then */
	/* tape[1].count == 0L and this part is vacuous.               */

	for (base = 0, block_size = 1L; tape[base+1].count != 0L;
		base ^= 2, block_size <<= 1)
	{
		int dest;
		struct tape *tape0, *tape1;
		tape0 = tape + base;
		tape1 = tape + base + 1;
		dest = base ^ 2;
		tape[dest].count = tape[dest+1].count = 0;
		for (; tape0->count != 0; dest ^= 1)
		{
			unsigned long n0, n1;
			struct tape *output_tape = tape + dest;
			n0 = n1 = block_size;
			while (1)
			{
				struct record *chosen_record;
				struct tape *chosen_tape;
				if (n0 == 0 || tape0->count == 0)
				{
					if (n1 == 0 || tape1->count == 0)
						break;
					chosen_tape = tape1;
					n1--;
				}
				else if (n1 == 0 || tape1->count == 0)
				{
					chosen_tape = tape0;
					n0--;
				}
				else if ((*compare)(tape0->first, tape1->first, pointer) > 0)
				{
					chosen_tape = tape1;
					n1--;
				}
				else
				{
					chosen_tape = tape0;
					n0--;
				}
				chosen_tape->count--;
				chosen_record = chosen_tape->first;
				chosen_tape->first = chosen_record->next[index];
				if (output_tape->count == 0)
					output_tape->first = chosen_record;
				else
					output_tape->last->next[index] = chosen_record;
				output_tape->last = chosen_record;
				output_tape->count++;
			}
		}
	}

	if (tape[base].count > 1L)
		tape[base].last->next[index] = NULL;
	if (pcount != NULL)
		*pcount = tape[base].count;
	return tape[base].first;
}

static int compare_case_sensitive_strings(LIST *p, LIST *q, void *pointer)
{
    return strcmp(p->string, q->string);
}
	
static int compare_case_insensitive_strings(LIST *p, LIST *q, void *pointer)
{
#if defined(_MSC_VER)
	return stricmp(p->string, q->string);
#else
	return strcasecmp(p->string, q->string);
#endif
}
	
/*
 *
 */
LIST *list_sort( LIST *l, int case_sensitive )
{
	LIST *nl = list_sort_helper( l, 0, case_sensitive ? (int (*)(void*, void*, void*))compare_case_sensitive_strings : (int (*)(void*, void*, void*))compare_case_insensitive_strings, NULL, NULL );
	LIST *tail = nl;
	while ( tail->next )
		tail = tail->next;
	nl->tail = tail;
	return nl;
}

/*
 * lol_init() - initialize a LOL (list of lists)
 */

void
lol_init( LOL *lol )
{
	lol->count = 0;
}

/*
 * lol_add() - append a LIST onto an LOL
 */

void
lol_add( 
	LOL	*lol,
	LIST	*l )
{
	if( lol->count < LOL_MAX )
	    lol->list[ lol->count++ ] = l;
}

/*
 * lol_free() - free the LOL and its LISTs
 */

void
lol_free( LOL *lol )
{
	int i;

	for( i = 0; i < lol->count; i++ )
	    list_free( lol->list[i] );

	lol->count = 0;
}

/*
 * lol_get() - return one of the LISTs in the LOL
 */

LIST *
lol_get( 
	LOL	*lol,
	int	i )
{
	return i < lol->count ? lol->list[i] : 0;
}

/*
 * lol_print() - debug print LISTS separated by ":"
 */

void
lol_print( LOL *lol )
{
	int i;

	for( i = 0; i < lol->count; i++ )
	{
	    if( i )
		printf( " : " );
	    list_print( lol->list[i] );
	}
}
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
void
list_done(void)
{
#ifdef OPT_IMPROVED_MEMUSE_EXT
    mempool_done(list_pool);
#endif
}
#endif /* OPT_DEBUG_MEM_TOTALS_EXT */

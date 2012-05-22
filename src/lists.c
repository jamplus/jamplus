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
	NewList	*l )
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
	    newlist_free( lol->list[i] );

	lol->count = 0;
}

/*
 * lol_get() - return one of the LISTs in the LOL
 */

NewList *
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
	    newlist_print( lol->list[i] );
	}
}

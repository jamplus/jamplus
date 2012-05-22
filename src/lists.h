/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * Structures defined:
 *
 *	LOL - list of LISTs
 *
 * External routines:
 *
 *	lol_init() - initialize a LOL (list of lists)
 *	lol_add() - append a LIST onto an LOL
 *	lol_free() - free the LOL and its LISTs
 *	lol_get() - return one of the LISTs in the LOL
 *	lol_print() - debug print LISTS separated by ":"
 */

/*
 * LOL - list of LISTs
 */

#include "newlist.h"

typedef struct _lol LOL;

# define LOL_MAX 9

struct _lol {
	int	count;
	NewList	*list[ LOL_MAX ];
} ;

void	lol_add( LOL *lol, NewList *l );
void	lol_init( LOL *lol );
void	lol_free( LOL *lol );
NewList *	lol_get( LOL *lol, int i );
void	lol_print( LOL *lol );

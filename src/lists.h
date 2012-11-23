/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * Structures defined:
 *
 *	LIST - list of strings
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
 * LIST - list of strings
 */

struct LIST;
struct LISTITEM;

typedef struct LIST LIST;
typedef struct LISTITEM LISTITEM;

/*
 * LOL - list of LISTs
 */

typedef struct _lol LOL;

# define LOL_MAX 9

struct _lol {
	int	count;
	LIST	*list[ LOL_MAX ];
} ;

LISTITEM* list_first(LIST* list);
LISTITEM* list_next(LISTITEM* item);
char const* list_value(LISTITEM* item);

LIST* list_new(void);
void list_free(LIST* list);

int list_length(LIST* list);
int list_empty(LIST* list);
int list_equal(LIST* a, LIST* b);
/* Everything in l0 is in l1 */
int list_in(LIST* l0, LIST* l1);

LIST* list_append(LIST* list, char const* value, int copy);
/* Takes ownership of tail */
LIST* list_appendList(LIST* list, LIST* tail);
LIST* list_copy(LIST* head, LIST* list);
LIST* list_copytail(LIST* head, LISTITEM* first, int maxNumToCopy);
LIST* list_sublist(LIST* list, int start, int count);
LIST* list_remove(LIST* list, LIST* removeItems);
LIST* list_sort(LIST* list, int caseSensitive);

void list_print(LIST* list);
void list_printq(FILE* out, LIST* list);

void list_done(void);

void	lol_add( LOL *lol, LIST *l );
void	lol_init( LOL *lol );
void	lol_free( LOL *lol );
LIST *	lol_get( LOL *lol, int i );
void	lol_print( LOL *lol );

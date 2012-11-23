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
 *	list_first() - return the first list item in a list
 *	list_next() - return the next item in the list (or NULL if at end)
 *	list_value() - return the string stored in a list item
 *	list_new() - create a new, empty, list
 *	list_free() - free a list (includes freeing all the list items)
 *	list_length() - return the number of items in a list
 *	list_empty() - check if a list contains zero items
 *	list_equal() - check that two lists contain exactly the same items in the
 *	same order.
 *	list_in() - checks that a list is a subset of another
 *	list_append() - appends a string to a list
 *	list_appendList() - joins two lists together into one
 *	list_copy() - create a copy of a list
 *	list_copytail() - create a copy of a subsection of a list
 *	list_sublist() - create a copy of a subsection of a list
 *	list_remove() - remove a set of items from a list
 *	list_sort() - sort a list according to the item values
 *	list_print() - print the strings in a list to stdout
 *	list_printq() - print the strings in a list to a file, safely quoted
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

# define L0 ((LIST* )0)

void	lol_add( LOL *lol, LIST *l );
void	lol_init( LOL *lol );
void	lol_free( LOL *lol );
LIST *	lol_get( LOL *lol, int i );
void	lol_print( LOL *lol );

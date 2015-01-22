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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define USE_MEMPOOL (1)
#define USE_COPYONWRITE (1)

struct LISTITEM {
	struct LISTITEM* next;
	char const* string;
};

struct LIST {
	struct LISTITEM* head;
	struct LISTITEM** tail;
#if USE_COPYONWRITE
	unsigned int refs;
#endif
};

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

/* Allocators */
#if USE_MEMPOOL

#include "mempool.h"

/* Note: the pool is shared when non-COW lists are on as the head and item are the same size */
static MEMPOOL* g_listPool = NULL;
static MEMPOOL* g_listHeadPool = NULL;
static LISTITEM* allocItem(void)
{
	if(!g_listPool) {
		g_listPool = mempool_create("LIST", sizeof(LISTITEM));
#if !USE_COPYONWRITE
		g_listHeadPool = g_listPool;
#endif
	}

	return mempool_alloc(g_listPool);
}

static LIST* allocHead(void)
{
	if(!g_listHeadPool) {
		g_listHeadPool = mempool_create("LIST", sizeof(LIST));
#if !USE_COPYONWRITE
		g_listPool = g_listHeadPool;
#endif
	}
	return mempool_alloc(g_listHeadPool);
}

static void freeItem(LISTITEM* item)
{
	mempool_free(g_listPool, item);
}

static void freeHead(LIST* list)
{
	mempool_free(g_listHeadPool, list);
}

void list_done(void)
{
	mempool_done(g_listPool);
#if USE_COPYONWRITE
	mempool_done(g_listHeadPool);
#endif
}

#else

static size_t g_allocated = 0;
static LISTITEM* allocItem(void)
{
	g_allocated += sizeof(LISTITEM);
	return malloc(sizeof(LISTITEM));
}

static LIST* allocHead(void)
{
	g_allocated += sizeof(LIST);
	return malloc(sizeof(LIST));
}

static void freeItem(LISTITEM* item)
{
	g_allocated -= sizeof(LISTITEM);
	free(item);
}

static void freeHead(LIST* list)
{
	g_allocated -= sizeof(LIST);
	free(list);
}

void list_done(void)
{
	printf("LIST: %luK allocated at exit\n", g_allocated / 1024);
}
#endif

LIST* list_realcopy(LIST* head, LIST* list);

/* List implementation */
LISTITEM* list_first(LIST* list)
{
	if(list) {
		return list->head;
	} else {
		return NULL;
	}
}

LISTITEM* list_next(LISTITEM* item)
{
	return item->next;
}

char const* list_value(LISTITEM* item)
{
	return item->string;
}

LIST* list_new(void)
{
	LIST* list = allocHead();
	list->head = NULL;
	list->tail = &list->head;
#if USE_COPYONWRITE
	list->refs = 1;
#endif

	return list;
}

void list_freeitem(LISTITEM* item)
{
	freestr(item->string);
	freeItem(item);
}

void list_free(LIST* list)
{
#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		list->refs -= 1;
	}
	else
#endif
	{
		LISTITEM* item;
		for(item = list_first(list); item;) {
			LISTITEM* n = list_next(item);
			list_freeitem(item);
			item = n;
		}
		freeHead(list);
	}
}

int list_length(LIST* list)
{
	int l = 0;
	LISTITEM* item;
	for(item = list_first(list); item; item = list_next(item)) {
		l += 1;
	}
	return l;
}

int list_empty(LIST* list)
{
	return !list_first(list);
}

int list_in(LIST* l0, LIST* l1)
{
	LISTITEM* item;

	if(!l1) { return 0; }
	if(!l0) { return 1; }

	for(item = list_first(l0); item; item = list_next(item)) {
		int found = 0;
		LISTITEM* searchItem;
		for(searchItem = list_first(l1); searchItem; searchItem = list_next(searchItem)) {
			if(!strcmp(list_value(item), list_value(searchItem))) {
				found = 1;
				break;
			}
		}
		if(!found) {
			return 0;
		}
	}

	return 1;
}

LIST* list_append(LIST* list, char const* value, int copy)
{
	LISTITEM* item;

#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		LIST* copy = list_realcopy(NULL, list);
		list_free(list);
		list = copy;
	}
#endif

	if(DEBUG_LISTS) {
		printf("list > %s <\n", value);
	}
	if(!list)
	{
		list = list_new();
	}

	item = allocItem();
	item->string = copy? copystr(value) : newstr(value);

	item->next = NULL;
	*list->tail = item;

	list->tail = &item->next;

	return list;
}

LIST* list_appendList(LIST* list, LIST* tail)
{
	if(!list) { return tail; }
	if(!tail) { return list; }

#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		LIST* copy = list_realcopy(NULL, list);
		list_free(list);
		list = copy;
	}
	if(tail && tail->refs > 1) {
		LISTITEM* item;
		for(item = list_first(tail); item; item = list_next(item)) {
			list_append(list, list_value(item), 1);
		}

		list_free(tail);

		return list;
	}
	else
#endif
	{
		LISTITEM* item;
		for(item = list_first(tail); item;)
		{
			LISTITEM* next = list_next(item);

			/* Move item into list */
			item->next = NULL;
			*(list->tail) = item;
			list->tail = &(item->next);

			item = next;
		}

		/* Dispose of the old list head */
		tail->head = NULL;
		tail->tail = &(tail->head);
		list_free(tail);

		return list;
	}
}

LIST* list_realcopy(LIST* head, LIST* list)
{
	LIST* result = head;
	LISTITEM* item;
	for(item = list_first(list); item ; item = list_next(item)) {
		result = list_append(result, list_value(item), 1);
	}

	return result;
}

LIST* list_copy(LIST* head, LIST* list)
{
#if USE_COPYONWRITE
	if(!head) {
		if(list) { list->refs += 1; }
		return list;
	} else if(!list) {
		if(head) { head->refs += 1; }
		return head;
	} else
#endif
	{
		return list_realcopy(head, list);
	}
}

LIST* list_copytail(LIST* head, LISTITEM* first, int maxNumToCopy)
{
	LIST* result;

#if USE_COPYONWRITE
	if(head && head->refs > 1) {
		LIST* copy = list_realcopy(NULL, head);
		list_free(head);
		head = copy;
	}
#endif

	result = head;
	for(; first && maxNumToCopy--; first = list_next(first)) {
		result = list_append(result, list_value(first), 1);
	}

	return result;
}

LIST* list_sublist(LIST* list, int start, int count)
{
	LIST* result = NULL;
	LISTITEM* item = list_first(list);
	for(; item && start--; item = list_next(item));
	for(; item && count--; item = list_next(item)) {
		result = list_append(result, list_value(item), 1);
	}

	return result;
}

LIST* list_remove(LIST* list, LIST* removeItems)
{
	LISTITEM** prevNext;

	if(!list) { return NULL; }
	if(!removeItems) { return list; }

#if USE_COPYONWRITE
	if(list->refs > 1) {
		LIST* copy = list_realcopy(NULL, list);
		list_free(list);
		list = copy;
	}
#endif

	prevNext = &list->head;
	while(*prevNext) {
		int remove = 0;
		LISTITEM* searchItem;
		for(searchItem = list_first(removeItems); searchItem; searchItem = list_next(searchItem)) {
			if(list_value(searchItem) == list_value(*prevNext)) {
				remove = 1;
				break;
			}
		}

		if(remove)
		{
			LISTITEM* item = *prevNext;
			*prevNext = item->next;
			list_freeitem(item);
		} else {
			prevNext = &((*prevNext)->next);
		}
	}

	list->tail = prevNext;
	return list;
}

int list_equal(LIST* a, LIST* b)
{
	LISTITEM* ai = list_first(a);
	LISTITEM* bi = list_first(b);

	for(; ai && bi; ai = list_next(ai), bi = list_next(bi)) {
		if(list_value(ai) != list_value(bi)) {
			return 0;
		}
	}

	return !ai && !bi;
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

static int compare_case(LISTITEM *p, LISTITEM *q, void *pointer)
{
    return strcmp(list_value(p), list_value(q));
}
	
static int compare_nocase(LISTITEM *p, LISTITEM *q, void *pointer)
{
#if defined(_MSC_VER)
	return stricmp(list_value(p), list_value(q));
#else
	return strcasecmp(list_value(p), list_value(q));
#endif
}

LIST* list_sort(LIST* list, int caseSensitive)
{
	LISTITEM* newHead;
	LISTITEM* newLast;

	if(!list || !list_first(list)) { return list; }

#if USE_COPYONWRITE
	if(list->refs > 1) {
		LIST* copy = list_realcopy(NULL, list);
		list_free(list);
		list = copy;
	}
#endif

	newHead = list_sort_helper(list_first(list), 0, (int (*)(void*, void*, void*))(caseSensitive? &compare_case : &compare_nocase), NULL, NULL);

	newLast = newHead;
	for(; list_next(newLast); newLast = list_next(newLast));
	list->head = newHead;
	list->tail = &newLast->next;

	return list;
}

void list_print(LIST* list)
{
	LISTITEM* item;
	for(item = list_first(list); item; item = list_next(item)) {
		printf("%s ", list_value(item));
	}
}

void list_printq(FILE* out, LIST* list)
{
	LISTITEM* item;
	for(item = list_first(list); item; item = list_next(item)) {
		/* Icky code from lists.c */

		const char *p = list_value(item);
		const char *ep = p + strlen( p );
		const char *op = p;

		fputc( '\n', out );
		fputc( '\t', out );
		fputc( '"', out );

		/* Any embedded "'s?  Escape them */

		while( ( p = (char *)memchr( op, '"',  ep - op ) ) )
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


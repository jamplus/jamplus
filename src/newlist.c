#include "jam.h"
#include "newlist.h"
#include "newstr.h"

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#define USE_MEMPOOL (1)
#define USE_COPYONWRITE (1)

struct NewListItem {
	struct NewListItem* next;
	char const* string;
};

struct NewList {
	struct NewListItem* head;
	struct NewListItem** tail;
#if USE_COPYONWRITE
	unsigned int refs;
#endif
};

/* Allocators */
#if USE_MEMPOOL

#include "mempool.h"

/* Note: the pool is shared when non-COW lists are on as the head and item are the same size */
static MEMPOOL* g_listPool = NULL;
static MEMPOOL* g_listHeadPool = NULL;
static NewListItem* allocItem(void)
{
	if(!g_listPool) {
		g_listPool = mempool_create("NEWLIST", sizeof(NewListItem));
#if !USE_COPYONWRITE
		g_listHeadPool = g_listPool;
#endif
	}

	return mempool_alloc(g_listPool);
}

static NewList* allocHead(void)
{
	if(!g_listHeadPool) {
		g_listHeadPool = mempool_create("NEWLIST", sizeof(NewList));
#if !USE_COPYONWRITE
		g_listPool = g_listHeadPool;
#endif
	}
	return mempool_alloc(g_listHeadPool);
}

static void freeItem(NewListItem* item)
{
	mempool_free(g_listPool, item);
}

static void freeHead(NewList* list)
{
	mempool_free(g_listHeadPool, list);
}

void newlist_done(void)
{
	mempool_done(g_listPool);
#if USE_COPYONWRITE
	mempool_done(g_listHeadPool);
#endif
}

#else

static size_t g_allocated = 0;
static NewListItem* allocItem(void)
{
	g_allocated += sizeof(NewListItem);
	return malloc(sizeof(NewListItem));
}

static NewList* allocHead(void)
{
	g_allocated += sizeof(NewList);
	return malloc(sizeof(NewList));
}

static void freeItem(NewListItem* item)
{
	g_allocated -= sizeof(NewListItem);
	free(item);
}

static void freeHead(NewList* list)
{
	g_allocated -= sizeof(NewList);
	free(list);
}

void newlist_done(void)
{
	printf("NEWLIST: %luK allocated at exit\n", g_allocated / 1024);
}
#endif

/* List implementation */
NewListItem* newlist_first(NewList* list)
{
	if(list) {
		return list->head;
	} else {
		return NULL;
	}
}

NewListItem* newlist_next(NewListItem* item)
{
	return item->next;
}

char const* newlist_value(NewListItem* item)
{
	return item->string;
}

NewList* newlist_new(void)
{
	NewList* list = allocHead();
	list->head = NULL;
	list->tail = &list->head;
#if USE_COPYONWRITE
	list->refs = 1;
#endif

	return list;
}

void newlist_freeitem(NewListItem* item)
{
	freestr(item->string);
	freeItem(item);
}

void newlist_free(NewList* list)
{
#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		list->refs -= 1;
	}
	else
#endif
	{
		NewListItem* item;
		for(item = newlist_first(list); item;) {
			NewListItem* n = newlist_next(item);
			newlist_freeitem(item);
			item = n;
		}
		freeHead(list);
	}
}

int newlist_length(NewList* list)
{
	int l = 0;
	NewListItem* item;
	for(item = newlist_first(list); item; item = newlist_next(item)) {
		l += 1;
	}
	return l;
}

int newlist_empty(NewList* list)
{
	return !newlist_first(list);
}

int newlist_in(NewList* l0, NewList* l1)
{
	NewListItem* item;

	if(!l1) { return 0; }
	if(!l0) { return 1; }

	for(item = newlist_first(l0); item; item = newlist_next(item)) {
		int found = 0;
		NewListItem* searchItem;
		for(searchItem = newlist_first(l1); searchItem; searchItem = newlist_next(searchItem)) {
			if(!strcmp(newlist_value(item), newlist_value(searchItem))) {
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

NewList* newlist_append(NewList* list, char const* value, int copy)
{
	NewListItem* item;

#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		NewList* copy = newlist_realcopy(NULL, list);
		newlist_free(list);
		list = copy;
	}
#endif

	if(DEBUG_LISTS) {
		printf("list > %s <\n", value);
	}
	if(!list)
	{
		list = newlist_new();
	}

	item = allocItem();
	item->string = copy? copystr(value) : newstr(value);

	item->next = NULL;
	*list->tail = item;

	list->tail = &item->next;

	return list;
}

NewList* newlist_appendList(NewList* list, NewList* tail)
{
	if(!list) { return tail; }
	if(!tail) { return list; }

#if USE_COPYONWRITE
	if(list && list->refs > 1) {
		NewList* copy = newlist_realcopy(NULL, list);
		newlist_free(list);
		list = copy;
	}
	if(tail && tail->refs > 1) {
		NewListItem* item;
		for(item = newlist_first(tail); item; item = newlist_next(item)) {
			newlist_append(list, newlist_value(item), 1);
		}

		newlist_free(tail);

		return list;
	}
	else
#endif
	{
		NewListItem* item;
		for(item = newlist_first(tail); item;)
		{
			NewListItem* next = newlist_next(item);

			/* Move item into list */
			item->next = NULL;
			*(list->tail) = item;
			list->tail = &(item->next);

			item = next;
		}

		/* Dispose of the old list head */
		tail->head = NULL;
		tail->tail = &(tail->head);
		newlist_free(tail);

		return list;
	}
}

NewList* newlist_realcopy(NewList* head, NewList* list)
{
	NewList* result = head;
	NewListItem* item;
	for(item = newlist_first(list); item ; item = newlist_next(item)) {
		result = newlist_append(result, newlist_value(item), 1);
	}

	return result;
}

NewList* newlist_copy(NewList* head, NewList* list)
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
		return newlist_realcopy(head, list);
	}
}

NewList* newlist_copytail(NewList* head, NewListItem* first, int maxNumToCopy)
{
	NewList* result;

#if USE_COPYONWRITE
	if(head && head->refs > 1) {
		NewList* copy = newlist_realcopy(NULL, head);
		newlist_free(head);
		head = copy;
	}
#endif

	result = head;
	for(; first && maxNumToCopy--; first = newlist_next(first)) {
		result = newlist_append(result, newlist_value(first), 1);
	}

	return result;
}

NewList* newlist_sublist(NewList* list, int start, int count)
{
	NewList* result = NULL;
	NewListItem* item = newlist_first(list);
	for(; item && start--; item = newlist_next(item));
	for(; item && count--; item = newlist_next(item)) {
		result = newlist_append(result, newlist_value(item), 1);
	}

	return result;
}

NewList* newlist_remove(NewList* list, NewList* removeItems)
{
	NewListItem** prevNext;

	if(!list) { return NULL; }
	if(!removeItems) { return list; }

#if USE_COPYONWRITE
	if(list->refs > 1) {
		NewList* copy = newlist_realcopy(NULL, list);
		newlist_free(list);
		list = copy;
	}
#endif

	prevNext = &list->head;
	while(*prevNext) {
		int remove = 0;
		NewListItem* searchItem;
		for(searchItem = newlist_first(removeItems); searchItem; searchItem = newlist_next(searchItem)) {
			if(newlist_value(searchItem) == newlist_value(*prevNext)) {
				remove = 1;
				break;
			}
		}

		if(remove)
		{
			NewListItem* item = *prevNext;
			*prevNext = item->next;
			newlist_freeitem(item);
		} else {
			prevNext = &((*prevNext)->next);
		}
	}

	list->tail = prevNext;
	return list;
}

int newlist_equal(NewList* a, NewList* b)
{
	NewListItem* ai = newlist_first(a);
	NewListItem* bi = newlist_first(b);

	for(; ai && bi; ai = newlist_next(ai), bi = newlist_next(bi)) {
		if(newlist_value(ai) != newlist_value(bi)) {
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

static int compare_case(NewListItem *p, NewListItem *q, void *pointer)
{
    return strcmp(newlist_value(p), newlist_value(q));
}
	
static int compare_nocase(NewListItem *p, NewListItem *q, void *pointer)
{
#if defined(_MSC_VER)
	return stricmp(newlist_value(p), newlist_value(q));
#else
	return strcasecmp(newlist_value(p), newlist_value(q));
#endif
}

NewList* newlist_sort(NewList* list, int caseSensitive)
{
	NewListItem* newHead;
	NewListItem* newLast;

	if(!list || !newlist_first(list)) { return list; }

#if USE_COPYONWRITE
	if(list->refs > 1) {
		NewList* copy = newlist_realcopy(NULL, list);
		newlist_free(list);
		list = copy;
	}
#endif

	newHead = list_sort_helper(newlist_first(list), 0, caseSensitive? &compare_case : &compare_nocase, NULL, NULL);

	newLast = newHead;
	for(; newlist_next(newLast); newLast = newlist_next(newLast));
	list->head = newHead;
	list->tail = &newLast->next;

	return list;
}

void newlist_print(NewList* list)
{
	NewListItem* item;
	for(item = newlist_first(list); item; item = newlist_next(item)) {
		printf("%s ", newlist_value(item));
	}
}

void newlist_printq(FILE* out, NewList* list)
{
	NewListItem* item;
	for(item = newlist_first(list); item; item = newlist_next(item)) {
		/* Icky code from lists.c */

		const char *p = newlist_value(item);
		const char *ep = p + strlen( p );
		const char *op = p;

		fputc( '\n', out );
		fputc( '\t', out );
		fputc( '"', out );

		/* Any embedded "'s?  Escape them */

		while( p = (char *)memchr( op, '"',  ep - op ) )
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


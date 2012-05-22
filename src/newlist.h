#ifndef NEWLIST_H__
#define NEWLIST_H__

#include <stdio.h>

struct NewList;
struct NewListItem;

typedef struct NewList NewList;
typedef struct NewListItem NewListItem;

NewListItem* newlist_first(NewList* list);
NewListItem* newlist_next(NewListItem* item);
char const* newlist_value(NewListItem* item);

NewList* newlist_new(void);
void newlist_free(NewList* list);

int newlist_length(NewList* list);
int newlist_empty(NewList* list);
int newlist_equal(NewList* a, NewList* b);
/* Everything in l0 is in l1 */
int newlist_in(NewList* l0, NewList* l1);

NewList* newlist_append(NewList* list, char const* value, int copy);
/* Takes ownership of tail */
NewList* newlist_appendList(NewList* list, NewList* tail);
NewList* newlist_copy(NewList* head, NewList* list);
NewList* newlist_realcopy(NewList* head, NewList* list);
NewList* newlist_copytail(NewList* head, NewListItem* first, int maxNumToCopy);
NewList* newlist_sublist(NewList* list, int start, int count);
NewList* newlist_remove(NewList* list, NewList* removeItems);
NewList* newlist_sort(NewList* list, int caseSensitive);

void newlist_print(NewList* list);
void newlist_printq(FILE* out, NewList* list);

void newlist_done(void);

#endif

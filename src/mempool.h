#ifndef MEMPOOL_H
#define MEMPOOL_H

/* A memory pool is a stupid allocator that always allocates the same
 * sized object and never frees the memory it allocates.  The
 * advantage is a great reduction in memory fragmentation. */

#include <stddef.h>

typedef struct _MEMPOOL MEMPOOL;

MEMPOOL* mempool_create(const char* name, size_t item_size);
void* mempool_alloc(MEMPOOL* pool);
void mempool_free(MEMPOOL* pool, void* item);
void mempool_done(MEMPOOL* pool);

#endif

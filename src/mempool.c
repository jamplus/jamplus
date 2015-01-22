#include <stdio.h>
#include <stdlib.h>
#include "jam.h"
#include "mempool.h"

#define MEMPOOL_CHUNKSIZE (1024 * 128)

typedef struct _MEMPOOL_FREE_BLOCK {
    struct _MEMPOOL_FREE_BLOCK* next;
} MEMPOOL_FREE_BLOCK;

typedef struct _MEMPOOL {
    size_t item_size;
    const char* name;		/* name for debugging output */
    long malloc_bytes;		/* # of bytes currently allocated via
				 * malloc() */
    long alloc_count;		/* # of times mempool_alloc() is
				 * called. */
    long free_count;		/* # of times mempool_free() called. */
    MEMPOOL_FREE_BLOCK* free_list;
} _MEMPOOL;

static MEMPOOL_FREE_BLOCK*
mempool_alloc_chunk(MEMPOOL* pool)
{
    MEMPOOL_FREE_BLOCK* chunk;
    MEMPOOL_FREE_BLOCK* p;
    MEMPOOL_FREE_BLOCK* end;
    long num_items;
    size_t chunk_size;
    size_t item_size;

    item_size = pool->item_size;
    num_items = (long)(MEMPOOL_CHUNKSIZE / item_size);
    chunk_size = num_items * item_size;

    chunk = malloc(chunk_size);
    pool->malloc_bytes += (long)chunk_size;
    p = chunk;
    end = (MEMPOOL_FREE_BLOCK*)((char*)chunk + chunk_size);
    while (1) {
	MEMPOOL_FREE_BLOCK* next = (MEMPOOL_FREE_BLOCK*)((char*)p + item_size);
	if (next < end) {
	    p->next = next;
	} else {
	    p->next = NULL;
	    break;
	}
	p = next;
    }
    return chunk;
}


MEMPOOL*
mempool_create(const char* name, size_t item_size)
{
    MEMPOOL* pool = malloc(sizeof(MEMPOOL));
    pool->name = name;
    pool->item_size = item_size;
    pool->free_list = NULL;
    pool->malloc_bytes = 0;
    pool->alloc_count = 0;
    pool->free_count = 0;
    return pool;
}


void*
mempool_alloc(MEMPOOL* pool)
{
    MEMPOOL_FREE_BLOCK* block;

    ++pool->alloc_count;

    if (!pool->free_list) {
	/* with an empty free list, we need more memory */
	pool->free_list = mempool_alloc_chunk(pool);
    }

    /* pull off the head of the free list */
    block = pool->free_list;
    pool->free_list = pool->free_list->next;
    return block;
}


void
mempool_free(MEMPOOL* pool, void* item)
{
    if (item) {
	MEMPOOL_FREE_BLOCK* block;

	++pool->free_count;

	/* put this block on the head of the free list */
	block = (MEMPOOL_FREE_BLOCK*)item;
	block->next = pool->free_list;
	pool->free_list = block;
    }
}


void
mempool_done(MEMPOOL* pool)
{
    if (pool && (DEBUG_MEM
#ifdef OPT_DEBUG_MEM_TOTALS_EXT
	    || DEBUG_MEM_TOTALS
#endif
    )) {
    printf("pool %s: %ldK allocated, %ld allocs, %ld frees (%ld leaked)\n",
	       pool->name,
	       pool->malloc_bytes / 1024,
	       pool->alloc_count,
	       pool->free_count,
	       pool->alloc_count - pool->free_count);
    }
}

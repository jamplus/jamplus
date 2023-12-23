/*
 * This file is not yet part of Jam
 */

/*
 * hcache.h - handle #includes in source files
 */

#pragma once

#include "xxhash.h"

struct checksumdata {
	const char	*boundname;
	int			age;	  /* if too old, we'll remove it from cache */
	time_t      originalmtime;    /* when md5sum was cached  */
	time_t		currentmtime;     /* the last file time the md5sum was checked */
	XXH128_hash_t      contentmd5sum;
	char		contentmd5sum_calculated;
	char		contentmd5sum_changed;
	struct checksumdata	*next;
} ;

/*void hcache_init(void);*/
void hcache_done(void);
LIST *hcache( TARGET *t, LIST *hdrscan );
const char* hcache_get_builtinfilename(void);
#ifdef OPT_BUILTIN_MD5CACHE_EXT
int read_md5sum_string( const char* str, XXH128_hash_t* sum);
int ismd5empty( XXH128_hash_t md5sum );
int getcachedmd5sum( TARGET *t, int forcetimecheck );
int getcachedmd5sumhelper( const char *boundname, XXH128_hash_t newmd5sum, int forcetimecheck );
void setcachedmd5sum( TARGET *t );
const char *checksums_filename();
void checksums_nextpass();
/* Get a filename in cache for given md5sum. */
const char *filecache_getpath(TARGET *t);
const char *filecache_getfilename(TARGET *t, XXH128_hash_t sum, const char* extension);
LIST *filecache_fillvalues(TARGET *t);
void filecache_disable(TARGET *t);
int filecache_retrieve(TARGET *t, XXH128_hash_t buildmd5sum);
void filecache_update(TARGET* t, XXH128_hash_t buildmd5sum);

int checksum_retrieve(TARGET *t, XXH128_hash_t buildmd5sum, int performutime);
void checksum_update(TARGET *t, XXH128_hash_t buildmd5sum);

int hcache_getrulemd5sum( TARGET *t );
void hcache_finalizerulemd5sum( TARGET *t );
#endif

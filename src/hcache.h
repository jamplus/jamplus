/*
 * This file is not yet part of Jam
 */

/*
 * hcache.h - handle #includes in source files
 */

struct checksumdata {
	const char	*boundname;
	int			age;	  /* if too old, we'll remove it from cache */
	time_t      mtime;    /* when md5sum was cached  */
	MD5SUM      contentmd5sum;
	MD5SUM      currentcontentmd5sum;
	char		contentmd5sum_calculated;
	char		contentmd5sum_changed;
	struct checksumdata	*next;
} ;

/*void hcache_init(void);*/
void hcache_done(void);
LIST *hcache( TARGET *t, LIST *hdrscan );
const char* hcache_filename(void);
#ifdef OPT_BUILTIN_MD5CACHE_EXT
int read_md5sum_string( const char* str, MD5SUM sum);
int ismd5empty( MD5SUM md5sum );
int getcachedmd5sum( TARGET *t, int forcetimecheck );
void setcachedmd5sum( TARGET *t );
const char *checksums_filename();
void checksums_nextpass();
/* Get a filename in cache for given md5sum. */
const char *filecache_getpath(TARGET *t);
const char *filecache_getfilename(TARGET *t, MD5SUM sum, const char* extension);
LIST *filecache_fillvalues(TARGET *t);
void filecache_disable(TARGET *t);
int filecache_retrieve(TARGET *t, MD5SUM buildmd5sum);
void filecache_update(TARGET* t);

int checksum_retrieve(TARGET *t, MD5SUM buildmd5sum);
void checksum_update(TARGET *t);

int hcache_getrulemd5sum( TARGET *t );
void hcache_finalizerulemd5sum( TARGET *t );
#endif

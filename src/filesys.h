/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * filesys.h - OS specific file routines
 *
 * 11/04/02 (seiwald) - const-ing for string literals
 */

#include "buffer.h"
#include "xxhash.h"

#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
typedef void (*scanback)( void *closure, const char *file, int found, time_t t, int dir );
#else
typedef void (*scanback)( void *closure, const char *file, int found, time_t t );
#endif

void file_dirscan( const char *dir, scanback func, void *closure );
void file_archscan( const char *arch, scanback func, void *closure );

int file_time( const char *filename, time_t *time );
#ifdef OPT_NODELETE_READONLY
int file_writeable(const char* filename);
#endif
#if defined(OPT_BUILTIN_MD5CACHE_EXT)  ||  defined(OPT_HEADER_CACHE_EXT)
int file_mkdir(const char *inPath);
#endif

#ifdef OPT_HDRPIPE_EXT
FILE* file_popen(const char *cmd, const char *mode);
int file_pclose(FILE *file);
#endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int copyfile(const char *dstin, const char *src, XXH128_hash_t* hash);
int jfindfile(const char* wildcard, BUFFER* foundfilebuff);
const char *md5tostring(XXH128_hash_t sum);
void md5file(const char *filename, XXH128_hash_t* hash);
#endif

#ifdef OPT_SET_JAMPROCESSPATH_EXT
void getexecutablepath(char* buffer, size_t bufferLen);
void getprocesspath(char* buffer, size_t bufferLen);
#endif

#ifdef OPT_PRINT_TOTAL_TIME_EXT
#if _MSC_VER  &&  _MSC_VER < 1300
unsigned __int64 getmilliseconds();
#else
unsigned long long getmilliseconds();
#endif
#endif

int dir_isempty(const char* indir);

int file_absolutepath(const char* partialPath, BUFFER* absbuff);

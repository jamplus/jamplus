/*
 * This file has been donated to Jam.
 */

# include "jam.h"
# include "lists.h"
# include "parse.h"
# include "rules.h"
# include "regexp.h"
# include "headers.h"
# include "newstr.h"
# include "hash.h"
# include "hcache.h"
# include "variable.h"
# include "search.h"
# include "compile.h"
# include "filesys.h"
# include "buffer.h"
#if _MSC_VER
# include <sys/utime.h>
#else
#include <utime.h>
#endif

#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
#include "luasupport.h"
#endif

#ifdef OPT_HEADER_CACHE_EXT

/*
 * Craig W. McPheeters, Alias|Wavefront.  Nov/2001.
 * Jan/2002.  Extensions by Matt Armstrong.
 *    See the file README.header_scan_cache for details on the extensions.
 * Jan/2002.  Modification to extensions by Craig.
 *
 * hcache.c, hcache.h - handle cacheing of #includes in source files
 *
 * Create a cache of files scanned for headers.	 When starting jam,
 * look for the cache file and load it if present.  When finished the
 * binding phase, create a new header cache.  The cache contains
 * files, their timestamps and the header files found in their scan.
 * During the binding phase of jam, look in the header cache first for
 * the headers contained in a file.  If the cache is present and
 * valid, use its contents.  This can result in dramatic speedups on
 * large projects (eg. 3min -> 1min startup on one project.)
 *
 * External routines:
 *    hcache_init() - read and parse the local .jamdeps file.
 *    hcache_done() - write a new .jamdeps file
 *    hcache() - return list of headers on target.  Use cache or do a scan.
 *
 * The dependency file format is an ascii file with 1 line per target.
 * Each line has the following fields:
 * @boundname@ timestamp commandlinemd5sum targetmd5sum age num @file@ @file@ num @hdrscan@ @hdrscan@ ... \n
 *   where the first number is the number of headers, and the second is the
 *   number of elements in the hdrscan list.
 *
 * Filenames may contain any ascii or non-ascii characters.  If they
 * contain the '@' or '#' characters, they are quoted on output and
 * their quoting is handled on input.  Often the '\' character is used
 * for quoting, but as that is so common in NT pathnames, the '#'
 * character is used instead. Both '@' and '#' are characters
 * disallowed in Perforce filenames - and they should be rare in other
 * SCM systems hopefully.  CWM.
 */

struct hcachedata {
	const char		*boundname;
	time_t		time;
	LIST		*includes;
	LIST		*hdrscan; /* the HDRSCAN value for this target */
	int			age;	  /* if too old, we'll remove it from cache */
#ifdef OPT_BUILTIN_MD5CACHE_EXT
	time_t      mtime;    /* when md5sum was cached  */
	MD5SUM      rulemd5sum;
	MD5SUM      currentrulemd5sum;
	MD5SUM      contentmd5sum;
	MD5SUM      currentcontentmd5sum;
#endif
	struct hcachedata	*next;
} ;

typedef struct hcachedata HCACHEDATA ;

typedef struct hcachefile {
	const char		*cachename;
	const char		*cachefilename;
	struct hash		*hcachehash;
	HCACHEDATA		*hcachelist;
	int			dirty;
	struct hcachefile	*next;
} HCACHEFILE;

struct hash *hcachefilehash = 0;
HCACHEFILE *hcachefilelist = 0;

static HCACHEFILE *lasthcachefile;
static const char *lasthcachefile_name;

static int queries = 0;
static int hits = 0;

#ifdef OPT_BUILTIN_MD5CACHE_EXT
#define CACHE_FILE_VERSION "version 1-md5cl"
#else
#define CACHE_FILE_VERSION "version 1"
#endif

/*
 * Return the name of the header cache file.  May return NULL.
 *
 * The user sets this by setting the DEPCACHE variable in a Jamfile.
 * We cache the result so the user can't change the cache file during
 * header scanning.
 */
/*const char* hcache_filename(void)
{
	static const char *name = 0;
	if( !name ) {
		LIST *hcachevar = var_get( "HCACHEFILE" );

		if( hcachevar ) {
			TARGET *t = bindtarget( hcachevar->string );

			pushsettings( t->settings );
			t->boundname = search( t->name, &t->time );
			popsettings( t->settings );

			name = copystr( t->boundname );
		}
	}
	return name;
}
*/
/*
 * Return the maximum age a cache entry can have before it is purged
 * from the cache.
 *
 * A maxage of 0 indicates that the cache entries should never be
 * purged, in effect disabling the aging of cache entries.
 */
static int
cache_maxage(void)
{
	int age = 0;
	LIST *var = var_get( "DEPCACHEMAXAGE" );

	if( list_first(var) ) {
		age = atoi( list_value(list_first(var)) );
		if( age < 0 )
			age = 0;
	}

	return age;
}

/*
 * Read any spaces we're on.  Return the first non-space character
 */
static int
skip_spaces( BUFFER *buff )
{
	int ch = buffer_getchar( buff );

	while( ch == ' ' )
		ch = buffer_getchar( buff );

	return ch;
}

/*
 * Read a string from the file.	 Handle quoted characters.  The
 * returned value is as returned by newstr(), so it need not be freed.
 */
const char *
read_string( BUFFER* buff )
{
	int ch, i = 0;
	char filename[ MAXJPATH ];

	ch = skip_spaces( buff );
	if( ch != '@' )
		return 0;

	ch = buffer_getchar( buff );
	while( ch != '@' && ch != EOF && i < MAXJPATH ) {
		if( ch == '#' ) /* Quote */
			filename[ i++ ] = buffer_getchar( buff );
		else
			filename[ i++ ] = (char)ch;
		ch = buffer_getchar( buff );
	}

	if( ch != '@' )
		return 0;

	filename[ i ] = 0;
	return newstr( filename );
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT

/*
 * Read a md5sum.
 */
void read_md5sum( BUFFER *buff, MD5SUM sum )
{
	int ch, i, val;
	memset(sum, 0, sizeof(*sum));

	ch = skip_spaces( buff );
	val = 0;
	i = 0;
	while( i < MD5_SUMSIZE*2 ) {
		ch = tolower( ch );
		if (ch >= '0' && ch <='9') {
			val = val*16 + ch-'0';
		} else if (ch >= 'a' && ch <='f') {
			val = val*16 + ch-'a'+0xa;
		} else {
			break;
		}
		if ( i&1 ) {
			sum[i/2] = (char)val;
			val = 0;
		}
		i++;
		ch = buffer_getchar( buff );
	}
}

/*
 * Read a md5sum.
 */
int read_md5sum_string( const char* str, MD5SUM sum)
{
	int ch, i, val;
	memset(sum, 0, sizeof(*sum));

	while (*str  &&  *str == ' ')
		str++;
	ch = *str++;
	val = 0;
	i = 0;
	while( ch  &&  i < MD5_SUMSIZE*2 ) {
		ch = tolower( ch );
		if (ch >= '0' && ch <='9') {
			val = val*16 + ch-'0';
		} else if (ch >= 'a' && ch <='f') {
			val = val*16 + ch-'a'+0xa;
		} else {
			break;
		}
		if ( i&1 ) {
			sum[i/2] = (char)val;
			val = 0;
		}
		i++;
		ch = *str++;
	}
	return i == MD5_SUMSIZE*2;
}

#endif

static int
read_int( BUFFER *buff )
{
	int	 ch;
	//  char num[ 30 ];
	int value = 0;

	ch = skip_spaces( buff );
	while( ch >= '0' && ch <= '9' ) {
		//	num[ i++ ] = ch;
		value = (ch - '0') + value * 10;
		ch = buffer_getchar( buff );
	}
	//    num[ i ] = 0;

	/*    return atoi( num );*/
	return value;
}

void
write_string( FILE *f, const char *s )
{
	int i = 0;

	fputc( '@', f );
	while( s[ i ] != 0 ) {
		if( s[ i ] == '@' || s[ i ] == '#' )
			fputc( '#', f ); /* Quote */
		fputc( s[ i++ ], f );
	}
	fputs( "@ ", f );
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT

/*
 * Write a md5sum.
 */
void write_md5sum( FILE *f, MD5SUM sum)
{
	int ch, i, val;

	for( i=0; i<MD5_SUMSIZE; i++ ) {
		val = sum[i];

		ch = val>>4;
		if (ch >= 0xa) {
			fputc( ch-0xa+'a',f );
		} else {
			fputc( ch+'0', f );
		}

		ch = val&15;
		if (ch >= 0xa) {
			fputc( ch-0xa+'a',f );
		} else {
			fputc( ch+'0', f );
		}
	}
	fputc( ' ', f );
}

#endif

static void
write_int( FILE *f, int i )
{
	fprintf( f, "%d ", i );
}

void
hcache_readfile(HCACHEFILE *file)
{
	HCACHEDATA	cachedata, *c, *last = 0;
	FILE	*f;
	int		bad_cache = 1, ch;
	const char	*version;
	BUFFER	buff;
	long	buffsize;

/*    if( ! (hcachename = hcache_filename()) )
	return;*/

	if( ! (f = fopen( file->cachefilename, "rb" )) )
		return;

	fseek( f, 0, SEEK_END );
	buffsize = ftell( f );
	fseek( f, 0, SEEK_SET );
	buffer_init( &buff );
	buffer_resize( &buff, buffsize + 1 );
	if ( fread( buffer_ptr( &buff ), buffsize, 1, f ) != 1 )
	{
		fclose( f );
		goto bail;
	}
	buffer_ptr( &buff )[buffsize] = 0;
	fclose( f );

	version = read_string( &buff );
	ch = buffer_getchar( &buff );
	if (!version || strcmp( version, CACHE_FILE_VERSION ) || ch != '\n' ) {
		goto bail;
	}

	for(;;) {
		int i, count, ch;
		LIST *l;

		c = &cachedata;

		c->boundname = read_string( &buff );
		if( !c->boundname ) /* Test for eof */
			break;

		c->time = read_int( &buff );
		c->age = read_int( &buff ) + 1; /* we're getting older... */

#ifdef OPT_BUILTIN_MD5CACHE_EXT
		c->mtime = read_int( &buff );
		read_md5sum( &buff, c->rulemd5sum );
		memcpy( &c->currentrulemd5sum, &c->rulemd5sum, MD5_SUMSIZE );
		read_md5sum( &buff, c->contentmd5sum );
		memcpy( &c->currentcontentmd5sum, &c->contentmd5sum, MD5_SUMSIZE );
#endif

		if( !c->boundname )
			goto bail;

		/* headers */
		count = read_int( &buff );
		for( l = 0, i = 0; i < count; ++i ) {
			const char *s = read_string( &buff );
			if( !s )
				goto bail;
			l = list_append( l, s, 0 );
		}
		c->includes = l;

		/* hdrscan */
		count = read_int( &buff );
		for( l = 0, i = 0; i < count; ++i ) {
			const char *s = read_string( &buff );
			if( !s )
				goto bail;
			l = list_append( l, s, 0 );
		}
		c->hdrscan = l;

		/* Read the newline */
		ch = skip_spaces( &buff );
		if( ch != '!' )
			goto bail;
		ch = skip_spaces( &buff );
		if( ch != '\n' )
			goto bail;

		if( !hashenter( file->hcachehash, (HASHDATA **)&c ) ) {
			printf( "jam: can't insert header cache item, bailing on %s\n",
				file->cachefilename );
			goto bail;
		}

		c->next = 0;
		if( last )
			last->next = c;
		else
			file->hcachelist = c;
		last = c;
	}

	bad_cache = 0;

	if( DEBUG_HEADER )
		printf( "hcache read from file %s\n", file->cachefilename );

bail:
	/* If its bad, no worries, it'll be overwritten in hcache_done() */
	if( bad_cache )
		printf( "jam: warning: the cache was invalid: %s\n", file->cachefilename );
	buffer_free( &buff );
}


static HCACHEFILE* hcachefile_get(TARGET *t)
{
	HCACHEFILE filedata, *file = &filedata;

	SETTINGS *vars;
	const char *hcachename = NULL;
	if ( t->flags & T_FLAG_USEDEPCACHE )
	{
		for ( vars = t->settings; vars; vars = vars->next )
		{
			if ( vars->symbol[0] == 'D'  &&  strcmp( vars->symbol, "DEPCACHE" ) == 0 )
			{
				hcachename = list_value(list_first(vars->value));
				break;
			}
		}
	}

	if ( !hcachename )
	{
		LIST *hcache = var_get( "DEPCACHE" );
		if ( list_first(hcache) )
			hcachename = list_value(list_first(hcache));
	}

	if ( !hcachename )
	{
		hcachename = newstr( "standard" );
	}

	if (lasthcachefile_name == hcachename)
		return lasthcachefile;

	filedata.cachename = hcachename;

	if ( !hcachefilehash ) {
		hcachefilehash = hashinit( sizeof( HCACHEFILE ), "hcachefile" );
	}

	if( !hashcheck( hcachefilehash, (HASHDATA **) &file ) ) {
		if( hashenter( hcachefilehash, (HASHDATA **)&file ) ) {
			char varBuffer[ MAXJPATH ];
			LIST *hcachevar;

			file->cachefilename = 0;
			file->hcachehash = hashinit( sizeof( HCACHEDATA ), "hcache" );
			file->hcachelist = 0;
			file->next = hcachefilelist;
			file->dirty = 0;
			hcachefilelist = file;

			strcpy( varBuffer, "DEPCACHE." );
			strcat( varBuffer, hcachename );

			hcachevar = var_get( varBuffer );
			if( list_first(hcachevar) ) {
				TARGET *t = bindtarget(list_value(list_first(hcachevar)));
				t->boundname = search_using_target_settings( t, t->name, &t->time );

				file->cachefilename = copystr( t->boundname );
				hcache_readfile( file );
			}
		}
	}

	lasthcachefile = file;
	lasthcachefile_name = file->cachename;

	return lasthcachefile;
}


void
	hcache_writefile(HCACHEFILE *file)
{
	FILE	*f;
	HCACHEDATA	*c;
	int		header_count = 0;
	int		maxage;

	if( !file  ||  !file->dirty  ||  !file->cachefilename )
		return;

	file_mkdir(file->cachefilename);

	if( ! (f = fopen( file->cachefilename, "wb" ) ) )
		return;

	maxage = cache_maxage();

	/* print out the version */
	fprintf( f, "@%s@\n", CACHE_FILE_VERSION );

	for( c = file->hcachelist; c; c = c->next ) {
		LISTITEM	*l;

		if( maxage == 0 )
			c->age = 0;
		else if( c->age > maxage )
			continue;

		write_string( f, c->boundname );
		write_int( f, (int)c->time );
		write_int( f, c->age );

#ifdef OPT_BUILTIN_MD5CACHE_EXT
		write_int( f, (int)c->mtime );
		write_md5sum( f, c->rulemd5sum );
		write_md5sum( f, c->contentmd5sum );
#endif

		write_int( f, list_length( c->includes ) );
		for( l = list_first(c->includes); l; l = list_next( l ) ) {
			write_string( f, list_value(l) );
		}

		write_int( f, list_length( c->hdrscan ) );
		for( l = list_first(c->hdrscan); l; l = list_next( l ) ) {
			write_string( f, list_value(l) );
		}

		fputc( '!', f );
		fputc( '\n', f );
		++header_count;
	}

	if( DEBUG_HEADER )
		printf( "hcache written to %s.	 %d dependencies, %.0f%% hit rate\n",
		file->cachefilename, header_count,
		queries ? 100.0 * hits / queries : 0 );

	fclose( f );
}


void hcache_done()
{
	HCACHEFILE *file;
	for( file = hcachefilelist; file; file = file->next ) {
		hcache_writefile( file );
		hashdone(file->hcachehash);
	}
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT
int  md5matchescommandline( TARGET *t );
#endif

LIST *
	hcache( TARGET *t, LIST *hdrscan )
{
	HCACHEDATA	cachedata, *c = &cachedata;
	HCACHEFILE	*file;
	LIST	*l = 0;
	int		use_cache = 1;
	const char *target;
# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p;
# endif

	target = t->boundname;

# ifdef DOWNSHIFT_PATHS
	p = path;

	do *p++ = (char)tolower( *target );
	while( *target++ );

	target = path;
# endif

	++queries;

	c->boundname = target;

	file = hcachefile_get( t );
	//    if ( file )
	{
		if( hashcheck( file->hcachehash, (HASHDATA **) &c ) )
		{
#ifdef OPT_BUILTIN_MD5CACHE_EXT
			if( c->time == t->time  &&  md5matchescommandline( t ) )
#else
			if( c->time == t->time )
#endif
			{
				if( !list_equal(hdrscan, c->hdrscan) )
					use_cache = 0;
			}
			else
				use_cache = 0;

			if( use_cache ) {
				if( DEBUG_HEADER )
					printf( "using header cache for %s\n", t->boundname );
				c->age = 0; /* The entry has been used, its young again */
				++hits;
				l = list_copy( 0, c->includes );
				{
					LIST *hdrfilter = var_get( "HDRFILTER" );
					if ( list_first(hdrfilter) )
					{
						LOL lol;
						lol_init( &lol );
						lol_add( &lol, list_append( L0, t->name, 1 ) );
						lol_add( &lol, l );
						lol_add( &lol, list_append( L0, t->boundname, 0 ) );
						l = evaluate_rule( list_value(list_first(hdrfilter)), &lol, NULL );
						lol_free( &lol );
					}
				}
				return l;
			}
			else {
				if( DEBUG_HEADER )
					printf( "header cache out of date for %s\n", t->boundname );
				list_free( c->includes );
				list_free( c->hdrscan );
				c->includes = 0;
				c->hdrscan = 0;
			}
		} else {
			if( hashenter( file->hcachehash, (HASHDATA **)&c ) ) {
				c->boundname = newstr( c->boundname );
				c->next = file->hcachelist;
				file->hcachelist = c;
#ifdef OPT_BUILTIN_MD5CACHE_EXT
				c->mtime = 0;
				memset( &c->rulemd5sum, 0, MD5_SUMSIZE );
				memset( &c->currentrulemd5sum, 0, MD5_SUMSIZE );
				memset( &c->contentmd5sum, 0, MD5_SUMSIZE );
				memset( &c->currentcontentmd5sum, 0, MD5_SUMSIZE );
#endif
			}
		}
	}

	file->dirty = 1;

	/* 'c' points at the cache entry.  Its out of date. */

	l = headers1( c->boundname, hdrscan );

	l = list_appendList( list_copy( 0, var_get( "HDREXTRA" ) ), l );

	c->includes = list_copy( 0, l );

	{
		LIST *hdrfilter = var_get( "HDRFILTER" );
		if (list_first(hdrfilter))
		{
			LOL lol;
			lol_init( &lol );
			lol_add( &lol, list_append( L0, t->name, 1 ) );
			lol_add( &lol, l );
			lol_add( &lol, list_append( L0, t->boundname, 0 ) );
			l = evaluate_rule( list_value(list_first(hdrfilter)), &lol, NULL );
			lol_free( &lol );
		}
	}

	c->time = t->time;
	c->age = 0;

	c->hdrscan = list_copy( 0, hdrscan );

	return l;
}

#ifdef OPT_BUILTIN_MD5CACHE_EXT
char md5sumempty[ MD5_SUMSIZE ] = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 };

int ismd5empty( MD5SUM md5sum )
{
	return memcmp(md5sum, md5sumempty, sizeof(MD5SUM)) == 0;
}

/*
 * Get cached md5sum of a file. If none found, or not up to date, if the file is source
 * try to recalculate the sum. If not, then return empty sum (all zeroes).
 */
int getcachedmd5sum( TARGET *t, int source )
{
	HCACHEDATA cachedata, *c = &cachedata;
	int  use_cache = 1;
	HCACHEFILE *file;
	const char *target = t->boundname;
# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p;
#endif

	if ( t->contentmd5sum_calculated )
		return t->contentmd5sum_changed;

	if (!source) {
		memset(&t->buildmd5sum, 0, sizeof(t->buildmd5sum));
		memset(&t->contentmd5sum, 0, sizeof(t->contentmd5sum));
		t->contentmd5sum_calculated = 1;
		t->contentmd5sum_changed = 0;
		return t->contentmd5sum_changed;
	}

	file = hcachefile_get( t );

	++queries;

# ifdef DOWNSHIFT_PATHS
	p = path;

	do *p++ = (char)tolower( *target );
	while( *target++ );

	target = path;
# endif

	c->boundname = target;

	if( hashcheck( file->hcachehash, (HASHDATA **) &c ) )
	{
		if ( t->time == 0 ) {
			/* This file was generated.  Grab its timestamp. */
			file_time( c->boundname, &c->mtime );
		} else if( c->mtime != t->time )
			use_cache = 0;

		if ( use_cache ) {
			use_cache = memcmp(md5sumempty, &c->contentmd5sum, sizeof(c->contentmd5sum)) != 0;
		}

		if( use_cache ) {
			if( DEBUG_MD5HASH )
				printf( "- content md5: %s (%s)\n", t->boundname, md5tostring(c->contentmd5sum));
			c->age = 0; /* The entry has been used, its young again */
			++hits;
			t->contentmd5sum_changed = 0;
			memcpy(&t->contentmd5sum, &c->contentmd5sum, sizeof(t->contentmd5sum));
			t->contentmd5sum_calculated = 1;
			return t->contentmd5sum_changed;
		}
		else {
			if( DEBUG_MD5HASH )
				printf( "md5 cache out of date for %s (time %d, md5time %d)\n", t->boundname , (int)t->time, (int)c->mtime );
		}
	} else {
		if( hashenter( file->hcachehash, (HASHDATA **)&c ) ) {
			c->boundname = newstr( c->boundname );
			c->next = file->hcachelist;
			file->hcachelist = c;
			c->time = 0;
			c->includes = NULL;
			c->hdrscan = NULL;
		}
	}

	file->dirty = 1;

	/* 'c' points at the cache entry.  Its out of date. */

	{
		MD5SUM origmd5sum;
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		LIST *md5callback;
#endif

		memcpy( &origmd5sum, &c->contentmd5sum, sizeof( MD5SUM ) );
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		pushsettings( t->settings );
		md5callback = var_get( "MD5CALLBACK" );
		popsettings( t->settings );

		if ( list_first(md5callback) )
		{
			luahelper_md5callback(t->boundname, c->contentmd5sum, list_value(list_first(md5callback)));
		}
		else
		{
#endif
			md5file( t->boundname, c->contentmd5sum );
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		}
#endif
		t->contentmd5sum_changed = memcmp( &origmd5sum, &c->contentmd5sum, sizeof( MD5SUM ) ) != 0;
	}
	if( DEBUG_MD5HASH )
		printf( "- content md5: %s (%s)\n", t->boundname, md5tostring(c->contentmd5sum));

	c->mtime = t->time;
	if ( c->mtime == 0 ) {
		/* This file was generated.  Grab its timestamp. */
		file_time( c->boundname, &c->mtime );
	}
	c->age = 0;
	memcpy(&t->contentmd5sum, &c->contentmd5sum, sizeof(t->contentmd5sum));
	t->contentmd5sum_calculated = (char)(memcmp(md5sumempty, &t->contentmd5sum, sizeof(t->contentmd5sum)) != 0);
	memset(&t->buildmd5sum, 0, sizeof(t->buildmd5sum));

	return t->contentmd5sum_changed;
}

/*
 * Set cached md5sum of a file.
 */
void setcachedmd5sum( TARGET *t )
{
	HCACHEDATA cachedata, *c = &cachedata;
	const char *target = t->boundname;
# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p;
#endif

	HCACHEFILE	*file = hcachefile_get( t );

# ifdef DOWNSHIFT_PATHS
	p = path;

	do *p++ = (char)tolower( *target );
	while( *target++ );

	target = path;
# endif

	c->boundname = target;

	if( !hashcheck( file->hcachehash, (HASHDATA **) &c ) )
	{
		if( hashenter( file->hcachehash, (HASHDATA **)&c ) ) {
			c->boundname = newstr( c->boundname );
			c->next = file->hcachelist;
			file->hcachelist = c;
			c->time = t->time;
			c->includes = NULL;
			c->hdrscan = NULL;
		}
	}

	file->dirty = 1;

	/* 'c' points at the cache entry.  Its out of date. */

	memcpy(c->rulemd5sum, t->rulemd5sum, sizeof(MD5SUM));
	memcpy(c->currentrulemd5sum, t->rulemd5sum, sizeof(MD5SUM));
	memcpy(c->contentmd5sum, t->contentmd5sum, sizeof(MD5SUM));
	memcpy(c->currentcontentmd5sum, t->contentmd5sum, sizeof(MD5SUM));
	c->mtime = t->time;
	c->age = 0;
}


/*
 * Get a filename in cache for given md5sum.
 */
const char *filecache_getpath(TARGET *t)
{
	char buffer[1024];
	LIST *filecache;
	const char *cachedir = NULL;
	LIST *cachevar;

	pushsettings( t->settings );
	filecache = var_get( "FILECACHE" );
	if ( !list_first(filecache) ) {
		popsettings( t->settings );
		return NULL;
	}

	/* get directory where objcache should reside */
	strcpy( buffer, list_value(list_first(filecache)) );
	strcat( buffer, ".PATH" );
	cachevar = var_get( buffer );
	if( list_first(cachevar) ) {
		TARGET *t = bindtarget(list_value(list_first(cachevar)));
		t->boundname = search( t->name, &t->time );
		cachedir = copystr( t->boundname );
	}

	popsettings( t->settings );

	return cachedir;
}


/*
 * Get a filename in cache for given md5sum.
 */
const char *filecache_getfilename(TARGET *t, MD5SUM sum, const char* extension)
{
	BUFFER buff;
	size_t pos;
	const char *cachedir;
	const char* result;

	cachedir = filecache_getpath(t);
	/* if no cachedir, no cachefiles */
	if (cachedir==NULL) {
		return NULL;
	}

	/* put the cachedir in front of buffer */
	buffer_init(&buff);
	buffer_addstring(&buff, cachedir, strlen(cachedir));
	buffer_addchar(&buff, '/');

	pos = buffer_pos(&buff);
	buffer_addstring(&buff, "000/", 4);

	/* add use md5 as filename */
	buffer_addstring(&buff, md5tostring(sum), 32);
	if (extension)
		buffer_addstring(&buff, extension, strlen(extension));
	buffer_addchar(&buff, 0);

	buffer_setpos(&buff, pos);
	buffer_putstring(&buff, buffer_ptr(&buff) + pos + 4, 3);

	result = newstr(buffer_ptr(&buff));
	buffer_free(&buff);
	return result;
}


LIST *filecache_fillvalues(TARGET *t)
{
	LIST *filecache;

	if ( !( t->flags & T_FLAG_USEFILECACHE ) )
		return 0;

	filecache = var_get( "FILECACHE" );
	if ( list_first(filecache) ) {
		LIST *l;
		BUFFER buff;
		char const* filecacheStr = list_value(list_first(filecache));

		buffer_init(&buff);
		buffer_addstring(&buff, filecacheStr, strlen(filecacheStr));
		buffer_addstring(&buff, ".USE", 4);
		buffer_addchar(&buff, 0);
		l = var_get( buffer_ptr( &buff ) );
		if ( list_first(l)  &&  atoi( list_value(list_first(l)) ) != 0) {
			t->filecache_use = 1;
		}
		buffer_free(&buff);

		buffer_init(&buff);
		buffer_addstring(&buff, filecacheStr, strlen(filecacheStr));
		buffer_addstring(&buff, ".GENERATE", 9);
		buffer_addchar(&buff, 0);
		l = var_get( buffer_ptr( &buff ) );
		if ( list_first(l)  &&  atoi(list_value(list_first(l))) != 0) {
			t->filecache_generate = 1;
		}
		buffer_free(&buff);
	}

	return filecache;
}


void filecache_disable(TARGET *t)
{
	BUFFER buff;
	LIST *filecache;
	char const* filecacheStr;
	pushsettings( t->settings );
	filecache = var_get( "FILECACHE" );
	if ( !list_first(filecache) ) {
		popsettings( t->settings );
		return;
	}

	filecacheStr = list_value(list_first(filecache));

	buffer_init(&buff);
	buffer_addstring(&buff, filecacheStr, strlen(filecacheStr));
	buffer_addstring(&buff, ".USE", 4);
	buffer_addchar(&buff, 0);
	var_set(buffer_ptr(&buff), list_append(L0, "0", 0), VAR_SET);
	buffer_free(&buff);

	buffer_init(&buff);
	buffer_addstring(&buff, filecacheStr, strlen(filecacheStr));
	buffer_addstring(&buff, ".GENERATE", 9);
	buffer_addchar(&buff, 0);
	var_set(buffer_ptr(&buff), list_append(L0, "0", 0), VAR_SET);
	buffer_free(&buff);
}


static int filecache_findlink(const char *cachedname, MD5SUM blobmd5sum)
{
	int haveblobmd5sum = 0;

	/* Search for the appropriate .link file that matches the target. */
	BUFFER linknamebuff;
	BUFFER wildbuff;
	buffer_init(&wildbuff);
	buffer_addstring(&wildbuff, cachedname, strlen(cachedname));
	buffer_addstring(&wildbuff, "-*.link", 7);
	buffer_addchar(&wildbuff, 0);

	if (findfile(buffer_ptr(&wildbuff), &linknamebuff))
	{
		const char* dashPtr = strrchr(buffer_ptr(&linknamebuff), '-');
		const char* slashPtr = strrchr(buffer_ptr(&linknamebuff), '/');
#ifdef OS_NT
		const char* backslashPtr = strrchr(buffer_ptr(&linknamebuff), '\\');
		if (backslashPtr > slashPtr)
			slashPtr = backslashPtr;
#endif
		if (dashPtr > slashPtr)
			haveblobmd5sum = read_md5sum_string(dashPtr + 1, blobmd5sum);
	}

	buffer_free(&linknamebuff);
	buffer_free(&wildbuff);

	return haveblobmd5sum;
}


int filecache_retrieve(TARGET *t, MD5SUM buildmd5sum)
{
	MD5SUM blobmd5sum;
	MD5SUM copymd5sum;
	time_t time;

	/* if the target is available in the cache */
	const char *cachedname = filecache_getfilename(t, buildmd5sum, 0);
	if (!cachedname)
		return 0;

	if (!filecache_findlink(cachedname, blobmd5sum))
	{
		if( DEBUG_MD5HASH)
		{
			printf("Cannot find %s in cache as %s\n", t->name, cachedname);
			filecache_disable(t);
		}
		return 0;
	}

	getcachedmd5sum( t, 1 );

	if ( file_time( t->boundname, &time ) == 0 )
	{
		if (memcmp(blobmd5sum, t->contentmd5sum, sizeof(MD5SUM)) == 0)
		{
			if (!(t->flags & T_FLAG_NOCARE))
#ifdef _MSC_VER
				_utime(t->boundname, NULL);
#else
				utime(t->boundname, NULL);
#endif
			printf("%s is already the proper cached target.\n", t->name);
			return 1;
		}
	}

	cachedname = filecache_getfilename(t, blobmd5sum, ".blob");

	/* try to get it from the cache */
	if (copyfile(t->boundname, cachedname, &copymd5sum)  &&  memcmp(copymd5sum, blobmd5sum, sizeof(MD5SUM)) == 0)
	{
		printf( "Using cached %s\n", t->name );
		return 1;
	}
	else if (!(t->flags & T_FLAG_OPTIONALFILECACHE))
	{
		printf( "Cannot retrieve %s from cache (will build normally)\n", t->name );
		return 0;
	}

	if( DEBUG_MD5HASH)
	{
		printf( "Cannot find %s in cache as %s\n", t->name, cachedname );
	}

	return 0;
}


void filecache_update(TARGET *t)
{
	MD5SUM blobmd5sum;
	int haveblobmd5sum = 0;
	const char *cachedname;
	const char *blobname;
	int cacheerror;

	if (!t->filecache_generate)
		return;

	/* If the buildmd5sum is empty, then the file doesn't exist. */
	cacheerror = ismd5empty(t->buildmd5sum);
	if (cacheerror)
		return;

	haveblobmd5sum = 0;
	cachedname = filecache_getfilename(t, t->buildmd5sum, NULL);
	if (!cachedname)
		return;

	/* Search for the appropriate .link file that matches the target. */
	haveblobmd5sum = filecache_findlink(cachedname, blobmd5sum);

	/* If we weren't able to determine the target md5sum, do it now. */
	if (!haveblobmd5sum)
	{
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		LIST *md5callback;

		pushsettings( t->settings );
		md5callback = var_get( "MD5CALLBACK" );
		popsettings( t->settings );

		if ( list_first(md5callback) )
		{
			luahelper_md5callback(t->boundname, blobmd5sum, list_value(list_first(md5callback)));
		}
		else
		{
#endif
			md5file(t->boundname, blobmd5sum);
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
		}
#endif
		memcpy(t->contentmd5sum, blobmd5sum, sizeof(MD5SUM));
		if (ismd5empty(t->contentmd5sum))
			return;
	}

	{
		/* Is the blob already there? */
		time_t blobtime;
		blobname = filecache_getfilename(t, blobmd5sum, ".blob");
		if (file_time(blobname, &blobtime) == -1)
		{
			time_t blobpartialtime;
			const char *blobpartialname;

			if(DEBUG_MD5HASH)
				printf("Caching %s as %s\n", t->name, cachedname);
			else
				printf("Caching %s\n", t->name);

			/* Write the new .blob to the cache. */
			blobpartialname = filecache_getfilename(t, blobmd5sum, ".blob.partial");
			if (file_time(blobpartialname, &blobpartialtime) == -1)
			{
				if (copyfile(blobpartialname, t->boundname, &blobmd5sum) == 0  ||
					rename(blobpartialname, blobname) != 0)
				{
					printf("** Unable to write %s to cache.\n", t->name);
					filecache_disable(t);
					return;
				}
			}
		}
	}

	/* Write the new .link file to the cache. */
	{
		FILE *file;
		BUFFER linknamebuff;
		buffer_init(&linknamebuff);
		buffer_addstring(&linknamebuff, cachedname, strlen(cachedname));
		buffer_addchar(&linknamebuff, '-');
		buffer_addstring(&linknamebuff, md5tostring(blobmd5sum), 32);
		buffer_addstring(&linknamebuff, ".link", 5);
		buffer_addchar(&linknamebuff, 0);

		file_mkdir(buffer_ptr(&linknamebuff));
		file = fopen(buffer_ptr(&linknamebuff), "wb");
		if (file)
		{
			write_md5sum(file, blobmd5sum);
			write_string(file, t->name);
			fclose(file);
		}

		buffer_free(&linknamebuff);
	}
}


/*
 */
int hcache_getrulemd5sum( TARGET *t )
{
	HCACHEDATA cachedata, *c = &cachedata;
	const char *target = t->name;
# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p;
# endif

	HCACHEFILE	*file = hcachefile_get( t );
	if ( !file->cachefilename )
		return 1;

# ifdef DOWNSHIFT_PATHS
	p = path;

	do *p++ = (char)tolower( *target );
	while( *target++ );

	target = path;
# endif

	c->boundname = target;

	if( hashcheck( file->hcachehash, (HASHDATA **) &c ) )
	{
		if( memcmp( &c->currentrulemd5sum, &t->rulemd5sum, MD5_SUMSIZE ) == 0 )
			return 1;

		memcpy( &c->currentrulemd5sum, &t->rulemd5sum, MD5_SUMSIZE );
	}
	else
	{
		// Enter it into the cache.
		if( hashenter( file->hcachehash, (HASHDATA **)&c ) )
		{
			c->boundname = newstr( c->boundname );
			c->next = file->hcachelist;
			file->hcachelist = c;
			c->mtime = 0;
			memcpy( &c->currentrulemd5sum, &t->rulemd5sum, MD5_SUMSIZE );
			memset( &c->rulemd5sum, 0, MD5_SUMSIZE );
			memset( &c->currentcontentmd5sum, 0, MD5_SUMSIZE );
			memset( &c->contentmd5sum, 0, MD5_SUMSIZE );
			c->time = 0;
			c->age = 0;
			c->includes = NULL;
			c->hdrscan = NULL;
		}
	}

	file->dirty = 1;

	return 0;
}


/*
 */
void hcache_finalizerulemd5sum( TARGET *t )
{
	HCACHEDATA cachedata, *c = &cachedata;
	const char *target = t->name;
# ifdef DOWNSHIFT_PATHS
	char path[ MAXJPATH ];
	char *p;
# endif

	HCACHEFILE	*file = hcachefile_get( t );
	if ( !file->cachefilename )
		return;

# ifdef DOWNSHIFT_PATHS
	p = path;

	do *p++ = (char)tolower( *target );
	while( *target++ );

	target = path;
# endif

	c->boundname = target;

	if( hashcheck( file->hcachehash, (HASHDATA **) &c )  &&  memcmp( &c->rulemd5sum, &c->currentrulemd5sum, MD5_SUMSIZE ) != 0 )
	{
		memcpy( &c->rulemd5sum, &c->currentrulemd5sum, MD5_SUMSIZE );
		file->dirty = 1;
	}
}


#endif

#endif

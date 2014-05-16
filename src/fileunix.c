/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * fileunix.c - manipulate file names and scan directories on UNIX/AmigaOS
 *
 * External routines:
 *
 *	file_dirscan() - scan a directory for files
 *	file_time() - get timestamp of file, if not done by file_dirscan()
 *	file_archscan() - scan an archive for files
 *
 * File_dirscan() and file_archscan() call back a caller provided function
 * for each file found.  A flag to this callback function lets file_dirscan()
 * and file_archscan() indicate that a timestamp is being provided with the
 * file.   If file_dirscan() or file_archscan() do not provide the file's
 * timestamp, interested parties may later call file_time().
 *
 * 04/08/94 (seiwald) - Coherent/386 support added.
 * 12/19/94 (mikem) - solaris string table insanity support
 * 02/14/95 (seiwald) - parse and build /xxx properly
 * 05/03/96 (seiwald) - split into pathunix.c
 * 11/21/96 (peterk) - BEOS does not have Unix-style archives
 * 01/08/01 (seiwald) - closure param for file_dirscan/file_archscan
 * 04/03/01 (seiwald) - AIX uses SARMAG
 * 07/16/02 (seiwald) - Support BSD style long filename in archives.
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/27/02 (seiwald) - support for AIX big archives
 * 12/30/02 (seiwald) - terminate ar_hdr for solaris sscanf()
 * 12/30/02 (seiwald) - skip solaris' empty archive member names (/, //xxx)
 */

# include "jam.h"
# include "filesys.h"
# include "pathsys.h"

# ifdef USE_FILEUNIX

# if defined( OS_SEQUENT ) || \
     defined( OS_DGUX ) || \
     defined( OS_SCO ) || \
     defined( OS_ISC )
# define PORTAR 1
# endif

# if defined( OS_RHAPSODY ) || \
     defined( OS_MACOSX ) || \
     defined( OS_NEXT )
/* need unistd for rhapsody's proper lseek */
# include <sys/dir.h>
# include <unistd.h>
# define STRUCT_DIRENT struct direct
# else
# include <dirent.h>
# define STRUCT_DIRENT struct dirent
# endif

#if defined( OS_MACOSX )
#include <CoreFoundation/CFBundle.h>
#endif

# ifdef OS_COHERENT
# include <arcoff.h>
# define HAVE_AR
# endif

# if defined( OS_MVS ) || \
     defined( OS_INTERIX )

#define	ARMAG	"!<arch>\n"
#define	SARMAG	8
#define	ARFMAG	"`\n"

struct ar_hdr		/* archive file member header - printable ascii */
{
	char	ar_name[16];	/* file member name - `/' terminated */
	char	ar_date[12];	/* file member date - decimal */
	char	ar_uid[6];	/* file member user id - decimal */
	char	ar_gid[6];	/* file member group id - decimal */
	char	ar_mode[8];	/* file member mode - octal */
	char	ar_size[10];	/* file member size - decimal */
	char	ar_fmag[2];	/* ARFMAG - string to end header */
};

# define HAVE_AR
# endif

# if defined( OS_QNX ) || \
     defined( OS_BEOS ) || \
     defined( OS_MPEIX )
# define NO_AR
# define HAVE_AR
# endif

# ifndef HAVE_AR
# ifdef _AIX43
/* AIX 43 ar SUPPORTs only __AR_BIG__ */
# define __AR_BIG__
# endif
# include <ar.h>
# endif

#ifdef OPT_BUILTIN_MD5CACHE_EXT
# include "md5.h"
#endif

#ifdef __FreeBSD__
#include <sys/sysctl.h>
#endif

#include <errno.h>

/*
 * file_dirscan() - scan a directory for files
 */

void
file_dirscan(
	const char *dir,
	scanback func,
	void *closure )
{
	PATHNAME f;
	DIR *d;
	STRUCT_DIRENT *dirent;
	char filename[ MAXJPATH ];

	/* First enter directory itself */

	memset( (char *)&f, '\0', sizeof( f ) );

	f.f_dir.ptr = dir;
	f.f_dir.len = strlen(dir);

	dir = *dir ? dir : ".";

	/* Special case / : enter it */

#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	if( f.f_dir.len == 1 && f.f_dir.ptr[0] == '/' )
	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0, 1 );
#else
	if( f.f_dir.len == 1 && f.f_dir.ptr[0] == '/' )
	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0 );
#endif

	/* Now enter contents of directory */

	if( !( d = opendir( dir ) ) )
	    return;

	if( DEBUG_BINDSCAN )
	    printf( "scan directory %s\n", dir );

	while( ( dirent = readdir( d ) ) )
	{
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
/*	    struct stat attr;*/
	    f.f_base.ptr = dirent->d_name;
	    f.f_base.len = strlen(dirent->d_name);
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f, filename, 0, 1 );
#else
	    path_build( &f, filename, 0 );
#endif
/*	    stat(filename, &attr);*/
/*	    if ( attr.st_mode & S_IFDIR )*/
		if ( dirent->d_type & DT_DIR )
	    {
			if ( ! ( ( dirent->d_name[0] == '.'  &&  dirent->d_name[1] == 0 )  ||
					( dirent->d_name[0] == '.'  &&  dirent->d_name[1] == '.'  &&  dirent->d_name[2] == 0 ) ) )
			{
				(*func)( closure, filename, 0 /* stat()'ed */, 0, 1 ); //attr.st_mtime, 1 );
			}
	    }
	    else
	    {
			(*func)( closure, filename, 0 /* stat()'ed */, (time_t)0, 0 ); //attr.st_mtime, 0 );
	    }
#else
# ifdef old_sinix
	    /* Broken structure definition on sinix. */
	    f.f_base.ptr = dirent->d_name - 2;
# else
	    f.f_base.ptr = dirent->d_name;
# endif
	    f.f_base.len = strlen( f.f_base.ptr );

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f, filename, 0, 1 );
#else
	    path_build( &f, filename, 0 );
#endif

	    (*func)( closure, filename, 0 /* not stat()'ed */, (time_t)0 );
#endif
	}

	closedir( d );
}

/*
 * file_time() - get timestamp of file, if not done by file_dirscan()
 */

int
file_time(
	const char *filename,
	time_t	*time )
{
	struct stat statbuf;

	if( stat( filename, &statbuf ) < 0 )
	    return -1;

	*time = statbuf.st_mtime;
	return 0;
}

#ifdef OPT_NODELETE_READONLY
/*
 * file_writeable() - return whether the file is writeable or not
 */
int
file_writeable(const char* filename)
{
    int fd;

    fd = open( filename, O_WRONLY );
    if (fd < 0)
        return 0;
    close(fd);
    return 1;
}
#endif /* OPT_NODELETE_READONLY */
/*
 * file_archscan() - scan an archive for files
 */

# ifndef AIAMAG	/* God-fearing UNIX */

# define SARFMAG 2
# define SARHDR sizeof( struct ar_hdr )

void
file_archscan(
	const char *archive,
	scanback func,
	void *closure )
{
# ifndef NO_AR
	struct ar_hdr ar_hdr;
	char buf[ MAXJPATH ];
	long offset;
	char    *string_table = 0;
	int fd;

	if( ( fd = open( archive, O_RDONLY, 0 ) ) < 0 )
	    return;

	if( read( fd, buf, SARMAG ) != SARMAG ||
	    strncmp( ARMAG, buf, SARMAG ) )
	{
	    close( fd );
	    return;
	}

	offset = SARMAG;

	if( DEBUG_BINDSCAN )
	    printf( "scan archive %s\n", archive );

	while( read( fd, &ar_hdr, SARHDR ) == SARHDR &&
	       !memcmp( ar_hdr.ar_fmag, ARFMAG, SARFMAG ) )
	{
	    long    lar_date;
	    long    lar_size;
	    char    lar_name[256];
	    char    *dst = lar_name;

	    /* solaris sscanf() does strlen first, so terminate somewhere */

	    ar_hdr.ar_fmag[0] = 0;

	    /* Get date & size */

	    sscanf( ar_hdr.ar_date, "%ld", &lar_date );
	    sscanf( ar_hdr.ar_size, "%ld", &lar_size );

	    /* Handle solaris string table.
	    ** The entry under the name // is the table,
	    ** and entries with the name /nnnn refer to the table.
	    */

	    if( ar_hdr.ar_name[0] != '/' )
	    {
		/* traditional archive entry names:
		** ends at the first space, /, or null.
		*/

		char *src = ar_hdr.ar_name;
		const char *e = src + sizeof( ar_hdr.ar_name );

		while( src < e && *src && *src != ' ' && *src != '/' )
		    *dst++ = *src++;
	    }
	    else if( ar_hdr.ar_name[1] == '/' )
	    {
		/* this is the "string table" entry of the symbol table,
		** which holds strings of filenames that are longer than
		** 15 characters (ie. don't fit into a ar_name)
		*/

		string_table = (char *)malloc(lar_size);

		lseek(fd, offset + SARHDR, 0);
		if( read(fd, string_table, lar_size) != lar_size )
		    printf( "error reading string table\n" );
	    }
	    else if( string_table && ar_hdr.ar_name[1] != ' ' )
	    {
		/* Long filenames are recognized by "/nnnn" where nnnn is
		** the offset of the string in the string table represented
		** in ASCII decimals.
		*/

		char *src = string_table + atoi( ar_hdr.ar_name + 1 );

		while( *src != '/' )
		    *dst++ = *src++;
	    }

	    /* Terminate lar_name */

	    *dst = 0;

	    /* Modern (BSD4.4) long names: if the name is "#1/nnnn",
	    ** then the actual name is the nnnn bytes after the header.
	    */

	    if( !strcmp( lar_name, "#1" ) )
	    {
		int len = atoi( ar_hdr.ar_name + 3 );
		if( read( fd, lar_name, len ) != len )
		    printf("error reading archive entry\n");
		lar_name[len] = 0;
	    }

	    /* Build name and pass it on.  */

	    if( lar_name[0] )
	    {
		if( DEBUG_BINDSCAN )
		    printf( "archive name %s found\n", lar_name );

		sprintf( buf, "%s(%s)", archive, lar_name );

#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
		(*func)( closure, buf, 1 /* time valid */, (time_t)lar_date, 0 );
#else
		(*func)( closure, buf, 1 /* time valid */, (time_t)lar_date );
#endif
	    }

	    /* Position at next member */

	    offset += SARHDR + ( ( lar_size + 1 ) & ~1 );
	    lseek( fd, offset, 0 );
	}

	if (string_table)
	    free(string_table);

	close( fd );

# endif /* NO_AR */

}

# else /* AIAMAG - RS6000 AIX */

void
file_archscan(
	const char *archive,
	scanback func,
	void *closure )
{
	struct fl_hdr fl_hdr;

	struct {
		struct ar_hdr hdr;
		char pad[ 256 ];
	} ar_hdr ;

	char buf[ MAXJPATH ];
	long offset;
	int fd;

	if( ( fd = open( archive, O_RDONLY, 0 ) ) < 0 )
	    return;

# ifdef __AR_BIG__

	if( read( fd, (char *)&fl_hdr, FL_HSZ ) != FL_HSZ ||
	    strncmp( AIAMAGBIG, fl_hdr.fl_magic, SAIAMAG ) )
	{
	    if( strncmp( AIAMAG, fl_hdr.fl_magic, SAIAMAG ) )
		printf( "Can't read new archive %s before AIX 4.3.\n" );

	    close( fd );
	    return;
	}

# else

	if( read( fd, (char *)&fl_hdr, FL_HSZ ) != FL_HSZ ||
	    strncmp( AIAMAG, fl_hdr.fl_magic, SAIAMAG ) )
	{
	    close( fd );
	    return;
	}

# endif

	sscanf( fl_hdr.fl_fstmoff, "%ld", &offset );

	if( DEBUG_BINDSCAN )
	    printf( "scan archive %s\n", archive );

	while( offset > 0 &&
	       lseek( fd, offset, 0 ) >= 0 &&
	       read( fd, &ar_hdr, sizeof( ar_hdr ) ) >= sizeof( ar_hdr.hdr ) )
	{
	    long    lar_date;
	    int	    lar_namlen;

	    sscanf( ar_hdr.hdr.ar_namlen, "%d", &lar_namlen );
	    sscanf( ar_hdr.hdr.ar_date, "%ld", &lar_date );
	    sscanf( ar_hdr.hdr.ar_nxtmem, "%ld", &offset );

	    if( !lar_namlen )
		continue;

	    ar_hdr.hdr._ar_name.ar_name[ lar_namlen ] = '\0';

	    sprintf( buf, "%s(%s)", archive, ar_hdr.hdr._ar_name.ar_name );

	    (*func)( closure, buf, 1 /* time valid */, (time_t)lar_date );
	}

	close( fd );
}

# endif /* AIAMAG - RS6000 AIX */

#if defined(OPT_BUILTIN_MD5CACHE_EXT)  ||  defined(OPT_HEADER_CACHE_EXT)

/* From LuaPlus' iox.cpp's PathCreate(). */
int file_mkdir(const char *inPath)
{
	char path[MAXJPATH];
	char* pathPtr = path;
	char ch;

	if (*inPath == '/') {
		++inPath;			// Skip the initial /
		*pathPtr++ = '/';
	}
	
	while ((ch = *inPath++))
	{
		if (ch == '/')
		{
			*pathPtr = 0;
			if (mkdir(path, 0777)  &&  errno != EEXIST)
			{
				int err = errno;  (void)err;
				return -1;
			}
			*pathPtr++ = '/';
		}
		else
			*pathPtr++ = ch;
	}

	return 0;
}


#endif


# ifdef OPT_HDRPIPE_EXT
/*
// From some MSDN sample, I think.
static int CreatePipeChild(HANDLE* child, HANDLE* inH, HANDLE* outH, HANDLE* errH, int redirect_stderr_to_stdout, LPCTSTR Command)
{
    SECURITY_ATTRIBUTES lsa;
    HANDLE ChildIn;
    HANDLE ChildOut;
    HANDLE ChildErr = NULL;
    SECURITY_ATTRIBUTES sa;
    PROCESS_INFORMATION pi;
    STARTUPINFO             si;
    HANDLE hNul;

    sa.nLength = sizeof(sa);                        // Security descriptor for INHERIT.
    sa.lpSecurityDescriptor = 0;
    sa.bInheritHandle       = 0;

    lsa.nLength=sizeof(SECURITY_ATTRIBUTES);
    lsa.lpSecurityDescriptor=NULL;
    lsa.bInheritHandle=TRUE;

    if (!CreatePipe(&ChildIn,inH,&lsa,0))
    {
	// Error.
    }

    if (!CreatePipe(outH,&ChildOut,&lsa,0))
    {
	// Error.
    }

    if (!redirect_stderr_to_stdout)
    {
	if (!CreatePipe(errH,&ChildErr,&lsa,0))
	{
	    // Error.
	}
    }

    // Lets Redirect Console StdHandles - easy enough

    // Dup the child handle to get separate handles for stdout and err,
    hNul = CreateFile("NUL",
	GENERIC_READ | GENERIC_WRITE,
	FILE_SHARE_READ | FILE_SHARE_WRITE,
	NULL, OPEN_EXISTING,
	0,
	NULL);

    if (hNul != NULL)
    {
	// Set up members of STARTUPINFO structure.
	memset(&si, 0, sizeof(si));
	si.cb = sizeof(STARTUPINFO);
	si.dwFlags = STARTF_USESTDHANDLES | STARTF_USESHOWWINDOW;
	si.wShowWindow = SW_HIDE;
	si.hStdOutput = ChildOut;
	si.hStdError    = redirect_stderr_to_stdout ? ChildOut : ChildErr;
	si.hStdInput    = ChildIn;
	if (CreateProcess(NULL, (char*)Command, NULL, NULL, TRUE, 0, NULL, NULL, &si, &pi) == TRUE)
	{
	    CloseHandle(pi.hThread);        // Thread handle not needed
	    //fprintf(stderr, "create process success\n");
	    *child = pi.hProcess;  // Return process handle (to get RC)
	} else
	    return -1;
	CloseHandle(hNul);                                      // Close error handle,
	CloseHandle(ChildOut);
	if (!redirect_stderr_to_stdout)
	    CloseHandle(ChildErr);
	CloseHandle(ChildIn);
    }
    else
    {
	// Error.
    }

    return 0;
}
*/

FILE* file_popen(const char *cmd, const char *mode)
{
/*    const char* comspec;
    char* commandBuffer;
    char* stderr_to_stdout;
    int redirectStderr = 0;
    HANDLE child;
    HANDLE hIn = INVALID_HANDLE_VALUE, hOut = INVALID_HANDLE_VALUE, hErr = INVALID_HANDLE_VALUE;
    int rc;
    FILE* file;
    int isCmd;

    if (!mode  ||  !*mode  ||  (mode[0] != 'r'  &&  mode[0] != 'w'))
	return NULL;

    comspec = getenv("COMSPEC");
    if (!comspec)
	comspec = "cmd";

    commandBuffer = (char*)malloc(strlen(comspec) + 4 + strlen(cmd) + 2 + 1);
    strcpy(commandBuffer, comspec);
    strcat(commandBuffer, " /c ");
    strlwr(commandBuffer);
    isCmd = strstr(commandBuffer, "cmd.exe") != NULL;
    if (isCmd)
	strcat(commandBuffer, "\"");
    strcat(commandBuffer, cmd);
    if (isCmd)
	strcat(commandBuffer, "\"");

    stderr_to_stdout = strstr(commandBuffer, "2>&1");
    if (stderr_to_stdout)
    {
	stderr_to_stdout[0] = stderr_to_stdout[1] = stderr_to_stdout[2] = stderr_to_stdout[3] = ' ';
	redirectStderr = 1;
    }

    rc = CreatePipeChild(&child, &hIn, &hOut, &hErr, redirectStderr, commandBuffer);
    free(commandBuffer);
    if (rc == -1)
    {
	return NULL;
    }

    if (mode[0] == 'r')
    {
	file = _fdopen(_open_osfhandle((long)hOut, _O_RDONLY | _O_TEXT), "rt");
	if (hIn != INVALID_HANDLE_VALUE)
	    CloseHandle(hIn);
	if (hErr != INVALID_HANDLE_VALUE)
	    CloseHandle(hErr);
    }
    else
    {
	file = _fdopen(_open_osfhandle((long)hIn, _O_WRONLY | _O_TEXT), "wt");
	if (hOut != INVALID_HANDLE_VALUE)
	    CloseHandle(hOut);
	if (hErr != INVALID_HANDLE_VALUE)
	    CloseHandle(hErr);
    }
    setvbuf(file, NULL, _IONBF, 0);

    CloseHandle(child);

    return file;
*/
	return 0;
}


int file_pclose(FILE *file)
{
/*    if (file)
    {
	fclose(file);
	return 0;
    }*/
    return -1;
}

# endif /* OPT_HDRPIPE_EXT */

#ifdef OPT_BUILTIN_MD5CACHE_EXT

/*
 * copyfile() - copy one file into another. returns 1 if successful
 */
int copyfile(const char *dst, const char *src, MD5SUM* md5sum)
{
    MD5_CTX context;
    size_t size = 0, sizeout = 0;
    FILE *fsrc = NULL, *fdst = NULL;
    unsigned char block[1<<16];

    /* printf("copy %s->%s\n", src, dst); */

    file_mkdir(dst);

    fsrc = fopen(src, "rb");
    if (fsrc==NULL) {
	printf("cannot open %s for reading - %s\n", src, strerror(errno));
	return 0;
    }

    fdst = fopen(dst, "wb");
    if (fdst==NULL) {
	fclose(fsrc);
	printf("cannot open %s for writing - %s\n", dst, strerror(errno));
	return 0;
    }

    if (md5sum) {
	MD5Init(&context);
    }

    while(!feof(fsrc)) {
	size = fread(block, 1, sizeof(block), fsrc);
	if (size==0) {
	    break;
	}

	if (md5sum) {
	    MD5Update(&context, block, size);
	}

	sizeout = fwrite(block, 1, size, fdst);
	if (sizeout!=size) {
	    printf("error while copying %s to %s - %s\n", src, dst, strerror(errno));
	    fclose(fsrc);
	    fclose(fdst);
	    return 0;
	}
    }

    if (md5sum) {
	MD5Final(*md5sum, &context);
    }

    fclose(fsrc);
    fclose(fdst);
    return 1;
}

/**
	\internal
	\author Jack Handy

	Borrowed from http://www.codeproject.com/string/wildcmp.asp.
	Modified by Joshua Jensen.
**/
static int wildmatch( const char* pattern, const char *string, int caseSensitive )
{
	// Handle all the letters of the pattern and the string.
	while ( *string != 0  &&  *pattern != '*' )
	{
		if ( *pattern != '?' )
		{
			if ( caseSensitive )
			{
				if ( *pattern != *string )
					return 0;
			}
			else
			{
				if ( toupper( *pattern ) != toupper( *string ) )
					return 0;
			}
		}

		pattern++;
		string++;
	}

	const char* mp = NULL;
	const char* cp = NULL;
	while ( *string != 0 )
	{
		if (*pattern == '*')
		{
			// It's a match if the wildcard is at the end.
			if ( *++pattern == 0 )
			{
				return 1;
			}

			mp = pattern;
			cp = string + 1;
		}
		else
		{
			if ( caseSensitive )
			{
				if ( *pattern == *string  ||  *pattern == '?' )
				{
					pattern++;
					string++;
				}
				else
				{
					pattern = mp;
					string = cp++;
				}
			}
			else
			{
				if ( toupper( *pattern ) == toupper( *string )  ||  *pattern == '?' )
				{
					pattern++;
					string++;
				}
				else
				{
					pattern = mp;
					string = cp++;
				}
			}
		}
	}

	// Collapse remaining wildcards.
	while ( *pattern == '*' )
		pattern++;

	return !*pattern;
}


int findfile(const char* wildcard, BUFFER* foundfilebuff)
{
	DIR* dirp;
	struct dirent* dp;
    const char* lastslash;
	const char* lastslash2;
	BUFFER pathbuff;

	lastslash = strrchr(wildcard, '/');
	lastslash2 = strrchr(wildcard, '\\');
	lastslash = lastslash > lastslash2 ? lastslash : lastslash2;

	buffer_init(&pathbuff);
	buffer_addstring(&pathbuff, wildcard, lastslash - wildcard);
	buffer_addchar(&pathbuff, 0);

    buffer_init(foundfilebuff);

	dirp = opendir(buffer_ptr(&pathbuff));
	if (!dirp)
	{
		buffer_free(&pathbuff);
		return 0;
	}

	// Any files found?
	while ((dp = readdir(dirp)) != NULL)
	{
		if (wildmatch(lastslash + 1, dp->d_name, 1))
		{
			buffer_addstring(foundfilebuff, wildcard, lastslash - wildcard + 1);
			buffer_addstring(foundfilebuff, dp->d_name, strlen(dp->d_name));
			buffer_addchar(foundfilebuff, 0);
			closedir(dirp);
			return 1;
		}
	}

	closedir(dirp);
	return 0;
}

# include "newstr.h"

/* Convert md5sum to a string representation. */
const char *md5tostring(MD5SUM sum)
{
  char buffer[1024];
  char *pbuf = buffer;
  int ch, i, val;

  /* add use md5 as filename */
  for( i=0; i<MD5_SUMSIZE; i++ ) {
    val = sum[i];

    ch = val>>4;
    if (ch >= 0xa) {
      *pbuf++ = (char)(ch-0xa+'a');
    } else {
      *pbuf++ = (char)(ch+'0');
    }

    ch = val&15;
    if (ch >= 0xa) {
      *pbuf++ = (char)(ch-0xa+'a');
    } else {
      *pbuf++ = (char)(ch+'0');
    }
  }
  *pbuf++ = 0;

  return newstr(buffer);
}



/* Calculate md5sum of a file. */
void md5file(const char *filename, MD5SUM sum)
{
    MD5_CTX context;
#define BLOCK_SIZE 1024 /* file is read in blocks of custom size, just so we don't have to read the whole file at once */
    FILE *f = fopen( filename, "rb" );

    if( f == NULL ) {
//	printf("Cannot calculate md5 for %s\n", filename);
	memset(sum, 0, sizeof(MD5SUM));
	return;
    }

    /* initialize the MD5 hash state */
    MD5Init( &context );

    /* for each block in the file */
    while (!feof(f)) {
	unsigned char block[BLOCK_SIZE];
	size_t readsize = fread(block, 1, BLOCK_SIZE, f);
	/* process the block - adding its values to the hash */
	MD5Update( &context, block, readsize );
    }
    /* finish input processing - write the hash key to the destination buffer */
    MD5Final( sum, &context );

    fclose(f);
}

#endif

#ifdef OPT_SET_JAMPROCESSPATH_EXT

#ifdef __FreeBSD__
void sysctl_get_pathname(char* buffer, size_t bufferLen)
{
	int mib[4];

	mib[0] = CTL_KERN;
	mib[1] = KERN_PROC;
	mib[2] = KERN_PROC_PATHNAME;
	mib[3] = -1;

	if (sysctl(mib, 4, buffer, &bufferLen, 0, 0) != 0)
	{
		buffer[0] = 0;
	}
	else
	{
		buffer[bufferLen] = 0;
	}
}
#endif

void getprocesspath(char* buffer, size_t bufferLen)
{
#if defined( OS_MACOSX )
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef bundleUrl = CFBundleCopyBundleURL(mainBundle);
	CFURLRef workingUrl = CFURLCreateCopyDeletingPathExtension(kCFAllocatorSystemDefault, bundleUrl);
	CFStringRef workingString = CFURLCopyFileSystemPath(workingUrl, kCFURLPOSIXPathStyle);
	CFMutableStringRef normalizedString = CFStringCreateMutableCopy(NULL, 0, workingString);
	CFStringGetCString(normalizedString, buffer, bufferLen - 1, kCFStringEncodingUTF8);
	CFRelease(workingUrl);
	CFRelease(workingString);
	CFRelease(normalizedString);
	CFRelease(bundleUrl);
#elif defined(__FreeBSD__)
	sysctl_get_pathname(buffer, bufferLen);
	dirname(buffer);
	strcat(buffer, "/");
#else
	int count = readlink("/proc/self/exe", buffer, bufferLen);
	if (count != -1)
	{
		buffer[count] = 0;
		dirname(buffer);
		strcat(buffer, "/");
		return;
	}
	*buffer = 0;
#endif
}

void getexecutablepath(char* buffer, size_t bufferLen)
{
#if defined( OS_MACOSX )
	CFBundleRef mainBundle = CFBundleGetMainBundle();
	CFURLRef executableUrl = CFBundleCopyExecutableURL(mainBundle);
	CFStringRef executableString = CFURLCopyFileSystemPath(executableUrl, kCFURLPOSIXPathStyle);
	CFMutableStringRef normalizedString = CFStringCreateMutableCopy(NULL, 0, executableString);
	CFStringGetCString(normalizedString, buffer, bufferLen - 1, kCFStringEncodingUTF8);
	CFRelease(executableUrl);
	CFRelease(executableString);
	CFRelease(normalizedString);
#elif defined(__FreeBSD__)
	sysctl_get_pathname(buffer, bufferLen);
#else
	if (readlink("/proc/self/exe", buffer, bufferLen) != -1)
	{
		return;
	}
	*buffer = 0;
#endif	
}

#endif

#ifdef OPT_PRINT_TOTAL_TIME_EXT

#include <sys/time.h>

unsigned long long getmilliseconds()
{
	struct timeval tv;
	gettimeofday(&tv, 0);
	return tv.tv_sec * 1000 + tv.tv_usec / 1000;
}

#endif

# endif /* USE_FILEUNIX */


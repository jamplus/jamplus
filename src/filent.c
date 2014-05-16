/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * filent.c - scan directories and archives on NT
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
 * 07/10/95 (taylor)  Findfirst() returns the first file on NT.
 * 05/03/96 (seiwald) split apart into pathnt.c
 * 01/20/00 (seiwald) - Upgraded from K&R to ANSI C
 * 10/03/00 (anton) - Porting for Borland C++ 5.5
 * 01/08/01 (seiwald) - closure param for file_dirscan/file_archscan
 * 11/04/02 (seiwald) - const-ing for string literals
 * 01/23/03 (seiwald) - long long handles for NT IA64
 */

# include "jam.h"
# include "filesys.h"
# include "pathsys.h"

# ifdef OS_NT

# include <windows.h>

# ifdef __BORLANDC__
# if __BORLANDC__ < 0x550
# include <dir.h>
# include <dos.h>
# endif
# undef PATHNAME	/* cpp namespace collision */
# define _finddata_t ffblk
# endif

# include <io.h>
# include <sys/stat.h>
# include <direct.h>

#ifdef OPT_BUILTIN_MD5CACHE_EXT
# include "md5.h"
#endif

/*
 * file_dirscan() - scan a directory for files
 */

# define FINDTYPE intptr_t

void
file_dirscan(
	const char *dir,
	scanback func,
	void	*closure )
{
	PATHNAME f;
	char filespec[ MAXJPATH ];
	char filename[ MAXJPATH ];
	FINDTYPE handle;
	int ret;
	struct _finddata_t finfo[1];

	/* First enter directory itself */

	memset( (char *)&f, '\0', sizeof( f ) );

	f.f_dir.ptr = dir;
	f.f_dir.len = (int)strlen(dir);

	dir = *dir ? dir : ".";

 	/* Special case \ or d:\ : enter it */

#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
 	if( f.f_dir.len == 1 && (f.f_dir.ptr[0] == '\\' || f.f_dir.ptr[0] == '/') )
 	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0, 1 );
 	else if( f.f_dir.len == 3 && f.f_dir.ptr[1] == ':' )
 	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0, 1 );
#else
 	if( f.f_dir.len == 1 && f.f_dir.ptr[0] == '\\' )
 	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0 );
 	else if( f.f_dir.len == 3 && f.f_dir.ptr[1] == ':' )
 	    (*func)( closure, dir, 0 /* not stat()'ed */, (time_t)0 );
#endif

	/* Now enter contents of directory */

	sprintf( filespec, "%s/*", dir );

	if( DEBUG_BINDSCAN )
	    printf( "scan directory %s\n", dir );

# if defined(__BORLANDC__) && __BORLANDC__ < 0x550
	if ( ret = findfirst( filespec, finfo, FA_NORMAL | FA_DIREC ) )
	    return;

	while( !ret )
	{
	    time_t time_write = finfo->ff_fdate;

	    time_write = (time_write << 16) | finfo->ff_ftime;
	    f.f_base.ptr = finfo->ff_name;
	    f.f_base.len = strlen( finfo->ff_name );

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f, filename, 0, 1 );
#else
	    path_build( &f, filename, 0 );
#endif

	    (*func)( closure, filename, 1 /* stat()'ed */, time_write );

	    ret = findnext( finfo );
	}
# else
	handle = _findfirst( filespec, finfo );

	if( ret = ( handle == (FINDTYPE)(-1) ) )
	    return;

	while( !ret )
	{
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	    if ( finfo->attrib & _A_SUBDIR )
	    {
		if ( ! ( ( finfo->name[0] == '.'  &&  finfo->name[1] == 0 )  ||
					( finfo->name[0] == '.'  &&  finfo->name[1] == '.'  &&  finfo->name[2] == 0 ) ) )
		{
		    f.f_base.ptr = finfo->name;
		    f.f_base.len = (int)(strlen( finfo->name ) + 1);

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
		    path_build( &f, filename, 0, 1 );
#else
		    path_build( &f, filename, 0 );
#endif

		    (*func)( closure, filename, 1 /* stat()'ed */, finfo->time_write, 1 );
		}
	    }
	    else
	    {
		f.f_base.ptr = finfo->name;
		f.f_base.len = (int)(strlen( finfo->name ));

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
		path_build( &f, filename, 0, 1 );
#else
		path_build( &f, filename, 0 );
#endif

		(*func)( closure, filename, 1 /* stat()'ed */, finfo->time_write, 0 );
	    }
#else
	    f.f_base.ptr = finfo->name;
	    f.f_base.len = strlen( finfo->name );

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	    path_build( &f, filename, 0, 1 );
#else
	    path_build( &f, filename, 0 );
#endif

	    (*func)( closure, filename, 1 /* stat()'ed */, finfo->time_write );
#endif

	    ret = _findnext( handle, finfo );
	}

	_findclose( handle );
# endif

}

/*
 * file_time() - get timestamp of file, if not done by file_dirscan()
 */

int
file_time(
	const char *filename,
	time_t	*time )
{
	/* On NT this is called only for C:/ */

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
file_writeable( const char* filename )
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

/* Straight from SunOS */

#define	ARMAG	"!<arch>\n"
#define	SARMAG	8

#define	ARFMAG	"`\n"

struct ar_hdr {
	char	ar_name[16];
	char	ar_date[12];
	char	ar_uid[6];
	char	ar_gid[6];
	char	ar_mode[8];
	char	ar_size[10];
	char	ar_fmag[2];
};

# define SARFMAG 2
# define SARHDR sizeof( struct ar_hdr )

void
file_archscan(
	const char *archive,
	scanback func,
	void	*closure )
{
	struct ar_hdr ar_hdr;
	char *string_table = 0;
	char buf[ MAXJPATH ];
	long offset;
	int fd;

	if( ( fd = open( archive, O_RDONLY | O_BINARY, 0 ) ) < 0 )
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
	    char    *name = 0;
 	    char    *endname;
	    char    *c;

	    sscanf( ar_hdr.ar_date, "%ld", &lar_date );
	    sscanf( ar_hdr.ar_size, "%ld", &lar_size );

	    lar_size = ( lar_size + 1 ) & ~1;

	    if (ar_hdr.ar_name[0] == '/' && ar_hdr.ar_name[1] == '/' )
	    {
		/* this is the "string table" entry of the symbol table,
		** which holds strings of filenames that are longer than
		** 15 characters (ie. don't fit into a ar_name
		*/

#ifdef OPT_FIX_NT_ARSCAN_LEAK
		if (string_table)
		    free(string_table);
#endif
		string_table = malloc(lar_size + 1);
		if (read(fd, string_table, lar_size) != lar_size)
		    printf("error reading string table\n");
		offset += SARHDR + lar_size;
		continue;
	    }
	    else if (ar_hdr.ar_name[0] == '/' && ar_hdr.ar_name[1] != ' ')
	    {
		/* Long filenames are recognized by "/nnnn" where nnnn is
		** the offset of the string in the string table represented
		** in ASCII decimals.
		*/

		name = string_table + atoi( ar_hdr.ar_name + 1 );
		endname = name;
		while( *endname != '/'  &&  *endname != 0 )
		    endname++;
		if (*endname != 0)
			endname++;
	    }
	    else
	    {
		/* normal name */
		name = ar_hdr.ar_name;
		endname = name + sizeof( ar_hdr.ar_name );
	    }

	    /* strip trailing space, slashes, and backslashes */

	    while( endname-- > name )
		if( *endname != ' ' && *endname != '\\' && *endname != '/' )
		    break;
	    *++endname = 0;

	    /* strip leading directory names, an NT specialty */

	    if( c = strrchr( name, '/' ) )
		name = c + 1;
	    if( c = strrchr( name, '\\' ) )
		name = c + 1;

	    sprintf( buf, "%s(%.*s)", archive, endname - name, name );
#ifdef OPT_SCAN_SUBDIR_NOTIFY_EXT
	    (*func)( closure, buf, 1 /* time valid */, (time_t)lar_date, 0 );
#else
	    (*func)( closure, buf, 1 /* time valid */, (time_t)lar_date );
#endif

	    offset += SARHDR + lar_size;
	    lseek( fd, offset, 0 );
	}

#ifdef OPT_FIX_NT_ARSCAN_LEAK
	if (string_table)
	    free(string_table);
#endif
	close( fd );
}

#if defined(OPT_BUILTIN_MD5CACHE_EXT)  ||  defined(OPT_HEADER_CACHE_EXT)

/* From LuaPlus' iox.cpp's PathCreate(). */
int file_mkdir(const char *inPath)
{
	char path[MAX_PATH];
	char* pathPtr = path;
	char ch;

	if ((inPath[0] == '\\'  ||  inPath[0] == '/')  &&  (inPath[1] == '\\'  ||  inPath[1] == '/'))
	{
		*pathPtr++ = '\\';
		*pathPtr++ = '\\';
		inPath += 2;
		while (ch = *inPath++)
		{
			*pathPtr++ = ch;
			if (ch == '/'  ||  ch == '\\')
				break;
		}
	}

	while (ch = *inPath++)
	{
		if (ch == '/'  ||  ch == '\\')
		{
			*pathPtr = 0;
			if (!CreateDirectory(path, NULL)  &&  (GetLastError() != ERROR_ALREADY_EXISTS  &&  GetLastError() != ERROR_ACCESS_DENIED))
				return -1;
			*pathPtr++ = '\\';
		}
		else
			*pathPtr++ = ch;
	}

	return 0;
}


#endif


# ifdef OPT_HDRPIPE_EXT

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


FILE* file_popen(const char *cmd, const char *mode)
{
    const char* comspec;
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
}


int file_pclose(FILE *file)
{
    if (file)
    {
	fclose(file);
	return 0;
    }
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
	    MD5Update(&context, block, (unsigned int)size);
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

int findfile(const char* wildcard, BUFFER* foundfilebuff)
{
    HANDLE handle;
    WIN32_FIND_DATA fd;
    const char* lastslash;

    buffer_init(foundfilebuff);
    handle = FindFirstFile(wildcard, &fd);
    if (handle == INVALID_HANDLE_VALUE)
	return 0;
    FindClose(handle);

    lastslash = max(strrchr(wildcard, '/'), strrchr(wildcard, '\\'));
    buffer_addstring(foundfilebuff, wildcard, lastslash - wildcard + 1);
    buffer_addstring(foundfilebuff, fd.cFileName, strlen( fd.cFileName ));
    buffer_addchar(foundfilebuff, 0);
    return 1;
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
	MD5Update( &context, block, (unsigned int)readsize );
    }
    /* finish input processing - write the hash key to the destination buffer */
    MD5Final( sum, &context );

    fclose(f);
}

#endif

#ifdef OPT_SET_JAMPROCESSPATH_EXT

void getprocesspath(char* buffer, size_t bufferLen)
{
    char *ptr;
    GetModuleFileName(NULL, buffer, (DWORD)bufferLen);
    ptr = strrchr(buffer, '\\');
    if (!ptr)
	ptr = strrchr(buffer, '/');
    if (ptr)
	*ptr = 0;
}

void getexecutablepath(char* buffer, size_t bufferLen)
{
    GetModuleFileName(NULL, buffer, (DWORD)bufferLen);
}

#endif

#ifdef OPT_PRINT_TOTAL_TIME_EXT

#pragma comment(lib, "winmm.lib")

#if _MSC_VER  &&  _MSC_VER < 1300
unsigned __int64 getmilliseconds()
#else
unsigned long long getmilliseconds()
#endif
{
    return timeGetTime();
}

#endif

# endif /* NT */

#include <stdio.h>
#include <string.h>
#include "fileglob.h"
#include "miniz.h"

int main(int argc, char **argv, char **envp)
{
	FILE *fin;
	FILE *fout;
	char buf[ 1024 ];
	char rootDirectory[1000];
	size_t rootDirectoryLength = 0;

	if( argc != 3 )
	{
		fprintf(stderr, "usage: %s jamzipdata.c packageinfo.txt\n", argv[0]);
		return -1;
	}

	mz_zip_archive zip;
	memset(&zip, 0, sizeof(zip));
	//mz_bool ret = mz_zip_writer_init_file(&zip, argv[1], 0);
	mz_bool ret = mz_zip_writer_init_heap(&zip, 0, 512 * 1024);

	if ( !( fin = fopen( argv[2], "r" ) ) )
	{
		perror( *argv );
		return -1;
	}

	while ( fgets( buf, sizeof( buf ), fin ) )
	{
		char *p = buf;

		/* Strip leading whitespace. */
		while (*p == ' ' || *p == '\t' || *p == '\n')
			p++;

		/* Drop comments and empty lines. */

		if (*p == '#' || !*p)
			continue;

		unsigned char* srcPtr = (unsigned char*)p;
		char* destPtr = rootDirectory;
		while (*srcPtr && *srcPtr != '\n' && *srcPtr != '$')
		{
			if (*srcPtr == '\\')
			{
				*destPtr = '/';
			}
			else
			{
				*destPtr = *srcPtr;
			}
			++srcPtr;
			++destPtr;
		}
		if (*srcPtr == '$')
		{
			++srcPtr;
		}
		if (destPtr != rootDirectory && destPtr[-1] != '/')
		{
			*destPtr++ = '/';
		}
		*destPtr = 0;
		rootDirectoryLength = destPtr - rootDirectory;

		char wildcard[1000];
		strcpy(wildcard, rootDirectory);
		destPtr = wildcard + rootDirectoryLength;

		while (*srcPtr && *srcPtr != '\n' && *srcPtr != '$')
		{
			if (*srcPtr == '\\')
			{
				*destPtr = '/';
			}
			else
			{
				*destPtr = *srcPtr;
			}
			++srcPtr;
			++destPtr;
		}
		*destPtr = 0;

		if (*srcPtr == '$')
		{
			++srcPtr;
		}

		unsigned char* entryFilename = srcPtr;
		while (*srcPtr && *srcPtr != '\n')
		{
			++srcPtr;
		}
		*srcPtr = 0;
		if (*entryFilename == 0)
		{
			entryFilename = NULL;
		}

		//printf("Searching wildcard %s\n", wildcard);
		fileglob* glob = fileglob_Create(wildcard);
		while (fileglob_Next(glob))
		{
			const char* filename = fileglob_FileName(glob);
			//printf("%s\n", filename);
			mz_zip_writer_add_file(&zip, entryFilename != NULL ? (const char*)entryFilename : filename + rootDirectoryLength, filename, NULL, 0, MZ_NO_COMPRESSION);
		}

		//mz_zip_writer_finalize_archive(&zip);
	}

	void* zipBuffer;
	size_t zipSize;
	mz_zip_writer_finalize_heap_archive(&zip, &zipBuffer, &zipSize);

	//fout = fopen("out.zip", "wb");
	//fwrite(zipBuffer, zipSize, 1, fout);
	//fclose(fout);

	if (!( fout = fopen( argv[1], "w" ) ) )
	{
		perror( argv[1] );
		return -1;
	}
	fprintf(fout, "static const unsigned char jamZipBuffer[] = {\n    ");
	int n = 1;
	const unsigned char* srcPtr = (const unsigned char*)zipBuffer;
	while (srcPtr - (unsigned char*)zipBuffer < (ptrdiff_t)zipSize)
	{
		fprintf(fout, "%3u,", *srcPtr++);
		if (n == 20)
		{
			fprintf(fout, "\n    ");
			n = 0;
		}
		++n;
	}
	fprintf(fout, "\n};\n\n");
	fclose(fout);

	fclose(fin);
	mz_zip_writer_end(&zip);
	return 0;
}

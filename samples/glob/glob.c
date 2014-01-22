#include "fileglob.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void Usage()
{
	printf("glob 3.0 - A file globbing utility\n");
	printf("    Algorithm and original implementation by Matthias Wandel (MWandel@rim.net)\n");
    printf("    New implementation from Ruby, Copyright (C) 1993-2013 Yukihiro Matsumoto.\n");
	printf("    Extensions by Joshua Jensen (jjensen@workspacewhiz.com)\n");
	printf("\nUsage: glob [OPTIONS] patterns\n");
	printf("   -v         = Verbose directory and file statistics\n");
	printf("   -vv        = Extra verbose directory and file statistics\n");
	printf("   -e pattern = Exclusive pattern.  All ignore patterns are not used.  Only\n");
	printf("                files matching the exclusive pattern are counted.\n");
	printf("   -i pattern = Ignore patterns of the name [pattern].  Close with a\n");
	printf("                forward slash to ignore a directory.\n\n");
	exit(-1);
}


int main (int argc, char **argv) {
	int i, argn;
	int verbose = 0;

	if (argc == 1)
		Usage();

	for (argn = 1; argn < argc; ++argn) {
		char* arg = argv[argn];
		if (arg[0] != '-')
			break; // Filenames from here on.

		if (strcmp(arg, "-?") == 0) {
			Usage();
		}

		if (strcmp(arg, "-v") == 0) {
			verbose = 1;
		}

		if (strcmp(arg, "-vv") == 0) {
			verbose = 2;
		}
	}

	for (; argn < argc; ++argn) {
		fileglob* glob;
		char path[1000];
		char* startPath = path;
		strcpy(path, argv[argn]);
		if (*startPath == '\''  &&  startPath[strlen(startPath) - 1] == '\'') {
			startPath++;
			startPath[strlen(startPath) - 1] = 0;
		}
		glob = fileglob_Create(startPath);
        
		for (i = 1; i < argn; ++i) {
			char* arg = argv[i];

			if (strcmp(arg, "-e") == 0) {
				++i;
				fileglob_AddExclusivePattern(glob, argv[i]);
			}
			else if (strcmp(arg, "-i") == 0) {
				i++;
				fileglob_AddIgnorePattern(glob, argv[i]);
			}
		}

		while (fileglob_Next(glob)) {
			const char* filename = fileglob_FileName(glob);
			if (verbose) {
				fileglob_uint64 creationTime = fileglob_CreationTime(glob);
				fileglob_uint64 accessTime = fileglob_AccessTime(glob);
				fileglob_uint64 writeTime = fileglob_WriteTime(glob);
				fileglob_uint64 creationFILETIME = fileglob_CreationFILETIME(glob);
				fileglob_uint64 accessFILETIME = fileglob_AccessFILETIME(glob);
				fileglob_uint64 writeFILETIME = fileglob_WriteFILETIME(glob);
				fileglob_uint64 fileSize = fileglob_FileSize(glob);
				int isDirectory = fileglob_IsDirectory(glob);
				int isLink = fileglob_IsLink(glob);
				int isReadOnly = fileglob_IsReadOnly(glob);
				const char* permissions = fileglob_Permissions(glob);
				if (verbose == 1) {
					printf("%s - creationTime=%llu, accessTime=%llu, writeTime=%llu, creationFILETIME=%llu, accessFILETIME=%llu, writeFILETIME=%llu, fileSize=%llu, isDirectory=%s, isLink=%s, isReadOnly=%s, permissions=%s\n",
							filename, creationTime, accessTime, writeTime, creationFILETIME, accessFILETIME, writeFILETIME, fileSize, isDirectory ? "true" : "false", isLink ? "true" : "false", isReadOnly ? "true" : "false", permissions);
				} else {
					fileglob_uint64 numberOfLinks = fileglob_NumberOfLinks(glob);
					printf("%s - creationTime=%lld, accessTime=%lld, writeTime=%lld, creationFILETIME=%lld, accessFILETIME=%lld, writeFILETIME=%lld, fileSize=%lld, isDirectory=%s, isLink=%s, isReadOnly=%s, permissions=%s, numberOfLinks=%lld\n",
							filename, creationTime, accessTime, writeTime, creationFILETIME, accessFILETIME, writeFILETIME, fileSize, isDirectory ? "true" : "false", isLink ? "true" : "false", isReadOnly ? "true" : "false", permissions, numberOfLinks);
				}
			} else {
				printf("%s\n", filename);
			}
		}

		fileglob_Destroy(glob);
	}

	return EXIT_SUCCESS;
}

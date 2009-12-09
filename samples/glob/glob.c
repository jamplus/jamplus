#include "fileglob.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void Usage()
{
	printf("glob 2.0 - A file globbing utility\n");
	printf("    Algorithm and original implementation by Matthias Wandel (MWandel@rim.net)\n");
	printf("    Extensions and new C interface by Joshua Jensen (jjensen@workspacewhiz.com)\n");
	printf("\nUsage: glob -i pattern patterns\n");
	printf("   -e pattern = Exclusive pattern.  All ignore patterns are not used.  Only\n");
	printf("                files matching the exclusive pattern are counted.\n");
	printf("   -i pattern = Ignore patterns of the name [pattern].  Close with a\n");
	printf("                forward slash to ignore a directory.\n\n");
	exit(-1);
}


int main (int argc, char **argv)
{
	int i, argn;

	if (argc == 1)
		Usage();

	for (argn = 1; argn < argc; ++argn) {
		char* arg = argv[argn];
		if (arg[0] != '-')
			break; // Filenames from here on.

		if (strcmp(arg, "-?") == 0)
		{
			Usage();
		}
	}

	for (; argn < argc; ++argn) {
		fileglob* glob = fileglob_Create(argv[argn]);

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
			printf("%s\n", filename);
		}
		fileglob_Destroy(glob);
	}

	return EXIT_SUCCESS;
}

/*

s:\c*\*
s:\c*\*\
s:\c*\...
s:\c*\...\
\c*\*
*\*.c
...\*.c
/*
/...
..\...

*/


#include "FileGlobBase.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

/**
	A specialized derived class that just prints the filenames to stdout.
**/
class FileGlobPrint : public FileGlobBase
{
	virtual void FoundMatch( const char* fileName )
	{
		printf( "%s\n", fileName );
	}
};


void Usage()
{
	printf( "Glob - A file globbing utility\n" );
	printf( "    Algorithm and original implementation by Matthias Wandel (MWandel@rim.net)\n" );
	printf( "    Extensions and C++ interface by Joshua Jensen (jjensen@workspacewhiz.com)\n" );
	printf( "\nUsage: Glob -i pattern patterns\n" );
	printf( "   -e pattern = Exclusive pattern.  All ignore patterns are not used.  Only\n" );
	printf( "                files matching the exclusive pattern are counted.\n" );
	printf( "   -i pattern = Ignore patterns of the name [pattern].  Close with a\n" );
	printf( "                forward slash to ignore a directory.\n\n" );
	exit( -1 );
}


int main (int argc, char **argv)
{
	FileGlobPrint glob;

	if ( argc == 1 )
		Usage();

	int argn;
	for ( argn = 1; argn < argc; ++argn )
	{
		char* arg = argv[ argn ];
		if ( arg[0] != '-' )
			break; // Filenames from here on.

		if ( strcmp( arg, "-e" ) == 0 )
		{
			argn++;
			glob.AddExclusivePattern( argv[ argn ] );
		}
		else if ( strcmp( arg, "-i" ) == 0 )
		{
			argn++;
			glob.AddIgnorePattern( argv[ argn ] );
		}
		else if ( strcmp( arg, "-?" ) == 0 )
		{
			Usage();
		}
	}

	for ( ; argn < argc; ++argn)
		glob.MatchPattern( argv[argn] );

#if 0
	for ( FileGlobList::Iterator it = glob.begin(); it != glob.end(); ++it )
	{
		const char* str = (*it).c_str();
		printf( "%s\n", str );
	}
#endif 0

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


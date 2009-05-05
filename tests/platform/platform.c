#include <stdio.h>

main()
{
#ifdef USING_WIN32
	printf("Using win32\n");
#elif defined(USING_MACOSX)
	printf("Using macosx\n");
#endif
}
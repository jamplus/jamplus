#include <stdio.h>

extern void Func();

#ifdef USING_WIN32
extern void Win32();
#elif defined(USING_MACOSX)
extern void MacOSX();
#endif

main()
{
#ifdef USING_WIN32
	printf("Using win32\n");
	Win32();
#elif defined(USING_MACOSX)
	printf("Using macosx\n");
	MacOSX();
#endif
	Func();
}

#include <stdio.h>

int main()
{
#if defined(PLATFORM_WIN32DX)
	printf("Hello from win32-dx!\n");
#elif defined(PLATFORM_WIN32OGL)
	printf("Hello from win32-ogl!\n");
#endif
	return 0;
}

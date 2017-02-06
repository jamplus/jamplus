#include <stdio.h>

int main()
{
#if defined(PLATFORM_WIN32DX)
#if defined(CONFIG_DEBUG)
	printf("Hello from win32-dx debug!\n");
#elif defined(CONFIG_RELEASE)
	printf("Hello from win32-dx release!\n");
#endif // CONFIG_RELEASE
#elif defined(PLATFORM_WIN32OGL)
#if defined(CONFIG_DEBUG)
	printf("Hello from win32-ogl debug!\n");
#elif defined(CONFIG_RELEASE)
	printf("Hello from win32-ogl release!\n");
#endif // CONFIG_RELEASE
#endif
	return 0;
}

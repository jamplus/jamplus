#include "Misc_InternalPch.h"

#if defined(_WIN32)
#include <windows.h>
#pragma comment(lib, "winmm.lib")
#elif defined(__APPLE__)
#include <CoreServices/CoreServices.h>
#include <unistd.h>
#include <sys/time.h>
#endif // _WIN32

#include <stdio.h>
#include <assert.h>
#include "Map.h"
#include "AnsiString.h"
#include <time.h>

namespace Misc {

bool gInAssert = false;	

DWORD GetMilliseconds()
{
#if defined(_WIN32)
	return ::timeGetTime();
#elif defined(PLATFORM_MAC)
	timeval time;
	gettimeofday(&time, NULL);
	return (time.tv_sec * 1000) + (time.tv_usec / 1000);
#else
	CORE_ASSERT(0);
	return 0;
#endif // _WIN32
}


void SleepMilliseconds(unsigned int milliseconds)
{
#if defined(_WIN32)
	::Sleep(milliseconds);
#elif defined(PLATFORM_MAC)
	usleep(milliseconds * 1000);
#endif
}

} // namespace Misc

#include <stdio.h>

int main()
{
#if defined(TEST_DEBUG_DEFINE)
	const char* helloworld = "Hello, Debug World!\n";
#elif defined(TEST_RETAIL_DEFINE)
	const char* helloworld = "Hello, Retail World!\n";
#endif
	puts(helloworld);
	return 0;
}

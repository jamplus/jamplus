#include <stdio.h>
#include "../lib-c/add.h"

#if _MSC_VER
__declspec(dllexport)
#endif
void ExportA()
{
	printf("ExportA: 2 + 5 = %d\n", Add(2, 5));
}

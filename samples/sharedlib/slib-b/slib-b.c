#include <stdio.h>
#include "../lib-c/add.h"

#if _MSC_VER
__declspec(dllexport)
#endif
void ExportB()
{
	printf("ExportB: 3 + 9 = %d\n", Add(3, 9));
}

#include <stdio.h>
#include "../lib-c/add.h"

__declspec(dllexport) void ExportB()
{
	printf("ExportB: 3 + 9 = %d\n", Add(3, 9));
}

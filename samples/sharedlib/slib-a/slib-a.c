#include <stdio.h>
#include "../lib-c/add.h"

__declspec(dllexport) void ExportA()
{
	printf("ExportA: 2 + 5 = %d\n", Add(2, 5));
}

#include <stdio.h>
#include "../lib-c/add.h"

__declspec(dllexport) void ExportA()
{
	//a
	printf("ExportA: 2 + 5 = %d\n", Add(2, 5));
}


__declspec(dllexport) void ExportA2()
{
	printf("ExportA2: 3 + 9 = %d\n", Add(3, 9));
}

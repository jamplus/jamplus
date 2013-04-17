#if defined(FAKEPS3_PPU)

#include <stdio.h>

extern void RunSPUThing();

int main()
{
	printf("In PPU thing!\n");
	RunSPUThing();
	printf("Back in PPU thing!\n");
	return 0;
}

#endif /* FAKEPS3_PPU */


#include <stdio.h>
#include <stdlib.h>

int main(int argc, char **argv) {
	int x;
	int y;

	if (argc != 3) {
		printf("Usage: add x y\n");
		return 1;
	}

	x = atoi(argv[1]);
	y = atoi(argv[2]);

	printf("%d\n", x + y);
	return 0;
}

#include <stdio.h>
#include "config.h"

int main() {
    printf("Built for platform %s\n", PLATFORM);
#ifdef IS_AWESOME
    printf("This is awesome!\n");
#endif /* IS_AWESOME */
#ifdef IS_NOT_AWESOME
    printf("This is not awesome... :(\n");
#endif /* IS_NOT_AWESOME */
    return 0;
}


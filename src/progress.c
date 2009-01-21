#include <stdlib.h>
#include <string.h>
#include <time.h>
#include "progress.h"

#define PROGRESS_WINDOW 10

typedef struct
{
    time_t when;
    int completed;

} TIMESTAMP;

struct _PROGRESS
{
    int total;
    int stampcount;
    TIMESTAMP stamps[PROGRESS_WINDOW];
};

#define LAST_STAMP(p) ((p)->stamps[(p)->stampcount - 1])
#define FIRST_STAMP(p) ((p)->stamps[0])

PROGRESS*
progress_start(int total)
{
    PROGRESS* p = malloc(sizeof(PROGRESS));
    p->total = total;
    p->stampcount = 0;
    progress_update(p, 0);
    return p;
}

static double
progress_estimate(PROGRESS* progress)
{
    int count;
    int left;
    double elapsed;
    double rate;

    if (progress->stampcount < 2) {
	return 0.0;
    }

    count = LAST_STAMP(progress).completed - FIRST_STAMP(progress).completed;
    left = progress->total - LAST_STAMP(progress).completed;
    elapsed = (double)(LAST_STAMP(progress).when - FIRST_STAMP(progress).when);
    if (elapsed <= 0.1) {
	elapsed = 0.1;
    }
    rate = count / elapsed;
    return left / rate;
}

double
progress_update(PROGRESS* progress, int completed)
{
    time_t now;

    time(&now);

    /* only return progress every 10 seconds */
    if (progress->stampcount > 0
	&& difftime(now, LAST_STAMP(progress).when) < 10.0) {
	return 0.0;
    }

    if (progress->stampcount == PROGRESS_WINDOW)
    {
	memmove(progress->stamps, progress->stamps + 1,
		sizeof(progress->stamps[0]) * (PROGRESS_WINDOW - 1));
	--progress->stampcount;
    }
    ++progress->stampcount;
    LAST_STAMP(progress).completed = completed;
    LAST_STAMP(progress).when = now;

    return progress_estimate(progress);
}

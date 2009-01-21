#ifndef PROGRESS_H
#define PROGRESS_H

struct _PROGRESS;
typedef struct _PROGRESS PROGRESS;

PROGRESS* progress_start(int total);
double progress_update(PROGRESS* progress, int completed);

#endif

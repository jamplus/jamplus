#include "jam.h"
#include "tmpfile.h"
#include <stdio.h>
#include <stdlib.h>
#include <fcntl.h>
#if defined(OS_NT)
#include <io.h>
#else
#include <unistd.h>
#endif

static int do_newtmp(char** name, const char* ext)
{
    int h = 0;
    int i;
    int flags;
    size_t extlen = 0;

    if (ext) extlen = strlen(ext);

    flags = O_WRONLY | O_CREAT | O_EXCL;

#if defined(OS_NT)
#if defined(_MSC_VER)
    /*
     * Using _O_TEMPORARY to force FILE_FLAG_DELETE_ON_CLOSE here would be
     * really nifty, but we have to keep the handle open and lots of NT stuff
     * (most notably cmd.exe and its buildins) tries to open files for
     * exclusive use which then fails.
     */

     flags |= _O_SHORT_LIVED;
     flags |= _O_BINARY;
#endif
#endif

#if defined(OS_UNIX)
    flags |= O_NONBLOCK;
#endif

    for (i = 0; i < 100; ++i) {
	*name = tempnam(0, "jam");

	if (ext) {
	    *name = realloc(*name, strlen(*name) + extlen + 1);
	    strcat(*name, ext);
	}

	h = open(*name, flags, 0600);
	if (h != -1) break;
	free(*name);
	*name = 0;
    }

    return h;
}

TMPFILE* tmp_new(const char* ext)
{
    TMPFILE* t;
    int h;

    t = malloc(sizeof(TMPFILE));
    h = do_newtmp(&(t->name), ext);
    if (h == -1) {
	free(t);
	return 0;
    }

    t->file = fdopen(h, "ab");

    if (!t->file) {
	close(h);
	unlink(t->name);
	free(t);
	return 0;
    }

    return t;
}

void tmp_close(TMPFILE* f)
{
    if (f->file != 0) {
	fclose(f->file);
	f->file = 0;
    }
}

void tmp_release(TMPFILE* f)
{
    tmp_close(f);

    if (f->name) {
	unlink(f->name);
	free(f->name);
    }

    free(f);
}

int tmp_write(TMPFILE* f, const char* p, int count)
{
    return fwrite(p, 1, count, f->file) == (size_t)count;
}

int tmp_flush(TMPFILE* f)
{
    return fflush(f->file) == 0;
}

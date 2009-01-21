#ifndef __TMPFILE_H__
#define __TMPFILE_H__
typedef struct _tmpfile TMPFILE;

struct _tmpfile {
    char* name;
    void* file;
} ;

TMPFILE* tmp_new(const char* ext);
int tmp_write(TMPFILE* f, const char* p, int count);
void tmp_close(TMPFILE* f);
void tmp_release(TMPFILE* f);
int tmp_write_eol(TMPFILE* f);
int tmp_flush(TMPFILE* f);
#endif /* __TMPFILE_H__ */

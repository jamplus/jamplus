#ifndef BUFFER_H
#define BUFFER_H

#include <stdio.h>

typedef struct _buffer {
  char *buffer;
  char static_buffer[1024];
  int pos;
  int buffsize;
} BUFFER;

#define buffer_init(buff) ((buff)->buffer = (char*)&(buff)->static_buffer, (buff)->pos = 0, (buff)->buffsize = 1024)

#define buffer_ptr(buff)	((buff)->buffer)
#define buffer_size(buff)	((buff)->buffsize)
#define buffer_pos(buff)	((buff)->pos)
#define buffer_posptr(buff)	((buff)->buffer + (buff)->pos)

#define buffer_reset(buff) ((buff)->pos = 0)


void buffer_openspacehelper(BUFFER *buff, int amount);
void buffer_resize(BUFFER* buff, int size);

#define buffer_free(buff)	buffer_resize(buff, 0)

#define buffer_openspace(buff, amount) \
  if (((int)(amount) + (buff)->pos) > (buff)->buffsize) \
    buffer_openspacehelper((buff), (amount));

#define buffer_addchar(buff, c) { buffer_openspace(buff, 1); (buff)->buffer[(buff)->pos] = (c); (buff)->pos++; }
#define buffer_addstring(buff, str, len) { buffer_openspace((buff), (len)); memcpy((buff)->buffer + (buff)->pos, str, (len)); (buff)->pos += (int)(len); }
#define buffer_putchar(buff, c) (buff)->buffer[(buff)->pos] = (c)
#define buffer_putstring(buff, str, len) { buffer_openspace((buff), (len)); memcpy((buff)->buffer + (buff)->pos, str, (len)); }
#define buffer_setpos(buff, newpos) (buff)->pos = newpos;
#define buffer_deltapos(buff, delta) (buff)->pos += delta
#define buffer_isempty(buff) ((buff)->pos == 0)

#define buffer_getchar(buff) ((buff)->pos + 1 < (buff)->buffsize ? (buff)->buffer[(buff)->pos++] : EOF)

#endif /* BUFFER_H */

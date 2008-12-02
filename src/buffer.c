#include "buffer.h"
#include <string.h>
#include <malloc.h>

void buffer_openspacehelper(BUFFER *buff, int amount)
{
    if (amount + buff->pos < 1024)
        buffer_resize(buff, 1024);
    else
        buffer_resize(buff, amount + buff->pos);
}


void buffer_resize(BUFFER* buff, int size)
{
    if (size == 0)
    {
	if (buff->buffer != (char*)&buff->static_buffer) {
	    free(buff->buffer);
	    buff->buffer = (char*)&buff->static_buffer;
	}
	return;
    }

    if (size < 1024) {
        buff->buffsize = size;
	buff->pos = buff->pos > size ? size : buff->pos;
	if (buff->buffer != (char*)&buff->static_buffer) {
	    free(buff->buffer);
            buff->buffer = (char*)&buff->static_buffer;
	}
        return;
    }

    if (buff->buffer == (char*)&buff->static_buffer) {
	buff->buffer = (char*)malloc(size);
	memcpy(buff->buffer, &buff->static_buffer, buff->pos);
	buff->buffsize = size;
    } else {
        buff->buffsize = size > buff->buffsize * 2 ? size : buff->buffsize * 2;
        buff->buffer = (char*)realloc(buff->buffer, buff->buffsize);
    }
}


/*
 * Copyright 1993, 2000 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * variable.h - handle jam multi-element variables
 *
 * 11/04/02 (seiwald) - const-ing for string literals
 */

#include "buffer.h"

void 	var_defines( const char **e );
int	var_string( const char *in, BUFFER *buff, int outsize, LOL *lol, char separator );
LIST * 	var_get( const char *symbol );
void 	var_set( const char *symbol, LIST *value, int flag );
LIST * 	var_swap( const char *symbol, LIST *value );
void 	var_done();

/*
 * Defines for var_set().
 */

# define VAR_SET	0	/* override previous value */
# define VAR_APPEND	1	/* append to previous value */
# define VAR_DEFAULT	2	/* set only if no previous value */
/* commented out so jamgram.y can compile #ifdef OPT_MINUS_EQUALS_EXT */
# define VAR_REMOVE	3	/* filter an old value */
/* commented out so jamgram.y can compile #endif */


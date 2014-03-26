/*
 * Copyright 1993, 1995 Christopher Seiwald.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * command.c - maintain lists of commands
 *
 * 01/20/00 (seiwald) - Upgraded from K&R to ANSI C
 * 09/08/00 (seiwald) - bulletproof PIECEMEAL size computation
 */

# include "jam.h"

# include "lists.h"
# include "parse.h"
# include "variable.h"
# include "rules.h"
#ifdef OPT_RESPONSE_FILES
# include "expand.h"
# include "tmpfile.h"
#endif

# include "command.h"
# include "buffer.h"
# include <limits.h>

#ifdef OPT_RESPONSE_FILES
#ifdef OPT_MULTIPASS_EXT
static int cmd_string( RULE* rule, const char *in, BUFFER *buff, int outsize,
		       LOL *lol, TMPLIST **response_files, CMD* cmd);
#else
static int cmd_string( RULE* rule, const char *in, BUFFER *buff, int outsize,
		       LOL *lol, TMPLIST **response_files);
#endif /* OPT_MULTIPASS_EXT */
#endif
/*
 * cmd_new() - return a new CMD or 0 if too many args
 */

CMD *
cmd_new(
	RULE	*rule,
	LIST	*targets,
	LIST	*sources,
	LIST	*shell,
	int	maxline )
{
	BUFFER buff;
	CMD *cmd = (CMD *)malloc( sizeof( CMD ) );

	cmd->rule = rule;
	cmd->shell = shell;
	cmd->next = 0;
	cmd->tail = 0;
#ifdef OPT_RESPONSE_FILES
	cmd->response_files = 0;
#endif
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	cmd->luastring = 0;
#endif

	lol_init( &cmd->args );
	lol_add( &cmd->args, targets );
	lol_add( &cmd->args, sources );

	buffer_init( &cmd->commandbuff );

	/* Bail if the result won't fit in maxline */
	/* We don't free targets/sources/shell if bailing. */

        buffer_init(&buff);
#ifdef OPT_RESPONSE_FILES
#ifdef OPT_MULTIPASS_EXT
    	if ( cmd_string( rule, rule->actions, &buff, maxline, &cmd->args,
			&cmd->response_files, cmd ) < 0 )
	{
	    cmd_free( cmd );
	    return 0;
	}
#ifdef OPT_BUILTIN_LUA_SUPPORT_EXT
	if (rule->flags & RULE_LUA)
	{
	    cmd->luastring = malloc(buffer_pos(&buff) + 1);
	    memcpy(cmd->luastring, buffer_ptr(&buff), buffer_pos(&buff));
	    buffer_free(&buff);
	}
	else
#endif
#ifdef OPT_ACTIONS_DUMP_TEXT_EXT
	if (rule->flags & RULE_WRITEFILE)
	{
	    buffer_free(&buff);
	}
	else
#endif
	if (buffer_pos(&buff) < maxline)
	{
	    buffer_addstring( &cmd->commandbuff, buffer_ptr( &buff ), buffer_pos( &buff ) );
	    buffer_free(&buff);
	}
	else
#else
    	if( cmd_string( rule, rule->actions, &buff, maxline, &cmd->args,
			&cmd->response_files ) < 0 )
#endif /* OPT_MULTIPASS_EXT */
#else
	if( var_string( rule->actions, &cmd->commandbuff, maxline, &cmd->args, ' ' ) < 0 )
#endif
	{
	    cmd_free( cmd );
	    return 0;
	}
#ifdef OPT_PIECEMEAL_PUNT_EXT
        /* if the command was too long and we can possibly make it
           shorter, try.  Otherwise hope for the best. */
        if ( strlen( buffer_ptr( &cmd->commandbuff ) ) > MAXLINE && rule->flags & RULE_PIECEMEAL )
        {
            cmd_free( cmd );
            return 0;
        }
#endif

	return cmd;
}

/*
 * cmd_free() - free a CMD
 */

void
cmd_free( CMD *cmd )
{
	lol_free( &cmd->args );
	list_free( cmd->shell );
#ifdef OPT_RESPONSE_FILES
	while( cmd->response_files )
	{
	    TMPLIST *t;

	    t = cmd->response_files;
	    cmd->response_files = t->next;
	    tmp_release( t->file );
	    free( t );
	}
#endif
	buffer_free( &cmd->commandbuff );
	free( (char *)cmd );
}

#ifdef OPT_RESPONSE_FILES
/*
 * cmd_string() - expand a string with the magic 'expand to file'
 * syntax, replacing the syntax with the names of temporary files.
 *
 * Copies in to out; doesn't modify targets & sources.  Returns -1
 * when out is too small.
 *
 * Adds files created into the response_files linked list.  The caller
 * is responsible for deletion, even in failure conditions.
 */
#ifdef OPT_MULTIPASS_EXT
static int
cmd_string(
    RULE     *rule,
    const char *in,
    BUFFER   *buff,
    int	      outsize,
    LOL	     *lol,
    TMPLIST **response_files,
    CMD* cmd)
#else
static int
cmd_string(
    RULE     *rule,
    const char *in,
    BUFFER   *buff,
    int	      outsize,
    LOL	     *lol,
    TMPLIST **response_files)
#endif
{
    while (*in  &&  (int)buffer_pos(buff) < outsize) {
	int 	dollar = 0;
	size_t	lastword;

	/* Copy white space */

	while (isspace(*in)) {
	    if ((int)buffer_pos(buff) >= outsize)
		return -1;
	    buffer_addchar(buff, *in++);
	}

	lastword = buffer_pos(buff);

	/* Copy non-white space, watching for variables and optionally
	 * for response file indicators. */

	while (*in && !isspace(*in)) {
	    if ((int)buffer_pos(buff) >= outsize)
		return -1;

	    if (in[0] == '$' && in[1] == '(') {
		dollar++;
		} else if (in[0] == '$' && in[1] == '@' && in[2] == '(') {
		in++;
		dollar++;
	    } else if (((rule->flags & RULE_RESPONSE) && in[0] == '@' && in[1] == '(')
	        || (in[0] == '^' && in[1] == '^' && in[2] == '^' && in[3] == '(')) {
		const char *ine;
		int depth;
		TMPLIST *r;
		size_t tlen;
        int offset;

		r = malloc(sizeof(*r));
		r->next = *response_files;
		*response_files = r;
		r->file = tmp_new(0);
		if (!r->file)
		{
		    printf("jam: Could not create temporary file\n");
		    exit(EXITBAD);
		}

		tlen = strlen(r->file->name);
		if ((int)buffer_pos(buff) + tlen >= outsize)
		    return -1;
		buffer_addstring(buff, r->file->name, tlen);

        if (in[0] == '^')
		offset = 4;
		else
		offset = 2;
        ine = in + offset;
		depth = 1;
		while (*ine && depth > 0) {
		    switch (*ine) {
			case '(':
			    ++depth;
			    break;
			case ')':
			    --depth;
			    break;
		    }
		    ++ine;
		}
		if (globs.noexec == 0  &&  depth == 0) {
		    char save;
		    int expandedSize;
		    BUFFER subbuff;
		    BUFFER expandedsubbuff;
		    int expandedsubbuffsize;

		    save = ine[-1];
		    ((char*)ine)[-1] = '\0';

		    buffer_init(&subbuff);

		    while (0 > (expandedSize = var_string(
				     in + offset, &subbuff, 0, lol, ' '))) {
			    printf("jam: out of memory");
			    exit(EXITBAD);
			}

		    ((char*)ine)[-1] = save;

		    buffer_init(&expandedsubbuff);
		    expandedsubbuffsize = cmd_string(rule, buffer_ptr(&subbuff), &expandedsubbuff, INT_MAX, lol, response_files, cmd);

		    tmp_write(r->file, buffer_ptr( &expandedsubbuff ), expandedsubbuffsize - 1);
//		    tmp_write(r->file, buffer_ptr( &subbuff ), expandedSize - 1);

		    buffer_free(&expandedsubbuff);
		    buffer_free(&subbuff);

		    if (!tmp_flush(r->file)) {
			printf("jam: I/O error on temporary file\n");
			exit(EXITBAD);
		    }
		    tmp_close(r->file);
		}
		in = ine;
		break;
#ifdef OPT_ACTIONS_DUMP_TEXT_EXT
	    } else if (in[0] == '^' && in[1] == '^' && in[2] == '(') {
		const char *ine;
		int depth;

		rule->flags |= RULE_WRITEFILE;
		ine = in + 3;
		depth = 1;
		while (*ine && *ine != '|' && depth > 0) {
		    switch (*ine) {
			case '(':
			    ++depth;
			    break;
			case ')':
			    --depth;
			    break;
		    }
		    ++ine;
		}
		if (globs.noexec == 0  &&  depth == 1) {
		    char save;
		    int expandedSize;
		    FILE* file;
		    BUFFER subbuff;

		    save = ine[0];
		    ((char*)ine)[0] = '\0';

		    buffer_init( &subbuff );

		    while (0 > (expandedSize = var_string(
				     in + 3, &subbuff, 0, lol, ' '))) {
			    printf("jam: out of memory");
			    exit(EXITBAD);
			}

		    ((char*)ine)[0] = save;

		    file = fopen(buffer_ptr( &subbuff ), "wb");
		    buffer_free( &subbuff );

		    ine++;
		    in = ine;
		    depth = 1;
		    while (*ine && depth > 0) {
			switch (*ine) {
			    case '(':
				++depth;
				break;
			    case ')':
				--depth;
				break;
			}
			++ine;
		    }
		    if (depth == 0) {
			char save;
			int expandedSize;
			BUFFER subbuff2;

			save = ine[-1];
			((char*)ine)[-1] = '\0';

			buffer_init( &subbuff2 );

			while (0 > (expandedSize = var_string(
					 in, &subbuff2, 0, lol, ' '))) {
				printf("jam: out of memory");
				exit(EXITBAD);
			    }

			((char*)ine)[-1] = save;

			fwrite(buffer_ptr( &subbuff2 ), 1, expandedSize - 1, file);
			fflush(file);
			fclose(file);
			buffer_free( &subbuff2 );
		    }
		}

		in = ine;
		break;
#endif
	    } else if (in[0] == '@' && in[1] == '(') {
		dollar++;
		}

	    buffer_addchar(buff, *in++);
	}

	if (dollar) {
	    LIST *expanded = var_expand(L0, buffer_ptr(buff) + lastword, buffer_posptr(buff), lol, 0);
	    LISTITEM *l = list_first(expanded);

	    buffer_setpos(buff, lastword);

	    while (l)
	    {
		size_t so = strlen(list_value(l));

		if ((int)buffer_pos(buff) + so >= outsize)
		    return -1;
		buffer_addstring(buff, list_value(l), so);

		/* Separate with space */

		l = list_next(l);
		if (l) {
		    buffer_addchar(buff, ' ');
		}
	    }
	    list_free(expanded);
	}
    }

    if ((int)buffer_pos(buff) >= outsize)
	return -1;
    buffer_addchar(buff, 0);
    return (int)buffer_pos(buff);
}
#endif

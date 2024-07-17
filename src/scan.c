/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * scan.c - the jam yacc scanner
 *
 * 12/26/93 (seiwald) - bump buf in yylex to 10240 - yuk.
 * 09/16/94 (seiwald) - check for overflows, unmatched {}'s, etc.
 *			Also handle tokens abutting EOF by remembering
 *			to return EOF now matter how many times yylex()
 *			reinvokes yyline().
 * 02/11/95 (seiwald) - honor only punctuation keywords if SCAN_PUNCT.
 * 07/27/95 (seiwald) - Include jamgram.h after scan.h, so that YYSTYPE is
 *			defined before Linux's yacc tries to redefine it.
 * 01/10/01 (seiwald) - \ can now escape any whitespace char
 * 11/04/02 (seiwald) - const-ing for string literals
 */

#include "jam.h"
#include "lists.h"
#include "parse.h"
#include "scan.h"
#include "jamgram.h"
#include "jambase.h"
#include "newstr.h"
#include "miniz.h"
#include "variable.h"
#include "filesys.h"

extern mz_zip_archive *zip_attemptopen();
extern int zip_findfile(const char *filename);

struct keyword {
	const char *word;
	int type;
} keywords[] = {
# include "jamgramtab.h"
	{ 0, 0 }
} ;

struct include {
	struct include 	*next;		/* next serial include file */
	const char 	*string;	/* pointer into current line */
	char		**strings;	/* for yyfparse() -- text to parse */
	FILE 		*file;		/* for yyfparse() -- file being read */
	const char 	*fname;		/* for yyfparse() -- file name */
	int 		line;		/* line counter for error messages */
	char**		origstrings; /* strings list was allocated, so free it when done parsing its contents */
	char 		buf[ 512 ];	/* for yyfparse() -- line buffer */
} ;

static struct include *incp = 0; /* current file; head of chain */

#ifdef OPT_IMPROVED_WARNINGS_EXT
static struct include *lastIncp = 0; /* current file; head of chain */
#endif
static int scanmode = SCAN_NORMAL;
static int anyerrors = 0;
static char* symdump(YYSTYPE* s);

# define BIGGEST_TOKEN 10240	/* no single token can be larger */

/*
 * Set parser mode: normal, string, or keyword
 */

void yymode(int n)
{
	scanmode = n;
}

void yyerror(const char* s)
{
	if (incp)
		printf("%s: line %d: ", incp->fname, incp->line);
#ifdef OPT_IMPROVED_WARNINGS_EXT
	else if (lastIncp)
		printf("file may be: %s: ", lastIncp->fname);
#endif

	printf("%s at %s\n", s, symdump(&yylval));

	++anyerrors;
}

#ifdef OPT_IMPROVED_WARNINGS_EXT
char* file_and_line(void)
{
	static char		msg[1024];

	msg[0] = 0;
	if (incp)
		sprintf (msg, "(%s : %d)", incp->fname, incp->line);
	else if (lastIncp)
		sprintf (msg, "(last file: %s)", lastIncp->fname);

	return msg;
}
#endif
int yyanyerrors()
{
	return anyerrors != 0;
}

void yyfparse(const char* s)
{
	struct include* i = (struct include*)malloc(sizeof(*i));

	/* Push this onto the incp chain. */

	i->string = "";
	i->strings = 0;
	i->file = 0;
	i->fname = copystr(s);
	i->line = 0;
	i->origstrings = 0;
	i->next = incp;
	incp = i;

	var_set("JAM_CURRENT_SCRIPT", list_append(L0, i->fname, 0), VAR_SET);

	/* If the filename is "+", it means use the internal jambase. */

	if (!strcmp(s, "+"))
		i->strings = (char**)jambase;
}

void yyfparselines( const char* s, char **lines )
{
	struct include* i = (struct include*)malloc(sizeof(*i));

	/* Push this onto the incp chain. */

	i->string = "";
	i->strings = lines;
	i->file = 0;
	i->fname = copystr(s);
	i->line = 0;
	i->origstrings = 0;
	i->next = incp;
	incp = i;
}

/*
 * yyline() - read new line and return first character
 *
 * Fabricates a continuous stream of characters across include files,
 * returning EOF at the bitter end.
 */

int yyline()
{
	struct include* i = incp;

	if (!incp)
		return EOF;

	/* Once we start reading from the input stream, we reset the */
	/* include insertion point so that the next include file becomes */
	/* the head of the list. */

	/* If necessary, open the file */

	if (!i->strings && !i->file)
	{
		FILE* f = stdin;

		//printf("fopencheck: %s\n", i->fname);
		if (strcmp(i->fname, "-") && !(f = fopen(i->fname, "r")))
		{
			//printf("internalzip: %s\n", i->fname);
			mz_zip_archive* pZipArchive = zip_attemptopen();
			if (pZipArchive != NULL)
			{
				// Search for the file.
					//printf("internalfind: %s\n", i->fname);
				int entryIndex = zip_findfile(i->fname);
				if (entryIndex != -1)
				{

					BUFFER buff;
					buffer_init(&buff);
					buffer_addstring(&buff, "embed:", 6);
					buffer_addstring(&buff, i->fname, strlen(i->fname));
					buffer_addchar(&buff, 0);
					var_set("JAM_CURRENT_SCRIPT", list_append(L0, buffer_ptr(&buff), 0), VAR_SET);
					buffer_free(&buff);

					//printf("internal: %s\n", i->fname);

					size_t bufferSize;
					unsigned char* buffer = (unsigned char*)mz_zip_reader_extract_to_heap(pZipArchive, entryIndex, &bufferSize, 0);
					unsigned char* ptr = buffer;
					unsigned char* linePtr = buffer;
					int numLines = 0;
					while (ptr - buffer < (ptrdiff_t)bufferSize)
					{
						if (*ptr == '\n')
						{
							++numLines;
							linePtr = ptr + 1;
						}
						++ptr;
					}

					if (ptr - linePtr != 0)
					{
						++numLines;
					}

					char** strings = (char**)malloc(sizeof(char*) * (size_t)(numLines + 1));
					ptr = buffer;
					linePtr = buffer;
					numLines = 0;
					while (ptr - buffer < (ptrdiff_t)bufferSize)
					{
						if (*ptr == '\n')
						{
							unsigned char* endOfLinePtr = ptr + 1;
							char* string = malloc(endOfLinePtr - linePtr + 1);
							memcpy(string, linePtr, endOfLinePtr - linePtr);
							string[endOfLinePtr - linePtr] = 0;
							strings[numLines++] = string;
							linePtr = endOfLinePtr;
						}
						++ptr;
					}

					if (ptr - linePtr != 0)
					{
						++numLines;
						unsigned char* endOfLinePtr = ptr + 1;
						char* string = malloc(endOfLinePtr - linePtr + 1);
						memcpy(string, linePtr, endOfLinePtr - linePtr);
						string[endOfLinePtr - linePtr] = 0;
						strings[numLines++] = string;
					}

					strings[numLines] = 0;

					pZipArchive->m_pFree(pZipArchive->m_pIO_opaque, buffer);

					i->strings = strings;
					i->string = "";
					i->origstrings = strings;
				}
				else
				{
					perror(i->fname);
				}
			}
			else
			{
				perror(i->fname);
			}
		}
		else
		{
			//printf("disk: %s\n", i->fname);
			BUFFER buff;
			if (file_absolutepath(i->fname, &buff)) {
				var_set("JAM_CURRENT_SCRIPT", list_append(L0, buffer_ptr(&buff), 0), VAR_SET);
			}
			else {
				var_set("JAM_CURRENT_SCRIPT", list_append(L0, i->fname, 0), VAR_SET);
			}
			buffer_free(&buff);

			i->file = f;
		}
	}

	/* If there is more data in this line, return it. */

	if (*i->string)
		return *i->string++;

	/* If we're reading from an internal string list, go to the */
	/* next string. */

	if (i->strings)
	{
		if (!*i->strings)
			goto next;

		i->line++;
		i->string = *(i->strings++);
		return *i->string++;
	}

	/* If there's another line in this file, start it. */

	if (i->file && fgets(i->buf, sizeof(i->buf), i->file))
	{
		i->line++;
		i->string = i->buf;
		return *i->string++;
	}

next:
	/* This include is done.  */
	/* Free it up and return EOF so yyparse() returns to parse_file(). */
#ifdef OPT_IMPROVED_WARNINGS_EXT
	if (lastIncp)
	{
		freestr(lastIncp->fname);
		free((char*)lastIncp);
	}
	lastIncp = incp;
#endif

	incp = i->next;

	/* Close file, free name */

	if (i->file && i->file != stdin)
		fclose(i->file);

	if (i->origstrings != NULL)
	{
		char** strings = i->origstrings;
		while (*strings != NULL)
		{
			free(*strings);
			++strings;
		}
		free(i->origstrings);
	}

#ifdef OPT_IMPROVED_WARNINGS_EXT
	/* memory leak */
#else
	freestr(i->fname);
	free((char*)i);
#endif

	return EOF;
}

/*
 * yylex() - set yylval to current token; return its type
 *
 * Macros to move things along:
 *
 *	yychar() - return and advance character; invalid after EOF
 *	yyprev() - back up one character; invalid before yychar()
 *
 * yychar() returns a continuous stream of characters, until it hits
 * the EOF of the current include file.
 */

# define yychar() ( *incp->string ? *incp->string++ : yyline() )
# define yyprev() ( incp->string-- )

int yylex()
{
	int c;
	char buf[BIGGEST_TOKEN];
	char* b = buf;

	if (!incp)
		goto eof;

	/* Get first character (whitespace or of token) */

	c = yychar();

	if (scanmode == SCAN_STRING)
	{
		/* If scanning for a string (action's {}'s), look for the */
		/* closing brace.  We handle matching braces, if they match! */

		int nest = 1;

		while (c != EOF && b < buf + sizeof(buf))
		{
			if (c == '{')
				nest++;

			if (c == '}' && !--nest)
				break;

			*b++ = c;

			c = yychar();
		}

		/* We ate the ending brace -- regurgitate it. */

		if (c != EOF)
			yyprev();

		/* Check obvious errors. */

		if (b == buf + sizeof(buf))
		{
			yyerror("action block too big");
			goto eof;
		}

		if (nest)
		{
			yyerror("unmatched {} in action block");
			goto eof;
		}

		*b = 0;
		yylval.type = STRING;
		yylval.string = newstr(buf);

	}
	else
	{
		char* b = buf;
		struct keyword* k;
		int inquote = 0;
		int notkeyword;

		/* Eat white space */

		for (;; )
		{
			/* Skip past white space */

			while (c != EOF && isspace(c))
				c = yychar();

			/* Not a comment?  Swallow up comment line. */

			if (c != '#')
				break;
			while ((c = yychar()) != EOF && c != '\n')
				;
		}

		/* c now points to the first character of a token. */

		if (c == EOF)
			goto eof;

		/* While scanning the word, disqualify it for (expensive) */
		/* keyword lookup when we can: $anything, "anything", \anything */

		notkeyword = c == '$';

		/* look for white space to delimit word */
		/* "'s get stripped but preserve white space */
		/* \ protects next character */

		while (
			c != EOF &&
			b < buf + sizeof(buf) &&
			(inquote || !isspace(c)))
		{
			if (c == '"')
			{
				/* begin or end " */
				inquote = !inquote;
				notkeyword = 1;
			}
			else if (c != '\\')
			{
				/* normal char */
				*b++ = c;
			}
			else if ((c = yychar()) != EOF)
			{
				/* \c */
				*b++ = c;
				notkeyword = 1;
			}
			else
			{
				/* \EOF */
				break;
			}

			c = yychar();
		}

		/* Check obvious errors. */

		if (b == buf + sizeof(buf))
		{
			yyerror("string too big");
			goto eof;
		}

		if (inquote)
		{
			yyerror("unmatched \" in string");
			goto eof;
		}

#ifdef OPT_FIND_BAD_SEMICOLON_USAGE_EXT
		if (!notkeyword && b - 1 > buf)
		{
			if (buf[0] == ';' || *(b - 1) == ';')
			{
				yyerror("found semicolon at the beginning or end of a token.\n\tSurround semicolons with whitespace.");
				goto eof;
			}
			if (buf[0] == ':' || *(b - 1) == ':')
			{
				yyerror("found colon at the beginning or end of a token.\n\tSurround colons with whitespace.");
				goto eof;
			}
		}
#endif

		/* We looked ahead a character - back up. */

		if (c != EOF)
			yyprev();

		/* scan token table */
		/* don't scan if it's obviously not a keyword or if its */
		/* an alphabetic when were looking for punctuation */

		*b = 0;
		yylval.type = ARG;

		if (!notkeyword && !(isalpha(*buf) && scanmode == SCAN_PUNCT))
		{
			for (k = keywords; k->word; k++)
				if (*buf == *k->word && !strcmp(k->word, buf))
				{
					yylval.type = k->type;
					yylval.string = k->word;	/* used by symdump */
					break;
				}
		}

		if (yylval.type == ARG)
			yylval.string = newstr(buf);
	}

	if (DEBUG_SCAN)
		printf("scan %s\n", symdump(&yylval));

	return yylval.type;

eof:
	yylval.type = EOF;
	return yylval.type;
}

static char* symdump(YYSTYPE* s)
{
	static char buf[BIGGEST_TOKEN + 20];

	switch (s->type)
	{
		case EOF:
			sprintf(buf, "EOF");
			break;
		case 0:
			sprintf(buf, "unknown symbol %s", s->string);
			break;
		case ARG:
			sprintf(buf, "argument %s", s->string);
			break;
		case STRING:
			sprintf(buf, "string \"%s\"", s->string);
			break;
		default:
			sprintf(buf, "keyword %s", s->string);
			break;
	}
	return buf;
}

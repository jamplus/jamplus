/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * expand.c - expand a buffer, given variable values
 *
 * External routines:
 *
 *	var_expand() - variable-expand input string into list of strings
 *
 * Internal routines:
 *
 *	var_edit_parse() - parse : modifiers into PATHNAME structure
 *	var_edit_file() - copy input target name to output, modifying filename
 *	var_edit_shift() - do upshift/downshift mods
 *
 * 01/25/94 (seiwald) - $(X)$(UNDEF) was expanding like plain $(X)
 * 04/13/94 (seiwald) - added shorthand L0 for null list pointer
 * 01/20/00 (seiwald) - Upgraded from K&R to ANSI C
 * 01/11/01 (seiwald) - added support for :E=emptyvalue, :J=joinval
 * 01/13/01 (seiwald) - :UDJE work on non-filename strings
 * 02/19/01 (seiwald) - make $($(var):J=x) join multiple values of var
 * 01/25/02 (seiwald) - fixed broken $(v[1-]), by ian godin
 * 10/22/02 (seiwald) - list_new() now does its own newstr()/copystr()
 * 11/04/02 (seiwald) - const-ing for string literals
 * 12/30/02 (armstrong) - fix out-of-bounds access in var_expand()
 */

# include "jam.h"
# include "lists.h"
# include "variable.h"
# include "expand.h"
# include "pathsys.h"
# include "newstr.h"
# include "buffer.h"
# include "regexp.h"
# include "fileglob.h"

#ifdef OPT_EXPAND_BINDING_EXT
# include "parse.h"
# include "rules.h"
# include "search.h"
#endif

# include "hash.h"

typedef struct {
	PATHNAME	f;		/* :GDBSMR -- pieces */
	char		parent;		/* :P -- go to parent directory */
	char		filemods;	/* one of the above applied */
	char		downshift;	/* :L -- downshift result */
	char		upshift;	/* :U -- upshift result */
	PATHPART	empty;		/* :E -- default for empties */
	PATHPART	join;		/* :J -- join list with char */
#ifdef OPT_SLASH_MODIFIERS_EXT
	char		fslash;		/* :/ -- convert all \ to / */
	char		bslash;		/* :\ -- convert all / to \ */
#endif
#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
	LIST		*includes_excludes;
#endif
#ifdef OPT_EXPAND_FILEGLOB_EXT
	char		wildcard;
	PATHPART	wildcard_remove_prepend;
#endif
#ifdef OPT_EXPAND_LITERALS_EXT
	char		expandliteral;
#endif
#ifdef OPT_EXPAND_BINDING_EXT
	char		expandbinding;
#endif
#ifdef OPT_EXPAND_ESCAPE_PATH_EXT
	char		escapepath;
#endif
	char		targetsetting;
	PATHPART	targetname;

} VAR_EDITS ;

static void var_edit_parse( const char *mods, VAR_EDITS *edits );
static void var_edit_file( const char *in, BUFFER *buff, VAR_EDITS *edits );
static void var_edit_shift( char *out, VAR_EDITS *edits );
#ifdef OPT_SLASH_MODIFIERS_EXT
static void var_edit_slash( char *out, VAR_EDITS *edits );
#endif

struct hash *regexhash;

typedef struct
{
    const char *name;
    regexp *re;
} regexdata;

# define MAGIC_COLON	'\001'
# define MAGIC_LEFT	'\002'
# define MAGIC_RIGHT	'\003'

/*
 * var_expand() - variable-expand input string into list of strings
 *
 * Would just copy input to output, performing variable expansion,
 * except that since variables can contain multiple values the result
 * of variable expansion may contain multiple values (a list).  Properly
 * performs "product" operations that occur in "$(var1)xxx$(var2)" or
 * even "$($(var2))".
 *
 * Returns a newly created list.
 */

char leftParen = '(';
char rightParen = ')';

LIST *
var_expand(
	LIST		*prefix,
	const char 	*in,
	const char 	*end,
	LOL		*lol,
	int		cancopyin )
{
	BUFFER buff;
	const char *inp = in;
	int depth;
	size_t save_buffer_pos, ov_save_buffer_pos;
	int literal = 0;

	if( DEBUG_VAREXP )
	    printf( "expand '%.*s'\n", end - in, in );

	/* This gets alot of cases: $(<) and $(>) */

	if( end - in == 4 && in[0] == '$' && in[1] == leftParen && in[3] == rightParen )
	{
	    switch( in[2] )
	    {
	    case '1':
	    case '<':
		return list_copy( prefix, lol_get( lol, 0 ) );

	    case '2':
	    case '>':
		return list_copy( prefix, lol_get( lol, 1 ) );
	    }
	}

	buffer_init( &buff );

	/* Just try simple copy of in to out. */

	while( in < end ) {
	    char ch = *in++;
	    buffer_addchar( &buff, ch );
	    if( ch == '$' && *in == leftParen )
		goto expand;
#ifdef OPT_EXPAND_LITERALS_EXT
	    if( ch == '@' && *in == leftParen ) {
		literal = 1;
		goto expand;
	    }
	    if( ch == '@' && in[0] == '$' && in[1] == leftParen ) {
		++in;
		literal = 1;
		goto expand;
	    }
#endif
	}

	/* No variables expanded - just add copy of input string to list. */

	/* Cancopyin is an optimization: if the input was already a list */
	/* item, we can use the copystr() to put it on the new list. */
	/* Otherwise, we use the slower newstr(). */

	buffer_putchar( &buff, 0 );

	if( cancopyin ) {
	    LIST *new_list = list_append( prefix, inp, 1 );
	    buffer_free( &buff );
	    return new_list;
	}
	else {
	    LIST *new_list = list_append( prefix, buffer_ptr( &buff ), 0 );
	    buffer_free( &buff );
	    return new_list;
	}

    expand:
	/*
	 * Input so far (ignore blanks):
	 *
	 *	stuff-in-outbuf $(variable) remainder
	 *			 ^	             ^
	 *			 in		     end
	 * Output so far:
	 *
	 *	stuff-in-outbuf $
	 *	^	         ^
	 *	out_buf          out
	 *
	 *
	 * We just copied the $ of $(...), so back up one on the output.
	 * We now find the matching close paren, copying the variable and
	 * modifiers between the $( and ) temporarily into out_buf, so that
	 * we can replace :'s with MAGIC_COLON.  This is necessary to avoid
	 * being confused by modifier values that are variables containing
	 * :'s.  Ugly.
	 */

	depth = 1;
	buffer_deltapos( &buff, -1 );
	save_buffer_pos = buffer_pos( &buff );
	in++;

	while( in < end && depth )
	{
	    char ch = *in++;
	    buffer_addchar( &buff, ch );
        if ( ch == leftParen )
        {
            depth++;
        }
        else if ( ch == rightParen )
        {
            depth--;
        }
        else
        {
	    switch( ch )
	    {
	    case ':': buffer_deltapos( &buff, -1 ); buffer_addchar( &buff, MAGIC_COLON ); break;
	    case '[': buffer_deltapos( &buff, -1 ); buffer_addchar( &buff, MAGIC_LEFT ); break;
	    case ']': buffer_deltapos( &buff, -1 ); buffer_addchar( &buff, MAGIC_RIGHT ); break;
	    }
        }
	}

	/* Copied ) - back up. */

	buffer_deltapos( &buff, -1 );
	ov_save_buffer_pos = buffer_pos( &buff );
	buffer_setpos( &buff, save_buffer_pos );

	/*
	 * Input so far (ignore blanks):
	 *
	 *	stuff-in-outbuf $(variable) remainder
	 *			            ^        ^
	 *			            in       end
	 * Output so far:
	 *
	 *	stuff-in-outbuf variable
	 *	^	        ^       ^
	 *	out_buf         out	ov
	 *
	 * Later we will overwrite 'variable' in out_buf, but we'll be
	 * done with it by then.  'variable' may be a multi-element list,
	 * so may each value for '$(variable element)', and so may 'remainder'.
	 * Thus we produce a product of three lists.
	 */

	{
	    LIST *variables = 0;
	    LIST *remainder = 0;
	    LISTITEM *vars;

	    /* Recursively expand variable name & rest of input */

	    if( save_buffer_pos < ov_save_buffer_pos )
		variables = var_expand( L0, buffer_posptr( &buff ), buffer_ptr( &buff ) + ov_save_buffer_pos, lol, 0 );
	    if( in < end )
		remainder = var_expand( L0, in, end, lol, 0 );

	    /* Now produce the result chain */

	    /* For each variable name */

	    for( vars = list_first(variables); vars; vars = list_next( vars ) )
	    {
		LIST *value, *evalue = 0;
		LISTITEM* valueSliceStart = NULL;
#ifdef OPT_EXPAND_LITERALS_EXT
		LIST *origvalue = 0;
#endif
		char *colon;
		char *bracket;
		BUFFER varnamebuff;
		int sub1 = 0, sub2 = -1;
		VAR_EDITS edits;
		memset(&edits, 0, sizeof(VAR_EDITS));
		if (leftParen == '{') {
			edits.empty.ptr = "";
			edits.empty.len = 0;
		}

		/* Look for a : modifier in the variable name */
		/* Must copy into varname so we can modify it */

		buffer_init( &varnamebuff );
		buffer_addstring( &varnamebuff, list_value(vars), strlen( list_value(vars) ) );
		buffer_addchar( &varnamebuff, 0 );

		if( ( colon = strchr( buffer_ptr( &varnamebuff ), MAGIC_COLON ) ) )
		{
		    *colon = '\0';
		    var_edit_parse( colon + 1, &edits );
		}

		/* Look for [x-y] and [x-] subscripting */
		/* sub1 is x (0 default) */
		/* sub2 is length (-1 means forever) */

		if( ( bracket = strchr( buffer_ptr( &varnamebuff ), MAGIC_LEFT ) ) )
		{
		    char *dash;

		    if( ( dash = strchr( bracket + 1, '-' ) ) )
			*dash = '\0';

		    sub1 = atoi( bracket + 1 ) - 1;

		    if( !dash )
			sub2 = 1;
		    else if( !dash[1] || dash[1] == MAGIC_RIGHT )
			sub2 = -1;
		    else
			sub2 = atoi( dash + 1 ) - sub1;

		    *bracket = '\0';
		}

		/* Get variable value, specially handling $(<), $(>), $(n) */

#ifdef OPT_EXPAND_LITERALS_EXT
		if ( !literal )
#endif
		{
		    const char* varname = buffer_ptr( &varnamebuff );
		    if( varname[0] == '<' && !varname[1] )
			value = lol_get( lol, 0 );
		    else if( varname[0] == '>' && !varname[1] )
			value = lol_get( lol, 1 );
		    else if( varname[0] >= '1' && varname[0] <= '9' && !varname[1] )
			value = lol_get( lol, varname[0] - '1' );
			else if ( edits.targetsetting ) {
				TARGET* t = bindtarget(edits.targetname.ptr);
				SETTINGS* settings = quicksettingslookup(t, varname);
				if (settings)
					value = list_copy(L0, settings->value);
				else
					value = L0;
			} else
			value = var_get( varname );
		}
#ifdef OPT_EXPAND_LITERALS_EXT
		else {
		    origvalue = value = list_append( L0, buffer_ptr( &varnamebuff ), 0 );
		}
#endif

		/* The fast path: $(x) - just copy the variable value. */
		/* This is only an optimization */

		if( buffer_isempty( &buff ) && !bracket && !colon && in == end )
		{
		    prefix = list_copy( prefix, value );
		    buffer_free( &buff );
		    continue;
		}

		/* Handle start subscript */
		valueSliceStart = list_first(value);
		while(sub1 > 0 && valueSliceStart)
		{
			sub1 -= 1;
			valueSliceStart = list_next(valueSliceStart);
		}

		/* Empty w/ :E=default? */

		if( !valueSliceStart && (colon || leftParen == '{') && edits.empty.ptr ) {
		    evalue = value = list_append( L0, edits.empty.ptr, 0 );
		    valueSliceStart = list_first(value);
		}

#ifdef OPT_EXPAND_LITERALS_EXT
		if ( colon && edits.expandliteral ) {
		    LOL lol;
		    char const* string = list_value(list_first(value));
		    LIST *newvalue = var_expand( L0, string, string + strlen( string ), &lol, 0 );
		    if ( origvalue ) {
			list_free( origvalue );
			origvalue = 0;
		    }
		    value = newvalue;
			valueSliceStart = list_first(value);
		    sub2 = -1;
		}
#endif

#ifdef OPT_EXPAND_FILEGLOB_EXT
		if ( edits.wildcard ) {
		    LIST *newl = L0;
		    for( ; valueSliceStart; valueSliceStart = list_next( valueSliceStart ) ) {
				LIST *foundfiles = L0;
				fileglob* glob;

				/* Handle end subscript (length actually) */
				if( sub2 >= 0 && --sub2 < 0 )
					break;

				glob = fileglob_Create( list_value(valueSliceStart) );
				while ( fileglob_Next( glob ) ) {
					foundfiles = list_append( foundfiles, fileglob_FileName( glob ) + edits.wildcard_remove_prepend.len, 0 );
				}
				fileglob_Destroy( glob );

				/* TODO: Efficiency: Just append to newl above? */
				newl = list_copy( newl, foundfiles );
				list_free( foundfiles );
			}
			if ( origvalue ) {
				list_free( origvalue );
				origvalue = 0;
		    }

		    value = newl;
		    origvalue = value;
			valueSliceStart = list_first(value);
		}
#endif

		/* For each variable value */

		for( ; valueSliceStart; valueSliceStart = list_next( valueSliceStart ) )
		{
		    LISTITEM *rem;
		    size_t save_buffer_pos;
		    size_t end_buffer_pos;
		    const char *valuestring;

		    /* Handle end subscript (length actually) */

		    if( sub2 >= 0 && --sub2 < 0 )
			break;

		    /* Apply : mods, if present */

		    save_buffer_pos = buffer_pos( &buff );

		    valuestring = list_value(valueSliceStart);

#ifdef OPT_EXPAND_BINDING_EXT
		    if( colon && edits.expandbinding ) {
				SETTINGS *expandText;
				TARGET *t = bindtarget( valuestring );
				expandText = quicksettingslookup( t, "EXPAND_TEXT" );
				if ( expandText && list_first(expandText->value) ) {
					valuestring = list_value(list_first(expandText->value));
				} else {
					if( t->binding == T_BIND_UNBOUND ) {
						t->boundname = search_using_target_settings( t, t->name, &t->time );
						t->binding = t->time ? T_BIND_EXISTS : T_BIND_MISSING;
					}
					valuestring = t->boundname;
				}
		    }
#endif

		    if( colon && edits.filemods ) {
			var_edit_file( valuestring, &buff, &edits );
		    } else {
			buffer_addstring( &buff, valuestring, strlen( valuestring ) + 1 );
		    }
		    buffer_setpos( &buff, save_buffer_pos );

		    if( colon && ( edits.upshift || edits.downshift ) )
			var_edit_shift( buffer_posptr( &buff ), &edits );

#ifdef OPT_SLASH_MODIFIERS_EXT
		    if( colon && ( edits.fslash || edits.bslash ) )
			var_edit_slash( buffer_posptr( &buff ), &edits );
#endif

#ifdef OPT_EXPAND_ESCAPE_PATH_EXT
			if ( colon && edits.escapepath )
			{
				const char* ptr = buffer_posptr( &buff );
				const char* endptr = ptr + strlen( ptr );
				BUFFER escapebuff;
				buffer_init( &escapebuff );
			    save_buffer_pos = buffer_pos( &buff );

#ifdef NT
				while ( ptr != endptr  &&  *ptr != ' '  &&  *ptr != '/' )
					++ptr;
				if (*ptr == ' '  ||  *ptr == '/' ) {
					buffer_addchar( &escapebuff, '"' );
					buffer_addstring( &escapebuff, buffer_posptr( &buff ), endptr - buffer_posptr( &buff ) );
					buffer_addchar( &escapebuff, '"' );
					buffer_addchar( &escapebuff, 0 );
					buffer_addstring( &buff, buffer_ptr( &escapebuff ), buffer_pos( &escapebuff ) );
				}

#else
				while ( ptr != endptr ) {
					if ( *ptr == ' '  ||  *ptr == '\\'  ||  *ptr == leftParen  ||  *ptr == rightParen  ||  *ptr == '"' ) {
						buffer_addchar( &escapebuff, '\\' );
					}
					buffer_addchar( &escapebuff, *ptr );
					++ptr;
				}
				buffer_addchar( &escapebuff, 0 );
				buffer_addstring( &buff, buffer_ptr( &escapebuff ), buffer_pos( &escapebuff ) );
#endif

				buffer_setpos( &buff, save_buffer_pos );
				buffer_free( &escapebuff );
			}
#endif

		    /* Handle :J=joinval */
		    /* If we have more values for this var, just */
		    /* keep appending them (with the join value) */
		    /* rather than creating separate LIST elements. */

		    if( colon && edits.join.ptr &&
		      ( list_next( valueSliceStart ) || list_next( vars ) ) )
		    {
			buffer_setpos( &buff, buffer_pos( &buff ) + strlen( buffer_posptr( &buff ) ) );
			buffer_addstring( &buff, edits.join.ptr, strlen( edits.join.ptr ) + 1 );
			buffer_deltapos( &buff, -1 );
			continue;
		    }

		    /* If no remainder, append result to output chain. */

		    if( in == end )
		    {
			prefix = list_append( prefix, buffer_ptr( &buff ), 0 );
			continue;
		    }

		    /* For each remainder, append the complete string */
		    /* to the output chain. */
		    /* Remember the end of the variable expansion so */
		    /* we can just tack on each instance of 'remainder' */

		    save_buffer_pos = buffer_pos( &buff );
		    end_buffer_pos = strlen( buffer_ptr( &buff ) );
		    buffer_setpos( &buff, end_buffer_pos );

		    for( rem = list_first(remainder); rem; rem = list_next( rem ) )
		    {
			buffer_addstring( &buff, list_value(rem), strlen( list_value(rem) ) + 1 );
			buffer_setpos( &buff, end_buffer_pos );
			prefix = list_append( prefix, buffer_ptr( &buff ), 0 );
		    }

		    buffer_setpos( &buff, save_buffer_pos );
		}

		/* Toss used empty */

		if( evalue )
		    list_free( evalue );

#ifdef OPT_EXPAND_LITERALS_EXT
		if ( origvalue )
		    list_free( origvalue );
#endif

#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
		if ( edits.includes_excludes ) {
		    LIST *newl = L0;
		    LISTITEM* l;

		    LIST *origprefix = prefix;
		    int hasInclude = 0;

		    if ( !regexhash )
			regexhash = hashinit( sizeof(regexdata), "regex" );

		    {
			LISTITEM *inex = list_first(edits.includes_excludes);
			while ( inex ) {
			    char mod = list_value(inex)[0];
			    inex = list_next( inex );

			    if ( mod == 'I' ) {
				hasInclude = 1;
			    }
			}
		    }

		    for (l = list_first(prefix) ; l; l = list_next( l ) )
		    {
			LISTITEM *inex = list_first(edits.includes_excludes);
			int remove = hasInclude;

			while ( inex ) {
			    char mod = list_value(inex)[0];
			    regexp *re;
			    regexdata data, *d = &data;
			    inex = list_next( inex );
			    data.name = list_value(inex);
			    if( !hashcheck( regexhash, (HASHDATA **)&d ) )
			    {
				d->re = jam_regcomp( list_value(inex) );
				(void)hashenter( regexhash, (HASHDATA **)&d );
			    }
			    re = d->re;
			    inex = list_next( inex );

			    if ( mod == 'X' ) {
				if( jam_regexec( re, list_value(l) ) )
				    remove = 1;
			    } else if ( mod == 'I' ) {
				if( jam_regexec( re, list_value(l) ) )
				    remove = 0;
			    }
			}

			if ( !remove )
			    newl = list_append( newl, list_value(l), 1 );
		    }

			/* TODO: Efficiency: Just modify prefix? */
		    list_free( origprefix );
		    prefix = newl;
		}
#endif

//#ifdef OPT_EXPAND_LITERALS_EXT
//		buffer_free( &buff );
//#endif
#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
		list_free( edits.includes_excludes );
#endif

	    }

	    /* variables & remainder were gifts from var_expand */
	    /* and must be freed */

		list_free( variables );
		list_free( remainder );

	    if( DEBUG_VAREXP )
	    {
		printf( "expanded to " );
		list_print( prefix );
		printf( "\n" );
	    }

	    buffer_free( &buff );
	    return prefix;
	}
}

/*
 * var_edit_parse() - parse : modifiers into PATHNAME structure
 *
 * The : modifiers in a $(varname:modifier) currently support replacing
 * or omitting elements of a filename, and so they are parsed into a
 * PATHNAME structure (which contains pointers into the original string).
 *
 * Modifiers of the form "X=value" replace the component X with
 * the given value.  Modifiers without the "=value" cause everything
 * but the component X to be omitted.  X is one of:
 *
 *	G <grist>
 *	D directory name
 *	B base name
 *	S .suffix
 *	M (member)
 *	R root directory - prepended to whole path
 *
 * This routine sets:
 *
 *	f->f_xxx.ptr = 0
 *	f->f_xxx.len = 0
 *		-> leave the original component xxx
 *
 *	f->f_xxx.ptr = string
 *	f->f_xxx.len = strlen( string )
 *		-> replace component xxx with string
 *
 *	f->f_xxx.ptr = ""
 *	f->f_xxx.len = 0
 *		-> omit component xxx
 *
 * var_edit_file() below and path_build() obligingly follow this convention.
 */

static void
var_edit_parse(
	const char	*mods,
	VAR_EDITS	*edits )
{
	int havezeroed = 0;
	memset( (char *)edits, 0, sizeof( *edits ) );

	while( *mods )
	{
	    char *p;
	    PATHPART *fp;
#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
	    char mod[2];
	    mod[1] = 0;
#endif

	    switch( *mods++ )
	    {
	    case 'L': edits->downshift = 1; continue;
	    case 'U': edits->upshift = 1; continue;
	    case 'P': edits->parent = edits->filemods = 1; continue;
	    case 'E': fp = &edits->empty; goto strval;
	    case 'J': fp = &edits->join; goto strval;
	    case 'G': fp = &edits->f.f_grist; goto fileval;
	    case 'R': fp = &edits->f.f_root; goto fileval;
	    case 'D': fp = &edits->f.f_dir; goto fileval;
	    case 'B': fp = &edits->f.f_base; goto fileval;
	    case 'S': fp = &edits->f.f_suffix; goto fileval;
	    case 'M': fp = &edits->f.f_member; goto fileval;
#ifdef OPT_SLASH_MODIFIERS_EXT
	    case '/':  edits->fslash = 1; continue;
	    case '\\': edits->bslash = 1; continue;
#endif
#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
	    case 'I': mod[0] = 'I'; goto listval;
	    case 'X': mod[0] = 'X'; goto listval;
#endif
#ifdef OPT_EXPAND_FILEGLOB_EXT
	    case 'W': edits->wildcard = 1; fp = &edits->wildcard_remove_prepend; goto strval;
#endif
#ifdef OPT_EXPAND_LITERALS_EXT
	    case 'A': edits->expandliteral = 1; continue;
#endif
#ifdef OPT_EXPAND_BINDING_EXT
	    case 'T': edits->expandbinding = 1; continue;
#endif
#ifdef OPT_EXPAND_ESCAPE_PATH_EXT
	    case 'C': edits->escapepath = 1; continue;
#endif
		case 'Z': edits->targetsetting = 1; fp = &edits->targetname; goto strval;
	    case MAGIC_COLON: continue;
	    default: return; /* should complain, but so what... */
	    }

	fileval:

	    /* Handle :CHARS, where each char (without a following =) */
	    /* selects a particular file path element.  On the first such */
	    /* char, we deselect all others (by setting ptr = "", len = 0) */
	    /* and for each char we select that element (by setting ptr = 0) */

	    edits->filemods = 1;

	    if( *mods != '=' )
	    {
		int i;

		if( !havezeroed++ )
		    for( i = 0; i < 6; i++ )
		{
		    edits->f.part[ i ].len = 0;
		    edits->f.part[ i ].ptr = "";
		}

		fp->ptr = 0;
		continue;
	    }

	strval:

	    /* Handle :X=value, or :X */

	    if( *mods != '=' )
	    {
		fp->ptr = "";
		fp->len = 0;
	    }
	    else if( ( p = strchr( mods, MAGIC_COLON ) ) )
	    {
		*p = 0;
		fp->ptr = ++mods;
		fp->len = (int)(p - mods);
		mods = p + 1;
	    }
	    else
	    {
		fp->ptr = ++mods;
		fp->len = (int)(strlen( mods ));
		mods += fp->len;
	    }
#ifdef OPT_EXPAND_INCLUDES_EXCLUDES_EXT
	    continue;

	listval:

	    if( *mods != '=' )
	    {
	    }
	    else if( ( p = strchr( mods, MAGIC_COLON ) ) )
	    {
		*p = 0;
		edits->includes_excludes = list_append( edits->includes_excludes, mod, 0 );
		edits->includes_excludes = list_append( edits->includes_excludes, ++mods, 0 );
		mods = p + 1;
	    }
	    else
	    {
		edits->includes_excludes = list_append( edits->includes_excludes, mod, 0 );
		edits->includes_excludes = list_append( edits->includes_excludes, ++mods, 0 );
		mods += strlen( mods );
	    }
#endif
	}
}

/*
 * var_edit_file() - copy input target name to output, modifying filename
 */

static void
var_edit_file(
	const char *in,
	BUFFER *buff,
	VAR_EDITS *edits )
{
	PATHNAME pathname;
	char		buf[ MAXJPATH ];

	/* Parse apart original filename, putting parts into "pathname" */

	path_parse( in, &pathname );

	/* Replace any pathname with edits->f */

	if( edits->f.f_grist.ptr )
	    pathname.f_grist = edits->f.f_grist;

	if( edits->f.f_root.ptr )
	    pathname.f_root = edits->f.f_root;

	if( edits->f.f_dir.ptr )
	    pathname.f_dir = edits->f.f_dir;

	if( edits->f.f_base.ptr )
	    pathname.f_base = edits->f.f_base;

	if( edits->f.f_suffix.ptr )
	    pathname.f_suffix = edits->f.f_suffix;

	if( edits->f.f_member.ptr )
	    pathname.f_member = edits->f.f_member;

	/* If requested, modify pathname to point to parent */

	if( edits->parent )
	    path_parent( &pathname );

	/* Put filename back together */

#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	path_build( &pathname, buf, 0, 1 );
#else
	path_build( &pathname, buf, 0 );
#endif
	buffer_addstring( buff, buf, strlen( buf ) + 1 );
}

/*
 * var_edit_shift() - do upshift/downshift mods
 */

static void
var_edit_shift(
	char	*out,
	VAR_EDITS *edits )
{
	/* Handle upshifting, downshifting now */

	if( edits->upshift )
	{
	    for( ; *out; ++out )
		*out = (char)toupper( *out );
	}
	else if( edits->downshift )
	{
	    for( ; *out; ++out )
		*out = (char)tolower( *out );
	}
}

#ifdef OPT_SLASH_MODIFIERS_EXT

/*
 * var_edit_slash() - do forward/backward slash mod
 */

static void
var_edit_slash(
	char	*out,
	VAR_EDITS *edits )
{
	/* Handle forward, backward slash modifications now */

	if( edits->fslash )
	{
	    for( ; *out; ++out )
		if( *out == '\\' )
		    *out = '/';
	}
	else if( edits->bslash )
	{
	    for( ; *out; ++out )
		if( *out == '/' )
		    *out = '\\';
	}
}

#endif

/*
 * Copyright 1993-2002 Christopher Seiwald and Perforce Software, Inc.
 *
 * This file is part of Jam - see jam.c for Copyright information.
 */

/*
 * search.c - find a target along $(SEARCH) or $(LOCATE) 
 *
 * 11/04/02 (seiwald) - const-ing for string literals
 */

# include "jam.h"
# include "lists.h"
# include "search.h"
# include "timestamp.h"
# include "pathsys.h"
# include "variable.h"
# include "newstr.h"

const char *
search( 
	const char *target,
	time_t	*time )
{
	PATHNAME f[1];
	LIST	*varlist;
	char	buf[ MAXJPATH ];
#ifdef OPT_PATH_BINDING_EXT
	PATHNAME bf[1];
#endif

	/* Parse the filename */

	path_parse( target, f );

	f->f_grist.ptr = 0;
	f->f_grist.len = 0;

#ifdef OPT_PATH_BINDING_EXT
	if ( varlist = var_get( "BINDING" ) )
	{
		path_parse( varlist->string, bf );

		f->f_dir = bf->f_dir;
		f->f_base = bf->f_base;
		f->f_suffix = bf->f_suffix;
	}
#endif

	if( varlist = var_get( "LOCATE" ) )
	{
		f->f_root.ptr = varlist->string;
		f->f_root.len = (int)(strlen( varlist->string ));

		path_build( f, buf, 1 );

		if( DEBUG_SEARCH )
			printf( "locate %s: %s\n", target, buf );

		timestamp( buf, time );

		return newstr( buf );
	}
	else if( varlist = var_get( "SEARCH" ) )
	{
		LIST *searchextensionslist = var_get( "SEARCH_EXTENSIONS" );
		if ( searchextensionslist )
		{
			for ( ; searchextensionslist; searchextensionslist = list_next( searchextensionslist ) )
			{
				while( varlist )
				{
					f->f_root.ptr = varlist->string;
					f->f_root.len = (int)(strlen( varlist->string ));

					strcpy( path_build( f, buf, 1 ), searchextensionslist->string );

					if( DEBUG_SEARCH )
						printf( "search %s: %s\n", target, buf );

					timestamp( buf, time );

					if( *time )
						return newstr( buf );

					varlist = list_next( varlist );
				}
			}
		}
		else
		{
			while( varlist )
			{
				f->f_root.ptr = varlist->string;
				f->f_root.len = (int)(strlen( varlist->string ));

				path_build( f, buf, 1 );

				if( DEBUG_SEARCH )
					printf( "search %s: %s\n", target, buf );

				timestamp( buf, time );

				if( *time )
					return newstr( buf );

				varlist = list_next( varlist );
			}
		}
	}

	/* Look for the obvious */
	/* This is a questionable move.  Should we look in the */
	/* obvious place if SEARCH is set? */

	f->f_root.ptr = 0;
	f->f_root.len = 0;

	path_build( f, buf, 1 );

	if( DEBUG_SEARCH )
		printf( "search %s: %s\n", target, buf );

	timestamp( buf, time );

	return newstr( buf );
}

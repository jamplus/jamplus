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

# include "parse.h"
# include "rules.h"

# include "search.h"
# include "timestamp.h"
# include "pathsys.h"
# include "variable.h"
# include "newstr.h"

static const char *
search_helper( 
	   const char *target,
	   time_t	*time,
	   LIST *(*varget)( const char*, void* ),
	   void *userData )
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
	if ( ( varlist = varget( "BINDING", userData ) ) )
	{
		path_parse( varlist->string, bf );
		
		f->f_dir = bf->f_dir;
		f->f_base = bf->f_base;
		f->f_suffix = bf->f_suffix;
	}
#endif
	
	if( ( varlist = varget( "LOCATE", userData ) ) )
	{
		f->f_root.ptr = varlist->string;
		f->f_root.len = (int)(strlen( varlist->string ));
		
		path_build( f, buf, 1 );
		
		if( DEBUG_SEARCH )
			printf( "locate %s: %s\n", target, buf );
		
		timestamp( buf, time );
		
		return newstr( buf );
	}
	else if( ( varlist = varget( "SEARCH", userData ) ) )
	{
		LIST *searchextensionslist;
		LIST *savevarlist = varlist;
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
		
		searchextensionslist = varget( "SEARCH_EXTENSIONS", userData );
		if ( searchextensionslist )
		{
			for ( ; searchextensionslist; searchextensionslist = list_next( searchextensionslist ) )
			{
				varlist = savevarlist;
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


static LIST *standard_search_var_get( const char *symbol, void *userData ) {
	return var_get( symbol );
}

const char *search( const char *target, time_t	*time ) {
	return search_helper( target, time, standard_search_var_get, NULL );
}

static LIST *search_using_target_settings_var_get( const char *symbol, void *userData ) {
	SETTINGS* settings = quicksettingslookup( (TARGET*)userData, symbol );
	return settings ? settings->value : NULL;
}

const char *search_using_target_settings( TARGET *t, const char *target, time_t *time ) {
	return search_helper( target, time, search_using_target_settings_var_get, t );
}

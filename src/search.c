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
	if ( list_first(varlist = varget( "BINDING", userData )) )
	{
		path_parse( list_value(list_first(varlist)), bf );
		
		f->f_dir = bf->f_dir;
		f->f_base = bf->f_base;
		f->f_suffix = bf->f_suffix;
	}
#endif
	
	if( list_first(varlist = varget( "LOCATE", userData )) )
	{
		f->f_root.ptr = list_value(list_first(varlist));
		f->f_root.len = (int)(strlen( list_value(list_first(varlist)) ));
		
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
		path_build( f, buf, 1, 1 );
#else
		path_build( f, buf, 1 );
#endif
		
		if( DEBUG_SEARCH )
			printf( "locate %s: %s\n", target, buf );
		
		timestamp( buf, time, 0 );
		
		return newstr( buf );
	}
	else if( list_first(varlist = varget( "SEARCH", userData )) )
	{
		LIST *searchextensionslist;
		LISTITEM* var = list_first(varlist);
		while( var )
		{
			f->f_root.ptr = list_value(var);
			f->f_root.len = (int)(strlen( list_value(var) ));
			
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
			path_build( f, buf, 1, 1 );
#else
			path_build( f, buf, 1 );
#endif
			
			if( DEBUG_SEARCH )
				printf( "search %s: %s\n", target, buf );
			
			timestamp( buf, time, 0 );
			
			if( *time )
				return newstr( buf );
			
			var = list_next( var );
		}
		
		searchextensionslist = varget( "SEARCH_EXTENSIONS", userData );
		if ( list_first(searchextensionslist) )
		{
			LISTITEM* ext = list_first(searchextensionslist);
			for ( ; ext; ext = list_next(ext) )
			{
				LISTITEM* var = list_first(varlist);
				while( var )
				{
					f->f_root.ptr = list_value(var);
					f->f_root.len = (int)(strlen( list_value(var) ));
					
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
					strcpy( path_build( f, buf, 1, 1 ), list_value(ext) );
#else
					strcpy( path_build( f, buf, 1 ), list_value(ext) );
#endif
					
					if( DEBUG_SEARCH )
						printf( "search %s: %s\n", target, buf );
					
					timestamp( buf, time, 0 );
					
					if( *time )
						return newstr( buf );
					
					var = list_next( var );
				}
			}
		}			
	}
	
	/* Look for the obvious */
	/* This is a questionable move.  Should we look in the */
	/* obvious place if SEARCH is set? */
	
	f->f_root.ptr = 0;
	f->f_root.len = 0;
	
#ifdef OPT_ROOT_PATHS_AS_ABSOLUTE_EXT
	path_build( f, buf, 1, 1 );
#else
	path_build( f, buf, 1 );
#endif
	
	if( DEBUG_SEARCH )
		printf( "search %s: %s\n", target, buf );
	
	timestamp( buf, time, 0 );
	
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

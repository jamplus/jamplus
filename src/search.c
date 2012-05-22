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
	   NewList *(*varget)( const char*, void* ),
	   void *userData )
{
	PATHNAME f[1];
	NewList	*varlist;
	char	buf[ MAXJPATH ];
#ifdef OPT_PATH_BINDING_EXT
	PATHNAME bf[1];
#endif
	
	/* Parse the filename */
	
	path_parse( target, f );
	
	f->f_grist.ptr = 0;
	f->f_grist.len = 0;
	
#ifdef OPT_PATH_BINDING_EXT
	if ( newlist_first(varlist = varget( "BINDING", userData )) )
	{
		path_parse( newlist_value(newlist_first(varlist)), bf );
		
		f->f_dir = bf->f_dir;
		f->f_base = bf->f_base;
		f->f_suffix = bf->f_suffix;
	}
#endif
	
	if( newlist_first(varlist = varget( "LOCATE", userData )) )
	{
		f->f_root.ptr = newlist_value(newlist_first(varlist));
		f->f_root.len = (int)(strlen( newlist_value(newlist_first(varlist)) ));
		
		path_build( f, buf, 1 );
		
		if( DEBUG_SEARCH )
			printf( "locate %s: %s\n", target, buf );
		
		timestamp( buf, time );
		
		return newstr( buf );
	}
	else if( newlist_first(varlist = varget( "SEARCH", userData )) )
	{
		NewList *searchextensionslist;
		NewListItem* var = newlist_first(varlist);
		while( var )
		{
			f->f_root.ptr = newlist_value(var);
			f->f_root.len = (int)(strlen( newlist_value(var) ));
			
			path_build( f, buf, 1 );
			
			if( DEBUG_SEARCH )
				printf( "search %s: %s\n", target, buf );
			
			timestamp( buf, time );
			
			if( *time )
				return newstr( buf );
			
			var = newlist_next( var );
		}
		
		searchextensionslist = varget( "SEARCH_EXTENSIONS", userData );
		if ( newlist_first(searchextensionslist) )
		{
			NewListItem* ext = newlist_first(searchextensionslist);
			for ( ; ext; ext = newlist_next(ext) )
			{
				NewListItem* var = newlist_first(varlist);
				while( var )
				{
					f->f_root.ptr = newlist_value(var);
					f->f_root.len = (int)(strlen( newlist_value(var) ));
					
					strcpy( path_build( f, buf, 1 ), newlist_value(ext) );
					
					if( DEBUG_SEARCH )
						printf( "search %s: %s\n", target, buf );
					
					timestamp( buf, time );
					
					if( *time )
						return newstr( buf );
					
					var = newlist_next( var );
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


static NewList *standard_search_var_get( const char *symbol, void *userData ) {
	return var_get( symbol );
}

const char *search( const char *target, time_t	*time ) {
	return search_helper( target, time, standard_search_var_get, NULL );
}

static NewList *search_using_target_settings_var_get( const char *symbol, void *userData ) {
	SETTINGS* settings = quicksettingslookup( (TARGET*)userData, symbol );
	return settings ? settings->value : NULL;
}

const char *search_using_target_settings( TARGET *t, const char *target, time_t *time ) {
	return search_helper( target, time, search_using_target_settings_var_get, t );
}

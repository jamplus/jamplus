#include "FileGlobBase.h"
extern "C" {
#include "lists.h"
}
#include "fileglob.h"

class FileGlob : public FileGlobBase
{
public:
	FileGlob()
		: files( NULL )
	{
	}

	virtual void FoundMatch( const char* name )
	{
		this->files = list_new( this->files, name, 0 );
	}

	LIST *files;
};



extern "C" LIST *fileglob( const char *args )
{
	FileGlob glob;
	glob.MatchPattern( args );
	return glob.files;
}

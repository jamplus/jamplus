#include "fileglob.h"
#if defined(WIN32)
#include <windows.h>
#else
#include <dirent.h>
#include <sys/stat.h>
#define MAX_PATH 256
#endif
#include <assert.h>
#include <time.h>

#define MODIFIER_CHARACTER '@'

#if defined(_MSC_VER)
#pragma warning(disable : 4996)
#endif

#if defined(WIN32)

static time_t glob_ConvertToTime_t(const FILETIME* fileTime)
{
	FILETIME localTime;
	SYSTEMTIME sysTime;
	TIME_ZONE_INFORMATION timeZone;
	struct tm atm;
	int dst;

	FileTimeToLocalFileTime(fileTime, &localTime);
	FileTimeToSystemTime(&localTime, &sysTime);

	// then convert the system time to a time_t (C-runtime local time)
	if (sysTime.wYear < 1900) {
		return 0;
	}

	dst = GetTimeZoneInformation(&timeZone) == TIME_ZONE_ID_STANDARD;
	
	atm.tm_sec = sysTime.wSecond;
	atm.tm_min = sysTime.wMinute;
	atm.tm_hour = sysTime.wHour;
	atm.tm_mday = sysTime.wDay;
	atm.tm_mon = sysTime.wMonth - 1;        // tm_mon is 0 based
	atm.tm_year = sysTime.wYear - 1900;     // tm_year is 1900 based
	atm.tm_isdst = -1;
	return mktime(&atm);
}

#endif

typedef struct fileglob_StringNode {
	struct fileglob_StringNode* next;
	char* buffer;
} fileglob_StringNode;


typedef struct fileglob_Context {
	struct fileglob_Context* prev;

	char patternBuf[MAX_PATH * 2];
	char* pattern;

	char basePath[MAX_PATH];
	size_t basePathLen;
	char* basePathLastSlashPtr;
	char* basePathEndPtr;
	char* recurseAtPtr;

	int matchFiles;
	char matchPattern[MAX_PATH];

	WIN32_FIND_DATA fd;
	HANDLE handle;

	fileglob_StringNode* directoryListHead;
	fileglob_StringNode* directoryListTail;

	fileglob_StringNode* iterNode;
} fileglob_Context;


typedef struct fileglob
{
	fileglob_Context* context;
	fileglob_Context* previousContext;

	fileglob_StringNode* exclusiveDirectoryPatternsHead;
	fileglob_StringNode* exclusiveDirectoryPatternsTail;

	fileglob_StringNode* exclusiveFilePatternsHead;
	fileglob_StringNode* exclusiveFilePatternsTail;

	fileglob_StringNode* ignoreDirectoryPatternsHead;
	fileglob_StringNode* ignoreDirectoryPatternsTail;

	fileglob_StringNode* ignoreFilePatternsHead;
	fileglob_StringNode* ignoreFilePatternsTail;

	char combinedName[MAX_PATH * 2];

	int filesAndFolders;
} fileglob;


static void _fileglob_list_clear(fileglob_StringNode** head, fileglob_StringNode** tail) {
	fileglob_StringNode* node;
	for (node = *head; node;) {
		fileglob_StringNode* oldNode = node;
		node = node->next;
		free(oldNode->buffer);
		free(oldNode);
	}

	*head = 0;
	*tail = 0;
}


static void _fileglob_list_append(fileglob_StringNode** head, fileglob_StringNode** tail, const char* theString) {
	size_t patternLen;
	fileglob_StringNode* newNode = (fileglob_StringNode*)malloc(sizeof(fileglob_StringNode));
	if (!*head)
		*head = newNode;
	if (*tail)
		(*tail)->next = newNode;
	*tail = newNode;
	newNode->next = NULL;
	patternLen = strlen(theString);
	newNode->buffer = (char*)malloc(patternLen + 1);
	memcpy(newNode->buffer, theString, patternLen + 1);
}


/**
	\internal
	\author Jack Handy

	Borrowed from http://www.codeproject.com/string/wildcmp.asp.
	Modified by Joshua Jensen.
**/
static int WildMatch(const char* pattern, const char *string, int caseSensitive) {
	const char* mp = 0;
	const char* cp = 0;

	if (caseSensitive) {
		// Handle all the letters of the pattern and the string.
		while (*string != 0  &&  *pattern != '*') {
			if (*pattern != '?') {
				if (*pattern != *string)
					return 0;
			}

			pattern++;
			string++;
		}

		while (*string != 0) {
			if (*pattern == '*') {
				// It's a match if the wildcard is at the end.
				if (*++pattern == 0) {
					return 1;
				}

				mp = pattern;
				cp = string + 1;
			} else {
				if (*pattern == *string  ||  *pattern == '?') {
					pattern++;
					string++;
				} else  {
					pattern = mp;
					string = cp++;
				}
			}
		}
	} else {
		// Handle all the letters of the pattern and the string.
		while (*string != 0  &&  *pattern != '*') {
			if (*pattern != '?') {
				if (toupper(*pattern) != toupper(*string))
					return 0;
			}

			pattern++;
			string++;
		}

		while (*string != 0) {
			if (*pattern == '*') {
				// It's a match if the wildcard is at the end.
				if (*++pattern == 0) {
					return 1;
				}

				mp = pattern;
				cp = string + 1;
			} else {
				if (toupper(*pattern) == toupper(*string)  ||  *pattern == '?') {
					pattern++;
					string++;
				} else {
					pattern = mp;
					string = cp++;
				}
			}
		}
	}

	// Collapse remaining wildcards.
	while (*pattern == '*')
		pattern++;

	return !*pattern;
}

/* Forward declares. */
int _fileglob_GlobHelper(fileglob* self, const char* inPattern);

/**
**/
static void _fileglob_FreeContextLevel(fileglob* self) {
	if (self->context) {
		fileglob_Context* oldContext = self->context;
		_fileglob_list_clear(&oldContext->directoryListHead, &oldContext->directoryListTail);
		self->context = oldContext->prev;
		if (oldContext->handle != INVALID_HANDLE_VALUE) {
			FindClose(oldContext->handle);
		}
		free(oldContext);
	}
}


/**
**/
void _fileglob_Reset(fileglob* self) {
	_fileglob_list_clear(&self->exclusiveDirectoryPatternsHead, &self->exclusiveDirectoryPatternsTail);
	_fileglob_list_clear(&self->exclusiveFilePatternsHead, &self->exclusiveFilePatternsTail);
	_fileglob_list_clear(&self->ignoreDirectoryPatternsHead, &self->ignoreDirectoryPatternsTail);
	_fileglob_list_clear(&self->ignoreFilePatternsHead, &self->ignoreFilePatternsTail);

	while (self->context) {
		_fileglob_FreeContextLevel(self);
	}
}


/**
**/
void fileglob_MatchPattern(fileglob* self, const char* inPattern);

fileglob* fileglob_Create(const char* inPattern) {
	fileglob* self = (fileglob*)malloc(sizeof(fileglob));
	memset(self, 0, sizeof(fileglob));
	fileglob_MatchPattern(self, inPattern);
	return self;
}


/**
**/
void fileglob_Destroy(fileglob* self) {
	if (!self)
		return;
	_fileglob_Reset(self);
	free(self);
}



/**
	Finds all files matching [inPattern].  The wildcard expansion understands
	the following pattern constructs:

	- ?
		- Any single character.
	- *
		- Any character of which there are zero or more of them.
	- **
		- All subdirectories recursively.

	Additionally, if the pattern closes in a single slash, only directories
	are processed.  Forward slashes and backslashes may be used
	interchangeably.

	- *\
		- List all the directories in the current directory.  Can also be
		  *(forwardslash), but it turns off the C++ comment in this message.
	- **\
		- List all directories recursively.

	Wildcards may appear anywhere in the pattern, including directories.

	- *\*\*\*.c

	Note that *.* only matches files that have an extension.  This is different
	than standard DOS behavior.  Use * all by itself to match files, extension
	or not.

	Recursive wildcards can be used anywhere:

	c:/Dir1\**\A*\**\FileDirs*\**.mp3

	This matches all directories under c:\Dir1\ that start with A.  Under all
	of the directories that start with A, directories starting with FileDirs
	are matched recursively.  Finally, all files ending with an mp3 extension
	are matched.

	Any place that has more than two .. for going up a subdirectory is expanded
	a la 4DOS.

	...../StartSearchHere\**

	Expands to:

	../../../../StartSearchHere\**
		
	\param inPattern The pattern to use for matching.
**/
void fileglob_MatchPattern(fileglob* self, const char* inPattern) {
	char pattern[MAX_PATH];
	const char* srcPtr;
	char* destPtr;
	const char* lastSlashPtr;
	int numPeriods;

	if (inPattern == 0)
		inPattern = "*";

	// Give ourselves a local copy of the inPattern with all \ characters
	// changed to / characters and more than two periods expanded.
	srcPtr = inPattern;
	destPtr = pattern;

	// Is it a Windows network path?   If so, don't convert the opening \\.
	if (srcPtr[0] == '\\'   &&   srcPtr[1] == '\\')
	{
		*destPtr++ = *srcPtr++;
		*destPtr++ = *srcPtr++;
	}

	lastSlashPtr = srcPtr - 1;
	numPeriods = 0;
	while (*srcPtr != '\0') {
		char ch = *srcPtr;
		
		///////////////////////////////////////////////////////////////////////
		// Check for slashes or backslashes.
		if (ch == '\\'  ||  ch == '/') {
			*destPtr++ = '/';

			lastSlashPtr = srcPtr;
			numPeriods = 0;
		}

		///////////////////////////////////////////////////////////////////////
		// Check for .
		else if (ch == '.') {
			if (srcPtr - numPeriods - 1 == lastSlashPtr) {
				numPeriods++;
				if (numPeriods > 2) {
					*destPtr++ = '/';
					*destPtr++ = '.';
					*destPtr++ = '.';
				} else {
					*destPtr++ = '.';
				}
			} else {
				*destPtr++ = '.';
			}
		}

		///////////////////////////////////////////////////////////////////////
		// Check for **
		else if (ch == '*'  &&  srcPtr[1] == '*') {
			if (srcPtr - 1 != lastSlashPtr) {
				// Something like this:
				//
				// /Dir**/
				//
				// needs to be translated to:
				//
				// /Dir*/**/
				*destPtr++ = '*';
				*destPtr++ = '/';
			}

			srcPtr += 2;

			*destPtr++ = '*';
			*destPtr++ = '*';

			// Did we get a double star this round?
			if (srcPtr[0] != '/'  &&  srcPtr[0] != '\\') {
				// Handle the case that looks like this:
				//
				// /**Text
				//
				// Translate to:
				//
				// /**/*Text
				*destPtr++ = '/';
				*destPtr++ = '*';
			}
			else if (srcPtr[1] == '\0'  ||  srcPtr[1] == MODIFIER_CHARACTER) {
				srcPtr++;

				*destPtr++ = '/';
				*destPtr++ = '*';
				*destPtr++ = '/';
			}

			// We added one too many in here... the compiler will optimize.
			srcPtr--;
		}

		///////////////////////////////////////////////////////////////////////
		// Check for @
		else if (ch == MODIFIER_CHARACTER) {
			// Gonna finish this processing in another loop.
			break;
		}

		///////////////////////////////////////////////////////////////////////
		// Check for +
		else if (ch == '+') {
			self->filesAndFolders = 1;
		}
			
		///////////////////////////////////////////////////////////////////////
		// Everything else.
		else {
			*destPtr++ = *srcPtr;
		}

		srcPtr++;
	}

	*destPtr = 0;

	// Check for the @.
	if (*srcPtr == MODIFIER_CHARACTER) {
		_fileglob_Reset(self);
	}

	while (*srcPtr == MODIFIER_CHARACTER) {
		char ch;

		srcPtr++;

		ch = *srcPtr++;
		if (ch == '-'  ||  ch == '=') {
			char buffer[1000];
			char* ptr = buffer;
			while (*srcPtr != MODIFIER_CHARACTER  &&  *srcPtr != '\0') {
				*ptr++ = *srcPtr++;
			}

			*ptr = 0;

			if (ch == '-')
				fileglob_AddIgnorePattern(self, buffer);
			else if (ch == '=')
				fileglob_AddExclusivePattern(self, buffer);
		} else
			break;		// Don't know what it is.
	}

	// Start globbing!
	_fileglob_GlobHelper(self, pattern);
}


/**
	Adds a pattern to the file glob database of exclusive patterns.  If any
	exclusive patterns are registered, the ignore database is completely
	ignored.  Only patterns matching the exclusive patterns will be
	candidates for matching.

	\param name The exclusive pattern.
**/
void fileglob_AddExclusivePattern(fileglob* self, const char* pattern)
{
	fileglob_StringNode* node;

	if (pattern[strlen(pattern) - 1] == '/') {
		for (node = self->exclusiveDirectoryPatternsHead; node; node = node->next) {
#if defined(WIN32)
			if (stricmp(node->buffer, pattern) == 0)
#else
			if (strcasecmp(node->buffer, pattern) == 0)
#endif
				return;
		}

		_fileglob_list_append(&self->exclusiveDirectoryPatternsHead, &self->exclusiveDirectoryPatternsTail, pattern);
	} else {
		for (node = self->exclusiveFilePatternsHead; node; node = node->next) {
#if defined(WIN32)
			if (stricmp(node->buffer, pattern) == 0)
#else
			if (strcasecmp(node->buffer, pattern) == 0)
#endif
				return;
		}

		_fileglob_list_append(&self->exclusiveFilePatternsHead, &self->exclusiveFilePatternsTail, pattern);
	}
}


/**
	Adds a pattern to ignore to the file glob database.  If a pattern of
	the given name is found, its contents will not be considered for further
	matching.  The result is as if the pattern did not exist for the search
	in the first place.

	\param name The pattern to ignore.
**/
void fileglob_AddIgnorePattern(fileglob* self, const char* pattern)
{
	fileglob_StringNode* node;

	if (pattern[strlen(pattern) - 1] == '/') {
		for (node = self->ignoreDirectoryPatternsHead; node; node = node->next) {
#if defined(WIN32)
			if (stricmp(node->buffer, pattern) == 0)
#else
			if (strcasecmp(node->buffer, pattern) == 0)
#endif
				return;
		}

		_fileglob_list_append(&self->ignoreDirectoryPatternsHead, &self->ignoreDirectoryPatternsTail, pattern);
	} else {
		for (node = self->ignoreFilePatternsHead; node; node = node->next) {
#if defined(WIN32)
			if (stricmp(node->buffer, pattern) == 0)
#else
			if (strcasecmp(node->buffer, pattern) == 0)
#endif
				return;
		}

		_fileglob_list_append(&self->ignoreFilePatternsHead, &self->ignoreFilePatternsTail, pattern);
	}
}


/**
	Match an exclusive pattern.

	\param text The text to match an exclusive pattern against.
	\return Returns true if the directory should be ignored, false otherwise.
**/
int _fileglob_MatchExclusiveDirectoryPattern(fileglob* self, const char* text) {
	fileglob_StringNode* node;

	for (node = self->exclusiveDirectoryPatternsHead; node; node = node->next) {
		if (WildMatch(node->buffer, text, 0))
			return 1;
	}

	return 0;
}


/**
	Match an exclusive pattern.

	\param text The text to match an exclusive pattern against.
	\return Returns true if the directory should be ignored, false otherwise.
**/
int _fileglob_MatchExclusiveFilePattern(fileglob* self, const char* text) {
	fileglob_StringNode* node;

	for (node = self->exclusiveFilePatternsHead; node; node = node->next) {
		if (WildMatch(node->buffer, text, 0))
			return 1;
	}

	return 0;
}


/**
	Do a case insensitive find for the pattern.

	\param text The text to match an ignore pattern against.
	\return Returns true if the directory should be ignored, false otherwise.
**/
static int _fileglob_MatchIgnoreDirectoryPattern(fileglob* self, const char* text) {
	fileglob_StringNode* node;

	for (node = self->ignoreDirectoryPatternsHead; node; node = node->next) {
		if (WildMatch(node->buffer, text, 0))
			return 1;
	}

	return 0;
}


/**
	Do a case insensitive find for the pattern.

	\param text The text to match an ignore pattern against.
	\return Returns true if the directory should be ignored, false otherwise.
**/
static int _fileglob_MatchIgnoreFilePattern(fileglob* self, const char* text) {
	fileglob_StringNode* node;

	for (node = self->ignoreFilePatternsHead; node; node = node->next) {
		if (WildMatch(node->buffer, text, 0))
			return 1;
	}

	return 0;
}


/**
	\internal Simple path splicing (assumes no '/' in either part)
	\author Matthias Wandel (MWandel@rim.net) http://www.sentex.net/~mwandel/
**/
static void SplicePath(char * dest, const char * p1, const char * p2)
{
	size_t l = strlen(p1);
	if (l == 0) {
		strcpy(dest, p2);
	} else {
		if (l + strlen(p2) > _MAX_PATH-2) {
			// Path too long.
			assert(0);
		}
		memcpy(dest, p1, l + 1);
		if (dest[l-1] != '/'  &&  dest[l-1] != ':') {
			dest[l++] = '/';
		}
		strcpy(dest+l, p2);
	}
}


int fileglob_Next(fileglob* self) {
	return _fileglob_GlobHelper(self, 0);
}


const char* fileglob_FileName(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		SplicePath(self->combinedName, self->context->basePath, self->context->fd.cFileName);
		return self->combinedName;
	}

	return NULL;
}


unsigned __int64 fileglob_CreationTime(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return glob_ConvertToTime_t(&self->context->fd.ftCreationTime);
	}

	return 0;
}


unsigned __int64 fileglob_AccessTime(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return glob_ConvertToTime_t(&self->context->fd.ftLastAccessTime);
	}

	return 0;
}


unsigned __int64 fileglob_WriteTime(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return glob_ConvertToTime_t(&self->context->fd.ftLastWriteTime);
	}

	return 0;
}


unsigned __int64 fileglob_CreationFILETIME(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return ((unsigned __int64)self->context->fd.ftCreationTime.dwHighDateTime << 32) |
				(unsigned __int64)self->context->fd.ftCreationTime.dwLowDateTime;
	}

	return 0;
}


unsigned __int64 fileglob_AccessFILETIME(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return ((unsigned __int64)self->context->fd.ftLastAccessTime.dwHighDateTime << 32) |
				(unsigned __int64)self->context->fd.ftLastAccessTime.dwLowDateTime;
	}

	return 0;
}


unsigned __int64 fileglob_WriteFILETIME(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return ((unsigned __int64)self->context->fd.ftLastWriteTime.dwHighDateTime << 32) |
				(unsigned __int64)self->context->fd.ftLastWriteTime.dwLowDateTime;
	}

	return 0;
}


unsigned __int64 fileglob_FileSize(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return ((unsigned __int64)self->context->fd.nFileSizeLow + ((unsigned __int64)self->context->fd.nFileSizeHigh << 32));
	}

	return 0;
}


int fileglob_IsDirectory(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return (self->context->fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) != 0;
	}

	return 0;
}


int fileglob_IsReadOnly(fileglob* self) {
	if (self->context->handle != INVALID_HANDLE_VALUE) {
		return (self->context->fd.dwFileAttributes & FILE_ATTRIBUTE_READONLY) != 0;
	}

	return 0;
}



/**
	\internal Does all the actual globbing.
	\author Matthias Wandel (MWandel@rim.net) http://http://www.sentex.net/~mwandel/
	\author Joshua Jensen (jjensen@workspacewhiz.com)

	Matthias Wandel wrote the original C algorithm, which is contained in
	his Exif Jpeg header parser at http://www.sentex.net/~mwandel/jhead/ under
	the filename MyGlob.c.  It should be noted that the MAJORITY of this
	function is his, albeit rebranded style-wise.

	I have made the following extensions:

	-	Support for ignoring directories.
	-	Automatic conversion from **Stuff to **\*Stuff.  Allows lookup of
		files by extension, too: '**.h' translates to '**\*.h'.
	-	Ability to handle forward slashes and backslashes.
	-	A minimal C++ class design.
	-	Wildcard matching not based on FindFirstFile().  Should allow greater
		control in the future and patching in of the POSIX fnmatch() function
		on systems that support it.
**/

int _fileglob_GlobHelper(fileglob* self, const char* inPattern)
{
	fileglob_Context* context = self->context;
	int hasWildcard;
	int found;

Setup:
	if (!context) {
		context = (fileglob_Context*)malloc(sizeof(fileglob_Context));
		context->prev = self->context;
		context->handle = INVALID_HANDLE_VALUE;
		context->pattern = NULL;
		context->iterNode = NULL;
		context->directoryListHead = context->directoryListTail = 0;
		context->basePathLastSlashPtr = 0;
		strcpy(context->patternBuf, inPattern);
		self->context = context;
		if (context->prev == NULL)
			return 1;
	}

DoRecursion:
	found = 1;

	if (!context->pattern) {
		char* pattern;

		context->basePathEndPtr = context->basePathLastSlashPtr = context->basePath;
		context->recurseAtPtr = NULL;

		// Split the path into base path and pattern to match against.
		hasWildcard = 0;

		for (pattern = context->patternBuf; *pattern != '\0'; ++pattern) {
			char ch = *pattern;

			// Is it a '?' ?
			if (ch == '?')
				hasWildcard = 1;

			// Is it a '*' ?
			else if (ch == '*') {
				hasWildcard = 1;

				// Is there a '**'?
				if (pattern[1] == '*') {
					// If we're just starting the pattern or the characters immediately
					// preceding the pattern are a drive letter ':' or a directory path
					// '/', then set up the internals for later recursion.
					if (pattern == context->patternBuf  ||  pattern[-1] == '/'  ||  pattern[-1] == ':') {
						char ch2 = pattern[2];
						if (ch2 == '/') {
							context->recurseAtPtr = pattern;
							memcpy(pattern, pattern + 3, strlen(pattern) - 2);
						} else if (ch2 == '\0') {
							context->recurseAtPtr = pattern;
							*pattern = '\0';
						}
					}
				}
			}

			// Is there a '/' or ':' in the pattern at this location?
			if (ch == '/'  ||  ch == ':') {
				if (hasWildcard)
					break;
				else {
					if (pattern[1])
						context->basePathLastSlashPtr = &context->basePath[pattern - context->patternBuf + 1];
					context->basePathEndPtr = &context->basePath[pattern - context->patternBuf + 1];
				}
			}
		}

		context->pattern = pattern;

		// Copy the directory down.
		context->basePathLen = context->basePathEndPtr - context->basePath;
		strncpy(context->basePath, context->patternBuf, context->basePathLen);
		context->basePath[context->basePathLen] = 0;
	}

	if (context->handle == INVALID_HANDLE_VALUE) {
		size_t matchLen;

		// If there is no wildcard this time, then just add the current file and
		// get out of here.
		if (!hasWildcard)
		{
#if defined(WIN32)
#else
			DIR* dirp;
#endif
			int isDir = 0;
			size_t patternLen = strlen(context->patternBuf);
			if (context->patternBuf[patternLen - 1] == '/'  ||  context->patternBuf[patternLen - 1] == '\\') {
			    isDir = 1;
				context->patternBuf[patternLen - 1] = 0;
			}
#if defined(WIN32)
			context->handle = FindFirstFile(context->patternBuf, &context->fd);
			if (isDir) {
				size_t len = strlen(context->fd.cFileName);
				context->fd.cFileName[len] = '/';
				context->fd.cFileName[len + 1] = '\0';
			    context->patternBuf[patternLen - 1] = '/';
			}
			*context->basePathLastSlashPtr = 0;
			if (context->handle != INVALID_HANDLE_VALUE)
				return 1;
#else
			struct stat attr;
			int ret = stat(patternBuf, &attr);
			if (isDir)
			    patternBuf[patternLen - 1] = '/';
			if (ret != -1)
				FoundMatch(patternBuf);
#endif
			goto NewContext;
		}

		// Did we make it to the end of the pattern?  If so, we should match files,
		// since there were no slashes encountered.
		context->matchFiles = *context->pattern == 0;

		// Copy the wildcard matching string.
		matchLen = (context->pattern - context->patternBuf) - context->basePathLen;
		strncpy(context->matchPattern, context->patternBuf + context->basePathLen, matchLen + 1);
		if (context->matchPattern[matchLen] == '/')
			context->matchPattern[matchLen + 1] = 0;

#if defined(WIN32)
		if (!hasWildcard) {
			// This is probably a single file lookup.
			strcpy(context->basePathEndPtr, context->matchPattern);
			if (context->basePathEndPtr[strlen(context->basePathEndPtr) - 1] == '/')
				context->basePathEndPtr[strlen(context->basePathEndPtr) - 1] = 0;
		}
		else {
			// Do the file search with *.* in the directory specified in basePattern.
			strcpy(context->basePathEndPtr, "*.*");
		}
		
		// Start the find.
		context->handle = FindFirstFile(context->basePath, &context->fd);
		if (context->handle == INVALID_HANDLE_VALUE) {
			found = 0;
		}

		// Clear out the *.* so we can use the original basePattern string.
		*context->basePathEndPtr = 0;
	} else {
		goto NextFile;
	}

	// Any files found?
	if (context->handle != INVALID_HANDLE_VALUE)
	{
		for (;;)
		{
			// Is the file a directory?
			if (context->fd.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY) {
				// Knock out "." or ".."
				int ignore = context->fd.cFileName[0] == '.'  &&
						(context->fd.cFileName[1] == 0  ||
							(context->fd.cFileName[1] == '.'  &&  context->fd.cFileName[2] == 0));

				// Should this file be ignored?
				int matches = 0;
				if (!ignore) {
					size_t len = strlen(context->fd.cFileName);
					context->fd.cFileName[len] = '/';
					context->fd.cFileName[len + 1] = '\0';
					matches = WildMatch(context->matchPattern, context->fd.cFileName, 0);
				}

				// Do a wildcard match.
				if (!ignore  &&  matches) {
					// It matched.  Let's see if the file should be ignored.
					
					// See if this is a directory to ignore.
					ignore = _fileglob_MatchIgnoreDirectoryPattern(self, context->fd.cFileName);
					
					// Is this pattern exclusive?
					if (self->exclusiveDirectoryPatternsHead) {
						int exclusive = _fileglob_MatchExclusiveDirectoryPattern(self, context->fd.cFileName);
						ignore = !exclusive;
//						if (exclusive)
//							break;
					}
					
					// Should this file be ignored?
//					if (!ignore  &&  !context->matchFiles  &&  *context->pattern == 0)
//						break;
					if (!ignore) {
						_fileglob_list_append(&context->directoryListHead, &context->directoryListTail, context->fd.cFileName);
						if ((!context->matchFiles  ||  self->filesAndFolders)  &&  *context->pattern == 0)
							break;
					}
				}
			} else {
				// Do a wildcard match.
				if (WildMatch(context->matchPattern, context->fd.cFileName, 0)) {
					// It matched.  Let's see if the file should be ignored.
					int ignore = _fileglob_MatchIgnoreFilePattern(self, context->fd.cFileName);
					
					// Is this pattern exclusive?
					if (!ignore  &&  self->exclusiveFilePatternsHead) {
						ignore = !_fileglob_MatchExclusiveFilePattern(self, context->fd.cFileName);
					}
					
					// Should this file be ignored?
					if (!ignore) {
						if (context->matchFiles)
							break;
					}
				}
			}

NextFile:
			// Look up the next file.
			found = FindNextFile(context->handle, &context->fd) == TRUE;
			if (!found)
				break;
		}

		if (!found) {
			// Close down the file find handle.
			FindClose(context->handle);
			context->handle = INVALID_HANDLE_VALUE;

			context->iterNode = context->directoryListHead;
		}
	}
	
#else
	// Start the find.
	DIR* dirp = opendir(basePath[0] ? basePath : ".");
	if (!dirp)
		return;

	// Any files found?
	struct dirent* dp;
	while ((dp = readdir(dirp)) != NULL)
	{
		for (;;)
		{
			struct stat attr;
			strcpy(basePathEndPtr, dp->d_name);
			stat(basePath, &attr);
			*basePathEndPtr = 0;
			
			// Is the file a directory?
			if ((attr.st_mode & S_IFDIR) != 0  &&  !matchFiles)
			{
				// Do a wildcard match.
				if (WildMatch(matchPattern, dp->d_name, false))
				{
					// It matched.  Let's see if the file should be ignored.
					bool ignore = false;
					
					// Knock out "." or ".." if they haven't already been.
					size_t len = strlen(dp->d_name);
					dp->d_name[len] = '/';
					dp->d_name[len + 1] = '\0';
					
					// See if this is a directory to ignore.
					ignore = MatchIgnorePattern(dp->d_name);
					
					dp->d_name[len] = 0;
					
					// Should this file be ignored?
					if (!ignore)
					{
						// Nope.  Add it to the linked list.
						fileList.push_back(dp->d_name);
					}
				}
			}
			else if ((attr.st_mode & S_IFDIR) == 0  &&  matchFiles)
			{
				// Do a wildcard match.
				if (WildMatch(matchPattern, dp->d_name, false))
				{
					// It matched.  Let's see if the file should be ignored.
					bool ignore = MatchIgnorePattern(dp->d_name);
					
					// Is this pattern exclusive?
					if (!ignore  &&  m_exclusiveFilePatterns.begin() != m_exclusiveFilePatterns.end())
					{
						ignore = !MatchExclusivePattern(dp->d_name);
					}
					
					// Should this file be ignored?
					if (!ignore)
					{
						// Nope.  Add it to the linked list.
						fileList.push_back(dp->d_name);
					}
				}
			}
			
			// Look up the next file.
			if ((dp = readdir(dirp)) == NULL)
				break;
		}
		
		// Close down the file find handle.
		closedir(dirp);
	}
	
#endif

	// Iterate the file list and either recurse or add the file as a found
	// file.
	if (!context->matchFiles) {
		if (found) {
			return 1;
		}

NextDirectory:
		if (context->iterNode) {
			// Need more directories.
			SplicePath(self->combinedName, context->basePath, context->iterNode->buffer);
			strcpy(self->combinedName + strlen(self->combinedName) - 1, context->pattern);

			context->iterNode = context->iterNode->next;

			context = NULL;
			inPattern = self->combinedName;
			goto Setup;
		}
	} else {
		if (found)
			return 1;
	}

	// Do we need to recurse?
NewContext:
	if (!context->recurseAtPtr) {
		_fileglob_FreeContextLevel(self);

		context = self->context;
		if (!context)
			return 0;

		goto NextDirectory;
	}

	strcpy(context->matchPattern, context->recurseAtPtr);
	strcpy(context->recurseAtPtr, "*/**/");
	strcat(context->patternBuf, context->matchPattern);

	inPattern = context->patternBuf;
	context->pattern = NULL;
	_fileglob_list_clear(&context->directoryListHead, &context->directoryListTail);
	goto DoRecursion;
}



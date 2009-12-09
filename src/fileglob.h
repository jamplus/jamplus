/**
	\file fileglob.h
**/
#ifndef __FILEGLOB_H__
#define __FILEGLOB_H__

#ifdef __cplusplus
extern "C" {
#endif

typedef struct fileglob fileglob;

fileglob* fileglob_Create(const char* inPattern);
void fileglob_Destroy(fileglob* self);
void fileglob_AddExclusivePattern(fileglob* self, const char* name);
void fileglob_AddIgnorePattern(fileglob* self, const char* name);

int fileglob_Next(fileglob* self);

const char* fileglob_FileName(fileglob* self);
unsigned __int64 fileglob_CreationTime(fileglob* self);
unsigned __int64 fileglob_AccessTime(fileglob* self);
unsigned __int64 fileglob_WriteTime(fileglob* self);
unsigned __int64 fileglob_CreationFILETIME(fileglob* self);
unsigned __int64 fileglob_AccessFILETIME(fileglob* self);
unsigned __int64 fileglob_WriteFILETIME(fileglob* self);
unsigned __int64 fileglob_FileSize(fileglob* self);
int fileglob_IsDirectory(fileglob* self);
int fileglob_IsReadOnly(fileglob* self);

#ifdef __cplusplus
} /* extern "C" */
#endif

#endif /* __FILEGLOB_H__ */

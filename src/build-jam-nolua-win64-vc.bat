cl /nologo /O2 onepackagesupportfiles.c
onepackagesupportfiles jamzipbuffer.c packagefiles.txt
cl /nologo /O2 /Oi /Gy /GL /Fe"%~dp0..\bin\win64\jam-nolua.exe" onejam-nolua.c



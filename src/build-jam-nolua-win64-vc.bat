cl /nologo /O2 /Oi /Gy /GL /Fe"%~dp0..\bin\win64\jam-nolua.exe" onejam-nolua.c
%~dp0..\bin\win64\jam-nolua.exe --packagebuildmodules %~dp0..\bin
move %~dp0..\bin\win64\jam-nolua.exe.repack %~dp0..\bin\win64\jam-nolua.exe



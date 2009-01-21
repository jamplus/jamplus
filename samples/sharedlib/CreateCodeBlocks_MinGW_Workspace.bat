@echo off
call %~dp0..\..\bin\scripts\JamToWorkspace.bat --gen=codeblocks --compiler=mingw Jamfile.jam ../../build/sharedlib
start ..\..\build\sharedlib

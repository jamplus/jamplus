@echo off
call %~dp0..\..\..\bin\scripts\JamToWorkspace.bat --gen=codeblocks --compiler=mingw Jamfile.jam ../../../build/tutorials/01-helloworld
start ..\..\..\build\tutorials\01-helloworld

@echo off
call %~dp0..\..\bin\scripts\JamToWorkspace.bat --gen=vs2005 --compiler=mingw Jamfile.jam ../../build/helloworld
start ..\..\build\helloworld

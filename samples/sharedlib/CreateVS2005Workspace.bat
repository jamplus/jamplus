@echo off
call %~dp0..\..\bin\scripts\JamToWorkspace.bat --gen=vs2005 Jamfile.jam ../../build/sharedlib
start ..\..\build\sharedlib

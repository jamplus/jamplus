@echo off
call %~dp0..\..\bin\scripts\JamToWorkspace.bat --gen=vs2008 --jamflags=CSC_COMPILER=mono Jamfile.jam ../../build/csharp-windowsforms-mono
start ..\..\build\csharp-windowsforms-mono

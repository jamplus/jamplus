@echo off
call %~dp0..\..\bin\scripts\JamToWorkspace.bat --gen=vs2008 Jamfile.jam ../../build/csharp-windowsforms
start ..\..\build\csharp-windowsforms

@echo off
call %~dp0..\..\..\bin\scripts\JamToWorkspace.bat --gen=vs2005 Jamfile.jam ../../../build/tutorials/02-helloworld-static
start ..\..\..\build\tutorials\02-helloworld-static

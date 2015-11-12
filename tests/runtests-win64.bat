@echo off
setlocal
set PATH=%~dp0..\bin\win64;%PATH%
%~dp0..\bin\win64\lua\lua.exe %~dp0runtests.lua --platform win64 %*

@echo off
setlocal
set PATH=%~dp0..\bin\win32;%PATH%
%~dp0..\bin\win32\lua\lua.exe %~dp0runtests.lua %*

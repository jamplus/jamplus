@echo off
setlocal
set PATH=%~dp0..\bin\win32;%PATH%
%~dp0..\bin\win32\lua\lua.exe -debug %~dp0runtests.lua %*

@echo off
setlocal

call %~dp0jmakehelper.cmd %*

nmake /f Makefile.win32 PLATFORM=win32

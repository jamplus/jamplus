@echo off
setlocal

call %~dp0jmakehelper.cmd %*

nmake /f Makefile.win64 PLATFORM=win64

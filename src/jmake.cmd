@echo off
if NOT "%VS90COMNTOOLS%" == "" set COMNTOOLS=%VS90COMNTOOLS%
if NOT "%VS80COMNTOOLS%" == "" set COMNTOOLS=%VS80COMNTOOLS%
if "%COMNTOOLS%" == "" ( 
 echo Cannot find Visual Studio 2005/2008. Aborting.
 goto :end 
)

call "%COMNTOOLS%vsvars32.bat"

nmake /f Makefile.Windows
bin.ntx86\jam.exe -sCONFIG=release -sBUILD_J=yes
@echo jam.exe is at bin.ntx86\jam.exe
@echo j.exe is at jbin.ntx86\j.exe

:end
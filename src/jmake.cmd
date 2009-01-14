@echo off

REM Test for Visual Studio 2008

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\Microsoft\VisualStudio\9.0 /v InstallDir') do set VSDir=%%k) 2>nul

if NOT "%VSDir%" == "" ( 
  set COMNTOOLS=%VSDir%\..\..\Common7\
  goto :foundenv
)

if NOT "%VS90COMNTOOLS%" == "" ( 
  set COMNTOOLS=%VS90COMNTOOLS%
  goto :foundenv
)


REM Test for Visual Studio 2005

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\Microsoft\VisualStudio\8.0 /v InstallDir') do set VSDir=%%k) 2>nul

if NOT "%VSDir%" == "" ( 
  set COMNTOOLS=%VSDir%\..\..\Common7\
  goto :foundenv
)

if NOT "%VS80COMNTOOLS%" == "" ( 
  set COMNTOOLS=%VS80COMNTOOLS%
  goto :foundenv
)

REM Test for Visual Studio 2003

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\Microsoft\VisualStudio\7.1 /v InstallDir') do set VSDir=%%k) 2>nul

if NOT "%VSDir%" == "" ( 
  set COMNTOOLS=%VSDir%\..\..\Common7\
  goto :foundenv
)

if NOT "%VS71COMNTOOLS%" == "" ( 
  set COMNTOOLS=%VS71COMNTOOLS%
  goto :foundenv
)

REM Test for Visual Studio 2002

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\Microsoft\VisualStudio\7.0 /v InstallDir') do set VSDir=%%k) 2>nul

if NOT "%VSDir%" == "" ( 
  set COMNTOOLS=%VSDir%\..\..\Common7\
  goto :foundenv
)

if NOT "%VS70COMNTOOLS%" == "" ( 
  set COMNTOOLS=%VS70COMNTOOLS%
  goto :foundenv
)

:foundenv
if "%COMNTOOLS%" == "" ( 
 echo Cannot find Visual Studio. Aborting.
 goto :end
)

if "%VCINSTALLDIR%" == "" call "%COMNTOOLS%vsvars32.bat"

nmake /f Makefile.Windows
@echo jam.exe is at bin.ntx86\jam.exe

:end
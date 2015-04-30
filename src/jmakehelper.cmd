@echo off

REM Determine command line variables (/V or /v for verbose output)

set VERBOSE=0

if "%1" == "/V" (
  set VERBOSE=1
)

if "%1" == "/v" (
  set VERBOSE=1
)

REM Setup 64-bit aware registry location

IF NOT "%ProgramFiles(x86)%"=="" SET WOW6432NODE=WOW6432NODE\

REM Test for Visual Studio 2013

if %VERBOSE% == 1 echo.Checking Visual Studio 2013
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKCU\software\%WOW6432NODE%Microsoft\VisualStudio\12.0_Config /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2013
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS120COMNTOOLS%" == "" (
  set VS=2013
  set COMNTOOLS="%VS120COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo   ...done

REM Test for Visual Studio 2012

if %VERBOSE% == 1 echo.Checking Visual Studio 2012
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKCU\software\%WOW6432NODE%Microsoft\VisualStudio\11.0_Config /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2012
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS110COMNTOOLS%" == "" (
  set VS=2012
  set COMNTOOLS="%VS110COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo   ...done

REM Test for Visual Studio 2010

if %VERBOSE% == 1 echo.Checking Visual Studio 2010
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\%WOW6432NODE%Microsoft\VisualStudio\10.0 /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2010
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS100COMNTOOLS%" == "" (
  set VS=2010
  set COMNTOOLS="%VS100COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo   ...done

REM Test for Visual Studio 2008

if %VERBOSE% == 1 echo.Checking Visual Studio 2008
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\%WOW6432NODE%Microsoft\VisualStudio\9.0 /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2008
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment


if NOT "%VS90COMNTOOLS%" == "" (
  set VS=2008
  set COMNTOOLS="%VS90COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo   ...done

REM Test for Visual Studio 2005

if %VERBOSE% == 1 echo.Checking Visual Studio 2005
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\%WOW6432NODE%Microsoft\VisualStudio\8.0 /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2005
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS80COMNTOOLS%" == "" (
  set VS=2005
  set COMNTOOLS="%VS80COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...done

REM Test for Visual Studio 2003

if %VERBOSE% == 1 echo.Checking Visual Studio 2003
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\%WOW6432NODE%Microsoft\VisualStudio\7.1 /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2003
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS71COMNTOOLS%" == "" (
  set VS=2003
  set COMNTOOLS="%VS71COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo   ...done

REM Test for Visual Studio 2002

if %VERBOSE% == 1 echo.Checking Visual Studio 2002
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query HKLM\software\%WOW6432NODE%Microsoft\VisualStudio\7.0 /v InstallDir') do set VSDir=%%k) 2>nul

if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=2002
  set COMNTOOLS="%VSDir%..\..\Common7\Tools\vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...looking in environment

if NOT "%VS70COMNTOOLS%" == "" (
  set VS=2002
  set COMNTOOLS="%VS70COMNTOOLS%vsvars32.bat"
  goto :foundenv
)

if %VERBOSE% == 1 echo.  ...done

REM Test for Visual C++ 6.0

if %VERBOSE% == 1 echo.Checking Visual C++ 6.0
if %VERBOSE% == 1 echo.  ...looking in registry

(for /f "tokens=1,2*" %%i in ('reg query "HKLM\SOFTWARE\Microsoft\DevStudio\6.0\Products\Microsoft Visual C++" /v ProductDir') do set VSDir=%%k) 2>nul
if %VERBOSE% == 1 echo.  ...done

if NOT "%VSDir%" == "" (
  set VS=6.0
  set COMNTOOLS="%VSDir%\Bin\vcvars32.bat"
  goto :foundenv
)


:foundenv

if %COMNTOOLS% == "" (
 echo Cannot find Visual Studio. Aborting.
 goto :end
)

if %VERBOSE% == 1 echo.Found Visual Studio %VS%
if %VERBOSE% == 1 echo.

if "%VCINSTALLDIR%" == "" call %COMNTOOLS%

:end

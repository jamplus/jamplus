@echo off
del Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building with all 3 passes.  Both files will be built in pass 2.
pause
jam
pause
del Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building only with passes 1 and 2.  Both files will be built in pass 2.
pause
jam -s IGNORE_PASS_3=true
pause
del Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building only with passes 2 and 3.  Both files will be built in pass 2.
pause
jam -s PASS_NUM=2
pause
del Care.* NoCare.*

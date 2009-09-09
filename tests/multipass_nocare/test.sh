@echo off
rm Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building with all 3 passes.  Both files will be built in pass 2.
read -p "Press Enter to continue"
jam
read -p "Press Enter to continue"
rm Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building only with passes 1 and 2.  Both files will be built in pass 2.
read -p "Press Enter to continue"
jam -s IGNORE_PASS_3=true
read -p "Press Enter to continue"
rm Care.* NoCare.*
echo >Care.cpp
echo >Care.h
echo >NoCare.cpp
echo =====Building only with passes 2 and 3.  Both files will be built in pass 2.
read -p "Press Enter to continue"
jam -s PASS_NUM=2
read -p "Press Enter to continue"
rm Care.* NoCare.*

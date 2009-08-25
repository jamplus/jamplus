@echo off
jam --workspace --gen=vs2008 Jamfile.jam ../../build/sharedlib
start ..\..\build\sharedlib

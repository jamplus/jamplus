@echo off
jam --workspace --gen=vs2005 Jamfile.jam ../../build/sharedlib
start ..\..\build\sharedlib

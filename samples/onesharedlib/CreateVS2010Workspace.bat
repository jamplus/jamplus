@echo off
jam --workspace --gen=vs2010 Jamfile.jam ../../build/sharedlib
start ..\..\build\sharedlib

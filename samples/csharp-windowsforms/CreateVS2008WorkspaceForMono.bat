@echo off
jam --workspace --gen=vs2008 --jamflags=CSC_COMPILER=gmcs Jamfile.jam ../../build/csharp-windowsforms-mono
start ..\..\build\csharp-windowsforms-mono

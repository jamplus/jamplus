@echo off
jam --workspace --gen=vs2008 --compiler=vs2008 Jamfile.jam ../../build/simplemfc
start ..\..\build\simplemfc
